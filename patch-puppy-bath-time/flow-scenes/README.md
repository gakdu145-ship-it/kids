# Google Flow 장면 프롬프트 (처음부터 전체 생성)

설정: Veo 3.1 Lite, 9:16, x1. 프롬프트는 수정 없이 그대로 붙여넣습니다.

## 0. 레퍼런스 이미지 만들기 (Gemini, 1회)

`node generate-images.mjs` 를 실행하면 `ref-images/*.txt` 마다 같은 이름의 `.png`가 생깁니다.

## 1~8. 장면 만들기 (Flow)

장면마다 재료 이미지를 올리고 `sceneN.txt`를 붙여넣습니다. 결과는 `clips/sceneN.mp4`로 저장합니다.

| 장면 | 내용 | 카메라 무브 | 재료 이미지 |
|---|---|---|---|
| scene1 | 훅: 진흙 털기, 렌즈에 촥 | 고정 샷 (로우 앵글) | patch, backyard |
| scene2 | Quackers 등장, 욕조로 풍덩 | 슬로우 푸시 인 | patch, quackers, bathroom |
| scene3 | 머리, 귀 + 거품 귀 | 고정 샷 | patch, quackers, bathroom |
| scene4 | 함께 해요: 배 어디 있지? | 슬로우 돌리 인 | patch, bathroom |
| scene5 | 발 1~4 세기 | 틸트 다운 | patch, quackers, bathroom |
| scene6 | 헹구기 + Shake Shake 물벼락 | 아크 라이트 | patch, daddy_dog, bathroom |
| scene7 | 엔딩 후렴 + Your turn | 크레인 업 | patch, daddy_dog, quackers, bathroom |
| scene8 | 루프: 다시 진흙, 렌즈에 촥 | 트래킹 | patch, backyard |

재료 개수 제한에 걸리면 quackers → daddy_dog 순으로 뺍니다. patch와 배경은 빼지 않습니다.

## 편집: 클립 하나로 2개 업로드

| 버전 | 구성 | 목적 |
|---|---|---|
| 메인 Short (55~60초) | scene1 → scene8 | 노래 전체, 조회수용 |
| 후렴 Short (15~20초) | scene1 → scene3 → scene6 (진흙 훅 → 거품 귀 → 물벼락) | 짧고 반복 재생 잘 되는 버전 |

나중에 여러 편이 모이면 메인 Short들을 이어 붙여 3~5분 롱폼 모음집으로 올립니다.

## 편집 체크

- scene1의 첫 프레임이 곧 훅입니다. 앞을 자르지 말고, 첫 2초 안에 소리나 대사가 시작되는지 확인합니다.
- scene8 끝(렌즈에 진흙)과 scene1의 진흙이 튀는 순간이 같은 그림입니다. 페이드나 엔드카드는 넣지 않습니다.
- 질문 대사 뒤("...?", "...with me!")는 0.5~1초 여유를 남겨 아이가 따라 할 틈을 줍니다.

## 공통 규칙 (모든 프롬프트에 이미 들어 있음)

- 같은 마당/욕실 설명과 배경 재료로 장소 고정
- 고무 오리는 하나, Quackers는 손바닥 크기
- Patch는 항상 왼쪽 눈 갈색 반점 + 빨간 목걸이
- 캐릭터는 한 번씩만 등장, 처음부터 끝까지 크기와 모습 유지
- 장면당 카메라 무브 1개, 속도와 시작·끝 구도 명시
