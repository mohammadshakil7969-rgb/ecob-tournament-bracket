import 'package:flutter/material.dart';

void main() {
  runApp(const TournamentApp());
}

class TournamentApp extends StatelessWidget {
  const TournamentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ECOB Tournament Bracket',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF174B35),
        ),
      ),
      home: const BracketHome(),
    );
  }
}

class BracketHome extends StatefulWidget {
  const BracketHome({super.key});

  @override
  State<BracketHome> createState() => _BracketHomeState();
}

class _BracketHomeState extends State<BracketHome> {
  final List<String> teams = List.generate(32, (i) => 'Team ${i + 1}');

  // Store the index of each match winner.
  final Map<String, int> winners = {};

  final List<String> rounds = [
    'ROUND OF 32',
    'ROUND OF 16',
    'QUARTER-FINAL',
    'SEMI-FINAL',
  ];

  String matchKey(String side, int round, int match) =>
      '${side}_${round}_$match';

  int? teamAt(String side, int round, int match, int slot) {
    if (round == 0) {
      final position = match * 2 + slot;
      return side == 'L' ? position : 31 - position;
    }

    return winners[matchKey(side, round - 1, match * 2 + slot)];
  }

  void selectWinner(
    String side,
    int round,
    int match,
    int? team,
  ) {
    if (team == null) return;

    setState(() {
      winners[matchKey(side, round, match)] = team;

      // Clear only the dependent matches in later rounds.
      for (int r = round + 1; r < 4; r++) {
        winners.remove(
          matchKey(side, r, match ~/ (1 << (r - round))),
        );
      }

      winners.remove('FINAL');
    });
  }

  Future<void> editTeams() async {
    final controllers = teams
        .map((name) => TextEditingController(text: name))
        .toList();

    final result = await showDialog<List<String>>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit 32 Team Names'),
        content: SizedBox(
          width: 400,
          height: 420,
          child: ListView.builder(
            itemCount: 32,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: TextField(
                controller: controllers[i],
                decoration: InputDecoration(
                  labelText: 'Team ${i + 1}',
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(
                dialogContext,
                List.generate(
                  32,
                  (i) => controllers[i].text.trim().isEmpty
                      ? 'Team ${i + 1}'
                      : controllers[i].text.trim(),
                ),
              );
            },
            child: const Text('Save Names'),
          ),
        ],
      ),
    );

    for (final controller in controllers) {
      controller.dispose();
    }

    if (result != null) {
      setState(() {
        for (int i = 0; i < 32; i++) {
          teams[i] = result[i];
        }
      });
    }
  }

  void resetTournament() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Reset Tournament?'),
        content: const Text(
          'All team names and match results will be reset.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() {
                for (int i = 0; i < 32; i++) {
                  teams[i] = 'Team ${i + 1}';
                }
                winners.clear();
              });
              Navigator.pop(dialogContext);
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  Widget teamRow({
    required int? teamIndex,
    required int? winnerIndex,
    required VoidCallback? onTap,
  }) {
    final isWinner =
        teamIndex != null && teamIndex == winnerIndex;

    return InkWell(
      onTap: onTap,
      child: Container(
        height: 31,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        color: isWinner ? const Color(0xFFDDF4E4) : Colors.white,
        child: Row(
          children: [
            Icon(
              isWinner ? Icons.check_circle : Icons.circle_outlined,
              size: 13,
              color: isWinner
                  ? const Color(0xFF168344)
                  : Colors.grey,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                teamIndex == null ? 'TBD' : teams[teamIndex],
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight:
                      isWinner ? FontWeight.bold : FontWeight.w500,
                  color: teamIndex == null
                      ? Colors.grey
                      : const Color(0xFF202820),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildMatch(String side, int round, int match) {
    final first = teamAt(side, round, match, 0);
    final second = teamAt(side, round, match, 1);
    final winner = winners[matchKey(side, round, match)];

    return Container(
      width: 166,
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFB9CBBE)),
        borderRadius: BorderRadius.circular(5),
        boxShadow: const [
          BoxShadow(color: Color(0x10000000), blurRadius: 2),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          teamRow(
            teamIndex: first,
            winnerIndex: winner,
            onTap: first == null
                ? null
                : () => selectWinner(side, round, match, first),
          ),
          const Divider(height: 1, thickness: 1),
          teamRow(
            teamIndex: second,
            winnerIndex: winner,
            onTap: second == null
                ? null
                : () => selectWinner(side, round, match, second),
          ),
        ],
      ),
    );
  }

  Widget buildRound(String side, int round) {
    final count = 8 >> round;

    return SizedBox(
      width: 180,
      child: Column(
        children: [
          SizedBox(
            height: 54,
            child: Center(
              child: Text(
                rounds[round],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF174B35),
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                count,
                (i) => buildMatch(side, round, i),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildFinal() {
    final left = winners[matchKey('L', 3, 0)];
    final right = winners[matchKey('R', 3, 0)];
    final champion = winners['FINAL'];

    return SizedBox(
      width: 190,
      child: Column(
        children: [
          const SizedBox(height: 54),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 15),
            child: Text(
              'THE FINAL',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Color(0xFF174B35),
              ),
            ),
          ),
          const Spacer(),
          Container(
            width: 170,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFD0AB47)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                teamRow(
                  teamIndex: left,
                  winnerIndex: champion,
                  onTap: left == null
                      ? null
                      : () => setState(() => winners['FINAL'] = left),
                ),
                const Divider(height: 1),
                teamRow(
                  teamIndex: right,
                  winnerIndex: champion,
                  onTap: right == null
                      ? null
                      : () => setState(() => winners['FINAL'] = right),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Icon(
            Icons.emoji_events,
            color: Color(0xFFC49A27),
            size: 45,
          ),
          const Text(
            'CHAMPION',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Color(0xFF174B35),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 170,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF174B35),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              champion == null ? 'TBD' : teams[champion],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF174B35),
        foregroundColor: Colors.white,
        title: const Text(
          'ECOB TOURNAMENT',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Edit team names',
            onPressed: editTeams,
            icon: const Icon(Icons.edit_note),
          ),
          IconButton(
            tooltip: 'Reset',
            onPressed: resetTournament,
            icon: const Icon(Icons.restart_alt),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: const Color(0xFFE0EBE3),
            child: const Column(
              children: [
                Text(
                  '32 TEAM KNOCKOUT',
                  style: TextStyle(
                    color: Color(0xFF174B35),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap any team in a match to select the winner',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(
                width: 8 * 180.0 + 190,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ...List.generate(
                      4,
                      (i) => buildRound('L', i),
                    ),
                    buildFinal(),
                    ...List.generate(
                      4,
                      (i) => buildRound('R', 3 - i),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            color: const Color(0xFF174B35),
            padding: const EdgeInsets.all(10),
            child: const Text(
              '32 TEAMS  •  31 MATCHES  •  1 CHAMPION',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
