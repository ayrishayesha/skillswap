import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BasicInfo extends StatefulWidget {
  const BasicInfo({super.key});

  @override
  State<BasicInfo> createState() => _BasicInfoState();
}

class _BasicInfoState extends State<BasicInfo> {
  // Controllers
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final deptController = TextEditingController();
  final batchController = TextEditingController();

  final supabase = Supabase.instance.client;

  Uint8List? imageBytes;
  XFile? pickedFile;

  bool loading = false;

  // Pick Image
  Future<void> pickImage() async {
    final picker = ImagePicker();

    final XFile? result = await picker.pickImage(source: ImageSource.gallery);

    if (result != null) {
      final bytes = await result.readAsBytes();

      setState(() {
        pickedFile = result;
        imageBytes = bytes;
      });
    }
  }

  // Upload Image to Supabase Storage
  Future<String?> uploadImage() async {
    if (pickedFile == null || imageBytes == null) return null;

    try {
      final fileName = "profile_${DateTime.now().millisecondsSinceEpoch}.jpg";

      await supabase.storage
          .from('Bucket1')
          .uploadBinary(
            fileName,
            imageBytes!,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      final url = supabase.storage.from('Bucket1').getPublicUrl(fileName);

      return url;
    } catch (e) {
      debugPrint("Upload Error: $e");
      return null;
    }
  }

  // Save Data to users Table
  Future<void> submitData() async {
    setState(() {
      loading = true;
    });

    try {
      // Get current user
      final user = supabase.auth.currentUser;

      if (user == null) {
        throw "User not logged in";
      }

      final name = nameController.text.trim();
      final email = emailController.text.trim();
      final dept = deptController.text.trim();
      final batch = batchController.text.trim();

      if (name.isEmpty || email.isEmpty || dept.isEmpty || batch.isEmpty) {
        throw "Fill all fields";
      }

      // Upload Image
      final imageUrl = await uploadImage();

      // Insert into users table
      await supabase.from('users').insert({
        'id': user.id,
        'name': name,
        'email': email,
        'department': dept,
        'batch': int.parse(batch),
        'profile_pic': imageUrl,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile Saved Successfully")),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() {
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Colors.black),
        title: const Text("Basic Info", style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // Progress
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 20,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Title
            const Text(
              "Let's set up your profile",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            const Text(
              "Add your details so others can find you.",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 30),

            // Profile Image
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: imageBytes != null
                        ? MemoryImage(imageBytes!)
                        : null,
                    child: imageBytes == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : null,
                  ),

                  Positioned(
                    bottom: 0,
                    right: 0,

                    child: GestureDetector(
                      onTap: pickImage,

                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),

                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            const Center(
              child: Text(
                "Upload Photo (Optional)",
                style: TextStyle(
                  color: Colors.deepPurple,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 30),

            buildField(controller: nameController, hint: "Full Name"),

            const SizedBox(height: 15),

            buildField(controller: emailController, hint: "Email"),

            const SizedBox(height: 15),

            buildField(controller: deptController, hint: "Department"),

            const SizedBox(height: 15),

            buildField(
              controller: batchController,
              hint: "Batch (Number)",
              isNumber: true,
            ),

            const SizedBox(height: 40),

            // Next Button
            SizedBox(
              width: double.infinity,
              height: 55,

              child: ElevatedButton(
                onPressed: loading ? null : submitData,

                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),

                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Next",
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Input Field
  Widget buildField({
    required TextEditingController controller,
    required String hint,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,

      keyboardType: isNumber ? TextInputType.number : TextInputType.text,

      decoration: InputDecoration(
        hintText: hint,

        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),

        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.deepPurple),
        ),
      ),
    );
  }
}
