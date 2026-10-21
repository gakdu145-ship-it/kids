# Google Flow 장면 프롬프트 (처음부터 전체 생성)

설정: Veo 3.1 Lite, 9:16, x1. 프롬프트는 수정 없이 그대로 붙여넣습니다.

## 0. 레퍼런스 이미지 만들기 (Gemini, 1회)

`node generate-images.mjs` 를 실행하면 `ref-images/*.txt` 마다 같은 이름의 `.png`가 생깁니다.

## 1~8. 장면 만들기 (Flow)

장면마다 재료 이미지를 올리고 `sceneN.txt`를 붙여넣습니다. 결과는 `clips/sceneN.mp4`로 저장합니다.

| 장면 | 내용 | 카메라 무브 | 재료 이미지 |
|---|---|---|---|
| scene1 | 훅: 굴뚝 딸기 팝콘 | 고정 샷 | ellie, chuggy, fruit_valley |
| scene2 | 출발, Trunk Toot | 트래킹 (좌→우) | ellie, chuggy, fruit_valley |
| scene3 | 빨강: 딸기 1-2-3 | 고정 샷 | ellie, chuggy, fruit_valley |
| scene4 | 노랑 퀴즈 | 슬로우 푸시 인 | ellie, fruit_valley |
| scene5 | 초록: 브로콜리 한 입 | 슬로우 돌리 인 | ellie, chuggy, fruit_valley |
| scene6 | 보라: 포도 덩굴 통과 | 트래킹 (우→좌) | ellie, chuggy, fruit_valley |
| scene7 | 무지개 접시 + Your turn | 크레인 업 | ellie, chuggy, fruit_valley |
| scene8 | 루프: 다시 딸기 팝콘 | 팬 오른쪽 | ellie, chuggy, fruit_valley |

재료 개수 제한에 걸리면 chuggy 순으로 뺍니다. ellie와 배경은 빼지 않습니다.

## 편집: 클립 하나로 2개 업로드

| 버전 | 구성 | 목적 |
|---|---|---|
| 메인 Short (55~60초) | scene1 → scene8 | 노래 전체, 조회수용 |
| 후렴 Short (15~20초) | scene1 → scene3 → scene7 (딸기 팝콘 → 빨강 → 무지개 후렴) | 짧고 반복 재생 잘 되는 버전 |

나중에 여러 편이 모이면 메인 Short들을 이어 붙여 3~5분 롱폼 모음집으로 올립니다.

## 편집 체크

- scene1의 첫 프레임이 곧 훅입니다. 앞을 자르지 말고, 첫 2초 안에 소리나 대사가 시작되는지 확인합니다.
- scene8 끝(Ellie와 기관차가 나란히, 딸기를 잡은 순간)과 scene1의 딸기를 잡는 순간이 같은 그림입니다. 페이드나 엔드카드는 넣지 않습니다.
- 질문 대사 뒤("...?", "...with me!")는 0.5~1초 여유를 남겨 아이가 따라 할 틈을 줍니다.

## 공통 규칙 (모든 프롬프트에 이미 들어 있음)

- 같은 과일 계곡 설명과 배경 재료로 장소 고정
- 기차는 하나, 화물칸 3개
- 과일·채소는 평범한 음식 (얼굴 없음)
- Ellie는 항상 기관사 모자와 빨간 반다나
- 캐릭터는 한 번씩만 등장, 처음부터 끝까지 크기와 모습 유지
- 장면당 카메라 무브 1개, 속도와 시작·끝 구도 명시
