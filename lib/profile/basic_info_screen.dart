import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:my_app/profile/showcase_skills.dart';

class BasicInfo extends StatefulWidget {
  const BasicInfo({super.key});

  @override
  State<BasicInfo> createState() => _BasicInfoState();
}

class _BasicInfoState extends State<BasicInfo> {
  final supabase = Supabase.instance.client;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final deptController = TextEditingController();
  final batchController = TextEditingController();

  Uint8List? imageBytes;
  XFile? pickedFile;

  bool loading = false;
  bool loadingUserInfo = true;

  @override
  void initState() {
    super.initState();
    loadProfile();
  }

  Future<void> loadProfile() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      emailController.text = user.email ?? '';

      final res = await supabase
          .from('profiles')
          .select('full_name, department, avatar_url, batch')
          .eq('id', user.id)
          .maybeSingle();

      if (res != null) {
        nameController.text = (res['full_name'] ?? '').toString();
        deptController.text = (res['department'] ?? '').toString();
        batchController.text = (res['batch'] ?? '').toString();
      }
    } catch (e) {
      debugPrint("loadProfile error: $e");
    } finally {
      if (mounted) setState(() => loadingUserInfo = false);
    }
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      imageBytes = await file.readAsBytes();
      pickedFile = file;
      if (mounted) setState(() {});
    }
  }

  Future<String?> uploadImage() async {
    if (pickedFile == null || imageBytes == null) return null;

    try {
      final user = supabase.auth.currentUser;
      if (user == null) return null;

      final filePath =
          "${user.id}/avatar_${DateTime.now().millisecondsSinceEpoch}.jpg";

      await supabase.storage
          .from('Bucket1')
          .uploadBinary(
            filePath,
            imageBytes!,
            fileOptions: const FileOptions(contentType: 'image/jpeg'),
          );

      return supabase.storage.from('Bucket1').getPublicUrl(filePath);
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  Future<void> submitData() async {
    try {
      setState(() => loading = true);

      final user = supabase.auth.currentUser;
      if (user == null) throw "User not logged in";

      final fullName = nameController.text.trim();
      final dept = deptController.text.trim();
      final batchText = batchController.text.trim();

      if (fullName.isEmpty || dept.isEmpty || batchText.isEmpty) {
        throw "Please fill all fields";
      }

      final batchValue = int.tryParse(batchText);
      if (batchValue == null) throw "Batch must be a number";

      final imageUrl = await uploadImage();

      await supabase.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'full_name': fullName,
        'department': dept,
        'batch': batchValue, // ✅ save batch
        'avatar_url': imageUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ShowcaseSkillsPage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    deptController.dispose();
    batchController.dispose(); // ✅ added
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Basic Info"), centerTitle: true),
      body: loadingUserInfo
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: imageBytes != null
                            ? MemoryImage(imageBytes!)
                            : null,
                        child: imageBytes == null
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.grey,
                              )
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: pickImage,
                          child: const CircleAvatar(
                            radius: 18,
                            backgroundColor: Colors.deepPurple,
                            child: Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  buildField(controller: nameController, hint: "Full Name"),
                  const SizedBox(height: 15),

                  buildField(
                    controller: emailController,
                    hint: "Email",
                    readOnly: true,
                  ),
                  const SizedBox(height: 15),

                  buildField(controller: deptController, hint: "Department"),
                  const SizedBox(height: 15),

                  buildField(
                    controller: batchController,
                    hint: "Batch (Number)",
                    isNumber: true,
                  ),

                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading ? null : submitData,
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text("Next"),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget buildField({
    required TextEditingController controller,
    required String hint,
    bool readOnly = false,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        hintText: hint,
        filled: readOnly,
        fillColor: readOnly ? Colors.grey.shade100 : null,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
