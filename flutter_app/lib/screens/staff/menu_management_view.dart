import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../theme/app_theme.dart';
import '../../widgets/glass_card.dart';
import '../../widgets/category_pills.dart';
import '../../widgets/food_card.dart';
import '../../state/menu_state.dart';
import '../../state/app_state.dart';
import '../../models/menu_item.dart';

class MenuManagementView extends StatefulWidget {
  const MenuManagementView({super.key});

  @override
  State<MenuManagementView> createState() => _MenuManagementViewState();
}

class _MenuManagementViewState extends State<MenuManagementView> {
  String _query = '';
  String _category = 'All';

  @override
  Widget build(BuildContext context) {
    final menuState = context.watch<MenuState>();
    final items = menuState.items.where((i) {
      final matchesQuery =
          _query.isEmpty || i.name.toLowerCase().contains(_query.toLowerCase());
      final matchesCategory = _category == 'All' || i.category == _category;
      return matchesQuery && matchesCategory;
    }).toList();

    final available = menuState.items.where((i) => i.available).length;
    final outOfStock = menuState.items.length - available;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth > 1000;
        final catalog = _catalog(items);
        final stats =
            _statsPanel(menuState.items.length, available, outOfStock);

        return wide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 3, child: catalog),
                  const SizedBox(width: 20),
                  SizedBox(width: 280, child: stats),
                ],
              )
            : Column(
                children: [
                  stats,
                  const SizedBox(height: 16),
                  Expanded(child: catalog),
                ],
              );
      }),
    );
  }

  Widget _catalog(List<MenuItem> items) {
    final menuState = context.read<MenuState>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: PillSearchBar(
                    onChanged: (v) => setState(() => _query = v))),
          ],
        ),
        const SizedBox(height: 14),
        CategoryPillBar(
          categories: menuState.categories,
          selected: _category,
          onSelected: (c) => setState(() => _category = c),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: items.isEmpty
              ? const Center(
                  child: Text('No items match',
                      style: TextStyle(color: AppColors.textMuted)))
              : GridView.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 380,
                    mainAxisExtent: 320,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) =>
                      _StaffMenuCard(item: items[i], index: i),
                ),
        ),
      ],
    );
  }

  Widget _statsPanel(int total, int available, int outOfStock) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('MENU OVERVIEW', style: AppTheme.uppercaseLabel),
          const SizedBox(height: 16),
          _statRow('Total Items', '$total', AppColors.textPrimary),
          _statRow('Available', '$available', AppColors.green),
          _statRow('Out of Stock', '$outOfStock', AppColors.red),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => showDialog(
                  context: context, builder: (_) => const _MenuEditDialog()),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('ADD FOOD'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statRow(String label, String value, Color color) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
            Text(value,
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
      );
}

// Corner tags cycle for visual variety, purely cosmetic — matches the
// "Bestseller / Chef Special / Quick Bite / Popular" styling from the
// reference without needing a dedicated backend field.
const _cornerTags = ['Bestseller', 'Chef Special', 'Quick Bite', 'Popular'];

