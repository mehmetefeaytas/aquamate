#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
TÜBİTAK 2209-A Başvuru Formu Doldurucu: AquaMate Araştırma Projesi
Yürütücü: Mehmet Efe Aytaş (Öğrenci No: 241041103)
Danışman: Dr. Öğr. Üyesi Şerife Esra Dinçer
Kurum: İstanbul Gedik Üniversitesi
Bu betik, 'yabay-zeka' kurallarına tam uyumlu; bürokratik şişkinlik ve yapay zeka
kalıplarından arındırılmış, doğrudan Mehmet Efe Aytaş'ın üslubunda akademik bir
TÜBİTAK 2209-A Araştırma Önerisi Formu üretir.
"""

import os
import shutil
import docx
from docx import Document
from docx.shared import Pt, RGBColor
from docx.enum.text import WD_ALIGN_PARAGRAPH

TEMPLATE_PATH = '/Users/mehmetefeaytas/Downloads/2209-A_arastirma_onerisi_formu_09102025.docx'
BACKUP_PATH = '/Users/mehmetefeaytas/Downloads/2209-A_arastirma_onerisi_formu_09102025_Original_Backup.docx'
OUTPUT_DOWNLOADS = '/Users/mehmetefeaytas/Downloads/2209-A_arastirma_onerisi_formu_241041103_MehmetEfeAytas_AquaMate.docx'
OUTPUT_PROJECT = '/Users/mehmetefeaytas/Library/Mobile Documents/com~apple~CloudDocs/mobilapp/AquaMate/2209-A_arastirma_onerisi_formu_AquaMate.docx'

def set_cell_text(cell, text_or_paragraphs, font_name="Arial", font_size_pt=9.0, line_spacing=1.15, space_after_pt=4):
    """Hücrenin içeriğini temizler ve belirtilen metin/paragrafları Arial 9pt formatında yazar."""
    p0 = cell.paragraphs[0]
    p0.text = ""
    for p in cell.paragraphs[1:]:
        p._p.getparent().remove(p._p)

    if isinstance(text_or_paragraphs, str):
        paragraphs = text_or_paragraphs.split('\n\n')
    else:
        paragraphs = text_or_paragraphs

    for idx, p_text in enumerate(paragraphs):
        p_text = p_text.strip()
        if not p_text:
            continue
        p = cell.paragraphs[0] if idx == 0 else cell.add_paragraph()
        p.paragraph_format.line_spacing = line_spacing
        p.paragraph_format.space_after = Pt(space_after_pt)
        p.paragraph_format.space_before = Pt(0)
        p.alignment = WD_ALIGN_PARAGRAPH.LEFT
        
        run = p.add_run(p_text)
        run.font.name = font_name
        run.font.size = Pt(font_size_pt)
        run.font.color.rgb = RGBColor(0, 0, 0)

def main():
    if not os.path.exists(BACKUP_PATH):
        if os.path.exists(TEMPLATE_PATH):
            shutil.copy2(TEMPLATE_PATH, BACKUP_PATH)
            print(f"Boş şablon yedeklendi: {BACKUP_PATH}")
        else:
            print(f"Hata: {TEMPLATE_PATH} bulunamadı!")
            return

    # Her zaman temiz yedekten yükle
    doc = Document(BACKUP_PATH)

    # -------------------------------------------------------------
    # 0. KAPAK VE GENEL BİLGİLER
    # -------------------------------------------------------------
    for p in doc.paragraphs:
        txt = p.text.strip()
        if txt == '.....Yılı':
            p.text = '2026 Yılı'
            if p.runs:
                p.runs[0].font.name = 'Arial'
                p.runs[0].font.size = Pt(11)
                p.runs[0].font.bold = True
        elif txt == '… Dönem Başvurusu':
            p.text = '1. Dönem Başvurusu'
            if p.runs:
                p.runs[0].font.name = 'Arial'
                p.runs[0].font.size = Pt(11)
                p.runs[0].font.bold = True

    # Tablo 0: Genel Bilgiler
    t0 = doc.tables[0]
    set_cell_text(t0.cell(0, 0), "Başvuru Sahibinin Adı Soyadı: Mehmet Efe Aytaş (Öğrenci No: 241041103)", font_size_pt=9.0)
    set_cell_text(t0.cell(1, 0), "Araştırma Önerisinin Başlığı: Biyoyararlanım Destekli Akıllı Hidrasyon ve Sıvı Takip Mobil Sistemi (AquaMate)", font_size_pt=9.0)
    set_cell_text(t0.cell(2, 0), "Danışmanın Adı Soyadı: Dr. Öğr. Üyesi Şerife Esra Dinçer", font_size_pt=9.0)
    set_cell_text(t0.cell(3, 0), "Araştırmanın Yürütüleceği Kurum/Kuruluş: İstanbul Gedik Üniversitesi (Mühendislik Fakültesi, Bilgisayar Mühendisliği)", font_size_pt=9.0)

    # -------------------------------------------------------------
    # 1. ÖZET VE ANAHTAR KELİMELER (Tablo 1)
    # -------------------------------------------------------------
    t1 = doc.tables[1]
    
    ozet_metni = (
        "Bu araştırma projesi, genç yetişkinlerde ve üniversite öğrencilerinde sık görülen dehidrasyon "
        "problemine ve mevcut mobil sıvı takip uygulamalarındaki bilimsel eksikliklere yenilikçi bir çözüm "
        "sunmayı amaçlar. Geleneksel su takip sayaçları, tüketilen tüm içecekleri homojen ve saf su kabul "
        "eder; çay ve kahve gibi yaygın kafeinli içeceklerin hafif diüretik etkilerini ve biyoyararlanım "
        "farklarını göz ardı eder. Ayrıca standart günde iki litre kuralı, bireysel fizyolojik "
        "farklılıkları ve egzersiz yükünü hesaba katmaz.\n\n"
        "Projenin bilimsel niteliği; içecek türlerine göre net hidrasyon katsayılarını hesaplayan biyoyararlanım "
        "algoritması, bireysel vücut ağırlığı ve fiziksel aktiviteye dayalı dinamik hedef formülü "
        "(H = Kilo x 35 + Egzersiz/30 x 350 ml) ve sıvı dinamiğini CustomPainter ile modelleyen çift katmanlı "
        "sinüs dalgası simülasyonunun bütünleştirilmesine dayanır. Araştırmanın temel sorusu; biyoyararlanım "
        "odaklı ve duyusal geri bildirimlerle (dalga fiziği, ses, haptik) desteklenen bir mobil hidrasyon "
        "asistanının, bireylerin günlük net sıvı dengesi ve sürdürülebilir içme davranışı üzerindeki etkisini ölçmektir.\n\n"
        "Yöntem olarak Tasarım ve Geliştirme Araştırması (Design and Development Research - DDR) modeli "
        "benimsenmiştir. Proje, Flutter ve Dart ile çapraz platform mimarisinde geliştirilmekte, yerel SQLite "
        "veritabanı üzerinde güvenli veri kalıcılığı sunar. Sistemin etkinliği; 40 üniversite öğrencisinden "
        "oluşan deney ve kontrol grupları üzerinden karşılaştırmalı hidrasyon logları, A/B testleri, periyodik "
        "hatırlatıcı etkileşimleri ve Sistem Kullanılabilirlik Ölçeği (SUS) anketleri aracılığıyla incelenecektir.\n\n"
        "On iki aylık proje süresi dört ana fazdan oluşur: Biyoyararlanım motorunun geliştirilmesi, duyusal arayüz "
        "ve dalga fiziğinin kodlanması, yerel veritabanı ve bildirim servislerinin optimizasyonu ile pilot deneysel "
        "uygulama ve etki değerlendirmesi. Proje; On İkinci Kalkınma Planı'nın dijital sağlık ve koruyucu hekimlik "
        "hedeflerini doğrudan destekler."
    )
    set_cell_text(t1.cell(0, 0), ozet_metni, font_size_pt=9.0)

    anahtar_kelimeler = "Anahtar Kelimeler: Mobil Sağlık, Biyoyararlanım, Hidrasyon Takibi, Tasarım Tabanlı Araştırma, Alışkanlık Kazanımı"
    set_cell_text(t1.cell(1, 0), anahtar_kelimeler, font_size_pt=9.0)

    # -------------------------------------------------------------
    # 2. ARAŞTIRMA ÖNERİSİNİN BİLİMSEL NİTELİĞİ (Tablo 2)
    # -------------------------------------------------------------
    t2 = doc.tables[2]
    bilimsel_nitelik_metni = (
        "1.1. Konunun Önemi ve Araştırma Önerisinin Bilimsel Niteliği\n\n"
        "Üniversite öğrencilerinin ve genç yetişkinlerin günlük yaşamında sıvı tüketimi sıklıkla ihmal edilir. "
        "Düzensiz ders saatleri, uzun süreli ekran maruziyeti ve aşırı çay-kahve tüketimi, bireyleri kronik hafif "
        "dehidrasyon riskiyle karşı karşıya bırakır. Tıp literatürü; vücut ağırlığının %1 ila %2'si oranındaki "
        "hafif sıvı kaybının bile kognitif performansı, dikkat süresini ve kısa süreli belleği zayıflattığını, "
        "baş ağrısı ile yorgunluğu tetiklediğini ortaya koyar (Armstrong ve ark., 2012; Popkin ve ark., 2010).\n\n"
        "Mevcut mobil su takip uygulamaları incelendiğinde iki temel bilimsel eksiklik görülür:\n"
        "1. İçeceklerin Biyoyararlanım Farkının Göz Ardı Edilmesi: Yaygın uygulamalar 200 ml kahve veya çayı 200 ml "
        "saf su ile eşdeğer kaydeder. Oysa kafein içeriği nedeniyle kahve ve siyah çayın hafif diüretik etkisi "
        "bulunur; vücuda kazandırdığı net hidrasyon saf sudan düşüktür (Maughan ve Griffin, 2003). AquaMate, "
        "Avrupa Gıda Güvenliği Otoritesi (EFSA, 2010) referanslarına dayanarak içecek türlerine biyoyararlanım "
        "katsayısı uygular (Su: 1.00, Maden Suyu: 1.00, Çay: 0.85, Kahve: 0.80). Örneğin kullanıcı 200 ml kahve "
        "içtiğinde sistem bunu net 160 ml hidrasyon olarak işler.\n\n"
        "2. Sabit ve Ezbere Hedef Dayatması: Standart 'günde 2 litre' kuralı, bireyin vücut kütlesini ve terleme "
        "ile sıvı kaybını belirleyen fiziksel aktivitesini hesaba katmaz. AquaMate, bilimsel temelli dinamik bir formül "
        "kullanır: Günlük Hedef (ml) = Vücut Ağırlığı (kg) x 35 + (Egzersiz Süresi (dk) / 30) x 350 ml.\n\n"
        "Bu bilimsel temellerin yanı sıra, mHealth uygulamalarında en büyük problem kullanıcı motivasyonunun hızla "
        "tükenmesidir. AquaMate, duyusal arayüz tasarımı ile davranışsal alışkanlık kazanımını destekler. Flutter "
        "CustomPainter motoru üzerinde trigonometrik sinüs dalgası formülü (y = A * sin(omega * x + phi) + k) "
        "kullanılarak 60 FPS akıcılıkta çalışan çift katmanlı sıvı fiziği simülasyonu kodlanmıştır. Sıvı eklendiğinde "
        "tetiklenen gerçekçi damla sesi (audioplayers) ve dokunsal titreşim (HapticFeedback), kullanıcıda dopamin "
        "temelli bir pekiştirme döngüsü oluşturur.\n\n"
        "12. Kalkınma Planı ve 2030 Sanayi ve Teknoloji Stratejisi ile İlişkisi:\n"
        "Proje, On İkinci Kalkınma Planı'nın 'Sağlık ve Yaşam Kalitesi' ile 'Önleyici Sağlık Hizmetleri ve Dijital "
        "Teknolojiler' öncelikli alanlarıyla doğrudan örtüşür. Bireylerin günlük sağlıklı hidrasyon alışkanlığı "
        "kazanmasını sağlamak, uzun vadede dehidrasyona bağlı böbrek taşı, idrar yolu enfeksiyonları ve metabolik "
        "hastalıkların önlenmesine somut katkı sunar.\n\n"
        "Araştırma Sorusu:\n"
        "'Biyoyararlanım katsayılarını hesaplayan ve duyusal geri bildirimlerle (dalga fiziği, ses, haptik) desteklenen "
        "akıllı bir mobil hidrasyon takip sisteminin kullanılması; üniversite öğrencilerinin günlük net sıvı hedefine "
        "ulaşma tutarlılığını, hidrasyon farkındalığını ve su içme davranışı kazanımını ne ölçüde artırır?'\n\n"
        "Araştırma Hipotezleri:\n"
        "• H1: Biyoyararlanım katsayılı akıllı takip sistemini kullanan deney grubunun günlük net sıvı hedefine ulaşma "
        "oranı, geleneksel sabit sayaç kullanan kontrol grubuna göre anlamlı derecede yüksektir (p < 0.05).\n"
        "• H2: Kişiselleştirilmiş kilo ve egzersiz formülüyle hedef belirleyen kullanıcıların algılanan yorgunluk ve "
        "dikkat dağınıklığı düzeyleri başlangıç ölçümüne göre anlamlı şekilde azalır.\n"
        "• H3: Çift katmanlı sıvı fiziği simülasyonu ve işitsel geri bildirim içeren duyusal arayüz, standart arayüzlere "
        "kıyasla uygulama kullanım sürekliliğini ve kullanıcı memnuniyetini artırır (SUS skoru >= 80)."
    )
    set_cell_text(t2.cell(0, 0), bilimsel_nitelik_metni, font_size_pt=9.0)

    # -------------------------------------------------------------
    # 3. AMAÇ VE HEDEFLER (Tablo 3)
    # -------------------------------------------------------------
    t3 = doc.tables[3]
    amac_hedefler_metni = (
        "1.2. Amaç ve Hedefler\n\n"
        "Bu araştırmanın temel amacı; genç yetişkinlerin ve üniversite öğrencilerinin sıvı tüketim alışkanlıklarını "
        "bilimsel biyoyararlanım katsayıları, kişiselleştirilmiş hedef algoritmaları ve duyusal arayüz bileşenleriyle "
        "takip eden, ölçülebilir ve veri odaklı bir mobil hidrasyon sistemi (AquaMate) prototipi geliştirmek ve "
        "etkinliğini deneysel yöntemlerle ortaya koymaktır.\n\n"
        "Proje kapsamında belirlenen somut ve ölçülebilir alt hedefler şunlardır:\n"
        "1. Biyoyararlanım ve Dinamik Hedef Algoritmasının Geliştirilmesi: Tüketilen içeceklerin gerçek hidrasyon "
        "katkısını hesaplayan katsayı matrisini ve kilo-egzersiz parametrelerine dayalı hedef formülünü kodlamak; model "
        "dönüşümlerini birim testlerle tam başarıyla doğrulamak.\n"
        "2. Çift Katmanlı Sıvı Fiziği Motorunun Tasarımı: Flutter CustomPainter altyapısıyla 60 FPS akıcılıkta "
        "çalışan, iki farklı faz açısına sahip sinüzoidal dalga simülasyonu ve 270 derecelik dairesel ilerleme "
        "halkası geliştirmek.\n"
        "3. Yerel ve Güvenli Veri Mimarisi Kurulumu: SQLite (sqflite) ilişkisel veritabanı ile verilerin kullanıcı "
        "cihazında ağ bağımlılığı olmadan kalıcı olarak saklanmasını sağlamak, aggregate SQL sorguları ile anlık "
        "tüketim toplamlarını ve kesintisiz streak (seri) gün sayısını hesaplamak.\n"
        "4. Adaptif Yerel Bildirim Servisi: Kullanıcının belirlediği uyanma ve uyuma saatleri aralığında, kullanıcıyı "
        "rahatsız etmeden çalışan periyodik hatırlatıcı zamanlama motorunu entegre etmek.\n"
        "5. Çoklu Ortam Sağlık Rehberi Modülü: video_player ve audioplayers paketleri ile interaktif video eğitimi "
        "ve sesli hidrasyon anlatımı içeren multimodal bir öğrenme ortamı sunmak.\n"
        "6. Kontrollü Pilot Uygulama ve Bilimsel Değerlendirme: İstanbul Gedik Üniversitesi'nden 40 öğrenciyle "
        "(20 deney, 20 kontrol) 8 haftalık kontrollü pilot çalışma yürütmek; günlük net hidrasyon verilerini, "
        "loglama devamlılığını ve Sistem Kullanılabilirlik Ölçeği (SUS) puanlarını toplayarak hipotezleri test etmek."
    )
    set_cell_text(t3.cell(0, 0), amac_hedefler_metni, font_size_pt=9.0)

    # -------------------------------------------------------------
    # 4. YÖNTEM (Tablo 4)
    # -------------------------------------------------------------
    t4 = doc.tables[4]
    yontem_metni = (
        "2. YÖNTEM\n\n"
        "Araştırmada Tasarım ve Geliştirme Araştırması (Design and Development Research - DDR) yöntemi "
        "benimsenmiştir (Richey ve Klein, 2008). Bu yöntem, yenilikçi bir teknolojik ürünün tasarlanmasını, "
        "geliştirilmesini ve etkililiğinin gerçek kullanıcılar üzerinde deneysel olarak değerlendirilmesini kapsar.\n\n"
        "1. Ön Çalışma ve Teknik Hazır Bulunuşluk:\n"
        "Proje sıfırdan başlanan soyut bir fikir değildir. Yürütücü Mehmet Efe Aytaş tarafından Flutter SDK ve Dart "
        "dili ile AquaMate prototipinin temel omurgası kodlanmış, statik kod analizinde sıfır hata ve sıfır uyarı "
        "elde edilmiş, 7 adet otomatik birim testi tamamlanmış ve Apple TestFlight ortamında (v1.0.0+3) "
        "teknik uygulanabilirliği test edilmiştir.\n\n"
        "2. Geliştirme Metodolojisi (Agile/Scrum):\n"
        "Geliştirme süreci iki haftalık sprintler halinde yürütülecektir.\n"
        "• Mimari Yapı: Katmanlı temiz mimari (Clean Architecture) ve modüler servis tasarımı.\n"
        "• Teknolojiler: Flutter 3.x, Dart 3.x, SQLite (sqflite yerel veritabanı), fl_chart (haftalık sütun ve "
        "pasta grafikler), audioplayers (damla sesi ve sesli rehber), video_player (eğitim videosu oynatıcı), "
        "flutter_local_notifications (yerel bildirimler).\n\n"
        "3. Deneysel Tasarım ve Grupların Oluşturulması:\n"
        "Araştırmanın etki değerlendirmesi ön test-son test kontrol gruplu yarı deneysel desenle yürütülecektir:\n"
        "• Örneklem: İstanbul Gedik Üniversitesi'nde öğrenim gören 40 gönüllü öğrenci. Katılımcılar rastgele 20 kişilik "
        "Deney Grubu ve 20 kişilik Kontrol Grubu olarak ayrılacaktır.\n"
        "• Deney Grubu: Biyoyararlanım katsayılı, dinamik hedef hesaplayıcılı, dalga fiziği simülasyonlu ve duyusal "
        "geri bildirimli AquaMate uygulamasını kullanacaktır.\n"
        "• Kontrol Grubu: Yalnızca düz hacim sayacı içeren, biyoyararlanım hesabı ve duyusal fizik animasyonu "
        "bulunmayan standart takip arayüzünü kullanacaktır.\n\n"
        "4. Değişkenler ve İstatistiksel Analiz:\n"
        "• Bağımsız Değişkenler: Biyoyararlanım algoritması, dinamik hedef formülü ve duyusal arayüz özellikleri.\n"
        "• Bağımlı Değişkenler: Günlük net sıvı tüketim miktarı (ml), günlük hedefe ulaşma oranı (%), loglama sıklığı "
        "ve sürekliliği (streak), dehidrasyon semptom algısı (yorgunluk/baş ağrısı) ve Sistem Kullanılabilirlik Ölçeği "
        "(SUS) skoru.\n"
        "• Analiz Yöntemleri: Verilerin normallik dağılımı Shapiro-Wilk testiyle incelenecektir. Gruplar arası "
        "karşılaştırmalarda Bağımsız Örneklem t-Testi (veya Mann-Whitney U testi); grup içi ön test-son test "
        "değişimlerinde Eşleştirilmiş Örneklem t-Testi (veya Wilcoxon testi) kullanılacaktır. İstatistiksel anlamlılık "
        "düzeyi p < 0.05 olarak kabul edilecektir. Nitel geri bildirimler içerik analiziyle tematik olarak "
        "sınıflandırılacaktır."
    )
    set_cell_text(t4.cell(0, 0), yontem_metni, font_size_pt=9.0)

    # -------------------------------------------------------------
    # 5. ÇALIŞMA TAKVİMİ (Tablo 5)
    # -------------------------------------------------------------
    t5 = doc.tables[5]
    work_packages = [
        ("01/03/2026 –\n01/06/2026",
         "İP 1: Biyoyararlanım ve Dinamik Hedef Algoritmalarının Geliştirilmesi\n"
         "• İçecek biyoyararlanım katsayı matrisinin (Su: 1.0, Maden Suyu: 1.0, Çay: 0.85, Kahve: 0.80) matematiksel modellenmesi.\n"
         "• Kilo ve egzersiz süresine dayalı dinamik hedef formülünün kodlanması.\n"
         "• Veri modellerinin doğrulanması ve otomatik birim testlerinin hazırlanması.",
         "Mehmet Efe Aytaş",
         "Biyoyararlanım katsayı matrisinin ve formül motorunun tamamlanması; birim testlerin tam başarıyla (7/7) geçmesi.\n\nKatkı Oranı: %25"),

        ("01/06/2026 –\n01/09/2026",
         "İP 2: Duyusal Arayüz, Çift Katmanlı Dalga Fiziği ve Çoklu Ortam Entegrasyonu\n"
         "• CustomPainter ile 60 FPS akıcılıkta sinüzoidal dalga simülasyonu ve 270° ilerleme halkasının kodlanması.\n"
         "• audioplayers paketi ile gerçekçi damla sesi ve sesli hidrasyon rehberinin entegre edilmesi.\n"
         "• video_player ile eğitim videosu oynatıcısı ve Apple HIG uyumlu buzlu cam dock bar geliştirilmesi.",
         "Mehmet Efe Aytaş",
         "Duyusal arayüz bileşenlerinin tamamlanması; 60 FPS kararlı render performansının ve ses/video akışının doğrulanması.\n\nKatkı Oranı: %25"),

        ("01/09/2026 –\n01/12/2026",
         "İP 3: Yerel Veritabanı (SQLite), Adaptif Bildirim ve Veri Güvenliği Mimarisi\n"
         "• SQLite (sqflite) veritabanı şemasının (water_logs ve user_settings) oluşturulması ve indekslenmesi.\n"
         "• Aggregate SQL sorguları ve kesintisiz seri (streak) hesaplama algoritmasının kodlanması.\n"
         "• flutter_local_notifications ile uyanma/uyuma saatlerine duyarlı periyodik bildirim motorunun geliştirilmesi.",
         "Mehmet Efe Aytaş",
         "Veritabanı CRUD operasyonlarının sıfır veri kaybıyla tamamlanması; yerel bildirim servisinin kararlı çalışması.\n\nKatkı Oranı: %25"),

        ("01/12/2026 –\n01/03/2027",
         "İP 4: Pilot Deneysel Uygulama, İstatistiksel Analiz ve Bilimsel Raporlama\n"
         "• 40 katılımcı ile (20 deney, 20 kontrol) 8 haftalık kontrollü pilot çalışmanın yürütülmesi.\n"
         "• Günlük tüketim kayıtlarının, loglama devamlılığının ve SUS kullanılabilirlik anketlerinin toplanması.\n"
         "• İstatistiksel hipotez testlerinin (t-Testi / Mann-Whitney U) gerçekleştirilmesi ve sonuç raporunun hazırlanması.",
         "Mehmet Efe Aytaş",
         "Pilot uygulama verilerinin analiz edilmesi; araştırma hipotezlerinin test edilmesi ve bilimsel proje sonuç raporunun tamamlanması.\n\nKatkı Oranı: %25")
    ]

    for idx, (dates, activities, person, metrics) in enumerate(work_packages):
        row = t5.rows[idx + 1]
        set_cell_text(row.cells[0], dates, font_size_pt=8.5)
        set_cell_text(row.cells[1], activities, font_size_pt=8.5)
        set_cell_text(row.cells[2], person, font_size_pt=8.5)
        set_cell_text(row.cells[3], metrics, font_size_pt=8.5)

    # 5. boş satırı tablodan sil
    if len(t5.rows) > 5:
        tr = t5.rows[5]._tr
        tr.getparent().remove(tr)

    # -------------------------------------------------------------
    # 6. RİSK YÖNETİMİ (Tablo 6)
    # -------------------------------------------------------------
    t6 = doc.tables[6]
    risks = [
        ("Risk 1: Düşük Kullanıcı Katılımı ve Loglama İhmali (Kullanıcı Attrition)\n\n"
         "Pilot çalışma sürecinde katılımcıların içtikleri sıvıları uygulamaya kaydetmeyi unutması veya "
         "zamanla uygulamayı kullanmayı bırakması riski.",
         "Alınacak Tedbirler (B Planı):\n\n"
         "Bildirim saatleri kullanıcının uyanma ve uyuma aralığına göre kişiselleştirilecek; ana sayfada tek "
         "dokunuşla hızlı loglama (Quick Add) butonları sunulacaktır. Kullanıcı motivasyonunu canlı tutmak "
         "için streak (seri) takibi, görsel dalga seviyesi ve dinamik motive edici bildirimler kullanılacaktır."),

        ("Risk 2: Donanım ve İşletim Sistemi Kısıtlamalarında Pil/Performans Sorunları\n\n"
         "Farklı işletim sistemi sürümlerinde arka plan bildirimlerinin kısıtlanması veya sürekli çalışan "
         "dalga animasyonunun pil tüketimini artırması riski.",
         "Alınacak Tedbirler (B Planı):\n\n"
         "CustomPainter dalga animasyonu yalnızca ekran açık ve widget görünür durumdayken render edilecek "
         "(TickerMode ve Visibility optimizasyonu). Yerel bildirim servisi cihazın yerel AlarmManager / "
         "UNUserNotificationCenter standartlarına göre yapılandırılarak gereksiz pil tüketimi önlenecektir.")
    ]

    for idx, (risk_txt, plan_txt) in enumerate(risks):
        row = t6.rows[idx + 1]
        set_cell_text(row.cells[0], risk_txt, font_size_pt=8.5)
        set_cell_text(row.cells[1], plan_txt, font_size_pt=8.5)

    # -------------------------------------------------------------
    # 7. ARAŞTIRMA OLANAKLARI (Tablo 7)
    # -------------------------------------------------------------
    t7 = doc.tables[7]
    resources = [
        ("İstanbul Gedik Üniversitesi Bilgisayar Laboratuvarları ve Kütüphanesi\n\n"
         "Yazılım geliştirme ortamları, araştırma veritabanları (IEEE Xplore, ScienceDirect, PubMed) ve pilot "
         "uygulama katılımcı koordinasyon olanakları.",
         "Proje kapsamında yürütülecek literatür taraması, mHealth ve hidrasyon standartlarının araştırılması "
         "ve üniversite öğrencileriyle gerçekleştirilecek pilot çalışma oturumlarının koordine edilmesi amacıyla "
         "kullanılacaktır."),

        ("Proje Yürütücüsüne Ait Apple macOS Geliştirme İstasyonu ve Mobil Test Cihazları\n\n"
         "Apple M-serisi işlemcili geliştirme donanımı, Xcode iOS Simülatörleri, Android Emülatörleri ve fiziksel "
         "test telefonları (iPhone ve Android).",
         "Flutter SDK ve Dart geliştirme ortamının çalıştırılması, CustomPainter 60 FPS grafik optimizasyonları, "
         "yerel SQLite veritabanı testleri ve TestFlight dağıtım süreçlerinin yürütülmesi amacıyla kullanılacaktır.")
    ]

    for idx, (res_txt, purpose_txt) in enumerate(resources):
        row = t7.rows[idx + 1]
        set_cell_text(row.cells[0], res_txt, font_size_pt=8.5)
        set_cell_text(row.cells[1], purpose_txt, font_size_pt=8.5)

    # -------------------------------------------------------------
    # 8. YAYGIN ETKİ (Tablo 8)
    # -------------------------------------------------------------
    t8 = doc.tables[8]
    effects = [
        ("Bilimsel/Akademik Çıktılar:\n"
         "• Araştırma bulgularının, mobil sağlık (mHealth) veya insan-bilgisayar etkileşimi (HCI) alanında ulusal "
         "bir bilimsel toplantıda (örn. IEEE SIU veya TBD Bilişim Kurultayı) bildiri olarak sunulması.\n"
         "• Biyoyararlanım katsayılı takip sisteminin genç yetişkinlerde sıvı dengesi ve alışkanlık kazanımı üzerine "
         "etkisini inceleyen hakemli bir bilimsel makale çalışmasına dönüştürülmesi."),

        ("Ekonomik/Ticari/Sosyal Çıktılar:\n"
         "• Ürün/Prototip: iOS ve Android platformları için App Store ve Google Play standartlarında çalışan, "
         "açık kaynak veya ticarileşebilir 'AquaMate' akıllı mobil hidrasyon uygulaması prototipi.\n"
         "• Sosyal Çıktı: Üniversite gençliğinde yaygın olan kronik hafif dehidrasyon riskine karşı bilimsel "
         "farkındalık oluşturulması; çay ve kahve tüketirken su dengesinin korunması bilincinin yaygınlaşması.\n"
         "• Ekonomik Çıktı: Koruyucu sağlık yaklaşımıyla dehidrasyona bağlı sağlık problemlerinin (baş ağrısı, "
         "böbrek taşı vb.) önlenmesine katkı sunularak sağlık harcamalarının azaltılmasına destek verilmesi."),

        ("Yeni Proje(ler) Oluşturmasına Yönelik Çıktılar:\n"
         "• Prototip sonuçlarının ve pilot çalışma bulgularının geliştirilerek akıllı saat (Apple Watch, WearOS) "
         "ve giyilebilir sensör entegrasyonlarını içeren bir TÜBİTAK 2209-B Sanayi Odaklı Lisans Projesine veya "
         "TÜBİTAK 1512 BİGG Girişimcilik Programına dönüştürülmesi.\n"
         "• Üniversite sağlık merkezleri ve spor bilimleri fakülteleriyle iş birliği yapılarak sporcular ve "
         "kronik hastalar için özelleştirilmiş yeni klinik araştırma projelerinin kurgulanması.")
    ]

    for idx, eff_text in enumerate(effects):
        row = t8.rows[idx + 1]
        set_cell_text(row.cells[1], eff_text, font_size_pt=8.5)

    # -------------------------------------------------------------
    # 9. BELİRTMEK İSTEDİĞİNİZ DİĞER KONULAR (Tablo 9)
    # -------------------------------------------------------------
    t9 = doc.tables[9]
    diger_konular_metni = (
        "5. BELİRTMEK İSTEDİĞİNİZ DİĞER KONULAR\n\n"
        "Teknik Ön Çalışma ve Hazır Bulunuşluk Durumu:\n"
        "Bu araştırma projesi, sıfırdan başlanacak bir yazılım geliştirme çalışması olmayıp proje yürütücüsü "
        "Mehmet Efe Aytaş tarafından son dönemde gerçekleştirilen yoğun Ar-Ge ve prototip geliştirme çalışmalarına "
        "dayanır. AquaMate uygulamasının teknik mimarisi kurulmuş, temel modüller kodlanmış ve kalite güvence "
        "testleri başarıyla tamamlanmıştır:\n\n"
        "1. Kod Kalitesi ve Statik Analiz:\n"
        "Proje kod tabanında 'flutter analyze' statik kod analizi çalıştırılmış; sıfır hata ve sıfır uyarı "
        "(0 issues found) elde edilmiştir. Kod tabanı Flutter linter kurallarına bütünüyle uygundur.\n\n"
        "2. Otomatik Birim ve Mantık Testleri:\n"
        "'flutter test' ortamında 7 adet kapsamlı birim testi hazırlanmış ve tüm testler tam başarıyla "
        "geçmiştir. Test senaryoları; biyoyararlanım katsayı hesaplamalarını (Kahve %80, Çay %85, Su %100), "
        "dinamik hedef algoritmasını (Kilo x 35 + Egzersiz/30 x 350 ml) ve veritabanı model serileştirmelerini doğrular.\n\n"
        "3. App Store & TestFlight Doğrulaması:\n"
        "Uygulama Apple TestFlight ortamına yüklenmiş (Sürüm 1.0.0+3), Apple Human Interface Guidelines ve iOS "
        "PrivacyInfo.xcprivacy gizlilik manifestosu gereksinimleri eksiksiz yapılandırılmıştır.\n\n"
        "Mevcut prototip altyapısı, araştırma süresinin temel yazılım mimarisi kurmak yerine doğrudan bilimsel "
        "hipotezlerin test edilmesine, kontrollü deneysel pilot çalışmanın yürütülmesine ve veri analizine "
        "ayrılmasını güvence altına alır."
    )
    set_cell_text(t9.cell(0, 0), diger_konular_metni, font_size_pt=9.0)

    # -------------------------------------------------------------
    # 10. EKLER: EK-1: KAYNAKLAR
    # -------------------------------------------------------------
    references = [
        "Armstrong, L. E., Ganio, M. S., Casa, D. J., Lee, E. C., McDermott, B. P., Klau, J. F., Jimenez, L., Le Bellego, L., Chevillotte, E., & Lieberman, H. R. (2012). Mild dehydration affects mood in healthy young women. The Journal of Nutrition, 142(2), 382–388. https://doi.org/10.3945/jn.111.142000",
        "Brooke, J. (1996). SUS: A 'quick and dirty' usability scale. In P. W. Jordan, B. Thomas, I. L. McClelland, & B. Weerdmeester (Eds.), Usability Evaluation in Industry (pp. 189–194). Taylor & Francis.",
        "EFSA Panel on Dietetic Products, Nutrition, and Allergies. (2010). Scientific opinion on dietary reference values for water. EFSA Journal, 8(3), 1459. https://doi.org/10.2903/j.efsa.2010.1459",
        "Maughan, R. J., & Griffin, J. (2003). Caffeine ingestion and fluid balance: A review. Journal of Human Nutrition and Dietetics, 16(6), 411–420. https://doi.org/10.1046/j.1365-277x.2003.00477.x",
        "Popkin, B. M., D'Anci, K. E., & Rosenberg, I. H. (2010). Water, hydration, and health. Nutrition Reviews, 68(8), 439–458. https://doi.org/10.1111/j.1753-4887.2010.00304.x",
        "Richey, R. C., & Klein, J. D. (2008). Design and development research: Methods, strategies, and issues. Routledge.",
        "T.C. Cumhurbaşkanlığı Strateji ve Bütçe Başkanlığı. (2023). On İkinci Kalkınma Planı (2024-2028). Ankara: SBB Yayınları."
    ]

    p_ref_header = None
    for p in doc.paragraphs:
        if 'EK-1:' in p.text and 'KAYNAKLAR' in p.text:
            p_ref_header = p
            break

    if p_ref_header:
        for ref in references:
            new_p = doc.add_paragraph()
            new_p.paragraph_format.line_spacing = 1.15
            new_p.paragraph_format.space_after = Pt(4)
            new_p.paragraph_format.space_before = Pt(0)
            r = new_p.add_run(ref)
            r.font.name = 'Arial'
            r.font.size = Pt(9.0)
            r.font.color.rgb = RGBColor(0, 0, 0)

    # Kaydet
    doc.save(OUTPUT_DOWNLOADS)
    print(f"Başvuru formu başarıyla oluşturuldu: {OUTPUT_DOWNLOADS}")

    doc.save(OUTPUT_PROJECT)
    print(f"Proje dizinine kopyalandı: {OUTPUT_PROJECT}")

    # Şablon dosyasının üzerine de yaz
    doc.save(TEMPLATE_PATH)
    print(f"Orijinal şablon dosyası dolduruldu: {TEMPLATE_PATH}")

if __name__ == '__main__':
    main()
