import 'package:flutter/material.dart';
import 'package:my_app/helper/helper_details_page.dart';

class SearchResultPage extends StatefulWidget {
  final List allHelpers;
  final String query;

  const SearchResultPage({
    super.key,
    required this.allHelpers,
    required this.query,
  });

  @override
  State<SearchResultPage> createState() => _SearchResultPageState();
}

class _SearchResultPageState extends State<SearchResultPage> {
  List results = [];

  @override
  void initState() {
    super.initState();
    filterResults();
  }

  void filterResults() {
    final q = widget.query.toLowerCase();

    results = widget.allHelpers.where((h) {
      final name = (h['full_name'] ?? '').toString().toLowerCase();
      final skills = (h['skills'] as List?) ?? [];

      final skillMatch = skills.any(
        (s) => s.toString().toLowerCase().contains(q),
      );

      return name.contains(q) || skillMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          "${widget.query} Helpers",
          style: const TextStyle(color: Colors.black),
        ),
      ),
      body: results.isEmpty
          ? const Center(child: Text("No helpers found"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: results.length,
              itemBuilder: (context, index) {
                final h = results[index];
                return helperCard(h);
              },
            ),
    );
  }

  Widget helperCard(Map h) {
    final skills = (h['skills'] as List?)?.join(", ") ?? "";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundImage:
                h['avatar_url'] != null && h['avatar_url'].toString().isNotEmpty
                ? NetworkImage(h['avatar_url'])
                : null,
            child: h['avatar_url'] == null || h['avatar_url'].toString().isEmpty
                ? const Icon(Icons.person)
                : null,
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  h['full_name'] ?? '',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${h['department']} · Year ${h['batch']}",
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Text(skills, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HelperDetailsPage(helperId: h['id']),
                ),
              );
            },
            child: const Text("View"),
          ),
        ],
      ),
    );
  }
}
