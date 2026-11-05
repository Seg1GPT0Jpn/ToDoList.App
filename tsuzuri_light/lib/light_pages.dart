import 'package:flutter/material.dart';
import 'package:rpg_game_app/account/account_screen.dart';
import 'package:rpg_game_app/account/welcome_screen.dart';
import 'package:rpg_game_app/app/theme.dart';
import 'package:rpg_game_app/art/paper.dart';
import 'package:rpg_game_app/classroom/classroom_screens.dart';
import 'package:rpg_game_app/meta/learning_status_screen.dart';
import 'package:rpg_game_app/meta/review_tower_screen.dart';
import 'package:rpg_game_app/meta/settings_screen.dart';
import 'package:rpg_game_app/meta/today_plan.dart';
import 'package:rpg_game_app/study/exam_world_screens.dart';
import 'package:rpg_game_app/study/personal_books.dart';
import 'package:rpg_game_app/study/sea_home_screen.dart';
import 'package:rpg_game_app/vocab/vocab_home.dart';

/// ホームから開く画面。ホームを出したあとで読みこむ（起動時に読むプログラムを小さくするため）
Widget sea(PersonalBooks books) => SeaHomeScreen(personalBooks: books);
Widget exam() => const ExamWorldListScreen();
Widget vocab(PersonalBooks books) => Scaffold(
  appBar: AppBar(title: Text('単語帳', style: serif(18))),
  body: NotebookPaper(child: VocabHome(books: books)),
);
Widget classroom([String? code]) => ClassroomHubScreen(joinCode: code);
Widget review() => const ReviewTowerScreen();
Widget status() => const LearningStatusScreen();
Widget settings() => const SettingsScreen();
Widget account() => const AccountScreen();
Widget welcome() => const WelcomeScreen();
Widget todayPlan() => const TodayPlanCard();
