const express = require("express");
const fetch = require("node-fetch");
const cron = require("node-cron");
const path = require("path");

const app = express();
const PORT = process.env.PORT || 3000;

const TELEGRAM_BOT_TOKEN = "7559836941:AAFFgyR1TWjyYmmNc-IPyr6NpZZdUXRrP_c";
const TELEGRAM_CHAT_ID = "6814152338";

let recommendedCoins = [];
let sentCoins = new Set();

app.use(express.static("public"));

async function getUSDTMarkets() {
  try {
    const res = await fetch("https://api.binance.com/api/v3/exchangeInfo");
    const data = await res.json();
    return data.symbols
      .filter(s => s.symbol.endsWith("USDT") && s.status === "TRADING")
      .map(s => s.symbol);
  } catch (err) {
    console.error("فشل في جلب الأزواج:", err.message);
    return [];
  }
}

async function checkBuyPressure(symbol) {
  const url = `https://api.binance.com/api/v3/trades?symbol=${symbol}&limit=20`;
  try {
    const res = await fetch(url);
    const trades = await res.json();
    const buyTrades = trades.filter(t => !t.isBuyerMaker);
    const buyRatio = (buyTrades.length / trades.length) * 100;

    if (buyRatio > 70 && !sentCoins.has(symbol)) {
      const coinData = { symbol, buyRatio: buyRatio.toFixed(2) };
      recommendedCoins.push(coinData);
      await sendToTelegram(coinData);
      sentCoins.add(symbol);
    }
  } catch (err) {
    console.error(`خطأ في ${symbol}:`, err.message);
  }
}

async function sendToTelegram(coin) {
  const msg = `🚀 العملة: ${coin.symbol}
نسبة الشراء: ${coin.buyRatio}%
مرشحة للارتفاع قريبًا!`;
  const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
  try {
    await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ chat_id: TELEGRAM_CHAT_ID, text: msg })
    });
    console.log(`✅ أُرسلت: ${coin.symbol}`);
  } catch (err) {
    console.error("فشل في الإرسال:", err.message);
  }
}

cron.schedule("*/5 * * * *", async () => {
  console.log("تشغيل تلقائي...");
  recommendedCoins = [];
  const pairs = await getUSDTMarkets();
  for (const coin of pairs.slice(0, 50)) {
    await checkBuyPressure(coin);
  }
});

app.get("/coins", (req, res) => res.json(recommendedCoins));

app.get("/", (req, res) => {
  res.sendFile(path.join(__dirname, "public", "index.html"));
});

app.listen(PORT, () => console.log(`الخادم يعمل على http://localhost:${PORT}`));
