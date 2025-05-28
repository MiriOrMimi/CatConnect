import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as img;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloudinary_public/cloudinary_public.dart';
import 'package:dio/dio.dart';
import 'package:cat_connect/main.dart';

class AddPostScreen extends StatefulWidget {
  @override
  _AddPostScreenState createState() => _AddPostScreenState();
}

class _AddPostScreenState extends State<AddPostScreen> {
  late Interpreter _interpreter;
  String _result = 'Carica un\'immagine';
  Color _backgroundColor = Colors.white;
  bool _showPostForm = false;
  final TextEditingController _descriptionController = TextEditingController();
  String userID = '';
  String imageURL = '';
  String filePath = '';
  bool _isLoading = false;
  bool _showButton = false;
  final cloudinary = CloudinaryPublic('dzyi6fulj', 'cat_connect', cache: false);
  List<String> catBreeds = [];
  String? razzaSelezionata;

  @override
  void initState() {
    super.initState();
    _pickImage();
    _loadModel();
    fetchCatBreeds();
  }
 //caricamento del modello tflite
  Future<void> _loadModel() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final modelPath = '${appDocDir.path}/cat_detector.tflite';

    final file = File(modelPath);
    if (!file.existsSync()) {
      final ByteData data = await rootBundle.load('assets/cat_detector.tflite');
      final buffer = data.buffer.asUint8List();
      file.writeAsBytesSync(buffer);
    }

    final modelFile = File(modelPath);
    _interpreter = Interpreter.fromFile(modelFile);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    final image = File(pickedFile.path);
    filePath = pickedFile.path;
    _predictImage(image);
  }
  
  //metodo per riconoscere il gatto
  Future<void> _predictImage(File image) async {
    setState(() {
      _isLoading = true;
    });

    final imageBytes = await image.readAsBytes();
    img.Image? imageInput = img.decodeImage(imageBytes);

    if (imageInput == null) {
      setState(() {
        _result = "Errore nell'elaborazione dell'immagine";
        _backgroundColor = Colors.red;
        _showPostForm = false;
        _isLoading = false;
      });
      return;
    }

    img.Image resizedImage =
        img.copyResize(imageInput, width: 224, height: 224);
    var input = Float32List(1 * 224 * 224 * 3);
    var pixelIndex = 0;

    for (int y = 0; y < resizedImage.height; y++) {
      for (int x = 0; x < resizedImage.width; x++) {
        var pixel = resizedImage.getPixel(x, y);
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }

    var inputShape = _interpreter.getInputTensor(0).shape;
    var outputShape = _interpreter.getOutputTensor(0).shape;

    var inputArray = input.reshape(inputShape);
    var outputArray =
        List.generate(outputShape[0], (_) => List.filled(outputShape[1], 0.0));

    _interpreter.run(inputArray, outputArray);

    double prediction = outputArray[0][0];

    setState(() {
      if (prediction < 0.1) {
        _backgroundColor = const Color.fromARGB(255, 135, 233, 135);
        _showPostForm = true;
      } else {
        _backgroundColor = const Color.fromARGB(255, 243, 173, 173);
        _showPostForm = false;
      }
      _isLoading = false;
      _showButton = true;
    });
  }

  //pubblico il post
  Future<void> _sendPost() async {
    setState(() {
      _isLoading = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    try {
      CloudinaryResponse response = await cloudinary.uploadFile(
        CloudinaryFile.fromFile(filePath,
            resourceType: CloudinaryResourceType.Image),
      );
      imageURL = response.secureUrl;
      print("URL immagine: $imageURL");
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

    if (token == null) {
      setState(() {
        _isLoading = false;
      });
      return;
    }

    try {
      final response = await http.get(

        Uri.parse('https://catconnect-7yg6.onrender.com/api/auth/me'),
        headers: {'Authorization': '$token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['id'] != null) {
          setState(() {
            userID = data['id'];
          });
        }
      } else {
        setState(() {
          _descriptionController.text =
              'Errore nella risposta: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _descriptionController.text = 'Errore durante la richiesta: $e';
      });
    }


    const String apiUrl = 'https://catconnect-7yg6.onrender.com/api/auth/addPost';

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'imageUrl': imageURL,
          'description': _descriptionController.text,
          'author': userID,
          'breed': razzaSelezionata
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar( 
          const SnackBar(content: Text('Post pubblicato con successo!')),
        );
        MyAppState? appState = context.findAncestorStateOfType<MyAppState>();
        if (appState != null) {
          appState.updateSelectedIndex(0); 
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Errore durante la pubblicazione del post')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Errore di connessione: $error')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> fetchCatBreeds() async {
    catBreeds.add('Altro');
    final response =
        await http.get(Uri.parse('https://api.thecatapi.com/v1/breeds'));
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      setState(() {
        catBreeds = data.map((item) => item['name'].toString()).toList();
        catBreeds.add('Altro');
      });
    } else {
      throw Exception('Errore nel caricamento delle razze');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (filePath.isNotEmpty)
              Image.file(
                File(filePath),
                width: 200,
                height: 200,
                fit: BoxFit.cover,
              ),
            SizedBox(height: 20),
            if (_isLoading) CircularProgressIndicator(),
            if (!_isLoading && _showButton)
              ElevatedButton(
                onPressed: _pickImage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                  shadowColor: Colors.black.withOpacity(0.2),
                  side: BorderSide(color: Colors.grey, width: 1),
                ),
                child: const Text(
                  'Seleziona un\'altra immagine',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (_showPostForm) ...[
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: TextField(
                  controller: _descriptionController,
                  decoration: InputDecoration(
                    labelText: 'Descrizione del post',
                    labelStyle: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.blue, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    hintText: 'Aggiungi una descrizione...',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  maxLines: 3,
                  minLines: 1,
                ),
              ),
              SizedBox(height: 10),
              DropdownButton<String>(
                value: razzaSelezionata,
                hint: const Text('Seleziona la razza del gatto'),
                dropdownColor: Colors.white,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                items: catBreeds.map((breed) {
                  return DropdownMenuItem(
                    value: breed,
                    child: Text(breed),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    razzaSelezionata = value!;
                  });
                },
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _sendPost,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 12, horizontal: 25),
                  shadowColor: Colors.black.withOpacity(0.2),
                  elevation: 5,
                  side: BorderSide(color: Colors.grey, width: 1),
                ),
                child: const Text(
                  'Carica',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _interpreter.close();
    super.dispose();
  }
}
