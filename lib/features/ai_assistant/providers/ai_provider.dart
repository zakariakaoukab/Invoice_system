import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_service.dart';

final aiServiceProvider = Provider<AiService>((ref) {
  return AiService();
});

class ChatMessage {
  final String text;
  final bool isUser;
  
  ChatMessage({required this.text, required this.isUser});
}

class ChatNotifier extends StateNotifier<List<ChatMessage>> {
  final AiService _aiService;
  bool isLoading = false;

  ChatNotifier(this._aiService) : super([
    ChatMessage(text: 'Hello! I am your AI Business Assistant. Ask me anything about your sales, stock, or performance.', isUser: false)
  ]);

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // Add user message
    state = [...state, ChatMessage(text: text, isUser: true)];
    isLoading = true;
    
    // Trigger UI rebuild for loading state
    state = [...state]; 

    try {
      final response = await _aiService.askQuestion(text);
      state = [...state, ChatMessage(text: response, isUser: false)];
    } catch (e) {
      state = [...state, ChatMessage(text: 'Error communicating with AI: $e', isUser: false)];
    } finally {
      isLoading = false;
      state = [...state];
    }
  }
}

final chatProvider = StateNotifierProvider<ChatNotifier, List<ChatMessage>>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  return ChatNotifier(aiService);
});
