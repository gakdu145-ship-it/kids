# 효과음 출처

## Mixkit (Sound Effects Free License)

상업적 이용 가능(수익 창출 YouTube 포함), 출처 표기 의무 없음. 효과음 자체를 재배포하거나 내 것으로 등록하는 것은 금지입니다. 받은 날: 2026-10-21. 약관은 바뀔 수 있으니 업로드 전에 https://mixkit.co/license/ 를 한 번 확인하세요.

| 파일 | Mixkit 번호 | 원래 제목 | 쓰는 곳 |
|---|---|---|---|
| `squeak.wav` | 1014 | Rubber duck squeak | scene2 Quackers |
| `boing.wav` | 2894 | Boing hit sound | scene1·8 점프 |
| `mud_splat.wav` | 385 | Falling into mud surface | scene1·8 진흙 착지 |
| `lens_splat.wav` | 2889 | Funny cartoon fast splat | scene1 렌즈 진흙 |
| `splash.wav` | 1311 | Water splash | scene2 욕조 입수, scene4 발라당 |
| `splash_big.wav` | 2884 | Funny cartoon splash | scene6 물벼락 |
| `whoosh.wav` | 1490 | Fast whoosh transition | 마당↔욕실 전환 |
| `slide_up.wav` | 616 | Cartoon toy whistle | scene2 들어 올리기 |
| `amb_birds.wav` | 17 | Little birds singing in the trees | 마당 배경 |

원본 MP3는 `download/`에 있고, `fetch-sfx.ps1`이 WAV로 바꾸면서 앞의 무음을 자르고 음량을 맞춥니다.

## 배경음악: Mixkit (Stock Music Free License)

| 파일 | Mixkit 번호 | 제목 / 작곡 | 비고 |
|---|---|---|---|
| `../music/jumping-around.mp3` (+ `.wav`) | 8 | Jumping Around / Ahjay Stelino | 장르 Children, 약 108 BPM, 보컬 없음, 2:23 중 앞 63초 사용 |

상업적 이용 가능(YouTube 포함), 출처 표기 의무 없음. 원본 그대로 되팔거나 재배포하는 것은 금지입니다. 받은 날: 2026-10-21. Mixkit 음악 중 일부는 수익 창출 금지인 Restricted License이므로, 다른 곡으로 바꿀 때는 곡 페이지의 라이선스가 "Stock Music Free License"인지 꼭 확인하세요.

## 직접 합성 (`make-sfx.ps1`)

`whip`, `footstep`, `bloop1~5`, `pat`, `pop1~4`, `xylo`, `flutter`, `drip`, `ding`, `twinkle`, `amb_bubbles`, `amb_breeze`.
Mixkit 파일로 바뀐 소리의 합성 버전은 `synth/`에 보관합니다.
