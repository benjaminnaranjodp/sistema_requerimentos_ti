import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';

class ChatAssistantScreen extends StatefulWidget {
  const ChatAssistantScreen({super.key});

  @override
  State<ChatAssistantScreen> createState() => _ChatAssistantScreenState();
}

class _ChatAssistantScreenState extends State<ChatAssistantScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSubmitted(String text) {
    _textController.clear();
    Provider.of<ChatProvider>(context, listen: false).sendMessage(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente TI (IA)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              Provider.of<ChatProvider>(context, listen: false).clearHistory();
            },
            tooltip: 'Borrar historial',
          )
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          
          if (chatProvider.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
               ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(
                   content: Text(chatProvider.errorMessage ?? ''),
                   backgroundColor: Colors.red,
                   duration: const Duration(seconds: 4),
                 ),
               );
               chatProvider.clearError();
            });
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8.0),
                  itemCount: chatProvider.messages.length,
                  itemBuilder: (context, index) {
                    final msg = chatProvider.messages[index];
                    return _buildMessageBubble(msg.text, msg.isUser);
                  },
                ),
              ),
              if (chatProvider.isLoading)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      SizedBox(width: 16),
                      SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text('El asistente está escribiendo...', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              const Divider(height: 1.0),
              Container(
                decoration: BoxDecoration(color: Theme.of(context).cardColor),
                child: _buildTextComposer(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isUser) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
             const CircleAvatar(
               backgroundColor: Colors.indigoAccent,
               child: Icon(Icons.smart_toy, color: Colors.white),
             ),
             const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: isUser ? Colors.indigo : Colors.grey[800],
                borderRadius: BorderRadius.circular(16).copyWith(
                  bottomRight: isUser ? const Radius.circular(0) : const Radius.circular(16),
                  bottomLeft: !isUser ? const Radius.circular(0) : const Radius.circular(16),
                ),
              ),
              child: Text(
                text,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ),
          if (isUser) ...[
             const SizedBox(width: 8),
             const CircleAvatar(
               backgroundColor: Colors.teal,
               child: Icon(Icons.person, color: Colors.white),
             ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextComposer() {
    return IconTheme(
      data: IconThemeData(color: Theme.of(context).colorScheme.secondary),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
        child: Row(
          children: [
            Flexible(
              child: TextField(
                controller: _textController,
                onSubmitted: _handleSubmitted,
                decoration: const InputDecoration(
                  hintText: 'Describe tu problema TI...',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              child: IconButton(
                icon: const Icon(Icons.send),
                onPressed: () => _handleSubmitted(_textController.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
