import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../auth/auth_service.dart';
import '../routes.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
  final auth = Provider.of<AuthService>(context);
  final user = auth.user;
  final display = (user != null && user.profile.displayName.isNotEmpty)
    ? user.profile.displayName
    : (user?.username ?? 'User');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Event Connect'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final nav = Navigator.of(context);
              await auth.logout();
              nav.pushReplacementNamed(Routes.login);
            },
          )
        ],
      ),
      body: Center(
        child: Text('Welcome $display', style: const TextStyle(fontSize: 18)),
      ),
    );
  }
}
