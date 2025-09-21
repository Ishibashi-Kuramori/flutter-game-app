import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

// オーバーレイ関連(主にプレイ中以外)
class OverlayScreen extends StatelessWidget {
  const OverlayScreen({super.key, required this.title, required this.subtitle, required this.hightScoreStr});

  final String title; // メインタイトル(開始/敗北/勝利等)
  final String subtitle; // サブタイトル(操作案内等)
  final Future<String> hightScoreStr; // ハイスコア文字列

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: const Alignment(0, -0.15),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ハイスコア(0.75秒で下から上に移動)
          FutureBuilder<String>(
            future: hightScoreStr, // BrickBreakerから受け取ったFuture<String>
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // データ読み込み中を示す
                return const CircularProgressIndicator(color: Colors.white);
              } else {
                return Text(
                  snapshot.data!,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: Colors.blue,
                  ),
                ).animate().slideX(duration: 750.ms, begin: -10, end: 0);
              }
            }
          ),
          const SizedBox(height: 16),
          // メインタイトル(0.75秒で上から下に移動)
          Text(
            title,
            style: Theme.of(context).textTheme.headlineLarge,
          ).animate().slideY(duration: 750.ms, begin: -3, end: 0),
          const SizedBox(height: 16),
          // サブタイトル(フェードイン/アウトを1秒ごとにリピート)
          Text(
            subtitle,
            style: Theme.of(context).textTheme.headlineSmall)
              .animate(onPlay: (controller) => controller.repeat())
              .fadeIn(duration: 1.seconds)
              .then()
              .fadeOut(duration: 1.seconds),
        ],
      ),
    );
  }
}