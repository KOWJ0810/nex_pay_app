import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'selfie_page.dart'; 
import '../../models/registration_data.dart';

class AddressInfoPage extends StatefulWidget {
  @override
  _AddressInfoPageState createState() => _AddressInfoPageState();
}

class _AddressInfoPageState extends State<AddressInfoPage> {
  final streetController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final postcodeController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    streetController.dispose();
    cityController.dispose();
    stateController.dispose();
    postcodeController.dispose();
    super.dispose();
  }

  void _submitAddress() {
    if (_formKey.currentState!.validate()) {
      final street = streetController.text.trim();
      final city = cityController.text.trim();
      final state = stateController.text.trim();
      final postcode = postcodeController.text.trim();

      print("Address submitted: $street, $city, $state, $postcode");

        RegistrationData.street = street;
        RegistrationData.city = city;
        RegistrationData.state = state;
        RegistrationData.postcode = postcode;



      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SelfiePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: primaryColor,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Column(
                    children: [
                      Text("Step 4", style: TextStyle(color: Colors.white, fontSize: 18)),
                      Text("Enter Your Address",
                          style: TextStyle(color: accentColor, fontSize: 18)),
                    ],
                  ),
                ),
                SizedBox(height: 30),

                Text("Street Address", style: TextStyle(color: Colors.white)),
                TextFormField(
                  controller: streetController,
                  style: TextStyle(color: Colors.white),
                  decoration: _inputDecoration("e.g. 123 Jalan ABC"),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Required field" : null,
                ),
                SizedBox(height: 20),

                Text("City", style: TextStyle(color: Colors.white)),
                TextFormField(
                  controller: cityController,
                  style: TextStyle(color: Colors.white),
                  decoration: _inputDecoration("e.g. Kuala Lumpur"),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Required field" : null,
                ),
                SizedBox(height: 20),

                Text("State", style: TextStyle(color: Colors.white)),
                TextFormField(
                  controller: stateController,
                  style: TextStyle(color: Colors.white),
                  decoration: _inputDecoration("e.g. Selangor"),
                  validator: (value) =>
                      value == null || value.isEmpty ? "Required field" : null,
                ),
                SizedBox(height: 20),

                Text("Postcode", style: TextStyle(color: Colors.white)),
                TextFormField(
                  controller: postcodeController,
                  style: TextStyle(color: Colors.white),
                  decoration: _inputDecoration("e.g. 47000"),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return "Required field";
                    if (!RegExp(r'^\d{5}$').hasMatch(value)) return "Invalid postcode";
                    return null;
                  },
                ),
                SizedBox(height: 40),

                ElevatedButton(
                  onPressed: _submitAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    minimumSize: Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: Text(
                    "Next",
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: accentColor),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: accentColor, width: 2),
      ),
    );
  }
}
