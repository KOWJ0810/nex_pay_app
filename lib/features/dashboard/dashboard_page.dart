import 'package:flutter/material.dart';
import 'package:nex_pay_app/features/topup/top_up_page.dart';
import '../../core/constants/colors.dart';

class DashboardPage extends StatelessWidget {
  final int userId = 152;
  final String userName = 'Kenneph';
  final double balance = 1234.56;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Text('NexPay', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.notifications, color: accentColor),
            onPressed: () {},
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting & Balance
              Text(
                'Hello, $userName 👋',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Balance', style: TextStyle(fontSize: 16)),
                        SizedBox(height: 5),
                        Text('RM ${balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    ),
                    Icon(Icons.account_balance_wallet, size: 40),
                  ],
                ),
              ),

              SizedBox(height: 30),

              // Quick Actions
              Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAction(Icons.send, 'Send'),
                  _buildAction(Icons.qr_code_scanner, 'Scan'),
                  _buildAction(Icons.request_page, 'Request'),
                  _buildAction(Icons.wallet, 'Top Up', onPressed:(){                                     
                    Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => TopUpPage())
                    );
                  }
                  )
                ],
              ),

              SizedBox(height: 30),

              // Recent Transactions
              Text(
                'Recent Transactions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Expanded(
                child: ListView(
                  children: [
                    _buildTransaction('Starbucks Coffee', '- RM18.50', 'Today'),
                    _buildTransaction('Transfer from Lee', '+ RM200.00', 'Yesterday'),
                    _buildTransaction('Maxis Bill', '- RM100.00', '1 Jul'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAction(IconData icon, String label, {VoidCallback? onPressed}) {
      return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: primaryColor,
            child: Icon(icon, color: Colors.white),
          ),
          SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildTransaction(String title, String amount, String date) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(Icons.arrow_circle_right_outlined, color: primaryColor),
        title: Text(title),
        subtitle: Text(date),
        trailing: Text(
          amount,
          style: TextStyle(
            color: amount.startsWith('+') ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
