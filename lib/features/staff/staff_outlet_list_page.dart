import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import '../../core/constants/api_config.dart';
import 'package:nex_pay_app/router.dart';


class StaffOutletListPage extends StatefulWidget {
  const StaffOutletListPage({super.key});

  @override
  State<StaffOutletListPage> createState() => _StaffOutletListPageState();
}

class _StaffOutletListPageState extends State<StaffOutletListPage> {
  final storage = const FlutterSecureStorage();

  List<dynamic> merchants = [];
  bool loading = true;
  String? errorMessage;

  static const primaryColor = Color(0xFF102520);
  static const accentColor = Color(0xFFB2DD62);

  @override
  void initState() {
    super.initState();
    _fetchAssignedOutlets();
  }

  Future<void> _fetchAssignedOutlets() async {
    try {
      final token = await storage.read(key: "token");
      if (token == null) {
        setState(() {
          loading = false;
          errorMessage = "Session expired. Please login again.";
        });
        return;
      }

      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/merchants/outlets/getOutletByStaff"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);

        if (jsonRes["success"] == true) {
          setState(() {
            merchants = jsonRes["data"]["merchants"] ?? [];
            loading = false;
          });
        } else {
          setState(() {
            loading = false;
            errorMessage = "No outlets assigned.";
          });
        }
      } else {
        setState(() {
          loading = false;
          errorMessage = "Server error: ${res.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = "Error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          "My Outlets",
          style: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),

      body: loading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor),
            )
          : errorMessage != null
              ? Center(
                  child: Text(
                    errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 16),
                  ),
                )
              : merchants.isEmpty
                  ? const Center(
                      child: Text(
                        "You are not assigned to any outlets.",
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: merchants.length,
                      itemBuilder: (context, index) {
                        final merchant = merchants[index];
                        final outlets = merchant["outlets"] as List<dynamic>;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            childrenPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            iconColor: primaryColor,
                            collapsedIconColor: primaryColor,

                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  merchant["merchantName"],
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: primaryColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  merchant["merchantType"],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 4, horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: accentColor.withOpacity(.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    merchant["merchantStatus"],
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: primaryColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            children: [
                              const SizedBox(height: 10),
                              ...outlets.map((outlet) {
                                return GestureDetector(
                                  onTap: () {
                                    context.pushNamed(
                                      RouteNames.staffDashboard,
                                      extra: {"outletId": outlet["outletId"]},
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 14),
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          outlet["outletName"],
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          outlet["outletAddress"],
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey.shade700,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 4, horizontal: 10),
                                              decoration: BoxDecoration(
                                                color:
                                                    accentColor.withOpacity(.2),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                "Role: ${outlet["accessRole"]}",
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: primaryColor,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 10),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  vertical: 4, horizontal: 10),
                                              decoration: BoxDecoration(
                                                color: Colors.blue
                                                    .withOpacity(.15),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: Text(
                                                outlet["status"],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}