#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
AquaMate PowerPoint Sunumu Düzenleyici
Bu betik, 'Purple Pink Gradient Mobile Application Presentation.pptx' dosyasını
AquaMate projesinin teknik gereksinimleri, sınav soruları, 100 puanlık notlandırma
kriterleri ve gerçek iPhone 17 Pro ekran görüntüleri ile donatarak profesyonelce düzenler.
"""

import os
import shutil
from pptx import Presentation
from pptx.util import Pt

SOURCE_PPTX = '/Users/mehmetefeaytas/Downloads/Purple Pink Gradient Mobile Application Presentation.pptx'
BACKUP_PPTX = '/Users/mehmetefeaytas/Downloads/Purple Pink Gradient Mobile Application Presentation_Original_Backup.pptx'
PROJECT_PPTX = '/Users/mehmetefeaytas/Library/Mobile Documents/com~apple~CloudDocs/mobilapp/AquaMate/AquaMate_Sunum.pptx'

IMG_HOME = 'doc_screenshots/1_ana_sayfa.png'
IMG_STATS = 'doc_screenshots/2_istatistik.png'
IMG_GUIDE = 'doc_screenshots/3_rehber.png'
IMG_SETTINGS = 'doc_screenshots/4_ayarlar.png'

def set_text_exact(shape, text, font_size_pt=None):
    """Metin kutusundaki metni, var olan ilk run biçimlendirmesini koruyarak günceller."""
    if not shape.has_text_frame:
        return
    tf = shape.text_frame
    r0 = tf.paragraphs[0].runs[0] if (tf.paragraphs and tf.paragraphs[0].runs) else None
    fname = r0.font.name if r0 else None
    fbold = r0.font.bold if r0 else None
    fsize = r0.font.size if r0 else None
    fcolor = r0.font.color.rgb if (r0 and r0.font.color and r0.font.color.type == 1) else None

    # İlk paragrafı güncelle
    p0 = tf.paragraphs[0]
    p0.text = text
    if p0.runs:
        r = p0.runs[0]
        if fname: r.font.name = fname
        if fbold is not None: r.font.bold = fbold
        if font_size_pt:
            r.font.size = Pt(font_size_pt)
        elif fsize:
            r.font.size = fsize
        if fcolor:
            r.font.color.rgb = fcolor

    # Kalan gereksiz paragrafları temizle
    for p in tf.paragraphs[1:]:
        p.text = ''

def replace_phone_image(slide, shape_name, image_path):
    """Bir slide içindeki mockup telefonun ekranına ait serbest çizim dolgusunu yeni resimle değiştirir."""
    def find_shape(s):
        if s.name == shape_name:
            return s
        if s.shape_type == 6: # Group
            for sub in s.shapes:
                res = find_shape(sub)
                if res: return res
        return None

    target = None
    for s in slide.shapes:
        res = find_shape(s)
        if res:
            target = res
            break

    if not target:
        print(f"Uyarı: {shape_name} bulunamadı!")
        return False

    image_part, rId = slide.part.get_or_add_image_part(image_path)
    if hasattr(target, '_element') and hasattr(target._element, 'spPr') and target._element.spPr is not None:
        blip = target._element.spPr.find('{http://schemas.openxmlformats.org/drawingml/2006/main}blipFill/{http://schemas.openxmlformats.org/drawingml/2006/main}blip')
        if blip is not None:
            blip.attrib['{http://schemas.openxmlformats.org/officeDocument/2006/relationships}embed'] = rId
            fill_rect = target._element.spPr.find('{http://schemas.openxmlformats.org/drawingml/2006/main}blipFill/{http://schemas.openxmlformats.org/drawingml/2006/main}stretch/{http://schemas.openxmlformats.org/drawingml/2006/main}fillRect')
            if fill_rect is not None:
                fill_rect.attrib['l'] = '0'
                fill_rect.attrib['t'] = '0'
                fill_rect.attrib['r'] = '0'
                fill_rect.attrib['b'] = '0'
            return True
    return False

def find_shape_by_name(container, name):
    for s in container.shapes:
        if s.name == name:
            return s
        if s.shape_type == 6: # Group
            res = find_shape_by_name(s, name)
            if res: return res
    return None

def update_top_nav(slide):
    """Tüm slaytlarda ortak olan üst menü çubuğunu günceller."""
    for s in slide.shapes:
        if s.has_text_frame:
            txt = s.text_frame.text.strip()
            if txt == 'Ingoude Company':
                set_text_exact(s, 'AquaMate')
            elif txt == 'Home':
                set_text_exact(s, 'Ana Sayfa')
            elif txt == 'Service':
                set_text_exact(s, 'Özellikler')
            elif txt == 'About Us':
                set_text_exact(s, 'Mimari')
            elif txt == 'Contact':
                set_text_exact(s, 'İletişim')

def main():
    if not os.path.exists(SOURCE_PPTX):
        print(f"Hata: {SOURCE_PPTX} bulunamadı!")
        return

    # Orijinal dosyanın yedeğini oluştur
    if not os.path.exists(BACKUP_PPTX):
        shutil.copy2(SOURCE_PPTX, BACKUP_PPTX)
        print(f"Orijinal sunum yedeklendi: {BACKUP_PPTX}")

    prs = Presentation(SOURCE_PPTX)

    # -------------------------------------------------------------
    # SLIDE 1: KAPAK / HERO SLAYTI
    # -------------------------------------------------------------
    s1 = prs.slides[0]
    update_top_nav(s1)
    
    # Hero Başlık: "Aqua" ve "Mate"
    tb47 = find_shape_by_name(s1, 'TextBox 47')
    tb48 = find_shape_by_name(s1, 'TextBox 48')
    if tb47: set_text_exact(tb47, 'Aqua')
    if tb48: set_text_exact(tb48, 'Mate')

    # Alt Başlık / Rozet
    tb52 = find_shape_by_name(s1, 'TextBox 52')
    if tb52: set_text_exact(tb52, 'AKILLI HİDRASYON & SIVI TAKİP ASİSTANI', font_size_pt=11.0)

    # 3 Telefon Ekranı: Merkez Ana Sayfa, Sol İstatistik, Sağ Rehber
    replace_phone_image(s1, 'Freeform 19', IMG_HOME)
    replace_phone_image(s1, 'Freeform 39', IMG_STATS)
    replace_phone_image(s1, 'Freeform 29', IMG_GUIDE)
    print("Slide 1 güncellendi.")

    # -------------------------------------------------------------
    # SLIDE 2: PROJENİN AMACI VE VİZYONU
    # -------------------------------------------------------------
    s2 = prs.slides[1]
    update_top_nav(s2)

    tb40 = find_shape_by_name(s2, 'TextBox 40')
    if tb40: set_text_exact(tb40, 'Projenin Amacı & Klinik Vizyonu', font_size_pt=34.0)

    tb41 = find_shape_by_name(s2, 'TextBox 41')
    if tb41:
        set_text_exact(
            tb41,
            'Günümüz yoğun çalışma temposunda su tüketimi sıklıkla ihmal edilmektedir. '
            'Yetersiz hidrasyon; baş ağrısı, kronik yorgunluk, dikkat dağınıklığı ve böbrek fonksiyonu '
            'bozukluklarına yol açar. AquaMate, kullanıcıya düzenli içme alışkanlığı kazandırmak '
            'için geliştirilmiş akıllı bir dijital sağlık asistanıdır.',
            font_size_pt=11.5
        )

    tb42 = find_shape_by_name(s2, 'TextBox 42')
    if tb42:
        set_text_exact(
            tb42,
            'Klasik sayaçların aksine tüketilen içeceklerin biyoyararlanım katsayılarını (net hidrasyon) '
            'hesaba katar (Çay %85, Kahve %80, Su %100). Bireysel kilo ve egzersiz bazlı akıllı hedef '
            'formülü, periyodik yerel hatırlatıcılar ve motive edici sıvı dalga simülasyonu sunar.',
            font_size_pt=11.5
        )

    tb35 = find_shape_by_name(s2, 'TextBox 35')
    if tb35: set_text_exact(tb35, '%100 Net Hidrasyon', font_size_pt=13.0)

    tb36 = find_shape_by_name(s2, 'TextBox 36')
    if tb36: set_text_exact(tb36, '7/7 Test & 0 Hata', font_size_pt=13.0)

    # Soldaki Mockup Telefon: Ana Sayfa
    replace_phone_image(s2, 'Freeform 17', IMG_HOME)
    print("Slide 2 güncellendi.")

    # -------------------------------------------------------------
    # SLIDE 3: TEKNİK AVANTAJLAR & NOTLANDIRMA KRİTERLERİ (100 PUAN)
    # -------------------------------------------------------------
    s3 = prs.slides[2]
    update_top_nav(s3)

    tb30 = find_shape_by_name(s3, 'TextBox 30')
    if tb30: set_text_exact(tb30, 'Teknik Başarılar & Notlandırma Kriterleri', font_size_pt=34.0)

    # 6 Maddelik Notlandırma Matrisi
    points = [
        ('TextBox 35', 'TextBox 34', '01', 'Derste İşlenmeyen Özellik (20P): CustomPainter ile çift katmanlı sinüs dalgası sıvı fiziği simülasyonu ve biyoyararlanım katsayı algoritması.'),
        ('TextBox 40', 'TextBox 39', '02', 'İlişkisel Veritabanı (20P): SQLite (sqflite) ile cihazda veri kalıcılığı, aggregate SQL sorguları ve kesintisiz streak (seri) takibi.'),
        ('TextBox 45', 'TextBox 44', '03', 'Ses & Video Entegrasyonu (10P): audioplayers su damlası sesi ve sesli rehber, video_player ile yerleşik eğitim videosu.'),
        ('TextBox 50', 'TextBox 49', '04', 'Uyumlu Sayfa Geçişleri (10P): AnimatedSwitcher cross-fade geçişleri, Apple HIG buzlu cam (blur 20) dock bar ve iOS haptik geri bildirim.'),
        ('TextBox 55', 'TextBox 54', '05', 'Hatasız Çalışma & Test (10P): flutter analyze 0 hata/uyarı, flutter test 7/7 başarılı, TestFlight yayına hazır sürüm (v1.0.0+3).'),
        ('TextBox 60', 'TextBox 59', '06', 'Görsel Uyum & İçerik (20P): WHO/EFSA sağlık standartlarına uygun kişisel formül ve Apple Human Interface Guidelines estetiği.')
    ]

    for num_box, desc_box, num_val, desc_text in points:
        nb = find_shape_by_name(s3, num_box)
        db = find_shape_by_name(s3, desc_box)
        if nb: set_text_exact(nb, num_val, font_size_pt=16.0)
        if db: set_text_exact(db, desc_text, font_size_pt=10.5)

    replace_phone_image(s3, 'Freeform 19', IMG_STATS)
    print("Slide 3 güncellendi.")

    # -------------------------------------------------------------
    # SLIDE 4: MENÜ VE EKRANLAR
    # -------------------------------------------------------------
    s4 = prs.slides[3]
    update_top_nav(s4)

    tb53 = find_shape_by_name(s4, 'TextBox 53')
    if tb53: set_text_exact(tb53, 'Uygulama Ekranları ve Modüller', font_size_pt=34.0)

    s4_points = [
        ('TextBox 58', 'TextBox 57', '01', 'Ana Sayfa (Canlı Hidrasyon): Çift katmanlı sinüs dalgası animasyonu, 270° dairesel ilerleme halkası, buzlu cam metrik kapsülü ve tek tıkla hızlı sıvı ekleme.'),
        ('TextBox 63', 'TextBox 62', '02', 'İstatistik Ekranı: fl_chart ile 7 günlük çubuk grafiği, içecek türü dağılım pasta grafiği ve kaydırarak silinebilir tüketim geçmişi.'),
        ('TextBox 68', 'TextBox 67', '03', 'Hidrasyon Rehberi: Dahili video oynatıcı (slider/oynat/duraklat), sesli hidrasyon rehberi ve bilimsel sağlık bilgi kartları.')
    ]
    for num_box, desc_box, num_val, desc_text in s4_points:
        nb = find_shape_by_name(s4, num_box)
        db = find_shape_by_name(s4, desc_box)
        if nb: set_text_exact(nb, num_val, font_size_pt=16.0)
        if db: set_text_exact(db, desc_text, font_size_pt=11.0)

    replace_phone_image(s4, 'Freeform 20', IMG_HOME)
    replace_phone_image(s4, 'Freeform 30', IMG_STATS)
    replace_phone_image(s4, 'Freeform 40', IMG_GUIDE)
    print("Slide 4 güncellendi.")

    # -------------------------------------------------------------
    # SLIDE 5: ÖNE ÇIKAN MÜHENDİSLİK ÖZELLİKLERİ
    # -------------------------------------------------------------
    s5 = prs.slides[4]
    update_top_nav(s5)

    tb60 = find_shape_by_name(s5, 'TextBox 60')
    if tb60: set_text_exact(tb60, 'Öne Çıkan Mühendislik Özellikleri', font_size_pt=34.0)

    s5_points = [
        ('TextBox 65', 'TextBox 64', '01', 'Çift Katmanlı Dalga Fiziği: CustomPainter ve sinüs formülüyle su seviyesinin 60 FPS akıcı animasyonu.'),
        ('TextBox 70', 'TextBox 69', '02', 'Biyoyararlanım Motoru: Çay (%85), Kahve (%80) ve Su (%100) katsayılarıyla net biyolojik hidrasyon hesabı.'),
        ('TextBox 75', 'TextBox 74', '03', 'Akıllı Hedef & Hatırlatıcı: Kilo ve egzersiz bazlı kişisel formül ve periyodik yerel bildirim motoru.'),
        ('TextBox 80', 'TextBox 79', '04', 'Yerel SQLite Depolama: water_logs ve user_settings tabloları ile cihazda hızlı, güvenli veri kalıcılığı.')
    ]
    for num_box, desc_box, num_val, desc_text in s5_points:
        nb = find_shape_by_name(s5, num_box)
        db = find_shape_by_name(s5, desc_box)
        if nb: set_text_exact(nb, num_val, font_size_pt=16.0)
        if db: set_text_exact(db, desc_text, font_size_pt=10.5)

    replace_phone_image(s5, 'Freeform 19', IMG_HOME)
    replace_phone_image(s5, 'Freeform 29', IMG_STATS)
    replace_phone_image(s5, 'Freeform 39', IMG_GUIDE)
    replace_phone_image(s5, 'Freeform 49', IMG_SETTINGS)
    print("Slide 5 güncellendi.")

    # -------------------------------------------------------------
    # SLIDE 6: KALİTE GÜVENCESİ & TEST DOĞRULAMASI
    # -------------------------------------------------------------
    s6 = prs.slides[5]
    update_top_nav(s6)

    tb40 = find_shape_by_name(s6, 'TextBox 40')
    if tb40: set_text_exact(tb40, 'Kalite Güvencesi & Test Doğrulaması', font_size_pt=34.0)

    tb42 = find_shape_by_name(s6, 'TextBox 42')
    if tb42: set_text_exact(tb42, '0 Hata / 0 Uyarı (flutter analyze)', font_size_pt=12.0)

    tb44 = find_shape_by_name(s6, 'TextBox 44')
    if tb44: set_text_exact(tb44, '7/7 Birim Testi (%100 Başarı)', font_size_pt=12.0)

    tb46 = find_shape_by_name(s6, 'TextBox 46')
    if tb46: set_text_exact(tb46, 'TestFlight & App Store v1.0.0+3', font_size_pt=12.0)

    tb47 = find_shape_by_name(s6, 'TextBox 47')
    if tb47:
        set_text_exact(
            tb47,
            'AquaMate geliştirme sürecinde endüstri standardı kalite güvence ilkeleri uygulanmıştır: '
            'statik kod analizinde sıfır hata ve sıfır uyarı elde edilmiş, tüm hidrasyon modelleri ve '
            'hesaplayıcılar otomatik birim testleriyle doğrulanmış ve Apple gizlilik manifestosu '
            '(PrivacyInfo.xcprivacy) ile TestFlight ortamına başarıyla yüklenmiştir.',
            font_size_pt=11.5
        )

    replace_phone_image(s6, 'Freeform 19', IMG_HOME)
    replace_phone_image(s6, 'Freeform 29', IMG_SETTINGS)
    print("Slide 6 güncellendi.")

    # -------------------------------------------------------------
    # SLIDE 7: SİSTEM MİMARİSİ & VERİTABANI
    # -------------------------------------------------------------
    s7 = prs.slides[6]
    update_top_nav(s7)

    tb50 = find_shape_by_name(s7, 'TextBox 50')
    if tb50: set_text_exact(tb50, 'Sistem Mimarisi & Veritabanı Yapısı', font_size_pt=34.0)

    tb51 = find_shape_by_name(s7, 'TextBox 51')
    if tb51:
        set_text_exact(
            tb51,
            'AquaMate, katmanlı temiz mimari prensipleriyle tasarlanmıştır. Veritabanı katmanı (DatabaseHelper) '
            'SQLite motoruyla ilişkisel veri kalıcılığını sağlarken, servis katmanı bildirim ve ses süreçlerini '
            'reaktif olarak yönetir.',
            font_size_pt=11.5
        )

    tb56 = find_shape_by_name(s7, 'TextBox 56')
    tb55 = find_shape_by_name(s7, 'TextBox 55')
    if tb56: set_text_exact(tb56, '01', font_size_pt=16.0)
    if tb55:
        set_text_exact(
            tb55,
            'İlişkisel Veritabanı: water_logs ve user_settings tabloları ile aggregate hesaplamalar ve kesintisiz streak (seri) takibi.',
            font_size_pt=10.5
        )

    tb61 = find_shape_by_name(s7, 'TextBox 61')
    tb60 = find_shape_by_name(s7, 'TextBox 60')
    if tb61: set_text_exact(tb61, '02', font_size_pt=16.0)
    if tb60:
        set_text_exact(
            tb60,
            'Performans & Bellek: Dispose pattern ile bellek sızıntıları önlenmiş, asenkron veritabanı okumalarıyla 60 FPS sabit hız elde edilmiştir.',
            font_size_pt=10.5
        )

    replace_phone_image(s7, 'Freeform 19', IMG_HOME)
    replace_phone_image(s7, 'Freeform 29', IMG_STATS)
    replace_phone_image(s7, 'Freeform 39', IMG_SETTINGS)
    print("Slide 7 güncellendi.")

    # -------------------------------------------------------------
    # SLIDE 8: TÜM EKRANLAR VİTRİNİ (5 TELEFON)
    # -------------------------------------------------------------
    s8 = prs.slides[7]
    update_top_nav(s8)

    tb67 = find_shape_by_name(s8, 'TextBox 67')
    tb68 = find_shape_by_name(s8, 'TextBox 68')
    tb70 = find_shape_by_name(s8, 'TextBox 70')
    tb69 = find_shape_by_name(s8, 'TextBox 69')
    tb71 = find_shape_by_name(s8, 'TextBox 71')

    if tb67: set_text_exact(tb67, '01. Ana Sayfa', font_size_pt=14.0)
    if tb68: set_text_exact(tb68, '02. İstatistik', font_size_pt=14.0)
    if tb70: set_text_exact(tb70, '03. Rehber', font_size_pt=14.0)
    if tb69: set_text_exact(tb69, '04. Ayarlar', font_size_pt=14.0)
    if tb71: set_text_exact(tb71, '05. Hızlı Ekleme', font_size_pt=14.0)

    replace_phone_image(s8, 'Freeform 19', IMG_HOME)
    replace_phone_image(s8, 'Freeform 29', IMG_STATS)
    replace_phone_image(s8, 'Freeform 39', IMG_GUIDE)
    replace_phone_image(s8, 'Freeform 49', IMG_SETTINGS)
    replace_phone_image(s8, 'Freeform 59', IMG_HOME)
    print("Slide 8 güncellendi.")

    # -------------------------------------------------------------
    # SLIDE 9: İLETİŞİM & PROJE BİLGİLERİ
    # -------------------------------------------------------------
    s9 = prs.slides[8]
    update_top_nav(s9)

    tb53 = find_shape_by_name(s9, 'TextBox 53')
    if tb53: set_text_exact(tb53, 'Proje & Geliştirici Bilgileri', font_size_pt=34.0)

    tb55 = find_shape_by_name(s9, 'TextBox 55')
    if tb55: set_text_exact(tb55, 'Geliştirici: Mehmet Efe Aytaş', font_size_pt=13.0)

    tb57 = find_shape_by_name(s9, 'TextBox 57')
    if tb57: set_text_exact(tb57, 'Proje: AquaMate (Flutter & Dart)', font_size_pt=13.0)

    tb59 = find_shape_by_name(s9, 'TextBox 59')
    if tb59: set_text_exact(tb59, 'Sürüm: v1.0.0+3 (iOS & Android)', font_size_pt=13.0)

    tb61 = find_shape_by_name(s9, 'TextBox 61')
    if tb61: set_text_exact(tb61, 'T.C. Üniversitesi — Bilgisayar / Yazılım Mühendisliği', font_size_pt=13.0)

    tb62 = find_shape_by_name(s9, 'TextBox 62')
    if tb62:
        set_text_exact(
            tb62,
            'Mobil Uygulama Geliştirme Dersi Dönem Vize Projesi kapsamında hazırlanmış olup; '
            'kaynak kodları, birim testleri ve kapsamlı vize cevap raporu (.docx) ile birlikte eksiksiz teslim edilmiştir.',
            font_size_pt=11.5
        )

    replace_phone_image(s9, 'Freeform 22', IMG_HOME)
    replace_phone_image(s9, 'Freeform 32', IMG_STATS)
    replace_phone_image(s9, 'Freeform 42', IMG_GUIDE)
    print("Slide 9 güncellendi.")

    # -------------------------------------------------------------
    # SLIDE 10: TEŞEKKÜRLER & KAPANIŞ
    # -------------------------------------------------------------
    s10 = prs.slides[9]
    update_top_nav(s10)

    tb80 = find_shape_by_name(s10, 'TextBox 80')
    if tb80: set_text_exact(tb80, 'Teşekkür Ederiz', font_size_pt=48.0)

    tb81 = find_shape_by_name(s10, 'TextBox 81')
    if tb81:
        set_text_exact(
            tb81,
            'AquaMate Akıllı Sıvı Takip Asistanı sunumunu dinlediğiniz için teşekkür ederiz. '
            'Sorularınız, görüşleriniz ve proje değerlendirmeleriniz memnuniyetle karşılanacaktır.',
            font_size_pt=12.0
        )

    replace_phone_image(s10, 'Freeform 19', IMG_HOME)
    replace_phone_image(s10, 'Freeform 29', IMG_STATS)
    replace_phone_image(s10, 'Freeform 39', IMG_GUIDE)
    replace_phone_image(s10, 'Freeform 49', IMG_SETTINGS)
    replace_phone_image(s10, 'Freeform 59', IMG_HOME)
    replace_phone_image(s10, 'Freeform 69', IMG_STATS)
    print("Slide 10 güncellendi.")

    # Kaydet
    prs.save(SOURCE_PPTX)
    print(f"Orijinal dosya güncellendi: {SOURCE_PPTX}")

    prs.save(PROJECT_PPTX)
    print(f"Proje dizinine kopyalandı: {PROJECT_PPTX}")

if __name__ == '__main__':
    main()
