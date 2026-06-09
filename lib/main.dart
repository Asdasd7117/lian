import 'dart:js' as js;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class ApiConfig {
  static const String pexelsKey = "1y1rQKXW16VqMqafrrTynioop03NY52ZGvoT75iGAEI31XtRQrZxGLF3";
}

void main() => runApp(const MaterialApp(home: AiStudioScreen()));

class AiStudioScreen extends StatefulWidget {
  const AiStudioScreen({super.key});
  @override
  State<AiStudioScreen> createState() => _AiStudioScreenState();
}

class _AiStudioScreenState extends State<AiStudioScreen> {
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _textOverlayController = TextEditingController();
  Uint8List? _audioBytes;
  String _status = "حالة النظام: جاهز بانتظار إبداعك";

  Future<void> _pickAudio() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.audio, withData: true);
    if (result != null) {
      setState(() {
        _audioBytes = result.files.first.bytes;
        _status = "تم اختيار الصوت بنجاح";
      });
    }
  }

  void _generate() async {
    if (_descController.text.isEmpty) {
      setState(() => _status = "يرجى كتابة وصف المشهد أولاً!");
      return;
    }
    setState(() => _status = "جاري المعالجة...");

    final result = await js.context.callMethod('processVideo', [
      _descController.text,
      _textOverlayController.text,
      _audioBytes
    ]);

    setState(() => _status = "تم الانتهاء");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Text("استوديو الذكاء الاصطناعي", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const Text("اصنع مقطعك الإبداعي بثوان معدودة", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),
              TextField(controller: _descController, maxLines: 3, decoration: const InputDecoration(labelText: "وصف مشهد الفيديو", border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
              const SizedBox(height: 15),
              TextField(controller: _textOverlayController, decoration: const InputDecoration(labelText: "كتابة نص فوق الفيديو (اختياري)", border: OutlineInputBorder(), filled: true, fillColor: Colors.white)),
              const SizedBox(height: 15),
              SizedBox(width: double.infinity, height: 50, child: ElevatedButton(onPressed: _pickAudio, child: const Text("اختر ملف الصوت من الجهاز"))),
              const SizedBox(height: 25),
              SizedBox(width: double.infinity, height: 60, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), onPressed: _generate, child: const Text("صناعة الفيديو الآن", style: TextStyle(color: Colors.white, fontSize: 18)))),
              const SizedBox(height: 20),
              Text(_status, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey)),
            ],
          ),
        ),
      ),
    );
  }
}
