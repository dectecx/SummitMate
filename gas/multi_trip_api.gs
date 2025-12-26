// ============================================================
// SummitMate - 多行程 API 擴充
// Multi-Trip API Extensions
// ============================================================
//
// 將以下函式加入 Code.gs 或建立新檔案
// 這些函式擴充現有 API 以支援 trip_id 篩選
//
// ============================================================

/**
 * 取得所有資料 (支援 trip_id 篩選)
 * @param {string} tripId - 可選，篩選特定行程
 */
function fetchAllWithTripId(tripId) {
  const ss = getSpreadsheet();

  return {
    itinerary: getItineraryDataFiltered(ss, tripId),
    messages: getMessagesDataFiltered(ss, tripId),
  };
}

/**
 * 取得行程資料 (支援 trip_id 篩選)
 */
function getItineraryDataFiltered(ss, tripId) {
  const sheet = ss.getSheetByName("Itinerary");
  if (!sheet) return [];

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  const headers = data[0];
  const tripIdIndex = headers.indexOf("trip_id");
  const rows = data.slice(1);

  return rows
    .map((row) => {
      const item = {};
      headers.forEach((header, index) => {
        const key = headerToKey(header);
        item[key] = row[index];
      });
      return item;
    })
    .filter((item) => {
      // 過濾空行
      if (!item.day || !item.name) return false;
      // 若有指定 tripId，則只回傳該行程的資料
      if (tripId && tripIdIndex !== -1) {
        return item.trip_id === tripId;
      }
      return true;
    });
}

/**
 * 取得留言資料 (支援 trip_id 篩選)
 */
function getMessagesDataFiltered(ss, tripId) {
  const sheet = ss.getSheetByName("Messages");
  if (!sheet) return [];

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  const headers = data[0];
  const tripIdIndex = headers.indexOf("trip_id");
  const rows = data.slice(1);

  return rows
    .map((row) => {
      const msg = {};
      headers.forEach((header, index) => {
        const key = headerToKey(header);
        let value = row[index];

        if (key === "timestamp" && value instanceof Date) {
          value = value.toISOString();
        }
        if (key === "parent_id") {
          value = value || null;
        }
        if (key === "avatar" && (value === null || value === "")) {
          value = "🐻";
        }

        msg[key] = value;
      });

      if (!msg.avatar) {
        msg.avatar = "🐻";
      }

      return msg;
    })
    .filter((msg) => {
      if (!msg.uuid) return false;
      // 若有指定 tripId，則只回傳該行程或全域 (trip_id 為空) 的留言
      if (tripId && tripIdIndex !== -1) {
        return !msg.trip_id || msg.trip_id === tripId;
      }
      return true;
    });
}

// ============================================================
// 修改 doGet 以支援 trip_id 參數
// 將此替換原有的 doGet case
// ============================================================

/*
在 doGet 函式中，修改 case "fetch_all":

case "fetch_all":
  const tripId = e.parameter.trip_id;
  if (tripId) {
    return createJsonResponse(fetchAllWithTripId(tripId));
  }
  return createJsonResponse(fetchAll());

case "fetch_itinerary":
  const itTripId = e.parameter.trip_id;
  return createJsonResponse({
    itinerary: getItineraryDataFiltered(getSpreadsheet(), itTripId),
  });

case "fetch_messages":
  const msgTripId = e.parameter.trip_id;
  return createJsonResponse({
    messages: getMessagesDataFiltered(getSpreadsheet(), msgTripId),
  });
*/

// ============================================================
// 行程 (Trip) CRUD API
// ============================================================

const TRIPS_SHEET_NAME = "Trips";
const TRIPS_HEADERS = [
  "id",
  "name",
  "start_date",
  "end_date",
  "description",
  "cover_image",
  "is_active",
  "created_at",
];

/**
 * 取得所有行程
 */
