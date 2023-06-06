import 'dart:convert';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

void main() {
  runApp(ChatApp());
}

class ChatApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'NotoSans',
        brightness: Brightness.dark,
        primaryColor: Colors.black,
        hintColor: Colors.green,
      ),
      debugShowMaterialGrid: false,
      debugShowCheckedModeBanner: false,
      home: ChatScreen(),
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [
        const Locale('pt', 'BR'), // Português brasileiro
      ],
    );
  }
}

class ChatMessage {
  bool isUser;
  String message;
  ChatMessage(this.isUser, this.message);
}

class ChatScreen extends StatefulWidget {
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) {
      return;
    }

    _textController.clear();

    setState(() {
      _messages.insert(0, ChatMessage(true, text));
    });

    var response = await fetchGpt3Response(text);

    setState(() {
      _messages.insert(0, ChatMessage(false, response));
    });
  }

  Future<String> fetchGpt3Response(String prompt) async {
    var headers = {
      'Authorization': 'Bearer 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',
      'Content-Type': 'application/json',
    };

    var body = jsonEncode({
      'model': 'gpt-3.5-turbo',
      'messages': [
        {
          'role': 'user',
          'content': prompt,
        },
      ],
      'temperature': 0.7,
    });

    var response = await http.post(
      Uri.parse('https://api.openai.com/v1/chat/completions'),
      headers: headers,
      body: body,
    );

    if (response.statusCode == 200) {
      var responses = jsonDecode(response.body)['choices'];
      if (responses.isNotEmpty) {
        return responses[0]['message']['content'].trim();
      } else {
        throw Exception('A API do GPT-3 não retornou uma resposta');
      }
    } else {
      throw Exception('Erro ao obter resposta da API do GPT-3');
    }
  }

  Widget _textComposerWidget() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
        child: Row(
          children: <Widget>[
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: InputDecoration.collapsed(hintText: "Enviar uma mensagem"),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(child: Text(message.isUser ? "U" : "C")),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(message.isUser ? "Usuário" : "Chat", style: Theme.of(context).textTheme.subtitle1),
                Container(
                  margin: const EdgeInsets.only(top: 5.0),
                  child: Text(message.message),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Amigo da Escola")),
      body: Column(
        children: <Widget>[
          Flexible(
            child: ListView.builder(
              padding: EdgeInsets.all(8.0),
              reverse: true,
              itemBuilder: (_, int index) => _buildMessage(_messages[index]),
              itemCount: _messages.length,
            ),
          ),
          Divider(height: 1.0),
          Container(
            decoration: BoxDecoration(color: Theme.of(context).cardColor),
            child: _textComposerWidget(),
          ),
        ],
      ),
    );
  }
}
