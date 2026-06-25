import 'package:carrentalapp/core/constant/payment_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../auth/auth_provider.dart';
import '../../data/model/car_model.dart';
import 'booking_confirm.dart';

class CarDetailPage extends StatefulWidget {
  final CarModel car;
  final LatLng pickupLocation;
  final String pickupAddress;

  const CarDetailPage({
    super.key,
    required this.car,
    required this.pickupLocation,
    required this.pickupAddress,
  });

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  DateTime? pickupDate;
  DateTime? returnDate;
  double totalAmount = 0.0;
  String selectedPayment = "Cash";

  void _calculateTotal() {
    if (pickupDate != null && returnDate != null) {
      if (returnDate!.isBefore(pickupDate!)) {
        setState(() => returnDate = pickupDate!.add(const Duration(days: 1)));
      }
      final duration = returnDate!.difference(pickupDate!);
      final days = duration.inDays > 0 ? duration.inDays : 1;

      setState(() {
        totalAmount = days * widget.car.pricePerDay.toDouble();
      });
    }
  }

  String? ownerPhoneNumber;

  @override
  void initState() {
    super.initState();
    _fetchOwnerPhone();
    debugPrint("DETAIL PAGE RECEIVED: Color=${widget.car.color}, Plate=${widget.car.carNumber},"
        "Fuel=${widget.car.fuelCapacity}"
    );
    debugPrint(widget.car.toString());
  }

