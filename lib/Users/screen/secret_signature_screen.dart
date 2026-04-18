import 'package:flutter/material.dart';

class SecretSignatureScreen extends StatelessWidget {
  const SecretSignatureScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          'Developer Signature',
          style: TextStyle(
            color: Color(0xFF2D3436),
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF2D3436)),
        elevation: 0,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 32,
                    vertical: isSmallScreen ? 16 : 24,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          isSmallScreen ? 50 : 60,
                        ),
                        child: Container(
                          width: isSmallScreen ? 100 : 120,
                          height: isSmallScreen ? 100 : 120,
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFF6B6B,
                                ).withValues(alpha: 0.3),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/uninest.jpeg',
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 30 : 40),

                      Text(
                        'UNI NEST',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 28 : 32,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF2D3436),
                          letterSpacing: 2,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Text(
                        'Crafted with ❤️ by',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 16 : 18,
                          color: const Color(0xFFFF6B6B),
                          letterSpacing: 1,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 16 : 20),

                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFFF6B6B),
                            Color(0xFF4ECDC4),
                            Color(0xFFFF6B6B),
                          ],
                          tileMode: TileMode.mirror,
                        ).createShader(bounds),
                        child: Text(
                          'Gabrial Deora',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 24 : 28,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 2,
                          ),
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 30 : 40),

                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16 : 32,
                        ),
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(
                              0xFFFF6B6B,
                            ).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.psychology,
                              color: const Color(0xFFFF6B6B),
                              size: isSmallScreen ? 28 : 32,
                            ),
                            SizedBox(height: isSmallScreen ? 10 : 12),
                            Text(
                              '🎉 CONGRATULATIONS! 🎉',
                              style: TextStyle(
                                color: const Color(0xFF2D3436),
                                fontSize: isSmallScreen ? 16 : 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            SizedBox(height: isSmallScreen ? 6 : 8),
                            Text(
                              'You\'ve discovered the legendary secret screen!\nOnly the most curious minds find this place.',
                              style: TextStyle(
                                color: const Color(0xFF636E72),
                                fontSize: isSmallScreen ? 13 : 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 30 : 40),

                      Column(
                        children: [
                          Text(
                            '🌟 UNI NEST Perks 🌟',
                            style: TextStyle(
                              color: const Color(0xFF2D3436),
                              fontSize: isSmallScreen ? 16 : 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(height: isSmallScreen ? 12 : 16),
                          _buildPowerCard(
                            '🍔',
                            'Order delicious food instantly',
                            isSmallScreen,
                          ),
                          _buildPowerCard(
                            '⚡',
                            'Lightning-fast delivery to your location',
                            isSmallScreen,
                          ),
                          _buildPowerCard(
                            '💰',
                            'Exclusive student discounts & offers',
                            isSmallScreen,
                          ),
                          _buildPowerCard(
                            '📱',
                            'Track your order in real-time',
                            isSmallScreen,
                          ),
                          _buildPowerCard(
                            '⭐',
                            'Rate and review your favorite meals',
                            isSmallScreen,
                          ),
                        ],
                      ),

                      SizedBox(height: isSmallScreen ? 30 : 40),

                      Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16 : 32,
                        ),
                        padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(
                              0xFFFF6B6B,
                            ).withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Column(
                              children: [
                                Icon(
                                  Icons.email,
                                  color: const Color(0xFFFF6B6B),
                                  size: isSmallScreen ? 28 : 32,
                                ),
                                SizedBox(height: isSmallScreen ? 10 : 12),
                                Text(
                                  'Found the signature? Let me know!',
                                  style: TextStyle(
                                    color: const Color(0xFF2D3436),
                                    fontSize: isSmallScreen ? 16 : 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: isSmallScreen ? 8 : 10),
                                GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Email copied! Send your message to gabrialdeora003@gmail.com',
                                        ),
                                        backgroundColor: const Color(
                                          0xFFFF6B6B,
                                        ),
                                        duration: const Duration(seconds: 3),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: isSmallScreen ? 12 : 16,
                                      vertical: isSmallScreen ? 8 : 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF8F9FA),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(
                                          0xFFFF6B6B,
                                        ).withValues(alpha: 0.5),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.copy,
                                          size: isSmallScreen ? 16 : 18,
                                          color: const Color(0xFFFF6B6B),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'gabrialdeora003@gmail.com',
                                          style: TextStyle(
                                            color: const Color(0xFF2D3436),
                                            fontSize: isSmallScreen ? 13 : 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: isSmallScreen ? 8 : 10),
                                Text(
                                  'I found your signature!',
                                  style: TextStyle(
                                    color: const Color(0xFF636E72),
                                    fontSize: isSmallScreen ? 12 : 13,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                            Positioned(
                              right: -20,
                              top: -25,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF6B6B),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF6B6B,
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.auto_awesome,
                                      color: Colors.white,
                                      size: isSmallScreen ? 12 : 14,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'SURPRISE!',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: isSmallScreen ? 10 : 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: isSmallScreen ? 40 : 60),

                      ElevatedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Go Back'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6B6B),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 20 : 24,
                            vertical: isSmallScreen ? 10 : 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPowerCard(String emoji, String text, bool isSmallScreen) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(emoji, style: TextStyle(fontSize: isSmallScreen ? 18 : 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: const Color(0xFF2D3436),
                fontSize: isSmallScreen ? 13 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
