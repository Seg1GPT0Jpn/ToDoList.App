import 'dart:convert';

import 'school_material.dart';

/// 学校の対策資料を置いている Google ドライブのフォルダ（予想問題・授業ノートなど）。
///
/// アプリはフォルダへのリンクだけを持ち、中身はコピーしない。フォルダを開くので、
/// ドライブにファイルが増えればそのまま見られる。リンクは学校のパスワードから作った鍵で
/// 暗号化してあり、パスワードを知らないと読めない（鍵はアプリの中に置かない）。
class SchoolDriveLink {
  const SchoolDriveLink({
    required this.title,
    required this.url,
    this.group = '',
  });

  final String title;
  final String url;

  /// 教科（見出し）。空ならいちばん上に出す
  final String group;

  static SchoolDriveLink? fromMap(Object? m) {
    if (m is! Map) return null;
    final title = m['t'], url = m['u'];
    if (title is! String || url is! String) return null;
    if (!url.startsWith('https://drive.google.com/')) return null;
    final group = m['g'];
    return SchoolDriveLink(
      title: title,
      url: url,
      group: group is String ? group : '',
    );
  }

  Map<String, Object> toMap() => {
        't': title,
        'u': url,
        if (group.isNotEmpty) 'g': group,
      };
}

abstract final class SchoolDrive {
  /// tool/drive_seal.dart で作る
  static const sealed =
      'VFFCMiLXotOme2jcPdtLudic0GaBX7xTrtTYw/TUn7f0Eo/hczciNNj6lE7dZTv1pQjyWoxMMeJ81FLTuxkd7iZhBWq/wPMV69UwaVZGy+qWw72Jv0N2FkGRWcSHi9tIAOCtO4IzIRB8/yigVkta0H0TwUWrs7JJ7CQE6SrkpzyFiNwiWiVmI5EPISrj3IcJE8oiDVpCdwTnHbNqqbV0C9oG6IDfihdgn2a094BHxm8lg/pecEsQOEVsBGR1UhBu2LQs8OzxgxKF8jMF0KuzS52bItIZ4w97oXrQWJej5jHO/eeRVypDWLfCxzfRBU3kTx6F5ULHFvj7/vjtd4nmK06qLkqsWUSD47Jv/bQL+nDjlbpZzJkw4vOjz9OlvVnKWAjvllllggk1SKTv1VCyqdcnLQjJCfYK3BL0rLGE0QqHB7dYQv58OE+bS4wrq8dL9b9GBO2xubBB040cqaMUqJEVVL1CED68/QWrXKqNd0AB5U6b4c4Qrt76gxtY0vKl4VEFBmHUNJuJ5Jf1HJhrnzGJCfYqy/owO9uVqTzHxGR15OV5dtgO7nXxTIVlunkwu16z6zqqMnrW0zY9y/vzEcxSFZBCtGnt40yfOqRDQlvJm0Q5BY0ieCoMIkFjw8V81AhOo1LgOPgbzvcZakP2GG4jyJUfInkkPFOE7TqcKbh1I9gjScjZtoLmGI+c1rBklYsfPp1FHsMI79Lb4vvIp4mQdpGRBSEdvCNbeZn56+ajlAe2EC92w50aODzQ+4M+AYdu1RogyqG3IiCA8XEoxCuvJ4quVHvEHu/Nwp5/n2sTWian6RimZ7zZKbGVKmq+//tGuYaLQ8TwO3hCukmObr4/a57NA0Luidd4aDY+uk8a9+3auV6jb5HeUGHncKiI/6mVr9lnYjnWGG8sx53JUlB/2bGn7tx7b5+nGviPZHR1rTkcrPBpJ4OA7nAXJVLkT1stPkUAm6ZgE0qCCGE+Pu5kCu+xzxqU9+T4OJjnXkYXQZxGoL6a/JFy7R6hMYi67NzgCCBcyOkduXthCFgvJfm/Xk5OmVH3E2hbRrcVxObfkYMIFP98xvPXhXDF0fCL+w6IsaaRRBFuwFsT6iXGB9VnkEXVNDm+LGBvYQyNJV8ZdsP3SMz4zaT9GFCpw66bIQPxjxrgds7bCL+PqxYrhxCGp47OreLJhrzWUaGxR7a1hMnaiovGpxhjwdmet+hB0E46b7TMxQ4R8VBal91Ia05MF13ttZC0AsMzaGYNWHHfr+iUxmpiENcWNNgoyCEx18Mppdx7U7iyJrJrUsgHTXqBIsCKJKU/ic5KaZsRe5iaZV0tnEosOU0Awj7vn87cFTOL6qrf1AFKjUYTpmgLUQ8weeuKi2JPPOLmVM0hkdRZrb+DpFX6OSyQqN9gKqymwk7f1WLqNP8hFXZvYOphnhBuQA0hmTJq47fXhMwNf333F667nf40JMPpZkvWqusMzDv4n6IWMSpP0OLfhPbZmYi0Mczqk7+wd9QsxlEOi55TpbMGZ53mpePFse+jwwLKc4pEmdPPzRny0wstCPQcxic7DTYCLwk+Y8spr34JCDfNWPHygegqckzNcbagiqmFesR6gHeupQQWaZ1L8DF6Me4fq4MmBH3niGa+avTjJ1v/IgyCBa+aTzT+jcTgqEBL3rg1MQp4Kd3pzXEmYDLG2JphYEAwbtjWt7sLhTM9yFC6CMWtYwS0Cj0iBclUttbGw4Fu3PqPT7L2V2PltPtgK/pjKA4=';

  /// 暗号化する（道具・テスト用）
  static String seal(
          List<SchoolDriveLink> links, List<int> nonce, List<int> key) =>
      base64.encode(
        SchoolMaterials.seal(
          utf8.encode(jsonEncode([for (final l in links) l.toMap()])),
          nonce,
          key: key,
        ),
      );

  /// [key]（[SchoolMaterials.keyFor] で作る）で開く。鍵がちがえば null
  static List<SchoolDriveLink>? open(List<int> key, {String data = sealed}) {
    try {
      final bytes = SchoolMaterials.open(base64.decode(data), key: key);
      if (bytes == null) return null;
      final list = jsonDecode(utf8.decode(bytes));
      if (list is! List) return null;
      final links = list
          .map(SchoolDriveLink.fromMap)
          .whereType<SchoolDriveLink>()
          .toList();
      return links.isEmpty ? null : links;
    } catch (_) {
      return null;
    }
  }
}
