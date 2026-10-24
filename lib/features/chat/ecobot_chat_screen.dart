import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/constants/taxonomy.dart';
import '../../data/models/detected_item.dart';
import 'ecobot_service.dart';

class EcoBotChatScreen extends StatefulWidget {
  final DetectedItem? initialItem;
  final String? sceneSummary;

  const EcoBotChatScreen({
    super.key,
    this.initialItem,
    this.sceneSummary,
  });

  @override
  State<EcoBotChatScreen> createState() => _EcoBotChatScreenState();
}

class _EcoBotChatScreenState extends State<EcoBotChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeGreeting();
  }

  void _initializeGreeting() {
    String greeting;
    if (widget.initialItem != null) {
      final item = widget.initialItem!;
      greeting = "Hello! I noticed you are inspecting **${Taxonomy.getDisplayName(item.effectiveClass)}** "
          "(Confidence: ${(item.confidence * 100).toStringAsFixed(0)}%). "
          "How can I help you sort, recycle, or repurpose this item?";
    } else {
      greeting = "Hello! I am EcoBot. Ask me anything about waste sorting, recycling, composting, or municipal disposal!";
    }
    _messages.add(ChatMessage(text: greeting, isUser: false));
  }

  Future<void> _sendMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    _controller.clear();
    setState(() {
      _messages.add(ChatMessage(text: clean, isUser: true));
      _isLoading = true;
    });

    _scrollToBottom();

    String? contextJson;
    if (widget.initialItem != null) {
      final it = widget.initialItem!;
      contextJson = "item: ${it.effectiveClass}, confidence: ${(it.confidence * 100).toStringAsFixed(0)}%, contamination: ${it.contaminationLevel ?? 'clean'}";
    } else if (widget.sceneSummary != null) {
      contextJson = widget.sceneSummary;
    }

    final response = await EcoBotService.sendMessage(
      userMessage: clean,
      conversationHistory: _messages,
      itemContextJson: contextJson,
    );

    setState(() {
      _messages.add(ChatMessage(text: response, isUser: false));
      _isLoading = false;
    });

    _scrollToBottom();
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.smart_toy_outlined, size: 24),
            SizedBox(width: 8),
            Text('EcoBot Assistant'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Context Chip Header
          if (widget.initialItem != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.green.shade50,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 18, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Context: ${Taxonomy.getDisplayName(widget.initialItem!.effectiveClass)} (${widget.initialItem!.contaminationLevel ?? 'clean'})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (ctx, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.82,
                    ),
                    decoration: BoxDecoration(
                      color: msg.isUser ? Colors.green.shade700 : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                    ),
                    child: msg.isUser
                        ? Text(
                            msg.text,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
                          )
                        : MarkdownBody(
                            data: msg.text,
                            styleSheet: MarkdownStyleSheet(
                              p: const TextStyle(fontSize: 14, color: Colors.black87),
                            ),
                          ),
                  ),
                );
              },
            ),
          ),

          // Loading Indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 8),
                  Text('EcoBot is consulting recycling rules...', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),

          // Suggested question chips
          if (widget.initialItem != null)
            Container(
              height: 40,
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildQuestionChip("Which bin does it go in?"),
                  _buildQuestionChip("Can I recycle if it is dirty?"),
                  _buildQuestionChip("Any creative upcycling ideas?"),
                ],
              ),
            ),

          // Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                )
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText: 'Ask about recycling, bins, or disposal...',
                        hintStyle: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      onSubmitted: _sendMessage,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.green),
                    onPressed: () => _sendMessage(_controller.text),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionChip(String question) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        label: Text(question, style: const TextStyle(fontSize: 12)),
        onPressed: () => _sendMessage(question),
        backgroundColor: Colors.grey.shade100,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

