import 'package:flutter/material.dart';

/// Page de texte statique réutilisable (Aide, Confidentialité, CGU).
class InfoPageScreen extends StatelessWidget {
  const InfoPageScreen({required this.title, required this.body, super.key});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Text(body, style: const TextStyle(fontSize: 15, height: 1.5)),
      ),
    );
  }
}
