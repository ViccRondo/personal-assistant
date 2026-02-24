const express = require('express');
const cors = require('cors');
const axios = require('axios');

const app = express();
const PORT = process.env.PORT || 3004;

app.use(cors());
app.use(express.json());

// OpenClaw Gateway URL
const GATEWAY_URL = process.env.GATEWAY_URL || 'http://101.47.159.98:18789';

app.post('/api/chat', async (req, res) => {
  const { message } = req.body;
  
  if (!message) {
    return res.json({ reply: '本小姐没听清楚呢...' });
  }
  
  try {
    // Forward to OpenClaw gateway
    const response = await axios.post(`${GATEWAY_URL}/api/chat`, {
      message: message
    }, {
      timeout: 30000
    });
    
    res.json({ reply: response.data?.reply || '本小姐收到啦～' });
  } catch (error) {
    console.error('Gateway error:', error.message);
    // Fallback response when gateway is unavailable
    res.json({ reply: '本小姐现在有点困，等会儿再聊吧～' });
  }
});

app.get('/health', (req, res) => {
  res.json({ status: 'ok' });
});

app.listen(PORT, () => {
  console.log(`Voice Assistant API running on port ${PORT}`);
  console.log(`Gateway: ${GATEWAY_URL}`);
});
