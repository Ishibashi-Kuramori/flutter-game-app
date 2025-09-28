import 'dart:async';
import 'dart:math' as math;
import 'dart:html' as html;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart'; 
import 'package:flutter/services.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  final nameController = TextEditingController();
  final rand = math.Random(); // 乱数
  double get width => size.x;  // ゲーム画面幅
  double get height => size.y; // ゲーム画面高さ
  final FirebaseFirestore _firestore = FirebaseFirestore.instance; // Firestoreインスタンスを取得
  Future<String>? hightScoreStr; // ハイスコア文字列(非同期で値を取得する為Futureを使用)
  int lowScore = 0; // ハイスコア内の最低スコア

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
    // ローカルストレージの名前を取得
    final savedName = html.window.localStorage['playerName'];
    if (savedName != null && savedName.isNotEmpty) {
      nameController.text = savedName;
    }
    // ハイスコアを取得
    hightScoreStr = getHighScoresAsString();
    debugPrint('collision with $hightScoreStr');
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
    double spballRadius = ballRadius;
    if (nameController.text == spNameBig) spballRadius *= 6;
    if (nameController.text == spNameSmall) spballRadius /= 6;
    world.add(Ball(
      difficultyModifier: difficultyModifier,
      radius: spballRadius,
      position: size / 2, // 画面中央に配置
      velocity: Vector2(
          (rand.nextDouble() - 0.5) * width, // 左右ランダムな強度(方角)に移動
          height * 0.2 // 下方向に移動(マイナスだと上に行く)
        )
        .normalized()
        ..scale(height / 4))); // ボールの速度は、ゲームの高さの 1/4

    // ボールを追加(2個目)
    if (nameController.text == spNameDouble) {
    world.add(Ball(
      difficultyModifier: difficultyModifier,
      radius: spballRadius,
      position: size / 2, // 画面中央に配置
      velocity: Vector2(
          (rand.nextDouble() - 0.5) * width, // 左右ランダムな強度(方角)に移動
          height * -0.2 // 上方向に移動(マイナスだと上に行く)
        )
        .normalized()
        ..scale(height / 4))); // ボールの速度は、ゲームの高さの 1/4
    }

    // バットを追加
    double spbatWidth = batWidth;
    if (nameController.text == spNameLong) spbatWidth *= 2;
    if (nameController.text == spNameShort) spbatWidth /= 2;
    world.add(
      Bat(
        size: Vector2(spbatWidth, batHeight),
        cornerRadius: const Radius.circular(ballRadius / 2),
        position: Vector2(width / 2, height * 0.95), // 配置位置(中央下部)
      ),
    );

    // ブロックを追加
    world.addAll([
      for (var i = 0; i < brickColors.length; i++)
        for (var j = 1; j <= 9; j++)
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

  // ゲーム終了時の処理
  void gameEnd(bool isWin) async {

    // 名前が'reset'の場合はハイスコアを初期化
    if (nameController.text == spNameReset) {
      await initializeHighScores();
      // ハイスコア表示を更新
      hightScoreStr = getHighScoresAsString();
    } 
    
    // 特殊な名前以外の場合にハイスコア更新
    if (!spNames.contains(nameController.text)) {
      // ハイスコア更新時はスコアをFirebaseに送信
      if (score.value > lowScore) {
        await sendHighScores();
        // ハイスコア表示を更新
        hightScoreStr = getHighScoresAsString();
      }
      // 特殊な名前以外が入力されていたらローカルストレージに保存
      if (nameController.text.isNotEmpty) {
        html.window.localStorage['playerName'] = nameController.text;
      }
    }

    if (isWin) {
      // 効果音を鳴らして勝利画面表示
      FlameAudio.play('Win.mp3');
      playState = PlayState.won; // ステータスをwonに遷移
    } else {
      // 効果音を鳴らしてゲームオーバー画面表示
      FlameAudio.play('GameOver.mp3');
      playState = PlayState.gameOver;
    }
    // ボールを削除
    world.removeAll(world.children.query<Ball>());
  }

  // FirebaseからHightScore一覧を取得し、文字列加工して返却
  Future<String> getHighScoresAsString() async {
    try {
      // 'HightScore' コレクションからドキュメントをscore降順で最大5件取得する
      final QuerySnapshot querySnapshot = await _firestore.collection('HightScore')
        .orderBy('score', descending: true).get();
      // ドキュメントが一つもない場合は空文字列を返す
      if (querySnapshot.docs.isEmpty) {
        return '';
      }
      final List<String> rank = ['1st', '2nd', '3rd', '4th', '5th'];
      final List<String> scoreEntries = [];

      // タイトル部分を作成
      scoreEntries.add('');
      scoreEntries.add('    HIGH-SCORE');
      scoreEntries.add('');

      // 1位から5位までループ
      for (int i = 0; i < 5; i++) {
        String name = '';
        int score = 0;
        // 実際にドキュメントが存在するかチェック
        if (i < querySnapshot.docs.length) {
          final Map<String, dynamic> data = querySnapshot.docs[i].data() as Map<String, dynamic>;
          name = data['name'] as String? ?? '';
          score = data['score'] as int? ?? 0;
          // ランキングが5thまで有る場合は最低スコアを記録
          if (i == 4) lowScore = score;
        }
        // 名前が空文字の場合はNoNameを代入
        if(name.isEmpty) name = 'NoName';
        // ランキングを1行分生成
        scoreEntries.add('${rank[i]}: ${score.toString().padLeft(2, '0')} … $name ');
      }

      // 末尾に余白を入れる
      scoreEntries.add('');
      scoreEntries.add('');
      scoreEntries.add('');

      // リスト内の文字列を改行で結合して返す
      return scoreEntries.join('\n');
    } catch (e) {
      // エラーが発生した場合
      return 'GetHighScoresError';
    }
  }

  // ハイスコアの初期化
  Future<void> sendHighScores() async {
    try {
      await _firestore.collection('HightScore').add({
        'name': nameController.text,
        'score': score.value,
      });
    } catch (e) {
      debugPrint('sendHighScores(): $e');
    }
    return;
  }

  // ハイスコアの初期化
  Future<void> initializeHighScores() async {
    try {
      // コレクション内のすべてのドキュメントを取得
      final QuerySnapshot snap = await _firestore.collection('HightScore').get();
      if (snap.docs.isEmpty) return; // 既にドキュメントが無ければ終了
      // バッチ処理を作成
      final WriteBatch batch = _firestore.batch();
      // 各ドキュメントをバッチに追加して削除指示
      for (final doc in snap.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit(); // バッチをコミット
    } catch (e) {
      debugPrint('initializeHighScores(): $e');
    }
    return;
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
