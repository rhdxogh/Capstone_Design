import 'dart:convert';
import 'package:http/http.dart' as http;

import '../config/naver_api.dart';
import '../models/naver_news_article.dart';

class NaverNewsService {
  static const _base = 'https://openapi.naver.com/v1/search/news.json';

  static ({List<String> strong, List<String> weak}) _teamKeys(
      String teamNameOrId,
      ) {
    final t = teamNameOrId.toLowerCase();

    if (t.contains('ssg') || t.contains('랜더스') || t.contains('landers')) {
      return (
      strong: ['SSG 랜더스', '랜더스'],
      weak: ['SSG', '인천', '문학', '랜더스필드'],
      );
    }
    if (t.contains('키움') || t.contains('히어로즈') || t.contains('kiwoom')) {
      return (
      strong: ['키움 히어로즈', '키움', '히어로즈'],
      weak: ['고척'],
      );
    }
    if (t == 'kt' || t.contains('위즈') || t.contains('wiz')) {
      return (
      strong: ['KT 위즈', '위즈'],
      weak: ['KT', '수원'],
      );
    }
    if (t.contains('lg') || t.contains('트윈스') || t.contains('twins')) {
      return (
      strong: ['LG 트윈스', '트윈스'],
      weak: ['LG', '잠실'],
      );
    }
    if (t.contains('두산') || t.contains('베어스') || t.contains('doosan')) {
      return (
      strong: ['두산 베어스', '두산', '베어스'],
      weak: ['잠실'],
      );
    }
    if (t.contains('기아') || t.contains('kia') || t.contains('타이거즈')) {
      return (
      strong: ['KIA 타이거즈', '기아 타이거즈', '타이거즈'],
      weak: ['광주', '챔피언스필드'],
      );
    }
    if (t.contains('삼성') || t.contains('라이온즈') || t.contains('samsung')) {
      return (
      strong: ['삼성 라이온즈', '삼성', '라이온즈'],
      weak: ['대구'],
      );
    }
    if (t.contains('nc') || t.contains('다이노스') || t.contains('dinos')) {
      return (
      strong: ['NC 다이노스', '다이노스'],
      weak: ['NC', '창원'],
      );
    }
    if (t.contains('롯데') || t.contains('자이언츠') || t.contains('lotte')) {
      return (
      strong: ['롯데 자이언츠', '롯데', '자이언츠'],
      weak: ['부산', '사직'],
      );
    }
    if (t.contains('한화') || t.contains('이글스') || t.contains('hanwha')) {
      return (
      strong: ['한화 이글스', '한화', '이글스'],
      weak: ['대전'],
      );
    }

    return (strong: [teamNameOrId], weak: const []);
  }

