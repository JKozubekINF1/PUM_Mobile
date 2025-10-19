import 'package:flutter/material.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:pum_project/services/api_connection.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({
    super.key,
  });
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscurePassword1 = true;
  bool _obscurePassword2 = true;
  String _message = '';

  void _setMessage(String message) {
    if (mounted) {
      setState(() {
        _message = message;
      });
    }
  }

  Future<void> _register() async {
    _setMessage('');
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.register(
        _emailController.text.trim(),
        _passwordController.text,
        _confirmPasswordController.text,
      );
      _setMessage(AppLocalizations.of(context)!.registerSuccessfulMessage);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
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
            Text(AppLocalizations.of(context)!.registerPageTitle), const SizedBox(height: 30),
            _buildEmailField(), const SizedBox(height: 16),
            _buildPasswordField(), const SizedBox(height: 16),
            _buildConfirmPasswordField(), const SizedBox(height: 16),
            _buildRegisterButton(), const SizedBox(height: 20),
            _buildLoginText(), const SizedBox(height: 24),
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
      obscureText: _obscurePassword1,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.passwordLabel,
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword1 ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscurePassword1 = !_obscurePassword1;
            });
          },
        ),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextField(
      controller: _confirmPasswordController,
      obscureText: _obscurePassword2,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.confirmPasswordLabel,
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword2 ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscurePassword2 = !_obscurePassword2;
            });
          },
        ),
        border: OutlineInputBorder(),
      ),
    );
  }

  Widget _buildLoginText() {
    return Align(
      alignment: Alignment.center,
      child: TextButton(
        onPressed: () {
          Navigator.pushNamed(context, '/login');
        },
        child: Text(
          AppLocalizations.of(context)!.loginDuringRegisterLabel, style: TextStyle(color: Color(0xFF375534)),
        ),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (){
          _register();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF375534),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(AppLocalizations.of(context)!.registerButtonLabel)
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