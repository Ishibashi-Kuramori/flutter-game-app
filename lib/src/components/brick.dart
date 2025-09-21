import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../brick_breaker.dart';
import '../config.dart';

// ブロック関連の処理
class Brick extends RectangleComponent
  with CollisionCallbacks, // 衝突判定コールバックを使用
    HasGameReference<BrickBreaker> {
  Brick({required super.position, required Color color})
    : super(
        size: Vector2(brickWidth, brickHeight),
        anchor: Anchor.center,
        paint: Paint()
          ..color = color
          ..style = PaintingStyle.fill,
        children: [RectangleHitbox()],
      );

  // 衝突判定コールバック(ボールと接触時)
  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    removeFromParent(); // 自身を削除
    game.score.value++; // スコア+1

    // 最後のブロックと接触時
    if (game.world.children.query<Brick>().length == 1) {
      game.gameEnd(true);
    }
  }
}