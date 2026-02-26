import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_app/screen/chats_screen.dart';

class ChatHomePage extends StatefulWidget {
  final bool isHelper;

  const ChatHomePage({super.key, required this.isHelper});

  @override
  State<ChatHomePage> createState() => _ChatHomePageState();
}

class _ChatHomePageState extends State<ChatHomePage> {
  final supabase = Supabase.instance.client;
  bool loading = true;
  List<Map> conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      if (widget.isHelper) {
        final data = await supabase
            .from('messages')
            .select('*, sender:profiles!sender_id(id, full_name, avatar_url)')
            .eq('receiver_id', user.id)
            .order('created_at', ascending: false);

        Map<String, Map> latestPerLearner = {};
        for (var msg in data) {
          final senderId = msg['sender_id'];
          if (!latestPerLearner.containsKey(senderId) ||
              DateTime.parse(msg['created_at']).isAfter(
                DateTime.parse(latestPerLearner[senderId]!['created_at']),
              )) {
            latestPerLearner[senderId] = msg;
          }
        }
        setState(() {
          conversations = latestPerLearner.values.toList();
        });
      } else {
        final data = await supabase
            .from('messages')
            .select(
              '*, receiver:profiles!receiver_id(id, full_name, avatar_url)',
            )
            .eq('sender_id', user.id)
            .order('created_at', ascending: false);

        Map<String, Map> latestPerHelper = {};
        for (var msg in data) {
          final receiverId = msg['receiver_id'];
          if (!latestPerHelper.containsKey(receiverId) ||
              DateTime.parse(msg['created_at']).isAfter(
                DateTime.parse(latestPerHelper[receiverId]!['created_at']),
              )) {
            latestPerHelper[receiverId] = msg;
          }
        }
        setState(() {
          conversations = latestPerHelper.values.toList();
        });
      }
    } catch (e) {
      print("ERROR loading conversations: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        backgroundColor: Colors.blue,
        actions: [IconButton(icon: const Icon(Icons.person), onPressed: () {})],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final convo = conversations[index];
                final userInfo = widget.isHelper
                    ? convo['sender']
                    : convo['receiver'];

                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: userInfo['avatar_url'] != null
                        ? NetworkImage(userInfo['avatar_url'])
                        : null,
                    child: userInfo['avatar_url'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(
                    userInfo['full_name'] ??
                        (widget.isHelper ? 'Learner' : 'Helper'),
                  ),
                  subtitle: Text(convo['message'] ?? ''),
                  trailing: Text(
                    _formatTime(convo['created_at']),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatsScreen(
                          requestId: convo['request_id'],
                          currentUserId: supabase.auth.currentUser!.id,
                          otherUserId: userInfo['id'],
                          otherUserName: userInfo['full_name'],
                          role: widget.isHelper ? 'helper' : 'learner',
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  String _formatTime(String date) {
    final time = DateTime.parse(date).toLocal();
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return "Just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}
