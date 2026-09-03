import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/brand_header.dart';
import '../../widgets/timeline_stepper.dart';
import '../../widgets/otp_box_input.dart';
import '../../state/app_state.dart';
import '../../state/order_state.dart';
import '../../models/order.dart';

class TrackTab extends StatefulWidget {
  const TrackTab({super.key});

  @override
  State<TrackTab> createState() => _TrackTabState();
}

class _TrackTabState extends State<TrackTab> {
  String _otp = '';
  bool _verifying = false;
  String? _error;

  Future<void> _submitOtp(Order order) async {
    setState(() { _verifying = true; _error = null; });
    final appState = context.read<AppState>();
    final orderState = context.read<OrderState>();
    try {
      if (appState.simulationMode && !appState.firebaseAvailable) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (_otp != order.otp) throw Exception('Invalid OTP');
        await orderState.updateStatus(order.orderId, 'OTP_VERIFIED');
        await Future.delayed(const Duration(milliseconds: 400));
        await orderState.updateStatus(order.orderId, 'DELIVERED');
      } else {
        final result = await appState.api.verifyDeliveryOtp(
          orderId: order.orderId, authId: order.authId,
          coachNo: order.coachNo, seatNo: order.seatNo, otp: _otp,
        );
        if (result['success'] != true) throw Exception(result['message']);
      }
    } catch (e) {
      setState(() => _error = 'Invalid OTP. Please check and try again.');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final orderState = context.watch<OrderState>();

    final order = appState.activeOrderId == null
        ? null
        : orderState.orders.where((o) => o.orderId == appState.activeOrderId).firstOrNull;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BrandHeader(
              trailing: InfoPill(label: 'Coach ${appState.coachNo} · Seat ${appState.seatNo}'),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: order == null ? _emptyState() : _orderJourney(order),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle,
                border: Border.all(color: AppColors.cardBorder)),
            child: const Icon(Icons.airline_seat_recline_normal_rounded, size: 36, color: AppColors.textMuted),
          ),
          const SizedBox(height: 18),
          const Text('No Active Order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          const Text('Order something from the Bistro to see it tracked here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _orderJourney(Order order) {
    if (order.orderStatus == 'DELIVERED') {
      return _deliveredState(order);
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Active Order Journey', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text('ID: ${order.orderId}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
          const SizedBox(height: 20),
          _panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Technical Timeline', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15))),
                    Text(order.orderStatus == 'ARRIVED' || order.orderStatus == 'OTP_VERIFIED' ? 'ARRIVED' : 'IN PROGRESS',
                        style: const TextStyle(color: AppColors.amber, fontSize: 11, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 16),
                TimelineStepper(currentStatus: order.orderStatus, order: order),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _panel(
            child: TransitVector(
              progress: _progressFor(order.orderStatus),
              seatLabel: 'Your Seat: ${order.coachNo}-${order.seatNo}',
            ),
          ),
          if (order.orderStatus == 'ARRIVED') ...[
            const SizedBox(height: 16),
            _panel(
              borderColor: AppColors.primary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: const [
                      Icon(Icons.lock_rounded, color: AppColors.primaryBright, size: 20),
                      SizedBox(width: 8),
                      Text('Authorization Required', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text('Enter code to unlock compartment',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                  const SizedBox(height: 18),
                  OtpBoxInput(onChanged: (v) => _otp = v),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 12)),
                  ],
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: (_verifying || _otp.length < 6) ? null : () => _submitOtp(order),
                      child: _verifying
                          ? const SizedBox(height: 18, width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('UNLOCK COMPARTMENT'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _deliveredState(Order order) {
    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(color: AppColors.green.withOpacity(0.12), shape: BoxShape.circle,
                  border: Border.all(color: AppColors.green.withOpacity(0.4))),
              child: const Icon(Icons.check_rounded, size: 40, color: AppColors.green),
            ),
            const SizedBox(height: 20),
            const Text('Enjoy Your Meal', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text('Order ID: ${order.orderId} · Delivered',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
            const SizedBox(height: 28),
            SizedBox(
              width: 220,
              child: ElevatedButton(
                onPressed: () => context.read<AppState>().setPassengerTab(2),
                child: const Text('View History'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 220,
              child: OutlinedButton(
                onPressed: () => context.read<AppState>().clearActiveOrder(),
                child: const Text('Dismiss'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  double _progressFor(String status) {
    switch (status) {
      case 'PLACED':
      case 'CONFIRMED':
      case 'PREPARING':
      case 'READY':
        return 0.0;
      case 'LOADED':
        return 0.15;
      case 'DISPATCHED':
        return 0.55;
      case 'ARRIVED':
      case 'OTP_VERIFIED':
      case 'DELIVERED':
        return 1.0;
      default:
        return 0.0;
    }
  }

  Widget _panel({required Widget child, Color? borderColor}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor ?? AppColors.cardBorder),
      ),
      child: child,
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
