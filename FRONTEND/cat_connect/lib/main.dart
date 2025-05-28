import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'account.dart';
import 'add_post.dart';
import 'home.dart';
import 'search.dart';
import 'login.dart';
import 'searched.dart';
import 'cat_snake.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Aggiungi i tuoi temi qui
final Map<String, ThemeData> themes = {
  'Classico': ThemeData(
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.light(primary: Colors.white, secondary: Colors.black),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.white, foregroundColor: Colors.black),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Colors.black, selectedItemColor: Colors.white),
  ),
  'Primario: Nero, Secondario: Bianco': ThemeData(
    primaryColor: Colors.black,
    scaffoldBackgroundColor: Colors.white,
    colorScheme: ColorScheme.light(primary: Colors.black, secondary: Colors.white),
    appBarTheme: const AppBarTheme(backgroundColor: Colors.black, foregroundColor: Colors.white),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Colors.black, selectedItemColor: Colors.white),
  ),
  'Sole Estivo': ThemeData(
    primaryColor: Color(0xFFFFEB3B),
    scaffoldBackgroundColor: Color(0xFFFF9800),
    colorScheme: ColorScheme.light(primary: Color(0xFFFFEB3B), secondary: Color(0xFFFF9800)),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFFFEB3B), foregroundColor: Colors.black),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Color(0xFFFF9800), selectedItemColor: Colors.white),
  ),
  'Notte Stellata': ThemeData(
    primaryColor: Color(0xFF1A237E),
    scaffoldBackgroundColor: Color(0xFF64B5F6),
    colorScheme: ColorScheme.light(primary: Color(0xFF1A237E), secondary: Color(0xFF64B5F6)),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF1A237E), foregroundColor: Colors.white),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Color(0xFF1A237E), selectedItemColor: Colors.white),
  ),
  'Verde Natura': ThemeData(
    primaryColor: Color(0xFF2E7D32),
    scaffoldBackgroundColor: Color(0xFFAED581),
    colorScheme: ColorScheme.light(primary: Color(0xFF2E7D32), secondary: Color(0xFFAED581)),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF2E7D32), foregroundColor: Colors.white),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Color(0xFF2E7D32), selectedItemColor: Colors.white),
  ),
  'Rosa Delicato': ThemeData(
    primaryColor: Color(0xFFF8BBD0),
    scaffoldBackgroundColor: Color(0xFFEC407A),
    colorScheme: ColorScheme.light(primary: Color(0xFFF8BBD0), secondary: Color(0xFFEC407A)),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFFF8BBD0), foregroundColor: Colors.black),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Color(0xFFEC407A), selectedItemColor: Colors.white),
  ),
  'Grigio Elegante': ThemeData(
    primaryColor: Color(0xFF212121),
    scaffoldBackgroundColor: Color(0xFFBDBDBD),
    colorScheme: ColorScheme.light(primary: Color(0xFF212121), secondary: Color(0xFFBDBDBD)),
    appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF212121), foregroundColor: Colors.white),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(backgroundColor: Color(0xFF212121), selectedItemColor: Colors.white),
  ),
};

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  MyAppState createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  int _selectedIndex = 0;
  bool _isLoggedIn = false;
  String? _selectedUserId;

  // Inizializza _widgetOptions con un placeholder per AccountScreen
  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(), // Aggiungi 'const' se possibile
    SearchScreen(), // Aggiungi 'const' se possibile
    AddPostScreen(), // Aggiungi 'const' se possibile
    SnakeGame(), // Aggiungi 'const' se possibile
    Placeholder(), // Placeholder per AccountScreen
  ];

  String _currentTheme = 'Classico'; // Tema predefinito

  @override
  void initState() {
    super.initState();
    //_checkLoginStatus(); // verifica il login all'avvio
    _loadTheme(); // Carica il tema salvato
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentTheme = prefs.getString('theme') ?? 'Classico';
    });
  }

  Future<void> _saveTheme(String themeName) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _currentTheme = themeName;
    });
    prefs.setString('theme', themeName); // Salva il nome del tema
  }

  // ✅ Verifica se esiste un token salvato
  Future<void> _checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    if (token != null) {
      setState(() {
        _isLoggedIn = true;
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      _selectedUserId = null;
      // Aggiorna l'elemento AccountScreen con la funzione _saveTheme
      if (index == 4) {
        _widgetOptions[index] = AccountScreen(onThemeChanged: _saveTheme);
      }
    });
  }

  void _handleLogin(bool isLoggedIn) {
    setState(() {
      _isLoggedIn = isLoggedIn;
    });
  }

  void showUserProfileScreen(String userId) {
    setState(() {
      _selectedUserId = userId;
    });
  }

  void updateSelectedIndex(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void updateLogin(int index) {
    setState(() {
      _isLoggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cat Connect',
      theme: themes[_currentTheme], // Applica il tema scelto
      home: _isLoggedIn
          ? Scaffold(
              appBar: AppBar(
                toolbarHeight: 48,
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.pets, color: Colors.black, size: 24),
                    const SizedBox(width: 6),
                    Text(
                      'Cat Connect',
                      style: GoogleFonts.londrinaSolid(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.pets, color: Colors.black, size: 24),
                  ],
                ),
                centerTitle: true,
                backgroundColor: Colors.white,
                foregroundColor: const Color(0x548ac6),
              ),
              body: _selectedUserId == null
                  ? _widgetOptions.elementAt(_selectedIndex)
                  : SearchedUserScreen(userId: _selectedUserId!),
              bottomNavigationBar: Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                ),
                child: BottomNavigationBar(
                  backgroundColor: Colors.transparent,
                  selectedItemColor: Colors.white,
                  unselectedItemColor: Colors.grey,
                  currentIndex: _selectedIndex,
                  onTap: _onItemTapped,
                  type: BottomNavigationBarType.fixed,
                  items: const <BottomNavigationBarItem>[
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: 'Home',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.search),
                      label: 'Search',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.add),
                      label: 'Add Post',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.gamepad),
                      label: 'Game',
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.account_circle),
                      label: 'Account',
                    ),
                  ],
                ),
              ),
            )
          : LoginScreen(onLogin: _handleLogin),
    );
  }
}