import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter/ffmpeg_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'dart:io';

void main() {
  runApp(VideoGeneratorApp());
}

class VideoGeneratorApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
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

  Future<void> generateVideo(String text) async {
    setState(() => _loading = true);
    final dir = await getTemporaryDirectory();
    final outputPath = '${dir.path}/video.mp4';

    // هنا نولد فيديو بسيط من لون ونص فقط
    final command =
        '-f lavfi -i color=c=blue:s=640x360:d=5 -vf "drawtext=text=\'$text\':fontcolor=white:fontsize=24:x=(w-text_w)/2:y=(h-text_h)/2" -c:v libx264 -pix_fmt yuv420p $outputPath';

    await FFmpegKit.execute(command);

    await GallerySaver.saveVideo(outputPath);
    setState(() => _loading = false);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('تم حفظ الفيديو في الاستوديو ✅')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("إنشاء فيديو من وصف")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _desc,
              decoration: InputDecoration(labelText: 'اكتب وصف الفيديو'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading
                  ? null
                  : () => generateVideo(_desc.text.isEmpty
                      ? "فيديو تجريبي"
                      : _desc.text),
              child: _loading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('إنشاء الفيديو'),
            ),
          ],
        ),
      ),
    );
  }
}
