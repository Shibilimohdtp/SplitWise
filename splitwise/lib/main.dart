import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/models/user.dart';
import 'package:splitwise/services/auth_service.dart';
import 'package:splitwise/services/settings_service.dart';
import 'package:splitwise/services/expense_service.dart';
import 'package:splitwise/services/user_service.dart';
import 'package:splitwise/features/authentication/login_screen.dart';
import 'package:splitwise/features/group_management/home_screen.dart';
import 'package:splitwise/constants/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'package:splitwise/features/group_management/group_detail_screen.dart';
import 'package:splitwise/services/group_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final settingsService = SettingsService();
  await settingsService.init();

  runApp(
    ChangeNotifierProvider.value(
      value: settingsService,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        Provider<UserService>(create: (_) => UserService()),
        Provider<GroupService>(create: (_) => GroupService()),
        ProxyProvider<SettingsService, ExpenseService>(
          update: (_, settings, __) => ExpenseService(settings),
        ),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settings, _) {
          return MaterialApp.router(
            routerConfig: _router,
            debugShowCheckedModeBanner: false,
            title: 'Expense Tracker',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          );
        },
      ),
    );
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const AuthWrapper(),
    ),
    GoRoute(
      path: '/group/:id',
      builder: (context, state) {
        final groupId = state.pathParameters['id']!;
        return FutureBuilder(
          future: Provider.of<GroupService>(context, listen: false)
              .getGroup(groupId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            if (snapshot.hasError || !snapshot.hasData) {
              return const Scaffold(
                  body: Center(child: Text('Group not found')));
            }
            final group = snapshot.data!;
            return GroupDetailScreen(group: group);
          },
        );
      },
    ),
  ],
);

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    return StreamBuilder<User?>(
      stream: authService.user,
      builder: (_, AsyncSnapshot<User?> snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          final User? user = snapshot.data;
          return user == null ? const LoginScreen() : const HomeScreen();
        }
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
