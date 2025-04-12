import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/services/auth_service.dart';
import 'package:splitwise/services/group_service.dart';
import 'package:splitwise/utils/app_color.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _memberEmailController = TextEditingController();
  bool _isLoading = false;
  final List<String> _members = [];
  final FocusNode _emailFocusNode = FocusNode();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _memberEmailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final groupService = GroupService();
        final currentUser = authService.currentUser;

        if (currentUser == null) {
          throw Exception('No user logged in');
        }

        final group = await groupService.createGroup(
          _nameController.text,
          _descriptionController.text,
          currentUser.uid,
        );

        if (group != null) {
          for (String memberEmail in _members) {
            await groupService.inviteMember(group.id, memberEmail);
          }
          if (mounted) {
            Navigator.of(context).pop(true);
          }
        } else {
          throw Exception('Failed to create group');
        }
      } catch (e) {
        if (mounted) {
          _showErrorSnackBar(e.toString());
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Failed to create group: $message',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
        duration: const Duration(seconds: 4),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _addMember() {
    final email = _memberEmailController.text.trim();
    if (email.isNotEmpty && !_members.contains(email)) {
      setState(() {
        _members.add(email);
        _memberEmailController.clear();
      });
      _emailFocusNode.requestFocus();
    }
  }

  void _removeMember(String email) {
    setState(() {
      _members.remove(email);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryMain.withValues(alpha: 0.05),
                offset: const Offset(0, 2),
                blurRadius: 8,
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Column(
              children: [
                Text(
                  'Create New Group',
                  style: TextStyle(
                    color: AppColors.textMain,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textMain),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            children: [
              _buildGroupInfoSection(),
              const SizedBox(height: 32),
              _buildMembersSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildGroupInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Group Information',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textMain,
          ),
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _nameController,
          label: 'Group Name',
          hint: 'Enter group name',
          icon: Icons.group_outlined,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter a group name';
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildTextField(
          controller: _descriptionController,
          label: 'Description',
          hint: 'Enter group description',
          icon: Icons.description_outlined,
          maxLines: 3,
          validator: (value) {
            if (value?.isEmpty ?? true) {
              return 'Please enter a description';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildMembersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Add Members',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textMain,
              ),
            ),
            Text(
              '${_members.length} members',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _buildTextField(
                controller: _memberEmailController,
                label: 'Email Address',
                hint: 'Enter member\'s email',
                icon: Icons.email_outlined,
                focusNode: _emailFocusNode,
                onSubmitted: (_) => _addMember(),
                keyboardType: TextInputType.emailAddress,
              ),
            ),
            const SizedBox(width: 12),
            _buildAddButton(),
          ],
        ),
        const SizedBox(height: 24),
        _buildMembersList(),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
    FocusNode? focusNode,
    void Function(String)? onSubmitted,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textLight,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textLight.withValues(alpha: 0.5),
              fontSize: 16,
            ),
            prefixIcon: Icon(icon, color: AppColors.textLight),
            filled: true,
            fillColor: AppColors.surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderLight),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryMain),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
          style: const TextStyle(
            fontSize: 16,
            color: AppColors.textMain,
          ),
          maxLines: maxLines,
          validator: validator,
          onFieldSubmitted: onSubmitted,
          keyboardType: keyboardType,
        ),
      ],
    );
  }

  Widget _buildAddButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 28, 0, 0),
      height: 56,
      width: 56,
      child: ElevatedButton(
        onPressed: _addMember,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryMain,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Icon(Icons.add, size: 24),
      ),
    );
  }

  Widget _buildMembersList() {
    if (_members.isEmpty) {
      return Center(
        child: Column(
          children: [
            const SizedBox(height: 32),
            Icon(
              Icons.person_add_outlined,
              size: 48,
              color: AppColors.textLight.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No members added yet',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.textLight.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _members.length,
      itemBuilder: (context, index) {
        final email = _members[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.secondaryMain.withValues(alpha: 0.1),
              child: Text(
                email[0].toUpperCase(),
                style: const TextStyle(
                  color: AppColors.secondaryMain,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            title: Text(
              email,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textMain,
                fontWeight: FontWeight.w500,
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.remove_circle_outline,
                  color: AppColors.error),
              onPressed: () => _removeMember(email),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryMain.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 16,
          ),
        ],
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: _isLoading ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryMain,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: _isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'Create Group',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ),
    );
  }
}
