# 2026년 6월 9일 기준

CURRENCY_TO_KRW = {
    # 아시아 / 오세아니아
    "KRW": 1.0,        # 대한민국 원
    "JPY": 9.47,       # 일본 엔 (100엔 기준이 아닌 1엔 기준)
    "CNY": 223.60,     # 중국 위안
    "TWD": 47.99,      # 대만 달러
    "HKD": 193.55,     # 홍콩 달러
    "SGD": 1178.28,    # 싱가포르 달러
    "VND": 0.058,      # 베트남 동
    "THB": 46.22,      # 태국 바트
    "IDR": 0.084,      # 인도네시아 루피아
    "MYR": 376.35,     # 말레이시아 링깃
    "PHP": 24.45,      # 필리핀 페소
    "INR": 15.90,      # 인도 루피
    "AUD": 1069.29,    # 호주 달러
    "NZD": 878.58,     # 뉴질랜드 달러

    # 아메리카
    "USD": 1516.76,    # 미국 달러
    "CAD": 1087.50,    # 캐나다 달러
    "MXN": 86.47,      # 멕시코 페소
    "BRL": 294.66,     # 브라질 헤알
    "ARS": 1.04,       # 아르헨티나 페소
    "CLP": 1.65,       # 칠레 페소
    "COP": 0.42,       # 콜롬비아 페소

    # 유럽
    "EUR": 1749.86,    # 유럽 유로 (스페인, 프랑스, 독일, 이탈리아 등)
    "GBP": 2024.88,    # 영국 파운드
    "CHF": 1904.59,    # 스위스 프랑
    "SEK": 161.37,     # 스웨덴 크로나
    "NOK": 159.63,     # 노르웨이 크로네
    "DKK": 232.94,     # 덴마크 크로네
    "RUB": 20.59,      # 러시아 루블
    "TRY": 32.81,      # 튀르키예 리라

    # 중동 / 아프리카
    "AED": 412.95,     # 아랍에미리트 디르함
    "SAR": 404.34,     # 사우디아라비아 리얄
    "QAR": 416.58,     # 카타르 리얄
    "EGP": 29.00,      # 이집트 파운드
    "ZAR": 91.53       # 남아공 랜드
}

def process_exchange_rates(llm_items: list, departure_currency: str) -> list:
    dep_rate = CURRENCY_TO_KRW.get(departure_currency.upper(), 1.0)
    
    for item in llm_items:
        content = item.get("content", {})
        
        if content.get("item_type") == "price" and content.get("converted_price"):
            try:
                raw_price_str = str(content["converted_price"]).replace(",", "").strip()
                pure_number = float(raw_price_str)

                if departure_currency.upper() == "KRW":
                    if pure_number < 100 or "." in raw_price_str:
                        pure_number *= 1000
                
                price_in_krw = pure_number * dep_rate
                
                content["converted_price"] = f"{price_in_krw:,.0f}원"
                
            except ValueError:
                content["converted_price"] = content.get("raw_text", "")

    return llm_items