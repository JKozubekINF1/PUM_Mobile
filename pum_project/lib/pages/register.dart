import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:pum_project/services/api_connection.dart';
import 'package:provider/provider.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _processing = false;
  bool _obscurePassword1 = true;
  bool _obscurePassword2 = true;
  bool _validCredentials = false;

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _setProcessing(bool processing) {
    if (mounted) setState(() => _processing = processing);
  }

  void _checkCredentials() {
    _setProcessing(true);
    _validCredentials = true;

    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _usernameController.text.trim().isEmpty) {
      _displaySnackbar(AppLocalizations.of(context)!.emptyFieldMessage);
      _validCredentials = false;
    } else if (_passwordController.text != _confirmPasswordController.text) {
      _displaySnackbar(AppLocalizations.of(context)!.failedToRepeatPasswordMessage);
      _validCredentials = false;
    } else if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(_emailController.text.trim())) {
      _displaySnackbar(AppLocalizations.of(context)!.incorrectEmailMessage);
      _validCredentials = false;
    } else if (!RegExp(r"^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[^A-Za-z0-9]).{6,20}$")
        .hasMatch(_passwordController.text.trim())) {
      _displaySnackbar(AppLocalizations.of(context)!.incorrectPasswordMessage);
      _validCredentials = false;
    }

    if (_validCredentials) {
      _register();
    } else {
      _setProcessing(false);
    }
  }

  Future<void> _register() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.register(
        _emailController.text.trim(),
        _usernameController.text.trim(),
        _passwordController.text,
        _confirmPasswordController.text,
      );
      if (mounted) {
        _displaySnackbar(AppLocalizations.of(context)!.registerSuccessfulMessage);
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      _displaySnackbar(_formatError(e.toString()));
      debugPrint('$e');
    } finally {
      _setProcessing(false);
    }
  }

  String _formatError(String raw) {
    final msg = raw.replaceFirst('Exception: ', '').toLowerCase();
    if (msg.contains('email is already registered')) {
      return AppLocalizations.of(context)!.emailTakenMessage;
    } else if (msg.contains('username is already taken')) {
      return AppLocalizations.of(context)!.nicknameTakenMessage;
    } else if (msg.contains('network') || msg.contains('timeout')) {
      return AppLocalizations.of(context)!.noConnectionMessage;
    } else if (msg.contains('not a subtype')) {
      return AppLocalizations.of(context)!.incorrectEmailMessage;
    } else {
      return AppLocalizations.of(context)!.genericErrorMessage;
    }
  }

  void _displaySnackbar(String message) {
    var snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildPageHeader(),
              const SizedBox(height: 30),
              _buildEmailField(),
              const SizedBox(height: 20),
              _buildUsernameField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 20),
              _buildConfirmPasswordField(),
              const SizedBox(height: 40),
              _buildRegisterButton(),
              const SizedBox(height: 20),
              _buildLoginText(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader() {
    return Column(
      children: [
        Icon(
          Icons.person_add,
          size: 80,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.registerPageTitle,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.emailLabel,
        prefixIcon: const Icon(Icons.email),
        border: const OutlineInputBorder(),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildUsernameField() {
    return TextField(
      controller: _usernameController,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.usernameLabel,
        prefixIcon: const Icon(Icons.person),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword1,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.passwordLabel,
        prefixIcon: const Icon(Icons.lock),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword1 ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscurePassword1 = !_obscurePassword1;
            });
          },
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextField(
      controller: _confirmPasswordController,
      obscureText: _obscurePassword2,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.confirmPasswordLabel,
        prefixIcon: const Icon(Icons.lock_outline),
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword2 ? Icons.visibility : Icons.visibility_off),
          onPressed: () {
            setState(() {
              _obscurePassword2 = !_obscurePassword2;
            });
          },
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildRegisterButton() {
    return ElevatedButton(
      onPressed: _processing ? null : _checkCredentials,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        elevation: 2,
      ),
      child: _processing
          ? const SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
      )
          : Text(
        AppLocalizations.of(context)!.registerButtonLabel,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildLoginText() {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/login');
      },
      child: Text(AppLocalizations.of(context)!.loginDuringRegisterLabel),
    );
  }
}