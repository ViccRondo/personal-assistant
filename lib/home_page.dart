import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

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
  
  // TTS
  final FlutterTts _flutterTts = FlutterTts();
  bool _isSpeaking = false;
  
  // 对话
  final List<Map<String, dynamic>> _messages = [];
  bool _isListening = false;
  bool _isThinking = false;
  
  // 动画
  late AnimationController _animationController;
  
  // API 配置
  static const String _apiUrl = 'https://api.minimax.chat/v1/text/chatcompletion_pro';
  static const String _apiKey = 'YOUR_MINIMAX_API_KEY'; // 需要替换
  
  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    // 添加欢迎消息
    _messages.add({
      'role': 'assistant',
      'content': '观众～你好呀！我是花火，随时准备和你聊天哦！🎭',
      'timestamp': DateTime.now(),
    });
  }
  
  void _initSpeech() async {
    _speechEnabled = await _speech.initialize(
      onError: (error) => print('Speech error: $error'),
      onStatus: (status) => print('Speech status: $status'),
    );
    setState(() {});
  }
  
  void _initTts() async {
    // 配置中文 TTS
    await _flutterTts.setLanguage('zh-CN');
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setPitch(1.0);
    
    _flutterTts.setStartHandler(() {
      setState(() => _isSpeaking = true);
    });
    
    _flutterTts.setCompletionHandler(() {
      setState(() => _isSpeaking = false);
    });
    
    _flutterTts.setErrorHandler((msg) {
      setState(() => _isSpeaking = false);
    });
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
    
    // 添加用户消息
    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
        'timestamp': DateTime.now(),
      });
      _isThinking = true;
    });
    
    // 发送 API 请求
    try {
      final response = await _sendToAI(text);
      
      // 添加 AI 回复
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response,
          'timestamp': DateTime.now(),
        });
        _isThinking = false;
      });
      
      // 语音播放
      await _speak(response);
    } catch (e) {
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': '抱歉，我刚才走神了...可以再说一次吗？',
          'timestamp': DateTime.now(),
        });
        _isThinking = false;
      });
    }
  }
  
  Future<String> _sendToAI(String message) async {
    // 这里是对接 OpenClaw 或其他 AI API 的示例
    // 需要根据实际情况配置
    
    final sessionId = const Uuid().v4();
    
    // 模拟 API 调用 - 实际需要对接真实 API
    // 这里返回一个模拟的回复
    await Future.delayed(const Duration(seconds: 1));
    
    final replies = [
      '观众～本小姐听到了呢！🎭',
      '哎呀，哥哥说什么？本小姐没听清楚～',
      '这场对话，只为你而准备哦～♠️',
      '有趣！本小姐喜欢和你聊天～',
      '哥哥今天怎么样呀？本小姐在这里陪你～',
    ];
    
    return replies[DateTime.now().second % replies.length];
  }
  
  Future<void> _speak(String text) async {
    // 使用 Minimax TTS 或系统 TTS
    // 这里先用系统 TTS，实际可以对接 Minimax API
    
    try {
      await _flutterTts.speak(text);
    } catch (e) {
      print('TTS error: $e');
    }
  }
  
  void _stopSpeaking() async {
    await _flutterTts.stop();
    setState(() => _isSpeaking = false);
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
    _flutterTts.stop();
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
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54),
            onPressed: () {
              _showSettingsDialog();
            },
          ),
        ],
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
          
          // 思考/说话状态指示
          if (_isThinking || _isSpeaking)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isThinking)
                    const Text(
                      '🎭 花火思考中...',
                      style: TextStyle(color: Colors.white54),
                    ),
                  if (_isSpeaking)
                    const Text(
                      '🔊 花火说话中...',
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
                  onLongPress: _isSpeaking ? _stopSpeaking : null,
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
  
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2A2A4E),
        title: const Text('⚙️ 设置', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.volume_up, color: Colors.white),
              title: const Text('语音回复', style: TextStyle(color: Colors.white)),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: Colors.pink,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.mic, color: Colors.white),
              title: const Text('语音输入', style: TextStyle(color: Colors.white)),
              trailing: Switch(
                value: true,
                onChanged: (value) {},
                activeColor: Colors.pink,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('关闭'),
          ),
        ],
      ),
    );
  }
}
