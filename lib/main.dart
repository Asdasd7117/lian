name: video_generator_app
description: تطبيق Flutter يقوم بإنشاء فيديو من وصف المستخدم ويحفظه في الاستوديو
publish_to: 'none'

version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"

dependencies:
  flutter:
    sdk: flutter
  ffmpeg_kit_flutter: ^6.0.2
  path_provider: ^2.1.2
  media_store_plus: ^1.2.0
  permission_handler: ^11.3.1

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.1

flutter:
  uses-material-design: true
