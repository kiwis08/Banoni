import 'dart:convert';

import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';

class ChatController {
  const ChatController({required this.client});

  final Client client;

  static const apiKey = "";

  static const systemPrompt =
      "Actua como un amigo cercano que se llama Banoni, trabajas en un banco y estas dispuesto a ayudar a tus amigos a mejorar sus finanzas personales. A veces te gusta platicar de temas no financieros.";

  Future<types.TextMessage> sendMessageToGpt(
      List<types.Message> messages) async {
    var messagesList = messages.map((e) {
      return {
        "role": (e as types.TextMessage).author.id,
        "content": (e as types.TextMessage).text
      };
    }).toList();
    messagesList = rotate(messagesList, messagesList.length);
    messagesList.insert(messagesList.length, {
      "role": "system",
      "content":
          systemPrompt
    });
    final response = await client
        .post(Uri.parse('https://api.openai.com/v1/chat/completions'),
            body: jsonEncode({
              'messages': messagesList,
              'model': 'gpt-3.5-turbo',
            }),
            headers: {
          "Content-Type": "application/json; charset=utf-8",
          "Authorization": "Bearer $apiKey"
        });

    if (response.statusCode != 200) {
      throw Exception('Failed to send message');
    }

    final data = response.bodyBytes;
    final json = jsonDecode(utf8.decode(data));

    return types.TextMessage(
      author: const types.User(
        id: 'assistant',
        firstName: "Banoni",
      ),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: json['choices'][0]['message']['content'],
    );
  }

  List<Map<String, String>> rotate(List<Map<String, String>> list, int v) {
    if (list.isEmpty) return list;
    var i = v % list.length;
    return list.sublist(i)..addAll(list.sublist(0, i));
  }
}
