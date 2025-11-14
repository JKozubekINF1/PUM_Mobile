import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../l10n/generated/app_localizations.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late PageController _pageViewController;

  @override
  void dispose() {
    super.dispose();
    _pageViewController.dispose();
  }

  @override
  void initState() {
    super.initState();
    _pageViewController = PageController();
  }

  void _changeToPage(int number) {
    _pageViewController.animateToPage(number, duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
  }

  void _logout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();
    if (mounted) {
      _displaySnackbar(AppLocalizations.of(context)!.logoutSuccessfulMessage);
      Navigator.pushNamedAndRemoveUntil(context, "/", (route) => false);
    }
  }

  void _displaySnackbar(String message) {
    var snackBar = SnackBar(content: Text(message));
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    if (authProvider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Title")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.homePageTitle),
        actions: [
          _buildProfileIcon(),
          _buildLogoutButton(),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: SizedBox(
                child: _buildMenu(),
              ),
            ),
            _buildNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileIcon() {
    return Flexible(
      child: ElevatedButton(
        child: Text(AppLocalizations.of(context)!.profileButtonLabel),
        onPressed: () {
          Navigator.pushNamed(context, '/profile');
        },
      ),
    );
  }

  Widget _buildLogoutButton() {
    return Flexible(
      child: ElevatedButton(
        child: Text(AppLocalizations.of(context)!.logoutButtonLabel),
        onPressed: () {
          _logout();
        },
      ),
    );
  }

  Widget _buildMenu() {
    return Column(
      children: <Widget>[
        Expanded(
          child: PageView(
            controller: _pageViewController,
            scrollDirection: Axis.horizontal,
            children: <Widget>[
              Column(
                children: [
                  _buildNewActivityPage(),
                ],
              ),
              Column(
                children: [
                  _buildActivityHistoryPage(),
                ],
              ),
              Column(
                children: [
                  _buildLeaderboardPage(),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNavigationBar() {
    return Row(
      children: <Widget>[
        Expanded(
          flex: 1,
          child: ColoredBox(
            color: Theme.of(context).appBarTheme.backgroundColor as Color,
            child: TextButton(
              onPressed: () {
                _changeToPage(0);
              },
              child: Text('ICON 1'),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: ColoredBox(
            color: Theme.of(context).appBarTheme.backgroundColor as Color,
            child: TextButton(
              onPressed: () {
                _changeToPage(1);
              },
              child: Text('ICON 2'),
            ),
          ),
        ),
        Expanded(
          flex: 1,
          child: ColoredBox(
            color: Theme.of(context).appBarTheme.backgroundColor as Color,
            child: TextButton(
              onPressed: () {
                _changeToPage(2);
              },
              child: Text('ICON 3'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewActivityPage() {
    return Expanded(
      child: SizedBox(
        child: Column(
          children: [
            Text('New Activity Page'),
            _buildStartActivityButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityHistoryPage() {
    return Expanded(
      child: SizedBox(
        child: Column(
          children: [
            Text('Activity History Page'),
          ],
        ),
      ),
    );
  }

  Widget _buildLeaderboardPage() {
    return Expanded(
      child: SizedBox(
        child: Column(
          children: [
            Text('Leaderboard Page'),
          ],
        ),
      ),
    );
  }

  Widget _buildStartActivityButton() {
    return ElevatedButton(
      onPressed: () {
        Navigator.pushNamed(context,'/track');
      },
      child: Text('START ACTIVITY'),
    );
  }
}