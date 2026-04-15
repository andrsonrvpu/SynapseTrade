import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/synapse_theme.dart';
import 'dashboard_screen.dart';
import 'analyze_screen.dart';
import 'history_screen.dart';
import 'broker_settings_screen.dart';
import 'profile_screen.dart';

/// Main app shell — Floating glassmorphic bottom navigation dock.
/// 5 tabs: Dashboard, Analysis, History, Broker Settings, Profile.
/// Matches Stitch "The Floating Dock" design spec.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    AnalyzeScreen(),
    HistoryScreen(),
    BrokerSettingsScreen(),
    ProfileScreen(),
  ];

  final List<_NavItem> _navItems = const [
    _NavItem(Icons.grid_view, 'Dashboard'),
    _NavItem(Icons.query_stats, 'Analysis'),
    _NavItem(Icons.history, 'History'),
    _NavItem(Icons.settings, 'Broker'),
    _NavItem(Icons.person, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SynapseTheme.surface,
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      extendBody: true,
      bottomNavigationBar: _buildFloatingNavBar(),
    );
  }

  Widget _buildFloatingNavBar() {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A2A).withOpacity(0.5),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.8),
                  blurRadius: 32,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_navItems.length, (i) {
                final isActive = _currentIndex == i;
                return GestureDetector(
                  onTap: () => setState(() => _currentIndex = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? SynapseTheme.primaryContainer.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: isActive
                          ? [
                              BoxShadow(
                                color: SynapseTheme.primaryContainer.withOpacity(0.4),
                                blurRadius: 15,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      _navItems[i].icon,
                      color: isActive
                          ? SynapseTheme.primaryContainer
                          : Colors.grey[600],
                      size: 24,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
