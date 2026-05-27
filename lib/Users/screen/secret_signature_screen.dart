import 'package:flutter/material.dart';

import '../../utils/app_theme.dart';

class SecretSignatureScreen extends StatefulWidget {
  const SecretSignatureScreen({super.key});

  @override
  State<SecretSignatureScreen> createState() => _SecretSignatureScreenState();
}

class _SecretSignatureScreenState extends State<SecretSignatureScreen>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<Animation<double>> _fadeAnimations;
  late final List<Animation<Offset>> _slideAnimations;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimations = List.generate(6, (i) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(i * 0.1, 0.6 + i * 0.08, curve: Curves.easeOut),
        ),
      );
    });

    _slideAnimations = List.generate(6, (i) {
      return Tween<Offset>(
        begin: const Offset(0, 20),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _controller,
          curve: Interval(i * 0.1, 0.6 + i * 0.08, curve: Curves.easeOutCubic),
        ),
      );
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: AppColors.surface,
            foregroundColor: AppColors.textPrimary,
            iconTheme: const IconThemeData(color: AppColors.primary),
            title: Text(
              'Developer Signature',
              style: DMSansFont.bold.copyWith(fontSize: 18),
            ),
            centerTitle: true,
            elevation: 0,
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _animatedSection(0, _buildLogo()),
                  const SizedBox(height: 24),
                  _animatedSection(1, _buildTitle()),
                  const SizedBox(height: 32),
                  _animatedSection(2, _buildDiscoveryCard()),
                  const SizedBox(height: 32),
                  _animatedSection(3, _buildPerksSection()),
                  const SizedBox(height: 32),
                  _animatedSection(4, _buildContactCard(context)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _animatedSection(int index, Widget child) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return FadeTransition(
          opacity: _fadeAnimations[index],
          child: SlideTransition(
            position: _slideAnimations[index],
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildLogo() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 24,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/uninest.png',
          width: 120,
          height: 120,
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      children: [
        Text(
          'UNI NEST',
          style: DMSansFont.bold.copyWith(
            fontSize: 32,
            color: AppColors.textPrimary,
            letterSpacing: 3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Crafted with passion by',
          style: DMSansFont.medium.copyWith(
            fontSize: 16,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Gabrial Deora',
          style: DMSansFont.semiBold.copyWith(
            fontSize: 28,
            color: AppColors.primary,
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoveryCard() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'You discovered the secret!',
              style: DMSansFont.bold.copyWith(
                fontSize: 18,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Only the most curious minds find this place. Welcome to the inner circle.',
              style: DMSansFont.regular.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerksSection() {
    final perks = [
      _PerkData(
        icon: Icons.fastfood_outlined,
        text: 'Order delicious food instantly',
      ),
      _PerkData(
        icon: Icons.bolt_outlined,
        text: 'Lightning-fast delivery to your location',
      ),
      _PerkData(
        icon: Icons.local_offer_outlined,
        text: 'Exclusive student discounts & offers',
      ),
      _PerkData(
        icon: Icons.map_outlined,
        text: 'Track your order in real-time',
      ),
      _PerkData(
        icon: Icons.star_outline,
        text: 'Rate and review your favorite meals',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'UNI NEST Perks',
          style: DMSansFont.semiBold.copyWith(
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ...perks.map((perk) => _buildPerkItem(perk)),
      ],
    );
  }

  Widget _buildPerkItem(_PerkData perk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(perk.icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              perk.text,
              style: DMSansFont.regular.copyWith(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.15)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(
                  Icons.email_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
                const SizedBox(height: 16),
                Text(
                  'Found the signature?',
                  style: DMSansFont.semiBold.copyWith(
                    fontSize: 18,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Drop me a message.',
                  style: DMSansFont.regular.copyWith(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => _showCopiedSnackBar(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.copy,
                          size: 18,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'gabrialdeora003@gmail.com',
                          style: DMSansFont.medium.copyWith(
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          right: 12,
          top: -12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text(
                  'SURPRISE!',
                  style: DMSansFont.bold.copyWith(
                    fontSize: 11,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCopiedSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Email copied! Send your message to gabrialdeora003@gmail.com',
          style: DMSansFont.medium.copyWith(fontSize: 14, color: Colors.white),
        ),
        backgroundColor: AppColors.textPrimary,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

class _PerkData {
  final IconData icon;
  final String text;
  _PerkData({required this.icon, required this.text});
}
