import 'speech.dart';

/// Web 以外では flutter_tts を使う
Speaker? createPlatformSpeaker() => null;
