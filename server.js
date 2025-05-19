// server.js
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

app.use(express.static(path.join(__dirname, "public")));

async function getUSDTMarkets() {
  try {
    const res = await fetch("https://api.binance.com/api/v3/exchangeInfo");
    const data = await res.json();
    return data.symbols
      .filter(s => s.symbol.endsWith("USDT") && s.status === "TRADING")
      .map(s => s.symbol)
      .slice(0, 1000); // فحص 1000 عملة فقط
  } catch (err) {
    console.error("فشل في جلب أزواج USDT:", err.message);
    return [];
  }
}

async function checkCoin(symbol) {
  try {
    // شمعة الساعة الأخيرة
    const klineUrl = `https://api.binance.com/api/v3/klines?symbol=${symbol}&interval=1h&limit=2`;
    const klineRes = await fetch(klineUrl);
    const klines = await klineRes.json();
    const lastCandle = klines[klines.length - 2];
    if (!lastCandle) return;

    const open = parseFloat(lastCandle[1]);
    const close = parseFloat(lastCandle[4]);
    const volume = parseFloat(lastCandle[5]);
    if (close <= open) return; // ليست شمعة دعم واضحة

    // تحليل صفقات الشراء مقابل البيع
    const tradeUrl = `https://api.binance.com/api/v3/trades?symbol=${symbol}&limit=1000`;
    const tradeRes = await fetch(tradeUrl);
    const trades = await tradeRes.json();

    const buyTrades = trades.filter(t => !t.isBuyerMaker);
    const buyVolume = buyTrades.reduce((sum, t) => sum + parseFloat(t.qty), 0);
    const totalVolume = trades.reduce((sum, t) => sum + parseFloat(t.qty), 0);
    const buyRatio = (buyVolume / totalVolume) * 100;

    if (buyRatio > 70 && volume > 500000) { // الحيتان يشترون عند دعم
      const coinData = { symbol, buyRatio: buyRatio.toFixed(2), volume: volume.toFixed(2) };

      if (!sentCoins.has(symbol)) {
        recommendedCoins.push(coinData);
        await sendToTelegram(coinData);
        sentCoins.add(symbol);
      }
    }
  } catch (err) {
    console.error(`خطأ في فحص ${symbol}:`, err.message);
  }
}

async function sendToTelegram(coin) {
  const msg = `🚨 عملة محتملة للارتفاع 🚨\n\n` +
              `العملة: ${coin.symbol}\n` +
              `نسبة الشراء: ${coin.buyRatio}%\n` +
              `حجم الشمعة: ${coin.volume}`;
  const url = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;
  try {
    await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ chat_id: TELEGRAM_CHAT_ID, text: msg })
    });
    console.log(`✅ تم إرسال ${coin.symbol}`);
  } catch (err) {
    console.error("فشل إرسال الرسالة إلى تيليجرام:", err.message);
  }
}

cron.schedule("*/5 * * * *", async () => {
  console.log("تشغيل الفحص التلقائي...");
  recommendedCoins = [];
  const usdtPairs = await getUSDTMarkets();
  for (const coin of usdtPairs) {
    await checkCoin(coin);
  }
});

app.get("/coins", (req, res) => {
  res.json(recommendedCoins);
});

app.listen(PORT, () => {
  console.log("الخادم يعمل على http://localhost:" + PORT);
});
