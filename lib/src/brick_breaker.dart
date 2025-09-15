import 'dart:async';
import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart'; 
import 'package:flutter/services.dart';
import 'package:flame_audio/flame_audio.dart';

import 'components/components.dart';
import 'config.dart';

// ステータス定義
enum PlayState { welcome, playing, gameOver, won }

// ゲーム本体関連
class BrickBreaker extends FlameGame
  with HasCollisionDetection, // 衝突判定
    KeyboardEvents, // キー入力イベント
    TapDetector { // タップイベント
  BrickBreaker() : super(
    camera: CameraComponent.withFixedResolution(
      width: gameWidth,   // config.dartに定義したゲーム画面幅
      height: gameHeight, // config.dartに定義したゲーム画面高さ
    ),
  );

  final ValueNotifier<int> score = ValueNotifier(0); // スコア
  final rand = math.Random(); // 乱数
  double get width => size.x;  // ゲーム画面幅
  double get height => size.y; // ゲーム画面高さ

  // ステータスsetter/geter
  late PlayState _playState;
  PlayState get playState => _playState;
  set playState(PlayState playState) {
    _playState = playState;
    // セットしたステータスに応じて分岐
    switch (playState) {
      case PlayState.welcome:
      case PlayState.gameOver:
      case PlayState.won:
        // ステータスに応じたoverlayを上乗せ
        overlays.add(playState.name);
      case PlayState.playing:
        // overlayを削除
        overlays.remove(PlayState.welcome.name);
        overlays.remove(PlayState.gameOver.name);
        overlays.remove(PlayState.won.name);
    }
  }

  // ゲームロード時の処理
  @override
  FutureOr<void> onLoad() async {
    super.onLoad();

    // サウンド系のキャッシュ
    await FlameAudio.audioCache.loadAll(['Bat.mp3','Brick.mp3', 'GameOver.mp3', 'Start.mp3', 'Wall.mp3', 'Win.mp3']);

    // 座標(0,0)の起点を左上にセット(デフォは中央)
    camera.viewfinder.anchor = Anchor.topLeft;
    // ゲーム画面描画領域を配置
    world.add(PlayArea());
    // ステータスをwelcomeで初期化
    playState = PlayState.welcome;
  }

  // ゲーム開始時の処理
  void startGame() {
    // 既に開始中の場合は抜ける
    if (playState == PlayState.playing) return;

    FlameAudio.play('Start.mp3');

    // 既存のオブジェクトを除去
    world.removeAll(world.children.query<Ball>());
    world.removeAll(world.children.query<Bat>());
    world.removeAll(world.children.query<Brick>());

    // ステータスを開始中に変更
    playState = PlayState.playing;
    // スコアを初期化
    score.value = 0;

    // ボールを追加
    world.add(Ball(
      difficultyModifier: difficultyModifier,
      radius: ballRadius,
      position: size / 2, // 画面中央に配置
      velocity: Vector2(
          (rand.nextDouble() - 0.5) * width, // 左右ランダムな強度(方角)に移動
          height * 0.2 // 下方向に移動(マイナスだと上に行く)
        )
        .normalized()
        ..scale(height / 4))); // ボールの速度は、ゲームの高さの 1/4
    
    // バットを追加
    world.add(
      Bat(
        size: Vector2(batWidth, batHeight),
        cornerRadius: const Radius.circular(ballRadius / 2),
        position: Vector2(width / 2, height * 0.95), // 配置位置(中央下部)
      ),
    );

    // ブロックを追加
    world.addAll([
      for (var i = 0; i < brickColors.length; i++)
        for (var j = 1; j <= 5; j++)
          Brick(
            position: Vector2(
              (i + 0.5) * brickWidth + (i + 1) * brickGutter,
              (j + 2.0) * brickHeight + j * brickGutter,
            ),
            color: brickColors[i],
          ),
    ]);
    
    // デバッグONで座標情報が表示
    //debugMode = true;
  }

  // タップイベント処理
  @override
  void onTap() {
    super.onTap();
    // タップでゲーム開始
    startGame();
  }

  // キー入力イベント処理
  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    super.onKeyEvent(event, keysPressed);
    switch (event.logicalKey) {
      // 左キーで左移動
      case LogicalKeyboardKey.arrowLeft:
        world.children.query<Bat>().first.moveBy(-batStep);
      // 右キーで右移動
      case LogicalKeyboardKey.arrowRight:
        world.children.query<Bat>().first.moveBy(batStep);
      // スペースor改行でゲーム開始
      case LogicalKeyboardKey.space:
      case LogicalKeyboardKey.enter:
        startGame();
    }
    return KeyEventResult.handled;
  }

  // 領域内の色を定義
  @override
  Color backgroundColor() => const Color(0xfff2e8cf);
}
