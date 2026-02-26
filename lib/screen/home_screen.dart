import 'package:flutter/material.dart';
import 'package:my_app/helper/helper_details_screen.dart';
import 'package:my_app/helper/helper_notification_page.dart';
import 'package:my_app/helper/helper_request_page.dart';

import 'package:my_app/learner/learner_request_page.dart';
import 'package:my_app/screen/caht_home_screen.dart';
import 'package:my_app/learner/learner_notification_screen.dart';
import 'package:my_app/profile/profile_page.dart';
import 'package:my_app/helper/all_helper_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_app/request/request_service.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final supabase = Supabase.instance.client;

  int currentIndex = 0;
  String? currentUserRole;

  List helpers = [];
  List allHelpers = [];

  int unreadCount = 0;
  RealtimeChannel? notificationChannel;

  String selectedFilter = "All";
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCurrentUserRole();
    fetchHelpers();
    fetchUnreadCount();
    listenGlobalNotification();
  }

  Future<void> fetchCurrentUserRole() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final data = await supabase
        .from('profiles')
        .select('role')
        .eq('id', user.id)
        .single();

    setState(() {
      currentUserRole = data['role'];
    });
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

  Future<void> fetchUnreadCount() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    if (currentUserRole == 'learner') {
      final data = await supabase
          .from('request')
          .select()
          .eq('learner_id', user.id)
          .inFilter('status', ['accepted', 'rejected'])
          .eq('is_seen', false);

      setState(() {
        unreadCount = data.length;
      });
    } else if (currentUserRole == 'helper') {
      final data = await supabase
          .from('request')
          .select()
          .eq('helper_id', user.id)
          .eq('status', 'pending')
          .eq('is_seen', false);

      setState(() {
        unreadCount = data.length;
      });
    }
  }

  void listenGlobalNotification() {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    notificationChannel = supabase
        .channel('global-notification')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'request',
          callback: (payload) {
            final newData = payload.newRecord;

            if (currentUserRole == 'learner' &&
                newData['learner_id'] == user.id &&
                (newData['status'] == 'accepted' ||
                    newData['status'] == 'rejected')) {
              fetchUnreadCount();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    "Tumar request ${newData['status'].toString().toUpperCase()} hoyeche",
                  ),
                  backgroundColor: newData['status'] == 'accepted'
                      ? Colors.blue
                      : Colors.red,
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.only(top: 10, left: 16, right: 16),
                ),
              );
            }

            if (currentUserRole == 'helper' &&
                newData['helper_id'] == user.id &&
                newData['status'] == 'pending') {
              fetchUnreadCount();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    "you have a new request.please check your request screen to accept or reject the request",
                  ),
                  backgroundColor: Colors.blue,
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.only(top: 10, left: 16, right: 16),
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

  void applyFilter() {
    List filtered = allHelpers;

    if (selectedFilter != "All") {
      filtered = filtered.where((h) {
        final skills = (h['skills'] as List?) ?? [];
        return skills.any(
          (s) => s.toString().toLowerCase() == selectedFilter.toLowerCase(),
        );
      }).toList();
    }

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
          currentUserRole == null
              ? const Center(child: CircularProgressIndicator())
              : (currentUserRole == 'helper'
                    ? const HelperRequestsPage()
                    : const LearnerRequestsPage()),

          currentUserRole == null
              ? const Center(child: CircularProgressIndicator())
              : ChatHomePage(isHelper: currentUserRole == 'helper'),
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

  Widget homeScreen() {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "CampusMentor",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Stack(
                  children: [
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
                        fetchUnreadCount();
                      },
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

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
                  applyFilter();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AllHelpersPage(helpers: helpers),
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

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Mentors",
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
        ],
      ),
    );
  }

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
          boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10)],
        ),
        child: Column(
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HelperDetailsPage(helperId: h['id']),
                  ),
                );
              },
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundImage:
                        h['avatar_url'] != null &&
                            h['avatar_url'].toString().isNotEmpty
                        ? NetworkImage(h['avatar_url'])
                        : null,
                    child: h['avatar_url'] == null
                        ? const Icon(Icons.person, size: 30)
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    h['full_name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${h['department']} · Batch $batch",
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  RequestService().showRequestPopup(
                    context: context,
                    helperId: h['id'],
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Request",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
