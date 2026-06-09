import concurrent.futures
from fastapi import APIRouter
from pydantic import BaseModel
from typing import List, Optional, Dict, Any
import time
from collections import Counter

from prompt import process_llm
from back_commu import fetch_analysis_from_backend
from exchange import process_exchange_rates


router = APIRouter()

class UserPreferences(BaseModel):
    spicy: int
    salty: int
    sweet: int
    meat: int
    seafood: int
    vegetarian: int

class Vertex(BaseModel):
    x: int
    y: int


class MenuItemInput(BaseModel):
    box_id: str
    raw_text: str
    vertices: List[Vertex]

class AnalyzeMenuRequest(BaseModel):
    departure_language: str
    arrival_language: str
    user_allergies: List[str]
    user_preferences: UserPreferences
    menu_items: List[MenuItemInput]

class ContentData(BaseModel):
    item_type: str
    raw_text: str
    translated_text: Optional[str] = None
    converted_price: Optional[str] = None
    normalized_text: Optional[str] = None

class LayoutData(BaseModel):
    source_box_ids: List[str]
    direction: Optional[str] = None
    ratio: Optional[float] = None



class RiskAnalyzedResult(BaseModel):
    dish_id: Optional[int] = 0
    risk_level: Optional[str] = None
    risk_causes: Optional[List[str]] = None

class AnalyzedMenuItemOutput(BaseModel):
    item_id: str
    content: ContentData
    layout: LayoutData
    risk_analyzed_result: Optional[RiskAnalyzedResult] = None

class Recommendation(BaseModel):
    item_id: str
    korean_name: str

class RecommendationResponse(BaseModel):
    category: List[Recommendation] = []
    taste: List[Recommendation] = []

class AnalyzeMenuResponse(BaseModel):
    status: str
    error_code: Optional[str] = None
    error_message: Optional[str] =None
    analyzed_menu_items: List[AnalyzedMenuItemOutput]
    recommendations: RecommendationResponse

# 병렬 작업 
def get_y_coords(vertices):
    return [v['y'] for v in vertices]

def smart_chunking(raw_menus: list, target_size: int = 5 , max_size: int = 8, safe_gap: int = 25) -> list:
    chunks = []
    current_chunk = []
    
    for i, menu in enumerate(raw_menus):
        current_chunk.append(menu)
        
        if i < len(raw_menus) - 1:
            curr_y_max = max(get_y_coords(menu['vertices']))
            next_y_min = min(get_y_coords(raw_menus[i+1]['vertices']))
            
            gap = next_y_min - curr_y_max
            
            is_safe_to_cut = (len(current_chunk) >= target_size) and (gap > safe_gap)
            
            is_forced_to_cut = (len(current_chunk) >= max_size)
            
            if is_safe_to_cut or is_forced_to_cut:
                chunks.append(current_chunk)
                current_chunk = [] 
                
    if current_chunk:
        chunks.append(current_chunk) 
        
    return chunks


