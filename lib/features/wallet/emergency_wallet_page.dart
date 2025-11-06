import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';
import 'package:nex_pay_app/core/constants/api_config.dart';

class EmergencyWalletPage extends StatefulWidget {
  const EmergencyWalletPage({super.key});

  @override
  State<EmergencyWalletPage> createState() => _EmergencyWalletPageState();
}

class _EmergencyWalletPageState extends State<EmergencyWalletPage> {
  final storage = const FlutterSecureStorage();

  Map<String, dynamic>? senderUser;
  Map<String, dynamic>? receiverUser;

  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPairings();
  }

  Future<void> _fetchPairings() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final token = await storage.read(key: 'token');
      final userId = await storage.read(key: 'user_id');

      if (token == null || userId == null) {
        setState(() => errorMessage = 'Session expired. Please log in again.');
        return;
      }

      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/emergency-wallet/pairings/by-user/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes['success'] == true) {
          final data = jsonRes['data'];
          if (jsonRes['hasSender'] == true && data['senderSide'] != null) {
            final sender = data['senderSide']['partner'];
            senderUser = {
              'pairingId': data['senderSide']['pairingId'],
              'name': sender['name'],
              'phone': sender['phone'],
            };
          }
          if (jsonRes['hasReceiver'] == true && data['receiverSide'] != null) {
            final receiver = data['receiverSide']['partner'];
            receiverUser = {
              'pairingId': data['receiverSide']['pairingId'],
              'name': receiver['name'],
              'phone': receiver['phone'],
            };
          }
        } else {
          setState(() => errorMessage = "Failed to load relationships.");
        }
      } else {
        setState(() => errorMessage = "Server error: ${res.statusCode}");
      }
    } catch (e) {
      setState(() => errorMessage = "Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _terminatePairing(int pairingId) async {
    try {
      final token = await storage.read(key: 'token');
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session expired. Please login again.')),
        );
        return;
      }

      final res = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/emergency-wallet/pairings/$pairingId/terminate'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes['success'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Emergency contact revoked successfully.')),
          );
          await _fetchPairings();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(jsonRes['message'] ?? 'Failed to revoke contact.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Server error: ${res.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF102520);
    const accentColor = Color(0xFFB2DD62);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Emergency Wallet',
          style: TextStyle(color: accentColor, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator(color: accentColor))
          : errorMessage != null
              ? Center(
                  child: Text(errorMessage!,
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600)))
              : Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      const Text(
                        "Emergency Relationships",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Sender Section
                      _relationshipCard(
                        title: "Sender",
                        subtitle: "Can send money to you during emergency",
                        user: senderUser,
                        color: Colors.blue.shade50,
                        accentColor: accentColor,
                        onAdd: () => context.pushNamed(RouteNames.addRelationship),
                      ),
                      const SizedBox(height: 16),

                      // Receiver Section
                      _relationshipCard(
                        title: "Receiver",
                        subtitle: "You will send money to during emergency",
                        user: receiverUser,
                        color: Colors.green.shade50,
                        accentColor: accentColor,
                        onAdd: () => context.pushNamed(RouteNames.addRelationship),
                      ),

                      const Spacer(),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => context.pushNamed(RouteNames.addRelationship),
                          icon: const Icon(Icons.person_add_alt_1_rounded, color: primaryColor),
                          label: const Text(
                            "Add Relationship",
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _relationshipCard({
    required String title,
    required String subtitle,
    required Map<String, dynamic>? user,
    required Color color,
    required Color accentColor,
    required VoidCallback onAdd,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF102520)),
          ),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 14),
          if (user != null)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: accentColor.withOpacity(0.3),
                    child: const Icon(Icons.person_rounded, color: Color(0xFF102520)),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['name'],
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        user['phone'],
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Colors.grey),
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Confirm Removal'),
                          content: const Text('Are you sure you want to remove this emergency contact?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              style: ElevatedButton.styleFrom(backgroundColor: accentColor),
                              child: const Text('Confirm'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true && user['pairingId'] != null) {
                        await _terminatePairing(user['pairingId']);
                      }
                    },
                  ),
                ],
              ),
            )
          else
            OutlinedButton(
              onPressed: onAdd,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: accentColor, width: 1.4),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_rounded, color: Color(0xFF102520)),
                  SizedBox(width: 8),
                  Text(
                    "Add Emergency Contact",
                    style: TextStyle(
                      color: Color(0xFF102520),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}