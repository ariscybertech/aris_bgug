import 'dart:ui';
import 'dart:math' as math;

import 'package:flame/animation.dart';
import 'package:flame/components/animation_component.dart';
import 'package:flame/components/mixins/has_game_ref.dart';
import 'package:flame/components/mixins/resizable.dart';
import 'package:flame/position.dart';

import '../constants.dart';
import '../game.dart';

abstract class Obstacle extends AnimationComponent with HasGameRef<BgugGame>, Resizable {
  Obstacle(double x, String texture) : super(16.0, 16.0, Animation.sequenced(texture, 3, textureWidth: 16.0, textureHeight: 16.0)..stepTime = 0.075) {
    this.x = x;
  }

  @override
  void resize(Size size) {
    super.resize(size);
    width = height = sizeTenth(size);
  }

  @override
  void update(double t) {
    super.update(t);
    final player = gameRef.player;
    if (toRect().overlaps(player.toRect())) {
      if (player.velocity.x.abs() >= player.velocity.y.abs()) {
        player.x = x - player.width;
      } else if (player.y > size.height / 2) {
        player.y = y - player.height;
        player.angle = math.pi / 2;
      } else {
        player.y = y + height;
        player.angle = 3 * math.pi / 2;
      }
      player.velocity = Position(0.0, 0.0);
      player.die();
    }
  }
}

class UpObstacle extends Obstacle {
  UpObstacle(double x) : super(x, 'up_obstacle.png');

  @override
  void resize(Size size) {
    super.resize(size);
    y = sizeTop(size);
  }
}

class DownObstacle extends Obstacle {
  DownObstacle(double x) : super(x, 'obstacle.png');

  @override
  void resize(Size size) {
    super.resize(size);
    y = sizeBottom(size) - height;
  }
}
