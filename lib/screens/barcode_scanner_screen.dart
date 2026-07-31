import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/recipe.dart';
import 'add_meal_screen.dart';
import 'widgets/app_toast.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _isScanning = true;

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (!_isScanning) return;
    
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final String? code = barcodes.first.rawValue;
    if (code == null) return;

    setState(() => _isScanning = false);
    _lookupProduct(code);
  }

  Future<void> _lookupProduct(String code) async {
    try {
      final url = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$code.json');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 1) {
          final p = data['product'];
          final nutrients = p['nutriments'] ?? {};
          
          final recipe = Recipe(
            apiMealId: 'barcode:$code',
            name: p['product_name'] ?? 'Branded Product',
            source: 'Barcode Scanner',
            imageUrl: p['image_url'],
            calories: (nutrients['energy-kcal_100g'] as num?)?.toDouble(),
            protein: (nutrients['proteins_100g'] as num?)?.toDouble(),
            carbs: (nutrients['carbohydrates_100g'] as num?)?.toDouble(),
            fat: (nutrients['fat_100g'] as num?)?.toDouble(),
            author: p['brands'] ?? 'Branded',
            isVerified: true,
          );

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => AddMealScreen(recipe: recipe)),
            );
          }
          return;
        }
      }
      
      if (mounted) {
        AppToast.show(context, message: 'Product not found in database.', type: ToastType.info);
        setState(() => _isScanning = true);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Failed to lookup product.', type: ToastType.error);
        setState(() => _isScanning = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Scan Product'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          MobileScanner(
            onDetect: _handleBarcode,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orangeAccent, width: 2),
                borderRadius: BorderRadius.circular(24),
              ),
            ),
          ),
          Positioned(
            bottom: 64,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: const Text(
                  'Align barcode within the frame',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
