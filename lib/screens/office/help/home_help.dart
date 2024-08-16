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
  List<dynamic> _messages = [];
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
      _messages.add({'type': 'text', 'content': message});
    });
    _textController.clear();

    final lowerCaseMessage =
        message.toLowerCase(); // Convertir le message en minuscules

    // Liste de mots-clés pour détecter les intentions d'achat
    final purchaseIntents = {
      'produit': [
        'commander',
        'consulter',
        'rechercher',
        'voir',
        'comparer',
        'commandé',
	      'chaussure',
	      'lotion',
	      'corporelle',
	      'montre',
	      'cosmétique',
	      'beauté',
	      'machine',
	      'traitement',
	      'canapé',
	      'fauteuil',
        'consulté',
        'recherché',
        'comparé',
        'essayer',
        'essayé',
        'trouver',
        'produit',
        'article',
        'marchandise',
        'bien',
        'article',
        'prix',
        'catalogue',
        'vente',
        'offre',
	      'offrir',
	      'vouloir',
	      'veux',
	      "m'offrir",
	      "s'offrir",
        'promotion',
        'marque', 
      ],
      'nourriture': [
                'payé',
        'payer',
        'prendre',
        'manger',
        'goûter',
        'commander',
        'déguster',
        'cuisiner',
        'préparer',
        'boire',
        'soif',
        'acheter',
        'acheté',
        'commandé',
        'réserver',
        'mangé',
        'goûté',
        'dégusté',
        'cuisiné',
        'préparé',
        'réservé',
        'nourriture',
        'plat',
        'repas',
        'cuisine',
        'restaurant',
        'repas',
	      'savourer',
	      'savouré',
	      'bouffer',
	      'bouffé',
        'déjeuner',
        'dîner',
        'snack',
        'menu',
        'spécialité',
        'ingrédient',
        'dîné'
	      'boisson',
        'poisson'
	      'jus',
      ],
      'événement': [
               'assister',
        'salle',
        'salon',
        'participer',
        'organiser',
        'planifier',
        'annoncer',
        'célébrer',
        'assisté',
        'participé',
        'organisé',
        'planifié',
        'annoncé',
	      'mariage',
	      'communion',
	      'anniversaire',
	      'chill',
	      'baptême',
        'célébré',
        'évènement',
	      'inviter',
        'spectacle',
        'concert',
        'fête',
        'louer',
        'loué',
        'soirée',
        'réunion',
        'festival',
        'conférence',
        'exposition',
	      'décorer',
	      'programmer',
	      'animer',
	      'animation',
	      'fêter',
        'événementiel',
        'activité'
      ],
    };

    String? matchedIntent;
    for (var intent in purchaseIntents.keys) {
      if (purchaseIntents[intent]!
          .any((keyword) => lowerCaseMessage.contains(keyword))) {
        matchedIntent = intent;
        break;
      }
    }

    if (matchedIntent != null) {
      final collection = intentCollectionMap[matchedIntent]!;
      final foundProducts = await _searchProducts(collection, lowerCaseMessage);

      if (foundProducts.isNotEmpty) {
        setState(() {
          _messages.addAll(foundProducts.map((product) => {
                'type': 'product',
                'product': product,
              }));
        });

        // Concaténer les résultats dans le message vocal
        String resultsMessage = 'Je vous propose les produits suivants :';
        for (var product in foundProducts) {
          resultsMessage +=
              '\n\n${product['title']}, au prix de ${product['price']} Franc CFA. Il appartient à la catégorie ${product['categorie']} et est décrit comme : ${product['description']}.';
        }
        resultsMessage +=
            "Je suis encore jeune et je ne cesse de m'améliorer pour une assistance plus solide. Merci";
        _speak(resultsMessage);
      } else {
        // Utilisation de l'API Hugging Face si aucun produit n'est trouvé
        final response = await _callHuggingFaceApi(message);
        if (response != null) {
          setState(() {
            _messages.add({'type': 'text', 'content': response});
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
          _messages.add({'type': 'text', 'content': response});
        });
        _speak(response);
      } else {
        print('Erreur lors de l\'appel à l\'API');
      }
    }
  }

  Future<List<Map<String, dynamic>>> _searchProducts(String collection, String lowerCaseMessage) async {
    final firestore = FirebaseFirestore.instance;

    // Récupérer un document aléatoire de la collection
    final allDocs = await firestore.collection(collection).get();
    final randomDoc = (allDocs.docs..shuffle()).first;

    // Extraire le champ 'produits' du document
    final productsList = randomDoc.data()['produits'] as List<dynamic>;

    // Convertir en liste de produits
    final products = productsList.toList();

    // Chercher un produit exact basé sur le message
    Map<String, dynamic>? exactProduct;
    final productTitle = lowerCaseMessage.trim().toLowerCase();
    if (productTitle.isNotEmpty) {
      print(productTitle);

      exactProduct = products.firstWhere(
        (product) {
          final title = product['title']?.toLowerCase() ?? '';
          // Vérifier si le titre du produit est contenu dans le texte recherché
          final match = productTitle.contains(title);
          //print('Produit: $title, Correspondance: $match');
          return match;
        },
        orElse: () => <String, dynamic>{}, // Retourne une carte vide si aucun produit ne correspond
      );

      //print('Produit exact trouvé: $exactProduct');
    }

    // Sélectionner deux éléments aléatoires
    final random = Random();
    final selectedProducts = <Map<String, dynamic>>[];

    // Ajouter le produit exact en premier, si trouvé
    if (exactProduct != null && exactProduct.isNotEmpty) {
      selectedProducts.add(exactProduct);
    }

    // S'assurer qu'il y a suffisamment de produits pour en sélectionner deux
    while (selectedProducts.length < 3 && products.isNotEmpty) {
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

    // Retourner les produits sélectionnés
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
                  final message = _messages[index];
                  if (message['type'] == 'text') {
                    return ListTile(
                      title: Text(message['content']),
                      trailing: IconButton(
                        icon: Icon(Icons.volume_up),
                        onPressed: () => _speak(message['content']),
                      ),
                    );
                  } else if (message['type'] == 'product') {
                    final product = message['product'];
                    return ProductCard(product: product);
                  } else {
                    return Container();
                  }
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
                        hintText: 'Votre message...',
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

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;

  ProductCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.all(8.0),
      color: Colors.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Affichage de l'image en haut
          if (product['image'] != '' && product['image'] != null)
            Image.network(
              product['image'],
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Affichage du titre
                Text(
                  product['title'],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                // Affichage du prix
                Text(
                  'Prix: ${product['price']} FCFA',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 4),
                // Affichage de la catégorie
                Text(
                  'Catégorie: ${product['categorie']}',
                  style: TextStyle(fontSize: 16),
                ),
                SizedBox(height: 4),
                // Affichage de la description
                Text(
                  'Description: ${product['description']}',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
