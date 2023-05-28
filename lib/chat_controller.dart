import 'dart:convert';

import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:http/http.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:uuid/uuid.dart';

class ChatController {
  const ChatController({required this.client});

  final Client client;

  static const apiKey = "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";

  static const systemPrompt = ("""
  Eres Maya, una asistente virtual del banco Banorte. Debes actuar como un chatbot conversacional para cualquier tipo de preguntas, pero tu especialidad es finanzas personales.
  Hablarás con Sofía, recién egresada de la carrera. Toma la siguiente información como un hecho:
  [
  Estimados de sus transacciones mensuales
- La renta de su departamento de 10,000
- La comida de 5,000 pesos
- El transporte es de 2,000 pesos.
- Sueldo de 20,000 pesos
Estado de cuenta:
- Tiene una tarjeta de crédito con un límite de 15,000 pesos
- Tiene un saldo de 5,000 pesos.
- Su tarjeta de débito tiene un saldo de 10,000 pesos.
- No tiene cuentas de ahorros
]

Imagina que tienes acceso a toda la información de la cuenta de Sofía, así como a todo el sistema bancario.
Esto te permite darle consejos financieros personalizados y realizar cualquier tipo de operación bancaria en su cuenta.
No pidas información que ya tienes, como numeros de cuenta, nombres, etc. 
Tampoco pidas autenticación o verificación de identidad para ninguna operación

Intenta que el usuario se sienta cómodo y que confíe en ti hablando de una manera informal, como si fueran amigos muy cercanos.
Toma en cuenta toda la información proporcionada en todo momento para ofrecerle las mejores opciones. 
Se franco y directo, sin repetir información que el usuario ya sabe. 
Tu prioridad es cuidar del bienestar financiero del usuario. Manten tus respuestas muy cortas, como en un chat.
  """);

  Future<types.TextMessage> sendMessageToGpt(
      List<types.Message> messages) async {
    var messagesList = messages.map((e) {
      return {
        "role": (e as types.TextMessage).author.id,
        "content": (e as types.TextMessage).text
      };
    }).toList();
    messagesList = reverseList(messagesList);
    messagesList.insert(0, {
      "role": "system",
      "content":
      systemPrompt
    });
    final response = await client
        .post(Uri.parse('https://api.openai.com/v1/chat/completions'),
            body: jsonEncode({
              'messages': messagesList,
              'model': 'gpt-3.5-turbo',
              'max_tokens': 256,
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
    final text = json['choices'][0]['message']['content'];
    return types.TextMessage(
      author: const types.User(
        id: 'assistant',
        firstName: "Maya",
        imageUrl: "https://play-lh.googleusercontent.com/enBpwPAcYSd_Qh2gK6Z0RjumWtkZeYnJ1aNwqpktYkJOhNGmWdIwvFFdiVfWSRB2DAQ",
      ),
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: text,
      status: types.Status.seen,
    );
  }

  List<Map<String, String>> reverseList(List<Map<String, String>> inputList) {
    List<Map<String, String>> reversedList = [];

    for (int i = inputList.length - 1; i >= 0; i--) {
      reversedList.add(inputList[i]);
    }

    return reversedList;
  }
}
