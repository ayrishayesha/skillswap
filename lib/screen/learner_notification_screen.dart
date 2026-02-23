import 'package:flutter/material.dart';
import 'package:my_app/request/request_accepted_page.dart';
import 'package:my_app/request_details.dart';
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

  // ================= INIT =================
  @override
  void initState() {
    super.initState();

    initNotificationSystem();
  }

  Future<void> initNotificationSystem() async {
    await fetchRequests(); // First load
    markAllSeen(); // Clear badge
    startRealtime(); // Live listen
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

      if (!mounted) return;

      setState(() {
        requests = data;
        loading = false;
      });
    } catch (e) {
      debugPrint("FETCH ERROR => $e");

      if (!mounted) return;

      setState(() => loading = false);
    }
  }

  // ================= REALTIME =================
  void startRealtime() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    channel = supabase
        .channel('learner-notification-global')
        .onPostgresChanges(
          event: PostgresChangeEvent.all, // ✅ IMPORTANT
          schema: 'public',
          table: 'request',
          callback: (payload) {
            final newData = payload.newRecord;

            if (newData['learner_id'] == user.id) {
              fetchRequests();

              final status = newData['status'];

              if (status == 'accepted' || status == 'rejected') {
                markSingleUnseen(newData['id']);
                showPopup(status);
              }
            }
          },
        )
        .subscribe();
  }

  // ================= SEEN SYSTEM =================

  // Mark all as seen when open page
  Future<void> markAllSeen() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('request')
        .update({'is_seen': true})
        .eq('learner_id', user.id)
        .or('status.eq.accepted,status.eq.rejected');
  }

  // Mark single unseen for new notification
  Future<void> markSingleUnseen(String id) async {
    await supabase.from('request').update({'is_seen': false}).eq('id', id);
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
        backgroundColor: status == "accepted" ? Colors.blue : Colors.red,
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
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RequestDetailsPage(requestId: r['id']),
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
                    _formatDateTime(r['created_at']),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
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

                const SizedBox(height: 6),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => RequestAcceptedPage(requestId: r['id']),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text(
                    "View",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ],
        ),
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
        return Colors.blue;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _formatDateTime(String date) {
    // Parse as UTC first
    final dtUtc = DateTime.parse(date).toUtc();

    // Convert to device's local timezone
    final dtLocal = dtUtc.toLocal();

    final day = "${dtLocal.day}/${dtLocal.month}/${dtLocal.year}";

    int hour = dtLocal.hour;
    final minute = dtLocal.minute.toString().padLeft(2, '0');

    String period = hour >= 12 ? "PM" : "AM";

    hour = hour % 12;
    if (hour == 0) hour = 12;

    final time = "$hour:$minute $period";

    return "$day\n$time";
  }
}
