import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/generated/app_localizations.dart';
import '../services/api_connection.dart';

class ResetPage extends StatefulWidget {
  const ResetPage({super.key});

  @override
  State<ResetPage> createState() => _ResetPageState();
}

class _ResetPageState extends State<ResetPage> {
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  bool _isTokenSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final loc = AppLocalizations.of(context)!;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.forgotPassword(_emailController.text.trim());

      if (mounted) {
        setState(() {
          _isTokenSent = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.codeSentSuccessMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.errorLabel}: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final loc = AppLocalizations.of(context)!;

    try {
      final apiService = Provider.of<ApiService>(context, listen: false);
      await apiService.resetPassword(
        _emailController.text.trim(),
        _tokenController.text.trim(),
        _passwordController.text,
        _confirmPasswordController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.passwordResetSuccessMessage)),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.errorLabel}: ${e.toString().replaceAll("Exception:", "")}')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.resetPasswordPageTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _buildPageTitle(loc),
              const SizedBox(height: 30),

              // EMAIL
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: loc.emailLabel,
                  prefixIcon: const Icon(Icons.email),
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_isTokenSent,
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return loc.invalidEmailError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              if (!_isTokenSent) ...[
                Text(
                  loc.enterEmailInstructionMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendCode,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(loc.sendCodeButton),
                ),
              ],

              if (_isTokenSent) ...[
                const Divider(height: 40),
                Text(
                  loc.codeSentInstructionMessage,
                  style: TextStyle(color: Theme.of(context).primaryColor, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _tokenController,
                  decoration: InputDecoration(
                    labelText: loc.tokenLabel,
                    prefixIcon: const Icon(Icons.vpn_key),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? loc.enterCodeError
                      : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: loc.newPasswordLabel,
                    prefixIcon: const Icon(Icons.lock),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) => value != null && value.length < 6
                      ? loc.passwordTooShortError
                      : null,
                ),
                const SizedBox(height: 20),

                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: loc.confirmPasswordLabel,
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value != _passwordController.text) {
                      return loc.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed: _isLoading ? null : _handleResetPassword,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : Text(loc.resetPasswordButton),
                ),

                TextButton(
                  onPressed: () => setState(() => _isTokenSent = false),
                  child: Text(loc.wrongEmailGoBackLabel),
                )
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPageTitle(AppLocalizations loc) {
    return Align(
      alignment: Alignment.center,
      child: Icon(
        Icons.lock_reset,
        size: 80,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}