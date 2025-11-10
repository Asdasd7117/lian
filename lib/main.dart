import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart'; // ✅ التعديل الجديد على المكتبة

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
  bool _isProcessing = false;
  String _status = "اضغط على الزر لتوليد الفيديو";

  Future<void> _generateVideo() async {
    setState(() {
      _isProcessing = true;
      _status = "جاري إنشاء الفيديو...";
    });

    try {
      // الأمر المستخدم مع FFmpeg لإنشاء فيديو بسيط بلون واحد لمدة 5 ثوانٍ
      final command =
          '-f lavfi -i color=c=blue:s=640x480:d=5 -vf "drawtext=text=\'Hello Flutter\':x=(w-text_w)/2:y=(h-text_h)/2:fontcolor=white:fontsize=40" /storage/emulated/0/Download/output.mp4';

      await FFmpegKit.execute(command);

      setState(() {
        _status = "تم إنشاء الفيديو بنجاح! (تم حفظه في مجلد التنزيلات)";
      });
    } catch (e) {
      setState(() {
        _status = "حدث خطأ أثناء إنشاء الفيديو: $e";
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
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
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
