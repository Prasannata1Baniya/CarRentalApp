import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carrentalapp/auth/auth_provider.dart';
import 'package:carrentalapp/screens/passenger/car_rent_page.dart';
import '../auth_page/login_page.dart';

class PassengerProfileContent extends StatelessWidget {
  const PassengerProfileContent({super.key});

  // Synced with your Premium Brand Palette
  static const Color kBrandDark = Color(0xFF221F1E);
  static const Color kAccentOrange = Colors.orange;
  static const Color kBgSurface = Color(0xFFF5F5F7);
  static const Color kTextMuted = Color(0xFF7A7A7A);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: kBgSurface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 24.0),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: kBrandDark.withValues(alpha: 0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // --- INTERNAL CONTAINER HEADER TITLE ---
                    Padding(
                      padding: const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
                      child: Text(
                        "My Profile",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: kBrandDark,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),

                    // 1. USER HERO PROFILE DETAILS
                    Container(
                      padding: const EdgeInsets.only(top: 16, bottom: 24, left: 20, right: 20),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: kAccentOrange.withValues(alpha: 0.2), width: 4),
                            ),
                            child: const CircleAvatar(
                              radius: 46,
                              backgroundColor: kBgSurface,
                              child: Icon(Icons.person_rounded, size: 48, color: kBrandDark),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user?.displayName ?? "Passenger Name",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kBrandDark, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? "passenger@example.com",
                            style: const TextStyle(color: kTextMuted, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                    const Divider(thickness: 1, height: 1, indent: 24, endIndent: 24),

                    // 2. PASSENGER MENU TILES
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      child: Column(
                        children: [
                          _buildProfileTile(
                            context: context,
                            icon: Icons.history_rounded,
                            title: "My Ride History",
                            subtitle: "View your past trips and receipts",
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => RentCarPage()));
                            },
                          ),
                          _buildProfileTile(
                            context: context,
                            icon: Icons.account_balance_wallet_rounded,
                            title: "Payment Methods",
                            subtitle: "Manage your eSewa and Cash options",
                            onTap: () {},
                          ),
                          _buildProfileTile(
                            context: context,
                            icon: Icons.notifications_none_rounded,
                            title: "Notifications",
                            subtitle: "Manage your alerts and news",
                            onTap: () {},
                          ),
                          _buildProfileTile(
                            context: context,
                            icon: Icons.help_outline_rounded,
                            title: "Help & Support",
                            subtitle: "Get help with your rides",
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),

                    const Divider(thickness: 1, height: 1, indent: 24, endIndent: 24),
                    const SizedBox(height: 24),

                    // 3. LOGOUT CTA FIELD
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red.shade300, width: 1.5),
                          foregroundColor: Colors.red.shade700,
                          backgroundColor: Colors.red.shade50.withValues(alpha: 0.3),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ).buildOutlinedButton(
                          onPressed: () => _handleLogout(context, authProvider),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded, size: 18),
                              SizedBox(width: 8),
                              Text("Logout Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.2)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text("DriverX - Passenger v1.0", style: TextStyle(color: kTextMuted, fontSize: 11, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: kAccentOrange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: kAccentOrange, size: 22),
      ),
      title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, color: kBrandDark, fontSize: 15)
      ),
      subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: kTextMuted, fontWeight: FontWeight.w400)
      ),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kTextMuted),
    );
  }

  // --- LOGOUT DIALOG ---
  void _handleLogout(BuildContext context, AuthProviderMethod auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Column(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 40),
            SizedBox(height: 10),
            Text("Sign Out", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: kBrandDark, letterSpacing: -0.5)),
          ],
        ),
        content: const Text(
          "Are you sure you want to log out of DriveX?",
          textAlign: TextAlign.center,
          style: TextStyle(color: kTextMuted, fontSize: 14, fontWeight: FontWeight.w500),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(color: kTextMuted, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            ),
            onPressed: () async {
              await auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                      (route) => false,
                );
              }
            },
            child: const Text("LOGOUT", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

extension on ButtonStyle {
  Widget buildOutlinedButton({required VoidCallback onPressed, required Widget child}) {
    return OutlinedButton(style: this, onPressed: onPressed, child: child);
  }
}