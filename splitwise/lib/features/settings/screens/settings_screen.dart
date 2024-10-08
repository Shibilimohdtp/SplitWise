import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/services/settings_service.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);

    return Scaffold(
      appBar: AppBar(title: Text('Settings')),
      body: ListView(
        children: [
          ListTile(
            title: Text('Currency'),
            subtitle: Text(settingsService.currency),
            trailing: Icon(Icons.chevron_right),
            onTap: () => _showCurrencyPicker(context, settingsService),
          ),
          SwitchListTile(
            title: Text('Dark Mode'),
            value: settingsService.isDarkMode,
            onChanged: (value) => settingsService.setDarkMode(value),
          ),
        ],
      ),
    );
  }

  void _showCurrencyPicker(
      BuildContext context, SettingsService settingsService) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('Select Currency'),
          children: <Widget>[
            _buildCurrencyOption(context, settingsService, 'USD'),
            _buildCurrencyOption(context, settingsService, 'EUR'),
            _buildCurrencyOption(context, settingsService, 'GBP'),
            _buildCurrencyOption(context, settingsService, 'JPY'),
            // Add more currencies as needed
          ],
        );
      },
    );
  }

  Widget _buildCurrencyOption(
      BuildContext context, SettingsService settingsService, String currency) {
    return SimpleDialogOption(
      onPressed: () {
        settingsService.setCurrency(currency);
        Navigator.pop(context);
      },
      child: Text(currency),
    );
  }
}
