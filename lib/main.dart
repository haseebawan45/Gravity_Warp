import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/game.dart';
import 'package:game_warp/game/gravity_warp_game.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set preferred orientations to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    // Use system UI overlay style
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
    
    runApp(const MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gravity Warp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.cyan,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    );
  }
}

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final game = GravityWarpGame();
    
    return Scaffold(
      body: GameWidget(
        game: game,
        overlayBuilderMap: {
          'gameOver': (context, _) => GameOverOverlay(game: game),
          'mainMenu': (context, _) => MainMenuOverlay(game: game),
          'pauseMenu': (context, _) => PauseMenuOverlay(game: game),
          'gameUI': (context, _) => GameUIOverlay(game: game),
        },
        initialActiveOverlays: const ['mainMenu'],
      ),
    );
  }
}

class MainMenuOverlay extends StatelessWidget {
  final GravityWarpGame game;

  const MainMenuOverlay({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'GRAVITY WARP',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.cyan,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 50),
          ElevatedButton(
            onPressed: () {
              game.startGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              'START GAME',
              style: TextStyle(fontSize: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class GameOverOverlay extends StatelessWidget {
  final GravityWarpGame game;

  const GameOverOverlay({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'GAME OVER',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Score: ${game.score.toInt()}',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              game.resetGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              'PLAY AGAIN',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class PauseMenuOverlay extends StatelessWidget {
  final GravityWarpGame game;

  const PauseMenuOverlay({
    super.key,
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'PAUSED',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              game.resumeGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.cyan,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              'RESUME',
              style: TextStyle(fontSize: 18),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () {
              game.resetGame();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            ),
            child: const Text(
              'MAIN MENU',
              style: TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class GameUIOverlay extends StatelessWidget {
  final GravityWarpGame game;

  const GameUIOverlay({
    super.key, 
    required this.game,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              ValueListenableBuilder(
                valueListenable: game.scoreNotifier,
                builder: (context, value, child) {
                  return Text(
                    'Score: ${value.toInt()}',
                    style: const TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.pause, color: Colors.white),
                onPressed: () {
                  game.pauseGame();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
