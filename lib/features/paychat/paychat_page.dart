import 'dart:convert';

import 'package:contacts_service/contacts_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:nex_pay_app/core/constants/api_config.dart';
import 'package:nex_pay_app/core/constants/colors.dart';
import 'package:nex_pay_app/core/service/secure_storage.dart';
import 'package:nex_pay_app/router.dart';
import 'package:nex_pay_app/widgets/nex_scaffold.dart';
import 'package:permission_handler/permission_handler.dart';

/// Simple model to map /api/paychat/chatrooms response
class PayChatRoom {
  final int chatroomId;
  final String type; // DIRECT or GROUP
  final String? title;
  final int? createdByUserId;
  final DateTime createdAt;
  final List<int> memberUserIds;

  /// Optional fields for nicer UI if backend later sends them
  final String? lastMessage;
  final String? lastMessageTimeLabel;
  final String displayName; // what we show in list

  PayChatRoom({
    required this.chatroomId,
    required this.type,
    required this.title,
    required this.createdByUserId,
    required this.createdAt,
    required this.memberUserIds,
    required this.displayName,
    this.lastMessage,
    this.lastMessageTimeLabel,
  });

  /// Safely convert dynamic -> int (handles int, double, String)
  static int _toInt(dynamic v, {int defaultValue = 0}) {
    if (v == null) return defaultValue;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) {
      return int.tryParse(v) ?? defaultValue;
    }
    return defaultValue;
  }

  factory PayChatRoom.fromJson(
    Map<String, dynamic> json,
    int currentUserId,
  ) {
    final dynamic membersAny = json['memberUserIds'];
    final List<int> members = [];
    if (membersAny is List) {
      for (final item in membersAny) {
        final id = _toInt(item);
        if (id != 0) members.add(id);
      }
    }

    final int id = _toInt(json['chatroomId']);
    final String type = json['type']?.toString().toUpperCase() ?? 'DIRECT';
    final String? title =
        json['title'] != null ? json['title'].toString() : null;

    // Prefer backend-provided title for both DIRECT and GROUP chats.
    // For DIRECT chats, backend now sets title to the opposite username.
    String computedDisplayName;
    if (title != null && title.trim().isNotEmpty) {
      computedDisplayName = title.trim();
    } else if (type == 'GROUP') {
      computedDisplayName = 'Group chat #$id';
    } else {
      computedDisplayName = 'Chat #$id';
    }

    final createdByRaw = json['createdByUserId'];
    final int? createdById =
        createdByRaw == null ? null : _toInt(createdByRaw, defaultValue: 0);

    final createdAtStr = json['createdAt']?.toString();
    final createdAt =
        createdAtStr != null ? DateTime.tryParse(createdAtStr) : null;

    return PayChatRoom(
      chatroomId: id,
      type: type,
      title: title,
      createdByUserId: createdById == 0 ? null : createdById,
      createdAt: createdAt ?? DateTime.now(),
      memberUserIds: members,
      displayName: computedDisplayName,
      lastMessage: (json['lastMessage'] ??
              json['last_message'])
              ?.toString(),

      lastMessageTimeLabel: (json['lastMessageTime'] ??
                            json['last_message_time'])
                            ?.toString(),
    );
  }
}

/// Preview of a user found by phone number for DIRECT chat
class PaychatUserPreview {
  final int userId;
  final String phone;
  final String name;
  final String? avatarUrl;

  const PaychatUserPreview({
    required this.userId,
    required this.phone,
    required this.name,
    this.avatarUrl,
  });

