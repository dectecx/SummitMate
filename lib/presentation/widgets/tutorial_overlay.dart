import 'package:flutter/material.dart';
import '../../infrastructure/tools/tutorial_service.dart';

/// 導覽目標模型
class TutorialTarget {
  final String identify;
  final TutorialTopic topic;
  final GlobalKey? keyTarget; // Ensure this is nullable
  final String content;
  final ContentAlign align;
  final Alignment alignSkip;
  final Future<void> Function()? onFocus;

  TutorialTarget({
    required this.identify,
    required this.topic,
    this.keyTarget,
    required this.content,
    this.align = ContentAlign.bottom,
    this.alignSkip = Alignment.bottomRight,
    this.onFocus,
  });
}

enum ContentAlign { top, bottom, left, right, center }

/// 自定義平滑導覽遮罩
class TutorialOverlay extends StatefulWidget {
  final List<TutorialTarget> targets;
  final VoidCallback onFinish;
  final VoidCallback onSkip;
  final bool showSkipTopic;
  final void Function(int nextIndex)? onSkipTopic;

  const TutorialOverlay({
    super.key,
    required this.targets,
    required this.onFinish,
    required this.onSkip,
    this.showSkipTopic = false,
    this.onSkipTopic,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  int _currentIndex = 0;
  Rect? _currentRect;
  Rect? _targetRect;

  bool _isInit = false;
  bool _isTransitioning = false; // 防止快速連續點擊

  double _opacity = 1.0; // Control opacity for fade-out

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // 平滑移動時間
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.addListener(() {
      setState(() {});
    });

    // 初始化第一個目標
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initTarget();
    });
  }

  Future<void> _initTarget() async {
    if (_currentIndex >= widget.targets.length) {
      // Fade out before finishing
      if (mounted) {
        setState(() => _opacity = 0.0);
        await Future.delayed(const Duration(milliseconds: 500));
      }
      widget.onFinish();
      return;
    }

    final target = widget.targets[_currentIndex];

    // 執行 onFocus callback (如展開高度圖等)
    if (target.onFocus != null) {
      try {
        await target.onFocus!();
        // callback 內部已包含必要延遲，僅額外等待100ms確保完成
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        debugPrint('Tutorial onFocus error: $e');
      }
    }

    if (!mounted) return;

    // 若無 keyTarget (例如最後的結束畫面)，設定為空 Rect (不挖孔)
    if (target.keyTarget == null) {
      final rect = Rect.zero; // Zero rect -> no hole

      if (!_isInit) {
        setState(() {
          _currentRect = rect;
          _targetRect = rect;
          _isInit = true;
        });
      } else {
        setState(() {
          _currentRect = _targetRect;
          _targetRect = rect;
        });
        _controller.forward(from: 0);
      }
      return;
    }

    // Retry 機制：尋找渲染物件
    RenderBox? renderBox;
    for (int i = 0; i < 20; i++) {
      renderBox = target.keyTarget!.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) break;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    // 如果有執行過 onFocus（如展開動作），再等待一下並重新查詢位置
    // 確保光圈跟隨展開後的內容
    if (target.onFocus != null && renderBox != null && renderBox.hasSize) {
      await Future.delayed(const Duration(milliseconds: 50));
      renderBox = target.keyTarget!.currentContext?.findRenderObject() as RenderBox?;
    }

    if (renderBox != null && renderBox.hasSize) {
      final size = renderBox.size;
      final offset = renderBox.localToGlobal(Offset.zero);

      // 增加一點 padding
      final rect = Rect.fromLTWH(offset.dx - 4, offset.dy - 4, size.width + 8, size.height + 8);

      // 如果是第一次，直接設定位置 (不動畫)
      if (!_isInit) {
        setState(() {
          _currentRect = rect;
          _targetRect = rect;
          _isInit = true;
        });
      } else {
        // 設定新目標，播放動畫
        setState(() {
          _currentRect = _targetRect; // 起點是上一次的終點
          _targetRect = rect;
        });
        _controller.forward(from: 0);
      }
    } else {
      // 找不到目標 (可能被遮擋或未渲染)，直接跳下一個或結束
      // 避免無限迴圈，稍微延遲後正確處理
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) _next();
    }
  }

  void _next() {
    // 防止快速連續點擊
    if (_isTransitioning) return;

    _isTransitioning = true;

    if (_currentIndex < widget.targets.length - 1) {
      _currentIndex++;
      _initTarget().then((_) {
        if (mounted) {
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted) _isTransitioning = false;
          });
        }
      });
    } else {
      // If user clicks "Next" on the last step, we restart initTarget which handles finish
      _currentIndex++;
      _initTarget().then((_) {
        if (mounted) _isTransitioning = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInit || _targetRect == null) return const SizedBox.shrink();

    // 計算當前動畫中的開孔位置
    // 使用 Rect.lerp 插值
    final currentHole = Rect.lerp(_currentRect, _targetRect, _animation.value) ?? _targetRect!;

    // Prevent RangeError when fading out (currentIndex > last index)
    final safeIndex = _currentIndex >= widget.targets.length ? widget.targets.length - 1 : _currentIndex;
    final currentTarget = widget.targets[safeIndex];

    return AnimatedOpacity(
      opacity: _opacity,
      duration: const Duration(milliseconds: 500),
      child: Stack(
        children: [
          // 1. 繪製遮罩與開孔
          GestureDetector(
            onTap: _next, // 點擊任意處下一步 (可依需求改為只點擊目標或按鈕)
            child: CustomPaint(
              size: MediaQuery.of(context).size,
              painter: _HolePainter(hole: currentHole),
            ),
          ),

          // 2. 繪製說明文字與按鈕
          // 根據 align 判斷顯示位置
          if (currentTarget.align == ContentAlign.center)
            Align(
              alignment: Alignment.center,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle_outline, color: Colors.white, size: 64),
                    const SizedBox(height: 24),
                    // 高亮文字方框
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF667eea), // 紫藍
                            Color(0xFF764ba2), // 深紫
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 30,
                            spreadRadius: 2,
                            offset: const Offset(0, 10),
                          ),
                          BoxShadow(
                            color: const Color(0xFF667eea).withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
                          ),
                        ],
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                      ),
                      child: Text(
                        currentTarget.content,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          height: 1.4,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text("點擊螢幕完成教學", style: TextStyle(color: Colors.white70, fontSize: 16)),
                  ],
                ),
              ),
            )
          else
            Positioned(
              top: currentTarget.align == ContentAlign.bottom ? currentHole.bottom + 20 : null,
              bottom: currentTarget.align == ContentAlign.top
                  ? MediaQuery.of(context).size.height - currentHole.top + 20
                  : null,
              left: 20,
              right: 20,
              child: Material(
                color: Colors.transparent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentTarget.content,
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),
                    const Text("點擊螢幕繼續", style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ],
                ),
              ),
            ),

          // 3. 跳過按鈕區域
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 跳過教學 (紅色警告色，優先顯示)
                    TextButton.icon(
                      onPressed: widget.onSkip,
                      icon: const Icon(Icons.close, color: Colors.redAccent),
                      label: const Text(
                        "跳過教學",
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.white.withValues(alpha: 0.9),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                    ),
                    // 跳過此主題 (灰色次要色，僅在完整教學模式顯示)
                    if (widget.showSkipTopic) ...[
                      const SizedBox(width: 12),
                      TextButton.icon(
                        onPressed: () {
                          final nextIndex = TutorialService.getNextTopicIndex(widget.targets, _currentIndex);
                          if (nextIndex != null && widget.onSkipTopic != null) {
                            widget.onSkipTopic!(nextIndex);
                          } else {
                            // 無下一主題，等同完成
                            widget.onFinish();
                          }
                        },
                        icon: const Icon(Icons.skip_next, color: Colors.grey),
                        label: const Text(
                          "跳過此主題",
                          style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.9),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HolePainter extends CustomPainter {
  final Rect hole;

  _HolePainter({required this.hole});

  @override
  void paint(Canvas canvas, Size size) {
    // 使用 SaveLayer + BlendMode.clear 來確保開孔正確 (替代 Path.combine)
    canvas.saveLayer(Rect.fromLTWH(0, 0, size.width, size.height), Paint());

    // 1. 繪製半透明背景 (完成畫面使用較淡的背景)
    final isCompletionScreen = hole.width == 0 && hole.height == 0; // 完成畫面沒有開孔
    final overlayOpacity = isCompletionScreen ? 0.5 : 0.8;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black.withValues(alpha: overlayOpacity),
    );

    // 2. 挖孔 (使用 BlendMode.clear)
    final radius = (hole.width > hole.height ? hole.width : hole.height) / 2;
    final center = hole.center;

    final holePaint = Paint()..blendMode = BlendMode.clear;

    canvas.drawCircle(center, radius, holePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HolePainter oldDelegate) {
    return oldDelegate.hole != hole;
  }
}
