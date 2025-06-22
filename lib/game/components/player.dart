import 'dart:math';
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';
import 'package:game_warp/game/gravity_warp_game.dart';
import 'package:game_warp/game/components/obstacle.dart';

class Player extends PositionComponent with CollisionCallbacks, HasGameRef<GravityWarpGame> {
  Vector2 velocity = Vector2.zero();
  final Paint _paint = Paint()..color = Colors.cyan;
  final Paint _glowPaint = Paint()..color = Colors.cyan.withOpacity(0.3);
  late final ShapeHitbox hitbox;
  final Random _random = Random();
  
  // Trail effect properties
  final List<Vector2> _positionHistory = [];
  final int _maxTrailLength = 10;
  
  // Particle component for effects
  late final ParticleSystemComponent _particleSystem;
  
  Player({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    hitbox = CircleHitbox(
      radius: size.x / 2,
      anchor: Anchor.center,
      position: size / 2,
    );
    add(hitbox);
    
    // Initialize particle system
    _particleSystem = ParticleSystemComponent(
      particle: Particle.generate(
        count: 0,
        lifespan: 1,
        generator: (i) => AcceleratedParticle(
          acceleration: Vector2(0, 0),
          speed: Vector2(0, 0),
          position: Vector2.zero(),
          child: CircleParticle(
            radius: 1,
            paint: Paint()..color = Colors.cyan,
          ),
        ),
      ),
    );
    add(_particleSystem);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    // Update position based on velocity
    position += velocity;
    
    // Check boundaries
    if (position.x < 0) position.x = 0;
    if (position.x > gameRef.gameWidth - size.x) position.x = gameRef.gameWidth - size.x;
    if (position.y < 0) position.y = 0;
    if (position.y > gameRef.gameHeight - size.y) position.y = gameRef.gameHeight - size.y;
    
    // Update trail positions
    if (velocity.length > 0) {
      _positionHistory.insert(0, Vector2(position.x + size.x / 2, position.y + size.y / 2));
      
      if (_positionHistory.length > _maxTrailLength) {
        _positionHistory.removeLast();
      }
      
      // Add movement particles
      _emitMovementParticles();
    }
  }
  
  void _emitMovementParticles() {
    final center = Vector2(size.x / 2, size.y / 2);
    final worldCenter = Vector2(position.x + center.x, position.y + center.y);
    
    // Create particle effect based on current gravity direction
    final colors = [
      Colors.cyan.withOpacity(0.7),
      Colors.blue.withOpacity(0.5),
      Colors.white.withOpacity(0.3),
    ];
    
    // Generate particles in the opposite direction of movement
    Vector2 particleDirection;
    switch (gameRef.gravityDirection) {
      case GravityDirection.up:
        particleDirection = Vector2(0, 1);
        break;
      case GravityDirection.down:
        particleDirection = Vector2(0, -1);
        break;
      case GravityDirection.left:
        particleDirection = Vector2(1, 0);
        break;
      case GravityDirection.right:
        particleDirection = Vector2(-1, 0);
        break;
    }
    
    final effect = ParticleSystemComponent(
      position: worldCenter,
      particle: Particle.generate(
        count: 2,
        lifespan: 0.5,
        generator: (i) {
          final randomOffset = Vector2(
            _random.nextDouble() * 10 - 5,
            _random.nextDouble() * 10 - 5,
          );
          
          return AcceleratedParticle(
            acceleration: particleDirection * 5,
            speed: particleDirection * (20 + _random.nextDouble() * 20) + randomOffset,
            position: Vector2.zero(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final color = colors[(particle.progress * colors.length).floor().clamp(0, colors.length - 1)];
                final paint = Paint()..color = color;
                final radius = 3 * (1 - particle.progress);
                canvas.drawCircle(Offset.zero, radius, paint);
              },
            ),
          );
        },
      ),
    );
    
    gameRef.add(effect);
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw trail
    if (_positionHistory.isNotEmpty) {
      final path = Path();
      path.moveTo(_positionHistory[0].x - position.x, _positionHistory[0].y - position.y);
      
      for (int i = 1; i < _positionHistory.length; i++) {
        path.lineTo(_positionHistory[i].x - position.x, _positionHistory[i].y - position.y);
      }
      
      final trailPaint = Paint()
        ..color = Colors.cyan.withOpacity(0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8
        ..strokeCap = StrokeCap.round;
      
      canvas.drawPath(path, trailPaint);
    }
    
    // Draw glow effect
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2 + 5,
      _glowPaint,
    );
    
    // Draw player as a circle
    canvas.drawCircle(
      Offset(size.x / 2, size.y / 2),
      size.x / 2,
      _paint,
    );
    
    // Draw direction indicator based on current gravity
    final indicatorPaint = Paint()..color = Colors.white;
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x / 2;
    
    switch (gameRef.gravityDirection) {
      case GravityDirection.up:
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy - radius * 0.5),
            width: radius * 0.4,
            height: radius * 0.4,
          ),
          indicatorPaint,
        );
        break;
      case GravityDirection.down:
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(center.dx, center.dy + radius * 0.5),
            width: radius * 0.4,
            height: radius * 0.4,
          ),
          indicatorPaint,
        );
        break;
      case GravityDirection.left:
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(center.dx - radius * 0.5, center.dy),
            width: radius * 0.4,
            height: radius * 0.4,
          ),
          indicatorPaint,
        );
        break;
      case GravityDirection.right:
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset(center.dx + radius * 0.5, center.dy),
            width: radius * 0.4,
            height: radius * 0.4,
          ),
          indicatorPaint,
        );
        break;
    }
  }
  
  void updateDirection(GravityDirection direction) {
    // Reset velocity when changing direction
    velocity = Vector2.zero();
    
    // Clear trail when changing direction
    _positionHistory.clear();
  }
  
  @override
  void onCollisionStart(
    Set<Vector2> intersectionPoints,
    PositionComponent other,
  ) {
    super.onCollisionStart(intersectionPoints, other);
    
    // If collided with obstacle, game over
    if (other is Obstacle) {
      // Create explosion effect
      _createExplosionEffect();
      gameRef.gameOver();
    }
  }
  
  void _createExplosionEffect() {
    final center = Vector2(position.x + size.x / 2, position.y + size.y / 2);
    
    final explosion = ParticleSystemComponent(
      position: center,
      particle: Particle.generate(
        count: 50,
        lifespan: 0.8,
        generator: (i) {
          final speed = Vector2(
            _random.nextDouble() * 200 - 100,
            _random.nextDouble() * 200 - 100,
          );
          
          final colors = [
            Colors.white,
            Colors.cyan,
            Colors.blue,
            Colors.redAccent,
          ];
          
          return AcceleratedParticle(
            acceleration: Vector2(0, 0),
            speed: speed,
            position: Vector2.zero(),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final color = colors[(particle.progress * colors.length).floor().clamp(0, colors.length - 1)];
                final paint = Paint()..color = color.withOpacity(1 - particle.progress);
                final radius = 5 * (1 - particle.progress);
                canvas.drawCircle(Offset.zero, radius, paint);
              },
            ),
          );
        },
      ),
    );
    
    gameRef.add(explosion);
  }
} 