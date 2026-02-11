import 'package:flutter/material.dart';
import 'package:my_app/helper/helper_details_page.dart';

class AllHelpersPage extends StatelessWidget {
  final List helpers;

  const AllHelpersPage({super.key, required this.helpers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("All Helpers")),
      body: helpers.isEmpty
          ? const Center(child: Text("No helpers found"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: helpers.length,
              itemBuilder: (context, i) {
                final h = helpers[i];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                          h['avatar_url'] != null &&
                              h['avatar_url'].toString().isNotEmpty
                          ? NetworkImage(h['avatar_url'])
                          : null,
                      child:
                          h['avatar_url'] == null ||
                              h['avatar_url'].toString().isEmpty
                          ? const Icon(Icons.person)
                          : null,
                    ),
                    title: Text(h['full_name'] ?? ''),
                    subtitle: Text((h['skills'] as List?)?.join(", ") ?? ""),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => HelperDetailsPage(helperId: h['id']),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
