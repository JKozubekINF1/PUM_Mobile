import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';
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
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty || _usernameController.text.trim().isEmpty) {
    _displaySnackbar(AppLocalizations.of(context)!.emptyFieldMessage);
    _setValidCredentials(false);
    }
    else if (_passwordController.text != _confirmPasswordController.text) {
      _displaySnackbar(AppLocalizations.of(context)!.failedToRepeatPasswordMessage);
      _setValidCredentials(false);
    }
    else if (!RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
        .hasMatch(_emailController.text.trim())) {
    _displaySnackbar(AppLocalizations.of(context)!.incorrectEmailMessage);
    _setValidCredentials(false);
    }
    else if (!RegExp(r"^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[^A-Za-z0-9]).{6,20}$")
        .hasMatch(_passwordController.text.trim())) {
      _displaySnackbar(AppLocalizations.of(context)!.incorrectPasswordMessage);
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
            child: _buildRegisterColumn(),
          ),
          Flexible(
            flex: 1,
            child: _buildSubmitColumn(),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisterColumn() {
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
            child: _buildConfirmPasswordField(),
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
            child: _buildUsernameField(),
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
            child: _buildRegisterButton(),
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
            child: _buildLoginText(),
          ),
        ),
      ],
    );
  }

  Widget _buildPageTitle() {
    return Align(
      alignment: Alignment.center,
      child: Text(
        AppLocalizations.of(context)!.registerPageTitle, style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.emailLabel,
        border: OutlineInputBorder(),
      ), style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildUsernameField() {
    return TextField(
      controller: _usernameController,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.usernameLabel,
        border: OutlineInputBorder(),
      ), style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword1,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.passwordLabel,
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword1 ? Icons.visibility : Icons.visibility_off, color: Theme.of(context).iconTheme.color),
          onPressed: () {
            setState(() {
              _obscurePassword1 = !_obscurePassword1;
            });
          },
        ),
        border: OutlineInputBorder(),
      ), style: Theme.of(context).textTheme.bodyMedium,
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextField(
      controller: _confirmPasswordController,
      obscureText: _obscurePassword2,
      decoration: InputDecoration(
        labelText: AppLocalizations.of(context)!.confirmPasswordLabel,
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword2 ? Icons.visibility : Icons.visibility_off, color: Theme.of(context).iconTheme.color),
          onPressed: () {
            setState(() {
              _obscurePassword2 = !_obscurePassword2;
            });
          },
        ),
        border: OutlineInputBorder(),
      ), style: Theme.of(context).textTheme.bodyMedium,
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
          AppLocalizations.of(context)!.loginDuringRegisterLabel, style: Theme.of(context).textTheme.bodyMedium,
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
        child: Text(AppLocalizations.of(context)!.registerButtonLabel)
      ),
    );
  }
}