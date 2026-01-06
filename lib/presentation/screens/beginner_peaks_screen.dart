import 'package:flutter/material.dart';

class BeginnerPeaksScreen extends StatefulWidget {
  const BeginnerPeaksScreen({super.key});

  @override
  State<BeginnerPeaksScreen> createState() => _BeginnerPeaksScreenState();
}

class _BeginnerPeaksScreenState extends State<BeginnerPeaksScreen> {
  late PageController _pageController;
  int _currentPageIndex = 1000; // Start in the middle for infinite scroll illusion

  // Total distinct pages: 1 Intro/Info Page + 5 Category Pages = 6 Total
  // Index 0: Intro/Excluded/Suggestions
  // Index 1-5: Categories
  List<_PageContent> get _allPages {
    final List<_PageContent> pages = [
      _InfoPageContent(), // The "General Info" page
      ..._categories, // The 5 data categories
    ];
    return pages;
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.9, initialPage: _currentPageIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '新手百岳日出指南',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Dynamic Background based on current category
          AnimatedBuilder(
            animation: _pageController,
            builder: (context, child) {
              int activeIndex = 0;
              if (_pageController.hasClients && _pageController.position.haveDimensions) {
                // Safe access using null check
                activeIndex = (_pageController.page ?? 0).round() % _allPages.length;
              } else {
                activeIndex = _currentPageIndex % _allPages.length;
              }
              final activePage = _allPages[activeIndex];

              return Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [activePage.bgColor.withValues(alpha: 0.8), Colors.blueGrey.shade900],
                  ),
                ),
              );
            },
          ),

          SafeArea(
            child: Column(
              children: [
                // Custom Tab Indicator
                Container(
                  height: 50,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _allPages.length,
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, _) {
                          int currentPageLoopIndex = 0;
                          if (_pageController.hasClients && _pageController.position.haveDimensions) {
                            currentPageLoopIndex = (_pageController.page ?? 0).round() % _allPages.length;
                          } else {
                            currentPageLoopIndex = _currentPageIndex % _allPages.length;
                          }
                          final isSelected = currentPageLoopIndex == index;
                          return GestureDetector(
                            onTap: () {
                              if (!_pageController.hasClients || !_pageController.position.haveDimensions) return;

                              // Calculate nearest instance of this index
                              final current = _pageController.page!.round();
                              final currentMod = current % _allPages.length;
                              var diff = index - currentMod;
                              // Optimize direction
                              if (diff > 3) diff -= _allPages.length;
                              if (diff < -3) diff += _allPages.length;

                              _pageController.animateToPage(
                                current + diff,
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutQuart,
                              );
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.white : Colors.white24,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isSelected
                                    ? [const BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2))]
                                    : [],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _allPages[index].menuTitle,
                                style: TextStyle(
                                  color: isSelected ? _allPages[index].bgColor : Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPageIndex = index;
                      });
                    },
                    itemBuilder: (context, index) {
                      final dataIndex = index % _allPages.length;
                      final pageData = _allPages[dataIndex];

                      if (pageData is _InfoPageContent) {
                        return _buildInfoPage(context);
                      } else if (pageData is _CategoryData) {
                        return _buildCategoryPage(context, pageData);
                      }
                      return const SizedBox();
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPage(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, spreadRadius: 2)],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '指南簡介',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
            ),
            const SizedBox(height: 16),
            const Text(
              '這份清單專為「平常有運動習慣的新手」設計。我們精選了風景絕美、日出震撼的路線，並排除了部分雖熱門但不適合初次體驗日出的百岳。',
              style: TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
            ),
            const Divider(height: 48, thickness: 2),

            Text(
              '給新手的「第一座」建議',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
            ),
            const SizedBox(height: 16),
            _buildSuggestionItem('📷 輕鬆拍美照', '合歡北峰', Colors.amber),
            _buildSuggestionItem('🏠 體驗住山屋', '奇萊南華', Colors.orange),
            _buildSuggestionItem('💪 挑戰體能極限', '北大武山', Colors.redAccent),
            _buildSuggestionItem('⛺ 享受野營感', '屏風山', Colors.green),

            const Divider(height: 48, thickness: 2),

            Text(
              '未收錄的熱門百岳？',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal.shade800),
            ),
            const SizedBox(height: 8),
            const Text('以下路線雖熱門，但在此指南中未被列入首選：', style: TextStyle(fontSize: 14, color: Colors.grey)),
            const SizedBox(height: 16),
            _buildExcludedItem('合歡主/東峰', '視野略遜北峰，建議順路撿，不需專程看日出。'),
            _buildExcludedItem('合歡西峰', '路程太遠，俗稱「七上八下」，新手容易走到懷疑人生。'),
            _buildExcludedItem('品田山', 'V型斷崖對懼高症新手不友善，摸黑風險高。'),
            _buildExcludedItem('畢祿/羊頭', '多在樹林中行走，展望較少，單攻極累。'),

            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionItem(String label, String peak, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: color),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const Spacer(),
          Text(
            '➝ $peak',
            style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildExcludedItem(String name, String reason) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, height: 1.4),
                children: [
                  TextSpan(
                    text: '$name：',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: reason),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPage(BuildContext context, _CategoryData category) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: category.color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.terrain, color: category.color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    Text(category.subtitle, style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // List
          Expanded(
            child: ListView.separated(
              itemCount: category.peaks.length,
              separatorBuilder: (ctx, i) => const SizedBox(height: 16),
              itemBuilder: (ctx, i) => _buildPeakCard(category.peaks[i], category.color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeakCard(_PeakData peak, Color themeColor) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      color: Colors.grey.shade50,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          child: Text(peak.name.substring(0, 1), style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        title: Text(peak.displayName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildMiniTag(Icons.schedule, peak.days),
              const SizedBox(width: 8),
              _buildMiniTag(Icons.place, peak.location),
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
            child: Column(
              children: [
                const Divider(),
                // Ratings Section
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    children: [
                      Expanded(child: _buildRatingColumn('推薦指數', peak.recommendation, Colors.amber, Icons.star)),
                      Container(width: 1, height: 30, color: Colors.grey.shade300),
                      Expanded(
                        child: _buildRatingColumn('體力難度', peak.difficulty, Colors.redAccent.shade200, Icons.hiking),
                      ),
                    ],
                  ),
                ),

                // Tags
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: double.infinity,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildPillTag('H${peak.height}m', Colors.blueGrey),
                      _buildPillTag('往返${peak.distance}', Colors.green),
                      _buildPillTag('爬升${peak.climb}', Colors.orange),
                    ],
                  ),
                ),

                // Details Table
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    children: [
                      _buildDetailRow('入園申請', peak.permit),
                      const SizedBox(height: 8),
                      _buildDetailRow('住宿資訊', peak.accommodation),
                      const SizedBox(height: 8),
                      _buildDetailRow('體能需求', peak.limit),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                // Sunrise Feature
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.wb_sunny, size: 20, color: Colors.amber),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          peak.feature,
                          style: const TextStyle(fontSize: 14, height: 1.4, color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniTag(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 2),
        Text(text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRatingColumn(String label, int value, Color color, IconData icon) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            5,
            (index) => Icon(
              index < value ? icon : (icon == Icons.star ? Icons.star_border : Icons.drag_handle),
              color: index < value ? color : Colors.grey.shade300,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPillTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13, color: Colors.black87)),
        ),
      ],
    );
  }

  // Define categories here
  List<_CategoryData> get _categories => [
    _CategoryData(
      title: '一、快樂大景型',
      subtitle: 'CP值最高，付出少回報高',
      color: Colors.orange,
      peaks: [
        _PeakData(
          name: '合歡北峰',
          height: 3422,
          feature: '視野極其開闊，看著太陽從花蓮方向的雲海升起，金光灑在著名的「反射板」上，背景是險峻的黑色奇萊。',
          limit: '低',
          permit: '免申請',
          recommendation: 5,
          difficulty: 1,
          manage: '太魯閣國家公園',
          accommodation: '免背帳 (可住清境或滑雪山莊)',
          distance: '約 4 km',
          climb: '約 447 m',
          days: '1天 (單攻)',
          location: '南投縣仁愛鄉',
        ),
        _PeakData(
          name: '奇萊南華',
          height: 3358,
          feature: '「黃金大草原」是它的招牌。日出時，整片短箭竹草原會被染成金黃色，柔美夢幻，完全沒有斷崖的恐懼感。',
          limit: '中低 (路程較長但平緩)',
          permit: '需申請入園/入山 (超級熱門)',
          recommendation: 5,
          difficulty: 2,
          manage: '太魯閣國家公園',
          accommodation: '天池山莊 (需抽籤)',
          distance: '約 26-28 km',
          climb: '約 1000 m',
          days: '2天1夜',
          location: '南投縣仁愛鄉',
        ),
        _PeakData(
          name: '郡大山',
          height: 3265,
          feature: '站在山頂，巨大的玉山群峰就在眼前一字排開，日出時可以看到玉山的剪影或被陽光照亮的壯麗山體。',
          limit: '低 (坐車比爬山累)',
          permit: '需申請入山',
          recommendation: 4,
          difficulty: 2,
          manage: '玉山國家公園',
          accommodation: '免 (單攻) 或 望鄉部落',
          distance: '約 7.4 km',
          climb: '約 400 m',
          days: '1天 (單攻)',
          location: '南投縣信義鄉',
        ),
        _PeakData(
          name: '鹿林山、麟趾山',
          height: 2854,
          feature: '雖然不是百岳，但這裡是公認「看玉山日出最美的地方」。在此看著太陽從台灣最高峰旁升起。',
          limit: '極低',
          permit: '免申請',
          recommendation: 5,
          difficulty: 1,
          manage: '玉山國家公園',
          accommodation: '東埔山莊 / 阿里山',
          distance: '約 6-8 km (O型)',
          climb: '約 300-400 m',
          days: '1天',
          isBaiyue: false,
          location: '南投縣信義鄉',
        ),
      ],
    ),
    _CategoryData(
      title: '二、國家級地標',
      subtitle: '沒去過就不算爬過山',
      color: Colors.blue,
      peaks: [
        _PeakData(
          name: '玉山主峰',
          height: 3952,
          feature: '「台灣之巔」。看著層層疊疊的山巒在腳下甦醒，那種感動是無可取代的。',
          limit: '中 (高海拔適應)',
          permit: '需抽籤 (極難中)',
          recommendation: 5,
          difficulty: 3,
          manage: '玉山國家公園',
          accommodation: '排雲山莊 (需抽籤)',
          distance: '約 21.8 km',
          climb: '約 1350 m',
          days: '2天1夜',
          location: '南投縣信義鄉',
        ),
        _PeakData(
          name: '雪山主東峰',
          height: 3886,
          feature: '「黃金圈谷」。全台最美的冰斗地形，日出時陽光會先照亮圈谷頂端，慢慢向下延伸。',
          limit: '中 (冬季難度大增)',
          permit: '需申請入園/入山',
          recommendation: 5,
          difficulty: 3,
          manage: '雪霸國家公園',
          accommodation: '三六九山莊',
          distance: '約 21.8 km',
          climb: '約 1700 m',
          days: '2天1夜',
          location: '台中市和平區',
        ),
        _PeakData(
          name: '嘉明湖',
          height: 3602,
          feature: '大多數人會選擇在向陽山看日出，視野極佳；若在湖畔，則能看到陽光喚醒藍寶石般的湖水。',
          limit: '中高 (路途遙遠)',
          permit: '需抽籤',
          recommendation: 5,
          difficulty: 4,
          manage: '林務局',
          accommodation: '向陽山屋 / 嘉明湖山屋',
          distance: '約 26 km',
          climb: '約 1500 m',
          days: '3-4天',
          location: '台東縣海端鄉',
        ),
      ],
    ),
    _CategoryData(
      title: '三、展望無敵型',
      subtitle: '睡醒就是日出，或視野極其遼闊',
      color: Colors.indigo,
      peaks: [
        _PeakData(
          name: '武陵四秀-桃山',
          height: 3325,
          feature: '擁有 360 度大景，正對著大霸尖山。因為山屋就在山頂，可以睡到日出前 15 分鐘再起床。',
          limit: '中高 (陡上)',
          permit: '需申請入園/入山',
          recommendation: 4,
          difficulty: 3,
          manage: '雪霸國家公園',
          accommodation: '桃山山屋',
          distance: '約 9 km',
          climb: '約 1400 m',
          days: '2天1夜',
          location: '台中市和平區',
        ),
        _PeakData(
          name: '武陵四秀-池有山',
          height: 3303,
          feature: '著名的「池有名樹」剪影配上日出，非常有禪意。石瀑地形也是一大看點。',
          limit: '中',
          permit: '需申請入園/入山',
          recommendation: 4,
          difficulty: 3,
          manage: '雪霸國家公園',
          accommodation: '新達山屋',
          distance: '約 10 km',
          climb: '約 1300 m',
          days: '2天1夜',
          location: '台中市和平區',
        ),
        _PeakData(
          name: '北大武山',
          height: 3092,
          feature: '「雲海的故鄉」。這裡是南台灣看雲海日出的首選，太陽從翻騰的雲海中跳出，氣勢萬千。',
          limit: '中高 (濕滑陡峭)',
          permit: '需申請檜谷山莊 (抽籤)',
          recommendation: 5,
          difficulty: 4,
          manage: '林務局',
          accommodation: '檜谷山莊',
          distance: '約 18 km',
          climb: '約 1500 m',
          days: '2-3天',
          location: '屏東縣泰武鄉',
        ),
      ],
    ),
    _CategoryData(
      title: '四、野營與長征型',
      subtitle: '享受山林露營與長途跋涉',
      color: Colors.green,
      peaks: [
        _PeakData(
          name: '屏風山',
          height: 3250,
          feature: '在山頂可以近距離欣賞奇萊北壁的雄偉崩壁，被朝陽染紅時非常震撼。',
          limit: '高 (新路雖好走但仍遠)',
          permit: '需申請入園/入山',
          recommendation: 4,
          difficulty: 4,
          manage: '太魯閣國家公園',
          accommodation: '松針營地 (需自背)',
          distance: '約 18-20 km',
          climb: '約 2000 m',
          days: '2-3天',
          location: '花蓮縣秀林鄉',
        ),
        _PeakData(
          name: '閂山',
          height: 3168,
          feature: '擁有柔美的高山草原，看著中央尖山與南湖大山在日出中顯得格外神聖。',
          limit: '中',
          permit: '需申請入園/入山',
          recommendation: 3,
          difficulty: 3,
          manage: '太魯閣國家公園',
          accommodation: '25K 工寮 (破舊)',
          distance: '約 20 km (需接駁)',
          climb: '約 800 m',
          days: '2天1夜',
          location: '台中市和平區',
        ),
        _PeakData(
          name: '大霸尖山',
          height: 3492,
          feature: '「黃金大霸」。在中霸坪看著金光照亮酒桶狀的大霸尖山，是每位登山客必收的照片。',
          limit: '中高 (踢林道考驗耐心)',
          permit: '需申請入園/入山',
          recommendation: 5,
          difficulty: 3,
          manage: '雪霸國家公園',
          accommodation: '九九山莊',
          distance: '約 62 km',
          climb: '約 1800 m',
          days: '3天2夜',
          location: '新竹縣尖石鄉',
        ),
      ],
    ),
    _CategoryData(
      title: '五、體能試煉型',
      subtitle: '單攻聖地 - 測試極限',
      color: Colors.red,
      peaks: [
        _PeakData(
          name: '志佳陽大山',
          height: 3289,
          feature: '這裡是欣賞雪山南壁與雪山主峰背面最壯觀的角度，日出時雪山會呈現迷人的粉紅色。',
          limit: '極高 (超級陡)',
          permit: '需申請入園/入山',
          recommendation: 3,
          difficulty: 5,
          manage: '雪霸國家公園',
          accommodation: '希瑪農莊 / 瓢簞山屋',
          distance: '約 16.6 km',
          climb: '約 1700 m',
          days: '1-2天',
          location: '台中市和平區',
        ),
        _PeakData(
          name: '西巒大山',
          height: 3081,
          feature: '雖然沿途都在樹林裡很無聊，但山頂有瞭望台，視野 360 度無死角，正對玉山山脈，日出極美。',
          limit: '高 (膝軟大山)',
          permit: '需申請入山',
          recommendation: 3,
          difficulty: 4,
          manage: '林務局',
          accommodation: '登山口露營',
          distance: '約 20 km',
          climb: '約 1500 m',
          days: '1天 (單攻)',
          location: '南投縣信義鄉',
        ),
      ],
    ),
  ];
}

