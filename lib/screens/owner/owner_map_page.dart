import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';

class OwnerMapPage extends StatelessWidget {
  final LatLng pickupLocation;
  final String bookingId;

  const OwnerMapPage({
    super.key,
    required this.pickupLocation,
    required this.bookingId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pickup Location"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: pickupLocation,
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.carrentalapp.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: pickupLocation,
                    width: 80,
                    height: 80,
                    child: const Icon(
                      Icons.location_on,
                      color: Colors.red,
                      size: 45,
                    ),
                  ),
                ],
              ),
            ],
          ),

          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 10),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  /*const Text(
                    "Passenger is waiting here",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),*/

                  // ... inside the Column ...
                  PickupAddressWidget(
                    lat: pickupLocation.latitude,
                    lng: pickupLocation.longitude,
                  ),

                  /*FutureBuilder<List<Placemark>>(
                    future: placemarkFromCoordinates(
                        pickupLocation.latitude,
                        pickupLocation.longitude
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Text("Loading address...");
                      }

                      if (snapshot.hasError) {
                        return const Text("Location lookup failed.");
                      }

                      if (snapshot.hasData && snapshot.data!.isNotEmpty) {
                        final place = snapshot.data![0];
                        return Text(
                          "${place.street ?? ''}, ${place.locality ?? ''}",
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        );
                      }

                      return const Text("Passenger is waiting here");
                    },
                  ),*/
                  const SizedBox(height: 10),
                  const Text(
                    "Navigate to this location to pick up your passenger.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => _confirmAcceptance(context),
                      child: const Text(
                        "ACCEPT & START NAVIGATION",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAcceptance(BuildContext context) async {
    try {
      await FirebaseFirestore.instance.collection('bookings').doc(bookingId).update({
        'status': 'accepted',
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Ride Accepted! Get moving!"), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    }
  }
}

class PickupAddressWidget extends StatefulWidget {
  final double lat;
  final double lng;
  const PickupAddressWidget({super.key, required this.lat, required this.lng});

  @override
  State<PickupAddressWidget> createState() => _PickupAddressWidgetState();
}

class _PickupAddressWidgetState extends State<PickupAddressWidget> {
  String? address;

  @override
  void initState() {
    super.initState();
    _fetchAddress();
  }

  Future<void> _fetchAddress() async {
    if (widget.lat == 0.0 && widget.lng == 0.0) {
      if (mounted) setState(() => address = "Location not set");
      return;
    }

    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(widget.lat, widget.lng);

      if (mounted && placemarks.isNotEmpty) {
        final p = placemarks[0];
        setState(() => address = "${p.street ?? ''}, ${p.locality ?? ''}".replaceAll(RegExp(r'^,\s*'), ''));
      }
    } catch (e) {
      if (mounted) setState(() => address = "Address Unavailable");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      address ?? "Loading address...",
      textAlign: TextAlign.center,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}