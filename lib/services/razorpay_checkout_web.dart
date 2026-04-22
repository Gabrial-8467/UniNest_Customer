// Matches the public constants exposed by razorpay_flutter and is compiled only
// for Flutter web through the conditional export in razorpay_checkout.dart.
// ignore_for_file: avoid_web_libraries_in_flutter, constant_identifier_names

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

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
  static const String EVENT_PAYMENT_SUCCESS = 'payment.success';
  static const String EVENT_PAYMENT_ERROR = 'payment.error';

  RazorpayEventHandler<PaymentSuccessResponse>? _successHandler;
  RazorpayEventHandler<PaymentFailureResponse>? _errorHandler;

  void on(String event, Function handler) {
    if (event == EVENT_PAYMENT_SUCCESS) {
      _successHandler = handler as RazorpayEventHandler<PaymentSuccessResponse>;
    } else if (event == EVENT_PAYMENT_ERROR) {
      _errorHandler = handler as RazorpayEventHandler<PaymentFailureResponse>;
    }
  }

  void open(Map<String, dynamic> options) {
    final razorpayConstructor = globalContext['Razorpay'];
    if (razorpayConstructor == null) {
      _errorHandler?.call(
        const PaymentFailureResponse(
          code: 'checkout_script_missing',
          message: 'Unable to load Razorpay Checkout. Please try again.',
        ),
      );
      return;
    }

    final checkoutOptions = Map<String, dynamic>.from(options);
    checkoutOptions['handler'] = ((JSObject response) {
      _successHandler?.call(
        PaymentSuccessResponse(
          orderId: _readString(response, 'razorpay_order_id'),
          paymentId: _readString(response, 'razorpay_payment_id'),
          signature: _readString(response, 'razorpay_signature'),
        ),
      );
    }).toJS;

    final modal = Map<String, dynamic>.from(
      (checkoutOptions['modal'] as Map?) ?? const <String, dynamic>{},
    );
    modal['ondismiss'] = (() {
      _errorHandler?.call(
        const PaymentFailureResponse(
          code: 'payment_cancelled',
          message: 'Payment cancelled.',
        ),
      );
    }).toJS;
    checkoutOptions['modal'] = modal;

    final checkout = (razorpayConstructor as JSFunction)
        .callAsConstructor<JSObject>(checkoutOptions.jsify());

    checkout.callMethod<JSAny?>(
      'on'.toJS,
      'payment.failed'.toJS,
      ((JSObject response) {
        final error = _readProperty(response, 'error') as JSObject?;
        _errorHandler?.call(
          PaymentFailureResponse(
            code: _readString(error, 'code') ?? 'payment_failed',
            message:
                _readString(error, 'description') ??
                _readString(error, 'reason') ??
                'Payment failed.',
          ),
        );
      }).toJS,
    );

    checkout.callMethod<JSAny?>('open'.toJS);
  }

  void clear() {
    _successHandler = null;
    _errorHandler = null;
  }
}

JSAny? _readProperty(JSObject? source, String property) {
  if (source == null || !source.has(property)) {
    return null;
  }

  return source[property];
}

String? _readString(JSObject? source, String property) {
  final value = _readProperty(source, property);
  return value?.dartify()?.toString();
}
