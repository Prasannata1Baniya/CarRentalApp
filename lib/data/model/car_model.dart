import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class CarModel {
  final String model;
  final double pricePerDay;
  final double fuelCapacity;
  final String image;
  final String ownerId;
  final String fuelType;
  final String color;
  final String carNumber;
  final String ownerPhone;

  CarModel({
    required this.model,
    required this.pricePerDay,
    required this.fuelCapacity,
    required this.image,
    required this.ownerId,
    required this.fuelType,
    required this.color,
    required this.carNumber,
    required this.ownerPhone,
  });


  factory CarModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    debugPrint("Reading Firestore Data: $data");
    final car =  CarModel(
      model: data['carModel'] ?? 'Unknown',
      pricePerDay: (data['pricePerDay'] as num?)?.toDouble() ?? 0.0,
      fuelCapacity: (data['fuelCapacity'] as num?)?.toDouble() ?? 0.0,
      image: data['carImage'] ?? '',
      ownerId: data['ownerId'] ?? doc.id,
      fuelType: data['fuelType'] ?? 'N/A',
      color: data['carColor'] ?? 'N/A',
      carNumber: data['plateNumber'] ?? 'N/A',
      ownerPhone: data['phone'] ?? 'N/A',
    );
    debugPrint("FROM FIRESTORE => ${car.toString()}");
    return car;
  }

  @override
  String toString() {
    return '''
CarModel(
model: $model,
color: $color,
fuelType: $fuelType,
plate: $carNumber,
phone: $ownerPhone,
fuelCapacity: $fuelCapacity
)
''';
  }

}