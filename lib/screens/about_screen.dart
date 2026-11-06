import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_info.dart';
import '../theme/app_theme.dart';
import '../widgets/section_card.dart';

/// Hakkında, gizlilik, kullanım koşulları ve lisanslar.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Hakkında')),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildHero(context),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Gizlilik Özeti',
              subtitle: 'Verilerin cihazında kalır',
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Bullet(
                    'Tüm hidrasyon, kafein ve ambalaj kayıtların yalnızca bu '
                    'cihazdaki yerel veritabanında saklanır.',
                  ),
                  _Bullet(
                    'Hiçbir kişisel veri toplanmaz, sunucuya gönderilmez, '
                    'üçüncü taraflarla paylaşılmaz ve reklam amacıyla '
                    'kullanılmaz.',
                  ),
                  _Bullet(
                    'Uygulama hesap açmanı istemez. Yalnızca istersen '
                    'girdiğin görünen ad, selamlamada kullanılmak üzere bu '
                    'cihazda saklanır; e-posta, telefon veya konum istenmez.',
                  ),
                  _Bullet(
                    'Bildirim izni yalnızca su ve geri dönüşüm hatırlatmaları '
                    'için kullanılır, istediğin zaman kapatabilirsin.',
                  ),
                  _Bullet(
                    'Uygulamayı silmen tüm yerel verilerin de silinmesi '
                    'anlamına gelir.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Sağlık Uyarısı',
              subtitle: 'Tıbbi tavsiye değildir',
              child: const Text(
                'AquaMate; hidrasyon, kafein ve ambalaj atığı konusunda genel '
                'bilgi sunar. Sunduğu hedefler ve değerler kişisel sağlık '
                'durumunu değerlendirmez; tanı, tedavi veya tıbbi tavsiye '
                'yerine geçmez. Kronik hastalık, hamilelik, emzirme veya ilaç '
                'kullanımı durumunda bir sağlık profesyoneline danış.',
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.subtitle,
                  height: 1.55,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SectionCard(
              title: 'Kullanım Koşulları',
              subtitle: 'Kısa özet',
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _Bullet(
                    'Uygulama "olduğu gibi" sunulur ve kesintisiz çalışacağı '
                    'garanti edilmez.',
                  ),
                  _Bullet(
                    'Girilen değerlerin doğruluğundan kullanıcı sorumludur; '
                    'kafein ve atık hesapları yaklaşık değerlerdir.',
                  ),
                  _Bullet(
                    'Uygulama içeriği ticari amaçla kopyalanamaz veya yeniden '
                    'satılamaz.',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ActionTile(
              icon: Icons.description_outlined,
              title: 'Açık Kaynak Lisansları',
              subtitle: 'Kullanılan paketlerin lisansları',
              onTap: () => showLicensePage(
                context: context,
                applicationName: AppInfo.name,
                applicationVersion: AppInfo.versionLabel,
                applicationLegalese: '© 2026 AquaMate',
              ),
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.person_outline_rounded,
              title: 'Geliştirici',
              subtitle:
                  '${AppInfo.developerName} · ${AppInfo.developerUrlLabel}',
              onTap: () => _openUrl(
                context,
                AppInfo.developerUrl,
                fallback: AppInfo.developerUrlLabel,
              ),
            ),
            const SizedBox(height: 10),
            _ActionTile(
              icon: Icons.mail_outline_rounded,
              title: 'İletişim',
              subtitle: AppInfo.supportEmail,
              onTap: () => _openUrl(
                context,
                'mailto:${AppInfo.supportEmail}?subject=AquaMate%20Geri%20Bildirim',
                fallback: AppInfo.supportEmail,
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Column(
                children: <Widget>[
                  Text(
                    '${AppInfo.name} ${AppInfo.versionLabel}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.subtitle,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Yerel veri · Reklamsız · Hesapsız',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.subtitle,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bağlantıyı açar; açılamazsa adresi kopyalayıp bilgi verir.
  Future<void> _openUrl(
    BuildContext context,
    String url, {
    required String fallback,
  }) async {
    bool opened = false;
    try {
      opened = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      opened = false;
    }
    if (opened || !context.mounted) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: fallback));
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$fallback panoya kopyalandı')));
  }

  Widget _buildHero(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(26),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            width: 62,
            height: 62,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            AppInfo.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppInfo.tagline,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sürüm ${AppInfo.versionLabel}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Icon(
            Icons.check_circle_rounded,
            size: 16,
            color: AppColors.green,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.subtitle,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 19, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.heading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.subtitle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
