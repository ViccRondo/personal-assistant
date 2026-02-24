# Personal Assistant - 花火 🎭

一个语音助手 App，可以和来自匹诺康尼的剧作家花火直接对话！

## 功能特性

- 🎙️ **语音输入** - 按住说话，支持中文语音识别
- 🔊 **语音回复** - 语音播报回复内容
- 💬 **自然对话** - AI 对话能力，理解上下文
- 🎨 **精美界面** - 暗色主题，流畅动画
- ⚙️ **设置页面** - 可配置 API Key、开关语音功能

## 技术栈

- **Flutter** - 跨平台 UI 框架
- **speech_to_text** - 语音识别
- **flutter_tts** - 语音合成
- **Minimax API** - AI 对话能力（需要配置）

## 快速开始

### 1. 安装 APK
从 GitHub Releases 下载最新 APK：
https://github.com/ViccRondo/personal-assistant/releases

### 2. 配置权限
首次使用需要授予：
- **麦克风权限** - 用于语音输入

### 3. 配置 API
1. 打开 App
2. 点击右上角 ⚙️ 设置按钮
3. 输入你的 API Key（Minimax）
4. 保存设置

## 语音识别启用方法

如果提示"语音识别不可用"，需要：

### 方法1：检查系统语音服务
- 打开手机 **设置**
- 找到 **应用** 或 **应用管理**
- 找到 **语音识别** 或 **Google 语音识别**
- 确保已**启用**

### 方法2：检查默认语音输入
- 设置 → 语言和输入 → 语音输入
- 确保选择的是 Google 语音识别

### 方法3：重新安装/更新 Google Play 服务
某些设备需要 Google Play 服务才能使用语音识别

## 配置 API

### Minimax API（对话能力）
1. 访问 https://platform.minimax.io/
2. 注册账号并获取 API Key
3. 在设置页面输入 API Key

### TTS 配置
使用系统默认 TTS 或在设置中配置 Minimax TTS

## 项目结构

```
lib/
├── main.dart          # 应用入口
└── home_page.dart     # 主界面（语音对话）
```

## 开发

```bash
# 克隆项目
git clone https://github.com/ViccRondo/personal-assistant.git
cd personal-assistant

# 安装依赖
flutter pub get

# 运行
flutter run

# 构建 Release APK
flutter build apk --release
```

## 问题排查

**Q: 语音识别不可用**
A: 
1. 确保已授予麦克风权限
2. 检查系统设置中语音识别服务是否启用
3. 确保设备已连接网络

**Q: API 请求失败**
A: 
1. 检查 API Key 是否正确
2. 检查网络连接
3. 确认 API 余额充足

## License

MIT
