import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_config.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';
import 'package:nex_pay_app/router.dart';


class MerchantAddOutletPage extends StatefulWidget {
  const MerchantAddOutletPage({Key? key}) : super(key: key);

  @override
  State<MerchantAddOutletPage> createState() => _MerchantAddOutletPageState();
}

class _MerchantAddOutletPageState extends State<MerchantAddOutletPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Add New Outlet',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor,
                primaryColor.withOpacity(.85),
                accentColor.withOpacity(.9),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Outlet Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Outlet Name',
                          prefixIcon: const Icon(Icons.storefront_rounded, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Please enter outlet name' : null,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Outlet Address',
                          prefixIcon: const Icon(Icons.location_on_rounded, color: primaryColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        maxLines: 3,
                        validator: (v) => v == null || v.isEmpty ? 'Please enter outlet address' : null,
                      ),
                      const SizedBox(height: 30),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 2,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text(
                                  'Add Outlet',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: primaryColor,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: 'token');

      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Session expired. Please log in again.")),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      final body = {
        "outletName": _nameController.text.trim(),
        "outletAddress": _addressController.text.trim(),
      };

      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/merchants/outlets'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      setState(() => _isSubmitting = false);

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);

        if (jsonRes['success'] == true) {
          final data = jsonRes['data'];

          if (!mounted) return;

          context.pushNamed(
            RouteNames.addOutletSuccess,
            extra: {
              "outletName": data["outletName"],
              "outletAddress": data["outletAddress"],
              "dateCreated": data["dateCreated"],
            },
          );
          return;
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to add outlet. Code: ${res.statusCode}")),
      );

    } catch (e) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }
}
