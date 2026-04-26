import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/group_event.dart';
import '../cubits/group_event/group_event_state.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import '../cubits/group_event/group_event_cubit.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import '../cubits/favorites/group_event/group_event_favorites_cubit.dart';
import '../cubits/favorites/group_event/group_event_favorites_state.dart';
import 'group_event_review_screen.dart';

import '../widgets/group_event/detail/description_section.dart';
import '../widgets/group_event/detail/trip_section.dart';
import '../widgets/group_event/detail/comments_section.dart';
import '../widgets/group_event/detail/info_grid.dart';
import '../widgets/group_event/detail/organizer_section.dart';
import '../widgets/group_event/detail/private_message_section.dart';
import '../widgets/group_event/detail/status_widgets.dart';

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

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除揪團'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('確定要刪除「${_event.title}」嗎？'),
            if (_event.linkedTripId != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '注意：刪除揪團後，所有成員將失去對關聯行程的存取權限。',
                        style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            const Text('此操作無法復原。', style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await context.read<GroupEventCubit>().deleteEvent(eventId: _event.id);
              if (success && context.mounted) {
                ToastService.success('已刪除揪團活動');
                Navigator.pop(context);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('刪除'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
      backgroundColor: colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // 1. Expanded Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: colorScheme.primary,
            leading: _buildGlassIconButton(icon: Icons.arrow_back_ios_new, onTap: () => Navigator.pop(context)),
            actions: [
              if (isCreator) ...[
                _buildGlassIconButton(
                  icon: Icons.delete_outline,
                  onTap: () => _confirmDelete(context),
                ),
                const SizedBox(width: 8),
              ],
              Padding(
                padding: const EdgeInsets.only(right: 16),
                child: BlocBuilder<GroupEventFavoritesCubit, GroupEventFavoritesState>(
                  builder: (context, state) {
                    final isFavorite = context.read<GroupEventFavoritesCubit>().isFavorite(_event.id);
                    return _buildGlassIconButton(
                      icon: isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? Colors.red : Colors.white,
                      onTap: () {
                        context.read<GroupEventFavoritesCubit>().toggleFavorite(_event.id);
                        ScaffoldMessenger.of(context).clearSnackBars();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isFavorite ? '已從感興趣移除' : '已加入感興趣'),
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colorScheme.primary, colorScheme.secondary],
                  ),
                ),
                child: Center(child: Icon(Icons.terrain, size: 80, color: Colors.white.withValues(alpha: 0.2))),
              ),
            ),
          ),

          // 2. Content Body
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final isDesktop = constraints.maxWidth > 800;

                          if (isDesktop) {
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Main Content (Left)
                                Expanded(
                                  flex: 2,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _buildTitleSection(),
                                      const SizedBox(height: 24),
                                      InfoGrid(
                                        startDate: _event.startDate,
                                        location: _event.location,
                                        maxMembers: _event.maxMembers,
                                      ),
                                      const SizedBox(height: 32),
                                      DescriptionSection(description: _event.description),
                                      const SizedBox(height: 32),
                                      TripSection(
                                        event: _event,
                                        isCreator: isCreator,
                                        isSyncing: isSyncing,
                                      ),
                                      const SizedBox(height: 32),
                                      CommentsSection(event: _event),
                                      const SizedBox(height: 100),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 40),
                                // Sidebar Content (Right)
                                Expanded(
                                  flex: 1,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      OrganizerSection(
                                        creatorName: _event.creatorName,
                                        creatorAvatar: _event.creatorAvatar,
                                        isCreator: isCreator,
                                      ),
                                      const SizedBox(height: 24),
                                      if (_event.myApplicationStatus != null) ...[
                                        StatusCard(status: _event.myApplicationStatus!),
                                        const SizedBox(height: 24),
                                      ],
                                      PrivateMessageSection(
                                        privateMessage: _event.privateMessage,
                                        myApplicationStatus: _event.myApplicationStatus,
                                        isCreator: isCreator,
                                      ),
                                      const SizedBox(height: 32),
                                      _buildDesktopActionButton(context, colorScheme, isCreator, isSyncing),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          }

                          // Mobile View
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildTitleSection(),
                              const SizedBox(height: 24),
                              InfoGrid(
                                startDate: _event.startDate,
                                location: _event.location,
                                maxMembers: _event.maxMembers,
                              ),
                              const SizedBox(height: 24),
                              OrganizerSection(
                                creatorName: _event.creatorName,
                                creatorAvatar: _event.creatorAvatar,
                                isCreator: isCreator,
                              ),
                              const SizedBox(height: 24),
                              if (_event.myApplicationStatus != null) ...[
                                StatusCard(status: _event.myApplicationStatus!),
                                const SizedBox(height: 24),
                              ],
                              PrivateMessageSection(
                                privateMessage: _event.privateMessage,
                                myApplicationStatus: _event.myApplicationStatus,
                                isCreator: isCreator,
                              ),
                              const SizedBox(height: 24),
                              DescriptionSection(description: _event.description),
                              const SizedBox(height: 24),
                              TripSection(
                                event: _event,
                                isCreator: isCreator,
                                isSyncing: isSyncing,
                              ),
                              const SizedBox(height: 24),
                              CommentsSection(event: _event),
                              const SizedBox(height: 100),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          if (MediaQuery.of(context).size.width > 800) return const SizedBox.shrink();

          return Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
            ),
            child: SafeArea(child: _buildActionContent(context, colorScheme, isCreator, isSyncing)),
          );
        },
      ),
    );
  }

  Widget _buildTitleSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _ExpandableTitle(title: _event.title)),
        const SizedBox(width: 12),
        StatusChip(status: _event.status),
      ],
    );
  }

  Widget _buildDesktopActionButton(BuildContext context, ColorScheme colorScheme, bool isCreator, bool isSyncing) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [_buildActionContent(context, colorScheme, isCreator, isSyncing)],
    );
  }

  Widget _buildActionContent(BuildContext context, ColorScheme colorScheme, bool isCreator, bool isSyncing) {
    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, settingsState) {
        final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;
        final cubitState = context.watch<GroupEventCubit>().state;

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
            icon: const Icon(Icons.rate_review_rounded),
            label: const Text('審核報名'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          );
        }

        if (_event.myApplicationStatus != null) {
          return FilledButton(
            onPressed: null,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.outline.withValues(alpha: 0.3),
              foregroundColor: colorScheme.onSurface.withValues(alpha: 0.38),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('已報名'),
          );
        }

        return FilledButton(
          onPressed: isOffline || !_event.canApply || isSyncing ? null : _handleApply,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: isSyncing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(_event.isFull ? '已額滿' : (_event.approvalRequired ? '申請加入' : '立即加入')),
        );
      },
    );
  }

  // Helper Widgets
  Widget _buildGlassIconButton({required IconData icon, required VoidCallback onTap, Color color = Colors.white}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onTap,
        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
        padding: EdgeInsets.zero,
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
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, height: 1.2),
        ),
        secondChild: Text(
          widget.title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, height: 1.2),
        ),
        crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        duration: const Duration(milliseconds: 200),
      ),
    );
  }
}
