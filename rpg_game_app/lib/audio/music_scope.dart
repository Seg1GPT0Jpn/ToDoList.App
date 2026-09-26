import 'package:flutter/widgets.dart';

import '../app/services.dart';

/// この画面を開いているあいだ、[music] の BGM を流す
class MusicScope extends StatefulWidget {
  const MusicScope({super.key, required this.music, required this.child});

  final String music;
  final Widget child;

  @override
  State<MusicScope> createState() => _MusicScopeState();
}

class _MusicScopeState extends State<MusicScope> {
  RpgServices? _services;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_services != null) return;
    _services = RpgServices.of(context);
    _services!.music.enter(widget.music);
  }

  @override
  void dispose() {
    _services?.music.leave(widget.music);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
