import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carrentalapp/auth/auth_provider.dart';

class OwnerEarningContent extends StatelessWidget {
  const OwnerEarningContent({super.key});

  static const Color kPrimaryDark = Color(0xFF221F1E);
  static const Color kAccentGold = Color(0xFFFFA24D);
  static const Color kBgLight = Color(0xFFF5F5F7);

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final ownerId = authProvider.user?.uid;

    if (ownerId == null) {
      return const Scaffold(body: Center(child: Text("User not authenticated")));
    }

    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        title: const Text("My Earnings", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.orange,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('ownerId', isEqualTo: ownerId)
            .where('status', isEqualTo: 'completed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kAccentGold));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          double total = 0;
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            var priceValue = data['price'];
            if (priceValue != null) {
              total += double.tryParse(priceValue.toString()) ?? 0.0;
            }
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: const BoxDecoration(
                  color: kPrimaryDark,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    const Text("Total Revenue", style: TextStyle(color: Colors.white60, fontSize: 14, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    Text(
                      "Rs. ${total.toStringAsFixed(2)}",
                      style: const TextStyle(color: kAccentGold, fontSize: 38, fontWeight: FontWeight.bold, letterSpacing: -0.5),
                    ),
                  ],
                ),
              ),

              const Padding(
                padding: EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Text("Payout History", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryDark)),
              ),

              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: snapshot.data!.docs.length,
                  physics: const BouncingScrollPhysics(),
                  itemBuilder: (context, index) {
                    var data = snapshot.data!.docs[index].data() as Map<String, dynamic>;

                    var rawPrice = data['price'] ?? 0;
                    double displayPrice = double.tryParse(rawPrice.toString()) ?? 0.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                        ),
                        title: Text(
                            data['carModel'] ?? "Completed Ride",
                            style: const TextStyle(fontWeight: FontWeight.bold, color: kPrimaryDark)
                        ),
                        subtitle: Text(
                            "Paid via ${data['paymentMethod'] ?? 'Cash'}",
                            style: const TextStyle(color: Colors.grey, fontSize: 12)
                        ),
                        trailing: Text(
                            "Rs. ${displayPrice.toStringAsFixed(0)}",
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: kPrimaryDark)
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.account_balance_wallet_outlined, size: 70, color: Colors.grey),
          SizedBox(height: 16),
          Text("No earnings yet", style: TextStyle(color: kPrimaryDark, fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 4),
          Text("Your completed trip revenue will show up here.", style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}