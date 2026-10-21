# Google Flow 장면 프롬프트 (처음부터 전체 생성)

설정: Veo 3.1 Lite, 9:16, x1. 프롬프트는 수정 없이 그대로 붙여넣습니다.

## 0. 배경 이미지 만들기 (Gemini, 1회)

| 프롬프트 | 저장할 이름 |
|---|---|
| `ref-images/bedroom.txt` | `ref-images/bedroom.png` |
| `ref-images/bathroom.txt` | `ref-images/bathroom.png` |

## 1~8. 장면 만들기 (Flow)

장면마다 재료 이미지를 올리고 `sceneN.txt`를 붙여넣습니다. 결과는 `DINO/sceneN.mp4`로 저장합니다.

| 장면 | 내용 | 카메라 무브 | 재료 이미지 |
|---|---|---|---|
| scene1 | 양치 싫어하는 아기 공룡 | 슬로우 푸시 인 | baby_dino, mama_dino, bedroom |
| scene2 | 이빨에 낀 음식과 세균 | 크래시 줌 인 | baby_dino, germs, bedroom |
| scene3 | 칫솔 Sparkle 등장 | 휩 팬 오른쪽 | baby_dino, sparkle, bathroom |
| scene4 | 1절: 앞니 위아래 | 고정 샷 | baby_dino, sparkle, germs, bathroom |
| scene5 | 2절: 어금니 동글동글 | 아크 라이트 | baby_dino, mama_dino, sparkle, bathroom |
| scene6 | 헹구고 뱉기 | 틸트 다운 | baby_dino, bathroom |
| scene7 | 반짝이는 이빨, 엄마 포옹 | 슬로우 줌 아웃 | baby_dino, mama_dino, bathroom |
| scene8 | 엔딩 후렴, 손 흔들기 | 크레인 업 | baby_dino, mama_dino, sparkle, bathroom |

재료 개수 제한에 걸리면 germs → sparkle 순으로 뺍니다. baby_dino와 배경은 빼지 않습니다.

## 공통 규칙 (모든 프롬프트에 이미 들어 있음)

- 같은 침실/욕실 설명과 배경 재료로 장소 고정
- 아기 공룡은 맨손, 칫솔은 하나, Sparkle은 손에 쥐는 크기
- 캐릭터는 한 번씩만 등장, 처음부터 끝까지 크기와 모습 유지
- 장면당 카메라 무브 1개, 속도와 시작·끝 구도 명시

8초 × 8개 = 약 64초. 편집에서 어색한 앞뒤를 잘라 60초로 맞춥니다.
