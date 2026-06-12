import 'dart:async';
import 'dart:js' as js;
import 'dart:math';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  runApp(const BlackjackApp());
}

class BlackjackApp extends StatelessWidget {
  const BlackjackApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Triple Threat Blackjack',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Arial'),
      home: const AppEntry(),
    );
  }
}

// ── App Settings ──────────────────────────────────────────────
class TableTheme {
  final String name;
  final List<Color> tableGradient;
  final Color feltLineColor;
  final Color accentColor;
  final int requiredLevel;  // VIP unlock level
  final String vipTier;     // Bronze/Silver/Gold/Platinum/Diamond
  const TableTheme(this.name, this.tableGradient, this.feltLineColor,
      this.accentColor, this.requiredLevel, this.vipTier);
}

const List<TableTheme> kTableThemes = [
  TableTheme('Classic Green',
    [Color(0xFF1E7A30), Color(0xFF165A22), Color(0xFF0E3A16)],
    Color(0x60D4AF37), Color(0xFFD4AF37), 1, 'Bronze'),
  TableTheme('Red Velvet',
    [Color(0xFF7A1E1E), Color(0xFF5A1616), Color(0xFF3A0E0E)],
    Color(0x60D4AF37), Color(0xFFD4AF37), 4, 'Silver'),
  TableTheme('Midnight Blue',
    [Color(0xFF1A2A5E), Color(0xFF111E45), Color(0xFF0A1230)],
    Color(0x6064B5F6), Color(0xFF64B5F6), 7, 'Gold'),
  TableTheme('Purple Felt',
    [Color(0xFF4A1A7A), Color(0xFF35125A), Color(0xFF200A3A)],
    Color(0x60CE93D8), Color(0xFFCE93D8), 10, 'Platinum'),
  TableTheme('Black Tie',
    [Color(0xFF2A2A2A), Color(0xFF1A1A1A), Color(0xFF0A0A0A)],
    Color(0x60D4AF37), Color(0xFFD4AF37), 13, 'Diamond'),
  TableTheme('Royal Gold',
    [Color(0xFF3A2800), Color(0xFF2A1C00), Color(0xFF1A1000)],
    Color(0xFFD4AF37), Color(0xFFFFD700), 15, 'Diamond'),
];

// ── VIP Tier System ───────────────────────────────────────────
class VipTier {
  final String name, emoji;
  final int minLevel;
  final Color color;
  final int maxBet;
  final String perk;
  const VipTier(this.name, this.emoji, this.minLevel, this.color, this.maxBet, this.perk);
}

const List<VipTier> kVipTiers = [
  VipTier('Bronze',   '🥉', 1,  Color(0xFFCD7F32), 500,   'Access to Classic Green table'),
  VipTier('Silver',   '🥈', 4,  Color(0xFFBDBDBD), 1000,  'Unlocks Red Velvet table + higher bets'),
  VipTier('Gold',     '🥇', 7,  Color(0xFFFFD700), 2500,  'Unlocks Midnight Blue + Purple tables'),
  VipTier('Platinum', '💎', 10, Color(0xFF00E5FF), 5000,  'Unlocks Black Tie + double XP'),
  VipTier('Diamond',  '👑', 13, Color(0xFFFFFFFF), 10000, 'All tables + Royal Gold exclusive'),
];

VipTier getVipTier(int level) {
  VipTier current = kVipTiers.first;
  for (final t in kVipTiers) {
    if (level >= t.minLevel) current = t;
  }
  return current;
}

VipTier? getNextVipTier(int level) {
  for (final t in kVipTiers) {
    if (level < t.minLevel) return t;
  }
  return null;
}

bool isTableUnlocked(TableTheme theme, int level) => level >= theme.requiredLevel;

// ── Tournament System ─────────────────────────────────────────
enum TournamentType { quick, standard, marathon }

class TournamentConfig {
  final String name, subtitle;
  final int durationMinutes, startingChips, entryFee;
  final int prize1st, prize2nd, prize3rd, participationPrize;
  final TournamentType type;
  final String emoji;
  const TournamentConfig({
    required this.name, required this.subtitle, required this.type,
    required this.durationMinutes, required this.startingChips,
    required this.entryFee, required this.prize1st, required this.prize2nd,
    required this.prize3rd, required this.participationPrize, required this.emoji,
  });
}

const List<TournamentConfig> kTournaments = [
  TournamentConfig(
    name: 'QUICK FIRE', subtitle: '10 minute blitz',
    type: TournamentType.quick, emoji: '⚡',
    durationMinutes: 10, startingChips: 1000, entryFee: 0,
    prize1st: 3000, prize2nd: 1500, prize3rd: 750, participationPrize: 100,
  ),
  TournamentConfig(
    name: 'STANDARD', subtitle: '30 minute grind',
    type: TournamentType.standard, emoji: '🎯',
    durationMinutes: 30, startingChips: 2000, entryFee: 250,
    prize1st: 8000, prize2nd: 3500, prize3rd: 1500, participationPrize: 125,
  ),
  TournamentConfig(
    name: 'MARATHON', subtitle: '60 minute endurance',
    type: TournamentType.marathon, emoji: '🏆',
    durationMinutes: 60, startingChips: 5000, entryFee: 1000,
    prize1st: 25000, prize2nd: 10000, prize3rd: 4000, participationPrize: 500,
  ),
];

// ── Daily Challenge System ────────────────────────────────────
enum ChallengeDifficulty { easy, medium, hard }
enum ChallengeType {
  winRounds, winStreak, tripleWin, sideBet, winHands,
  winWithoutBust, doubleWin, playRounds, bigBet,
}

class ChallengeDefinition {
  final String id, title, description;
  final ChallengeDifficulty difficulty;
  final ChallengeType type;
  final int target, chipReward, xpReward;
  const ChallengeDefinition({
    required this.id, required this.title, required this.description,
    required this.difficulty, required this.type,
    required this.target, required this.chipReward, required this.xpReward,
  });
}

const List<ChallengeDefinition> kAllChallenges = [
  // Easy
  ChallengeDefinition(id:'win3', title:'Win 3 Rounds', description:'Win 3 rounds today',
    difficulty:ChallengeDifficulty.easy, type:ChallengeType.winRounds,
    target:3, chipReward:200, xpReward:25),
  ChallengeDefinition(id:'play5', title:'Play 5 Rounds', description:'Complete 5 rounds',
    difficulty:ChallengeDifficulty.easy, type:ChallengeType.playRounds,
    target:5, chipReward:150, xpReward:20),
  ChallengeDefinition(id:'streak2', title:'Win Streak x2', description:'Win 2 hands in a row',
    difficulty:ChallengeDifficulty.easy, type:ChallengeType.winStreak,
    target:2, chipReward:200, xpReward:25),
  ChallengeDefinition(id:'win5hands', title:'Win 5 Hands', description:'Win 5 individual hands',
    difficulty:ChallengeDifficulty.easy, type:ChallengeType.winHands,
    target:5, chipReward:175, xpReward:20),
  ChallengeDefinition(id:'doublewin', title:'Double Win', description:'Win 2 hands in one round',
    difficulty:ChallengeDifficulty.easy, type:ChallengeType.doubleWin,
    target:1, chipReward:225, xpReward:30),
  // Medium
  ChallengeDefinition(id:'win5', title:'Win 5 Rounds', description:'Win 5 rounds today',
    difficulty:ChallengeDifficulty.medium, type:ChallengeType.winRounds,
    target:5, chipReward:500, xpReward:75),
  ChallengeDefinition(id:'streak3', title:'Win Streak x3', description:'Win 3 hands in a row',
    difficulty:ChallengeDifficulty.medium, type:ChallengeType.winStreak,
    target:3, chipReward:500, xpReward:75),
  ChallengeDefinition(id:'sidebet', title:'Side Bet Hit', description:'Win a side bet',
    difficulty:ChallengeDifficulty.medium, type:ChallengeType.sideBet,
    target:1, chipReward:600, xpReward:80),
  ChallengeDefinition(id:'win10hands', title:'Win 10 Hands', description:'Win 10 individual hands',
    difficulty:ChallengeDifficulty.medium, type:ChallengeType.winHands,
    target:10, chipReward:450, xpReward:65),
  ChallengeDefinition(id:'bigbet', title:'High Roller', description:'Place a \$200+ bet',
    difficulty:ChallengeDifficulty.medium, type:ChallengeType.bigBet,
    target:200, chipReward:400, xpReward:60),
  // Hard
  ChallengeDefinition(id:'triple3', title:'Triple Threat x3', description:'Win all 3 hands 3 times',
    difficulty:ChallengeDifficulty.hard, type:ChallengeType.tripleWin,
    target:3, chipReward:1500, xpReward:200),
  ChallengeDefinition(id:'streak5', title:'Win Streak x5', description:'Win 5 hands in a row',
    difficulty:ChallengeDifficulty.hard, type:ChallengeType.winStreak,
    target:5, chipReward:1500, xpReward:200),
  ChallengeDefinition(id:'win10', title:'Win 10 Rounds', description:'Win 10 rounds today',
    difficulty:ChallengeDifficulty.hard, type:ChallengeType.winRounds,
    target:10, chipReward:1200, xpReward:175),
  ChallengeDefinition(id:'nobust5', title:'Clean Sweep', description:'Win 5 rounds without busting',
    difficulty:ChallengeDifficulty.hard, type:ChallengeType.winWithoutBust,
    target:5, chipReward:1800, xpReward:220),
  ChallengeDefinition(id:'sidebet3', title:'Side Bet Master', description:'Win 3 side bets',
    difficulty:ChallengeDifficulty.hard, type:ChallengeType.sideBet,
    target:3, chipReward:2000, xpReward:250),
];

class DailyChallenge {
  final ChallengeDefinition def;
  int progress;
  bool completed;
  bool rewardClaimed;
  DailyChallenge(this.def) : progress = 0, completed = false, rewardClaimed = false;
  double get progressPct => (progress / def.target).clamp(0.0, 1.0);
}

class ChallengeManager {
  static List<DailyChallenge> _todayChallenges = [];
  static String _loadedDate = '';
  static Map<String, int> _savedProgress = {};
  static Set<String> _claimed = {};

  static String _todayStr() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  static List<DailyChallenge> get todayChallenges => _todayChallenges;

  static void load() {
    try {
      final s = html.window.localStorage;
      _loadedDate = s['bjChalDate'] ?? '';
      final prog = s['bjChalProg'] ?? '';
      final claimed = s['bjChalClaimed'] ?? '';
      _claimed = claimed.isEmpty ? {} : claimed.split(',').toSet();
      if (prog.isNotEmpty) {
        for (final p in prog.split(';')) {
          final kv = p.split(':');
          if (kv.length == 2) _savedProgress[kv[0]] = int.tryParse(kv[1]) ?? 0;
        }
      }
    } catch (_) {}
    _generateToday();
  }

  static void _generateToday() {
    final today = _todayStr();
    // Seed by date so everyone gets same challenges
    final seed = today.hashCode.abs();
    final rng = Random(seed);

    final easy = kAllChallenges.where((c) => c.difficulty == ChallengeDifficulty.easy).toList();
    final medium = kAllChallenges.where((c) => c.difficulty == ChallengeDifficulty.medium).toList();
    final hard = kAllChallenges.where((c) => c.difficulty == ChallengeDifficulty.hard).toList();

    easy.shuffle(rng); medium.shuffle(rng); hard.shuffle(rng);

    _todayChallenges = [
      DailyChallenge(easy.first),
      DailyChallenge(medium.first),
      DailyChallenge(hard.first),
    ];

    // Restore progress if same day
    if (_loadedDate == today) {
      for (final c in _todayChallenges) {
        c.progress = _savedProgress[c.def.id] ?? 0;
        c.completed = c.progress >= c.def.target;
        c.rewardClaimed = _claimed.contains(c.def.id);
      }
    } else {
      // New day — reset
      _savedProgress = {};
      _claimed = {};
      _save();
    }
  }

  static void _save() {
    try {
      final s = html.window.localStorage;
      s['bjChalDate'] = _todayStr();
      s['bjChalProg'] = _savedProgress.entries.map((e) => '${e.key}:${e.value}').join(';');
      s['bjChalClaimed'] = _claimed.join(',');
    } catch (_) {}
  }

  // Returns list of newly completed challenge IDs
  static List<String> updateProgress({
    required int winsThisRound, required int currentStreak,
    required bool tripleWin, required bool sideHit,
    required bool hadBust, required int totalBet, required bool wonRound,
  }) {
    final newly = <String>[];
    for (final c in _todayChallenges) {
      if (c.completed) continue;
      final prev = c.progress;
      switch (c.def.type) {
        case ChallengeType.winRounds: if (wonRound) c.progress++; break;
        case ChallengeType.playRounds: c.progress++; break;
        case ChallengeType.winStreak: c.progress = currentStreak; break;
        case ChallengeType.tripleWin: if (tripleWin) c.progress++; break;
        case ChallengeType.sideBet: if (sideHit) c.progress++; break;
        case ChallengeType.winHands: c.progress += winsThisRound; break;
        case ChallengeType.winWithoutBust: if (wonRound && !hadBust) c.progress++; else if (hadBust) c.progress = 0; break;
        case ChallengeType.doubleWin: if (winsThisRound >= 2) c.progress++; break;
        case ChallengeType.bigBet: if (totalBet >= c.def.target) c.progress = c.def.target; break;
      }
      _savedProgress[c.def.id] = c.progress;
      if (c.progress >= c.def.target && !c.completed) {
        c.completed = true;
        newly.add(c.def.id);
      }
    }
    _save();
    return newly;
  }

  static int claimReward(String challengeId) {
    final c = _todayChallenges.firstWhere((c) => c.def.id == challengeId,
        orElse: () => DailyChallenge(kAllChallenges.first));
    if (!c.completed || c.rewardClaimed) return 0;
    c.rewardClaimed = true;
    _claimed.add(challengeId);
    _save();
    PlayerStorage.addXP(c.def.xpReward);
    // Track total challenges claimed for Challenge Ace badge
    try {
      final s = html.window.localStorage;
      final total = int.tryParse(s['bjTotalChallenges'] ?? '0') ?? 0;
      final newTotal = total + 1;
      s['bjTotalChallenges'] = '$newTotal';
      if (newTotal >= 30) {
        if (!PlayerStorage.earnedBadges.contains('challenge_ace')) {
          PlayerStorage.earnedBadges.add('challenge_ace');
          PlayerStorage.save();
        }
      }
    } catch (_) {}
    return c.def.chipReward;
  }

  static int get completedCount => _todayChallenges.where((c) => c.completed).length;
  static int get claimedCount => _todayChallenges.where((c) => c.rewardClaimed).length;
}

class TournamentEntry {
  final String name;
  final int avatarIndex, finalBalance, rank;
  TournamentEntry(this.name, this.avatarIndex, this.finalBalance, this.rank);
}
// ── AI Player Personalities ───────────────────────────────────
enum AiPersonality { aggressive, conservative, balanced, lucky }

class AiPlayer {
  final String name;
  final int avatarIndex;
  final AiPersonality personality;
  int balance;
  int handsPlayed;
  int handsWon;
  int biggestWin;
  int lastBet;

  AiPlayer({
    required this.name,
    required this.avatarIndex,
    required this.personality,
    required this.balance,
  }) : handsPlayed = 0, handsWon = 0, biggestWin = 0, lastBet = 0;

  double get winRate => handsPlayed > 0 ? handsWon / handsPlayed : 0;
  String get winRateStr => handsPlayed > 0
      ? '${(winRate * 100).toStringAsFixed(0)}%' : '—';

  void simulateHand(Random rng, int startingChips) {
    handsPlayed++;
    int bet;
    double winChance;
    switch (personality) {
      case AiPersonality.aggressive:
        bet = (balance * (0.15 + rng.nextDouble() * 0.25)).round().clamp(25, balance);
        winChance = 0.44;
        break;
      case AiPersonality.conservative:
        bet = (balance * (0.03 + rng.nextDouble() * 0.07)).round().clamp(10, balance);
        winChance = 0.48;
        break;
      case AiPersonality.lucky:
        bet = (balance * (0.08 + rng.nextDouble() * 0.15)).round().clamp(15, balance);
        winChance = rng.nextDouble() < 0.3 ? 0.65 : 0.38;
        break;
      case AiPersonality.balanced:
      default:
        bet = (balance * (0.06 + rng.nextDouble() * 0.12)).round().clamp(15, balance);
        winChance = 0.46;
        break;
    }
    lastBet = bet.clamp(1, balance);
    final won = rng.nextDouble() < winChance;
    if (won) {
      handsWon++;
      final gain = (lastBet * (1 + rng.nextDouble() * 0.5)).round();
      balance += gain;
      if (gain > biggestWin) biggestWin = gain;
    } else {
      balance = (balance - lastBet).clamp(0, 999999);
    }
    if (balance < 50) balance = 50 + rng.nextInt(100);
  }
}

const List<String> kAiNames = [
  'Ace_King88', 'DealerSlayer', 'CardShark_KC', 'LuckyMike',
  'BlackjackPro', 'TripleThreat7', 'ChipBoss', 'VegasVic',
  'TheCounter', 'NightOwl99', 'RoyalFlush', 'SplitKing',
  'DoubleDowner', 'HotHand_Hank', 'AllInAnna',
];

const List<AiPersonality> kAiPersonalities = [
  AiPersonality.aggressive, AiPersonality.conservative,
  AiPersonality.balanced, AiPersonality.lucky,
  AiPersonality.aggressive, AiPersonality.balanced,
  AiPersonality.conservative, AiPersonality.lucky,
  AiPersonality.balanced, AiPersonality.aggressive,
  AiPersonality.lucky, AiPersonality.conservative,
  AiPersonality.balanced, AiPersonality.aggressive,
  AiPersonality.lucky,
];
class TournamentStorage {
  static String _lastFreeEntry = '';
  static Map<String, DateTime> _lastPlayed = {};

  static Duration cooldownFor(TournamentType type) {
    switch (type) {
      case TournamentType.quick:    return const Duration(hours: 2);
      case TournamentType.standard: return const Duration(hours: 6);
      case TournamentType.marathon: return const Duration(hours: 24);
    }
  }

  static Duration? cooldownRemaining(TournamentType type) {
    final last = _lastPlayed[type.name];
    if (last == null) return null;
    final elapsed = DateTime.now().difference(last);
    final cd = cooldownFor(type);
    if (elapsed >= cd) return null;
    return cd - elapsed;
  }

  static bool canEnter(TournamentType type) =>
      cooldownRemaining(type) == null;

  static void recordEntry(TournamentType type) {
    _lastPlayed[type.name] = DateTime.now();
    _saveCooldowns();
  }

  static String formatCooldown(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) return '${h}h ${m.toString().padLeft(2,'0')}m';
    if (m > 0) return '${m}m ${s.toString().padLeft(2,'0')}s';
    return '${s}s';
  }

  static bool canEnterFree() {
    final today = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
    return _lastFreeEntry != today;
  }

  static void useFreeEntry() {
    _lastFreeEntry = '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}';
    try {
      html.window.localStorage['bjTournFree'] = _lastFreeEntry;
    } catch (_) {}
  }

  static void _saveCooldowns() {
    try {
      final s = html.window.localStorage;
      _lastPlayed.forEach((key, dt) {
        s['bjTournCD_$key'] = dt.millisecondsSinceEpoch.toString();
      });
    } catch (_) {}
  }

  static void load() {
    try {
      final s = html.window.localStorage;
      _lastFreeEntry = s['bjTournFree'] ?? '';
      for (final type in TournamentType.values) {
        final raw = s['bjTournCD_${type.name}'];
        if (raw != null) {
          final ms = int.tryParse(raw);
          if (ms != null) {
            _lastPlayed[type.name] =
                DateTime.fromMillisecondsSinceEpoch(ms);
          }
        }
      }
    } catch (_) {}
  }

   // Simulate leaderboard with some AI opponents
  static List<TournamentEntry> generateResults(
      String playerName, int playerAvatar, int playerBalance,
      TournamentConfig config) {
    final rng = Random();
    final opponents = [
      ['Ace_King', 0], ['DealerSlayer', 2], ['CardShark99', 4],
      ['LuckyLou', 1], ['BlackjackPro', 3], ['TripleThreat', 5],
      ['ChipBoss', 6], ['VegasVic', 7], ['TheCounter', 2],
    ];
    final entries = <TournamentEntry>[];
    // Generate AI scores around starting chips with variance
    for (int i = 0; i < 6; i++) {
      final opp = opponents[i];
      final variance = (rng.nextDouble() * 2 - 0.8);
      final aiBalance = (config.startingChips * (1 + variance)).round().clamp(0, config.startingChips * 4);
      entries.add(TournamentEntry(opp[0] as String, opp[1] as int, aiBalance, 0));
    }
    entries.add(TournamentEntry(playerName, playerAvatar, playerBalance, 0));
    entries.sort((a, b) => b.finalBalance.compareTo(a.finalBalance));
    return entries.asMap().entries.map((e) =>
        TournamentEntry(e.value.name, e.value.avatarIndex, e.value.finalBalance, e.key + 1)
    ).toList();
  }
}

class AppSettings {
  static int _themeIndex = 0;
  static bool _soundEnabled = true;
  static double _volume = 0.7; // 0.0 to 1.0

  static int get themeIndex => _themeIndex;
  static bool get soundEnabled => _soundEnabled;
  static double get volume => _volume;
  static TableTheme get theme => kTableThemes[_themeIndex];

  static void setTheme(int index) { _themeIndex = index; _save(); }
  static void toggleSound() { _soundEnabled = !_soundEnabled; _save(); }
  static void setVolume(double v) { _volume = v.clamp(0.0, 1.0); _save(); }

  static void _save() {
    try {
      html.window.localStorage['bjSoundOn'] = _soundEnabled ? '1' : '0';
      html.window.localStorage['bjVolume'] = _volume.toString();
      html.window.localStorage['bjTheme'] = _themeIndex.toString();
    } catch (_) {}
  }

  static void load() {
    try {
      final s = html.window.localStorage;
      _soundEnabled = (s['bjSoundOn'] ?? '1') == '1';
      _volume = double.tryParse(s['bjVolume'] ?? '0.7') ?? 0.7;
      _themeIndex = int.tryParse(s['bjTheme'] ?? '0') ?? 0;
    } catch (_) {}
  }
}


// ── Progression System ────────────────────────────────────────
class PlayerLevel {
  final int level;
  final String title;
  final int xpRequired;
  final Color color;
  const PlayerLevel(this.level, this.title, this.xpRequired, this.color);
}

const List<PlayerLevel> kLevels = [
  PlayerLevel(1,  'Rookie',       0,      Color(0xFFBDBDBD)),
  PlayerLevel(2,  'Apprentice',   200,    Color(0xFF90A4AE)),
  PlayerLevel(3,  'Dealer',       500,    Color(0xFF80CBC4)),
  PlayerLevel(4,  'Sharp',        1000,    Color(0xFF4CAF50)),
  PlayerLevel(5,  'Hustler',      2000,    Color(0xFF26A69A)),
  PlayerLevel(6,  'Pro',          3500,   Color(0xFF42A5F5)),
  PlayerLevel(7,  'Shark',        5500,   Color(0xFF1E88E5)),
  PlayerLevel(8,  'High Roller',  8500,   Color(0xFF7E57C2)),
  PlayerLevel(9,  'Whale',        13000,   Color(0xFF9C27B0)),
  PlayerLevel(10, 'Legend',       20000,   Color(0xFFFFD700)),
  PlayerLevel(11, 'Myth',         30000,   Color(0xFFFF9800)),
  PlayerLevel(12, 'Ghost',        45000,  Color(0xFF00BCD4)),
  PlayerLevel(13, 'Phantom',      65000,  Color(0xFFE91E63)),
  PlayerLevel(14, 'Maestro',      90000,  Color(0xFFF44336)),
  PlayerLevel(15, 'Godfather',    120000,  Color(0xFFD4AF37)),
  PlayerLevel(16, 'Immortal',     160000,  Color(0xFF00E5FF)),
  PlayerLevel(17, 'The House',    200000, Color(0xFFFFFFFF)),
];

PlayerLevel getLevelForXP(int xp) {
  PlayerLevel current = kLevels.first;
  for (final l in kLevels) {
    if (xp >= l.xpRequired) current = l;
  }
  return current;
}

PlayerLevel? getNextLevel(int xp) {
  for (int i = 0; i < kLevels.length - 1; i++) {
    if (xp >= kLevels[i].xpRequired && xp < kLevels[i+1].xpRequired) {
      return kLevels[i+1];
    }
  }
  return null;
}

double getLevelProgress(int xp) {
  final current = getLevelForXP(xp);
  final next = getNextLevel(xp);
  if (next == null) return 1.0;
  final range = next.xpRequired - current.xpRequired;
  final progress = xp - current.xpRequired;
  return (progress / range).clamp(0.0, 1.0);
}

int calcXP({
  required int wins, required int totalHands,
  required int streak, required bool sideHit, required bool tripleWin,
}) {
  int xp = 5; // base for playing
  xp += wins * 10;
  if (tripleWin) xp += 50;
  if (streak >= 2) xp += streak * 5;
  if (sideHit) xp += 25;
  return xp;
}

// ── Badges ────────────────────────────────────────────────────
class Badge {
  final String id, name, description, emoji;
  const Badge(this.id, this.name, this.description, this.emoji);
}

const List<Badge> kBadges = [
  // ── Early Game ────────────────────────────────────────────
  Badge('deal_me_in',     'Deal Me In',         'Complete your first round',              '🃏'),
  Badge('first_blood',    'First Blood',         'Win your first hand',                    '🩸'),
  Badge('side_hustler',   'Side Hustler',        'Place your first side bet',              '💜'),
  Badge('double_threat',  'Double Threat',       'Win 2 hands in one round',               '🎯'),
  Badge('hot_hand',       'Hot Hand',            'Win 3 hands in a row',                   '🌶️'),
  Badge('first_triple',   'Triple Threat',       'Win all 3 hands in one round',           '🎰'),
  // ── Progression ───────────────────────────────────────────
  Badge('level_5',        'Going Pro',           'Reach Level 5',                          '⭐'),
  Badge('big_spender',    'High Roller',         'Bet \$500+ in a single round',           '💵'),
  Badge('streak_5',       'On a Roll',           'Win 5 hands in a row',                   '🔥'),
  Badge('banker',         'Banker',              'Accumulate \$50,000 balance',            '🏦'),
  Badge('daily_grinder',  'Daily Grinder',       'Claim daily bonus 7 days in a row',      '📅'),
  Badge('broke',          'Busted',              'Run out of chips',                       '💸'),
  // ── Mid Game ──────────────────────────────────────────────
  Badge('comeback',       'Comeback Kid',        'Win after dropping below \$100',         '💪'),
  Badge('rounds_50',      'Card Shark',          'Play 50 rounds',                         '🦈'),
  Badge('bronze_elite',   'Bronze Elite',        'Reach Bronze VIP tier',                  '🥉'),
  Badge('rounds_100',     'Veteran',             'Play 100 rounds',                        '⚔️'),
  Badge('silver_fox',     'Silver Fox',          'Reach Silver VIP tier',                  '🥈'),
  Badge('streak_10',      'Unstoppable',         'Win 10 hands in a row',                  '💫'),
  // ── Advanced ──────────────────────────────────────────────
  Badge('win_rate_60',    'Untouchable',         'Achieve 60%+ win rate (20+ rounds)',     '🛡️'),
  Badge('tourn_rookie',   'Tournament Rookie',   'Enter your first tournament',            '🎖️'),
  Badge('tourn_champ',    'Tournament Champion', 'Finish 1st in any tournament',           '🏆'),
  Badge('level_10',       'Legend Status',       'Reach Level 10',                         '👑'),
  Badge('on_fire',        'On Fire',             'Win 3 side bets in one session',         '🔥'),
  Badge('wagered_100k',   'Big Spender',         'Wager \$100,000 lifetime',               '💰'),
  // ── Elite ─────────────────────────────────────────────────
  Badge('social',         'Social Butterfly',    'Add your first friend',                  '🦋'),
  Badge('gold_standard',  'Gold Standard',       'Reach Gold VIP tier',                    '🥇'),
  Badge('triple_master',  'Triple Master',       'Win all 3 hands 25 times',               '🎯'),
  Badge('rounds_250',     'Statistician',        'Play 250 rounds',                        '📊'),
  Badge('challenge_ace',  'Challenge Ace',       'Complete 30 daily challenges',           '🎯'),
  Badge('rounds_500',     'Night Owl',           'Play 500 rounds',                        '🌙'),
  // ── Legendary ─────────────────────────────────────────────
  Badge('platinum_club',  'Platinum Club',       'Reach Platinum VIP tier',                '💎'),
  Badge('high_society',   'High Society',        'Reach Level 13',                         '🎩'),
  Badge('millionaire',    'Millionaire',         'Accumulate \$1,000,000 balance',         '💰'),
  Badge('squad_goals',    'Squad Goals',         'Add 5 friends',                          '👥'),
  Badge('sharp_shooter',  'Sharp Shooter',       'Win 500 individual hands',               '🎯'),
  Badge('diamond_royale', 'Diamond Royale',      'Reach Diamond VIP tier',                 '💎'),
  Badge('rounds_1000',    'Creature of the Night', 'Play 1,000 rounds',                   '🌙'),
  Badge('diamond_hands',  'Diamond Hands',       'Accumulate 100,000 XP',                  '💎'),
  Badge('the_house',      'The House',           'Win 10,000 individual hands',            '🏛️'),
  Badge('untouchable_season', 'Untouchable Season', 'Maintain 60%+ win rate over 500+ rounds', '👑'),
];

// Uses a simple in-memory store + cookies for web persistence
class LeaderboardEntry {
  final String name;
  final int avatarIndex;
  final int balance;
  final int rounds;
  final int wins;
  final int netProfit;     // balance - 2000 starting chips
  final int bestStreak;    // highest win streak
  final int biggestWin;    // biggest single round win
  final DateTime date;

  LeaderboardEntry({
    required this.name, required this.avatarIndex, required this.balance,
    required this.rounds, required this.wins, required this.netProfit,
    required this.bestStreak, required this.biggestWin, required this.date,
  });

  double get winRatePct => rounds > 0 ? wins / rounds * 100 : 0;
  String get winRateStr => rounds >= 20
      ? '${winRatePct.toStringAsFixed(1)}%'
      : '${winRatePct.toStringAsFixed(1)}% (${rounds}r)';
  bool get qualifiesForWinRate => rounds >= 20;

  String toStorageString() =>
      '$name|$avatarIndex|$balance|$rounds|$wins|$netProfit|$bestStreak|$biggestWin|${date.millisecondsSinceEpoch}';

  static LeaderboardEntry? fromStorageString(String s) {
    try {
      final p = s.split('|');
      if (p.length < 9) {
        // Legacy format — upgrade it
        if (p.length >= 6) {
          return LeaderboardEntry(
            name: p[0], avatarIndex: int.parse(p[1]),
            balance: int.parse(p[2]), rounds: int.parse(p[3]),
            wins: int.parse(p[4]), netProfit: int.parse(p[2]) - 2000,
            bestStreak: 0, biggestWin: 0,
            date: DateTime.fromMillisecondsSinceEpoch(int.parse(p[5])),
          );
        }
        return null;
      }
      return LeaderboardEntry(
        name: p[0], avatarIndex: int.parse(p[1]),
        balance: int.parse(p[2]), rounds: int.parse(p[3]),
        wins: int.parse(p[4]), netProfit: int.parse(p[5]),
        bestStreak: int.parse(p[6]), biggestWin: int.parse(p[7]),
        date: DateTime.fromMillisecondsSinceEpoch(int.parse(p[8])),
      );
    } catch (_) { return null; }
  }
}

class PlayerStorage {
  static String _playerName = '';
  static int _avatarIndex = 0;
  static String _lastBonusDate = '';
  static int _bonusStreak = 0;
  static int get bonusStreak => _bonusStreak;
  static int _totalChips = 0;
  static bool _pendingBonus = false;
  static bool _loaded = false;

  // Persistent stats
  static int _statRounds = 0;
  static int _statWins = 0;
  static int _statLosses = 0;
  static int _statPushes = 0;
  static int _statBiggestWin = 0;
  static int _statBestStreak = 0;
  static int _statWagered = 0;
  static int _statProfit = 0;

  // XP and badges
  static int _xp = 0;
  static Set<String> _earnedBadges = {};
  static int _tripleWins = 0;
  static int _totalHandsWon = 0;

