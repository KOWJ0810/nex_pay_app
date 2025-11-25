import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:nex_pay_app/core/constants/api_config.dart';
import 'package:nex_pay_app/core/constants/colors.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:nex_pay_app/router.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';

class PaymentRequestSummary {
  final int requestId;
  final double amount;
  final String? note;
  final String status;
  final int fromUserId;
  final int toUserId;

  const PaymentRequestSummary({
    required this.requestId,
    required this.amount,
    required this.note,
    required this.status,
    required this.fromUserId,
    required this.toUserId,
  });

  static int _toInt(dynamic v, {int defaultValue = 0}) {
    if (v == null) return defaultValue;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  static double _toDouble(dynamic v, {double defaultValue = 0.0}) {
    if (v == null) return defaultValue;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  factory PaymentRequestSummary.fromJson(Map<String, dynamic> json) {
    return PaymentRequestSummary(
      requestId: _toInt(json['requestId'] ?? json['request_id']),
      amount: _toDouble(json['amount']),
      note: json['note']?.toString(),
      status: (json['status'] ?? json['requestStatus'] ?? '').toString(),
      fromUserId: _toInt(json['fromUserId'] ?? json['from_user_id']),
      toUserId: _toInt(json['toUserId'] ?? json['to_user_id']),
    );
  }
}

class GroupPaymentSummary {
  final int groupPaymentId;
  final String title;
  final double totalAmount;
  final String status; // OPEN / CLOSED

  const GroupPaymentSummary({
    required this.groupPaymentId,
    required this.title,
    required this.totalAmount,
    required this.status,
  });

  static int _toInt(dynamic v, {int defaultValue = 0}) {
    if (v == null) return defaultValue;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  static double _toDouble(dynamic v, {double defaultValue = 0.0}) {
    if (v == null) return defaultValue;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  factory GroupPaymentSummary.fromJson(Map<String, dynamic> json) {
    return GroupPaymentSummary(
      groupPaymentId: _toInt(json['groupPaymentId'] ?? json['group_payment_id']),
      title: (json['title'] ?? '').toString(),
      totalAmount: _toDouble(json['totalAmount'] ?? json['total_amount']),
      status: (json['status'] ?? '').toString(),
    );
  }
}

class GroupPaymentContribution {
  final int userId;
  final double assignedAmount;
  final double paidAmount;
  final String status;       // UNPAID / PAID
  final int? transactionId;
  final String? userName;

  const GroupPaymentContribution({
    required this.userId,
    required this.assignedAmount,
    required this.paidAmount,
    required this.status,
    this.transactionId,
    this.userName,
  });

  static int _toInt(dynamic v, {int defaultValue = 0}) {
    if (v == null) return defaultValue;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  static double _toDouble(dynamic v, {double defaultValue = 0.0}) {
    if (v == null) return defaultValue;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  factory GroupPaymentContribution.fromJson(Map<String, dynamic> json) {
    return GroupPaymentContribution(
      userId: _toInt(json['userId'] ?? json['user_id']),
      assignedAmount:
          _toDouble(json['assignedAmount'] ?? json['assigned_amount']),
      paidAmount: _toDouble(json['paidAmount'] ?? json['paid_amount']),
      status: (json['status'] ?? '').toString(),
      transactionId: json['transactionId'] != null
          ? _toInt(json['transactionId'])
          : null,
      userName: (json['userName'] ??
                 json['user_name'] ??
                 json['displayName'] ??
                 json['display_name'])
            ?.toString(),    
    );
  }

  bool get isPaid => status.toUpperCase() == 'PAID';
}

class GroupPaymentDetail {
  final int groupPaymentId;
  final int chatroomId;
  final int creatorUserId;
  final String title;
  final double totalAmount;
  final String status; // OPEN / CLOSED
  final DateTime? dueAt;
  final DateTime createdAt;
  final List<GroupPaymentContribution> contributions;

  const GroupPaymentDetail({
    required this.groupPaymentId,
    required this.chatroomId,
    required this.creatorUserId,
    required this.title,
    required this.totalAmount,
    required this.status,
    required this.dueAt,
    required this.createdAt,
    required this.contributions,
  });

  static int _toInt(dynamic v, {int defaultValue = 0}) {
    if (v == null) return defaultValue;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  static double _toDouble(dynamic v, {double defaultValue = 0.0}) {
    if (v == null) return defaultValue;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return DateTime.tryParse(s);
  }

  factory GroupPaymentDetail.fromJson(Map<String, dynamic> json) {
    final contribAny = json['contributions'] ?? json['contribs'];
    final List<GroupPaymentContribution> contribs = [];
    if (contribAny is List) {
      for (final c in contribAny) {
        if (c is Map<String, dynamic>) {
          contribs.add(GroupPaymentContribution.fromJson(c));
        }
      }
    }

    return GroupPaymentDetail(
      groupPaymentId:
          _toInt(json['groupPaymentId'] ?? json['group_payment_id']),
      chatroomId: _toInt(json['chatroomId'] ?? json['chatroom_id']),
      creatorUserId:
          _toInt(json['creatorUserId'] ?? json['creator_user_id']),
      title: (json['title'] ?? '').toString(),
      totalAmount: _toDouble(json['totalAmount'] ?? json['total_amount']),
      status: (json['status'] ?? '').toString(),
      dueAt: _toDateTime(json['dueAt'] ?? json['due_at']),
      createdAt:
          _toDateTime(json['createdAt'] ?? json['created_at']) ?? DateTime.now(),
      contributions: contribs,
    );
  }

  bool get isClosed => status.toUpperCase() == 'CLOSED';

  int get totalPeople => contributions.length;

  int get paidCount =>
      contributions.where((c) => c.isPaid).length;

  double get paidAmount =>
      contributions.fold(0.0, (sum, c) => sum + c.paidAmount);
}


/// Simple DTO for a chat message from /paychat/chatrooms/{id}/messages
class ChatMessage {
  final int messageId;
  final int chatroomId;
  final int senderId;
  final String type; // TEXT, SYSTEM, PAYMENT_REQUEST, GROUP_PAYMENT
  final String? text;
  final PaymentRequestSummary? paymentRequest;
  final DateTime createdAt;
  final GroupPaymentSummary? groupPayment;
  

  const ChatMessage({
    required this.messageId,
    required this.chatroomId,
    required this.senderId,
    required this.type,
    required this.text,
    this.paymentRequest,
    this.groupPayment,
    required this.createdAt,
  });

  static int _toInt(dynamic v, {int defaultValue = 0}) {
    if (v == null) return defaultValue;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v) ?? defaultValue;
    return defaultValue;
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Support both camelCase and snake_case keys coming from backend
    final dynamic messageIdAny = json['messageId'] ?? json['message_id'];
    final dynamic chatroomIdAny = json['chatroomId'] ?? json['chatroom_id'];

    // Try multiple possibilities for sender id
    dynamic senderIdAny = json['senderId'] ??
        json['sender_id'] ??
        json['senderUserId'] ??
        json['userId'] ??
        json['user_id'] ??
        json['fromUserId'];

    // Some backends may nest sender object
    if (senderIdAny == null && json['sender'] is Map<String, dynamic>) {
      final senderMap = json['sender'] as Map<String, dynamic>;
      senderIdAny =
          senderMap['userId'] ?? senderMap['user_id'] ?? senderMap['id'];
    }

    final createdAtStr =
        (json['createdAt'] ?? json['created_at'])?.toString();
    final createdAt =
        createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;

    final parsedSenderId = _toInt(senderIdAny);

    PaymentRequestSummary? pr;
    final dynamic prJson =
        json['paymentRequestSummary'] ??
        json['paymentRequest'] ??
        json['payment_request_summary'] ??
        json['payment_request'];

    if (prJson is Map<String, dynamic>) {
      pr = PaymentRequestSummary.fromJson(prJson);
    }

    GroupPaymentSummary? gp;
    final dynamic gpJson =
        json['groupPaymentSummary'] ??
        json['groupPayment'] ??
        json['group_payment_summary'] ??
        json['group_payment'];

    if (gpJson is Map<String, dynamic>) {
      gp = GroupPaymentSummary.fromJson(gpJson);
    }

    return ChatMessage(
      messageId: _toInt(messageIdAny),
      chatroomId: _toInt(chatroomIdAny),
      senderId: parsedSenderId,
      type: json['type']?.toString() ?? 'TEXT',
      text: json['text']?.toString(),
      paymentRequest: pr,
      groupPayment: gp,      // 👈
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  bool get isSystem => type.toUpperCase() == 'SYSTEM';
  bool get isText => type.toUpperCase() == 'TEXT';
}

/// Chatroom page for 1-1 / group chat
class ChatroomPage extends StatefulWidget {
  final int chatroomId;
  final String chatTitle; // e.g. other user name or group title

  const ChatroomPage({
    Key? key,
    required this.chatroomId,
    required this.chatTitle,
  }) : super(key: key);

  @override
  State<ChatroomPage> createState() => _ChatroomPageState();
}

class _ChatroomPageState extends State<ChatroomPage> {
  final Map<int, String> _memberNamesById = {};
  
  Future<void> _confirmPayPaymentRequest(PaymentRequestSummary pr) async {
    // Only the requested payer should be able to confirm and pay
    final isPayer = _currentUserId != null && pr.toUserId == _currentUserId;
    if (!isPayer) return;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.06),
                    width: 0.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.payments_rounded, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Confirm payment',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'You are about to pay:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'RM ${pr.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if ((pr.note ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        pr.note!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Confirm & pay'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      await _payPaymentRequest(pr);
    }
  }
  static const _secure = secureStorage;

  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  StompClient? _stompClient;
  bool _wsConnected = false;

  List<ChatMessage> _messages = [];
  bool _loading = false;
  bool _sending = false;
  List<int> _groupMemberIds = [];
  int? _currentUserId;
  int? _otherUserId;
  bool _isGroupChat = false;

  final Map<int, GroupPaymentDetail> _groupPayments = {};
  final Set<int> _loadingGroupPayments = {};

  @override
  void initState() {
    super.initState();
    _initAndLoad();
    _connectWebSocket();
  }

  @override
  void dispose() {
    _stompClient?.deactivate();
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<String?> _getAccessToken() async {
    return await _secure.read(key: 'token');
  }

  Future<int?> _getCurrentUserId() async {
    final val = await _secure.read(key: 'user_id');
    if (val == null) return null;
    return int.tryParse(val);
  }

  Future<void> _initAndLoad() async {
    setState(() => _loading = true);
    try {
      final uid = await _getCurrentUserId();
      setState(() => _currentUserId = uid);
      await _loadChatroomMeta();
      await _loadMessages();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadChatroomMeta() async {
  try {
    final token = await _getAccessToken();
    if (token == null) {
      throw Exception('Not logged in');
    }

    final uri = Uri.parse('${ApiConfig.baseUrl}/paychat/chatrooms');
    final resp = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception('Failed to load chatroom meta (${resp.statusCode})');
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Unexpected chatroom meta response');
    }
    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Unknown error');
    }

    final data = decoded['data'];
    if (data is! List) return;

    final currentId = _currentUserId;
    if (currentId == null) return;

    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final idAny = item['chatroomId'] ?? item['chatroom_id'];
      final id = ChatMessage._toInt(idAny);
      if (id != widget.chatroomId) continue;

      final typeStr = (item['type'] ?? '').toString().toUpperCase();
      _isGroupChat = typeStr == 'GROUP';
      final membersAny = item['memberUserIds'] ?? item['member_user_ids'];
      final memberIds = <int>[];
      if (membersAny is List) {
        for (final e in membersAny) {
          final mid = PaymentRequestSummary._toInt(e);
          if (mid != 0) memberIds.add(mid);
        }
      }

      if (_isGroupChat) {
        _groupMemberIds = memberIds;
        if (!_groupMemberIds.contains(currentId)) {
          _groupMemberIds.add(currentId);
        }

        // 👇 load names for these members
        await _loadGroupMemberNames();
      } else {
        for (final mid in memberIds) {
          if (mid != currentId) {
            _otherUserId = mid;
            break;
          }
        }
      }
      break;
    }
  } catch (e) {
    debugPrint('Failed to load chatroom meta: $e');
  }
}

Future<void> _loadGroupMemberNames() async {
  try {
    final token = await _getAccessToken();
    if (token == null) throw Exception('Not logged in');

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/paychat/chatrooms/${widget.chatroomId}/members',
    );

    final resp = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception('Failed to load member names (${resp.statusCode})');
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Unknown error');
    }

    final data = decoded['data'];
    if (data is! List) return;

    final Map<int, String> names = {};
    for (final item in data) {
      if (item is! Map<String, dynamic>) continue;
      final id = PaymentRequestSummary._toInt(item['userId'] ?? item['user_id']);
      final name = (item['userName'] ?? item['user_name'] ?? '').toString();
      if (id != 0 && name.isNotEmpty) {
        names[id] = name;
      }
    }

    if (!mounted) return;
    setState(() {
      _memberNamesById
        ..clear()
        ..addAll(names);
    });
  } catch (e) {
    debugPrint('Failed to load group member names: $e');
  }
}

    Future<void> _ensureGroupPaymentDetailLoaded(int groupPaymentId) async {
    if (_groupPayments.containsKey(groupPaymentId) ||
        _loadingGroupPayments.contains(groupPaymentId)) {
      return;
    }

    _loadingGroupPayments.add(groupPaymentId);
    try {
      final token = await _getAccessToken();
      if (token == null) throw Exception('Not logged in');

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/paychat/group-payments/$groupPaymentId',
      );

      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (resp.statusCode != 200) {
        throw Exception('Failed to load group payment (${resp.statusCode})');
      }

      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
        throw Exception(decoded['message'] ?? 'Unknown error');
      }

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid group payment data');
      }

      final detail = GroupPaymentDetail.fromJson(data);

      if (!mounted) return;
      setState(() {
        _groupPayments[groupPaymentId] = detail;
      });
    } catch (e) {
      debugPrint('Failed to load group payment detail: $e');
    } finally {
      _loadingGroupPayments.remove(groupPaymentId);
    }
  }

  Future<void> _loadMessages() async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        throw Exception('Not logged in');
      }

