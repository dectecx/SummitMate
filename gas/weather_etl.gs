/**
 * Weather ETL Script (氣象資料擷取與轉換腳本)
 * 功能:
 * 1. 抓取 CWA 氣象資料 (JSON ID: F-B0053-033)。
 * 2. 解析並攤平儲存至 Raw Data 工作表 (備份用)。
 * 3. 轉換並聚合資料至 App View 工作表 (供 API 讀取)。
 * 4. 實作快取機制以減少 API 呼叫次數。
 */

// ==========================================
// 核心設定
// ==========================================
// API Key 建議設定在 Script Properties，但也允許在此備用
// 設定位置：專案設定 (Project Settings) > 指令碼屬性 (Script Properties)
const CWA_DATA_ID = "F-B0053-033"; // 登山氣象資料 (JSON) - [中文註解: 氣象局登山預報資料 ID]
const CACHE_DURATION_HOURS = 6; // 快取有效時間 (小時)

/**
 * 主要進入點：執行同步
 * 用途：設定為「時間驅動」觸發器 (例如每 1 小時或 6 小時)
 * 邏輯：檢查上次更新時間 -> 若過期則 Fetch -> 否則只重產 View
 */
function syncWeatherToSheets(forceUpdate = false) {
  const props = PropertiesService.getScriptProperties();
  const lastUpdate = props.getProperty("LAST_CWA_FETCH");
  const now = new Date().getTime();
  
  // 檢查是否需要抓取新資料
  let shouldFetch = true;
  if (!forceUpdate && lastUpdate) {
    const lastTime = new Date(lastUpdate).getTime();
    const hoursDiff = (now - lastTime) / (1000 * 60 * 60);
    if (hoursDiff < CACHE_DURATION_HOURS) {
      Logger.log(`資料尚新 (上次更新: ${hoursDiff.toFixed(2)} 小時前)，跳過 CWA Fetch，使用 Raw Data 產出 View。`);
      shouldFetch = false;
    }
  }

  // 1. 準備 Raw Data (原始資料)
  let rawData = [];
  if (shouldFetch) {
    rawData = fetchFromCWA(); // 抓取新資料
    if (rawData && rawData.length > 0) {
      saveRawData(rawData); // 寫入 Raw Sheet
    }
  } else {
    rawData = readRawData(); // 從 Raw Sheet 讀取
  }

  // 若沒有 Raw Data (可能是第一次跑或讀取失敗)，強制重抓
  if (!rawData || rawData.length === 0) {
    Logger.log("無可用的 Raw Data，強制從 CWA 抓取...");
    rawData = fetchFromCWA();
    if (rawData && rawData.length > 0) {
      saveRawData(rawData);
    }
  }

  if (!rawData || rawData.length === 0) {
    Logger.log("錯誤：無法取得任何氣象資料，中止程序。");
    return;
  }

  // 2. 轉換並產出 App View (應用程式視圖)
  generateAppView(rawData);
}

/**
 * 步驟 A: 從 CWA API 抓取並解析 (Extract)
 * 回傳：攤平後的二維陣列 (Raw Data 結構)
 */
function fetchFromCWA() {
  const props = PropertiesService.getScriptProperties();
  const CWA_API_KEY = props.getProperty("CWA_API_KEY");

  if (!CWA_API_KEY) {
    Logger.log("錯誤：未設定 CWA_API_KEY");
    return null;
  }

  const URL = `https://opendata.cwa.gov.tw/fileapi/v1/opendataapi/${CWA_DATA_ID}?Authorization=${CWA_API_KEY}&format=JSON&downloadType=WEB`;
  Logger.log(`Fetch URL: ${URL}`);

  try {
    const response = UrlFetchApp.fetch(URL, {muteHttpExceptions: true});
    let jsonString = response.getContentText();
    // 處理 BOM (Byte Order Mark)
    if (jsonString.charCodeAt(0) === 0xFEFF) {
      jsonString = jsonString.substr(1);
    }
    const json = JSON.parse(jsonString);

    if (!json.cwaopendata || !json.cwaopendata.Dataset || !json.cwaopendata.Dataset.Locations) {
      Logger.log("錯誤：JSON 結構不符。CWA Keys: " + Object.keys(json.cwaopendata));
      return null;
    }

    const locations = json.cwaopendata.Dataset.Locations.Location;
    Logger.log(`取得 ${locations.length} 個地點`);

    const issueTime = getIssueTime(json);
    PropertiesService.getScriptProperties().setProperty("LATEST_ISSUE_TIME", issueTime || "");
    Logger.log(`取得 ${locations.length} 個地點, 發布時間: ${issueTime}`);

    const rawData = [];

    locations.forEach(loc => {
      const locName = loc.LocationName;
      if (!loc.WeatherElement) return;

      loc.WeatherElement.forEach(el => {
        const elName = el.ElementName;
        if (!el.Time) return;

        el.Time.forEach(t => {
          const startTime = t.StartTime;
          const endTime = t.EndTime;
          
          // [修正]: ElementValue 是物件 (Map)，不是陣列
          // 且新增 FullRawData 欄位儲存完整 JSON
          let valObj = t.ElementValue;
          let extractedValue = "";
          let fullJson = "";

          if (valObj) {
            extractedValue = extractValue(elName, valObj);
            fullJson = JSON.stringify(valObj);
          }
          
          rawData.push([locName, startTime, endTime, elName, extractedValue, fullJson]);
        });
      });
    });

    Logger.log(`解析完成，共 ${rawData.length} 筆`);
    return rawData;

  } catch (e) {
    Logger.log("Fetch Error: " + e.toString());
    return null;
  }
}

