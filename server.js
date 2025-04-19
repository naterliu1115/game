const express = require('express');
const axios = require('axios');
require('dotenv').config();

const app = express();
app.use(express.json());

const DISCORD_WEBHOOK_URL = process.env.DISCORD_WEBHOOK_URL;

let lastPushTime = 0;
const COOLDOWN_MS = 10000;
const MAX_RETRIES = 10;
const RETRY_DELAY_MS = 2 * 60 * 1000; // 2 分鐘

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
  res.status(200).send("Webhook received. Will attempt to notify Discord up to 10 times.");

  // ✅ 啟動 retry 任務
  let attempt = 0;

  const trySend = async () => {
    try {
      attempt++;
      console.log(`📤 Attempt ${attempt} sending to Discord...`);

      const response = await axios.post(DISCORD_WEBHOOK_URL, message, {
        headers: {
          'User-Agent': 'MyWebhookBridge/1.0',
          'Content-Type': 'application/json'
        },
        timeout: 5000
      });

      lastPushTime = Date.now();
      console.log(`✅ Delivered on attempt ${attempt}`, response.status);
    } catch (err) {
      console.error(`❌ Failed on attempt ${attempt}:`, err.message);
      if (attempt < MAX_RETRIES) {
        console.log(`🔁 Waiting 2 minutes before retrying...`);
        setTimeout(trySend, RETRY_DELAY_MS);
      } else {
        console.error("❌ Max retries reached. Giving up.");
      }
    }
  };

  // 開始第一次發送
  trySend();
});

app.get("/", (req, res) => {
  res.send("🟢 GitHub → Discord Webhook Bridge is running");
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server is running on port ${PORT}`);
});
