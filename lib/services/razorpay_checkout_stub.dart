// Matches the public constants exposed by razorpay_flutter.
// ignore_for_file: constant_identifier_names

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

  RazorpayEventHandler<PaymentFailureResponse>? _errorHandler;

  void on(String event, Function handler) {
    if (event == EVENT_PAYMENT_ERROR) {
      _errorHandler = handler as RazorpayEventHandler<PaymentFailureResponse>;
    }
  }

  void open(Map<String, dynamic> options) {
    _errorHandler?.call(
      const PaymentFailureResponse(
        code: 'unsupported_platform',
        message: 'Razorpay payments are not supported on this platform.',
      ),
    );
  }

  void clear() {
    _errorHandler = null;
  }
}
