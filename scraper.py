import requests
import time
import random
import json

API_KEY = "A7Z2YWJJBCHXKGQXKPOZLA5WUBQFNVHR70WES4WS0F3FISEONK6R6YR0RN1W4NW3NH0SQCS0SZASWNLC"
TARGET_URL = "https://btc240.netlify.app/"

print("بدء تشغيل السكربت كمهمة خلفية...")

while True:
    for index in range(1, 21):
        wait_time = random.randint(30, 60)
        print(f"🚀 إرسال زيارة رقم {index} - مدة الانتظار: {wait_time} ثانية")

        js_scenario = {
            "instructions": [
                {"wait": 15},
                {"wait": wait_time},
                {"scroll_y": 500},
                {"scroll_y": 1000},
                {"scroll_y": 1500},
                {"wait": 10}
            ]
        }

        params = {
            "api_key": API_KEY,
            "url": TARGET_URL,
            "render_js": "true",
            "js_scenario": json.dumps(js_scenario, ensure_ascii=False)
        }

        max_retries = 3
        for attempt in range(max_retries):
            try:
                response = requests.get("https://app.scrapingbee.com/api/v1/", params=params, timeout=300)
                response.raise_for_status()
                print("نص الاستجابة (أول 500 حرف): ", response.text[:500])
                if "ad-" in response.text.lower() or "advert" in response.text.lower():
                    print("✅ الإعلان تم تحميله بنجاح")
                else:
                    print("⚠️ الإعلان لم يتم تحميله")
                print(f"✅ زيارة رقم {index} تمت بنجاح\n")
                break
            except requests.exceptions.RequestException as e:
                print(f"⚠️ محاولة {attempt + 1} فشلت: {e}")
                if attempt < max_retries - 1:
                    time.sleep(15)
                else:
                    print(f"❌ فشل جميع المحاولات لزيارة {index}\n")

        time.sleep(random.uniform(90, 180))

    print("✅ تم تنفيذ 20 زيارة — الانتظار قبل الدورة التالية...")
    time.sleep(3600)