  factory PaychatUserPreview.fromJson(Map<String, dynamic> json) {
    final rawId = json['userId'] ?? json['user_id'];
    final id = (rawId is int)
        ? rawId
        : int.tryParse(rawId?.toString() ?? '') ?? 0;

    return PaychatUserPreview(
      userId: id,
      phone: (json['phoneNum'] ?? json['phone'] ?? '').toString(),
      name: (json['userName'] ??
              json['username'] ??
              json['name'] ??
              '')
          .toString(),
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

class PayChatPage extends StatefulWidget {
  const PayChatPage({super.key});

  @override
  State<PayChatPage> createState() => _PayChatPageState();
}

class _PayChatPageState extends State<PayChatPage> {
  final TextEditingController _searchCtrl = TextEditingController();

  // use same alias as in LoginPage
  static const _secure = secureStorage;

  bool _loading = false;
  List<PayChatRoom> _chatRooms = [];

  @override
  void initState() {
    super.initState();
    _loadChatrooms();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// 🔑 Get JWT token from FlutterSecureStorage (key: 'token')
  Future<String?> _getAccessToken() async {
    return await _secure.read(key: 'token');
  }

  /// 👤 Get current user id from FlutterSecureStorage (key: 'user_id')
  Future<int?> _getCurrentUserId() async {
    final value = await _secure.read(key: 'user_id');
    if (value == null) return null;
    return int.tryParse(value);
  }

  Future<void> _loadChatrooms() async {
    setState(() => _loading = true);

    try {
      final token = await _getAccessToken();
      final currentUserId = await _getCurrentUserId();

      if (token == null || currentUserId == null) {
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
        throw Exception('Failed to load chatrooms (${resp.statusCode})');
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
        throw Exception('Expected a list of chatrooms');
      }

      final rooms = data
          .where((e) => e is Map<String, dynamic>)
          .map((e) => PayChatRoom.fromJson(
                e as Map<String, dynamic>,
                currentUserId,
              ))
          .toList();

      // Sort descending by createdAt (newest first)
      rooms.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _chatRooms = rooms;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load chats: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openNewChatSheet() async {
    final token = await _getAccessToken();
    final currentUserId = await _getCurrentUserId();

    if (token == null || currentUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please log in again.')),
        );
      }
      return;
    }

    final createdRoom = await showModalBottomSheet<PayChatRoom>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: _NewChatSheet(
            accessToken: token,
            currentUserId: currentUserId,
          ),
        );
      },
    );

    if (!mounted) return;

    if (createdRoom != null) {
      await _loadChatrooms();
      context.pushNamed(
        RouteNames.chatroom,
        extra: {
          'user_id': null,
          'username': createdRoom.displayName,
          'chatroom_id': createdRoom.chatroomId,
        },
      );
    }
  }

  List<PayChatRoom> get _filteredRooms {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) return _chatRooms;
    return _chatRooms
        .where((r) =>
            r.displayName.toLowerCase().contains(q) ||
            (r.lastMessage ?? '').toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return NexScaffold(
      currentIndex: 2,
      body: Stack(
        children: [
          // Gradient header background
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.3,
              width: double.infinity,
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
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header row
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "PayChat",
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Row(
                        children: [
                          IconButton(
                            tooltip: 'New Chat',
                            icon: const Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.white,
                            ),
                            onPressed: _openNewChatSheet,
                          ),
                          
                        ],
                      ),
                    ],
                  ),
                ),

                // Search bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, color: Colors.grey),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: const InputDecoration(
                            hintText: "Search chats...",
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Chat list
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadChatrooms,
                    child: _loading && _chatRooms.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : _filteredRooms.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 60),
                                  Center(
                                    child: Text(
                                      "No chats yet.\nTap the chat icon on top to start one.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.grey),
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                itemCount: _filteredRooms.length,
                                itemBuilder: (context, index) {
                                  final chat = _filteredRooms[index];

                                  final subtitle =
                                      chat.lastMessage ?? 'No messages yet';
                                  final timeLabel =
                                      chat.lastMessageTimeLabel ?? '';

                                  return Container(
                                    margin:
                                        const EdgeInsets.only(bottom: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.05),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 8),
                                      leading: CircleAvatar(
                                        radius: 26,
                                        backgroundColor:
                                            accentColor.withOpacity(0.9),
                                        child: Text(
                                          (chat.displayName.isNotEmpty)
                                              ? chat.displayName[0]
                                                  .toUpperCase()
                                              : "?",
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              chat.displayName,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 16,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                          if (chat.type == 'GROUP')
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.green
                                                    .withOpacity(0.12),
                                                borderRadius:
                                                    BorderRadius.circular(999),
                                              ),
                                              child: const Text(
                                                "Group",
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.green,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                      subtitle: Text(
                                        subtitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                      trailing: Text(
                                        timeLabel,
                                        style: TextStyle(
                                          color: Colors.grey[500],
                                          fontSize: 12,
                                        ),
                                      ),
                                      onTap: () {
                                        context.pushNamed(
                                          RouteNames.chatroom,
                                          extra: {
                                            'user_id': null,
                                            'username': chat.displayName,
                                            'chatroom_id': chat.chatroomId,
                                          },
                                        );
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet to create DIRECT / GROUP chat
class _NewChatSheet extends StatefulWidget {
  final String accessToken;
  final int currentUserId;

  const _NewChatSheet({
    required this.accessToken,
    required this.currentUserId,
  });

  @override
  State<_NewChatSheet> createState() => _NewChatSheetState();
}

class _NewChatSheetState extends State<_NewChatSheet> {
  String _type = 'DIRECT'; // or GROUP

  // DIRECT mode
  final TextEditingController _phoneCtrl = TextEditingController();
  bool _lookingUp = false;
  PaychatUserPreview? _preview;
  String? _lookupError;

  // GROUP mode
  final TextEditingController _groupTitleCtrl = TextEditingController();
  final TextEditingController _groupPhoneCtrl = TextEditingController();
  bool _groupLookingUp = false;
  String? _groupLookupError;
  final List<PaychatUserPreview> _selectedGroupMembers = [];

  bool _submitting = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _groupTitleCtrl.dispose();
    _groupPhoneCtrl.dispose();
    super.dispose();
  }

  String _normalizePhone(String input) {
    // keep digits and leading +
    final cleaned = input.replaceAll(RegExp(r'[^0-9+]'), '');
    if (cleaned.startsWith('++')) {
      return cleaned.replaceAll('+', '');
    }
    return cleaned;
  }

  Future<void> _lookupByPhone() async {
    final phoneRaw = _phoneCtrl.text.trim();
    if (phoneRaw.isEmpty) {
      setState(() {
        _lookupError = 'Please enter a phone number';
        _preview = null;
      });
      return;
    }

    final phone = _normalizePhone(phoneRaw);

    setState(() {
      _lookingUp = true;
      _lookupError = null;
      _preview = null;
      _phoneCtrl.text = phone;
    });

    try {
      // Debug logging to help diagnose issues
      debugPrint('🔍 PayChat lookup: phoneRaw=\"$phoneRaw\", normalized=\"$phone\"');

      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/paychat/search-user-by-phone'
        '?phone=${Uri.encodeQueryComponent(phone)}',
      );
      debugPrint('🔍 Requesting: $uri');

      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      debugPrint('🔍 Status: ${resp.statusCode}');
      debugPrint('🔍 Body: ${resp.body}');

      Map<String, dynamic>? bodyJson;
      try {
        final decodedBody = jsonDecode(resp.body);
        if (decodedBody is Map<String, dynamic>) {
          bodyJson = decodedBody;
        }
      } catch (_) {
        bodyJson = null;
      }

      final backendMessage = bodyJson != null && bodyJson['message'] != null
          ? bodyJson['message'].toString()
          : '';

      // Special handling for "user not found" case: show friendly text instead of generic error
      if (resp.statusCode == 400 &&
          backendMessage.toLowerCase().contains('user not found')) {
        if (!mounted) return;
        setState(() {
          _preview = null;
          _lookupError = 'User not found or not registered on NexPay';
        });
        return;
      }

      if (resp.statusCode != 200) {
        // For other errors, bubble up a clearer message if possible
        if (backendMessage.isNotEmpty) {
          throw Exception(backendMessage);
        }
        throw Exception('Status ${resp.statusCode}');
      }

      if (bodyJson == null) {
        throw Exception('Unexpected response');
      }
      if (bodyJson['success'] != true) {
        throw Exception(bodyJson['message']?.toString() ?? 'User not found');
      }

      final data = bodyJson['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid user data');
      }

      final preview = PaychatUserPreview.fromJson(data);

      if (!mounted) return;
      setState(() {
        _preview = preview;
        _lookupError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _preview = null;
        // Show a cleaned-up error message
        final msg = e.toString();
        _lookupError = msg.startsWith('Exception: ')
            ? msg.substring('Exception: '.length)
            : msg;
      });
    } finally {
      if (mounted) setState(() => _lookingUp = false);
    }
  }

  /// FULL SCREEN CONTACT LIST (like Touch 'n Go)
  Future<void> _openContactsPage() async {
    final Contact? selected = await Navigator.of(context).push<Contact>(
      MaterialPageRoute(
        builder: (_) => const _ContactListPage(),
        fullscreenDialog: true,
      ),
    );

    if (selected == null) return;

    final phone = (selected.phones?.isNotEmpty ?? false)
        ? (selected.phones!.first.value ?? '')
        : '';

    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selected contact has no phone')),
        );
      }
      return;
    }

    final normalized = _normalizePhone(phone);

    setState(() {
      _phoneCtrl.text = normalized;
    });

    // auto lookup after picking
    await _lookupByPhone();
  }

  Future<void> _lookupGroupMemberByPhone() async {
    final phoneRaw = _groupPhoneCtrl.text.trim();
    if (phoneRaw.isEmpty) {
      setState(() {
        _groupLookupError = 'Please enter a phone number';
      });
      return;
    }

    final phone = _normalizePhone(phoneRaw);

    setState(() {
      _groupLookingUp = true;
      _groupLookupError = null;
      _groupPhoneCtrl.text = phone;
    });

    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/paychat/search-user-by-phone'
        '?phone=${Uri.encodeQueryComponent(phone)}',
      );

      final resp = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
      );

      Map<String, dynamic>? bodyJson;
      try {
        final decodedBody = jsonDecode(resp.body);
        if (decodedBody is Map<String, dynamic>) {
          bodyJson = decodedBody;
        }
      } catch (_) {
        bodyJson = null;
      }

      final backendMessage = bodyJson != null && bodyJson['message'] != null
          ? bodyJson['message'].toString()
          : '';

      if (resp.statusCode == 400 &&
          backendMessage.toLowerCase().contains('user not found')) {
        if (!mounted) return;
        setState(() {
          _groupLookupError = 'User not found or not registered on NexPay';
        });
        return;
      }

      if (resp.statusCode != 200) {
        if (backendMessage.isNotEmpty) {
          throw Exception(backendMessage);
        }
        throw Exception('Status ${resp.statusCode}');
      }

      if (bodyJson == null || bodyJson['success'] != true) {
        throw Exception(bodyJson?['message']?.toString() ?? 'User not found');
      }

      final data = bodyJson['data'];
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid user data');
      }

