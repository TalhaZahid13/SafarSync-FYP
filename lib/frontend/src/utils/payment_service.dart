import 'package:flutter/material.dart' show ThemeMode;
import 'package:flutter_stripe/flutter_stripe.dart';
import 'api_service.dart';

class PaymentService {
  /// Creates a Stripe PaymentIntent, shows the payment sheet, confirms on backend.
  /// Returns the backend payment record ID on success, or null if not available.
  static Future<int?> pay({
    required int bookingId,
    required int amountInCents,
  }) async {
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

    await Stripe.instance.initPaymentSheet(
      paymentSheetParameters: SetupPaymentSheetParameters(
        paymentIntentClientSecret: clientSecret,
        merchantDisplayName: 'SafarSync',
        style: ThemeMode.system,
      ),
    );

    await Stripe.instance.presentPaymentSheet();

    final confirmResponse = await ApiService.postRequest('/payments/confirm', {
      'booking_id': bookingId,
      'payment_intent_id': paymentIntentId,
    });

    if (confirmResponse['success'] != true) {
      throw Exception(
        confirmResponse['error'] ?? 'Payment succeeded but confirmation failed',
      );
    }

    return confirmResponse['payment_id'] as int?;
  }

  static Future<List<dynamic>> getHistory() async {
    final r = await ApiService.getRequest('/payments/history');
    return r['payments'] as List? ?? [];
  }

  static Future<Map<String, dynamic>?> getReceipt(int paymentId) async {
    final r = await ApiService.getRequest('/payments/$paymentId/receipt');
    if (r['success'] == true) return r['receipt'] as Map<String, dynamic>?;
    return null;
  }

  static Future<bool> requestRefund(int bookingId) async {
    final r = await ApiService.postRequest('/payments/refund', {
      'booking_id': bookingId,
    });
    return r['success'] == true;
  }
}
