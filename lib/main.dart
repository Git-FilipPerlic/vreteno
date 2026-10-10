import 'package:flutter/material.dart';

void main() => runApp(const VretenoApp());

class VretenoApp extends StatelessWidget {
  const VretenoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vreteno',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const Scaffold(body: Center(child: Text('Vreteno'))),
    );
  }
}