  static int get xp => _xp;
  static Set<String> get earnedBadges => _earnedBadges;
  static PlayerLevel get level => getLevelForXP(_xp);
  static int get tripleWins => _tripleWins;
  static int get totalHandsWon => _totalHandsWon;

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final s = html.window.localStorage;
      _playerName = s['bjName'] ?? '';
      _avatarIndex = int.tryParse(s['bjAvatar'] ?? '0') ?? 0;
      _lastBonusDate = s['bjBonus'] ?? '';
      _bonusStreak = int.tryParse(s['bjBonusStreak'] ?? '0') ?? 0;
      _totalChips = int.tryParse(s['bjChips'] ?? '0') ?? 0;
      _statRounds = int.tryParse(s['bjRounds'] ?? '0') ?? 0;
      _statWins = int.tryParse(s['bjWins'] ?? '0') ?? 0;
      _statLosses = int.tryParse(s['bjLosses'] ?? '0') ?? 0;
      _statPushes = int.tryParse(s['bjPushes'] ?? '0') ?? 0;
      _statBiggestWin = int.tryParse(s['bjBigWin'] ?? '0') ?? 0;
      _statBestStreak = int.tryParse(s['bjBestStreak'] ?? '0') ?? 0;
      _statWagered = int.tryParse(s['bjWagered'] ?? '0') ?? 0;
      _statProfit = int.tryParse(s['bjProfit'] ?? '0') ?? 0;
      _xp = int.tryParse(s['bjXP'] ?? '0') ?? 0;
      final badgeStr = s['bjBadges'] ?? '';
      _earnedBadges = badgeStr.isEmpty ? {} : badgeStr.split(',').toSet();
      _tripleWins = int.tryParse(s['bjTriples'] ?? '0') ?? 0;
      _totalHandsWon = int.tryParse(s['bjHandsWon'] ?? '0') ?? 0;
    } catch (_) {}
    _loaded = true;
  }

  static void save() {
    try {
      final s = html.window.localStorage;
      s['bjName'] = _playerName;
      s['bjAvatar'] = '$_avatarIndex';
      s['bjBonus'] = _lastBonusDate;
      s['bjBonusStreak'] = '$_bonusStreak';
      s['bjChips'] = '$_totalChips';
      s['bjRounds'] = '$_statRounds';
      s['bjWins'] = '$_statWins';
      s['bjLosses'] = '$_statLosses';
      s['bjPushes'] = '$_statPushes';
      s['bjBigWin'] = '$_statBiggestWin';
      s['bjBestStreak'] = '$_statBestStreak';
      s['bjWagered'] = '$_statWagered';
      s['bjProfit'] = '$_statProfit';
      s['bjXP'] = '$_xp';
      s['bjBadges'] = _earnedBadges.join(',');
      s['bjTriples'] = '$_tripleWins';
      s['bjHandsWon'] = '$_totalHandsWon';
    } catch (_) {}
  }

  // Stats getters
  static int get statRounds => _statRounds;
  static int get statWins => _statWins;
  static int get statLosses => _statLosses;
  static int get statPushes => _statPushes;
  static int get statBiggestWin => _statBiggestWin;
  static int get statBestStreak => _statBestStreak;
  static int get statWagered => _statWagered;
  static int get statProfit => _statProfit;

  static void saveStats({
    required int rounds, required int wins, required int losses,
    required int pushes, required int biggestWin, required int bestStreak,
    required int wagered, required int profit,
  }) {
    _statRounds = rounds; _statWins = wins; _statLosses = losses;
    _statPushes = pushes; _statBiggestWin = biggestWin;
    _statBestStreak = bestStreak; _statWagered = wagered; _statProfit = profit;
    save();
  }

  static bool get hasName => _playerName.isNotEmpty;
  static String get playerName => _playerName;
  static int get avatarIndex => _avatarIndex;
  static int get savedChips => _totalChips;
  static bool get pendingBonus => _pendingBonus;

  static void setPlayer(String name, int avatar) {
    _playerName = name; _avatarIndex = avatar; save();
  }

  static void saveChips(int chips) {
    _totalChips = chips; save();
  }

  static bool get canClaimDailyBonus {
    final today = _todayString();
    return _lastBonusDate != today;
  }

  static void claimBonus() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final yesterdayStr = '${yesterday.year}-${yesterday.month}-${yesterday.day}';
    if (_lastBonusDate == yesterdayStr) {
      _bonusStreak++;
    } else {
      _bonusStreak = 1;
    }
    _lastBonusDate = _todayString();
    _pendingBonus = true;
    save();
    // Check daily grinder badge
    if (_bonusStreak >= 7) {
      if (!_earnedBadges.contains('daily_grinder')) {
        _earnedBadges.add('daily_grinder');
        save();
      }
    }
  }

  static void addXP(int amount) {
    _xp += amount;
    save();
  }

  // Returns list of newly earned badge IDs
  static List<String> checkAndAwardBadges({
  required int totalRounds, required int totalWins, required int bestStreak,
  required bool justWon, required bool tripleWin, required bool sideHit,
  required bool wasBroke, required bool comeback, required bool bigSpender,
  required int balance, required int handsWonThisRound,
  required bool enteredTournament, required bool wonTournament,
  required int totalSideBetsSession, required int totalWagered,
}) {
  if (tripleWin) _tripleWins++;
  _totalHandsWon += handsWonThisRound;

  final newBadges = <String>[];
  void check(String id, bool condition) {
    if (condition && !_earnedBadges.contains(id)) {
      _earnedBadges.add(id); newBadges.add(id);
    }
  }

  // Early game
  check('deal_me_in',    totalRounds >= 1);
  check('first_blood',   justWon && totalWins >= 1);
  check('side_hustler',  sideHit);
  check('double_threat', handsWonThisRound >= 2);
  check('hot_hand',      bestStreak >= 3);
  check('first_triple',  tripleWin);

  // Progression
  check('level_5',       getLevelForXP(_xp).level >= 5);
  check('big_spender',   bigSpender);
  check('streak_5',      bestStreak >= 5);
  check('banker',        balance >= 50000);
  check('broke',         wasBroke);

  // Mid game
  check('comeback',      comeback);
  check('rounds_50',     totalRounds >= 50);
  check('bronze_elite',  getVipTier(getLevelForXP(_xp).level).name == 'Bronze');
  check('rounds_100',    totalRounds >= 100);
  check('silver_fox',    getVipTier(getLevelForXP(_xp).level).name == 'Silver' ||
                         getVipTier(getLevelForXP(_xp).level).minLevel >= 4);
  check('streak_10',     bestStreak >= 10);

  // Advanced
  final totalHands = _statWins + _statLosses + _statPushes;
  check('win_rate_60',   totalRounds >= 20 && totalHands > 0 &&
                         (_statWins / totalHands) >= 0.60);
  check('tourn_rookie',  enteredTournament);
  check('tourn_champ',   wonTournament);
  check('level_10',      getLevelForXP(_xp).level >= 10);
  check('on_fire',       totalSideBetsSession >= 3);
  check('wagered_100k',  totalWagered >= 100000);

  // Elite
  check('social',        PlayerStorage.friends.isNotEmpty);
  check('gold_standard', getVipTier(getLevelForXP(_xp).level).minLevel >= 7);
  check('triple_master', _tripleWins >= 25);
  check('rounds_250',    totalRounds >= 250);
  check('rounds_500',    totalRounds >= 500);

  // Legendary
  check('platinum_club', getVipTier(getLevelForXP(_xp).level).minLevel >= 10);
  check('high_society',  getLevelForXP(_xp).level >= 13);
  check('millionaire',   balance >= 1000000);
  check('squad_goals',   PlayerStorage.friends.length >= 5);
  check('sharp_shooter', _totalHandsWon >= 500);
  check('diamond_royale',getVipTier(getLevelForXP(_xp).level).minLevel >= 13);
  check('rounds_1000',   totalRounds >= 1000);
  check('diamond_hands', _xp >= 100000);
  check('the_house',     _totalHandsWon >= 10000);
  check('untouchable_season', totalRounds >= 500 && totalHands > 0 &&
                         (_statWins / totalHands) >= 0.60);

  if (newBadges.isNotEmpty) save();
  return newBadges;
}

  static int collectPendingBonus() {
if (!_pendingBonus) return 0;
_pendingBonus = false;
if (_bonusStreak >= 7) return 2000;
if (_bonusStreak >= 5) return 1500;
if (_bonusStreak >= 3) return 1000;
if (_bonusStreak >= 2) return 750;
return 500;
}

  // ── Leaderboard ──────────────────────────────────────────────
  static List<LeaderboardEntry> getLeaderboard() {
    try {
      final s = html.window.localStorage;
      final raw = s['bjLeaderboard'] ?? '';
      if (raw.isEmpty) return [];
      return raw.split('\n')
          .map((e) => LeaderboardEntry.fromStorageString(e))
          .whereType<LeaderboardEntry>()
          .toList();
    } catch (_) { return []; }
  }

  static void submitScore({
    required String name, required int avatarIndex,
    required int balance, required int rounds, required int wins,
    required int netProfit, required int bestStreak, required int biggestWin,
  }) {
    try {
      final entries = getLeaderboard();
      entries.removeWhere((e) => e.name == name);
      entries.add(LeaderboardEntry(
        name: name, avatarIndex: avatarIndex, balance: balance,
        rounds: rounds, wins: wins, netProfit: netProfit,
        bestStreak: bestStreak, biggestWin: biggestWin,
        date: DateTime.now(),
      ));
      entries.sort((a, b) => b.netProfit.compareTo(a.netProfit));
      final top10 = entries.take(10).toList();
      final s = html.window.localStorage;
      s['bjLeaderboard'] = top10.map((e) => e.toStorageString()).join('\n');
    } catch (_) {}
  }

  static String _todayString() {
    final n = DateTime.now();
    return '${n.year}-${n.month}-${n.day}';
  }

  static Duration get timeUntilNextBonus {
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    return midnight.difference(now);
  }

  // ── Player Code ───────────────────────────────────────────────
  static String _playerCode = '';

  static String get playerCode {
    if (_playerCode.isNotEmpty) return _playerCode;
    // Generate deterministic code from name + avatar
    final base = '${_playerName.toUpperCase().replaceAll(' ', '')}-'
        '${(_avatarIndex * 1337 + _playerName.hashCode.abs() % 9000 + 1000) % 9000 + 1000}';
    _playerCode = base;
    return _playerCode;
  }

  // Encode current stats into a shareable string
  static String generateShareCode() {
    final data = [
      _playerName,
      _avatarIndex,
      _totalChips,
      _statRounds,
      _statWins,
      _statBestStreak,
      _statBiggestWin,
      getLevelForXP(_xp).level,
      _xp,
      playerCode,
    ].join('|');
    // Simple base64-like encoding
    return data.split('').map((c) => c.codeUnitAt(0).toRadixString(16)).join('-');
  }

  static Map<String, String>? decodeShareCode(String code) {
    try {
      final decoded = code.trim().split('-')
          .map((h) => String.fromCharCode(int.parse(h, radix: 16))).join();
      final parts = decoded.split('|');
      if (parts.length < 10) return null;
      return {
        'name': parts[0], 'avatarIndex': parts[1], 'chips': parts[2],
        'rounds': parts[3], 'wins': parts[4], 'bestStreak': parts[5],
        'biggestWin': parts[6], 'level': parts[7], 'xp': parts[8],
        'code': parts[9],
      };
    } catch (_) { return null; }
  }

  // ── Friends ───────────────────────────────────────────────────
  static List<Map<String, String>> _friends = [];

  static List<Map<String, String>> get friends => _friends;

  static void loadFriends() {
    try {
      final s = html.window.localStorage;
      final raw = s['bjFriends'] ?? '';
      if (raw.isEmpty) { _friends = []; return; }
      _friends = raw.split('\n').map((line) {
        final map = <String, String>{};
        for (final kv in line.split(',')) {
          final parts = kv.split('=');
          if (parts.length == 2) map[parts[0]] = parts[1];
        }
        return map;
      }).where((m) => m.isNotEmpty && m.containsKey('name')).toList();
    } catch (_) { _friends = []; }
  }

  static void saveFriends() {
    try {
      final s = html.window.localStorage;
      s['bjFriends'] = _friends.map((f) =>
          f.entries.map((e) => '${e.key}=${e.value}').join(',')).join('\n');
    } catch (_) {}
  }

  static String? addFriend(String shareCode) {
    final data = decodeShareCode(shareCode);
    if (data == null) return 'Invalid code — ask your friend to share again';
    if (data['code'] == playerCode) return 'That\'s your own code!';
    final isNew = !_friends.any((f) => f['code'] == data['code']);
    if (!isNew) {
      // Update existing friend stats
      final idx = _friends.indexWhere((f) => f['code'] == data['code']);
      _friends[idx] = data;
      saveFriends();
      return null;
    }
    if (_friends.length >= 20) return 'Max 20 friends reached';
    _friends.add(data);
    saveFriends();
    // Award referral bonus for first-time add
    _totalChips += 2000;
    save();
    return 'REFERRAL_BONUS'; // special return to trigger bonus UI
  }

  static void removeFriend(String code) {
    _friends.removeWhere((f) => f['code'] == code);
    saveFriends();
  }
}

// ── Sound Engine ──────────────────────────────────────────────
class SoundEngine {
  static bool _enabled = true;
  static double _volume = 0.7;
  static bool _ready = false;
  static const String _js = r"""window._ttb=(function(){var ctx,amb;function ac(){if(!ctx){ctx=new(window.AudioContext||window.webkitAudioContext)();}if(ctx.state==="suspended")ctx.resume();return ctx;}function tone(f,d,t,g,f2){try{var c=ac(),o=c.createOscillator(),e=c.createGain();o.type=t||"sine";o.frequency.value=f;if(f2)o.frequency.linearRampToValueAtTime(f2,c.currentTime+d);e.gain.setValueAtTime(0,c.currentTime);e.gain.linearRampToValueAtTime(g,c.currentTime+0.008);e.gain.exponentialRampToValueAtTime(0.0001,c.currentTime+d);o.connect(e);e.connect(c.destination);o.start(c.currentTime);o.stop(c.currentTime+d+0.1);}catch(ex){}}function noise(dur,freq,q,gain){try{var c=ac();var buf=c.createBuffer(1,Math.floor(c.sampleRate*dur),c.sampleRate);var d2=buf.getChannelData(0);for(var i=0;i<d2.length;i++)d2[i]=(Math.random()*2-1);var src=c.createBufferSource();src.buffer=buf;var flt=c.createBiquadFilter();flt.type="bandpass";flt.frequency.value=freq||1800;flt.Q.value=q||8;var env=c.createGain();env.gain.setValueAtTime(gain,c.currentTime);env.gain.exponentialRampToValueAtTime(0.0001,c.currentTime+dur);src.connect(flt);flt.connect(env);env.connect(c.destination);src.start(c.currentTime);src.stop(c.currentTime+dur+0.1);}catch(ex){}}function jingle(notes,vol){notes.forEach(function(n){setTimeout(function(){tone(n.f,n.d,"sine",vol);},n.t);});}return{card:function(v){noise(0.08,2600,6,v*1.1);noise(0.05,400,2,v*0.9);tone(1800,0.04,"sine",v*0.3,3200);},chip:function(v){noise(0.025,3500,18,v*1.1);noise(0.018,2200,12,v*0.7);tone(1200,0.03,"sine",v*0.2);noise(0.012,4500,22,v*0.45);},win:function(v){var n=[{f:659,d:0.18,t:0},{f:784,d:0.18,t:140},{f:988,d:0.18,t:280},{f:784,d:0.1,t:420},{f:1047,d:0.32,t:510}];jingle(n,v*0.9);},tripleWin:function(v){var n=[{f:523,d:0.13,t:0},{f:659,d:0.13,t:110},{f:784,d:0.13,t:220},{f:1047,d:0.13,t:330},{f:1319,d:0.22,t:440},{f:1047,d:0.55,t:620},{f:1319,d:0.55,t:620},{f:1047,d:0.9,t:1000}];jingle(n,v*1.0);},lose:function(v){tone(330,0.25,"sawtooth",v*0.8,155);setTimeout(function(){tone(220,0.3,"sawtooth",v*0.65,125);},270);},push:function(v){tone(440,0.16,"triangle",v*0.65);},side:function(v){var freqs=[523,622,698,784,880,988,1047,1175];freqs.forEach(function(f,i){setTimeout(function(){tone(f,0.18,"sine",v*0.28);},i*55);});},badge:function(v){var n=[{f:659,d:0.2,t:0},{f:784,d:0.2,t:140},{f:988,d:0.2,t:280},{f:1319,d:0.38,t:420}];jingle(n,v*0.85);},lvl:function(v){var n=[{f:392,d:0.13,t:0},{f:494,d:0.13,t:95},{f:587,d:0.13,t:190},{f:698,d:0.13,t:285},{f:880,d:0.13,t:380},{f:1047,d:0.42,t:475}];jingle(n,v*0.95);},tap:function(v){noise(0.016,3200,14,v*0.6);},startAmb:function(v){if(amb)return;try{var c=ac();amb=true;var mv=v*0.07;var mel=[261,293,329,349,392,349,329,293,261,220,246,261,293,261,246,220];var bas=[130,130,164,174,146,130,146,130];var mi=0;var bi=0;var spd=480;function nm(){if(!amb)return;var f=mel[mi%mel.length];mi++;if(f>0){var o=c.createOscillator();var g=c.createGain();var lp=c.createBiquadFilter();lp.type="lowpass";lp.frequency.value=1600;o.type="triangle";o.frequency.value=f;g.gain.setValueAtTime(0,c.currentTime);g.gain.linearRampToValueAtTime(mv,c.currentTime+0.03);g.gain.exponentialRampToValueAtTime(0.0001,c.currentTime+0.42);o.connect(lp);lp.connect(g);g.connect(c.destination);o.start();o.stop(c.currentTime+0.45);}setTimeout(nm,spd);}function nb(){if(!amb)return;var f=bas[bi%bas.length];bi++;if(f>0){var o=c.createOscillator();var g=c.createGain();o.type="sine";o.frequency.value=f;g.gain.setValueAtTime(0,c.currentTime);g.gain.linearRampToValueAtTime(mv*0.8,c.currentTime+0.05);g.gain.exponentialRampToValueAtTime(0.0001,c.currentTime+0.85);o.connect(g);g.connect(c.destination);o.start();o.stop(c.currentTime+0.9);}setTimeout(nb,spd*2);}nm();setTimeout(nb,spd);}catch(ex){amb=null;}},stopAmb:function(){amb=null;}};})();""";
  static void setEnabled(bool v) => _enabled = v;
  static void setVolume(double v) => _volume = v.clamp(0.0, 1.0);
  static void _init() {
    if (_ready) return; _ready = true;
    try { js.context.callMethod(r"eval", [_js]); } catch(_) {}
  }
  static void _play(String fn) {
    if (!_enabled || _volume <= 0) return;
    _init();
    try {
      final v = _volume.toStringAsFixed(2);
      js.context.callMethod(r"eval", ["if(window._ttb)window._ttb.$fn($v);"]);
    } catch (_) {}
  }
  static void deal()          => _play("card");
  static void chipPlace()     => _play("chip");
  static void tap()           => _play("tap");
  static void win()           => _play("win");
  static void tripleWin()     => _play("tripleWin");
  static void lose()          => _play("lose");
  static void push()          => _play("push");
  static void sideBetHit()    => _play("side");
  static void badgeUnlock()   => _play("badge");
  static void levelUp()       => _play("lvl");
  static void startAmbience() => _play("startAmb");
  static void stopAmbience()  => _play("stopAmb");
}

// ── IAP Service ───────────────────────────────────────────
class IAPService {
  static const String chips1k  = 'com.triplethreat.chips_1000';
  static const String chips5k  = 'com.triplethreat.chips_5000';
  static const String chips15k = 'com.triplethreat.chips_15000';
  static const String vipPass  = 'com.triplethreat.vip_monthly';
  static const Map<String, int> chipAmounts = {chips1k:1000,chips5k:5000,chips15k:15000};
  static bool _isWeb() { try { return html.window.location.href.isNotEmpty; } catch(_){return false;} }
  static Future<bool> purchaseChips(String productId,
      {required Function(int chips) onSuccess, required Function(String error) onError}) async {
    if (_isWeb()) {
      await Future.delayed(const Duration(milliseconds: 800));
      final chips = chipAmounts[productId] ?? 0;
      if (chips > 0) { onSuccess(chips); return true; }
      onError('Unknown product'); return false;
    }
    onError('Billing not available'); return false;
  }
  static Future<bool> purchaseVip({required VoidCallback onSuccess, required Function(String) onError}) async {
    if (_isWeb()) { await Future.delayed(const Duration(milliseconds: 800)); onSuccess(); return true; }
    onError('Billing not available'); return false;
  }
}


// ── Ad Manager ────────────────────────────────────────────
class AdManager {
  static bool _adShowing = false;
  static Future<void> showRewarded(BuildContext context,
      {required int rewardChips, required VoidCallback onReward}) async {
    if (_adShowing) return;
    _adShowing = true;
    bool watched = false;
    final completer = Completer<void>();
    int secondsLeft = 5; bool canSkip = false; Timer? timer;
    showDialog(context: context, barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(builder: (ctx, setS) {
        timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
          secondsLeft--;
          if (secondsLeft <= 0) canSkip = true;
          if (secondsLeft <= 0) { t.cancel(); watched = true; Navigator.of(ctx).pop(); completer.complete(); }
          else { setS(() {}); }
        });
        return Center(child: Container(
          width: 280, padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(color: const Color(0xFF0A0A0A),
              borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0x40FFFFFF))),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('Watch & Earn', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            Container(width: double.infinity, height: 80, color: const Color(0xFF1A1A1A),
              child: const Center(child: Text('TV', style: TextStyle(fontSize: 40)))),
            const SizedBox(height: 12),
            Text('+\$${rewardChips} chips for watching!',
                textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11)),
            const SizedBox(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('\$secondsLeft s', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              GestureDetector(
                onTap: canSkip ? () { timer?.cancel(); Navigator.of(ctx).pop(); completer.complete(); } : null,
                child: Container(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(color: canSkip ? const Color(0xFF1565C0) : const Color(0x20FFFFFF),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(canSkip ? 'SKIP' : 'WAIT...',
                    style: TextStyle(color: canSkip ? Colors.white : Colors.white38,
                        fontSize: 11, fontWeight: FontWeight.w800)))),
            ]),
          ])));
      }));
    await completer.future;
    _adShowing = false;
    if (watched) onReward();
  }
}


// ── Notification Service ────────────────────────────
class NotificationService {
  static bool _permitted = false;
  static bool get isPermitted => _permitted;

  static Future<bool> requestPermission() async {
    try {
      final result = js.context.callMethod('eval', [
        'Notification.permission === "granted" ? "granted" : (Notification.permission === "denied" ? "denied" : "default")'
      ]) as String;
      if (result == 'granted') { _permitted = true; return true; }
      if (result == 'denied') return false;
      js.context.callMethod('eval', ['Notification.requestPermission().then(function(p){window._np=p;});']);
      for (int i = 0; i < 30; i++) {
        await Future.delayed(const Duration(milliseconds: 200));
        final r = js.context.callMethod('eval', ['window._np||""']) as String;
        if (r == 'granted') { _permitted = true; return true; }
        if (r == 'denied') return false;
      }
    } catch (_) {}
    return false;
  }

  static void show({required String title, required String body}) {
    if (!_permitted) return;
    try {
      final t = title.replaceAll("'", "\'");
      final b = body.replaceAll("'", "\'");
      js.context.callMethod('eval', ["if(Notification.permission==='granted'){new Notification('\$t',{body:'\$b'});}"]);
    } catch (_) {}
  }

  static void scheduleDailyBonusReminder() {
    try {
      final ms = PlayerStorage.timeUntilNextBonus.inMilliseconds;
      if (ms <= 0) return;
      js.context.callMethod('eval', [
        "clearTimeout(window._bt);window._bt=setTimeout(function(){if(Notification.permission==='granted'){new Notification('Triple Threat Blackjack',{body:'Don\\'t break your streak - bonus is ready!'});}},\$ms);"
      ]);
    } catch (_) {}
  }
}


class ShareHelper {
  // Copy to clipboard on web, native share on mobile after App Store build
  static void share(BuildContext context, String text) {
    try {
      html.window.navigator.clipboard?.writeText(text);
    } catch (_) {}
    _showCopiedSnack(context, text);
  }

  static void _showCopiedSnack(BuildContext context, String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Text('📋 ', style: TextStyle(fontSize: 16)),
        const Expanded(child: Text('Copied! Paste into any app to share.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
      ]),
      backgroundColor: const Color(0xFF1B5E20),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  static String friendReferral(String playerCode) =>
      '🃏 Join me on Triple Threat Blackjack!\n\n'
      'Enter my code to add me as a friend and we BOTH get \$2,000 FREE chips!\n\n'
      'My code: $playerCode\n\n'
      '👆 Open Triple Threat Blackjack → MENU → FRIENDS → ADD FRIEND → paste my code\n\n'
      '#TripleThreatBlackjack #Casino #Blackjack';

  static String badgeEarned(Badge badge) =>
      '${badge.emoji} I just unlocked "${badge.name}" in Triple Threat Blackjack!\n\n'
      '"${badge.description}"\n\n'
      'Can you earn it too? 🃏\n'
      '#TripleThreatBlackjack #Achievement #Blackjack';

  static String bigWin(int amount) =>
      '💰 HUGE WIN on Triple Threat Blackjack!\n\n'
      'I just won ${fmtMoney(amount)} in a single round! 🎰\n\n'
      'Think you can beat that?\n'
      '#TripleThreatBlackjack #BigWin #Casino';

  static String levelUp(PlayerLevel level) =>
      '⬆️ Just reached Level ${level.level} "${level.title}" in Triple Threat Blackjack!\n\n'
      'The grind is real 🃏💪\n\n'
      '#TripleThreatBlackjack #LevelUp #Blackjack';

  static String tripleWin() =>
      '🎯🎯🎯 TRIPLE WIN! All 3 hands won in ONE round!\n\n'
      'Triple Threat Blackjack is the most exciting blackjack game out there!\n\n'
      '#TripleThreatBlackjack #TripleWin #Casino #Blackjack';

  static String tournamentWin(String tournamentName, int rank, int prize) =>
      '🏆 ${rank == 1 ? "1ST PLACE" : rank == 2 ? "2ND PLACE" : "3RD PLACE"} '
      'in the $tournamentName Tournament!\n\n'
      'Won ${fmtMoney(prize)} in chips! 🎰\n\n'
      'Triple Threat Blackjack — 3 hands, 1 destiny\n'
      '#TripleThreatBlackjack #Tournament #Winner';

  static String vipTier(VipTier tier) =>
      '${tier.emoji} Just reached ${tier.name} VIP status in Triple Threat Blackjack!\n\n'
      'The grind never stops 🃏\n\n'
      '#TripleThreatBlackjack #VIP #${tier.name}';

  // Share button widget
  static Widget shareBtn(BuildContext context, String text, {String label = 'SHARE'}) {
    return GestureDetector(
      onTap: () => share(context, text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1565C0), Color(0xFF0D47A1)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter),
          borderRadius: BorderRadius.circular(20),
          boxShadow: const [BoxShadow(color: Color(0x601565C0), blurRadius: 8)]),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.share, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(
              color: Colors.white, fontSize: 11,
              fontWeight: FontWeight.w800, letterSpacing: 1)),
        ]),
      ),
    );
  }
}


const List<Color> kAvatarColors = [
  Color(0xFFD32F2F), Color(0xFF1565C0), Color(0xFF2E7D32),
  Color(0xFF6A1B9A), Color(0xFFE65100), Color(0xFF00838F),
  Color(0xFFAD1457), Color(0xFF37474F),
  Color(0xFF880E4F), Color(0xFF1A237E), Color(0xFF004D40), Color(0xFF3E2723),
];
const List<String> kAvatarEmojis = ['🎩','🦁','🐺','🦊','🐯','🦅','🃏','💀','👑','🌙','🔥','💎'];
const List<String> kAvatarLabels = ['Gambler','Lion','Wolf','Fox','Tiger','Eagle','Joker','Ghost','Royale','Night Owl','Hot Hand','Diamond'];

// ── App Entry — decides which screen to show first ────────────
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});
  @override State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  @override void initState() {
    super.initState();
    PlayerStorage.load().then((dynamic _) {
      AppSettings.load();
      TournamentStorage.load();
      ChallengeManager.load();
      PlayerStorage.loadFriends();
      SoundEngine.setEnabled(AppSettings.soundEnabled);
      SoundEngine.setVolume(AppSettings.volume);
      Future.delayed(const Duration(milliseconds: 500), SoundEngine.startAmbience);
      Future.delayed(const Duration(seconds: 3), () async {
        if (await NotificationService.requestPermission()) {
          NotificationService.scheduleDailyBonusReminder();
        }
      });
      if (!mounted) return;
      if (!PlayerStorage.hasName) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (BuildContext _) => const LoginScreen()));
      } else {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (BuildContext _) => const SplashScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F3A0A),
      body: Center(child: CircularProgressIndicator(color: Color(0xFFD4AF37))),
    );
  }
}

// ── Auth Service ────────────────────────────────────────────
class AuthService {
  static String _guestName() {
    final r = Random();
    const a = ['Lucky','Swift','Bold','Ace','Royal','Wild','Sharp','Golden'];
    const n = ['Player','Dealer','Shark','King','Hustler','Card','Chip','Hand'];
    return '${a[r.nextInt(a.length)]}${n[r.nextInt(n.length)]}${1000+r.nextInt(8999)}';
  }
  static Future<Map<String,String>?> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return {'name':'GooglePlayer','provider':'google'};
  }
  static Future<Map<String,String>?> signInWithApple() async {
    await Future.delayed(const Duration(milliseconds: 800));
    return {'name':'ApplePlayer','provider':'apple'};
  }
  static Future<Map<String,String>> signInAsGuest() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return {'name':_guestName(),'provider':'guest'};
  }
}

// ── Login Screen ────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}
class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _fade, _slide;
  bool _loading = false; String _loadingLabel = '';
  @override void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _slide = Tween<double>(begin: 40, end: 0).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }
  @override void dispose() { _animCtrl.dispose(); super.dispose(); }
  Future<void> _handleLogin(Future<Map<String,String>?> Function() fn, String label) async {
    setState(() { _loading = true; _loadingLabel = label; });
    try {
      final result = await fn();
      if (result == null) { setState(() => _loading = false); return; }
      PlayerStorage.setPlayer(result['name'] ?? 'Player', 0);
      PlayerStorage.save();
      if (!mounted) return;
      final provider = result['provider'] ?? 'guest';
      Navigator.of(context).pushReplacement(MaterialPageRoute(
        builder: (_) => provider == 'guest' ? const SplashScreen() : AvatarPickerScreen(playerName: result['name']!)));
    } catch(e) { setState(() => _loading = false); }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [Color(0xFF061A04), Color(0xFF0A2608), Color(0xFF061A04)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: FeltPainter())),
          Center(child: FadeTransition(opacity: _fade,
            child: AnimatedBuilder(animation: _slide,
              builder: (_, child) => Transform.translate(offset: Offset(0, _slide.value), child: child),
              child: Container(
                width: 380,
                padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
                decoration: BoxDecoration(
                  color: const Color(0xF00A1A08),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                  boxShadow: const [BoxShadow(color: Color(0x80D4AF37), blurRadius: 32)]),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('🃏', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(colors: [Color(0xFFFFE082), Color(0xFFD4AF37)]).createShader(b),
                    child: const Text('TRIPLE THREAT', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900, letterSpacing: 5))),
                  const Text('BLACKJACK', style: TextStyle(color: Color(0x80D4AF37), fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 8)),
                  const SizedBox(height: 4),
                  const Text('Patent Pending', style: TextStyle(color: Color(0x50D4AF37), fontSize: 9, fontWeight: FontWeight.w500, letterSpacing: 2)),
                  const SizedBox(height: 32),
                  if (_loading) ...[
                    const CircularProgressIndicator(color: Color(0xFFD4AF37)),
                    const SizedBox(height: 16),
                    Text(_loadingLabel, style: const TextStyle(color: Color(0x80D4AF37), fontSize: 12)),
                  ] else ...[
                    _SocialBtn(onTap: () => _handleLogin(AuthService.signInWithGoogle,'Signing in with Google...'),
                      label: 'Continue with Google', badge: 'G', color: const Color(0xFF1A3A6A), bColor: const Color(0xFF4285F4)),
                    const SizedBox(height: 12),
                    _SocialBtn(onTap: () => _handleLogin(AuthService.signInWithApple,'Signing in with Apple...'),
                      label: 'Continue with Apple', badge: '', color: const Color(0xFF1A1A1A), bColor: const Color(0xFF888888)),
                    const SizedBox(height: 20),
                    Row(children: const [Expanded(child: Divider(color: Color(0x40D4AF37))),
                      Padding(padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Text('or', style: TextStyle(color: Color(0x60D4AF37), fontSize: 12))),
                      Expanded(child: Divider(color: Color(0x40D4AF37)))]),
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () => _handleLogin(AuthService.signInAsGuest,'Creating guest account...'),
                      child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(color: const Color(0x15D4AF37),
                          borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0x40D4AF37))),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.person_outline, color: Color(0xFFD4AF37), size: 18),
                          SizedBox(width: 10),
                          Text('Play as Guest', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 15, fontWeight: FontWeight.w700)),
                        ]))),
                    const SizedBox(height: 12),
                    const Text('Guest progress saved locally', textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0x50FFFFFF), fontSize: 9)),
                  ],
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen())),
                    child: const Text('By continuing you agree to our Terms & Privacy Policy',
                      textAlign: TextAlign.center, style: TextStyle(color: Color(0x60FFFFFF), fontSize: 8,
                          decoration: TextDecoration.underline, decorationColor: Color(0x60FFFFFF))),
                  ),
                ]),
              ),
            ),
          )),
        ]),
      ),
    );
  }
}

class _SocialBtn extends StatelessWidget {
  final VoidCallback onTap; final String label, badge; final Color color, bColor;
  const _SocialBtn({required this.onTap,required this.label,required this.badge,required this.color,required this.bColor});
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(14), border: Border.all(color: bColor, width: 1.5)),
      child: Row(children: [
        if (badge.isNotEmpty) ...[
          Container(width: 26, height: 26,
            decoration: BoxDecoration(color: bColor.withOpacity(0.3), borderRadius: BorderRadius.circular(6)),
            child: Center(child: Text(badge, style: TextStyle(color: bColor, fontSize: 13, fontWeight: FontWeight.w900)))),
          const SizedBox(width: 14),
        ],
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      ])));
}

