import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../router.dart';

class OutletListPaymentLinkPage extends StatefulWidget {
  const OutletListPaymentLinkPage({super.key});

  @override
  State<OutletListPaymentLinkPage> createState() =>
      _OutletListPaymentLinkPageState();
}

class _OutletListPaymentLinkPageState
    extends State<OutletListPaymentLinkPage> {
  List<dynamic> outlets = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchOutlets();
  }

  Future<void> fetchOutlets() async {
    try {
      const storage = FlutterSecureStorage();
      final token = await storage.read(key: "token");

      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/merchants/outlets"),
        headers: {"Authorization": "Bearer $token"},
      );

      final jsonRes = jsonDecode(res.body);

      if (res.statusCode == 200 &&
          jsonRes["success"] == true &&
          jsonRes["data"] != null) {
        setState(() {
          outlets = jsonRes["data"]["outlets"];
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: primaryColor,
        title: const Text(
          "Select Outlet",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),

      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : hasError
              ? const Center(child: Text("Failed to load outlets"))
              : outlets.isEmpty
                  ? const Center(child: Text("No outlets found"))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: outlets.length,
                      itemBuilder: (context, index) {
                        final outlet = outlets[index];

                        return GestureDetector(
                          onTap: () {
                            context.pushNamed(
                              RouteNames.showPaymentLink,
                              extra: {'outletId': outlet['outletId']},
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: 42,
                                  width: 42,
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(Icons.storefront_rounded,
                                      color: primaryColor),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        outlet["outletName"] ?? "No Name",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: primaryColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        outlet["outletAddress"] ??
                                            "No Address",
                                        style: const TextStyle(
                                            color: Colors.black54),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.chevron_right_rounded,
                                    color: Colors.black38)
                              ],
                            ),
                          ),
                        );
                      },
                    ),
    );
  }
  
}