import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../widgets/login_widget.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({Key? key}) : super(key: key);

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }  Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );      
      // Check if user is admin (you may want to check a Firestore field in production)
      if (_emailController.text.trim().toLowerCase().contains('admin')) {
        if (mounted) {
          // Clear the entire navigation stack and replace with admin dashboard
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/admin-dashboard', 
            (route) => false
          );
        }
      } else {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _errorMessage = 'Not an admin account.';
          _isLoading = false;
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = e.message ?? 'An error occurred during sign in';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'An unexpected error occurred';
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    return LoginWidget(
      title: 'Admin Login',
      emailController: _emailController,
      passwordController: _passwordController,
      isLoading: _isLoading,
      errorMessage: _errorMessage,
      onSignIn: _signIn,
      primaryColor: AppColors.secondary,
      secondaryColor: AppColors.secondaryLight,
      emailLabel: 'Admin Email',
    );
  }
}
