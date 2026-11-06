import 'package:aquamate/models/models.dart';

/// Testlerde kullanılan hızlı [WaterLog] kurucusu.
WaterLog buildLog({
  required String drink,
  required int ml,
  String? containerId,
  bool recycled = false,
  DateTime? at,
  int? id,
}) {
  final DrinkType type = drinkTypeOf(drink);
  return WaterLog(
    id: id,
    drinkType: type.label,
    rawAmount: ml,
    effectiveAmount: type.effectiveOf(ml),
    caffeineMg: type.caffeineOf(ml),
    containerId: containerId,
    recycled: recycled,
    createdAt: at ?? DateTime(2026, 11, 6, 9),
  );
}