  Future<void> _fetchOwnerPhone() async {
    try {
      debugPrint("Fetching phone for ownerId: ${widget.car.ownerId}");
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.car.ownerId).get();
      if (doc.exists) {
        debugPrint("Phone data found: ${doc.data()?['phone']}"); // Check this log
        setState(() {
          ownerPhoneNumber = doc.data()?['phone'] ?? 'No Phone';
        });
      } else {
        debugPrint("User document does not exist for this ownerId");
      }
    } catch (e) {
      debugPrint("Error fetching phone: $e");
    }
  }

  Widget _buildPremiumDatePickerTheme(BuildContext context, Widget child) {
    return Theme(
      data: Theme.of(context).copyWith(
        colorScheme: const ColorScheme.light(
          primary: Colors.orange,
          onPrimary: Colors.white,
          surface: Colors.white,
          onSurface: Color(0xFF221F1E),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF221F1E),
            textStyle: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
          ),
        ),
      ),
      child: child,
    );
  }

  void _processEsewaSDKPayment() {
    try {
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
          environment: Environment.test,
          clientId: PaymentConfig.clientId,
          secretId: PaymentConfig.secretKey,
        ),
        esewaPayment: EsewaPayment(
          productId: "ride_${DateTime.now().millisecondsSinceEpoch}",
          productName: widget.car.model,
          productPrice: totalAmount.toString(),
          callbackUrl: '',
        ),
        onPaymentSuccess: (EsewaPaymentSuccessResult data) {
          debugPrint(":::SUCCESS::: => $data");
          _saveBookingToFirestore(paymentStatus: "paid", method: "eSewa");
        },
        onPaymentFailure: (data) {
          debugPrint(":::FAILURE::: => $data");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Payment Failed. Try again.")),
          );
        },
        onPaymentCancellation: (data) {
          debugPrint(":::CANCELLATION::: => $data");
        },
      );
    } catch (e) {
      debugPrint("EXCEPTION : ${e.toString()}");
    }
  }

  Future<void> _saveBookingToFirestore({required String paymentStatus, required String method}) async {
    final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);
    final userId = authProvider.user?.uid;
    if (userId == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Colors.orange)),
    );

    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'userId': userId,
        'ownerId': widget.car.ownerId,
        'carModel': widget.car.model,
        'totalPrice': totalAmount,
        'pickupDate': pickupDate?.toIso8601String(),
        'returnDate': returnDate?.toIso8601String(),
        'paymentMethod': method,
        'paymentStatus': paymentStatus,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
        'pickupLat': widget.pickupLocation.latitude,
        'pickupLng': widget.pickupLocation.longitude,
      });

      if (!mounted) return;
      Navigator.pop(context);
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BookingConfirmContent(car: widget.car)));
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width > 900;
    debugPrint("--- DETAILED INSPECTION ---");
    debugPrint("Model: ${widget.car.model}");
    debugPrint("Color: '${widget.car.color}'");
    debugPrint("Plate: '${widget.car.carNumber}'");
    debugPrint("---------------------------");
    debugPrint("UI IS SEEING: ${widget.car.color}");
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(widget.car.model, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        //backgroundColor: Colors.orange,
        //backgroundColor: Color(0xFF221F1E),
        backgroundColor: Color(0xFFFF8C42),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildCarPreview()),
                    const SizedBox(width: 30),
                    Expanded(flex: 1, child: _buildBookingCard()),
                  ],
                )
              else
                Column(
                  children: [
                    _buildCarPreview(),
                    const SizedBox(height: 20),
                    _buildBookingCard(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCarPreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: widget.car.image.startsWith('http')
              ? Image.network(widget.car.image, height: 400, width: double.infinity, fit: BoxFit.cover)
              : Image.asset(widget.car.image, height: 400, width: double.infinity, fit: BoxFit.cover),
        ),
        const SizedBox(height: 24),
        Text(widget.car.model, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Color(0xFF221F1E))),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 7,
          children: [
            _buildSpecTile(Icons.palette_rounded, "Color",widget.car.color),
            _buildSpecTile(Icons.local_gas_station_rounded, "Fuel",widget.car.fuelType),
            _buildSpecTile(Icons.numbers_rounded, "Plate No.",widget.car.carNumber),
            _buildSpecTile(
              Icons.phone_rounded,
              "Contact",
              ownerPhoneNumber ?? widget.car.ownerPhone,
              onTap: () => _makePhoneCall(ownerPhoneNumber ?? widget.car.ownerPhone),
            ),
          ],
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16.0),
          child: Divider(),
        ),

        const Text('Pickup Location Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF221F1E))),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            children: [
              const Icon(Icons.radio_button_checked_rounded, color: Colors.orange, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "SELECTED ADDRESS",
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 0.5),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.pickupAddress,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF221F1E)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        Container(
          height: 250,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: FlutterMap(
              options: MapOptions(initialCenter: widget.pickupLocation, initialZoom: 15.0),
              children: [
                TileLayer(
                  urlTemplate: 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png',
                  subdomains: const ['a', 'b', 'c', 'd'],
                  userAgentPackageName: 'com.prasannata.carrentalapp',
                ),
                MarkerLayer(markers: [
                  Marker(
                    point: widget.pickupLocation,
                    child: const Icon(Icons.location_on_rounded, color: Colors.redAccent, size: 38),
                  ),
                ]),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBookingCard() {
    return Card(
     color: Colors.white,
     //surfaceTintColor: Colors.transparent,
      elevation: 6,
      //shadowColor: Colors.black.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rs. ${widget.car.pricePerDay}',
                    style: const TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold)),
                const Text('/ day', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Rental Duration', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF221F1E))),
            const SizedBox(height: 10),

            _dateTile("Pickup Date", pickupDate, () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
                builder: (context, child) => _buildPremiumDatePickerTheme(context, child!),
              );
              if (picked != null) {
                setState(() => pickupDate = picked);
                _calculateTotal();
              }
            }),
            const SizedBox(height: 10),

            _dateTile("Return Date", returnDate, () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: pickupDate?.add(const Duration(days: 1)) ?? DateTime.now().add(const Duration(days: 1)),
                firstDate: pickupDate ?? DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 90)),
                builder: (context, child) => _buildPremiumDatePickerTheme(context, child!), // Injects theme overrides here!
              );
              if (picked != null) {
                setState(() => returnDate = picked);
                _calculateTotal();
              }
            }),
            const SizedBox(height: 20),
            const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF221F1E))),
            const SizedBox(height: 10),
            Row(
              children: [
                _payBtn("Cash", Icons.money_rounded, "Cash"),
                const SizedBox(width: 10),
                _payBtn("eSewa", Icons.account_balance_wallet_rounded, "eSewa"),
              ],
            ),
            const SizedBox(height: 20),
            if (totalAmount > 0) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text("Rs. $totalAmount", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.orange)),
                ],
              ),
              const SizedBox(height: 20),
            ],
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: selectedPayment == "eSewa" ? Colors.green.shade700 : const Color(0xFF221F1E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                onPressed: () {
                  if (pickupDate == null || returnDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select dates first!")));
                    return;
                  }
                  selectedPayment == "eSewa" ? _processEsewaSDKPayment() : _saveBookingToFirestore(paymentStatus: "unpaid", method: "Cash");
                },
                child: const Text("Confirm Reservation", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dateTile(String label, DateTime? date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 2),
            Text(
              date == null ? "Select Date" : "${date.day}/${date.month}/${date.year}",
              style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF221F1E)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _payBtn(String title, IconData icon, String value) {
    bool isSel = selectedPayment == value;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => selectedPayment = value),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSel ? Colors.orange : const Color(0xFFF5F5F7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSel ? Colors.orange : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSel ? Colors.white : Colors.black54, size: 20),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSel ? Colors.white : const Color(0xFF221F1E),
                  fontSize: 12,
                  fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    await launchUrl(launchUri);
  }

  Widget _buildSpecTile(IconData icon, String label, String value,{VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          //color: Colors.black,
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.orange, size: 20),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10,
                    color: Colors.grey, fontWeight: FontWeight.bold)),
                Text(value, style: const TextStyle(fontSize: 13,
                    fontWeight: FontWeight.bold,color: Color(0xFF221F1E))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}