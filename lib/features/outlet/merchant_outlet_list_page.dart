import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';

class MerchantOutletListPage extends StatefulWidget {
  const MerchantOutletListPage({Key? key}) : super(key: key);

  @override
  State<MerchantOutletListPage> createState() => _MerchantOutletListPageState();
}

class _MerchantOutletListPageState extends State<MerchantOutletListPage> {
  List<dynamic> outlets = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOutlets();
  }

  // ─── Custom Back Logic ─────────────────────────────────────────────────────
  void _onBackPressed() {
    // Explicitly go to Merchant Account Page
    context.goNamed(RouteNames.merchantAccount); 
  }

  Future<void> _fetchOutlets() async {
    const storage = secureStorage;
    final token = await storage.read(key: 'token');
    if (token == null) return;

    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/merchants/outlets'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body);
        if (json['success'] == true) {
          if (mounted) {
            setState(() {
              outlets = json['data']['outlets'];
              isLoading = false;
            });
          }
        }
      } else {
        if (mounted) setState(() => isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use WillPopScope (or PopScope in newer Flutter) to handle Android back button
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _onBackPressed();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ─── 1. Immersive Header ─────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 120,
              pinned: true,
              backgroundColor: primaryColor,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: _onBackPressed, // Use custom handler
              ),
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                title: const Text(
                  'My Outlets',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [primaryColor, const Color(0xFF0D201C)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            // ─── 2. Content ──────────────────────────────────────────────────
            if (isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: accentColor)))
            else if (outlets.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.store_mall_directory_rounded, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text("No outlets found", style: TextStyle(color: Colors.grey[500], fontSize: 16)),
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
                      final outlet = outlets[index];
                      return _buildOutletCard(outlet);
                    },
                    childCount: outlets.length,
                  ),
                ),
              ),
              
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
        
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            context.pushNamed(RouteNames.merchantAddOutlet);
          },
          label: const Text(
            'Add Outlet',
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
          ),
          icon: const Icon(Icons.add_business_rounded, color: primaryColor),
          backgroundColor: accentColor,
        ),
      ),
    );
  }

  // ─── Card Widget ───────────────────────────────────────────────────────────
  Widget _buildOutletCard(dynamic outlet) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            context.pushNamed(
              RouteNames.merchantOutletDetail,
              extra: {'outletId': outlet['outletId']},
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon Box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.storefront_rounded, color: primaryColor, size: 24),
                ),
                
                const SizedBox(width: 16),
                
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              outlet['outletName'] ?? 'Outlet',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: primaryColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildMenu(outlet),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        outlet['outletAddress'] ?? '',
                        style: TextStyle(color: Colors.grey[600], fontSize: 13, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(dynamic outlet) {
    return PopupMenuButton<String>(
      padding: EdgeInsets.zero,
      icon: Icon(Icons.more_vert_rounded, size: 20, color: Colors.grey[400]),
      onSelected: (value) => _handleMenuAction(value, outlet),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'edit',
          child: Row(children: [Icon(Icons.edit_rounded, size: 18), SizedBox(width: 8), Text('Edit')]),
        ),
        const PopupMenuItem(
          value: 'delete',
          child: Row(children: [Icon(Icons.delete_rounded, size: 18, color: Colors.red), SizedBox(width: 8), Text('Delete', style: TextStyle(color: Colors.red))]),
        ),
      ],
    );
  }

  void _handleMenuAction(String value, dynamic outlet) {
    if (value == 'edit') {
      context.pushNamed(
        RouteNames.editOutletPage,
        extra: {
          'outletId': outlet['outletId'],
          'outletName': outlet['outletName'],
          'outletAddress': outlet['outletAddress'],
        },
      );
    } else if (value == 'delete') {
      _showDeleteDialog(outlet);
    }
  }

  void _showDeleteDialog(dynamic outlet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete Outlet"),
        content: const Text("Are you sure? This cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteOutlet(outlet['outletId']);
            },
            child: const Text("Delete"),
          )
        ],
      ),
    );
  }

  Future<void> _deleteOutlet(int id) async {
    // Implement delete logic similar to your original code
    // Then call setState to remove from list
    const storage = secureStorage;
    final token = await storage.read(key: 'token');
    
    try {
      final res = await http.delete(
        Uri.parse('${ApiConfig.baseUrl}/merchants/outlets/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (res.statusCode == 200) {
        setState(() {
          outlets.removeWhere((o) => o['outletId'] == id);
        });
        if(mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Outlet deleted")));
      }
    } catch (_) {}
  }
}