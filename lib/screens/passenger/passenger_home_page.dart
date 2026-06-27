import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:carrentalapp/data/model/car_model.dart';
import 'package:carrentalapp/widgets/car_card.dart';

class PassengerHomeContent extends StatefulWidget {
  const PassengerHomeContent({super.key});

  @override
  State<PassengerHomeContent> createState() => _PassengerHomeContentState();
}

class _PassengerHomeContentState extends State<PassengerHomeContent> {
  LatLng _currentCenter = const LatLng(27.7172, 85.3240);
  final MapController _mapController = MapController();
  bool _isLoadingLocation = false;

  static const Color kPrimaryDark = Color(0xFF221F1E);
  static const Color kAccentGold = Color(0xFFFFA24D);
  static const Color kBgLight = Color(0xFFF5F5F7);

  /*final List<CarModel> carList = [
    CarModel(model: "Fortuner GR", pricePerDay: 1000, fuelCapacity: 50, image: "assets/images/car1.jpg", ownerId: '',
        fuelType: '', color: '', carNumber: '', ownerPhone: ''),
    CarModel(model: "Land Cruiser", pricePerDay: 1000, fuelCapacity: 80, image: "assets/images/car2.jpg",
        ownerId: '', fuelType: '', color: '', carNumber: '', ownerPhone: ''),
    CarModel(model: "Tesla Model X", pricePerDay: 1000, fuelCapacity: 100, image: "assets/images/car3.jpg", ownerId: '',
        fuelType: '', color: '', carNumber: '', ownerPhone: ''),
    CarModel(model: "Hyundai Tucson", pricePerDay: 1000, fuelCapacity: 55, image: "assets/images/car4.jpg", ownerId: '',
        fuelType: '', color: '', carNumber: '', ownerPhone: ''),
    CarModel(model: "Kia Sportage", pricePerDay: 1000, fuelCapacity: 60, image: "assets/images/car2.jpg", ownerId: '',
        fuelType: '', color: '', carNumber: '', ownerPhone: ''),
    CarModel(model: "Suzuki Vitara", pricePerDay: 1000, fuelCapacity: 45, image: "assets/images/car3.jpg", ownerId: '', fuelType: '',
        color: '', carNumber: '', ownerPhone: ''),
  ];*/

  String _address = "Locating your premium pickup point...";

  Future<Position?> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return null;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {

      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return null;
    }
    if (permission == LocationPermission.deniedForever) return null;

    try {
      setState(() => _isLoadingLocation = true);
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
    } catch (e) {
      debugPrint("Error getting location: $e");
      return null;
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  Future<void> _updateAddress(LatLng position) async {
    try {
      final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1'
      );

      final response = await http.get(url, headers: {
        'User-Agent': 'com.prasannata.carrentalapp',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['address'];

        String city = address['city'] ?? address['town'] ?? address['village'] ?? '';
        String road = address['road'] ?? address['suburb'] ?? '';
        String displayName = road.isNotEmpty ? "$road, $city" : city;

        if (!mounted) return;
        setState(() {
          _address = displayName.isNotEmpty ? displayName : "Location Found";
        });
      }
    } catch (e) {
      debugPrint("Geocoding error: $e");
      if (!mounted) return;
      setState(() {
        _address = "Point: ${position.latitude.toStringAsFixed(3)}, ${position.longitude.toStringAsFixed(3)}";
      });
    }
  }

  Future<void> _initLocation() async {
    Position? position = await _getCurrentLocation();
    if (position != null && mounted) {
      LatLng newPoint = LatLng(position.latitude, position.longitude);
      _mapController.move(newPoint, 14.5);
      setState(() {
        _currentCenter = newPoint;
        _address = "Current Location";
      });
      _updateAddress(newPoint);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initLocation());
  }

  @override
  Widget build(BuildContext context) {
    bool isWideScreen = MediaQuery.of(context).size.width > 950;

    return Scaffold(
      backgroundColor: kBgLight,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('owners').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: kAccentGold));
            }
        
            List<CarModel> liveCarList = [];
        
            if (snapshot.hasData) {
              liveCarList = snapshot.data!.docs.map((doc) {
                return CarModel.fromFirestore(doc);
              }).toList();
            }
        
            final List<CarModel> allCars = liveCarList;
        
            return Column(
              children: [
                _buildPremiumHeader(),
                Expanded(
                  child: isWideScreen ? _buildWebView(allCars) : _buildMobileView(allCars),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPremiumHeader() {
    return Container(
      height: 70,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: const Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("DriveX", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.2, color: kPrimaryDark, fontSize: 18)),
              Text("Your premium journey starts here", style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w400)),
            ],
          ),
          Spacer(),
          Icon(Icons.notifications_none_rounded, color: kPrimaryDark, size: 22),
        ],
      ),
    );
  }

  Widget _buildWebView(List<CarModel> cars) {
    return Row(
      children: [
        Expanded(flex: 3, child: _buildMap()),
        Expanded(
          flex: 2,
          child: Container(
            color: kBgLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(24, 24, 24, 8),
                  child: Text("Available Rides", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: kPrimaryDark, letterSpacing: -0.5)),
                ),
                Expanded(child: _buildCarGrid(2, cars, true)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView(List<CarModel> cars) {
    return Column(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.45, child: _buildMap()),
        Expanded(
          child: Container(
            color: kBgLight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 4),
                  child: Text("Select a Ride", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kPrimaryDark)),
                ),
                Expanded(child: _buildCarGrid(1, cars, false)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMap() {
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _currentCenter,
            initialZoom: 14.5,
            onPositionChanged: (pos, hasGesture) {
              if (hasGesture && pos.center != null) {
                setState(() => _currentCenter = pos.center);
              }
            },
            onMapEvent: (event) {
              if (event is MapEventMoveEnd) {
                _updateAddress(event.camera.center);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
              userAgentPackageName: 'com.prasannata.carrentalapp',
            ),
          ],
        ),
        Center(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(color: kPrimaryDark, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12, spreadRadius: 2)]),
                  child: const Icon(Icons.directions_car_filled_rounded, color: kAccentGold, size: 20),
                ),
                Container(width: 2, height: 10, color: kPrimaryDark),
              ],
            ),
          ),
        ),
        Positioned(
          top: 20,
          left: 16, right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: kPrimaryDark.withValues(alpha: 0.06), blurRadius: 24, offset: const Offset(0, 8))],
            ),
            child: Row(
              children: [
                const Icon(Icons.radio_button_checked_rounded, color: kAccentGold, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("PICKUP LOCATION", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.0)),
                      const SizedBox(height: 2),
                      Text(_address, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: kPrimaryDark), overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                if (_isLoadingLocation)
                  const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: kPrimaryDark))
                else
                  IconButton(
                    icon: const Icon(Icons.my_location_rounded, color: kPrimaryDark, size: 18),
                    onPressed: _initLocation,
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                  )
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCarGrid(int crossAxisCount, List<CarModel> cars, bool isDesktop) {
    return GridView.builder(
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      clipBehavior: Clip.none,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: isDesktop ? 0.84 : 1.35,
        mainAxisSpacing: 24,
        crossAxisSpacing: 24,
      ),
      itemCount: cars.length,
      itemBuilder: (context, index) {
        return CarCard(car: cars[index], pickupLocation: _currentCenter, pickupAddress: _address,);
      },
    );
  }
}