  static List<String> _playerKeys(String teamNameOrId) {
    final t = teamNameOrId.toLowerCase();

    if (t.contains('ssg') || t.contains('랜더스') || t.contains('landers')) {
      return [
        '백승건', '이건욱', '조병현', '장지훈', '서진용',
        '송영진', '김광현', '최민준', '앤더슨', '한두솔',
        '노경은', '김건우', '최현석', '김민', '문승원',
        '김택형', '이승훈', '안현서', '신헌민', '박종훈',
        '정동윤', '화이트', '박시후', '신지환', '최수호',
        '임성준', '전영준', '박기호', '천범석', '이로운',
        '김현재', '이도우', '조요한', '박성빈', '한지헌',
        '도재현', '김준영',

        '박대온', '조형우', '김민식', '신범수', '이율예',
        '이지영', '김규민',

        '박지환', '박성한', '정준재', '김수윤', '김찬형',
        '김성현', '최준우', '현원회', '안상현', '최정',
        '고명준', '김태윤', '석정우', '김성민', '허진',
        '최윤석', '홍대인',

        '이승민', '하재훈', '채현우', '최상민', '에레디아',
        '이정범', '한유섬', '오태곤', '류효승', '정현승',
        '최민창', '최지훈', '박정빈', '김창평', '임근우',
        '백준서', '이원준',

        '김건웅', '윤태현', '김도현', '박상후', '이기순',
        '김민준', '박세직', '윤성보', '변건우', '김정민',
        '류현곤', '전의산',

        '이숭용',
      ];
    }


    if (t.contains('키움') || t.contains('히어로즈') || t.contains('kiwoom')) {
      return [
        '박주성', '김성민', '이강준', '정현우', '박준현',
        '김윤하', '조영건', '김성진', '김재웅', '오석주',
        '와일스', '박윤성', '박지성', '박진형', '안우진',
        '이준우', '정다훈', '원종현', '이승호', '유토',
        '김선기', '하영민', '알칸타라', '양지율', '김서준',
        '배동현', '전준표', '손현기', '정세영', '김동욱',
        '이태양', '김인범', '김연주', '임진묵', '이명종',
        '백진수', '박성훈', '윤석원', '윤현', '김동규',
        '손힘찬', '오혜성', '정동준', '이태준', '한민우',
        '최현우', '김태언', '박준건', '김유빈', '이승재',
        '김준형',

        '김건희', '고재현', '김동헌', '박성빈', '김지성',
        '박준형', '김리안', '김주영',

        '김태진', '박한결', '이재상', '우선진', '안치홍',
        '김웅빈', '서건창', '김병휘', '김지석', '최재영',
        '엄송원', '최주환', '송지후', '어준서',
        '여동욱', '전태현', '권혁빈', '서유신', '심휘윤',
        '유정택',

        '이주형', '이용규', '임병욱', '브룩스', '주성원',
        '추재현', '임지열', '원성준', '이형종', '박찬혁',
        '박주홍', '이주형', '박수종', '박채울',

        '주승빈', '김동혁', '김시앙', '이승원', '이종민',
        '장재영', '박범준', '주승우', '고영우',

        '설종진', '박병호'
      ];
    }


    if (t == 'kt' || t.contains('위즈') || t.contains('wiz')) {
      return [
        '고영표', '한차현', '스기모토', '우규민', '임준형',
        '권성준', '최동환', '이채호', '문용익', '배제성',
        '김태오', '이정현', '김민수', '전용주', '소형준',
        '맷 사우어', '한승혁', '이상동', '케일럽 보슬리', '주권',
        '지명성', '김동현', '손동현', '오원석',
        '이상우', '이현민', '조이현', '박영현', '김정운',
        '원상현', '이원재', '박지훈', '고준혁', '정정우',
        '한지용', '이준명', '김건웅', '강건', '장민호',
        '박준혁', '윤상인', '이민준', '김휘연',
        '김규한', '권효준', '정진호',

        '장성우', '조대현', '김민석', '한승택', '강현우',
        '이승현', '이정환', '이준희', '김유빈', '박치성',

        '오윤석', '강민성', '이강민', '김상수', '류현인',
        '허경민', '문상철', '오서진', '안인산', '권동진',
        '장준원', '손민석', '임상우', '김건휘',
        '이용현', '박성준',

        '최원준', '안치영', '김현수', '안현민', '배정대',
        '최성민', '이정훈', '힐리어드', '장진혁', '김민혁',
        '신범준', '유준규', '최동희', '박민석', '정영웅',
        '김경환',

        '정준영', '한승주', '황의준', '최윤서',
        '이근혁', '신호준', '박태완', '육청명', '김병준',
        '이승언', '김재원',

        '이강철',
      ];
    }

    if (t.contains('lg') || t.contains('트윈스') || t.contains('twins')) {
      return [
        '김유영', '임찬규', '함덕주', '김대현', '송승기',
        '최지명', '정우영', '우강훈', '이우찬', '배재준',
        '이민호', '장시환', '손주영', '톨허스트', '이정용',
        '이지강', '성동현', '김강률', '조원태', '이상영',
        '이종준', '김진성', '김동현', '김진수', '치리노스',
        '김윤식', '조건희', '권우준', '장현식', '유영찬',
        '김주온', '박시원', '박준성', '백승현', '양우진',
        '김영우', '웰스', '우명현', '진우영', '이믿음',
        '안이도', '윤형민', '박성진', '성준서', '하헌규',
        '김지용', '허용주', '오승윤', '임정균', '원상훈',
        '양진혁', '허준혁',

        '박동원', '김준태', '이주헌', '강민기',
        '이한림', '박준기', '전경원',

        '문보경', '신민재', '김주성', '구본혁', '이영빈',
        '오지환', '김정률', '손용준', '오스틴', '추세현',
        '김성진', '천성호', '송찬의', '문정빈', '강민균',
        '엄태경', '주정환', '우정안', '이지백', '곽민호',
        '이태훈', '송대현', '김유민',

        '최원영', '문성주', '박해민', '함창건', '홍창기',
        '이재원', '서영준', '김현종', '박현우', '최명경',
        '권동혁', '이준서',

        '배강', '김종우', '강석현', '김대원', '정지헌',
        '심규빈', '김도윤', '김범석', '김성우', '김웅',
        '고영웅', '김종운', '박관우', '박명근',

        '염경엽'
      ];
    }


    if (t.contains('두산') || t.contains('베어스') || t.contains('doosan')) {
      return [
        '박치국', '최주형', '김정우', '박정수', '타무라',
        '김민규', '최승용', '이병헌', '양재훈', '이주호',
        '색로그', '최종인', '서준오', '최지강', '이주엽',
        '이용찬', '김명신', '곽빈', '벤자민', '박신지',
        '이영하', '김유성', '김호준', '박웅', '최준호',
        '최원준', '김택연', '윤태호', '최민석', '플렉센',
        '제환유', '김한중', '최우인', '김지윤', '장우진',
        '황희천', '임종훈', '정성현', '안치호', '안민겸',
        '이기석',

        '김성재', '김기연', '양의지', '박민준', '윤준호',
        '장규빈', '류현준', '이희성',

        '임종성', '박성재', '오명진', '박찬호', '김민혁',
        '김동준', '이유찬', '박계범', '강승호', '박지훈',
        '박준순', '양석환', '안재석', '신민철', '지강혁',
        '이선우', '한다현', '김준상', '심건보', '남태웅',

        '김민석', '손아섭', '전다민', '카메론', '정수빈',
        '김대한', '김인태', '홍성호', '신우열', '조수행',
        '천현재', '김주오', '양현진', '김문수', '주야준',
        '엄지민', '임현철',

        '백승우', '임서준', '강태완', '김동주', '김영현',
        '김무빈', '손율기', '김태완', '박지호', '여동건',
        '이상혁',

        '김원형'
      ];
    }


    if (t.contains('기아') || t.contains('kia') || t.contains('타이거즈')) {
      return [
        '곽도규', '유지성', '김태형', '조상우', '윤영철',
        '김현수', '윤중현', '이준영', '김사윤', '이형범',
        '올러', '장재혁', '최지민', '네일', '황동하',
        '김건국', '이태양', '정찬화', '김정엽', '이의리',
        '김범수', '전상현', '홍건희', '김기훈', '양현종',
        '한재승', '이성원', '김도현', '김시훈', '정해영',
        '김현수', '성영탁', '이도현', '홍민규', '김대유',
        '강이준', '장민기', '이승재', '조건호', '김세일',
        '김경묵', '김상범', '오규석', '이호진', '정다훈',
        '최건희', '나연우', '지현', '김양수', '최유찬',
        '유승철',

        '주효상', '한준수', '김태군', '권다결', '김선우',
        '이도훈', '신명승',

        '박민', '김선빈', '김도영', '정해원', '정현창',
        '김규성', '윤도현', '최정용', '변우혁', '데일',
        '황대인', '이호연', '박상준', '오선우', '장시현',
        '오정환', '김재현', '이준범', '한준희', '송호정',
        '황석민', '엄준현', '박종혁', '차상현',

        '박정우', '이창진', '박재현', '카스토로', '김호령',
        '한승연', '김석환', '김민규', '나성범', '고종욱',
        '이영재', '박헌', '천정민', '곽동호',

        '이송찬', '김태윤', '최지웅', '강효종', '김찬민',
        '김민재', '김두현', '조대현', '이상준', '강동훈',
        '강민제', '임다온', '김민주', '이호민',

        '이범호',
      ];
    }
    
    if (t.contains('삼성') || t.contains('라이온즈') || t.contains('samsung')) {
      return [
        '이호성', '유선엽', '메닝', '최지광', '미야지',
        '이재희', '원태인', '양현', '최원태', '이승현',
        '김태훈', '이승민', '백정현', '최하늘', '임기영',
        '이호범', '양창섭', '이재익', '김무신', '정민성',
        '서현원', '배찬승', '이승현', '장찬희', '김재윤',
        '홍원표', '김상호', '박용재', '정재훈', '후라도',
        '김시온', '박주혁', '허윤동', '최예한', '권현우',
        '홍준영', '김백산', '천겸', '진희성', '김유현',
        '신윤호', '김성경', '김동현', '우승완', '홍승원',
        '이서준', '한수동', '황정현', '박주영', '석예헌',
        '신정환', '어윤성', '김서준',

        '김재성', '박진우', '이병헌', '김도환', '장승현',
        '강민호', '박세혁', '차동영', '이서준', '안민성',

        '디아즈', '이해승', '심재훈', '이재현', '김재상',
        '류지혁', '김영웅', '차승준', '이창용', '양우현',
        '전병우', '박장민', '김상준', '조민성', '임주찬',
        '이한민',

        '구자욱', '김재혁', '이성규', '김태훈', '윤정빈',
        '김헌곤', '최형우', '김성윤', '함수호', '류승민',
        '홍현빈', '김지찬', '박승규', '강준서', '김상민',
        '이진용', '강민성', '조세익',

        '박권후', '홍무원', '박시원', '김현준', '김호진',
        '이현준', '유병선', '신경민', '박준용', '황동재',
        '양도근', '김대호',

        '박진만'
      ];
    }

    if (t.contains('nc') || t.contains('다이노스') || t.contains('dinos')) {
      return [
        '김녹원', '라일리', '정구범', '토다', '김영규',
        '신민혁', '임지민', '목지훈', '김재열', '최성영',
        '배하겐', '하준영', '임정호', '이준혁', '류진욱',
        '신영우', '손주환', '조민석', '이재학', '김진호',
        '박지한', '전사민', '구창모', '김태경', '배재환',
        '원종해', '최우석', '테일러', '최요한', '이세민',
        '강태경', '소이현', '전루건', '김준원',
        '홍재문', '김태현', '노재원', '박동수', '김태우',
        '최윤혁', '정주영', '김오엘', '정튼튼', '윤성환',
        '윤서현', '손민서', '서동욱',

        '안중열', '김형준', '이희성', '김정호', '신민우',
        '박성재', '김동현',

        '박민우', '허윤', '서호철', '오태양', '김주원',
        '신재인', '홍종표', '김한별', '최정원', '도태훈',
        '데이비슨', '윤준혁', '오영수', '한재환', '김휘집',
        '김건', '박인우', '박주찬', '조현진', '신성호',
        '이한', '장창훈', '유재현', '조효원', '김명규',

        '천재환', '한석현', '권희동', '박건우', '고준휘',
        '박시원', '이우성', '고승완', '오장한', '배상호',
        '김범준', '박영빈', '양가온솔', '조창연', '안지원',

        '이준호', '이용준', '송명기', '김재민', '신용석',
        '박한결', '홍유원', '김민균', '조현민', '김휘건',
        '서준교', '김세훈', '김민규', '임상현',
        
        '이호준'
      ];
    }


    if (t.contains('롯데') || t.contains('자이언츠') || t.contains('lotte')) {
      return [
        '한현희', '김진욱', '현도훈', '정성종', '김강현',
        '박세웅', '구승민', '비슬리', '김태혁', '로드리게스',
        '김원중', '김영준', '박정민', '이민석', '홍민기',
        '이영재', '박세진', '나균안', '박진', '이지하',
        '코야마', '최이준', '이준서', '윤성빈', '최준용',
        '정현수', '박준우', '송재영', '최종현', '박시영',
        '정철원', '신동건', '이승헌', '정우준', '조영우',
        '이병준', '김주완', '김태균', '정선우', '박문건',
        '하혜성', '이태연', '김기준', '조경민', '장세진',
        '김창훈', '석상호', '박세현', '김화종', '남해담',
        '김한결', '김현수', '손준이',

        '박재엽', '유강남', '손성빈', '정문혁', '정보근',
        '김현도', '강승구', '이건희', '하준서',
        '서하은',

        '고승민', '김세민', '한태양', '전민재', '최항',
        '김민성', '한동희', '이호준', '나승엽', '노진혁',
        '박승욱', '박찬형', '이서준', '박지훈', '김호범',
        '이정민', '이지훈', '홍서연', '배인혁', '이로하',

        '황성빈', '신윤후', '장두성', '전준우', '조세진',
        '레이예스', '손호영', '김동혁', '김동현', '윤동희',
        '김한울', '김대현', '이인한', '엄장윤', '윤수녕',
        '박건', '조민영', '유제모',

        '전하원', '정대선', '박성준', '안우진', '소한빈',
        '이선우', '전미르', '진승현', '강성우', '서동욱',
        '최민규', '김현우', '한승현', '김태현', '이태경',

        '김태형'
      ];
    }

    if (t.contains('한화') || t.contains('이글스') || t.contains('hanwha')) {
      return [
        '문동주', '엄상백', '에르난데스', '김승일', '이상규',
        '왕옌청', '화이트', '이민우', '장유호', '황준서',
        '이교훈', '정이황', '김종수', '박재규', '김범준',
        '김서현', '배민서', '김도빈', '양수호', '원종혁',
        '윤산흠', '김민우', '강재민', '조동욱', '박상원',
        '정우주', '권민규', '주현상', '강건우', '박준영',
        '류현진', '하동준', '여현승', '황의성', '박준영',
        '이기창', '양선률', '한서구', '양경모', '이동영',
        '엄요셉', '박부성', '김관우', '김겸재',

        '최재훈', '이재원', '허관회', '장규현', '박상언',
        '허인서', '정우성',

        '정민규', '이도윤', '한경빈', '심우준',
        '노시환', '하주석', '채은성', '한지윤', '강백호',
        '문현빈', '김건', '박정현', '최유빈', '황영묵',
        '배승수', '권휘규', '김준수', '이지성', '임종찬',
        '이진영', '권광민', '김태연', '페라자', '유로결',
        '이원석', '최인호', '오재원', '유민', '이재환',
        '박주진', '이도훈', '김동휘', '최윤호', '노석진',
        '김해찬',

        '남지민', '이민준', '정은원', '송지환', '권현',
        '성지훈', '김규연', '정안석', '박상현',
        '최준서', '김기중', '엄상현', '최주원', '이민재',

        '김경문'
      ];
    }


    return const [];
  }

