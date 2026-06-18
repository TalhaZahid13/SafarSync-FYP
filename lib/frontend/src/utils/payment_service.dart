import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'api_service.dart';

class PaymentService {
  /// Creates a Stripe PaymentIntent on the backend, shows the payment sheet,
  /// then confirms the payment record once the sheet succeeds.
  ///
  /// [amountInCents] — e.g. $50.00 = 5000
  /// Throws [StripeException] if the user cancels the sheet.
  /// Throws [Exception] for backend/network errors.
  static Future<void> pay({
    required int bookingId,
    required int amountInCents,
  }) async {
    // 1. Ask backend to create a PaymentIntent and return clientSecret
    final intentResponse = await ApiService.postRequest(
      '/payments/create-intent',
      {'booking_id': bookingId, 'amount': amountInCents},
    );

    if (intentResponse['success'] != true) {
      throw Exception(
        intentResponse['error'] ?? 'Failed to create payment intent',
      );
    }

    final clientSecret = intentResponse['clientSecret'] as String;
    final paymentIntentId = intentResponse['paymentIntentId'] as String;

    // 2. Initialize the Stripe payment sheet
    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'SafarSync',
        style: ThemeMode.system,
      ),
    );

    // 3. Present the sheet — throws StripeException if user cancels
    await Stripe.instance.presentPaymentSheet();

    // 4. Record the confirmed payment on the backend
    final confirmResponse = await ApiService.postRequest('/payments/confirm', {
      'booking_id': bookingId,
      'payment_intent_id': paymentIntentId,
    });

    if (confirmResponse['success'] != true) {
      throw Exception(
        confirmResponse['error'] ?? 'Payment succeeded but confirmation failed',
      );
    }
  }
}