class AvatarPickerScreen extends StatefulWidget {
  final String playerName;
  const AvatarPickerScreen({super.key, required this.playerName});
  @override State<AvatarPickerScreen> createState() => _AvatarPickerScreenState();
}
class _AvatarPickerScreenState extends State<AvatarPickerScreen> {
  int _selected = 0;
  @override Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(
          colors: [Color(0xFF061A04), Color(0xFF0A2608)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Center(child: Container(
          width: 380, padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(color: const Color(0xF00A1A08), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFFD4AF37), width: 2)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('Welcome, ${widget.playerName}!', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text('Pick your avatar', style: TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 24),
            Wrap(spacing: 10, runSpacing: 10, children: List.generate(kAvatarEmojis.length, (i) {
              final sel = _selected == i;
              final col = kAvatarColors[i.clamp(0, kAvatarColors.length-1)];
              return GestureDetector(onTap: () => setState(() => _selected = i),
                child: AnimatedContainer(duration: const Duration(milliseconds: 200),
                  width: sel ? 68 : 58, padding: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(color: sel ? col.withOpacity(0.25) : const Color(0x10FFFFFF),
                    borderRadius: BorderRadius.circular(12), border: Border.all(color: sel ? col : const Color(0x30FFFFFF), width: sel ? 2.5 : 1)),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(kAvatarEmojis[i], style: TextStyle(fontSize: sel ? 26 : 22)),
                    const SizedBox(height: 2),
                    Text(kAvatarLabels[i], style: TextStyle(color: sel ? col : Colors.white38, fontSize: 7, fontWeight: FontWeight.w700)),
                  ])));
            })),
            const SizedBox(height: 28),
            GestureDetector(
              onTap: () { PlayerStorage.setPlayer(widget.playerName, _selected);
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const SplashScreen())); },
              child: Container(width: double.infinity, height: 52,
                decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFE55C), Color(0xFFD4AF37), Color(0xFFA07800)]), borderRadius: BorderRadius.circular(26)),
                child: const Center(child: Text("LET'S PLAY", style: TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 4))))),
          ]),
        )),
      ),
    );
  }
}

// ── Username Screen ───────────────────────────────────────────
class UsernameScreen extends StatefulWidget {
  const UsernameScreen({super.key});
  @override State<UsernameScreen> createState() => _UsernameScreenState();
}

class _UsernameScreenState extends State<UsernameScreen> with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  int _selectedAvatar = 0;
  late AnimationController _animCtrl;
  late Animation<double> _fade;
  String _error = '';

  @override void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn);
    _animCtrl.forward();
  }

  @override void dispose() { _ctrl.dispose(); _animCtrl.dispose(); super.dispose(); }

  void _confirm() {
    final name = _ctrl.text.trim();
    if (name.isEmpty) { setState(() => _error = 'Enter your name to continue'); return; }
    if (name.length < 2) { setState(() => _error = 'Name must be at least 2 characters'); return; }
    PlayerStorage.setPlayer(name, _selectedAvatar);
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (BuildContext _) => const SplashScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3), radius: 1.4,
            colors: [Color(0xFF1E5C14), Color(0xFF0F3A0A), Color(0xFF061A04)],
          ),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: FeltPainter())),
          FadeTransition(opacity: _fade,
            child: Center(child: Container(
              width: 480,
              padding: const EdgeInsets.all(36),
              decoration: BoxDecoration(
                color: const Color(0xEE0A1A08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                boxShadow: const [BoxShadow(color: Color(0x80D4AF37), blurRadius: 30)],
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                // Title
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFD4AF37)],
                  ).createShader(b),
                  child: const Text('WELCOME', style: TextStyle(
                      color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: 6)),
                ),
                const SizedBox(height: 6),
                const Text('Set up your player profile', style: TextStyle(
                    color: Color(0x80D4AF37), fontSize: 12, letterSpacing: 2)),
                const SizedBox(height: 32),

                // Name input
                const Align(alignment: Alignment.centerLeft,
                  child: Text('YOUR NAME', style: TextStyle(
                      color: Color(0xFFD4AF37), fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.w700))),
                const SizedBox(height: 8),
                TextField(
                  controller: _ctrl,
                  maxLength: 16,
                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: 'Enter your name...',
                    hintStyle: const TextStyle(color: Color(0x40FFFFFF)),
                    filled: true,
                    fillColor: const Color(0x20FFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0x60D4AF37)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0x60D4AF37)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => _confirm(),
                ),
                if (_error.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(_error, style: const TextStyle(color: Color(0xFFEF5350), fontSize: 11)),
                ],

                const SizedBox(height: 28),

                // Avatar color picker
                const Align(alignment: Alignment.centerLeft,
                  child: Text('PICK YOUR COLOR', style: TextStyle(
                      color: Color(0xFFD4AF37), fontSize: 10, letterSpacing: 3, fontWeight: FontWeight.w700))),
                const SizedBox(height: 12),
                Row(mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(kAvatarColors.length, (i) {
                    final selected = _selectedAvatar == i;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedAvatar = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: selected ? 46 : 38,
                        height: selected ? 46 : 38,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: kAvatarColors[i],
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? const Color(0xFFFFD700) : Colors.transparent,
                            width: 3),
                          boxShadow: selected ? [BoxShadow(
                            color: kAvatarColors[i].withOpacity(0.7),
                            blurRadius: 14)] : [],
                        ),
                        child: selected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 36),

                // Confirm button
                GestureDetector(
                  onTap: _confirm,
                  child: Container(
                    width: double.infinity, height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE55C), Color(0xFFD4AF37), Color(0xFFA07800)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: const [BoxShadow(color: Color(0xAAD4AF37), blurRadius: 20, offset: Offset(0, 4))],
                    ),
                    child: const Center(child: Text("LET'S PLAY", style: TextStyle(
                        color: Colors.black, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 4))),
                  ),
                ),

                const SizedBox(height: 16),
                const Text('\$1,000 FREE CHIPS WAITING FOR YOU',
                    style: TextStyle(color: Color(0x60D4AF37), fontSize: 9, letterSpacing: 2)),
              ]),
            ))),
        ]),
      ),
    );
  }
}

// ── Daily Bonus Overlay ───────────────────────────────────────
class DailyBonusOverlay extends StatefulWidget {
  final String playerName;
  final int avatarIndex;
  final VoidCallback onClaim;
  const DailyBonusOverlay({super.key, required this.playerName, required this.avatarIndex, required this.onClaim});
  @override State<DailyBonusOverlay> createState() => _DailyBonusOverlayState();
}

class _DailyBonusOverlayState extends State<DailyBonusOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _fade;

  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scale = Tween<double>(begin: 0.7, end: 1.0).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  String _formatCountdown() {
    final d = PlayerStorage.timeUntilNextBonus;
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fade,
      child: Container(
        color: const Color(0xBB000000),
        child: Center(child: ScaleTransition(scale: _scale,
          child: Container(
            width: 340,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A4A10), Color(0xFF0A2008)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
              boxShadow: const [
                BoxShadow(color: Color(0xAAD4AF37), blurRadius: 30),
                BoxShadow(color: Color(0x50D4AF37), blurRadius: 60, spreadRadius: 4),
              ],
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Avatar circle
              Container(
                width: 64, height: 64,
                decoration: BoxDecoration(
                  color: kAvatarColors[widget.avatarIndex],
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                  boxShadow: [BoxShadow(color: kAvatarColors[widget.avatarIndex].withOpacity(0.6), blurRadius: 16)],
                ),
                child: Center(child: Text(
                  kAvatarEmojis[widget.avatarIndex.clamp(0, kAvatarEmojis.length-1)],
                  style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                )),
              ),
              const SizedBox(height: 12),
              Text('Welcome back,', style: const TextStyle(color: Color(0x80D4AF37), fontSize: 11, letterSpacing: 2)),
              Text(widget.playerName, style: const TextStyle(
                  color: Color(0xFFD4AF37), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 1)),
              const SizedBox(height: 24),

              // Bonus amount
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0x20D4AF37),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0x60D4AF37)),
                ),
                child: Column(children: [
                  const Text('DAILY BONUS', style: TextStyle(
                      color: Color(0xFFD4AF37), fontSize: 10, letterSpacing: 4, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFD4AF37)],
                    ).createShader(b),
                    child: Text('+\$${PlayerStorage.bonusStreak >= 7 ? 2000 : PlayerStorage.bonusStreak >= 5 ? 1500 : PlayerStorage.bonusStreak >= 3 ? 1000 : PlayerStorage.bonusStreak >= 2 ? 750 : 500}', style: TextStyle(
                        color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                  ),
                  const Text('FREE CHIPS', style: TextStyle(
color: Color(0x80D4AF37), fontSize: 10, letterSpacing: 3)),
]),
),
const SizedBox(height: 16),
// 7 gold dots streak indicator
Row(mainAxisAlignment: MainAxisAlignment.center, children: [
...List.generate(7, (i) {
final filled = i < PlayerStorage.bonusStreak;
return Container(
margin: const EdgeInsets.symmetric(horizontal: 4),
width: 28, height: 28,
decoration: BoxDecoration(
shape: BoxShape.circle,
color: filled ? const Color(0xFFD4AF37) : const Color(0x20D4AF37),
border: Border.all(
color: filled ? const Color(0xFFFFD700) : const Color(0x40D4AF37),
width: 2),
boxShadow: filled ? [const BoxShadow(
color: Color(0x80D4AF37), blurRadius: 8)] : [],
),
child: filled ? const Icon(Icons.local_fire_department,
color: Colors.black, size: 14) : null,
);
}),
]),
const SizedBox(height: 4),
Text('${PlayerStorage.bonusStreak}/7 day streak',
style: const TextStyle(color: Color(0x80D4AF37), fontSize: 9, letterSpacing: 1)),
const SizedBox(height: 12),
Text('Next bonus in ${_formatCountdown()}',
                  style: const TextStyle(color: Color(0x60FFFFFF), fontSize: 10, letterSpacing: 1)),
              const SizedBox(height: 24),

              // Claim button
              GestureDetector(
                onTap: widget.onClaim,
                child: Container(
                  width: double.infinity, height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE55C), Color(0xFFD4AF37), Color(0xFFA07800)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(26),
                    boxShadow: const [BoxShadow(color: Color(0xAAD4AF37), blurRadius: 16, offset: Offset(0, 4))],
                  ),
                  child: const Center(child: Text('CLAIM BONUS', style: TextStyle(
                      color: Colors.black, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 3))),
                ),
              ),
            ]),
          ),
        )),
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;
  bool _showBonus = false;

  @override void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeIn));
    _scale = Tween<double>(begin: 0.8, end: 1).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 1400), () {
      if (mounted && PlayerStorage.canClaimDailyBonus) setState(() => _showBonus = true);
    });
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  void _claimBonus() {
    PlayerStorage.claimBonus();
    setState(() => _showBonus = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3), radius: 1.4,
            colors: [Color(0xFF1E5C14), Color(0xFF0F3A0A), Color(0xFF061A04)],
          ),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: FeltPainter())),
          Positioned.fill(child: Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFD4AF37), width: 2),
            ),
          )),
          Center(child: FadeTransition(opacity: _fade, child: ScaleTransition(scale: _scale,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Player greeting
              if (PlayerStorage.hasName) ...[
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: kAvatarColors[PlayerStorage.avatarIndex],
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD4AF37), width: 1.5)),
                    child: Center(child: Text(
                      kAvatarEmojis[PlayerStorage.avatarIndex.clamp(0, kAvatarEmojis.length-1)],
                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900))),
                  ),
                  const SizedBox(width: 8),
                  Text('Hey, ${PlayerStorage.playerName}!',
                      style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1)),
                ]),
                const SizedBox(height: 16),
              ],
              const Text('TRIPLE THREAT', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.w400, letterSpacing: 12)),
              const SizedBox(height: 4),
              ShaderMask(
                shaderCallback: (b) => const LinearGradient(
                  colors: [Color(0xFFFFD700), Color(0xFFD4AF37), Color(0xFFB8960C)],
                ).createShader(b),
                child: const Text('BLACKJACK', style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900, letterSpacing: 6)),
              ),
              const SizedBox(height: 4),
              const Text('ARRANGE YOUR DESTINY', style: TextStyle(color: Color(0x80D4AF37), fontSize: 11, letterSpacing: 4)),
              const SizedBox(height: 48),
                Row(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
                Container(width: 40, height: 1, color: const Color(0x60D4AF37)),
                const SizedBox(width: 10),
                suitWidget('S', const Color(0x70FFFFFF), 24),
                const SizedBox(width: 10),
                suitWidget('H', const Color(0x90CC0000), 24),
                const SizedBox(width: 10),
                suitWidget('D', const Color(0x90CC0000), 24),
                const SizedBox(width: 10),
                suitWidget('C', const Color(0x70FFFFFF), 24),
                const SizedBox(width: 10),
                Container(width: 40, height: 1, color: const Color(0x60D4AF37)),
              ]),
              const SizedBox(height: 48),
              GestureDetector(
                onTap: () => Navigator.of(context).pushReplacement(
                  PageRouteBuilder(
                    pageBuilder: (BuildContext ctx, Animation<double> a1, Animation<double> a2) => const GameScreen(),
                    transitionsBuilder: (BuildContext ctx, Animation<double> anim, Animation<double> a2, Widget child) =>
                        FadeTransition(opacity: anim, child: child),
                    transitionDuration: const Duration(milliseconds: 600),
                  ),
                ),
                child: Container(
                  width: 240, height: 60,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFE55C), Color(0xFFD4AF37), Color(0xFFA07800)],
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(color: Color(0xAAD4AF37), blurRadius: 28, offset: Offset(0, 6)),
                    ],
                  ),
                  child: const Center(child: Text('PLAY NOW', style: TextStyle(color: Colors.black, fontSize: 19, fontWeight: FontWeight.w900, letterSpacing: 4))),
                ),
              ),
              const SizedBox(height: 16),
              const Text('\$1,000 FREE CHIPS TO START', style: TextStyle(color: Color(0x70D4AF37), fontSize: 9, letterSpacing: 3, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const Center(child: Text('Triple Threat Blackjack™  •  Patent Pending  •  v1.0.0', style: TextStyle(color: Colors.white24, fontSize: 9))),
            ]),
          ))),
          // Daily bonus overlay
          if (_showBonus) Positioned.fill(child: DailyBonusOverlay(
            playerName: PlayerStorage.playerName,
            avatarIndex: PlayerStorage.avatarIndex,
            onClaim: _claimBonus,
          )),
        ]),
      ),
    );
  }
}

// ── Painters ──────────────────────────────────────────────────
class FeltPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final arc = Paint()..color = const Color(0x07FFFFFF)..strokeWidth = 0.8..style = PaintingStyle.stroke;
    final cx = size.width / 2;
    final cy = size.height * 1.5;
    for (double r = 80; r < size.width * 1.8; r += 45) {
      canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r), -3.14159, 3.14159, false, arc);
    }
  }
  @override bool shouldRepaint(_) => false;
}

// ── Betting Circle Painter ────────────────────────────────────
class BettingCirclePainter extends CustomPainter {
  final bool isActive;
  final bool hasBet;
  BettingCirclePainter({this.isActive = false, this.hasBet = false});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width * 0.44;

    if (isActive) {
      canvas.drawCircle(Offset(cx, cy), r + 3,
        Paint()..color = const Color(0x18FFD700));
    }

    // Outer ring
    canvas.drawCircle(Offset(cx, cy), r,
      Paint()
        ..color = hasBet ? const Color(0xCCD4AF37) : const Color(0x55D4AF37)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke);

    // Inner ring
    canvas.drawCircle(Offset(cx, cy), r * 0.72,
      Paint()
        ..color = hasBet ? const Color(0x70D4AF37) : const Color(0x28D4AF37)
        ..strokeWidth = 0.8
        ..style = PaintingStyle.stroke);

    // Tick marks
    for (int i = 0; i < 24; i++) {
      final angle = i * 2 * pi / 24;
      final inner = i % 2 == 0 ? r * 0.86 : r * 0.92;
      canvas.drawLine(
        Offset(cx + cos(angle) * inner, cy + sin(angle) * inner),
        Offset(cx + cos(angle) * r, cy + sin(angle) * r),
        Paint()
          ..color = hasBet ? const Color(0x99D4AF37) : const Color(0x44D4AF37)
          ..strokeWidth = 1.2
          ..strokeCap = StrokeCap.round,
      );
    }

    // PLACE BET label when empty
    if (!hasBet) {
      final tp = TextPainter(
        text: const TextSpan(text: 'PLACE BET',
          style: TextStyle(color: Color(0x55D4AF37), fontSize: 7,
              fontWeight: FontWeight.w700, letterSpacing: 2)),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(BettingCirclePainter o) =>
      o.isActive != isActive || o.hasBet != hasBet;
}

class CardBackPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = const Color(0xFF0D1B6B));
    final p = Paint()..color = const Color(0x30D4AF37)..strokeWidth = 0.8..style = PaintingStyle.stroke;
    final sp = size.width * 0.35;
    for (double x = -sp; x < size.width + sp; x += sp) {
      for (double y = -sp; y < size.height + sp; y += sp) {
        final path = Path();
        path.moveTo(x + sp / 2, y); path.lineTo(x + sp, y + sp / 2);
        path.lineTo(x + sp / 2, y + sp); path.lineTo(x, y + sp / 2); path.close();
        canvas.drawPath(path, p);
      }
    }
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(4, 4, size.width - 8, size.height - 8), const Radius.circular(4)),
        Paint()..color = const Color(0x80D4AF37)..strokeWidth = 1.5..style = PaintingStyle.stroke);
    final cx = size.width / 2; final cy = size.height / 2; final ds = size.width * 0.18;
    final diamond = Path();
    diamond.moveTo(cx, cy - ds); diamond.lineTo(cx + ds, cy); diamond.lineTo(cx, cy + ds); diamond.lineTo(cx - ds, cy); diamond.close();
    canvas.drawPath(diamond, Paint()..color = const Color(0x60D4AF37)..style = PaintingStyle.fill);
  }
  @override bool shouldRepaint(_) => false;
}

class SuitPainter extends CustomPainter {
  final String suit; final Color color;
  SuitPainter(this.suit, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color..style = PaintingStyle.fill;
    final w = size.width; final h = size.height; final cx = w / 2;
    switch (suit) {
      case 'H':
        final path = Path();
        path.moveTo(cx, h * .88); path.cubicTo(w * -.05, h * .52, w * -.05, h * .08, cx, h * .33);
        path.cubicTo(w * 1.05, h * .08, w * 1.05, h * .52, cx, h * .88);
        canvas.drawPath(path, p); break;
      case 'D':
        final path = Path();
        path.moveTo(cx, 0); path.lineTo(w, h / 2); path.lineTo(cx, h); path.lineTo(0, h / 2); path.close();
        canvas.drawPath(path, p); break;
      case 'S':
        final path = Path();
        path.moveTo(cx, 0); path.cubicTo(w * 1.08, h * .42, w * .68, h * .68, cx, h * .58);
        path.cubicTo(w * .32, h * .68, w * -.08, h * .42, cx, 0);
        canvas.drawPath(path, p);
        final stem = Path();
        stem.moveTo(cx - w * .16, h * .72); stem.quadraticBezierTo(w * .18, h * .94, w * .14, h);
        stem.lineTo(w * .86, h); stem.quadraticBezierTo(w * .82, h * .94, cx + w * .16, h * .72); stem.close();
        canvas.drawPath(stem, p); break;
      case 'C':
        canvas.drawCircle(Offset(cx, h * .32), w * .27, p);
        canvas.drawCircle(Offset(w * .24, h * .58), w * .24, p);
        canvas.drawCircle(Offset(w * .76, h * .58), w * .24, p);
        final stem = Path();
        stem.moveTo(cx - w * .16, h * .74); stem.quadraticBezierTo(w * .18, h * .94, w * .14, h);
        stem.lineTo(w * .86, h); stem.quadraticBezierTo(w * .82, h * .94, cx + w * .16, h * .74); stem.close();
        canvas.drawPath(stem, p); break;
    }
  }
  @override bool shouldRepaint(SuitPainter o) => o.suit != suit || o.color != color;
}

Widget suitWidget(String suit, Color color, double size) =>
    SizedBox(width: size, height: size, child: CustomPaint(painter: SuitPainter(suit, color)));

// ── Card model ────────────────────────────────────────────────
class PlayingCard {
  final String suit, value, id;
  PlayingCard(this.suit, this.value) : id = '${suit}_${value}_${Random().nextDouble()}';
  bool get isRed => suit == 'H' || suit == 'D';
}

int _cardSortKey(PlayingCard c) {
  switch (c.value) {
    case 'A': return 14; case 'K': return 13; case 'Q': return 12; case 'J': return 11;
    default: return int.parse(c.value);
  }
}

List<PlayingCard> createDeck() {
  const suits = ['S', 'H', 'D', 'C'];
  const values = ['A', '2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K'];
  final deck = <PlayingCard>[];
  for (int d = 0; d < 7; d++)
    for (final s in suits)
      for (final v in values)
        deck.add(PlayingCard(s, v));
  deck.shuffle();
  return deck;
}

int handValue(List<PlayingCard> hand) {
  int total = 0, aces = 0;
  for (final c in hand) {
    if (c.value == 'A') { total += 11; aces++; }
    else if (['J', 'Q', 'K'].contains(c.value)) total += 10;
    else total += int.parse(c.value);
  }
  while (total > 21 && aces > 0) { total -= 10; aces--; }
  return total;
}

String valueBadge(List<PlayingCard> hand) {
  if (hand.isEmpty) return '';
  final v = handValue(hand);
  if (v > 21) return 'BUST';
  return '$v';
}

bool canSplit(List<PlayingCard> hand) => hand.length == 2 && hand[0].value == hand[1].value;

// ── Chips ─────────────────────────────────────────────────────
Color chipColor(int amount) {
  if (amount <= 1) return const Color(0xFFBDBDBD);    // grey
  if (amount <= 10) return const Color(0xFFD32F2F);   // red
  if (amount <= 50) return const Color(0xFF2E7D32);   // green
  if (amount <= 200) return const Color(0xFF1565C0);  // blue
  if (amount <= 500) return const Color(0xFF6A1B9A);  // purple
  if (amount <= 1000) return const Color(0xFFE65100); // orange
  return const Color(0xFFB8860C);                      // gold
}

List<int> _chipDenoms(int amount) {
  const denoms = [500, 100, 25, 5, 1];
  final result = <int>[];
  int rem = amount;
  for (final d in denoms) {
    if (rem <= 0) break;
    final count = (rem ~/ d).clamp(0, 5 - result.length);
    for (int i = 0; i < count; i++) result.add(d);
    rem -= count * d;
    if (result.length >= 5) break;
  }
  return result;
}

class ChipPainter extends CustomPainter {
  final Color color;
  ChipPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);
    final c = Color(color.value | 0xFF000000);
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFFFFFFFF)..style = PaintingStyle.fill);
    canvas.drawCircle(center, r, Paint()..color = c..style = PaintingStyle.fill);
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFFFFFFFF)..style = PaintingStyle.stroke..strokeWidth = 2.5);
    canvas.drawCircle(center, r * 0.78, Paint()..color = const Color(0xFFFFFFFF)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    for (int i = 0; i < 12; i++) {
      final a = i * pi / 6;
      canvas.drawLine(Offset(center.dx + cos(a) * r * 0.84, center.dy + sin(a) * r * 0.84),
          Offset(center.dx + cos(a) * r * 0.97, center.dy + sin(a) * r * 0.97),
          Paint()..color = const Color(0xFFFFFFFF)..strokeWidth = 2.5..strokeCap = StrokeCap.round);
    }
    canvas.drawCircle(Offset(r, r * 0.6), r * 0.4, Paint()..color = const Color(0x25FFFFFF)..style = PaintingStyle.fill);
  }
  @override bool shouldRepaint(ChipPainter o) => o.color != color;
}

// Single-canvas stacked chip painter — no bleed-through
class StackedChipsPainter extends CustomPainter {
  final List<int> denoms;
  final double chipSize;
  final String label;
  StackedChipsPainter(this.denoms, this.chipSize, this.label);

  void _drawOneChip(Canvas canvas, Offset center, double r, Color color) {
    final c = Color(color.value | 0xFF000000);
    // White base first — blocks anything underneath
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFFFFFFFF)..style = PaintingStyle.fill);
    canvas.drawCircle(center, r, Paint()..color = c..style = PaintingStyle.fill);
    canvas.drawCircle(center, r, Paint()..color = const Color(0xFFFFFFFF)..style = PaintingStyle.stroke..strokeWidth = 2.5);
    canvas.drawCircle(center, r * 0.78, Paint()..color = const Color(0xFFFFFFFF)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    for (int j = 0; j < 12; j++) {
      final a = j * pi / 6;
      canvas.drawLine(
        Offset(center.dx + cos(a) * r * 0.84, center.dy + sin(a) * r * 0.84),
        Offset(center.dx + cos(a) * r * 0.97, center.dy + sin(a) * r * 0.97),
        Paint()..color = const Color(0xFFFFFFFF)..strokeWidth = 2.0..strokeCap = StrokeCap.round);
    }
    canvas.drawCircle(Offset(center.dx, center.dy - r * 0.28), r * 0.38,
        Paint()..color = const Color(0x20FFFFFF)..style = PaintingStyle.fill);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final r = chipSize / 2;
    final stagger = chipSize * 0.28;
    // Draw bottom chip first (index 0 = largest denom), each one stagger pixels higher
    for (int i = 0; i < denoms.length; i++) {
      final center = Offset(r, size.height - r - i * stagger);
      _drawOneChip(canvas, center, r, chipColor(denoms[i]));
    }
    // Label on top chip (highest = last index)
    final topY = size.height - r - (denoms.length - 1) * stagger;
    final tp = TextPainter(
      text: TextSpan(text: label, style: TextStyle(
        color: denoms.last == 1 ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
        fontWeight: FontWeight.w900, fontSize: chipSize * 0.22,
        shadows: const [Shadow(color: Color(0xFF000000), blurRadius: 3)],
      )),
      textDirection: TextDirection.ltr,
    );
    tp.layout();
    tp.paint(canvas, Offset(r - tp.width / 2, topY - tp.height / 2));
  }

  @override bool shouldRepaint(StackedChipsPainter o) => o.denoms.toString() != denoms.toString();
}

Widget chipWidget(int amount, double size, {String? label}) {
  if (amount <= 0) return SizedBox(width: size, height: size);
  final displayLabel = label ?? fmtMoney(amount);
  // Color based on total amount, not individual denom
  final color = chipColor(amount);
  final isDark = amount <= 1;

  return SizedBox(
    width: size, height: size,
    child: Stack(alignment: Alignment.center, children: [
      CustomPaint(size: Size(size, size), painter: ChipPainter(color)),
      Text(
        displayLabel,
        style: TextStyle(
          color: isDark ? Colors.black87 : Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: amount >= 1000 ? size * 0.17 : size * 0.22,
          shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
        ),
      ),
    ]),
  );
}

Widget _singleChip(int denom, double size, {String? label, bool labelDark = false}) {
  return SizedBox(
    width: size, height: size,
    child: Stack(alignment: Alignment.center, children: [
      CustomPaint(size: Size(size, size), painter: ChipPainter(chipColor(denom))),
      if (label != null) Text(label,
        style: TextStyle(
          color: labelDark ? Colors.black87 : Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: size * 0.22,
          shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
        )),
    ]),
  );
}


// ── Animated card ─────────────────────────────────────────────
class AnimCard extends StatefulWidget {
  final PlayingCard card;
  final bool faceDown, animate;
  final double w, h;
  const AnimCard({super.key, required this.card, this.faceDown = false, this.animate = false, this.w = 56, this.h = 78});
  @override State<AnimCard> createState() => _AnimCardState();
}

class _AnimCardState extends State<AnimCard> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade, _scale;
  @override void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 320));
    _fade = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeOut));
    _scale = Tween<double>(begin: 0.6, end: 1).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutBack));
    if (widget.animate) Future.delayed(const Duration(milliseconds: 20), () { if (mounted) _c.forward(); });
    else _c.value = 1.0;
  }
  @override void dispose() { _c.dispose(); super.dispose(); }
  @override Widget build(BuildContext context) => FadeTransition(opacity: _fade, child: ScaleTransition(scale: _scale, child: _buildCard()));

  Widget _buildCard() {
    if (widget.faceDown) {
      return Container(width: widget.w, height: widget.h,
        decoration: BoxDecoration(
          gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: [Color(0xFF0D1B6B), Color(0xFF1A3399), Color(0xFF0D1B6B)]),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0xAA000000), blurRadius: 8, offset: Offset(2, 4))]),
        child: ClipRRect(borderRadius: BorderRadius.circular(6),
            child: CustomPaint(size: Size(widget.w, widget.h), painter: CardBackPainter())));
    }
    final color = widget.card.isRed ? const Color(0xFFCC0000) : const Color(0xFF111111);
    final is10 = widget.card.value == '10';
    final valSize = widget.w > 50 ? (is10 ? 12.0 : 15.0) : widget.w > 36 ? (is10 ? 9.0 : 11.0) : (is10 ? 7.5 : 9.0);
    final suitSm = widget.w > 50 ? 12.0 : widget.w > 36 ? 9.0 : 7.5;
    final suitLg = widget.w > 50 ? 26.0 : widget.w > 36 ? 18.0 : 14.0;
    return Container(width: widget.w, height: widget.h,
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFCCCCCC)),
          boxShadow: const [BoxShadow(color: Color(0xAA000000), blurRadius: 6, offset: Offset(2, 4))]),
      child: Stack(children: [
        Positioned(top: 3, left: 4, child: SizedBox(width: widget.w * 0.5, child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Text(widget.card.value, style: TextStyle(fontSize: valSize, fontWeight: FontWeight.w900, color: color, height: 1.0)),
          suitWidget(widget.card.suit, color, suitSm),
        ]))),
        Center(child: suitWidget(widget.card.suit, color, suitLg)),
        Positioned(bottom: 3, right: 4, child: Transform.rotate(angle: pi,
          child: SizedBox(width: widget.w * 0.5, child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Text(widget.card.value, style: TextStyle(fontSize: valSize, fontWeight: FontWeight.w900, color: color, height: 1.0)),
            suitWidget(widget.card.suit, color, suitSm),
          ])))),
      ]));
  }
}

// ── Side odds ─────────────────────────────────────────────────
class SideOdds { final String name; final int pays; const SideOdds(this.name, this.pays); }
const List<SideOdds> sideOddsList = [
  SideOdds('All Six Aces',500000),SideOdds('6-Card Str. Flush',50000),SideOdds('Six of a Kind',40000),
  SideOdds('Five of a Kind',500),SideOdds('3x BJ Setup',300),SideOdds('Two Sets of Trips',250),
  SideOdds('6-Card Flush',200), SideOdds('6-Card Straight',150),SideOdds('Full House',50),
  SideOdds('All Six Tens',40),SideOdds('5-Card Flush',25),SideOdds('5-Card Straight',20),
  SideOdds('Three Pairs',12),SideOdds('All Six Low (A-6)',6),
];
bool _isStraight(List<int> rn) {
final s=[...rn.toSet()]..sort();
if(s.length!=rn.length)return false;
// Normal straight
bool ok=true;
for(int i=1;i<s.length;i++){if(s[i]!=s[i-1]+1){ok=false;break;}}
if(ok)return true;
// Ace-high straight (A=0, treat as 13)
if(s[0]==0){
final s2=[...s.skip(1),13]..sort();
bool ok2=true;
for(int i=1;i<s2.length;i++){if(s2[i]!=s2[i-1]+1){ok2=false;break;}}
if(ok2)return true;
}
return false;
}

bool _isFlush(List<PlayingCard> cards){
final s=cards[0].suit;
return cards.every((c)=>c.suit==s);
}

bool _isStraightCards(List<PlayingCard> cards){
const vals=['A','2','3','4','5','6','7','8','9','10','J','Q','K'];
final rn=cards.map((c)=>vals.indexOf(c.value)).toList();
return _isStraight(rn);
}

bool _isFullHouse(List<PlayingCard> cards){
final m=<String,int>{};
for(final c in cards)m[c.value]=(m[c.value]??0)+1;
final v=m.values.toList()..sort((a,b)=>b.compareTo(a));
return v.length==2&&v[0]==3&&v[1]==2;
}

bool _any5(List<PlayingCard> cards, bool Function(List<PlayingCard>) test){
for(int skip=0;skip<cards.length;skip++){
final sub=[for(int i=0;i<cards.length;i++)if(i!=skip)cards[i]];
if(test(sub))return true;
}
return false;
}

