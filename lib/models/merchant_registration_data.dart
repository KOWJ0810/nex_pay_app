import 'dart:io';

class MerchantRegistrationData {
  static String merchantName = '';
  static String merchantType = '';
  static String businessRegCode = '';
  static String bankAccountNum = '';
  static File? businessSsmImage;
  static String pin = '';

  static Map<String, dynamic> toJson({
    String? businessSsmImageUrl,
  }) {
    return {
      "merchant_name": merchantName,
      "merchant_type": merchantType,
      "business_reg_code": businessRegCode,
      "bank_account_num": bankAccountNum,
      if (businessSsmImageUrl != null) "business_ssm_image": businessSsmImageUrl,
      "pin": pin,
    };
  }
}