  static bool _isLikelyTeamTitle({
    required NaverNewsArticle article,
    required String teamNameOrId,
  }) {
    final keys = _teamKeys(teamNameOrId);
    final players = _playerKeys(teamNameOrId);

    final title = article.title.toLowerCase();

    final titleKeys = [
      ...keys.strong,
      ...keys.weak,
      ...players,
    ];

    return titleKeys.any(
          (key) => key.trim().isNotEmpty && title.contains(key.toLowerCase()),
    );
  }

  static List<String> _buildQueries(String teamNameOrId) {
    final t = teamNameOrId.toLowerCase();
    final keys = _teamKeys(teamNameOrId);

    if (t.contains('기아') || t.contains('kia') || t.contains('타이거즈')) {
      return [
        'KIA 타이거즈',
        '기아 타이거즈',
        '타이거즈 프로야구',
        'KIA 타이거즈 KBO',
        'KIA 타이거즈 선수',
        'KIA 타이거즈 감독',
      ];
    }

    final List<String> queries = [];

    if (keys.strong.isNotEmpty) {
      queries.add(keys.strong.first);
      queries.add('${keys.strong.first} 프로야구');
      queries.add('${keys.strong.first} KBO');
      queries.add('${keys.strong.first} 경기');
      queries.add('${keys.strong.first} 선수');
      queries.add('${keys.strong.first} 감독');
    }

    if (keys.strong.length >= 2) {
      queries.add('${keys.strong[1]} 프로야구');
      queries.add('${keys.strong[1]} 경기');
    }

    final seen = <String>{};
    return queries.where((q) => seen.add(q)).toList();
  }

