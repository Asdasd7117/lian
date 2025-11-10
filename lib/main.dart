import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';

void main() {
  runApp(VideoGeneratorApp());
}

class VideoGeneratorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VideoGeneratorPage(),
    );
  }
}

class VideoGeneratorPage extends StatefulWidget {
  @override
  State<VideoGeneratorPage> createState() => _VideoGeneratorPageState();
}

class _VideoGeneratorPageState extends State<VideoGeneratorPage> {
  final TextEditingController _desc = TextEditingController();
  bool _loading = false;

  static const platform = MethodChannel('video_generator_app/save');

  Future<void> saveVideoToGallery(String path) async {
    try {
      await platform.invokeMethod('saveVideo', {'path': path});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ تم حفظ الفيديو في الاستوديو')),
      );
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ فشل الحفظ: ${e.message}')),
      );
    }
  }

  Future<void> generateVideo(String text) async {
    setState(() => _loading = true);
    final dir = await getTemporaryDirectory();
    final outputPath =
        '${dir.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final command =
        '-f lavfi -i color=c=blue:s=640x360:d=5 -vf "drawtext=text=\'$text\':fontcolor=white:fontsize=32:x=(w-text_w)/2:y=(h-text_h)/2" -c:v libx264 -pix_fmt yuv420p $outputPath';

    await FFmpegKit.execute(command);
    await saveVideoToGallery(outputPath);
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("🎬 إنشاء فيديو من وصف"),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _desc,
              decoration: InputDecoration(
                labelText: 'اكتب وصف الفيديو',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loading
                  ? null
                  : () {
                      if (_desc.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('⚠️ الرجاء كتابة وصف أولاً')),
                        );
                        return;
                      }
                      generateVideo(_desc.text.trim());
                    },
              icon: Icon(Icons.movie_creation),
              label: _loading
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2)),
                        SizedBox(width: 10),
                        Text("جارٍ إنشاء الفيديو..."),
                      ],
                    )
                  : Text('إنشاء الفيديو'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
