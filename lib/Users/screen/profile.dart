import 'package:flutter/material.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_theme.dart';
import '../../../utils/utils.dart';

import 'help_support.dart';
import 'order_history.dart';
import 'wishlist.dart';
import '../../../services/notification_service.dart';

class ProfileScreen extends StatefulWidget {
  final bool showBackButton;

  const ProfileScreen({super.key, this.showBackButton = true});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userData;
  bool isLoading = true;
  bool isGuestMode = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    debugPrint('🔄 Starting profile load...');
    setState(() {
      isLoading = true;
      isGuestMode = false;
      errorMessage = null;
    });

    try {
      // Get token from AuthService
      final token = await AuthService.getToken();
      debugPrint(
        '🔑 Retrieved token: ${token != null ? "Found" : "Not found"}',
      );

      if (token == null || token.isEmpty) {
        debugPrint('❌ No token available');
        setState(() {
          isGuestMode = true;
          isLoading = false;
        });
        return;
      }

      debugPrint('📡 Calling API service...');

      final response = await ApiService.getUserProfile(token);

      debugPrint('📊 API response: $response');

      if (response['success'] == true) {
        debugPrint('✅ Profile loaded successfully');
        setState(() {
          userData = response['data'];
          isLoading = false;
        });
      } else {
        debugPrint('❌ Profile load failed: ${response['error']}');
        setState(() {
          errorMessage = response['error'] ?? 'Failed to load profile';
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('💥 Profile load exception: $e');
      setState(() {
        errorMessage = 'Network error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F9FA),
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: _buildAppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.textLight),
              const SizedBox(height: 16),
              Text(
                errorMessage!,
                style: TextStyle(fontSize: 15, color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadUserProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (isGuestMode) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: _buildAppBar(),
        body: _buildGuestView(),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildMenuItems(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0,
      title: const Text(
        'Profile',
        style: TextStyle(
          color: Color(0xFF2D3436),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      leading: widget.showBackButton
          ? IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            )
          : null,
      automaticallyImplyLeading: widget.showBackButton,
      actions: isGuestMode
          ? null
          : [
              IconButton(
                onPressed: _showEditProfileDialog,
                icon: const Icon(Icons.edit, color: AppColors.textPrimary),
              ),
            ],
    );
  }

  Widget _buildGuestView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: AppColors.primary.withValues(alpha: 0.12),
              child: const Icon(
                Icons.person_outline,
                size: 40,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'You are browsing as guest',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3436),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Login or create an account to load your profile and access protected backend features.',
              style: TextStyle(
                fontSize: 15,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('Login'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                child: const Text('Sign Up'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 16, bottom: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          _buildNameInitialsAvatar(),
          const SizedBox(height: 14),
          Text(
            userData?['name'] ?? userData?['fullName'] ?? 'Unknown User',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3436),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            userData?['email'] ?? 'No email',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildNameInitialsAvatar() {
    final name = userData?['name'] ?? userData?['fullName'] ?? 'Unknown User';
    final initials = _getInitials(name);

    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.primary, width: 3),
      ),
      child: CircleAvatar(
        radius: 48,
        backgroundColor: AppColors.primary,
        child: Text(
          initials,
          style: const TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty || name == 'Unknown User') return '?';

    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  Widget _buildMenuItems() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _menuItem(
            icon: Icons.history,
            title: 'Order History',
            subtitle: 'View your past orders',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const OrderHistoryScreen(showBackButton: true),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _menuItem(
            icon: Icons.favorite,
            title: 'Wishlist',
            subtitle: 'Your favorite products',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const WishlistScreen(showBackButton: true),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _menuItem(
            icon: Icons.help,
            title: 'Help & Support',
            subtitle: 'Get help and contact support',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      const HelpSupportScreen(showBackButton: true),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          _menuItem(
            icon: Icons.notifications,
            title: 'Test Notifications',
            subtitle: 'Test FCM token registration',
            onTap: () {
              NotificationService.testTokenRegistration();
            },
          ),
          const SizedBox(height: 10),
          _menuItem(
            icon: Icons.logout,
            title: 'Logout',
            subtitle: 'Sign out of your account',
            isDestructive: true,
            onTap: _showLogoutDialog,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppColors.error : AppColors.primary,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppColors.error : AppColors.textPrimary,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: AppColors.textLight,
        ),
        onTap: onTap,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              Navigator.pop(context);
              await AuthService.logout();
              navigator.pushNamedAndRemoveUntil('/login', (route) => false);
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(
      text: userData?['name'] ?? userData?['fullName'] ?? '',
    );
    final emailController = TextEditingController(
      text: userData?['email'] ?? '',
    );
    final phoneController = TextEditingController(
      text: userData?['phone'] ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(labelText: 'Phone'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (userData != null) {
                setState(() {
                  userData!['name'] = nameController.text.trim();
                  userData!['email'] = emailController.text.trim();
                  userData!['phone'] = phoneController.text.trim();
                });
              }
              Navigator.pop(context);

              Helpers.showSuccessSnackBar(
                context,
                'Profile updated successfully!',
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
