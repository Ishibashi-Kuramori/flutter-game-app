import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flutter/material.dart';
import 'package:flame_audio/flame_audio.dart';

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
  Vector2? _lastPosition; // 前フレームの位置

  // ゲームエンジンがフレーム単位で呼び出す処理
  // dt: 前のフレームと現フレームの間の時間
  @override
  void update(double dt) {
    super.update(dt);

    final oldPos = _lastPosition ?? position.clone(); // 前フレームの位置を取得
    Vector2 newPos = _collisionPlayArea(oldPos, dt);  // ゲーム領域とボールの衝突計算

    position.setFrom(newPos);
    _lastPosition = position.clone();
  }

  // ゲーム領域とボールの衝突計算
  // ※稀に衝突判定をすり抜ける為、callbackを使わずupdate毎に判定
  //   前フレームと現フレームで壁を跨る場合は、方角を反射し反転後の押し戻した座標を返却
  Vector2 _collisionPlayArea(Vector2 oldPos, double dt) {
    final moveVec = velocity * dt;
    Vector2 newPos = oldPos + moveVec;

    // --- 左の壁 ---
    if (newPos.x - radius < 0) {
      FlameAudio.play('Wall.mp3');
      double t = (radius - oldPos.x) / moveVec.x;    // 壁に当たるまでの比率を計算
      newPos = oldPos + moveVec * t;                 // 当たった位置に移動
      velocity.x = -velocity.x;                      // 反射
      newPos.x = radius + (1 - t) * velocity.x * dt; // 残りを進める
    }

    // --- 右の壁 ---
    else if (newPos.x + radius > game.width) {
      FlameAudio.play('Wall.mp3');
      double t = (game.width - radius - oldPos.x) / moveVec.x;
      newPos = oldPos + moveVec * t;
      velocity.x = -velocity.x;
      newPos.x = game.width - radius + (1 - t) * velocity.x * dt;
    }

    // --- 上の壁 ---
    else if (newPos.y - radius < 0) {
      FlameAudio.play('Wall.mp3');
      double t = (radius - oldPos.y) / moveVec.y;
      newPos = oldPos + moveVec * t;
      velocity.y = -velocity.y;
      newPos.y = radius + (1 - t) * velocity.y * dt;
    }

    // --- 下の壁 ---
    else if (newPos.y + radius > game.height) {
      // 反射計算無しでゲームオーバー処理
      add(
        RemoveEffect(
          delay: 0.35,
          onComplete: () => _gameOver(),
        ),
      );
    }

    return newPos;
  }

  void _gameOver() {
    FlameAudio.play('GameOver.mp3');
    game.playState = PlayState.gameOver;
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
      // update毎に交差判定する為、ここでは何も無し

    // バットと衝突した場合
    } else if (other is Bat) {
      FlameAudio.play('Bat.mp3');
      velocity.y = -velocity.y; // 縦方向はそのまま反転
      // 横方向はバットとボールの相対位置に応じて変化させる
      velocity.x =
          velocity.x +
          (position.x - other.position.x) / other.size.x * game.width * 0.3;
    // ブロックと衝突した場合
    } else if (other is Brick) {
      FlameAudio.play('Brick.mp3');
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
