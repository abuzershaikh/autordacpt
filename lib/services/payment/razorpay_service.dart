import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../core/utils/logger.dart';

class PaymentSuccessResultData {
  final String paymentId;
  final String? orderId;
  final String? signature;

  PaymentSuccessResultData({
    required this.paymentId,
    this.orderId,
    this.signature,
  });
}

class PaymentErrorResultData {
  final int? code;
  final String? message;

  PaymentErrorResultData({this.code, this.message});
}

class RazorpayService {
  late Razorpay _razorpay;

  // Replace with your Razorpay Test or Live Key ID (e.g. rzp_test_xxxxxxxx)
  static const String razorpayKeyId = 'rzp_test_1DP5mmOlF5G5ag';

  Function(PaymentSuccessResultData)? onSuccess;
  Function(PaymentErrorResultData)? onError;
  Function(String walletName)? onExternalWallet;

  void initialize({
    required Function(PaymentSuccessResultData) onSuccess,
    required Function(PaymentErrorResultData) onError,
    Function(String walletName)? onExternalWallet,
  }) {
    _razorpay = Razorpay();
    this.onSuccess = onSuccess;
    this.onError = onError;
    this.onExternalWallet = onExternalWallet;

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  void openCheckout({
    required num amountInRupees,
    required String planName,
    required String userEmail,
    required String userContact,
    String? customKeyId,
  }) {
    final int amountInPaise = (amountInRupees * 100).toInt();

    final options = {
      'key': customKeyId ?? razorpayKeyId,
      'amount': amountInPaise,
      'name': 'Auto Ride Acceptor',
      'description': '$planName Subscription',
      'timeout': 300, // 5 minutes
      'prefill': {
        'contact': userContact.isNotEmpty ? userContact : '9999999999',
        'email': userEmail.isNotEmpty ? userEmail : 'user@autoride.com',
      },
      'theme': {
        'color': '#2196F3',
      },
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      Logger.error('Error opening Razorpay checkout', error: e);
      onError?.call(PaymentErrorResultData(message: e.toString()));
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    Logger.success('Razorpay Payment Success: ${response.paymentId}');
    onSuccess?.call(
      PaymentSuccessResultData(
        paymentId: response.paymentId ?? 'pay_${DateTime.now().millisecondsSinceEpoch}',
        orderId: response.orderId,
        signature: response.signature,
      ),
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    Logger.error('Razorpay Payment Failed: ${response.code} - ${response.message}');
    onError?.call(
      PaymentErrorResultData(
        code: response.code,
        message: response.message ?? 'Payment failed or cancelled',
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    Logger.log('Razorpay External Wallet: ${response.walletName}');
    onExternalWallet?.call(response.walletName ?? 'Unknown Wallet');
  }

  void dispose() {
    _razorpay.clear();
  }
}
