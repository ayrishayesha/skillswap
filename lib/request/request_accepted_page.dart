import 'package:flutter/material.dart';
import 'package:my_app/screen/chats_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RequestAcceptedPage extends StatefulWidget {
  final String requestId;

  const RequestAcceptedPage({super.key, required this.requestId});

  @override
  State<RequestAcceptedPage> createState() => _RequestAcceptedPageState();
}

class _RequestAcceptedPageState extends State<RequestAcceptedPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  Map? requestData;
  Map? helperData;

  @override
  void initState() {
    super.initState();
    _loadRequest();
  }

  Future<void> _loadRequest() async {
    try {
      final data = await supabase
          .from('request')
          .select('''
            id,
            subject,
            status,
            learner_id,
            helper_id,
            helper:profiles!helper_id (
              id,
              full_name,
              avatar_url,
              department
            )
          ''')
          .eq('id', widget.requestId)
          .single();

      setState(() {
        requestData = data;
        helperData = data['helper'];
        loading = false;
      });
    } catch (e) {
      print("ERROR => $e");
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Request Accepted"), centerTitle: true),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : requestData == null
          ? const Center(child: Text("Failed to load data"))
          : _body(),
    );
  }

  Widget _body() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 20),
          const CircleAvatar(
            radius: 40,
            backgroundColor: Color(0xFFE3F2FD),
            child: Icon(Icons.check_circle, size: 50, color: Colors.blue),
          ),
          const SizedBox(height: 20),
          const Text(
            "Request Accepted!",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            "Helper is ready to help you.",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          _helperCard(),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _goToChat,
              icon: const Icon(Icons.chat),
              label: const Text("Go to Chat", style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }

  Widget _helperCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 8)],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundImage:
                helperData?['avatar_url'] != null &&
                    helperData!['avatar_url'].toString().isNotEmpty
                ? NetworkImage(helperData!['avatar_url'])
                : null,
            child: helperData?['avatar_url'] == null
                ? const Icon(Icons.person, size: 30)
                : null,
          ),
          const SizedBox(height: 10),
          Text(
            helperData?['full_name'] ?? '',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            helperData?['department'] ?? '',
            style: const TextStyle(color: Colors.grey),
          ),
          const Divider(height: 30),
          Text(
            'Subject: ${requestData?['subject'] ?? ''}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  void _goToChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatsScreen(
          requestId: requestData!['id'],
          currentUserId: requestData!['learner_id'],
          otherUserId: requestData!['helper_id'],
          otherUserName: helperData!['full_name'],
        ),
      ),
    );
  }
}
