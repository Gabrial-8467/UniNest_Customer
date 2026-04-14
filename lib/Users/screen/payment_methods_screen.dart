import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';

class PaymentMethodsScreen extends StatefulWidget {
  final bool showBackButton;

  const PaymentMethodsScreen({super.key, this.showBackButton = true});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  String _selectedMethod = 'cod';

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'cod',
      'name': 'Cash on Delivery',
      'description': 'Pay when you receive your order',
      'icon': Icons.money,
    },
    {
      'id': 'card',
      'name': 'Credit/Debit Card',
      'description': 'Pay securely with your card',
      'icon': Icons.credit_card,
    },
    {
      'id': 'upi',
      'name': 'UPI',
      'description': 'Pay using UPI apps',
      'icon': Icons.qr_code_scanner,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: const Text(
          'Payment Methods',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: widget.showBackButton
            ? IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back,
                  color: AppColors.textPrimary,
                ),
              )
            : null,
        automaticallyImplyLeading: widget.showBackButton,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _paymentMethods.length,
        itemBuilder: (context, index) {
          final method = _paymentMethods[index];
          final isSelected = _selectedMethod == method['id'];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(color: AppColors.primary, width: 2)
                  : null,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : AppColors.background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  method['icon'] as IconData,
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.textSecondary,
                  size: 24,
                ),
              ),
              title: Text(
                method['name'] as String,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? AppColors.primary : AppColors.textPrimary,
                ),
              ),
              subtitle: Text(
                method['description'] as String,
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              trailing: isSelected
                  ? Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    )
                  : Icon(Icons.chevron_right, color: AppColors.textLight),
              onTap: () {
                setState(() {
                  _selectedMethod = method['id'] as String;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${method['name']} selected as default'),
                    backgroundColor: AppColors.success,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save Preference',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }
}
