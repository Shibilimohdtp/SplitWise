import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/models/expense.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/auth_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/widgets/custom_text_field.dart';
import 'package:splitwise/widgets/custom_button.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class AddExpenseScreen extends StatefulWidget {
  final Group group;

  AddExpenseScreen({required this.group});

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late ExpenseService _expenseService;
  late UserService _userService;

  String _description = '';
  double _amount = 0;
  String _splitMethod = 'Equal';
  Map<String, bool> _participants = {};
  Map<String, double> _customSplitAmounts = {};
  Map<String, double> _percentageSplits = {};
  Map<String, int> _shareSplits = {};
  String _category = 'Uncategorized';
  File? _receiptImage;
  String _comment = '';

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
    widget.group.members.forEach((memberId) {
      _participants[memberId] = true;
      _customSplitAmounts[memberId] = 0;
      _percentageSplits[memberId] = 0;
      _shareSplits[memberId] = 1;
    });
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      final authService = Provider.of<AuthService>(context, listen: false);
      final settingsService =
          Provider.of<SettingsService>(context, listen: false);

      final splitDetails = _calculateSplitDetails();

      final expense = Expense(
        id: '',
        groupId: widget.group.id,
        payerId: authService.currentUser!.uid,
        amount: _amount,
        currency: settingsService.currency,
        description: _description,
        date: DateTime.now(),
        splitDetails: splitDetails,
        category: _category,
        comment: _comment,
        splitMethod: _splitMethod,
      );

      try {
        await _expenseService.addExpense(expense, receiptImage: _receiptImage);
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add expense. Please try again.')),
        );
      }
    }
  }

  Map<String, double> _calculateSplitDetails() {
    final activeParticipants = _participants.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    switch (_splitMethod) {
      case 'Equal':
        final splitAmount = _amount / activeParticipants.length;
        return Map.fromEntries(
            activeParticipants.map((uid) => MapEntry(uid, splitAmount)));
      case 'Exact':
        return Map.fromEntries(activeParticipants
            .map((uid) => MapEntry(uid, _customSplitAmounts[uid] ?? 0)));
      case 'Percentage':
        return Map.fromEntries(activeParticipants.map((uid) =>
            MapEntry(uid, (_percentageSplits[uid] ?? 0) * _amount / 100)));
      case 'Shares':
        final totalShares = activeParticipants.fold<int>(
            0, (sum, uid) => sum + (_shareSplits[uid] ?? 0));
        final valuePerShare = _amount / totalShares;
        return Map.fromEntries(activeParticipants.map(
            (uid) => MapEntry(uid, (_shareSplits[uid] ?? 0) * valuePerShare)));
      default:
        return {};
    }
  }

  Widget _buildSplitInputs() {
    switch (_splitMethod) {
      case 'Exact':
        return _buildExactSplitInputs();
      case 'Percentage':
        return _buildPercentageSplitInputs();
      case 'Shares':
        return _buildShareSplitInputs();
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildExactSplitInputs() {
    return Column(
      children: widget.group.members.map((memberId) {
        if (_participants[memberId] ?? false) {
          return FutureBuilder<String>(
            future: _userService.getUserName(memberId),
            builder: (context, snapshot) {
              final userName = snapshot.data ?? 'Loading...';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(child: Text(userName)),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _customSplitAmounts[memberId] =
                                double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
        return SizedBox.shrink();
      }).toList(),
    );
  }

  Widget _buildPercentageSplitInputs() {
    return Column(
      children: widget.group.members.map((memberId) {
        if (_participants[memberId] ?? false) {
          return FutureBuilder<String>(
            future: _userService.getUserName(memberId),
            builder: (context, snapshot) {
              final userName = snapshot.data ?? 'Loading...';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(child: Text(userName)),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Percentage',
                          border: OutlineInputBorder(),
                          suffixText: '%',
                        ),
                        onChanged: (value) {
                          setState(() {
                            _percentageSplits[memberId] =
                                double.tryParse(value) ?? 0;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
        return SizedBox.shrink();
      }).toList(),
    );
  }

  Widget _buildShareSplitInputs() {
    return Column(
      children: widget.group.members.map((memberId) {
        if (_participants[memberId] ?? false) {
          return FutureBuilder<String>(
            future: _userService.getUserName(memberId),
            builder: (context, snapshot) {
              final userName = snapshot.data ?? 'Loading...';
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(child: Text(userName)),
                    SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Shares',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _shareSplits[memberId] = int.tryParse(value) ?? 1;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        }
        return SizedBox.shrink();
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Add Expense')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            CustomTextField(
              labelText: 'Description',
              onSaved: (value) => _description = value!,
              validator: (value) =>
                  value!.isEmpty ? 'Please enter a description' : null,
            ),
            SizedBox(height: 16),
            CustomTextField(
              labelText: 'Amount (${settingsService.currency})',
              keyboardType: TextInputType.number,
              onSaved: (value) => _amount = double.parse(value!),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter an amount' : null,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _category,
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) => setState(() => _category = value!),
              decoration: InputDecoration(labelText: 'Category'),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _splitMethod,
              items: _splitMethods.map((method) {
                return DropdownMenuItem(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (value) => setState(() => _splitMethod = value!),
              decoration: InputDecoration(labelText: 'Split Method'),
            ),
            SizedBox(height: 16),
            Text('Participants:',
                style: Theme.of(context).textTheme.titleMedium),
            ...widget.group.members.map((memberId) {
              return FutureBuilder<String>(
                future: _userService.getUserName(memberId),
                builder: (context, snapshot) {
                  final userName = snapshot.data ?? 'Loading...';
                  return CheckboxListTile(
                    title: Text(userName),
                    value: _participants[memberId],
                    onChanged: (bool? value) {
                      setState(() {
                        _participants[memberId] = value!;
                      });
                    },
                  );
                },
              );
            }),
            if (_splitMethod != 'Equal') ...[
              SizedBox(height: 16),
              Text('Split Details:',
                  style: Theme.of(context).textTheme.titleMedium),
              _buildSplitInputs(),
            ],
            SizedBox(height: 16),
            CustomTextField(
              labelText: 'Comment (Optional)',
              maxLines: 3,
              onSaved: (value) => _comment = value!,
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.camera_alt),
              label: Text('Upload Receipt'),
              onPressed: () async {
                final ImagePicker _picker = ImagePicker();
                final XFile? image =
                    await _picker.pickImage(source: ImageSource.gallery);
                if (image != null) {
                  setState(() {
                    _receiptImage = File(image.path);
                  });
                }
              },
            ),
            if (_receiptImage != null) ...[
              SizedBox(height: 8),
              Text('Receipt image selected',
                  style: TextStyle(color: Colors.green)),
            ],
            SizedBox(height: 24),
            CustomButton(
              onPressed: _submit,
              child: Text('Add Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
