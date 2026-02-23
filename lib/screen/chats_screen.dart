// ================= FULL FIXED CHATS SCREEN =================
import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:my_app/screen/session_complete.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Timer? _timer;
  int _remainingSeconds = 900;
  bool _sessionEnded = false;
  bool _alreadyExtended = false;
  bool _sessionFullyCompleted = false;

  Map<String, dynamic>? _replyingTo;
  bool _isEditing = false;
  int? _editingMessageId;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  PlatformFile? _selectedFile;

  // ====== ADDITIONAL VARIABLES FOR TIMER LOGIC ======
  StreamSubscription? _statusSubscription;
  bool _bothReady = false; // true only if both learner & helper ready

  @override
  void initState() {
    super.initState();
    _checkSessionState();
    _loadMessages();
    _subscribeToMessages();
    _markReadyAndListen();
  }

  @override
  void dispose() {
    _timer?.cancel();
    channel?.unsubscribe();
    _controller.dispose();
    _scrollController.dispose();
    _statusSubscription?.cancel();

    _markNotReady();

    super.dispose();
  }

  // =================== READY STATUS LOGIC ===================
  Future<void> _markReadyAndListen() async {
    await supabase.from('chat_status').upsert({
      'request_id': widget.requestId,
      'user_id': widget.currentUserId,
      'status': 'ready',
    }, onConflict: 'request_id,user_id');

    _statusSubscription = supabase
        .from('chat_status')
        .stream(primaryKey: ['request_id', 'user_id'])
        .eq('request_id', widget.requestId)
        .listen((event) {
          final readyUsers = event
              .where((e) => e['status'] == 'ready')
              .toList();

          final allReady = readyUsers.length >= 2;

          if (mounted && allReady != _bothReady) {
            setState(() {
              _bothReady = allReady;
            });

            if (_bothReady) {
              _startTimer();
            } else {
              _timer?.cancel();
            }
          }
        });
  }

  Future<void> _markNotReady() async {
    await supabase
        .from('chat_status')
        .update({'status': 'not_ready'})
        .eq('request_id', widget.requestId)
        .eq('user_id', widget.currentUserId);
  }

  // ================= LOAD MESSAGES =================
  Future<void> _loadMessages() async {
    try {
      final data = await supabase
          .from('messages')
          .select()
          .eq('request_id', widget.requestId)
          .order('created_at', ascending: true);

      if (!mounted) return;

      setState(() {
        messages = List<Map<String, dynamic>>.from(data);
      });

      _scrollToBottom();
    } catch (e) {
      debugPrint("Load message error: $e");
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  // ================= REALTIME =================
  void _subscribeToMessages() {
    channel = supabase.channel('chat_${widget.requestId}');

    channel!.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final newMessage = Map<String, dynamic>.from(payload.newRecord);
        if (newMessage['request_id'] == widget.requestId) {
          if (mounted) setState(() => messages.add(newMessage));
          _scrollToBottom();
        }
      },
    );

    channel!.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final updated = Map<String, dynamic>.from(payload.newRecord);
        final index = messages.indexWhere((msg) => msg['id'] == updated['id']);
        if (index != -1) {
          setState(() => messages[index] = updated);
        }
      },
    );

    channel!.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'messages',
      callback: (payload) {
        final deletedId = payload.oldRecord['id'];
        setState(() => messages.removeWhere((msg) => msg['id'] == deletedId));
      },
    );

    channel!.subscribe();
  }

  // ================= SEND MESSAGE =================
  Future<void> _sendMessage() async {
    if ((_controller.text.trim().isEmpty &&
            _selectedImage == null &&
            _selectedFile == null) ||
        _sessionEnded ||
        _sessionFullyCompleted)
      return;

    try {
      // ===== EDIT MODE =====
      if (_isEditing && _editingMessageId != null) {
        await supabase
            .from('messages')
            .update({
              'message': _controller.text.trim(),
              'reply_to': _replyingTo?['id'],
            })
            .eq('id', _editingMessageId!);

        final index = messages.indexWhere(
          (msg) => msg['id'] == _editingMessageId,
        );
        if (index != -1) {
          setState(() {
            messages[index]['message'] = _controller.text.trim();
            messages[index]['reply_to'] = _replyingTo?['id'];
          });
        }

        setState(() {
          _isEditing = false;
          _editingMessageId = null;
          _replyingTo = null;
        });
        _controller.clear();
        _scrollToBottom();
        return;
      }

      // ===== NORMAL SEND =====
      String? uploadedUrl;
      String? fileName;
      String type = 'text';

      if (_selectedImage != null && _selectedImageBytes != null) {
        final path =
            "${widget.currentUserId}/chat_${DateTime.now().millisecondsSinceEpoch}.jpg";
        await supabase.storage
            .from('Bucket1')
            .uploadBinary(
              path,
              _selectedImageBytes!,
              fileOptions: const FileOptions(contentType: 'image/jpeg'),
            );
        uploadedUrl = supabase.storage.from('Bucket1').getPublicUrl(path);
        type = 'image';
      } else if (_selectedFile != null) {
        fileName = _selectedFile!.name;
        final path =
            "${widget.currentUserId}/chat_${DateTime.now().millisecondsSinceEpoch}_${fileName}";
        if (_selectedFile!.bytes != null) {
          await supabase.storage
              .from('Bucket1')
              .uploadBinary(
                path,
                _selectedFile!.bytes!,
                fileOptions: const FileOptions(upsert: true),
              );
        }
        uploadedUrl = supabase.storage.from('Bucket1').getPublicUrl(path);
        type = 'file';
      }

      final inserted = await supabase.from('messages').insert({
        'request_id': widget.requestId,
        'sender_id': widget.currentUserId,
        'receiver_id': widget.otherUserId,
        'message': uploadedUrl ?? _controller.text.trim(),
        'type': type,
        'file_name': fileName,
        'reply_to': _replyingTo?['id'],
        'created_at': DateTime.now().toIso8601String(),
      });
      // .select()
      // .single();

      // if (inserted != null) {
      //   setState(() => messages.add(Map<String, dynamic>.from(inserted)));
      // }

      _controller.clear();
      setState(() {
        _selectedImage = null;
        _selectedImageBytes = null;
        _selectedFile = null;
        _replyingTo = null;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint("Send Error: $e");
    }
  }

  // ================= IMAGE PICKER =================
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _selectedImage = file;
      _selectedImageBytes = bytes;
      _selectedFile = null;
    });
    Navigator.pop(context);
  }

  // ================= FILE PICKER =================
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(withData: true);
    if (result == null || result.files.isEmpty) return;
    setState(() {
      _selectedFile = result.files.single;
      _selectedImage = null;
      _selectedImageBytes = null;
    });
    Navigator.pop(context);
  }

  // ================= DELETE =================
  Future<void> _deleteMessage(dynamic id) async {
    await supabase.from('messages').delete().eq('id', id);
    setState(() => messages.removeWhere((msg) => msg['id'] == id));
  }

  // ================= TIMER =================
  final ValueNotifier<int> _remainingSecondsNotifier = ValueNotifier(900);

  void _startTimer() {
    if (!_bothReady) return;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSecondsNotifier.value > 0) {
        _remainingSecondsNotifier.value--;
      } else {
        timer.cancel();
        if (!_alreadyExtended)
          _showTimeUpPopup();
        else
          _goToSessionComplete();
      }
    });
  }

  void _extendSession() {
    Navigator.pop(context);

    setState(() {
      _alreadyExtended = true;
      _remainingSecondsNotifier.value = 900;
    });

    _startTimer();
  }

  void _goToSessionComplete() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('session_${widget.requestId}_fully_completed', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SessionCompleteScreen(
          helperName: widget.otherUserName,
          totalMinutes: 30,
        ),
      ),
    );
  }

  Future<void> _checkSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    final done =
        prefs.getBool('session_${widget.requestId}_fully_completed') ?? false;
    if (done) _goToSessionComplete();
  }

  void _showTimeUpPopup() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Time Up'),
        content: const Text('Request another 15 minutes?'),
        actions: [
          TextButton(onPressed: _extendSession, child: const Text('Extend')),
          TextButton(onPressed: _goToSessionComplete, child: const Text('End')),
        ],
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Row(
          children: [
            const CircleAvatar(radius: 18),
            const SizedBox(width: 10),
            Text(
              widget.otherUserName,
              style: const TextStyle(color: Colors.black),
            ),
            const Spacer(),
            if (_bothReady)
              ValueListenableBuilder<int>(
                valueListenable: _remainingSecondsNotifier,
                builder: (_, remainingSeconds, __) {
                  final min = remainingSeconds ~/ 60;
                  final sec = remainingSeconds % 60;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '$min:${sec.toString().padLeft(2, '0')}',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          if (!_sessionFullyCompleted)
            Padding(
              padding: const EdgeInsets.all(8),
              child: ElevatedButton(
                onPressed: _goToSessionComplete,
                child: const Text('Mark as Complete'),
              ),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                final isMe = msg['sender_id'] == widget.currentUserId;
                final replyToMsg = msg['reply_to'] != null
                    ? messages.firstWhere(
                        (m) => m['id'] == msg['reply_to'],
                        orElse: () => {},
                      )
                    : null;

                return GestureDetector(
                  onLongPress: () => _showMessageOptions(msg, isMe),
                  child: Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      padding: const EdgeInsets.all(12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.7,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? Colors.blue : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (replyToMsg != null && replyToMsg.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.all(6),
                              margin: const EdgeInsets.only(bottom: 6),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                _getReplyPreview(replyToMsg),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          _buildMessageContent(msg, isMe),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_replyingTo != null)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade300,
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Replying to: ${_replyingTo!.isNotEmpty ? _getReplyPreview(_replyingTo!) : ''}',
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _replyingTo = null),
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                if (_selectedImage != null)
                  Stack(
                    children: [
                      Image.memory(
                        _selectedImageBytes!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                      Positioned(
                        top: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedImage = null;
                            _selectedImageBytes = null;
                          }),
                          child: const CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.black54,
                            child: Icon(Icons.close, size: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (_selectedFile != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.insert_drive_file),
                        const SizedBox(width: 8),
                        Expanded(child: Text(_selectedFile!.name)),
                        GestureDetector(
                          onTap: () => setState(() => _selectedFile = null),
                          child: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: _showAttachmentSheet,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        enabled: !_sessionEnded && !_sessionFullyCompleted,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(12)),
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send, color: Colors.blue),
                      onPressed: _sendMessage,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getReplyPreview(Map<String, dynamic> msg) {
    if (msg.isEmpty) return '';
    switch (msg['type']) {
      case 'image':
        return '[Image]';
      case 'file':
        return '[File] ${msg['file_name'] ?? 'unknown'}';
      default:
        return msg['message'] ?? '';
    }
  }

  void _showAttachmentSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.image),
            title: const Text('Image'),
            onTap: _pickImage,
          ),
          ListTile(
            leading: const Icon(Icons.attach_file),
            title: const Text('File'),
            onTap: _pickFile,
          ),
        ],
      ),
    );
  }

  void _showMessageOptions(Map<String, dynamic> msg, bool isMe) {
    showModalBottomSheet(
      context: context,
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.reply),
            title: const Text('Reply'),
            onTap: () {
              setState(() => _replyingTo = msg);
              Navigator.pop(context);
            },
          ),
          if (isMe)
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                _controller.text = msg['message'];
                _isEditing = true;
                _editingMessageId = msg['id'];
                setState(() {
                  _replyingTo = msg['reply_to'] != null
                      ? messages.firstWhere(
                          (m) => m['id'] == msg['reply_to'],
                          orElse: () => {},
                        )
                      : null;
                });
                Navigator.pop(context);
              },
            ),
          if (isMe)
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete'),
              onTap: () {
                _deleteMessage(msg['id']);
                Navigator.pop(context);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMessageContent(Map<String, dynamic> msg, bool isMe) {
    switch (msg['type']) {
      case 'image':
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(msg['message'], width: 200, fit: BoxFit.cover),
        );
      case 'file':
        final fileName = msg['file_name'] ?? 'Download File';
        return InkWell(
          onTap: () async {
            final url = Uri.parse(msg['message']);
            if (await canLaunchUrl(url))
              await launchUrl(url, mode: LaunchMode.externalApplication);
          },
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isMe ? Colors.white24 : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.insert_drive_file),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    fileName,
                    style: TextStyle(
                      color: isMe ? Colors.white : Colors.black,
                      fontWeight: FontWeight.w500,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return Text(
          msg['message'] ?? '',
          style: TextStyle(color: isMe ? Colors.white : Colors.black),
        );
    }
  }

  String get formattedTime {
    final min = _remainingSeconds ~/ 60;
    final sec = _remainingSeconds % 60;
    return '$min:${sec.toString().padLeft(2, '0')}';
  }
}
