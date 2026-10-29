# 趣味沉浸式 iOS 相冊：低 Token、防錯執行計劃

> 目標平台：iOS 18+，使用目前可用的 Xcode / iOS 27 SDK 編譯  
> 語言：Swift 6 language mode  
> 文件狀態：規劃完成，尚未建立 App 功能代碼

## 1. 固定決策

後續 Task 不再重新討論以下選項，除非有 benchmark 否決：

| 項目 | 決策 |
|---|---|
| UI | SwiftUI；iOS 18+ API 可用 |
| 資料 | SwiftData 只存 metadata；原圖與衍生圖存檔案系統 |
| 照片選擇 | Apple `PhotosPicker`，以檔案型 `Transferable` 匯入 |
| 影像管線 | Nuke 首選；若本地檔案 spike 失敗，才切換 Kingfisher |
| 首頁 | SwiftUI 2.5D 等軸測村落 + iOS 18 zoom transition |
| 展廳 | SwiftUI 3D transform 走廊 + 拍立得互動 |
| 真 3D | RealityKit `RealityView` + USDZ；不引入 SceneKit |
| 照片風格 | Core Image；只有確認需要時才採用 InstantCamera 的 MIT 代碼與聲明 |
| 架構 | Feature-first MVVM + Domain/Data 邊界；單 App target，暫不拆 Swift Package |
| 依賴 | 初期只加 Nuke；禁止同時加入 Nuke、Kingfisher、SDWebImage |

### 不做的過度設計

- 不建立多層 Interactor/UseCase，除非一個流程已被兩個以上 ViewModel 使用。
- 不先拆十幾個 Swift Package；先以目錄和 protocol 約束邊界。
- 不自行實作通用圖片下載器、動畫框架、輪播框架或資料庫。
- 不把 3D 場景物件、`UIImage`、`Color` 或沙盒絕對 URL 放進 Domain model。
- 不在每個 View 內直接操作 SwiftData 或 FileManager。

## 2. 目錄與責任邊界

```text
App/
  AppEnvironment.swift
  AppRouter.swift
  MemoryAlbumApp.swift

Domain/
  Models/
  Repositories/
  Policies/

Data/
  Persistence/
  FileSystem/
  ImagePipeline/
  Import/

Features/
  Home/
  Room/
  Gallery/
  PhotoDetail/

Scene3D/
  RoomScene/
  Rendering/
  Assets/

DesignSystem/
  Colors/
  Materials/
  Motion/
  Components/

Resources/
Tests/
UITests/
docs/
scripts/
```

依賴方向：

```text
App -> Features -> Domain
Data -> Domain
Features -> Data protocols only
Scene3D -> Domain snapshots only
Domain -> 無 UI / SwiftData / RealityKit / FileManager 依賴
```

## 3. 不可破壞的資料規則

1. `PhotoItemEntity` 只保存相對檔案路徑，例如 `originals/<UUID>.heic`。
2. 原圖保留原始編碼與 EXIF；顯示圖、縮圖、翻面效果圖都是可分離衍生檔。
3. 匯入流程必須 staged write；檔案、衍生圖、SwiftData 記錄全部成功才算完成。
4. 房間刪除使用 `.cascade` 刪 metadata，但檔案刪除由 `MediaCleanupCoordinator` 處理。
5. 啟動時清理孤兒檔案；資料缺失時顯示可恢復的 placeholder，不讓整個房間失敗。
6. 同一照片 UUID 的所有檔案共享前綴，禁止用可變的使用者名字作檔名。
7. 3D 展示參數保持純量欄位或穩定 JSON；不要把 `simd`、`Color`、`Entity` 直接持久化。
8. 佈局位置若由 UUID 生成，必須使用穩定 hash，不可在每次 render 使用新的隨機值。

## 4. 低 Token 工作流

### 4.1 每個 Task 的固定提示

在新一輪對話只貼這一小段，Task ID 換成下一個：

```text
讀取 AGENTS.md 和 docs/IMPLEMENTATION_PLAN.md 的 <TASK-ID>。
只實作該 Task；只修改其 File Scope；不要改依賴版本或無關代碼。
完成後執行指定驗收，回報 Changed / Checks / Risks，各最多 3 行。
```

