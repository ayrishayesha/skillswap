import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LearnerNotificationPage extends StatefulWidget {
  const LearnerNotificationPage({super.key});

  @override
  State<LearnerNotificationPage> createState() =>
      _LearnerNotificationPageState();
}

class _LearnerNotificationPageState extends State<LearnerNotificationPage> {
  final supabase = Supabase.instance.client;

  List requests = [];
  bool loading = true;

  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();

    fetchRequests();
    listenRealtime(); // 🔔 Realtime Listener
  }

  @override
  void dispose() {
    channel?.unsubscribe();
    super.dispose();
  }

  // ================= FETCH =================
  Future<void> fetchRequests() async {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {
      final data = await supabase
          .from('request')
          .select('''
            id,
            status,
            created_at,

            helper:profiles!helper_id (
              id,
              full_name,
              avatar_url,
              department,
              batch
            )
          ''')
          .eq('learner_id', user.id)
          .order('created_at', ascending: false);

      setState(() {
        requests = data;
        loading = false;
      });
    } catch (e) {
      print("FETCH ERROR => $e");
      setState(() => loading = false);
    }
  }

  // ================= REALTIME =================
  void listenRealtime() {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    channel = supabase
        .channel('learner-notification')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'request',
          callback: (payload) {
            final newData = payload.newRecord;

            // Check if this update is for this learner
            if (newData['learner_id'] == user.id) {
              final status = newData['status'];

              if (status == 'accepted' || status == 'rejected') {
                fetchRequests();
                showPopup(status);
              }
            }
          },
        )
        .subscribe();
  }

  // ================= POPUP =================
  void showPopup(String status) {
    if (!mounted) return;

    String msg = "";

    if (status == "accepted") {
      msg = "🎉 Your request has been ACCEPTED!";
    } else if (status == "rejected") {
      msg = "❌ Your request has been REJECTED";
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: status == "accepted" ? Colors.green : Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Notifications"), centerTitle: true),

      backgroundColor: const Color(0xffF6F7FB),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
          ? const Center(child: Text("No notifications yet"))
          : RefreshIndicator(
              onRefresh: fetchRequests,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final r = requests[index];
                  final helper = r['helper'];

                  if (helper == null) return const SizedBox();

                  return notificationCard(r, helper);
                },
              ),
            ),
    );
  }

  // ================= CARD =================
  Widget notificationCard(Map r, Map helper) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6)],
      ),

      child: Row(
        children: [
          /// Avatar
          CircleAvatar(
            radius: 24,
            backgroundImage:
                helper['avatar_url'] != null &&
                    helper['avatar_url'].toString().isNotEmpty
                ? NetworkImage(helper['avatar_url'])
                : null,
            child: helper['avatar_url'] == null
                ? const Icon(Icons.person)
                : null,
          ),

          const SizedBox(width: 12),

          /// Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  helper['full_name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  getMessage(r['status']),
                  style: TextStyle(
                    fontSize: 13,
                    color: getStatusColor(r['status']),
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  formatDate(r['created_at']),
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),

          /// Status Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: getStatusColor(r['status']).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              r['status'].toString().toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                color: getStatusColor(r['status']),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  String getMessage(String status) {
    if (status == "accepted") {
      return "Helper accepted your request";
    } else if (status == "rejected") {
      return "Helper rejected your request";
    } else {
      return "Request pending";
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "accepted":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String formatDate(String date) {
    final dt = DateTime.parse(date);

    return "${dt.day}/${dt.month}/${dt.year}";
  }
}
