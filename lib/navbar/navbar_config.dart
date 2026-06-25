import 'package:flutter/material.dart';
import 'package:carrentalapp/screens/passenger/car_rent_page.dart';
import '../screens/owner/car_management.dart';
import '../screens/owner/earning_page.dart';
import '../screens/owner/owner_home_content.dart';
import '../screens/owner/owner_profile.dart';
import '../screens/passenger/passenger_home_page.dart';
import '../screens/passenger/profile.dart';
import '../screens/passenger/history.dart';


enum UserRole { passenger, owner }

class NavItem {
  final String label;
  final IconData icon;
  final Widget screen;
  const NavItem({required this.label, required this.icon, required this.screen});
}

const List<NavItem> passengerDestinations = [
  NavItem(label: 'Home', icon: Icons.home, screen: PassengerHomeContent()),
  NavItem(label: "Rentals", icon: Icons.calendar_month_rounded, screen: RentCarPage()),
  NavItem(label: 'History', icon: Icons.history_outlined, screen: HistoryPage()),
  NavItem(label: 'Profile', icon: Icons.person_outline, screen: PassengerProfileContent()),
];

const List<NavItem> ownerDestinations = [
  NavItem(label: 'Home', icon: Icons.home_outlined, screen: OwnerHomeContent()),
  NavItem(label: 'Car', icon: Icons.directions_car, screen: CarManagementContent()),
  NavItem(label: 'Earning', icon: Icons.monetization_on_outlined, screen: OwnerEarningContent()),
  NavItem(label: 'Profile', icon: Icons.person_outline, screen: OwnerProfileContent()),
];

List<NavItem> getDestinationsForRole(UserRole role) {
  return role == UserRole.owner ? ownerDestinations : passengerDestinations;
}


/*List<NavItem> getDestinationsForRole(UserRole role) {
  switch (role) {
    case UserRole.passenger:
      return passengerDestinations;
    case UserRole.driver:
      return driverDestinations;
  }
}
*/