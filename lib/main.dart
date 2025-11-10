import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // لإخفاء العلامة
      home: Scaffold(
        appBar: AppBar(
          title: Text('تطبيقي البسيط'),
          centerTitle: true,
        ),
        body: Center(
          child: Text(
            'أهلا وسهلا',
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }
}
