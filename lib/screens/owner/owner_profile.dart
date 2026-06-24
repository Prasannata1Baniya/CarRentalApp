import 'package:carrentalapp/screens/owner/earning_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carrentalapp/auth/auth_provider.dart';
import '../auth_page/login_page.dart';

class OwnerProfileContent extends StatelessWidget {
  const OwnerProfileContent({super.key});

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
                    const Padding(
                      padding: EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
                      child: Text(
                        "Owner Profile",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: kBrandDark,
                          letterSpacing: -0.6,
                        ),
                      ),
                    ),

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
                              child: Icon(Icons.business_center_rounded, size: 40, color: kBrandDark),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            user?.displayName ?? "Owner Name",
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: kBrandDark, letterSpacing: -0.5),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            user?.email ?? "owner@example.com",
                            style: const TextStyle(color: kTextMuted, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),

                    const Divider(thickness: 1, height: 1, indent: 24, endIndent: 24),

                    // --- OPTIONS LIST ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      child: Column(
                        children: [
                          _buildProfileTile(
                            icon: Icons.directions_car_rounded,
                            title: "My Fleet",
                            subtitle: "Manage your listed vehicles",
                            onTap: () {},
                          ),
                          _buildProfileTile(
                            icon: Icons.analytics_rounded,
                            title: "Earnings Report",
                            subtitle: "View your revenue statistics",
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_)=>OwnerEarningContent()));
                            },
                          ),
                          _buildProfileTile(
                            icon: Icons.settings_rounded,
                            title: "App Settings",
                            subtitle: "Configure account preferences",
                            onTap: () {},
                          ),
                        ],
                      ),
                    ),

                    const Divider(thickness: 1, height: 1, indent: 24, endIndent: 24),
                    const SizedBox(height: 24),

                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.red.shade300, width: 1.5),
                            foregroundColor: Colors.red.shade700,
                            backgroundColor: Colors.red.shade50.withValues(alpha: 0.3),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _showLogoutDialog(context, authProvider),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.logout_rounded, size: 18),
                              SizedBox(width: 8),
                              Text("Logout Account", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    const Text("DriveX - Owner v1.0", style: TextStyle(color: kTextMuted, fontSize: 11, fontWeight: FontWeight.w500)),
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
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, color: kBrandDark, fontSize: 15)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: kTextMuted, fontWeight: FontWeight.w400)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: kTextMuted),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProviderMethod auth) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Column(
          children: [
            Icon(Icons.logout_rounded, color: Colors.redAccent, size: 40),
            SizedBox(height: 10),
            Text("Sign Out", style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: kBrandDark)),
          ],
        ),
        content: const Text(
          "Are you sure you want to log out of DriveX?",
          textAlign: TextAlign.center,
          style: TextStyle(color: kTextMuted, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CANCEL", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
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