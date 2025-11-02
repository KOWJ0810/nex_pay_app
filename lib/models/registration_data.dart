import 'dart:io';

class SecurityQuestion {
  final String question;
  final String answer;

  SecurityQuestion({required this.question, required this.answer});

  Map<String, dynamic> toJson() => {
        "question": question,
        "answer": answer,
      };
}

class RegistrationData {
  static String fullName = '';
  static String icNum = '';
  static String phoneNum = '';
  static String email = '';
  static String pin = '';
  static String street = '';
  static String postcode = '';
  static String city = '';
  static String state = '';
  static File? icFrontImage;
  static File? icBackImage;
  static File? selfieImage;

  // 🔹 Add list of security questions
  static List<SecurityQuestion> securityQuestions = [];

  // Convenience: convert all to JSON (for createUser API)
  static Map<String, dynamic> toJson({
    required String icFrontUrl,
    required String icBackUrl,
    required String selfieUrl,
  }) {
    return {
      "user_name": fullName,
      "ic_num": icNum,
      "phoneNum": phoneNum,
      "ic_image_front": icFrontUrl,
      "ic_image_back": icBackUrl,
      "user_verification_image": selfieUrl,
      "email": email,
      "street_address": street,
      "postcode": postcode,
      "city": city,
      "state": state,
      "country": "Malaysia",
      "account_pin_num": pin,
      "securityQuestions": securityQuestions.map((q) => q.toJson()).toList(),
    };
  }
}