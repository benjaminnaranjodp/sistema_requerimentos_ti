import 'dart:convert';
import 'package:http/http.dart' as http;

class AiService {
  // Reemplazar con tu API Key de Groq (https://console.groq.com/keys)
  static const String _apiKey = String.fromEnvironment('GROQ_API_KEY', defaultValue: 'PON_TU_API_KEY_AQUI');
  static const String _baseUrl = 'https://api.groq.com/openai/v1/chat/completions';

  Future<String> getResponse(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content': 'Eres un asistente de soporte técnico de nivel 1 para un Sistema de Requerimientos TI. '
                  'Tu objetivo es ayudar a los usuarios a resolver problemas comunes de hardware, software, redes y cuentas. '
                  'Eres amable, conciso y profesional. Si el problema es complejo, sugiere al usuario que levante un ticket/requerimiento formal. '
                  'Responde siempre en español y de forma breve.',
            },
            {
              'role': 'user',
              'content': prompt,
            },
          ],
          'max_tokens': 1024,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final choices = data['choices'] as List?;
        if (choices != null && choices.isNotEmpty) {
          return choices[0]['message']['content'] as String;
        }
        return 'No pude generar una respuesta. Por favor, intenta de nuevo.';
      } else {
        throw Exception('Error del servidor (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      if (e is Exception && e.toString().contains('Error del servidor')) {
        rethrow;
      }
      throw Exception('Sin conexión a internet. Verifica tu red e intenta de nuevo.');
    }
  }
}
