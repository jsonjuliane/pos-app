import 'package:flutter/material.dart';

class PasswordField extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;

  const PasswordField({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      obscureText: true,
      decoration: const InputDecoration(
        labelText: 'Password',
        prefixIcon: Icon(Icons.lock_outline),
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,
      validator: (val) {
        if (val == null || val.isEmpty) return 'Password required';
        if (val.length < 6) return 'Minimum 6 characters';
        return null;
      },
    );
  }
}