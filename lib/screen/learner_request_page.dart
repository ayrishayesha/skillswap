import 'package:flutter/material.dart';
import 'package:my_app/helper/helper_details_screen.dart';
import 'package:my_app/request_details.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class LearnerRequestsPage extends StatefulWidget {
  const LearnerRequestsPage({super.key});

  @override
  State<LearnerRequestsPage> createState() => _LearnerRequestsPageState();
}

class _LearnerRequestsPageState extends State<LearnerRequestsPage> {
  final supabase = Supabase.instance.client;

  List requests = [];
  bool loading = true;

  RealtimeChannel? channel;

  @override
  void initState() {
    super.initState();

    fetchRequests();
    listenForUpdates(); // 🔔 realtime
  }

  @override
  void dispose() {
    channel?.unsubscribe();
    super.dispose();
  }

  // ================= FETCH =================
  Future<void> fetchRequests() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() => loading = false);
      return;
    }

    final data = await supabase
        .from('request')
        .select('''
          id,
          status,
          created_at,
          subject,

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
  }

  // ================= REALTIME =================
  void listenForUpdates() {
    final user = supabase.auth.currentUser;

    if (user == null) return;

    channel = supabase
        .channel('learner-request-updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'request',
          callback: (payload) {
            final newRecord = payload.newRecord;

            // Check if this update is for current learner
            if (newRecord['learner_id'] == user.id) {
              final status = newRecord['status'];

              if (status == 'accepted' || status == 'rejected') {
                fetchRequests();
                showNotification(status);
              }
            }
          },
        )
        .subscribe();
  }

  // ================= POPUP =================
  void showNotification(String status) {
    if (!mounted) return;

    final msg = status == 'accepted'
        ? "🎉 Your request was ACCEPTED!"
        : "❌ Your request was REJECTED";

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: status == 'accepted' ? Colors.green : Colors.red,
      ),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Requests"), centerTitle: true),

      backgroundColor: const Color(0xffF6F7FB),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
          ? const Center(child: Text("No requests yet"))
          : RefreshIndicator(
              onRefresh: fetchRequests,

              child: ListView.builder(
                padding: const EdgeInsets.all(16),

                itemCount: requests.length,

                itemBuilder: (context, index) {
                  final r = requests[index];
                  final helper = r['helper'];

                  if (helper == null) return const SizedBox();

                  return requestCard(r, helper);
                },
              ),
            ),
    );
  }

  // ================= CARD =================
  Widget requestCard(Map r, Map helper) {
    return GestureDetector(
      // ✅ ADDED: Clickable
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RequestDetailsPage(
              requestId: r['id'], // ✅ শুধু id পাঠাতে হবে
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6)],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
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
                    "${helper['department']} • Batch ${helper['batch']}",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                  const SizedBox(height: 6),

                  if (r['subject'] != null)
                    Text(
                      "Need help for ${r['subject']}",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),

                  const SizedBox(height: 6),

                  Row(
                    children: [
                      const Text("Status: "),
                      Text(
                        r['status'],
                        style: TextStyle(
                          color: _getStatusColor(r['status']),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            Text(
              _formatDateTime(r['created_at']),
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
  // ================= HELPERS =================

  Color _getStatusColor(String status) {
    switch (status) {
      case "accepted":
        return Colors.blue;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // ✅ UPDATED: Date + Time (AM/PM format)
  String _formatDateTime(String date) {
    final dt = DateTime.parse(date).toLocal();

    final day = "${dt.day}/${dt.month}/${dt.year}";

    int hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');

    String period = hour >= 12 ? "PM" : "AM";

    hour = hour % 12;
    if (hour == 0) hour = 12; // 0 হলে 12 show করবে

    final time = "$hour:$minute $period";

    return "$day\n$time"; // Date এর নিচে AM/PM time দেখাবে
  }
}
