import 'package:flutter/material.dart';
import 'package:carrentalapp/data/model/car_model.dart';
import '../../navbar/navbar_config.dart';
import '../../widgets/app_shell.dart';

class BookingConfirmContent extends StatelessWidget {
  final CarModel car;

  const BookingConfirmContent({super.key, required this.car});

  // DriveX Premium Color Palette
  static const Color kPrimaryDark = Color(0xFF221F1E);
  static const Color kAccentGold = Color(0xFFFFA24D);
  static const Color kBgLight = Color(0xFFF5F5F7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgLight,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // --- 1. SUCCESS ICON ---
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check_rounded, size: 55, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- 2. SUCCESS TEXT ---
                  const Text(
                    "Booking Confirmed!",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: kPrimaryDark, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Your ride with ${car.model} has been successfully booked.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 15, color: Colors.grey, height: 1.4),
                  ),
                  const SizedBox(height: 35),

                  // --- 3. SUMMARY CARD ---
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow("Car Model", car.model),
                        const Divider(height: 24, color: kBgLight),
                        // FIXED: Changed display from "/hr" to "/day" to match your system
                        _buildSummaryRow("Price", "Rs. ${car.pricePerDay}/day"),
                        const Divider(height: 24, color: kBgLight),
                        _buildSummaryRow("Status", "Reserved", isStatus: true),
                      ],
                    ),
                  ),
                  const SizedBox(height: 45),

                  // --- 4. BACK TO HOME BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimaryDark,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AppShell(userRole: UserRole.passenger, initialIndex: 0),
                          ),
                              (route) => false,
                        );
                      },
                      child: const Text(
                          "Back to Home",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // --- 5. VIEW RIDES BUTTON ---
                  TextButton(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AppShell(userRole: UserRole.passenger, initialIndex: 1),
                        ),
                            (route) => false,
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    ),
                    child: const Text(
                        "View My Rides",
                        style: TextStyle(color: kAccentGold, fontSize: 15, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String title, String value, {bool isStatus = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 15, color: Colors.grey, fontWeight: FontWeight.w500)),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isStatus ? Colors.green : kPrimaryDark,
          ),
        ),
      ],
    );
  }
}