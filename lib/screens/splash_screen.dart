import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_logo.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;

        final authProvider = context.read<AuthProvider>();
        final user = authProvider.currentUser;

        if (user == null || !authProvider.hasSupabaseSession) {
          context.go('/login');
          return;
        }

        if (user.role == UserRole.tenant) {
          context.go('/tenant_home');
        } else {
          context.go('/landowner_dashboard');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeIn(
              duration: const Duration(seconds: 1),
              child: const AppLogo(height: 240),
            ),
          ],
        ),
      ),
    );
  }
}
