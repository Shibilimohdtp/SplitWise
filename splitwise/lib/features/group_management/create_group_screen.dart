import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/services/auth_service.dart';
import 'package:splitwise/services/group_service.dart';
import 'package:splitwise/widgets/common/animated_wrapper.dart';
import 'package:splitwise/widgets/feedback/status_snackbar.dart';
import 'package:splitwise/widgets/create_group/group_info_section.dart';
import 'package:splitwise/widgets/create_group/members_section.dart';
import 'package:splitwise/widgets/common/action_bottom_bar.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  CreateGroupScreenState createState() => CreateGroupScreenState();
}

class CreateGroupScreenState extends State<CreateGroupScreen> {
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
          throw Exception('No user logged in. Please sign in again.');
        }

        // Create the group first
        final group = await groupService.createGroup(
          _nameController.text.trim(),
          _descriptionController.text.trim(),
          currentUser.uid,
        );

        if (group != null) {
          // If there are members to add
          if (_members.isNotEmpty) {
            try {
              // Add members one by one and catch individual errors
              for (String memberEmail in _members) {
                try {
                  await groupService.inviteMember(group.id, memberEmail);
                } catch (memberError) {
                  // Log the error but continue with other members
                  if (kDebugMode) {
                    print('Error adding member $memberEmail: $memberError');
                  }
                  // Optionally show a warning for this specific member
                  if (mounted) {
                    StatusSnackbar.showError(
                      context,
                      message: 'Could not add $memberEmail',
                      details: memberError.toString(),
                    );
                  }
                }
              }
            } catch (membersError) {
              // If there's a general error with adding members, log it
              if (kDebugMode) {
                print('Error adding members: $membersError');
              }
              // But still consider the group creation successful
            }
          }

          if (mounted) {
            // Show success message before popping
            StatusSnackbar.showSuccess(
              context,
              message: 'Group created successfully!',
            );
            // Delay navigation slightly to allow snackbar to be seen
            Future.delayed(const Duration(milliseconds: 1000), () {
              if (mounted) {
                Navigator.of(context).pop(true);
              }
            });
          }
        } else {
          throw Exception('Failed to create group. Please try again.');
        }
      } catch (e) {
        if (mounted) {
          StatusSnackbar.showError(
            context,
            message: 'Failed to create group',
            details: e.toString(),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  bool _isValidEmail(String email) {
    // Simple email validation regex
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  void _addMember() {
    final email = _memberEmailController.text.trim();

    // Validate email format
    if (email.isEmpty) {
      StatusSnackbar.showError(context,
          message: 'Please enter an email address');
      return;
    }

    if (!_isValidEmail(email)) {
      StatusSnackbar.showError(context,
          message: 'Please enter a valid email address');
      return;
    }

    if (_members.contains(email)) {
      StatusSnackbar.showError(context,
          message: 'This email is already added to the group');
      return;
    }

    // Add the member
    setState(() {
      _members.add(email);
      _memberEmailController.clear();
    });

    // Show a small confirmation
    StatusSnackbar.showInfo(
      context,
      message: '$email added to group',
    );

    _emailFocusNode.requestFocus();
  }

  void _removeMember(String email) {
    setState(() {
      _members.remove(email);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        scrolledUnderElevation: 2,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Create New Group',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor:
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            children: [
              // Animated sections
              AnimatedWrapper(
                child: GroupInfoSection(
                  nameController: _nameController,
                  descriptionController: _descriptionController,
                  nameValidator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter a group name';
                    }
                    return null;
                  },
                  descriptionValidator: (value) {
                    if (value?.isEmpty ?? true) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(height: 16),
              // Second animated section with delay
              AnimatedWrapper.delayed(
                delay: const Duration(milliseconds: 100),
                child: MembersSection(
                  memberEmailController: _memberEmailController,
                  members: _members,
                  emailFocusNode: _emailFocusNode,
                  onAddMember: _addMember,
                  onRemoveMember: _removeMember,
                  onSubmitted: (_) => _addMember(),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: ActionBottomBar(
        actionText: 'Create Group',
        onAction: _submit,
        isLoading: _isLoading,
      ),
    );
  }
}
