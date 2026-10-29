# 「趣味沉浸式 iOS 相冊」GitHub 開源方案調研

> 調研日期：2026-10-29  
> 目標平台：iOS 18+、Swift 6、SwiftUI、SwiftData、PhotosUI  
> 本階段只做選型，不建立 App 工程、不提交產品程式碼。

## 1. 結論先行

GitHub 上沒有找到一個成熟、授權清楚、支援 iOS 18+、可直接承擔「微縮村落 + SwiftData 房間 + 沉浸式 3D 照片展廳」的一站式開源 App。可持續的做法是：

1. **產品核心自研**：房間模型、照片生命週期、沉浸式畫廊、手勢與轉場。這些是產品差異，不應被通用輪播元件綁住。
2. **Apple 原生優先**：`PhotosPicker`、SwiftData、ImageIO、Core Image、SwiftUI 3D transform、RealityKit。
3. **只引入一個成熟的影像管線依賴**：首選 Nuke；若本地檔案 provider 的實測結果不理想，改用 Kingfisher。
4. **3D 分層演進**：首版用 SwiftUI 2.5D 完成選屋與卡片展廳；需要真正走動、光影、實體空間時，再以 RealityKit `RealityView` 接入 USDZ 房間。
5. **展示型專案只借鑑實作**：SnapJournal、AR Spatial Photo Gallery、InstantCamera 等可提供拍立得、翻面、材質與色調思路，但除 InstantCamera 外都不宜直接作為生產依賴。

## 2. 建議採用的最小依賴棧

| 能力 | 決策 | 理由 |
|---|---|---|
| 照片選擇 | Apple `PhotosPicker` | 不要求完整相簿權限，適合「只選幾張、複製進 App」的產品模型 |
| 元數據持久化 | SwiftData | iOS 18 原生、與 SwiftUI 整合好；不把原圖 BLOB 寫進資料庫 |
| 原圖與衍生檔 | 自建 actor + Application Support 目錄 | 檔案與資料庫是兩個交易域，需要補償、孤兒清理與路徑可遷移設計 |
| 影像解碼／降採樣／快取 | 首選 Nuke，實測 gate 不過則改 Kingfisher | 避免自行重做解碼、取消、request coalescing、記憶體快取與降採樣 |
| 照片風格 | Core Image | 適合作為拍立得、紙張、色調與顆粒的本地處理層 |
| 首頁選屋 | SwiftUI 2.5D perspective / isometric | 視覺可控、啟動快、可精細控制卡片命中與無障礙 |
| 展廳互動 | SwiftUI 3D transform + 原生 ScrollView | iOS 18 的 view-aligned paging 與放大轉場足以處理大部分照片牆與拍立得場景 |
| 真 3D 房間 | RealityKit `RealityView` + USDZ | iOS 18 可用，Apple 長期方向明確；不必為此引入 SceneKit |
| 3D 拖拽輔助 | 可選 RealityUI，先做技術驗證 | 成熟度尚可，但產品應用的必要性要由實際手勢需求決定 |

不要同時引入 Nuke、Kingfisher 與 SDWebImage。對本產品而言，它們解決的是同一層問題。

## 3. 候選方案評估

### 3.1 可直接採用或優先試用

