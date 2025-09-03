import 'package:flutter/material.dart';
import 'src/widgets/ine_processor_widget.dart';

/// Punto de entrada principal del módulo Flutter
/// Este archivo se usa cuando el módulo se ejecuta como aplicación independiente
void main() {
  runApp(const IneProcessorApp());
}

/// Aplicación principal del módulo INE Processor
class IneProcessorApp extends StatelessWidget {
  const IneProcessorApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'INE Processor Module',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const IneProcessorWidget(),
      debugShowCheckedModeBanner: false,
    );
  }
}