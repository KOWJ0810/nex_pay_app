import 'dart:convert';
import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/api_config.dart';
import '../../router.dart';

class SecurityFallbackArgs {
  final int userId;
  final String deviceId;
  final String deviceName;
  final String platform;

  const SecurityFallbackArgs({
    required this.userId,
    required this.deviceId,
    required this.deviceName,
    required this.platform,
  });
}

class SecurityQuestionsFallbackPage extends StatefulWidget {
  final SecurityFallbackArgs args;
  const SecurityQuestionsFallbackPage({super.key, required this.args});

  @override
  State<SecurityQuestionsFallbackPage> createState() =>
      _SecurityQuestionsFallbackPageState();
}

class _SecurityQuestionsFallbackPageState
    extends State<SecurityQuestionsFallbackPage> {
  static const FlutterSecureStorage _secure = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  bool _loading = true;
  bool _submitting = false;
  String? _error;
  List<_SecQ> _questions = [];
  final Map<int, TextEditingController> _controllers = {};

  String _authToken = '';

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      // token from secure storage
      _authToken = await _secure.read(key: 'token') ?? '';

      // fetch questions
      await _fetchQuestions();
    } catch (e) {
      _error = 'Failed to load security questions.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchQuestions() async {
    final uid = widget.args.userId;
    // Adjust if your ApiConfig.baseUrl already includes /api
    final url = Uri.parse('${ApiConfig.baseUrl}/users/security-questions/$uid');

    final res = await http.get(url, headers: {
      if (_authToken.isNotEmpty) 'Authorization': 'Bearer $_authToken',
      'Content-Type': 'application/json',
    });

    if (res.statusCode != 200) {
      throw Exception('status ${res.statusCode}');
    }

    final json = jsonDecode(res.body) as Map<String, dynamic>;
    final success = json['success'] == true;
    if (!success) throw Exception('backend returned success=false');

    final list = (json['questions'] as List)
        .map((e) => _SecQ(
              id: (e['id'] as num).toInt(),
              question: (e['question'] ?? '').toString(),
              answer: (e['answer'] ?? '').toString(),
            ))
        .toList();

    _questions = list;
    // build controllers
    for (final q in _questions) {
      _controllers[q.id] = TextEditingController();
    }
  }

  bool _answersMatch() {
    // case-insensitive, trim whitespace
    for (final q in _questions) {
      final input = (_controllers[q.id]?.text ?? '').trim().toLowerCase();
      final expected = q.answer.trim().toLowerCase();
      if (input != expected) return false;
    }
    return true;
  }

  Future<void> _onSubmit() async {
    if (_submitting) return;
    setState(() {
      _error = null;
    });

    if (_questions.isEmpty) {
      setState(() => _error = 'No questions to answer.');
      return;
    }

    if (!_answersMatch()) {
      setState(() => _error = 'One or more answers are incorrect.');
      return;
    }

    setState(() => _submitting = true);

    try {
      // If you want to (re)derive a nicer device name/platform here:
      String deviceName = widget.args.deviceName;
      String platform = widget.args.platform;

      // Defense: if missing, detect again
      if (deviceName.isEmpty || platform.isEmpty) {
        final info = DeviceInfoPlugin();
        platform = Platform.isIOS ? 'iOS' : (Platform.isAndroid ? 'Android' : 'Other');
        if (Platform.isIOS) {
          final ios = await info.iosInfo;
          deviceName = ios.name ?? ios.modelName ?? ios.model ?? 'iPhone';
        } else if (Platform.isAndroid) {
          final android = await info.androidInfo;
          final brand = android.brand ?? '';
          final model = android.model ?? android.device ?? '';
          final combo = [brand, model].where((s) => s.isNotEmpty).join(' ').trim();
          deviceName = combo.isEmpty ? 'Android Device' : combo;
        }
      }

      final uid = widget.args.userId;
      final url = Uri.parse('${ApiConfig.baseUrl}/users/updateDeviceId/$uid');

      final body = jsonEncode({
        "userId": uid,
        "deviceId": widget.args.deviceId,
        "deviceName": deviceName,
        "platform": platform,
        "registeredAt": DateTime.now().toIso8601String(),
      });

      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          if (_authToken.isNotEmpty) 'Authorization': 'Bearer $_authToken',
        },
        body: body,
      );

      if (res.statusCode == 200) {
        // Treat as success: trust new device locally & route home
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('is_logged_in', true);
        await prefs.setInt('user_id', uid);
        await prefs.setString('device_id', widget.args.deviceId);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Device verified via security questions.'),
            backgroundColor: primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.goNamed(RouteNames.home);
      } else {
        setState(() {
          _error = 'Failed to update device (${res.statusCode}).';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Network error. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF4F6FA),
        foregroundColor: Colors.black87,
        title: const Text('Verify with security questions',
            style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(.05),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                      border: Border.all(color: accentColor.withOpacity(.18)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Answer your security questions',
                            style: TextStyle(
                                fontWeight: FontWeight.w800, fontSize: 16)),
                        const SizedBox(height: 12),
                        if (_questions.isEmpty)
                          const Text(
                            'No security questions found for this account.',
                            style: TextStyle(color: Colors.black54),
                          )
                        else
                          ..._questions.map((q) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextField(
                                controller: _controllers[q.id],
                                textInputAction: TextInputAction.next,
                                decoration: InputDecoration(
                                  labelText: q.question,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        if (_error != null) ...[
                          const SizedBox(height: 6),
                          Text(_error!,
                              style: const TextStyle(color: Colors.redAccent)),
                        ],
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 50,
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _submitting || _questions.isEmpty
                                ? null
                                : _onSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Verify & continue',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w800)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SecQ {
  final int id;
  final String question;
  final String answer;
  _SecQ({required this.id, required this.question, required this.answer});
}