不要在每次 prompt 重貼產品概念、架構或整份需求。完整上下文只維護在文件中。

### 4.2 節省 token 的規則

- 一次只交付一個可驗收的垂直切片，建議變更少於 500 行；超過 800 行必須拆分。
- 使用 `rg -n "symbol" path` 定位，不讓代理重讀整個專案。
- 錯誤只取最相關的 `error:` 行與最後 80 行；不貼完整 `xcodebuild` log。
- 同一個錯誤修三次仍失敗，停止並回報，不做無限猜測。
- 不為每個小功能重寫 README；只在 `docs/STATUS.md` 補一行狀態。
- 共用型別、命名、錯誤碼先由 Foundation Task 定義，後續任務只引用。
- 每完成一個 Sprint 才跑完整 build + tests + UI smoke；單 Task 跑最小測試集。

### 4.3 防錯閘門

- G0：工程可建立、可啟動、依賴解析成功。
- G1：資料與 storage 單元測試通過；失敗匯入不留下半成品。
- G2：選屋與轉場可返回、可恢復、Reduced Motion 可用。
- G3：展廳可長時間滑動；不因離屏卡片保留原圖。
- G4：RealityKit 垂直切片通過真機 frame time / memory / asset 預算。
- G5：完整匯入、刪除、重啟、前後台、動態字體與 VoiceOver 驗收。

### 4.4 執行環境前提

iOS 編譯與效能驗收必須在 macOS + Xcode 完成。Windows 端只能撰寫與審查代碼，不可宣稱 `xcodebuild`、Simulator 或 Instruments 已通過。每次跨主機交接先確認工程文件與依賴已同步。

## 5. Sprint 0：工程基線

### T0.1 工程腳手架與驗證命令

**目標**

建立 iOS 18、Swift 6、SwiftUI 的最小可啟動工程；以 `project.yml` 作 XcodeGen source of truth，加入 Nuke。

**File Scope**

`project.yml`、`App/`、`scripts/verify.sh`、`.gitignore`、`AGENTS.md`。

**驗收**

- Debug/Release 均可編譯。
- `scripts/verify.sh fast` 執行 build 與空測試。
- `.xcodeproj` 不手改；可由 `project.yml` 重生。
- 鎖定實際 Xcode/Swift 版本並記錄在 `docs/STATUS.md`。

### T0.2 Domain contracts 與測試 fixture

**目標**

定義 `RoomEntity`、`PhotoItemEntity`、repository protocols、typed errors 與穩定的 preview/test fixtures。

**File Scope**

`Domain/`、`Data/Persistence/`、`Tests/Domain/`、`Tests/Fixtures/`。

**驗收**

- Domain 不 import SwiftUI、SwiftData、RealityKit、FileManager。
- 房間與照片的一對多、排序、刪除契約有測試。
- 有 1 間房、4 間房、0 張照片、缺失檔案四組 fixture。

### T0.3 Nuke 本地圖 spike

**目標**

用一個 48MP HEIC、10 張 12MP JPEG、1 張方向異常 EXIF 圖，驗證 local URL/Data 載入、降採樣、取消、memory-only cache 與釋放。

**File Scope**

`Data/ImagePipeline/`、`Tests/ImagePipeline/`、`docs/DECISIONS.md`。

**驗收**

- 1000 px 展廳圖與 320 px 縮圖不經過 full-size `UIImage` 常駐。
- 連續更新 50 次不同 URL 能取消舊 request。
- 若 Nuke gate 失敗，決策文件記錄原因並切換 Kingfisher；不可雙棧。

## 6. Sprint 1：照片資料與匯入

### T1.1 `PhotoStorageManager`

**目標**

實作 actor 化的 staging、commit、delete、相對路徑解析與孤兒掃描。

**File Scope**

`Data/FileSystem/`、`Domain/Repositories/MediaFileRepository.swift`、`Tests/FileSystem/`。

**驗收**

