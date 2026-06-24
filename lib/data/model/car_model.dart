import 'package:cloud_firestore/cloud_firestore.dart';

class CarModel {
  final String model;
  final double pricePerDay;
  final double fuelCapacity;
  final String image;
  final String ownerId;

  CarModel({
    required this.model, required this.pricePerDay, required this.fuelCapacity, required this.image, required this.ownerId,
  });

  factory CarModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CarModel(
      model: data['carModel'] ?? 'Unknown Car',
      pricePerDay: (data['pricePerDay'] as num?)?.toDouble() ?? 0.0,
      fuelCapacity: (data['fuelCapacity'] as num?)?.toDouble() ?? 0.0,
      image: data['carImage'] ?? '',
      ownerId: doc.id,
    );
  }
}