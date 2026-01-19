import 'package:flutter/material.dart';

/// 裝備搜尋欄
class GearSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const GearSearchBar({super.key, required this.controller, required this.onChanged, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          hintText: '搜尋本地裝備...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: controller.text.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: onClear) : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: Theme.of(context).cardColor,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        ),
        onChanged: onChanged,
      ),
    );
  }
}
