import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class UsernameFormField extends StatelessWidget {
  const UsernameFormField({
    super.key,
    required this.controller,
    this.decoration,
    this.enabled = true,
  });

  final TextEditingController controller;
  final InputDecoration? decoration;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.username],
      autocorrect: false,
      obscureText: false,
      maxLength: 12,
      maxLengthEnforcement: MaxLengthEnforcement.none,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: decoration ??
          const InputDecoration(
            labelText: '学号',
          ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return '请填入您的学号';
        } else if (value.length != 12) {
          return '学号不是12位';
        }
        return null;
      },
    );
  }
}
