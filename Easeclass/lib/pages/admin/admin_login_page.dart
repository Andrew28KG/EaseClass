import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../theme/app_colors.dart';
import '../../widgets/login_widget.dart';
import '../../services/auth_service.dart';
import 'package:provider/provider.dart';

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
  }
    Future<void> _signIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      
      if (!mounted) return;
      
      // Simply navigate to admin dashboard for any successful login
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/admin-dashboard', 
        (route) => false
      );
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
      primaryColor: AdminColors.adminPrimary,
      secondaryColor: AdminColors.adminPrimaryLight,
      emailLabel: 'Admin Email',
    );
  }
}
