// Matches the public constants exposed by razorpay_flutter.
// ignore_for_file: constant_identifier_names

import 'dart:io' show Platform;

import 'package:razorpay_flutter/razorpay_flutter.dart' as razorpay_flutter;

typedef RazorpayEventHandler<T> = void Function(T response);

class PaymentSuccessResponse {
  const PaymentSuccessResponse({this.paymentId, this.orderId, this.signature});

  final String? paymentId;
  final String? orderId;
  final String? signature;
}

class PaymentFailureResponse {
  const PaymentFailureResponse({this.code, this.message});

  final String? code;
  final String? message;
}

class Razorpay {
  static const String EVENT_PAYMENT_SUCCESS =
      razorpay_flutter.Razorpay.EVENT_PAYMENT_SUCCESS;
  static const String EVENT_PAYMENT_ERROR =
      razorpay_flutter.Razorpay.EVENT_PAYMENT_ERROR;

  Razorpay() {
    if (_supportsNativeCheckout) {
      _razorpay = razorpay_flutter.Razorpay();
    }
  }

  razorpay_flutter.Razorpay? _razorpay;
  RazorpayEventHandler<PaymentFailureResponse>? _errorHandler;

  bool get _supportsNativeCheckout => Platform.isAndroid || Platform.isIOS;

  void on(String event, Function handler) {
    if (event == EVENT_PAYMENT_SUCCESS) {
      _razorpay?.on(event, (razorpay_flutter.PaymentSuccessResponse response) {
        (handler as RazorpayEventHandler<PaymentSuccessResponse>).call(
          PaymentSuccessResponse(
            paymentId: response.paymentId,
            orderId: response.orderId,
            signature: response.signature,
          ),
        );
      });
    } else if (event == EVENT_PAYMENT_ERROR) {
      _errorHandler = handler as RazorpayEventHandler<PaymentFailureResponse>;
      _razorpay?.on(event, (razorpay_flutter.PaymentFailureResponse response) {
        _errorHandler?.call(
          PaymentFailureResponse(
            code: response.code.toString(),
            message: response.message,
          ),
        );
      });
    }
  }

  void open(Map<String, dynamic> options) {
    if (!_supportsNativeCheckout || _razorpay == null) {
      _errorHandler?.call(
        const PaymentFailureResponse(
          code: 'unsupported_platform',
          message: 'Razorpay payments are supported only on Android and iOS.',
        ),
      );
      return;
    }

    _razorpay!.open(options);
  }

  void clear() {
    _razorpay?.clear();
    _razorpay = null;
    _errorHandler = null;
  }
}
