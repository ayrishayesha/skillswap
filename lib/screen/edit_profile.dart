import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_app/screen/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfile extends StatefulWidget {
  const EditProfile({super.key});

  @override
  State<EditProfile> createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final supabase = Supabase.instance.client;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final deptController = TextEditingController();
  final batchController = TextEditingController();
  final bioController = TextEditingController();

  Uint8List? imageBytes;
  XFile? pickedFile;

  String? existingAvatarUrl;

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
          .select('full_name, department, batch, avatar_url, bio')
          .eq('id', user.id)
          .maybeSingle();

      if (res != null) {
        nameController.text = res['full_name'] ?? '';
        deptController.text = res['department'] ?? '';
        batchController.text = res['batch']?.toString() ?? '';
        existingAvatarUrl = res['avatar_url'];
        bioController.text = res['bio'] ?? '';
      }
    } catch (e) {
      debugPrint("Load error: $e");
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
      setState(() {});
    }
  }

  Future<String?> uploadImage() async {
    if (pickedFile == null || imageBytes == null) return null;

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
  }

  Future<void> submitData() async {
    try {
      setState(() => loading = true);

      final user = supabase.auth.currentUser;
      if (user == null) throw "User not logged in";

      String? imageUrl;
      if (pickedFile != null) {
        imageUrl = await uploadImage();
      }

      final existingProfile = await supabase
          .from('profiles')
          .select('avatar_url')
          .eq('id', user.id)
          .maybeSingle();

      await supabase.from('profiles').upsert({
        'id': user.id,
        'email': user.email,
        'full_name': nameController.text.trim(),
        'department': deptController.text.trim(),
        'batch': int.tryParse(batchController.text.trim()),
        'avatar_url': imageUrl ?? existingProfile?['avatar_url'],
        'bio': bioController.text.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'id');

      if (!mounted) return;

      // <-- NEW: Show success SnackBar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Profile updated successfully!"),
          backgroundColor: Color(0xff3563E9),
          duration: Duration(seconds: 2),
        ),
      );

      // <-- NEW: Navigate back to Profile page after save
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const Learner_Profile_Page()),
        );
      });
    } catch (e) {
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
    batchController.dispose();
    bioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F6FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        title: const Text(
          "Edit Profile",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: loadingUserInfo
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 65,
                        backgroundColor: Colors.orange.shade200,
                        backgroundImage: imageBytes != null
                            ? MemoryImage(imageBytes!)
                            : (existingAvatarUrl != null
                                  ? NetworkImage(existingAvatarUrl!)
                                        as ImageProvider
                                  : null),
                        child: (imageBytes == null && existingAvatarUrl == null)
                            ? const Icon(
                                Icons.person,
                                size: 60,
                                color: Colors.white,
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
                            backgroundColor: Color(0xff3563E9),
                            child: Icon(
                              Icons.camera_alt,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "Change Photo",
                    style: TextStyle(
                      color: Color(0xff3563E9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  buildLabel("FULL NAME"),
                  const SizedBox(height: 5),
                  buildField(nameController),
                  const SizedBox(height: 18),
                  buildLabel("DEPARTMENT"),
                  const SizedBox(height: 5),
                  buildField(deptController),
                  const SizedBox(height: 18),
                  buildLabel("EMAIL"),
                  const SizedBox(height: 5),
                  buildField(emailController, readOnly: true),
                  const SizedBox(height: 20),
                  buildLabel("BATCH"),
                  const SizedBox(height: 5),
                  buildField(batchController, isNumber: true),
                  const SizedBox(height: 20),
                  buildLabel("BIO"),
                  const SizedBox(height: 5),
                  buildField(bioController),

                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: loading ? null : submitData,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(
                          255,
                          81,
                          117,
                          227,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 4,
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Save Changes",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  Widget buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          letterSpacing: 1,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget buildField(
    TextEditingController controller, {
    bool readOnly = false,
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        filled: true,
        fillColor: readOnly ? Colors.grey.shade200 : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