abstract class _PageContent {
  String get menuTitle;
  Color get bgColor;
}

class _InfoPageContent extends _PageContent {
  @override
  String get menuTitle => '指南簡介';
  @override
  Color get bgColor => Colors.teal;
}

class _CategoryData extends _PageContent {
  final String title;
  final String subtitle;
  final Color color;
  final List<_PeakData> peaks;

  _CategoryData({required this.title, required this.subtitle, required this.color, required this.peaks});

  @override
  String get menuTitle => title.split('、')[1].substring(0, 2); // Extract 快樂, 國家...
  @override
  Color get bgColor => color;
}

class _PeakData {
  final String name;
  final int height;
  final String feature;
  final bool isBaiyue;

  // New fields
  final String location;
  final String days;
  final String distance;
  final String climb;
  final int recommendation;
  final int difficulty;
  final String permit;
  final String manage;
  final String accommodation;
  final String limit;

  String get displayName => isBaiyue ? name : '$name (非百岳)';

  _PeakData({
    required this.name,
    required this.height,
    required this.feature,
    required this.location,
    required this.days,
    required this.distance,
    required this.climb,
    required this.recommendation,
    required this.difficulty,
    required this.permit,
    required this.manage,
    required this.accommodation,
    required this.limit,
    this.isBaiyue = true,
  });
}
