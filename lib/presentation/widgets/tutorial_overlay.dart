import 'dart:ui';
import 'package:flutter/material.dart';

/// 導覽目標模型
class TutorialTarget {
  final String identify;
  final GlobalKey keyTarget;
  final String content;
  final ContentAlign align;
  final Alignment alignSkip;
  final Future<void> Function()? onFocus;

  TutorialTarget({
    required this.identify,
    required this.keyTarget,
    required this.content,
    this.align = ContentAlign.bottom,
    this.alignSkip = Alignment.bottomRight,
    this.onFocus,
  });
}

enum ContentAlign { top, bottom, left, right }

/// 自定義平滑導覽遮罩
class TutorialOverlay extends StatefulWidget {
  final List<TutorialTarget> targets;
  final VoidCallback onFinish;
  final VoidCallback onSkip;

  const TutorialOverlay({super.key, required this.targets, required this.onFinish, required this.onSkip});

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
      widget.onFinish();
      return;
    }

    final target = widget.targets[_currentIndex];

    // 執行目標的聚焦前動作 (如切換分頁)
    if (target.onFocus != null) {
      await target.onFocus!();
      // 等待 UI 更新
      if (mounted) {
        // 增加延遲以確保分頁切換動畫完成
        await Future.delayed(const Duration(milliseconds: 300));
      }
    }

    if (!mounted) return;

    // Retry 機制：尋找渲染物件
    RenderBox? renderBox;
    for (int i = 0; i < 10; i++) {
      renderBox = target.keyTarget.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null && renderBox.hasSize) break;
      await Future.delayed(const Duration(milliseconds: 100));
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
    if (_currentIndex < widget.targets.length - 1) {
      _currentIndex++;
      _initTarget();
    } else {
      widget.onFinish();
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

    final currentTarget = widget.targets[_currentIndex];

    return Stack(
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
        // 簡單實作：根據 align 判斷顯示位置
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

        // 3. 跳過按鈕
        Positioned(
          top: 40,
          right: 20,
          child: SafeArea(
            child: TextButton(
              onPressed: widget.onSkip,
              child: const Text(
                "跳過教學",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
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

    // 1. 繪製半透明背景
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.black.withOpacity(0.6));

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