      final user = PaychatUserPreview.fromJson(data);

      if (!mounted) return;

      final alreadySelected =
          _selectedGroupMembers.any((m) => m.userId == user.userId);
      if (alreadySelected) {
        setState(() {
          _groupLookupError = 'User already added to group';
        });
        return;
      }

      setState(() {
        _selectedGroupMembers.add(user);
        _groupPhoneCtrl.clear();
        _groupLookupError = null;
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      setState(() {
        _groupLookupError = msg.startsWith('Exception: ')
            ? msg.substring('Exception: '.length)
            : msg;
      });
    } finally {
      if (mounted) setState(() => _groupLookingUp = false);
    }
  }

  Future<void> _openContactsPageForGroup() async {
    final Contact? selected = await Navigator.of(context).push<Contact>(
      MaterialPageRoute(
        builder: (_) => const _ContactListPage(),
        fullscreenDialog: true,
      ),
    );

    if (selected == null) return;

    final phone = (selected.phones?.isNotEmpty ?? false)
        ? (selected.phones!.first.value ?? '')
        : '';

    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selected contact has no phone')),
      );
      return;
    }

    final normalized = _normalizePhone(phone);
    _groupPhoneCtrl.text = normalized;
    await _lookupGroupMemberByPhone();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    setState(() => _submitting = true);

    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/paychat/chatrooms');

      final Map<String, dynamic> payload = {
        'type': _type,
      };

      if (_type == 'DIRECT') {
        // ensure we have preview
        if (_preview == null) {
          await _lookupByPhone();
        }
        if (_preview == null) {
          throw Exception('Please select a valid NexPay user first');
        }
        payload['otherUserId'] = _preview!.userId;
      } else {
        final title = _groupTitleCtrl.text.trim();
        if (title.isEmpty) {
          throw Exception('Please enter group name');
        }
        payload['title'] = title;

        if (_selectedGroupMembers.isEmpty) {
          throw Exception('Please add at least one member to the group');
        }

        final ids = <int>{
          ..._selectedGroupMembers.map((u) => u.userId),
          widget.currentUserId,
        }.toList();

        payload['memberUserIds'] = ids;
      }

      final resp = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer ${widget.accessToken}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (resp.statusCode != 200) {
        throw Exception('Failed to create chat (${resp.statusCode})');
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
        throw Exception('Expected chatroom object in response');
      }

      final room = PayChatRoom.fromJson(data, widget.currentUserId);

      if (!mounted) return;

      // Decide what to show as the chat title in the ChatroomPage
      // For DIRECT chats, prefer the other user's name from _preview
      String chatTitle;
      if (_type == 'DIRECT' && _preview != null && _preview!.name.isNotEmpty) {
        chatTitle = _preview!.name;
      } else {
        // For GROUP chats or fallback, use the room displayName
        chatTitle = room.displayName;
      }

      // Close the bottom sheet
      Navigator.of(context).pop();

      // Navigate straight into the chatroom with the chosen title
      context.pushNamed(
        RouteNames.chatroom,
        extra: {
          'user_id': null,
          'username': chatTitle,
          'chatroom_id': room.chatroomId,
        },
      );
      return;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20)
          .copyWith(top: 16, bottom: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const Text(
            'Start New Chat',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Individual'),
                    value: 'DIRECT',
                    groupValue: _type,
                    dense: true,
                    onChanged: (v) {
                      setState(() => _type = v ?? 'DIRECT');
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Group'),
                    value: 'GROUP',
                    groupValue: _type,
                    dense: true,
                    onChanged: (v) {
                      setState(() => _type = v ?? 'GROUP');
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (_type == 'DIRECT') ...[
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Friend phone number',
                hintText: 'e.g. 0123456789',
                prefixIcon: const Icon(Icons.phone_rounded),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: _lookingUp
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  onPressed: _lookingUp ? null : _lookupByPhone,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _openContactsPage,
                icon: const Icon(Icons.contacts_outlined, size: 18),
                label: const Text('Choose from contacts'),
              ),
            ),
            if (_lookupError != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _lookupError!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                ),
              ),
            if (_preview != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6F8FB),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E4EE)),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: primaryColor.withOpacity(0.15),
                      child: Text(
                        _preview!.name.isNotEmpty
                            ? _preview!.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _preview!.name.isNotEmpty
                                ? _preview!.name
                                : 'NexPay user',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _preview!.phone,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'On NexPay',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green,
                                    fontWeight: FontWeight.w600,
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
              ),
            ],
          ] else ...[
            TextField(
              controller: _groupTitleCtrl,
              decoration: const InputDecoration(
                labelText: 'Group name',
                hintText: 'e.g. Family Dinner',
                prefixIcon: Icon(Icons.group_outlined),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _groupPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Add member by phone',
                hintText: 'e.g. 0123456789',
                prefixIcon: const Icon(Icons.person_add_alt_1_outlined),
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: _groupLookingUp
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                  onPressed:
                      _groupLookingUp ? null : _lookupGroupMemberByPhone,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _openContactsPageForGroup,
                icon: const Icon(Icons.contacts_outlined, size: 18),
                label: const Text('Add from contacts'),
              ),
            ),
            if (_groupLookupError != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _groupLookupError!,
                  style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                  ),
                ),
              ),
            if (_selectedGroupMembers.isNotEmpty) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Selected members',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _selectedGroupMembers.map((u) {
                  final displayName =
                      u.name.isNotEmpty ? u.name : u.phone;
                  return Chip(
                    label: Text(displayName),
                    avatar: CircleAvatar(
                      child: Text(
                        (displayName.isNotEmpty
                                ? displayName[0]
                                : '?')
                            .toUpperCase(),
                      ),
                    ),
                    onDeleted: () {
                      setState(() {
                        _selectedGroupMembers
                            .removeWhere((m) => m.userId == u.userId);
                      });
                    },
                  );
                }).toList(),
              ),
            ],
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Create',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// FULL SCREEN CONTACT LIST PAGE
class _ContactListPage extends StatefulWidget {
  const _ContactListPage({Key? key}) : super(key: key);

