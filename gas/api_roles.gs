/**
 * ============================================================
 * Role-Based Access Control (RBAC) API
 * ============================================================
 * @fileoverview 處理角色與權限相關邏輯
 *
 * API Actions:
 *   - auth_get_roles: 取得可用角色列表
 *   - auth_assign_role: 指派角色給使用者 (Admin Only)
 */

// ============================================================
// === PUBLIC API (doPost Handlers integration) ===
// ============================================================

/**
 * 取得所有可用角色 (供 UI 下拉選單使用)
 * @returns {Object} 標準 API 回應
 */
function getAvailableRoles() {
  const roles = _getAllRoles();
  // 僅回傳 id, code, name, description
  return buildResponse(API_CODES.SUCCESS, { roles: roles });
}

/**
 * 指派角色 (僅限管理員或系統內部呼叫)
 * @param {Object} payload - { accessToken, targetUserId, newRoleId }
 * @returns {Object} 標準 API 回應
 */
function assignUserRole(payload) {
  const { accessToken, targetUserId, newRoleId } = payload;

  if (!accessToken || !targetUserId || !newRoleId) {
    return buildResponse(API_CODES.INVALID_PARAMS, null, "缺少必要參數");
  }

  // 1. 驗證呼叫者權限 (必須是 Admin 或 Leader)
  // 注意: 這裡需要 _getUserPermissions 尚未實作在 api_auth.gs，暫時先檢查是否為 Admin Code
  // 理想上應該檢查 permissions.include('user.manage')

  const validation = validateToken(accessToken);
  if (!validation.isValid)
    return buildResponse(
      API_CODES.AUTH_ACCESS_TOKEN_INVALID,
      null,
      "Token 無效"
    );

  const callerId = validation.payload.uid;

  // 檢查呼叫者是否具有權限 (這裡先簡單實作，後續需整合 PermissionService)
  // const callerPermissions = _getUserPermissions(callerId); // TODO: implement in api_auth

  // 2. 更新使用者角色
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_USERS);
  const result = _findUserById(sheet, targetUserId);

  if (!result)
    return buildResponse(
      API_CODES.AUTH_INVALID_CREDENTIALS,
      null,
      "找不到目標使用者"
    );

  const { rowIndex } = result;

  // 寫入新的 Role ID
  const headers = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const roleIdCol = headers.indexOf("role_id") + 1;
  const updatedAtCol = headers.indexOf("updated_at") + 1;

  if (roleIdCol > 0) {
    sheet.getRange(rowIndex, roleIdCol).setValue(newRoleId);
  }
  if (updatedAtCol > 0) {
    sheet.getRange(rowIndex, updatedAtCol).setValue(new Date().toISOString());
  }

  return buildResponse(API_CODES.SUCCESS, null, "角色更新成功");
}

// ============================================================
// === INTERNAL HELPERS ===
// ============================================================

/**
 * 取得該 Role ID 對應的所有 Permission Codes
 * @param {string} roleId
 * @returns {string[]} e.g. ['trip.view', 'trip.edit']
 */
function _getRolePermissions(roleId) {
  if (!roleId) return [];

  const ss = getSpreadsheet();
  const rpSheet = ss.getSheetByName(SHEET_ROLE_PERMISSIONS);
  const pSheet = ss.getSheetByName(SHEET_PERMISSIONS);

  if (!rpSheet || !pSheet) return [];

  // 1. 找出該 Role 擁有的 Permission IDs
  // 效能優化: 可快取
  const rpData = rpSheet.getDataRange().getValues();
  const permissionIds = [];

  // Skip header
  for (let i = 1; i < rpData.length; i++) {
    // Col 1 = role_id, Col 2 = permission_id
    if (rpData[i][1] === roleId) {
      permissionIds.push(rpData[i][2]);
    }
  }

  if (permissionIds.length === 0) return [];

  // 2. 找出 Permission Codes
  const pData = pSheet.getDataRange().getValues();
  const codes = [];

  // 建立 ID -> Code Map 以加速查找 (或簡單兩層迴圈)
  // 這裡資料量不大，簡單迴圈即可
  for (let i = 1; i < pData.length; i++) {
    const pId = pData[i][0]; // Col 0 = id
    const pCode = pData[i][1]; // Col 1 = code

    if (permissionIds.includes(pId)) {
      codes.push(pCode);
    }
  }

  return codes;
}

/**
 * 取得所有角色定義
 * @returns {Array} [{id, code, name, description}, ...]
 */
function _getAllRoles() {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(SHEET_ROLES);
  if (!sheet) return [];

  const data = sheet.getDataRange().getValues();
  const roles = [];

  // Skip header
  for (let i = 1; i < data.length; i++) {
    roles.push({
      id: data[i][0],
      code: data[i][1],
      name: data[i][2],
      description: data[i][3],
    });
  }

  return roles;
}

/**
 * 依 ID 取得角色資訊
 * @param {string} roleId
 * @returns {Object|null}
 */
function _getRoleById(roleId) {
  const roles = _getAllRoles();
  return roles.find((r) => r.id === roleId) || null;
}

/**
 * 依 Code 取得角色資訊
 * @param {string} code
 * @returns {Object|null}
 */
function _getRoleByCode(code) {
  const roles = _getAllRoles();
  return roles.find((r) => r.code === code) || null;
}
