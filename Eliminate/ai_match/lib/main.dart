import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

// ------------------------------
// THEME & COLORS
// ------------------------------
class AppColors {
  static const background = Color(0xFF0E1530); // deep navy
  static const panel = Color(0xFF162042); // card / panels
  static const panelAlt = Color(0xFF1B2752);
  static const cyan = Color(0xFF23D4FF);
  static const purple = Color(0xFF7C5CFF);
  static const orange = Color(0xFFFF9D47);
  static const pink = Color(0xFFFF5FA0);
  static const success = Color(0xFF27D980);
  static const danger = Color(0xFFFF4D5E);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFFCFD7FF);
}

ThemeData buildTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: AppColors.cyan,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.cyan,
      secondary: AppColors.purple,
      surface: AppColors.panel,
      background: AppColors.background,
      onPrimary: Colors.black,
      onSurface: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.background,
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleLarge: TextStyle(
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyMedium: TextStyle(color: AppColors.textSecondary),
    ),
    // cardTheme removed to avoid API mismatch with some Flutter versions
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.panelAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      hintStyle: const TextStyle(color: AppColors.textSecondary),
    ),
  );
}

// ------------------------------
// MODELS (In‑Memory for Demo)
// ------------------------------
class Profile {
  String name;
  int age;
  List<String> photos; // asset or network urls
  String description;
  String? zodiac; // optional
  Set<String> musicTags; // optional
  String? team; // optional

  // Rating state
  final List<double> givenRatings =
      []; // ratings current user gave to this profile
  int superLikesLeftToday = 3;

  Profile({
    required this.name,
    required this.age,
    required this.photos,
    this.description = '',
    this.zodiac,
    Set<String>? musicTags,
    this.team,
  }) : musicTags = musicTags ?? {};

  double get averageRating => givenRatings.isEmpty
      ? 0
      : (givenRatings.reduce((a, b) => a + b) / givenRatings.length);

  // Business rule: after first 5 ratings, users can only give >= (avg - 2)
  double minAllowedForNext() {
    if (givenRatings.length < 5) return 1;
    final minAllowed = max(1, averageRating - 2);
    return double.parse(minAllowed.toStringAsFixed(1));
  }
}

// Demo dataset of candidate cards (like Tinder)
final demoProfiles = <Profile>[
  Profile(
    name: 'Elif',
    age: 24,
    photos: ['assets/avatars/avatar1.jpg'],
    description: 'Doğa yürüyüşü, elektronik müzik, kediler 🐾',
    zodiac: 'Koç',
    musicTags: {'EDM', 'House', 'Lo‑Fi'},
    team: 'GS',
  ),
  Profile(
    name: 'Mert',
    age: 27,
    photos: ['assets/avatars/avatar2.jpg'],
    description: 'Basketbol, kahve, indie filmler.',
    zodiac: 'Yengeç',
    musicTags: {'Indie', 'Jazz'},
    team: 'FB',
  ),
  Profile(
    name: 'Derya',
    age: 23,
    photos: ['assets/avatars/avatar3.jpg'],
    description: 'Fotoğraf, kamp, alternatif rock.',
    zodiac: 'Terazi',
    musicTags: {'Rock'},
    team: 'BJK',
  ),
];

// Mock current user
class CurrentUserState extends ChangeNotifier {
  bool isLoggedIn = false;
  bool completedMandatoryProfile = false; // forces "Sen" section first

  // Account metrics for "Hesap Ayarları" top cards
  String plan = 'Free';
  DateTime? planEndsAt;
  int matchCount = 0;
  double winRate = 0.0; // percent-like metric

  int dailySuperLikesLeft = 3;

  // On real app, save to storage
  void login(String email, String password) {
    isLoggedIn = true;
    notifyListeners();
  }

  void register(String email, String password) {
    isLoggedIn = true;
    notifyListeners();
  }

  void completeProfile() {
    completedMandatoryProfile = true;
    notifyListeners();
  }
}

// ------------------------------
// APP ROOT
// ------------------------------
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AI Match – Modern Dashboard',
      theme: buildTheme(),
      home: StateScope(child: const AuthGate()),
    );
  }
}

// Simple inherited ChangeNotifier for demo (instead of provider)
class StateScope extends StatefulWidget {
  final Widget child;
  const StateScope({super.key, required this.child});
  static _StateScopeState of(BuildContext context) =>
      context.findAncestorStateOfType<_StateScopeState>()!;
  @override
  State<StateScope> createState() => _StateScopeState();
}

class _StateScopeState extends State<StateScope> {
  final CurrentUserState user = CurrentUserState();

