import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app/theme.dart';

/// かながわ教材ライブラリ（授業プリントと問題プリントの無料サイト）
const studyLibraryUrl = 'https://seg1gpt0jpn.github.io/Kanagawa-Stydy-Library/';

/// かながわ教材ライブラリを開く
Future<void> openStudyLibrary() =>
    launchUrl(Uri.parse(studyLibraryUrl), mode: LaunchMode.externalApplication);

/// アカウント画面の「かながわ教材ライブラリ」
class StudyLibraryCard extends StatelessWidget {
  const StudyLibraryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      key: const ValueKey('study-library'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.menu_book, size: 20),
                const SizedBox(width: 6),
                Text('かながわ教材ライブラリ', style: serif(16)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '中学・高校の授業プリントと、解答解説つきの問題プリントを、'
              '教科・単元ごとに無料で読んだり印刷したりできるサイトです。',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: TsuzuriColors.inkSoft,
              ),
            ),
            const SizedBox(height: 4),
            TextButton.icon(
              key: const ValueKey('study-library-open'),
              onPressed: openStudyLibrary,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('教材ライブラリを開く'),
            ),
          ],
        ),
      ),
    );
  }
}
