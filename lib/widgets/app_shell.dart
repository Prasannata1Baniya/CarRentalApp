import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../navbar/navbar_config.dart';

class AppShell extends StatefulWidget {
  final UserRole userRole;
  final int initialIndex;

  const AppShell({
    super.key,
    required this.userRole,
    this.initialIndex = 0,
  });

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late int _currentIndex;
  late List<NavItem> _destinations;

  static const Color kBrandDarkBackground = Color(0xFF221F1E);
  static const Color kAccentOrangeHighlight = Color(0xFFFFA24D);
  static const Color kMutedUnselected = Color(0xFF9E9E9E);

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _destinations = getDestinationsForRole(widget.userRole);
    _setupPushNotifications();
  }

  void _setupPushNotifications() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    String? token = await messaging.getToken();
    if (token != null) {
      String? uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).update({
          'fcmToken': token,
        });
      }
    }

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.notification?.body ?? 'New Update!'),
            backgroundColor: kAccentOrangeHighlight,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 950;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
          // --- UPGRADED PREMIUM GLOBAL NAVIGATION RAIL ---
            Theme(
              data: ThemeData(
                navigationRailTheme: const NavigationRailThemeData(
                  indicatorColor: Colors.transparent,
                ),
              ),
              child: NavigationRail(
                backgroundColor: kBrandDarkBackground,
                selectedIndex: _currentIndex,
                onDestinationSelected: (i) => setState(() => _currentIndex = i),
                labelType: NavigationRailLabelType.all,
                unselectedIconTheme: const IconThemeData(color: kMutedUnselected, size: 22),
                selectedIconTheme: const IconThemeData(color: kAccentOrangeHighlight, size: 24),
                unselectedLabelTextStyle: const TextStyle(
                  color: kMutedUnselected,
                  fontSize: 11,
                  fontWeight: FontWeight.normal,
                  letterSpacing: 0.2,
                ),
                selectedLabelTextStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                leading: Padding(
                  padding: const EdgeInsets.only(top: 28.0, bottom: 40.0),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04), // Modern optimized syntax
                      shape: BoxShape.circle,
                    ),
                    child: Image.asset(
                      "assets/images/driveX_logo.png",
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.directions_car_filled_rounded,
                        color: kAccentOrangeHighlight,
                        size: 24,
                      ),
                    ),
                  ),
                ),
                destinations: _destinations.map((item) => NavigationRailDestination(
                  icon: Icon(item.icon),
                  selectedIcon: Icon(item.icon, color: kAccentOrangeHighlight),
                  label: Text(item.label),
                )).toList(),
              ),
            ),

          // --- SYSTEM COMPONENT SCREEN WORKSPACE CANVAS ---
          Expanded(
            child: IndexedStack(
              index: _currentIndex,
              children: _destinations.map((item) => item.screen).toList(),
            ),
          ),
        ],
      ),

      bottomNavigationBar: isWide
          ? null
          : Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08), // Modern optimized syntax
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (i) => setState(() => _currentIndex = i),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: kAccentOrangeHighlight,
          unselectedItemColor: Colors.grey.shade400,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.1),
          items: _destinations.map((item) => BottomNavigationBarItem(
            icon: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Icon(item.icon, size: 20),
            ),
            activeIcon: Padding(
              padding: const EdgeInsets.only(bottom: 4.0),
              child: Icon(item.icon, size: 22),
            ),
            label: item.label,
          )).toList(),
        ),
      ),
    );
  }
}