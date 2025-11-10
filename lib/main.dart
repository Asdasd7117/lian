import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';

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
  final TextEditingController _descriptionController = TextEditingController();
  bool _isProcessing = false;
  String _status = "اضغط على الزر لتوليد الفيديو";

  Future<void> _generateVideo() async {
    setState(() {
      _isProcessing = true;
      _status = "جاري إنشاء الفيديو...";
    });

    try {
      // طلب صلاحية التخزين
      if (await Permission.storage.request().isGranted) {
        // الحصول على مجلد التطبيق في التخزين الخارجي
        final Directory dir = (await getExternalStorageDirectory())!;
        final String path = '${dir.path}/output.mp4';

        // أمر توليد الفيديو مع النص المدخل
        final String command =
            '-f lavfi -i color=c=blue:s=640x480:d=5 '
            '-vf "drawtext=text=\'${_descriptionController.text}\':x=(w-text_w)/2:y=(h-text_h)/2:fontcolor=white:fontsize=40" '
            '$path';

        // استدعاء المنصة الأصلية (Java/Kotlin) لتشغيل الأمر
        final String result = await platform.invokeMethod('generateVideo', {'command': command});

        setState(() {
          _status = "تم إنشاء الفيديو بنجاح!\nتم حفظه في:\n$path";
        });
      } else {
        setState(() {
          _status = "لم تُمنح صلاحية التخزين.";
        });
      }
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
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
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
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "أدخل وصف الفيديو",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isProcessing ? null : _generateVideo,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
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
