import 'package:flutter/material.dart';

class EmailField extends StatelessWidget {
  final String value;
  final void Function(String) onChanged;
  final VoidCallback onSubmitted;

  const EmailField({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: value,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      decoration: const InputDecoration(
        labelText: 'Email',
        prefixIcon: Icon(Icons.email_outlined),
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,
      onFieldSubmitted: (_) => onSubmitted(),
      validator: (val) {
        if (val == null || val.isEmpty) return 'Email required';
        if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(val)) return 'Invalid email';
        return null;
      },
    );
  }
}