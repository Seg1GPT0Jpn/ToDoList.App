import 'package:flutter_test/flutter_test.dart';
import 'package:rpg_game_app/field/field_map.dart';

void main() {
  // . 床  # 壁  N 人（歩けない）
  const rows = ['#######', '#..#..#', '#..#.N#', '#.....#', '#######'];
  bool walk(Cell c) =>
      c.row >= 0 &&
      c.row < rows.length &&
      c.col >= 0 &&
      c.col < rows[c.row].length &&
      rows[c.row][c.col] == '.';

  test('壁をよけて、いちばん近い道を通る', () {
    final p = findFieldPath((col: 1, row: 1), (col: 4, row: 1), walk)!;
    expect(p.last, (col: 4, row: 1));
    expect(p.length, 7);
    for (final c in p) {
      expect(walk(c), isTrue);
    }
  });

  test('人のマスは、となりまで行って最後にふみ出す', () {
    final p = findFieldPath((col: 1, row: 3), (col: 5, row: 2), walk)!;
    expect(p.last, (col: 5, row: 2));
    expect(walk(p[p.length - 2]), isTrue);
  });

  test('行けない場所は null、いる場所は空', () {
    expect(findFieldPath((col: 1, row: 1), (col: 10, row: 10), walk), isNull);
    expect(findFieldPath((col: 1, row: 1), (col: 1, row: 1), walk), isEmpty);
  });
}
