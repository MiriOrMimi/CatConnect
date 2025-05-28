import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class SearchedUserScreen extends StatefulWidget {
  final String? userId;

  const SearchedUserScreen({super.key, this.userId});

  @override
  _SearchedUserScreenState createState() => _SearchedUserScreenState();
}

class _SearchedUserScreenState extends State<SearchedUserScreen> {
  String username = '';
  String profileImageUrl = '';
  int followers = 0;
  int following = 0;
  int posts = 0;
  List<String> userPosts = [];
  bool _isLoading = true;
  bool _isFollowing = false;
  String? _errorMessage;
  String userID = "";

  @override
  void initState() {
    super.initState();
    if (widget.userId != null) {
      _fetchUserData();
      _followButton();
    }
  }

  Future<void> _followButton() async {
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
          if (data['following'].contains(widget.userId)) {
            _isFollowing = true;
          }
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Errore di rete: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchUserData() async {
    if (widget.userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('https://catconnect-7yg6.onrender.com/api/auth/user/${widget.userId}'),
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
              'Errore nel recupero dei dati utente: ${response.statusCode}';
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

  Future<void> _follow() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    String urlFollow;

    if(_isFollowing == false){
      urlFollow = "https://catconnect-7yg6.onrender.com/api/auth/follow";
    }else{
      urlFollow = "https://catconnect-7yg6.onrender.com/api/auth/unfollow";
    }

    print(widget.userId);

    try {
      final response = await http.post(
        Uri.parse(urlFollow),
        headers: {
          'Authorization': token!,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'userId': widget.userId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _isFollowing = !_isFollowing;
          if(_isFollowing == true){
            followers++;
          }else{
            followers--;
          }
        });
      } else {
        setState(() {
          _errorMessage = "Errore nel follow: ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Errore di rete: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(
              username.isEmpty ? 'Caricamento...' : 'Account di $username')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 50,
                                  backgroundImage:
                                      NetworkImage(profileImageUrl),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          username,
                                          style: const TextStyle(
                                              fontSize: 22,
                                              fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(
                                            width:
                                                12), // Spazio tra username e bottone
                                        ElevatedButton(
                                          onPressed:_follow,
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.black,
                                          ),
                                          child: Text(
                                            _isFollowing
                                                ? 'Following'
                                                : 'Follow',
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                        '$followers followers  •  $following following'),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text('Posts ($posts)',
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 10),
                      ],
                    ),
                  ),
                ),
                userPosts.isEmpty
                    ? const SliverFillRemaining(
                        child:
                            Center(child: Text('Non ci sono post disponibili')),
                      )
                    : SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        sliver: SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
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
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
