from fastapi import FastAPI, Request, Response
from fastapi.middleware.cors import CORSMiddleware
from front_commu import router as front_router
import json

app = FastAPI(title="AllerView AI Server")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], 
    allow_credentials=True,
    allow_methods=["*"], 
    allow_headers=["*"], 
)

@app.middleware("http")
async def log(request: Request, call_next):
    req_body = await request.body()
    if req_body:
        print("\n" + "="*50)
        print(f"[요청 들어옴] {request.method} {request.url.path}")
        try:
            print("")
            ##print(json.dumps(json.loads(req_body), indent=2, ensure_ascii=False))
        except:
            print(req_body.decode("utf-8"))
        print("="*50 + "\n")
    
    response = await call_next(request)

    res_body = b""
    async for chunk in response.body_iterator:
        res_body += chunk

    print(f"[응답 나감] 상태코드: {response.status_code}")
    try:
        print("")
        ##print(json.dumps(json.loads(res_body), indent=2, ensure_ascii=False))
    except:
        print(res_body.decode("utf-8")[:500] + " ... (이하 생략)") 
    print("="*50 + "\n")

    return Response(
        content=res_body,
        status_code=response.status_code,
        headers=dict(response.headers),
        media_type=response.media_type
    )

app.include_router(front_router)

@app.get("/")
def read_root():
    return {"message": "AI 서버가 작동 중입니다!_2026년 6월 9일 업데이트 완료"}