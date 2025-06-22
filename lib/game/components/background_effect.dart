import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:game_warp/game/gravity_warp_game.dart';

class BackgroundParticle extends PositionComponent {
  final Paint _paint;
  double _speed;
  final double _size;
  final double _maxAlpha;
  double _alpha;
  final Random _random = Random();
  
  BackgroundParticle({
    required Vector2 position,
    required Color color,
    required double speed,
    required double size,
    required double alpha,
  }) : 
    _paint = Paint()..color = color,
    _speed = speed,
    _size = size,
    _maxAlpha = alpha,
    _alpha = alpha,
    super(position: position, size: Vector2.all(size));
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Pulse effect - make particles fade in and out
    _alpha += _random.nextDouble() * 0.1 * (_random.nextBool() ? 1 : -1);
    if (_alpha < 0.1) _alpha = 0.1;
    if (_alpha > _maxAlpha) _alpha = _maxAlpha;
    
    _paint.color = _paint.color.withOpacity(_alpha);
    
    // Slow movement
    position.y += _speed * dt;
    position.x += sin(position.y / 50) * dt * 10;
    
    // Loop back to top when reaching bottom
    if (position.y > 1000) {
      position.y = -_size;
      position.x = _random.nextDouble() * 500;
    }
  }
  
  @override
  void render(Canvas canvas) {
    canvas.drawCircle(
      Offset(_size / 2, _size / 2),
      _size / 2,
      _paint,
    );
  }
}

class BackgroundEffect extends Component with HasGameRef<GravityWarpGame> {
  final List<BackgroundParticle> _particles = [];
  final Random _random = Random();
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Create particles with different colors, sizes, and speeds
    final colors = [
      Colors.cyan.withOpacity(0.3),
      Colors.blue.withOpacity(0.3),
      Colors.purple.withOpacity(0.3),
      Colors.teal.withOpacity(0.3),
    ];
    
    for (int i = 0; i < 50; i++) {
      final color = colors[_random.nextInt(colors.length)];
      final size = _random.nextDouble() * 6 + 2;
      final speed = _random.nextDouble() * 20 + 5;
      final alpha = _random.nextDouble() * 0.5 + 0.1;
      
      final particle = BackgroundParticle(
        position: Vector2(
          _random.nextDouble() * gameRef.gameWidth,
          _random.nextDouble() * gameRef.gameHeight,
        ),
        color: color,
        speed: speed,
        size: size,
        alpha: alpha,
      );
      
      _particles.add(particle);
      add(particle);
    }
  }
  
  void updateGravityEffect(GravityDirection direction) {
    for (final particle in _particles) {
      switch (direction) {
        case GravityDirection.up:
          particle._speed = -particle._speed.abs();
          break;
        case GravityDirection.down:
          particle._speed = particle._speed.abs();
          break;
        case GravityDirection.left:
          // Make particles move left
          particle._speed = particle._speed.abs() * 0.5;
          break;
        case GravityDirection.right:
          // Make particles move right
          particle._speed = particle._speed.abs() * 0.5;
          break;
      }
    }
  }
} 