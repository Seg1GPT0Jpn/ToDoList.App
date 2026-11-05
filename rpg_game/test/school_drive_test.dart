import 'dart:io';

import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

final _password = Platform.environment['SCHOOL_PASSWORD'];

void main() {
  test('ドライブのリンクは鍵がないと読めず、鍵があれば開ける', () {
    final key = SchoolMaterials.keyFor('pw-123');
    const links = [
      SchoolDriveLink(
          title: '全体', url: 'https://drive.google.com/drive/folders/a'),
      SchoolDriveLink(
        title: '数学',
        url: 'https://drive.google.com/drive/folders/b',
        group: '数学',
      ),
    ];
    final sealed = SchoolDrive.seal(links, List.filled(16, 7), key);
    expect(sealed.contains('drive.google'), isFalse);
    final opened = SchoolDrive.open(key, data: sealed)!;
    expect([for (final l in opened) l.title], ['全体', '数学']);
    expect(opened[1].group, '数学');
    expect(SchoolDrive.open(SchoolMaterials.keyFor('wrong'), data: sealed),
        isNull);
    expect(SchoolDrive.open(SchoolMaterials.keyFor('wrong')), isNull);
  });

  test('ドライブ以外のリンクは読まない', () {
    expect(SchoolDriveLink.fromMap({'t': 'x', 'u': 'https://example.com/'}),
        isNull);
  });

  test('同梱のリンクは学校のパスワードで開ける', () {
    final links = SchoolDrive.open(SchoolMaterials.keyFor(_password!))!;
    expect(links.length, greaterThanOrEqualTo(10));
    expect(links.first.group, '');
  }, skip: _password == null ? 'SCHOOL_PASSWORD がないので中身は確かめない' : false);
}
