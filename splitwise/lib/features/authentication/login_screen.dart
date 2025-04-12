import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splitwise/services/auth_service.dart';
import 'package:splitwise/features/authentication/signup_screen.dart';
import 'package:splitwise/features/authentication/forgot_password_screen.dart';
import 'package:splitwise/utils/app_color.dart';
import 'package:splitwise/widgets/custom_text_field.dart';
import 'package:splitwise/widgets/custom_button.dart';
import 'package:splitwise/models/user.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _isLoading = false;

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() => _isLoading = true);
      try {
        User? user = await Provider.of<AuthService>(context, listen: false)
            .signIn(_email, _password);
        if (user != null) {
          // Navigate to the main screen or handle successful login
          Navigator.pushReplacementNamed(context, '/home');
        } else {
          throw Exception('Failed to sign in');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Failed to sign in. Please try again.')),
          );
        }
      }
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Welcome Back!',
                  style: Theme.of(context).textTheme.headlineMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                CustomTextField(
                  labelText: 'Email',
                  onSaved: (value) => _email = value!,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your email' : null,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'Password',
                  obscureText: true,
                  onSaved: (value) => _password = value!,
                  validator: (value) =>
                      value!.isEmpty ? 'Please enter your password' : null,
                ),
                const SizedBox(height: 24),
                CustomButton(
                  onPressed: _isLoading ? null : _submit,
                  color: AppColors.accentMain,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Log In'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SignUpScreen()),
                  ),
                  child: const Text(
                    'Don\'t have an account? Sign Up',
                    style: TextStyle(color: AppColors.textMain),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ForgotPasswordScreen()),
                  ),
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(color: AppColors.textMain),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