      // Backend: GET /api/paychat/chatrooms/{chatroomId}/messages
      // In Flutter: ApiConfig.baseUrl already includes /api
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/paychat/chatrooms/${widget.chatroomId}/messages'
        '?page=0&size=50',
      );

      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (resp.statusCode != 200) {
        throw Exception('Failed to load messages (${resp.statusCode})');
      }

      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format');
      }
      if (decoded['success'] != true) {
        throw Exception(decoded['message'] ?? 'Unknown error');
      }

      final data = decoded['data'];
      if (data is! List) {
        throw Exception('Expected a list of messages');
      }

      final msgs = data
          .where((e) => e is Map<String, dynamic>)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();

      // Backend returns newest first; we want oldest at top
      msgs.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      setState(() {
        _messages = msgs;
      });

      for (final m in msgs) {
        final gp = m.groupPayment;
        if (gp != null) {
          _ensureGroupPaymentDetailLoaded(gp.groupPaymentId);
        }
      }

      // Scroll to bottom after list builds
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.jumpTo(_scrollCtrl.position.maxScrollExtent);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load messages: $e')),
      );
    }
  }

  void _connectWebSocket() {
    try {
      // ApiConfig.baseUrl example: https://nexpaybe.example.com/api
      final httpBase = ApiConfig.baseUrl.replaceAll('/api', '');
      final sockJsUrl = '$httpBase/ws'; // must start with http/https

      _stompClient = StompClient(
        config: StompConfig.sockJS(
          url: sockJsUrl,
          onConnect: _onStompConnect,
          onWebSocketError: (dynamic error) {
            debugPrint('STOMP WebSocket error: $error');
          },
        ),
      );

      _stompClient!.activate();
    } catch (e) {
      debugPrint('Failed to init WebSocket: $e');
    }
  }

  void _onStompConnect(StompFrame frame) {
    setState(() {
      _wsConnected = true;
    });

    _stompClient?.subscribe(
      destination: '/topic/chatrooms/${widget.chatroomId}',
      callback: (StompFrame msg) {
        if (msg.body == null) return;
        try {
          final decoded = jsonDecode(msg.body!);
          if (decoded is Map<String, dynamic>) {
            final incoming = ChatMessage.fromJson(decoded);

            // Avoid duplicate messages (same messageId)
            final alreadyExists = _messages.any(
              (m) =>
                  m.messageId != 0 &&
                  incoming.messageId != 0 &&
                  m.messageId == incoming.messageId,
            );
            if (alreadyExists) {
              debugPrint(
                  'Skip duplicate incoming messageId=${incoming.messageId}');
              return;
            }

            setState(() {
              _messages.add(incoming);
            });

            final gp = incoming.groupPayment;
            if (gp != null) {
              _ensureGroupPaymentDetailLoaded(gp.groupPaymentId);
            }

            // Scroll to bottom when a new message arrives
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollCtrl.hasClients) {
                _scrollCtrl.animateTo(
                  _scrollCtrl.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut,
                );
              }
            });

            // If this is a system message (e.g. "Paid RM..."), reload messages
            // so any related payment-request bubbles get updated status.
            if (incoming.isSystem) {
              // Fire and forget; no loading spinner
              _loadMessages();
            }
            setState(() {});
          }
        } catch (e) {
          debugPrint('Failed to handle STOMP message: $e');
        }
      },
    );
  }

  Future<void> _sendMessage() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final token = await _getAccessToken();
      if (token == null) {
        throw Exception('Not logged in');
      }

      final wsWasConnected = _wsConnected;

      // Backend: POST /api/paychat/messages
      final uri = Uri.parse('${ApiConfig.baseUrl}/paychat/messages');
      final body = jsonEncode({
        'chatroomId': widget.chatroomId,
        'text': text,
      });

      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (resp.statusCode != 200) {
        throw Exception('Failed to send message (${resp.statusCode})');
      }

      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response format');
      }
      if (decoded['success'] != true) {
        throw Exception(decoded['message'] ?? 'Unknown error');
      }

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Expected message object in data');
      }

      final msg = ChatMessage.fromJson(data);

      if (!wsWasConnected) {
        // No WebSocket → we add manually
        setState(() {
          _messages.add(msg);
          _inputCtrl.clear();
        });
      } else {
        // WebSocket is connected → server will push, just clear input
        setState(() {
          _inputCtrl.clear();
        });
      }

      await Future.delayed(const Duration(milliseconds: 80));
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  void _openActionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.95),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.05),
                      width: 0.7,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          radius: 18,
                          backgroundColor: primaryColor.withOpacity(0.12),
                          child: const Icon(
                            Icons.schedule_rounded,
                            size: 18,
                            color: primaryColor,
                          ),
                        ),
                        title: const Text(
                          'Schedule payment',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: const Text(
                          'Set a future date to auto-pay',
                          style: TextStyle(fontSize: 12),
                        ),
                        onTap: () {
                          Navigator.of(ctx).pop();
                          _openSchedulePayment();
                        },
                      ),
                      const Divider(height: 0),
                      if (!_isGroupChat)
                        ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                const Color(0xFF0A84FF).withOpacity(0.12),
                            child: const Icon(
                              Icons.request_page_outlined,
                              size: 18,
                              color: Color(0xFF0A84FF),
                            ),
                          ),
                          title: const Text(
                            'Payment request',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'Ask your friend to pay you',
                            style: TextStyle(fontSize: 12),
                          ),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _openPaymentRequestSheet();
                          },
                        ),
                      if (_isGroupChat)
                        ListTile(
                          leading: CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                const Color(0xFF34C759).withOpacity(0.12),
                            child: const Icon(
                              Icons.group_outlined,
                              size: 18,
                              color: Color(0xFF34C759),
                            ),
                          ),
                          title: const Text(
                            'Group payment',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'Split a bill with this group',
                            style: TextStyle(fontSize: 12),
                          ),
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _openGroupPaymentSheet();
                          },
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _openSchedulePayment() {
    // TODO: Replace with your actual schedule payment route
    try {
      context.pushNamed(RouteNames.scheduleSuccess);
    } catch (e) {
      debugPrint('Schedule payment navigation not configured: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule payment screen is not configured yet.'),
        ),
      );
    }
  }

  Future<void> _openGroupPaymentSheet() async {
  if (!_isGroupChat || _groupMemberIds.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Group payment is only available in group chats.'),
      ),
    );
    return;
  }

  // Exclude the creator from payers; the money is going to them
  final me = _currentUserId;
  final payerIds = me == null
      ? List<int>.from(_groupMemberIds)
      : _groupMemberIds.where((id) => id != me).toList();

  if (payerIds.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No other members to split with in this group.'),
      ),
    );
    return;
  }

  final titleCtrl = TextEditingController(text: widget.chatTitle);
  final totalCtrl = TextEditingController();

  // Controllers for custom amounts per payer
  final Map<int, TextEditingController> perMemberCtrls = {
    for (final id in payerIds) id: TextEditingController(),
  };

  bool isCustomSplit = false;

  final result = await showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return StatefulBuilder(
        builder: (ctx, setModalState) {
          double customTotal = 0.0;
          if (isCustomSplit) {
            for (final id in payerIds) {
              final text = perMemberCtrls[id]!.text.trim();
              final val = double.tryParse(text);
              if (val != null && val > 0) {
                customTotal += val;
              }
            }
          }

          return Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 12,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.06),
                      width: 0.7,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.group_outlined,
                              size: 18,
                              color: primaryColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'New group payment',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          labelText: 'Title',
                          hintText: 'e.g. Penang Trip',
                          filled: true,
                          fillColor: const Color(0xFFF6F7FB),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Toggle between split equally vs custom amounts
                      Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  isCustomSplit = false;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: !isCustomSplit
                                      ? primaryColor.withOpacity(0.1)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.scatter_plot_outlined,
                                      size: 16,
                                      color: !isCustomSplit
                                          ? primaryColor
                                          : Colors.grey[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Split equally',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: !isCustomSplit
                                            ? primaryColor
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  isCustomSplit = true;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isCustomSplit
                                      ? primaryColor.withOpacity(0.1)
                                      : const Color(0xFFF3F4F6),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.tune_rounded,
                                      size: 16,
                                      color: isCustomSplit
                                          ? primaryColor
                                          : Colors.grey[700],
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Custom amounts',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isCustomSplit
                                            ? primaryColor
                                            : Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (!isCustomSplit) ...[
                        TextField(
                          controller: totalCtrl,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Total amount (RM)',
                            prefixText: 'RM ',
                            filled: true,
                            fillColor: const Color(0xFFF3F4F6),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'We\'ll split this equally between ${payerIds.length} members.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ] else ...[
                        Text(
                          'Assign specific amounts to each member (you won\'t be charged).',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 56.0 * payerIds.length,
                          child: ListView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: payerIds.length,
                            itemBuilder: (ctx, index) {
                              final id = payerIds[index];
                              final isMe = me != null && id == me;

                              // 🔹 Use username instead of raw userId
                              // Make sure you have a Map<int, String> _memberNamesById
                              // populated from your "get members by chatroomId" API.
                              final userName =
                                  _memberNamesById[id] ?? 'Member';

                              final label = isMe ? 'You' : userName;

                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        label,
                                        style: const TextStyle(
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    SizedBox(
                                      width: 120,
                                      child: TextField(
                                        controller: perMemberCtrls[id],
                                        keyboardType:
                                            const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                        onChanged: (_) {
                                          setModalState(() {});
                                        },
                                        decoration: InputDecoration(
                                          prefixText: 'RM ',
                                          hintText: '0.00',
                                          isDense: true,
                                          filled: true,
                                          fillColor:
                                              const Color(0xFFF3F4F6),
                                          border: OutlineInputBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            borderSide: BorderSide.none,
                                          ),
                                          contentPadding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 8,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Total: RM ${customTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 4),
                          ElevatedButton(
                            onPressed: () {
                              final title = titleCtrl.text.trim();
                              if (title.isEmpty) {
                                ScaffoldMessenger.of(ctx).showSnackBar(
                                  const SnackBar(
                                    content:
                                        Text('Please enter a title.'),
                                  ),
                                );
                                return;
                              }

                              List<Map<String, dynamic>> contributions;

                              if (!isCustomSplit) {
                                final rawAmount = totalCtrl.text.trim();
                                final total =
                                    double.tryParse(rawAmount);
                                if (total == null || total <= 0) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter a valid total amount.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                final perHead =
                                    total / payerIds.length;
                                contributions = payerIds
                                    .map((id) => {
                                          'userId': id,
                                          'amount': double.parse(
                                            perHead
                                                .toStringAsFixed(2),
                                          ),
                                        })
                                    .toList();
                              } else {
                                contributions = [];

                                // ✅ Only include members that have a positive amount
                                for (final id in payerIds) {
                                  final text =
                                      perMemberCtrls[id]!.text.trim();
                                  if (text.isEmpty) continue;

                                  final amount =
                                      double.tryParse(text) ?? 0.0;
                                  if (amount <= 0) {
                                    // Ignore non-positive values silently
                                    continue;
                                  }

                                  contributions.add({
                                    'userId': id,
                                    'amount': amount,
                                  });
                                }

                                if (contributions.isEmpty) {
                                  ScaffoldMessenger.of(ctx).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Please enter at least one positive amount.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                              }

                              Navigator.of(ctx).pop({
                                'title': title,
                                'contributions': contributions,
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            child: const Text('Create'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );

  if (result == null) return;

  final title = result['title'] as String;
  final List contributionsRaw = result['contributions'] as List;
  final contributions = contributionsRaw
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();

  await _createGroupPayment(title, contributions);
}

  Future<void> _createGroupPayment(
    String title,
    List<Map<String, dynamic>> contributions,
  ) async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        throw Exception('Not logged in');
      }

      if (contributions.isEmpty) {
        throw Exception('No contributors found for this group payment.');
      }

      // Derive totalAmount from the contributions list
      double totalAmount = 0.0;
      for (final c in contributions) {
        final raw = c['amount'];
        if (raw is num) {
          totalAmount += raw.toDouble();
        } else if (raw is String) {
          final parsed = double.tryParse(raw);
          if (parsed != null) {
            totalAmount += parsed;
          }
        }
      }

      if (totalAmount <= 0) {
        throw Exception('Total amount must be greater than 0.');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/paychat/group-payments');
      final body = jsonEncode({
        'chatroomId': widget.chatroomId,
        'title': title,
        'dueAt': null,
        'contributions': contributions,
      });

      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (resp.statusCode != 200) {
        throw Exception(
          'Failed to create group payment (${resp.statusCode})',
        );
      }

      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response');
      }
      if (decoded['success'] != true) {
        throw Exception(decoded['message'] ?? 'Unknown error');
      }

      // Backend pushes GROUP_PAYMENT bubble via WebSocket; as fallback refresh.
      await _loadMessages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Group payment created.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create group payment: $e')),
      );
    }
  }

  Future<void> _openGroupPaymentDetailSheet(GroupPaymentSummary gp) async {
    try {
      final detail = await _fetchGroupPaymentDetail(gp.groupPaymentId);
      if (!mounted || detail == null) return;

      final total = detail.totalAmount;
      final paidCount = detail.contributions
          .where((c) => c.status.toUpperCase() == 'PAID')
          .length;
      final totalCount = detail.contributions.length;
      final ratio =
          totalCount == 0 ? 0.0 : paidCount / totalCount.toDouble();

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
              left: 12,
              right: 12,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.96),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.black.withOpacity(0.06),
                      width: 0.7,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              detail.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Total: RM ${total.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E5EA),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: ratio.clamp(0.0, 1.0),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '$paidCount/$totalCount paid',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...detail.contributions.map((c) {
                        final isMe =
                            _currentUserId != null && c.userId == _currentUserId;
                        final statusUpper = c.status.toUpperCase();
                        final isPaid = statusUpper == 'PAID';

                        Color chipColor;
                        Color chipTextColor;
                        String label;
                        if (isPaid) {
                          chipColor = const Color(0xFFE5FBE8);
                          chipTextColor = const Color(0xFF1E8449);
                          label = 'Paid';
                        } else {
                          chipColor = const Color(0xFFFFE5E5);
                          chipTextColor = const Color(0xFFB00020);
                          label = 'Unpaid';
                        }

                        final nameLabel = isMe
                          ? 'You'
                          : (c.userName ?? 'Member');

                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: const Color(0xFFE5E5EA),
                                child: Text(
                                  (nameLabel.isNotEmpty ? nameLabel[0].toUpperCase() : '?'),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  nameLabel,
                                  style: const TextStyle(
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: chipColor,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: chipTextColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Close'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load group payment detail: $e')),
      );
    }
  }

    Future<void> _payGroupContribution(int groupPaymentId) async {
  try {
    final token = await _getAccessToken();
    if (token == null) throw Exception('Not logged in');

    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/paychat/group-payments/$groupPaymentId/pay',
    );

    final resp = await http.post(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (resp.statusCode != 200) {
      throw Exception('Failed to pay (${resp.statusCode})');
    }

    final decoded = jsonDecode(resp.body);
    if (decoded is! Map<String, dynamic> || decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Unknown error');
    }

    // ✅ Re-fetch the latest detail from backend and overwrite cached one
    final updatedDetail = await _fetchGroupPaymentDetail(groupPaymentId);
    if (mounted && updatedDetail != null) {
      setState(() {
        _groupPayments[groupPaymentId] = updatedDetail;
      });
    }

    // Refresh messages so the SYSTEM bubble etc. stays in sync
    await _loadMessages();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Payment successful.')),
      );
    }
  } catch (e) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Failed to pay: $e')),
    );
  }
}

  Future<void> _confirmPayGroupContribution(GroupPaymentDetail detail) async {
    final myId = _currentUserId;
    if (myId == null) return;

    GroupPaymentContribution? myContrib;
    for (final c in detail.contributions) {
      if (c.userId == myId) {
        myContrib = c;
        break;
      }
    }
    if (myContrib == null) return;
    if (myContrib.isPaid) return;

    final remaining =
        myContrib.assignedAmount - myContrib.paidAmount;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.06),
                    width: 0.8,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.groups_rounded, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Pay your share',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      detail.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Amount due:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'RM ${remaining.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: const Text('Confirm & pay'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (confirmed == true) {
      await _payGroupContribution(detail.groupPaymentId);
    }
  }

  Future<GroupPaymentDetail?> _fetchGroupPaymentDetail(int groupPaymentId) async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        throw Exception('Not logged in');
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/paychat/group-payments/$groupPaymentId',
      );

      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (resp.statusCode != 200) {
        throw Exception('Failed to fetch detail (${resp.statusCode})');
      }

      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response');
      }
      if (decoded['success'] != true) {
        throw Exception(decoded['message'] ?? 'Unknown error');
      }

      final data = decoded['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid detail payload');
      }

      return GroupPaymentDetail.fromJson(data);
    } catch (e) {
      debugPrint('Error fetching group payment detail: $e');
      return null;
    }
  }

  Future<void> _ensureOtherUserId() async {
    // If already determined or this is a group chat, nothing to do
    if (_isGroupChat || _otherUserId != null) return;

    final me = _currentUserId;
    if (me == null) return;

    // Try to infer from existing messages (any non-system sender that is not me)
    for (final m in _messages) {
      if (!m.isSystem && m.senderId != 0 && m.senderId != me) {
        _otherUserId = m.senderId;
        debugPrint('Derived _otherUserId from messages: $_otherUserId');
        break;
      }
    }

    // If still null, fall back to reloading chatroom meta
    if (_otherUserId == null) {
      try {
        await _loadChatroomMeta();
        debugPrint('Reloaded chatroom meta, _otherUserId=$_otherUserId, _isGroupChat=$_isGroupChat');
      } catch (_) {
        // ignore
      }
    }
  }

  Future<void> _openPaymentRequestSheet() async {
    // Make sure we have the other user id for 1-to-1 chat
    await _ensureOtherUserId();

    if (_isGroupChat || _otherUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Payment request is only available in 1-to-1 chats.'),
        ),
      );
      return;
    }

    final amountCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final friendName = widget.chatTitle;
        return Padding(
          padding: EdgeInsets.only(
            left: 12,
            right: 12,
            top: 12,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.96),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: Colors.black.withOpacity(0.06),
                    width: 0.7,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.request_page_outlined,
                            size: 18,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'New payment request',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Request from $friendName',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        labelText: 'Amount (RM)',
                        prefixText: 'RM ',
                        filled: true,
                        fillColor: const Color(0xFFF3F4F6),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: noteCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Note (optional)',
                        filled: true,
                        fillColor: const Color(0xFFF6F7FB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 4),
                        ElevatedButton(
                          onPressed: () {
                            final raw = amountCtrl.text.trim();
                            final amount = double.tryParse(raw);
                            if (amount == null || amount <= 0) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(
                                  content: Text('Please enter a valid amount.'),
                                ),
                              );
                              return;
                            }
                            Navigator.of(ctx).pop({
                              'amount': amount,
                              'note': noteCtrl.text.trim(),
                            });
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          child: const Text('Send request'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (result == null) return;

    final amount = result['amount'] as double;
    final note = (result['note'] as String).isEmpty
        ? null
        : result['note'] as String;
    await _createPaymentRequest(amount, note);
  }

  Future<void> _createPaymentRequest(double amount, String? note) async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        throw Exception('Not logged in');
      }
      if (_otherUserId == null) {
        throw Exception('No target user found for this chatroom');
      }

      final uri = Uri.parse('${ApiConfig.baseUrl}/paychat/payment-requests');
      final body = jsonEncode({
        'chatroomId': widget.chatroomId,
        'toUserId': _otherUserId,
        'amount': amount,
        'note': note,
      });

      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: body,
      );

      if (resp.statusCode != 200) {
        throw Exception('Failed to create request (${resp.statusCode})');
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response');
      }
      if (decoded['success'] != true) {
        throw Exception(decoded['message'] ?? 'Unknown error');
      }

      // Backend will push the new payment-request bubble via WebSocket.
      // As a fallback, refresh messages.
      await _loadMessages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment request sent.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create request: $e')),
      );
    }
  }

  Future<void> _payPaymentRequest(PaymentRequestSummary pr) async {
    try {
      final token = await _getAccessToken();
      if (token == null) {
        throw Exception('Not logged in');
      }

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/paychat/payment-requests/${pr.requestId}/pay',
      );

      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (resp.statusCode != 200) {
        throw Exception('Failed to pay (${resp.statusCode})');
      }
      final decoded = jsonDecode(resp.body);
      if (decoded is! Map<String, dynamic>) {
        throw Exception('Unexpected response');
      }
      if (decoded['success'] != true) {
        throw Exception(decoded['message'] ?? 'Unknown error');
      }

      await _loadMessages();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment successful.'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pay: $e')),
      );
    }
  }
  

  /// Modern glass-style chat bubble UI (iOS glass light mode)
  Widget _buildMessageBubble(ChatMessage m) {
    final isMine = _currentUserId != null && m.senderId == _currentUserId;
    final isSystem = m.isSystem;

    debugPrint(
      'Bubble for msgId=${m.messageId}, senderId=${m.senderId}, '
      'currentUserId=$_currentUserId, isMine=$isMine',
    );

    final pr = m.paymentRequest;
    final isPaymentRequest =
        m.type.toUpperCase() == 'PAYMENT_REQUEST' && pr != null;

    final gp = m.groupPayment;
    final isGroupPayment =
        m.type.toUpperCase() == 'GROUP_PAYMENT' && gp != null;

    if (isGroupPayment) {
      final detail = _groupPayments[gp!.groupPaymentId];
      return _buildGroupPaymentCard(m, gp, detail);
    }

    // System message = center pill chip, light style
    if (isSystem) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F7),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: Colors.black.withOpacity(0.06),
                  width: 0.6,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                m.text ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      );
    }

    if (isPaymentRequest) {
      final isTarget = _currentUserId != null && pr!.toUserId == _currentUserId;
      final isRequester = _currentUserId != null && pr.fromUserId == _currentUserId;
      final statusUpper = pr.status.toUpperCase();
      final canPay = isTarget && statusUpper == 'PENDING';

      // Whose money flow? Labels for clarity
      final friendName = widget.chatTitle;
      final fromLabel = isRequester ? 'You' : friendName;
      final toLabel = isTarget ? 'You' : friendName;

      // Text variations depending on who is viewing
      final titleText = isRequester
          ? 'You requested a payment'
          : (isTarget
              ? '$friendName requested a payment'
              : 'Payment request');

      final footerText = canPay
          ? 'Tap to pay by NexPay'
          : (statusUpper == 'PAID'
              ? 'Paid via NexPay'
              : 'Waiting on payment');

      // From/to description so user can see who requested from who
      String fromToText = '$fromLabel → $toLabel';

      // Card colors depending on status & role
      Color cardColor;
      Color pillColor;
      Color pillTextColor;
      Color sideStripeColor;
      if (statusUpper == 'PENDING') {
        // Lime for pending, but slightly different accent depending on role
        cardColor = const Color(0xFFC6E87A); // light lime
        pillColor = Colors.black.withOpacity(0.08);
        pillTextColor = Colors.black87;
        sideStripeColor = isRequester
            ? const Color(0xFF1E8449) // green for "you requested"
            : const Color(0xFF0A84FF); // blue for "you need to pay"
      } else if (statusUpper == 'PAID') {
        cardColor = const Color(0xFFD8F5F0); // soft teal
        pillColor = const Color(0xFF1ABC9C);
        pillTextColor = Colors.white;
        sideStripeColor = const Color(0xFF1ABC9C);
      } else {
        cardColor = const Color(0xFFE5E5EA); // neutral grey
        pillColor = Colors.black.withOpacity(0.12);
        pillTextColor = Colors.black87;
        sideStripeColor = Colors.black26;
      }

      return Padding
        (
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: GestureDetector(
            onTap: canPay ? () => _confirmPayPaymentRequest(pr) : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.9,
              ),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Colored side stripe to indicate role
                  Container(
                    width: 4,
                    height: 72,
                    decoration: BoxDecoration(
                      color: sideStripeColor,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Main card content
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Left icon circle
                            Container(
                              width: 36,
                              height: 36,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.swap_horiz,
                                  size: 18,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RM ${pr.amount.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    titleText,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.7),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          fromToText,
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black.withOpacity(0.8),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if ((pr.note ?? '').isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            pr.note!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.black.withOpacity(0.75),
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        // Divider line
                        Container(
                          height: 1,
                          width: double.infinity,
                          color: Colors.white.withOpacity(0.8),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                footerText,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: pillColor,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    statusUpper,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: pillTextColor,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _formatTime(m.createdAt),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.black.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (isGroupPayment) {
      final statusUpper = gp!.status.toUpperCase();
      final isClosed = statusUpper == 'CLOSED';
      final title = gp.title.isNotEmpty ? gp.title : 'Group payment';
      final totalLabel = 'Total: RM ${gp.totalAmount.toStringAsFixed(0)}';

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => _openGroupPaymentDetailSheet(gp),
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              margin: const EdgeInsets.only(right: 40),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.black.withOpacity(0.06),
                  width: 0.7,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + total
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          totalLabel,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Simple progress bar placeholder; actual ratio shown in detail sheet
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: Container(
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E5EA),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: isClosed ? 1.0 : 0.3,
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isClosed ? 'Fully paid' : 'Tap to view who has paid',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        _formatTime(m.createdAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final bubbleAlignment =
        isMine ? Alignment.centerRight : Alignment.centerLeft;

    final bgGradient = isMine
        ? const LinearGradient(
            colors: [
              Color(0xFF0A84FF),
              Color(0xFF4C6FFF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : const LinearGradient(
            colors: [
              Color(0xFFF6F7FB),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          );

    final textColor = isMine ? Colors.white : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment: bubbleAlignment,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment:
              isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!isMine) ...[
                CircleAvatar(
                radius: 16,
                backgroundColor: Colors.white,
                
                child: Text(
                  (() {
                  final name = _memberNamesById[m.senderId] ?? widget.chatTitle ?? '';
                  return name.isNotEmpty ? name[0].toUpperCase() : '?';
                  })(),
                  style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                  ),
                ),
                ),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: isMine
                      ? const Radius.circular(18)
                      : const Radius.circular(6),
                  bottomRight: isMine
                      ? const Radius.circular(6)
                      : const Radius.circular(18),
                ),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    decoration: BoxDecoration(
                      gradient: bgGradient,
                      border: Border.all(
                        color: isMine
                            ? Colors.white.withOpacity(0.4)
                            : Colors.black.withOpacity(0.06),
                        width: 0.7,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.07),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isMine
                          ? CrossAxisAlignment.end
                          : CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.text ?? '',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(m.createdAt),
                          style: TextStyle(
                            color: textColor.withOpacity(0.7),
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (isMine) const SizedBox(width: 4),
          ],
        ),
      ),
    );
  }

    Widget _buildGroupPaymentCard(
  ChatMessage m,
  GroupPaymentSummary summary,
  GroupPaymentDetail? detail,
) {
  final createdAtLabel = _formatTime(m.createdAt);

  final int memberCount = detail?.totalPeople ?? 0;
  final int paidCount = detail?.paidCount ?? 0;

  final bool isClosed =
      (detail?.isClosed ?? false) || summary.status.toUpperCase() == 'CLOSED';

  // Progress: based on people count (like "2/3 Paid")
  final double progress =
      memberCount > 0 ? paidCount / memberCount : 0.0;

  final myId = _currentUserId;
  GroupPaymentContribution? myContrib;
  if (detail != null && myId != null) {
    for (final c in detail.contributions) {
      if (c.userId == myId) {
        myContrib = c;
        break;
      }
    }
  }

  final bool isCreator =
      _currentUserId != null && m.senderId == _currentUserId;
  final bool isPayer = !isCreator && myContrib != null;
  final bool hasPaid = myContrib?.isPaid ?? false;
  final bool canPay = !isClosed && myContrib != null && !myContrib.isPaid;

  // 🔵 Background rules:
  // - Creator: white
  // - Payer & not yet paid: accentColor
  // - Payer & paid (or anyone else): white
  final Color cardBgColor = (isCreator || !isPayer || hasPaid)
      ? Colors.white
      : accentColor;

  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Align(
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: canPay && detail != null
            ? () => _confirmPayGroupContribution(detail)
            : null,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.9,
          ),
          decoration: BoxDecoration(
            color: cardBgColor,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isClosed
                  ? Colors.green.withOpacity(0.3)
                  : Colors.black.withOpacity(0.06),
              width: 0.7,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + total
              Row(
                children: [
                  Expanded(
                    child: Text(
                      summary.title.isNotEmpty
                          ? summary.title
                          : 'Group payment',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      'Total: RM ${summary.totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Progress bar + label
              if (detail != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    height: 6,
                    width: double.infinity,
                    color: const Color(0xFFE4E5EA),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: progress.clamp(0.0, 1.0),
                        child: Container(
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$paidCount/${memberCount == 0 ? "?" : memberCount} Paid',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
              ] else ...[
                const SizedBox(height: 4),
                Text(
                  'Loading participants…',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(height: 8),
              ],

              // Participants list (inside card)
              if (detail != null)
                Column(
                  children: detail.contributions.map((c) {
                    final bool isMe =
                        _currentUserId != null &&
                        c.userId == _currentUserId;
                    final label = isMe
                        ? 'You'
                        : (c.userName ?? 'Member');

                    final bool paid = c.isPaid;

                    final chipColor = paid
                        ? primaryColor
                        : primaryColor.withOpacity(0.12);
                    final chipTextColor =
                        paid ? accentColor : primaryColor;
                    final chipText = paid ? 'Paid' : 'Unpaid';

                          return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: const Color(0xFFE5E5EA),
                            child: Text(
                              (c.userName != null && c.userName!.isNotEmpty)
                                  ? c.userName![0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: chipColor,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              chipText,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: chipTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),

              const SizedBox(height: 6),

              // Footer row: left hint + time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isClosed
                          ? 'Fully paid'
                          : (canPay
                              ? 'Tap to pay your share'
                              : 'Waiting for others to pay'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    createdAtLabel,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: Colors.transparent,
      ),
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F2F6),
        body: SafeArea(
          child: Column(
            children: [
              // Glass AppBar - light iOS style
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.black.withOpacity(0.05),
                          width: 0.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: Colors.black87,
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const SizedBox(width: 4),
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.white,
                            child: Text(
                              widget.chatTitle.isNotEmpty
                                  ? widget.chatTitle[0].toUpperCase()
                                  : '?',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.chatTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Row(
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: Colors.greenAccent.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Secure chat',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.more_vert_rounded,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Chat area (glass container, light mode)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.black.withOpacity(0.07),
                            width: 0.8,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Expanded(
                              child: RefreshIndicator(
                                onRefresh: _loadMessages,
                                color: primaryColor,
                                backgroundColor: Colors.transparent,
                                child: _loading
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: primaryColor,
                                        ),
                                      )
                                    : _messages.isEmpty
                                        ? ListView(
                                            children: [
                                              const SizedBox(height: 80),
                                              Center(
                                                child: Text(
                                                  'No messages yet.\nSay hi 👋',
                                                  textAlign: TextAlign.center,
                                                  style: TextStyle(
                                                    color: Colors.grey[500],
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          )
                                        : ListView.builder(
                                            controller: _scrollCtrl,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 12,
                                            ),
                                            itemCount: _messages.length,
                                            itemBuilder: (context, index) {
                                              final m = _messages[index];
                                              return _buildMessageBubble(m);
                                            },
                                          ),
                              ),
                            ),

                            // Input bar
                            Divider(
                              height: 1,
                              color: Colors.black.withOpacity(0.04),
                            ),
                            SafeArea(
                              top: false,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                    10, 6, 10, 10),
                                child: Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline_rounded),
                                      color: Colors.grey[700],
                                      onPressed: _openActionsSheet,
                                    ),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: BackdropFilter(
                                          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFF3F4F6).withOpacity(0.95),
                                              borderRadius: BorderRadius.circular(24),
                                              border: Border.all(
                                                color: Colors.black.withOpacity(0.04),
                                                width: 0.7,
                                              ),
                                            ),
                                            child: TextField(
                                              controller: _inputCtrl,
                                              minLines: 1,
                                              maxLines: 4,
                                              style: const TextStyle(color: Colors.black87),
                                              textInputAction: TextInputAction.send,
                                              onSubmitted: (_) => _sendMessage(),
                                              decoration: InputDecoration(
                                                hintText: 'Type a message…',
                                                hintStyle: TextStyle(
                                                  color: Colors.grey[500],
                                                ),
                                                border: InputBorder.none,
                                                contentPadding: const EdgeInsets.symmetric(
                                                  horizontal: 14,
                                                  vertical: 10,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    ClipOval(
                                      child: Material(
                                        color: primaryColor,
                                        child: InkWell(
                                          onTap: _sending ? null : _sendMessage,
                                          child: SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: Center(
                                              child: _sending
                                                  ? const SizedBox(
                                                      width: 18,
                                                      height: 18,
                                                      child: CircularProgressIndicator(
                                                        strokeWidth: 2,
                                                        valueColor: AlwaysStoppedAnimation<Color>(
                                                            Colors.white),
                                                      ),
                                                    )
                                                  : const Icon(
                                                      Icons.send_rounded,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}