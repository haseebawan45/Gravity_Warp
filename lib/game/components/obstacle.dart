import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:game_warp/game/gravity_warp_game.dart';

class Obstacle extends PositionComponent with HasGameRef<GravityWarpGame> {
  Vector2 velocity;
  final Paint _paint = Paint()..color = Colors.redAccent;
  final Paint _glowPaint = Paint()..color = Colors.redAccent.withOpacity(0.3);
  final Random _random = Random();
  double _rotationSpeed;
  double _pulseFactor = 0;
  double _pulseDirection = 1;
  
  Obstacle({
    required Vector2 position,
    required Vector2 size,
    required this.velocity,
    double rotation = 0,
  }) : 
    _rotationSpeed = (Random().nextDouble() - 0.5) * 3,
    super(position: position, size: size, angle: rotation);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    final hitbox = RectangleHitbox(
      anchor: Anchor.center,
      position: size / 2,
      size: size * 0.8, // Slightly smaller hitbox for better gameplay
    );
    add(hitbox);
    
    // Add trailing particles
    add(
      TimerComponent(
        period: 0.05,
        repeat: true,
        onTick: _emitTrailParticle,
      ),
    );
  }
  
  void _emitTrailParticle() {
    final trailParticle = ParticleSystemComponent(
      position: Vector2(size.x / 2, size.y / 2),
      particle: Particle.generate(
        count: 1,
        lifespan: 0.5,
        generator: (i) {
          final colors = [
            Colors.redAccent.withOpacity(0.7),
            Colors.orange.withOpacity(0.5),
            Colors.yellow.withOpacity(0.3),
          ];
          
          return AcceleratedParticle(
            acceleration: Vector2.zero(),
            speed: Vector2.zero(),
            position: Vector2.zero(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final color = colors[(particle.progress * colors.length).floor().clamp(0, colors.length - 1)];
                final paint = Paint()..color = color.withOpacity(1 - particle.progress);
                final radius = size.x * 0.4 * (1 - particle.progress);
                canvas.drawCircle(Offset.zero, radius, paint);
              },
            ),
          );
        },
      ),
    );
    
    gameRef.add(trailParticle..position = position + Vector2(size.x / 2, size.y / 2));
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update position based on velocity
    position += velocity * dt;
    
    // Rotate the obstacle
    angle += _rotationSpeed * dt;
    
    // Pulse effect
    _pulseFactor += dt * _pulseDirection * 2;
    if (_pulseFactor > 0.3) {
      _pulseDirection = -1;
    } else if (_pulseFactor < 0) {
      _pulseDirection = 1;
    }
    
    // Check if obstacle is outside of the screen
    if (position.x < -size.x ||
        position.x > gameRef.gameWidth + size.x ||
        position.y < -size.y ||
        position.y > gameRef.gameHeight + size.y) {
      removeFromParent();
    }
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Save the canvas state
    canvas.save();
    
    // Move to center for rotation
    final centerX = size.x / 2;
    final centerY = size.y / 2;
    canvas.translate(centerX, centerY);
    
    // Draw glow effect
    final glowSize = size.x / 2 + 5 + _pulseFactor * 3;
    canvas.drawCircle(
      Offset.zero,
      glowSize,
      _glowPaint,
    );
    
    // Draw obstacle as a custom shape
    final path = Path();
    final triangleSize = size.x / 2;
    
    // Draw a spiked shape
    final numSpikes = 3;
    final angleStep = 2 * pi / numSpikes;
    final innerRadius = triangleSize * 0.5;
    final outerRadius = triangleSize;
    
    for (int i = 0; i < numSpikes * 2; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final currAngle = i * angleStep / 2;
      final x = cos(currAngle) * radius;
      final y = sin(currAngle) * radius;
      
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    
    path.close();
    
    // Draw the shape with a gradient
    final gradient = RadialGradient(
      colors: [Colors.red, Colors.redAccent, Colors.orange],
      stops: const [0.0, 0.7, 1.0],
      radius: 0.8,
    );
    
    final rect = Rect.fromCircle(center: Offset.zero, radius: outerRadius);
    final paint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.fill;
    
    canvas.drawPath(path, paint);
    
    // Draw a glowing outline
    final outlinePaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    canvas.drawPath(path, outlinePaint);
    
    // Restore canvas state
    canvas.restore();
  }
} 