import 'package:flutter/material.dart';
import 'package:my_app/helper/helper_details_screen.dart';
import 'package:my_app/helper/helper_notification_page.dart';
import 'package:my_app/helper/helper_request_page.dart';
import 'package:my_app/screen/chats_screen.dart';
import 'package:my_app/request/request_service.dart';
import 'package:my_app/screen/leaener_notification_screen.dart';
import 'package:my_app/screen/learner_request_page.dart';
import 'package:my_app/screen/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_app/helper/all_helper_view_screen.dart';

class LearnerHome extends StatefulWidget {
  const LearnerHome({super.key});

  @override
  State<LearnerHome> createState() => _LearnerHomeState();
}

class _LearnerHomeState extends State<LearnerHome> {
  final supabase = Supabase.instance.client;

  int currentIndex = 0;

  List helpers = [];
  List allHelpers = [];

  // ✅ CHANGED: Role variable add করা হয়েছে
  String? currentUserRole;

  String selectedFilter = "All";
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCurrentUserRole(); // ✅ CHANGED
    fetchHelpers();
  }

  // ✅ CHANGED: Current user role fetch function
  Future<void> fetchCurrentUserRole() async {
    final user = supabase.auth.currentUser;

    if (user != null) {
      final data = await supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .single();

      setState(() {
        currentUserRole = data['role'];
      });
    }
  }

  Future<void> fetchHelpers() async {
    final data = await supabase
        .from('profiles')
        .select()
        .eq('role', 'helper')
        .eq('open_for_requests', true);

    setState(() {
      allHelpers = data;
      helpers = data;
    });
  }

  void applyFilter() {
    List filtered = allHelpers;

    // Filter by chip
    if (selectedFilter != "All") {
      filtered = filtered.where((h) {
        final skills = (h['skills'] as List?) ?? [];
        return skills.any(
          (s) => s.toString().toLowerCase() == selectedFilter.toLowerCase(),
        );
      }).toList();
    }

    // Search by name OR skill
    if (searchController.text.isNotEmpty) {
      final query = searchController.text.toLowerCase();

      filtered = filtered.where((h) {
        final name = (h['full_name'] ?? '').toString().toLowerCase();
        final skills = (h['skills'] as List?) ?? [];

        final skillMatch = skills.any(
          (s) => s.toString().toLowerCase().contains(query),
        );

        return name.contains(query) || skillMatch;
      }).toList();
    }

    setState(() {
      helpers = filtered;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      body: IndexedStack(
        index: currentIndex,
        children: [
          homeScreen(),

          // ✅ CHANGED: Role based Requests Page
          currentUserRole == null
              ? const Center(child: CircularProgressIndicator())
              : (currentUserRole == 'helper'
                    ? const HelperRequestsPage()
                    : const LearnerRequestsPage()),

          const ChatsPage(),
          const Learner_Profile_Page(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) => setState(() => currentIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: "Requests",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            label: "Chats",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),
        ],
      ),
    );
  }

  // ================= HOME =================

  Widget homeScreen() {
    return SafeArea(
      child: Column(
        children: [
          /// APP BAR
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "QuickHelp",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Stack(
                  children: [
                    // ✅ CHANGED: Role based Notification navigation
                    IconButton(
                      icon: const Icon(Icons.notifications_none),
                      onPressed: () {
                        if (currentUserRole == 'helper') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HelperNotificationPage(),
                            ),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LearnerNotificationPage(),
                            ),
                          );
                        }
                      },
                    ),

                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          /// SEARCH
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: searchController,
                onSubmitted: (value) {
                  final query = value.toLowerCase();

                  final filtered = allHelpers.where((h) {
                    final name = (h['full_name'] ?? '')
                        .toString()
                        .toLowerCase();
                    final skills = (h['skills'] as List?) ?? [];

                    final skillMatch = skills.any(
                      (s) => s.toString().toLowerCase().contains(query),
                    );

                    return name.contains(query) || skillMatch;
                  }).toList();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllHelpersPage(helpers: filtered),
                    ),
                  );
                },

                decoration: const InputDecoration(
                  border: InputBorder.none,
                  icon: Icon(Icons.search),
                  hintText: "Search Python, DSA, DBMS...",
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          /// FILTER CHIPS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                filterChip("All"),
                filterChip("Python"),
                filterChip("DSA"),
                filterChip("DBMS"),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// TOP HELPERS TITLE
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Top Helpers",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AllHelpersPage(helpers: helpers),
                      ),
                    );
                  },
                  child: const Text(
                    "View all",
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          /// HORIZONTAL HELPERS
          SizedBox(
            height: 290,
            child: helpers.isEmpty
                ? const Center(child: Text("No helpers found"))
                : ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16),
                    itemCount: helpers.length,
                    itemBuilder: (context, i) {
                      return SizedBox(
                        width: MediaQuery.of(context).size.width * 0.45,
                        child: helperCard(helpers[i]),
                      );
                    },
                  ),
          ),

          const SizedBox(height: 12),

          /// RECENTLY ACTIVE
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                const Text(
                  "Recently Active",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                recentTile("Mike T.", "DBMS", true),
                recentTile("Emily R.", "OS Design", false),
                recentTile("John D.", "ReactJS", false),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= COMPONENTS =================

  Widget filterChip(String text) {
    final bool active = selectedFilter == text;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = text;
        });
        applyFilter();
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(color: active ? Colors.white : Colors.black),
        ),
      ),
    );
  }

  Widget helperCard(Map h) {
    final batch = h['batch']?.toString() ?? '';
    final skills = (h['skills'] as List?)?.join(", ") ?? "No skills";

    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// Avatar + Rating
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                // Only card area (not button) navigates to details
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HelperDetailsPage(helperId: h['id']),
                  ),
                );
              },
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: Colors.white,
                          child: CircleAvatar(
                            radius: 34,
                            backgroundImage:
                                h['avatar_url'] != null &&
                                    h['avatar_url'].toString().isNotEmpty
                                ? NetworkImage(h['avatar_url'])
                                : null,
                            child:
                                h['avatar_url'] == null ||
                                    h['avatar_url'].toString().isEmpty
                                ? const Icon(Icons.person, size: 30)
                                : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    h['full_name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${h['department']} · Year $batch",
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      skills,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // ================= BUTTON =================
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  RequestService().showRequestPopup(
                    context: context,
                    helperId: h['id'],
                  );
                },

                child: const Text(
                  "Request",
                  style: TextStyle(color: Color.fromARGB(249, 255, 255, 255)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget recentTile(String name, String skill, bool online) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              const CircleAvatar(radius: 22, child: Icon(Icons.person)),
              if (online)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  "Helping with $skill",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
          ElevatedButton(onPressed: () {}, child: const Text("Request")),
        ],
      ),
    );
  }
}
