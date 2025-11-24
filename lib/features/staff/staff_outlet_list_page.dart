import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import '../../core/constants/api_config.dart';
import 'package:nex_pay_app/router.dart';

class StaffOutletListPage extends StatefulWidget {
  const StaffOutletListPage({super.key});

  @override
  State<StaffOutletListPage> createState() => _StaffOutletListPageState();
}

class _StaffOutletListPageState extends State<StaffOutletListPage> {
  final storage = secureStorage;

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
        if (mounted) {
          setState(() {
            loading = false;
            errorMessage = "Session expired. Please login again.";
          });
        }
        return;
      }

      final res = await http.get(
        Uri.parse("${ApiConfig.baseUrl}/merchants/outlets/getOutletByStaff"),
        headers: {"Authorization": "Bearer $token"},
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);

        if (jsonRes["success"] == true) {
          if (mounted) {
            setState(() {
              merchants = jsonRes["data"]["merchants"] ?? [];
              loading = false;
              errorMessage = null; // Clear error on success
            });
          }
        } else {
          if (mounted) {
            setState(() {
              loading = false;
              errorMessage = "No outlets assigned.";
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            loading = false;
            errorMessage = "Server error: ${res.statusCode}";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = "Error: $e";
        });
      }
    }
  }

  Future<void> _onRefresh() async {
    setState(() => loading = true);
    await _fetchAssignedOutlets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: primaryColor,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // ─── 1. Modern Sliver Header ─────────────────────────────────────
            SliverAppBar(
              expandedHeight: 160.0,
              floating: false,
              pinned: true,
              backgroundColor: primaryColor,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: false,
                titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
                title: const Text(
                  "My Workplaces",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, const Color(0xFF0D201C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Stack(
                    children: [
                      // Decorative Circle
                      Positioned(
                        right: -30,
                        top: -30,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: accentColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: Icon(
                          Icons.storefront_rounded, 
                          color: Colors.white.withOpacity(0.1), 
                          size: 80
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),

            // ─── 2. Content Body ─────────────────────────────────────────────
            if (loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator(color: primaryColor)),
              )
            else if (errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                      const SizedBox(height: 16),
                      Text(errorMessage!, style: const TextStyle(color: Colors.grey)),
                      TextButton(onPressed: _onRefresh, child: const Text("Try Again"))
                    ],
                  ),
                ),
              )
            else if (merchants.isEmpty)
              const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_ind_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("No outlets assigned yet.", style: TextStyle(fontSize: 16, color: Colors.grey)),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final merchant = merchants[index];
                      return _buildMerchantGroup(merchant);
                    },
                    childCount: merchants.length,
                  ),
                ),
              ),
              
            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ─── Merchant Group Widget ─────────────────────────────────────────────────
  Widget _buildMerchantGroup(dynamic merchant) {
    final outlets = merchant["outlets"] as List<dynamic>;
    final merchantName = merchant["merchantName"] ?? "Unknown Merchant";
    final merchantType = merchant["merchantType"] ?? "Business";

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: true,
          tilePadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          shape: const Border(), // Remove default borders
          collapsedShape: const Border(),
          
          // Header: Merchant Info
          leading: CircleAvatar(
            backgroundColor: primaryColor.withOpacity(0.1),
            child: Text(
              merchantName.substring(0, 1).toUpperCase(),
              style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            merchantName,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: primaryColor,
            ),
          ),
          subtitle: Text(
            merchantType,
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
          ),
          
          // Body: List of Outlets
          children: outlets.map((outlet) => _buildOutletCard(outlet)).toList(),
        ),
      ),
    );
  }

  // ─── Outlet Card Widget ────────────────────────────────────────────────────
  Widget _buildOutletCard(dynamic outlet) {
    final status = outlet["status"] ?? "ACTIVE";
    final isActive = status == "ACTIVE";
    final role = outlet["accessRole"] ?? "Staff";

    return GestureDetector(
      onTap: () {
        context.pushNamed(
          RouteNames.staffDashboard,
          extra: {"outletId": outlet["outletId"]},
        );
      },
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            // Left: Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: const Icon(Icons.store_mall_directory_rounded, color: primaryColor, size: 24),
            ),
            
            const SizedBox(width: 16),
            
            // Middle: Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    outlet["outletName"] ?? "Outlet",
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 12, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          outlet["outletAddress"] ?? "No address",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Badges Row
                  Row(
                    children: [
                      _buildBadge(
                        text: role,
                        bgColor: accentColor.withOpacity(0.2),
                        textColor: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      _buildBadge(
                        text: status,
                        bgColor: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                        textColor: isActive ? Colors.green[700]! : Colors.red[700]!,
                      ),
                    ],
                  )
                ],
              ),
            ),
            
            // Right: Arrow
            const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({required String text, required Color bgColor, required Color textColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}