SideOdds? evalSideBet(List<PlayingCard> cards) {
if(cards.length<6)return null;
const vals=['A','2','3','4','5','6','7','8','9','10','J','Q','K'];
final ranks=cards.map((c)=>c.value).toList();

// Rank counts
final rc=<String,int>{};
for(final r in ranks)rc[r]=(rc[r]??0)+1;
final counts=rc.values.toList()..sort((a,b)=>b.compareTo(a));

// Suit counts
final sc=<String,int>{};
for(final c in cards)sc[c.suit]=(sc[c.suit]??0)+1;
final isFlush6=sc.length==1;
final isStraight6=_isStraightCards(cards);

// All Six Aces
if(counts[0]==6&&ranks[0]=='A')return sideOddsList[0];
// 6-Card Straight Flush
if(isStraight6&&isFlush6)return sideOddsList[1];
// Six of a Kind
if(counts[0]==6)return sideOddsList[2];
// Five of a Kind
if(counts[0]==5)return sideOddsList[3];
// 3x BJ Setup
final aC=ranks.where((r)=>r=='A').length;
final tC=ranks.where((r)=>['10','J','Q','K'].contains(r)).length;
if(aC==3&&tC==3)return sideOddsList[4];
// Two Sets of Trips
if(counts.length>=2&&counts[0]==3&&counts[1]==3)return sideOddsList[5];
// 6-Card Flush
if(isFlush6)return sideOddsList[6];
// 6-Card Straight
if(isStraight6)return sideOddsList[7];
// All Six Tens
if(ranks.every((r)=>['10','J','Q','K'].contains(r)))return sideOddsList[9];
// Three Pairs
if(counts.length==3&&counts[0]==2&&counts[1]==2&&counts[2]==2)return sideOddsList[12];
// 5-Card Straight Flush (any 5)
if(_any5(cards,(sub)=>_isStraightCards(sub)&&_isFlush(sub)))return sideOddsList[1];
// 5-Card Flush (any 5)
if(_any5(cards,(sub)=>_isFlush(sub)))return sideOddsList[10];
// Full House (any 5)
if(_any5(cards,(sub)=>_isFullHouse(sub)))return sideOddsList[8];
// 5-Card Straight (any 5)
if(_any5(cards,(sub)=>_isStraightCards(sub)))return sideOddsList[11];
// All Six Low A-6
if(ranks.every((r)=>['A','2','3','4','5','6'].contains(r)))return sideOddsList[13];
return null;
}

enum Phase { bet, dealing, arrange, play, dealerTurn, result }

String fmtMoney(int n) {
  if (n >= 1000000) return '\$${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) { final s = n.toString(); return '\$${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}'; }
  return '\$$n';
}

// ── Game Screen ───────────────────────────────────────────────
class GameScreen extends StatefulWidget {
  final int? tournamentBalance;
  final Function(int)? onBalanceUpdate;
  const GameScreen({super.key, this.tournamentBalance, this.onBalanceUpdate});
  @override State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  Phase phase = Phase.bet;
  List<PlayingCard> deck = [], pool6 = [], dealer = [];
  List<List<List<PlayingCard>>> hands = [[], [], []];
  List<List<int>> handBets = [[], [], []];
  int activeSlot = 0, activeSubHand = 0;
  int balance = 0, bet = 0, sideBet = 0, winStreak = 0;
  int _totalRounds = 0, _totalWins = 0, _totalLosses = 0, _totalPushes = 0;
  int _biggestWin = 0, _bestStreak = 0, _totalWagered = 0, _totalProfit = 0;
  List<bool> doubleUsed = [false, false, false];
  List<List<String?>> results = [[], [], []];
  int? profit;
  SideOdds? sideWin;
  int nextHand = 0;
  bool showOdds = false, offeringInsurance = false, tookInsurance = false;
  int insuranceBet = 0;
  String message = '';
  int selChip = 25, usedCardCount = 0;
  List<PlayingCard> _shoe = [];
  int _lastBet = 0, _lastMainBet = 0, _lastSideBet = 0;
  bool _betOnMain = true, _bettingOnSide = false;
  Timer? msgTimer;
  Set<String> animCards = {};
  List<bool> splitFromAces = [false, false, false];
  bool showChipStore = false;
  bool _adWatching = false;
  int _adWatchCount = 0;
  int _lastBalancePopup = 9999;

  @override
  void initState() {
    super.initState();
    if (widget.tournamentBalance != null) {
      // Tournament mode — use fixed starting chips
      balance = widget.tournamentBalance!;
    } else {
      // Normal mode — load saved balance
      final bonus = PlayerStorage.collectPendingBonus();
      final saved = PlayerStorage.savedChips;
      balance = saved > 0 ? saved + bonus : 1000 + bonus;
      if (bonus > 0) PlayerStorage.saveChips(balance);
    }
    // Load persistent stats
    _totalRounds = PlayerStorage.statRounds;
    _totalWins = PlayerStorage.statWins;
    _totalLosses = PlayerStorage.statLosses;
    _totalPushes = PlayerStorage.statPushes;
    _biggestWin = PlayerStorage.statBiggestWin;
    _bestStreak = PlayerStorage.statBestStreak;
    _totalWagered = PlayerStorage.statWagered;
    _totalProfit = PlayerStorage.statProfit;
    _initShoe();
  }

  void _initShoe() {
_shoe = createDeck();
_shoe = _shoe.sublist(35);
setState(() => usedCardCount = 0);
}

bool get hideHole => phase == Phase.dealing || phase == Phase.arrange || phase == Phase.play;

  void showMsg(String msg) {
    setState(() => message = msg);
    msgTimer?.cancel();
    msgTimer = Timer(const Duration(milliseconds: 3000), () { if (mounted) setState(() => message = ''); });
  }
  void _applyLastBet(){
    if (_lastMainBet > 0 && balance >= _lastMainBet * 3 + sideBet) {
      setState(() => bet = _lastMainBet);
      SoundEngine.chipPlace();
    }
  }

  void deal() {
    if (balance <= 0) { setState(() => showChipStore = true); return; }
    final maxBet = getVipTier(PlayerStorage.level.level).maxBet;
    if (bet > maxBet) {
      showMsg('Max bet for your VIP tier is ${fmtMoney(maxBet)}');
      setState(() => bet = maxBet);
      return;
    }
    final total = bet * 3 + sideBet;
    if (balance < total) { showMsg('Not enough chips! Adjust your bet.'); return; }
    if (bet < 1) { showMsg('Place a bet first!'); return; }
    if (_shoe.length < 52) { _initShoe(); setState(() => usedCardCount = 0); }
final rp = _shoe.sublist(0, 6);
_shoe = _shoe.sublist(6);
rp.sort((a, b) => _cardSortKey(b).compareTo(_cardSortKey(a)));
final dc = _shoe.sublist(0, 2);
_shoe = _shoe.sublist(2);
setState(() {
pool6 = rp; dealer = dc; deck = _shoe;

      hands = [[], [], []]; handBets = [[bet], [bet], [bet]];
      activeSlot = 0; activeSubHand = 0;
      doubleUsed = [false, false, false];
      results = [[], [], []]; profit = null; sideWin = null;
      nextHand = 0; balance -= total; phase = Phase.dealing;
      animCards = {}; splitFromAces = [false, false, false];
      offeringInsurance = false; tookInsurance = false; insuranceBet = 0;
    });
    int delay = 0;
    for (final c in [...dc, ...rp]) {
      delay += 180;
      Future.delayed(Duration(milliseconds: delay), () {
        if (mounted) {
          setState(() => animCards.add(c.id));
          SoundEngine.deal();
        }
      });
    }
    Future.delayed(Duration(milliseconds: delay + 350), () {
      if (mounted) setState(() => phase = Phase.arrange);
      showMsg('Arrange your cards — tap to place');
    });
  }

  void tapPool(PlayingCard card) {
    if (phase != Phase.arrange) return;
    int target = -1;
    for (int i = nextHand; i < 3; i++) { if (hands[i].isEmpty || (hands[i].isNotEmpty && hands[i][0].length < 2)) { target = i; break; } }
    if (target == -1) for (int j = 0; j < 3; j++) { if (hands[j].isEmpty || (hands[j].isNotEmpty && hands[j][0].length < 2)) { target = j; break; } }
    if (target == -1) { showMsg('All hands full!'); return; }
    if (!pool6.any((c) => c.id == card.id)) return;
    SoundEngine.deal();
    setState(() {
      if (hands[target].isEmpty) hands[target] = [[card]];
      else hands[target][0] = [...hands[target][0], card];
      pool6 = pool6.where((c) => c.id != card.id).toList();
      if (hands[target][0].length >= 2) { int nn = target + 1; nextHand = nn > 2 ? 2 : nn; }
      else nextHand = target;
    });
  }

  void recall(int slot, int cardIdx) {
    if (phase != Phase.arrange) return;
    if (hands[slot].isEmpty || hands[slot][0].length <= cardIdx) return;
    final removed = hands[slot][0][cardIdx];
    setState(() {
      hands[slot][0].removeAt(cardIdx);
      if (hands[slot][0].isEmpty) hands[slot] = [];
      final np = [...pool6, removed];
      np.sort((a, b) => _cardSortKey(b).compareTo(_cardSortKey(a)));
      pool6 = np; nextHand = slot < nextHand ? slot : nextHand;
    });
  }

  void confirmArrange() {
if (hands.any((h) => h.isEmpty || h[0].length != 2)) { showMsg('Each hand needs 2 cards!'); return; }
if (sideBet > 0) {
    final all6 = [...hands[0][0], ...hands[1][0], ...hands[2][0]];
final sw = evalSideBet(all6); setState(() => sideWin = sw);
}   
    setState(() { phase = Phase.play; activeSlot = 0; activeSubHand = 0; });
    Future.delayed(const Duration(milliseconds: 100), _checkFor21);
    if (dealer.isNotEmpty && dealer[0].value == 'A') {
      setState(() => offeringInsurance = true);
      showMsg('Dealer shows Ace — Insurance?');
    } else {
      showMsg('Hand 1 — make your move');
    }
  }

  void _checkFor21() {
if (handValue(currentHand) >= 21) {
Future.delayed(const Duration(milliseconds: 600), advanceHand);
}
}

void takeInsurance() {
    final cost = (bet * 3) ~/ 2;
    if (balance < cost) { showMsg('Not enough for insurance!'); return; }
    setState(() { tookInsurance = true; insuranceBet = cost; balance -= cost; offeringInsurance = false; });
showMsg('Insurance taken');
Future.delayed(const Duration(milliseconds: 800), () {
if (mounted) _checkDealerBlackjack();
});
}

  void declineInsurance() {
setState(() => offeringInsurance = false);
_checkDealerBlackjack();
}

void _checkDealerBlackjack() {
if (dealer.length >= 2 && handValue(dealer) == 21) {
// Dealer has blackjack — reveal and finish immediately
setState(() => phase = Phase.dealerTurn);
Future.delayed(const Duration(milliseconds: 600), () {
if (mounted) finishRound(dealer);
});
} else {
showMsg('Hand 1 — make your move');
}
}

  List<PlayingCard> get currentHand => hands[activeSlot][activeSubHand];

  void doHit() {
    if (deck.isEmpty) return;
    final c = deck.first;
    SoundEngine.deal();
    setState(() { deck = deck.sublist(1); hands[activeSlot][activeSubHand] = [...currentHand, c]; animCards.add(c.id); });
    if (handValue(currentHand) >= 21) Future.delayed(const Duration(milliseconds: 600), advanceHand);
  }

  void doStand() => advanceHand();

  void doDouble() {
    final cb = handBets[activeSlot][activeSubHand];
    if (doubleUsed[activeSlot] || balance < cb) { showMsg('Cannot double!'); return; }
    if (deck.isEmpty) return;
    final c = deck.first;
    setState(() {
      deck = deck.sublist(1);
      hands[activeSlot][activeSubHand] = [...currentHand, c];
      balance -= cb; handBets[activeSlot][activeSubHand] = cb * 2;
      doubleUsed[activeSlot] = true; animCards.add(c.id);
    });
    advanceHand();
  }

  void doSplit() {
    if (!canSplit(currentHand)) { showMsg('Cannot split!'); return; }
    final cb = handBets[activeSlot][activeSubHand];
    if (balance < cb) { showMsg('Not enough to split!'); return; }
    if (deck.length < 2) return;
    final c1 = deck[0]; final c2 = deck[1];
    final card1 = currentHand[0]; final card2 = currentHand[1];
    final isAce = card1.value == 'A';
    setState(() {
      deck = deck.sublist(2);
      hands[activeSlot] = [[card1, c1], [card2, c2]];
      handBets[activeSlot] = [cb, cb]; balance -= cb;
      animCards.addAll([c1.id, c2.id]);
      if (isAce) splitFromAces[activeSlot] = true;
    });
    if (isAce) {
      showMsg('Split Aces — auto-standing both hands!');
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() => activeSubHand = 1);
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          advanceHand();
        });
      });
    } else showMsg('Split! Playing sub-hand 1');
  }

  void advanceHand() {
    if (activeSubHand + 1 < hands[activeSlot].length) {
      setState(() => activeSubHand = activeSubHand + 1);
      showMsg('H${activeSlot + 1} — 2nd hand, make your move');
      return;
    }
    for (int s = activeSlot + 1; s < 3; s++) {
      if (hands[s].isNotEmpty) {
        setState(() { activeSlot = s; activeSubHand = 0; });
        showMsg('Hand ${s + 1} — make your move');
        Future.delayed(const Duration(milliseconds: 100), _checkFor21);
        return;
      }
    }
    setState(() => phase = Phase.dealerTurn);
    runDealer();
  }
   bool _isSoftSeventeen(List<PlayingCard> hand) {
  int total = 0, aces = 0;
  for (final c in hand) {
    if (c.value == 'A') { total += 11; aces++; }
    else if (['J', 'Q', 'K'].contains(c.value)) total += 10;
    else total += int.parse(c.value);
  }
  while (total > 21 && aces > 0) { total -= 10; aces--; }
  return total == 17 && aces > 0;
}
  void runDealer() {
    var dd = [...dealer]; var rem = [...deck];
    SoundEngine.deal(); // hole card reveal
    void step() {
      if ((handValue(dd) < 17 || _isSoftSeventeen(dd))  && rem.isNotEmpty) {
        final nc = rem.first; dd = [...dd, nc]; rem = rem.sublist(1);
        setState(() { dealer = dd; deck = rem; animCards.add(nc.id); });
        SoundEngine.deal();
        Future.delayed(const Duration(milliseconds: 700), step);
      } else finishRound(dd);
    }
    Future.delayed(const Duration(milliseconds: 800), step);
  }

  void finishRound(List<PlayingCard> dc) {
    final dv = handValue(dc); final bust = dv > 21;
    int pay = 0;
    if (tookInsurance && dv == 21 && dc.length == 2) pay += insuranceBet * 2;
    final res = List.generate(3, (slot) => List.generate(hands[slot].length, (sub) {
      final h = hands[slot][sub]; final v = handValue(h); final hBet = handBets[slot][sub];
      if (v > 21) return 'bust';
      if (bust || v > dv) { pay += hBet * 2; return 'win'; }
      if (v == dv) { return 'lose'; }
      return 'lose';
    }));
    int wins = res.fold(0, (s, r) => s + r.where((x) => x == 'win').length);
    int losses = res.fold(0, (s, r) => s + r.where((x) => x == 'lose' || x == 'bust').length);
    int pushes = res.fold(0, (s, r) => s + r.where((x) => x == 'push').length);
    if (wins == 3) pay += (bet * 15) ~/ 10; else if (wins == 2) pay += (bet ~/ 2);
        if (sideBet > 0 && sideWin != null) pay += sideBet * sideWin!.pays;
    final totalBet = handBets.fold(0, (s, hb) => s + hb.fold(0, (a, b) => a + b))
        + sideBet + (tookInsurance ? insuranceBet : 0);
    final roundProfit = pay - totalBet;
    setState(() {
      results = res; profit = roundProfit; balance += pay; dealer = dc; phase = Phase.result;
      usedCardCount += dealer.length + hands.fold(0, (s, h) => s + h.fold(0, (a, c) => a + c.length));
      _shoe = deck;
      if (wins > 0) { winStreak++; if (winStreak > _bestStreak) _bestStreak = winStreak; }
      else winStreak = 0;
      _lastBet = bet;
      _lastMainBet = bet;
      _lastSideBet = sideBet;
      _totalRounds++;
      _totalWins += wins;
      _totalLosses += losses;
      _totalPushes += pushes;
      _totalWagered += totalBet;
      _totalProfit += roundProfit;
      if (roundProfit > _biggestWin) _biggestWin = roundProfit;
    });
    if (widget.tournamentBalance == null) PlayerStorage.saveChips(balance);
    widget.onBalanceUpdate?.call(balance);
    if (widget.tournamentBalance == null && !showChipStore && balance < 100 && _lastBalancePopup >= 100) {
      _lastBalancePopup = 100;
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted && !showChipStore) setState(() => showChipStore = true);
      });
    } else if (balance >= 300) { _lastBalancePopup = 9999; }
    // Update daily challenges
    if (widget.tournamentBalance == null) {
      final hadBust = results.any((r) => r.any((x) => x == 'bust'));
      final newlyChallenges = ChallengeManager.updateProgress(
        winsThisRound: wins, currentStreak: winStreak,
        tripleWin: wins == 3, sideHit: sideWin != null,
        hadBust: hadBust, totalBet: totalBet, wonRound: wins > 0,
      );
      if (newlyChallenges.isNotEmpty) {
        final chal = ChallengeManager.todayChallenges
            .firstWhere((c) => c.def.id == newlyChallenges.first);
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) showMsg('🎯 Challenge Complete: ${chal.def.title}!');
        });
      }
    }
    PlayerStorage.saveStats(
      rounds: _totalRounds, wins: _totalWins, losses: _totalLosses,
      pushes: _totalPushes, biggestWin: _biggestWin, bestStreak: _bestStreak,
      wagered: _totalWagered, profit: _totalProfit,
    );
    // Award XP
    final xpEarned = calcXP(
      wins: wins, totalHands: wins + losses + pushes,
      streak: winStreak, sideHit: sideWin != null,
      tripleWin: wins == 3,
    );
    PlayerStorage.addXP(xpEarned);
    // Check badges
    final newBadges = PlayerStorage.checkAndAwardBadges(
      totalRounds: _totalRounds, totalWins: _totalWins,
      bestStreak: _bestStreak, justWon: wins > 0,
      tripleWin: wins == 3, sideHit: sideWin != null,
      wasBroke: balance <= 0, comeback: balance > 100 && _totalProfit < -1500,
      bigSpender: totalBet >= 500, balance: balance,
      handsWonThisRound: wins,
      enteredTournament: false,
      wonTournament: false,
      totalSideBetsSession: sideWin != null ? 1 : 0,
      totalWagered: _totalWagered,
    );
    // Show badge notification if earned
    if (newBadges.isNotEmpty) {
      SoundEngine.badgeUnlock();
      final badge = kBadges.firstWhere((b) => b.id == newBadges.first,
          orElse: () => const Badge('', '', '', '🏆'));
      Future.delayed(const Duration(milliseconds: 800), () {
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext ctx) => Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1A3A10), Color(0xFF0A1A08)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                  boxShadow: const [BoxShadow(color: Color(0x80D4AF37), blurRadius: 20)]),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(badge.emoji, style: const TextStyle(fontSize: 52)),
                  const SizedBox(height: 8),
                  const Text('BADGE UNLOCKED!', style: TextStyle(
                      color: Color(0xFFD4AF37), fontSize: 12,
                      fontWeight: FontWeight.w900, letterSpacing: 3)),
                  const SizedBox(height: 6),
                  Text(badge.name, style: const TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 4),
                  Text(badge.description, textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white60, fontSize: 11)),
                  const SizedBox(height: 16),
                  ShareHelper.shareBtn(ctx, ShareHelper.badgeEarned(badge),
                      label: 'SHARE THIS ACHIEVEMENT'),
                  const SizedBox(height: 10),
                  GestureDetector(
                    onTap: () => Navigator.pop(ctx),
                    child: const Text('CONTINUE', style: TextStyle(
                        color: Color(0x80D4AF37), fontSize: 11, letterSpacing: 2)),
                  ),
                ]),
              ),
            ),
          );
        }
      });
    }
    PlayerStorage.submitScore(
      name: PlayerStorage.playerName,
      avatarIndex: PlayerStorage.avatarIndex,
      balance: balance,
      rounds: _totalRounds,
      wins: _totalWins,
      netProfit: _totalProfit,
      bestStreak: _bestStreak,
      biggestWin: _biggestWin,
    );
    final _msgSeed = DateTime.now().millisecond;
