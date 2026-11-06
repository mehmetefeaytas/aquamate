import 'package:flutter/material.dart';

/// İçecek kategorisi - katalog ekranındaki gruplama ve filtreler için.
enum DrinkCategory {
  water('Su & Soda'),
  tea('Çay'),
  coffee('Kahve'),
  juice('Meyve & Tatlı İçecekler'),
  dairy('Süt Ürünleri'),
  energy('Enerji & Spor'),
  other('Diğer');

  const DrinkCategory(this.label);

  final String label;
}

/// Uygulamanın desteklediği içecek türleri ve gerçek hidrasyon/kafein değerleri.
class DrinkType {
  const DrinkType({
    required this.label,
    required this.shortLabel,
    required this.hydrationFactor,
    required this.caffeinePer100ml,
    required this.icon,
    required this.color,
    required this.category,
    this.defaultContainerId,
    this.isCustom = false,
    this.customId,
  });

  /// Veritabanına yazılan içecek adı (özel içecekler için de birincil anahtar).
  final String label;

  /// Çip üzerindeki kısa gösterim.
  final String shortLabel;

  /// Biyoyararlanım katsayısı (net hidrasyon / brüt miktar).
  final double hydrationFactor;

  /// 100 ml başına kafein (mg).
  final double caffeinePer100ml;

  final IconData icon;
  final Color color;
  final DrinkCategory category;

  /// Bu içecek seçildiğinde önerilen varsayılan kap.
  final String? defaultContainerId;

  /// Kullanıcının kendi eklediği içecek mi?
  final bool isCustom;

  /// `custom_drinks` tablosundaki satır kimliği (yalnızca özel içecekler).
  final int? customId;

  /// 200 ml kahve -> net hidrasyon katkısı.
  int effectiveOf(int rawMl) => (rawMl * hydrationFactor).round();

  /// 200 ml kahve -> kafein katkısı (mg).
  int caffeineOf(int rawMl) => (rawMl * caffeinePer100ml / 100).round();

  String get factorLabel => '%${(hydrationFactor * 100).round()}';

  /// Kafein içermiyorsa etiketlerde gösterilmez.
  bool get hasCaffeine => caffeinePer100ml > 0;

  DrinkType copyWith({
    String? label,
    String? shortLabel,
    double? hydrationFactor,
    double? caffeinePer100ml,
    IconData? icon,
    Color? color,
    DrinkCategory? category,
    String? defaultContainerId,
    bool? isCustom,
    int? customId,
  }) {
    return DrinkType(
      label: label ?? this.label,
      shortLabel: shortLabel ?? this.shortLabel,
      hydrationFactor: hydrationFactor ?? this.hydrationFactor,
      caffeinePer100ml: caffeinePer100ml ?? this.caffeinePer100ml,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      category: category ?? this.category,
      defaultContainerId: defaultContainerId ?? this.defaultContainerId,
      isCustom: isCustom ?? this.isCustom,
      customId: customId ?? this.customId,
    );
  }
}

/// Özel içecek oluştururken seçilebilen ikonlar.
/// Sabit liste, ağaç sarsıntısında (tree-shaking) ikonların kaybolmaması için
/// gereklidir; veritabanında bu listenin indeksi saklanır.
const List<IconData> kCustomDrinkIcons = <IconData>[
  Icons.local_drink_rounded,
  Icons.water_drop_rounded,
  Icons.emoji_food_beverage_rounded,
  Icons.coffee_rounded,
  Icons.local_cafe_rounded,
  Icons.bubble_chart_rounded,
  Icons.spa_rounded,
  Icons.bolt_rounded,
  Icons.sports_rounded,
  Icons.blender_rounded,
  Icons.free_breakfast_rounded,
  Icons.eco_rounded,
];

IconData customDrinkIconAt(int? index) {
  if (index == null || index < 0 || index >= kCustomDrinkIcons.length) {
    return kCustomDrinkIcons.first;
  }
  return kCustomDrinkIcons[index];
}

