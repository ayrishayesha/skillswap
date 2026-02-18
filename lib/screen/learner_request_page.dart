import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    fetchRequests();
  }

  // ================= FETCH =================
  Future<void> fetchRequests() async {
    final user = supabase.auth.currentUser;

    if (user == null) {
      setState(() => loading = false);
      return;
    }

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

      print("REQUESTS => $data");

      setState(() {
        requests = data;
        loading = false;
      });
    } catch (e) {
      print("FETCH ERROR => $e");

      setState(() {
        loading = false;
      });
    }
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
          ? const Center(
              child: Text("No requests yet", style: TextStyle(fontSize: 15)),
            )
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
            radius: 26,
            backgroundColor: Colors.grey.shade200,

            backgroundImage:
                helper['avatar_url'] != null &&
                    helper['avatar_url'].toString().isNotEmpty
                ? NetworkImage(helper['avatar_url'])
                : null,

            child:
                helper['avatar_url'] == null ||
                    helper['avatar_url'].toString().isEmpty
                ? const Icon(Icons.person)
                : null,
          ),

          const SizedBox(width: 12),

          /// Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Name
                Text(
                  helper['full_name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 4),

                /// Dept + Batch
                Text(
                  "${helper['department'] ?? ''} • Batch ${helper['batch'] ?? ''}",
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 6),

                /// Status
                Row(
                  children: [
                    const Text("Status: ", style: TextStyle(fontSize: 12)),

                    Text(
                      r['status'],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(r['status']),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// Date
          Text(
            _formatDate(r['created_at']),
            style: const TextStyle(fontSize: 11, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ================= HELPERS =================

  Color _getStatusColor(String status) {
    switch (status) {
      case "accepted":
        return Colors.green;

      case "rejected":
        return Colors.red;

      default:
        return Colors.orange;
    }
  }

  String _formatDate(String date) {
    final dt = DateTime.parse(date);

    return "${dt.day}/${dt.month}/${dt.year}";
  }
}
