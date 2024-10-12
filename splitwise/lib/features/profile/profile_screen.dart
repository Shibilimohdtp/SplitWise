import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:splitwise/services/auth_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/models/user.dart';
import 'package:splitwise/widgets/custom_text_field.dart';
import 'package:splitwise/utils/app_color.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  final UserService _userService = UserService();
  String? _profileImageUrl;
  bool _isLoading = false;
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _usernameController = TextEditingController();
    _emailController = TextEditingController();
    _loadUserData();
  }

  void _loadUserData() async {
    setState(() => _isLoading = true);
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser!.uid;
    final userData = await _userService.getUserData(userId);
    setState(() {
      _nameController.text = userData['name'] ?? '';
      _usernameController.text = userData['username'] ?? '';
      _emailController.text = userData['email'] ?? '';
      _profileImageUrl = userData['profileImageUrl'];
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() => _isUpdating = true);
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final userId = authService.currentUser!.uid;
        await _userService.updateProfileImage(userId, File(image.path));
        String? newImageUrl = await _userService.getProfileImageUrl(userId);
        setState(() {
          _profileImageUrl = newImageUrl;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Profile picture updated successfully')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Failed to update profile picture: ${e.toString()}')),
        );
      }
      setState(() => _isUpdating = false);
    }
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundColor: AppColors.backgroundLight,
          backgroundImage:
              _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
          child: _profileImageUrl == null
              ? Icon(Icons.person, size: 60, color: AppColors.primaryMain)
              : null,
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: GestureDetector(
            onTap: _pickAndUploadImage,
            child: Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentMain,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.camera_alt, color: Colors.white, size: 20),
            ),
          ),
        ),
        if (_isUpdating)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text('Profile', style: TextStyle(color: Colors.white)),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryLight, AppColors.primaryMain],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildProfileImage(),
                        SizedBox(height: 24),
                        _buildInfoCard(),
                        SizedBox(height: 24),
                        _buildSaveButton(authService),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomTextField(
              controller: _nameController,
              labelText: 'Name',
              // prefixIcon: Icon(Icons.person, color: AppColors.primaryMain),
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _usernameController,
              labelText: 'Username',
              // prefixIcon:
              //     Icon(Icons.alternate_email, color: AppColors.primaryMain),
            ),
            SizedBox(height: 16),
            CustomTextField(
              controller: _emailController,
              labelText: 'Email',
              readOnly: true,
              // prefixIcon: Icon(Icons.email, color: AppColors.primaryMain),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSaveButton(AuthService authService) {
    return ElevatedButton(
      onPressed: _isLoading || _isUpdating
          ? null
          : () async {
              setState(() => _isUpdating = true);
              User updatedUser = User(
                uid: authService.currentUser!.uid,
                name: _nameController.text,
                username: _usernameController.text,
                email: _emailController.text,
              );
              try {
                await _userService.updateUserProfile(updatedUser);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Profile updated successfully')),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Failed to update profile: ${e.toString()}')),
                );
              }
              setState(() => _isUpdating = false);
            },
      child: _isUpdating
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : Text('Save Changes'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: AppColors.accentMain,
        padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
    );
  }
}
