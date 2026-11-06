import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/drink_repository.dart';
import '../theme/app_theme.dart';
import 'drink_editor_screen.dart';

/// Tüm içecek kataloğu: arama, kategori filtresi ve özel içecek yönetimi.
class DrinkLibraryScreen extends StatefulWidget {
  const DrinkLibraryScreen({super.key, this.pickMode = true});

  /// `true` ise bir içeceğe dokunulduğunda seçip kapatır.
  /// `false` ise yalnızca katalog yönetimi (Ayarlar'dan açılır).
  final bool pickMode;

  @override
  State<DrinkLibraryScreen> createState() => _DrinkLibraryScreenState();
}

class _DrinkLibraryScreenState extends State<DrinkLibraryScreen> {
  final TextEditingController _search = TextEditingController();
  DrinkCategory? _category;
  String _query = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await DrinkRepository.instance.reload();
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
  }

  List<DrinkType> get _filtered {
    final String query = normalizeForSearch(_query.trim());
    return DrinkRepository.instance.all.where((DrinkType type) {
      if (_category != null && type.category != _category) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }
      return normalizeForSearch(type.label).contains(query);
    }).toList();
  }

  Future<void> _openEditor([DrinkType? drink]) async {
    final bool? changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (BuildContext context) => DrinkEditorScreen(drink: drink),
      ),
    );
    if (changed == true) {
      await _load();
    }
  }

  Future<void> _confirmDelete(DrinkType drink) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('İçeceği sil'),
        content: Text(
          '"${drink.label}" katalogdan kaldırılacak. Geçmiş kayıtların '
          'silinmez, eski tüketimlerin korunur.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await DrinkRepository.instance.deleteCustom(drink);
    await _load();
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${drink.label} kaldırıldı')));
  }

  @override
  Widget build(BuildContext context) {
    final List<DrinkType> drinks = _filtered;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.pickMode ? 'İçecek Seç' : 'İçecek Kütüphanesi'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Yeni içecek ekle',
            onPressed: () => _openEditor(),
            icon: const Icon(Icons.add_circle_outline_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
                  child: TextField(
                    controller: _search,
                    onChanged: (String value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'İçecek ara (kahve, ayran...)',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 4),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    children: <Widget>[
                      _CategoryChip(
                        label: 'Tümü',
                        selected: _category == null,
                        onTap: () => setState(() => _category = null),
                      ),
                      for (final DrinkCategory category in kDrinkCategories)
                        _CategoryChip(
                          label: category.label,
                          selected: _category == category,
                          onTap: () => setState(() => _category = category),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: drinks.isEmpty
                      ? _buildEmpty()
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                          physics: const BouncingScrollPhysics(),
                          itemCount: drinks.length,
                          separatorBuilder: (_, _) =>
                              const SizedBox(height: 10),
                          itemBuilder: (BuildContext context, int index) {
                            return _DrinkRow(
                              drink: drinks[index],
                              onTap: () {
                                if (widget.pickMode) {
                                  Navigator.of(context).pop(drinks[index]);
                                } else if (drinks[index].isCustom) {
                                  _openEditor(drinks[index]);
                                }
                              },
                              onEdit: drinks[index].isCustom
                                  ? () => _openEditor(drinks[index])
                                  : null,
                              onDelete: drinks[index].isCustom
                                  ? () => _confirmDelete(drinks[index])
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Özel İçecek',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              Icons.search_off_rounded,
              size: 42,
              color: AppColors.subtitle,
            ),
            const SizedBox(height: 12),
            const Text(
              'Aradığın içecek katalogda yok.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.heading,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Kendi içeceğini ekleyerek hidrasyon ve kafein değerlerini '
              'sen belirleyebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: AppColors.subtitle,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _openEditor(),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Özel içecek ekle'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : const Color(0xFFE3ECF7),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.subtitle,
            ),
          ),
        ),
      ),
    );
  }
}

class _DrinkRow extends StatelessWidget {
  const _DrinkRow({
    required this.drink,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final DrinkType drink;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: drink.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(drink.icon, color: drink.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            drink.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.heading,
                            ),
                          ),
                        ),
                        if (drink.isCustom) ...<Widget>[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Özel',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${drink.category.label} · Hidrasyon ${drink.factorLabel}'
                      '${drink.hasCaffeine ? ' · ${drink.caffeinePer100ml.round()} mg/100 ml kafein' : ' · kafeinsiz'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.subtitle,
                      ),
                    ),
                  ],
                ),
              ),
              if (onEdit != null)
                IconButton(
                  onPressed: onEdit,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.edit_outlined, size: 19),
                  color: AppColors.subtitle,
                ),
              if (onDelete != null)
                IconButton(
                  onPressed: onDelete,
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.delete_outline_rounded, size: 19),
                  color: const Color(0xFFE11D48),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
