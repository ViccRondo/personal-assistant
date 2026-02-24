import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

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
  
  // 设置
  String _apiKey = '';
  String _apiUrl = 'https://api.minimax.chat/v1/text/chatcompletion_pro';
  String _model = 'abab6.5s-chat';
  bool _voiceReplyEnabled = true;
  bool _voiceInputEnabled = true;
  
  @override
  void initState() {
    super.initState();
    _initSpeech();
    _initTts();
    _loadSettings();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
    
    // 添加欢迎消息
    _messages.add({
      'role': 'assistant',
      'content': '观众～你好呀！我是花火，随时准备和你聊天哦！🎭\n\n首次使用请先设置API Key，点击右上角⚙️进入设置～',
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
  
  void _initTts() async {
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
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _apiKey = prefs.getString('api_key') ?? '';
      _apiUrl = prefs.getString('api_url') ?? 'https://api.minimax.chat/v1/text/chatcompletion_pro';
      _model = prefs.getString('model') ?? 'abab6.5s-chat';
      _voiceReplyEnabled = prefs.getBool('voice_reply') ?? true;
      _voiceInputEnabled = prefs.getBool('voice_input') ?? true;
    });
  }
  
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_key', _apiKey);
    await prefs.setString('api_url', _apiUrl);
    await prefs.setString('model', _model);
    await prefs.setBool('voice_reply', _voiceReplyEnabled);
    await prefs.setBool('voice_input', _voiceInputEnabled);
  }
  
  void _startListening() async {
    if (!_voiceInputEnabled) {
      _showMessage('语音输入已关闭，请在设置中开启');
      return;
    }
    if (!_speechEnabled) {
      _showMessage('语音识别不可用，请确保已授予麦克风权限，并检查系统设置中是否启用了语音识别');
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
      listenMode: stt.ListenMode.confirmation,
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
      final response = await _sendToAI(text);
      
      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': response,
          'timestamp': DateTime.now(),
        });
        _isThinking = false;
      });
      
      if (_voiceReplyEnabled) {
        await _speak(response);
      }
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
    if (_apiKey.isEmpty) {
      return '观众～还没有设置API Key呢！\n请先点击右上角⚙️设置好API Key再来和本小姐聊天吧～🎭';
    }
    
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'messages': [
            {
              'role': 'system',
              'content': '你是花火，来自游戏《崩坏：星穹铁道》的角色。你是一个来自匹诺康尼的剧作家，属于「假面愚者」组织。你的性格：古灵精怪、神秘莫测、偶尔认真偶尔调皮、自称「本小姐」。口头禅：「观众～」「这场表演只为你而准备」。现在请用中文和用户聊天，保持轻松愉快的语气，但不要过于话痨。'
            },
            {'role': 'user', 'content': message}
          ],
          'temperature': 0.7,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return 'API请求失败了...${response.statusCode}';
      }
    } catch (e) {
      return '网络好像有点问题呢...';
    }
  }
  
  Future<void> _speak(String text) async {
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
            onPressed: () => _showSettingsDialog(),
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
          
          // 状态指示
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
    final apiKeyController = TextEditingController(text: _apiKey);
    final apiUrlController = TextEditingController(text: _apiUrl);
    final modelController = TextEditingController(text: _model);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF2A2A4E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 标题
                  Row(
                    children: [
                      const Text('⚙️ ', style: TextStyle(fontSize: 24)),
                      const Text(
                        '设置',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // API 配置
                  const Text('API 配置', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  // API Key
                  TextField(
                    controller: apiKeyController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'API Key',
                      labelStyle: const TextStyle(color: Colors.white54),
                      hintText: '输入你的API Key',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setModalState(() => _apiKey = value),
                  ),
                  const SizedBox(height: 10),
                  
                  // API URL
                  TextField(
                    controller: apiUrlController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'API URL',
                      labelStyle: const TextStyle(color: Colors.white54),
                      hintText: 'API地址',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setModalState(() => _apiUrl = value),
                  ),
                  const SizedBox(height: 10),
                  
                  // Model
                  TextField(
                    controller: modelController,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Model',
                      labelStyle: const TextStyle(color: Colors.white54),
                      hintText: '模型名称',
                      hintStyle: const TextStyle(color: Colors.white24),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (value) => setModalState(() => _model = value),
                  ),
                  const SizedBox(height: 20),
                  
                  // 功能开关
                  const Text('功能开关', style: TextStyle(color: Colors.pink, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  
                  SwitchListTile(
                    title: const Text('语音回复', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('AI回复时自动语音播放', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: _voiceReplyEnabled,
                    activeColor: Colors.pink,
                    onChanged: (value) => setModalState(() => _voiceReplyEnabled = value),
                  ),
                  
                  SwitchListTile(
                    title: const Text('语音输入', style: TextStyle(color: Colors.white)),
                    subtitle: const Text('按住说话进行输入', style: TextStyle(color: Colors.white54, fontSize: 12)),
                    value: _voiceInputEnabled,
                    activeColor: Colors.pink,
                    onChanged: (value) => setModalState(() => _voiceInputEnabled = value),
                  ),
                  const SizedBox(height: 20),
                  
                  // 保存按钮
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        _apiKey = apiKeyController.text;
                        _apiUrl = apiUrlController.text;
                        _model = modelController.text;
                        _saveSettings();
                        Navigator.pop(context);
                        _showMessage('设置已保存！');
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.pink,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('保存设置', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // API 说明
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('💡 API 说明', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        SizedBox(height: 5),
                        Text(
                          '• 默认使用 Minimax API\n'
                          '• 可在MiniMax开放平台获取API Key\n'
                          '• Model推荐: abab6.5s-chat',
                          style: TextStyle(color: Colors.white54, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
