import 'package:flutter/material.dart';

import 'data/beginner_peaks_data.dart';
import 'models/page_content.dart';
import 'widgets/category_page_view.dart';
import 'widgets/info_page_view.dart';

/// 新手百岳日出指南
///
/// 提供給登山新手的百岳推薦清單，包含路線難度、日出特色等資訊。
/// 使用 [PageView] 實現類無限捲動的分類切換效果。
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
  List<PageContent> get _allPages {
    final List<PageContent> pages = [
      InfoPageContent(), // The "General Info" page
      ...BeginnerPeaksData.categories, // The 5 data categories
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

                      if (pageData is InfoPageContent) {
                        return const InfoPageView();
                      } else if (pageData is CategoryData) {
                        return CategoryPageView(category: pageData);
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
}
