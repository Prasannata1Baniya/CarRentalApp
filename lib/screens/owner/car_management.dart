import 'dart:convert';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:carrentalapp/auth/auth_provider.dart';
import '../../utils/input_decoration.dart';

class CarManagementContent extends StatefulWidget {
  const CarManagementContent({super.key});

  @override
  State<CarManagementContent> createState() => _CarManagementContentState();
}

class _CarManagementContentState extends State<CarManagementContent> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _modelController = TextEditingController();
  final TextEditingController _plateController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _fuelCapacityController = TextEditingController();

  String _fuelType = 'Petrol';
  String? _carImageUrl;
  Uint8List? _webImage;
  File? _mobileImage;

  bool _isLoading = false;
  bool _isEditing = false;

  final ImagePicker _picker = ImagePicker();
  final InputDecorate inputDecorate = InputDecorate();

  @override
  void dispose() {
    _modelController.dispose();
    _plateController.dispose();
    _colorController.dispose();
    _priceController.dispose();
    _fuelCapacityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (!_isEditing) return;
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      if (kIsWeb) {
        final bytes = await pickedFile.readAsBytes();
        setState(() => _webImage = bytes);
      } else {
        setState(() => _mobileImage = File(pickedFile.path));
      }
    }
  }

  void _loadData(Map<String, dynamic> data) {
    if (_isEditing) return;
    _modelController.text = data['carModel'] ?? '';
    _plateController.text = data['plateNumber'] ?? '';
    _colorController.text = data['carColor'] ?? '';
    _priceController.text = (data['pricePerDay'] ?? '').toString();
    _fuelCapacityController.text = (data['fuelCapacity'] ?? '').toString();
    _fuelType = data['fuelType'] ?? 'Petrol';
    _carImageUrl = data['carImage'];
  }

  Future<void> _saveCarDetails(String ownerId) async {
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isLoading = true);

    try {
      String? finalImageUrl = _carImageUrl;
      if (_webImage != null || _mobileImage != null) {
        finalImageUrl = await _uploadToCloudinary();
      }

      await FirebaseFirestore.instance.collection('owners').doc(ownerId).set({
        'carModel': _modelController.text.trim(),
        'plateNumber': _plateController.text.trim(),
        'carColor': _colorController.text.trim(),
        'pricePerDay': double.tryParse(_priceController.text.trim()) ?? 0.0,
        'fuelCapacity': double.tryParse(_fuelCapacityController.text.trim()) ?? 0.0,
        'fuelType': _fuelType,
        'carImage': finalImageUrl,
        'isAvailable': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      messenger.showSnackBar(
        const SnackBar(content: Text('Vehicle profile updated successfully!'), backgroundColor: Colors.green),
      );

      if (!mounted) return;
      setState(() {
        _isEditing = false;
        _webImage = null;
        _mobileImage = null;
      });
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Error saving details: $e'), backgroundColor: Colors.redAccent),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<String?> _uploadToCloudinary() async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'];
    final uploadPreset = dotenv.env['CLOUDINARY_PRESET'];
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    var request = http.MultipartRequest('POST', uri);
    request.fields['upload_preset'] = uploadPreset!;

    if (kIsWeb) {
      request.files.add(http.MultipartFile.fromBytes('file', _webImage!, filename: 'upload.jpg'));
    } else {
      request.files.add(await http.MultipartFile.fromPath('file', _mobileImage!.path));
    }

    final response = await request.send();
    final resBody = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      final data = jsonDecode(resBody);
      return data['secure_url'];
    } else {
      debugPrint(resBody);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ownerId = Provider.of<AuthProviderMethod>(context).user?.uid;

    if (ownerId == null) {
      return const Scaffold(body: Center(child: Text("User not authenticated")));
    }

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('owners').doc(ownerId).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.exists) {
          final carData = snapshot.data!.data() as Map<String, dynamic>;
          _loadData(carData);
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF4F6F8),
          appBar: AppBar(
            title: const Text("Manage Vehicle", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor: Colors.orange,
            elevation: 0,
            actions: [
              if (!_isEditing)
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFFFF5500)),
                  onPressed: () => setState(() => _isEditing = true),
                ),
            ],
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF5500)))
              : SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildImageSelector(),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Vehicle Information",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF112233)),
                        ),
                        const SizedBox(height: 20),

                        // Added practical layout examples here
                        _buildDecoratedField(_modelController, "Car Model", "Tesla Model 3", Icons.directions_car_outlined),
                        _buildDecoratedField(_plateController, "License Plate", "BA 1 CHA 1234", Icons.badge_outlined),
                        _buildDecoratedField(_colorController, "Car Color", "Metallic Black", Icons.palette_outlined),
                        _buildDecoratedField(_priceController, "Price per Day (Rs)", "1000", Icons.payments_outlined, isNumeric: true),
                        _buildDecoratedField(_fuelCapacityController, "Fuel Capacity (L)", "55", Icons.local_gas_station_outlined, isNumeric: true),

                        const SizedBox(height: 12),

                        const Text("Fuel Type", style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue: _fuelType,
                          dropdownColor: Colors.white,
                          style: const TextStyle(color: Color(0xFF112233)),
                          decoration: inputDecorate.buildInputDecoration("Fuel Type", prefixIcon: const Icon(Icons.ev_station_outlined, size: 20)),
                          items: ['Petrol', 'Diesel', 'Electric', 'Hybrid'].map((type) {
                            return DropdownMenuItem(value: type, child: Text(type));
                          }).toList(),
                          onChanged: _isEditing ? (value) => setState(() => _fuelType = value!) : null,
                        ),

                        const SizedBox(height: 30),

                        if (_isEditing)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Colors.grey),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => setState(() => _isEditing = false),
                                  child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFF5500),
                                    padding: const EdgeInsets.symmetric(vertical: 16),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () => _saveCarDetails(ownerId),
                                  child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSelector() {
    return GestureDetector(
      onTap: _pickImage,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: _isEditing ? Border.all(color: const Color(0xFFFF5500), width: 1.5) : Border.all(color: Colors.grey.shade300),
          image: _getImageDecoration(),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: (_webImage == null && _mobileImage == null && _carImageUrl == null)
            ? const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined, size: 40, color: Color(0xFFFF5500)),
            SizedBox(height: 8),
            Text("Upload Vehicle Photo", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          ],
        )
            : null,
      ),
    );
  }

  DecorationImage? _getImageDecoration() {
    if (_webImage != null) return DecorationImage(image: MemoryImage(_webImage!), fit: BoxFit.cover);
    if (_mobileImage != null) return DecorationImage(image: FileImage(_mobileImage!), fit: BoxFit.cover);
    if (_carImageUrl != null) return DecorationImage(image: NetworkImage(_carImageUrl!), fit: BoxFit.cover);
    return null;
  }

  Widget _buildDecoratedField(TextEditingController controller, String label, String example, IconData icon, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        enabled: _isEditing,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: Color(0xFF112233)),
        decoration: inputDecorate.buildInputDecoration(
          "$label (e.g., $example)",
          prefixIcon: Icon(icon, color: Colors.grey.shade600, size: 20),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return "Required Field";
          if (isNumeric && double.tryParse(value.trim()) == null) return "Enter a valid number";
          return null;
        },
      ),
    );
  }
}