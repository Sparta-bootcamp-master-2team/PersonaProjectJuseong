# CurrencyConverterApp

**CurrencyConverterApp**은 실시간 환율 정보를 제공하고, 선택한 통화를 기준으로 손쉽게 계산할 수 있는 iOS 애플리케이션입니다.

<br>

## 주요 기능

- **실시간 환율 데이터 로드**: 네트워크를 통해 최신 환율 정보를 가져오며, 캐싱된 데이터가 유효하면 Core Data를 통해 로컬에서 불러옵니다.

- **환율 목록 제공 및 즐겨찾기**: 주요 통화들의 환율 정보를 목록으로 보여주고, 즐겨찾기 등록 및 해제가 가능합니다.

- **환율 계산기 기능**: 특정 통화를 기준으로 금액을 입력하면 다른 통화로 실시간 환산 결과를 제공합니다.

- **데이터 상태 복원 및 저장**: 앱 실행 시 마지막으로 보던 화면을 복원하며, 백그라운드 진입 시 현재 상태를 저장합니다.

- **상승/하락 아이콘 표시**: 이전 환율과 비교하여 변화가 있을 경우 상승/하락 이미지를 통해 시각적으로 표시합니다.

- **다크 모드 대응**: iOS 시스템 설정에 따라 자동으로 라이트/다크 모드를 전환하며, 가독성과 접근성을 고려한 색상 구성을 사용합니다.

<br>

## 기술 스택

- **프레임워크**: UIKit
- **레이아웃**: SnapKit (코드 기반 오토레이아웃)
- **데이터 저장**: Core Data (환율 정보 및 상태 저장)
- **비즈니스 로직 구성**: Clean Architecture (Presentation / Domain / Data Layer 분리)
- **비동기 처리**: Swift Concurrency (`async/await`)
- **화면 구성**: Coordinator 패턴 적용 (`AppCoordinator`)
- **설계 패턴**: MVVM

<br>

## 스크린샷
|             | 환율화면       | 계산기화면     |
|-------------|----------------|----------------|
| 라이트 모드 | <img src="https://github.com/user-attachments/assets/fc9f64b0-7d17-4364-925c-7cec80ab2595" width="250" /> | <img src="https://github.com/user-attachments/assets/1492b1ea-3299-4590-960f-552db317cba6" width="250" /> |
| 다크 모드   | <img src="https://github.com/user-attachments/assets/e0c99446-e993-4acd-8aa7-52529611dfc8" width="250" /> | <img src="https://github.com/user-attachments/assets/d90cf3ed-0ec8-4a09-8255-df7096ebf510" width="250" /> |

<br>

## 메모리 안정성 검증 (Memory Debugging)

환율 계산기 앱은 **Xcode의 Memory Graph Debugger**를 활용하여 화면 간 전환 및 반복적인 사용자 상호작용 이후에도 **메모리 누수 없이 안정적으로 객체가 해제되는 구조**임을 검증했다.

- **Memory Leak 및 순환 참조 확인**  
  Xcode의 **Memory Graph Debugger**를 통해 `ViewController`, `ViewModel`, `Coordinator` 간의 참조 관계를 시각적으로 분석하였다.
- **Memory Leak 디버깅**
  Leaks Instrument를 통해 ViewController 순환 참조나 retain cycle 없이 해제됨을 확인했다.

### 디버깅 화면
#### Leaks Instrument
<img src="https://github.com/user-attachments/assets/3472b6ea-8af8-4849-af0f-6939f12ef30b" width="80%">

#### Memory Graph Debugge
<img src="https://github.com/user-attachments/assets/f13345eb-4ae4-48f8-914c-afaedd369601" width="80%">

<br>

## 📁 프로젝트 구조

```
CurrencyConverterApp/
├── App
│   ├── AppCoordinator.swift                  // 앱의 초기 흐름을 담당하는 Coordinator
│   ├── AppDelegate.swift
│   ├── LaunchScreen.storyboard
│   └── SceneDelegate.swift
│
├── Data                                      // 실제 데이터 접근 구현부
│   ├── CoreData
│   │   ├── CoreDataManager.swift             // Core Data CRUD를 담당하는 비동기 Actor
│   │   ├── CoreDataModel.xcdatamodeld        // Core Data 모델 정의
│   │   └── CoreDataStack.swift               // NSPersistentContainer 설정
│   ├── Network
│   │   ├── ExchangeRatesDTO.swift            // API 응답을 위한 DTO 구조체
│   │   └── NetworkManager.swift              // 비동기 네트워크 요청 처리
│   └── Repository
│       └── ExchangeRateRepositoryImpl.swift  // Repository 인터페이스 구현체
│
├── Domain                                    // 비즈니스 로직 담당
│   ├── Entity
│   │   └── ExchangeRateInfo.swift            // 도메인 모델 (환율 정보)
│   ├── Protocol
│   │   └── ExchangeRateRepository.swift      // 데이터 접근을 추상화한 프로토콜
│   └── UseCase
│       ├── FetchExchangeRateUseCase.swift    // 환율 정보 전체 로드
│       └── ToggleFavoriteUseCase.swift       // 즐겨찾기 상태 토글
│
├── Presentation                              // 화면 구성 및 UI 로직
│   ├── CalculatorView
│   │   ├── CalculatorViewController.swift    // 계산기 화면 뷰컨
│   │   └── CalculatorViewModel.swift         // 계산기 화면 뷰모델
│   ├── ExchangeRateView
│   │   ├── ExchangeRateCell.swift            // 환율 셀 뷰
│   │   ├── ExchangeRateViewController.swift  // 환율 목록 뷰컨
│   │   └── ExchangeRateViewModel.swift       // 환율 목록 뷰모델
│   └── Protocol
│       └── ViewModelProtocol.swift           // 공통 ViewModel 프로토콜 정의
│
├── Resource
│   ├── Assets.xcassets
│   └── Info.plist
│
└── Utils
    └── Extensions
        ├── Array+Extensions.swift            // Array 관련 유틸 확장
        └── UIViewController+Extensions.swift // UIViewController 관련 유틸 확장
```
