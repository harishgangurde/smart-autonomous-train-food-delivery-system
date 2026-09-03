import 'package:firebase_auth/firebase_auth.dart';

/// Wraps Firebase Auth's phone-number verification flow. This talks to
/// Firebase directly from the device — the FastAPI backend is never in
/// this path, which is the standard/correct shape for Firebase Phone Auth
/// (Google's own SMS/reCAPTCHA infrastructure handles delivery).
class FirebaseAuthService {
  // A getter, not an eagerly-evaluated field: FirebaseAuth.instance throws
  // if Firebase.initializeApp() was never called (e.g. no project
  // configured yet). Deferring evaluation to first real use means this
  // class is safe to construct unconditionally — the crash only happens
  // if something actually tries to use it before Firebase is set up,
  // which every call site already guards against via
  // `appState.firebaseAvailable`.
  FirebaseAuth get _auth => FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  /// Starts phone verification. [onCodeSent] fires once Firebase has sent
  /// the SMS and gives you a verificationId to pair with the user's typed
  /// code. [onAutoVerified] fires on Android when the OS auto-detects the
  /// SMS and signs the user in without them typing anything.
  Future<void> sendOtp({
    required String phoneNumber, // full E.164 format, e.g. +919999999999
    required void Function(String verificationId) onCodeSent,
    required void Function(String error) onError,
    void Function(User user)? onAutoVerified,
  }) async {
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          final result = await _auth.signInWithCredential(credential);
          if (result.user != null) onAutoVerified?.call(result.user!);
        } catch (e) {
          onError(e.toString());
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        onError(e.message ?? 'Verification failed');
      },
      codeSent: (String verificationId, int? resendToken) {
        onCodeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  Future<User> verifyOtp({
    required String verificationId,
    required String smsCode,
  }) async {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    final result = await _auth.signInWithCredential(credential);
    if (result.user == null) {
      throw Exception('Sign-in failed — no user returned');
    }
    return result.user!;
  }

  /// The single staff account uses Firebase email/password sign-in
  /// instead of phone OTP — set up once in Firebase console
  /// (Authentication → Sign-in method → Email/Password, then
  /// Authentication → Users → Add user). Works from any device with
  /// internet, independent of the FastAPI backend or local network —
  /// this is what makes staff login resilient to the backend being
  /// offline, and what makes it work correctly from a phone that can't
  /// reach your dev machine's "localhost".
  Future<User> signInStaff(
      {required String email, required String password}) async {
    final result = await _auth.signInWithEmailAndPassword(
        email: email, password: password);
    if (result.user == null) {
      throw Exception('Sign-in failed — no user returned');
    }
    return result.user!;
  }

  Future<void> signOut() => _auth.signOut();
}
