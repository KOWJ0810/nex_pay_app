import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import '../../core/constants/api_config.dart';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';

class MerchantOutletDetailPage extends StatefulWidget {
  final int outletId;

  const MerchantOutletDetailPage({Key? key, required this.outletId})
      : super(key: key);

  @override
  State<MerchantOutletDetailPage> createState() =>
      _MerchantOutletDetailPageState();
}

class _MerchantOutletDetailPageState extends State<MerchantOutletDetailPage> {
  Map<String, dynamic>? outletData;
  List<dynamic> staffList = [];
  bool isLoading = true;
  bool staffLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOutletDetails();
    _fetchStaffList();
  }

  Future<void> _fetchOutletDetails() async {
    const storage = secureStorage;
    final token = await storage.read(key: "token");

    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/merchants/outlets/${widget.outletId}"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes["success"] == true) {
          setState(() {
            outletData = jsonRes["data"];
            isLoading = false;
          });
        }
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _fetchStaffList() async {
    const storage = secureStorage;
    final token = await storage.read(key: "token");

    try {
      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/merchants/outlets/${widget.outletId}/staff"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes["success"] == true) {
          setState(() {
            staffList = jsonRes["data"]["staff"] ?? [];
            staffLoading = false;
          });
        }
      } else {
        setState(() => staffLoading = false);
      }
    } catch (_) {
      setState(() => staffLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final outletName = outletData?["outletName"] ?? "Loading...";

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 150,
            elevation: 0,
            backgroundColor: primaryColor,
            iconTheme: const IconThemeData(color: Colors.white),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: false,
              expandedTitleScale: 1.0,
              titlePadding: const EdgeInsetsDirectional.only(
                start: 16,
                bottom: 16,
                end: 16,
              ),
              title: Text(
                outletName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 24,
                ),
              ),
              background: Container(
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
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Outlet Address",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    outletData?["outletAddress"] ?? "Loading...",
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Staff Involved",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: accentColor,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          GoRouter.of(context).pushNamed(
                            RouteNames.merchantAddStaff,
                            extra: {'outletId': widget.outletId},
                          );
                        },
                        icon: Icon(Icons.add_rounded,
                            color: primaryColor, size: 20),
                        label: Text(
                          "Add Staff",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      )
                    ],
                  ),

                  const SizedBox(height: 12),

                  if (staffLoading)
                    const Center(child: CircularProgressIndicator()),

                  if (!staffLoading && staffList.isEmpty)
                    const Padding(
                      padding: EdgeInsets.only(top: 12),
                      child: Text(
                        "No staff assigned.",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),

                  if (!staffLoading)
                    ...staffList.map(
                      (staff) => Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: accentColor.withOpacity(.2),
                              child: Icon(Icons.person, color: primaryColor),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    staff["name"] ?? "Unknown",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    staff["phone"] ?? "",
                                    style: TextStyle(
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_rounded, color: Colors.red),
                              onPressed: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text("Remove Staff?"),
                                    content: const Text("Are you sure you want to remove this staff member?"),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                          foregroundColor: Colors.white,
                                        ),
                                        child: const Text("Remove"),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirm == true) {
                                  const storage = secureStorage;
                                  final token = await storage.read(key: "token");

                                  final url = "${ApiConfig.baseUrl}/merchants/outlets/${widget.outletId}/staff/${staff["userId"]}";
                                  final res = await http.delete(
                                    Uri.parse(url),
                                    headers: {"Authorization": "Bearer $token"},
                                  );

                                  if (res.statusCode == 200) {
                                    final jsonRes = jsonDecode(res.body);
                                    if (jsonRes["success"] == true) {
                                      setState(() {
                                        staffList.removeWhere((s) => s["userId"] == staff["userId"]);
                                      });
                                    }
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text("Failed to remove staff")),
                                    );
                                  }
                                }
                              },
                            ),
                          ],
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
}