/**
 * 輔助函式：從 ElementValue 物件中提取主要數值
 */
function extractValue(elementName, valObj) {
  // 防呆：如果是 Array 取第一個
  if (Array.isArray(valObj)) {
    if (valObj.length > 0) valObj = valObj[0];
    else return "";
  }

  // 特定對照表 (CWA Hiking API Keys)
  let key = "";
  switch (elementName) {
    case "平均溫度": key = "Temperature"; break;
    case "平均相對濕度": key = "RelativeHumidity"; break;
    case "12小時降雨機率": key = "ProbabilityOfPrecipitation"; break;
    case "風速": key = "WindSpeed"; break;
    case "天氣現象": key = "Weather"; break;
    case "最高溫度": key = "MaxTemperature"; break;
    case "最低溫度": key = "MinTemperature"; break;
    case "最高體感溫度": key = "MaxApparentTemperature"; break;
    case "最低體感溫度": key = "MinApparentTemperature"; break;
  }

  if (key && valObj[key] !== undefined) return valObj[key];
  
  // 後備方案 (Fallback)：若無對應 key，取第一個
  const keys = Object.keys(valObj);
  if (keys.length > 0) return valObj[keys[0]];
  
  return "";
}

/**
 * 步驟 C: 儲存 Raw Data (原始資料)
 */
function saveRawData(rows) {
  const header = ["Location", "StartTime", "EndTime", "Element", "Value", "FullElementValue"];
  updateSheet("Weather_CWA_Hiking_Raw", [header, ...rows]);
  PropertiesService.getScriptProperties().setProperty("LAST_CWA_FETCH", new Date().toISOString());
}

/**
 * 步驟 B: 讀取 Raw Data Sheet
 */
function readRawData() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName("Weather_CWA_Hiking_Raw");
  if (!sheet) return null;
  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];
  return data.slice(1);
}

/**
 * 步驟 D: 產出 App View (應用程式視圖)
 */
function generateAppView(rawDataRows) {
  const elementMap = {
    "平均溫度": "T",
    "平均相對濕度": "RH",
    "12小時降雨機率": "PoP",
    "風速": "WS",
    "天氣現象": "Wx",
    "最高溫度": "MaxT",
    "最低溫度": "MinT",
    "最高體感溫度": "MaxAT",
    "最低體感溫度": "MinAT"
  };

  const consolidatedData = {};

  rawDataRows.forEach(row => {
    // row: [Location, StartTime, EndTime, ElementName, Value, FullRawData]
    const [loc, start, end, elName, val] = row;
    if (elementMap[elName]) {
      const shortKey = elementMap[elName];
      const compositeKey = `${loc}|${start}|${end}`;

      if (!consolidatedData[compositeKey]) {
        consolidatedData[compositeKey] = {
          Location: loc, StartTime: start, EndTime: end,
          T: "", RH: "", PoP: "", WS: "", Wx: "", MaxT: "", MinT: "", MaxAT: "", MinAT: ""
        };
      }
      consolidatedData[compositeKey][shortKey] = val;
    }
  });
  
  // 取得發布時間
  const issueTime = PropertiesService.getScriptProperties().getProperty("LATEST_ISSUE_TIME") || "";

  Object.values(consolidatedData).forEach(item => {
    // 將 IssueTime 加入每一筆資料中
    item.IssueTime = issueTime;
  });

  const appHeader = ["Location", "StartTime", "EndTime", "Wx", "T", "PoP", "MinT", "MaxT", "RH", "WS", "MinAT", "MaxAT", "IssueTime"];
  const appRows = [];

  Object.values(consolidatedData).forEach(item => {
    appRows.push([
      item.Location, item.StartTime, item.EndTime,
      item.Wx, item.T, item.PoP, item.MinT, item.MaxT, item.RH, item.WS, item.MinAT, item.MaxAT, item.IssueTime
    ]);
  });

  updateSheet("Weather_Hiking_App", [appHeader, ...appRows]);
}

/**
 * 輔助：提取 IssueTime (發布時間)
 */
function getIssueTime(json) {
  try {
    return json.cwaopendata.Dataset.DatasetInfo.IssueTime;
  } catch (e) {
    return "";
  }
}

/**
 * 通用寫入工具 (Update Sheet)
 */
function updateSheet(sheetName, data) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(sheetName);
  
  if (!sheet) {
    sheet = ss.insertSheet(sheetName);
  }
  
  sheet.clearContents();
  
  if (data && data.length > 0) {
    // 檢查行列數防止錯誤
    const rows = data.length;
    const cols = data[0].length;
    sheet.getRange(1, 1, rows, cols).setValues(data);
  }
}

/**
 * [API 接口] 供 Code.gs 呼叫
 */
function getWeatherData() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName("Weather_Hiking_App");
  
  if (!sheet) return { error: "Weather data not ready (氣象資料尚未準備好)" };

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  const headers = data[0];
  const rows = data.slice(1);

  return rows.map(row => {
    const item = {};
    headers.forEach((h, i) => {
      item[h] = row[i];
    });
    return item;
  });
}

/**
 * (選用) 首次安裝初始化氣象工作表
 */
function setupWeatherSheets() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  if (!ss.getSheetByName("Weather_CWA_Hiking_Raw")) ss.insertSheet("Weather_CWA_Hiking_Raw");
  if (!ss.getSheetByName("Weather_Hiking_App")) ss.insertSheet("Weather_Hiking_App");
  Logger.log("氣象工作表初始化完成");
}
