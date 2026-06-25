import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:carrentalapp/auth/auth_provider.dart';

import 'active_ride.dart';
import 'owner_map_page.dart';

class OwnerHomeContent extends StatelessWidget {
  const OwnerHomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProviderMethod>(context);
    final ownerId = authProvider.user?.uid;

    if (ownerId == null) return const Center(child: Text("Not logged in"));

    return Scaffold(
      appBar: AppBar(
        title: const Text("New Rent Requests"),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .where('ownerId', isEqualTo: ownerId)
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrint("ERROR: ${snapshot.error}");
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildNoRequests();
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            padding: const EdgeInsets.all(12),
            itemBuilder: (context, index) {
              var doc = snapshot.data!.docs[index];
              var data = doc.data() as Map<String, dynamic>;
              return _buildRequestCard(context, doc.id, data, ownerId);
            },
          );
        },
      ),
    );
  }


  /*Widget _buildRequestCard(BuildContext context, String docId, Map<String, dynamic> data, String ownerId) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),

      elevation: 5,

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),

      child: Padding(

        padding: const EdgeInsets.all(16.0),

        child: Column(

          children: [

            Row(

              children: [

                Expanded(

                  child: Column(

                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [

                      Text(data['carModel'] ?? "Unknown Car",

                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),

                      Text("Payment: ${data['paymentMethod'] ?? 'N/A'}",

                          style: TextStyle(

                              color: data['paymentStatus'] == 'paid' ? Colors.green : Colors.red,

                              fontWeight: FontWeight.bold, fontSize: 12)),

                    ],

                  ),

                ),

                Text("Rs. ${data['totalPrice'] ?? 0}",

                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),

              ],

            ),

            const Divider(height: 30),

            Row(
              children: [

                const Icon(Icons.location_on, color: Colors.red),

                const SizedBox(width: 10),
                const Expanded(child: Text("Pickup: Kathmandu (Click to see on Map)", style: TextStyle(color: Colors.black54))),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerMapPage(

                      pickupLocation: LatLng(data['pickupLat'], data['pickupLng']),

                      bookingId: docId,

                    )));

                  },

                  icon: const Icon(Icons.map, size: 18),
                  label: const Text("VIEW MAP"),

                )

              ],

            ),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () => _acceptRide(context, docId, ownerId, data),
              child: const Text("ACCEPT RIDE"),

            ),
          ],
        ),
      ),
    );

  }*/

  Widget _buildRequestCard(BuildContext context, String docId, Map<String, dynamic> data, String ownerId) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Model & Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['carModel'] ?? "Unknown",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF221F1E))),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: (data['paymentStatus'] == 'paid' ? Colors.green.shade50 : Colors.red.shade50),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(data['paymentMethod']?.toUpperCase() ?? "CASH",
                        style: TextStyle(color: data['paymentStatus'] == 'paid' ? Colors.green : Colors.red, fontWeight: FontWeight.bold, fontSize: 10)),
                  ),
                ],
              ),
              Text("Rs. ${data['totalPrice'] ?? 0}",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.orange)),
            ],
          ),

          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),

          // Location & Map Button
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.location_on, color: Colors.orange, size: 22),
              ),
              const SizedBox(width: 15),
              const Expanded(child: Text("Pickup Location", style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF221F1E)))),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => OwnerMapPage(
                    pickupLocation: LatLng(data['pickupLat'], data['pickupLng']),
                    bookingId: docId,
                  )));
                },
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                icon: const Icon(Icons.map, size: 16),
                label: const Text("MAP"),
              )
            ],
          ),

          const SizedBox(height: 20),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () => _acceptRide(context, docId, ownerId, data),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF221F1E),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text("ACCEPT RIDE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1.2)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _acceptRide(BuildContext context, String docId, String ownerId, Map<String, dynamic> data) async {
    try {
      final updateData = {
        'status': 'accepted',
        'ownerId': ownerId,
        'acceptedAt': FieldValue.serverTimestamp(),
      };

      await FirebaseFirestore.instance.collection('bookings').doc(docId).update(updateData);

      data.addAll(updateData);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ride Accepted!"), backgroundColor: Colors.green),
        );

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ActiveRideContent(
              bookingId: docId,
              bookingData: data,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to accept ride: ${e.toString()}"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildNoRequests() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Searching for nearby Customers...", style: TextStyle(fontSize: 18, color: Colors.grey)),
        ],
      ),
    );
  }
}