  @override
  Widget build(BuildContext context) {
    return InheritedState(data: this, child: widget.child);
  }
}

class InheritedState extends InheritedWidget {
  final _StateScopeState data;
  const InheritedState({required this.data, required super.child});
  @override
  bool updateShouldNotify(covariant InheritedState oldWidget) => true;
}

CurrentUserState userOf(BuildContext context) => StateScope.of(context).user;

// ------------------------------
// AUTH
// ------------------------------
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool showLogin = true;
  @override
  Widget build(BuildContext context) {
    final user = userOf(context);
    if (user.isLoggedIn) {
      return const Shell();
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B1026), Color(0xFF0E1530), Color(0xFF111B3E)],
          ),
        ),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'AI Match',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      showLogin ? 'Giriş Yap' : 'Kayıt Ol',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 24),
                    const _AuthForm(),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => setState(() => showLogin = !showLogin),
                      child: Text(
                        showLogin
                            ? 'Hesabın yok mu? Kayıt ol'
                            : 'Hesabın var mı? Giriş yap',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthForm extends StatefulWidget {
  const _AuthForm();
  @override
  State<_AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<_AuthForm> {
  final email = TextEditingController();
  final password = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: email,
          decoration: const InputDecoration(hintText: 'E‑posta'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: password,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Şifre'),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.cyan,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              userOf(context).login(email.text, password.text);
              setState(() {});
            },
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'Devam Et',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ------------------------------
// SHELL LAYOUT (NavigationRail + Pages)
// ------------------------------
enum PageKey { sen, modlar, oylama, mesajlar, ayarlar, yardim }

class Shell extends StatefulWidget {
  const Shell({super.key});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  PageKey current = PageKey.sen; // force Sen first time

  @override
  Widget build(BuildContext context) {
    final user = userOf(context);

    // force to Sen until profile completed
    if (!user.completedMandatoryProfile && current != PageKey.sen) {
      current = PageKey.sen;
    }

    return Scaffold(
      body: Row(
        children: [
          Container(
            width: 88,
            decoration: BoxDecoration(
              color: AppColors.panel,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 16)
              ],
            ),
            child: NavigationRail(
              extended: false,
              backgroundColor: Colors.transparent,
              selectedIndex: PageKey.values.indexOf(current),
              onDestinationSelected: (i) {
                final target = PageKey.values[i];
                if (!user.completedMandatoryProfile && target != PageKey.sen)
                  return; // lock
                setState(() => current = target);
              },
              labelType: NavigationRailLabelType.all,
              destinations: const [
                NavigationRailDestination(
                    icon: Icon(Icons.person), label: Text('Sen')),
                NavigationRailDestination(
                    icon: Icon(Icons.games), label: Text('Modlar')),
                NavigationRailDestination(
                    icon: Icon(Icons.how_to_vote),
                    label: Text('Hadi\nOylayalım')),
                NavigationRailDestination(
                    icon: Icon(Icons.chat_bubble), label: Text('Mesajlar')),
                NavigationRailDestination(
                    icon: Icon(Icons.settings), label: Text('Ayarlar')),
                NavigationRailDestination(
                    icon: Icon(Icons.help_outline), label: Text('Yardım')),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0B1026),
                    Color(0xFF0E1530),
                    Color(0xFF111B3E)
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: _buildPage(current),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(PageKey key) {
    switch (key) {
      case PageKey.sen:
        return const SenPage();
      case PageKey.modlar:
        return const ModlarPage();
      case PageKey.oylama:
        return HadiOylayalimPage();
      case PageKey.mesajlar:
        return const MesajlarPage();
      case PageKey.ayarlar:
        return const AyarlarPage();
      case PageKey.yardim:
        return const YardimPage();
    }
  }
}

// ------------------------------
// PAGE: SEN (mandatory profile)
// ------------------------------
class SenPage extends StatefulWidget {
  const SenPage({super.key});
  @override
  State<SenPage> createState() => _SenPageState();
}

class _SenPageState extends State<SenPage> {
  final name = TextEditingController();
  final age = TextEditingController();
  String? zodiac;
  final musicChoices = <String>{};
  String? team;

  final availableMusic = const [
    'Pop',
    'Rock',
    'Rap',
    'EDM',
    'Lo‑Fi',
    'Jazz',
    'Classical',
    'Indie'
  ];
  final zodiacs = const [
    'Koç',
    'Boğa',
    'İkizler',
    'Yengeç',
    'Aslan',
    'Başak',
    'Terazi',
    'Akrep',
    'Yay',
    'Oğlak',
    'Kova',
    'Balık'
  ];
  final teams = const ['GS', 'FB', 'BJK', 'TS', 'Bursa'];

  List<String> photos = [];

  @override
  Widget build(BuildContext context) {
    final user = userOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Zorunlu Profil',
                style: Theme.of(context).textTheme.headlineMedium),
            if (!user.completedMandatoryProfile)
              FilledButton.icon(
                icon: const Icon(Icons.lock_open),
                label: const Text('Kaydet ve Kilidi Aç'),
                onPressed: () {
                  if (name.text.trim().isEmpty ||
                      int.tryParse(age.text) == null ||
                      photos.length < 2) {
                    _toast(context, 'İsim, yaş ve en az 2 fotoğraf zorunlu.');
                    return;
                  }
                  user.completeProfile();
                  setState(() {});
                },
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _panel(
              width: 360,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('İsim'),
                  const SizedBox(height: 8),
                  TextField(
                      controller: name,
                      decoration: const InputDecoration(hintText: 'Adın')),
                  const SizedBox(height: 16),
                  const Text('Yaş'),
                  const SizedBox(height: 8),
                  TextField(
                      controller: age,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(hintText: 'Yaşın')),
                  const SizedBox(height: 16),
                  const Text('Burç (opsiyonel)'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    items: zodiacs
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    value: zodiac,
                    onChanged: (v) => setState(() => zodiac = v),
                    decoration: const InputDecoration(hintText: 'Seç'),
                  ),
                  const SizedBox(height: 16),
                  const Text('Takım (opsiyonel)'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    items: teams
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    value: team,
                    onChanged: (v) => setState(() => team = v),
                    decoration: const InputDecoration(hintText: 'Seç'),
                  ),
                ],
              ),
            ),
            _panel(
              width: 520,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Müzik Zevkleri (opsiyonel)'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final tag in availableMusic)
                        FilterChip(
                          label: Text(tag),
                          selected: musicChoices.contains(tag),
                          onSelected: (v) => setState(() => v
                              ? musicChoices.add(tag)
                              : musicChoices.remove(tag)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const Text('Fotoğraflar (en az 2 – en çok 6)'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final p in photos)
                        _photoChip(p,
                            onDelete: () => setState(() => photos.remove(p))),
                      if (photos.length < 6)
                        OutlinedButton.icon(
                          onPressed: () {
                            final pool = [
                              'assets/avatars/avatar1.jpg',
                              'assets/avatars/avatar2.jpg',
                              'assets/avatars/avatar3.jpg',
                            ];
                            final pick = pool[Random().nextInt(pool.length)];
                            if (!photos.contains(pick))
                              setState(() => photos.add(pick));
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Ekle (demo)'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _photoChip(String path, {required VoidCallback onDelete}) {
    return Chip(
      avatar: CircleAvatar(backgroundImage: AssetImage(path)),
      label: Text(path.split('/').last),
      deleteIcon: const Icon(Icons.close),
      onDeleted: onDelete,
    );
  }
}

// ------------------------------
// PAGE: MODLAR (Hızlı Oyun / Odalar)
// ------------------------------
class ModlarPage extends StatelessWidget {
  const ModlarPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Modlar', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _bigButton(
              icon: Icons.flash_on,
              title: 'Hızlı Oyun',
              subtitle: 'Anında eşleşme deneyimi',
              onTap: () => _toast(context, 'Hızlı Oyun başlatıldı (demo).'),
              color: AppColors.orange,
            ),
            _bigButton(
              icon: Icons.meeting_room,
              title: 'Odalar',
              subtitle: 'Özel temalı odalarda buluş',
              onTap: () => _toast(context, 'Oda listesi (demo).'),
              color: AppColors.purple,
            ),
          ],
        ),
      ],
    );
  }
}

// ------------------------------
// PAGE: Hadi Oylayalım (Tinder‑style rating with constraints + live Chart)
// ------------------------------
class HadiOylayalimPage extends StatefulWidget {
  HadiOylayalimPage({super.key});

  @override
  State<HadiOylayalimPage> createState() => _HadiOylayalimPageState();
}

class _HadiOylayalimPageState extends State<HadiOylayalimPage> {
  int index = 0; // current card
  double currentSlider = 5; // 1..10
  final ratingsHistory = <double>[]; // for chart per viewed person

  Profile get currentProfile => demoProfiles[index % demoProfiles.length];

  @override
  Widget build(BuildContext context) {
    final p = currentProfile;
    final minAllowed = p.minAllowedForNext();

    currentSlider = currentSlider.clamp(minAllowed, 10);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Hadi Oylayalım',
                style: Theme.of(context).textTheme.headlineMedium),
            Row(
              children: [
                _miniStat(
                    'Beğenilme',
                    p.averageRating == 0
                        ? '-'
                        : p.averageRating.toStringAsFixed(1)),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => _openChart(context),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.panelAlt),
                  child: const Text('Oran'),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _profileCard(p)),
              const SizedBox(width: 16),
              _ratingPanel(
                minAllowed: minAllowed,
                onRate: (value) {
                  setState(() {
                    p.givenRatings.add(value);
                    ratingsHistory.add(value);
                  });
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FilledButton.tonalIcon(
              onPressed: () {
                if (userOf(context).dailySuperLikesLeft <= 0) {
                  _toast(context, 'Günlük super like hakkın bitti.');
                  return;
                }
                userOf(context).dailySuperLikesLeft -= 1;
                _toast(context, 'Super like gönderildi!');
              },
              icon: const Icon(Icons.star),
              label:
                  Text('Super Like (${userOf(context).dailySuperLikesLeft})'),
            ),
            OutlinedButton.icon(
              onPressed: () => setState(() => index++),
              icon: const Icon(Icons.skip_next),
              label: const Text('Sonraki'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _profileCard(Profile p) {
    final photo = p.photos.isNotEmpty ? p.photos.first : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: photo == null
                    ? Container(
                        color: AppColors.panelAlt,
                        child:
                            const Center(child: Icon(Icons.person, size: 64)),
                      )
                    : Image.asset(photo,
                        fit: BoxFit.cover, width: double.infinity),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Text('${p.name}, ${p.age}',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8),
                if (p.zodiac != null) Chip(label: Text(p.zodiac!)),
                if (p.team != null)
                  Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Chip(label: Text(p.team!))),
              ],
            ),
            const SizedBox(height: 6),
            Text(p.description),
            const SizedBox(height: 8),
            Wrap(
                spacing: 6,
                children: [for (final m in p.musicTags) Chip(label: Text(m))]),
          ],
        ),
      ),
    );
  }

  Widget _ratingPanel(
      {required double minAllowed, required void Function(double) onRate}) {
    return SizedBox(
      width: 140,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text('Puan (1‑10)'),
              const SizedBox(height: 8),
              Expanded(
                child: RotatedBox(
                  quarterTurns: -1,
                  child: Slider(
                    value: currentSlider,
                    min: minAllowed,
                    max: 10,
                    divisions: ((10 - minAllowed) * 10).round(),
                    label: currentSlider.toStringAsFixed(1),
                    onChanged: (v) => setState(() => currentSlider = v),
                  ),
                ),
              ),
              Text('Min: ${minAllowed.toStringAsFixed(1)}',
                  style: const TextStyle(color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              FilledButton(
                  onPressed: () =>
                      onRate(double.parse(currentSlider.toStringAsFixed(1))),
                  child: const Text('Puanla')),
            ],
          ),
        ),
      ),
    );
  }

  void _openChart(BuildContext context) {
    final values = currentProfile.givenRatings.isEmpty
        ? [0.0]
        : currentProfile.givenRatings.map((e) => e.clamp(1.0, 10.0)).toList();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: AppColors.panel,
        child: SizedBox(
          width: 640,
          height: 360,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Beğeni Grafiği (1‑10)'),
                    IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: LineChart(
                    LineChartData(
                      minY: 1,
                      maxY: 10,
                      gridData: FlGridData(show: true),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        bottomTitles: AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 24),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles:
                              SideTitles(showTitles: true, reservedSize: 28),
                        ),
                        rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          dotData: FlDotData(show: true),
                          barWidth: 3,
                          spots: [
                            for (int i = 0; i < values.length; i++)
                              FlSpot(i.toDouble() + 1, values[i]),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------
// PAGE: MESAJLAR
// ------------------------------
class MesajlarPage extends StatelessWidget {
  const MesajlarPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mesajlar', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 12),
        _panel(
          child: const ListTile(
            leading: CircleAvatar(child: Icon(Icons.person)),
            title: Text('Eşleşme bekleniyor…'),
            subtitle:
                Text('Super like karşılıklı olursa burada sohbet başlayacak.'),
          ),
        ),
      ],
    );
  }
}

