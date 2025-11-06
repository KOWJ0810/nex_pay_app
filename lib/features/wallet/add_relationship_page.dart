import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:nex_pay_app/router.dart';
import '../../core/constants/api_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AddRelationshipPage extends StatefulWidget {
  const AddRelationshipPage({super.key});

  @override
  State<AddRelationshipPage> createState() => _AddRelationshipPageState();
}

class _AddRelationshipPageState extends State<AddRelationshipPage> {
  String? selectedRole;
  final TextEditingController _phoneController = TextEditingController();

  Map<String, dynamic>? userData;
  bool isLoading = false;
  String? errorMessage;
  bool userSelected = false;

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 12),
            const Text(
              "Who you are",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: primaryColor,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Are you the sender or receiver?",
              style: TextStyle(fontSize: 15, color: Colors.black54),
            ),
            const SizedBox(height: 20),

            // Role buttons
            Row(
              children: [
                Expanded(
                  child: _roleButton(
                    label: "Sender",
                    selected: selectedRole == "Sender",
                    onTap: () => setState(() => selectedRole = "Sender"),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _roleButton(
                    label: "Receiver",
                    selected: selectedRole == "Receiver",
                    onTap: () => setState(() => selectedRole = "Receiver"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // Phone number input
            if (selectedRole != null) ...[
              Text(
                "Who is the person",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Enter the person’s phone number",
                style: TextStyle(fontSize: 15, color: Colors.black54),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "e.g. 0123456789",
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.black26),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Search button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _phoneController.text.isNotEmpty ? _searchUser : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    disabledBackgroundColor: Colors.grey.shade400,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                        )
                      : const Text(
                          "Search",
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // If user data found
              if (userData != null) ...[
                GestureDetector(
                  onTap: () => setState(() => userSelected = true),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: userSelected ? accentColor.withOpacity(0.15) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: userSelected ? accentColor : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.grey.shade200,
                          child: const Icon(Icons.person_rounded, size: 32, color: Colors.grey),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userData!['user_name'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                userData!['email'] ?? '',
                                style: const TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Wallet Balance: RM ${userData!['wallet_balance'] ?? 0}",
                                style: const TextStyle(fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: userSelected
                      ? () async {
                          const storage = FlutterSecureStorage();
                          final currentUserIdStr = await storage.read(key: 'user_id');
                          if (currentUserIdStr == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("User ID not found in secure storage")),
                            );
                            return;
                          }
                          final currentUserId = int.tryParse(currentUserIdStr);
                          if (currentUserId == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("Invalid user ID format")),
                            );
                            return;
                          }

                          final selectedUserId = userData!['user_id'] as int;

                          if (selectedRole == "Receiver") {
                            await _initiatePairing(
                              isSender: false,
                              senderUserId: selectedUserId,
                              receiverUserId: currentUserId,
                            );
                          } else if (selectedRole == "Sender") {
                            await _initiatePairing(
                              isSender: true,
                              senderUserId: currentUserId,
                              receiverUserId: selectedUserId,
                            );
                          }
                        }
                      : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentColor,
                      disabledBackgroundColor: Colors.grey.shade400,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text(
                      "Continue",
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],

              // Error message
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(errorMessage!,
                      style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _roleButton({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    const primaryColor = Color(0xFF102520);
    const accentColor = Color(0xFFB2DD62);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? accentColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? accentColor : Colors.black26,
            width: 1.4,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? primaryColor : Colors.black87,
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _searchUser() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      userData = null;
      userSelected = false;
    });

    final phoneNum = _phoneController.text.trim();
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/getUserDetailsByPhoneNum?phoneNum=$phoneNum'),
      );

      if (res.statusCode == 200) {
        final jsonRes = jsonDecode(res.body);
        if (jsonRes['success'] == true && jsonRes['user'] != null) {
          setState(() => userData = jsonRes['user']);
        } else {
          setState(() => errorMessage = "User not found.");
        }
      } else {
        setState(() => errorMessage = "Failed to fetch user details.");
      }
    } catch (e) {
      setState(() => errorMessage = "Error: $e");
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _initiatePairing({
  required bool isSender,
  required int senderUserId,
  required int receiverUserId,
}) async {
  const storage = FlutterSecureStorage();
  final token = await storage.read(key: 'token');

  final body = {
    "senderUserId": senderUserId,
    "receiverUserId": receiverUserId,
    "initiatedByUserId": isSender ? senderUserId : receiverUserId,
  };

  try {
    final res = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/emergency-wallet/pairings/initiate'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );

    if (res.statusCode == 200) {
      final jsonRes = jsonDecode(res.body);

      if (jsonRes['success'] == true) {
        if (isSender) {
          // Navigate to sender_generate_code_page
          context.pushNamed(
            RouteNames.senderGenerateCode,
            extra: {
              'pairingId': jsonRes['pairingId'],
              'status': jsonRes['status'],
              'firstCode': jsonRes['firstCode'],
              'phone': _phoneController.text,
              'userId': userData!['user_id'],
              'userName': userData!['user_name'],
            },
          );
        } else {
          // Navigate to receiver_verification_page
          context.pushNamed(
            RouteNames.receiverVerification,
            extra: {
              'pairingId': jsonRes['pairingId'],
              'status': jsonRes['status'],
              'phone': _phoneController.text,
              'userId': userData!['user_id'],
              'userName': userData!['user_name'],
            },
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed: ${jsonRes['message'] ?? 'Unknown error'}")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Server Error: ${res.statusCode}")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: $e")),
    );
  }
}

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
