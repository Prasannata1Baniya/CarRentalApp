import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  static const Color kPrimaryDark = Color(0xFF221F1E);
  static const Color kAccentGold = Color(0xFFFFA24D);
  static const Color kBgLight = Color(0xFFF5F5F7);

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    debugPrint("🔍 DEBUG: Current User ID is: $userId");

    if (userId == null) {
      return const Scaffold(body: Center(child: Text("Please log in to view history")));
    }

    return Scaffold(
      backgroundColor: kBgLight,
      appBar: AppBar(
        title: const Text("Rent History", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: kPrimaryDark,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('userId', isEqualTo: userId)
            .orderBy('createdAt', descending: false)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint("🚨 FIRESTORE INDEX ERROR: ${snapshot.error}");
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: Text(
                  "Loading history...\n\n"
                      "👉 Check your IDE console terminal for the automatic link to build the index!",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: kAccentGold));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          final bookings = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: bookings.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              var data = bookings[index].data() as Map<String, dynamic>;

              String rawStatus = data['status'] ?? 'pending';
              bool isCompleted = rawStatus.toLowerCase() == 'completed';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    children: [
                      Container(
                          width: 6,
                          height: 85,
                          color: isCompleted ? Colors.green : kAccentGold
                      ),
                      Expanded(
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          title: Text(
                            data['carModel'] ?? 'Rental Service',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: kPrimaryDark),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isCompleted ? Colors.green.withValues(alpha: 0.1) : kAccentGold.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    rawStatus.toUpperCase(),
                                    style: TextStyle(
                                        color: isCompleted ? Colors.green : Colors.orange.shade800,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
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
          Icon(Icons.history_rounded, size: 65, color: Colors.grey),
          SizedBox(height: 16),
          Text("No booking history", style: TextStyle(color: kPrimaryDark, fontWeight: FontWeight.bold, fontSize: 16)),
          SizedBox(height: 4),
          Text("Your rented cars will appear here.", style: TextStyle(color: Colors.grey, fontSize: 13)),
        ],
      ),
    );
  }
}