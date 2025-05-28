import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cat_connect/main.dart';

class LoginScreen extends StatefulWidget {
  final Function(bool) onLogin;

  const LoginScreen({Key? key, required this.onLogin}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isRegistering = false;
  bool _isLoading = false;
  String? _errorMessage;
  File? _profileImage;

  //controller delle varie text box
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();

  //dati per connettersi al repository pubblico su cui sono salvate le foto
  final cloudinary = CloudinaryPublic('dzyi6fulj', 'cat_connect', cache: false);

  //metodo per recuperare l'immagine da verificare
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }

  //metodo per fare il login
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Compilare tutti i campi";
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse('https://catconnect-7yg6.onrender.com/api/auth/login'),
        body: json.encode({
          'username': _usernameController.text,
          'password': _passwordController.text,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final token = data['token'];

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', token);

        MyAppState? appState = context.findAncestorStateOfType<MyAppState>();
        if (appState != null) {
          appState.updateSelectedIndex(0);
        }

        widget.onLogin(true);
      } else {
        setState(() {
          _errorMessage = "Errore nel login, ricontrolla le credenziali.";
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

  //metodo per la registrazione
  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });

    String? imageUrl;

    // salviamo l'immagine profilo nel repository
    if (_profileImage != null) {
      try {
        CloudinaryResponse response = await cloudinary.uploadFile(
          CloudinaryFile.fromFile(_profileImage!.path,
              resourceType: CloudinaryResourceType.Image),
        );
        imageUrl = response.secureUrl;
      } on DioException catch (e) {
        print('DioException: ${e.message}');
        setState(() {
          _isLoading = false;
        });
        return;
      } on CloudinaryException catch (e) {
        print(e.message);
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }
    //salviamo i dati dell'utente sul DB
    final response = await http.post(
      Uri.parse('https://catconnect-7yg6.onrender.com/api/auth/register'),
      body: json.encode({
        'username': _usernameController.text,
        'email': _emailController.text,
        'password': _passwordController.text,
        'profilePictureUrl': imageUrl,
      }),
      headers: {'Content-Type': 'application/json'},
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 201) {
      _login();
    } else {
      setState(() {
        _errorMessage =
            "Errore nella registrazione, ricontrolla i dati inseriti.";
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 50),
              Text(
                _isRegistering ? 'Registrati' : 'Accedi',
                style:
                    const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (_isRegistering)
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _profileImage != null
                        ? FileImage(_profileImage!)
                        : null,
                    child: _profileImage == null
                        ? const Icon(Icons.camera_alt, size: 50)
                        : null,
                  ),
                ),
              const SizedBox(height: 20),
              // if (_isRegistering)
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  labelStyle: TextStyle(color: Colors.black),
                ),
              ),
              if (_isRegistering)
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    labelStyle: TextStyle(color: Colors.black),
                  ),
                ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  labelStyle: TextStyle(color: Colors.black),
                ),
              ),
              const SizedBox(height: 20),
              if (_errorMessage != null)
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              if (_isLoading) const CircularProgressIndicator(),
              if (!_isLoading)
                ElevatedButton(
                  onPressed:
                      _isLoading ? null : (_isRegistering ? _register : _login),
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isRegistering ? 'Registrati' : 'Accedi',
                          style: const TextStyle(color: Colors.black),
                        ),
                ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isRegistering = !_isRegistering;
                  });
                },
                child: Text(
                  _isRegistering
                      ? 'Hai già un account? Accedi'
                      : 'Non hai un account? Registrati',
                  style: const TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
