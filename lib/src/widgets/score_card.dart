import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// スコア表示関連
class ScoreCard extends StatelessWidget {
  const ScoreCard({
    super.key, 
    required this.score, 
    required this.nameController,
    this.textFieldWidth
  });

  final ValueNotifier<int> score;
  final TextEditingController nameController;
  final double? textFieldWidth;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: score,
      builder: (context, score, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Score: ${score.toString().padLeft(2, '0')}'.toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge!,
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: textFieldWidth ?? double.infinity, // 指定なければ最大幅
                child: TextField(
                  controller: nameController,
                  maxLength: 10, // 最大10文字
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(10),
                    FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z]')), //大文字小文字英語のみ
                  ],
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Enter your name',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}