import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../data/model/car_model.dart';
import 'car_detail_page.dart';

class RentCarPage extends StatelessWidget {
  const RentCarPage({super.key});

  static const Color kPrimaryDark = Color(0xFF221F1E);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: kPrimaryDark,
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1200),
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(horizontal: 24),
              alignment: Alignment.centerLeft,
              child: const Text(
                "Available Cars",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18, // Clean header size
                    letterSpacing: -0.2
                ),
              ),
            ),
          ),
        ),

        Expanded(
          child: Container(
            color: const Color(0xFFF8F9FA),
            alignment: Alignment.topCenter, // Content starts from the top
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('owners')
                    .where('isAvailable', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.orangeAccent),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(
                      child: Text(
                        "No cars available right now",
                        style: TextStyle(color: Colors.black54, fontSize: 16),
                      ),
                    );
                  }

                  final cars = snapshot.data!.docs;

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      double gridWidth = constraints.maxWidth;

                      int crossAxisCount;
                      double childAspectRatio;

                      if (gridWidth < 600) {
                        crossAxisCount = 2;
                        childAspectRatio = 0.75;
                      } else if (gridWidth < 1000) {
                        crossAxisCount = 3;
                        childAspectRatio = 1.0;
                      } else {
                        crossAxisCount = 4;
                        childAspectRatio = 1.15;
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          childAspectRatio: childAspectRatio,
                          crossAxisSpacing: 24,
                          mainAxisSpacing: 24,
                        ),
                        itemCount: cars.length,
                        physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            DocumentSnapshot doc = cars[index];
                            var carData = doc.data() as Map<String, dynamic>;

                            CarModel currentCar = CarModel(
                              model: carData['carModel'] ?? 'Unknown',
                              pricePerDay: (carData['pricePerDay'] as num?)?.toDouble() ?? 0.0,
                              fuelCapacity: (carData['fuelCapacity'] as num?)?.toDouble() ?? 0.0,
                              image: carData['carImage'] ?? '',
                              ownerId: doc.id,
                            );

                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => CarDetailPage(
                                      car: currentCar,
                                      pickupLocation: const LatLng(27.7172, 85.3240),
                                      pickupAddress: "Kathmandu, Nepal",
                                    ),
                                  ),
                                );
                              },
                              child: _buildCarCard(
                                model: currentCar.model,
                                price: currentCar.pricePerDay.toString(),
                                imageUrl: currentCar.image,
                              ),
                            );
                          }
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }


  Widget _buildCarCard({required String model, required String price, String? imageUrl}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.04)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF1F2F3),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              width: double.infinity,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.grey, strokeWidth: 2),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.error_outline_rounded,
                    size: 40,
                    color: Colors.grey,
                  ),
                )
                    : const Center(
                  child: Icon(Icons.directions_car_filled_rounded, size: 45, color: Colors.grey),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  model,
                  style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: Color(0xFF221F1E), // Dark color
                      letterSpacing: -0.2
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                Text(
                    "Rs. $price / day",
                    style: const TextStyle(
                      color: Colors.orangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    )
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}