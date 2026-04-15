import 'package:flutter/material.dart';

/// 앱 전체에서 공유하는 알레르기 항목 목록 (22종)
/// 이모지 중복 없이 각 항목이 고유한 아이콘을 가집니다.
const List<Map<String, String>> allergyItems = [
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
  {'name': '아황산류', 'icon': '🧪'},
  {'name': '호두', 'icon': '🌰'},
  {'name': '닭고기', 'icon': '🍗'},
  {'name': '쇠고기', 'icon': '🥩'},
  {'name': '오징어', 'icon': '🦑'},
  {'name': '굴', 'icon': '🦪'},
  {'name': '전복', 'icon': '🐚'},
  {'name': '홍합', 'icon': '🐡'},
  {'name': '잣', 'icon': '🌲'},
  {'name': '추출성분', 'icon': '⚗️'},
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
