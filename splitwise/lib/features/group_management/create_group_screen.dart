import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/auth_service.dart';
import 'package:splitwise/services/group_service.dart';

import 'package:splitwise/widgets/common/action_bottom_bar.dart';
import 'package:splitwise/widgets/common/animated_wrapper.dart';
import 'package:splitwise/widgets/create_group/group_info_section.dart';
import 'package:splitwise/widgets/create_group/members_section.dart';
import 'package:splitwise/widgets/feedback/status_snackbar.dart';

class CreateGroupScreen extends StatefulWidget {
  final Group? group;
  const CreateGroupScreen({super.key, this.group});

  @override
  CreateGroupScreenState createState() => CreateGroupScreenState();
}

class CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final _memberEmailController = TextEditingController();
  bool _isLoading = false;
  final List<String> _members = [];
  final FocusNode _emailFocusNode = FocusNode();
  bool get _isEditMode => widget.group != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group?.name);
    _descriptionController =
        TextEditingController(text: widget.group?.description);
    if (_isEditMode) {
      _members.addAll(widget.group!.invitedEmails);
    }
  }

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
        final groupService = GroupService();
        if (_isEditMode) {
          final updatedGroup = widget.group!.copyWith(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            invitedEmails: _members,
          );
          await groupService.updateGroup(updatedGroup);
          if (mounted) {
            StatusSnackbar.showSuccess(
              context,
              message: 'Group updated successfully!',
            );
            Navigator.of(context).pop(true);
          }
        } else {
          final authService = Provider.of<AuthService>(context, listen: false);
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
        }
      } catch (e) {
        if (mounted) {
          StatusSnackbar.showError(
            context,
            message: _isEditMode
                ? 'Failed to update group'
                : 'Failed to create group',
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        title: Text(
          _isEditMode ? 'Edit Group' : 'Create New Group',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () => Navigator.pop(context),
          iconSize: 20,
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          children: [
            _buildAnimatedSection(
              index: 0,
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
            _buildAnimatedSection(
              index: 1,
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
      bottomNavigationBar: ActionBottomBar(
        actionText: _isEditMode ? 'Save Changes' : 'Create Group',
        onAction: _submit,
        isLoading: _isLoading,
      ),
    );
  }

  Widget _buildAnimatedSection({required int index, required Widget child}) {
    return AnimatedWrapper.staggered(
      index: index,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: child,
      ),
    );
  }
}
