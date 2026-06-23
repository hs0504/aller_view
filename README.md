<p align="center">
<img width="1758" height="514" alt="image" src="https://github.com/user-attachments/assets/da49e106-1f73-4809-833b-faf8732e6e79" />
</p>

<h2 align="center">
  식품 알레르기 사고 예방을 위한 개인 맞춤형 위험 식재료 정보 제공 서비스
</h2>


AllerView는 외국어 메뉴판을 촬영하거나 갤러리에서 불러와 OCR 및 AI 분석을 수행하고, 사용자의 알레르기 정보에 따라 메뉴별 위험정보를 제공하는 모바일 애플리케이션입니다.

사용자는 원본 메뉴판 이미지 위에 표시되는 분석 결과를 통해 위험 메뉴, 안전 메뉴, 추천 메뉴, 가격정보를 직관적으로 확인할 수 있으며, 상세정보와 주문 도우미 기능을 통해 외식 상황에서 알레르기 위험을 줄일 수 있습니다.

<p align="center">
<img width="260" height="480" alt="image" src="https://github.com/user-attachments/assets/57beea96-53fd-4cac-8c5a-eb27eb212dbe" />
</p>

---
## 시연 영상

[AllerView 시연 영상](https://www.youtube.com/shorts/_8kqlmXv1hk?feature=share)

---

## 주요 기능

### 사용자 맞춤 정보 설정

- 닉네임 설정
- 보유 알레르기 항목 선택
- 식성 및 맛 선호 정보 설정
- 설정된 사용자 정보를 기반으로 메뉴별 위험도 및 추천 결과 제공
<img width="130" height="241" alt="image" src="https://github.com/user-attachments/assets/aeb40a55-daf6-41e7-b769-392f6e2b29a5" />
<img width="130" height="241" alt="image" src="https://github.com/user-attachments/assets/cbf11b2d-6c1e-4a2f-a4c3-c1e6997dae6f" />
<img width="130" height="241" alt="image" src="https://github.com/user-attachments/assets/69b874be-24d8-4da1-81b8-ae4070d36e91" />
<img width="130" height="241" alt="image" src="https://github.com/user-attachments/assets/1e197880-2fde-46a2-8133-8ef319d92173" />


### 메뉴판 이미지 분석

- 카메라를 이용한 메뉴판 촬영
- 갤러리에 저장된 메뉴판 이미지 선택
- 분석할 메뉴판 언어 확인 및 변경
- 흔들림이나 흐림이 심한 이미지의 경우 재촬영 안내 제공

<img width="130" height="241" alt="image" src="https://github.com/user-attachments/assets/41f23f3b-0041-4532-8673-efa6ae1ed259" />
<img width="130" height="241" alt="image" src="https://github.com/user-attachments/assets/ce90142b-4f51-49f3-88ed-ce0832fff14a" />
<img width="130" height="241" alt="image" src="https://github.com/user-attachments/assets/e1fe62db-0dc4-467e-b858-4a2e98e0cfc2" />
<img width="130" height="241" alt="image" src="https://github.com/user-attachments/assets/2bb3ae8e-281b-4737-9513-1b48dcccdcb6" />
<img width="130" height="241" alt="image" src="https://github.com/user-attachments/assets/47e28ae0-0db1-4368-bca1-0b0a703ea8ea" />


### OCR 및 AI 기반 메뉴 분석

- Google Cloud Vision API를 활용한 메뉴판 텍스트 및 좌표 추출
- AI 서버를 통한 OCR 텍스트 보정, 번역, 정규화
- 메뉴명, 가격, 설명 등 텍스트 유형 분류
- LLM 기반 주요 식재료 추론
- 사용자 알레르기 정보 기반 위험도 분석
- 사용자 식성 및 맛 선호 기반 추천 메뉴 판단

<img width="130" height="241" alt="image" src="https://github.com/user-attachments/assets/fccc2aec-dfbc-4186-8c0d-74ff35ff83a7" />


### 이미지 기반 2D 오버레이

- OCR 좌표를 기반으로 원본 메뉴판 이미지 위에 분석 결과 표시
- 위험 메뉴, 안전 메뉴, 추천 메뉴, 가격정보를 색상으로 구분
- 메뉴 영역 선택 시 상세정보 확인 가능
- 원본 메뉴판 이미지 위에 분석 결과를 시각화하는 이미지 기반 2D 오버레이 방식을 사용

<img width="130" height="241" alt="image" src="https://github.com/user-attachments/assets/7a1db743-136b-4c95-b548-966901f23960" />

### 메뉴 상세정보 및 추천 결과

- 메뉴명
- 알레르기 위험 수준
- 위험 원인
- AI가 추론한 주요 식재료
- 추천 메뉴 여부 및 추천 이유
- 가격 및 원화 환산 가격 정보

환산 가격은 고정 환율을 기준으로 계산된 참고용 금액이며, 실제 결제 금액은 환율, 수수료, 매장 정책에 따라 달라질 수 있습니다.

<img width="130" height="241" alt="image" src="https://github.com/user-attachments/assets/26fc3460-4bab-443c-8b0d-56d3ec13735b" />
<img width="130" height="241" alt="image" src="https://github.com/user-attachments/assets/9be6f4a4-0987-4b05-8a91-4d6b59e00981" />
<img width="130" height="241" alt="image" src="https://github.com/user-attachments/assets/42de6be4-c0cd-4728-8b4a-fd6d940e06e3" />


### 주문 도우미

- 사용자가 선택한 메뉴와 등록된 알레르기 정보를 바탕으로, 음식점 직원에게 안전 여부를 확인할 수 있는 문구를 제공
- 직원에게 보여주는 문장은 설정된 메뉴판 언어로 제공되며, 사용자는 한국어 화면으로 전환하여 내용을 확인할 수 있음

<img width="130" height="241" alt="image" src="https://github.com/user-attachments/assets/34cd538a-71d3-4dbd-bed0-5737949de7bf" />
<img width="130" height="241" alt="image" src="https://github.com/user-attachments/assets/cb95d5c9-7841-47f9-b450-e818053775a9" />
<img width="130" height="241" alt="image" src="https://github.com/user-attachments/assets/3819c1d4-47f9-4dcf-8966-f797985b1df0" />
<img width="130" height="241" alt="image" src="https://github.com/user-attachments/assets/065de618-9ba7-45d9-8952-e613775872d5" />

---

## 시스템 구조


<img width="381" height="267" alt="image" src="https://github.com/user-attachments/assets/828e9f60-cf66-4405-aca7-374ee44f2175" />


Flutter 클라이언트, AI 서버, 백엔드 서버, 외부 API 및 데이터베이스를 연동하여 메뉴판 분석 결과를 제공합니다.


---

## 기술 스택

<img width="389" height="200" alt="image" src="https://github.com/user-attachments/assets/665c9c32-1e0a-47f8-85a4-9c19070055b7" />


### Frontend

| 구분 | 기술 | 활용 내용 |
|---|---|---|
| Framework | Flutter | 모바일 애플리케이션 UI 및 사용자 흐름 구현 |
| Language | Dart | Flutter 앱 개발 |
| OCR | Google Cloud Vision API | 메뉴판 이미지의 텍스트 및 좌표 정보 추출 |
| UI | 이미지 기반 2D 오버레이 | 원본 메뉴판 위에 번역 결과와 알레르기 위험정보 시각화 |

### AI Server

| 구분 | 기술 | 활용 내용 |
|---|---|---|
| Framework | FastAPI | 프론트엔드 및 백엔드 서버와 데이터 통신 |
| Language | Python | AI 서버 로직 구현 |
| LLM | Gemini API | OCR 텍스트 보정, 번역, 정규화, 환율 변환 |
| Cloud | Google Cloud Platform | AI 서버 배포 및 운영 환경 구성 |

### Backend

| 구분 | 기술 | 활용 내용 |
|---|---|---|
| Framework | NestJS | 인증, 메뉴 분석 등 REST API 서버 구현 |
| LLM | Groq API | 메뉴명 기반 식재료, 알레르기, 맛 프로파일 추론 |
| Image API | Pexels API | 분석된 요리의 대표 이미지 검색 및 수집 |
| Database | PostgreSQL | 사용자 정보, 알레르기 정보, 메뉴 정보 저장 |
| Cache | Redis | 기존 분석 결과 재사용 |
| Storage | Amazon S3 | 요리 이미지 저장 |

---

## 프로젝트 구조

- lib/
  - core/
    - api/
    - data/
    - env/
    - network/
    - ocr/
    - storage/
  - features/
    - auth/
    - camera/
    - home/
    - onboarding/
    - profile/
    - settings/
    - splash/
  - service/
- assets/
  - images/
- android/
- ios/
- test/

---

## 실행 방법

1. Flutter 의존성을 설치합니다.

    flutter pub get

2. 실행에 필요한 환경 설정 파일을 추가합니다.

    .env
    android/app/google-services.json

3. 앱을 실행합니다.

    flutter run

보안상 민감 정보가 포함된 설정 파일은 저장소에 포함하지 않습니다.

---

## 빌드 안내

릴리즈 빌드를 위해서는 Android 서명 키와 관련 설정 파일이 필요합니다.

아래 파일들은 보안상 저장소에 포함하지 않습니다.

- .env
- android/app/google-services.json
- GoogleService-Info.plist
- key.properties
- *.jks
- *.keystore

릴리즈 빌드 담당자는 필요한 설정 파일을 로컬 환경에 추가한 뒤 빌드를 진행해야 합니다.

---

## 팀원 및 역할

| 이름 | 역할 |
|---|---|
| 신성수 | 팀장, 백엔드 |
| 김효빈 | AI / 데이터 |
| 최형서 | 프론트엔드 |

---

## 참고 사항

- 최종 제출 및 검토 기준 브랜치는 `main`입니다.
- 민감 정보가 포함된 설정 파일과 API Key는 저장소에 포함하지 않습니다.
- 본 프로젝트는 식품 알레르기 환자가 외국어 메뉴판 환경에서 보다 안전하게 메뉴를 선택할 수 있도록 지원하는 것을 목표로 합니다.
