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
  bool _processing = false;
  bool _obscurePassword1 = true;
  bool _obscurePassword2 = true;
  bool _validCredentials = false;
  String _message = '';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
    if (_passwordController.text != _confirmPasswordController.text) {
      _setMessage(AppLocalizations.of(context)!.failedToRepeatPasswordMessage);
      _setValidCredentials(false);
    }
    if (!RegExp(r"^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[^A-Za-z0-9]).{6,20}$")
        .hasMatch(_passwordController.text.trim())) {
      _setMessage(AppLocalizations.of(context)!.incorrectPasswordMessage);
      _setValidCredentials(false);
    }
    if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(_emailController.text.trim())) {
      _setMessage(AppLocalizations.of(context)!.incorrectEmailMessage);
      _setValidCredentials(false);
    }
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _setMessage(AppLocalizations.of(context)!.emptyFieldMessage);
      _setValidCredentials(false);
    }
    if (_validCredentials) {
      _register();
    }
    _setProcessing(false);
  }

  Future<void> _register() async {
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
      _setMessage(_formatError(e.toString()));
      debugPrint('$e');
    } finally {
      _setProcessing(false);
    }
  }

  String _formatError(String raw) {
    final msg = raw.replaceFirst('Exception: ', '').toLowerCase();
    if (msg.contains('network') || msg.contains('timeout')) {
      return AppLocalizations.of(context)!.noConnectionMessage;
    } else if (msg.contains('not a subtype')) {
      return AppLocalizations.of(context)!.incorrectEmailMessage;
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