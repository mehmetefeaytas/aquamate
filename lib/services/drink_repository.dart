import 'package:flutter/material.dart';

import '../data/database_helper.dart';
import '../models/models.dart';

/// Yerleşik katalog + kullanıcının özel içeceklerini birleştiren servis.
///
/// Özel içecekler veritabanında tutulur; uygulama açılışında bir kez yüklenir
/// ve değişikliklerde [reload] çağrılır.
class DrinkRepository {
  DrinkRepository._();

  static final DrinkRepository instance = DrinkRepository._();

  List<DrinkType> _custom = <DrinkType>[];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Tüm içecekler: önce yerleşikler, sonra kullanıcı tanımlıları.
  List<DrinkType> get all => <DrinkType>[...kDrinkTypes, ..._custom];

  List<DrinkType> get custom => List<DrinkType>.unmodifiable(_custom);

  /// Katalog ekranındaki gruplama için.
  Map<DrinkCategory, List<DrinkType>> get grouped {
    final Map<DrinkCategory, List<DrinkType>> map =
        <DrinkCategory, List<DrinkType>>{};
    for (final DrinkType type in all) {
      map.putIfAbsent(type.category, () => <DrinkType>[]).add(type);
    }
    return map;
  }

  DrinkType byLabel(String label) => drinkTypeOf(label);

  /// Özel içecekleri yükler ve global kayıt defterine ekler.
  Future<void> ensureLoaded() async {
    if (_loaded) {
      return;
    }
    await reload();
  }

  Future<void> reload() async {
    try {
      final List<Map<String, Object?>> rows = await DatabaseHelper.instance
          .customDrinkRows();
      _custom = rows.map(_fromRow).toList();
      registerAllDrinkTypes(_custom);
      _loaded = true;
    } catch (_) {
      // Veritabanı açılamazsa yerleşik katalogla devam edilir.
      _custom = <DrinkType>[];
      _loaded = true;
    }
  }

  DrinkType _fromRow(Map<String, Object?> row) {
    final int? iconIndex = (row['icon_index'] as num?)?.toInt();
    final int colorValue = (row['color_value'] as num?)?.toInt() ?? 0x94A3B8;
    final String categoryName =
        (row['category'] as String?) ?? DrinkCategory.other.name;
    final DrinkCategory category = DrinkCategory.values.firstWhere(
      (DrinkCategory c) => c.name == categoryName,
      orElse: () => DrinkCategory.other,
    );

    return DrinkType(
      label: row['label'] as String,
      shortLabel: _shortLabel(row['label'] as String),
      hydrationFactor: (row['hydration_factor'] as num?)?.toDouble() ?? 1.0,
      caffeinePer100ml: (row['caffeine_per_100ml'] as num?)?.toDouble() ?? 0.0,
      icon: customDrinkIconAt(iconIndex),
      color: Color(colorValue),
      category: category,
      defaultContainerId: row['default_container'] as String?,
      isCustom: true,
      customId: (row['id'] as num?)?.toInt(),
    );
  }

  String _shortLabel(String label) {
    final List<String> words = label.split(' ');
    if (words.length == 1) {
      return label.length > 10 ? '${label.substring(0, 9)}…' : label;
    }
    return words.first.length > 9
        ? '${words.first.substring(0, 8)}…'
        : words.first;
  }

  Future<void> createCustom(DrinkType type) async {
    final Map<String, Object?> row = _toRow(type)
      ..remove('id')
      ..['created_at'] = DateTime.now().toIso8601String();
    await DatabaseHelper.instance.insertCustomDrink(row);
    await reload();
  }

  Future<void> updateCustom(DrinkType type) async {
    if (type.customId == null) {
      return;
    }
    await DatabaseHelper.instance.updateCustomDrink(
      type.customId!,
      _toRow(type)..remove('id'),
    );
    await reload();
  }

  Future<void> deleteCustom(DrinkType type) async {
    if (type.customId == null) {
      return;
    }
    await DatabaseHelper.instance.deleteCustomDrink(type.customId!);
    unregisterDrinkType(type.label);
    await reload();
  }

  Future<bool> labelExists(String label, {int? exceptId}) async {
    if (kDrinkTypes.any((DrinkType t) => t.label == label)) {
      return true;
    }
    return DatabaseHelper.instance.customDrinkLabelExists(
      label,
      exceptId: exceptId,
    );
  }

  Map<String, Object?> _toRow(DrinkType type) => <String, Object?>{
    'id': type.customId,
    'label': type.label,
    'hydration_factor': type.hydrationFactor,
    'caffeine_per_100ml': type.caffeinePer100ml,
    'icon_index': kCustomDrinkIcons.indexOf(type.icon),
    'color_value': type.color.toARGB32(),
    'category': type.category.name,
    'default_container': type.defaultContainerId,
  };
}
