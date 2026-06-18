import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';
import '../services/ai_service.dart';

class ChatProvider extends ChangeNotifier {
  final AiService _aiService = AiService();
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ChatProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final String? historyJson = prefs.getString('chat_history');
    if (historyJson != null) {
      final List<dynamic> decoded = jsonDecode(historyJson);
      _messages = decoded.map((e) => ChatMessage.fromJson(e)).toList();
      notifyListeners();
    } else {
      _messages.add(ChatMessage(
        text: '¡Hola! Soy tu Asistente Virtual de Soporte TI. ¿En qué te puedo ayudar hoy con tu equipo o cuenta?',
        isUser: false,
        timestamp: DateTime.now(),
      ));
      notifyListeners();
    }
  }

  Future<void> _saveHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(_messages.map((e) => e.toJson()).toList());
    await prefs.setString('chat_history', encoded);
  }

  /// Limpia el error después de que la UI lo muestre
  void clearError() {
    _errorMessage = null;
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    _messages.add(ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    ));
    _errorMessage = null;
    _isLoading = true;
    notifyListeners();
    await _saveHistory();

    try {
      final responseText = await _aiService.getResponse(text);

      _messages.add(ChatMessage(
        text: responseText,
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } catch (e) {
      _errorMessage = e.toString().replaceFirst('Exception: ', '');
      _messages.add(ChatMessage(
        text: '⚠️ No pude responder en este momento. Verifica tu conexión a internet e intenta de nuevo.',
        isUser: false,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
      await _saveHistory();
    }
  }

  void clearHistory() async {
    _messages.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('chat_history');
    _messages.add(ChatMessage(
      text: 'Historial borrado. ¿En qué te ayudo ahora?',
      isUser: false,
      timestamp: DateTime.now(),
    ));
    _errorMessage = null;
    notifyListeners();
  }
}
