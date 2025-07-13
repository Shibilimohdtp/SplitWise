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
import 'package:splitwise/widgets/add_expense/expense_confirmation_bottom_sheet.dart';
import 'package:splitwise/widgets/add_expense/payer_selection_section.dart';
import 'package:splitwise/widgets/common/action_bottom_bar.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:splitwise/widgets/common/animated_wrapper.dart';

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
  String? _selectedPayerId;
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
    final authService = Provider.of<AuthService>(context, listen: false);
    final settingsService =
        Provider.of<SettingsService>(context, listen: false);
    _expenseService = ExpenseService(settingsService);
    _userService = UserService();
    _selectedPayerId = authService.currentUser!.uid;

    // Initialize participants map for all group members
    for (var memberId in widget.group.memberIds) {
      _participants[memberId] = true;
      _customSplitAmounts[memberId] = 0;
      _percentageSplits[memberId] = 0;
      _shareSplits[memberId] = 1;
    }
    for (var email in widget.group.invitedEmails) {
      _participants[email] = true;
      _customSplitAmounts[email] = 0;
      _percentageSplits[email] = 0;
      _shareSplits[email] = 1;
    }

    // Add listener to amount controller to update the UI when amount changes
    _amountController.addListener(() {
      // This will trigger a rebuild when the amount changes
      if (mounted) {
        setState(() {});
      }
    });
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: colorScheme.surface,
        title: Text(
          'Add New Expense',
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
              child: ExpenseDetailsSection(
                descriptionController: _descriptionController,
                amountController: _amountController,
                selectedCategory: _category,
                onCategorySelected: (category) {
                  setState(() => _category = category);
                },
                categories: _categories,
              ),
            ),
            _buildAnimatedSection(
              index: 1,
              child: PayerSelectionSection(
                group: widget.group,
                userService: _userService,
                selectedPayerId: _selectedPayerId,
                onPayerSelected: (payerId) {
                  setState(() => _selectedPayerId = payerId);
                },
              ),
            ),
            _buildAnimatedSection(
              index: 2,
              child: ParticipantsSection(
                group: widget.group,
                userService: _userService,
                participants: _participants,
                onParticipantToggled: (memberId, isSelected) {
                  setState(() => _participants[memberId] = isSelected);
                },
                onSelectAll: () => setState(() {
                  for (var id in _getAllMemberIdentifiers()) {
                    _participants[id] = true;
                  }
                }),
                onClearAll: () => setState(() {
                  for (var id in _getAllMemberIdentifiers()) {
                    _participants[id] = false;
                  }
                }),
              ),
            ),
            _buildAnimatedSection(
              index: 3,
              child: SplitMethodSection(
                group: widget.group,
                userService: _userService,
                splitMethod: _splitMethod,
                splitMethods: _splitMethods,
                onSplitMethodChanged: (method) {
                  setState(() => _splitMethod = method);
                },
                participants: _participants,
                customSplitAmounts: _customSplitAmounts,
                percentageSplits: _percentageSplits,
                shareSplits: _shareSplits,
                onCustomSplitChanged: (memberId, amount) {
                  setState(() => _customSplitAmounts[memberId] = amount);
                },
                onPercentageSplitChanged: (memberId, percentage) {
                  setState(() => _percentageSplits[memberId] = percentage);
                },
                onShareSplitChanged: (memberId, shares) {
                  setState(() => _shareSplits[memberId] = shares);
                },
                totalAmount: double.tryParse(_amountController.text),
              ),
            ),
            _buildAnimatedSection(
              index: 4,
              child: AdditionalDetailsSection(
                commentController: _commentController,
                receiptImageUrl: _receiptImageUrl,
                isUploadingReceipt: _isUploadingReceipt,
                onPickImage: _pickAndUploadImage,
                onRemoveImage: () => setState(() => _receiptImageUrl = null),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
      bottomNavigationBar: ActionBottomBar(
        actionText: 'Add Expense',
        onAction: _submit,
        isLoading: _isSubmitting,
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

    // If no active participants, return empty map
    if (activeParticipants.isEmpty) {
      return {};
    }

    switch (_splitMethod) {
      case 'Equal':
        final splitAmount = amount / activeParticipants.length;
        return Map.fromEntries(
          activeParticipants.map((uid) => MapEntry(uid, splitAmount)),
        );

      case 'Exact':
        // Calculate the sum of all custom split amounts
        final Map<String, double> exactSplits = {};
        double totalAllocated = 0;

        // First pass: get all specified amounts
        for (var uid in activeParticipants) {
          final splitAmount = _customSplitAmounts[uid] ?? 0;
          exactSplits[uid] = splitAmount;
          totalAllocated += splitAmount;
        }

        // If the total doesn't match, adjust the values proportionally
        if (totalAllocated != 0 && totalAllocated != amount) {
          final adjustmentFactor = amount / totalAllocated;
          for (var uid in activeParticipants) {
            exactSplits[uid] = (exactSplits[uid]! * adjustmentFactor);
          }
        } else if (totalAllocated == 0) {
          // If no amounts were specified, default to equal split
          final equalShare = amount / activeParticipants.length;
          for (var uid in activeParticipants) {
            exactSplits[uid] = equalShare;
          }
        }

        return exactSplits;

      case 'Percentage':
        // Calculate the sum of all percentages
        double totalPercentage = 0;
        final Map<String, double> percentageSplits = {};

        // First pass: get all specified percentages
        for (var uid in activeParticipants) {
          final percentage = _percentageSplits[uid] ?? 0;
          percentageSplits[uid] = percentage;
          totalPercentage += percentage;
        }

        // If the total percentage doesn't add up to 100%, adjust proportionally
        if (totalPercentage != 0 && totalPercentage != 100) {
          final adjustmentFactor = 100 / totalPercentage;
          for (var uid in activeParticipants) {
            percentageSplits[uid] = percentageSplits[uid]! * adjustmentFactor;
          }
          totalPercentage = 100; // Now it should be exactly 100%
        } else if (totalPercentage == 0) {
          // If no percentages were specified, default to equal percentages
          final equalPercentage = 100 / activeParticipants.length;
          for (var uid in activeParticipants) {
            percentageSplits[uid] = equalPercentage;
          }
        }

        // Convert percentages to actual amounts
        return Map.fromEntries(
          activeParticipants.map(
            (uid) => MapEntry(
              uid,
              (percentageSplits[uid]! * amount / 100),
            ),
          ),
        );

      case 'Shares':
        final totalShares = activeParticipants.fold<int>(
          0,
          (sum, uid) => sum + (_shareSplits[uid] ?? 1),
        );

        // If no shares were specified, default to 1 share each
        if (totalShares == 0) {
          final equalShare = amount / activeParticipants.length;
          return Map.fromEntries(
            activeParticipants.map((uid) => MapEntry(uid, equalShare)),
          );
        }

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

      // Validate that we have active participants
      final activeParticipants = _participants.entries
          .where((entry) => entry.value)
          .map((entry) => entry.key)
          .toList();

      if (activeParticipants.isEmpty) {
        if (mounted) {
          StatusSnackbar.showError(
            context,
            message: 'No participants selected',
            details: 'Please select at least one participant.',
          );
        }
        return;
      }

      // Validate the amount
      final amount = double.tryParse(_amountController.text) ?? 0;
      if (amount <= 0) {
        if (mounted) {
          StatusSnackbar.showError(
            context,
            message: 'Invalid amount',
            details: 'Please enter a valid amount greater than zero.',
          );
        }
        return;
      }

      // Validate split details for non-equal splits
      if (_splitMethod != 'Equal') {
        bool isValid = true;
        String errorMessage = '';

        switch (_splitMethod) {
          case 'Exact':
            final totalAllocated = activeParticipants.fold<double>(
              0,
              (sum, uid) => sum + (_customSplitAmounts[uid] ?? 0),
            );
            if (totalAllocated == 0) {
              isValid = false;
              errorMessage =
                  'Please specify at least one amount for the exact split.';
            }
            break;

          case 'Percentage':
            final totalPercentage = activeParticipants.fold<double>(
              0,
              (sum, uid) => sum + (_percentageSplits[uid] ?? 0),
            );
            if (totalPercentage == 0) {
              isValid = false;
              errorMessage =
                  'Please specify at least one percentage for the percentage split.';
            }
            break;

          case 'Shares':
            final totalShares = activeParticipants.fold<int>(
              0,
              (sum, uid) => sum + (_shareSplits[uid] ?? 1),
            );
            if (totalShares == 0) {
              isValid = false;
              errorMessage =
                  'Please specify at least one share for the shares split.';
            }
            break;
        }

        if (!isValid) {
          if (mounted) {
            StatusSnackbar.showError(
              context,
              message: 'Invalid split details',
              details: errorMessage,
            );
          }
          return;
        }
      }

      // Prepare the expense data
      // final authService = Provider.of<AuthService>(context, listen: false);
      final settingsService =
          Provider.of<SettingsService>(context, listen: false);
      final splitDetails = _calculateSplitDetails();

      // Double-check that the split details sum up to the total amount
      final totalSplit =
          splitDetails.values.fold<double>(0, (sum, value) => sum + value);
      final adjustedSplitDetails = Map<String, double>.from(splitDetails);

      // If there's a small rounding error, adjust the first participant's amount
      if (totalSplit != amount && splitDetails.isNotEmpty) {
        final firstParticipant = splitDetails.keys.first;
        final difference = amount - totalSplit;
        adjustedSplitDetails[firstParticipant] =
            (splitDetails[firstParticipant] ?? 0) + difference;
      }

      final expense = Expense(
        id: '',
        groupId: widget.group.id,
        payerId: _selectedPayerId!,
        amount: amount,
        currency: settingsService.currency,
        description: _descriptionController.text,
        date: DateTime.now(),
        splitDetails: adjustedSplitDetails,
        category: _category,
        comment: _commentController.text,
        splitMethod: _splitMethod,
        receiptUrl: _receiptImageUrl,
      );

      // Show confirmation bottom sheet
      setState(() => _isSubmitting = true);

      await ExpenseConfirmationBottomSheet.show(
        context: context,
        expense: expense,
        group: widget.group,
        expenseService: _expenseService,
        userService: _userService,
        settingsService: settingsService,
        onSuccess: () {
          if (mounted) {
            Navigator.pop(context);
          }
        },
      );

      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
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

  List<String> _getAllMemberIdentifiers() {
    return [...widget.group.memberIds, ...widget.group.invitedEmails];
  }
}
