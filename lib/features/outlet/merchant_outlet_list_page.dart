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

  Future<void> _fetchOutlets() async {
    const storage = secureStorage;
    final token = await storage.read(key: 'token');
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
        setState(() {
          outlets = json['data']['outlets'];
          isLoading = false;
        });
      }
    } else {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          automaticallyImplyLeading: true,
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
          title: const Text(
            'My Outlets',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          children: [
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator(color: primaryColor))
                  : ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: outlets.length,
                      itemBuilder: (context, index) {
                        final outlet = outlets[index];
                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          child: Material(
                            borderRadius: BorderRadius.circular(16),
                            elevation: 3,
                            shadowColor: Colors.black.withOpacity(0.1),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                context.pushNamed(
                                  RouteNames.merchantOutletDetail,
                                  extra: {'outletId': outlet['outletId']},
                                );
                              },
                              splashColor: primaryColor.withOpacity(0.2),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 100,
                                      decoration: BoxDecoration(
                                        borderRadius: const BorderRadius.only(
                                          topLeft: Radius.circular(16),
                                          bottomLeft: Radius.circular(16),
                                        ),
                                        gradient: LinearGradient(
                                          colors: [
                                            accentColor.withOpacity(0.8),
                                            accentColor.withOpacity(0.4),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    outlet['outletName'] ?? '',
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 18,
                                                      color: Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                                PopupMenuButton<String>(
                                                  onSelected: (value) {
                                                    if (value == 'edit') {
                                                      // navigate to edit outlet page
                                                      context.pushNamed(
                                                        RouteNames.editOutletPage,
                                                        extra: {
                                                          'outletId': outlet['outletId'],
                                                          'outletName': outlet['outletName'],
                                                          'outletAddress': outlet['outletAddress'],
                                                        },
                                                      );
                                                    } else if (value == 'delete') {
                                                      showDialog(
                                                        context: context,
                                                        builder: (context) {
                                                          return AlertDialog(
                                                            title: const Text('Delete Outlet'),
                                                            content: const Text('Are you sure you want to delete this outlet? This action cannot be undone.'),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () => Navigator.pop(context),
                                                                child: const Text('Cancel'),
                                                              ),
                                                              ElevatedButton(
                                                                style: ElevatedButton.styleFrom(
                                                                  backgroundColor: Colors.red,
                                                                  foregroundColor: Colors.white,
                                                                ),
                                                                onPressed: () async {
                                                                  Navigator.pop(context); // close dialog first

                                                                  const storage = secureStorage;
                                                                  final token = await storage.read(key: 'token');
                                                                  final outletId = outlet['outletId'];

                                                                  final res = await http.delete(
                                                                    Uri.parse('${ApiConfig.baseUrl}/merchants/outlets/$outletId'),
                                                                    headers: {
                                                                      'Authorization': 'Bearer $token',
                                                                      'Content-Type': 'application/json',
                                                                    },
                                                                  );

                                                                  if (res.statusCode == 200) {
                                                                    final body = jsonDecode(res.body);
                                                                    if (body['success'] == true) {
                                                                      setState(() {
                                                                        outlets.removeWhere((o) => o['outletId'] == outletId);
                                                                      });

                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        const SnackBar(content: Text('Outlet deleted')),
                                                                      );
                                                                    } else {
                                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                                        SnackBar(content: Text(body['message'] ?? 'Failed to delete outlet')),
                                                                      );
                                                                    }
                                                                  } else {
                                                                    ScaffoldMessenger.of(context).showSnackBar(
                                                                      SnackBar(content: Text('Server Error: ${res.statusCode}')),
                                                                    );
                                                                  }
                                                                },
                                                                child: const Text('Delete'),
                                                              ),
                                                            ],
                                                          );
                                                        },
                                                      );
                                                    }
                                                  },
                                                  itemBuilder: (context) => [
                                                    PopupMenuItem(
                                                      value: 'edit',
                                                      child: Row(
                                                        children: const [
                                                          Icon(Icons.edit_rounded, size: 18, color: Colors.black87),
                                                          SizedBox(width: 10),
                                                          Text('Edit Outlet'),
                                                        ],
                                                      ),
                                                    ),
                                                    PopupMenuItem(
                                                      value: 'delete',
                                                      child: Row(
                                                        children: const [
                                                          Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                                                          SizedBox(width: 10),
                                                          Text(
                                                            'Delete Outlet',
                                                            style: TextStyle(color: Colors.red),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              outlet['outletAddress'] ?? '',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.black54,
                                                height: 1.3,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          context.pushNamed(RouteNames.merchantAddOutlet);
        },
        label: Text(
          'Add Outlet',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 16,
            color: primaryColor,
          ),
        ),
        icon: Icon(Icons.add_business_rounded, size: 28, color: primaryColor),
        backgroundColor: accentColor,
        elevation: 8,
        highlightElevation: 12,
      ),
    );
  }
}