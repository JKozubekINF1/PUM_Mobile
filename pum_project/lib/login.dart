import 'package:flutter/material.dart';
import 'l10n/generated/app_localizations.dart';
import 'package:pum_project/services/api_connection.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';

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
  bool _processing = false;
  bool _obscurePassword = true;
  bool _validCredentials = false;
  String _message = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _setProcessing(bool processing) {
    if (mounted) {
      setState(() {
        _processing = processing;
      });
    }
  }

  void _setValidCredentials(bool valid) {
    if (mounted) {
      setState(() {
        _validCredentials = valid;
      });
    }
  }

  void _setMessage(String message) {
    if (mounted) {
      setState(() {
        _message = message;
      });
    }
  }

  void _checkCredentials() {
    _setMessage('');
    _setProcessing(true);
    _setValidCredentials(true);
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _setMessage(AppLocalizations.of(context)!.emptyFieldMessage);
      _setValidCredentials(false);
    }
    if (_validCredentials) {
      _login();
    } else {
      _setProcessing(false);
    }
  }

  Future<void> _login() async {
    _setMessage('');
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false); // Pobieramy AuthProvider

      final responseData = await apiService.login( // Logowanie w ApiService
        _emailController.text.trim(),
        _passwordController.text,
      );

      final token = responseData['token'];
      if (token != null) {
        await authProvider.saveToken(token); // To wywoła notifyListeners
      }

      _setMessage(AppLocalizations.of(context)!.loginSuccessfulMessage);

      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }
    } catch (e) {
      _setMessage(_formatError(e.toString()));
      debugPrint('$e');
      _setProcessing(false);
    }
  }

  String _formatError(String raw) {
    final msg = raw.replaceFirst('Exception: ', '').toLowerCase();
    if (msg.contains('network') || msg.contains('timeout') || msg.contains('server error')) {
      return AppLocalizations.of(context)!.noConnectionMessage;
    } else if (msg.contains('credentials')) {
      return AppLocalizations.of(context)!.badLoginMessage;
    } else{
      return AppLocalizations.of(context)!.genericErrorMessage;
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
        border: const OutlineInputBorder(),
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
        border: const OutlineInputBorder(),
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
          AppLocalizations.of(context)!.registerDuringLoginLabel, style: const TextStyle(color: Color(0xFF375534)),
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
          AppLocalizations.of(context)!.forgotPasswordLabel, style: const TextStyle(color: Color(0xFF375534)),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
          onPressed: (){
            _processing ? null : _checkCredentials();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF375534),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: _processing
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(AppLocalizations.of(context)!.loginButtonLabel)
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