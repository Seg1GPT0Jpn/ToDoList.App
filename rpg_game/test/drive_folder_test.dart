import 'package:rpg_game/rpg_game.dart';
import 'package:test/test.dart';

String _entry(String id, String href, String title, String modified) =>
    '<div class="flip-entry" id="entry-$id" tabindex="0" role="link">'
    '<div class="flip-entry-info"><a href="$href" target="_blank">'
    '<div class="flip-entry-list-icon"><img src="x" alt=""/></div>'
    '<div class="flip-entry-title">$title</div></a></div>'
    '<div class="flip-entry-last-modified"><div>$modified</div></div></div>';

void main() {
  test('埋め込み用ページから、フォルダとファイルの一覧を読む', () {
    final html = '<html><body><div class="flip-entries">'
        '${_entry('f1', 'https://drive.google.com/file/d/f1/view?usp=drive_web', '予想問題 &amp; 解答.pdf', '11:29 pm')}'
        '${_entry('d1', 'https://drive.google.com/drive/folders/d1', '化学基礎', 'Oct 22')}'
        '${_entry('f2', 'https://drive.google.com/file/d/f2/view', 'ノート.PDF', '')}'
        '</div></body></html>';
    final list = DriveFolder.parse(html);
    expect([for (final e in list) e.id], ['d1', 'f2', 'f1']);
    expect(list[0].isFolder, isTrue);
    expect(list[2].title, '予想問題 & 解答.pdf');
    expect(list[2].modified, '11:29 pm');
    expect(
        list[2].url, 'https://drive.google.com/file/d/f1/view?usp=drive_web');
    expect(list[1].extension, 'pdf');
    expect(list[0].extension, '');
  });

  test('空のフォルダ・読めないページは空の一覧', () {
    expect(DriveFolder.parse('<html></html>'), isEmpty);
    expect(DriveFolder.parse(''), isEmpty);
  });

  test('フォルダのリンクから id を取り出す', () {
    expect(
      DriveFolder.idOf('https://drive.google.com/drive/folders/ab_C-1'),
      'ab_C-1',
    );
    expect(DriveFolder.idOf('https://drive.google.com/file/d/x/view'), isNull);
    expect(
      DriveFolder.embedUrl('abc').toString(),
      'https://drive.google.com/embeddedfolderview?id=abc#list',
    );
  });
}