/// Yerleşik içecek kataloğu (kafein değerleri 100 ml başına mg).
///
/// Kaynak aralıkları: demli çay ~10-20 mg, filtre kahve ~35-45 mg,
/// espresso ~200-220 mg, kola ~10 mg, enerji içeceği ~30-35 mg.
const List<DrinkType> kDrinkTypes = <DrinkType>[
  // ------------------------------------------------------------------- su
  DrinkType(
    label: 'Su',
    shortLabel: 'Su',
    hydrationFactor: 1.0,
    caffeinePer100ml: 0,
    icon: Icons.water_drop_rounded,
    color: Color(0xFF1B64D0),
    category: DrinkCategory.water,
    defaultContainerId: 'reusable_bottle',
  ),
  DrinkType(
    label: 'Maden Suyu',
    shortLabel: 'Maden',
    hydrationFactor: 1.0,
    caffeinePer100ml: 0,
    icon: Icons.bubble_chart_rounded,
    color: Color(0xFF56CCF2),
    category: DrinkCategory.water,
    defaultContainerId: 'glass_bottle',
  ),
  DrinkType(
    label: 'Soda',
    shortLabel: 'Soda',
    hydrationFactor: 0.98,
    caffeinePer100ml: 0,
    icon: Icons.local_drink_rounded,
    color: Color(0xFF38BDF8),
    category: DrinkCategory.water,
    defaultContainerId: 'glass_bottle',
  ),
  // ------------------------------------------------------------------ çay
  DrinkType(
    label: 'Çay',
    shortLabel: 'Çay',
    hydrationFactor: 0.85,
    caffeinePer100ml: 15,
    icon: Icons.emoji_food_beverage_rounded,
    color: Color(0xFFF5B942),
    category: DrinkCategory.tea,
    defaultContainerId: 'glass_cup',
  ),
  DrinkType(
    label: 'Yeşil Çay',
    shortLabel: 'Yeşil Çay',
    hydrationFactor: 0.88,
    caffeinePer100ml: 8,
    icon: Icons.emoji_food_beverage_rounded,
    color: Color(0xFF84CC16),
    category: DrinkCategory.tea,
    defaultContainerId: 'glass_cup',
  ),
  DrinkType(
    label: 'Bitki Çayı',
    shortLabel: 'Bitki',
    hydrationFactor: 0.95,
    caffeinePer100ml: 0,
    icon: Icons.spa_rounded,
    color: Color(0xFFA78BFA),
    category: DrinkCategory.tea,
    defaultContainerId: 'glass_cup',
  ),
  // ---------------------------------------------------------------- kahve
  DrinkType(
    label: 'Kahve',
    shortLabel: 'Kahve',
    hydrationFactor: 0.80,
    caffeinePer100ml: 40,
    icon: Icons.coffee_rounded,
    color: Color(0xFF8B5E34),
    category: DrinkCategory.coffee,
    defaultContainerId: 'paper_cup',
  ),
  DrinkType(
    label: 'Türk Kahvesi',
    shortLabel: 'Türk K.',
    hydrationFactor: 0.75,
    caffeinePer100ml: 100,
    icon: Icons.coffee_maker_rounded,
    color: Color(0xFF6F4E37),
    category: DrinkCategory.coffee,
    defaultContainerId: 'glass_cup',
  ),
  DrinkType(
    label: 'Espresso',
    shortLabel: 'Espresso',
    hydrationFactor: 0.70,
    caffeinePer100ml: 212,
    icon: Icons.coffee_rounded,
    color: Color(0xFF4B3621),
    category: DrinkCategory.coffee,
    defaultContainerId: 'glass_cup',
  ),
  DrinkType(
    label: 'Latte',
    shortLabel: 'Latte',
    hydrationFactor: 0.85,
    caffeinePer100ml: 30,
    icon: Icons.local_cafe_rounded,
    color: Color(0xFFC89F7B),
    category: DrinkCategory.coffee,
    defaultContainerId: 'paper_cup',
  ),
  DrinkType(
    label: 'Buzlu Kahve',
    shortLabel: 'Buzlu K.',
    hydrationFactor: 0.80,
    caffeinePer100ml: 40,
    icon: Icons.local_cafe_rounded,
    color: Color(0xFF9A6B4F),
    category: DrinkCategory.coffee,
    defaultContainerId: 'plastic_cup',
  ),
  // -------------------------------------------------------------- meyve
  DrinkType(
    label: 'Kola',
    shortLabel: 'Kola',
    hydrationFactor: 0.90,
    caffeinePer100ml: 10,
    icon: Icons.local_drink_rounded,
    color: Color(0xFF7F1D1D),
    category: DrinkCategory.juice,
    defaultContainerId: 'pet_bottle',
  ),
  DrinkType(
    label: 'Limonata',
    shortLabel: 'Limonata',
    hydrationFactor: 0.92,
    caffeinePer100ml: 0,
    icon: Icons.local_bar_rounded,
    color: Color(0xFFFACC15),
    category: DrinkCategory.juice,
    defaultContainerId: 'glass_cup',
  ),
  DrinkType(
    label: 'Meyve Suyu',
    shortLabel: 'Meyve S.',
    hydrationFactor: 0.90,
    caffeinePer100ml: 0,
    icon: Icons.local_drink_rounded,
    color: Color(0xFFFB923C),
    category: DrinkCategory.juice,
    defaultContainerId: 'tetra_pak',
  ),
  DrinkType(
    label: 'Smoothie',
    shortLabel: 'Smoothie',
    hydrationFactor: 0.88,
    caffeinePer100ml: 0,
    icon: Icons.blender_rounded,
    color: Color(0xFFE879F9),
    category: DrinkCategory.juice,
    defaultContainerId: 'plastic_cup',
  ),
  DrinkType(
    label: 'Sıcak Çikolata',
    shortLabel: 'Çikolata',
    hydrationFactor: 0.85,
    caffeinePer100ml: 10,
    icon: Icons.free_breakfast_rounded,
    color: Color(0xFF78350F),
    category: DrinkCategory.juice,
    defaultContainerId: 'paper_cup',
  ),
  // ---------------------------------------------------------------- süt
  DrinkType(
    label: 'Ayran',
    shortLabel: 'Ayran',
    hydrationFactor: 0.95,
    caffeinePer100ml: 0,
    icon: Icons.local_drink_rounded,
    color: Color(0xFF93C5FD),
    category: DrinkCategory.dairy,
    defaultContainerId: 'glass_cup',
  ),
  DrinkType(
    label: 'Kefir',
    shortLabel: 'Kefir',
    hydrationFactor: 0.95,
    caffeinePer100ml: 0,
    icon: Icons.local_drink_rounded,
    color: Color(0xFFA5B4FC),
    category: DrinkCategory.dairy,
    defaultContainerId: 'glass_cup',
  ),
  DrinkType(
    label: 'Süt',
    shortLabel: 'Süt',
    hydrationFactor: 0.90,
    caffeinePer100ml: 0,
    icon: Icons.local_drink_rounded,
    color: Color(0xFFE2E8F0),
    category: DrinkCategory.dairy,
    defaultContainerId: 'tetra_pak',
  ),
  // ------------------------------------------------------------- enerji
  DrinkType(
    label: 'Enerji İçeceği',
    shortLabel: 'Enerji',
    hydrationFactor: 0.85,
    caffeinePer100ml: 32,
    icon: Icons.bolt_rounded,
    color: Color(0xFFDC2626),
    category: DrinkCategory.energy,
    defaultContainerId: 'aluminum_can',
  ),
  DrinkType(
    label: 'Sporcu İçeceği',
    shortLabel: 'Sporcu',
    hydrationFactor: 1.0,
    caffeinePer100ml: 0,
    icon: Icons.sports_rounded,
    color: Color(0xFF0EA5E9),
    category: DrinkCategory.energy,
    defaultContainerId: 'pet_bottle',
  ),
  DrinkType(
    label: 'Hindistan Cevizi Suyu',
    shortLabel: 'Hindistan C.',
    hydrationFactor: 1.0,
    caffeinePer100ml: 0,
    icon: Icons.eco_rounded,
    color: Color(0xFF65A30D),
    category: DrinkCategory.energy,
    defaultContainerId: 'tetra_pak',
  ),
];

