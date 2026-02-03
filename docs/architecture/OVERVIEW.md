# 系統概覽 (System Overview)

SummitMate 是一款 **Offline-First** 登山行程管理應用，支援 iOS、Android 與 Web (PWA)。

---

## 資料流架構

### Mobile (iOS/Android)

```mermaid
graph TD
    User[使用者] <--> FlutterApp

    subgraph Local [本地端]
        FlutterApp <--> Hive[(Hive Database)]
        FlutterApp <--> SharedPreferences[設定]
    end

    subgraph Service Layer [服務層]
        FlutterApp --> GoogleSheetsService
        FlutterApp --> GearCloudService
        FlutterApp --> PollService
        FlutterApp --> WeatherService
    end

    subgraph Cloud [雲端]
        GoogleSheetsService -- HTTP POST (JSON) --> GAS[Google Apps Script]
        GearCloudService -- HTTP POST --> GAS
        PollService -- HTTP POST --> GAS
        WeatherService -- GET --> GAS
        GAS <--> GSheets[Google Sheets]
    end
```

### Web (PWA)

針對瀏覽器 CORS 限制，Web 版採用特殊的 Data Flow:

```mermaid
graph TD
    WebApp[Flutter Web PWA]

    subgraph Service Layer
        WebApp --> GoogleSheetsService
    end

    subgraph Browser Security
        GoogleSheetsService -- "POST text/plain (Avoid Preflight)" --> GAS
    end

    subgraph Cloud
        GAS -- "302 Redirect" --> GoogleServer
        GoogleServer -- "200 OK (Echo Response)" --> WebApp
    end
```

---

## 技術堆疊

| 類別         | 技術                               |
| :----------- | :--------------------------------- |
| Framework    | Flutter 3.x (Dart 3.x)             |
| Platforms    | iOS, Android, Web (CanvasKit)      |
| Local DB     | Hive (NoSQL)                       |
| State        | flutter_bloc (Cubit) + Provider    |
| Backend      | Google Sheets + Google Apps Script |
| Architecture | Clean Architecture                 |

---

## 相關文件

- [專案結構](./PROJECT_STRUCTURE.md)
- [模組關聯圖](./MODULE_DIAGRAM.md)
- [離線架構](./OFFLINE.md)
- [認證架構](./AUTH.md)