- 支援 `stage -> commit` 與 `stage -> rollback`。
- 原子寫入；中途失敗不留下已發布檔案。
- 刪除房間後可回收所有相關原圖／衍生圖。
- 容器根目錄變更時仍可解析相對路徑。

### T1.2 ImageIO 衍生圖與 EXIF

**目標**

以 `CGImageSource` 做 decode-before-memory 的降採樣，生成 thumbnail/display，並抽取 EXIF 摘要。

**File Scope**

`Data/ImagePipeline/`、`Domain/Models/PhotoMetadata.swift`、`Tests/ImagePipeline/`。

**驗收**

- HEIC/JPEG、旋轉、廣色域、無 EXIF、損壞檔均有測試。
- 縮圖長邊 320 px、展廳圖長邊 1024 px，輸出比例正確。
- 匯入每張圖片時峰值不包含完整原始 pixel buffer。

### T1.3 `PhotoImportService`

**目標**

整合 `PhotosPickerItem` 檔案型 `Transferable`、分批匯入、進度、取消與補償。

**File Scope**

`Data/Import/`、`Features/Room/Import/`、`Tests/Import/`。

**驗收**

- 可取消 30 張批次且不留下 metadata 或檔案。
- 同名檔、重複 UUID、磁碟空間失敗有 typed error。
- main actor 不進行 decode、encode 或大型檔案 copy。
- 匯入後重啟 App，照片仍可顯示。

### T1.4 Repository 與清理協調器

**目標**

完成房間／照片 CRUD、排序更新與 `MediaCleanupCoordinator`。

**File Scope**

`Data/Persistence/`、`Data/FileSystem/MediaCleanupCoordinator.swift`、`Tests/Persistence/`。

**驗收**

- create/update/delete/reorder 均有測試。
- 刪除房間是先收集 UUID、提交 DB 刪除、再非同步清檔。
- DB 記錄缺失檔與孤兒檔都有恢復策略。

### T1.5 匯入驗證 UI

**目標**

做最小房間頁與縮圖網格，只為驗證完整資料流，不做最終九宮格產品 UI。

**File Scope**

`Features/Room/`、`DesignSystem/Components/`、`UITests/ImportFlowTests.swift`。

**驗收**

- 空房間、匯入中、部分失敗、完成、刪除狀態清楚。
- 一次顯示 100 張縮圖時不載入 display/original。
- UI test 完成匯入 3 張、重啟、再刪除。

## 7. Sprint 2：選屋與轉場

### T2.1 `HomeVillageModel`

**目標**

定義四間屋子的展示資料、排序、焦點、主題與 accessibility label；資料只依賴 Domain snapshot。

**File Scope**

`Features/Home/`、`Domain/Models/RoomSnapshot.swift`、`Tests/Home/`。

**驗收**

- ViewModel 可用 `@Observable` 且標記 `@MainActor`。
- 點擊意圖只輸出 `selectRoom(id)`，不直接 push View。
- Reduce Motion、VoiceOver 與不可用房間狀態有明確資料。

### T2.2 2.5D `HomeVillageView`

**目標**

實作等軸測村落、房屋卡片、層次深度、視差、選取聚焦、微動效。

**File Scope**

`Features/Home/`、`DesignSystem/Motion/`、`Resources/Village/`。

**驗收**

- 不依賴通用 carousel。
- 所有透視由單一穩定 state 驅動，無渲染期隨機值。
- Reduce Motion 時停用視差與彈簧，仍保留可用轉場。
- 真機 120 Hz 目標：互動 p95 frame budget < 8.3 ms。

### T2.3 Room zoom transition 與導航

**目標**

以 `NavigationStack`、route enum、iOS 18 matched transition source 完成選屋到房間，並支援返回與狀態恢復。

**File Scope**

`App/AppRouter.swift`、`Features/Home/`、`Features/Room/RoomHostView.swift`、`UITests/HomeNavigationTests.swift`。

**驗收**

- 快速連點不產生重複 route。
- 返回後原本選取屋子與捲動位置保持。
- 轉場期間與結束後不出現兩份 interactive view 同時響應。
- 背景恢復不 crash。