| 專案 | 現況與授權 | 適用性 | 決策 |
|---|---|---|---|
| [Nuke](https://github.com/kean/Nuke) | 約 8.7k stars；MIT；近期仍活躍；Swift 6.2／iOS 16+ 分支已在開發 | `ImagePipeline`、記憶體／磁碟快取、request coalescing、prefetch、image processing、SwiftUI `LazyImage` | **首選影像管線**。只使用解碼、降採樣與快取能力；原圖生命週期仍由本專案的 storage actor 管理 |
| [Kingfisher](https://github.com/onevcat/Kingfisher) | 約 24.4k stars；MIT；近期仍活躍；Swift 6 strict concurrency prepared | 明確提供 `LocalFileImageDataProvider`、`DownsamplingImageProcessor`、SwiftUI 支援 | **保守備選**。若 Nuke 對本地沙盒 URL 或 memory-only cache 的 spike 不理想，改用它 |
| [Clean Architecture SwiftUI](https://github.com/nalexn/clean-architecture-swiftui) | 約 6.6k stars；MIT；2024 年已重整到現代 SwiftUI + SwiftData | Presentation / business logic / data access 分層、程式化導航、測試結構 | **架構參考，不複製整包代碼** |
| [InstantCamera](https://github.com/benny202505/InstantCamera) | MIT；Swift 6；Core Image；星數很低但授權與模組邊界清楚 | 拍立得色調、高光壓縮、顆粒、暗角、Frame layout；`InstaxCore` 與 UI 分離 | **先作為色調參考；若採用其代碼，需保留 MIT 聲明並補 memory／concurrency 審查** |

### 3.2 值得試用，但不是核心依賴

| 專案 | 現況與授權 | 優勢 | 限制 |
|---|---|---|---|
| [RealityUI](https://github.com/maxxfrazer/RealityUI) | 約 703 stars；MIT；近期仍活躍；Package 標示 iOS 13+ | RealityKit 的 drag / turn / tap component、約束與動畫封裝 | README 仍以 Swift 5.8／Xcode 13 表述；若使用，需先在目前 Xcode + Swift 6 語言模式做相容性 spike |
| [SwiftUIPager](https://github.com/fermoya/SwiftUIPager) | 約 1.47k stars；MIT；近期仍活躍 | 純 SwiftUI pager、頁面回收、縮放／旋轉動畫 | 是通用 pager，不是 3D 展廳；iOS 18 已可直接用 `ScrollView` + `scrollTargetBehavior`，不必為核心互動增加依賴 |
| [Prism](https://github.com/aheze/Prism) | 約 987 stars；MIT；最後 push 約在 2023 | 任何 SwiftUI View 都能做透視、擠出、陰影；非常適合 2.5D 趣味屋子 | 已多年未大改；複雜 3D 場景與碰撞仍需自建。適合參考或局部 vendor，不應成為不可替換的場景引擎 |

### 3.3 只適合閱讀與借鑑

| 專案 | 現況與授權 | 可借鑑 | 為什麼不直接依賴 |
|---|---|---|---|
| [SnapJournal](https://github.com/Kaushiki27Rai/SnapJournal-Project) | 約 1 star；README 宣稱 MIT，但倉庫中沒有 `LICENSE` 檔 | 拍立得 UI、`rotation3DEffect` 雙面翻轉、側邊點擊、Face ID 私有便簽、ImageRenderer 匯出 | 原圖以 `UIImage` 放在 model 中，會放大記憶體；元數據在 UserDefaults；同步 JPEG 寫入可能阻塞主執行緒；資料庫與檔案刪除沒有交易補償 |
| [AR Spatial Photo Gallery](https://github.com/JHONNYB01/ar-spatial-photo-gallery) | 無 LICENSE 檔；只有兩個展示檔 | RealityKit 程序化拍立得、`TextureResource.generate`、正反面貼圖、ARWorldMap 之外的 transform 編碼思路 | 預設為版權保留；不是完整 App；不應直接複製。其 `UIGraphics` 正規化也仍先解碼整張大圖 |
| [Vision Pro Spatial Photos](https://github.com/VeliuSami/visionpro-spatial-photos) | MIT；visionOS 範例 | RealityView 圖片弧線排列、frame entity、Metal vignette | 只適用 visionOS，不是 iOS 手機方案 |
| [PhotosPickerExplorer](https://github.com/kenkarimi/PhotosPickerExplorer) | 未見明確授權；展示專案 | PhotosPicker 與 Transferable 的最短範例 | 功能與生產生命週期不足；產品應直接使用 Apple API |
| [JustPhotoPicker](https://github.com/igooor-bb/JustPhotoPicker) | MIT；近期有提交 | 自訂相簿選擇器 UI | 使用完整 PhotoKit 相簿介面，通常比系統 `PhotosPicker` 要求更廣的相簿權限；不符合本產品「選中才複製」的隱私優先模型 |

### 3.4 明確不建議

| 專案／方案 | 原因 |
|---|---|
| [SceneView](https://github.com/sceneview/sceneview) | Apple 目標目前標示 **Alpha**，最低 **iOS 18** | 本產品雖可採用，但它主要封裝模型展示／AR；自訂展廳與相機控制仍需大量原生 RealityKit，所以不列為首選 |
| [CollectionViewPagingLayout](https://github.com/amirdew/CollectionViewPagingLayout) | 約 2.8k stars 很有吸引力，但倉庫已 **archived**；不應成為新專案的長期基礎 |
| [FSPagerView](https://github.com/WenchaoD/FSPagerView) | 約 7.4k stars、MIT、成熟，但本質是 UIKit `UICollectionView` 輪播；純 SwiftUI 專案引入它會增加橋接與手勢衝突 |
| [CardCarousel](https://github.com/Pafgz/CardCarousel) | MIT，但僅做 scale / offset / zIndex，沒有真正透視；核心體驗不足 |
| [3D-Carousel](https://github.com/noob-programmer1/3D-Carousel) | 星數與使用歷史太少，適合閱讀，不適合承擔核心導航 |

## 4. 3D 技術路線結論

| 路線 | 優勢 | 代價 | 建議 |
|---|---|---|---|
| SwiftUI 3D transform / Prism 類方案 | 啟動快、與 SwiftUI 狀態／字體／無障礙融合；適合卡片、拍立得、選屋；不需要 USDZ | 不是真正的場景圖；沒有實體遮擋、碰撞、光照與可走動相機 | **首版首頁與卡片展廳首選** |
| RealityKit + `RealityView` | iOS 18 原生；PBR、燈光、相機、實體節點、空間互動；Apple 後續方向明確 | 需要 USDZ 資產與材質管線；SwiftUI 視圖不能直接當 3D 節點；測試成本較高 | **真 3D 房間、可走動走廊、複雜房屋模型首選** |
| SceneKit | 舊資料與範例多，`SCNView` 手勢 API 熟悉 | 新專案生態已明顯落後 RealityKit；與 SwiftUI 的邊界仍要靠 representable | 可作為過渡或特定遺留需求，不作為新產品主渲染器 |
| SpriteKit | 2D 粒子、場景與物理簡單 | 只有平面，無法自然承擔走廊與屋子深度 | 不選為主架構；可局部做光影粒子 |

### 建議的漸進路徑

1. **Sprint 1–2**：以純 SwiftUI 做等軸測村落、房屋卡片、3D 翻面與拍立得。先把資料、權限、照片匯入與 60/120fps 基線打穩。
2. **Sprint 3**：對「星空觀測台」做 RealityKit 垂直切片：一座 USDZ 屋子、一枚 3D 拍立得、一次鏡頭推進、一次返回。
3. **Sprint 4**：量測真機 GPU frame time、記憶體峰值與資產載入時間，再決定其餘房間是否全部 RealityKit 化。

這樣不會讓「3D 引擎選型」卡住資料模型與最重要的照片體驗，也不會先做一個無法維護的全 3D 地圖。

## 5. 對系統架構的直接影響

### 5.1 照片與資料庫必須分離

SwiftData 只保存可查詢的文字、日期、標籤、相對路徑與展示參數。原圖、展示圖、縮略圖放在 Application Support 目錄：

```text
Application Support/
  Memories/
    originals/<UUID>.<ext>
    display/<UUID>.heic
    thumbnails/<UUID>.jpg
```

不要持久化沙盒絕對路徑；App 容器路徑可能因升級、還原或備份而改變。資料庫存相對路徑，啟動時再由 storage actor 解析。

刪除房間不能只依賴 SwiftData cascade 自動刪檔。應採用：

1. 標記或收集將被刪除的 photo UUID；
2. 刪除資料庫關聯；
3. 透過非同步 storage actor 刪除檔案；
4. 啟動時掃描孤兒檔案並清理。

### 5.2 匯入採 staged commit

`PhotosPicker` 選中後，流程應是：

```text
PhotosPickerItem
  -> 取得原始檔案／Transferable
  -> staging 目錄原子寫入
  -> 背景解析 EXIF 與尺寸
  -> 生成 thumbnail / display derivative
  -> SwiftData 插入記錄
  -> 成功後 rename/commit
  -> 任一步失敗則回收 staged files
```

不要先插入 SwiftData 再寫照片檔，否則很容易產生有記錄、無圖片的房間。

### 5.3 影像載入分級

| 用途 | 目標像素 | 策略 |
|---|---|---|
| 首頁房屋縮略圖 | 256–512 px | 一般 `Image`／memory cache |
| 展廳卡面 | 768–1024 px | ImageIO/Nuke 降採樣後顯示 |
| 全螢幕檢視 | 依畫面點數 × `displayScale` | 只解碼當前頁與前後各一頁 |
| 原圖 | 不常駐記憶體 | 僅在匯出、EXIF 詳情或明確需要最高畫質時讀取 |
| RealityKit texture | 通常 1024 px 上限 | 生成 `TextureResource` 後釋放中間 `CGImage`／`UIImage` |

`PhotosPickerItem.loadTransferable(type: Data.self)` 對大量 4K/48MP 圖會帶來不必要的整檔駐留；優先使用檔案型 `Transferable`，或使用 `loadTransferable(type:)` 的檔案 representation 後在背景搬移。

### 5.4 權限策略

- 匯入照片：使用系統 `PhotosPicker`，正常情況下不需要完整 Photo Library 權限說明與自訂授權 gate。
- 將作品存回相簿：只在實際使用時請求 `.addOnly`，並提供設定頁深層連結。
- 不保存 PHAsset 作為核心資料來源；使用者可在系統相簿刪除原圖，而 App 內選入的副本仍應存在。
- EXIF 應從已複製的原檔用 ImageIO 讀取，摘要寫入 SwiftData；避免每次顯示詳情都解碼原圖。

### 5.5 手勢與轉場

- 卡片翻面：前後兩面相差 180°，用同一個 `flipAngle` 驅動，不要靠延遲計時器切換布林值。
- 畫廊：原生 `ScrollView` + `scrollTargetBehavior(.viewAligned)` 作為骨架，`rotation3DEffect` 只負責視覺深度。
- 選屋英雄轉場：在相同 SwiftUI hierarchy 用 `matchedGeometryEffect`、全螢幕 overlay 或 iOS 18+ 的 zoom navigation transition。
- 縮放與拖曳：只有在 `scale > 1` 時允許 pan；與 pager 滾動同時存在時，需設定手勢優先級與方向門檻。

## 6. 特定範例的品質判讀

### SnapJournal

值得借鑑：

- 前後卡面相差 180°，同一角度驅動 `rotation3DEffect`；
- 卡片左右側透明 hit zone 的操作方式；
- 拍立得比例、紙張橫線、Face ID 與 ImageRenderer 匯出；
- 明確的 MVVM / Observation 分層意圖。

不能直接照搬：

- `Moment` 直接持有 `UIImage`；
- 所有原圖同步 JPEG 寫入與同步讀回；
- metadata 使用 UserDefaults；
- 每張照片先完整 `UIImage(data:)`，沒有解碼前降採樣；
- 刪檔與 metadata 更新不是同一個可恢復交易；
- README 宣稱 MIT，但缺乏 `LICENSE` 檔，法律狀態不能僅憑 README 當作已證實。

### AR Spatial Photo Gallery

值得借鑑：

- 用 `ModelEntity` 程序化建立白框與照片平面；
- `TextureResource.generate(from:options:)` 的非同步貼圖流程；
- 相框厚度、文字層、陰影與抬高避免 z-fighting；
- 將輕量 metadata 與大型世界地圖／材質分開儲存。

不能直接照搬：

- `UIGraphics` 正規化前已經拿到完整 `UIImage`；
- 所有工作標成 `@MainActor`；
- 倉庫沒有 LICENSE，不能複製代碼到商業產品；
- 只展示兩個檔案，缺少完整生命週期與測試。

### InstantCamera

值得借鑑：

- `InstaxCore` 與 SwiftUI App 分離；
- 將多種拍立得 personality 編碼為色調曲線、飽和度、亮部壓縮、顆粒與暗角；
- `CIContext.createCGImage` 明確控制輸出尺寸；
- `addOnly` 儲存相簿與 continuation 化的保存 API。

仍需補強：

- 先完整解碼輸入圖到 `UIImage`，再交給 Core Image，記憶體峰值不理想；
- `CIContext` 若每次建立，會增加 GPU／CPU 資源重建成本；
- 應改為 ImageIO 先降採樣，再建立 `CIImage`；
- 正式產品需加入色彩空間、廣色域、HDR、EXIF 方向與可取消任務測試。

## 7. 建議納入後續技術方案的「硬性決策」

1. 最低版本為 iOS 18；可採用 iOS 18+ 的 3D 與轉場 API。
2. 不將原圖 `Data` 寫入 SwiftData 作為常規存儲。
3. 持久化檔案相對路徑，不持久化容器絕對路徑。
4. 照片先 staged 寫入，再提交 SwiftData metadata。
5. 所有縮略圖與展廳圖在背景解碼，並依顯示尺寸降採樣。
6. 選屋與卡片互動優先 SwiftUI 3D transform；RealityKit 只承擔真正需要 3D 幾何的房間。
7. 通用 carousel 不支撐產品核心；不要因「不想造輪子」而引入會限制產品特色的 paging library。
8. Nuke／Kingfisher 二選一，以本地檔案、取消、預取、記憶體峰值與冷啟動實測決定，禁止雙棧並存。
9. 所有採用的第三方代碼保留 LICENSE／NOTICE；沒有 LICENSE 的展示專案只做概念參考。
10. 在進入 3D 全量製作前，先完成一個 RealityKit 垂直切片與效能 gate。

## 8. 下一階段建議

下一步應先寫產品技術架構與資料模型，不急著建立全部 3D 資產。第一批可執行 Task 建議是：

1. 建立 iOS 18 SwiftUI 工程、Swift 6 strict concurrency 設定與 CI；
2. 完成 SwiftData `RoomEntity` / `PhotoItemEntity` 與 storage actor 的 staged import spike；
3. 完成 Nuke 本地檔案／降採樣／預取 benchmark；
4. 完成純 SwiftUI 3D 選屋＋卡片翻面的視覺 spike；
5. 完成一個 RealityKit 星空房垂直切片，量測 frame time、memory peak 與 asset load；
6. 只有在上述 gate 通過後，再批量生產房屋與展廳資產。