  @override
  State<_ContactListPage> createState() => _ContactListPageState();
}

class _ContactListPageState extends State<_ContactListPage> {
  List<Contact> _contacts = [];
  List<Contact> _filtered = [];
  bool _loading = false;
  bool _permissionDenied = false;
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initContacts();
    _searchCtrl.addListener(_applyFilter);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilter);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _initContacts() async {
    setState(() {
      _loading = true;
      _permissionDenied = false;
    });

    final status = await Permission.contacts.request();
    debugPrint('Contacts permission status: $status');

    if (!status.isGranted) {
      if (!mounted) return;
      setState(() {
        _permissionDenied = true;
        _loading = false;
        _contacts = [];
        _filtered = [];
      });
      return;
    }

    await _loadContactsInternal();
  }

  Future<void> _loadContactsInternal() async {
    try {
      final contacts =
          await ContactsService.getContacts(withThumbnails: false);

      contacts.sort((a, b) {
        final na = a.displayName ?? '';
        final nb = b.displayName ?? '';
        return na.toLowerCase().compareTo(nb.toLowerCase());
      });

      if (mounted) {
        setState(() {
          _contacts = contacts;
          _filtered = contacts;
          _loading = false;
          _permissionDenied = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Unable to access contacts. Please check app permission.'),
          ),
        );
      }
    }
  }

  void _applyFilter() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filtered = _contacts);
      return;
    }

    setState(() {
      _filtered = _contacts.where((c) {
        final name = (c.displayName ?? '').toLowerCase();
        final phone = (c.phones?.isNotEmpty ?? false)
            ? (c.phones!.first.value ?? '').toLowerCase()
            : '';
        return name.contains(q) || phone.contains(q);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final showEmptyState = !_loading && (_permissionDenied || _filtered.isEmpty);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop<Contact>(null),
        ),
        title: const Text('Select contact'),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // search
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search contacts',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : showEmptyState
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _permissionDenied
                                  ? 'Contacts permission is required to show your contact list.'
                                  : 'No contacts found',
                              style: const TextStyle(color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                            if (_permissionDenied) ...[
                              const SizedBox(height: 8),
                              const Text(
                                'You can change this later in Settings > NexPay > Contacts.',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filtered.length,
                        itemBuilder: (context, index) {
                          final c = _filtered[index];
                          final name = c.displayName ?? 'Unknown';
                          final phone = (c.phones?.isNotEmpty ?? false)
                              ? (c.phones!.first.value ?? '')
                              : '';

                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor:
                                  primaryColor.withOpacity(0.15),
                              child: Text(
                                name.isNotEmpty
                                    ? name[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(name),
                            subtitle: Text(
                              phone.isNotEmpty ? phone : 'No phone number',
                              style: TextStyle(
                                color: phone.isNotEmpty
                                    ? Colors.black54
                                    : Colors.redAccent,
                              ),
                            ),
                            onTap: phone.isEmpty
                                ? null
                                : () {
                                    Navigator.of(context).pop<Contact>(c);
                                  },
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}