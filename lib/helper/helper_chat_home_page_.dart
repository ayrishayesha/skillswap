import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_app/screen/chats_screen.dart';

class HelperChatHomePage extends StatefulWidget {
  const HelperChatHomePage({super.key});

  @override
  State<HelperChatHomePage> createState() => _HelperChatHomePageState();
}

class _HelperChatHomePageState extends State<HelperChatHomePage> {
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
      // Get distinct learners who sent messages to this helper
      final data = await supabase
          .from('messages')
          .select('*, sender:profiles!sender_id(id, full_name, avatar_url)')
          .eq('receiver_id', user.id)
          .order('created_at', ascending: false);

      // Group by sender_id to get latest per learner
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
        loading = false;
      });
    } catch (e) {
      print("ERROR loading conversations: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chats"),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              // Navigate to helper profile page
            },
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: conversations.length,
              itemBuilder: (context, index) {
                final convo = conversations[index];
                final sender = convo['sender'];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundImage: sender['avatar_url'] != null
                        ? NetworkImage(sender['avatar_url'])
                        : null,
                    child: sender['avatar_url'] == null
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  title: Text(sender['full_name'] ?? 'Learner'),
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
                          otherUserId: sender['id'],
                          otherUserName: sender['full_name'],
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
