import 'package:flutter/material.dart';
import '../l10n/generated/app_localizations.dart';

class ResetPage extends StatefulWidget {
  const ResetPage({
    super.key,
  });
  @override
  State<ResetPage> createState() => _ResetPageState();
}

class _ResetPageState extends State<ResetPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            Flexible(
              flex: 1,
              child: _buildPageTitle(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPageTitle() {
    return Align(
      alignment: Alignment.center,
      child: Text(
        AppLocalizations.of(context)!.resetPasswordPageTitle,
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    );
  }
}