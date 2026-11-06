import 'package:flutter/material.dart';

/// Kabın yaşam döngüsü grubu.
enum ContainerGroup {
  /// Tekrar kullanılabilir (matara, cam bardak).
  reusable('Tekrar kullanılabilir'),

  /// Tek kullanımlık ambalaj (PET, karton bardak).
  singleUse('Tek kullanımlık');

  const ContainerGroup(this.label);

  final String label;
}

/// İçeceğin içildiği kap/ambalaj.
///
/// Atık ve CO2e değerleri 500 ml referans hacim içindir; gerçek kayıt için
/// [wasteFor] / [co2For] fonksiyonları ml'e göre doğrusal ölçekler.
/// Değerler yaşam döngüsü analizi (LCA) literatüründen yaklaşık alınmıştır;
/// amaç kesin muhasebe değil, kullanıcıya tutarlı bir karşılaştırma sunmaktır.
class ContainerType {
  const ContainerType({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.icon,
    required this.color,
    required this.group,
    required this.wasteGramsPer500ml,
    required this.co2GramsPer500ml,
    required this.recyclable,
    required this.ecoScore,
  });

  final String id;
  final String label;
  final String shortLabel;
  final IconData icon;
  final Color color;
  final ContainerGroup group;

  /// 500 ml içecek için üretilen ambalaj atığı (g).
  final int wasteGramsPer500ml;

  /// 500 ml içecek için ambalaj kaynaklı CO2e (g).
  final int co2GramsPer500ml;

  /// Belediye geri dönüşümünde kabul edilir mi?
  final bool recyclable;

  /// 0-100 arası sürdürülebilirlik puanı.
  final int ecoScore;

  bool get isReusable => group == ContainerGroup.reusable;

  /// Tek kullanımlık ve geri dönüştürülemez ambalaj.
  bool get isNonRecyclable => !isReusable && !recyclable;

  double wasteFor(int ml) => wasteGramsPer500ml * ml / 500;

  double co2For(int ml) => co2GramsPer500ml * ml / 500;
}

/// Kap kataloğu. Sıra, seçim ekranındaki gösterim sırasıdır.
const List<ContainerType> kContainerTypes = <ContainerType>[
  ContainerType(
    id: 'reusable_bottle',
    label: 'Matara / Termos',
    shortLabel: 'Matara',
    icon: Icons.sports_bar_rounded,
    color: Color(0xFF10B981),
    group: ContainerGroup.reusable,
    wasteGramsPer500ml: 0,
    co2GramsPer500ml: 5,
    recyclable: false,
    ecoScore: 100,
  ),
  ContainerType(
    id: 'reusable_cup',
    label: 'Kendi bardağım',
    shortLabel: 'Kendi bardağım',
    icon: Icons.emoji_food_beverage_rounded,
    color: Color(0xFF059669),
    group: ContainerGroup.reusable,
    wasteGramsPer500ml: 0,
    co2GramsPer500ml: 8,
    recyclable: false,
    ecoScore: 95,
  ),
  ContainerType(
    id: 'glass_cup',
    label: 'Cam bardak',
    shortLabel: 'Cam bardak',
    icon: Icons.wine_bar_rounded,
    color: Color(0xFF0891B2),
    group: ContainerGroup.reusable,
    wasteGramsPer500ml: 0,
    co2GramsPer500ml: 8,
    recyclable: false,
    ecoScore: 95,
  ),
  ContainerType(
    id: 'glass_bottle',
    label: 'Cam şişe',
    shortLabel: 'Cam şişe',
    icon: Icons.local_drink_rounded,
    color: Color(0xFF14B8A6),
    group: ContainerGroup.singleUse,
    wasteGramsPer500ml: 350,
    co2GramsPer500ml: 200,
    recyclable: true,
    ecoScore: 60,
  ),
  ContainerType(
    id: 'aluminum_can',
    label: 'Alüminyum kutu',
    shortLabel: 'Alüminyum',
    icon: Icons.local_drink_rounded,
    color: Color(0xFF64748B),
    group: ContainerGroup.singleUse,
    wasteGramsPer500ml: 13,
    co2GramsPer500ml: 120,
    recyclable: true,
    ecoScore: 55,
  ),
  ContainerType(
    id: 'pet_bottle',
    label: 'PET şişe',
    shortLabel: 'PET şişe',
    icon: Icons.local_drink_rounded,
    color: Color(0xFF3B82F6),
    group: ContainerGroup.singleUse,
    wasteGramsPer500ml: 14,
    co2GramsPer500ml: 82,
    recyclable: true,
    ecoScore: 45,
  ),
  ContainerType(
    id: 'plastic_cup',
    label: 'Plastik bardak',
    shortLabel: 'Plastik',
    icon: Icons.local_cafe_rounded,
    color: Color(0xFF6366F1),
    group: ContainerGroup.singleUse,
    wasteGramsPer500ml: 6,
    co2GramsPer500ml: 25,
    recyclable: true,
    ecoScore: 35,
  ),
  ContainerType(
    id: 'tetra_pak',
    label: 'Tetra pak',
    shortLabel: 'Tetra pak',
    icon: Icons.inventory_2_rounded,
    color: Color(0xFFF97316),
    group: ContainerGroup.singleUse,
    wasteGramsPer500ml: 25,
    co2GramsPer500ml: 60,
    recyclable: false,
    ecoScore: 30,
  ),
  ContainerType(
    id: 'paper_cup',
    label: 'Karton bardak',
    shortLabel: 'Karton',
    icon: Icons.local_cafe_rounded,
    color: Color(0xFFA16207),
    group: ContainerGroup.singleUse,
    wasteGramsPer500ml: 12,
    co2GramsPer500ml: 55,
    recyclable: false,
    ecoScore: 25,
  ),
];

/// Kimliğe göre kap bulur; bilinmeyen kimlik için `null` döner.
ContainerType? containerOf(String? id) {
  if (id == null) {
    return null;
  }
  for (final ContainerType type in kContainerTypes) {
    if (type.id == id) {
      return type;
    }
  }
  return null;
}

/// Eko hesabında "iyi senaryo" karşılaştırması için kullanılan matara.
ContainerType get kBestCaseContainer => kContainerTypes.first;
