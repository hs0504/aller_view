import requests
import json

BACKEND_URL = "https://allerview-729003075709.asia-northeast3.run.app/menu/analyze"

def fetch_analysis_from_backend(user_allergies: list, user_preferences: dict, normalized_items: list) -> dict:


    payload = {
        "user_allergies": user_allergies,
        "user_preferences": user_preferences,
        "menu_items": normalized_items
    }

    try:
        response = requests.post(BACKEND_URL, json=payload, timeout=10.0)
        response.raise_for_status()
        return response.json()
        
    except requests.exceptions.RequestException as e:
        print("\n")
        print(f"Backend 통신 에러 발생: {e}")
        
        if hasattr(e, 'response') and e.response is not None:
            print("\n[백엔드 서버가 보낸 상세 에러 메시지]")
            try:
                error_detail = e.response.json()
                print(json.dumps(error_detail, indent=2, ensure_ascii=False))
            except:
                print(e.response.text)
        print("\n")
        
        return {}
        