import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;

class WebSocketDemo extends StatefulWidget {
  const WebSocketDemo({Key? key}) : super(key: key);

  @override
  _WebSocketDemoState createState() => _WebSocketDemoState();
}

class _WebSocketDemoState extends State<WebSocketDemo> {
  final TextEditingController _controller = TextEditingController();
  late WebSocketChannel channel;
  final List<String> messages = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _connectToWebSocket();
  }

  Future<void> _connectToWebSocket() async {
    try {
      final uri = Uri.parse('wss://echo.websocket.events');
      channel = WebSocketChannel.connect(uri);
      print('Attempting to connect to $uri');

      channel.stream.listen(
        (message) {
          print('Received: $message');
          if (mounted) setState(() => messages.add(message.toString()));
        },
        onError: (error) {
          print('WebSocket error: $error');
          _showErrorDialog(error.toString());
        },
        onDone: () {
          print('WebSocket closed (code=${channel.closeCode}, reason=${channel.closeReason})');
          if (mounted) setState(() => _isConnected = false);
        },
      );

      if (mounted) setState(() => _isConnected = true);
      print('WebSocket connected');
    } catch (e) {
      print('Connection error: $e');
      _showErrorDialog(e.toString());
    }
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty || !_isConnected) return;

    try {
      print('Sending: $text');
      channel.sink.add(text);
      _controller.clear();
    } catch (e) {
      print('Send error: $e');
      _showErrorDialog(e.toString());
    }
  }

  void _showErrorDialog(String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ошибка WebSocket'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  void dispose() {
    if (_isConnected) {
      channel.sink.close(status.goingAway);
      print('WebSocket sink closed');
    }
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Demo'),
        actions: [
          Icon(_isConnected ? Icons.wifi : Icons.wifi_off,
               color: _isConnected ? Colors.green : Colors.red),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: messages.length,
                itemBuilder: (_, i) => ListTile(title: Text(messages[i])),
              ),
            ),
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Отправить сообщение',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _isConnected ? _sendMessage : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