class _StaffMenuCard extends StatelessWidget {
  final MenuItem item;
  final int index;
  const _StaffMenuCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    final menuState = context.read<MenuState>();
    return StaffFoodCard(
      item: item,
      cornerTag: _cornerTags[index % _cornerTags.length],
      actionsRow: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => showDialog(
                  context: context,
                  builder: (_) => _MenuEditDialog(existing: item)),
              icon: const Icon(Icons.edit_rounded, size: 14),
              label: const Text('EDIT', style: TextStyle(fontSize: 12)),
              style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10)),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => context
                .read<AppState>()
                .api
                .deleteMenuItem(item.id)
                .catchError((_) {}),
            borderRadius: BorderRadius.circular(100),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  size: 15, color: AppColors.red),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: (item.available ? AppColors.green : AppColors.red)
                  .withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(item.available ? 'ON' : 'OFF',
                    style: TextStyle(
                        color: item.available ? AppColors.green : AppColors.red,
                        fontSize: 10,
                        fontWeight: FontWeight.w800)),
                Switch(
                  value: item.available,
                  onChanged: (_) => menuState.toggleAvailability(item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuEditDialog extends StatefulWidget {
  final MenuItem? existing;
  const _MenuEditDialog({this.existing});

  @override
  State<_MenuEditDialog> createState() => _MenuEditDialogState();
}

class _MenuEditDialogState extends State<_MenuEditDialog> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _price = TextEditingController(
      text: widget.existing?.price.toStringAsFixed(0) ?? '');
  late final _category =
      TextEditingController(text: widget.existing?.category ?? 'Main');
  late final _description =
      TextEditingController(text: widget.existing?.description ?? '');
  late final _prepMinutes = TextEditingController(
      text: widget.existing?.prepMinutes.toString() ?? '10');

  String? _imageUrl; // existing URL, or a freshly-uploaded one
  Uint8List? _pickedBytes; // shown as a local preview while uploading
  bool _uploading = false;
  String? _uploadError;

  @override
  void initState() {
    super.initState();
    _imageUrl = widget.existing?.imageUrl;
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1200);
    if (picked == null) return;

    final bytes = await picked.readAsBytes();
    setState(() {
      _pickedBytes = bytes;
      _uploading = true;
      _uploadError = null;
    });

    try {
      final appState = context.read<AppState>();
      if (!appState.firebaseAvailable) {
        throw Exception(
            'Firebase Storage needs Firebase configured first — see FIREBASE_SETUP.md.');
      }
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final url = await appState.storage
          .uploadMenuImage(bytes: bytes, fileName: fileName);
      setState(() {
        _imageUrl = url;
        _uploading = false;
      });
    } catch (e) {
      setState(() {
        _uploading = false;
        _uploadError = 'Upload failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    widget.existing == null
                        ? 'Add Food Item'
                        : 'Edit Food Item',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 18),

                // --- Image: pick from gallery, upload to Firebase Storage ---
                GestureDetector(
                  onTap: _uploading ? null : _pickAndUploadImage,
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildImagePreview(),
                  ),
                ),
                if (_uploadError != null) ...[
                  const SizedBox(height: 6),
                  Text(_uploadError!,
                      style:
                          const TextStyle(color: AppColors.red, fontSize: 11)),
                ],
                const SizedBox(height: 16),

                TextField(
                    controller: _name,
                    decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 12),
                TextField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price (₹)')),
                const SizedBox(height: 12),
                TextField(
                    controller: _category,
                    decoration: const InputDecoration(labelText: 'Category')),
                const SizedBox(height: 12),
                TextField(
                    controller: _description,
                    decoration:
                        const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 12),
                TextField(
                    controller: _prepMinutes,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Prep time (minutes)')),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('CANCEL')),
                    const SizedBox(width: 8),
                    ElevatedButton(
                        onPressed: _uploading ? null : _save,
                        child: const Text('SAVE')),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_uploading) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(height: 8),
            Text('Uploading...',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      );
    }
    if (_pickedBytes != null) {
      return Image.memory(_pickedBytes!,
          fit: BoxFit.cover, width: double.infinity);
    }
    if (_imageUrl != null && _imageUrl!.isNotEmpty) {
      return Image.network(_imageUrl!,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (_, __, ___) => _placeholder());
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add_photo_alternate_outlined,
              color: AppColors.textMuted, size: 32),
          SizedBox(height: 8),
          Text('Tap to choose from gallery',
              style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ],
      ),
    );
  }

  void _save() {
    final appState = context.read<AppState>();
    final payload = {
      'name': _name.text.trim(),
      'price': double.tryParse(_price.text.trim()) ?? 0,
      'category':
          _category.text.trim().isEmpty ? 'Main' : _category.text.trim(),
      'description': _description.text.trim(),
      'prepMinutes': int.tryParse(_prepMinutes.text.trim()) ?? 10,
      'imageUrl': _imageUrl,
    };
    if (widget.existing == null) {
      appState.api.addMenuItem(payload).catchError((_) {});
    } else {
      appState.api
          .updateMenuItem(widget.existing!.id, payload)
          .catchError((_) {});
    }
    Navigator.of(context).pop();
  }
}
