import 'package:flutter/material.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:pum_project/services/api_connection.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({
    super.key,
  });
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String _message = '';

  void _setMessage(String message) {
    if (mounted) {
      setState(() {
        _message = message;
      });
    }
  }

  Future<void> _login() async {
    _setMessage('');
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      _setMessage(AppLocalizations.of(context)!.loginSuccessfulMessage);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    } catch (e) {
      debugPrint('$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(AppLocalizations.of(context)!.loginPageTitle), const SizedBox(height: 30),
            _buildEmailField(), const SizedBox(height: 16),
            _buildPasswordField(), const SizedBox(height: 16),
            _buildForgotPasswordText(), const SizedBox(height: 24),
            _buildLoginButton(), const SizedBox(height: 20),
            _buildRegisterText(), const SizedBox(height: 24),
            _buildMessageText(), const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.emailLabel,
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.passwordLabel,
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildRegisterText() {
    return Align(
      alignment: Alignment.center,
      child: TextButton(
        onPressed: () {
          Navigator.pushNamed(context, '/register');
        },
        child: Text(
          AppLocalizations.of(context)!.registerDuringLoginLabel, style: TextStyle(color: Color(0xFF375534)),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordText() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.pushNamed(context, '/resetpassword');
        },
        child: Text(
          AppLocalizations.of(context)!.forgotPasswordLabel, style: TextStyle(color: Color(0xFF375534)),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (){
          _login();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF375534),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(AppLocalizations.of(context)!.loginButtonLabel)
      ),
    );
  }

  Widget _buildMessageText() {
    if (_message.isEmpty) {
      return const SizedBox.shrink();
    }
    return Text(
      _message,
      textAlign: TextAlign.center,
    );
  }
}