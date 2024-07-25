import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class PresentationApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: PresentationScreen(),
    );
  }
}

class PresentationScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChatPage(),
    );
  }
}

class ChatPage extends StatefulWidget {
  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  TextEditingController _textController = TextEditingController();
  stt.SpeechToText _speech = stt.SpeechToText();
  FlutterTts _flutterTts = FlutterTts();
  List<String> _messages = [];
  bool _isListening = false;

  final String _hfToken = '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';
  final String _hfUrl = 'https://api-inference.huggingface.co/models/mistralai/Mistral-Nemo-Instruct-2407/v1/chat/completions';

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  void _initializeTts() async {
    try {
      await _flutterTts.setLanguage('fr-FR');
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
    } catch (e) {
      print('Erreur lors de l\'initialisation de TTS: $e');
    }
  }

  Future<void> _sendMessage(String message) async {
    setState(() {
      _messages.add(message);
    });
    _textController.clear();
    
    // Recherche des produits dans Firebase
    if (message.contains('produit') || message.contains('recherche')) {
      final foundProducts = await _searchProducts(message);

      if (foundProducts.isNotEmpty) {
        setState(() {
          _messages.addAll(foundProducts);
        });
        _speak('Voici les résultats de votre recherche.');
      } else {
        // Utilisation de l'API Hugging Face si aucun produit n'est trouvé
        final response = await _callHuggingFaceApi(message);
        if (response != null) {
          setState(() {
            _messages.add(response);
          });
          _speak(response);
        } else {
          print('Erreur lors de l\'appel à l\'API');
        }
      }
    } else {
      // Envoyer le message à l'API de Hugging Face pour d'autres requêtes
      final response = await _callHuggingFaceApi(message);
      if (response != null) {
        setState(() {
          _messages.add(response);
        });
        _speak(response);
      } else {
        print('Erreur lors de l\'appel à l\'API');
      }
    }
  }

  Future<List<String>> _searchProducts(String query) async {
    final firestore = FirebaseFirestore.instance;
    final collections = ['marchand', 'event', 'food'];
    List<String> results = [];

    for (var collection in collections) {
      final snapshot = await firestore.collection(collection)
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThanOrEqualTo: query + '\uf8ff')
        .get();

      for (var doc in snapshot.docs) {
        final product = doc.data();
        results.add('${product['name']} - ${product['price']}'); // Adjust as needed
      }
    }

    return results;
  }

  Future<String?> _callHuggingFaceApi(String userMessage) async {
    try {
      final response = await http.post(
        Uri.parse(_hfUrl),
        headers: {
          'Authorization': 'Bearer $_hfToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'model': 'meta-llama/Meta-Llama-3.1-8B-Instruct',
          'messages': [{'role': 'user', 'content': userMessage}],
          'max_tokens': 500,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);
        return responseBody['choices'][0]['message']['content'];
      } else {
        print('Erreur API: ${response.statusCode}');
        print('Message API: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Erreur lors de l\'appel API: $e');
      return null;
    }
  }

  Future<void> _speak(String message) async {
    try {
      var result = await _flutterTts.speak(message);
      if (result == 1) {
        print('Speech started');
      } else {
        print('Speech not started');
      }
    } catch (e) {
      print('Erreur lors de la lecture: $e');
    }
  }

  void _listen() async {
    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (status) {
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
        onError: (error) {
          setState(() {
            _isListening = false;
          });
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
        });
        _speech.listen(
          onResult: (result) {
            setState(() {
              _textController.text = result.recognizedWords;
            });
          },
          localeId: 'fr_FR',
        );
      }
    } else {
      _speech.stop();
      setState(() {
        _isListening = false;
      });
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _speech.stop();
    _flutterTts.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.blue,
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView.builder(
                itemCount: _messages.length,
                itemBuilder: (BuildContext context, int index) {
                  return ListTile(
                    title: Text(_messages[index]),
                    trailing: IconButton(
                      icon: Icon(Icons.volume_up),
                      onPressed: () => _speak(_messages[index]),
                    ),
                  );
                },
              ),
            ),
            Container(
              padding: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.yellow],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.0),
              ),
              child: Row(
                children: <Widget>[
                  IconButton(
                    icon: Icon(
                      Icons.mic,
                      color: _isListening ? Colors.red : Colors.black,
                    ),
                    onPressed: _listen,
                  ),
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      decoration: InputDecoration(
                        hintText: 'Tapez votre message ici...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () {
                      if (_textController.text.isNotEmpty) {
                        _sendMessage(_textController.text);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
