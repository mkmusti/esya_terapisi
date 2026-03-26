import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:scratcher/scratcher.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  await AudioManager.init();
  runApp(const EsyaTerapisiApp());
}

// --- GELİŞMİŞ SES YÖNETİCİSİ ---
class AudioManager {
  static final AudioPlayer _musicPlayer = AudioPlayer();
  static bool isMusicOn = true;
  static bool isSfxOn = true;
  static double volume = 0.5;

  // YENİ: Müzik Listesi ve Seçili İndeks
  static int currentMusicIndex = 0;

  static final List<Map<String, String>> musicList = [
    {"name": "Klasik Zen", "file": "sounds/zen_music_1.mp3"},
    {"name": "Yağmur Sesi", "file": "sounds/zen_music_2.mp3"},
    {"name": "Sakin Piyano", "file": "sounds/zen_music_3.mp3"},
  ];

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    isMusicOn = prefs.getBool('music') ?? true;
    isSfxOn = prefs.getBool('sfx') ?? true;
    volume = prefs.getDouble('volume') ?? 0.5;
    currentMusicIndex = prefs.getInt('musicIndex') ?? 0; // Kayıtlı müziği yükle

    // Hata önlemi: Eğer kayıtlı indeks liste dışındaysa sıfırla
    if (currentMusicIndex >= musicList.length) currentMusicIndex = 0;

    _musicPlayer.setReleaseMode(ReleaseMode.loop);
    if (isMusicOn) playMusic();
  }

  static void playMusic() async {
    if (isMusicOn) {
      try {
        // Eğer zaten çalıyor ve aynı müzikse dokunma, değilse yeni müziği çal
        await _musicPlayer.stop(); // Önce durdur (Temiz geçiş için)
        await _musicPlayer.play(
            AssetSource(musicList[currentMusicIndex]["file"]!),
            volume: volume
        );
      } catch (e) {
        print("Müzik çalma hatası: $e");
      }
    }
  }

  static void stopMusic() async {
    await _musicPlayer.pause();
  }

  static void setVolume(double val) async {
    volume = val;
    if (isMusicOn) _musicPlayer.setVolume(volume);
    saveSettings();
  }

  static void toggleMusic(bool value) {
    isMusicOn = value;
    if (isMusicOn) playMusic(); else stopMusic();
    saveSettings();
  }

  static void toggleSfx(bool value) {
    isSfxOn = value;
    saveSettings();
  }

  // YENİ: Müzik Değiştirme Fonksiyonu
  static void changeMusicTrack(int index) {
    if (index != currentMusicIndex) {
      currentMusicIndex = index;
      saveSettings();
      if (isMusicOn) playMusic(); // Yeni müziği hemen başlat
    }
  }

  static void saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('music', isMusicOn);
    prefs.setBool('sfx', isSfxOn);
    prefs.setDouble('volume', volume);
    prefs.setInt('musicIndex', currentMusicIndex); // Seçimi kaydet
  }
}

// --- GLASS WIDGET ---
class GlassBox extends StatelessWidget {
  final double? width;
  final double? height;
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? colorInfo;

  const GlassBox({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.borderRadius = 20,
    this.padding,
    this.margin,
    this.colorInfo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: colorInfo ?? Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white.withOpacity(0.15), Colors.white.withOpacity(0.05)],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class EsyaTerapisiApp extends StatelessWidget {
  const EsyaTerapisiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        fontFamily: 'Roboto',
        scaffoldBackgroundColor: Colors.transparent,
      ),
      home: const SplashScreen(),
    );
  }
}

class BackgroundScaffold extends StatelessWidget {
  final Widget body;
  final PreferredSizeWidget? appBar;

  const BackgroundScaffold({super.key, required this.body, this.appBar});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: appBar,
        body: body,
      ),
    );
  }
}