const _tripleMsgs = ['TRIPLE WIN! BONUS!','ALL THREE! UNSTOPPABLE!','TRIPLE THREAT ACTIVATED!','CLEAN SWEEP! BONUS PAID!','ALL HANDS WIN! LEGEND!'];
const _doubleMsgs = ['DOUBLE WIN!','TWO FOR THREE!','DOUBLE UP!','TWO HANDS WIN!','NICE DOUBLE!'];
const _lossMsgs = ['Dealer wins.','House takes it.','Better luck next hand.','Dealer wins this one.','The house always wins... sometimes.'];
const _singleMsgs = ['Won a hand!','One hand wins!','Keep it going!','One down, more to come!','Single hand win!'];
if (wins == 3) { SoundEngine.tripleWin(); showMsg(_tripleMsgs[_msgSeed % _tripleMsgs.length]); }
else if (wins == 2) { SoundEngine.win(); showMsg(_doubleMsgs[_msgSeed % _doubleMsgs.length]); }
else if (wins == 0) { SoundEngine.lose(); showMsg(_lossMsgs[_msgSeed % _lossMsgs.length]); }
else { SoundEngine.win(); showMsg(_singleMsgs[_msgSeed % _singleMsgs.length]); }
    if (sideWin != null) SoundEngine.sideBetHit();
  }

  void newRound() {
setState(() {
phase = Phase.bet; pool6 = []; hands = [[], [], []]; dealer = [];
results = [[], [], []]; profit = null; sideWin = null;
message = ''; nextHand = 0; animCards = {};
// Restore last bets
bet = _lastMainBet > 0 ? _lastMainBet : 0;
sideBet = _lastSideBet > 0 ? _lastSideBet : 0;
// Auto-correct if balance can't cover it
if (bet * 3 + sideBet > balance) {
bet = 0; sideBet = 0;
}
handBets = [[bet], [bet], [bet]]; doubleUsed = [false, false, false];
offeringInsurance = false; tookInsurance = false; insuranceBet = 0;
});
}

  void _showMenuOverlay() {
    showDialog(
      context: context,
      barrierColor: const Color(0xBB000000),
      builder: (BuildContext ctx) { return Center(
        child: SizedBox(
          height: 620,
          child: Container(
          width: 280,          
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0A1A08), Color(0xFF061208)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFD4AF37), width: 2),
            boxShadow: const [BoxShadow(color: Color(0x80D4AF37), blurRadius: 20)]),
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.center, children: [
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFD4AF37)]).createShader(b),
              child: const Text('MENU', style: TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 4)),
            ),
            const SizedBox(height: 24),
            _menuBtn(Icons.people, 'FRIENDS', () {
              Navigator.pop(ctx);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext _) => const FriendsScreen()));
            }),
            const SizedBox(height: 12),
            _menuBtn(Icons.task_alt, 'CHALLENGES  ${ChallengeManager.claimedCount < ChallengeManager.completedCount ? "🔴" : ""}', () {
              Navigator.pop(ctx);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext _) => ChallengesScreen(
                  onChipsEarned: (int chips) => setState(() => balance += chips),
                )));
            }),
            const SizedBox(height: 12),
            _menuBtn(Icons.military_tech, 'BADGES', () {
Navigator.pop(ctx);
Navigator.of(context).push(MaterialPageRoute(
builder: (BuildContext _) => const BadgesScreen()));
}),
const SizedBox(height: 12),
_menuBtn(Icons.diamond, 'VIP STATUS', () {
Navigator.pop(ctx);
Navigator.of(context).push(MaterialPageRoute(
builder: (BuildContext _) => const VipScreen()));
}),
const SizedBox(height: 12),
_menuBtn(Icons.timer, 'TOURNAMENT', () {
              Navigator.pop(ctx);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext _) => TournamentLobbyScreen(
                  playerBalance: balance,
                  onChipsChanged: (int chips) => setState(() => balance = chips),
                )));
            }),
            const SizedBox(height: 12),
            _menuBtn(Icons.bar_chart, 'STATS', () {
              Navigator.pop(ctx);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext _) => StatsScreen(
                  playerName: PlayerStorage.playerName,
                  avatarIndex: PlayerStorage.avatarIndex,
                  balance: balance,
                  totalRounds: _totalRounds,
                  totalWins: _totalWins,
                  totalLosses: _totalLosses,
                  totalPushes: _totalPushes,
                  biggestWin: _biggestWin,
                  bestStreak: _bestStreak,
                  totalWagered: _totalWagered,
                  totalProfit: _totalProfit,
                  winStreak: winStreak,
                )));
            }),
            const SizedBox(height: 12),
            _menuBtn(Icons.emoji_events, 'LEADERBOARD', () {
              Navigator.pop(ctx);
              Navigator.of(context).push(MaterialPageRoute(
                builder: (BuildContext _) => const LeaderboardScreen()));
            }),
            const SizedBox(height: 12),
            _menuBtn(Icons.help_outline, 'HOW TO PLAY', () {
  Navigator.pop(ctx);
  Navigator.of(context).push(MaterialPageRoute(
    builder: (BuildContext _) => const HowToPlayScreen()));
}),
const SizedBox(height: 12),
_menuBtn(Icons.settings, 'SETTINGS', () {
  Navigator.pop(ctx);
  Navigator.of(context).push(MaterialPageRoute(
    builder: (BuildContext _) => const SettingsScreen(),
  )).then((dynamic _) => setState(() {}));
}),
const SizedBox(height: 12),
              _menuBtn(Icons.home, 'MAIN MENU', () {
              PlayerStorage.saveChips(balance);
              PlayerStorage.submitScore(
                name: PlayerStorage.playerName,
                avatarIndex: PlayerStorage.avatarIndex,
                balance: balance,
                rounds: _totalRounds,
                wins: _totalWins,
                netProfit: _totalProfit,
                bestStreak: _bestStreak,
                biggestWin: _biggestWin,
              );
              Navigator.pop(ctx);
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (BuildContext _) => const SplashScreen()));
            }),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: const Text('BACK TO GAME', style: TextStyle(
                  color: Color(0x60D4AF37), fontSize: 10, letterSpacing: 2))),
          ]),
          ),
          ),
        ),
      ); },
    );
   }

  Widget _menuBtn(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0x20D4AF37),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x40D4AF37))),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: const Color(0xFFD4AF37), size: 16),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(
              color: Colors.white, fontSize: 14,
              fontWeight: FontWeight.w800, letterSpacing: 2)),
        ]),
      ),
    );
  }

  Widget _anim(PlayingCard c, {bool fd = false, double w = 56, double h = 78}) =>
      AnimCard(key: ValueKey(c.id), card: c, faceDown: fd, animate: animCards.contains(c.id), w: w, h: h);

  @override
  Widget build(BuildContext context) {
    final theme = AppSettings.theme;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.2), radius: 1.3,
            colors: theme.tableGradient),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: FeltPainter())),
          SafeArea(child: Column(children: [
            _topBar(),
            Expanded(child: _mainTable()),
            _bottomPanel(),
          ])),
          if (message.isNotEmpty) _toast(),
          if (showOdds) _oddsOverlay(),
          if (showChipStore) _chipStoreOverlay(),
          if (phase == Phase.result && profit != null)
            Positioned.fill(child: _ResultOverlay(
              profit: profit!,
              results: results,
              sideWin: sideWin,
              sideBet: sideBet,
              winStreak: winStreak,
              onNewDeal: newRound,
            )),
        ]),
      ),
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xCC000000), Color(0x00000000)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter)),
      child: Row(children: [
        _usedPile(),
        const SizedBox(width: 8),
        if (winStreak >= 2) Container(
padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
decoration: BoxDecoration(
gradient: const LinearGradient(colors: [Color(0xFFFF6B00), Color(0xFFFF9500)]),
borderRadius: BorderRadius.circular(8)),
child: Text('🔥$winStreak', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900))),
const SizedBox(width: 6),
        GestureDetector(
          onTap: () => _showMenuOverlay(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: const Color(0x40000000),
                borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0x40D4AF37))),
            child: const Text('MENU', style: TextStyle(color: Color(0xAAD4AF37), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
          ),
        ),
        
        // Level + VIP + XP bar
        Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: PlayerStorage.level.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: PlayerStorage.level.color.withOpacity(0.6))),
              child: Text('LVL ${PlayerStorage.level.level}  ${PlayerStorage.level.title}',
                  style: TextStyle(color: PlayerStorage.level.color,
                      fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
            ),
            const SizedBox(width: 4),
            Text(getVipTier(PlayerStorage.level.level).emoji,
                style: const TextStyle(fontSize: 12)),
          ]),
          const SizedBox(height: 3),
          SizedBox(width: 90, height: 4,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: getLevelProgress(PlayerStorage.xp),
                backgroundColor: const Color(0x30FFFFFF),
                valueColor: AlwaysStoppedAnimation<Color>(PlayerStorage.level.color),
              ),
            ),
          ),
          Text('${PlayerStorage.xp} XP', style: const TextStyle(
              color: Color(0x60FFFFFF), fontSize: 7, letterSpacing: 1)),
        ]),
        
          FittedBox(fit: BoxFit.scaleDown, child: Text(fmtMoney(balance), style: TextStyle(
              color: balance < 100 ? const Color(0xFFEF5350) : balance < 300 ? const Color(0xFFFFC107) : Colors.white,
              fontSize: balance >= 100000 ? 14 : balance >= 10000 ? 17 : 22, fontWeight: FontWeight.w900))),
          if (balance < 300) GestureDetector(
            onTap: () => setState(() => showChipStore = true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                  color: balance < 100 ? const Color(0xFFEF5350) : const Color(0xFFE65100),
                  borderRadius: BorderRadius.circular(6)),
              child: Text(balance < 100 ? '⚠ DANGER -ADD CHIPS NOW' : 'ADD CHIPS',
                  style: const TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.w800, letterSpacing: 1)))),
        
      ]),
    );
  }

  Widget _usedPile() {
    return SizedBox(width: 40, height: 38,
      child: Stack(children: [
        for (int i = 0; i < min(3, usedCardCount ~/ 6 + 1); i++)
          Positioned(left: i * 3.0, top: i * 1.5,
            child: Container(width: 28, height: 38,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A237E), Color(0xFF283593)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF5C6BC0), width: 1)))),
        if (usedCardCount > 0) Positioned(bottom: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
            decoration: BoxDecoration(color: Colors.black87, borderRadius: BorderRadius.circular(3)),
            child: Text('$usedCardCount', style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 7, fontWeight: FontWeight.w800)))),
      ]));
  }

  Widget _mainTable() {
    final dv = dealer.isNotEmpty ? handValue(dealer) : 0;
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 4, 10, 4),
      decoration: BoxDecoration(color: const Color(0x15000000),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x60D4AF37), width: 1)),
      child: Column(children: [
        _dealerZone(dv),
        Stack(alignment: Alignment.center, children: [
          Container(height: 1, margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: const BoxDecoration(gradient: LinearGradient(
                colors: [Color(0x00D4AF37), Color(0xFFD4AF37), Color(0x00D4AF37)]))),
          Container(width: 10, height: 10,
            decoration: const BoxDecoration(color: Color(0xFFD4AF37),
                boxShadow: [BoxShadow(color: Color(0xAAD4AF37), blurRadius: 10)]),
            transform: Matrix4.rotationZ(0.785)),
        ]),
        Expanded(child: Row(children: List.generate(3, (i) => Expanded(child: _playerPanel(i))))),
        // Side bet win banner on table
        if (phase == Phase.result && sideWin != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0x007B1FA2), Color(0xDD7B1FA2), Color(0x007B1FA2)]),
              border: const Border(
                top: BorderSide(color: Color(0x60CE93D8), width: 1),
                bottom: BorderSide(color: Color(0x60CE93D8), width: 1)),
            ),
            child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              const Icon(Icons.stars, color: Color(0xFFCE93D8), size: 14),
              const SizedBox(width: 8),
              const Text('SIDE BET  ', style: TextStyle(
                  color: Color(0xFFCE93D8), fontSize: 10,
                  fontWeight: FontWeight.w700, letterSpacing: 2)),
              Text(sideWin!.name, style: const TextStyle(
                  color: Colors.white70, fontSize: 10)),
              const Text('  •  ', style: TextStyle(color: Color(0x60CE93D8))),
              Text('+${fmtMoney(sideBet * sideWin!.pays)}',
                  style: const TextStyle(
                      color: Color(0xFFE040FB), fontSize: 14,
                      fontWeight: FontWeight.w900)),
              const SizedBox(width: 8),
              const Icon(Icons.stars, color: Color(0xFFCE93D8), size: 14),
            ]),
          ),
      ]),
    );
  }

  Widget _dealerZone(int dv) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 50, height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0x00D4AF37), Color(0xFFD4AF37)]))),
          suitWidget('S', const Color(0x40D4AF37), 10),
          const Padding(padding: EdgeInsets.symmetric(horizontal: 10),
            child: Text('D E A L E R', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 9, letterSpacing: 6, fontWeight: FontWeight.w700))),
          suitWidget('C', const Color(0x40D4AF37), 10),
          Container(width: 50, height: 1, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFD4AF37), Color(0x00D4AF37)]))),
        ]),
        const SizedBox(height: 6),
        if (phase != Phase.bet)
          Row(mainAxisAlignment: MainAxisAlignment.center,
            children: dealer.asMap().entries.map((e) =>
              Padding(padding: EdgeInsets.symmetric(horizontal: dealer.length >= 5 ? 2 : 5),
child: SizedBox(width: dealer.length >= 5 ? 36 : dealer.length >= 4 ? 44 : 54, height: dealer.length >= 5 ? 50 : dealer.length >= 4 ? 62 : 76,
child: _anim(e.value, fd: e.key == 1 && hideHole,
w: dealer.length >= 5 ? 36 : dealer.length >= 4 ? 44 : 54,
h: dealer.length >= 5 ? 50 : dealer.length >= 4 ? 62 : 76)))).toList()),
        const SizedBox(height: 2),
        if ((phase == Phase.result || phase == Phase.dealerTurn) && dealer.isNotEmpty)
          _valBadge(dv > 21 ? 'BUST' : '$dv', bust: dv > 21),
      ]),
    );
  }

  Widget _playerPanel(int slot) {
    final subHands = hands[slot];
    final isActive = phase == Phase.play && activeSlot == slot;
    final r = results[slot];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        border: Border(
          left: slot > 0 ? const BorderSide(color: Color(0x25D4AF37), width: 1) : BorderSide.none,
          right: slot < 2 ? const BorderSide(color: Color(0x25D4AF37), width: 1) : BorderSide.none),
        color: isActive ? const Color(0x12FFD700) : Colors.transparent),
      child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
        if (isActive) Container(
          margin: const EdgeInsets.only(bottom: 3),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(color: const Color(0xFFFFD700), borderRadius: BorderRadius.circular(6)),
          child: const Text('YOUR TURN', style: TextStyle(color: Colors.black, fontSize: 7, fontWeight: FontWeight.w900, letterSpacing: 1.5))),
        if (r.isNotEmpty && r.any((x) => x != null))
          Padding(padding: const EdgeInsets.only(bottom: 3),
            child: Wrap(alignment: WrapAlignment.center, spacing: 3,
              children: r.map((res) => _resultBadge(res ?? '')).toList())),
        if (subHands.isEmpty && (phase == Phase.arrange || phase == Phase.dealing))
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [_ghost(), const SizedBox(width: 6), _ghost()]),
        if (subHands.isNotEmpty)
          ...subHands.asMap().entries.map((e) {
            final sub = e.key; final h = e.value;
            final isActSub = isActive && activeSubHand == sub;
            final badge = valueBadge(h);
            final isSplit = subHands.length > 1;
            final cw = isSplit ? 26.0 : 34.0;
            final ch = isSplit ? 36.0 : 48.0;
            return Container(
              margin: EdgeInsets.symmetric(vertical: isSplit ? 0 : 1),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: isActSub ? const Color(0xFFFFD700) : Colors.transparent, width: 2)),
              child: Column(children: [
                Wrap(alignment: WrapAlignment.center, spacing: 2, runSpacing: 2, children: [
                  ...h.asMap().entries.map((ce) => GestureDetector(
                    onTap: () => recall(slot, ce.key),
                    child: SizedBox(width: cw, height: ch, child: _anim(ce.value, w: cw, h: ch)))),
                  if (phase == Phase.arrange || phase == Phase.dealing)
                    ...List.generate(2 - h.length, (_) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: SizedBox(width: cw, height: ch,
                        child: Container(decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: const Color(0x70D4AF37), width: 1.5),
                          color: const Color(0x08D4AF37)))))),
                ]),
                if (h.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 1),
                  child: _valBadge(badge, bust: badge == 'BUST')),
              ]));
          }),
        const SizedBox(height: 2),
        // Betting circle - hidden when split to prevent overflow
        if (subHands.length <= 1)
        GestureDetector(
          onTap: phase == Phase.bet ? () { setState(() { if (balance >= (bet + selChip) * 3 + sideBet) { bet += selChip; SoundEngine.chipPlace(); } }); } : null,
          child: SizedBox(
            width: 64, height: 64,
            child: Stack(alignment: Alignment.center, children: [
              CustomPaint(
                size: const Size(64, 64),
                painter: BettingCirclePainter(
                  isActive: phase == Phase.bet,
                  hasBet: bet > 0,
                ),
              ),
              if (bet > 0) chipWidget(bet, 40),
            ]),
          ),
        ),
        if (subHands.length <= 1) ...[
          const SizedBox(height: 2),
          Text('MIN \$1 • MAX \$500', style: const TextStyle(
              color: Color(0x40D4AF37), fontSize: 6, letterSpacing: 1, fontWeight: FontWeight.w600)),
          const SizedBox(height: 1),
        ],
        Text('H${slot + 1}', style: TextStyle(
            color: isActive ? const Color(0xFFFFD700) : const Color(0x80D4AF37),
            fontSize: 9, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
      ]),
    );
  }

  Widget _ghost() => Container(width: 32, height: 46,
decoration: BoxDecoration(borderRadius: BorderRadius.circular(7),
border: Border.all(color: const Color(0x70D4AF37), width: 1.5), color: const Color(0x08D4AF37)),
child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
suitWidget('D', const Color(0x25D4AF37), 12),
const SizedBox(height: 2),
const Text('TAP', style: TextStyle(color: Color(0x40D4AF37), fontSize: 6, fontWeight: FontWeight.w700, letterSpacing: 1)),
])));

  Widget _valBadge(String text, {bool bust = false}) {
    Color bg = const Color(0xAA000000); Color border = const Color(0x50FFFFFF);
    if (bust || text == 'BUST') { bg = const Color(0xDDC62828); border = const Color(0xFFEF5350); }
    if (text == '21') { bg = const Color(0xDDB8860C); border = const Color(0xFFFFD700); }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10),
          border: Border.all(color: border, width: 1.5),
          boxShadow: [BoxShadow(color: border.withOpacity(0.4), blurRadius: 6)]),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)));
  }

  Widget _resultBadge(String r) {
    Color bg = const Color(0xFFFFC107); Color border = const Color(0xFFFFD700);
    if (r == 'win') { bg = const Color(0xFF2E7D32); border = const Color(0xFF4CAF50); }
    if (r == 'lose' || r == 'bust') { bg = const Color(0xFF8B0000); border = const Color(0xFFEF5350); }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border, width: 1.5),
          boxShadow: [BoxShadow(color: border.withOpacity(0.4), blurRadius: 6)]),
      child: Text(r.toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 9, letterSpacing: 0.5)));
  }

  Widget _bottomPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xCC000000), Color(0xEE000000)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter),
        border: Border(top: BorderSide(color: Color(0x60D4AF37), width: 1))),
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 16),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        if (phase == Phase.bet) _betPhase(),
        if (phase == Phase.dealing) const Center(child: Padding(padding: EdgeInsets.symmetric(vertical: 10),
          child: Text('Dealing cards...', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: 1)))),
        if (phase == Phase.arrange) _arrangePhase(),
        if (phase == Phase.play && offeringInsurance) _insurancePanel(),
        if (phase == Phase.play && !offeringInsurance) _playPhase(),
        if (phase == Phase.dealerTurn) Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(color: Color(0xFFD4AF37), strokeWidth: 2)),
            const SizedBox(width: 12),
            const Text('Dealer drawing...', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.w700)),
          ]))),
        if (phase == Phase.result) const SizedBox.shrink(),
      ]),
    );
  }

  Widget _betPhase() {
  final isMain = !_bettingOnSide;
  return Column(children: [
    Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: const Color(0x20D4AF37),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0x40D4AF37))),
        child: Column(children: [
          const Text('BET × 3', style: TextStyle(color: Color(0xFFD4AF37),
              fontSize: 7, letterSpacing: 2, fontWeight: FontWeight.w700)),
          Text(fmtMoney(bet * 3), style: TextStyle(
              color: bet > 0 ? Colors.white : Colors.white38,
              fontSize: 17, fontWeight: FontWeight.w900)),
        ])),
      const SizedBox(width: 6),
      GestureDetector(
        onTap: () => setState(() => showOdds = true),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: const Color(0x206A1B9A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x806A1B9A))),
          child: Column(children: [
            const Text('SIDE BET', style: TextStyle(color: Color(0xFFCE93D8),
                fontSize: 7, letterSpacing: 2, fontWeight: FontWeight.w700)),
            Text(fmtMoney(sideBet), style: TextStyle(
                color: sideBet > 0 ? const Color(0xFFE040FB) : Colors.white38,
                fontSize: 17, fontWeight: FontWeight.w900)),
          ]))),
      const Spacer(),
      _dealButton(),
      const SizedBox(width: 4),
      GestureDetector(
        onTap: () => setState(() => showChipStore = true),
        child: Container(
          height: 46, width: 38,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF1565C0), Color(0xFF0D47A1)]),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x60FFFFFF), width: 1)),
          child: const Column(mainAxisAlignment: MainAxisAlignment.center,
              children: [
            Text('+', style: TextStyle(color: Colors.white,
                fontSize: 16, fontWeight: FontWeight.w900, height: 1)),
            Text('CHIPS', style: TextStyle(color: Colors.white70,
                fontSize: 6, fontWeight: FontWeight.w700)),
          ]))),
    ]),
    const SizedBox(height: 8),
    Row(children: [
      Expanded(child: GestureDetector(
        onTap: () => setState(() => _bettingOnSide = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: isMain ? const LinearGradient(
                colors: [Color(0xFFD4AF37), Color(0xFFA07800)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
            color: isMain ? null : const Color(0x15FFFFFF),
            borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10), bottomLeft: Radius.circular(10)),
            border: Border.all(
                color: isMain ? const Color(0xFFD4AF37) : const Color(0x40FFFFFF))),
          child: Center(child: Text('MAIN BET', style: TextStyle(
              color: isMain ? Colors.black : Colors.white54,
              fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)))))),
      Expanded(child: GestureDetector(
        onTap: () => setState(() => _bettingOnSide = true),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            gradient: !isMain ? const LinearGradient(
                colors: [Color(0xFF9C27B0), Color(0xFF6A1B9A)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter) : null,
            color: !isMain ? null : const Color(0x15FFFFFF),
            borderRadius: const BorderRadius.only(
                topRight: Radius.circular(10), bottomRight: Radius.circular(10)),
            border: Border.all(
                color: !isMain ? const Color(0xFFCE93D8) : const Color(0x40FFFFFF))),
          child: Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text('SIDE BET', style: TextStyle(
                color: !isMain ? Colors.white : Colors.white54,
                fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)),
            if (sideBet > 0) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(color: const Color(0x40E040FB),
                    borderRadius: BorderRadius.circular(4)),
                child: Text(fmtMoney(sideBet), style: const TextStyle(
                    color: Color(0xFFE040FB), fontSize: 8,
                    fontWeight: FontWeight.w900))),
            ],
          ]))))),
      const SizedBox(width: 6),
      GestureDetector(
        onTap: () => setState(() {
          if (_bettingOnSide) sideBet = 0; else bet = 0;
        }),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          decoration: BoxDecoration(color: const Color(0x40000000),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x40FFFFFF))),
          child: const Text('CLR', style: TextStyle(
              color: Colors.grey, fontWeight: FontWeight.w700, fontSize: 11)))),
    ]),
    const SizedBox(height: 8),
    Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [1, 5, 25, 100, 500].map((v) {
        final selected = isMain && selChip == v;
        return GestureDetector(
          onTap: () {
            SoundEngine.chipPlace();
            if (_bettingOnSide) {
              setState(() {
                if (balance >= bet * 3 + sideBet + v) sideBet += v;
              });
            } else {
              setState(() {
                selChip = v;
                if (balance >= (bet + v) * 3 + sideBet) bet += v;
              });
            }
          },
          child: Stack(alignment: Alignment.center, children: [
            SizedBox(width: 50, height: 50,
                child: CustomPaint(painter: ChipPainter(chipColor(v)))),
            if (selected) Container(width: 50, height: 50,
              decoration: BoxDecoration(shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD700), width: 3),
                boxShadow: const [BoxShadow(
                    color: Color(0xAAFFD700), blurRadius: 12)])),
            Text('\$$v', style: TextStyle(
                color: v == 1 ? Colors.black87 : Colors.white,
                fontWeight: FontWeight.w900, fontSize: 10,
                shadows: const [Shadow(color: Colors.black, blurRadius: 3)])),
          ]));
      }).toList()),
  ]);
}

  Widget _arrangePhase() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(color: const Color(0xFFD4AF37), borderRadius: BorderRadius.circular(8)),
          child: Text('H${nextHand + 1}', style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12))),
        const SizedBox(width: 6),
        const Text('Tap to place  |  Tap to recall', style: TextStyle(color: Color(0xAAFFFFFF), fontSize: 9)),
        const Spacer(),
        GestureDetector(onTap: confirmArrange,
          child: Container(width: 88, height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF43A047), Color(0xFF1B5E20)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter),
              borderRadius: BorderRadius.circular(22),
              boxShadow: const [BoxShadow(color: Color(0x6043A047), blurRadius: 12)],
              border: Border.all(color: const Color(0x8081C784), width: 1)),
            child: const Center(child: Text('CONFIRM', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2))))),
      ]),
      const SizedBox(height: 8),
      SizedBox(height: 86, child: ListView(scrollDirection: Axis.horizontal, children: [
        ...pool6.map((c) => GestureDetector(onTap: () => tapPool(c),
          child: Padding(padding: const EdgeInsets.only(right: 8),
            child: SizedBox(width: 60, height: 84, child: _anim(c, w: 60, h: 84))))),
        if (pool6.isEmpty) Center(child: Container(
padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
child: Column(mainAxisSize: MainAxisSize.min, children: [
const Text('✓', style: TextStyle(color: Color(0xFF4CAF50), fontSize: 18)),
const Text('ALL PLACED', style: TextStyle(color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
]))),
      ])),
    ]);
  }

  Widget _insurancePanel() {
    return Column(children: [
      Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Color(0xFFFFD700), size: 20),
        const SizedBox(width: 8),
        const Text('DEALER SHOWS ACE', style: TextStyle(color: Color(0xFFFFD700), fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 1)),
      ]),
      const SizedBox(height: 4),
      Text('Insurance pays 2:1 • Cost: \$${(bet * 3) ~/ 2}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _bigBtn('DECLINE', declineInsurance, const Color(0xFF8B0000), Colors.white)),
        const SizedBox(width: 10),
        Expanded(child: _bigBtn('TAKE INSURANCE', takeInsurance, const Color(0xFF1B8030), Colors.white)),
      ]),
    ]);
  }

  Widget _playPhase() {
    final hv = currentHand.isNotEmpty ? handValue(currentHand) : 0;
    final splitOk = currentHand.length == 2 && hands[activeSlot].length == 1 &&
        canSplit(currentHand) && balance >= handBets[activeSlot][activeSubHand];
    final dblOk = !doubleUsed[activeSlot] && currentHand.length == 2 &&
        hands[activeSlot].length == 1 && balance >= handBets[activeSlot][activeSubHand];
    return Column(children: [
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text('HAND ${activeSlot + 1}${hands[activeSlot].length > 1 ? " · ${activeSubHand + 1}" : ""}',
            style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w700, fontSize: 12, letterSpacing: 2)),
        const SizedBox(width: 12),
        Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(color: const Color(0xAA000000), borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x50D4AF37))),
          child: Text('$hv', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 22))),
      ]),
      const SizedBox(height: 10),
      if (handValue(currentHand) >=21)
        const SizedBox.shrink()
      else if (splitFromAces[activeSlot])
        Row(children: [Expanded(child: _actionTab('STAND', const Color(0xFFB71C1C), doStand))])
      else
        Row(children: [
          Expanded(child: _actionTab('STAND', const Color(0xFFB71C1C), doStand)),
          const SizedBox(width: 6),
          if (splitOk) ...[Expanded(child: _actionTab('SPLIT', const Color(0xFFE65100), doSplit)), const SizedBox(width: 6)],
          if (dblOk) ...[Expanded(child: _actionTab('DOUBLE', const Color(0xFF6A1B9A), doDouble)), const SizedBox(width: 6)],
          Expanded(child: _actionTab('HIT', const Color(0xFF1B5E20), doHit)),
        ]),
    ]);
  }

  Widget _resultPhase() {
    final won = profit != null && profit! > 0;
    final lost = profit != null && profit! < 0;
    return Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      if (profit != null) Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: won
            ? [const Color(0xFF1B8030), const Color(0xFF0D4018)]
            : lost ? [const Color(0xFF8B0000), const Color(0xFF4A0000)]
            : [const Color(0xFF4A4A00), const Color(0xFF2A2A00)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: won ? const Color(0xFF4CAF50) : lost ? const Color(0xFFEF5350) : const Color(0xFFFFD700),
              width: 1.5)),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(won ? 'YOU WIN' : lost ? 'HOUSE WINS' : 'PUSH',
              style: TextStyle(color: won ? const Color(0xFF81C784) : lost ? const Color(0xFFEF9A9A) : const Color(0xFFFFD700),
                  fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 2)),
          Text(won ? '+${fmtMoney(profit!)}' : lost ? '-${fmtMoney(profit!.abs())}' : fmtMoney(profit!),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 26)),
          if (winStreak >= 2) Row(mainAxisSize: MainAxisSize.min, children: [
            const Text('🔥', style: TextStyle(fontSize: 10)),
            Text(' $winStreak streak', style: const TextStyle(color: Color(0xFFFF9500), fontSize: 9, fontWeight: FontWeight.w700)),
          ]),
        ])),
      if (sideWin != null) ...[
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)],
              begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFCE93D8), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0xAA7B1FA2), blurRadius: 20),
              BoxShadow(color: Color(0x607B1FA2), blurRadius: 40, spreadRadius: 2),
            ]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.stars, color: Color(0xFFCE93D8), size: 12),
              const SizedBox(width: 4),
              const Text('SIDE BET HIT!', style: TextStyle(
                  color: Color(0xFFCE93D8), fontSize: 9,
                  fontWeight: FontWeight.w800, letterSpacing: 1.5)),
            ]),
            const SizedBox(height: 2),
            Text(sideWin!.name, style: const TextStyle(
                color: Colors.white70, fontSize: 8, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFE040FB), Color(0xFFCE93D8)],
              ).createShader(b),
              child: Text('+${fmtMoney(sideBet * sideWin!.pays)}',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)),
            ),
            Text('${sideWin!.pays}:1 odds',
                style: const TextStyle(color: Color(0x80CE93D8), fontSize: 8)),
          ])),
      ],
      const SizedBox(width: 12),
      GestureDetector(onTap: newRound,
        child: Container(height: 52, width: 150,
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFFFE55C), Color(0xFFD4AF37), Color(0xFFA07800)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(26),
            boxShadow: const [BoxShadow(color: Color(0xAAD4AF37), blurRadius: 16, offset: Offset(0, 4))]),
          child: const Center(child: Text('NEW DEAL', style: TextStyle(color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2))))),
    ]);
  }

  Widget _chipBtn(int value, bool selected, VoidCallback onTap) {
    return GestureDetector(onTap: onTap,
      child: Stack(alignment: Alignment.center, children: [
        SizedBox(width: 46, height: 46, child: CustomPaint(painter: ChipPainter(chipColor(value)))),
        if (selected) Container(width: 46, height: 46,
          decoration: BoxDecoration(shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFD700), width: 3),
            boxShadow: const [BoxShadow(color: Color(0xAAFFD700), blurRadius: 12)])),
        Text('\$$value', style: TextStyle(color: value == 1 ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.w900, fontSize: 10, shadows: const [Shadow(color: Colors.black, blurRadius: 3)])),
      ]));
  }

  Widget _actionTab(String label, Color color, VoidCallback onTap) {
    IconData icon = Icons.pan_tool;
    if (label == 'HIT') icon = Icons.add_circle_outline;
    if (label == 'STAND') icon = Icons.back_hand_outlined;
    if (label == 'DOUBLE') icon = Icons.keyboard_double_arrow_up;
    if (label == 'SPLIT') icon = Icons.call_split;
    return GestureDetector(onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24, width: 1),
          boxShadow: [BoxShadow(color: color.withOpacity(0.5), blurRadius: 10, offset: const Offset(0, 4))]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, color: Colors.white, size: 18),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5)),
        ])));
  }

  Widget _dealButton() {
    return GestureDetector(onTap: deal,
      child: Container(width: 130, height: 48,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFFFFE55C), Color(0xFFD4AF37), Color(0xFFA07800)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter),
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [BoxShadow(color: Color(0xAAD4AF37), blurRadius: 20, offset: Offset(0, 4))],
          border: Border.all(color: const Color(0xFFFFE082), width: 1)),
        child: const Center(child: Text('DEAL', style: TextStyle(color: Colors.black, fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 4)))));
  }

  Widget _bigBtn(String label, VoidCallback onTap, Color bg, Color fg, {double? width}) {
    return GestureDetector(onTap: onTap,
      child: Container(width: width,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: bg.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
        child: Center(child: Text(label, style: TextStyle(color: fg, fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 2)))));
  }

  Widget _chipStoreOverlay() {
    final pkgs = [
      {'chips': 500, 'price': 'FREE', 'color': const Color(0xFF2E7D32), 'label': 'Starter'},
      {'chips': 800, 'price': '\$0.99', 'color': const Color(0xFF1565C0), 'label': 'Popular'},
      {'chips': 2000, 'price': '\$1.99', 'color': const Color(0xFF6A1B9A), 'label': 'Value'},
      {'chips': 6000, 'price': '\$4.99', 'color': const Color(0xFFB8860C), 'label': 'High Roller'},
    ];

    final rows = pkgs.map<Widget>((pkg) {
      final color = pkg['color'] as Color;
      final chips = pkg['chips'] as int;
      final price = pkg['price'] as String;
      final lbl = pkg['label'] as String;
      return GestureDetector(
        onTap: () {
          setState(() { balance += chips; showChipStore = false; });
          showMsg('Added \$$chips chips!');
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0x60FFFFFF), width: 1),
          ),
          child: Row(
            children: [
              Stack(alignment: Alignment.center, children: [
                SizedBox(width: 44, height: 44, child: CustomPaint(painter: ChipPainter(color))),
                Text(chips >= 1000 ? '+${chips ~/ 1000}K' : '+$chips',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900)),
              ]),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(lbl, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
                Text('+$chips chips', style: const TextStyle(color: Colors.white70, fontSize: 10)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                child: Text(price, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12)),
              ),
            ],
          ),
        ),
      );
    }).toList();

    return GestureDetector(
      onTap: () => setState(() => showChipStore = false),
      child: Container(
        color: const Color(0xEE000000),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0A2010), Color(0xFF061408)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                boxShadow: const [BoxShadow(color: Color(0x80D4AF37), blurRadius: 20)],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('CHIP STORE', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 3)),
                  const SizedBox(height: 4),
                  Text('Balance: ${fmtMoney(balance)}', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                  const SizedBox(height: 16),
                  ...rows,
                  const SizedBox(height: 8),
                  const Text('TAP ANYWHERE TO CLOSE', style: TextStyle(color: Color(0x50FFFFFF), fontSize: 9, letterSpacing: 2)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toast() => Positioned(bottom: 160, left: 60, right: 60,
    child: Center(child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xF0000000), borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFD4AF37), width: 1.5),
          boxShadow: const [BoxShadow(color: Color(0x60D4AF37), blurRadius: 14)]),
      child: Text(message, textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)))));

  Widget _oddsOverlay() => GestureDetector(
    onTap: () => setState(() => showOdds = false),
    child: Container(color: const Color(0xF0000000),
      child: Center(child: Container(
        margin: const EdgeInsets.all(24), padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: const Color(0xFF0A2010), borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD4AF37), width: 2),
            boxShadow: const [BoxShadow(color: Color(0x80D4AF37), blurRadius: 20)]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('SIDE BET PAYS', style: TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w900, fontSize: 15, letterSpacing: 2)),
          const SizedBox(height: 2),
          const Text('Based on all 6 of your cards', style: TextStyle(color: Color(0x80FFFFFF), fontSize: 9)),
          const SizedBox(height: 14),
          ...sideOddsList.map((o) => Padding(padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(o.name, style: const TextStyle(color: Colors.white, fontSize: 12)),
              Text('${o.pays} to 1', style: const TextStyle(color: Color(0xFFD4AF37), fontWeight: FontWeight.w700, fontSize: 12)),
            ]))),
          const SizedBox(height: 14),
          const Text('TAP ANYWHERE TO CLOSE', style: TextStyle(color: Color(0x60FFFFFF), fontSize: 9, letterSpacing: 2)),
        ]),
      ))));
}

// ── Stats Screen ──────────────────────────────────────────────
Widget _statChip(String label, Color color) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
  decoration: BoxDecoration(color: color.withOpacity(0.25),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: color.withOpacity(0.6))),
  child: Text(label, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)));

class StatsScreen extends StatelessWidget {
  final String playerName;
  final int avatarIndex, balance, totalRounds, totalWins, totalLosses;
  final int totalPushes, biggestWin, bestStreak, totalWagered, totalProfit, winStreak;

  const StatsScreen({super.key,
    required this.playerName, required this.avatarIndex, required this.balance,
    required this.totalRounds, required this.totalWins, required this.totalLosses,
    required this.totalPushes, required this.biggestWin, required this.bestStreak,
    required this.totalWagered, required this.totalProfit, required this.winStreak,
  });

  @override
  Widget build(BuildContext context) {
    final totalHands = totalWins + totalLosses + totalPushes;
    final winRate = totalHands > 0 ? (totalWins / totalHands * 100).toStringAsFixed(1) : '—';
    final isUp = totalProfit >= 0;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3), radius: 1.4,
            colors: [Color(0xFF1E5C14), Color(0xFF0F3A0A), Color(0xFF061A04)],
          ),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: FeltPainter())),
          SafeArea(child: Column(children: [

            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xCC000000), Color(0x00000000)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0x40000000),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x40D4AF37))),
                    child: const Row(children: [
                      Icon(Icons.arrow_back_ios, color: Color(0xAAD4AF37), size: 12),
                      SizedBox(width: 4),
                      Text('BACK', style: TextStyle(color: Color(0xAAD4AF37), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ]),
                  ),
                ),
                const Spacer(),
                // Player badge
                Row(children: [
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: kAvatarColors[avatarIndex], shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD4AF37), width: 2),
                      boxShadow: [BoxShadow(color: kAvatarColors[avatarIndex].withOpacity(0.5), blurRadius: 10)]),
                    child: Center(child: Text(
                      kAvatarEmojis[avatarIndex.clamp(0, kAvatarEmojis.length-1)],
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900))),
                  ),
                  const SizedBox(width: 10),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(playerName, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 14, fontWeight: FontWeight.w800)),
                    Text('Balance: ${fmtMoney(balance)}', style: const TextStyle(color: Colors.white60, fontSize: 10)),
                  ]),
                ]),
                const Spacer(),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(colors: [Color(0xFFFFD700), Color(0xFFD4AF37)]).createShader(b),
                  child: const Text('STATS', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 4)),
                ),
              ]),
            ),

            // Stats grid
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: Column(children: [

                // Win rate hero card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1B8030), Color(0xFF0D4018)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFF4CAF50), width: 1.5),
                    boxShadow: const [BoxShadow(color: Color(0x604CAF50), blurRadius: 16)],
                  ),
                  child: Column(children: [
                    const Text('WIN RATE', style: TextStyle(color: Color(0xFF81C784), fontSize: 11, letterSpacing: 4, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(winRate == '—' ? '—%' : '$winRate%',
                        style: const TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w900, height: 1)),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _statChip('$totalWins W', const Color(0xFF4CAF50)),
                      const SizedBox(width: 8),
                      _statChip('$totalLosses L', const Color(0xFFEF5350)),
                      const SizedBox(width: 8),
                      _statChip('$totalPushes P', const Color(0xFF42A5F5)),
                    ]),
                    const SizedBox(height: 8),
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(isUp ? Icons.trending_up : Icons.trending_down,
                          color: isUp ? const Color(0xFF4CAF50) : const Color(0xFFEF5350), size: 16),
                      const SizedBox(width: 6),
                      Text('Net: ${isUp ? "+" : ""}${fmtMoney(totalProfit)}',
                          style: TextStyle(color: isUp ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                              fontSize: 13, fontWeight: FontWeight.w800)),
                    ]),
                  ]),
                ),

                // 2-column stat grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.7,
                  children: [
                    _statCard('ROUNDS PLAYED', '$totalRounds', Icons.casino, const Color(0xFF1565C0)),
                    _statCard('BEST STREAK', '$bestStreak 🔥', Icons.local_fire_department, const Color(0xFFE65100)),
                    _statCard('BIGGEST WIN', fmtMoney(biggestWin), Icons.emoji_events, const Color(0xFFB8860C)),
                    _statCard('TOTAL WAGERED', fmtMoney(totalWagered), Icons.attach_money, const Color(0xFF6A1B9A)),
                    _statCard('CURRENT STREAK', '$winStreak', Icons.trending_up, const Color(0xFF2E7D32)),
                    _statCard(
                      'NET PROFIT',
                      (totalProfit >= 0 ? '+' : '') + fmtMoney(totalProfit),
                      isUp ? Icons.arrow_upward : Icons.arrow_downward,
                      isUp ? const Color(0xFF2E7D32) : const Color(0xFF8B0000),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Return to game button
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity, height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE55C), Color(0xFFD4AF37), Color(0xFFA07800)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [BoxShadow(color: Color(0xAAD4AF37), blurRadius: 16, offset: Offset(0, 4))]),
                    child: const Center(child: Text('BACK TO GAME', style: TextStyle(
                        color: Colors.black, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2))),
                  ),
                ),
              ]),
            )),
          ])),
        ]),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0x15000000),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.4), width: 1.5),
        boxShadow: [BoxShadow(color: color.withOpacity(0.15), blurRadius: 8)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(child: Text(label, style: TextStyle(color: color, fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1.5))),
        ]),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, height: 1.2)),
      ]),
    );
  }
}

