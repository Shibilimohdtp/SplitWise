import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/models/expense.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/auth_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/widgets/custom_text_field.dart';
import 'package:splitwise/widgets/custom_button.dart';

class AddExpenseScreen extends StatefulWidget {
  final Group group;

  AddExpenseScreen({required this.group});

  @override
  _AddExpenseScreenState createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late ExpenseService _expenseService;

  String _description = '';
  double _amount = 0;
  String _splitMethod = 'Equal';
  Map<String, bool> _participants = {};

  @override
  void initState() {
    super.initState();
    final settingsService =
        Provider.of<SettingsService>(context, listen: false);
    _expenseService = ExpenseService(settingsService);
    widget.group.members.forEach((memberId) {
      _participants[memberId] = true;
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
        id: '', // This will be set by Firestore
        groupId: widget.group.id,
        payerId: authService.currentUser!.uid,
        amount: _amount,
        currency: settingsService.currency,
        description: _description,
        date: DateTime.now(),
        splitDetails: splitDetails,
      );

      try {
        await _expenseService.addExpense(expense);
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

    if (_splitMethod == 'Equal') {
      final splitAmount = _amount / activeParticipants.length;
      return Map.fromEntries(
          activeParticipants.map((uid) => MapEntry(uid, splitAmount)));
    } else {
      // Implement custom split logic here
      return {};
    }
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
              onSaved: (value) => _amount = double.parse(value!),
              validator: (value) =>
                  value!.isEmpty ? 'Please enter an amount' : null,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _splitMethod,
              items: ['Equal', 'Custom'].map((method) {
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
              return CheckboxListTile(
                title:
                    Text(memberId), // Ideally, show user's name instead of ID
                value: _participants[memberId],
                onChanged: (bool? value) {
                  setState(() {
                    _participants[memberId] = value!;
                  });
                },
              );
            }),
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
