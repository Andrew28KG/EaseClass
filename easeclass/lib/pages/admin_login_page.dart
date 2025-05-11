import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({Key? key}) : super(key: key);

  @override
  _AdminLoginPageState createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _isRegistering = false;

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (_isRegistering) {
          // Register new admin
          if (_passwordController.text != _confirmPasswordController.text) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Passwords do not match')),
            );
            return;
          }

          final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

          // Add admin data to Firestore
          await FirebaseFirestore.instance.collection('users').doc(userCredential.user!.uid).set({
            'email': _emailController.text.trim(),
            'role': 'admin',
            'createdAt': FieldValue.serverTimestamp(),
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin registration successful! Please login.')),
          );
          setState(() {
            _isRegistering = false;
          });
        } else {
          // Login existing admin
          final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

          // Verify admin role
          final userDoc = await FirebaseFirestore.instance
              .collection('users')
              .doc(userCredential.user!.uid)
              .get();

          if (userDoc.exists) {
            final role = userDoc.data()?['role'];
            if (role == 'admin') {
              Navigator.pushReplacementNamed(context, '/admin-dashboard');
            } else {
              await FirebaseAuth.instance.signOut();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('This is not an admin account. Please use the user login.')),
              );
            }
          } else {
            await FirebaseAuth.instance.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('User data not found. Please register first.')),
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        String message = 'An error occurred';
        if (e.code == 'user-not-found') {
          message = 'No admin found with this email';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password provided';
        } else if (e.code == 'email-already-in-use') {
          message = 'Email is already registered';
        } else if (e.code == 'weak-password') {
          message = 'Password is too weak';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message)),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isRegistering ? 'Admin Registration' : 'Admin Login'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Admin Email',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                if (_isRegistering) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm Password',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please confirm your password';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : Text(_isRegistering ? 'Register as Admin' : 'Login as Admin'),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isRegistering = !_isRegistering;
                      _emailController.clear();
                      _passwordController.clear();
                      _confirmPasswordController.clear();
                    });
                  },
                  child: Text(_isRegistering
                      ? 'Already have an admin account? Login here'
                      : 'Need to register as admin? Click here'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/user-login');
                  },
                  child: const Text('Are you a user? Login here'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
} 