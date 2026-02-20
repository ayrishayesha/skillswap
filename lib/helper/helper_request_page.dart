import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HelperRequestsPage extends StatefulWidget {
  const HelperRequestsPage({super.key});

  @override
  State<HelperRequestsPage> createState() => _HelperRequestsPageState();
}

class _HelperRequestsPageState extends State<HelperRequestsPage> {
  final supabase = Supabase.instance.client;

  List requests = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRequests();
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

  // ================= UPDATE =================
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
          backgroundColor: status == "accepted" ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      print("UPDATE ERROR => $e");
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Helper Requests"), centerTitle: true),

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

                  if (learner == null) {
                    return const SizedBox();
                  }

                  return requestCard(r, learner);
                },
              ),
            ),
    );
  }

  // ================= CARD =================
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
              /// Avatar
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

              /// Info
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

          /// Buttons
          if (status == "pending")
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      updateStatus(r['id'], "accepted");
                    },
                    icon: const Icon(Icons.check),
                    label: const Text("Accept"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      updateStatus(r['id'], "rejected");
                    },
                    icon: const Icon(Icons.close),
                    label: const Text("Reject"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                  ),
                ),
              ],
            ),

          /// If already accepted/rejected
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

  // ================= HELPERS =================
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
