import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_theme.dart';

class RatingDialog extends StatefulWidget {
  final String orderId;
  final String? displayOrderId;
  final VoidCallback? onSubmitted;

  const RatingDialog({
    super.key,
    required this.orderId,
    this.displayOrderId,
    this.onSubmitted,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  int _foodRating = 0;
  int _deliveryRating = 0;
  int _overallRating = 0;
  final _reviewController = TextEditingController();

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  Future<void> _submitRating() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please give an overall rating'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Validate ratings are within 1-5 range
    final food = _foodRating == 0 ? _overallRating : _foodRating;
    final delivery = _deliveryRating == 0 ? _overallRating : _deliveryRating;
    final overall = _overallRating;

    if (food < 1 ||
        food > 5 ||
        delivery < 1 ||
        delivery > 5 ||
        overall < 1 ||
        overall > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All ratings must be between 1 and 5'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Capture context before closing dialog
    final reviewText = _reviewController.text.trim();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final onSubmitted = widget.onSubmitted;

    // Optimistic UI: close dialog immediately
    navigator.pop();
    onSubmitted?.call();

    // Submit rating in background after dialog is closed
    _submitRatingInBackground(
      food: food,
      delivery: delivery,
      overall: overall,
      review: reviewText.isEmpty ? null : reviewText,
      scaffoldMessenger: scaffoldMessenger,
    );
  }

  Future<void> _submitRatingInBackground({
    required int food,
    required int delivery,
    required int overall,
    String? review,
    required ScaffoldMessengerState scaffoldMessenger,
  }) async {
    try {
      final token = await AuthService.getToken();
      if (token == null || token.isEmpty) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Please login to submit rating'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final result = await ApiService.rateOrder(
        token: token,
        orderId: widget.orderId,
        food: food,
        overall: overall,
        delivery: delivery,
        review: review,
      );

      if (result['success'] == true) {
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Thank you for your rating!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Failed to submit: ${result['error']}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Failed to submit rating: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Rate Your Order',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Order #${widget.displayOrderId ?? widget.orderId}',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              _buildRatingSection(
                title: 'Overall Experience *',
                rating: _overallRating,
                onChanged: (value) => setState(() => _overallRating = value),
              ),
              const SizedBox(height: 16),
              _buildRatingSection(
                title: 'Food Quality',
                rating: _foodRating,
                onChanged: (value) => setState(() => _foodRating = value),
              ),
              const SizedBox(height: 16),
              _buildRatingSection(
                title: 'Delivery',
                rating: _deliveryRating,
                onChanged: (value) => setState(() => _deliveryRating = value),
              ),
              const SizedBox(height: 16),
              const Text(
                'Review (Optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _reviewController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Share your experience...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.textLight),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.textLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _submitRating,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Submit Rating',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRatingSection({
    required String title,
    required int rating,
    required ValueChanged<int> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final starValue = index + 1;
            return IconButton(
              onPressed: () => onChanged(starValue),
              icon: Icon(
                starValue <= rating ? Icons.star : Icons.star_border,
                color: starValue <= rating ? Colors.amber : AppColors.textLight,
                size: 32,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4),
              constraints: const BoxConstraints(),
            );
          }),
        ),
      ],
    );
  }
}

void showRatingDialog(
  BuildContext context,
  String orderId, {
  String? displayOrderId,
  VoidCallback? onSubmitted,
}) {
  showDialog(
    context: context,
    barrierDismissible: true,
    builder: (context) => RatingDialog(
      orderId: orderId,
      displayOrderId: displayOrderId,
      onSubmitted: onSubmitted,
    ),
  );
}
