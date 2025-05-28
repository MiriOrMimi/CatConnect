import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// === POSIZIONE GRIGLIA ===
class Position {
  final int x;
  final int y;
  Position(this.x, this.y);
  bool equals(Position other) => x == other.x && y == other.y;
}

// === GIOCO PRINCIPALE ===
class SnakeGame extends StatefulWidget {
  const SnakeGame({super.key});
  @override
  State<SnakeGame> createState() => _SnakeGameState();
}

enum Direction { up, down, left, right }

class _SnakeGameState extends State<SnakeGame> {
  static const int rowSize = 10;
  static const Duration tickRate = Duration(milliseconds: 300);
  List<Position> snake = [Position(5, 5)];
  Direction direction = Direction.right;
  Position food = Position(7, 5);
  Timer? timer;
  int score = 0;
  bool gameOver = false;
  var topScores = [];
  var userID;
  var errore = 'arrivato';

  final String catEmoji = '🐱';
  final String foodEmoji = '🥫';

  @override
  void initState() {
    super.initState();
    startGame();
  }

  // === AVVIA GIOCO ===
  void startGame() {
    timer?.cancel();
    timer = Timer.periodic(tickRate, (_) => updateSnake());
  }

  // === GENERA CROCCHETTA ===
  void generateFood() {
    Random rand = Random();
    Position newFood;
    do {
      newFood = Position(rand.nextInt(rowSize), rand.nextInt(rowSize));
    } while (snake.any((s) => s.equals(newFood)));
    setState(() => food = newFood);
  }

  // === AGGIORNA POSIZIONE ===
  void updateSnake() {
    Position newHead;
    Position current = snake.first;

    switch (direction) {
      case Direction.up:
        newHead = Position(current.x, (current.y - 1 + rowSize) % rowSize);
        break;
      case Direction.down:
        newHead = Position(current.x, (current.y + 1) % rowSize);
        break;
      case Direction.left:
        newHead = Position((current.x - 1 + rowSize) % rowSize, current.y);
        break;
      case Direction.right:
        newHead = Position((current.x + 1) % rowSize, current.y);
        break;
    }

    if (snake.any((s) => s.equals(newHead))) {
      timer?.cancel();
      _GameOver();
      return;
    }

    setState(() {
      snake.insert(0, newHead);
      if (newHead.equals(food)) {
        score++;
        generateFood();
      } else {
        snake.removeLast();
      }
    });
  }

  // === CAMBIA DIREZIONE ===
  void changeDirection(Direction newDirection) {
    if ((direction == Direction.left && newDirection != Direction.right) ||
        (direction == Direction.right && newDirection != Direction.left) ||
        (direction == Direction.up && newDirection != Direction.down) ||
        (direction == Direction.down && newDirection != Direction.up)) {
      setState(() => direction = newDirection);
    }
  }

  // === DIALOG FINE GIOCO ===
  void _GameOver() async {
    setState(() {
      gameOver = true;
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) {
      setState(() {
        print('Non trovato il token. Effettua il login.');
      });
      return;
    }

    try {
      final response = await http.get(
        Uri.parse('https://catconnect-7yg6.onrender.com/api/auth/me'),
        headers: {'Authorization': token},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['id'] != null) {
          setState(() {
            userID = data['id'];
          });
        }
      }
    } catch (e) {
      setState(() {
        errore = 'erroraccio';
      });
    }

    final response = await http.post(
      Uri.parse('https://catconnect-7yg6.onrender.com/api/auth/addScore'),
      body: json.encode({'user': userID, 'score': score}),
      headers: {'Content-Type': 'application/json'},
    );

    setState(() {
      errore = 'passato1';
    });
    if (response.statusCode == 200) {
      setState(() {
        errore = 'passato2';
      });
      final res =
          await http.get(Uri.parse('https://catconnect-7yg6.onrender.com/api/auth/getScores'));

      setState(() {
        errore = 'passato3';
      });

      if (res.statusCode == 200) {
        try {
          final data = json.decode(
              res.body); // Decodifica la risposta JSON in una lista di mappe.

          if (data != null && data.isNotEmpty) {
            // Crea una lista di oggetti con i punteggi, ad esempio:
            List<Map<String, dynamic>> scoresList =
                List<Map<String, dynamic>>.from(data);

            setState(() {
              topScores =
                  scoresList; // Aggiorna lo stato con la lista dei punteggi
            });
          } else {
            print('Nessuna classifica trovata.');
          }
        } catch (e) {
          print('Errore nel parsing dei dati: $e');
        }
      } else {
        print('Errore nel recupero della classifica: ${res.statusCode}');
        print('Response body: ${res.body}');
      }
    }
  }

  // === RIAVVIA GIOCO ===
  void _restartGame() {
  setState(() {
    snake = [Position(5, 5)];
    direction = Direction.right;
    score = 0;
    gameOver = false;
    generateFood();
  });
  startGame();
}


  @override
  Widget build(BuildContext context) {
    if (!gameOver) {
      return Scaffold(
        backgroundColor: Colors.lightGreen[100],
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 12),

              // Punteggio in alto
              Text(
                'Punteggio: $score',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              // Griglia di gioco
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: GridView.builder(
                    itemCount: rowSize * rowSize,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: rowSize,
                    ),
                    itemBuilder: (context, index) {
                      final x = index % rowSize;
                      final y = index ~/ rowSize;
                      final pos = Position(x, y);

                      if (snake.any((s) => s.equals(pos))) {
                        return Center(
                          child: Text(catEmoji,
                              style: const TextStyle(fontSize: 20)),
                        );
                      } else if (food.equals(pos)) {
                        return Center(
                          child: Text(foodEmoji,
                              style: const TextStyle(fontSize: 20)),
                        );
                      } else {
                        return Container(color: Colors.lightGreen[300]);
                      }
                    },
                  ),
                ),
              ),

              // Frecce direzionali
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 48,
                          icon: const Icon(Icons.arrow_upward),
                          onPressed: () => changeDirection(Direction.up),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 48,
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () => changeDirection(Direction.left),
                        ),
                        const SizedBox(width: 40),
                        IconButton(
                          iconSize: 48,
                          icon: const Icon(Icons.arrow_forward),
                          onPressed: () => changeDirection(Direction.right),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          iconSize: 48,
                          icon: const Icon(Icons.arrow_downward),
                          onPressed: () => changeDirection(Direction.down),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Schermata Game Over con classifica
      return AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Center(
          child: Text(
            'GAME OVER',
            style: TextStyle(
              color: Colors.red,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            const Text(
              '🏆 Classifica',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            ...topScores.asMap().entries.map((entry) {
              final index = entry.key;
              final value = entry.value;
              String medal;
              switch (index) {
                case 0:
                  medal = '🥇';
                  break;
                case 1:
                  medal = '🥈';
                  break;
                case 2:
                  medal = '🥉';
                  break;
                default:
                  medal = '${index + 1}.';
              }
              return Text(
                '$medal ${value['user']['username'] ?? 'Utente'}: ${value['score']} punti',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 20),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
      );
    }
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
