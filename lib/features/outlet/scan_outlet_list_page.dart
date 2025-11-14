// lib/features/outlet/scan_outlet_list_page.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/api_config.dart';
import '../../core/constants/colors.dart';
import '../../router.dart';

class ScanOutletListPage extends StatefulWidget {
  const ScanOutletListPage({super.key});

  @override
  State<ScanOutletListPage> createState() => _ScanOutletListPageState();
}

class _ScanOutletListPageState extends State<ScanOutletListPage> {
  List<dynamic> outlets = [];
  int? selectedOutletId;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOutlets();
  }

  Future<void> _fetchOutlets() async {
    const storage = FlutterSecureStorage();
    final token = await storage.read(key: 'token');

    if (token == null) {
      _showError('Session expired. Please login again.');
      setState(() => isLoading = false);
      return;
    }

    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/merchants/outlets"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);

        if (jsonRes["success"] == true) {
          setState(() {
            outlets = jsonRes["data"]["outlets"] ?? [];
            isLoading = false;
          });
        } else {
          _showError("Failed to load outlets.");
        }
      } else {
        _showError("Server error ${res.statusCode}");
      }
    } catch (e) {
      _showError("Error: $e");
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text(
          "Select Outlet",
          style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        backgroundColor: primaryColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: primaryColor))
          : outlets.isEmpty
              ? const Center(
                  child: Text(
                    "No outlets found",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: outlets.length,
                  itemBuilder: (context, index) {
                    final outlet = outlets[index];
                    final outletId = outlet["outletId"];
                    final outletName = outlet["outletName"];
                    final outletAddress = outlet["outletAddress"];

                    final bool selected = selectedOutletId == outletId;

                    return GestureDetector(
                      onTap: () {
                        setState(() => selectedOutletId = outletId);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: selected
                              ? accentColor.withOpacity(0.20)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                selected ? accentColor : Colors.grey.shade300,
                            width: selected ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.storefront_rounded,
                                color: selected
                                    ? primaryColor
                                    : Colors.grey.shade600,
                                size: 32),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    outletName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    outletAddress,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (selected)
                              const Icon(Icons.check_circle_rounded,
                                  color: primaryColor, size: 28)
                          ],
                        ),
                      ),
                    );
                  },
                ),

      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: selectedOutletId == null
                  ? null
                  : () {
                      context.pushNamed(
                        RouteNames.merchantEnterPayAmount,
                        extra: {"outletId": selectedOutletId},
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedOutletId == null
                    ? Colors.grey.shade400
                    : accentColor,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                "Continue",
                style: TextStyle(
                  color: selectedOutletId == null
                      ? Colors.white
                      : primaryColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}