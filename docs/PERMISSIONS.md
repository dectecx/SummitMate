# 權限與成員管理規格 (Permissions & Membership Spec)

## 概述

SummitMate 採用 **Role-Based Access Control (RBAC)** 搭配 **Trip Membership (行程成員)** 的混合權限模型。
使用者必須同時滿足「系統角色權限」與「行程成員資格」才能執行特定操作。

## 角色定義 (System Roles)

系統目前定義以下幾種全域角色 (儲存於 `permissions` 欄位或 `role` 欄位)：

| 角色代碼 (Role Code) | 角色名稱 | 描述                               | 預設權限                                                                    |
| :------------------- | :------- | :--------------------------------- | :-------------------------------------------------------------------------- |
| `admin`              | 管理員   | 系統超級使用者                     | 所有權限 (`*`)                                                              |
| `guide`              | 嚮導     | 可建立與管理行程的專業嚮導         | `trip.create`, `trip.edit`, `trip.delete`, `trip.transfer`, `member.manage` |
| `member`             | 隊員     | 一般參與者，僅能檢視或編輯自己資料 | `trip.view`                                                                 |

## 行程成員資格 (Trip Membership)

除了系統層級的角色外，針對單一行程 (Trip)，使用者必須被加入該行程的成員列表 (`members`) 才能擁有操作權限。

### 成員資料結構

在 `Trip` Model 中新增 `members` 欄位：

```dart
List<String> members; // 儲存 User ID 列表
```

- **建立者 (Creator)**：建立行程時自動加入 `members`。
- **加入成員**：擁有 `member.manage` 權限者可將其他 User ID 加入列表。

## 權限判斷矩陣

操作權限判斷邏輯如下：

`Can(Action, User, Trip)`

| 操作 (Action)      | 系統角色 (Role) | 是否為成員 (In Trip) | 結果 (Result) | 備註                            |
| :----------------- | :-------------- | :------------------- | :------------ | :------------------------------ |
| **View Trip**      | Admin           | N/A                  | ✅ Allow      | Admin 可見所有                  |
| **View Trip**      | Guide/Member    | ✅ Yes               | ✅ Allow      | 成員可見                        |
| **View Trip**      | Guide/Member    | ❌ No                | ❌ Deny       | 非成員不可見                    |
| **Edit Trip**      | Admin           | N/A                  | ✅ Allow      |                                 |
| **Edit Trip**      | Guide           | ✅ Yes               | ✅ Allow      | 嚮導且在隊內                    |
| **Edit Trip**      | Guide           | ❌ No                | ❌ Deny       | 嚮導但非隊內                    |
| **Edit Trip**      | Member          | ✅ Yes               | ❌ Deny       | 一般隊員 (Role: Member) 僅有檢視權限，不可編輯行程 (需 Guide 以上) |
| **Delete Trip**    | Guide           | ✅ Yes               | ✅ Allow      | 需確認是否為 Creator (Optional) |
| **Manage Members** | Guide           | ✅ Yes               | ✅ Allow      | 邀請/移除成員                   |

## 實作細節

### PermissionService 邏輯更新

```dart
bool canEditTripSync(UserProfile? user, Trip trip) {
  if (user == null) return false;
  if (user.roleCode == 'admin') return true;

  // 1. 檢查是否為行程成員 (基本門檻)
  if (!trip.members.contains(user.id)) return false;

  // 2. 檢查是否有編輯權限 (角色賦予)
  return user.permissions.contains('trip.edit');
}
```

### 資料庫遷移 (Migration)

- 現有 `Trip` 資料缺乏 `members` 欄位。
- **Migration Strategy**:
  - 在讀取舊資料時，若 `members` 為空或 null，預設將 `createdBy` (Creator ID) 加入 `members`。
  - `Trip` model 的 `members` 預設值為 `[]`，但在邏輯層應確保至少有一位成員 (Creator)。

## 未來擴充

- **權限群組 (Permission Groups)**: 針對單一行程設定 Admin/Editor/Viewer (目前暫不實作，維持全域 Role)。
- **公公開行程 (Public Trips)**: 開放非成員檢視 (目前預設均為 Private)。
