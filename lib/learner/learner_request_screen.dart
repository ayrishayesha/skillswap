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

  Future<void> fetchRequests() async {
    setState(() {
      loading = true;
    });

    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('request')
        .select(
          'id, status, helper_id, profiles!inner(full_name, department, batch)',
        )
        .eq('learner_id', user.id)
        .order('created_at', ascending: false);

    setState(() {
      requests = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("My Requests")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : requests.isEmpty
          ? const Center(child: Text("No requests sent yet"))
          : ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, i) {
                final r = requests[i];
                final helper = r['profiles'];
                return Card(
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(helper['full_name']),
                    subtitle: Text(
                      "${helper['department']} · Year ${helper['batch']}\nStatus: ${r['status']}",
                    ),
                  ),
                );
              },
            ),
    );
  }
}
