import 'dart:js' as js;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(const MaterialApp(home: VideoEditorScreen()));

class VideoEditorScreen extends StatefulWidget {
  const VideoEditorScreen({super.key});
  @override
  State<VideoEditorScreen> createState() => _VideoEditorScreenState();
}

class _VideoEditorScreenState extends State<VideoEditorScreen> {
  Uint8List? _videoBytes;
  Uint8List? _audioBytes;
  final TextEditingController _textController = TextEditingController();
  String _status = "جاهز";

  Future<void> _pickVideo() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.video, withData: true);
    if (result != null) {
      setState(() => _videoBytes = result.files.first.bytes);
    }
  }

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio, withData: true);
    if (result != null) {
      setState(() => _audioBytes = result.files.first.bytes);
    }
  }

  void _generate() {
    if (_videoBytes == null || _audioBytes == null) {
      setState(() => _status = "يرجى اختيار فيديو وملف صوتي أولاً!");
      return;
    }
    
    setState(() => _status = "جاري المعالجة (قد يستغرق وقتاً)...");

    // إرسال البيانات إلى JS
    js.context.callMethod('processVideo', [
      _videoBytes, 
      _audioBytes, 
      _textController.text
    ]).then((result) {
      setState(() => _status = "تم الإنتاج!");
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("محرر الفيديو المحلي")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            ElevatedButton(onPressed: _pickVideo, child: const Text("اختر الفيديو")),
            ElevatedButton(onPressed: _pickAudio, child: const Text("اختر ملف الصوت")),
            TextField(controller: _textController, decoration: const InputDecoration(labelText: "اكتب النص على الفيديو")),
            const SizedBox(height: 20),
            ElevatedButton(onPressed: _generate, child: const Text("إنتاج الفيديو")),
            const SizedBox(height: 20),
            Text(_status),
          ],
        ),
      ),
    );
  }
}
