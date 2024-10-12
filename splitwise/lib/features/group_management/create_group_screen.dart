import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/services/auth_service.dart';
import 'package:splitwise/services/group_service.dart';
import 'package:splitwise/utils/app_color.dart';
import 'package:splitwise/widgets/custom_text_field.dart';
import 'package:splitwise/widgets/custom_button.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({Key? key}) : super(key: key);

  @override
  _CreateGroupScreenState createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
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
          if (mounted) {
            Navigator.of(context).pop(true); // Return true to indicate success
          }
        } else {
          throw Exception('Failed to create group');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to create group: ${e.toString()}')),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Create New Group'),
        backgroundColor: AppColors.primaryMain,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CustomTextField(
                  controller: _nameController,
                  labelText: 'Group Name',
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a group name' : null,
                ),
                SizedBox(height: 16),
                CustomTextField(
                  controller: _descriptionController,
                  labelText: 'Description',
                  maxLines: 3,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter a description' : null,
                ),
                SizedBox(height: 24),
                CustomButton(
                  onPressed: _isLoading ? null : _submit,
                  child: _isLoading
                      ? CircularProgressIndicator(color: AppColors.textMain)
                      : Text('Create Group'),
                  color: AppColors.accentMain,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
