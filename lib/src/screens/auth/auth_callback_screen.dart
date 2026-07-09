import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../routing/app_router.dart';

class AuthCallbackScreen extends ConsumerStatefulWidget {
  final String? token;
  final String? type;
  final String? accessToken;
  final String? refreshToken;

  const AuthCallbackScreen({
    super.key,
    this.token,
    this.type,
    this.accessToken,
    this.refreshToken,
  });

  @override
  ConsumerState<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends ConsumerState<AuthCallbackScreen> {
  @override
  void initState() {
    super.initState();
    _handleAuthCallback();
  }

  Future<void> _handleAuthCallback() async {
    final token = widget.token;
    final type = widget.type;
    final accessToken = widget.accessToken;
    final refreshToken = widget.refreshToken;

    if (accessToken != null && refreshToken != null) {
      // Session already provided in URL
      final success = await ref.read(authProvider.notifier).setSession(accessToken, refreshToken);
      if (success && mounted) {
        if (context.mounted) context.go(AppRoutes.home);
      } else if (mounted) {
        _showError('Session could not be restored. Please log in manually.');
      }
      return;
    }

    if (token != null && type == 'magiclink') {
      final success = await ref.read(authProvider.notifier).verifyMagicLink(token, 'magiclink');
      if (success && mounted) {
        if (context.mounted) context.go(AppRoutes.home);
      } else if (mounted) {
        _showError('Magic link invalid or expired. Please try again.');
      }
      return;
    }

    _showError('No authentication data found.');
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Signing you in...'),
          ],
        ),
      ),
    );
  }
}
