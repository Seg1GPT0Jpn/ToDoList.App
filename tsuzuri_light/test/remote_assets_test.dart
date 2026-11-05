import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:tsuzuri_light/remote_assets_io.dart';

/// remoteAssetBase のかわりに手元のサーバーへ送る
class _Client implements HttpClient {
  _Client(this._inner, this.port);
  final HttpClient _inner;
  final int port;
  @override
  Future<HttpClientRequest> getUrl(Uri url) =>
      _inner.getUrl(url.replace(scheme: 'http', host: '127.0.0.1', port: port));
  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  test('開いたときにネットから読んで端末に残し、次はネットなしでも開ける。裏で新しいかを確かめる', () async {
    final tmp = await Directory.systemTemp.createTemp('remote_assets');
    addTearDown(() => tmp.delete(recursive: true));
    var body = [1, 2, 3];
    var etag = '"v1"';
    final hits = <String>[];
    final server = await HttpServer.bind('127.0.0.1', 0);
    server.listen((r) async {
      hits.add('${r.uri.path} ${r.headers.value('if-none-match')}');
      if (r.headers.value('if-none-match') == etag) {
        r.response.statusCode = 304;
      } else {
        r.response.headers.set('etag', etag);
        r.response.add(body);
      }
      await r.response.close();
    });
    final client = _Client(HttpClient(), server.port);
    RemoteAssets make() => RemoteAssets(dir: () async => tmp, client: client);
    const path = 'assets/materials/x/01.bin';

    // はじめて：ネットから読む
    expect(await make().load(path), [1, 2, 3]);
    expect(hits.single, '/light/assets/packages/rpg_game_app/$path null');

    // 次に開いたとき：端末のものをすぐ出す。確かめてから7日たつまでは、ネットに聞かない
    expect(await make().load(path), [1, 2, 3]);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(hits, hasLength(1));
    final tag = File('${tmp.path}/remote_assets/$path.etag');
    Future<void> weekAgo() =>
        tag.setLastModified(DateTime.now().subtract(RemoteAssets.checkEvery));
    // 7日たったら、裏で確かめる（変わっていなければ 304）
    await weekAgo();
    expect(await make().load(path), [1, 2, 3]);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(hits.last, endsWith('"v1"'));
    expect(await make().load(path), [1, 2, 3]);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(hits, hasLength(2));

    // 公開した中身が変わったら、裏で入れかえ、その次から新しいものを使う
    body = [9, 9];
    etag = '"v2"';
    await weekAgo();
    final a = make();
    expect(await a.load(path), [1, 2, 3]);
    await Future<void>.delayed(const Duration(milliseconds: 200));
    expect(await make().load(path), [9, 9]);

    // ネットがなくても、端末に残っているものは開ける
    await server.close(force: true);
    expect(await make().load(path), [9, 9]);
    // 残っていないものは失敗する（画面は読めなかったことを出す）
    await expectLater(
      make().load('assets/materials/x/02.bin'),
      throwsA(anything),
    );
  });
}
