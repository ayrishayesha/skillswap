import 'package:flutter/material.dart';
import 'package:my_app/helper/helper_details_screen.dart';
import 'package:my_app/request/request_service.dart';

class AllHelpersPage extends StatelessWidget {
  final List helpers;

  const AllHelpersPage({super.key, required this.helpers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text("Helpers", style: TextStyle(color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
            child: Text(
              "${helpers.length} Helpers available",
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
          ),

          Expanded(
            child: helpers.isEmpty
                ? const Center(child: Text("No helpers found"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: helpers.length,
                    itemBuilder: (context, i) {
                      final h = helpers[i];

                      return HelperCard(helper: h);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class HelperCard extends StatelessWidget {
  final Map helper;

  const HelperCard({super.key, required this.helper});

  @override
  Widget build(BuildContext context) {
    final name = helper['full_name'] ?? '';
    final dept = helper['department'] ?? '';
    final avatar = helper['avatar_url'];

    final skills =
        (helper['skills'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: avatar != null && avatar.toString().isNotEmpty
                    ? NetworkImage(avatar)
                    : null,
                child: avatar == null || avatar.toString().isEmpty
                    ? const Icon(Icons.person, size: 28)
                    : null,
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      dept,
                      style: const TextStyle(color: Colors.blue, fontSize: 13),
                    ),
                    const SizedBox(height: 2),

                    if (skills.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: skills.map((s) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.deepPurple.shade50,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              s,
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            HelperDetailsPage(helperId: helper['id']),
                      ),
                    );
                  },
                  child: const Text("View Profile"),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    RequestService().showRequestPopup(
                      context: context,
                      helperId: helper['id'],
                    );
                  },
                  child: const Text(
                    "Request",
                    style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
