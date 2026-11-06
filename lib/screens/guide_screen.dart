import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme/app_theme.dart';
import '../widgets/app_transitions.dart';

/// Rehber ekranındaki bilgi konusu.
class GuideTopic {
  const GuideTopic({
    required this.title,
    required this.subtitle,
    required this.image,
    required this.icon,
    required this.color,
    required this.bullets,
    required this.detail,
  });

  final String title;
  final String subtitle;
  final String image;
  final IconData icon;
  final Color color;
  final List<String> bullets;
  final String detail;
}

const List<GuideTopic> kGuideTopics = <GuideTopic>[
  GuideTopic(
    title: 'Doğru Su İçme Zamanları',
    subtitle: 'Uyanınca, yemekten 30 dk önce, uyumadan önce',
    image: 'assets/images/water_timing.png',
    icon: Icons.access_time_rounded,
    color: Color(0xFF2F80ED),
    bullets: <String>[
      'Uyandıktan hemen sonra 1-2 bardak ılık su iç',
      'Yemeklerden 30 dakika önce su içerek sindirime hazırlık yap',
      'Yemek sırasında fazla su içme, yemekten 45 dk sonra devam et',
      'Egzersizden önce, sırasında ve sonrasında küçük yudumlar al',
      'Uyumadan 1 saat önce su içmeyi bırak',
    ],
    detail:
        'Vücut, gece boyunca terleme ve nefes yoluyla su kaybeder. Uyandığında '
        'içtiğin bir bardak su, metabolizmayı uyandırır ve günün ilk hidrasyon '
        'adımını atmanı sağlar.\n\n'
        'Öğünlerden yaklaşık 30 dakika önce içilen su, mide salgılarını '
        'hazırlar ve tokluk hissini destekler. Gün içinde suyu tek seferde '
        'değil, küçük yudumlar halinde dağıtmak, emilimi artırır.\n\n'
        'Akşam geç saatlerde aşırı su içmek gece sık uyanmaya neden olabilir; '
        'bu yüzden uyumadan önceki son suyunu yaklaşık bir saat önce iç.',
  ),
  GuideTopic(
    title: 'Dehidrasyonun 5 Gizli Belirtisi',
    subtitle: 'Baş ağrısı, yorgunluk, ağız kuruluğu ve daha fazlası',
    image: 'assets/images/dehydration_signs.png',
    icon: Icons.science_rounded,
    color: Color(0xFFFF9F43),
    bullets: <String>[
      'Sebepsiz baş ağrısı ve baş dönmesi',
      'Kalıcı yorgunluk ve enerji düşüklüğü',
      'Ağız kuruluğu ve kötü nefes',
      'Konsantrasyon güçlüğü ve hafıza problemleri',
      'Kabızlık, cilt kuruluğu ve kas krampları',
    ],
    detail:
        'Dehidrasyon çoğu zaman susama hissinden önce kendini gösterir. Beyin '
        'kitlesinin küçük bir kısmı su kaybettiğinde bile odaklanma ve kısa '
        'vadeli hafıza performansı düşebilir.\n\n'
        'Cilt kuruluğu, çatlayan dudaklar ve azalan idrar miktarı, vücudun '
        'su tasarrufuna geçtiğinin işaretleridir. Koyu renkli idrar, '
        'yeterince su içmediğini gösteren en pratik göstergedir.\n\n'
        'Gün içinde düzenli aralıklarla su içmek, bu belirtilerin çoğunu '
        'önler. Kendini yorgun hissettiğinde önce bir bardak su içmeyi dene.',
  ),
  GuideTopic(
    title: 'Böbrek ve Cilt Sağlığı İçin Su',
    subtitle: 'Günlük yeterli su tüketiminin faydaları',
    image: 'assets/images/kidney_skin.png',
    icon: Icons.favorite_rounded,
    color: Color(0xFF10B981),
    bullets: <String>[
      'Böbrek taşları riskini azaltır',
      'İdrar yolu enfeksiyonlarını önlemeye yardımcı olur',
      'Cildi nemlendirir ve elastikiyetini korur',
      'Vücuttan toksin atımını destekler',
      'Kan dolaşımı ve sindirim sistemi için hayati önem taşır',
    ],
    detail:
        'Böbrekler, gün içinde süzüldüğü kadar sıvıya ihtiyaç duyar. Yeterli '
        'su alımı idrar seyreltir ve minerallerin böbreklerde kristalleşip '
        'taş oluşturmasını zorlaştırır.\n\n'
        'Cilt, vücudun en büyük organıdır ve nem dengesini korumak için '
        'yeterli sıvıya ihtiyaç duyar. Düzenli su tüketimi cildin daha '
        'sağlıklı ve dolgun görünmesine katkı sağlar.\n\n'
        'Yetişkinler için genel öneri, kilogram başına yaklaşık 35 ml su '
        'yani 70 kg bir kişi için günde 2450 ml civarındadır. Hava sıcaklığı '
        've egzersiz süresi arttıkça bu değer yükselir.',
  ),
  GuideTopic(
    title: 'Kafein: Ne Kadar, Ne Zaman?',
    subtitle: '400 mg sınırı, uyku kalitesi ve gizli kafein kaynakları',
    image: 'assets/images/water_timing.png',
    icon: Icons.coffee_rounded,
    color: Color(0xFF8B5E34),
    bullets: <String>[
      'Sağlıklı yetişkinler için günlük üst sınır yaklaşık 400 mg',
      'Uykudan 8 saat önce kafein alımını kes',
      'Espresso ve Türk kahvesi küçük hacimde yüksek kafein içerir',
      'Kola, enerji içeceği ve çikolata da kafein kaynağıdır',
      'Kafein hidrasyonu azaltır: kahve %80, çay %85 sayılır',
    ],
    detail:
        'Kafein, merkezi sinir sistemini uyaran ve etkisi 3-7 saat süren bir '
        'maddedir. Günlük 400 mg sınırı sağlıklı yetişkinler için genel bir '
        'üst sınırdır; hamilelik, kalp ritim bozukluğu veya uyku problemi '
        'varsa bu sınır çok daha düşük tutulmalıdır.\n\n'
        'Bir fincan filtre kahve (200 ml) yaklaşık 80 mg, tek espresso '
        '(30 ml) yaklaşık 64 mg, bir bardak demli çay (200 ml) yaklaşık 30 mg '
        'kafein içerir. Türk kahvesi küçük fincanda yüksek kafein '
        'yoğunluğuna sahiptir.\n\n'
        'Kafein yarı ömrü kişiden kişiye değişir. Uyku kalitesini korumak '
        'için son kafeinini yatmadan en az 8 saat önce almayı hedefle; '
        'uygulamadaki "son kafein saati" bu kurala göre hesaplanır.\n\n'
        'Kafein hafif idrar söktürücü etki yapar; bu yüzden çay ve kahve '
        'içtiğinde bir bardak su daha içmeyi alışkanlık haline getir. '
        'Bu bölümdeki bilgiler tıbbi tavsiye değildir.',
  ),
  GuideTopic(
    title: 'Ambalaj Atığı ve Karbon Ayak İzi',
    subtitle: 'Matara mı, PET şişe mi? Farkı gör',
    image: 'assets/images/kidney_skin.png',
    icon: Icons.eco_rounded,
    color: Color(0xFF10B981),
    bullets: <String>[
      'Tek kullanımlık PET şişe 500 ml başına ~14 g atık üretir',
      'Karton bardak geri dönüştürülemez, cam şişe ise dönüştürülebilir',
      'Matara ve cam bardak neredeyse sıfır ambalaj atığı bırakır',
      'Geri dönüşüm, ambalaj kaynaklı CO₂e\'yi yaklaşık %40 azaltır',
      'Küçük alışkanlık değişiklikleri yılda kilogramlarca atık demek',
    ],
    detail:
        'Bir kişi günde iki PET şişe su tüketirse yılda yaklaşık 10 kg '
        'plastik atık üretir. Aynı miktar suyu matarayla taşımak bu atığı '
        'neredeyse tamamen ortadan kaldırır.\n\n'
        'Ambalajın çevresel etkisi yalnızca atık ağırlığı değildir: üretim, '
        'nakliye ve bertaraf süreçleri karbon emisyonu da oluşturur. '
        'Alüminyum kutu hafiftir ama üretimi enerji yoğundur; cam şişe '
        'ağırdır ancak defalarca dönüştürülebilir.\n\n'
        'Karton bardakların iç yüzeyi plastik filmle kaplı olduğu için '
        'standart belediye geri dönüşümünde kabul edilmez. Tetra pak da '
        'benzer şekilde katmanlıdır ve ayrı toplama gerektirir.\n\n'
        'En etkili adım basit: yanında matara taşı, kafede kendi bardağını '
        'kullan ve tek kullanımlık ambalajı geri dönüşüme ayır. AquaMate\'te '
        'her içecekte kabını seçerek bu etkiyi ölçebilirsin.',
  ),
];

