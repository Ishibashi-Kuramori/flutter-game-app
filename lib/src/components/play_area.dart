import 'dart:async';

import 'package:flame/collisions.dart'; // RectangleHitbox用
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../brick_breaker.dart';

// ゲーム画面描画領域関連
class PlayArea extends RectangleComponent // RectangleComponent:四角形描画
  with HasGameReference<BrickBreaker> {
  PlayArea() : super(
    paint: Paint()..color = const Color(0xfff2e8cf), // 領域内の色を定義
    children: [RectangleHitbox()], // 衝突判定
  );

  @override
  FutureOr<void> onLoad() async {
    super.onLoad();
    size = Vector2(game.width, game.height);
  }
}
