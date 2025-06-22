import 'package:flame/components.dart';
import 'package:flame/collisions.dart';
import 'package:flutter/material.dart';
import 'package:game_warp/game/gravity_warp_game.dart';

class Boundary extends PositionComponent with HasGameRef<GravityWarpGame> {
  final Paint _paint = Paint()..color = Colors.grey.withOpacity(0.5);
  
  Boundary({
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    // Add solid hitbox to boundary
    final hitbox = RectangleHitbox(
      anchor: Anchor.center,
      position: Vector2.zero(),
      size: size,
    );
    
    add(hitbox);
  }
  
  @override
  void render(Canvas canvas) {
    super.render(canvas);
    
    // Draw boundary as a rectangle
    final rect = Rect.fromCenter(
      center: Offset.zero,
      width: size.x,
      height: size.y,
    );
    
    canvas.drawRect(rect, _paint);
  }
} 