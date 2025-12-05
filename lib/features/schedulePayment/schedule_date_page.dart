import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:nex_pay_app/core/constants/colors.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/api_config.dart';

class ScheduleDatePage extends StatefulWidget {
  final int userId;

  const ScheduleDatePage({
    super.key,
    required this.userId,
  });

  @override
  State<ScheduleDatePage> createState() => _ScheduleDatePageState();
}

class _ScheduleDatePageState extends State<ScheduleDatePage> {
  DateTime? _selectedDate;
  DateTime? _endDate;
  String _selectedFrequency = "ONE_TIME";

  Map<String, dynamic>? userData;

  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/users/${widget.userId}'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          setState(() {
            userData = data['user'];
          });
        }
      } else {
        throw Exception('Failed to fetch user data');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data: $e')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  void _selectDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _selectEndDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: (_endDate ?? _selectedDate ?? now),
      firstDate: _selectedDate ?? now,
      lastDate: DateTime(now.year + 2),
    );
    if (picked != null) {
      setState(() {
        _endDate = picked;
      });
    }
  }

  void _submitSchedule() {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a start date")),
      );
      return;
    }

    if (_selectedFrequency != "ONE_TIME" && _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an end date")),
      );
      return;
    }

    if (_selectedDate != null && _endDate != null && _endDate!.isBefore(_selectedDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("End date cannot be before start date")),
      );
      return;
    }

    if (userData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("User data not loaded yet")),
      );
      return;
    }

    final formattedDate = DateFormat("yyyy-MM-dd'T'09:00:00").format(_selectedDate!);
    final formattedEndDate = _endDate != null ? DateFormat("yyyy-MM-dd'T'09:00:00").format(_endDate!) : null;

    context.pushNamed(
      'schedule-amount',
      extra: {
        'user_id': widget.userId,
        'username': userData!['username'],
        'phone_no': userData!['phoneNum'],
        'start_date': formattedDate,
        'frequency': _selectedFrequency,
        'end_date': formattedEndDate,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(90),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                primaryColor,
                primaryColor.withOpacity(.85),
                accentColor.withOpacity(.9),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.goNamed('paychat');
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Schedule Payment",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🔹 User Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: userData == null
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: accentColor.withOpacity(0.9),
                          radius: 26,
                          child: Text(
                            userData!["username"][0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userData!["username"],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              userData!["phoneNum"] ?? "No phone number",
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
            ),

            const SizedBox(height: 30),

            // 🔹 Start Date Selection
            const Text(
              "Select Start Date",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate != null
                          ? DateFormat('dd MMM yyyy').format(_selectedDate!)
                          : "Choose a date",
                      style: TextStyle(
                        color: _selectedDate != null ? Colors.black : Colors.grey[600],
                        fontSize: 15,
                      ),
                    ),
                    const Icon(Icons.calendar_today, color: Colors.grey),
                  ],
                ),
              ),
            ),

            if (_selectedFrequency != "ONE_TIME") ...[
              const SizedBox(height: 20),
              const Text(
                "Select End Date",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _selectEndDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _endDate != null
                            ? DateFormat('dd MMM yyyy').format(_endDate!)
                            : "Choose an end date",
                        style: TextStyle(
                          color: _endDate != null ? Colors.black : Colors.grey[600],
                          fontSize: 15,
                        ),
                      ),
                      const Icon(Icons.calendar_today, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 30),

            // 🔹 Frequency Dropdown
            const Text(
              "Select Frequency",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButton<String>(
                value: _selectedFrequency,
                underline: const SizedBox(),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: "ONE_TIME", child: Text("ONE_TIME")),
                  DropdownMenuItem(value: "DAILY", child: Text("DAILY")),
                  DropdownMenuItem(value: "WEEKLY", child: Text("WEEKLY")),
                  DropdownMenuItem(value: "MONTHLY", child: Text("MONTHLY")),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedFrequency = value!;
                    if (_selectedFrequency == "ONE_TIME") {
                      _endDate = null;
                    }
                  });
                },
              ),
            ),

            const Spacer(),

            // 🔹 Continue Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: _submitSchedule,
                child: const Text(
                  "Continue",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}