@router.post("/api/analyze-menu", response_model=AnalyzeMenuResponse)
def analyze_menu(request: AnalyzeMenuRequest):
    print("==================================================")
    print("프론트엔드 데이터 요청 도착")
    
    llm_input_data = [item.model_dump() for item in request.menu_items]

    chunks = smart_chunking(llm_input_data, target_size=5, max_size=8, safe_gap=25)
    
    print(f"[메뉴 병렬 분석 시작] 총 원본 아이템 개수: {len(llm_input_data)}개")
    print(f"[스마트 청킹 결과] 총 {len(chunks)}개의 스레드로 분할 호출합니다.")

    for idx, chunk in enumerate(chunks):
        if chunk: 
            start_box = chunk[0].get("box_id")
            end_box = chunk[-1].get("box_id")
            print(f"   ➡️ [스레드 {idx + 1} 할당] 데이터 {len(chunk)}개 (범위: {start_box} ~ {end_box})")
    print("==================================================")

    llm_start_time = time.time()
    all_analyzed_items = []
    chunk_results = [[] for _ in range(len(chunks))]
    has_error = False
    currency_votes = []

    with concurrent.futures.ThreadPoolExecutor(max_workers=len(chunks)) as executor:
        future_to_idx = {
            executor.submit(process_llm, chunk, request.departure_language): idx
            for idx, chunk in enumerate(chunks)
        }
        
        for future in concurrent.futures.as_completed(future_to_idx):
            idx = future_to_idx[future]
            result = future.result()
            
            if result.get("status") == "error":
                has_error = True
                
            chunk_results[idx] = result.get("analyzed_menu_items", [])

            chunk_currency = result.get("currency")
            if chunk_currency:
                currency_votes.append(chunk_currency.upper())

    final_currency = "KRW"
    if currency_votes:
        final_currency = Counter(currency_votes).most_common(1)[0][0]

    print(f"⏱️ LLM 병렬 처리 소요 시간: {time.time() - llm_start_time:.2f}초")
    print(f"💰 LLM이 추론한 메뉴판 통화 코드: {final_currency}")

    if has_error or not any(chunk_results):
        return AnalyzeMenuResponse(
            status="error",
            error_code="LLM_ERROR",
            error_message="LLM 처리 중 오류 발생",
            analyzed_menu_items=[],
            recommendations=RecommendationResponse(category=[], taste=[])
        )
    
    all_analyzed_items = []

    for items in chunk_results:
         all_analyzed_items.extend(items)


    for idx, item in enumerate(all_analyzed_items):
        item["item_id"] = f"result_{idx + 1:03d}"

    
    llm_items = process_exchange_rates(
        llm_items = all_analyzed_items,
        departure_currency = final_currency,
    )

    backend_request_data = []
    for item in llm_items:
        content = item.get("content", {})

        if content.get("item_type") == "menu_name" and content.get("normalized_text"):
            backend_request_data.append({
                "item_id": item["item_id"],
                "normalized_text": content["normalized_text"]
            })


    print("백엔드 서버로 위험도/추천 분석 요청")
    backend_start_time = time.time()

    backend_response = fetch_analysis_from_backend(
        departure_language = request.departure_language,
        user_allergies=request.user_allergies,
        user_preferences=request.user_preferences.model_dump(),
        normalized_items=backend_request_data
    )

    backend_duration = time.time() - backend_start_time
    print(f"⏱️ 백엔드(추천/위험도) 처리 소요 시간: {backend_duration:.2f}초")

    backend_response_data = {res["item_id"]: res for res in backend_response.get("menu_results", [])}


    final_analyzed_items = []

    for item in llm_items:
        item_id = item["item_id"]
        content = item.get("content", {})
        layout = item.get("layout", {})

        be_data = backend_response_data.get(item_id)

        risk_result = None
        if be_data:
            risk_result = RiskAnalyzedResult(
                dish_id=be_data.get("dish_id", 0),
                risk_level=be_data.get("risk_level", "safe"),
                risk_causes=be_data.get("risk_causes", [])
            )


        final_analyzed_items.append(
           AnalyzedMenuItemOutput(
                item_id=item_id,
                content=ContentData(**content),
                layout=LayoutData(**layout),
                risk_analyzed_result=risk_result
            )
        )

    raw_recs = backend_response.get("recommendations", {})

    category_recs = [
        Recommendation(
            item_id=rec["item_id"], 
            korean_name=rec["korean_name"]
        )
        for rec in raw_recs.get("category",[])
    ]

    taste_recs = [
        Recommendation(
            item_id=rec["item_id"],
            korean_name=rec["korean_name"]
        )
        for rec in raw_recs.get("taste",[])
    ]

    final_recommendations = RecommendationResponse(
        category = category_recs,
        taste=taste_recs
    )

    print("✅ 분석 완료! 결과를 반환합니다.")
    print("==================================================")

    return AnalyzeMenuResponse(
        status="success",
        analyzed_menu_items=final_analyzed_items,
        recommendations=final_recommendations
    )