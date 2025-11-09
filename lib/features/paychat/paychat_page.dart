import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nex_pay_app/core/constants/colors.dart';
import 'package:nex_pay_app/widgets/nex_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:nex_pay_app/router.dart';

class PayChatPage extends StatefulWidget {
  const PayChatPage({super.key});

  @override
  State<PayChatPage> createState() => _PayChatPageState();
}

class _PayChatPageState extends State<PayChatPage> {
  final List<Map<String, dynamic>> _chatRooms = [
    {
      "chatroom_id": 101,
      "user_id": 702,
      "name": "Luffy",
      "lastMessage": "Let's split the bill later.",
      "time": "10:24 AM"
    },
    {
      "chatroom_id": 102,
      "user_id": 704,
      "name": "Alice",
      "lastMessage": "Sent RM25 to you.",
      "time": "9:15 AM"
    },
    {
      "chatroom_id": 103,
      "user_id": 705,
      "name": "Marcus",
      "lastMessage": "Check your QR please.",
      "time": "Yesterday"
    },
    {
      "chatroom_id": 104,
      "user_id": 706,
      "name": "Family Group",
      "lastMessage": "Dinner payment shared.",
      "time": "Yesterday"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return NexScaffold(
      currentIndex: 2,
      body: Stack(
        children: [
          // ✅ Full gradient background (extends to the notch)
          AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light, // Keeps status bar icons visible
            child: Container(
              height: MediaQuery.of(context).size.height * 0.3, // Responsive height
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

          // ✅ Foreground Content
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                      IconButton(
                        icon: const Icon(Icons.settings_outlined, color: Colors.white),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Settings tapped")),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                // Search Bar
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
                          decoration: const InputDecoration(
                            hintText: "Search chats...",
                            border: InputBorder.none,
                            isDense: true,
                          ),
                          onSubmitted: (value) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("Searching for '$value'")),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ✅ Chat List
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.builder(
                      itemCount: _chatRooms.length,
                      itemBuilder: (context, index) {
                        final chat = _chatRooms[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
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
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              radius: 26,
                              backgroundColor: accentColor.withOpacity(0.9),
                              child: Text(
                                (chat["name"]?.isNotEmpty ?? false)
                                    ? chat["name"]![0].toUpperCase()
                                    : "?",
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            title: Text(
                              chat["name"] ?? "Unknown",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              chat["lastMessage"] ?? "",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                            trailing: Text(
                              chat["time"] ?? "",
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            onTap: () {
                              context.pushNamed(
                                RouteNames.chatroom,
                                extra: {
                                  'user_id': chat["user_id"],
                                  'user_name': chat["name"],
                                  'chatroom_id': chat["chatroom_id"],
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

          // ✅ Floating Button
          Positioned(
            bottom: 28,
            right: 24,
            child: FloatingActionButton.extended(
              heroTag: 'paychat_fab',
              backgroundColor: accentColor,
              foregroundColor: primaryColor,
              elevation: 5,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Start new chat")),
                );
              },
              label: const Text(
                "New Chat",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              icon: const Icon(Icons.chat_bubble_outline),
            ),
          ),
        ],
      ),
    );
  }
}