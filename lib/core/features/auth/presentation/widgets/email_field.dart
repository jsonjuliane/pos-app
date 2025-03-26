import 'package:flutter/material.dart';

class EmailField extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;

  const EmailField({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      keyboardType: TextInputType.emailAddress,
      decoration: const InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email_outlined),
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,
      validator: (val) {
        if (val == null || val.isEmpty) return 'Email required';
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) return 'Invalid email';
        return null;
      },
    );
  }
}