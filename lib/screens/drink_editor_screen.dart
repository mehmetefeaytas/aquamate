import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/drink_repository.dart';
import '../theme/app_theme.dart';

/// Kullanıcı tanımlı içecek ekleme / düzenleme ekranı.
class DrinkEditorScreen extends StatefulWidget {
  const DrinkEditorScreen({super.key, this.drink});

  /// `null` ise yeni içecek oluşturulur.
  final DrinkType? drink;

  @override
  State<DrinkEditorScreen> createState() => _DrinkEditorScreenState();
}

class _DrinkEditorScreenState extends State<DrinkEditorScreen> {
  static const List<Color> _palette = <Color>[
    Color(0xFF2F80ED),
    Color(0xFF1B64D0),
    Color(0xFF56CCF2),
    Color(0xFF10B981),
    Color(0xFF84CC16),
    Color(0xFFF5B942),
    Color(0xFFFF9F43),
    Color(0xFFE11D48),
    Color(0xFF8B5E34),
    Color(0xFFA78BFA),
    Color(0xFF0EA5E9),
    Color(0xFF64748B),
  ];

  late final TextEditingController _name;
  late double _hydration;
  late double _caffeine;
  late int _iconIndex;
  late Color _color;
  late DrinkCategory _category;
  String? _containerId;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.drink != null;

  @override
  void initState() {
    super.initState();
    final DrinkType? drink = widget.drink;
    _name = TextEditingController(text: drink?.label ?? '');
    _hydration = drink?.hydrationFactor ?? 1.0;
    _caffeine = drink?.caffeinePer100ml ?? 0;
    _iconIndex = drink == null ? 0 : kCustomDrinkIcons.indexOf(drink.icon);
    if (_iconIndex < 0) {
      _iconIndex = 0;
    }
    _color = drink?.color ?? AppColors.primary;
    _category = drink?.category ?? DrinkCategory.other;
    _containerId = drink?.defaultContainerId;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final String label = _name.text.trim();
    if (label.isEmpty) {
      setState(() => _error = 'İçecek adı boş olamaz.');
      return;
    }
    if (label.length > 30) {
      setState(() => _error = 'İçecek adı en fazla 30 karakter olabilir.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final int? exceptId = widget.drink?.customId;
    final bool exists = await DrinkRepository.instance.labelExists(
      label,
      exceptId: exceptId,
    );
    if (exists) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = 'Bu isimde bir içecek zaten var. Farklı bir ad dene.';
      });
      return;
    }

    final DrinkType type = DrinkType(
      label: label,
      shortLabel: label,
      hydrationFactor: _hydration,
      caffeinePer100ml: _caffeine,
      icon: kCustomDrinkIcons[_iconIndex],
      color: _color,
      category: _category,
      defaultContainerId: _containerId,
      isCustom: true,
      customId: widget.drink?.customId,
    );

    try {
      if (_isEditing) {
        await DrinkRepository.instance.updateCustom(type);
      } else {
        await DrinkRepository.instance.createCustom(type);
      }
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = 'Kaydedilemedi. Lütfen tekrar dene.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'İçeceği Düzenle' : 'Yeni İçecek'),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _buildPreview(),
            const SizedBox(height: 18),
            Text('İçecek Adı', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            TextField(
              controller: _name,
              maxLength: 30,
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) {
                setState(() {
                  if (_error != null) {
                    _error = null;
                  }
                });
              },
              decoration: InputDecoration(
                hintText: 'Örn. Ev yapımı naneli limonata',
                filled: true,
                fillColor: Colors.white,
                counterText: '',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildSlider(
              title: 'Hidrasyon katsayısı',
              value: _hydration,
              min: 0.2,
              max: 1.2,
              divisions: 20,
              label: '%${(_hydration * 100).round()}',
              helper:
                  'Su = %100. 250 ml içecek net ${(250 * _hydration).round()} ml sayılır.',
              onChanged: (double v) => setState(() => _hydration = v),
            ),
            const SizedBox(height: 14),
            _buildSlider(
              title: 'Kafein (100 ml başına)',
              value: _caffeine,
              min: 0,
              max: 250,
              divisions: 50,
              label: '${_caffeine.round()} mg',
              helper: _caffeine <= 0
                  ? 'Kafeinsiz içecek.'
                  : '250 ml içecek ${(_caffeine * 2.5).round()} mg kafein içerir.',
              onChanged: (double v) => setState(() => _caffeine = v),
            ),
            const SizedBox(height: 18),
            Text('Simge', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                for (int i = 0; i < kCustomDrinkIcons.length; i++)
                  GestureDetector(
                    onTap: () => setState(() => _iconIndex = i),
                    child: Container(
                      width: 46,
                      height: 46,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _iconIndex == i
                            ? _color.withValues(alpha: 0.16)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _iconIndex == i
                              ? _color
                              : const Color(0xFFE3ECF7),
                          width: _iconIndex == i ? 1.8 : 1.1,
                        ),
                      ),
                      child: Icon(
                        kCustomDrinkIcons[i],
                        size: 22,
                        color: _iconIndex == i ? _color : AppColors.subtitle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Renk', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: <Widget>[
                for (final Color color in _palette)
                  GestureDetector(
                    onTap: () => setState(() => _color = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _color == color
                              ? AppColors.heading
                              : Colors.transparent,
                          width: 2.4,
                        ),
                      ),
                      child: _color == color
                          ? const Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: Colors.white,
                            )
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Kategori', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                for (final DrinkCategory category in kDrinkCategories)
                  ChoiceChip(
                    label: Text(category.label),
                    selected: _category == category,
                    onSelected: (_) => setState(() => _category = category),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _category == category
                          ? Colors.white
                          : AppColors.subtitle,
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFFE3ECF7)),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Varsayılan kap',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: _containerId,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              items: <DropdownMenuItem<String?>>[
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Sorma, her zaman seçeyim'),
                ),
                for (final ContainerType container in kContainerTypes)
                  DropdownMenuItem<String?>(
                    value: container.id,
                    child: Text(container.label),
                  ),
              ],
              onChanged: (String? value) =>
                  setState(() => _containerId = value),
            ),
            if (_error != null) ...<Widget>[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE7EA),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE11D48),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: TextButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _isEditing ? 'Değişiklikleri Kaydet' : 'İçeceği Ekle',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Hidrasyon ve kafein değerleri tahminidir; tıbbi tavsiye yerine '
              'geçmez. Emin değilsen varsayılan değerleri kullanabilirsin.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.subtitle,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 54,
            height: 54,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(kCustomDrinkIcons[_iconIndex], color: _color, size: 26),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _name.text.trim().isEmpty ? 'Yeni içecek' : _name.text.trim(),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  'Hidrasyon %${(_hydration * 100).round()} · '
                  '${_caffeine.round()} mg/100 ml kafein',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlider({
    required String title,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String label,
    required String helper,
    required ValueChanged<double> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.heading,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            divisions: divisions,
            label: label,
            onChanged: onChanged,
          ),
          Text(
            helper,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.subtitle,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
