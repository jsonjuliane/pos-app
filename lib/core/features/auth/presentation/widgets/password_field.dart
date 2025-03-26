import 'package:flutter/material.dart';

class PasswordField extends StatefulWidget {
  final String value;
  final void Function(String) onChanged;
  final FocusNode focusNode;
  final VoidCallback onSubmitted;

  const PasswordField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.focusNode,
    required this.onSubmitted,
  });

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: widget.value,
      focusNode: widget.focusNode,
      obscureText: _obscure,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
        labelText: 'Password',
        prefixIcon: const Icon(Icons.lock_outline),
        border: const OutlineInputBorder(),
        suffixIcon: IconButton(
          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
      onChanged: widget.onChanged,
      onFieldSubmitted: (_) => widget.onSubmitted(),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Password required';
        if (val.length < 6) return 'Minimum 6 characters';
        return null;
      },
    );
  }
}