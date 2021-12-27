import 'dart:math' as math;

import 'package:flame/animation.dart' as animation;
import 'package:flame/components/animation_component.dart';
import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';

class _SkinComponent extends AnimationComponent {
  _SkinComponent(String skin) : super(
      1.0,
      1.0,
      animation.Animation.sequenced('skins/$skin', 8, textureWidth: 16.0, textureHeight: 16.0));

  @override
  void resize(Size size) {
    final fracByWidth = size.width / 16.0;
    final fracByHeight = size.height / 18.0;
    final frac = math.min(fracByWidth, fracByHeight);

    width = frac * 16.0;
    height = frac * 18.0;

    x = (size.width - width) / 2;
    y = (size.height - height) / 2;
  }
}

class _SkinWidgetGame extends BaseGame {
  _SkinWidgetGame(String skin) {
    add(_SkinComponent(skin));
  }

  @override
  Color backgroundColor() => const Color(0x00FFFFFF);
}

class SkinWidget extends StatefulWidget {
  final String skin;

  SkinWidget(this.skin);

  @override
  State<StatefulWidget> createState() => _SkinWidgetState(skin);
}

class _SkinWidgetState extends State<SkinWidget> {
  final _SkinWidgetGame game;

  _SkinWidgetState(String skin) : game = _SkinWidgetGame(skin);

  @override
  Widget build(BuildContext context) {
    return game.widget;
  }
}
