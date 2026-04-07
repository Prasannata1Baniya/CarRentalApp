import 'package:carrentalapp/navbar/navbar_config.dart';
import 'package:flutter/material.dart';
import 'package:carrentalapp/screens/passenger/rides_page.dart';
import '../screens/owner/car_management.dart';
import '../screens/owner/earning_page.dart';
import '../screens/owner/owner_home_content.dart';
import '../screens/owner/owner_profile.dart';
import '../screens/passenger/passenger_home_page.dart';
import '../screens/passenger/profile.dart';
import '../screens/passenger/ride_history.dart';

class NavItem {
  final String label;
  final IconData icon;
  final Widget screen;
  const NavItem({required this.label, required this.icon, required this.screen});
}

class NavigationShell extends StatefulWidget {
  final UserRole userRole;
  final int initialIndex;

  const NavigationShell({
    super.key,
    required this.userRole,
    this.initialIndex = 0,
  });


  @override
  State<NavigationShell> createState() => _NavigationShellState();
}

class _NavigationShellState extends State<NavigationShell> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }


  //Passenger Menu
  final List<NavItem> _passengerDestinations = [
    const NavItem(label: 'Home', icon: Icons.home, screen: PassengerHomeContent()),
    const NavItem(label: "Booking", icon: Icons.book_online_outlined, screen: MyRidesPage()),
    const NavItem(label: 'History', icon: Icons.history_outlined, screen: RideHistoryContent()),
    const NavItem(label: 'Profile', icon: Icons.person_outline, screen: PassengerProfileContent()),
  ];

  //Driver Menu
  final List<NavItem> _ownerDestinations = [
    const NavItem(label: 'Home', icon: Icons.home_outlined, screen: OwnerHomeContent()),
    const NavItem(label: 'Car', icon: Icons.directions_car, screen: CarManagementContent()),
    const NavItem(label: 'Earning', icon: Icons.monetization_on_outlined, screen: OwnerEarningContent()),
    const NavItem(label: 'Profile', icon: Icons.person_outline, screen: OwnerProfileContent()),
  ];

  @override
  Widget build(BuildContext context) {
    // Select the correct list based on user role
    final List<NavItem> activeDestinations =
    widget.userRole == UserRole.owner ? _ownerDestinations : _passengerDestinations;

    final bool isWide = MediaQuery.of(context).size.width > 600;

    return Scaffold(
      body: Row(
        children: [
          // Sidebar for Web/Tablet
          if (isWide)
            NavigationRail(
              backgroundColor: Colors.black,
              selectedIndex: _currentIndex,
              onDestinationSelected: (i) => setState(() => _currentIndex = i),
              labelType: NavigationRailLabelType.all,
              leading: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Image.asset("assets/images/SajiloRide_logo.png", height: 50),
              ),
              destinations: activeDestinations.map((item) {
                return NavigationRailDestination(
                  icon: Icon(item.icon,color: Colors.white,),
                  label: Text(item.label,selectionColor: Colors.white,),
                );
              }).toList(),
            ),

          // Main Content Area
          Expanded(
            child: activeDestinations[_currentIndex].screen,
          ),
        ],
      ),

      // Bottom NAVBAR for Mobile
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
        backgroundColor: Colors.black,

        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: widget.userRole == UserRole.owner ? Colors.orange : Colors.blue,
        items: activeDestinations.map((item) {
          return BottomNavigationBarItem(
            icon: Icon(item.icon,color: Colors.white,),
            label: item.label,backgroundColor: Colors.white
          );
        }).toList(),
      ),
    );
  }
}
