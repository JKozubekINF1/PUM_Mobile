import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
import 'package:pum_project/services/api_connection.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

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

  void _checkCredentials() {
    _setProcessing(true);
    _setValidCredentials(true);
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      _displaySnackbar(AppLocalizations.of(context)!.emptyFieldMessage);
      _setValidCredentials(false);
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
      _displaySnackbar(AppLocalizations.of(context)!.loginSuccessfulMessage);
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
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
    } else{
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
      appBar: AppBar(
      ),
      body: Column(
        children: [
          Flexible(
            flex: 1,
            child: _buildPageTitle(),
          ),
          Flexible(
            flex: 2,
            child: _buildLoginColumn(),
          ),
          Flexible(
            flex: 1,
            child: _buildSubmitColumn(),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginColumn() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Flexible(
          flex: 1,
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: _buildEmailField(),
          ),
        ),
        Flexible(
          flex: 1,
          child: const SizedBox(
            width: double.infinity,
            height: 10,
          ),
        ),
        Flexible(
          flex: 1,
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: _buildPasswordField(),
          ),
        ),
        Flexible(
          flex: 1,
          child: const SizedBox(
            width: double.infinity,
            height: 10,
          ),
        ),
        Flexible(
          flex: 1,
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: _buildForgotPasswordText(),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitColumn() {
    return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Flexible(
            flex: 1,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: _buildLoginButton(),
            ),
          ),
          Flexible(
            flex: 1,
            child: const SizedBox(
              width: double.infinity,
              height: 10,
            ),
          ),
          Flexible(
            flex: 1,
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: _buildRegisterText(),
            ),
          ),
        ],
    );
  }

  Widget _buildPageTitle() {
    return Align(
      alignment: Alignment.center,
      child: Text(
        AppLocalizations.of(context)!.loginPageTitle,
        style: Theme.of(context).textTheme.bodyLarge,
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
      style: Theme.of(context).textTheme.bodyMedium,
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
      style: Theme.of(context).textTheme.bodyMedium,
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
          AppLocalizations.of(context)!.registerDuringLoginLabel,
          style: Theme.of(context).textTheme.bodyMedium,
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
          AppLocalizations.of(context)!.forgotPasswordLabel,
          style: Theme.of(context).textTheme.bodyMedium,
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
        child: _processing
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(AppLocalizations.of(context)!.loginButtonLabel)
      ),
    );
  }
}