// ------------------------------
// PAGE: AYARLAR (Hesap Ayarları & Ayarlar)
// ------------------------------
class AyarlarPage extends StatefulWidget {
  const AyarlarPage({super.key});
  @override
  State<AyarlarPage> createState() => _AyarlarPageState();
}

class _AyarlarPageState extends State<AyarlarPage>
    with SingleTickerProviderStateMixin {
  late final TabController tab;
  @override
  void initState() {
    super.initState();
    tab = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final user = userOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Ayarlar', style: Theme.of(context).textTheme.headlineMedium),
            SizedBox(
              width: 360,
              child: TabBar(
                controller: tab,
                labelPadding: const EdgeInsets.symmetric(vertical: 8),
                tabs: const [Tab(text: 'Hesap Ayarları'), Tab(text: 'Ayarlar')],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: TabBarView(
            controller: tab,
            children: [
              SingleChildScrollView(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    _statCard(
                        title: 'Üyelik Tipi',
                        value: user.plan,
                        icon: Icons.workspace_premium,
                        gradient: const [AppColors.orange, AppColors.pink]),
                    _statCard(
                        title: 'Üyelik Bitiş Tarihi',
                        value: user.planEndsAt == null
                            ? '-'
                            : _fmtDate(user.planEndsAt!),
                        icon: Icons.event,
                        gradient: const [AppColors.cyan, AppColors.purple]),
                    _statCard(
                        title: 'Maç Sayısı',
                        value: user.matchCount.toString(),
                        icon: Icons.sports_mma,
                        gradient: const [Color(0xFF66E8A2), AppColors.success]),
                    _statCard(
                        title: 'Kazanma Oranı',
                        value: '${user.winRate.toStringAsFixed(1)}%',
                        icon: Icons.trending_up,
                        gradient: const [Color(0xFF6EC8FF), AppColors.cyan]),
                  ],
                ),
              ),
              SingleChildScrollView(
                child: Column(
                  children: [
                    _panel(
                      child: SwitchListTile(
                          value: true,
                          onChanged: (_) {},
                          title: const Text('Bildirimler'),
                          subtitle: const Text(
                              'Eşleşme ve mesaj bildirimlerini aç/kapat')),
                    ),
                    _panel(
                      child: ListTile(
                        leading: const Icon(Icons.lock),
                        title: const Text('Şifre Değiştir'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _toast(context, 'Şifre değiştir (demo).'),
                      ),
                    ),
                    _panel(
                      child: ListTile(
                        leading: const Icon(Icons.logout),
                        title: const Text('Çıkış Yap'),
                        onTap: () {
                          userOf(context).isLoggedIn = false;
                          userOf(context).completedMandatoryProfile = false;
                          Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const AuthGate()),
                              (route) => false);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ------------------------------
// PAGE: YARDIM
// ------------------------------
class YardimPage extends StatelessWidget {
  const YardimPage({super.key});
  @override
  Widget build(BuildContext context) {
    return _panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Yardım Merkezi',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text(
              '• "Sen" bölümünde isim, yaş ve en az 2 fotoğraf girilmeden diğer sayfalara geçemezsin.'),
          Text(
              '• "Hadi Oylayalım" ekranında ilk 5 puan serbesttir; sonra minimum puan ortalamanın 2 puan altıdır.'),
          Text(
              '• "Oran" butonuna tıklayarak canlı güncellenen grafiği açabilirsin.'),
        ],
      ),
    );
  }
}

// ------------------------------
// UI HELPERS
// ------------------------------
Widget _panel({double? width, Widget? child}) {
  return SizedBox(
      width: width,
      child: Card(
          child: Padding(padding: const EdgeInsets.all(16.0), child: child)));
}

Widget _bigButton(
    {required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    required Color color}) {
  return SizedBox(
    width: 300,
    height: 140,
    child: InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Ink(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
                colors: [color.withOpacity(.85), color.withOpacity(.55)])),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, size: 32, color: Colors.black.withOpacity(.85)),
            const Spacer(),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.black)),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(color: Colors.black87)),
          ]),
        ),
      ),
    ),
  );
}

Widget _statCard(
    {required String title,
    required String value,
    required IconData icon,
    required List<Color> gradient}) {
  return SizedBox(
    width: 280,
    height: 120,
    child: Card(
      child: Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
                colors: gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                stops: const [0.2, 1.0])),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(icon, color: Colors.black87),
            const Spacer(),
            Text(title,
                style: const TextStyle(
                    color: Colors.black87, fontWeight: FontWeight.w600)),
            Text(value,
                style: const TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 22)),
          ]),
        ),
      ),
    ),
  );
}

Widget _miniStat(String title, String value) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
        color: AppColors.panelAlt, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Text('$title: ', style: const TextStyle(color: AppColors.textSecondary)),
      Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
    ]),
  );
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

void _toast(BuildContext context, String msg) {
  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}
