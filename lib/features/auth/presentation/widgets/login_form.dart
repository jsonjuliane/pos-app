import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../shared/utils/error_handler.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../providers/login_providers.dart';
import 'email_field.dart';
import 'password_field.dart';
import 'forgot_password_dialog.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _passwordFocusNode = FocusNode();
  String? _error;

  @override
  void dispose() {
    _passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final form = _formKey.currentState!;
    if (!form.validate()) return;

    final email = ref.read(loginEmailProvider);
    final password = ref.read(loginPasswordProvider);

    await ref.read(loginControllerProvider.notifier).login(email, password);
    final state = ref.read(loginControllerProvider);

    if (!mounted) return;

    if (state is AsyncError) {
      setState(() {
        _error = mapFirebaseAuthError(state.error.toString());
      });
    } else if (state is AsyncData && state.value != null) {
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
          EmailField(
            value: email,
            onChanged: (val) => ref.read(loginEmailProvider.notifier).state = val,
            onSubmitted: () => _passwordFocusNode.requestFocus(),
          ),
          const SizedBox(height: 16),
          PasswordField(
            value: password,
            onChanged: (val) => ref.read(loginPasswordProvider.notifier).state = val,
            focusNode: _passwordFocusNode,
            onSubmitted: _submit,
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (_) => const ForgotPasswordDialog(),
                );
              },
              child: const Text('Forgot Password?'),
            ),
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            onPressed: loading ? null : _submit,
            loading: loading,
            child: const Text('Login'),
          ),
          const SizedBox(height: 12),
          AnimatedOpacity(
            opacity: _error != null ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Text(
              _error ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.red,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}