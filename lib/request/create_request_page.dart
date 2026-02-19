import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:my_app/request/request_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateRequestPage extends StatefulWidget {
  final String helperId;

  const CreateRequestPage({super.key, required this.helperId});

  @override
  State<CreateRequestPage> createState() => _CreateRequestPageState();
}

class _CreateRequestPageState extends State<CreateRequestPage> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController subjectController = TextEditingController();

  final supabase = Supabase.instance.client;

  List<String> skills = [];
  PlatformFile? selectedFile;

  /// ================= FETCH SKILLS =================
  Future<void> fetchSkills() async {
    final response = await supabase.from('skills').select('name');

    setState(() {
      skills = response.map<String>((e) => e['name'] as String).toList();
    });
  }

  @override
  void initState() {
    super.initState();
    fetchSkills();
  }

  /// ================= PICK FILE =================
  Future<void> pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      withData: true,
      type: FileType.custom,
      allowedExtensions: ['jpg', 'png', 'pdf', 'docx'],
    );

    if (result != null) {
      setState(() {
        selectedFile = result.files.first;
      });
    }
  }

  /// ================= FILE PREVIEW =================
  Widget filePreview() {
    if (selectedFile == null) return const SizedBox();

    IconData fileIcon = Icons.insert_drive_file;
    Color iconColor = Colors.blue;

    switch (selectedFile!.extension) {
      case 'jpg':
      case 'png':
        fileIcon = Icons.image;
        iconColor = Colors.green;
        break;
      case 'pdf':
        fileIcon = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'doc':
      case 'docx':
        fileIcon = Icons.description;
        iconColor = Colors.blue;
        break;
      default:
        fileIcon = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  padding: const EdgeInsets.all(5),
                  child: Icon(fileIcon, color: iconColor, size: 40),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                selectedFile!.name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 6),
              Text(
                "${(selectedFile!.size / 1024).toStringAsFixed(2)} KB",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          Positioned(
            right: 0,
            top: 0,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.red),
              onPressed: () {
                setState(() {
                  selectedFile = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          "Create Request",
          style: TextStyle(color: Colors.black),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            /// ================= SELECT SKILL =================
            const Text(
              "Select Skill",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            /// 🔥 Autocomplete Search Field (Main field e search)
            Autocomplete<String>(
              optionsBuilder: (TextEditingValue value) {
                if (value.text.isEmpty) {
                  return skills;
                }
                return skills.where(
                  (skill) =>
                      skill.toLowerCase().contains(value.text.toLowerCase()),
                );
              },
              onSelected: (value) {
                subjectController.text = value;
              },
              fieldViewBuilder:
                  (context, controller, focusNode, onFieldSubmitted) {
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        hintText: "Choose a subject",
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
            ),

            const SizedBox(height: 20),

            /// ================= TITLE =================
            const Text(
              "Request Title",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: "e.g. Help with Recursion in Java",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// ================= DESCRIPTION =================
            const Text(
              "Problem Description",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Describe your problem...",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            /// ================= ATTACHMENT =================
            const Text(
              "Attachment",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: pickFile,
              child: Container(
                height: 180,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: selectedFile == null
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.upload_file, size: 40),
                          SizedBox(height: 8),
                          Text("Tap to upload file or image"),
                        ],
                      )
                    : filePreview(),
              ),
            ),
            const SizedBox(height: 30),

            /// ================= POST BUTTON =================
            SizedBox(
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  if (subjectController.text.isEmpty ||
                      titleController.text.isEmpty ||
                      descriptionController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please fill all fields")),
                    );
                    return;
                  }

                  RequestService().sendFinalRequest(
                    context: context,
                    helperId: widget.helperId,
                    title: titleController.text.trim(),
                    description: descriptionController.text.trim(),
                    subject: subjectController.text.trim(),
                    file: selectedFile,
                  );
                },
                child: const Text(
                  "Post Request",
                  style: TextStyle(
                    color: Color.fromARGB(255, 255, 255, 255),
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
