import 'package:flutter/material.dart';

import '../state/app_state.dart';
import 'cart.dart';
import 'home.dart';
import 'order_history.dart';
import 'profile.dart';
import 'wishlist.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  void _selectTab(int index) {
    if (_currentIndex == index) {
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    return AnimatedBuilder(
      animation: appState,
      builder: (context, _) {
        final pages = <Widget>[
          HomeScreen(
            onOpenCart: () => _selectTab(3),
            onOpenProfile: () => _selectTab(4),
          ),
          const WishlistScreen(),
          const OrderHistoryScreen(),
          CartScreen(showBackButton: false, onBrowseMenu: () => _selectTab(0)),
          const ProfileScreen(showBackButton: false),
        ];

        return Scaffold(
          body: IndexedStack(index: _currentIndex, children: pages),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: _selectTab,
            height: 70,
            destinations: [
              const NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: 'Home',
              ),
              const NavigationDestination(
                icon: Icon(Icons.favorite_border),
                selectedIcon: Icon(Icons.favorite),
                label: 'Wishlist',
              ),
              const NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Orders',
              ),
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: appState.cartItemCount > 0,
                  label: Text('${appState.cartItemCount}'),
                  child: const Icon(Icons.shopping_cart_outlined),
                ),
                selectedIcon: Badge(
                  isLabelVisible: appState.cartItemCount > 0,
                  label: Text('${appState.cartItemCount}'),
                  child: const Icon(Icons.shopping_cart),
                ),
                label: 'Cart',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          ),
        );
      },
    );
  }
}