### T2.4 視覺系統與首頁完成度

**目標**

集中 theme token、材質、陰影、字體、sfx/haptic 介面，完成 loading/error/empty 狀態。

**File Scope**

`DesignSystem/`、`Features/Home/`。

**驗收**

- 四間房使用同一 theme enum，無散落 magic color。
- Dynamic Type、VoiceOver、對比度與 Reduce Motion 通過。
- 不新增外部 UI 依賴。

## 8. Sprint 3：沉浸式展廳

### T3.1 Gallery slot model

**目標**

用 Domain snapshot 計算穩定畫廊位置、索引、可見範圍與 LOD 等級；輸出純資料。

**File Scope**

`Domain/Policies/GalleryLayoutPolicy.swift`、`Features/Gallery/`、`Tests/Gallery/`。

**驗收**

- 相同 UUID/排序每次產生相同位置。
- 0/1/10/100/1000 張照片都能產生有限工作集。
- 不在 View 中計算 nested scrolling layout。

### T3.2 3D 透視走廊

**目標**

實作 `ScrollView` + `scrollTargetBehavior(.viewAligned)` + `rotation3DEffect` 的透視畫廊。

**File Scope**

`Features/Gallery/GalleryCorridorView.swift`、`DesignSystem/Components/`、`UITests/GallerySmokeTests.swift`。

**驗收**

- 當前頁與前後頁可預取，其他頁取消。
- 100 張縮圖長時間捲動後記憶體不持續成長。
- 120 Hz 與 60 Hz 均無可感知卡頓；Reduce Motion 使用淡入／位移替代深度旋轉。

### T3.3 拍立得卡與 EXIF 背面

**目標**

完成白邊、紙張、陰影、雙面翻轉、EXIF 詳情、便簽展示；前後兩面共用一個角度 state。

**File Scope**

`Features/Gallery/PolaroidCardView.swift`、`Features/PhotoDetail/`、`DesignSystem/Components/`。

**驗收**

- 不靠 `asyncAfter` 才切換卡面。
- 翻面期間 hit testing 正確，無雙面同時可點。
- EXIF 不讀取原圖即可顯示。
- 便簽修改有 debounce 和失敗提示。

### T3.4 拖拽、縮放與選取

**目標**

實作卡片拾取、拖動、放大、返回原位；手勢需與走廊滾動共存。

**File Scope**

`Features/Gallery/`、`DesignSystem/Motion/GalleryGesturePolicy.swift`、`Tests/Gallery/`。

**驗收**

- 水平拖動與垂直 pager 不互相搶手勢。
- 縮放只在卡面上生效；縮放後可 pan，雙擊可復位。
- 邊界限制、取消手勢、背景進入前台都能回到合法狀態。

### T3.5 展示參數持久化與展廳收尾

**目標**

保存卡片位置／角度／樣式；完成載入、錯誤、空房與刪除流程。

**File Scope**

`Data/Persistence/`、`Features/Gallery/`、`UITests/GalleryPersistenceTests.swift`。

**驗收**

- 重啟後展示位置與樣式一致。
- 刪除照片會同步移除可見卡片與衍生檔。
- 1000 張 metadata 查詢仍保持分頁／滑動可用。

## 9. Sprint 4：RealityKit 垂直切片

### T4.1 3D 資產契約與 preflight

**目標**

規定 USDZ 單位、座標軸、collider、材質、貼圖尺寸與相機路徑；建立自動檢查腳本。

**File Scope**

`docs/ASSET_SPEC.md`、`scripts/check_assets.sh`、`Scene3D/Assets/`。

**驗收**

- USDZ 可載入；單位、原點、朝向、碰撞體一致。
- 每間房貼圖 atlas 不大於 2048 px；首次上架資產有大小報告。
- 缺材質、NaN transform、超額 entity 會讓 CI fail。

### T4.2 星空房 `RealityView`

**目標**

建立一座房間、相機起點、燈光、環境、三張 3D 拍立得與一張照片 texture。

**File Scope**

`Scene3D/RoomScene/`、`Features/Room/RoomRealityView.swift`、`Resources/Scenes/`.