// ── Settings Screen ───────────────────────────────────────────
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedTheme = AppSettings.themeIndex;
  bool _soundOn = AppSettings.soundEnabled;
  double _volume = AppSettings.volume;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.3), radius: 1.4,
            colors: kTableThemes[_selectedTheme].tableGradient),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: FeltPainter())),
          SafeArea(child: Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xCC000000), Color(0x00000000)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              child: Row(children: [
                GestureDetector(
                  onTap: () {
                    AppSettings.setTheme(_selectedTheme);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0x40000000),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x40D4AF37))),
                    child: const Row(children: [
                      Icon(Icons.arrow_back_ios, color: Color(0xAAD4AF37), size: 12),
                      SizedBox(width: 4),
                      Text('BACK', style: TextStyle(color: Color(0xAAD4AF37), fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ]),
                  ),
                ),
                const Spacer(),
                ShaderMask(
                  shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFD4AF37)]).createShader(b),
                  child: const Text('SETTINGS', style: TextStyle(
                      color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 4)),
                ),
                const Spacer(),
                const SizedBox(width: 60),
              ]),
            ),

            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Sound toggle
                Container(
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0x15000000),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x40D4AF37))),
                  child: Row(children: [
                    Icon(
                      _soundOn ? Icons.volume_up : Icons.volume_off,
                      color: const Color(0xFFD4AF37), size: 28),
                    const SizedBox(width: 16),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text('SOUND EFFECTS', style: TextStyle(
                          color: Color(0xFFD4AF37), fontSize: 11,
                          fontWeight: FontWeight.w800, letterSpacing: 2)),
                      Text(_soundOn ? 'On' : 'Off',
                          style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    ])),
                    GestureDetector(
                      onTap: () => setState(() {
                        _soundOn = !_soundOn;
                        AppSettings.toggleSound();
                        SoundEngine.setEnabled(_soundOn);
                        if (_soundOn) SoundEngine.tap();
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 52, height: 30,
                        decoration: BoxDecoration(
                          color: _soundOn ? const Color(0xFF2E7D32) : const Color(0x40FFFFFF),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                              color: _soundOn ? const Color(0xFF4CAF50) : const Color(0x60FFFFFF))),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: _soundOn ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            width: 24, height: 24,
                            margin: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle)),
                        ),
                      ),
                    ),
                  ]),
                ),

                // Volume slider — only show when sound is on
                if (_soundOn) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0x15000000),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x40D4AF37))),
                    child: Column(children: [
                      Row(children: [
                        Icon(
                          _volume == 0 ? Icons.volume_mute
                            : _volume < 0.5 ? Icons.volume_down
                            : Icons.volume_up,
                          color: const Color(0xFFD4AF37), size: 22),
                        const SizedBox(width: 12),
                        const Expanded(child: Text('VOLUME',
                          style: TextStyle(color: Color(0xFFD4AF37),
                              fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 2))),
                        Text('${(_volume * 100).round()}%',
                            style: const TextStyle(color: Colors.white60, fontSize: 12)),
                      ]),
                      const SizedBox(height: 8),
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: const Color(0xFFD4AF37),
                          inactiveTrackColor: const Color(0x30FFFFFF),
                          thumbColor: const Color(0xFFD4AF37),
                          overlayColor: const Color(0x30D4AF37),
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                        ),
                        child: Slider(
                          value: _volume,
                          min: 0.0, max: 1.0,
                          onChanged: (v) {
                            setState(() => _volume = v);
                            AppSettings.setVolume(v);
                            SoundEngine.setVolume(v);
                          },
                          onChangeEnd: (v) => SoundEngine.tap(),
                        ),
                      ),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Mute', style: TextStyle(color: Colors.white38, fontSize: 9)),
                        const Text('Low', style: TextStyle(color: Colors.white38, fontSize: 9)),
                        const Text('Medium', style: TextStyle(color: Colors.white38, fontSize: 9)),
                        const Text('Full', style: TextStyle(color: Colors.white38, fontSize: 9)),
                      ]),
                    ]),
                  ),
                ],

                // Notifications
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final granted = await NotificationService.requestPermission();
                    if (granted) {
                      NotificationService.scheduleDailyBonusReminder();
                      NotificationService.show(title: 'Notifications ON', body: 'Daily bonus reminders enabled!');
                    }
                    setState(() {});
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                      color: NotificationService.isPermitted ? const Color(0x202E7D32) : const Color(0x20FFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: NotificationService.isPermitted ? const Color(0xFF4CAF50) : const Color(0x40FFFFFF))),
                    child: Row(children: [
                      Icon(NotificationService.isPermitted ? Icons.notifications_active : Icons.notifications_outlined,
                          color: NotificationService.isPermitted ? const Color(0xFF4CAF50) : const Color(0xFFD4AF37), size: 26),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text('DAILY BONUS REMINDERS', style: TextStyle(color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.5)),
                        Text(NotificationService.isPermitted ? 'On - daily reminders enabled' : 'Tap to enable notifications',
                            style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      ])),
                      if (NotificationService.isPermitted)
                        const Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 22),
                    ])),
                ),
                // Table theme
                const SizedBox(height: 8),
                const Text('TABLE THEME', style: TextStyle(
                    color: Color(0xFFD4AF37), fontSize: 11,
                    fontWeight: FontWeight.w800, letterSpacing: 3)),
                const SizedBox(height: 4),
                const Text('Tap to preview', style: TextStyle(
                    color: Color(0x60FFFFFF), fontSize: 9, letterSpacing: 1)),
                const SizedBox(height: 16),

                // Theme cards
                ...List.generate(kTableThemes.length, (i) {
                  final t = kTableThemes[i];
                  final playerLevel = PlayerStorage.level.level;
                  final unlocked = isTableUnlocked(t, playerLevel);
                  final selected = _selectedTheme == i && unlocked;
                  return GestureDetector(
                    onTap: unlocked ? () => setState(() => _selectedTheme = i) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: unlocked
                            ? t.tableGradient
                            : [const Color(0x20000000), const Color(0x10000000)],
                          begin: Alignment.centerLeft, end: Alignment.centerRight),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                            ? t.accentColor
                            : unlocked
                                ? const Color(0x30FFFFFF)
                                : const Color(0x20FFFFFF),
                          width: selected ? 2.5 : 1),
                        boxShadow: selected ? [
                          BoxShadow(color: t.accentColor.withOpacity(0.4), blurRadius: 14)
                        ] : [],
                      ),
                      child: Row(children: [
                        // Mini table preview
                        Container(
                          width: 60, height: 40,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: unlocked ? t.tableGradient : [const Color(0x20FFFFFF), const Color(0x10FFFFFF)]),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: unlocked
                                ? t.accentColor.withOpacity(0.6)
                                : const Color(0x20FFFFFF))),
                          child: unlocked
                            ? Center(child: CustomPaint(
                                size: const Size(60, 40),
                                painter: _MiniTablePainter(t.feltLineColor)))
                            : const Center(child: Text('🔒',
                                style: TextStyle(fontSize: 18))),
                        ),
                        const SizedBox(width: 16),
                        Expanded(child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.name, style: TextStyle(
                              color: unlocked
                                ? (selected ? t.accentColor : Colors.white)
                                : Colors.white38,
                              fontSize: 14, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 2),
                          // VIP tier badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: unlocked
                                ? getVipTier(t.requiredLevel).color.withOpacity(0.2)
                                : const Color(0x10FFFFFF),
                              borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              unlocked
                                ? '${getVipTier(t.requiredLevel).emoji} ${t.vipTier}'
                                : '🔒 Unlocks at Level ${t.requiredLevel} (${t.vipTier})',
                              style: TextStyle(
                                color: unlocked
                                  ? getVipTier(t.requiredLevel).color
                                  : Colors.white38,
                                fontSize: 8, fontWeight: FontWeight.w700)),
                          ),
                        ])),
                        if (selected) Icon(Icons.check_circle, color: t.accentColor, size: 22)
                        else if (!unlocked) const Icon(Icons.lock, color: Colors.white24, size: 18),
                      ]),
                    ),
                  );
                }),

                const SizedBox(height: 8),
                // Apply button
                GestureDetector(
                  onTap: () {
                    AppSettings.setTheme(_selectedTheme);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: double.infinity, height: 52,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFE55C), Color(0xFFD4AF37), Color(0xFFA07800)],
                        begin: Alignment.topCenter, end: Alignment.bottomCenter),
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: const [BoxShadow(
                          color: Color(0xAAD4AF37), blurRadius: 16, offset: Offset(0, 4))]),
                    child: const Center(child: Text('APPLY & RETURN', style: TextStyle(
                        color: Colors.black, fontSize: 15,
                        fontWeight: FontWeight.w900, letterSpacing: 2))),
                  ),
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LegalScreen())),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0x10FFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0x30FFFFFF))),
                    child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Icon(Icons.shield_outlined, color: Color(0xFFD4AF37), size: 18),
                      SizedBox(width: 8),
                      Text('Privacy Policy & Terms of Service',
                          style: TextStyle(color: Color(0xFFD4AF37), fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(child: Text('Triple Threat Blackjack v1.0.0', style: TextStyle(color: Colors.white24, fontSize: 9))),
                const SizedBox(height: 16),
              ]),
            )),
          ])),
        ]),
      ),
    );
  }
}

class _MiniTablePainter extends CustomPainter {
  final Color lineColor;
  _MiniTablePainter(this.lineColor);
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = lineColor..strokeWidth = 1..style = PaintingStyle.stroke;
    canvas.drawOval(Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2),
        width: size.width * 0.7, height: size.height * 0.7), p);
    canvas.drawLine(Offset(size.width * 0.25, size.height * 0.85),
        Offset(size.width * 0.75, size.height * 0.85), p);
  }
  @override bool shouldRepaint(_) => false;
}



// ── Result Overlay ────────────────────────────────────────────
class _ResultOverlay extends StatefulWidget {
  final int profit, sideBet, winStreak;
  final List<List<String?>> results;
  final SideOdds? sideWin;
  final VoidCallback onNewDeal;

  const _ResultOverlay({
    required this.profit, required this.results, required this.sideWin,
    required this.sideBet, required this.winStreak, required this.onNewDeal,
  });

  @override State<_ResultOverlay> createState() => _ResultOverlayState();
}

class _ResultOverlayState extends State<_ResultOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _slide, _fade, _scale, _shake;

  bool get _isWin => widget.profit > 0;
  bool get _isLoss => widget.profit < 0;
  bool get _isTriple => widget.results
      .every((r) => r.isNotEmpty && r.every((x) => x == 'win'));

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 650));
    _slide = Tween<double>(begin: 80, end: 0).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    _fade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5)));
    _scale = Tween<double>(begin: 0.85, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _shake = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: -10.0), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -10.0, end: 10.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 10.0, end: -8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: -8.0, end: 8.0), weight: 2),
      TweenSequenceItem(tween: Tween(begin: 8.0, end: 0.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _ctrl,
        curve: _isLoss ? Curves.easeOut : const Interval(0, 0)));
    _ctrl.forward();
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  Color get _borderColor => _isWin
      ? const Color(0xFF4CAF50)
      : _isLoss ? const Color(0xFFEF5350)
      : const Color(0xFFFFD700);

  List<Color> get _gradColors => _isWin
      ? [const Color(0xEE0D3018), const Color(0xEE071A0D)]
      : _isLoss
          ? [const Color(0xEE3A0000), const Color(0xEE1A0000)]
          : [const Color(0xEE1A1A00), const Color(0xEE0D0D00)];

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (BuildContext ctx, Widget? child) {
        return Container(
          color: const Color(0x88000000),
          child: Center(
            child: Transform.translate(
              offset: Offset(_isLoss ? _shake.value : 0, _slide.value),
              child: FadeTransition(opacity: _fade,
                child: ScaleTransition(scale: _scale,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: _gradColors,
                          begin: Alignment.topCenter, end: Alignment.bottomCenter),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: _borderColor, width: 2),
                      boxShadow: [
                        BoxShadow(color: _borderColor.withOpacity(0.5), blurRadius: 30),
                        BoxShadow(color: _borderColor.withOpacity(0.2), blurRadius: 60, spreadRadius: 4),
                      ],
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      // Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(
                              color: _borderColor.withOpacity(0.3), width: 1))),
                        child: Column(children: [
                          if (_isTriple) const Text('🎉🎊🎉',
                              style: TextStyle(fontSize: 28)),
                          if (_isTriple) const SizedBox(height: 4),
                          Text(
                            _isTriple ? 'TRIPLE WIN!'
                                : _isWin ? 'YOU WIN'
                                : _isLoss ? 'HOUSE WINS' : 'PUSH',
                            style: TextStyle(
                              color: _isWin ? const Color(0xFF81C784)
                                  : _isLoss ? const Color(0xFFEF9A9A)
                                  : const Color(0xFFFFD700),
                              fontSize: _isTriple ? 26 : 12,
                              fontWeight: FontWeight.w900, letterSpacing: 3),
                          ),
                          const SizedBox(height: 6),
                          ShaderMask(
                            shaderCallback: (b) => LinearGradient(colors: _isWin
                                ? [const Color(0xFF81C784), Colors.white]
                                : _isLoss
                                    ? [const Color(0xFFEF9A9A), Colors.white]
                                    : [const Color(0xFFFFD700), Colors.white],
                            ).createShader(b),
                            child: Text(
                              _isWin ? '+${fmtMoney(widget.profit)}'
                                  : _isLoss ? '-${fmtMoney(widget.profit.abs())}'
                                  : 'PUSH',
                              style: const TextStyle(color: Colors.white,
                                  fontSize: 48, fontWeight: FontWeight.w900, height: 1),
                            ),
                          ),
                      // Share button for big wins and triple wins
                      if (_isTriple || widget.profit >= 500) ...[
                        const SizedBox(height: 8),
                        Builder(builder: (BuildContext ctx) =>
                          ShareHelper.shareBtn(ctx,
                            _isTriple
                              ? ShareHelper.tripleWin()
                              : ShareHelper.bigWin(widget.profit),
                          )),
                      ],
                      if (widget.winStreak >= 2) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [Color(0xFFFF6B00), Color(0xFFFF9500)]),
                                borderRadius: BorderRadius.circular(12)),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Text('🔥', style: TextStyle(fontSize: 12)),
                                Text(' ${widget.winStreak} WIN STREAK',
                                    style: const TextStyle(color: Colors.white,
                                        fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                              ]),
                            ),
                          ],
                        ]),
                      ),

                      // Hand breakdown
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(3, (slot) {
                            final r = widget.results[slot];
                            if (r.isEmpty) return const SizedBox.shrink();
                            return Column(children: [
                              Text('H${slot + 1}', style: const TextStyle(
                                  color: Color(0x80D4AF37), fontSize: 9,
                                  fontWeight: FontWeight.w700, letterSpacing: 1)),
                              const SizedBox(height: 4),
                              ...r.map((res) => _handBadge(res ?? '')),
                            ]);
                          }),
                        ),
                      ),

                      // Side bet win
                      if (widget.sideWin != null)
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFF7B1FA2), Color(0xFF4A148C)]),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFCE93D8), width: 1.5)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(children: [
                                const Icon(Icons.stars, color: Color(0xFFCE93D8), size: 14),
                                const SizedBox(width: 6),
                                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  const Text('SIDE BET', style: TextStyle(
                                      color: Color(0xFFCE93D8), fontSize: 8,
                                      fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                                  Text(widget.sideWin!.name, style: const TextStyle(
                                      color: Colors.white70, fontSize: 9)),
                                ]),
                              ]),
                              Text('+${fmtMoney(widget.sideBet * widget.sideWin!.pays)}',
                                  style: const TextStyle(color: Color(0xFFE040FB),
                                      fontSize: 18, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ),

                      // Share win button
                      if (widget.profit > 0)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                          child: GestureDetector(
                            onTap: () {
                              final wins = widget.results.fold(0, (s,r) =>
                                  s + r.where((x) => x == 'win').length);
                              final msg = wins == 3
                                ? 'TRIPLE WIN on Triple Threat Blackjack! Won +${fmtMoney(widget.profit)}! Can you beat me?'
                                : widget.profit >= 500
                                  ? 'Just won +${fmtMoney(widget.profit)} on Triple Threat Blackjack! Play free!'
                                  : widget.winStreak >= 3
                                    ? '${widget.winStreak}-hand WIN STREAK on Triple Threat Blackjack!'
                                    : 'Playing Triple Threat Blackjack - won +${fmtMoney(widget.profit)}! Try it!';
                              ShareHelper.share(context, msg);
                            },
                            child: Container(
                              width: double.infinity, height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0x20FFFFFF),
                                borderRadius: BorderRadius.circular(21),
                                border: Border.all(color: const Color(0x50FFFFFF))),
                              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.share, color: Colors.white70, size: 16),
                                SizedBox(width: 8),
                                Text('SHARE WIN', style: TextStyle(
                                    color: Colors.white70, fontSize: 12,
                                    fontWeight: FontWeight.w800, letterSpacing: 2)),
                              ]))),
                        ),

                      // New deal button
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                        child: GestureDetector(
                          onTap: widget.onNewDeal,
                          child: Container(
                            width: double.infinity, height: 54,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFE55C), Color(0xFFD4AF37), Color(0xFFA07800)],
                                begin: Alignment.topCenter, end: Alignment.bottomCenter),
                              borderRadius: BorderRadius.circular(27),
                              boxShadow: const [BoxShadow(
                                  color: Color(0xAAD4AF37), blurRadius: 20, offset: Offset(0, 4))]),
                            child: const Center(child: Text('NEW DEAL',
                                style: TextStyle(color: Colors.black,
                                    fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 3))),
                          ),
                        ),
                      ),
                    ]),
                  ),
                )),
          )),
        );
      },
    );
  }

  Widget _handBadge(String result) {
    Color bg, border; String label;
    switch (result) {
      case 'win': bg = const Color(0xFF2E7D32); border = const Color(0xFF4CAF50); label = 'WIN'; break;
      case 'lose': bg = const Color(0xFF8B0000); border = const Color(0xFFEF5350); label = 'LOSE'; break;
      case 'bust': bg = const Color(0xFF6D0000); border = const Color(0xFFEF5350); label = 'BUST'; break;
      case 'push': bg = const Color(0xFF5A4A00); border = const Color(0xFFFFD700); label = 'PUSH'; break;
      default: return const SizedBox.shrink();
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 3),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1.5),
        boxShadow: [BoxShadow(color: border.withOpacity(0.4), blurRadius: 6)]),
      child: Text(label, style: const TextStyle(color: Colors.white,
          fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
    );
  }
}

// ── Leaderboard Screen ────────────────────────────────────────
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});
  @override State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  List<LeaderboardEntry> _all = [];
  final String _myName = PlayerStorage.playerName;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
    _all = PlayerStorage.getLeaderboard();
    if (_all.length <= 1) {
      final mock = [
        LeaderboardEntry(name:'TripleKing',avatarIndex:2,balance:48200,rounds:312,wins:189,netProfit:23400,bestStreak:8,biggestWin:4500,date:DateTime.now().subtract(const Duration(hours:2))),
        LeaderboardEntry(name:'BlackJax',avatarIndex:5,balance:35100,rounds:245,wins:156,netProfit:18900,bestStreak:6,biggestWin:3200,date:DateTime.now().subtract(const Duration(hours:5))),
        LeaderboardEntry(name:'AceHunter',avatarIndex:1,balance:28700,rounds:198,wins:121,netProfit:14200,bestStreak:5,biggestWin:2800,date:DateTime.now().subtract(const Duration(hours:8))),
        LeaderboardEntry(name:'CardShark99',avatarIndex:3,balance:21500,rounds:167,wins:98,netProfit:9800,bestStreak:4,biggestWin:2100,date:DateTime.now().subtract(const Duration(days:1))),
        LeaderboardEntry(name:'DealerBeater',avatarIndex:6,balance:15300,rounds:134,wins:79,netProfit:6500,bestStreak:3,biggestWin:1800,date:DateTime.now().subtract(const Duration(days:1))),
        LeaderboardEntry(name:'HighRoller7',avatarIndex:4,balance:12100,rounds:89,wins:52,netProfit:4200,bestStreak:4,biggestWin:1500,date:DateTime.now().subtract(const Duration(days:2))),
        LeaderboardEntry(name:'LuckyDeuce',avatarIndex:0,balance:8900,rounds:76,wins:43,netProfit:2100,bestStreak:3,biggestWin:900,date:DateTime.now().subtract(const Duration(days:2))),
      ];
      final myEntry = _all.isNotEmpty ? _all.first : null;
      _all = [...mock];
      if (myEntry != null) _all.add(myEntry);
      _all.sort((a,b) => b.netProfit.compareTo(a.netProfit));
    }
  }

  @override void dispose() { _tabs.dispose(); super.dispose(); }

  String _fmt(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${m[d.month-1]} ${d.day}';
  }

  List<LeaderboardEntry> _topEarner() {
    final l = [..._all]..sort((a,b) => b.netProfit.compareTo(a.netProfit));
    return l.take(10).toList();
  }

  List<LeaderboardEntry> _topStreak() {
    final l = [..._all]..sort((a,b) => b.bestStreak.compareTo(a.bestStreak));
    return l.take(10).toList();
  }

  List<LeaderboardEntry> _topWinRate() {
    final l = _all.where((e) => e.qualifiesForWinRate).toList()
      ..sort((a,b) => b.winRatePct.compareTo(a.winRatePct));
    return l.take(10).toList();
  }

  List<LeaderboardEntry> _topBigWin() {
    final l = [..._all]..sort((a,b) => b.biggestWin.compareTo(a.biggestWin));
    return l.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3), radius: 1.4,
            colors: [Color(0xFF1E5C14), Color(0xFF0F3A0A), Color(0xFF061A04)])),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: FeltPainter())),
          SafeArea(child: Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xCC000000), Color(0x00000000)],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              child: Column(children: [
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0x40000000),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x40D4AF37))),
                      child: const Row(children: [
                        Icon(Icons.arrow_back_ios, color: Color(0xAAD4AF37), size: 12),
                        SizedBox(width: 4),
                        Text('BACK', style: TextStyle(color: Color(0xAAD4AF37),
                            fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ]),
                    ),
                  ),
                  const Spacer(),
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFD4AF37)]).createShader(b),
                    child: const Text('LEADERBOARD', style: TextStyle(
                        color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.w900, letterSpacing: 3)),
                  ),
                  const Spacer(),
                  const SizedBox(width: 60),
                ]),
                const SizedBox(height: 12),
                // Tab bar
                TabBar(
                  controller: _tabs,
                  isScrollable: true,
                  indicatorColor: const Color(0xFFD4AF37),
                  indicatorWeight: 2,
                  labelColor: const Color(0xFFD4AF37),
                  unselectedLabelColor: const Color(0x60FFFFFF),
                  labelStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 1),
                  tabs: const [
                    Tab(text: '💰 TOP EARNER'),
                    Tab(text: '🔥 WIN STREAK'),
                    Tab(text: '🎯 WIN RATE'),
                    Tab(text: '⚡ HIGH ROLLER'),
                  ],
                ),
              ]),
            ),

            // Tab content
            Expanded(child: TabBarView(
              controller: _tabs,
              children: [
                _buildTab(_topEarner(), 'NET PROFIT',
                  (e) => e.netProfit >= 0 ? '+${fmtMoney(e.netProfit)}' : fmtMoney(e.netProfit),
                  (e) => '${e.rounds} rounds  •  ${e.winRateStr}  •  ${_fmt(e.date)}',
                  (e) => e.netProfit >= 0 ? const Color(0xFF4CAF50) : const Color(0xFFEF5350),
                  'No scores yet — play rounds to appear here'),
                _buildTab(_topStreak(), 'BEST STREAK',
                  (e) => '${e.bestStreak} 🔥',
                  (e) => '${e.rounds} rounds  •  ${e.winRateStr}  •  ${_fmt(e.date)}',
                  (e) => const Color(0xFFFF9500),
                  'No streaks yet — win consecutive hands'),
                _buildTab(_topWinRate(), 'WIN RATE',
                  (e) => e.winRateStr,
                  (e) => '${e.rounds} rounds played  •  ${_fmt(e.date)}',
                  (e) => const Color(0xFF64B5F6),
                  'Need 20+ rounds to qualify',
                  subtitle: 'Min 20 rounds required'),
                _buildTab(_topBigWin(), 'BIGGEST WIN',
                  (e) => '+${fmtMoney(e.biggestWin)}',
                  (e) => '${e.rounds} rounds  •  ${_fmt(e.date)}',
                  (e) => const Color(0xFFFFD700),
                  'No big wins yet — go for broke'),
              ],
            )),
          ])),
        ]),
      ),
    );
  }

  Widget _buildTab(
    List<LeaderboardEntry> entries,
    String valueLabel,
    String Function(LeaderboardEntry) valueFn,
    String Function(LeaderboardEntry) subFn,
    Color Function(LeaderboardEntry) colorFn,
    String emptyMsg, {
    String? subtitle,
  }) {
    return entries.isEmpty
      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('🏆', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(emptyMsg, textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0x80D4AF37),
                  fontSize: 12, letterSpacing: 1)),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(subtitle, style: const TextStyle(
                color: Color(0x50FFFFFF), fontSize: 10)),
          ],
        ]))
      : Column(children: [
Container(
margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
decoration: BoxDecoration(
gradient: const LinearGradient(colors: [Color(0x25D4AF37), Color(0x10D4AF37)]),
borderRadius: BorderRadius.circular(12),
border: Border.all(color: const Color(0x60D4AF37))),
child: Row(children: [
const Text('🌍', style: TextStyle(fontSize: 16)),
const SizedBox(width: 8),
const Text('YOUR GLOBAL RANK', style: TextStyle(
color: Color(0xFFD4AF37), fontSize: 9,
fontWeight: FontWeight.w700, letterSpacing: 2)),
const Spacer(),
Text('#${entries.indexWhere((e) => e.name == _myName) >= 0 ? entries.indexWhere((e) => e.name == _myName) + 1 : entries.length + 1} / ${1247 + (DateTime.now().millisecondsSinceEpoch ~/ 86400000 % 500)} players',
style: const TextStyle(
color: Colors.white, fontSize: 13,
fontWeight: FontWeight.w900)),
]),
),
Expanded(child: ListView.builder(
padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
itemCount: entries.length,
          itemBuilder: (BuildContext ctx, int i) {
            final e = entries[i];
            final isMe = e.name == _myName;
            final isTop3 = i < 3;
            final medals = ['🥇', '🥈', '🥉'];
            final rankColors = [
              const Color(0xFFFFD700),
              const Color(0xFFBDBDBD),
              const Color(0xFFCD7F32),
            ];
            final valColor = colorFn(e);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: isMe
                  ? [const Color(0x25D4AF37), const Color(0x10D4AF37)]
                  : isTop3
                    ? [rankColors[i].withOpacity(0.12), const Color(0x06FFFFFF)]
                    : [const Color(0x10FFFFFF), const Color(0x05FFFFFF)],
                  begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isMe
                    ? const Color(0x80D4AF37)
                    : isTop3 ? rankColors[i].withOpacity(0.5)
                    : const Color(0x25D4AF37),
                  width: isMe || isTop3 ? 1.5 : 1),
                boxShadow: isMe || isTop3 ? [
                  BoxShadow(
                    color: isMe ? const Color(0x30D4AF37) : rankColors[i].withOpacity(0.15),
                    blurRadius: 10)
                ] : [],
              ),
              child: Row(children: [
                // Rank
                SizedBox(width: 36, child: Center(child: isTop3
                  ? Text(medals[i], style: const TextStyle(fontSize: 20))
                  : Text('#${i+1}', style: const TextStyle(
                      color: Color(0x70D4AF37), fontSize: 13,
                      fontWeight: FontWeight.w800)))),
                const SizedBox(width: 8),
                // Avatar
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: kAvatarColors[e.avatarIndex.clamp(0, kAvatarColors.length-1)],
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isMe ? const Color(0xFFD4AF37)
                          : isTop3 ? rankColors[i] : const Color(0x40FFFFFF),
                      width: 1.5)),
                  child: Center(child: Text(
                    kAvatarEmojis[e.avatarIndex.clamp(0, kAvatarEmojis.length-1)],
                    style: const TextStyle(color: Colors.white,
                        fontSize: 15, fontWeight: FontWeight.w900))),
                ),
                const SizedBox(width: 10),
                // Name + sub
                Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(e.name, style: TextStyle(
                        color: isMe ? const Color(0xFFD4AF37) : Colors.white,
                        fontSize: 13, fontWeight: FontWeight.w800)),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0x40D4AF37),
                          borderRadius: BorderRadius.circular(4)),
                        child: const Text('YOU', style: TextStyle(
                            color: Color(0xFFD4AF37), fontSize: 7,
                            fontWeight: FontWeight.w900, letterSpacing: 1)),
                      ),
                    ],
                  ]),
                  Text(subFn(e), style: const TextStyle(
                      color: Colors.white38, fontSize: 9)),
                ])),
                // Value
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(valueFn(e), style: TextStyle(
                      color: valColor, fontSize: 15, fontWeight: FontWeight.w900)),
                  Text(valueLabel, style: const TextStyle(
                      color: Colors.white30, fontSize: 7, letterSpacing: 1)),
                ]),
              ]),
            );
          },
        )),
      ]);
  }
}

// ── Badges Screen ─────────────────────────────────────────────
class BadgesScreen extends StatelessWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final earned = PlayerStorage.earnedBadges;
    final xp = PlayerStorage.xp;
    final level = PlayerStorage.level;
    final nextLvl = getNextLevel(xp);
    final progress = getLevelProgress(xp);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0A0F0A), Color(0xFF060C06), Color(0xFF030703)],
            begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: FeltPainter())),
          SafeArea(child: Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xCC000000), Color(0x00000000)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0x40000000),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x40D4AF37))),
                    child: const Row(children: [
                      Icon(Icons.arrow_back_ios, color: Color(0xAAD4AF37), size: 12),
                      SizedBox(width: 4),
                      Text('BACK', style: TextStyle(color: Color(0xAAD4AF37),
                          fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ]),
                  ),
                ),
                const Spacer(),
                const Text('PROFILE', style: TextStyle(color: Color(0xFFD4AF37),
                    fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 4)),
                const Spacer(),
                const SizedBox(width: 60),
              ]),
            ),

            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(children: [

                // Level card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [level.color.withOpacity(0.25), const Color(0x10000000)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: level.color.withOpacity(0.6), width: 2),
                    boxShadow: [BoxShadow(color: level.color.withOpacity(0.3), blurRadius: 20)]),
                  child: Column(children: [
                    // Avatar + name
                    Row(children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(
                          color: kAvatarColors[PlayerStorage.avatarIndex],
                          shape: BoxShape.circle,
                          border: Border.all(color: level.color, width: 2.5),
                          boxShadow: [BoxShadow(color: level.color.withOpacity(0.5), blurRadius: 12)]),
                        child: Center(child: Text(
                          PlayerStorage.playerName.isNotEmpty
                              ? kAvatarEmojis[PlayerStorage.avatarIndex.clamp(0, kAvatarEmojis.length-1)] : '?',
                          style: const TextStyle(color: Colors.white,
                              fontSize: 24, fontWeight: FontWeight.w900))),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(PlayerStorage.playerName, style: const TextStyle(
                            color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 2),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                          decoration: BoxDecoration(
                            color: level.color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: level.color.withOpacity(0.5))),
                          child: Text('Level ${level.level} • ${level.title}',
                              style: TextStyle(color: level.color,
                                  fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      ])),
                    ]),
                    const SizedBox(height: 20),
                    // XP bar
                    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                      Text('$xp XP', style: TextStyle(color: level.color,
                          fontSize: 12, fontWeight: FontWeight.w700)),
                      if (nextLvl != null)
                        Text('${nextLvl.xpRequired} XP to ${nextLvl.title}',
                            style: const TextStyle(color: Colors.white54, fontSize: 10))
                      else
                        const Text('MAX LEVEL', style: TextStyle(
                            color: Color(0xFFFFD700), fontSize: 10, fontWeight: FontWeight.w800)),
                    ]),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress, minHeight: 10,
                        backgroundColor: const Color(0x20FFFFFF),
                        valueColor: AlwaysStoppedAnimation<Color>(level.color),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Level milestones
                    Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: kLevels.map((l) {
                        final reached = xp >= l.xpRequired;
                        return Column(children: [
                          Container(
                            width: 16, height: 16,
                            decoration: BoxDecoration(
                              color: reached ? l.color : const Color(0x20FFFFFF),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: reached ? l.color : const Color(0x30FFFFFF), width: 1.5)),
                          ),
                          const SizedBox(height: 2),
                          Text('${l.level}', style: TextStyle(
                              color: reached ? l.color : const Color(0x40FFFFFF),
                              fontSize: 7, fontWeight: FontWeight.w700)),
                        ]);
                      }).toList(),
                    ),
                  ]),
                ),

                // Badges section
                Row(children: [
                  const Text('BADGES', style: TextStyle(color: Color(0xFFD4AF37),
                      fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 3)),
                  const SizedBox(width: 8),
                  Text('${earned.length}/${kBadges.length}',
                      style: const TextStyle(color: Colors.white54, fontSize: 10)),
                ]),
                const SizedBox(height: 12),

                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.85,
                  children: kBadges.map((badge) {
                    final isEarned = earned.contains(badge.id);
                    final isLegendary = ['night_owl', 'diamond_hands', 'the_house',
                        'untouchable_season', 'triple_master'].contains(badge.id);
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isEarned
                            ? isLegendary
                                ? const Color(0x30D4AF37)
                                : const Color(0x20D4AF37)
                            : const Color(0x08FFFFFF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isEarned
                              ? isLegendary
                                  ? const Color(0xFFD4AF37)
                                  : const Color(0x80D4AF37)
                              : isLegendary
                                  ? const Color(0x40D4AF37)
                                  : const Color(0x20FFFFFF),
                          width: isLegendary ? 2 : 1.5),
                        boxShadow: isEarned ? [
                          BoxShadow(
                            color: isLegendary
                                ? const Color(0x60D4AF37)
                                : const Color(0x30D4AF37),
                            blurRadius: isLegendary ? 16 : 8)
                        ] : [],
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        if (isLegendary && !isEarned)
                          const Text('🏅', style: TextStyle(fontSize: 10)),
                        Text(isEarned ? badge.emoji : '🔒',
                            style: TextStyle(fontSize: isEarned ? 26 : 22)),
                        const SizedBox(height: 4),
                        Text(badge.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isEarned
                                  ? isLegendary ? const Color(0xFFD4AF37) : Colors.white
                                  : const Color(0x40FFFFFF),
                              fontSize: 9, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        if (isLegendary) Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0x30D4AF37),
                            borderRadius: BorderRadius.circular(4)),
                          child: const Text('LEGENDARY', style: TextStyle(
                              color: Color(0xAAD4AF37), fontSize: 6,
                              fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                        if (!isLegendary) Text(badge.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isEarned
                                  ? const Color(0x80FFFFFF)
                                  : const Color(0x25FFFFFF),
                              fontSize: 7)),
                      ]),
                    );
                  }).toList(),
                ),
              ]),
            )),
          ])),
        ]),
      ),
    );
  }
}

class TournamentLobbyScreen extends StatefulWidget {
  final int playerBalance;
  final Function(int) onChipsChanged;
  const TournamentLobbyScreen({super.key,
      required this.playerBalance, required this.onChipsChanged});
  @override State<TournamentLobbyScreen> createState() =>
      _TournamentLobbyScreenState();
}

class _TournamentLobbyScreenState extends State<TournamentLobbyScreen> {
  late int _balance;
  Timer? _cdTimer;

  @override
  void initState() {
    super.initState();
    _balance = widget.playerBalance;
    _cdTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _cdTimer?.cancel();
    super.dispose();
  }

