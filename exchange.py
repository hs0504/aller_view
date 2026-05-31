
# 2026년 5월 25일 기준
CURRENCY_TO_KRW = {
    "ko": 1.0,         # 한국어: 1원 = 1원
    "en": 1506.0,      # 영어: 1달러 = 1506.0원 (USD)
    "ja": 9.45,        # 일본어: 1엔 = 9.45원 (JPY)
    "zh-CN": 222.08,   # 중국어 간체: 1위안 = 222.08원 (CNY)
    "zh-TW": 47.97,    # 중국어 번체: 1대만달러 = 47.97원 (TWD)
    "es": 1754.94,     # 스페인어: 1유로 = 1754.94원 (EUR)
    "fr": 1754.94,     # 프랑스어: 1유로 = 1754.94원 (EUR)
    "de": 1754.94,     # 독일어: 1유로 = 1754.94원 (EUR)
    "it": 1754.94,     # 이탈리아어: 1유로 = 1754.94원 (EUR)
    "pt": 1754.94,     # 포르투갈어: 1유로 = 1754.94원 (EUR)
    "vi": 0.057,       # 베트남어: 1동 = 0.057원 (VND)
    "th": 46.30,       # 태국어: 1바트 = 46.30원 (THB)
    "id": 0.085,       # 인도네시아어: 1루피아 = 0.085원 (IDR)
    "ar": 409.37,      # 아랍어: 1디르함 = 409.37원 (AED)
    "ru": 21.22        # 러시아어: 1루블 = 21.22원 (RUB)
}

def format_price_by_language(value: float, arrival_lang: str) -> str:
    
    if arrival_lang == "en":
        return f"${value:,.2f}"  
        
    elif arrival_lang == "ja":
        return f"¥{value:,.0f}"  
        
    elif arrival_lang == "zh-CN":
        return f"¥{value:,.2f}"  
        
    elif arrival_lang == "zh-TW":
        return f"NT${value:,.0f}"  
        
    elif arrival_lang in ["es", "fr", "de", "it", "pt"]:
        return f"€{value:,.2f}"  
        
    elif arrival_lang == "vi":
        return f"{value:,.0f}₫"  
        
    elif arrival_lang == "th":
        return f"฿{value:,.2f}"  
        
    elif arrival_lang == "id":
        return f"Rp {value:,.0f}"  
        
    elif arrival_lang == "ar":
        return f"AED {value:,.2f}"  
        
    elif arrival_lang == "ru":
        return f"₽{value:,.2f}"  
        
    else:
        return f"{value:,.0f}원"


def process_exchange_rates(llm_items: list, departure_lang: str, arrival_lang: str) -> list:
    
    dep_rate = CURRENCY_TO_KRW.get(departure_lang, 1.0)
    arr_rate = CURRENCY_TO_KRW.get(arrival_lang, 1.0)

    for item in llm_items:
        content = item.get("content", {})
        
        if content.get("item_type") == "price" and content.get("converted_price"):
            try:
                raw_price_str = str(content["converted_price"]).replace(",", "").strip()
                pure_number = float(raw_price_str)

                if departure_lang == "ko":
                    if pure_number < 100 or "." in raw_price_str:
                        pure_number *= 1000
                
                price_in_krw = pure_number * dep_rate
                
                final_converted_value = price_in_krw / arr_rate
                
                final_price_str = format_price_by_language(final_converted_value, arrival_lang)
                
                content["converted_price"] = final_price_str
                
            except ValueError:
                content["converted_price"] = content.get("raw_text", "")

    return llm_items