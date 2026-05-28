import 'package:flutter/material.dart';

/// 앱 전체에서 공유하는 알레르기 항목 목록 (22종)
/// 이모지 중복 없이 각 항목이 고유한 아이콘을 가집니다.
/// description/foodExamples 필드는 설명이 필요한 항목에만 존재합니다.
const List<Map<String, String?>> allergyItems = [
  {'name': '계란', 'icon': '🥚'},
  {'name': '우유', 'icon': '🥛'},
  {'name': '메밀', 'icon': '🌾'},
  {'name': '땅콩', 'icon': '🥜'},
  {'name': '대두', 'icon': '🫘'},
  {'name': '밀', 'icon': '🍞'},
  {'name': '고등어', 'icon': '🐟'},
  {'name': '게', 'icon': '🦀'},
  {'name': '새우', 'icon': '🦐'},
  {'name': '돼지고기', 'icon': '🐖'},
  {'name': '복숭아', 'icon': '🍑'},
  {'name': '토마토', 'icon': '🍅'},
  {
    'name': '아황산류',
    'icon': '🧪',
    'description':
        '식품이 산화되거나 갈변하는 걸 막기 위해 사용하는 보존제 성분입니다.\n'
        '와인·건포도·말린 과일·식초류에 주로 들어있고, 이산화황이 일정 농도 이상 포함된 경우 의무 표기됩니다.\n'
        '천식이 있거나 황 성분에 민감하신 분은 두드러기·호흡 불편 등의 반응에 주의하세요.',
    'foodExamples': '와인,건포도,말린 살구,식초,가공 소시지',
  },
  {'name': '호두', 'icon': '🌰'},
  {'name': '닭고기', 'icon': '🍗'},
  {'name': '쇠고기', 'icon': '🥩'},
  {'name': '오징어', 'icon': '🦑'},
  {'name': '굴', 'icon': '🦪'},
  {'name': '전복', 'icon': '🐚'},
  {'name': '홍합', 'icon': '🐡'},
  {'name': '잣', 'icon': '🌲'},
  {
    'name': '추출성분',
    'icon': '⚗️',
    'description':
        '새우·게·우유 등 알레르기 유발 식재료를 가공·추출해 만든 성분입니다.\n'
        '원재료 자체가 아닌 소스·국물·조미료 형태로 소량 숨어있는 경우가 많아 눈에 띄지 않을 수 있어요.\n'
        '젤라틴(돼지·소 유래), 새우 엑기스, 굴 소스 등이 대표적인 예입니다.',
    'foodExamples': '젤라틴,새우 엑기스,굴 소스,치킨 스톡,각종 조미료',
  },
];

/// allergyItems 인덱스와 1:1 대응하는 색상 목록
const List<Color> allergyColors = [
  Color(0xFFFDD835), // 계란 - 노란색
  Color(0xFF90CAF9), // 우유 - 하늘색
  Color(0xFFBCAAA4), // 메밀 - 갈색빛
  Color(0xFFFF8F00), // 땅콩 - 주황갈색
  Color(0xFF8BC34A), // 대두 - 연두
  Color(0xFFFFB74D), // 밀  - 황금색
  Color(0xFF546E7A), // 고등어 - 청회색
  Color(0xFFEF5350), // 게  - 붉은색
  Color(0xFFFF7043), // 새우 - 주황빨강
  Color(0xFFF48FB1), // 돼지고기 - 핑크
  Color(0xFFFFAB91), // 복숭아 - 복숭아색
  Color(0xFFE53935), // 토마토 - 빨강
  Color(0xFFAB47BC), // 아황산류 - 보라
  Color(0xFF795548), // 호두 - 갈색
  Color(0xFFFFCA28), // 닭고기 - 황금
  Color(0xFFC62828), // 쇠고기 - 진빨강
  Color(0xFF7986CB), // 오징어 - 연보라
  Color(0xFF78909C), // 굴  - 회청색
  Color(0xFF26A69A), // 전복 - 청록
  Color(0xFF1565C0), // 홍합 - 진파랑
  Color(0xFF66BB6A), // 잣  - 연초록
  Color(0xFF9E9E9E), // 추출성분 - 회색
];