  static Future<String?> _extractImageFromArticle(String url) async {
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) return null;

      final res = await http.get(
        uri,
        headers: {
          'User-Agent': 'Mozilla/5.0',
        },
      ).timeout(const Duration(seconds: 2));

      if (res.statusCode != 200) return null;

      final html = res.body;

      final match = RegExp(
        '<meta property="og:image" content="([^"]+)"',
        caseSensitive: false,
      ).firstMatch(html);

      if (match != null) {
        return match.group(1);
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<List<NaverNewsArticle>> _fetchSingleQuery({
    required String query,
    required int start,
    required int display,
    required String sort,
  }) async {
    final uri = Uri.parse(_base).replace(queryParameters: {
      'query': query,
      'display': display.toString(),
      'start': start.toString(),
      'sort': sort,
    });

    final res = await http.get(
      uri,
      headers: {
        'X-Naver-Client-Id': NaverApiConfig.clientId,
        'X-Naver-Client-Secret': NaverApiConfig.clientSecret,
      },
    );

    if (res.statusCode != 200) {
      throw Exception('네이버 뉴스 실패: ${res.statusCode} ${res.body}');
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final items =
    (data['items'] as List<dynamic>? ?? []).whereType<Map<String, dynamic>>();

    final articles = items.map(NaverNewsArticle.fromJson).toList();

    final result = await Future.wait(
      articles.map((article) async {
        final articleUrl =
        article.originallink.isNotEmpty ? article.originallink : article.link;

        final imageUrl = await _extractImageFromArticle(articleUrl);

        return article.copyWith(imageUrl: imageUrl);
      }),
    );

    return result;
  }

  static Future<List<NaverNewsArticle>> fetchTeamNews({
    required String teamNameOrId,
    int start = 1,
    int display = 5,
    String sort = 'date',
  }) async {
    if (display < 1) display = 1;
    if (display > 100) display = 100;
    if (start < 1) start = 1;
    if (start > 1000) start = 1000;

    final queries = _buildQueries(teamNameOrId);
    final merged = <NaverNewsArticle>[];

    for (final q in queries) {
      try {
        final list = await _fetchSingleQuery(
          query: q,
          start: start,
          display: display,
          sort: sort,
        );
        merged.addAll(list);
      } catch (_) {
        // 한 쿼리 실패해도 전체 실패시키지 않음
      }
    }

    final seen = <String>{};
    final deduped = <NaverNewsArticle>[];

    for (final a in merged) {
      final key = (a.originallink.isNotEmpty ? a.originallink : a.link).trim();
      if (key.isEmpty) continue;
      if (seen.add(key)) deduped.add(a);
    }

    final titleFiltered = deduped
        .where(
          (article) => _isLikelyTeamTitle(
        article: article,
        teamNameOrId: teamNameOrId,
      ),
    )
        .toList();

    if (titleFiltered.isEmpty) {
      return deduped;
    }

    return titleFiltered;
  }
}






