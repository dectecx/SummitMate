import 'package:flutter/material.dart';
import 'message_list_screen.dart';
import 'poll_list_screen.dart';

class CollaborationTab extends StatelessWidget {
  const CollaborationTab({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
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
    );
  }
}
