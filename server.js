const express = require('express');
const axios = require('axios');
require('dotenv').config(); // 載入 .env 的內容

const app = express();
app.use(express.json());

// 從環境變數中讀取 Webhook URL
const DISCORD_WEBHOOK_URL = process.env.DISCORD_WEBHOOK_URL;

let lastPushTime = 0;
const COOLDOWN_MS = 10000;

app.post("/", async (req, res) => {
  const now = Date.now();
  if (now - lastPushTime < COOLDOWN_MS) {
    console.log("⏱️ Cooldown: Message blocked to avoid spam");
    return res.status(429).send("Too many requests, slow down.");
  }

  if (!req.body || !req.body.repository || !req.body.pusher) {
    console.log("❌ Invalid payload:", req.body);
    return res.status(400).send("Invalid webhook payload");
  }

  const { repository, pusher, commits } = req.body;

  if (!commits || commits.length === 0) {
    console.log("📭 No commits in this push");
    return res.status(200).send("No commits to process");
  }

  const commitText = commits.map(c =>
    `\n• [${c.id.substring(0, 7)}](${c.url}) ${c.message} - ${c.author.name}`
  ).join('\n');

  const message = {
    embeds: [{
      title: `🛠️ 新進度來啦！`,
      description: `**${pusher.name}** pushed ${commits.length} commit(s) to **${repository.name}**${commitText}`,
      color: 5814783,
      footer: { text: "大家一起來測一下!" },
      timestamp: new Date().toISOString()
    }]
  };

  // ✅ 提前回應 GitHub，避免 timeout
  res.status(200).send("Webhook received. Will notify Discord after 2 minutes.");

  // ✅ 延遲 2 分鐘後發送 webhook 給 Discord
  setTimeout(() => {
    axios.post(DISCORD_WEBHOOK_URL, message, {
      headers: {
        'User-Agent': 'MyWebhookBridge/1.0',
        'Content-Type': 'application/json'
      },
      timeout: 5000
    }).then(response => {
      lastPushTime = Date.now();
      console.log("✅ [DELAYED] Delivered to Discord!", response.status);
    }).catch(err => {
      console.error("❌ [DELAYED] Error sending webhook:", err.message);
      if (err.response) {
        console.error("📛 Response:", err.response.status, err.response.data);
      }
    });
  }, 2 * 60 * 1000); // 2 分鐘延遲
});

app.get("/", (req, res) => {
  res.send("🟢 GitHub → Discord Webhook Bridge is running");
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT}`);
});
