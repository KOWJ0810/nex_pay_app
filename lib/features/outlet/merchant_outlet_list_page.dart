import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';

class MerchantOutletListPage extends StatelessWidget {
  final int merchantId;

  const MerchantOutletListPage({Key? key, required this.merchantId}) : super(key: key);

  final List<Map<String, String>> outlets = const [
    {
      "name": "NexPay Café - KL",
      "address": "123 Jalan Ampang, Kuala Lumpur",
      "status": "Open"
    },
    {
      "name": "NexPay Electronics - PJ",
      "address": "22 Jalan Utara, Petaling Jaya",
      "status": "Closed"
    },
    {
      "name": "NexPay Store - Penang",
      "address": "88 Jalan Burma, Penang",
      "status": "Open"
    },
    {
      "name": "NexPay Mart - Johor",
      "address": "55 Jalan Tebrau, Johor Bahru",
      "status": "Open"
    },
  ];

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return Colors.green.shade600;
      case 'closed':
        return Colors.red.shade600;
      default:
        return Colors.grey.shade600;
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
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                itemCount: outlets.length,
                itemBuilder: (context, index) {
                  final outlet = outlets[index];
                  final status = outlet['status'] ?? '';
                  final statusColor = _statusColor(status);
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
                            extra: {'merchantId': merchantId, 'outletId': index},
                          );
                        },
                        splashColor: primaryColor.withOpacity(0.2),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
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
                                      Text(
                                        outlet['name'] ?? '',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        outlet['address'] ?? '',
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
                              Padding(
                                padding: const EdgeInsets.only(right: 16),
                                child: Chip(
                                  label: Text(
                                    status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                  backgroundColor: statusColor,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
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
          context.pushNamed(
            RouteNames.merchantAddOutlet,
            extra: {'merchantId': merchantId},
          );
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