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
import 'package:carrentalapp/data/model/car_model.dart';
import 'package:carrentalapp/screens/passenger/booking_confirm.dart';
import '../../auth/auth_provider.dart';

class CarDetailPage extends StatefulWidget {
  final CarModel car;
  final LatLng pickupLocation;

  const CarDetailPage({super.key, required this.car, required this.pickupLocation});

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
      final duration = returnDate!.difference(pickupDate!);
      // Use inDays for a "Per Day" rental, or inHours/24
      final days = duration.inDays;
      setState(() {
        totalAmount = (days > 0 ? days : 1) * widget.car.pricePerHour.toDouble();
      });
    }
  }

  // --- ESEWA SDK PAYMENT METHOD ---
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
          productPrice: totalAmount.toString(), // Updated to use totalAmount
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

    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'passengerId': userId,
        'carModel': widget.car.model,
        'totalPrice': totalAmount,
        'pickupDate': pickupDate,
        'returnDate': returnDate,
        'status': 'pending',
        'paymentMethod': method,
        'paymentStatus': paymentStatus,
        'timestamp': FieldValue.serverTimestamp(),
        'pickupLat': widget.pickupLocation.latitude,
        'pickupLng': widget.pickupLocation.longitude,
        'carImage': widget.car.image,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.car.model),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
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
        const SizedBox(height: 20),
        Text(widget.car.model, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold)),
        const Divider(),
        const Text('Pickup Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
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
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                MarkerLayer(markers: [
                  Marker(point: widget.pickupLocation, child: const Icon(Icons.location_on, color: Colors.red, size: 35)),
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
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Rs. ${widget.car.pricePerHour}',
                    style: const TextStyle(fontSize: 24, color: Colors.green, fontWeight: FontWeight.bold)),
                const Text('/ day', style: TextStyle(fontSize: 16, color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 20),
            const Text('Rental Duration', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Replaced Expanded with simple Container logic for vertical flow in Card
            _dateTile("Pickup Date", pickupDate, () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 30)),
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
              );
              if (picked != null) {
                setState(() => returnDate = picked);
                _calculateTotal();
              }
            }),
            const SizedBox(height: 20),
            const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              children: [
                _payBtn("Cash", Icons.money, "Cash"),
                const SizedBox(width: 10),
                _payBtn("eSewa", Icons.wallet, "eSewa"),
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
                  backgroundColor: selectedPayment == "eSewa" ? Colors.green : Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  if (pickupDate == null || returnDate == null) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Select dates first!")));
                    return;
                  }
                  selectedPayment == "eSewa" ? _processEsewaSDKPayment() : _saveBookingToFirestore(paymentStatus: "unpaid", method: "Cash");
                },
                child: const Text("Confirm Reservation", style: TextStyle(color: Colors.white, fontSize: 16)),
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
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            Text(date == null ? "Select Date" : "${date.day}/${date.month}/${date.year}", style: const TextStyle(fontWeight: FontWeight.bold)),
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
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? Colors.orange : Colors.grey[100],
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isSel ? Colors.orange : Colors.grey.shade300),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSel ? Colors.white : Colors.black54),
              Text(title, style: TextStyle(color: isSel ? Colors.white : Colors.black, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}


/*import 'package:carrentalapp/core/constant/payment_config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';
import 'package:carrentalapp/data/model/car_model.dart';
import 'package:carrentalapp/screens/passenger/booking_confirm.dart';
import '../../auth/auth_provider.dart';

class CarDetailPage extends StatefulWidget {
  final CarModel car;
  final LatLng pickupLocation;

  const CarDetailPage({super.key, required this.car, required this.pickupLocation});

  @override
  State<CarDetailPage> createState() => _CarDetailPageState();
}

class _CarDetailPageState extends State<CarDetailPage> {
  DateTime? pickupDate;
  DateTime? returnDate;
  double totalAmount = 0.0;
  String selectedPayment = "Cash";


  // --- Function to calculate total ---
  void _calculateTotal() {
    if (pickupDate != null && returnDate != null) {
      final duration = returnDate!.difference(pickupDate!);
      final hours = duration.inHours;
      setState(() {
        // Ensure at least 1 hour is charged if same day is selected
        totalAmount = (hours > 0 ? hours : 1) * widget.car.pricePerHour.toDouble();
      });
    }
  }

  // --- ESEWA SDK PAYMENT METHOD ---
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
          productPrice: totalAmount.toString(), // Updated to use totalAmount
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

  // --- SAVE TO FIRESTORE ---
  Future<void> _saveBookingToFirestore({required String paymentStatus, required String method}) async {
    final authProvider = Provider.of<AuthProviderMethod>(context, listen: false);
    final userId = authProvider.user?.uid;
    if (userId == null) return;

    // Show Loading
    showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));

    try {
      await FirebaseFirestore.instance.collection('bookings').add({
        'passengerId': userId,
        'carModel': widget.car.model,
        'totalPrice': totalAmount,
        'pickupDate': pickupDate,
        'returnDate': returnDate,
        'status': 'pending',
        'paymentMethod': method,
        'paymentStatus': paymentStatus,
        'timestamp': FieldValue.serverTimestamp(),
        'pickupLat': widget.pickupLocation.latitude,
        'pickupLng': widget.pickupLocation.longitude,
        'carImage': widget.car.image,
      });

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => BookingConfirmContent(car: widget.car)));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.car.model),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              children: [
                //Car image
                widget.car.image.startsWith('http')
                    ? Image.network(
                  widget.car.image,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                )
                    : Image.asset(
                  widget.car.image,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
                const SizedBox(width: 24),

                // --- DATE SELECTION ---
                _buildDateSection(),
                const SizedBox(width: 24),
              ],
            ),


            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TITLE ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(widget.car.model, style: const TextStyle(fontSize: 26,
                          fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 24),


                  // --- MAP SECTION ---
                  const Text('Pickup Point', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Container(
                    height: 180,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FlutterMap(
                        options: MapOptions(
                          initialCenter: widget.pickupLocation,
                          initialZoom: 15.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.prasannata.carrentalapp',
                          ),
                          MarkerLayer(markers: [
                            Marker(point: widget.pickupLocation, child: const Icon(Icons.location_on, color: Colors.red, size: 35)),
                          ]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  /*// --- PAYMENT OPTIONS ---
                  const Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _paymentOption("Cash", Icons.money),
                      const SizedBox(width: 12),
                      _paymentOption("eSewa", Icons.account_balance_wallet),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // --- TOTAL ESTIMATE DISPLAY ---
                  if (totalAmount > 0)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Estimate", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          Text("\$${totalAmount.toStringAsFixed(2)}",
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                        ],
                      ),
                    ),*/

                  // Bottom padding to ensure scroll clears the floating button
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ],
        ),
      ),
      /*floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: SizedBox(
          width: double.infinity,
          height: 55,
        ),
      ),*/
    );
  }

  // --- PAYMENT OPTION ---
  Widget _paymentOption(String title, IconData icon) {
    bool isSelected = selectedPayment == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedPayment = title),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? (title == "eSewa" ? Colors.green : Colors.orange) : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.black54),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  // --- WIDGET HELPER: DATE SECTION ---
  Widget _buildDateSection() {
    return Card(
      elevation: 5,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('\$Rs{widget.car.pricePerHour}',
                  style: const TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold)),
              Text('per day',
                  style: const TextStyle(fontSize: 22, color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          const Text('Rental Duration', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          _dateCard("Pickup", pickupDate, () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 30)),
            );
            if (picked != null) {
              setState(() => pickupDate = picked);
              _calculateTotal();
            }
          }),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.0),
            child: Icon(Icons.arrow_forward, color: Colors.grey),
          ),
          _dateCard("Return", returnDate, () async {
            DateTime? picked = await showDatePicker(
              context: context,
              initialDate: pickupDate?.add(const Duration(days: 1)) ?? DateTime.now(),
              firstDate: pickupDate ?? DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 90)),
            );
            if (picked != null) {
              setState(() => returnDate = picked);
              _calculateTotal();
            }
          }),

          // --- PAYMENT OPTIONS ---
          const Text('Select Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              _paymentOption("Cash", Icons.money),
              const SizedBox(width: 12),
              _paymentOption("eSewa", Icons.account_balance_wallet),
            ],
          ),
          const SizedBox(height: 20),
          // --- TOTAL ESTIMATE DISPLAY ---
          if (totalAmount > 0)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Total Estimate",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  Text("\$${totalAmount.toStringAsFixed(2)}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold,
                          color: Colors.orange)),
                ],
              ),
            ),
          const SizedBox(height:20),

          //Confirm button
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: selectedPayment == "eSewa" ? Colors.green : Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              // VALIDATION: Ensure dates are selected
              if (pickupDate == null || returnDate == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Please select both Pickup and Return dates"),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              if (selectedPayment == "eSewa") {
                _processEsewaSDKPayment();
              } else {
                _saveBookingToFirestore(paymentStatus: "unpaid", method: "Cash");
              }
            },
            child: Text(
              selectedPayment == "eSewa" ? "Pay \$${totalAmount > 0 ? totalAmount.toStringAsFixed(0) : widget.car.pricePerHour} via eSewa" : "Confirm Booking (Cash)",
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET HELPER: DATE CARD ---
  Widget _dateCard(String label, DateTime? date, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 4),
              Text(
                date == null ? "Select Date" : "${date.day}/${date.month}/${date.year}",
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

*/