  void _enter(TournamentConfig config) {
    if (!TournamentStorage.canEnter(config.type)) {
      final rem = TournamentStorage.cooldownRemaining(config.type)!;
      _showMsg('Next ${config.name} in ${TournamentStorage.formatCooldown(rem)}');
      return;
    }
    final isFree = config.entryFee == 0;
    final canFree = TournamentStorage.canEnterFree();
    if (isFree && !canFree) {
      _showMsg('Free entry used today. Come back tomorrow!');
      return;
    }
    if (!isFree && _balance < config.entryFee) {
      _showMsg('Not enough chips! Need ${fmtMoney(config.entryFee)}');
      return;
    }
    TournamentStorage.recordEntry(config.type);
    if (isFree) {
      TournamentStorage.useFreeEntry();
    } else {
      setState(() => _balance -= config.entryFee);
      PlayerStorage.saveChips(_balance);
      widget.onChipsChanged(_balance);
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (BuildContext _) => TournamentGameScreen(
        config: config,
        playerBalance: _balance,
        onComplete: (int finalBalance) {
          setState(() => _balance = finalBalance);
          widget.onChipsChanged(finalBalance);
        },
      ),
    ));
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: const Color(0xFF1A3A1A),
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3), radius: 1.4,
            colors: [Color(0xFF1A1A3A), Color(0xFF0A0A20), Color(0xFF050510)])),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: FeltPainter())),
          SafeArea(child: Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0x40000000),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x40D4AF37))),
                    child: const Row(children: [
                      Icon(Icons.arrow_back_ios, color: Color(0xAAD4AF37), size: 12),
                      SizedBox(width: 4),
                      Text('BACK', style: TextStyle(color: Color(0xAAD4AF37),
                          fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ]),
                  ),
                ),
                const Spacer(),
                Column(children: [
                  ShaderMask(
                    shaderCallback: (b) => const LinearGradient(
                      colors: [Color(0xFFFFD700), Color(0xFFD4AF37)]).createShader(b),
                    child: const Text('TOURNAMENT', style: TextStyle(
                        color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.w900, letterSpacing: 4)),
                  ),
                  Text('Balance: ${fmtMoney(_balance)}',
                      style: const TextStyle(color: Colors.white54, fontSize: 10)),
                ]),
                const Spacer(),
                const SizedBox(width: 60),
              ]),
            ),

            // Free entry banner
            if (TournamentStorage.canEnterFree())
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1B5E20), Color(0xFF2E7D32)]),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF4CAF50), width: 1.5)),
                child: Row(children: [
                  const Text('🎁', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('FREE ENTRY available today!',
                      style: TextStyle(color: Colors.white,
                          fontSize: 11, fontWeight: FontWeight.w800))),
                  const Text('Quick Fire only', style: TextStyle(
                      color: Colors.white60, fontSize: 9)),
                ]),
              ),

            // Tournament cards
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: kTournaments.length,
              itemBuilder: (BuildContext ctx, int i) {
                final t = kTournaments[i];
                final isFree = t.entryFee == 0;
                final canEnter = isFree
                    ? TournamentStorage.canEnterFree()
                    : _balance >= t.entryFee;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: i == 2
                        ? [const Color(0x30D4AF37), const Color(0x10D4AF37)]
                        : [const Color(0x15FFFFFF), const Color(0x08FFFFFF)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: i == 2
                        ? const Color(0x80D4AF37)
                        : const Color(0x30FFFFFF),
                      width: i == 2 ? 2 : 1)),
                  child: Column(children: [
                    // Header row
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                      child: Row(children: [
                        Text(t.emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.name, style: const TextStyle(
                              color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          Text(t.subtitle, style: const TextStyle(
                              color: Colors.white60, fontSize: 11)),
                        ])),
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('${t.durationMinutes} MIN', style: const TextStyle(
                              color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.w900)),
                          Text('Start: ${fmtMoney(t.startingChips)}',
                              style: const TextStyle(color: Colors.white54, fontSize: 9)),
                        ]),
                      ]),
                    ),
                    // Prize breakdown
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x15000000),
                        borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _prizeCol('🥇', '1ST', t.prize1st),
                          _prizeCol('🥈', '2ND', t.prize2nd),
                          _prizeCol('🥉', '3RD', t.prize3rd),
                          _prizeCol('🎖️', 'ENTRY', t.participationPrize),
                        ],
                      ),
                    ),
                     // Entry button with cooldown
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Builder(builder: (BuildContext ctx) {
                        final cdRemaining =
                            TournamentStorage.cooldownRemaining(t.type);
                        final onCooldown = cdRemaining != null;
                        final isFree = t.entryFee == 0;
                        final canFree = TournamentStorage.canEnterFree();
                        final hasChips = _balance >= t.entryFee;
                        final canGo = !onCooldown &&
                            (isFree ? canFree : hasChips);
                        return GestureDetector(
                          onTap: () => _enter(t),
                          child: Container(
                            width: double.infinity, height: 52,
                            decoration: BoxDecoration(
                              gradient: canGo
                                ? const LinearGradient(
                                    colors: [Color(0xFFFFE55C),
                                        Color(0xFFD4AF37),
                                        Color(0xFFA07800)],
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter)
                                : null,
                              color: canGo ? null : const Color(0x15FFFFFF),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: onCooldown
                                    ? const Color(0x40EF5350)
                                    : const Color(0x00000000)),
                              boxShadow: canGo ? const [BoxShadow(
                                  color: Color(0x80D4AF37),
                                  blurRadius: 12)] : [],
                            ),
                            child: onCooldown
                              ? Column(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                  const Text('NEXT TOURNAMENT IN',
                                      style: TextStyle(
                                          color: Color(0x80EF5350),
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 2)),
                                  const SizedBox(height: 2),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                    const Icon(Icons.timer,
                                        color: Color(0xAAEF5350),
                                        size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      TournamentStorage
                                          .formatCooldown(cdRemaining),
                                      style: const TextStyle(
                                          color: Color(0xFFEF5350),
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          fontFamily: 'monospace')),
                                  ]),
                                ])
                              : Center(child: Text(
                                  isFree
                                    ? (canFree
                                        ? 'ENTER FREE'
                                        : 'FREE ENTRY USED TODAY')
                                    : hasChips
                                        ? 'ENTER — ${fmtMoney(t.entryFee)}'
                                        : 'NEED ${fmtMoney(t.entryFee)}',
                                  style: TextStyle(
                                    color: canGo
                                        ? Colors.black
                                        : Colors.white38,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 2))),
                          ),
                        );
                      }),
                    ),
                  ]),
                );
              },
            )),
          ])),
        ]),
      ),
    );
  }

  Widget _prizeCol(String emoji, String label, int amount) {
    return Column(children: [
      Text(emoji, style: const TextStyle(fontSize: 16)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white54,
          fontSize: 8, letterSpacing: 1, fontWeight: FontWeight.w700)),
      Text(fmtMoney(amount), style: const TextStyle(
          color: Color(0xFFD4AF37), fontSize: 11, fontWeight: FontWeight.w900)),
    ]);
  }
}

// ── Tournament Game Screen ────────────────────────────────────
class TournamentGameScreen extends StatefulWidget {
  final TournamentConfig config;
  final int playerBalance;
  final Function(int) onComplete;
  const TournamentGameScreen({super.key, required this.config,
      required this.playerBalance, required this.onComplete});
  @override State<TournamentGameScreen> createState() => _TournamentGameScreenState();
}

class _TournamentGameScreenState extends State<TournamentGameScreen> {
  late Timer _gameTimer;
  late Timer _aiTimer;
  late int _secondsLeft;
  late int _playerBalance;
  bool _ended = false;
  bool _showStandings = false;
  bool _earlyExit = false;
  late List<AiPlayer> _aiPlayers;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _playerBalance = widget.config.startingChips;
    _secondsLeft = widget.config.durationMinutes * 60;

    final names = [...kAiNames]..shuffle();
    _aiPlayers = List.generate(14, (i) {
      return AiPlayer(
        name: names[i],
        avatarIndex: _rng.nextInt(kAvatarEmojis.length),
        personality: kAiPersonalities[i % kAiPersonalities.length],
        balance: widget.config.startingChips,
      );
    });

    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _endTournament();
    });

    _aiTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      setState(() {
        for (final ai in _aiPlayers) {
          if (_rng.nextDouble() < 0.25) {
            ai.simulateHand(_rng, widget.config.startingChips);
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _gameTimer.cancel();
    _aiTimer.cancel();
    super.dispose();
  }

  void _endTournament() {
    if (_ended) return;
    _ended = true;
    _gameTimer.cancel();
    _aiTimer.cancel();
    PlayerStorage.checkAndAwardBadges(
      totalRounds: PlayerStorage.statRounds,
      totalWins: PlayerStorage.statWins,
      bestStreak: PlayerStorage.statBestStreak,
      justWon: false, tripleWin: false, sideHit: false,
      wasBroke: false, comeback: false, bigSpender: false,
      balance: _playerBalance, handsWonThisRound: 0,
      enteredTournament: true, wonTournament: false,
      totalSideBetsSession: 0,
      totalWagered: PlayerStorage.statWagered,
    );
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (BuildContext _) => TournamentFinalScreen(
        config: widget.config,
        playerFinalBalance: _playerBalance,
        aiPlayers: _aiPlayers,
        earlyExit: _earlyExit,
        onDone: (int prize) {
          widget.onComplete(widget.playerBalance + prize);          
        },
      ),
    ));
  }

  List<Map<String, dynamic>> get _standings {
    final list = <Map<String, dynamic>>[];
    list.add({
      'name': PlayerStorage.playerName,
      'avatarIndex': PlayerStorage.avatarIndex,
      'balance': _playerBalance,
      'handsPlayed': 0,
      'winRate': '—',
      'biggestWin': 0,
      'isPlayer': true,
    });
    for (final ai in _aiPlayers) {
      list.add({
        'name': ai.name,
        'avatarIndex': ai.avatarIndex,
        'balance': ai.balance,
        'handsPlayed': ai.handsPlayed,
        'winRate': ai.winRateStr,
        'biggestWin': ai.biggestWin,
        'isPlayer': false,
      });
    }
    list.sort((a, b) =>
        (b['balance'] as int).compareTo(a['balance'] as int));
    return list;
  }

  int get _playerRank =>
      _standings.indexWhere((e) => e['isPlayer'] == true) + 1;

  String get _timeStr {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_secondsLeft <= 30) return const Color(0xFFEF5350);
    if (_secondsLeft <= 60) return const Color(0xFFFFC107);
    return const Color(0xFF4CAF50);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        GameScreen(
          tournamentBalance: _playerBalance,
          onBalanceUpdate: (int b) => setState(() => _playerBalance = b),
        ),

        // Tournament HUD
        Positioned(top: 0, left: 0, right: 0,
          child: SafeArea(child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF000000), Color(0xCC000000), Color(0x00000000)],
                begin: Alignment.topCenter, end: Alignment.bottomCenter)),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0x40000000),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x40D4AF37))),
                child: Row(children: [
                  Text(widget.config.emoji,
                      style: const TextStyle(fontSize: 11)),
                  const SizedBox(width: 4),
                  Text(widget.config.name, style: const TextStyle(
                      color: Color(0xFFD4AF37), fontSize: 9,
                      fontWeight: FontWeight.w800, letterSpacing: 1)),
                ]),
              ),
              const SizedBox(width: 8),
              // STANDINGS button
              GestureDetector(
                onTap: () => setState(() => _showStandings = true),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1565C0), Color(0xFF0D47A1)]),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: const [BoxShadow(
                        color: Color(0x601565C0), blurRadius: 6)]),
                  child: Row(children: [
                    const Icon(Icons.leaderboard,
                        color: Colors.white, size: 12),
                    const SizedBox(width: 4),
                    Text('STANDINGS  #$_playerRank',
                        style: const TextStyle(color: Colors.white,
                            fontSize: 9, fontWeight: FontWeight.w900)),
                  ]),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: _timerColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: _timerColor.withOpacity(0.6), width: 1.5)),
                child: Row(children: [
                  Icon(Icons.timer, color: _timerColor, size: 13),
                  const SizedBox(width: 4),
                  Text(_timeStr, style: TextStyle(
                      color: _timerColor, fontSize: 16,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'monospace')),
                ]),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (BuildContext ctx) => AlertDialog(
                    backgroundColor: const Color(0xFF0A1A08),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    title: const Text('End Tournament?',
                        style: TextStyle(color: Color(0xFFD4AF37),
                            fontWeight: FontWeight.w800)),
                    content: const Text(
                        'Your current balance will be your final score.',
                        style: TextStyle(color: Colors.white70)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('KEEP PLAYING',
                              style: TextStyle(
                                  color: Color(0xFFD4AF37)))),
                      TextButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _earlyExit = true;
                            _endTournament();
                          },
                          child: const Text('END NOW',
                              style: TextStyle(
                                  color: Color(0xFFEF5350)))),
                    ],
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0x40000000),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: const Color(0x40EF5350))),
                  child: const Text('END', style: TextStyle(
                      color: Color(0xAAEF5350), fontSize: 9,
                      fontWeight: FontWeight.w700, letterSpacing: 1)),
                ),
              ),
            ]),
          ))),

        // Live Standings Overlay
        if (_showStandings)
          Positioned.fill(child: GestureDetector(
            onTap: () => setState(() => _showStandings = false),
            child: Container(
              color: const Color(0xEE000000),
              child: SafeArea(child: Column(children: [
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                  const Icon(Icons.leaderboard,
                      color: Color(0xFFD4AF37), size: 18),
                  const SizedBox(width: 8),
                  const Text('LIVE STANDINGS', style: TextStyle(
                      color: Color(0xFFD4AF37), fontSize: 18,
                      fontWeight: FontWeight.w900, letterSpacing: 3)),
                ]),
                Text('${widget.config.name}  •  $_timeStr remaining',
                    style: const TextStyle(
                        color: Colors.white54, fontSize: 10)),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: const [
                    SizedBox(width: 36),
                    SizedBox(width: 8),
                    Expanded(child: Text('PLAYER', style: TextStyle(
                        color: Color(0x80D4AF37), fontSize: 8,
                        fontWeight: FontWeight.w700, letterSpacing: 1))),
                    SizedBox(width: 50, child: Text('HANDS',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0x80D4AF37),
                            fontSize: 8, fontWeight: FontWeight.w700))),
                    SizedBox(width: 46, child: Text('WIN%',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0x80D4AF37),
                            fontSize: 8, fontWeight: FontWeight.w700))),
                    SizedBox(width: 60, child: Text('BIG WIN',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0x80D4AF37),
                            fontSize: 8, fontWeight: FontWeight.w700))),
                    SizedBox(width: 70, child: Text('BALANCE',
                        textAlign: TextAlign.right,
                        style: TextStyle(color: Color(0x80D4AF37),
                            fontSize: 8, fontWeight: FontWeight.w700))),
                  ]),
                ),
                const SizedBox(height: 6),
                Expanded(child: GestureDetector(
                  onTap: () {},
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _standings.length,
                    itemBuilder: (BuildContext ctx, int i) {
                      final e = _standings[i];
                      final isPlayer = e['isPlayer'] as bool;
                      final medals = ['🥇', '🥈', '🥉'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: isPlayer
                              ? const Color(0x25D4AF37)
                              : const Color(0x08FFFFFF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isPlayer
                                ? const Color(0x80D4AF37)
                                : const Color(0x15FFFFFF))),
                        child: Row(children: [
                          SizedBox(width: 36,
                              child: Center(child: i < 3
                                ? Text(medals[i],
                                    style: const TextStyle(fontSize: 16))
                                : Text('#${i + 1}',
                                    style: const TextStyle(
                                        color: Color(0x70D4AF37),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w800)))),
                          const SizedBox(width: 8),
                          Container(
                            width: 28, height: 28,
                            decoration: BoxDecoration(
                              color: kAvatarColors[
                                  (e['avatarIndex'] as int).clamp(
                                      0, kAvatarColors.length - 1)],
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isPlayer
                                    ? const Color(0xFFD4AF37)
                                    : Colors.transparent)),
                            child: Center(child: Text(
                              kAvatarEmojis[
                                  (e['avatarIndex'] as int).clamp(
                                      0, kAvatarEmojis.length - 1)],
                              style:
                                  const TextStyle(fontSize: 12)))),
                          const SizedBox(width: 8),
                          Expanded(child: Row(children: [
                            Text(e['name'] as String,
                                style: TextStyle(
                                  color: isPlayer
                                      ? const Color(0xFFD4AF37)
                                      : Colors.white,
                                  fontSize: 11,
                                  fontWeight: isPlayer
                                      ? FontWeight.w900
                                      : FontWeight.w500)),
                            if (isPlayer) ...[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0x40D4AF37),
                                  borderRadius:
                                      BorderRadius.circular(4)),
                                child: const Text('YOU',
                                    style: TextStyle(
                                        color: Color(0xFFD4AF37),
                                        fontSize: 7,
                                        fontWeight:
                                            FontWeight.w900))),
                            ],
                          ])),
                          SizedBox(width: 50,
                              child: Text('${e['handsPlayed']}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Colors.white60,
                                      fontSize: 11))),
                          SizedBox(width: 46,
                              child: Text(e['winRate'] as String,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Color(0xFF64B5F6),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700))),
                          SizedBox(width: 60,
                              child: Text(
                                  fmtMoney(e['biggestWin'] as int),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700))),
                          SizedBox(width: 70,
                              child: Text(
                                  fmtMoney(e['balance'] as int),
                                  textAlign: TextAlign.right,
                                  style: TextStyle(
                                    color: isPlayer
                                        ? const Color(0xFFD4AF37)
                                        : Colors.white,
                                    fontSize: 12,
                                    fontWeight:
                                        FontWeight.w900))),
                        ]),
                      );
                    },
                  ),
                )),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _showStandings = false),
                    child: Container(
                      width: double.infinity, height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFFE55C),
                              Color(0xFFD4AF37), Color(0xFFA07800)],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter),
                        borderRadius: BorderRadius.circular(23)),
                      child: const Center(child: Text(
                          'BACK TO GAME',
                          style: TextStyle(color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2))),
                    ),
                  ),
                ),
              ])),
            ),
          )),
      ]),
    );
  }
}

// ── Tournament Final Results Screen ───────────────────────────
class TournamentFinalScreen extends StatefulWidget {
  final TournamentConfig config;
  final int playerFinalBalance;
  final List<AiPlayer> aiPlayers;
  final Function(int) onDone;
  final bool earlyExit;
  const TournamentFinalScreen({super.key,
      required this.config, required this.playerFinalBalance,
      required this.aiPlayers, required this.onDone,
      this.earlyExit = false});
  @override State<TournamentFinalScreen> createState() =>
      _TournamentFinalScreenState();
}

class _TournamentFinalScreenState extends State<TournamentFinalScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;
  late List<Map<String, dynamic>> _results;
  late int _playerRank;
  late int _prize;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this,
        duration: const Duration(milliseconds: 800));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _scale = Tween<double>(begin: 0.8, end: 1).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack));
    _results = [];
    _results.add({
      'name': PlayerStorage.playerName,
      'avatarIndex': PlayerStorage.avatarIndex,
      'balance': widget.playerFinalBalance,
      'handsPlayed': 0,
      'handsWon': 0,
      'biggestWin': 0,
      'winRate': '—',
      'isPlayer': true,
      'personality': '👤',
    });
    for (final ai in widget.aiPlayers) {
      String emoji;
      switch (ai.personality) {
        case AiPersonality.aggressive: emoji = '🔴'; break;
        case AiPersonality.conservative: emoji = '🔵'; break;
        case AiPersonality.lucky: emoji = '🟡'; break;
        default: emoji = '⚪';
      }
      _results.add({
        'name': ai.name,
        'avatarIndex': ai.avatarIndex,
        'balance': ai.balance,
        'handsPlayed': ai.handsPlayed,
        'handsWon': ai.handsWon,
        'biggestWin': ai.biggestWin,
        'winRate': ai.winRateStr,
        'isPlayer': false,
        'personality': emoji,
      });
    }
    _results.sort((a, b) =>
        (b['balance'] as int).compareTo(a['balance'] as int));
    _playerRank =
        _results.indexWhere((e) => e['isPlayer'] == true) + 1;
    _prize = widget.earlyExit ? widget.config.participationPrize
        : _playerRank == 1 ? widget.config.prize1st
        : _playerRank == 2 ? widget.config.prize2nd
        : _playerRank == 3 ? widget.config.prize3rd
        : widget.config.participationPrize;
    if (_playerRank == 1) {
      PlayerStorage.checkAndAwardBadges(
        totalRounds: PlayerStorage.statRounds,
        totalWins: PlayerStorage.statWins,
        bestStreak: PlayerStorage.statBestStreak,
        justWon: false, tripleWin: false, sideHit: false,
        wasBroke: false, comeback: false, bigSpender: false,
        balance: widget.playerFinalBalance, handsWonThisRound: 0,
        enteredTournament: false, wonTournament: true,
        totalSideBetsSession: 0,
        totalWagered: PlayerStorage.statWagered,
      );
    }
    _ctrl.forward();
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final medals = ['🥇', '🥈', '🥉'];
    final isTop3 = _playerRank <= 3;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3), radius: 1.4,
            colors: [Color(0xFF1A1A3A), Color(0xFF0A0A20),
                Color(0xFF050510)])),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: FeltPainter())),
          SafeArea(child: FadeTransition(opacity: _fade,
                child: Column(children: [
                const SizedBox(height: 12),
                Text(widget.config.emoji,
                    style: const TextStyle(fontSize: 36)),
                const SizedBox(height: 4),
                Text(widget.config.name, style: const TextStyle(
                    color: Color(0xFFD4AF37), fontSize: 13,
                    fontWeight: FontWeight.w700, letterSpacing: 3)),
                const Text('FINAL RESULTS', style: TextStyle(
                    color: Colors.white38, fontSize: 9,
                    letterSpacing: 3)),
                const SizedBox(height: 12),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: isTop3
                      ? [const Color(0x30D4AF37),
                          const Color(0x10D4AF37)]
                      : [const Color(0x15FFFFFF),
                          const Color(0x08FFFFFF)]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isTop3
                          ? const Color(0xFFD4AF37)
                          : const Color(0x40FFFFFF),
                      width: isTop3 ? 2 : 1),
                    boxShadow: isTop3 ? const [BoxShadow(
                        color: Color(0x60D4AF37),
                        blurRadius: 20)] : [],
                  ),
                  child: Row(children: [
                    Text(isTop3
                        ? medals[_playerRank - 1]
                        : '#$_playerRank',
                        style: TextStyle(
                            fontSize: isTop3 ? 32 : 20,
                            color: const Color(0xFFD4AF37))),
                    const SizedBox(width: 14),
                    Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(PlayerStorage.playerName,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900)),
                      Text('Final: ${fmtMoney(widget.playerFinalBalance)}',
                          style: const TextStyle(
                              color: Color(0xFFD4AF37),
                              fontSize: 13,
                              fontWeight: FontWeight.w800)),
                    ])),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x20D4AF37),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0x60D4AF37))),
                      child: Column(children: [
                        const Text('PRIZE', style: TextStyle(
                            color: Color(0xFFD4AF37),
                            fontSize: 8, letterSpacing: 2,
                            fontWeight: FontWeight.w700)),
                        Text('+${fmtMoney(_prize)}',
                            style: const TextStyle(
                                color: Color(0xFFFFD700),
                                fontSize: 20,
                                fontWeight: FontWeight.w900)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: const [
                    SizedBox(width: 36),
                    SizedBox(width: 8),
                    Expanded(child: Text('PLAYER',
                        style: TextStyle(
                            color: Color(0x80D4AF37), fontSize: 8,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1))),
                    SizedBox(width: 46, child: Text('HANDS',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0x80D4AF37),
                            fontSize: 8,
                            fontWeight: FontWeight.w700))),
                    SizedBox(width: 40, child: Text('WIN%',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0x80D4AF37),
                            fontSize: 8,
                            fontWeight: FontWeight.w700))),
                    SizedBox(width: 56, child: Text('BIG WIN',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Color(0x80D4AF37),
                            fontSize: 8,
                            fontWeight: FontWeight.w700))),
                    SizedBox(width: 66, child: Text('BALANCE',
                        textAlign: TextAlign.right,
                        style: TextStyle(color: Color(0x80D4AF37),
                            fontSize: 8,
                            fontWeight: FontWeight.w700))),
                  ]),
                ),
                const SizedBox(height: 4),
                SizedBox(height: 220, child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _results.length,
                  itemBuilder: (BuildContext ctx, int i) {
                    final e = _results[i];
                    final isPlayer = e['isPlayer'] as bool;
                    final bal = e['balance'] as int;
                    final handsPlayed = e['handsPlayed'] as int;
                    final winRate = e['winRate'] as String;
                    final biggestWin = e['biggestWin'] as int;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 5),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isPlayer
                            ? [const Color(0x25D4AF37),
                                const Color(0x10D4AF37)]
                            : i < 3
                              ? [const Color(0x12FFFFFF),
                                  const Color(0x06FFFFFF)]
                              : [const Color(0x08FFFFFF),
                                  const Color(0x03FFFFFF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isPlayer
                              ? const Color(0x80D4AF37)
                              : i < 3
                                  ? const Color(0x30FFFFFF)
                                  : const Color(0x15FFFFFF),
                          width: isPlayer ? 1.5 : 1),
                      ),
                      child: Row(children: [
                        SizedBox(width: 36,
                            child: Center(child: i < 3
                              ? Text(medals[i],
                                  style: const TextStyle(fontSize: 15))
                              : Text('#${i + 1}',
                                  style: const TextStyle(
                                      color: Color(0x70D4AF37),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800)))),
                        const SizedBox(width: 8),
                        Container(
                          width: 26, height: 26,
                          decoration: BoxDecoration(
                            color: kAvatarColors[
                                (e['avatarIndex'] as int).clamp(
                                    0, kAvatarColors.length - 1)],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isPlayer
                                  ? const Color(0xFFD4AF37)
                                  : Colors.transparent,
                              width: 1.5)),
                          child: Center(child: Text(
                            kAvatarEmojis[
                                (e['avatarIndex'] as int).clamp(
                                    0, kAvatarEmojis.length - 1)],
                            style: const TextStyle(fontSize: 11)))),
                        const SizedBox(width: 8),
                        Expanded(child: Row(children: [
                          Flexible(child: Text(
                              e['name'] as String,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isPlayer
                                    ? const Color(0xFFD4AF37)
                                    : Colors.white,
                                fontSize: 11,
                                fontWeight: isPlayer
                                    ? FontWeight.w900
                                    : FontWeight.w500))),
                          if (isPlayer) ...[
                            const SizedBox(width: 3),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 3, vertical: 1),
                              decoration: BoxDecoration(
                                color: const Color(0x40D4AF37),
                                borderRadius:
                                    BorderRadius.circular(3)),
                              child: const Text('YOU',
                                  style: TextStyle(
                                      color: Color(0xFFD4AF37),
                                      fontSize: 6,
                                      fontWeight: FontWeight.w900))),
                          ] else ...[
                            const SizedBox(width: 3),
                            Text(e['personality'] as String,
                                style: const TextStyle(fontSize: 8)),
                          ],
                        ])),
                        SizedBox(width: 46,
                            child: Text('$handsPlayed',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white60,
                                    fontSize: 11))),
                        SizedBox(width: 40,
                            child: Text(winRate,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Color(0xFF64B5F6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700))),
                        SizedBox(width: 56,
                            child: Text(
                                biggestWin > 0
                                    ? fmtMoney(biggestWin) : '—',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700))),
                        SizedBox(width: 66,
                            child: Text(fmtMoney(bal),
                                textAlign: TextAlign.right,
                                style: TextStyle(
                                  color: isPlayer
                                      ? const Color(0xFFD4AF37)
                                      : Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900))),
                      ]),
                    );
                  },
                )),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: SizedBox(
width: double.infinity, height: 50,
child: ElevatedButton(
onPressed: ()  {
                   widget.onDone(_prize);
                   Navigator.of(context).popUntil((route) => route.isFirst);
                 },
style: ElevatedButton.styleFrom(
backgroundColor: const Color(0xFFD4AF37),
shape: RoundedRectangleBorder(
borderRadius: BorderRadius.circular(25)),
elevation: 8),
child: Text(
'CLAIM +${fmtMoney(_prize)}',
style: const TextStyle(
color: Colors.black,
fontSize: 15,
fontWeight: FontWeight.w900,
letterSpacing: 2)),
),
                ),
                ),
              ]),
            
          )),
        ]),
      ),
    );
  }
}
// ── Challenges Screen ─────────────────────────────────────────
class ChallengesScreen extends StatefulWidget {
  final Function(int) onChipsEarned;
  const ChallengesScreen({super.key, required this.onChipsEarned});
  @override State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  void _claim(DailyChallenge c) {
    final chips = ChallengeManager.claimReward(c.def.id);
    if (chips > 0) {
      PlayerStorage.saveChips(PlayerStorage.savedChips + chips);
      widget.onChipsEarned(chips);
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('🎯 +${fmtMoney(chips)} chips + ${c.def.xpReward} XP!'),
        backgroundColor: const Color(0xFF1B5E20),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  Color _diffColor(ChallengeDifficulty d) {
    switch (d) {
      case ChallengeDifficulty.easy: return const Color(0xFF4CAF50);
      case ChallengeDifficulty.medium: return const Color(0xFFFF9800);
      case ChallengeDifficulty.hard: return const Color(0xFFEF5350);
    }
  }

  String _diffLabel(ChallengeDifficulty d) {
    switch (d) {
      case ChallengeDifficulty.easy: return 'EASY';
      case ChallengeDifficulty.medium: return 'MEDIUM';
      case ChallengeDifficulty.hard: return 'HARD';
    }
  }

  @override
  Widget build(BuildContext context) {
    final challenges = ChallengeManager.todayChallenges;
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day + 1);
    final diff = midnight.difference(now);
    final timeStr = '${diff.inHours}h ${diff.inMinutes % 60}m';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3), radius: 1.4,
            colors: [Color(0xFF1E5C14), Color(0xFF0F3A0A), Color(0xFF061A04)])),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: FeltPainter())),
          SafeArea(child: Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xCC000000), Color(0x00000000)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0x40000000),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x40D4AF37))),
                    child: const Row(children: [
                      Icon(Icons.arrow_back_ios, color: Color(0xAAD4AF37), size: 12),
                      SizedBox(width: 4),
                      Text('BACK', style: TextStyle(color: Color(0xAAD4AF37),
                          fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ]),
                  ),
                ),
                const Spacer(),
                Column(children: [
                  const Text('DAILY CHALLENGES', style: TextStyle(
                      color: Color(0xFFD4AF37), fontSize: 16,
                      fontWeight: FontWeight.w900, letterSpacing: 3)),
                  Text('Resets in $timeStr', style: const TextStyle(
                      color: Colors.white54, fontSize: 9)),
                ]),
                const Spacer(),
                const SizedBox(width: 60),
              ]),
            ),

            // Progress summary
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0x15000000),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x40D4AF37))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _summaryCol('COMPLETED', '${ChallengeManager.completedCount}/3', const Color(0xFF4CAF50)),
                  Container(width: 1, height: 40, color: const Color(0x30FFFFFF)),
                  _summaryCol('CLAIMED', '${ChallengeManager.claimedCount}/3', const Color(0xFFD4AF37)),
                  Container(width: 1, height: 40, color: const Color(0x30FFFFFF)),
                  _summaryCol('TOTAL REWARD', fmtMoney(
                    challenges.where((c) => c.rewardClaimed).fold(0, (s, c) => s + c.def.chipReward)
                  ), const Color(0xFFFFD700)),
                ],
              ),
            ),

            // Challenge cards
            Expanded(child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              itemCount: challenges.length,
              itemBuilder: (BuildContext ctx, int i) {
                final c = challenges[i];
                final color = _diffColor(c.def.difficulty);
                final canClaim = c.completed && !c.rewardClaimed;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: c.completed
                        ? [color.withOpacity(0.15), const Color(0x08FFFFFF)]
                        : [const Color(0x10FFFFFF), const Color(0x06FFFFFF)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: c.completed ? color.withOpacity(0.6) : const Color(0x30FFFFFF),
                      width: c.completed ? 1.5 : 1),
                    boxShadow: c.completed ? [
                      BoxShadow(color: color.withOpacity(0.2), blurRadius: 12)
                    ] : [],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      // Title row
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: color.withOpacity(0.5))),
                          child: Text(_diffLabel(c.def.difficulty), style: TextStyle(
                              color: color, fontSize: 8,
                              fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(child: Text(c.def.title, style: const TextStyle(
                            color: Colors.white, fontSize: 16,
                            fontWeight: FontWeight.w900))),
                        if (c.rewardClaimed)
                          const Text('✅', style: TextStyle(fontSize: 20))
                        else if (c.completed)
                          const Text('🎯', style: TextStyle(fontSize: 20)),
                      ]),
                      const SizedBox(height: 6),
                      Text(c.def.description, style: const TextStyle(
                          color: Colors.white60, fontSize: 11)),
                      const SizedBox(height: 14),

                      // Progress bar
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: c.progressPct,
                              minHeight: 8,
                              backgroundColor: const Color(0x20FFFFFF),
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text('${c.progress.clamp(0, c.def.target)}/${c.def.target}',
                              style: TextStyle(color: color,
                                  fontSize: 10, fontWeight: FontWeight.w700)),
                        ])),
                        const SizedBox(width: 14),
                        // Reward
                        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                          Text('+${fmtMoney(c.def.chipReward)}', style: const TextStyle(
                              color: Color(0xFFD4AF37), fontSize: 14,
                              fontWeight: FontWeight.w900)),
                          Text('+${c.def.xpReward} XP', style: const TextStyle(
                              color: Colors.white54, fontSize: 9)),
                        ]),
                      ]),

                      // Claim button
                      if (canClaim) ...[
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _claim(c),
                          child: Container(
                            width: double.infinity, height: 42,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFFFE55C), Color(0xFFD4AF37), Color(0xFFA07800)],
                                begin: Alignment.topCenter, end: Alignment.bottomCenter),
                              borderRadius: BorderRadius.circular(21),
                              boxShadow: const [BoxShadow(
                                  color: Color(0x80D4AF37), blurRadius: 10)]),
                            child: Center(child: Text(
                              'CLAIM +${fmtMoney(c.def.chipReward)}',
                              style: const TextStyle(color: Colors.black,
                                  fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2))),
                          ),
                        ),
                      ],
                    ]),
                  ),
                );
              },
            )),
          ])),
        ]),
      ),
    );
  }

  Widget _summaryCol(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(color: color,
          fontSize: 16, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: Colors.white54,
          fontSize: 8, letterSpacing: 1)),
    ]);
  }
}

