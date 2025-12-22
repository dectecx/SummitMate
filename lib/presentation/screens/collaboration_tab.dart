import 'package:flutter/material.dart';
import 'message_list_screen.dart';
import 'poll_list_screen.dart';

class CollaborationTab extends StatelessWidget {
  final GlobalKey? keyBtnSync;
  final GlobalKey? keyTabPolls;

  const CollaborationTab({super.key, this.keyBtnSync, this.keyTabPolls});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              tabs: [
                const Tab(text: '留言板', icon: Icon(Icons.forum_outlined)),
                Tab(key: keyTabPolls, text: '投票活動', icon: const Icon(Icons.how_to_vote_outlined)),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                MessageListScreen(keyBtnSync: keyBtnSync),
                const PollListScreen(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
