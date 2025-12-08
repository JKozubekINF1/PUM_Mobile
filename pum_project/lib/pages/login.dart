import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:pum_project/services/api_connection.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/profile_data.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _processing = false;
  bool _obscurePassword = true;
  bool _validCredentials = false;

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

  void _checkCredentials() {
    _setProcessing(true);
    _validCredentials = true;

    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _displaySnackbar(AppLocalizations.of(context)!.emptyFieldMessage);
      _validCredentials = false;
    }

    if (_validCredentials) {
      _login();
    } else {
      _setProcessing(false);
    }
  }

  Future<void> _login() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final responseData = await apiService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );
      final token = responseData['token'];
      if (token != null) {
        await authProvider.saveToken(token);
      }
      if (mounted) {
        _displaySnackbar(AppLocalizations.of(context)!.loginSuccessfulMessage);
        _checkIfProfileInitialized();
      }
    } catch (e) {
      _displaySnackbar(_formatError(e.toString()));
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
    } else {
      return AppLocalizations.of(context)!.genericErrorMessage;
    }
  }

  void _displaySnackbar(String message) {
    var snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  bool _profileInitializationRequirement(ProfileData profile) {
    return (profile.firstName != null);
  }

  Future<void> _checkIfProfileInitialized() async {
    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      final profile = await apiService.fetchProfile();
      final initialized = _profileInitializationRequirement(profile);

      if (initialized) {
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      } else {
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/profile/edit', (_) => false);
      }
    } catch (e) {
      debugPrint("$e");
    }
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
              const SizedBox(height: 40),
              _buildEmailField(),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 10),
              _buildForgotPasswordText(),
              const SizedBox(height: 30),
              _buildLoginButton(),
              const SizedBox(height: 20),
              _buildRegisterText(),
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
          Icons.login,
          size: 80,
          color: Theme.of(context).primaryColor,
        ),
        const SizedBox(height: 16),
        Text(
          AppLocalizations.of(context)!.loginPageTitle,
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

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.passwordLabel,
        prefixIcon: const Icon(Icons.lock),
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

  Widget _buildForgotPasswordText() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () {
          Navigator.pushNamed(context, '/resetpassword');
        },
        child: Text(AppLocalizations.of(context)!.forgotPasswordLabel),
      ),
    );
  }

  Widget _buildLoginButton() {
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
        AppLocalizations.of(context)!.loginButtonLabel,
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  Widget _buildRegisterText() {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, '/register');
      },
      child: Text(AppLocalizations.of(context)!.registerDuringLoginLabel),
    );
  }
}