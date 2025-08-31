import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';

import '../brick_breaker.dart';
import 'bat.dart';
import 'brick.dart';
import 'play_area.dart'; 

// ボール関連
class Ball extends CircleComponent // CircleComponent:: 円の描画
  with CollisionCallbacks, // 衝突判定コールバックを使用
    HasGameReference<BrickBreaker>{
  Ball({
    required this.velocity, // 速度(時間の経過に伴う位置の変化)
    required super.position, // 位置
    required double radius, // 半径
    required this.difficultyModifier,  // config.dartに定義したボールの速度上昇量
  }) : super(
    radius: radius,
    anchor: Anchor.center, // 座標基準中央
    paint: Paint() // ボールのスタイル定義
      ..color = const Color(0xff1e6091)
      ..style = PaintingStyle.fill,
    children: [CircleHitbox()],
  );

  final Vector2 velocity;
  final double difficultyModifier;

  // ゲームエンジンがフレーム単位で呼び出す処理
  // dt: 前のフレームと現フレームの間の時間
  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
  }

  // 衝突判定コールバック
  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other, // 衝突対象
  ) {
    super.onCollisionStart(intersectionPoints, other);
    // ゲーム領域と衝突した場合
    if (other is PlayArea) {
      // 上に衝突
      if (intersectionPoints.first.y <= 0) {
        velocity.y = -velocity.y;
      // 左に衝突
      } else if (intersectionPoints.first.x <= 0) {
        velocity.x = -velocity.x;
      // 右に衝突
      } else if (intersectionPoints.first.x >= game.width) {
        velocity.x = -velocity.x;
      // 下に衝突
      } else if (intersectionPoints.first.y >= game.height) {
        // 0.35秒後にステータスをgameOverに遷移
        add(
          RemoveEffect(
            delay: 0.35,
            onComplete: () {
              game.playState = PlayState.gameOver;
            },
          ),
        );
      }
    // バットと衝突した場合
    } else if (other is Bat) {
      velocity.y = -velocity.y; // 縦方向はそのまま反転
      // 横方向はバットとボールの相対位置に応じて変化させる
      velocity.x =
          velocity.x +
          (position.x - other.position.x) / other.size.x * game.width * 0.3;
    // ブロックと衝突した場合
    } else if (other is Brick) {
      // ブロック上側に衝突
      if (position.y < other.position.y - other.size.y / 2) {
        velocity.y = -velocity.y;
      // ブロック下側に衝突
      } else if (position.y > other.position.y + other.size.y / 2) {
        velocity.y = -velocity.y;
      // ブロック左側に衝突
      } else if (position.x < other.position.x) {
        velocity.x = -velocity.x;
      // ブロック右側に衝突
      } else if (position.x > other.position.x) {
        velocity.x = -velocity.x;
      }
      // ボールの速度を若干上昇させる
      velocity.setFrom(velocity * difficultyModifier);
    // それ以外と衝突した場合はログに出す
    } else {
      debugPrint('collision with $other');
    }
  }
}
