import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:game_warp/game/components/player.dart';
import 'package:game_warp/game/components/obstacle.dart';
import 'package:game_warp/game/components/boundary.dart';
import 'package:game_warp/game/components/background_effect.dart';

enum GravityDirection { up, down, left, right }
enum GameState { initializing, playing, paused, gameOver }

class GravityWarpGame extends FlameGame with HasCollisionDetection {
  // Game components
  late Player player;
  late BackgroundEffect backgroundEffect;
  final Random _random = Random();
  
  // Game properties
  double gameWidth = 0;
  double gameHeight = 0;
  double difficulty = 1.0;
  double timeSurvived = 0;
  double score = 0;
  double obstacleSpawnRate = 2.0; // seconds between spawns
  double timeSinceLastObstacle = 0;
  double timeSinceLastDifficultyIncrease = 0;
  
  // Visual effects
  late final CameraComponent gameCamera;
  bool _isShaking = false;
  
  // Game state
  GameState _gameState = GameState.initializing;
  GravityDirection gravityDirection = GravityDirection.down;
  final ValueNotifier<double> scoreNotifier = ValueNotifier(0);
  final ValueNotifier<int> highScoreNotifier = ValueNotifier(0);
  int highScore = 0;
  
  @override
  Color backgroundColor() => const Color(0xFF0A0A1F); // Dark blue background
  
  @override
  Future<void> onLoad() async {
    await super.onLoad();
    
    gameWidth = size.x;
    gameHeight = size.y;
    
    // Add camera
    gameCamera = CameraComponent(world: world)
      ..viewfinder.anchor = Anchor.topLeft;
    add(gameCamera);
    
    // Add background effect
    backgroundEffect = BackgroundEffect();
    add(backgroundEffect);
    
    // Add boundaries with glow effect
    final boundaries = [
      Boundary(
        position: Vector2(gameWidth / 2, 0),
        size: Vector2(gameWidth, 10),
      ),
      Boundary(
        position: Vector2(gameWidth / 2, gameHeight),
        size: Vector2(gameWidth, 10),
      ),
      Boundary(
        position: Vector2(0, gameHeight / 2),
        size: Vector2(10, gameHeight),
      ),
      Boundary(
        position: Vector2(gameWidth, gameHeight / 2),
        size: Vector2(10, gameHeight),
      ),
    ];
    
    for (final boundary in boundaries) {
      add(boundary);
    }
    
    // Add player
    player = Player(
      position: Vector2(gameWidth / 2, gameHeight / 2),
      size: Vector2(30, 30),
    );
    add(player);
  }
  
  @override
  void update(double dt) {
    super.update(dt);
    
    if (_gameState != GameState.playing) return;
    
    // Update game time
    timeSurvived += dt;
    score = timeSurvived * 10;
    scoreNotifier.value = score;
    
    // Increase difficulty over time
    timeSinceLastDifficultyIncrease += dt;
    if (timeSinceLastDifficultyIncrease >= 10) {
      timeSinceLastDifficultyIncrease = 0;
      difficulty += 0.2;
      
      // Visual feedback for difficulty increase
      _pulseBackground();
    }
    
    // Apply gravity to player
    applyGravity(dt);
    
    // Spawn obstacles
    timeSinceLastObstacle += dt;
    if (timeSinceLastObstacle >= obstacleSpawnRate / difficulty) {
      spawnObstacle();
      timeSinceLastObstacle = 0;
    }
  }
  
  void _pulseBackground() {
    // Add a quick pulse effect to the camera
    if (!_isShaking) {
      _isShaking = true;
      gameCamera.viewfinder.add(
        SequenceEffect([
          ScaleEffect.to(
            Vector2.all(1.05),
            EffectController(duration: 0.1),
          ),
          ScaleEffect.to(
            Vector2.all(1.0),
            EffectController(duration: 0.1),
          ),
        ], onComplete: () => _isShaking = false),
      );
    }
  }
  
  void applyGravity(double dt) {
    final gravityStrength = 300.0 * dt;
    
    switch (gravityDirection) {
      case GravityDirection.up:
        player.velocity.y = -gravityStrength;
        break;
      case GravityDirection.down:
        player.velocity.y = gravityStrength;
        break;
      case GravityDirection.left:
        player.velocity.x = -gravityStrength;
        break;
      case GravityDirection.right:
        player.velocity.x = gravityStrength;
        break;
    }
  }
  
