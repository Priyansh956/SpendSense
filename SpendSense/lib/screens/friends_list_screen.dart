import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../providers/splitwise_provider.dart';
import '../services/splitwise_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'add_friend_screen.dart';
import 'balances_screen.dart';

class FriendsListScreen extends StatefulWidget {
  const FriendsListScreen({super.key});

  @override
  State<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends State<FriendsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            _buildTabBar(),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _FriendsTab(
                    searchQuery: _searchQuery,
                    searchController: _searchController,
                  ),
                  const _RequestsTab(),
                  const _ActivityTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddFriendScreen()),
        ),
        backgroundColor: AppColors.neonGreen,
        foregroundColor: AppColors.black,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text(
          'Add Friend',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Friends',
                style: TextStyle(
                  color: AppColors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Split expenses together',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          // Balances button
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BalancesScreen()),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.neonGreen.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.neonGreen.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: AppColors.neonGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    'Balances',
                    style: TextStyle(
                      color: AppColors.neonGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Consumer<SplitwiseProvider>(
      builder: (context, provider, _) {
        final pendingCount = provider.pendingRequestCount;

        return Container(
          margin: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          decoration: BoxDecoration(
            color: AppColors.lightGrey,
            borderRadius: BorderRadius.circular(16),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.neonGreen,
              borderRadius: BorderRadius.circular(12),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: AppColors.black,
            unselectedLabelColor: AppColors.textSecondary,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 15,
            ),
            tabs: [
              const Tab(text: 'Friends'),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Requests'),
                    if (pendingCount > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.error,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '$pendingCount',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Tab(text: 'Activity'),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────
// FRIENDS TAB
// ─────────────────────────────────────────────────

class _FriendsTab extends StatelessWidget {
  final String searchQuery;
  final TextEditingController searchController;

  const _FriendsTab({
    required this.searchQuery,
    required this.searchController,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<SplitwiseProvider>(
      builder: (context, provider, _) {
        final filtered = provider.friends
            .where((f) =>
        searchQuery.isEmpty ||
            f.email.toLowerCase().contains(searchQuery) ||
            f.displayName.toLowerCase().contains(searchQuery))
            .toList();

        return Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
              child: TextField(
                controller: searchController,
                style: const TextStyle(color: AppColors.white),
                decoration: InputDecoration(
                  hintText: 'Search friends...',
                  hintStyle: TextStyle(color: AppColors.textSecondary),
                  prefixIcon:
                  const Icon(Icons.search, color: AppColors.textSecondary),
                  filled: true,
                  fillColor: AppColors.lightGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),

            if (provider.friends.isEmpty)
              Expanded(child: _buildEmptyFriends(context))
            else if (filtered.isEmpty)
              Expanded(
                child: Center(
                  child: Text(
                    'No friends match "$searchQuery"',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _FriendCard(friend: filtered[index]),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildEmptyFriends(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.lightGrey,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.group_outlined,
              size: 48,
              color: AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'No friends yet',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add friends to start splitting expenses',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddFriendScreen()),
            ),
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.neonGreen,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Add your first friend',
                style: TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  final Friend friend;

  const _FriendCard({required this.friend});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _Avatar(name: friend.displayName),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.displayName,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  friend.email,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Remove friend
          GestureDetector(
            onTap: () => _confirmRemove(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.person_remove_outlined,
                color: AppColors.error,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.lightGrey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove Friend',
            style: TextStyle(color: AppColors.white)),
        content: Text(
          'Remove ${friend.displayName} from your friends?',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await context
            .read<SplitwiseProvider>()
            .removeFriend(friend.uid);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${friend.displayName} removed'),
              backgroundColor: AppColors.darkGrey,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }
  }
}

// ─────────────────────────────────────────────────
// REQUESTS TAB
// ─────────────────────────────────────────────────

class _RequestsTab extends StatelessWidget {
  const _RequestsTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<SplitwiseProvider>(
      builder: (context, provider, _) {
        final incoming = provider.incomingRequests;
        final sent = provider.sentRequests;

        if (incoming.isEmpty && sent.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.mail_outline,
                    size: 56, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                const Text(
                  'No pending requests',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Friend requests will appear here',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          children: [
            if (incoming.isNotEmpty) ...[
              _sectionLabel('Received'),
              const SizedBox(height: 12),
              ...incoming.map((r) => _IncomingRequestCard(request: r)),
              const SizedBox(height: 24),
            ],
            if (sent.isNotEmpty) ...[
              _sectionLabel('Sent'),
              const SizedBox(height: 12),
              ...sent.map((r) => _SentRequestCard(request: r)),
            ],
          ],
        );
      },
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _IncomingRequestCard extends StatelessWidget {
  final FriendRequest request;

  const _IncomingRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.neonGreen.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Avatar(name: request.fromEmail),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.fromEmail.split('@')[0],
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      request.fromEmail,
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () async {
                    try {
                      await context
                          .read<SplitwiseProvider>()
                          .rejectRequest(request.id);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('$e'),
                          backgroundColor: AppColors.error,
                        ));
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    side: BorderSide(color: AppColors.mediumGrey),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Decline'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    try {
                      await context
                          .read<SplitwiseProvider>()
                          .acceptRequest(request);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '${request.fromEmail.split('@')[0]} added as friend!'),
                            backgroundColor: AppColors.success,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text('$e'),
                          backgroundColor: AppColors.error,
                        ));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.neonGreen,
                    foregroundColor: AppColors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Accept',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SentRequestCard extends StatelessWidget {
  final FriendRequest request;

  const _SentRequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          _Avatar(name: request.toEmail, dim: true),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.toEmail.split('@')[0],
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  request.toEmail,
                  style:
                  TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Pending',
              style: TextStyle(
                color: AppColors.warning,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// SHARED WIDGETS
// ─────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String name;
  final bool dim;

  const _Avatar({required this.name, this.dim = false});

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 22,
      backgroundColor:
      dim ? AppColors.mediumGrey : AppColors.neonGreen.withOpacity(0.8),
      child: Text(
        initial,
        style: TextStyle(
          color: dim ? AppColors.textSecondary : AppColors.black,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// ACTIVITY TAB
// ─────────────────────────────────────────────────

class _ActivityTab extends StatelessWidget {
  const _ActivityTab();

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return const SizedBox();

    return Consumer<SplitwiseProvider>(
      builder: (context, provider, _) {
        final expenses = provider.splitExpenses;

        if (expenses.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.history,
                    size: 56, color: AppColors.textTertiary),
                const SizedBox(height: 16),
                const Text(
                  'No activity yet',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        // Flatten expenses into individual debt logs
        final List<_ActivityLog> logs = [];

        for (final expense in expenses) {
          final payerUid = expense.paidByUid;
          final payerName = payerUid == currentUser.uid 
              ? 'You' 
              : (expense.paidByName.isNotEmpty ? expense.paidByName.split(' ')[0] : 'Someone');

          for (final participant in expense.participants) {
            // Skip the payer's own share
            if (participant.uid == payerUid) continue;

            final participantName = participant.uid == currentUser.uid 
                ? 'You' 
                : (participant.displayName.isNotEmpty ? participant.displayName.split(' ')[0] : 'Someone');

            logs.add(_ActivityLog(
              expense: expense,
              payerUid: payerUid,
              payerName: payerName,
              participantUid: participant.uid,
              participantName: participantName,
              amount: participant.amount,
              isPaid: participant.isPaid,
              date: expense.date,
            ));
          }
        }

        // Sort by date, newest first
        logs.sort((a, b) => b.date.compareTo(a.date));

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
          itemCount: logs.length,
          itemBuilder: (context, index) {
            return _ActivityLogCard(
              log: logs[index],
              currentUid: currentUser.uid,
            );
          },
        );
      },
    );
  }
}

class _ActivityLog {
  final SplitExpense expense;
  final String payerUid;
  final String payerName;
  final String participantUid;
  final String participantName;
  final double amount;
  final bool isPaid;
  final DateTime date;

  _ActivityLog({
    required this.expense,
    required this.payerUid,
    required this.payerName,
    required this.participantUid,
    required this.participantName,
    required this.amount,
    required this.isPaid,
    required this.date,
  });
}

class _ActivityLogCard extends StatelessWidget {
  final _ActivityLog log;
  final String currentUid;

  const _ActivityLogCard({required this.log, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    // Determine colors based on user involvement
    final bool amIPayer = log.payerUid == currentUid;
    final bool amIParticipant = log.participantUid == currentUid;

    Color amountColor = AppColors.white; // Default neutral color
    if (amIPayer) amountColor = AppColors.success; // Receiving money
    if (amIParticipant) amountColor = AppColors.error; // Giving money

    // Construct the verb
    String actionWord = log.isPaid ? 'paid' : 'owe';
    if (!amIParticipant && log.isPaid) actionWord = 'paid';
    if (!amIParticipant && !log.isPaid) actionWord = 'owes';

    // Example: You owe 500 to Gemini
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.lightGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: amountColor.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: amountColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              log.isPaid ? Icons.check_circle_outline : Icons.receipt_long,
              color: amountColor,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                RichText(
                  text: TextSpan(
                    style: const TextStyle(fontSize: 15, height: 1.4),
                    children: [
                      TextSpan(
                        text: log.participantName,
                        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: ' $actionWord ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextSpan(
                        text: '₹${log.amount.toStringAsFixed(0)}',
                        style: TextStyle(color: amountColor, fontWeight: FontWeight.bold),
                      ),
                      TextSpan(
                        text: ' to ',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                      TextSpan(
                        text: log.payerName,
                        style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${log.expense.title} • ${log.date.day}/${log.date.month}/${log.date.year}',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}