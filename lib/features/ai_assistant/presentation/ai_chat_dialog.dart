import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../providers/ai_provider.dart';

class AiChatDialog extends ConsumerStatefulWidget {
  const AiChatDialog({super.key});

  @override
  ConsumerState<AiChatDialog> createState() => _AiChatDialogState();
}

class _AiChatDialogState extends ConsumerState<AiChatDialog> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  void _sendMessage() {
    final text = _controller.text;
    if (text.trim().isNotEmpty) {
      ref.read(chatProvider.notifier).sendMessage(text);
      _controller.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatProvider);
    final notifier = ref.watch(chatProvider.notifier);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardBorderRadius),
      ),
      child: Container(
        width: 400,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.smart_toy_rounded, color: AppColors.primary),
                    SizedBox(width: 8),
                    Text(
                      'AI Business Assistant',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                )
              ],
            ),
            const Divider(),
            
            // Chat messages
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length + (notifier.isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length && notifier.isLoading) {
                    return const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }

                  final msg = messages[index];
                  return Align(
                    alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: msg.isUser ? AppColors.primary : AppColors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12).copyWith(
                          bottomRight: msg.isUser ? const Radius.circular(0) : const Radius.circular(12),
                          bottomLeft: !msg.isUser ? const Radius.circular(0) : const Radius.circular(12),
                        ),
                        border: msg.isUser ? null : Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          color: msg.isUser ? AppColors.onPrimary : AppColors.onSurface,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            // Input Area
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask about sales, stock...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.send, color: AppColors.primary),
                  onPressed: _sendMessage,
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
