import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/login_providers.dart';
import '../../../../utils/error_handler.dart';
import 'email_field.dart';
import 'password_field.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  String? _error;

  void _submit() async {
    final form = _formKey.currentState!;
    if (!form.validate()) return;

    final email = ref.read(loginEmailProvider);
    final password = ref.read(loginPasswordProvider);

    await ref.read(loginControllerProvider.notifier).login(email, password);
    final state = ref.read(loginControllerProvider);

    if (state is AsyncError) {
      if (!mounted) return;
      setState(() {
        _error = mapFirebaseAuthError(state.error.toString());
      });
    } else if (state is AsyncData && state.value != null) {
      if (!mounted) return;
      context.goNamed('dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = ref.watch(loginEmailProvider);
    final password = ref.watch(loginPasswordProvider);
    final loading = ref.watch(loginControllerProvider).isLoading;

    return Form(
      key: _formKey,
      child: Column(
        children: [
          EmailField(value: email, onChanged: (val) => ref.read(loginEmailProvider.notifier).state = val),
          const SizedBox(height: 16),
          PasswordField(value: password, onChanged: (val) => ref.read(loginPasswordProvider.notifier).state = val),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: loading ? null : _submit,
              child: loading
                  ? const SizedBox(
                height: 20, width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
              )
                  : const Text('Login'),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }
}