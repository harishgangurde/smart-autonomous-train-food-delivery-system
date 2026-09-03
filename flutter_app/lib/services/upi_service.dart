import 'package:url_launcher/url_launcher.dart';

/// Builds a standard UPI payment intent URI and attempts to launch it.
///
/// This is a direct peer-to-peer UPI collect request — no payment gateway,
/// no merchant account, no KYC needed. It's exactly what a shopkeeper's
/// "Scan to Pay" QR code encodes. Because there's no gateway sitting in
/// the middle, there's also no automatic webhook confirming the payment
/// went through — the passenger completes payment in their own UPI app
/// and then confirms in-app that they've paid (see PaymentScreen). Staff
/// can cross-check against their own UPI app's notifications if needed,
/// same as any small vendor accepting UPI today.
///
/// If real automatic payment verification becomes necessary later, this
/// is the seam to swap for a registered payment aggregator (Razorpay,
/// Cashfree, etc.) which requires business KYC.
class UpiService {
  /// [vpa] is the payee's UPI ID (e.g. "yourname@oksbi"), not a bank
  /// account number — UPI links address a VPA, not an account+IFSC.
  static String buildUpiUri({
    required String vpa,
    required String payeeName,
    required double amount,
    required String orderRef,
    String note = 'Train food order',
  }) {
    final params = {
      'pa': vpa,
      'pn': payeeName,
      'am': amount.toStringAsFixed(2),
      'cu': 'INR',
      'tn': note,
      'tr': orderRef,
    };
    final query = params.entries.map((e) => '${e.key}=${Uri.encodeComponent(e.value)}').join('&');
    return 'upi://pay?$query';
  }

  /// Attempts to open an installed UPI app (GPay/PhonePe/Paytm/etc) with
  /// the payment pre-filled. Works on Android reliably; iOS/desktop
  /// support varies, so the Payment screen always shows the QR code too.
  static Future<bool> launchUpiApp(String upiUri) async {
    final uri = Uri.parse(upiUri);
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  }
}
