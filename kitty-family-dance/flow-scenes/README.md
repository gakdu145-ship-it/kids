# Google Flow 장면 프롬프트 (처음부터 전체 생성)

설정: Veo 3.1 Lite, 9:16, x1, Ingredients to Video. 프롬프트는 수정 없이 그대로 붙여넣습니다.

강아지 편(`patch-puppy-bath-time/flow-scenes/README.md`)에서 배운 것을 처음부터 적용했습니다.

## 0. 재료 이미지 준비

1. `node generate-images.mjs`로 `ref-images/*.txt`를 모두 생성합니다.
2. 턴어라운드 시트에서 **정면 1컷만** 잘라 `ingredient_<이름>.png`로 저장합니다. 4방향 시트를 그대로 올리면 같은 캐릭터가 여러 마리 나옵니다.
3. 배경은 오른쪽 아래 Gemini 워터마크를 지워 `ingredient_living_room.png`로 저장합니다.
4. `family_lineup`은 네 마리가 한 번씩 나오는 한 장이라 자르지 않고 워터마크만 지워 `ingredient_family_lineup.png`로 씁니다.

| 재료 | 만드는 법 |
|---|---|
| `ingredient_mochi.png` | `mochi` 정면 1컷 |
| `ingredient_mommy_cat.png` | `mommy_cat` 정면 1컷 |
| `ingredient_daddy_cat.png` | `daddy_cat` 정면 1컷 |
| `ingredient_grandma_cat.png` | `grandma_cat` 정면 1컷 |
| `ingredient_family_lineup.png` | `family_lineup` 워터마크 제거 |
| `ingredient_living_room.png` | `living_room` 워터마크 제거 |

Flow 재료는 장면당 3장까지입니다. 가족 장면은 네 마리를 따로 올릴 수 없어서 `family_lineup` 한 장으로 넣습니다.

## 1~8. 장면 만들기 (Flow)

**scene6을 먼저 생성해 보세요.** 네 마리가 모두 나오는 가장 어려운 장면이라, 여기서 순서·크기·색이 맞으면 나머지도 맞습니다.

| 장면 | 내용 | 카메라 무브 | 재료 이미지 |
|---|---|---|---|
| scene1 | 훅: 털실 쫓아와 카메라 쪽으로 폴짝 | 고정 샷 (로우 앵글) | mochi, living_room |
| scene2 | Baby 폴짝 1번 + Can you pounce? | 고정 샷 | mochi, living_room |
| scene3 | Mommy 빙글 2번 | 퀵 아크 라이트 | mommy_cat, living_room |
| scene4 | Daddy 점프 3번 | 고정 (착지마다 살짝 흔들림) | daddy_cat, living_room |
| scene5 | Grandma 기지개 4번 + 반전 질주 | 질주 따라 휩 팬 | grandma_cat, living_room |
| scene6 | 다 같이 4동작 | 퀵 아크 라이트 | family_lineup, living_room |
| scene7 | 엔딩 후렴 + Your turn | 퀵 크레인 업 | family_lineup, living_room |
| scene8 | 루프: 털실 쫓다가 폴짝 직전 | 고정 샷 (로우 앵글) | family_lineup, living_room |

## 생성 후 클립 체크

| 확인 | 틀렸을 때 |
|---|---|
| 네 마리 색과 소품: Mochi 주황+분홍 방울 목걸이, 할머니 흰색+보라 안경+민트 숄, 엄마 연회색+라벤더 리본, 아빠 먹회색·흰색+빨간 나비넥타이 | 다시 생성 |
| 가족 장면에서 각자 한 마리씩 (쌍둥이 없음), 순서가 작은 순 | 다시 생성 |
| 털실은 하나, 공중에 멈춰 떠 있지 않음 | 다시 생성 |
| 실제 고양이처럼 보이지 않음 (카툰, 두 발로 섬) | 다시 생성 |
| Mochi 목소리가 어른 목소리가 아님 | 다시 생성 |
| 자막·글자·워터마크 없음 | 다시 생성 |

## 편집

| 버전 | 구성 | 목적 |
|---|---|---|
| 메인 Short (45~55초) | scene1 → scene8, 클립마다 2~3컷 | 노래 전체, 조회수용 |
| 후렴 Short (15~20초) | scene1 → scene5 → scene7 (폴짝 훅 → 할머니 반전 → 후렴) | 짧고 반복 재생 잘 되는 버전 |

- **배경 음악은 편집에서 한 곡으로 깝니다.** 모든 프롬프트에 "no background music"을 넣었습니다.
- **루프:** scene8은 Mochi가 카메라 앞에서 폴짝 직전 웅크린 자세로 끝납니다. scene1의 폴짝으로 이어지도록 페이드나 엔드카드는 넣지 않습니다.
- 질문 대사("Can you pounce?") 뒤는 0.5초만 남깁니다.

## 템포 (빠르게)

1차 편집(강아지 편)이 느리다는 피드백을 반영했습니다.

- **프롬프트:** 8초 안에 동작 3~4개를 2초 단위로 넣고, 첫 0.5초 안에 소리나 대사가 시작되게 했습니다. "slow" 카메라 무브는 빠른 무브로 바꾸고, "waits a moment", "holds still" 같은 멈춤은 뺐습니다. 노래는 약 120 BPM으로 빠르게 부르도록 적었습니다.
- **편집:** 8초 클립을 통째로 쓰지 않습니다.
  - 클립마다 앞뒤 0.3~0.5초의 준비 동작과 멈춘 끝을 자릅니다.
  - 한 클립을 2~3컷으로 나눕니다. 같은 클립 안에서 박자마다 110~130% 확대(펀치 인)로 끊으면 다시 생성하지 않아도 화면이 2~3초마다 바뀝니다.
  - 질문 뒤 쉼은 0.5초만 남깁니다.
  - 배경음악은 120~130 BPM 곡을 쓰고, 컷을 박자에 맞춥니다.
  - 목표 길이는 45~55초입니다.

## 공통 규칙 (모든 프롬프트에 이미 들어 있음)

- 같은 거실 설명과 배경 재료로 장소 고정
- Camera / Setting / Character(s) / Action / Dialogue / Audio / Style 순서, 동작은 `[00:00-00:02]` 시간 구간으로 2~3개만
- 대사는 `Dialogue:` 줄에 말하는 캐릭터와 목소리를 함께 적고, 말하지 않는 캐릭터는 "do not speak"
- 품종 이름 금지. "cartoon cat" + "No real animals, no other cats"
- 가족 순서는 항상 작은 순: Mochi → Grandma → Mommy → Daddy (family_lineup과 같게)
- 털실은 하나, 공중에 떠서 멈추는 물체 없음
- 캐릭터마다 한 마리씩 (no twins), 자막·글자·워터마크 금지
