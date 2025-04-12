import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:splitwise/services/auth_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/models/user.dart';
import 'package:splitwise/utils/app_color.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _emailController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final UserService _userService = UserService();
  String? _profileImageUrl;
  bool _isLoading = false;
  bool _isUpdating = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController()..addListener(_checkChanges);
    _usernameController = TextEditingController()..addListener(_checkChanges);
    _emailController = TextEditingController();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    _loadUserData();
  }

  void _checkChanges() {
    if (!_isLoading) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final userId = authService.currentUser!.uid;
      final userData = await _userService.getUserData(userId);

      setState(() {
        _nameController.text = userData['name'] ?? '';
        _usernameController.text = userData['username'] ?? '';
        _emailController.text = userData['email'] ?? '';
        _profileImageUrl = userData['profileImageUrl'];
        _isLoading = false;
        _hasChanges = false;
      });

      _animationController.forward();
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load profile data');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() => _isUpdating = true);
        final authService = Provider.of<AuthService>(context, listen: false);
        final userId = authService.currentUser!.uid;

        await _userService.updateProfileImage(userId, File(image.path));
        String? newImageUrl = await _userService.getProfileImageUrl(userId);

        setState(() {
          _profileImageUrl = newImageUrl;
          _hasChanges = true;
        });

        _showSuccessSnackBar('Profile picture updated successfully');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to update profile picture');
    } finally {
      setState(() => _isUpdating = false);
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildProfileImage() {
    return Stack(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.surfaceLight,
              width: 4,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryMain.withValues(alpha: 0.2),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            backgroundColor: AppColors.surfaceLight,
            backgroundImage: _profileImageUrl != null
                ? NetworkImage(_profileImageUrl!)
                : null,
            child: _profileImageUrl == null
                ? Icon(
                    Icons.person_outline_rounded,
                    size: 60,
                    color: AppColors.primaryMain.withValues(alpha: 0.5),
                  )
                : null,
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Material(
            color: AppColors.primaryMain,
            elevation: 4,
            shadowColor: AppColors.primaryMain.withValues(alpha: 0.4),
            shape: const CircleBorder(),
            child: InkWell(
              onTap: !_isUpdating ? _pickAndUploadImage : null,
              customBorder: const CircleBorder(),
              child: Container(
                padding: const EdgeInsets.all(12),
                child: const Icon(
                  Icons.camera_alt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ),
        ),
        if (_isUpdating)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  strokeWidth: 2,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool readOnly = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textLight,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            readOnly: readOnly,
            decoration: InputDecoration(
              prefixIcon: Icon(icon, color: AppColors.primaryMain),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.borderLight),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryMain),
              ),
            ),
            style: TextStyle(
              fontSize: 16,
              color: readOnly ? AppColors.textLight : AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Profile',
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.w600,
            fontSize: 24,
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: _isLoading
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(child: _buildProfileImage()),
                          const SizedBox(height: 32),
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryMain
                                      .withValues(alpha: 0.05),
                                  offset: const Offset(0, 4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Personal Information',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textMain,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                _buildTextField(
                                  controller: _nameController,
                                  label: 'Full Name',
                                  icon: Icons.person_outline_rounded,
                                ),
                                _buildTextField(
                                  controller: _usernameController,
                                  label: 'Username',
                                  icon: Icons.alternate_email_rounded,
                                ),
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Email Address',
                                  icon: Icons.email_outlined,
                                  readOnly: true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          ElevatedButton(
                            onPressed: (_hasChanges && !_isUpdating)
                                ? () async {
                                    setState(() => _isUpdating = true);
                                    try {
                                      final authService =
                                          Provider.of<AuthService>(
                                        context,
                                        listen: false,
                                      );
                                      User updatedUser = User(
                                        uid: authService.currentUser!.uid,
                                        name: _nameController.text,
                                        username: _usernameController.text,
                                        email: _emailController.text,
                                      );
                                      await _userService
                                          .updateUserProfile(updatedUser);
                                      setState(() => _hasChanges = false);
                                      _showSuccessSnackBar(
                                          'Profile updated successfully');
                                    } catch (e) {
                                      _showErrorSnackBar(
                                          'Failed to update profile');
                                    } finally {
                                      setState(() => _isUpdating = false);
                                    }
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryMain,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              disabledBackgroundColor:
                                  AppColors.primaryMain.withValues(alpha: 0.5),
                            ),
                            child: _isUpdating
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
