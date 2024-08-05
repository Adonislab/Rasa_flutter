import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math';
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
  final String _hfUrl =
      'https://api-inference.huggingface.co/models/mistralai/Mistral-Nemo-Instruct-2407/v1/chat/completions';

  final Map<String, String> intentCollectionMap = {
    'nourriture': 'marchands',
    'produit': 'boutiques',
    'événement': 'events',
  };

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

    final lowerCaseMessage = message.toLowerCase(); // Convertir le message en minuscules

    // Liste de mots-clés pour détecter les intentions d'achat
    final purchaseIntents = {
      'produit': ['acheter', 'commande', 'prix', 'achat', 'produit', 'marchandise'],
      'nourriture': ['nourriture', 'manger', 'faim', 'mets', 'mangé'],
      'événement': ['événement', 'soirée', 'concert', 'spectacle'],
    };

    String? matchedIntent;
    for (var intent in purchaseIntents.keys) {
      if (purchaseIntents[intent]!.any((keyword) => lowerCaseMessage.contains(keyword))) {
        matchedIntent = intent;
        break;
      }
    }

    if (matchedIntent != null) {
      final collection = intentCollectionMap[matchedIntent]!;
      final foundProducts = await _searchProducts(collection);

      if (foundProducts.isNotEmpty) {
        setState(() {
          _messages.addAll(foundProducts.map((product) => '${product['title']} - ${product['price']}'));
        });

        // Concaténer les résultats dans le message vocal
        String resultsMessage = 'Nous vous proposons les produits suivants :';
        for (var product in foundProducts) {
          resultsMessage += '\n\n${product['title']}, au prix de ${product['price']} FCFA. Il appartient à la catégorie ${product['categorie']} et est décrit comme : ${product['description']}';
        }
        _speak(resultsMessage);

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

  Future<List<Map<String, dynamic>>> _searchProducts(String collection) async {
    final firestore = FirebaseFirestore.instance;

    // Récupérer un document aléatoire de la collection
    final allDocs = await firestore.collection(collection).get();
    final randomDoc = (allDocs.docs..shuffle()).first;

    // Extraire le champ 'produits' du document
    final productsList = randomDoc.data()['produits'] as List<dynamic>;

    // Sélectionner deux éléments aléatoires
    final random = Random();
    final selectedProducts = <Map<String, dynamic>>[];
    final products = productsList.toList();

    // S'assurer qu'il y a suffisamment de produits pour en sélectionner deux
    if (products.length > 1) {
      for (int i = 0; i < 2; i++) {
        final randomIndex = random.nextInt(products.length);
        final product = products[randomIndex];
        products.removeAt(randomIndex); // Éviter les duplications

        selectedProducts.add({
          'categorie': product['categorie'] ?? '',
          'description': product['description'] ?? '',
          'price': product['price'] ?? '',
          'title': product['title'] ?? '',
          'image': product['image'] ?? '',
        });
      }
    }

    return selectedProducts.isEmpty
        ? [
            {
              'categorie': 'Aucune catégorie',
              'description': 'Aucune description',
              'price': 'Aucun prix',
              'title': 'Aucun titre',
              'image': 'Aucune image',
            }
          ]
        : selectedProducts;
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
          'messages': [
            {'role': 'user', 'content': userMessage}
          ],
          'max_tokens': 500,
          'stream': false,
        }),
      );

      if (response.statusCode == 200) {
        // Assurez-vous que la réponse est décodée en UTF-8
        final responseBody = utf8.decode(response.bodyBytes);
        final jsonResponse = json.decode(responseBody);
        String content = jsonResponse['choices'][0]['message']['content'];

        // Nettoyage et transformation des caractères spéciaux
        content = _sanitizeText(content);
        return content;
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

  String _sanitizeText(String text) {
    // Remplacer les caractères non imprimables ou spéciaux par des espaces ou d'autres caractères
    text = text.replaceAll(
        RegExp(r'\p{C}'), ''); // Remplace les caractères de contrôle Unicode
    text = text.replaceAll(RegExp(r'[\u{FFFD}]', unicode: true),
        ''); // Remplace les caractères de remplacement Unicode
    text = text.trim();
    return text;
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
                        hintText: 'Type your message...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.send),
                    onPressed: () => _sendMessage(_textController.text),
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
