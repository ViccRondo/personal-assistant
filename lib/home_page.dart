import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  // 语音识别
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  
  // 对话
  final List<Map<String, dynamic>> _messages = [];
  bool _isListening = false;
  bool _isThinking = false;
  
  // 动画
  late AnimationController _animationController;
  
  // API 配置 - OpenClaw Gateway
  static const String _gatewayUrl = 'https://vicc.online';
  
  @override
  void initState() {
    super.initState();
    _initSpeech();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    // 添加欢迎消息
    _messages.add({
      'role': 'assistant',
      'content': '观众～你好呀！我是花火！🎭\n\n现在可以直接和我语音聊天啦！',
      'timestamp': DateTime.now(),
    });
  }
  
  void _initSpeech() async {
    try {
      _speechEnabled = await _speech.initialize(
        onError: (error) => print('Speech error: $error'),
        onStatus: (status) => print('Speech status: $status'),
      );
    } catch (e) {
      print('Speech init error: $e');
      _speechEnabled = false;
    }
    setState(() {});
    print('Speech enabled: $_speechEnabled');
  }
  
  void _startListening() async {
    if (!_speechEnabled) {
      _showMessage('语音识别不可用，请检查权限设置');
      return;
    }
    
    _lastWords = '';
    setState(() => _isListening = true);
    
    await _speech.listen(
      onResult: (result) {
        setState(() {
          _lastWords = result.recognizedWords;
          if (result.finalResult) {
            _sendMessage(_lastWords);
          }
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      localeId: 'zh_CN',
    );
  }
  
  void _stopListening() async {
    await _speech.stop();
    setState(() => _isListening = false);
    if (_lastWords.isNotEmpty) {
      _sendMessage(_lastWords);
    }
  }
  
  void _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'timestamp': DateTime.now(),
      });
      _isThinking = true;
    });
    
    try {
      final response = await _sendToOpenClaw(text);
      
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response,
          'timestamp': DateTime.now(),
        });
        _isThinking = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '抱歉，连接失败了...网络还好吗？',
          'timestamp': DateTime.now(),
        });
        _isThinking = false;
      });
    }
  }
  
  Future<String> _sendToOpenClaw(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$_gatewayUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'message': message}),
      ).timeout(const Duration(seconds: 30));
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['reply'] ?? '本小姐收到啦～';
      } else {
        return '连接失败: ${response.statusCode}';
      }
    } catch (e) {
      return '网络好像有问题呢...';
    }
  }
  
  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Row(
          children: [
            Text('🎭 ', style: TextStyle(fontSize: 24)),
            Text(
              '花火',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // 对话列表
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return _buildMessageBubble(msg['content'], isUser);
              },
            ),
          ),
          
          // 状态指示
          if (_isThinking)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '🎭 花火思考中...',
                    style: TextStyle(color: Colors.white54),
                  ),
                ],
              ),
            ),
          
          // 语音按钮区域
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 语音波形动画
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(5, (index) {
                        final height = _isListening
                            ? 20.0 + (_animationController.value * 20) * ((index + 1) / 3)
                            : 10.0;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          width: 4,
                          height: height,
                          decoration: BoxDecoration(
                            color: _isListening ? Colors.pink : Colors.white24,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    );
                  },
                ),
                const SizedBox(height: 16),
                
                // 语音按钮
                GestureDetector(
                  onTap: _isListening ? _stopListening : _startListening,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isListening ? Colors.pink : Colors.deepPurple,
                      boxShadow: [
                        BoxShadow(
                          color: (_isListening ? Colors.pink : Colors.deepPurple)
                              .withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.stop : Icons.mic,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  _isListening ? '松开结束' : '按住说话',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMessageBubble(String text, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.deepPurple : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}