// ── VIP Screen ────────────────────────────────────────────────
class VipScreen extends StatelessWidget {
  const VipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final level = PlayerStorage.level.level;
    final currentVip = getVipTier(level);
    final nextVip = getNextVipTier(level);
    final xp = PlayerStorage.xp;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.3), radius: 1.4,
            colors: [
              currentVip.color.withOpacity(0.3),
              const Color(0xFF0A0A20),
              const Color(0xFF050510),
            ]),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: FeltPainter())),
          SafeArea(child: Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xCC000000), Color(0x00000000)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: const Color(0x40000000),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0x40D4AF37))),
                    child: const Row(children: [
                      Icon(Icons.arrow_back_ios, color: Color(0xAAD4AF37), size: 12),
                      SizedBox(width: 4),
                      Text('BACK', style: TextStyle(color: Color(0xAAD4AF37),
                          fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    ]),
                  ),
                ),
                const Spacer(),
                Text('VIP STATUS', style: TextStyle(
                    color: currentVip.color, fontSize: 18,
                    fontWeight: FontWeight.w900, letterSpacing: 4)),
                const Spacer(),
                const SizedBox(width: 60),
              ]),
            ),

            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(children: [
                // Current tier card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [currentVip.color.withOpacity(0.25), const Color(0x10000000)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: currentVip.color.withOpacity(0.7), width: 2),
                    boxShadow: [BoxShadow(color: currentVip.color.withOpacity(0.4), blurRadius: 24)]),
                  child: Column(children: [
                    Text(currentVip.emoji, style: const TextStyle(fontSize: 52)),
                    const SizedBox(height: 8),
                    Text('${currentVip.name} MEMBER', style: TextStyle(
                        color: currentVip.color, fontSize: 22,
                        fontWeight: FontWeight.w900, letterSpacing: 3)),
                    const SizedBox(height: 4),
                    Text('Level $level  •  ${PlayerStorage.level.title}',
                        style: const TextStyle(color: Colors.white60, fontSize: 12)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0x20000000),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: currentVip.color.withOpacity(0.3))),
                      child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                        _statCol('MAX BET', fmtMoney(currentVip.maxBet), currentVip.color),
                        Container(width: 1, height: 36, color: const Color(0x30FFFFFF)),
                        _statCol('TOTAL XP', '$xp XP', currentVip.color),
                        Container(width: 1, height: 36, color: const Color(0x30FFFFFF)),
                        _statCol('TABLES', '${kTableThemes.where((t) => isTableUnlocked(t, level)).length}/${kTableThemes.length}', currentVip.color),
                      ]),
                    ),
                    const SizedBox(height: 12),
                    Text(currentVip.perk, textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    const SizedBox(height: 12),
                    Builder(builder: (BuildContext ctx) =>
                      ShareHelper.shareBtn(ctx,
                        ShareHelper.vipTier(currentVip),
                        label: 'SHARE VIP STATUS')),
                  ]),
                ),

                // Next tier progress
                if (nextVip != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0x15000000),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x30FFFFFF))),
                    child: Column(children: [
                      Row(children: [
                        Text(nextVip.emoji, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Next: ${nextVip.name}', style: TextStyle(
                              color: nextVip.color, fontSize: 13, fontWeight: FontWeight.w800)),
                          Text('Reach Level ${nextVip.minLevel}',
                              style: const TextStyle(color: Colors.white54, fontSize: 10)),
                        ])),
                        Text('${nextVip.minLevel - level} levels away',
                            style: const TextStyle(color: Colors.white54, fontSize: 10)),
                      ]),
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (level - currentVip.minLevel) /
                              (nextVip.minLevel - currentVip.minLevel),
                          minHeight: 8,
                          backgroundColor: const Color(0x20FFFFFF),
                          valueColor: AlwaysStoppedAnimation<Color>(nextVip.color),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text('Unlocks: ${nextVip.perk}',
                          style: const TextStyle(color: Colors.white38, fontSize: 9)),
                    ]),
                  ),
                ],

                // All tiers
                const Align(alignment: Alignment.centerLeft,
                  child: Text('ALL TIERS', style: TextStyle(
                      color: Color(0xFFD4AF37), fontSize: 11,
                      fontWeight: FontWeight.w800, letterSpacing: 3))),
                const SizedBox(height: 12),
                ...kVipTiers.map((tier) {
                  final reached = level >= tier.minLevel;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: reached
                        ? LinearGradient(colors: [
                            tier.color.withOpacity(0.15), const Color(0x08FFFFFF)])
                        : null,
                      color: reached ? null : const Color(0x08FFFFFF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: reached ? tier.color.withOpacity(0.5) : const Color(0x20FFFFFF),
                        width: reached ? 1.5 : 1),
                      boxShadow: reached ? [
                        BoxShadow(color: tier.color.withOpacity(0.2), blurRadius: 8)
                      ] : [],
                    ),
                    child: Row(children: [
                      Text(reached ? tier.emoji : '🔒',
                          style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(tier.name, style: TextStyle(
                            color: reached ? tier.color : Colors.white38,
                            fontSize: 14, fontWeight: FontWeight.w800)),
                        Text('Level ${tier.minLevel}+  •  Max bet: ${fmtMoney(tier.maxBet)}',
                            style: TextStyle(
                                color: reached ? Colors.white54 : Colors.white24,
                                fontSize: 9)),
                        Text(tier.perk, style: TextStyle(
                            color: reached ? Colors.white60 : Colors.white24,
                            fontSize: 9)),
                      ])),
                      if (tier == currentVip) Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: tier.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: tier.color.withOpacity(0.5))),
                        child: Text('CURRENT', style: TextStyle(
                            color: tier.color, fontSize: 7, fontWeight: FontWeight.w900))),
                    ]),
                  );
                }),

                const SizedBox(height: 16),
                // Tables unlocked section
                const Align(alignment: Alignment.centerLeft,
                  child: Text('TABLE UNLOCKS', style: TextStyle(
                      color: Color(0xFFD4AF37), fontSize: 11,
                      fontWeight: FontWeight.w800, letterSpacing: 3))),
                const SizedBox(height: 12),
                ...kTableThemes.map((t) {
                  final unlocked = isTableUnlocked(t, level);
                  final vip = getVipTier(t.requiredLevel);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: unlocked
                        ? LinearGradient(colors: t.tableGradient,
                            begin: Alignment.centerLeft, end: Alignment.centerRight)
                        : null,
                      color: unlocked ? null : const Color(0x08FFFFFF),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: unlocked ? t.accentColor.withOpacity(0.5) : const Color(0x20FFFFFF))),
                    child: Row(children: [
                      Container(
                        width: 44, height: 30,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: unlocked ? t.tableGradient : [const Color(0x20FFFFFF), const Color(0x10FFFFFF)]),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: unlocked
                              ? t.accentColor.withOpacity(0.6) : const Color(0x20FFFFFF))),
                        child: unlocked
                          ? Center(child: CustomPaint(
                              size: const Size(44, 30),
                              painter: _MiniTablePainter(t.feltLineColor)))
                          : const Center(child: Text('🔒', style: TextStyle(fontSize: 12))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(t.name, style: TextStyle(
                          color: unlocked ? Colors.white : Colors.white38,
                          fontSize: 12, fontWeight: FontWeight.w700))),
                      Text('${vip.emoji} ${t.vipTier}', style: TextStyle(
                          color: unlocked ? vip.color : Colors.white24,
                          fontSize: 10, fontWeight: FontWeight.w700)),
                    ]),
                  );
                }),
              ]),
            )),
          ])),
        ]),
      ),
    );
  }

  Widget _statCol(String label, String value, Color color) {
    return Column(children: [
      Text(value, style: TextStyle(color: color,
          fontSize: 13, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: Colors.white54,
          fontSize: 8, letterSpacing: 1)),
    ]);
  }
}

// ── Friends Screen ────────────────────────────────────────────
class FriendsScreen extends StatefulWidget {
  const FriendsScreen({super.key});
  @override State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _codeCtrl = TextEditingController();
  String _error = '';
  String _successMsg = '';
  bool _showMyCode = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() { _tabs.dispose(); _codeCtrl.dispose(); super.dispose(); }

  void _addFriend() {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) { setState(() => _error = 'Enter a friend code'); return; }
    final result = PlayerStorage.addFriend(code);
    if (result != null && result != 'REFERRAL_BONUS') {
      setState(() { _error = result; _successMsg = ''; });
    } else if (result == 'REFERRAL_BONUS') {
      setState(() { _error = ''; _successMsg = ''; _codeCtrl.clear(); });
      _showReferralBonus();
    } else {
      setState(() { _error = ''; _successMsg = 'Stats updated for your friend!'; _codeCtrl.clear(); });
    }
  }

  void _showReferralBonus() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1B5E20), Color(0xFF0D3A10)],
              begin: Alignment.topCenter, end: Alignment.bottomCenter),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF4CAF50), width: 2),
            boxShadow: const [
              BoxShadow(color: Color(0x604CAF50), blurRadius: 30),
              BoxShadow(color: Color(0x304CAF50), blurRadius: 60, spreadRadius: 4),
            ]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Text('🎉', style: TextStyle(fontSize: 52)),
            const SizedBox(height: 8),
            const Text('FRIEND ADDED!', style: TextStyle(
                color: Color(0xFF4CAF50), fontSize: 14,
                fontWeight: FontWeight.w900, letterSpacing: 3)),
            const SizedBox(height: 16),
            const Text('REFERRAL BONUS', style: TextStyle(
                color: Color(0xFFD4AF37), fontSize: 10,
                fontWeight: FontWeight.w700, letterSpacing: 3)),
            const SizedBox(height: 6),
            ShaderMask(
              shaderCallback: (b) => const LinearGradient(
                colors: [Color(0xFFFFD700), Color(0xFFD4AF37)]).createShader(b),
              child: const Text('+\$2,000', style: TextStyle(
                  color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900, height: 1)),
            ),
            const SizedBox(height: 4),
            const Text('chips added to your balance', style: TextStyle(
                color: Colors.white54, fontSize: 11)),
            const SizedBox(height: 6),
            const Text('You both get this bonus when\nyou add each other!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 10)),
            const SizedBox(height: 12),
            // Share on social
            ShareHelper.shareBtn(ctx,
              ShareHelper.friendReferral(PlayerStorage.playerCode),
              label: 'SHARE & GET MORE FRIENDS'),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () { Navigator.pop(ctx); setState(() {}); },
              child: Container(
                width: double.infinity, height: 48,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFFE55C), Color(0xFFD4AF37), Color(0xFFA07800)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [BoxShadow(
                      color: Color(0x80D4AF37), blurRadius: 12)]),
                child: const Center(child: Text('AWESOME!',
                    style: TextStyle(color: Colors.black,
                        fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 3))),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Color _avatarColor(int idx) =>
      kAvatarColors[idx.clamp(0, kAvatarColors.length - 1)];

  @override
  Widget build(BuildContext context) {
    final myCode = PlayerStorage.playerCode;
    final myShareCode = PlayerStorage.generateShareCode();
    final friends = PlayerStorage.friends;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3), radius: 1.4,
            colors: [Color(0xFF1E5C14), Color(0xFF0F3A0A), Color(0xFF061A04)])),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: FeltPainter())),
          SafeArea(child: Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xCC000000), Color(0x00000000)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              child: Column(children: [
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0x40000000),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x40D4AF37))),
                      child: const Row(children: [
                        Icon(Icons.arrow_back_ios, color: Color(0xAAD4AF37), size: 12),
                        SizedBox(width: 4),
                        Text('BACK', style: TextStyle(color: Color(0xAAD4AF37),
                            fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1)),
                      ]),
                    ),
                  ),
                  const Spacer(),
                  const Text('FRIENDS', style: TextStyle(color: Color(0xFFD4AF37),
                      fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 4)),
                  const Spacer(),
                  Text('${friends.length}/20', style: const TextStyle(
                      color: Colors.white54, fontSize: 10)),
                ]),
                const SizedBox(height: 12),
                TabBar(
                  controller: _tabs,
                  indicatorColor: const Color(0xFFD4AF37),
                  indicatorWeight: 2,
                  labelColor: const Color(0xFFD4AF37),
                  unselectedLabelColor: const Color(0x60FFFFFF),
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1),
                  tabs: [
                    Tab(text: 'FRIENDS (${friends.length})'),
                    const Tab(text: 'ADD FRIEND'),
                  ],
                ),
              ]),
            ),

            Expanded(child: TabBarView(
              controller: _tabs,
              children: [
                // ── Friends list tab ──────────────────────────
                friends.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Text('👥', style: TextStyle(fontSize: 48)),
                      const SizedBox(height: 12),
                      const Text('NO FRIENDS YET', style: TextStyle(
                          color: Color(0xFFD4AF37), fontSize: 14,
                          fontWeight: FontWeight.w800, letterSpacing: 3)),
                      const SizedBox(height: 8),
                      const Text('Share your code and add friends\nto compare stats',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Color(0x60FFFFFF), fontSize: 11)),
                      const SizedBox(height: 24),
                      // Your code card
                      _myCodeCard(myCode, myShareCode),
                    ]))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        _myCodeCard(myCode, myShareCode),
                        const SizedBox(height: 16),
                        const Text('YOUR FRIENDS', style: TextStyle(
                            color: Color(0xFFD4AF37), fontSize: 10,
                            fontWeight: FontWeight.w800, letterSpacing: 2)),
                        const SizedBox(height: 10),
                        ...friends.map((f) {
                          final name = f['name'] ?? '?';
                          final avatarIdx = int.tryParse(f['avatarIndex'] ?? '0') ?? 0;
                          final chips = int.tryParse(f['chips'] ?? '0') ?? 0;
                          final rounds = int.tryParse(f['rounds'] ?? '0') ?? 0;
                          final wins = int.tryParse(f['wins'] ?? '0') ?? 0;
                          final level = int.tryParse(f['level'] ?? '1') ?? 1;
                          final streak = int.tryParse(f['bestStreak'] ?? '0') ?? 0;
                          final bigWin = int.tryParse(f['biggestWin'] ?? '0') ?? 0;
                          final winRate = rounds > 0
                              ? '${(wins / rounds * 100).toStringAsFixed(0)}%' : '—';
                          final lvl = getLevelForXP(int.tryParse(f['xp'] ?? '0') ?? 0);
                          final vip = getVipTier(level);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: const Color(0x12FFFFFF),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0x30D4AF37))),
                            child: Column(children: [
                              // Header
                              Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(children: [
                                  Container(
                                    width: 44, height: 44,
                                    decoration: BoxDecoration(
                                      color: _avatarColor(avatarIdx),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: lvl.color, width: 2)),
                                    child: Center(child: Text(
                                      kAvatarEmojis[(name.hashCode.abs()) % kAvatarEmojis.length],
                                      style: const TextStyle(color: Colors.white,
                                          fontSize: 18, fontWeight: FontWeight.w900))),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start, children: [
                                    Text(name, style: const TextStyle(
                                        color: Colors.white, fontSize: 15,
                                        fontWeight: FontWeight.w800)),
                                    Row(children: [
                                      Text('${vip.emoji} ${vip.name}  •  ',
                                          style: TextStyle(color: vip.color, fontSize: 9)),
                                      Text('Lv.$level ${lvl.title}',
                                          style: TextStyle(color: lvl.color, fontSize: 9)),
                                    ]),
                                  ])),
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (BuildContext ctx) => AlertDialog(
                                          backgroundColor: const Color(0xFF0A1A08),
                                          shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(16)),
                                          title: Text('Remove $name?',
                                              style: const TextStyle(color: Color(0xFFD4AF37),
                                                  fontWeight: FontWeight.w800)),
                                          content: const Text('They can be re-added with their code.',
                                              style: TextStyle(color: Colors.white70)),
                                          actions: [
                                            TextButton(onPressed: () => Navigator.pop(ctx),
                                                child: const Text('CANCEL',
                                                    style: TextStyle(color: Color(0xFFD4AF37)))),
                                            TextButton(onPressed: () {
                                              PlayerStorage.removeFriend(f['code'] ?? '');
                                              Navigator.pop(ctx);
                                              setState(() {});
                                            }, child: const Text('REMOVE',
                                                style: TextStyle(color: Color(0xFFEF5350)))),
                                          ],
                                        ),
                                      );
                                    },
                                    child: const Icon(Icons.more_vert,
                                        color: Colors.white38, size: 18),
                                  ),
                                ]),
                              ),
                              // Stats grid
                              Container(
                                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _fStat('BALANCE', fmtMoney(chips)),
                                    _fStat('WIN RATE', winRate),
                                    _fStat('STREAK', '$streak 🔥'),
                                    _fStat('BIG WIN', fmtMoney(bigWin)),
                                  ],
                                ),
                              ),
                              // Compare bar — who's winning
                              _compareBar(
                                PlayerStorage.savedChips, chips,
                                PlayerStorage.playerName, name),
                            ]),
                          );
                        }),
                      ],
                    ),

                // ── Add friend tab ────────────────────────────
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                  child: Column(children: [
                    // My code section
                    _myCodeCard(myCode, myShareCode),
                    const SizedBox(height: 24),
                    const Align(alignment: Alignment.centerLeft,
                      child: Text('ADD A FRIEND', style: TextStyle(
                          color: Color(0xFFD4AF37), fontSize: 11,
                          fontWeight: FontWeight.w800, letterSpacing: 3))),
                    const SizedBox(height: 6),
                    const Text('Ask your friend to share their code from this screen, then paste it below.',
                        style: TextStyle(color: Colors.white54, fontSize: 10)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _codeCtrl,
                      style: const TextStyle(color: Colors.white, fontSize: 13,
                          fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        hintText: 'Paste friend\'s share code here...',
                        hintStyle: const TextStyle(color: Color(0x40FFFFFF)),
                        filled: true,
                        fillColor: const Color(0x20FFFFFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0x60D4AF37))),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0x60D4AF37))),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFD4AF37), width: 2)),
                        contentPadding: const EdgeInsets.all(14),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear, color: Colors.white38, size: 18),
                          onPressed: () => _codeCtrl.clear()),
                      ),
                    ),
                    if (_error.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_error, style: const TextStyle(
                          color: Color(0xFFEF5350), fontSize: 11)),
                    ],
                    if (_successMsg.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(_successMsg, style: const TextStyle(
                          color: Color(0xFF4CAF50), fontSize: 11,
                          fontWeight: FontWeight.w700)),
                    ],
                    const SizedBox(height: 14),
                    GestureDetector(
                      onTap: _addFriend,
                      child: Container(
                        width: double.infinity, height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFE55C), Color(0xFFD4AF37), Color(0xFFA07800)],
                            begin: Alignment.topCenter, end: Alignment.bottomCenter),
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: const [BoxShadow(
                              color: Color(0x80D4AF37), blurRadius: 12)]),
                        child: const Center(child: Text('ADD FRIEND',
                            style: TextStyle(color: Colors.black,
                                fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2))),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0x10FFFFFF),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x20FFFFFF))),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('HOW IT WORKS', style: TextStyle(
                            color: Color(0xFFD4AF37), fontSize: 10,
                            fontWeight: FontWeight.w800, letterSpacing: 2)),
                        SizedBox(height: 8),
                        Text('1. Share your code with a friend',
                            style: TextStyle(color: Colors.white60, fontSize: 10)),
                        Text('2. They paste it in their game to add you',
                            style: TextStyle(color: Colors.white60, fontSize: 10)),
                        Text('3. You do the same with their code',
                            style: TextStyle(color: Colors.white60, fontSize: 10)),
                        Text('4. Both players get +\$2,000 chips! 🎉',
                            style: TextStyle(color: Color(0xFF4CAF50),
                                fontSize: 10, fontWeight: FontWeight.w700)),
                        SizedBox(height: 4),
                        Text('5. Stats update each time you re-share your code',
                            style: TextStyle(color: Colors.white60, fontSize: 10)),
                      ]),
                    ),
                  ]),
                ),
              ],
            )),
          ])),
        ]),
      ),
    );
  }

  Widget _myCodeCard(String myCode, String shareCode) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0x20D4AF37), Color(0x10D4AF37)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x60D4AF37), width: 1.5),
        boxShadow: const [BoxShadow(color: Color(0x30D4AF37), blurRadius: 10)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: kAvatarColors[PlayerStorage.avatarIndex],
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFD4AF37), width: 1.5)),
            child: Center(child: Text(
              PlayerStorage.playerName.isNotEmpty
                  ? kAvatarEmojis[PlayerStorage.avatarIndex.clamp(0, kAvatarEmojis.length-1)] : '?',
              style: const TextStyle(color: Colors.white,
                  fontSize: 16, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(PlayerStorage.playerName, style: const TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
            const Text('YOUR PROFILE', style: TextStyle(
                color: Color(0x80D4AF37), fontSize: 8, letterSpacing: 2)),
          ]),
        ]),
        const SizedBox(height: 12),
        const Text('YOUR CODE', style: TextStyle(
            color: Color(0xFFD4AF37), fontSize: 9,
            fontWeight: FontWeight.w700, letterSpacing: 2)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0x20000000),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0x40D4AF37))),
          child: Text(myCode, style: const TextStyle(
              color: Color(0xFFFFD700), fontSize: 18,
              fontWeight: FontWeight.w900, fontFamily: 'monospace', letterSpacing: 2)),
        ),
        const SizedBox(height: 10),
        // Share referral on social
        Builder(builder: (BuildContext ctx) => ShareHelper.shareBtn(ctx,
          ShareHelper.friendReferral(PlayerStorage.playerCode),
          label: 'SHARE CODE ON SOCIAL MEDIA')),
        const SizedBox(height: 6),
        const Text('Share to get +\$2,000 chips when friends add your code!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0x80D4AF37), fontSize: 9)),
        const SizedBox(height: 10),
        GestureDetector(
          onTap: () => setState(() => _showMyCode = !_showMyCode),
          child: Container(
            width: double.infinity, height: 40,
            decoration: BoxDecoration(
              color: const Color(0x20D4AF37),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0x40D4AF37))),
            child: Center(child: Text(
              _showMyCode ? 'HIDE SHARE CODE' : 'SHOW SHARE CODE (for friends to add you)',
              style: const TextStyle(color: Color(0xFFD4AF37),
                  fontSize: 10, fontWeight: FontWeight.w700))),
          ),
        ),
        if (_showMyCode) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0x15000000),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x30D4AF37))),
            child: SelectableText(
              shareCode,
              style: const TextStyle(color: Colors.white60,
                  fontSize: 8, fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 4),
          const Text('Copy this entire code and send to your friend',
              style: TextStyle(color: Colors.white38, fontSize: 9)),
        ],
      ]),
    );
  }

  Widget _fStat(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(
          color: Colors.white, fontSize: 12, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(
          color: Colors.white38, fontSize: 7, letterSpacing: 1)),
    ]);
  }

  Widget _compareBar(int myChips, int friendChips, String myName, String friendName) {
    if (myChips + friendChips == 0) return const SizedBox.shrink();
    final myPct = myChips / (myChips + friendChips);
    final isWinning = myChips >= friendChips;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(myName, style: TextStyle(
              color: isWinning ? const Color(0xFF4CAF50) : Colors.white54,
              fontSize: 9, fontWeight: FontWeight.w700)),
          Text('vs', style: const TextStyle(color: Colors.white38, fontSize: 8)),
          Text(friendName, style: TextStyle(
              color: !isWinning ? const Color(0xFFEF5350) : Colors.white54,
              fontSize: 9, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Row(children: [
            Expanded(flex: (myPct * 100).round(), child: Container(
              height: 8, color: const Color(0xFF4CAF50))),
            Expanded(flex: ((1 - myPct) * 100).round(), child: Container(
              height: 8, color: const Color(0xFFEF5350))),
          ]),
        ),
      ]),
    );
  }
}

// ── Legal Screen (Privacy Policy + Terms of Service) ──────────
// ── How To Play Screen ────────────────────────────────────────
class HowToPlayScreen extends StatefulWidget {
  const HowToPlayScreen({super.key});
  @override State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.3), radius: 1.4,
            colors: [Color(0xFF1E5C14), Color(0xFF0F3A0A), Color(0xFF061A04)])),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: FeltPainter())),
          SafeArea(child: Column(children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [Color(0xCC000000), Color(0x00000000)],
                    begin: Alignment.topCenter, end: Alignment.bottomCenter)),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0x20FFFFFF),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0x30FFFFFF))),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18)),
                ),
                const SizedBox(width: 14),
                const Text('HOW TO PLAY', style: TextStyle(
                    color: Color(0xFFD4AF37), fontSize: 20,
                    fontWeight: FontWeight.w900, letterSpacing: 2)),
              ]),
            ),
            // Tabs
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(children: [
                _tabBtn('THE GAME', 0),
                const SizedBox(width: 8),
                _tabBtn('SIDE BET', 1),
                const SizedBox(width: 8),
                _tabBtn('SCORING', 2),
              ]),
            ),
            // Content
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: _tab == 0 ? _gameTab() : _tab == 1 ? _sideBetTab() : _scoringTab(),
            )),
          ])),
        ]),
      ),
    );
  }

  Widget _tabBtn(String label, int index) {
    final active = _tab == index;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          gradient: active ? const LinearGradient(
            colors: [Color(0xFFD4AF37), Color(0xFFA07800)]) : null,
          color: active ? null : const Color(0x15FFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? const Color(0xFFD4AF37) : const Color(0x30FFFFFF))),
        child: Center(child: Text(label, style: TextStyle(
            color: active ? Colors.black : Colors.white54,
            fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1))),
      ),
    ));
  }

  Widget _section(String emoji, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(
              color: Color(0xFFD4AF37), fontSize: 14,
              fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 6),
          Text(body, style: const TextStyle(
              color: Colors.white70, fontSize: 13, height: 1.5)),
        ])),
      ]),
    );
  }

  Widget _gameTab() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: const Color(0x20D4AF37),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x40D4AF37))),
        child: const Text(
          'Triple Threat Blackjack is standard blackjack played across 3 hands simultaneously. '
          'You receive 6 cards and arrange them into 3 hands of 2 cards each — giving you full strategic control before the action begins.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5)),
      ),
      _section('💥', 'TRIPLE WIN BONUS',
        'Win all 3 hands in a single round to earn a Triple Threat Bonus — your bet is paid an extra 1.5x on top of all 3 hand wins!'),
      _section('🃏', 'BLACKJACK',
        'An Ace + any 10-value card on your starting 2 cards = Blackjack. Pays 1:1 — the arrangement advantage is your reward.'),
      _section('✂️', 'SPLIT',
        'If your 2 cards are the same regardless of suit, you can Split into 2 separate hands. Each gets an additional card. Split Aces auto-stand.'),
      _section('⬆️', 'DOUBLE DOWN',
        'Double your bet and receive exactly one more card. Only available on your initial 2 cards (no split hands).'),
      _section('🛡️', 'INSURANCE',
        'When the dealer shows an Ace, you may take Insurance for half your total bet. Pays 2:1 if dealer has blackjack.'),
      _section('🃏', 'THE DECK',
        'Triple Threat Blackjack uses 7 standard decks shuffled together. 35 cards are burned at the start of each shoe.'),
      _section('🏦', 'DEALER RULES',
        'Dealer must hit on 16 or below, stand on hard 17 or above, and hit soft 17.'),
    ]);
  }

  Widget _sideBetTab() {
    return Column(children: [
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0x156A1B9A),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0x406A1B9A))),
        child: const Text(
          'Place a side bet before the deal. Your 6 cards are evaluated for special combinations — the rarer the hand, the bigger the payout!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.5)),
      ),
      ...sideOddsList.map((o) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0x10FFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x20FFFFFF))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(o.name, style: const TextStyle(color: Colors.white, fontSize: 13)),
            Text('${o.pays} to 1', style: const TextStyle(
                color: Color(0xFFCE93D8), fontSize: 13, fontWeight: FontWeight.w800)),
          ]),
      )),
    ]);
  }

  Widget _scoringTab() {
    return Column(children: [
      _section('⭐', 'XP & LEVELS',
        'Earn XP every round. Win hands, hit side bets, and go on streaks to earn bonus XP. Level up to unlock new table themes and higher VIP tiers.'),
      _section('💎', 'VIP TIERS',
        'Bronze → Silver → Gold → Platinum → Diamond. Higher tiers unlock bigger max bets, exclusive table themes, and prestige status.'),
      _section('🎯', 'DAILY CHALLENGES',
        'Three challenges refresh every day — Easy, Medium, and Hard. Complete them for bonus chips and XP. Check the menu to claim rewards.'),
      _section('🏆', 'TOURNAMENTS',
        'Enter timed tournaments with a fixed starting balance. Your final balance determines your rank. Top 3 earn prize chips.'),
      _section('🔥', 'WIN STREAKS',
        'Win consecutive rounds to build your streak. Streaks appear on the leaderboard and unlock the On Fire and Unstoppable badges.'),
      _section('🏅', 'BADGES',
        'Earn badges for milestones like winning your first hand, hitting a side bet, going on a 10-win streak, and more. Legendary badges take serious dedication.'),
      _section('📊', 'LEADERBOARD',
        'Your net profit, best streak, win rate, and biggest single win are all tracked. Compete across 4 leaderboard categories.'),
      _section('👥', 'FRIENDS',
        'Share your player code to add friends. Both players receive \$2,000 bonus chips on first add. Compare stats head-to-head.'),
      _section('🎁', 'DAILY BONUS',
        'Claim free chips every 24 hours from the splash screen. Build your streak for bigger daily rewards. Set up notifications so you never miss it.'),
    ]);
  }
}
class LegalScreen extends StatefulWidget {
  const LegalScreen({super.key});
  @override State<LegalScreen> createState() => _LegalScreenState();
}

class _LegalScreenState extends State<LegalScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1A0A),
      body: SafeArea(
        child: Column(children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0x20FFFFFF),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x30FFFFFF))),
                  child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18)),
              ),
              const SizedBox(width: 14),
              const Text('Legal', style: TextStyle(
                  color: Color(0xFFD4AF37), fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ]),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(children: [
              _tab == 0 ? _activeTab('Privacy Policy') : _inactiveTab('Privacy Policy', () => setState(() => _tab = 0)),
              const SizedBox(width: 8),
              _tab == 1 ? _activeTab('Terms of Service') : _inactiveTab('Terms of Service', () => setState(() => _tab = 1)),
            ]),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
              child: _tab == 0 ? _privacyContent() : _termsContent(),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _activeTab(String label) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFFD4AF37), Color(0xFFA07800)]),
        borderRadius: BorderRadius.circular(10)),
      child: Center(child: Text(label, style: const TextStyle(color: Colors.black, fontSize: 12, fontWeight: FontWeight.w900))),
    ),
  );

  Widget _inactiveTab(String label, VoidCallback onTap) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0x15FFFFFF),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0x30FFFFFF))),
        child: Center(child: Text(label, style: const TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.w700))),
      ),
    ),
  );

  Widget _section(String title, String body) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(color: Color(0xFFD4AF37), fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 1)),
      const SizedBox(height: 6),
      Text(body, style: const TextStyle(color: Colors.white70, fontSize: 11, height: 1.6)),
    ]),
  );

  Widget _privacyContent() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Last updated: May 2026', style: TextStyle(color: Colors.white38, fontSize: 10)),
    const SizedBox(height: 16),
    _section('Information We Collect',
      'Triple Threat Blackjack stores only what is needed to run the game:\n\n'
      '• Gameplay data (chips, stats, level, badges) stored locally on your device\n'
      '• A randomly generated player code for the friend referral system\n'
      '• Optional display name and avatar chosen during setup\n\n'
      'We do not collect your real name, email, or any personally identifiable information unless you sign in with a social account.'),
    _section('How We Use Your Information',
      'All data is stored locally via browser localStorage and used solely to:\n\n'
      '• Save your progress between sessions\n'
      '• Display your stats and achievements\n'
      '• Enable the friend referral feature\n\n'
      'We do not sell, rent, or share your data with third parties.'),
    _section('Purchases & Payments',
      'Optional in-app purchases provide virtual chips with no real-world monetary value. Purchases are processed by the App Store or Google Play. We do not store payment information.'),
    _section('Children\'s Privacy',
      'Triple Threat Blackjack is intended for users 17 and older. We do not knowingly collect data from children under 13.'),
    _section('Data Security',
      'Your game data is stored locally on your device and is not transmitted to external servers.'),
    _section('Contact Us', 'Questions? Email us at:\ntriplethreatblackjack@gmail.com'),
  ]);

  Widget _termsContent() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    const Text('Last updated: May 2026', style: TextStyle(color: Colors.white38, fontSize: 10)),
    const SizedBox(height: 16),
    _section('Acceptance of Terms',
      'By using Triple Threat Blackjack you agree to these Terms. If you do not agree, do not use the App.'),
    _section('Entertainment Only — No Real Money',
      'Triple Threat Blackjack is a FREE social casino game for ENTERTAINMENT PURPOSES ONLY. It does not offer real money gambling. Virtual chips have no monetary value and cannot be redeemed for cash or prizes.'),
    _section('Eligibility',
      'You must be at least 17 years of age to use this App.'),
    _section('Virtual Currency & Purchases',
      'In-app chip purchases are final and non-refundable except as required by law. Virtual chips are licensed to you, not sold, and may be modified at any time.'),
    _section('User Conduct',
      'You agree not to cheat, hack, reverse-engineer, use bots, harass other users, or violate any applicable laws.'),
    _section('Intellectual Property',
      'All content including graphics, sounds, music, and code is the property of the developer and protected by copyright law.'),
    _section('Disclaimer',
      'The App is provided "as is" without warranties. We do not guarantee it will be error-free or uninterrupted.'),
    _section('Limitation of Liability',
      'To the fullest extent permitted by law, the developer is not liable for indirect or consequential damages from use of the App.'),
    _section('Contact', 'Questions? Email us at:\ntriplethreatblackjack@gmail.com'),
  ]);
}