  void changeGravity(GravityDirection direction) {
    if (_gameState != GameState.playing) return;
    
    // Only change if it's a different direction
    if (gravityDirection == direction) return;
    
    gravityDirection = direction;
    player.updateDirection(direction);
    
    // Update background particle effect
    backgroundEffect.updateGravityEffect(direction);
    
    // Add a small camera shake for feedback
    if (!_isShaking) {
      _isShaking = true;
      gameCamera.viewfinder.add(
        SequenceEffect([
          MoveByEffect(
            Vector2(_random.nextDouble() * 10 - 5, _random.nextDouble() * 10 - 5),
            EffectController(duration: 0.1),
          ),
          MoveByEffect(
            Vector2(_random.nextDouble() * 10 - 5, _random.nextDouble() * 10 - 5),
            EffectController(duration: 0.1),
          ),
          MoveByEffect(
            Vector2(0, 0),
            EffectController(duration: 0.1),
          ),
        ], onComplete: () => _isShaking = false),
      );
    }
  }
  
  void spawnObstacle() {
    // Determine entry point and direction
    final side = _random.nextInt(4); // 0: top, 1: right, 2: bottom, 3: left
    Vector2 position;
    Vector2 velocity;
    double rotation = 0;
    
    switch (side) {
      case 0: // top
        position = Vector2(
          _random.nextDouble() * gameWidth,
          0,
        );
        velocity = Vector2(
          _random.nextDouble() * 100 - 50,
          _random.nextDouble() * 100 + 100,
        );
        rotation = pi;
        break;
      case 1: // right
        position = Vector2(
          gameWidth,
          _random.nextDouble() * gameHeight,
        );
        velocity = Vector2(
          -(_random.nextDouble() * 100 + 100),
          _random.nextDouble() * 100 - 50,
        );
        rotation = pi * 1.5;
        break;
      case 2: // bottom
        position = Vector2(
          _random.nextDouble() * gameWidth,
          gameHeight,
        );
        velocity = Vector2(
          _random.nextDouble() * 100 - 50,
          -(_random.nextDouble() * 100 + 100),
        );
        rotation = 0;
        break;
      case 3: // left
        position = Vector2(
          0,
          _random.nextDouble() * gameHeight,
        );
        velocity = Vector2(
          _random.nextDouble() * 100 + 100,
          _random.nextDouble() * 100 - 50,
        );
        rotation = pi * 0.5;
        break;
      default:
        position = Vector2.zero();
        velocity = Vector2.zero();
        break;
    }
    
    // Scale velocity by difficulty
    velocity *= difficulty;
    
    // Add obstacle
    add(
      Obstacle(
        position: position,
        rotation: rotation,
        size: Vector2(20, 20),
        velocity: velocity,
      ),
    );
  }
  
  void startGame() {
    _gameState = GameState.playing;
    resetGame();
    overlays.remove('mainMenu');
    overlays.add('gameUI');
  }
  
  void resetGame() {
    score = 0;
    timeSurvived = 0;
    difficulty = 1.0;
    timeSinceLastObstacle = 0;
    timeSinceLastDifficultyIncrease = 0;
    scoreNotifier.value = 0;
    
    // Reset game state
    _gameState = GameState.playing;
    gravityDirection = GravityDirection.down;
    
    // Reset camera
    gameCamera.viewfinder.position = Vector2.zero();
    gameCamera.viewfinder.zoom = 1.0;
    
    // Clear all obstacles
    children.whereType<Obstacle>().forEach((obstacle) => obstacle.removeFromParent());
    
    // Reset player position
    player.position = Vector2(gameWidth / 2, gameHeight / 2);
    player.velocity = Vector2.zero();
    player.updateDirection(GravityDirection.down);
    
    // Remove overlays
    overlays.remove('mainMenu');
    overlays.remove('gameOver');
    overlays.remove('pauseMenu');
    overlays.add('gameUI');
  }
  
  void gameOver() {
    _gameState = GameState.gameOver;
    
    // Update high score
    if (score > highScore) {
      highScore = score.toInt();
      highScoreNotifier.value = highScore;
    }
    
    // Add a camera shake for game over
    if (!_isShaking) {
      _isShaking = true;
      gameCamera.viewfinder.add(
        SequenceEffect([
          MoveByEffect(
            Vector2(10, 10),
            EffectController(duration: 0.1),
          ),
          MoveByEffect(
            Vector2(-20, -20),
            EffectController(duration: 0.1),
          ),
          MoveByEffect(
            Vector2(10, 10),
            EffectController(duration: 0.1),
          ),
        ], onComplete: () => _isShaking = false),
      );
    }
    
    overlays.remove('gameUI');
    overlays.add('gameOver');
  }
  
  void pauseGame() {
    if (_gameState == GameState.playing) {
      _gameState = GameState.paused;
      overlays.remove('gameUI');
      overlays.add('pauseMenu');
      paused = true;
    }
  }
  
  void resumeGame() {
    if (_gameState == GameState.paused) {
      _gameState = GameState.playing;
      overlays.remove('pauseMenu');
      overlays.add('gameUI');
      paused = false;
    }
  }
} 