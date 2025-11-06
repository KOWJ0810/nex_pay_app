import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';
import '../../core/constants/api_config.dart';

class SearchTransferUserPage extends StatefulWidget {
  const SearchTransferUserPage({Key? key}) : super(key: key);

  @override
  State<SearchTransferUserPage> createState() => _SearchTransferUserPageState();
}

class _SearchTransferUserPageState extends State<SearchTransferUserPage> {
  final TextEditingController _phoneController = TextEditingController();
  bool _isLoading = false;

  Future<void> _searchUser() async {
    final phoneNum = _phoneController.text.trim();
    if (phoneNum.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse(
        '${ApiConfig.baseUrl}/users/getUserDetailsByPhoneNum?phoneNum=$phoneNum');

    try {
      final response = await http.get(url);
      final data = json.decode(response.body);

      if (data['success'] == true && data['user'] != null) {
        final user = data['user'];
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User found!')),
        );
        await Future.delayed(const Duration(milliseconds: 500));
        if (!mounted) return;
        context.pushNamed(
          RouteNames.enterAmount,
          extra: {
            'user_id': user['user_id'],
            'user_name': user['user_name'],
            'phoneNum': phoneNum,
          },
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not found')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error occurred while searching')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isButtonEnabled = _phoneController.text.trim().isNotEmpty && !_isLoading;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF102520),
        elevation: 2,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Transfer',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        shadowColor: Colors.black.withOpacity(0.1),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF102520),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Icon(
                    Icons.compare_arrows_rounded,
                    size: 64,
                    color: const Color(0xFF8FC75A),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "Enter your friend’s phone number to transfer instantly",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF666666),
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    prefixIcon: const Icon(
                      Icons.phone_android_rounded,
                      color: Color(0xFFB2DD62),
                    ),
                    hintText: 'Phone Number',
                    hintStyle: const TextStyle(color: Color(0xFFAAAAAA)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(30),
                      borderSide: const BorderSide(
                        color: Color(0xFFB2DD62),
                        width: 2,
                      ),
                    ),
                    // No enabledBorder to keep no border line by default
                  ),
                  onChanged: (_) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isButtonEnabled ? _searchUser : null,
                    style: ButtonStyle(
                      elevation: MaterialStateProperty.resolveWith<double>(
                        (states) => states.contains(MaterialState.disabled) ? 0 : 6,
                      ),
                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      padding: MaterialStateProperty.all<EdgeInsets>(EdgeInsets.zero),
                      backgroundColor: MaterialStateProperty.resolveWith<Color>(
                        (states) => Colors.transparent,
                      ),
                      shadowColor: MaterialStateProperty.all<Color>(Colors.black.withOpacity(0.25)),
                    ),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: isButtonEnabled
                            ? const LinearGradient(
                                colors: [Color(0xFFB2DD62), Color(0xFF8FC75A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : LinearGradient(
                                colors: [
                                  const Color(0xFFB2DD62).withOpacity(0.5),
                                  const Color(0xFF8FC75A).withOpacity(0.5)
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 3,
                                ),
                              )
                            : const Text(
                                'Search',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Make sure the phone number is linked to NexPay',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF999999),
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
