import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'dart:io';

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

  Future<void> saveVideoToGallery(String path) async {
    // طلب إذن الوصول للتخزين
    final status = await Permission.storage.request();
    if (status.isGranted) {
      await ImageGallerySaver.saveFile(path);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ تم حفظ الفيديو في الاستوديو')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ لم يتم منح إذن الوصول للتخزين')),
      );
    }
  }

  Future<void> generateVideo(String text) async {
    setState(() => _loading = true);
    final dir = await getTemporaryDirectory();
    final outputPath = '${dir.path}/video_${DateTime.now().millisecondsSinceEpoch}.mp4';

    // إنشاء فيديو بسيط من لون ونص فقط
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
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
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
