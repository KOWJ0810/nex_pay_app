import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/core/constants/colors.dart';
import 'package:nex_pay_app/router.dart';

class ScheduleAmountPage extends StatefulWidget {
  final int userId;
  final String userName;
  final String phoneNo;
  final DateTime startDate;
  final String frequency;
  final DateTime? endDate;

  const ScheduleAmountPage({
    super.key,
    required this.userId,
    required this.userName,
    required this.phoneNo,
    required this.startDate,
    required this.frequency,
    required this.endDate,
  });

  @override
  State<ScheduleAmountPage> createState() => _ScheduleAmountPageState();
}

class _ScheduleAmountPageState extends State<ScheduleAmountPage> {
  final TextEditingController _amountController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _confirmSchedule() {
    if (_formKey.currentState!.validate()) {
      final double amount = double.parse(_amountController.text);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Scheduled RM${amount.toStringAsFixed(2)} for ${widget.userName} (${widget.frequency}) starting ${widget.startDate}",
          ),
        ),
      );

      // Example of navigation to a confirmation or success page
      context.pushNamed(RouteNames.scheduleConfirm, 
      extra: {
        'user_id': widget.userId,
        'username': widget.userName,
        'phone_no': widget.phoneNo,
        'amount': amount,
        'start_date': widget.startDate,
        'frequency': widget.frequency,
        'end_date': widget.endDate,
      });
    }
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
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    onPressed: () {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      } else {
                        context.goNamed('schedule_date');
                      }
                    },
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "Enter Amount",
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
            // 🔹 Recipient Info
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
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: accentColor.withOpacity(0.9),
                    child: Text(
                      widget.userName[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.userName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          widget.phoneNo,
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Start: ${widget.startDate}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                        if (widget.endDate != null)
                          Text(
                            "End: ${widget.endDate}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        Text(
                          "Frequency: ${widget.frequency}",
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            // 🔹 Enter Amount
            const Text(
              "Enter Amount (RM)",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "0.00",
                  prefixIcon: const Icon(Icons.attach_money_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter an amount";
                  }
                  final parsed = double.tryParse(value);
                  if (parsed == null || parsed <= 0) {
                    return "Enter a valid positive amount";
                  }
                  return null;
                },
              ),
            ),

            const Spacer(),

            // 🔹 Confirm Button
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
                onPressed: _confirmSchedule,
                child: const Text(
                  "Confirm Schedule",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}