function fetchTrips() {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(TRIPS_SHEET_NAME);

  if (!sheet) {
    return { success: true, trips: [] };
  }

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) {
    return { success: true, trips: [] };
  }

  const headers = data[0];
  const trips = data.slice(1).map((row) => {
    const trip = {};
    headers.forEach((header, index) => {
      let value = row[index];
      // 處理日期
      if (
        (header === "start_date" ||
          header === "end_date" ||
          header === "created_at") &&
        value instanceof Date
      ) {
        value = value.toISOString();
      }
      trip[header] = value;
    });
    return trip;
  });

  return { success: true, trips: trips };
}

/**
 * 新增行程
 */
function addTrip(tripData) {
  const ss = getSpreadsheet();
  let sheet = ss.getSheetByName(TRIPS_SHEET_NAME);

  if (!sheet) {
    sheet = ss.insertSheet(TRIPS_SHEET_NAME);
    sheet.appendRow(TRIPS_HEADERS);
  }

  const id = tripData.id || Utilities.getUuid();
  const now = new Date().toISOString();

  sheet.appendRow([
    id,
    tripData.name || "新行程",
    tripData.start_date || now,
    tripData.end_date || "",
    tripData.description || "",
    tripData.cover_image || "",
    tripData.is_active || false,
    now,
  ]);

  return { success: true, id: id };
}

/**
 * 更新行程
 */
function updateTrip(tripData) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(TRIPS_SHEET_NAME);

  if (!sheet) {
    return { success: false, error: "找不到 Trips 工作表" };
  }

  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const idIndex = headers.indexOf("id");

  for (let i = 1; i < data.length; i++) {
    if (data[i][idIndex] === tripData.id) {
      // 更新該列
      headers.forEach((header, colIndex) => {
        if (
          tripData[header] !== undefined &&
          header !== "id" &&
          header !== "created_at"
        ) {
          sheet.getRange(i + 1, colIndex + 1).setValue(tripData[header]);
        }
      });
      return { success: true };
    }
  }

  return { success: false, error: "找不到該行程" };
}

/**
 * 刪除行程
 */
function deleteTrip(tripId) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(TRIPS_SHEET_NAME);

  if (!sheet) {
    return { success: false, error: "找不到 Trips 工作表" };
  }

  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const idIndex = headers.indexOf("id");

  for (let i = 1; i < data.length; i++) {
    if (data[i][idIndex] === tripId) {
      sheet.deleteRow(i + 1);
      return { success: true };
    }
  }

  return { success: false, error: "找不到該行程" };
}

/**
 * 設定活動行程
 */
function setActiveTrip(tripId) {
  const ss = getSpreadsheet();
  const sheet = ss.getSheetByName(TRIPS_SHEET_NAME);

  if (!sheet) {
    return { success: false, error: "找不到 Trips 工作表" };
  }

  const data = sheet.getDataRange().getValues();
  const headers = data[0];
  const idIndex = headers.indexOf("id");
  const activeIndex = headers.indexOf("is_active");

  // 先將所有行程設為非活動
  for (let i = 1; i < data.length; i++) {
    sheet.getRange(i + 1, activeIndex + 1).setValue(false);
  }

  // 設定指定行程為活動
  for (let i = 1; i < data.length; i++) {
    if (data[i][idIndex] === tripId) {
      sheet.getRange(i + 1, activeIndex + 1).setValue(true);
      return { success: true };
    }
  }

  return { success: false, error: "找不到該行程" };
}

// ============================================================
// doPost 擴充 - 加入以下 case 到 doPost switch
// ============================================================

/*
case "fetch_trips":
  return createJsonResponse(fetchTrips());
  
case "add_trip":
  return createJsonResponse(addTrip(data));
  
case "update_trip":
  return createJsonResponse(updateTrip(data));
  
case "delete_trip":
  return createJsonResponse(deleteTrip(data.id));
  
case "set_active_trip":
  return createJsonResponse(setActiveTrip(data.id));
*/
