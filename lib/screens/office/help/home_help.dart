import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeTts();
  }

  void _initializeTts() async {
    try {
      await _flutterTts.setLanguage('fr-FR'); // Configurer pour le français
      await _flutterTts.setSpeechRate(0.5); // Vitesse de la parole
      await _flutterTts.setVolume(1.0); // Volume
      await _flutterTts.setPitch(1.0); // Tonalité
    } catch (e) {
      print('Erreur lors de l\'initialisation de TTS: $e');
    }
  }

  void _sendMessage(String message) {
    setState(() {
      _messages.add(message);
    });
    _textController.clear(); // Effacer le texte après envoi
  }

  Future<void> _speak(String message) async {
    print('Speaking: $message'); // Log pour débogage
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
          print('onStatus: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() {
              _isListening = false;
            });
          }
        },
        onError: (error) {
          print('onError: $error');
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
