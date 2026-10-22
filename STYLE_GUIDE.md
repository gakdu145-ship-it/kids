# 캐릭터 스타일 가이드

새로 만드는 모든 편(`patch-puppy-bath-time`, `lulu-fruit-train`, `kitty-family-dance`)에 공통으로 적용합니다. 이미 클립을 만든 Baby Dino 편은 기존 스타일 그대로 둡니다.

## 방향

**최신 3D CG 렌더링 + 클래식 손그림 장편 애니메이션 느낌.**
3D의 말랑한 질감과 조명에, 손그림 장편 애니메이션 특유의 큰 눈, 과장된 표정, 동그란 형태, 탄력 있는 움직임을 더합니다.

> 프롬프트에는 스튜디오나 브랜드 이름을 쓰지 않고 특징만 풀어 씁니다. 브랜드 이름을 넣으면 기존 캐릭터를 닮은 결과가 나오기 쉽고, 상업 채널에서 저작권·상표 문제가 생길 수 있습니다.

## 디자인 원칙

| 원칙 | 기준 |
|---|---|
| 실루엣 | 검은 그림자만 보고도 누군지 알아볼 수 있어야 함 (Patch의 한쪽 눈 반점, Lulu의 한쪽만 접힌 귀, Mochi의 주황 털 + 분홍 방울 목걸이) |
| 형태 언어 | 원 = 아이·친근함, 둥근 사각형 = 부모·안정감, 작은 삼각형은 포인트에만 (부리, 리본). 날카로운 모서리 없음 |
| 비율 | 아기 1.6~2등신, 부모 3~3.5등신. 머리가 클수록 어려 보임 |
| 눈 | 얼굴 대비 크게, 홍채를 크게, 하이라이트 2개. 감정은 눈썹과 눈꺼풀로 표현 |
| 컬러 | 캐릭터당 메인 1색 + 포인트 소품 1색. 순수 검정(#000) 금지, 부드러운 먹색 사용 |
| 소품 | 캐릭터마다 바뀌지 않는 소품 하나 (비니, 반다나, 샤워캡 등). 장면 간 일관성을 지키는 핵심 장치 |
| 움직임 | 스쿼시 앤 스트레치(착지할 때 눌렸다 펴짐), 동작마다 예비 동작(점프 전 웅크림) |

## 템포

강아지 편이 느리다는 피드백으로 정한 기준입니다. 새 편은 모두 이 기준으로 씁니다.

| 항목 | 기준 |
|---|---|
| 화면 전환 | 2~3초마다. 8초 클립 하나를 편집에서 2~3컷으로 나눔 |
| 장면 안 동작 | 8초에 동작 3~4개, 2초 단위. 첫 0.5초 안에 소리나 대사 시작 |
| 카메라 | "slow" 무브 금지. 고정 샷이면 화면 안 동작을 많이 |
| 멈춤 | "waits a moment", "holds still" 금지. 질문 뒤 쉼은 편집에서 0.5초 |
| 노래 | 약 120 BPM, 배경음악도 120~130 BPM |
| 길이 | 메인 Short 45~55초 |

## 프롬프트 공통 문구

**레퍼런스 시트 (`ref-images/*.txt`)**
```
Stylized 3D animated feature film look blending modern CG rendering with classic hand-drawn animation appeal: oversized expressive eyes with detailed irises and bright catchlights, soft rounded squash-and-stretch shapes, clear appealing silhouette, warm storybook pastel palette, soft studio lighting with a gentle rim light, plain white background, no text.
```

**장면 (`flow-scenes/*.txt`)**
```
Stylized 3D animated feature film look with classic hand-drawn animation appeal, expressive eyes, soft squash-and-stretch motion, warm storybook pastel colors, soft cinematic lighting, vertical 9:16, no on-screen text.
```

## 레퍼런스 이미지 구성

| 종류 | 대상 | 용도 |
|---|---|---|
| 턴어라운드 (정면·3/4·측면·후면) | 모든 캐릭터 | Flow 장면 재료 |
| 표정 시트 (6컷) | 주인공 (Patch, Lulu, Mochi) | 디자인 확인용. 표정이 일관된지 보고, 마음에 들면 턴어라운드를 다시 생성 |
| 크기 비교 라인업 | 고양이 가족 | 가족 장면 재료 |

캐릭터별 상세 설정(성격, 비율, 컬러 HEX, 표정, 일관성 체크)은 각 편의 `02_characters.md`에 있습니다.
