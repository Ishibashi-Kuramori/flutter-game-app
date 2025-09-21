import 'package:flutter/material.dart';

// ブロックの配色
const brickColors = [
  Color(0xfff94144),
  Color(0xfff3722c),
  Color(0xfff8961e),
  Color(0xfff9844a),
  Color(0xfff9c74f),
  Color(0xff90be6d),
  Color(0xff43aa8b),
  Color(0xff4d908e),
  Color(0xff277da1),
  Color(0xff577590),
];

// ゲーム画面描画領域
const gameWidth = 820.0;
const gameHeight = 1600.0;

const ballRadius = gameWidth * 0.02; // ボールの半径
const batWidth = gameWidth * 0.2; // バットの幅
const batHeight = ballRadius * 2; // バットの高さ
const batStep = gameWidth * 0.05; // キー入力時のバット移動距離

const brickGutter = gameWidth * 0.015; // ブロック間の隙間
// ブロックの幅
final brickWidth =
    (gameWidth - (brickGutter * (brickColors.length + 1))) / brickColors.length;
const brickHeight = gameHeight * 0.03; // ブロックの高さ
const difficultyModifier = 1.06; // ボールの速度上昇量