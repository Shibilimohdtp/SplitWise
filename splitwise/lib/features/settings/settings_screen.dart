import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/utils/app_color.dart';
import 'package:splitwise/widgets/custom_switch.dart';

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settingsService = Provider.of<SettingsService>(context);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Settings',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryMain, AppColors.primaryLight],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.settings,
                    size: 80,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preferences',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildCurrencyCard(context, settingsService),
                  SizedBox(height: 16),
                  _buildThemeCard(context, settingsService),
                  SizedBox(height: 32),
                  Text(
                    'About',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textMain,
                    ),
                  ),
                  SizedBox(height: 16),
                  _buildAboutCard(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyCard(
      BuildContext context, SettingsService settingsService) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Currency',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain),
            ),
            SizedBox(height: 8),
            Text(
              'Select your preferred currency',
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: settingsService.currency,
              decoration: InputDecoration(
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              items: ['INR', 'USD', 'EUR', 'GBP', 'JPY'].map((String currency) {
                return DropdownMenuItem<String>(
                  value: currency,
                  child: Text(currency),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  settingsService.setCurrency(newValue);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard(
      BuildContext context, SettingsService settingsService) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain),
            ),
            SizedBox(height: 8),
            Text(
              'Choose between light and dark mode',
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Dark Mode',
                  style: TextStyle(fontSize: 16, color: AppColors.textMain),
                ),
                CustomSwitch(
                  value: settingsService.isDarkMode,
                  onChanged: (bool value) {
                    settingsService.setDarkMode(value);
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Information',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMain),
            ),
            SizedBox(height: 16),
            _buildInfoRow('Version', '1.0.0'),
            _buildInfoRow('Developer', 'Splitwise'),
            _buildInfoRow('Contact', 'support@splitwise.com'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement privacy policy action
              },
              child: Text('Privacy Policy'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentMain,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(fontSize: 14, color: AppColors.textLight)),
          Text(value,
              style: TextStyle(fontSize: 14, color: AppColors.textMain)),
        ],
      ),
    );
  }
}