/// Ekran 3: Hidrasyon Rehberi - video, ses ve görsel içerikler.
class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final double bottomInset = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 100 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Hidrasyon Rehberi',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Video, ses ve görsellerle suyunu doğru içmeyi öğren',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 18),
          const _VideoGuideCard(),
          const SizedBox(height: 16),
          const _AudioGuideCard(),
          const SizedBox(height: 24),
          Text('Görsel Rehber', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          for (final GuideTopic topic in kGuideTopics) ...<Widget>[
            _TopicCard(topic: topic),
            const SizedBox(height: 14),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- video kartı

class _VideoGuideCard extends StatefulWidget {
  const _VideoGuideCard();

  @override
  State<_VideoGuideCard> createState() => _VideoGuideCardState();
}

class _VideoGuideCardState extends State<_VideoGuideCard> {
  static const Duration _fallbackDuration = Duration(seconds: 45);

  VideoPlayerController? _controller;
  bool _ready = false;
  bool _realVideo = false;
  bool _playing = false;
  int _lastSecond = -1;

  double _simSeconds = 0;
  Timer? _simTimer;

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    VideoPlayerController? controller;
    try {
      controller = VideoPlayerController.asset('assets/videos/water_guide.mp4');
      await controller.initialize().timeout(const Duration(seconds: 8));
      if (!controller.value.isInitialized || controller.value.hasError) {
        throw Exception('Video kaynağı hazır değil.');
      }
      controller.addListener(_onVideoTick);
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _realVideo = true;
        _ready = true;
        _playing = controller!.value.isPlaying;
      });
    } catch (_) {
      // Dosya yoksa / açılamazsa simülasyon moduna düşülür.
      await controller?.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _realVideo = false;
        _ready = true;
      });
    }
  }

  void _onVideoTick() {
    final VideoPlayerController? c = _controller;
    if (c == null || !mounted) {
      return;
    }
    final VideoPlayerValue value = c.value;
    final int second = value.position.inSeconds;
    if (value.isPlaying != _playing || second != _lastSecond) {
      _lastSecond = second;
      setState(() => _playing = value.isPlaying);
    }
  }

  Duration get _position {
    if (_realVideo && _controller != null) {
      return _controller!.value.position;
    }
    return Duration(milliseconds: (_simSeconds * 1000).round());
  }

  Duration get _duration {
    if (_realVideo &&
        _controller != null &&
        _controller!.value.duration.inMilliseconds > 0) {
      return _controller!.value.duration;
    }
    return _fallbackDuration;
  }

  Future<void> _togglePlay() async {
    if (!_ready) {
      return;
    }
    if (_realVideo && _controller != null) {
      final VideoPlayerController c = _controller!;
      if (c.value.isPlaying) {
        await c.pause();
      } else {
        await c.play();
      }
      if (mounted) {
        setState(() => _playing = c.value.isPlaying);
      }
      return;
    }

    if (_playing) {
      _simTimer?.cancel();
      if (mounted) {
        setState(() => _playing = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _playing = true);
    }
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 400), (
      Timer timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _simSeconds += 0.4;
        if (_simSeconds >= _duration.inSeconds.toDouble()) {
          _simSeconds = 0;
          _playing = false;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _seek(double seconds) async {
    final Duration target = Duration(milliseconds: (seconds * 1000).round());
    if (_realVideo && _controller != null) {
      await _controller!.seekTo(target);
      if (mounted) {
        setState(() {});
      }
      return;
    }
    if (mounted) {
      setState(() => _simSeconds = seconds);
    }
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    final VideoPlayerController? c = _controller;
    if (c != null) {
      c.removeListener(_onVideoTick);
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double totalSeconds = _duration.inSeconds.toDouble().clamp(1, 100000);
    final double currentSeconds = _position.inSeconds.toDouble().clamp(
      0,
      totalSeconds,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Suyun Vücuttaki Mucizevi Yolculuğu',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Kısa eğitici video (optimize, düşük boyut)',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _StatusChip(
                text: _realVideo ? 'Gerçek Video' : 'Simülasyon',
                color: _realVideo ? AppColors.green : AppColors.orange,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: AspectRatio(
              aspectRatio: _realVideo && _controller != null
                  ? _controller!.value.aspectRatio
                  : 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  if (!_ready)
                    const ColoredBox(
                      color: Color(0xFFEAF3FD),
                      child: Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.6,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    )
                  else if (_realVideo && _controller != null)
                    VideoPlayer(_controller!)
                  else
                    const _PreviewPlaceholder(),
                  if (_ready)
                    _MediaOverlay(
                      playing: _playing,
                      position: _position,
                      duration: _duration,
                      onToggle: _togglePlay,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _PlayButton(playing: _playing, onTap: _togglePlay),
              const SizedBox(width: 12),
              Expanded(
                child: Slider(
                  value: currentSeconds,
                  min: 0,
                  max: totalSeconds,
                  onChanged: _ready ? (double v) => _seek(v) : null,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${_fmt(_position)} / ${_fmt(_duration)}',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.subtitle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- ses kartı

class _AudioGuideCard extends StatefulWidget {
  const _AudioGuideCard();

  @override
  State<_AudioGuideCard> createState() => _AudioGuideCardState();
}

class _AudioGuideCardState extends State<_AudioGuideCard> {
  static const Duration _fallbackDuration = Duration(minutes: 1);

  AudioPlayer? _player;
  bool _ready = false;
  bool _realAudio = false;
  bool _playing = false;
  Duration _position = Duration.zero;
  Duration _duration = _fallbackDuration;
  double _simSeconds = 0;
  Timer? _simTimer;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<void>? _completeSub;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    AudioPlayer? player;
    try {
      player = AudioPlayer();
      await player
          .setSource(AssetSource('audio/voice_guide.mp3'))
          .timeout(const Duration(seconds: 8));
      final Duration? total = await player.getDuration();
      _positionSub = player.onPositionChanged.listen((Duration position) {
        if (mounted) {
          setState(() => _position = position);
        }
      });
      _completeSub = player.onPlayerComplete.listen((void _) {
        if (mounted) {
          setState(() {
            _playing = false;
            _position = Duration.zero;
          });
        }
      });
      if (!mounted) {
        await player.dispose();
        return;
      }
      setState(() {
        _player = player;
        _realAudio = true;
        _ready = true;
        _duration = (total != null && total.inMilliseconds > 0)
            ? total
            : _fallbackDuration;
      });
    } catch (_) {
      // Asset yoksa zamanlayıcı destekli simülasyon modu devreye girer.
      await player?.dispose();
      if (!mounted) {
        return;
      }
      setState(() {
        _realAudio = false;
        _ready = true;
      });
    }
  }

  Duration get _currentPosition {
    if (_realAudio) {
      return _position;
    }
    return Duration(milliseconds: (_simSeconds * 1000).round());
  }

  Duration get _currentDuration => _realAudio ? _duration : _fallbackDuration;

  Future<void> _togglePlay() async {
    if (!_ready) {
      return;
    }

    if (_realAudio && _player != null) {
      final AudioPlayer player = _player!;
      if (_playing) {
        await player.pause();
        if (mounted) {
          setState(() => _playing = false);
        }
        return;
      }
      if (_position >= _currentDuration - const Duration(milliseconds: 400)) {
        await player.seek(Duration.zero);
      }
      await player.resume();
      if (mounted) {
        setState(() => _playing = true);
      }
      return;
    }

    if (_playing) {
      _simTimer?.cancel();
      if (mounted) {
        setState(() => _playing = false);
      }
      return;
    }

    if (mounted) {
      setState(() => _playing = true);
    }
    _simTimer?.cancel();
    _simTimer = Timer.periodic(const Duration(milliseconds: 400), (
      Timer timer,
    ) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _simSeconds += 0.4;
        if (_simSeconds >= _currentDuration.inSeconds.toDouble()) {
          _simSeconds = 0;
          _playing = false;
          timer.cancel();
        }
      });
    });
  }

  Future<void> _seek(double seconds) async {
    final Duration target = Duration(milliseconds: (seconds * 1000).round());
    if (_realAudio && _player != null) {
      await _player!.seek(target);
      if (mounted) {
        setState(() => _position = target);
      }
      return;
    }
    if (mounted) {
      setState(() => _simSeconds = seconds);
    }
  }

  @override
  void dispose() {
    _simTimer?.cancel();
    _positionSub?.cancel();
    _completeSub?.cancel();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double totalSeconds = _currentDuration.inSeconds.toDouble().clamp(
      1,
      100000,
    );
    final double currentSeconds = _currentPosition.inSeconds.toDouble().clamp(
      0,
      totalSeconds,
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.graphic_eq_rounded,
                  color: AppColors.orange,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Sabah Uyanınca Su ve Nefes Rehberi',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Sesli yönlendirme kartı',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              _StatusChip(
                text: _realAudio ? 'Ses Hazır' : 'Simülasyon',
                color: _realAudio ? AppColors.green : AppColors.orange,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              _PlayButton(playing: _playing, onTap: _togglePlay),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  children: <Widget>[
                    Slider(
                      value: currentSeconds,
                      min: 0,
                      max: totalSeconds,
                      onChanged: _ready ? (double v) => _seek(v) : null,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          _fmt(_currentPosition),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        Text(
                          _fmt(_currentDuration),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 46,
                height: 40,
                child: _EqualizerBars(active: _playing),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------- ortak parçalar

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.playing, required this.onTap});

  final bool playing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Ink(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: Icon(
            playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            color: Colors.white,
            size: 26,
          ),
        ),
      ),
    );
  }
}

class _MediaOverlay extends StatelessWidget {
  const _MediaOverlay({
    required this.playing,
    required this.position,
    required this.duration,
    required this.onToggle,
  });

  final bool playing;
  final Duration position;
  final Duration duration;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        GestureDetector(
          onTap: onToggle,
          child: AnimatedOpacity(
            opacity: playing ? 0 : 1,
            duration: const Duration(milliseconds: 250),
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.28),
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill_rounded,
                  color: Colors.white,
                  size: 58,
                ),
              ),
            ),
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 18, 12, 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: <Color>[
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Eğitici video',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${_fmt(position)} / ${_fmt(duration)}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PreviewPlaceholder extends StatefulWidget {
  const _PreviewPlaceholder();

  @override
  State<_PreviewPlaceholder> createState() => _PreviewPlaceholderState();
}

class _PreviewPlaceholderState extends State<_PreviewPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
      child: AnimatedBuilder(
        animation: _controller,
        builder: (BuildContext context, Widget? child) {
          return Center(
            child: Transform.scale(
              scale: 0.9 + (_controller.value * 0.18),
              child: Opacity(
                opacity: 0.55 + (_controller.value * 0.45),
                child: child,
              ),
            ),
          );
        },
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.water_drop_rounded, color: Colors.white, size: 44),
            SizedBox(height: 8),
            Text(
              'Önizleme yükleniyor...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EqualizerBars extends StatefulWidget {
  const _EqualizerBars({required this.active});

  final bool active;

  @override
  State<_EqualizerBars> createState() => _EqualizerBarsState();
}

class _EqualizerBarsState extends State<_EqualizerBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 700),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _controller.repeat();
    } else {
      _controller.value = 0.25;
    }
  }

  @override
  void didUpdateWidget(_EqualizerBars oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.repeat();
    } else if (!widget.active && oldWidget.active) {
      _controller.stop();
      _controller.value = 0.25;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? _) {
        return CustomPaint(painter: _BarsPainter(_controller.value));
      },
    );
  }
}

class _BarsPainter extends CustomPainter {
  const _BarsPainter(this.t);

  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..color = AppColors.primary;
    const int bars = 5;
    final double spacing = size.width / bars;
    for (int i = 0; i < bars; i++) {
      final double wave = 0.5 + 0.5 * math.sin((t * 6.28318) + (i * 0.9));
      final double barHeight = size.height * (0.35 + 0.55 * wave);
      final RRect rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          i * spacing + spacing * 0.25,
          (size.height - barHeight) / 2,
          spacing * 0.5,
          barHeight,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(_BarsPainter oldDelegate) => oldDelegate.t != t;
}

// ------------------------------------------------------------ görsel kartları

class _TopicCard extends StatefulWidget {
  const _TopicCard({required this.topic});

  final GuideTopic topic;

  @override
  State<_TopicCard> createState() => _TopicCardState();
}

class _TopicCardState extends State<_TopicCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final GuideTopic topic = widget.topic;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: <Widget>[
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 54,
                    height: 54,
                    child: _TopicImage(
                      path: topic.image,
                      icon: topic.icon,
                      color: topic.color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        topic.title,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        topic.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 260),
                  child: const Icon(
                    Icons.expand_more_rounded,
                    color: AppColors.subtitle,
                    size: 26,
                  ),
                ),
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !_expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: SizedBox(
                            width: double.infinity,
                            height: 150,
                            child: _TopicImage(
                              path: topic.image,
                              icon: topic.icon,
                              color: topic.color,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        for (final String bullet in topic.bullets)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Container(
                                  margin: const EdgeInsets.only(top: 5),
                                  width: 7,
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: topic.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    bullet,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.heading,
                                      height: 1.4,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                AppPageRoute<void>(
                                  page: GuideDetailScreen(topic: topic),
                                ),
                              );
                            },
                            icon: const Icon(
                              Icons.arrow_forward_rounded,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            label: const Text(
                              'Detaya Git',
                              style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
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
}

class _TopicImage extends StatelessWidget {
  const _TopicImage({
    required this.path,
    required this.icon,
    required this.color,
    this.fit = BoxFit.cover,
  });

  final String path;
  final IconData icon;
  final Color color;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      path,
      fit: fit,
      errorBuilder: (BuildContext context, Object error, StackTrace? stack) {
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[color, color.withValues(alpha: 0.6)],
            ),
          ),
          child: Center(child: Icon(icon, color: Colors.white, size: 26)),
        );
      },
    );
  }
}

/// Görsel konunun tam metnini gösteren detay sayfası.
class GuideDetailScreen extends StatelessWidget {
  const GuideDetailScreen({super.key, required this.topic});

  final GuideTopic topic;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(topic.title),
        backgroundColor: AppColors.background,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: SizedBox(
                width: double.infinity,
                height: 210,
                child: _TopicImage(
                  path: topic.image,
                  icon: topic.icon,
                  color: topic.color,
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(topic.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(topic.subtitle, style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.cardShadow,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final String bullet in topic.bullets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Icon(
                            Icons.check_circle_rounded,
                            size: 18,
                            color: topic.color,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              bullet,
                              style: const TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.heading,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: AppColors.cardShadow,
              ),
              child: Text(
                topic.detail,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.subtitle,
                  height: 1.6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _fmt(Duration d) {
  final String m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
  final String s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$m:$s';
}
