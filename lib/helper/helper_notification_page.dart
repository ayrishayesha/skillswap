import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HelperNotificationPage extends StatefulWidget {
  const HelperNotificationPage({super.key});

  @override
  State<HelperNotificationPage> createState() => _HelperNotificationPageState();
}

class _HelperNotificationPageState extends State<HelperNotificationPage> {
  final supabase = Supabase.instance.client;

  List requests = [];
  bool loading = true;
  RealtimeChannel? notificationChannel;

  @override
  void initState() {
    super.initState();
    fetchRequests();
    listenRealtimeNotification();
  }

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

            learner:profiles!learner_id (
              id,
              full_name,
              avatar_url,
              department,
              batch
            )
          ''')
          .eq('helper_id', user.id)
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

  Future<void> updateStatus(String requestId, String status) async {
    try {
      await supabase
          .from('request')
          .update({'status': status})
          .eq('id', requestId);

      fetchRequests();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Request $status"),
          backgroundColor: status == "accepted" ? Colors.blue : Colors.red,
        ),
      );
    } catch (e) {
      print("UPDATE ERROR => $e");
    }
  }

  void listenRealtimeNotification() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    notificationChannel = supabase
        .channel('helper-global-notification')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'request',
          callback: (payload) {
            final newData = payload.newRecord;

            if (newData['helper_id'] == user.id) {
              fetchRequests();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(top: 10, left: 16, right: 16),
                  backgroundColor: Colors.blue,
                  content: const Text(
                    "You have a new request.please check your request screen to accept or reject the request",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              );
            }
          },
        )
        .subscribe();
  }

  @override
  void dispose() {
    notificationChannel?.unsubscribe();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Mentor Notification"),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xffF6F7FB),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
          ? const Center(child: Text("No notification yet"))
          : RefreshIndicator(
              onRefresh: fetchRequests,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                itemBuilder: (context, index) {
                  final r = requests[index];
                  final learner = r['learner'];

                  if (learner == null) return const SizedBox();

                  return requestCard(r, learner);
                },
              ),
            ),
    );
  }

  Widget requestCard(Map r, Map learner) {
    final status = r['status'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 6)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundImage:
                    learner['avatar_url'] != null &&
                        learner['avatar_url'].toString().isNotEmpty
                    ? NetworkImage(learner['avatar_url'])
                    : null,
                child: learner['avatar_url'] == null
                    ? const Icon(Icons.person)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      learner['full_name'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "${learner['department'] ?? ''} | ${learner['batch'] ?? ''}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Status: ${status.toString().toUpperCase()}",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: getStatusColor(status),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (status == "pending")
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => updateStatus(r['id'], "accepted"),
                    label: const Text(
                      "Accept",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => updateStatus(r['id'], "rejected"),
                    label: const Text(
                      "Reject",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          if (status != "pending")
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: getStatusColor(status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Already ${status.toString().toUpperCase()}",
                style: TextStyle(
                  color: getStatusColor(status),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
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
}
