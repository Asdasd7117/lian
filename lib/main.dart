import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Video Generator',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const VideoGeneratorPage(),
    );
  }
}

class VideoGeneratorPage extends StatefulWidget {
  const VideoGeneratorPage({super.key});

  @override
  State<VideoGeneratorPage> createState() => _VideoGeneratorPageState();
}

class _VideoGeneratorPageState extends State<VideoGeneratorPage> {
  static const platform = MethodChannel('video_generator');
  bool _isProcessing = false;
  String _status = "اضغط على الزر لتوليد الفيديو";
  final TextEditingController _descController = TextEditingController();

  Future<void> _generateVideo() async {
    // 🔹 طلب صلاحية الوصول قبل أي شيء
    var status = await Permission.videos.request();

    if (status.isDenied || status.isPermanentlyDenied) {
      setState(() {
        _status = "تم رفض صلاحية الوصول للتخزين!";
      });
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = "جاري إنشاء الفيديو...";
    });

    try {
      // 🔹 تمرير النص المكتوب للوصف إلى الجانب الجافا
      final String result = await platform.invokeMethod(
        'generateVideo',
        {"description": _descController.text},
      );

      setState(() {
        _status = result;
      });
    } on PlatformException catch (e) {
      setState(() {
        _status = "حدث خطأ أثناء إنشاء الفيديو: ${e.message}";
      });
    }

    setState(() {
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("مولد الفيديو"),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  labelText: "أدخل وصف الفيديو",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isProcessing ? null : _generateVideo,
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: _isProcessing
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("توليد الفيديو"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
