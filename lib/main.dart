import 'package:custom_refresh_indicator_flutter/screen/demo_page.dart';
import 'package:custom_refresh_indicator_flutter/screen/demo_page_using_package.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Custom Refresh Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const DemoPageForPackage(),
    );
  }
}



