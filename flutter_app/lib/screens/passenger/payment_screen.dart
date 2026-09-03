import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../state/app_state.dart';
import '../../state/cart_state.dart';
import '../../state/order_state.dart';
import '../../services/upi_service.dart';
import '../../services/api_service.dart' show ApiException;
import 'passenger_shell_screen.dart';

enum _PayMethod { upi, prepaid }

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  _PayMethod _method = _PayMethod.upi;
  final _ticketController = TextEditingController();
  bool _ticketVerified = false;
  bool _loading = false;
  String? _error;
  late final String _txnRef =
      'TXN${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(999)}';

  Future<void> _verifyTicket() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final appState = context.read<AppState>();
    try {
      if (appState.simulationMode) {
        await Future.delayed(const Duration(milliseconds: 600));
        if (_ticketController.text.trim().isEmpty) throw Exception('invalid');
        _ticketVerified = true;
      } else {
        await appState.api.verifyTicket(
            _ticketController.text.trim(), appState.coachNo!, appState.seatNo!);
        _ticketVerified = true;
      }
      setState(() {});
    } catch (e) {
      // Show the real reason, not a guess — "not found" and "backend
      // unreachable" were previously indistinguishable, which made a
      // pure networking problem (wrong Backend URL on this device, or
      // backend not running) look identical to a genuinely bad ticket
      // number.
      setState(() => _error = _friendlyError(e));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openUpiApp(double amount) async {
    final appState = context.read<AppState>();
    final uri = UpiService.buildUpiUri(
      vpa: appState.upiVpa,
      payeeName: appState.upiPayeeName,
      amount: amount,
      orderRef: _txnRef,
    );
    final opened = await UpiService.launchUpiApp(uri);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Could not open a UPI app — scan the QR code instead.')),
      );
    }
  }

  Future<void> _confirmAndCreateOrder(
      {required String paymentMethod, String? ticketNumber}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final appState = context.read<AppState>();
    final cart = context.read<CartState>();
    final orderState = context.read<OrderState>();

    try {
      final order = await orderState.createOrder(
        passengerId: appState.passengerId!,
        passengerName: appState.passengerMobile ?? 'Passenger',
        coachNo: appState.coachNo!,
        seatNo: appState.seatNo!,
        items: cart.itemList.map((e) => e.toJson()).toList(),
        paymentMethod: paymentMethod,
        ticketNumber: ticketNumber,
      );

      cart.clear();
      if (appState.simulationMode) {
        appState.simulation.simulateOrderLifecycle(
          orderId: order.orderId,
          authId: order.authId,
          coachNo: order.coachNo,
          seatNo: order.seatNo,
        );
      }
      appState
          .setActiveOrder(order.orderId); // also switches shell to Track tab
      if (mounted) {
        Navigator.of(context)
            .popUntil(ModalRoute.withName(passengerShellRouteName));
      }
    } catch (e) {
      setState(() => _error = _friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Surfaces the real cause instead of a generic message — an
  /// ApiException carries the backend's actual error text (e.g. "Ticket
  /// number not found"); anything else is almost always the device
  /// simply failing to reach the backend at all (wrong Backend URL,
  /// different network, firewall) — showing the raw exception here is
  /// what makes that diagnosable instead of a dead-end "something went
  /// wrong".
  String _friendlyError(Object e) {
    if (e is ApiException) return e.message;
    return 'Could not reach the backend ($e). Check Settings → Backend '
        'Connection is set to the right address for this device.';
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartState>();
    final appState = context.watch<AppState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: GridBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              GlassCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total Amount',
                        style: TextStyle(color: AppColors.textSecondary)),
                    Text('₹${cart.total.toStringAsFixed(0)}',
                        style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Text('PAYMENT METHOD', style: AppTheme.uppercaseLabel),
              const SizedBox(height: 12),
              _MethodTile(
                title: 'Pay via UPI',
                subtitle: 'Scan QR or open GPay / PhonePe / Paytm',
                icon: Icons.qr_code_rounded,
                selected: _method == _PayMethod.upi,
                onTap: () => setState(() => _method = _PayMethod.upi),
              ),
              const SizedBox(height: 10),
              _MethodTile(
                title: 'Prepaid Ticket',
                subtitle: 'Already included in your ticket fare',
                icon: Icons.confirmation_number_rounded,
                selected: _method == _PayMethod.prepaid,
                onTap: () => setState(() => _method = _PayMethod.prepaid),
              ),
              if (_method == _PayMethod.upi) ...[
                const SizedBox(height: 16),
                if (!appState.upiConfigured)
                  GlassCard(
                    borderColor: AppColors.red,
                    child: Row(
                      children: const [
                        Icon(Icons.error_outline_rounded,
                            color: AppColors.red, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'UPI isn\'t configured yet. Ask staff to add a UPI ID in Staff → Settings.',
                            style:
                                TextStyle(color: AppColors.red, fontSize: 12.5),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  GlassCard(
                    child: Column(
                      children: [
                        Text('Pay ${appState.upiPayeeName}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 4),
                        Text(appState.upiVpa,
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12)),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16)),
                          child: QrImageView(
                            data: UpiService.buildUpiUri(
                              vpa: appState.upiVpa,
                              payeeName: appState.upiPayeeName,
                              amount: cart.total,
                              orderRef: _txnRef,
                            ),
                            size: 200,
                            backgroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                            'Scan with any UPI app, or tap below on mobile',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => _openUpiApp(cart.total),
                            icon:
                                const Icon(Icons.open_in_new_rounded, size: 16),
                            label: const Text('OPEN UPI APP'),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              if (_method == _PayMethod.prepaid) ...[
                const SizedBox(height: 16),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _ticketController,
                        enabled: !_ticketVerified,
                        decoration: const InputDecoration(
                            labelText: 'Ticket / PNR Number'),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Demo mode: try PNR1234567 or PNR7654321 (see backend/app/services/store.py '
                        'tickets_db — replace with a real ticketing API for production).',
                        style:
                            TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                      const SizedBox(height: 12),
                      if (_ticketVerified)
                        const Row(
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: AppColors.green, size: 18),
                            SizedBox(width: 6),
                            Text('Ticket verified',
                                style: TextStyle(color: AppColors.green)),
                          ],
                        )
                      else
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _loading ? null : _verifyTicket,
                            child: const Text('VERIFY TICKET'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.red)),
              ],
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading || !_canConfirm(appState)
                      ? null
                      : _onConfirmPressed,
                  child: _loading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_method == _PayMethod.upi
                          ? "I'VE COMPLETED THE PAYMENT"
                          : 'CONFIRM ORDER'),
                ),
              ),
              if (_method == _PayMethod.upi) ...[
                const SizedBox(height: 10),
                const Text(
                  'Since this is a direct UPI payment (no gateway), we rely on your '
                  'confirmation here that the transfer went through — same as any small '
                  'vendor accepting UPI. Please only confirm after the payment actually completes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  bool _canConfirm(AppState appState) {
    if (_method == _PayMethod.upi) return appState.upiConfigured;
    return _ticketVerified;
  }

  void _onConfirmPressed() {
    if (_method == _PayMethod.upi) {
      _confirmAndCreateOrder(paymentMethod: 'UPI');
    } else {
      _confirmAndCreateOrder(
          paymentMethod: 'PREPAID_TICKET',
          ticketNumber: _ticketController.text.trim());
    }
  }
}

class _MethodTile extends StatelessWidget {
  final String title, subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      borderColor: selected ? AppColors.primary : null,
      child: Row(
        children: [
          Icon(icon,
              color: selected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                Text(subtitle,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.textMuted),
        ],
      ),
    );
  }
}