// --- SPLASH SCREEN ---
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassBox(
                padding: const EdgeInsets.all(30),
                borderRadius: 100,
                child: const Icon(Icons.cleaning_services, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 40),
              const Text("EŞYA TERAPİSİ", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2)),
              const SizedBox(height: 10),
              const Text("Rahatla • Temizle • Yenile", style: TextStyle(fontSize: 16, color: Colors.white70)),
              const SizedBox(height: 60),
              GestureDetector(
                onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const GameScreen())),
                child: const GlassBox(
                  padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  borderRadius: 30,
                  child: Text("OYNA", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- YENİLENMİŞ SETTINGS SCREEN ---
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return BackgroundScaffold(
      appBar: AppBar(
        title: const Text("Ayarlar"),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView( // Ekran taşmasın diye
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // MÜZİK AÇ/KAPA
              GlassBox(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: SwitchListTile(
                  title: const Text("Müzik", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  secondary: Icon(Icons.music_note, color: AudioManager.isMusicOn ? Colors.white : Colors.white38),
                  value: AudioManager.isMusicOn,
                  activeColor: Colors.cyanAccent,
                  onChanged: (val) => setState(() => AudioManager.toggleMusic(val)),
                ),
              ),

              const SizedBox(height: 15),

              // YENİ: MÜZİK SEÇİMİ (Sadece müzik açıksa görünür)
              if (AudioManager.isMusicOn) ...[
                const Padding(
                  padding: EdgeInsets.only(left: 10, bottom: 5),
                  child: Text("Parça Seçimi", style: TextStyle(color: Colors.cyanAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
                GlassBox(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: List.generate(AudioManager.musicList.length, (index) {
                      bool isSelected = (AudioManager.currentMusicIndex == index);
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            AudioManager.changeMusicTrack(index);
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 5),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.cyanAccent.withOpacity(0.3) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: isSelected ? Border.all(color: Colors.cyanAccent, width: 1) : null,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                isSelected ? Icons.play_circle_fill : Icons.radio_button_unchecked,
                                color: isSelected ? Colors.cyanAccent : Colors.white54,
                              ),
                              const SizedBox(width: 15),
                              Text(
                                AudioManager.musicList[index]["name"]!,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.white70,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 15),
              ],

              // EFEKTLER
              GlassBox(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: SwitchListTile(
                  title: const Text("Efektler (ASMR)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  secondary: Icon(Icons.graphic_eq, color: AudioManager.isSfxOn ? Colors.white : Colors.white38),
                  value: AudioManager.isSfxOn,
                  activeColor: Colors.cyanAccent,
                  onChanged: (val) => setState(() => AudioManager.toggleSfx(val)),
                ),
              ),

              const SizedBox(height: 15),

              // SES SEVİYESİ
              GlassBox(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Ses Seviyesi", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Slider(
                      value: AudioManager.volume,
                      min: 0.0,
                      max: 1.0,
                      activeColor: Colors.cyanAccent,
                      inactiveColor: Colors.white24,
                      onChanged: (val) => setState(() => AudioManager.setVolume(val)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- GAME SCREEN ---
class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  final GlobalKey<ScratcherState> _scratcherKey = GlobalKey<ScratcherState>();
  final AudioPlayer _scratchPlayer = AudioPlayer();
  final AudioPlayer _successPlayer = AudioPlayer();

  Timer? _timer;
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;

  int _levelElapsedSeconds = 0;
  int _totalTourSeconds = 0;
  int? _highScoreSeconds;

  double progress = 0.0;
  bool isFinished = false;
  int currentLevelIndex = 0;
  int difficultyLevel = 1;

  final List<String> difficultyNames = ["Basic", "Elementary", "Medium", "Advanced", "Master"];
  String get currentRankName => difficultyLevel <= difficultyNames.length ? difficultyNames[difficultyLevel - 1] : "Grand Master";

  double sizeBrush = 40.0;
  double sizeSponge = 20.0;
  double sizeSandpaper = 70.0;
  double _currentBrushSize = 40.0;
  String _currentToolName = "Fırça";

  final List<Map<String, String>> levels = [
    {"title": "Bölüm 1: Porselen Tabak", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/porselentabak.jpg"},
    {"title": "Bölüm 2: Yanmış Tava", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/tava.jpg"},
    {"title": "Bölüm 3: Şef Bıçağı", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/bicak.jpg"},
    {"title": "Bölüm 4: Kesme Tahtası", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/ekmektahtasi.jpg"},
    {"title": "Bölüm 5: Bakır Çaydanlık", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/caydanlik.jpg"},
    {"title": "Bölüm 6: Spor Ayakkabı", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/sporayakkabi.jpg"},
    {"title": "Bölüm 7: Deri Çanta", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/dericanta.jpg"},
    {"title": "Bölüm 8: Güneş Gözlüğü", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/gunesgozlugu.jpg"},
    {"title": "Bölüm 9: Kol Saati", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/kolsaati.jpg"},
    {"title": "Bölüm 10: Pırlanta Yüzük", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/mucevher.jpg"},
    {"title": "Bölüm 11: Antika Tablo", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/antika.jpg"},
    {"title": "Bölüm 12: Çin Vazosu", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/vazo.jpg"},
    {"title": "Bölüm 13: Bahçe Cücesi", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/cuce.jpg"},
    {"title": "Bölüm 14: Paslı Anahtar", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/anahtar.jpg"},
    {"title": "Bölüm 15: Eski Ayna", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/ayna.jpg"},
    {"title": "Bölüm 16: Akıllı Telefon", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/telefon.jpg"},
    {"title": "Bölüm 17: Oyun Kolu", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/gamekontroller.jpg"},
    {"title": "Bölüm 18: Klavye", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/klavye.jpg"},
    {"title": "Bölüm 19: Hoparlör", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/speaker.jpg"},
    {"title": "Bölüm 20: Kulaklık", "dirty": "assets/images/camur_doku.jpg", "clean": "assets/images/kulaklik.jpg"},
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scratchPlayer.setReleaseMode(ReleaseMode.loop);
    _scratchPlayer.setSource(AssetSource('sounds/kazima.mp3'));
    _loadGameData(); // OYUN VERİLERİNİ YÜKLE
    _startTimer();
    _loadBannerAd();
  }

  // --- SAVE SYSTEM ---
  Future<void> _loadGameData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      difficultyLevel = prefs.getInt('difficultyLevel') ?? 1;
      currentLevelIndex = prefs.getInt('currentLevelIndex') ?? 0;
      _highScoreSeconds = prefs.getInt('highScore');
      sizeBrush = prefs.getDouble('sizeBrush') ?? 40.0;
      sizeSponge = prefs.getDouble('sizeSponge') ?? 20.0;
      sizeSandpaper = prefs.getDouble('sizeSandpaper') ?? 70.0;
      if (_currentToolName == "Fırça") _currentBrushSize = sizeBrush;
    });
  }

  Future<void> _saveGameData() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setInt('difficultyLevel', difficultyLevel);
    prefs.setInt('currentLevelIndex', currentLevelIndex);
    if (_highScoreSeconds != null) prefs.setInt('highScore', _highScoreSeconds!);
    prefs.setDouble('sizeBrush', sizeBrush);
    prefs.setDouble('sizeSponge', sizeSponge);
    prefs.setDouble('sizeSandpaper', sizeSandpaper);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      AudioManager.stopMusic();
      _stopTimer();
    } else if (state == AppLifecycleState.resumed) {
      if (AudioManager.isMusicOn) AudioManager.playMusic();
      if (!isFinished) _startTimer();
    }
  }

  void _loadBannerAd() {
    final adUnitId = Platform.isAndroid
        ? 'ca-app-pub-6890807918605748/4060648050'
        : 'ca-app-pub-3940256099942544/2934735716';

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) => setState(() => _isAdLoaded = true),
        onAdFailedToLoad: (ad, err) { ad.dispose(); _isAdLoaded = false; },
      ),
    )..load();
  }

  void _startTimer() {
    _timer?.cancel();
    _levelElapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isFinished) setState(() { _levelElapsedSeconds++; _totalTourSeconds++; });
    });
  }

  void _stopTimer() => _timer?.cancel();

  String formatTime(int totalSeconds) {
    final minutes = (totalSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scratchPlayer.dispose();
    _successPlayer.dispose();
    _timer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var currentLevelData = levels[currentLevelIndex];

    return BackgroundScaffold(
      appBar: AppBar(
        title: Text("${currentLevelData["title"]!} ($currentRankName)", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.settings, color: Colors.white),
          onPressed: () async {
            _stopTimer();
            await Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            if (!isFinished) _startTimer();
          },
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _resetLevel)
        ],
      ),
      body: Column(
        children: [
          // SKOR
          GlassBox(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  children: [
                    const Text("TOPLAM", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(formatTime(_totalTourSeconds), style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
                Column(
                  children: [
                    const Text("BEST", style: TextStyle(color: Colors.cyanAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                    Text(_highScoreSeconds == null ? "--:--" : formatTime(_highScoreSeconds!), style: const TextStyle(color: Colors.cyanAccent, fontSize: 20, fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),

          // PROGRESS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Temizlik: %${progress.toInt()}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                Text("Bölüm: ${formatTime(_levelElapsedSeconds)}", style: const TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            height: 8,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress / 100,
                backgroundColor: Colors.white24,
                color: Colors.cyanAccent,
              ),
            ),
          ),

          // OYUN ALANI
          Expanded(
            child: Center(
              child: GlassBox(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                padding: const EdgeInsets.all(10),
                borderRadius: 25,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Listener(
                    onPointerDown: (_) async { if (!isFinished && AudioManager.isSfxOn) await _scratchPlayer.resume(); },
                    onPointerUp: (_) async { await _scratchPlayer.pause(); },
                    child: Scratcher(
                      key: _scratcherKey,
                      brushSize: _currentBrushSize,
                      threshold: 95,
                      accuracy: ScratchAccuracy.low,
                      image: Image.asset(currentLevelData["dirty"]!, fit: BoxFit.cover),
                      onChange: (value) { setState(() => progress = value); },
                      onThreshold: () {
                        if (!isFinished) {
                          setState(() => isFinished = true);
                          _stopTimer();
                          _scratchPlayer.stop();
                          if (AudioManager.isSfxOn) _successPlayer.play(AssetSource('sounds/basari.mp3'));
                          _checkGameProgress();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: Image.asset(currentLevelData["clean"]!, fit: BoxFit.cover),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ARAÇLAR
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildGlassToolButton(Icons.brush, sizeBrush, "Fırça"),
                _buildGlassToolButton(Icons.clean_hands, sizeSponge, "Sünger"),
                _buildGlassToolButton(Icons.hardware, sizeSandpaper, "Zımpara"),
              ],
            ),
          ),

          // REKLAM
          if (_isAdLoaded)
            SizedBox(
              height: _bannerAd!.size.height.toDouble(),
              width: _bannerAd!.size.width.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
          else
            const SizedBox(height: 50),
        ],
      ),
    );
  }

  // --- MANTIK ---
  void _resetLevel() {
    _scratcherKey.currentState?.reset(duration: const Duration(milliseconds: 500));
    setState(() {
      isFinished = false;
      progress = 0.0;
      if (_currentToolName == "Fırça") _currentBrushSize = sizeBrush;
      if (_currentToolName == "Sünger") _currentBrushSize = sizeSponge;
      if (_currentToolName == "Zımpara") _currentBrushSize = sizeSandpaper;
    });
    _startTimer();
  }

  void _checkGameProgress() {
    if (currentLevelIndex < levels.length - 1) {
      _showGlassDialog("✅ Temizlendi!", "Bölüm: ${formatTime(_levelElapsedSeconds)}\nToplam: ${formatTime(_totalTourSeconds)}", "Sonraki", _nextLevel);
    } else {
      _showRankUpDialog();
    }
  }

  void _nextLevel() {
    setState(() { currentLevelIndex++; progress = 0; isFinished = false; });
    _saveGameData();
    _scratcherKey.currentState?.reset();
    _startTimer();
    Navigator.pop(context);
  }

  void _increaseDifficultyAndRestart() {
    setState(() {
      if (_highScoreSeconds == null || _totalTourSeconds < _highScoreSeconds!) _highScoreSeconds = _totalTourSeconds;
      _totalTourSeconds = 0;
      if (sizeSandpaper > 30) sizeSandpaper -= 10;
      if (sizeBrush > 15) sizeBrush -= 5;
      if (sizeSponge > 10) sizeSponge -= 5;
      difficultyLevel++;
      currentLevelIndex = 0; progress = 0; isFinished = false;
      if (_currentToolName == "Fırça") _currentBrushSize = sizeBrush;
      else if (_currentToolName == "Sünger") _currentBrushSize = sizeSponge;
      else if (_currentToolName == "Zımpara") _currentBrushSize = sizeSandpaper;
    });
    _saveGameData();
    _scratcherKey.currentState?.reset();
    _startTimer();
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Yeni Tur Başladı! Araçlar Küçüldü!"), backgroundColor: Colors.cyan));
  }

  Widget _buildGlassToolButton(IconData icon, double size, String name) {
    bool isSelected = (_currentToolName == name);
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentBrushSize = size;
          _currentToolName = name;
        });
      },
      child: Column(
        children: [
          GlassBox(
            padding: const EdgeInsets.all(12),
            borderRadius: 50,
            child: Icon(icon, color: isSelected ? Colors.cyanAccent : Colors.white70, size: 28),
          ),
          const SizedBox(height: 5),
          Text(name, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.cyanAccent : Colors.white70)),
        ],
      ),
    );
  }

  void _showGlassDialog(String title, String content, String btnText, VoidCallback onPressed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassBox(
            padding: const EdgeInsets.all(20),
            borderRadius: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Text(content, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                const SizedBox(height: 25),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.cyanAccent, foregroundColor: Colors.black),
                  onPressed: onPressed,
                  child: Text(btnText, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showRankUpDialog() {
    bool isNewRecord = (_highScoreSeconds == null || _totalTourSeconds < _highScoreSeconds!);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          child: GlassBox(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events, color: Colors.orangeAccent, size: 50),
                const SizedBox(height: 10),
                const Text("TUR BİTTİ!", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Text("Süre: ${formatTime(_totalTourSeconds)}", style: const TextStyle(color: Colors.white70)),
                if (isNewRecord) const Text("✨ YENİ REKOR! ✨", style: TextStyle(color: Colors.orangeAccent, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                const Text("Zorluk Artıyor. Hazır mısın?", style: TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
                  onPressed: _increaseDifficultyAndRestart,
                  child: const Text("Sonraki Tur (Zor)", style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}