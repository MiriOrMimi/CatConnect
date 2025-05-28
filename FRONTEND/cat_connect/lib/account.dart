import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cat_connect/main.dart';

class AccountScreen extends StatefulWidget {
  final Function(String) onThemeChanged; // Funzione per cambiare il tema

  const AccountScreen({super.key, required this.onThemeChanged});

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  String username = '';
  String profileImageUrl = '';
  int followers = 0;
  int following = 0;
  int posts = 0;
  List<String> userPosts = [];
  bool _isLoading = true;
  String? _errorMessage;
  String? _currentSelectedTheme;

  @override
  void initState() {
    super.initState();
    _loadCurrentTheme(); // Carica il tema corrente all'avvio
    _fetchUserData();
  }

  // Carica il tema corrente dalle SharedPreferences
  Future<void> _loadCurrentTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentSelectedTheme = prefs.getString('theme') ?? 'Classico';
    });
  }

  Future<void> _fetchUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token == null) {
      setState(() {
        _errorMessage = 'Non trovato il token. Effettua il login.';
        _isLoading = false;
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
        setState(() {
          username = data['username'];
          profileImageUrl = data['profilePictureUrl'];
          followers = data['followers'] != null ? data['followers'].length : 0;
          following = data['following'] != null ? data['following'].length : 0;
          posts = data['posts'] != null ? data['posts'].length : 0;
          userPosts = List<String>.from(data['posts'] ?? []).reversed.toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Errore nel recupero dei dati utente: ${response.statusCode}, ${response.body}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore di rete: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');

    MyAppState? appState = context.findAncestorStateOfType<MyAppState>();
    if (appState != null) {
      appState.updateLogin(0);
    }
  }

  // Funzione per cambiare il tema
  void _changeTheme(String? newTheme) {
    if (newTheme != null) {
      setState(() {
        _currentSelectedTheme = newTheme;
      });
      widget.onThemeChanged(newTheme); // Chiama la funzione passata dal main
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Account'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 50,
                              backgroundImage: NetworkImage(profileImageUrl),
                            ),
                            SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  username,
                                  style: TextStyle(
                                      fontSize: 22, fontWeight: FontWeight.bold),
                                ),
                                SizedBox(height: 8),
                                Text(
                                    '$followers followers  •  $following following'),
                              ],
                            ),
                            IconButton(
                              icon: const Icon(Icons.logout),
                              onPressed: _logout,
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        Text(
                          'Posts ($posts)',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 10),
                        // Aggiungi il selettore del tema
                        Text(
                          'Seleziona Tema',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        DropdownButton<String>(
                          value: _currentSelectedTheme,
                          onChanged: _changeTheme,
                          items: themes.keys.map((String themeName) {
                            return DropdownMenuItem<String>(
                              value: themeName,
                              child: Text(themeName),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                userPosts.isEmpty
                    ? SliverFillRemaining(
                        child: Center(
                          child: Text('Non ci sono post disponibili'),
                        ),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverGrid(
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  userPosts[index],
                                  fit: BoxFit.cover,
                                ),
                              );
                            },
                            childCount: userPosts.length,
                          ),
                        ),
                      ),
                if (_errorMessage != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}