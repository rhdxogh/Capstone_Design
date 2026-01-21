class StadiumLoc {
  final String id;
  final String nameKo;
  final String address;
  final double lat;
  final double lon;

  const StadiumLoc({
    required this.id,
    required this.nameKo,
    required this.address,
    required this.lat,
    required this.lon,
  });
}

const stadiumLocations = <StadiumLoc>[
  StadiumLoc(
    id: 'munhak',
    nameKo: '인천 SSG 랜더스 필드',
    address: '인천 미추홀구',
    lat: 37.4351,
    lon: 126.6906,
  ),
  StadiumLoc(
    id: 'jamsil',
    nameKo: '잠실야구장',
    address: '서울 송파구',
    lat: 37.5121,
    lon: 127.0719,
  ),
  StadiumLoc(
    id: 'gocheok',
    nameKo: '고척 스카이돔',
    address: '서울 구로구',
    lat: 37.4982,
    lon: 126.8671,
  ),
  StadiumLoc(
    id: 'daegu',
    nameKo: '대구 삼성라이온즈 파크',
    address: '대구광역시 수성구 야구전설로 1',
    lat: 35.8407,
    lon: 128.6811,
  ),
  StadiumLoc(
    id: 'daejeon',
    nameKo: '대전 한화생명 볼파크',
    address: '대전광역시 중구 대종로 373',
    lat: 36.3163,
    lon: 127.4311,
  ),
  StadiumLoc(
    id: 'sajik',
    nameKo: '사직 야구장',
    address: '부산광역시 동래구 사직로 45',
    lat: 35.1939,
    lon: 129.0615,
  ),
  StadiumLoc(
    id: 'suwon',
    nameKo: '수원 케이티 위즈파크',
    address: '경기도 수원시 장안구 경수대로 893',
    lat: 37.3001,
    lon: 127.0096,
  ),
  StadiumLoc(
    id: 'changwon',
    nameKo: '창원NC파크',
    address: '경상남도 창원시 마산회원구 삼호로 63',
    lat: 35.2225,
    lon: 128.5823,
  ),
  StadiumLoc(
    id: 'gwangju',
    nameKo: '광주-기아 챔피언스필드',
    address: '광주광역시 북구 서림로 10',
    lat: 35.1683,
    lon: 126.8893,
  ),
];
