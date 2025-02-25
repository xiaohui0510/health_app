import 'package:flutter/material.dart';
import 'package:huggingface_client/huggingface_client.dart';

class ChatboxScreen extends StatefulWidget {
  const ChatboxScreen({super.key});

  @override
  State<ChatboxScreen> createState() => _ChatboxScreenState();
}

class _ChatboxScreenState extends State<ChatboxScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  // Initialize the Hugging Face client and inference API.
  late final InferenceApi _inferenceApi;

  @override
  void initState() {
    super.initState();
    final client = HuggingFaceClient.getInferenceClient(
      "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",
      HuggingFaceClient.inferenceBasePath,
    );
    _inferenceApi = InferenceApi(client);
  }

  Future<void> _sendMessage() async {
    final input = _controller.text.trim();
    if (input.isEmpty) return;

    setState(() {
      // Add the user's message to the conversation.
      _messages.add({'role': 'user', 'message': input});
      _isLoading = true;
    });
    _controller.clear();

    try {
      // Prepare the query parameters for text generation.
      final params = ApiQueryNLPTextGeneration(inputs: input);
      // Query the model (using GPT‑2 as an example; replace with your model if needed).
      final result = await _inferenceApi.queryNLPTextGeneration(
        taskParameters: params,
        model: 'microsoft/phi-1_5', // Test the model here
      );

      // Process the result; assume that the first generated result is used.
      final generatedText = (result != null && result.isNotEmpty)
          ? (result.first?.generatedText ?? 'No response received.')
          : 'No response received.';
      setState(() {
        _messages.add({'role': 'assistant', 'message': generatedText});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'message': 'Error: $e'});
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildMessage(Map<String, String> message) {
    final isUser = message['role'] == 'user';
    return Container(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Container(
        decoration: BoxDecoration(
          color: isUser ? Colors.blue[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(8.0),
        ),
        padding: const EdgeInsets.all(12.0),
        child: Text(
          message['message'] ?? '',
          style: const TextStyle(fontSize: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat Assistant')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: CircularProgressIndicator(),
            ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Ask me anything...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _sendMessage,
                  child: const Text('Send'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
