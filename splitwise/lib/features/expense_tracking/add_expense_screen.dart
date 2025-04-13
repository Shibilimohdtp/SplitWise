import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/models/expense.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/auth_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/widgets/feedback/status_snackbar.dart';
import 'package:splitwise/widgets/add_expense/expense_details_section.dart';
import 'package:splitwise/widgets/add_expense/participants_section.dart';
import 'package:splitwise/widgets/add_expense/split_method_section.dart';
import 'package:splitwise/widgets/add_expense/additional_details_section.dart';
import 'package:splitwise/widgets/common/action_bottom_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';

class AddExpenseScreen extends StatefulWidget {
  final Group group;

  const AddExpenseScreen({super.key, required this.group});

  @override
  AddExpenseScreenState createState() => AddExpenseScreenState();
}

class AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late ExpenseService _expenseService;
  late UserService _userService;

  // Controllers
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  final _commentController = TextEditingController();

  // State variables
  String _category = 'Uncategorized';
  String _splitMethod = 'Equal';
  final Map<String, bool> _participants = {};
  final Map<String, double> _customSplitAmounts = {};
  final Map<String, double> _percentageSplits = {};
  final Map<String, int> _shareSplits = {};
  File? _receiptImage;
  String? _receiptImageUrl;
  bool _isUploadingReceipt = false;
  bool _isSubmitting = false;

  // Constants
  final List<String> _categories = [
    'Uncategorized',
    'Food',
    'Transport',
    'Entertainment',
    'Utilities',
    'Rent',
    'Other'
  ];
  final List<String> _splitMethods = ['Equal', 'Exact', 'Percentage', 'Shares'];

  @override
  void initState() {
    super.initState();
    final settingsService =
        Provider.of<SettingsService>(context, listen: false);
    _expenseService = ExpenseService(settingsService);
    _userService = UserService();

    // Initialize participants map for all group members
    for (var memberId in widget.group.members) {
      _participants[memberId] = true;
      _customSplitAmounts[memberId] = 0;
      _percentageSplits[memberId] = 0;
      _shareSplits[memberId] = 1;
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          'Add Expense',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, size: 20),
          onPressed: () => Navigator.pop(context),
          iconSize: 20,
          style: IconButton.styleFrom(
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            ExpenseDetailsSection(
              descriptionController: _descriptionController,
              amountController: _amountController,
              selectedCategory: _category,
              onCategorySelected: (category) {
                setState(() {
                  _category = category;
                });
              },
              categories: _categories,
            ),
            const SizedBox(height: 12),
            ParticipantsSection(
              group: widget.group,
              userService: _userService,
              participants: _participants,
              onParticipantToggled: (memberId, isSelected) {
                setState(() {
                  _participants[memberId] = isSelected;
                });
              },
              onSelectAll: () {
                setState(() {
                  for (var memberId in widget.group.members) {
                    _participants[memberId] = true;
                  }
                });
              },
              onClearAll: () {
                setState(() {
                  for (var memberId in widget.group.members) {
                    _participants[memberId] = false;
                  }
                });
              },
            ),
            const SizedBox(height: 12),
            SplitMethodSection(
              group: widget.group,
              userService: _userService,
              splitMethod: _splitMethod,
              splitMethods: _splitMethods,
              onSplitMethodChanged: (method) {
                setState(() {
                  _splitMethod = method;
                });
              },
              participants: _participants,
              customSplitAmounts: _customSplitAmounts,
              percentageSplits: _percentageSplits,
              shareSplits: _shareSplits,
              onCustomSplitChanged: (memberId, amount) {
                setState(() {
                  _customSplitAmounts[memberId] = amount;
                });
              },
              onPercentageSplitChanged: (memberId, percentage) {
                setState(() {
                  _percentageSplits[memberId] = percentage;
                });
              },
              onShareSplitChanged: (memberId, shares) {
                setState(() {
                  _shareSplits[memberId] = shares;
                });
              },
            ),
            const SizedBox(height: 12),
            AdditionalDetailsSection(
              commentController: _commentController,
              receiptImageUrl: _receiptImageUrl,
              isUploadingReceipt: _isUploadingReceipt,
              onPickImage: _pickAndUploadImage,
              onRemoveImage: () {
                setState(() {
                  _receiptImageUrl = null;
                });
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: ActionBottomBar.withAmount(
        actionText: 'Add Expense',
        onAction: _submit,
        isLoading: _isSubmitting,
        amount: double.tryParse(_amountController.text) ?? 0,
        currency: Provider.of<SettingsService>(context).currency,
      ),
    );
  }

  Future<void> _pickAndUploadImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _receiptImage = File(image.path);
      });
      await _uploadReceiptImage(_receiptImage!);
    }
  }

  Future<void> _uploadReceiptImage(File image) async {
    setState(() {
      _isUploadingReceipt = true;
    });

    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('receipts/${DateTime.now().millisecondsSinceEpoch}.jpg');
      final uploadTask = storageRef.putFile(image);
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      if (mounted) {
        setState(() {
          _receiptImageUrl = downloadUrl;
        });
      }
    } catch (e) {
      if (mounted) {
        StatusSnackbar.showError(
          context,
          message: 'Failed to upload receipt image',
          details: 'Please try again.',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingReceipt = false;
        });
      }
    }
  }

  Map<String, double> _calculateSplitDetails() {
    final activeParticipants = _participants.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    final amount = double.tryParse(_amountController.text) ?? 0;

    switch (_splitMethod) {
      case 'Equal':
        final splitAmount = amount / activeParticipants.length;
        return Map.fromEntries(
          activeParticipants.map((uid) => MapEntry(uid, splitAmount)),
        );

      case 'Exact':
        return Map.fromEntries(
          activeParticipants.map(
            (uid) => MapEntry(uid, _customSplitAmounts[uid] ?? 0),
          ),
        );

      case 'Percentage':
        return Map.fromEntries(
          activeParticipants.map(
            (uid) => MapEntry(
              uid,
              (_percentageSplits[uid] ?? 0) * amount / 100,
            ),
          ),
        );

      case 'Shares':
        final totalShares = activeParticipants.fold<int>(
          0,
          (sum, uid) => sum + (_shareSplits[uid] ?? 1),
        );
        final valuePerShare = amount / totalShares;
        return Map.fromEntries(
          activeParticipants.map(
            (uid) => MapEntry(
              uid,
              (_shareSplits[uid] ?? 1) * valuePerShare,
            ),
          ),
        );

      default:
        return {};
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_isSubmitting) return;

      setState(() => _isSubmitting = true);

      try {
        final authService = Provider.of<AuthService>(context, listen: false);
        final settingsService =
            Provider.of<SettingsService>(context, listen: false);
        final splitDetails = _calculateSplitDetails();
        final amount = double.tryParse(_amountController.text) ?? 0;

        final expense = Expense(
          id: '',
          groupId: widget.group.id,
          payerId: authService.currentUser!.uid,
          amount: amount,
          currency: settingsService.currency,
          description: _descriptionController.text,
          date: DateTime.now(),
          splitDetails: splitDetails,
          category: _category,
          comment: _commentController.text,
          splitMethod: _splitMethod,
          receiptUrl: _receiptImageUrl,
        );

        await _expenseService.addExpense(expense);

        if (mounted) {
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          StatusSnackbar.showError(
            context,
            message: 'Failed to add expense',
            details: 'Please try again.',
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSubmitting = false);
        }
      }
    }
  }
}
