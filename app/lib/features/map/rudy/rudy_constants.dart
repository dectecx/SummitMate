/// Constants for the Rudy Map (魯地圖) download client.
///
/// Rules from the author: download via [rudyHomeUrl] (the balancer, never a
/// hard-coded mirror), send `AppName/version (+contact URL)` as User-Agent on
/// every request, and never charge for downloads.
library;

const rudyHomeUrl = 'https://rudymap.tw';

/// The balancer route (302 to a mirror). Its list of files does not include
/// the PMTiles file yet, so it answers 404 for it.
const rudyBalancerBase = 'https://rudymap.tw/v1/';

/// Temporary: a mirror's own address, which is where the balancer redirects to.
/// Mirrors keep the files in their root directory.
const rudyDirectBase = 'https://moi.kcwu.csie.org/';

/// The one switch between the two routes. Set to true once the balancer lists
/// the PMTiles file; nothing else needs to change.
const rudyViaBalancer = false;

const rudyDownloadBase = rudyViaBalancer ? rudyBalancerBase : rudyDirectBase;

const rudyPmtilesFile = 'MOI_OSM_Taiwan_TOPO_Rudy.pmtiles';
const rudyStyleZipFile = 'MOI_OSM_Taiwan_TOPO_Rudy_pmtiles_style.zip';

/// Placeholder: glyphs are not published on the mirrors yet.
const rudyGlyphsZipFile = 'MOI_OSM_Taiwan_TOPO_Rudy_glyphs.zip';

/// The line on the map itself; the full credit is in [rudyAttribution].
const rudyShortCredit = '© OpenStreetMap contributors · 魯地圖';

/// Where OpenStreetMap explains its licence; its attribution guideline asks for a link to it.
const osmCopyrightUrl = 'https://www.openstreetmap.org/copyright';

const rudyAttribution =
    '地圖：魯地圖 Rudy Map（https://rudymap.tw）｜資料 © OpenStreetMap contributors (ODbL)'
    '｜等高線與 DEM：內政部 20 公尺 DTM｜樣式基於 OpenAndroMaps Elevate（Tobias Kühn）';

/// `SummitMate/<version> (+<contact>)`.
String rudyUserAgent({required String appVersion, required String contactUrl}) =>
    'SummitMate/$appVersion (+$contactUrl)';
