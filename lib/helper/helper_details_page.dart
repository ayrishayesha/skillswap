import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HelperDetailsPage extends StatefulWidget {
  final String helperId;

  const HelperDetailsPage({super.key, required this.helperId});

  @override
  State<HelperDetailsPage> createState() => _HelperDetailsPageState();
}

class _HelperDetailsPageState extends State<HelperDetailsPage> {
  final supabase = Supabase.instance.client;

  Map? helper;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchHelper();
  }

  Future<void> fetchHelper() async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('id', widget.helperId)
        .single();

    setState(() {
      helper = data;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Helper Details")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: helper!['avatar_url'] != null
                  ? NetworkImage(helper!['avatar_url'])
                  : null,
              child: helper!['avatar_url'] == null
                  ? const Icon(Icons.person, size: 50)
                  : null,
            ),
            const SizedBox(height: 12),

            Text(
              helper!['full_name'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            Text(
              "${helper!['department']} · Batch ${helper!['batch']}",
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 16),

            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Skills",
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),

            const SizedBox(height: 6),

            Wrap(
              spacing: 8,
              children: helper!['skills']
                  .toString()
                  .split(',')
                  .map<Widget>((s) => Chip(label: Text(s.trim())))
                  .toList(),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  // request logic later
                },
                child: const Text("Request Help"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
