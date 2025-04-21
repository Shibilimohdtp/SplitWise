import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/models/group.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/features/expense_tracking/models/expense_analysis_models.dart';
import 'package:splitwise/widgets/expence_analysis_components/overview_tab.dart';
import 'package:splitwise/widgets/expence_analysis_components/balances_tab.dart';
import 'package:splitwise/widgets/expence_analysis_components/settlements_tab.dart';

class ExpenseAnalysisScreen extends StatefulWidget {
  final Group group;
  const ExpenseAnalysisScreen({super.key, required this.group});

  @override
  ExpenseAnalysisScreenState createState() => ExpenseAnalysisScreenState();
}

class ExpenseAnalysisScreenState extends State<ExpenseAnalysisScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // --- Cached Services ---
  late SettingsService _settingsService;
  late ExpenseService _expenseService;
  late UserService _userService;

  // --- Lifecycle ---
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Cache services in initState for easier access
    _settingsService = Provider.of<SettingsService>(context, listen: false);
    _expenseService = Provider.of<ExpenseService>(context, listen: false);
    _userService = Provider.of<UserService>(context, listen: false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Build Method ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Common Styles
    final outlineColor = colorScheme.outline.withValues(alpha: 0.1);
    final outlineBorderSide = BorderSide(color: outlineColor, width: 1);
    final cardBorderRadius = BorderRadius.circular(kRadius);
    final iconButtonStyle = IconButton.styleFrom(
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      backgroundColor: colorScheme.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 2,
        backgroundColor: colorScheme.surface,
        centerTitle: false,
        title: Text('Expense Analysis',
            style: textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.2)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, size: 20, color: colorScheme.primary),
          onPressed: () => Navigator.pop(context),
          style: iconButtonStyle,
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: Icon(Icons.info_outline,
                  size: 20, color: colorScheme.primary),
              onPressed: () => _showInfoDialog(context, colorScheme, textTheme),
              style: iconButtonStyle,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin:
                const EdgeInsets.symmetric(horizontal: kPadding, vertical: 8),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .outline
                    .withValues(alpha: 0.3),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: colorScheme.primary,
              indicatorWeight: 0, // Hidden by BoxDecoration indicator
              labelColor: colorScheme.onPrimary,
              unselectedLabelColor: colorScheme.onSurfaceVariant,
              labelStyle: textTheme.labelMedium
                  ?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0.5),
              unselectedLabelStyle:
                  textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
              indicator: BoxDecoration(
                color: colorScheme.primary,
                borderRadius: BorderRadius.circular(8),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              labelPadding: const EdgeInsets.symmetric(horizontal: 8),
              splashBorderRadius: BorderRadius.circular(8),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Balances'),
                Tab(text: 'Settlements'),
              ],
            ),
          ),
        ),
      ),
      body: AnimatedSwitcher(
        duration: kAnimDuration,
        child: TabBarView(
          controller: _tabController,
          physics: const BouncingScrollPhysics(),
          children: [
            // Overview Tab
            OverviewTab(
              group: widget.group,
              expenseService: _expenseService,
              settingsService: _settingsService,
              userService: _userService,
              outlineBorderSide: outlineBorderSide,
              cardBorderRadius: cardBorderRadius,
            ),

            // Balances Tab
            BalancesTab(
              group: widget.group,
              expenseService: _expenseService,
              settingsService: _settingsService,
              userService: _userService,
              outlineBorderSide: outlineBorderSide,
              cardBorderRadius: cardBorderRadius,
            ),

            // Settlements Tab
            SettlementsTab(
              group: widget.group,
              expenseService: _expenseService,
              settingsService: _settingsService,
              userService: _userService,
              outlineBorderSide: outlineBorderSide,
              onSettlementCompleted: () => setState(() {}),
            ),
          ],
        ),
      ),
    );
  }

  // --- Dialogs ---
  void _showInfoDialog(
      BuildContext context, ColorScheme colorScheme, TextTheme textTheme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(children: [
            Icon(Icons.info_outline, color: colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Text('About Expense Analysis',
                style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600, letterSpacing: 0.2)),
          ]),
          content: SingleChildScrollView(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoSection(
                      context,
                      colorScheme,
                      textTheme,
                      'Overview',
                      'Total expenses, monthly trends, and member expense distribution.',
                      Icons.dashboard_outlined),
                  const SizedBox(height: kPadding),
                  _buildInfoSection(
                      context,
                      colorScheme,
                      textTheme,
                      'Balances',
                      'How much each member owes or is owed.',
                      Icons.account_balance_wallet_outlined),
                  const SizedBox(height: kPadding),
                  _buildInfoSection(
                      context,
                      colorScheme,
                      textTheme,
                      'Settlements',
                      'Suggested optimal payments to settle debts.',
                      Icons.swap_horiz_rounded),
                ]),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
              child: const Text('Close'),
            ),
          ],
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kRadius)),
          backgroundColor: colorScheme.surface,
        );
      },
    );
  }

  Widget _buildInfoSection(BuildContext context, ColorScheme colorScheme,
      TextTheme textTheme, String title, String description, IconData icon) {
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: colorScheme.primary, size: 16),
      ),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        Text(description,
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant)),
      ])),
    ]);
  }
}
