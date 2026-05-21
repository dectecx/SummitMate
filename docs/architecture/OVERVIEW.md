# 系統概覽 (System Overview)

SummitMate 是一款 **Offline-First** 登山行程管理應用，支援 iOS、Android 與 Web (PWA)。

---

## 系統架構

本專案採用前後端分離架構，後端為基於 Go 與 PostgreSQL 的 RESTful API 服務。

```mermaid
graph TD
    User[使用者] <--> FlutterApp[Flutter App]

    subgraph Local ["本地端"]
        FlutterApp <--> Drift[(Drift SQLite)]
        FlutterApp <--> SecureStorage[Secure Storage]
    end

    subgraph GoBackend ["Go Backend"]
        FlutterApp -- "REST (JSON)" --> ChiRouter[Chi Router]
        ChiRouter --> APIAdapter[API Adapters]
        APIAdapter --> Domain[Domain (Handlers, Services)]
        Domain --> Repo[Repositories]
        Repo --> PgPool[(PostgreSQL)]
    end
```

### Go Backend 內部分層 (Domain-Driven Design)

```mermaid
graph LR
    subgraph cmd
        API[cmd/api]
        Migrate[cmd/migrate]
        WeatherJob[cmd/weatherjob]
    end

    subgraph internal
        App[app]
        Common[common]
        subgraph Domains
            Trip[trip]
            Auth[auth]
            Interaction[interaction]
            GroupEvent[groupevent]
        end
    end

    API --> App
    App --> Domains
    Domains --> Common
```

---

## 技術堆疊

| 類別               | 技術                                              |
| :----------------- | :------------------------------------------------ |
| Frontend Framework | Flutter 3.x (Dart 3.x)                            |
| Platforms          | iOS, Android, Web (CanvasKit)                     |
| Local DB           | Drift (SQLite)                                    |
| State Management   | flutter_bloc (Cubit)                              |
| Tutorial System    | TutorialCubit + Memory Mock Injection             |
| API Layer (FE)     | Retrofit + Dio + Freezed (Code-Gen)               |
| DI / Service Loc.  | Injectable + GetIt                                |
| Backend            | Go 1.26 + Chi v5 + PostgreSQL                     |
| API Style          | OpenAPI 3.0 (Code-Gen via oapi-codegen)           |
| Authentication     | JWT (Access + Refresh Token)                      |
| Logging            | `log/slog` (JSON prod / Text dev)                 |
| Architecture       | Clean Architecture (Frontend) / Layered (Backend) |

---

## API 端點總覽

Go Backend 提供 `/api/v1` 前綴的 RESTful API，包含以下模組：

| 模組         | 端點範例                                                  | 認證       |
| :----------- | :-------------------------------------------------------- | :--------- |
| Health       | `GET /health`                                             | 無         |
| Auth         | `POST /auth/register`, `POST /auth/login`, `GET /auth/me` | 部分需 JWT |
| Trips        | `GET /trips`, `POST /trips`, `PUT /trips/{id}`            | JWT        |
| Trip Members | `GET /trips/{id}/members`, `POST /trips/{id}/members`     | JWT        |
| Itinerary    | `GET /trips/{id}/itinerary`, `POST /trips/{id}/itinerary` | JWT        |
| Trip Gear    | `GET /trips/{id}/gear`, `PUT /trips/{id}/gear/batch`      | JWT        |
| Trip Meals   | `GET /trips/{id}/meals`, `PUT /trips/{id}/meals/batch`    | JWT        |
| Messages     | `GET /trips/{id}/messages`, `POST /trips/{id}/messages`   | JWT        |
| Polls        | `GET /trips/{id}/polls`, `POST /trips/{id}/polls`         | JWT        |
| Gear Library | `GET /gear-library`, `PUT /gear-library/batch`            | JWT        |
| Meal Library | `GET /meal-library`, `PUT /meal-library/batch`            | JWT        |
| Favorites    | `GET /favorites`, `PUT /favorites/batch`                  | JWT        |
| Group Events | `GET /group-events`, `POST /group-events`                 | 部分需 JWT |
| Weather      | `GET /weather/hiking`, `GET /weather/hiking/{location}`   | 無         |
| Logs         | `POST /logs`                                              | 無         |
| Heartbeat    | `POST /system/heartbeat`                                  | JWT        |

完整 OpenAPI Spec 可透過 `GET /openapi.json` 取得，互動式文件位於 `GET /docs` (Scalar UI)。

---

## 互動教學系統 (Tutorial System)

系統採用 **Memory-only Mock Injection** 模式：
- **無定位依賴**：改用卡片導覽（Slide-based）取代舊有的 `GlobalKey` 遮罩定位，提升 UI 重構時的穩定性。
- **資料注入**：透過 `TutorialCubit` 將範例資料注入 `TripCubit`、`GearCubit` 等，讓使用者在真實介面中體驗功能。
- **寫入保護**：在教學模式下，系統會自動阻斷所有對本地 SQLite (Drift) 的寫入操作，確保測試資料不會永久保存。

---

## 相關文件

- [專案結構](./PROJECT_STRUCTURE.md)
- [模組關聯圖](./MODULE_DIAGRAM.md)
- [離線架構](./OFFLINE.md)
- [認證架構](./AUTH.md)
- [API Contract](../api/CONTRACT.md)
