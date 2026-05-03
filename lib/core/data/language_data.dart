/// 언어 옵션 모델
class LanguageOption {
  const LanguageOption({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.flag,
  });

  /// ISO 639-1 코드 (중국어는 zh-CN / zh-TW 구분)
  final String code;

  /// 한국어 표기명
  final String name;

  /// 해당 언어의 자국어 표기명
  final String nativeName;

  /// 국기 이모지
  final String flag;
}

/// 출발 언어 목록 (메뉴판 언어)
const List<LanguageOption> departureLanguageOptions = [
  LanguageOption(code: 'ja',    name: '일본어',      nativeName: '日本語',       flag: '🇯🇵'),
  LanguageOption(code: 'zh-CN', name: '중국어 간체',  nativeName: '中文(简体)',   flag: '🇨🇳'),
  LanguageOption(code: 'zh-TW', name: '중국어 번체',  nativeName: '中文(繁體)',   flag: '🇹🇼'),
  LanguageOption(code: 'en',    name: '영어',        nativeName: 'English',     flag: '🇺🇸'),
  LanguageOption(code: 'th',    name: '태국어',      nativeName: 'ภาษาไทย',    flag: '🇹🇭'),
  LanguageOption(code: 'vi',    name: '베트남어',    nativeName: 'Tiếng Việt',  flag: '🇻🇳'),
  LanguageOption(code: 'fr',    name: '프랑스어',    nativeName: 'Français',    flag: '🇫🇷'),
  LanguageOption(code: 'es',    name: '스페인어',    nativeName: 'Español',     flag: '🇪🇸'),
  LanguageOption(code: 'it',    name: '이탈리아어',  nativeName: 'Italiano',    flag: '🇮🇹'),
  LanguageOption(code: 'ko',    name: '한국어',      nativeName: '한국어',       flag: '🇰🇷'),
];

/// 도착 언어 목록 (번역 결과 언어)
const List<LanguageOption> arrivalLanguageOptions = [
  LanguageOption(code: 'ko',    name: '한국어',      nativeName: '한국어',       flag: '🇰🇷'),
  LanguageOption(code: 'en',    name: '영어',        nativeName: 'English',     flag: '🇺🇸'),
  LanguageOption(code: 'ja',    name: '일본어',      nativeName: '日本語',       flag: '🇯🇵'),
  LanguageOption(code: 'zh-CN', name: '중국어 간체',  nativeName: '中文(简体)',   flag: '🇨🇳'),
  LanguageOption(code: 'zh-TW', name: '중국어 번체',  nativeName: '中文(繁體)',   flag: '🇹🇼'),
];
