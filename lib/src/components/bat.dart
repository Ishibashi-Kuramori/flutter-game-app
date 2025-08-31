import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../brick_breaker.dart';

// バット関連
class Bat extends PositionComponent 
  with DragCallbacks, // ドラッグコールバック使用
    HasGameReference<BrickBreaker> {
  Bat({
    required this.cornerRadius,
    required super.position,
    required super.size,
  }) : super(
    anchor: Anchor.center,
    children: [RectangleHitbox()]
  );

  final Radius cornerRadius;

  final _paint = Paint()
    ..color = const Color(0xff1e6091)
    ..style = PaintingStyle.fill;

  // RectangleComponent,CircleComponentではないのでrenderで描画する必要アリ
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    canvas.drawRRect( // 丸い長方形を描画
      RRect.fromRectAndRadius(Offset.zero & size.toSize(), cornerRadius),
      _paint,
    );
  }

  // ドラッグ操作コールバック
  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    position.x = (position.x + event.localDelta.x).clamp(0, game.width);
  }

  // キーボード操作による移動(brick_breaker.dartからcall)
  void moveBy(double dx) {
    add(
      MoveToEffect(
        Vector2((position.x + dx).clamp(0, game.width), position.y),
        EffectController(duration: 0.1),
      ),
    );
  }
}