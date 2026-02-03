# 權限與成員管理規格 (Permissions & Membership Spec)

## 概述

SummitMate 採用 **Role-Based Access Control (RBAC)** 搭配 **Trip Membership (行程成員)** 的混合權限模型。
使用者必須同時滿足「系統角色權限」與「行程成員資格」才能執行特定操作。

## 系統角色定義 (System Roles)

系統目前定義以下幾種全域角色 (儲存於 `UserProfile.roleCode` 與 `permissions` 欄位)：

| 角色代碼 (Role Code) | 角色名稱 | 描述                               | 預設權限                                                                    |
| :------------------- | :------- | :--------------------------------- | :-------------------------------------------------------------------------- |
| `admin`              | 管理員   | 系統超級使用者                     | 所有權限 (`*`)                                                              |
| `guide`              | 嚮導     | 可建立與管理行程的專業嚮導         | `trip.create`, `trip.edit`, `trip.delete`, `trip.transfer`, `member.manage` |
| `member`             | 隊員     | 一般參與者，僅能檢視或編輯自己資料 | `trip.view`                                                                 |

---

## 行程層級角色 (Trip-Level Roles)

除了系統角色外，每個行程 (Trip) 內的成員還有「行程層級角色」，儲存於 `TripMembers.role_code`：

| 角色代碼 | 顯示名稱 | 說明                               |
| :------- | :------- | :--------------------------------- |
| `leader` | 團長     | 行程擁有者 (Owner)，擁有完整控制權 |
| `guide`  | 嚮導     | 協助管理行程，可編輯與管理成員     |
| `member` | 隊員     | 一般成員，僅能檢視                 |

> [!IMPORTANT]
> `Trip.userId` 欄位代表該行程的 **團長 (Leader/Owner)**，此人絕對擁有編輯/刪除/移交權限，無需額外檢查成員資格。

---

## 行程成員資格 (Trip Membership)

### 成員資料結構

**Trip Model (本地端)**

```dart
List<String> members; // 儲存 User ID 列表
```

**TripMembers Table (雲端)**
| Column | Type | Description |
| :-------- | :--- | :--------------------- |
| trip_id | UUID | 行程 ID |
| user_id | UUID | 使用者 ID |
| role_code | Text | `leader`, `guide`, `member` |

- **建立者 (Creator)**：建立行程時自動加入 `members` 並設為 `leader`。
- **加入成員**：擁有 `member.manage` 權限者可將其他 User ID 加入列表。

---

## 權限判斷矩陣

操作權限判斷邏輯：`Can(Action, User, Trip)`

| 操作 (Action)      | 系統角色 (Role) | 條件                          | 結果 (Result) | 備註                                     |
| :----------------- | :-------------- | :---------------------------- | :------------ | :--------------------------------------- |
| **View Trip**      | Admin           | N/A                           | ✅ Allow      | Admin 可見所有                           |
| **View Trip**      | Any             | `trip.members.contains(user)` | ✅ Allow      | 成員可見                                 |
| **View Trip**      | Any             | 非成員                        | ❌ Deny       | 非成員不可見                             |
| **Edit Trip**      | Admin           | N/A                           | ✅ Allow      |                                          |
| **Edit Trip**      | Any             | `trip.userId == user.id`      | ✅ Allow      | **團長 (Leader/Owner) 絕對擁有編輯權限** |
| **Edit Trip**      | Guide           | 是成員 + 有 `trip.edit`       | ✅ Allow      | 嚮導且在隊內                             |
| **Edit Trip**      | Member          | 是成員                        | ❌ Deny       | 一般隊員僅有檢視權限                     |
| **Delete Trip**    | Admin           | N/A                           | ✅ Allow      |                                          |
| **Delete Trip**    | Any             | `trip.userId == user.id`      | ✅ Allow      | **團長 (Leader/Owner) 絕對擁有刪除權限** |
| **Delete Trip**    | Guide           | 是成員 + 有 `trip.delete`     | ✅ Allow      |                                          |
| **Manage Members** | Guide           | 是成員 + 有 `member.manage`   | ✅ Allow      | 邀請/移除成員                            |

---

## 實作細節

### PermissionService 程式碼

```dart
bool canEditTripSync(UserProfile? user, Trip trip) {
  if (user == null) return false;
  if (user.roleCode == RoleConstants.admin) return true;

  // 0. 團長 (Leader/Owner) 絕對擁有編輯權限
  if (trip.userId == user.id) return true;

  // 1. 必須是行程成員 (基本門檻)
  if (!trip.members.contains(user.id)) return false;

  // 2. 必須擁有 'trip.edit' 權限 (角色賦予)
  return user.permissions.contains('trip.edit');
}

bool canDeleteTripSync(UserProfile? user, Trip trip) {
  if (user == null) return false;
  if (user.roleCode == RoleConstants.admin) return true;

  // 0. 團長 (Leader/Owner) 絕對擁有刪除權限
  if (trip.userId == user.id) return true;

  // 1. 必須是行程成員
  if (!trip.members.contains(user.id)) return false;

  return user.permissions.contains('trip.delete');
}
```

### 本地行程處理 (Pending Create)

未同步至雲端的行程 (`SyncStatus.pendingCreate`) 無法從 API 取得成員資料。
`MemberManagementScreen` 會使用本地快取的使用者資料顯示創建者為團長。

---

## 未來擴充

- **權限群組 (Permission Groups)**: 針對單一行程設定 Admin/Editor/Viewer (目前暫不實作)
- **公開行程 (Public Trips)**: 開放非成員檢視 (目前預設均為 Private)
- **行程轉移 (Transfer)**: 允許團長將 Leader 角色轉移給他人
