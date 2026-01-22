import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../data/models/group_event.dart';
import '../cubits/group_event/group_event_state.dart';
import '../../data/models/enums/group_event_status.dart';
import '../../data/models/enums/group_event_application_status.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import '../cubits/group_event/group_event_cubit.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import '../widgets/group_event/group_event_comment_sheet.dart';
import 'group_event_review_screen.dart';

/// 莫蘭迪綠色系 (Green Morandi Color Palette)
class _MorandiColors {
  // Primary (Forest Green)
  static const Color forestGreen = Color(0xFF4A6C56);
  // Secondary (Sage Green)
  static const Color sageGreen = Color(0xFF8FA89B);
  // Accent (Earth/Brown)
  static const Color earthBrown = Color(0xFFBCAAA4);
  // Background (Pale Mist)
  static const Color paleMist = Color(0xFFF7F9F7);
  // Text (Dark Charcoal)
  static const Color charcoal = Color(0xFF2C3E34);
}

class GroupEventDetailScreen extends StatefulWidget {
  final GroupEvent event;

  const GroupEventDetailScreen({super.key, required this.event});

  @override
  State<GroupEventDetailScreen> createState() => _GroupEventDetailScreenState();
}

class _GroupEventDetailScreenState extends State<GroupEventDetailScreen> {
  late GroupEvent _event;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
  }

  Future<void> _handleApply() async {
    final cubit = context.read<GroupEventCubit>();
    final success = await cubit.applyEvent(eventId: _event.id);
    if (success && mounted) {
      ToastService.success('報名成功！');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cubitState = context.watch<GroupEventCubit>().state;
    final isSyncing = cubitState is GroupEventLoaded && cubitState.isSyncing;

    if (cubitState is GroupEventLoaded) {
      final loadedEvent = cubitState.events.where((e) => e.id == widget.event.id).firstOrNull;
      if (loadedEvent != null) {
        _event = loadedEvent;
      }
    }

    final isCreator = _event.isCreator(cubitState is GroupEventLoaded ? cubitState.currentUserId : '');

    return Scaffold(
      backgroundColor: _MorandiColors.paleMist,
      body: CustomScrollView(
        slivers: [
          // 1. Expanded Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: _MorandiColors.forestGreen,
            leading: _buildGlassIconButton(icon: Icons.arrow_back_ios_new, onTap: () => Navigator.pop(context)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: _buildGlassIconButton(
                  icon: _event.isLiked ? Icons.favorite : Icons.favorite_border,
                  color: _event.isLiked ? const Color(0xFFFF6B6B) : Colors.white,
                  onTap: () {
                    context.read<GroupEventCubit>().likeEvent(eventId: _event.id);
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_MorandiColors.forestGreen, _MorandiColors.sageGreen],
                  ),
                ),
                child: Center(child: Icon(Icons.terrain, size: 80, color: Colors.white.withOpacity(0.2))),
              ),
            ),
          ),

          // 2. Content Body
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: const BoxDecoration(
                  color: _MorandiColors.paleMist,
                  borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title & Status
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _ExpandableTitle(title: _event.title)),
                          const SizedBox(width: 12),
                          _buildStatusChip(_event.status),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Info Grid
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: _MorandiColors.forestGreen.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildInfoItem(
                                  Icons.calendar_today_rounded,
                                  DateFormat('MM/dd').format(_event.startDate),
                                  '日期',
                                ),
                                _buildVerticalDivider(),
                                _buildInfoItem(
                                  Icons.location_on_rounded,
                                  _event.location.isNotEmpty ? _event.location : '未指定',
                                  '地點',
                                ),
                                _buildVerticalDivider(),
                                _buildInfoItem(Icons.people_rounded, '${_event.maxMembers}', '預計人數'),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              '※ 預計人數僅供參考，實際可報名人數無上限',
                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Organizer Section
                      Text('主辦人', style: _sectionTitleStyle),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _MorandiColors.sageGreen.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Text(_event.creatorAvatar, style: const TextStyle(fontSize: 24)),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _event.creatorName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _MorandiColors.charcoal,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('發起人', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                                ],
                              ),
                            ),
                            if (isCreator)
                              const Chip(
                                label: Text('我', style: TextStyle(color: Colors.white, fontSize: 12)),
                                backgroundColor: _MorandiColors.forestGreen,
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Application Status (if applied)
                      if (_event.myApplicationStatus != null) ...[
                        _buildStatusCard(_event.myApplicationStatus!),
                        const SizedBox(height: 24),
                      ],

                      // Success Message
                      if ((_event.myApplicationStatus != null || isCreator) && _event.privateMessage.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _MorandiColors.sageGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _MorandiColors.sageGreen.withOpacity(0.3)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.check_circle_outline, color: _MorandiColors.forestGreen),
                                  SizedBox(width: 8),
                                  Text(
                                    '報名成功訊息',
                                    style: TextStyle(fontWeight: FontWeight.bold, color: _MorandiColors.forestGreen),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              (isCreator || _event.myApplicationStatus == GroupEventApplicationStatus.approved)
                                  ? Text(_event.privateMessage, style: TextStyle(color: Colors.grey[800]))
                                  : ClipRect(
                                      child: ImageFiltered(
                                        imageFilter: ui.ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                        child: Text(_event.privateMessage, style: TextStyle(color: Colors.grey[800])),
                                      ),
                                    ),
                              if (!isCreator && _event.myApplicationStatus != GroupEventApplicationStatus.approved)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    '※ 此訊息將於審核通過後顯示',
                                    style: TextStyle(fontSize: 12, color: _MorandiColors.forestGreen.withOpacity(0.8)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Description
                      Text('活動詳情', style: _sectionTitleStyle),
                      const SizedBox(height: 12),
                      Text(
                        _event.description.isNotEmpty ? _event.description : '無詳細說明',
                        style: TextStyle(fontSize: 15, color: _MorandiColors.charcoal, height: 1.6),
                      ),
                      const SizedBox(height: 24),

                      // Comments Preview
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('留言板 (${_event.commentCount})', style: _sectionTitleStyle),
                          TextButton(
                            onPressed: () => GroupEventCommentSheet.show(context, _event.id),
                            child: const Text('查看全部', style: TextStyle(color: _MorandiColors.forestGreen)),
                          ),
                        ],
                      ),

                      // Comment List or CTA
                      if (_event.latestComments.isNotEmpty)
                        Column(
                          children: _event.latestComments
                              .map(
                                (comment) => Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 16,
                                        backgroundColor: _MorandiColors.sageGreen.withOpacity(0.2),
                                        child: Text(comment.userAvatar, style: const TextStyle(fontSize: 14)),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Text(
                                                  comment.userName,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                ),
                                                Text(
                                                  DateFormat('MM/dd HH:mm').format(comment.createdAt),
                                                  style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              comment.content,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                              .toList(),
                        ),

                      InkWell(
                        onTap: () => GroupEventCommentSheet.show(context, _event.id),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _MorandiColors.forestGreen.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              _event.latestComments.isEmpty ? '尚無留言，成為第一個留言者！' : '查看更多留言...',
                              style: const TextStyle(color: _MorandiColors.forestGreen, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
        ),
        child: SafeArea(
          child: BlocBuilder<SettingsCubit, SettingsState>(
            builder: (context, settingsState) {
              final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;

              if (isCreator) {
                return FilledButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => GroupEventReviewScreen(
                          eventId: _event.id,
                          currentUserId: cubitState is GroupEventLoaded ? cubitState.currentUserId : '',
                        ),
                      ),
                    );
                    if (context.mounted) {
                      context.read<GroupEventCubit>().fetchEvents(isAuto: false);
                    }
                  },
                  style: _primaryButtonStyle,
                  icon: const Icon(Icons.rate_review_rounded),
                  label: const Text('審核報名'),
                );
              }

              if (_event.myApplicationStatus != null) {
                return FilledButton(onPressed: null, style: _disabledButtonStyle, child: const Text('已報名'));
              }

              return FilledButton(
                onPressed: isOffline || !_event.canApply || isSyncing ? null : _handleApply,
                style: _primaryButtonStyle,
                child: isSyncing
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_event.isFull ? '已額滿' : (_event.approvalRequired ? '申請加入' : '立即加入')),
              );
            },
          ),
        ),
      ),
    );
  }

  // Styles
  TextStyle get _sectionTitleStyle =>
      const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _MorandiColors.charcoal);

  ButtonStyle get _primaryButtonStyle => FilledButton.styleFrom(
    backgroundColor: _MorandiColors.forestGreen,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    elevation: 0,
  );

  ButtonStyle get _disabledButtonStyle => FilledButton.styleFrom(
    backgroundColor: Colors.grey[300],
    foregroundColor: Colors.grey[600],
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    elevation: 0,
  );

  // Helper Widgets
  Widget _buildVerticalDivider() {
    return Container(height: 30, width: 1, color: Colors.grey[200]);
  }

  Widget _buildGlassIconButton({required IconData icon, required VoidCallback onTap, Color color = Colors.white}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: _MorandiColors.forestGreen, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, color: _MorandiColors.charcoal, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
      ],
    );
  }

  Widget _buildStatusChip(GroupEventStatus status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case GroupEventStatus.open:
        bg = _MorandiColors.forestGreen;
        text = Colors.white;
        label = '招募中';
        break;
      case GroupEventStatus.closed:
        bg = Colors.grey;
        text = Colors.white;
        label = '已截止';
        break;
      case GroupEventStatus.cancelled:
        bg = _MorandiColors.earthBrown;
        text = Colors.white;
        label = '已取消';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: TextStyle(color: text, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatusCard(GroupEventApplicationStatus status) {
    Color color;
    IconData icon;
    String text;

    switch (status) {
      case GroupEventApplicationStatus.pending:
        color = Colors.orange;
        icon = Icons.hourglass_empty;
        text = '審核中';
        break;
      case GroupEventApplicationStatus.approved:
        color = _MorandiColors.forestGreen;
        icon = Icons.check_circle;
        text = '已通過';
        break;
      case GroupEventApplicationStatus.rejected:
        color = _MorandiColors.earthBrown;
        icon = Icons.cancel;
        text = '未通過';
        break;
      default:
        color = Colors.grey;
        icon = Icons.info;
        text = '未知';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(color: color, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _ExpandableTitle extends StatefulWidget {
  final String title;

  const _ExpandableTitle({required this.title});

  @override
  State<_ExpandableTitle> createState() => _ExpandableTitleState();
}

class _ExpandableTitleState extends State<_ExpandableTitle> {
  bool isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      child: AnimatedCrossFade(
        firstChild: Text(
          widget.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _MorandiColors.charcoal,
            height: 1.2,
          ),
        ),
        secondChild: Text(
          widget.title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: _MorandiColors.charcoal,
            height: 1.2,
          ),
        ),
        crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    );
  }
}
