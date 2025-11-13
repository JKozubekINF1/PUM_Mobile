import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowLoginSuccess();
    });
  }

  void _checkAndShowLoginSuccess() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    if (authProvider.showLoginSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Zalogowano pomyślnie!')),
      );
      authProvider.clearLoginSuccess();
    }
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
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text("Title"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ElevatedButton(
              child: const Text('Map'),
              onPressed: () {
                Navigator.pushNamed(context, '/track');
              },
            ),
            const SizedBox(height: 20),

            authProvider.isAuthenticated
                ?
            Column(
              children: [
                ElevatedButton(
                  child: const Text('Profil'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/profile');
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  child: const Text('Wyloguj'),
                  onPressed: () async {
                    await authProvider.logout();

                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Zostałeś wylogowany.')),
                      );
                    }
                  },
                ),
              ],
            )
                :
            Column(
              children: [
                ElevatedButton(
                  child: const Text('Login'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/login');
                  },
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  child: const Text('Register'),
                  onPressed: () {
                    Navigator.pushNamed(context, '/register');
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}