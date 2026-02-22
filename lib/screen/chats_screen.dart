import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatsScreen extends StatefulWidget {
  final String requestId;
  final String currentUserId;
  final String otherUserId;
  final String otherUserName;

  const ChatsScreen({
    super.key,
    required this.requestId,
    required this.currentUserId,
    required this.otherUserId,
    required this.otherUserName,
  });

  @override
  State<ChatsScreen> createState() => _ChatsScreenState();
}

class _ChatsScreenState extends State<ChatsScreen> {
  final supabase = Supabase.instance.client;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> messages = [];
  RealtimeChannel? channel;

  // ================= TIMER =================
  Timer? _timer;

  int _remainingSeconds = 5; // 15 min

  bool _sessionEnded = false; // session finished or not

  bool _popupOpen = false; // popup multiple times open prevent

  int _extensionCount = 0; // কয়বার extend হয়েছে
  final int _maxExtension = 1; // শুধু ১ বার allow
  bool _alreadyExtended = false; // শুধু একবার extend allow
  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    _loadMessages();
    _subscribeToMessages();
    _startTimer();
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    _timer?.cancel();

    if (channel != null) {
      supabase.removeChannel(channel!);
    }

    _controller.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  // ================= LOAD MESSAGES =================
  Future<void> _loadMessages() async {
    final data = await supabase
        .from('messages')
        .select()
        .eq('request_id', widget.requestId)
        .order('created_at', ascending: true);

    setState(() {
      messages = List<Map<String, dynamic>>.from(data);
    });

    _scrollToBottom();
  }

  // ================= REALTIME =================
  void _subscribeToMessages() {
    channel = supabase.channel('chat_${widget.requestId}');

    channel!
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          callback: (payload) {
            final newMessage = Map<String, dynamic>.from(payload.newRecord);

            if (newMessage['request_id'] == widget.requestId) {
              if (!_sessionEnded) {
                setState(() {
                  messages.add(newMessage);
                });

                _scrollToBottom();
              }
            }
          },
        )
        .subscribe();
  }

  // ================= SEND MESSAGE =================
  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    if (_sessionEnded) return; // ❌ session ended → block

    _controller.clear();

    await supabase.from('messages').insert({
      'request_id': widget.requestId,
      'sender_id': widget.currentUserId,
      'receiver_id': widget.otherUserId,
      'message': text.trim(),
    });
  }

  // ================= SCROLL =================
  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // ================= START TIMER =================
  void _startTimer() {
    _timer?.cancel();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
      } else {
        timer.cancel();

        if (!_popupOpen && !_sessionEnded) {
          // ✅ যদি আগে extend করা হয়ে থাকে
          if (_alreadyExtended) {
            _goToSessionComplete(); // complete page
          } else {
            _showTimeUpPopup(); // first popup
          }
        }
      }
    });
  }

  // ================= EXTEND SESSION =================
  void _extendSession() {
    Navigator.pop(context);

    setState(() {
      _alreadyExtended = true; // ✅ mark as used
      _remainingSeconds = 5; // 15 min
      _popupOpen = false;
    });

    _startTimer();
  }

  // ================= END SESSION =================
  void _endSession() {
    Navigator.pop(context); // close popup

    setState(() {
      _sessionEnded = true;
      _popupOpen = false;
    });

    _timer?.cancel(); // stop timer
  }

  // ================= COMPLETE =================
  void _goToSessionComplete() {
    setState(() {
      _sessionEnded = true;
    });

    _timer?.cancel();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionCompleteScreen(
          helperName: widget.otherUserName,
          totalMinutes: 30, // 15 + 15
        ),
      ),
    );
  }

  // ================= POPUP =================
  void _showTimeUpPopup() {
    _popupOpen = true;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                const Icon(Icons.hourglass_empty, size: 50, color: Colors.blue),

                const SizedBox(height: 15),

                // Title
                const Text(
                  "Problem not solved.",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                // Subtitle
                const Text(
                  "Request another 15 minutes?",
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                // Request Extension Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _extendSession,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.all(14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Request Extension",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // End Session Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _endSession,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.all(14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "End Session",
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ================= FORMAT TIME =================
  String get formattedTime {
    if (_remainingSeconds <= 0) return "0:00";

    final min = _remainingSeconds ~/ 60;
    final sec = _remainingSeconds % 60;

    return "$min:${sec.toString().padLeft(2, '0')}";
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(widget.otherUserName),

            Text(
              formattedTime,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),

      body: Column(
        children: [
          // ================= CHAT LIST =================
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),

              itemCount: messages.length,

              itemBuilder: (context, index) {
                final msg = messages[index];

                final isMe = msg['sender_id'] == widget.currentUserId;

                return Align(
                  alignment: isMe
                      ? Alignment.centerRight
                      : Alignment.centerLeft,

                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),

                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),

                    decoration: BoxDecoration(
                      color: isMe ? Colors.blue : Colors.grey.shade200,

                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: Text(
                      msg['message'] ?? '',

                      style: TextStyle(
                        color: isMe ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ================= INPUT =================
          Padding(
            padding: const EdgeInsets.all(12),

            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,

                    enabled: !_sessionEnded, // ❌ session end → disable

                    decoration: const InputDecoration(
                      hintText: "Type a message...",

                      filled: true,
                      fillColor: Color(0xFFF2F2F2),

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                IconButton(
                  onPressed: () => _sendMessage(_controller.text),

                  icon: const Icon(Icons.send, color: Colors.blue),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/* ================= COMPLETE SCREEN ================= */

class SessionCompleteScreen extends StatelessWidget {
  final String helperName;
  final int totalMinutes;

  const SessionCompleteScreen({
    super.key,
    required this.helperName,
    required this.totalMinutes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Session Summary")),

      body: Padding(
        padding: const EdgeInsets.all(20),

        child: Column(
          children: [
            const SizedBox(height: 40),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(.15),
                shape: BoxShape.circle,
              ),

              child: const Icon(Icons.check, size: 40, color: Colors.green),
            ),

            const SizedBox(height: 20),

            const Text(
              "Session Completed!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            Text(
              "Great job! Your session with $helperName is done.",
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 30),

            Card(
              child: ListTile(
                leading: CircleAvatar(child: Text(helperName[0])),

                title: Text(helperName),

                subtitle: Text("Total Duration: $totalMinutes minutes"),
              ),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},

                child: const Text("Pay & Rate"),
              ),
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pop(context);
                },

                child: const Text("Back to Chats"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
