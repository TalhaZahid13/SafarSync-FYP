import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import '../utils/payment_service.dart';
import 'payment_receipt_screen.dart';

// ─── PaymentFailureScreen ─────────────────────────────────────────────────────

class PaymentFailureScreen extends StatelessWidget {
  final String failureReason;
  final VoidCallback? onRetry;

  const PaymentFailureScreen({
    super.key,
    required this.failureReason,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Payment Failed')),
      body: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.cancel_outlined, color: Colors.red, size: 80),
            const SizedBox(height: 20),
            Text(
              'Payment Failed',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
              ),
              child: Text(
                failureReason,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
            ),
            const SizedBox(height: 32),
            if (onRetry != null)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onRetry!();
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Back to Home'),
            ),
          ],
        ),
      ),
    );
  }
}

class PaymentPage extends StatefulWidget {
  final int bookingId;
  final String destinationName;
  final int durationDays;
  final int numTravelers;
  final double pricePerDay;
  final double totalAmount;

  const PaymentPage({
    super.key,
    required this.bookingId,
    required this.destinationName,
    required this.durationDays,
    this.numTravelers = 1,
    this.pricePerDay = 50.0,
    this.totalAmount = 0,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _loading = false;

  double get _subtotal =>
      widget.totalAmount > 0
          ? widget.totalAmount
          : widget.durationDays * widget.pricePerDay * widget.numTravelers;
  double get _tax => _subtotal * 0.10;
  double get _total => _subtotal + _tax;
  int get _totalCents => (_total * 100).round();

  Future<void> _pay() async {
    setState(() => _loading = true);
    try {
      final paymentId = await PaymentService.pay(
        bookingId: widget.bookingId,
        amountInCents: _totalCents,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment successful!'),
          backgroundColor: Colors.green,
        ),
      );
      if (paymentId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentReceiptScreen(
              paymentId: paymentId,
              bookingId: widget.bookingId,
              destinationName: widget.destinationName,
              amountPaid: _total,
            ),
          ),
        );
      } else {
        Navigator.pop(context, true);
      }
    } on StripeException catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      final msg = e.error.localizedMessage ?? 'Payment cancelled or failed';
      if (e.error.code == FailureCode.Canceled) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment cancelled')),
        );
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentFailureScreen(
            failureReason: msg,
            onRetry: _pay,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentFailureScreen(
            failureReason: e.toString(),
            onRetry: _pay,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              borderRadius: BorderRadius.circular(16),
              elevation: 1,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Booking Summary',
                        style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    _row('Destination', widget.destinationName),
                    _row('Duration',
                        '${widget.durationDays} day${widget.durationDays > 1 ? 's' : ''}'),
                    _row('Travelers',
                        '${widget.numTravelers} person${widget.numTravelers > 1 ? 's' : ''}'),
                    _row('Rate per day',
                        '\$${widget.pricePerDay.toStringAsFixed(0)}'),
                    const Divider(height: 24),
                    _row('Subtotal', '\$${_subtotal.toStringAsFixed(2)}'),
                    _row('Tax (10%)', '\$${_tax.toStringAsFixed(2)}',
                        muted: true),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total',
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold)),
                        Text(
                          '\$${_total.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 14, color: Colors.grey),
                SizedBox(width: 4),
                Text(
                  'Secured by Stripe',
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _pay,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _loading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Text('Pay \$${_total.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool muted = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(
                    color: muted ? Colors.grey : null, fontSize: 14)),
            Text(value,
                style: TextStyle(
                    color: muted ? Colors.grey : null, fontSize: 14)),
          ],
        ),
      );
}