**驗收**

- 進房後 2 秒內顯示可互動場景，或有可取消的 loading state。
- 拍立得可 tap 進詳情；返回不重建整個 App 場景。
- `onDisappear` 取消 texture/task 並移除場景引用。

### T4.3 相機路徑與空間轉場

**目標**

從 Home 屋子焦點推進到房內相機，再反向退出；處理中斷、旋轉與背景。

**File Scope**

`Features/Home/`、`Features/Room/`、`Scene3D/RoomScene/`。

**驗收**

- 動畫可由中斷狀態恢復，不疊加兩次 camera transform。
- 返回時首頁焦點仍一致。
- Reduce Motion 直接切換，不播放長鏡頭。

### T4.4 Texture cache 與場景資源生命週期

**目標**

完成 1024 px texture、LRU 上限、離屏釋放、可見集合與 memory pressure 處理。

**File Scope**

`Scene3D/Rendering/`、`Data/ImagePipeline/`、`Tests/Scene3D/`。

**驗收**

- 只載入螢幕內與預取範圍 texture。
- 房間切換 20 次後記憶體不持續上升。
- texture 任務可取消；不會在釋放後 setter 回調。

### T4.5 第二間房與全量 Gate

**目標**

以第一間房的模板新增第二主題，證明主題配置可擴充；完成真機效能與 QA。

**File Scope**

`Scene3D/`、`Resources/Scenes/`、`UITests/EndToEndTests.swift`、`docs/STATUS.md`。

**驗收**

- 新增房間不改 Domain schema。
- 進房、翻卡、看 EXIF、刪除、返回、重啟全流程通過。
- 真機無 crash；RealityKit 房內總記憶體目標 < 300 MB。
- Instruments Animation Hitches、Time Profiler、Allocations、GPU 報告已保存。

## 10. 每 Sprint 的快速驗收

| Gate | 必跑 |
|---|---|
| 每 Task | 指定 unit tests + Debug build |
| Sprint 0 | `scripts/verify.sh fast`、App 啟動 smoke |
| Sprint 1 | 匯入 30 張、取消、重啟、刪房、orphan scan |
| Sprint 2 | 首頁導航 UI tests、Reduce Motion、120 Hz 真機 |
| Sprint 3 | 100 張捲動 + 翻卡 + 重啟；Allocations |
| Sprint 4 | 兩房 E2E、USDZ preflight、GPU/Memory/Hitches |

## 11. 效能與隱私硬門檻

- 展廳同時解碼：最多 3 張（當前、前一、後一）；其餘 request 取消。
- 縮圖長邊 320 px；展廳圖預設 1024 px；3D texture 預設 1024 px。
- `NSCache` 依 decoded cost 設上限，收到 memory warning 時清空非可見項。
- 不使用 `UIImage(data:)` 直接顯示大圖；進入顯示層前先降採樣。
- 匯入時限制並行數，逐張 `autoreleasepool`，可取消。
- 首頁與展廳不得在主執行緒同步讀檔、encode、decode 或解析 EXIF。
- 匯入依賴 `PhotosPicker`；只有「存回相簿」請求 `.addOnly`。
- 不上傳、不埋點、不以 PHAsset 作唯一真實來源。

## 12. 應保存的固定文件

- `AGENTS.md`：範圍、架構、命令、禁止修改項。
- `docs/GITHUB_OPEN_SOURCE_RESEARCH.md`：選型與授權。
- `docs/IMPLEMENTATION_PLAN.md`：Task 與驗收。
- `docs/DECISIONS.md`：只有推翻既有決策時新增。
- `docs/STATUS.md`：每 Task 一行，最新 Gate 與已知阻塞。
- `docs/ASSET_SPEC.md`：Sprint 4 前建立。

## 13. 建議起點

只執行 `T0.1`。完成並驗證工程可啟動後，再依序執行 `T0.2`、`T0.3`。在 T0.3 的影像 spike 得出結論前，不建立任何 3D 或正式展廳 UI，避免把錯誤的影像策略帶進後續所有功能。
