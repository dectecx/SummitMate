import 'package:flutter/material.dart';
import 'message_list_screen.dart';
import 'poll_list_screen.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/cloud_guard.dart';

/// 協作頁面 (Tab 3)
///
/// 包含 [MessageListScreen] (留言板) 與 [PollListScreen] (投票活動)。
/// 透過 [CloudGuard] 保護，確保行程已上傳雲端後才可使用。
class CollaborationTab extends StatelessWidget {
  const CollaborationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return CloudGuard(
      featureName: '留言板與投票',
      icon: Icons.groups_outlined,
      child: ResponsiveLayout(
        mobile: DefaultTabController(
          length: 2,
          child: Column(
            children: [
              Container(
                color: Theme.of(context).colorScheme.surface,
                child: const TabBar(
                  tabs: [
                    Tab(text: '留言板', icon: Icon(Icons.forum_outlined)),
                    Tab(text: '投票活動', icon: Icon(Icons.how_to_vote_outlined)),
                  ],
                ),
              ),
              const Expanded(child: TabBarView(children: [MessageListScreen(), PollListScreen()])),
            ],
          ),
        ),
        desktop: Row(
          children: [
            const Expanded(child: MessageListScreen()),
            const VerticalDivider(width: 1),
            const Expanded(child: PollListScreen()),
          ],
        ),
      ),
    );
  }
}
