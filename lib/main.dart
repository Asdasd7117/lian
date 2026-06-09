import 'dart:convert';
import 'dart:js' as js;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

void main() => runApp(const MaterialApp(home: VideoEditorScreen()));

class ApiConfig {
  static const String pexelsKey = "1y1rQKXW16VqMqafrrTynioop03NY52ZGvoT75iGAEI31XtRQrZxGLF3"; 
}

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});
  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  Uint8List? _videoBytes;
  Uint8List? _audioBytes;
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  String _status = "جاهز للعمل";

  // 1. جلب فيديو من Pexels
  Future<void> _fetchVideoFromPexels() async {
    setState(() => _status = "جاري الاتصال بـ Pexels...");
    try {
      final response = await http.get(
        Uri.parse('https://api.pexels.com/videos/search?query=${_searchController.text}&per_page=1'),
        headers: {'Authorization': ApiConfig.pexelsKey},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final videoUrl = data['videos'][0]['video_files'][0]['link'];
        final videoResponse = await http.get(Uri.parse(videoUrl));
        setState(() {
          _videoBytes = videoResponse.bodyBytes;
          _status = "تم جلب الفيديو من Pexels بنجاح";
        });
      }
    } catch (e) { setState(() => _status = "خطأ في الاتصال: $e"); }
  }

  // 2. اختيار فيديو من جهاز المستخدم
  Future<void> _pickLocalVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
    if (result != null) setState(() => _videoBytes = result.files.first.bytes);
  }

  // 3. اختيار ملف صوتي من الجهاز
  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio, withData: true);
    if (result != null) setState(() => _audioBytes = result.files.first.bytes);
  }

  // 4. المعالجة النهائية
  void _generate() async {
    if (_videoBytes == null || _audioBytes == null || _textController.text.isEmpty) {
      setState(() => _status = "تأكد من اختيار فيديو وصوت وإدخال نص!");
      return;
    }
    setState(() => _status = "جاري المعالجة... لا تغلق الصفحة");

    final result = await js.context.callMethod('processVideo', [_videoBytes, _audioBytes, _textController.text]);

    final blob = js.context.callMethod('Blob', [[result], {'type': 'video/mp4'}]);
    final url = js.context.callMethod('URL', ['createObjectURL', blob]);
    final anchor = js.context.callMethod('document.createElement', ['a']);
    anchor.href = url;
    anchor.download = 'my_video.mp4';
    anchor.click();
    setState(() => _status = "تم التحميل!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("محرر الفيديو الشامل")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(controller: _searchController, decoration: const InputDecoration(labelText: "بحث Pexels")),
            ElevatedButton(onPressed: _fetchVideoFromPexels, child: const Text("جلب فيديو من الإنترنت")),
            const Divider(),
            ElevatedButton(onPressed: _pickLocalVideo, child: const Text("اختيار فيديو من الجهاز")),
            ElevatedButton(onPressed: _pickAudio, child: const Text("اختيار صوت من الجهاز")),
            TextField(controller: _textController, decoration: const InputDecoration(labelText: "أدخل النص/الوصف")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _generate, child: const Text("إنتاج الفيديو النهائي")),
            const SizedBox(height: 20),
            Text(_status, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
