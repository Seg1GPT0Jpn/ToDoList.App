import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// 公開しているサイトの、つづりクエストの同梱ファイルの場所（Light の Web 版と同じもの）
const remoteAssetBase =
    'https://tsuzuri-quest-v2.web.app/light/assets/packages/rpg_game_app/';

/// 資料・予想問題を APK に入れない（約36MB）かわりに、開いたときにネットから読む。
/// 一度読んだものは端末に残し、次からはネットなしで開ける。
/// 端末に残っているときは、それをすぐ使い、裏で新しくなっていないかを確かめる（変わっていなければほとんど通信しない）
Future<List<int>> Function(String path)? remoteAssetLoader() =>
    RemoteAssets().load;

class RemoteAssets {
  RemoteAssets({Future<Directory> Function()? dir, HttpClient? client})
    : _dir = dir ?? getApplicationSupportDirectory,
      _client = client ?? HttpClient();

  final Future<Directory> Function() _dir;
  final HttpClient _client;

  /// この起動ですでに新しいかを確かめたもの
  final _checked = <String>{};

  Future<File> _file(String path) async =>
      File('${(await _dir()).path}/remote_assets/$path');

  Future<List<int>> load(String path) async {
    final f = await _file(path);
    if (await f.exists()) {
      if (_checked.add(path) && await _due(f)) {
        unawaited(_fetch(path, f).catchError((_) => null));
      }
      return f.readAsBytes();
    }
    _checked.add(path);
    final bytes = await _fetch(path, f);
    if (bytes == null) throw HttpException('読みこめませんでした: $path');
    return bytes;
  }

  /// 新しいかを確かめる間隔（資料・予想問題はめったに変わらないので、通信を減らす）
  static const checkEvery = Duration(days: 7);

  /// 前に確かめてから [checkEvery] たったか（確かめた時刻は .etag の更新時刻）
  Future<bool> _due(File f) async {
    final tag = File('${f.path}.etag');
    if (!await tag.exists()) return true;
    return DateTime.now().difference(await tag.lastModified()) >= checkEvery;
  }

  /// ネットから読んで端末に残す。変わっていなければ（304）null
  Future<List<int>?> _fetch(String path, File f) async {
    final tag = File('${f.path}.etag');
    final req = await _client
        .getUrl(Uri.parse('$remoteAssetBase$path'))
        .timeout(const Duration(seconds: 20));
    if (await f.exists() && await tag.exists()) {
      req.headers.set(HttpHeaders.ifNoneMatchHeader, await tag.readAsString());
    }
    final res = await req.close().timeout(const Duration(seconds: 60));
    if (res.statusCode == HttpStatus.notModified) {
      await res.drain<void>();
      await tag.setLastModified(DateTime.now());
      return null;
    }
    if (res.statusCode != HttpStatus.ok) {
      await res.drain<void>();
      throw HttpException('読みこめませんでした（${res.statusCode}）: $path');
    }
    final bytes = <int>[];
    await for (final chunk in res) {
      bytes.addAll(chunk);
    }
    // 書きかけのファイルが残らないように、別の名前で書いてから置きかえる
    await f.parent.create(recursive: true);
    final tmp = File('${f.path}.part');
    await tmp.writeAsBytes(bytes, flush: true);
    await tmp.rename(f.path);
    final etag = res.headers.value(HttpHeaders.etagHeader);
    if (etag != null) await tag.writeAsString(etag);
    return bytes;
  }
}
