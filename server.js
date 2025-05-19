const express = require("express");
const fetch = require("node-fetch");
const cron = require("node-cron");
const bodyParser = require("body-parser");

const app = express();
const PORT = process.env.PORT || 3000;

app.use(bodyParser.json());
app.use(express.static("public"));

const TELEGRAM_BOT_TOKEN = "7559836941:AAFFgyR1TWjyYmmNc-IPyr6NpZZdUXRrP_c";
const TELEGRAM_CHAT_ID = "6814152338";

let recommendedCoins = [];
let sentCoins = new Set();

// جلب أزواج USDT من باينانس
async function getUSDTMarkets() {
  try {
    const res = await fetch("https://api.binance.com/api/v3/exchangeInfo");
    const data = await res.json();
    if (!data.symbols) throw new Error("البيانات غير متوفرة");
    return data.symbols
      .filter(s => s.symbol.endsWith("USDT") && s.status === "TRADING")
      .map(s => s.symbol);
  } catch (err) {
    console.error("فشل في جلب أزواج USDT:", err.message);
    return [];
  }
}

// اختيار 100 عملة عشوائية
function getRandomSample(array, n) {
  const shuffled = [...array].sort(() => 0.5 - Math.random());
  return shuffled.slice(0, n);
}

async function checkBuyPressure(symbol) {
  const url = `https://api.binance.com/api/v3/trades?symbol=${symbol}&limit=20`;

  try {
    const res = await fetch(url);
    const trades = await res.json();
    if (!Array.isArray(trades) || trades.length === 0) return;

    const buyTrades = trades.filter(t => !t.isBuyerMaker);
    const buyRatio = (buyTrades.length / trades.length) * 100;

    if (buyRatio > 60) {
      const coinData = { symbol, buyRatio: buyRatio.toFixed(2) };

      if (!sentCoins.has(symbol)) {
        recommendedCoins.push(coinData);
        await sendToTelegram(coinData);
        sentCoins.add(symbol);
      }
    }
  } catch (err) {
    console.error(`خطأ في ${symbol}:`, err.message);
  }
}

async function sendToTelegram(coin) {
  const msg = `🚀 العملة: ${coin.symbol}\nنسبة الشراء: ${coin.buyRatio}%\nمرشحة للارتفاع قريبًا!`;
  const telegramUrl = `https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/sendMessage`;

  try {
    await fetch(telegramUrl, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ chat_id: TELEGRAM_CHAT_ID, text: msg })
    });
    console.log(`✅ تم إرسال ${coin.symbol} إلى تيليجرام`);
  } catch (err) {
    console.error("فشل إرسال الرسالة إلى تيليجرام:", err.message);
  }
}

// مهمة مجدولة كل 5 دقائق
cron.schedule("*/5 * * * *", async () => {
  console.log("تشغيل الفحص التلقائي...");
  recommendedCoins = [];
  const usdtPairs = await getUSDTMarkets();
  const randomCoins = getRandomSample(usdtPairs, 100);

  for (const coin of randomCoins) {
    await checkBuyPressure(coin);
  }
});

app.get("/coins", (req, res) => {
  res.json(recommendedCoins);
});

app.listen(PORT, () => console.log(`الخادم يعمل على http://localhost:${PORT}`));
