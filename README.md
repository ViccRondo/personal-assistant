# Personal Assistant - 花火 🎭

一个语音助手 App，可以和来自匹诺康尼的剧作家花火直接对话！

## 功能特性

- 🎙️ **语音输入** - 按住说话，支持中文语音识别
- 🔊 **语音回复** - 语音播报回复内容
- 💬 **自然对话** - AI 对话能力，理解上下文
- 🎨 **精美界面** - 暗色主题，流畅动画

## 技术栈

- **Flutter** - 跨平台 UI 框架
- **speech_to_text** - 语音识别
- **flutter_tts** - 语音合成
- **Minimax API** - AI 对话能力（需要配置）

## 快速开始

### 1. 克隆项目
```bash
git clone https://github.com/ViccRondo/personal-assistant.git
cd personal-assistant
```

### 2. 安装依赖
```bash
flutter pub get
```

### 3. 运行
```bash
flutter run
```

### 4. 构建 APK
```bash
flutter build apk --debug
```

## 配置 API

### Minimax API（对话能力）
在 `lib/home_page.dart` 中替换：
```dart
static const String _apiKey = 'YOUR_MINIMAX_API_KEY';
```

### TTS 配置
可以使用系统 TTS 或接入 Minimax TTS API。

## 权限

- `RECORD_AUDIO` - 语音录制
- `INTERNET` - 网络请求

## 项目结构

```
lib/
├── main.dart          # 应用入口
└── home_page.dart     # 主界面（语音对话）
```

## 截图

[待添加]

## License

MIT