/// Katalog araması sırasında kullanıcı yazarken Türkçe karakterleri
/// sadeleştirerek eşleştirme yapılır (çay -> cay).
String normalizeForSearch(String value) {
  const Map<String, String> map = <String, String>{
    'ı': 'i',
    'İ': 'i',
    'ş': 's',
    'Ş': 's',
    'ğ': 'g',
    'Ğ': 'g',
    'ü': 'u',
    'Ü': 'u',
    'ö': 'o',
    'Ö': 'o',
    'ç': 'c',
    'Ç': 'c',
  };
  final StringBuffer buffer = StringBuffer();
  for (final int rune in value.runes) {
    final String char = String.fromCharCode(rune);
    buffer.write(map[char] ?? char.toLowerCase());
  }
  return buffer.toString();
}

/// Çalışma zamanı kayıt defteri: yerleşik + kullanıcı tanımlı içecekler.
///
/// `DrinkRepository` özel içecekleri yükledikçe bu defteri günceller; böylece
/// `WaterLog.type` gibi senkron erişim noktaları da özel içecekleri tanır.
final Map<String, DrinkType> _registry = <String, DrinkType>{
  for (final DrinkType type in kDrinkTypes) type.label: type,
};

void registerDrinkType(DrinkType type) {
  _registry[type.label] = type;
}

void unregisterDrinkType(String label) {
  if (kDrinkTypes.any((DrinkType t) => t.label == label)) {
    return;
  }
  _registry.remove(label);
}

void registerAllDrinkTypes(Iterable<DrinkType> types) {
  for (final DrinkType type in types) {
    registerDrinkType(type);
  }
}

/// Etiketten içecek tanımı bulur (veritabanı okumaları için).
///
/// Silinmiş bir özel içeceğin eski kaydı okunursa, kayıt bozulmasın diye
/// nötr bir tanım üretilir.
DrinkType drinkTypeOf(String label) {
  final DrinkType? known = _registry[label];
  if (known != null) {
    return known;
  }
  final DrinkType fallback = DrinkType(
    label: label,
    shortLabel: label,
    hydrationFactor: 0.9,
    caffeinePer100ml: 0,
    icon: Icons.local_drink_rounded,
    color: const Color(0xFF94A3B8),
    category: DrinkCategory.other,
    isCustom: true,
  );
  _registry[label] = fallback;
  return fallback;
}

/// Katalogdaki tüm yerleşik kategoriler (boş olanlar dahil).
List<DrinkCategory> get kDrinkCategories => DrinkCategory.values;
