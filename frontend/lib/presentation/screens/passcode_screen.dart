import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/providers/passcode_provider.dart';
import 'main_layout.dart';

class PasscodeScreen extends ConsumerStatefulWidget {
  const PasscodeScreen({super.key});

  @override
  ConsumerState<PasscodeScreen> createState() => _PasscodeScreenState();
}

class _PasscodeScreenState extends ConsumerState<PasscodeScreen> {
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleLogin() async {
    final success = await ref.read(loginProvider.notifier).login(
      _idController.text,
      _passwordController.text,
    );
    if (success) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainLayout()),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Incorrect User ID or Password 🌸'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '🌤️',
                style: TextStyle(fontSize: 80),
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome, Shivani',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your private space awaits.',
                style: TextStyle(
                  fontSize: 16,
                  color: colors.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 48),
              
              _buildTextField(
                controller: _idController,
                icon: Icons.person_outline,
                label: 'User ID',
                colors: colors,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _passwordController,
                icon: Icons.lock_outline,
                label: 'Password',
                isPassword: true,
                colors: colors,
              ),
              
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  child: const Text('Unlock Diary'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String label,
    bool isPassword = false,
    required ColorScheme colors,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: TextStyle(color: colors.onSurface),
        decoration: InputDecoration(
          icon: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Icon(icon, color: colors.primary),
          ),
          labelText: label,
          labelStyle: TextStyle(color: colors.onSurface.withOpacity(0.6)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
