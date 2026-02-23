import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class RequestDetailsPage extends StatefulWidget {
  final String requestId;

  const RequestDetailsPage({super.key, required this.requestId});

  @override
  State<RequestDetailsPage> createState() => _RequestDetailsPageState();
}

class _RequestDetailsPageState extends State<RequestDetailsPage> {
  final supabase = Supabase.instance.client;

  Map? request;
  bool loading = true;
  bool updating = false;

  bool isHelper = false;
  bool isLearner = false;

  @override
  void initState() {
    super.initState();
    fetchRequestDetails();
  }

  // ================= FETCH DATA =================
  Future<void> fetchRequestDetails() async {
    final user = supabase.auth.currentUser;

    final data = await supabase
        .from('request')
        .select('''
          id,
          title,
          description,
          subject,
          status,
          attachment_url,
          created_at,
          helper_id,
          learner_id,

          helper:profiles!helper_id (
            id,
            full_name,
            department,
            batch,
            avatar_url
          ),

          learner:profiles!learner_id (
            id,
            full_name,
            department,
            batch,
            avatar_url
          )
        ''')
        .eq('id', widget.requestId)
        .single();

    // detect role
    if (user != null) {
      if (user.id == data['helper_id']) {
        isHelper = true;
      } else if (user.id == data['learner_id']) {
        isLearner = true;
      }
    }

    setState(() {
      request = data;
      loading = false;
    });
  }

  // ================= UPDATE STATUS =================
  Future<void> updateStatus(String newStatus) async {
    setState(() => updating = true);

    await supabase
        .from('request')
        .update({'status': newStatus})
        .eq('id', widget.requestId);

    await fetchRequestDetails();

    setState(() => updating = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Request $newStatus successfully"),
        backgroundColor: newStatus == "accepted" ? Colors.blue : Colors.red,
      ),
    );
  }

  // ================= DOWNLOAD FILE =================
  Future<void> downloadFile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6FA),
      appBar: AppBar(
        title: const Text("Request Details"),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : request == null
          ? const Center(child: Text("No Data Found"))
          : buildBody(),
    );
  }

  Widget buildBody() {
    final profile = isHelper ? request!['learner'] : request!['helper'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // ================= PROFILE CARD =================
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: Colors.grey.shade200, blurRadius: 10),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundImage:
                      profile['avatar_url'] != null &&
                          profile['avatar_url'].toString().isNotEmpty
                      ? NetworkImage(profile['avatar_url'])
                      : null,
                  child: profile['avatar_url'] == null
                      ? const Icon(Icons.person, size: 30)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile['full_name'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${profile['department']} • ${profile['batch']} batch",
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                _statusBadge(request!['status']),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ================= DETAILS =================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _subjectBadge(request!['subject']),
                const SizedBox(height: 16),
                Text(
                  request!['title'] ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  request!['description'] ?? '',
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
                const SizedBox(height: 20),
                Text(
                  "Posted ${_formatDateTime(request!['created_at'])}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                // ================= ATTACHMENT =================
                // ================= ATTACHMENT =================
                // ================= ATTACHMENT =================
                if (request!['attachment_url'] != null &&
                    request!['attachment_url'].toString().isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.attach_file, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Attachment",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.download, color: Colors.green),
                          onPressed: () =>
                              downloadFile(request!['attachment_url']),
                          tooltip: "Download",
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // ================= BUTTONS (ONLY HELPER CAN SEE) =================
          if (isHelper && request!['status'] == "pending")
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: updating ? null : () => updateStatus("accepted"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: updating
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "Accept Request",
                            style: TextStyle(
                              color: Color.fromARGB(255, 255, 255, 255),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: updating ? null : () => updateStatus("rejected"),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "Reject Request",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _statusColor(status).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: _statusColor(status),
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _subjectBadge(String subject) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.orange.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        subject,
        style: const TextStyle(
          color: Colors.orange,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
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
    final dt = DateTime.parse(date).toLocal();
    int hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    String period = hour >= 12 ? "PM" : "AM";
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return "${dt.day}/${dt.month}/${dt.year}  $hour:$minute $period";
  }
}
