import 'dart:io';
import 'package:flutter/material.dart';
import '../models/listing.dart';
import '../services/listings_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/listing/image_picker_grid.dart';
import '../widgets/listing/meeting_point_picker.dart';

/// Post Item form — opens as full screen.
/// - Save as Draft → state='draft'
/// - Confirm → state='draft' then publish
class PostItemScreen extends StatefulWidget {
  /// Pass an existing listing to edit. Null = create new.
  final Listing? existing;

  const PostItemScreen({super.key, this.existing});

  @override
  State<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends State<PostItemScreen> {
  // Services
  final _listingsService = ListingsService();
  final _storageService = StorageService();

  // Form state
  final _titleCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _swapForCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  ListingCategory? _category;
  ListingCondition _condition = ListingCondition.newItem;
  bool _openToSwap = false;
  MeetingPoint? _meetingPoint;

  List<File> _newFiles = [];
  List<String> _existingUrls = [];

  bool _saving = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) _populateFromExisting();
  }

  void _populateFromExisting() {
    final l = widget.existing!;
    _titleCtrl.text = l.title;
    _priceCtrl.text = l.price?.toInt().toString() ?? '';
    _swapForCtrl.text = l.swapPreference ?? '';
    _descriptionCtrl.text = l.description ?? '';
    _category = l.category;
    _condition = l.condition ?? ListingCondition.newItem;
    _openToSwap = l.type == ListingType.trade || l.type == ListingType.both;
    _meetingPoint = l.meetingPoint;
    _existingUrls = [...l.images];
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _swapForCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  // ============================================================
  // Compute derived listing type
  // ============================================================

  ListingType? _computeType() {
    final hasPrice = _priceCtrl.text.trim().isNotEmpty;
    if (hasPrice && _openToSwap) return ListingType.both;
    if (hasPrice) return ListingType.sell;
    if (_openToSwap) return ListingType.trade;
    return null;
  }

  num? _parsePrice() {
    final text = _priceCtrl.text.trim();
    if (text.isEmpty) return null;
    return num.tryParse(text);
  }

  // ============================================================
  // Save / Publish
  // ============================================================

  Future<void> _save({required bool publish}) async {
    if (_titleCtrl.text.trim().isEmpty) {
      _showError('Please enter a product title');
      return;
    }

    if (publish) {
      // Strict validation for publish
      if (_existingUrls.isEmpty && _newFiles.isEmpty) {
        _showError('Please add at least 1 image');
        return;
      }
      if (_descriptionCtrl.text.trim().length < 10) {
        _showError('Description must be at least 10 characters');
        return;
      }
      if (_category == null) {
        _showError('Please select a category');
        return;
      }
      final type = _computeType();
      if (type == null) {
        _showError('Either set a price or enable Open to Swap');
        return;
      }
      if (_meetingPoint == null) {
        _showError('Please select a meeting point');
        return;
      }
      if (_openToSwap && _swapForCtrl.text.trim().isEmpty) {
        _showError('Please specify what you want to swap for');
        return;
      }
    }

    setState(() => _saving = true);

    try {
      Listing listing;
      final targetState = publish ? 'published' : 'draft';

      // Step 1: Create or update the listing fields (excluding state)
      if (_isEdit) {
        listing = widget.existing!;
        await _listingsService.update(
          listing.id,
          title: _titleCtrl.text.trim(),
          description: _descriptionCtrl.text.trim().isEmpty
              ? null
              : _descriptionCtrl.text.trim(),
          category: _category,
          type: _computeType(),
          price: _parsePrice(),
          swapPreference: _swapForCtrl.text.trim().isEmpty
              ? null
              : _swapForCtrl.text.trim(),
          condition: _condition,
          meetingPoint: _meetingPoint,
        );
      } else {
        listing = await _listingsService.createDraft(
          title: _titleCtrl.text.trim(),
          description: _descriptionCtrl.text.trim().isEmpty
              ? null
              : _descriptionCtrl.text.trim(),
          category: _category,
          type: _computeType(),
          price: _parsePrice(),
          swapPreference: _swapForCtrl.text.trim().isEmpty
              ? null
              : _swapForCtrl.text.trim(),
          condition: _condition,
          meetingPoint: _meetingPoint,
        );
      }

      // Step 2: Upload new images (if any)
      List<String> finalImages = [..._existingUrls];
      if (_newFiles.isNotEmpty) {
        final uploaded = await _storageService.uploadListingImages(
          listingId: listing.id,
          files: _newFiles,
        );
        finalImages = [...finalImages, ...uploaded];

        // Update listing with full image list
        await _listingsService.update(listing.id, images: finalImages);
      } else if (_isEdit && _existingUrls.length != widget.existing!.images.length) {
        // Existing images were removed
        await _listingsService.update(listing.id, images: finalImages);
      }

      // Step 3: Transition State via the new dedicated endpoint
      await _listingsService.updateState(listing.id, targetState);

      if (!mounted) return;
      _showSuccess(publish ? 'Item published!' : 'Saved as draft');
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade400,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.orange,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: _saving ? null : () => Navigator.pop(context),
        ),
        title: Text(
          _isEdit ? 'Edit Item' : 'Post new Item',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: AbsorbPointer(
        absorbing: _saving,
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Upload Photo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _label('Upload Photo'),
                    Text(
                      'Upload up to 10 photos',
                      style: const TextStyle(
                        color: AppColors.textGray,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ImagePickerGrid(
                  existingUrls: _existingUrls,
                  newFiles: _newFiles,
                  onFilesChanged: (files) =>
                      setState(() => _newFiles = files),
                  onExistingChanged: (urls) =>
                      setState(() => _existingUrls = urls),
                ),
                const SizedBox(height: 22),

                _label('Product Title'),
                const SizedBox(height: 6),
                _input('Enter item name, e.g. Calculus 1 Book', _titleCtrl),
                const SizedBox(height: 16),

                _label('Category'),
                const SizedBox(height: 6),
                _categoryDropdown(),
                const SizedBox(height: 16),

                _label('Condition'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _conditionBtn(ListingCondition.newItem),
                    const SizedBox(width: 8),
                    _conditionBtn(ListingCondition.likeNew),
                    const SizedBox(width: 8),
                    _conditionBtn(ListingCondition.used),
                  ],
                ),
                const SizedBox(height: 16),

                _label('Price'),
                const SizedBox(height: 6),
                _input(
                  '฿',
                  _priceCtrl,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 18),

                _buildOpenToSwap(),
                const SizedBox(height: 16),

                if (_openToSwap) ...[
                  _label('Want to Swap For'),
                  const SizedBox(height: 6),
                  _input(
                    'Enter desired item e.g. dorm accessories',
                    _swapForCtrl,
                    suffixIcon: Icons.list_alt,
                  ),
                  const SizedBox(height: 16),
                ],

                _label('Description'),
                const SizedBox(height: 6),
                _input(
                  'provide detail information about item ...',
                  _descriptionCtrl,
                  maxLines: 4,
                ),
                const SizedBox(height: 16),

                _label('Meeting Point'),
                const SizedBox(height: 6),
                MeetingPointPicker(
                  selected: _meetingPoint,
                  onChanged: (p) => setState(() => _meetingPoint = p),
                ),
                const SizedBox(height: 32),

                _buildActionButtons(),
                const SizedBox(height: 24),
              ],
            ),

            // Loading overlay
            if (_saving)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.orange,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // UI helpers
  // ============================================================

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
          color: AppColors.navy,
        ),
      );

  Widget _input(
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
    TextInputType? keyboardType,
    IconData? suffixIcon,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, color: AppColors.navy),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textGray.withOpacity(0.7),
          fontSize: 13,
        ),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon, color: AppColors.textGray, size: 20)
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: _inputBorder(),
        enabledBorder: _inputBorder(),
        focusedBorder: _inputBorder(color: AppColors.orange, width: 1.5),
      ),
    );
  }

  OutlineInputBorder _inputBorder({Color? color, double width = 1}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(24),
      borderSide: BorderSide(
        color: color ?? AppColors.textGray.withOpacity(0.5),
        width: width,
      ),
    );
  }

  Widget _categoryDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.textGray.withOpacity(0.5)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<ListingCategory>(
          isExpanded: true,
          value: _category,
          hint: Text(
            'Select Category',
            style: TextStyle(
              color: AppColors.textGray.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.navy),
          style: const TextStyle(fontSize: 14, color: AppColors.navy),
          items: ListingCategory.values
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c.displayName),
                  ))
              .toList(),
          onChanged: (v) => setState(() => _category = v),
        ),
      ),
    );
  }

  Widget _conditionBtn(ListingCondition cond) {
    final isActive = _condition == cond;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _condition = cond),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isActive ? AppColors.navy : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.navy, width: 1.2),
          ),
          child: Center(
            child: Text(
              cond.displayName,
              style: TextStyle(
                color: isActive ? Colors.white : AppColors.navy,
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOpenToSwap() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Open to Swap',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.navy,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'Enable if you looking for trade',
                style: TextStyle(color: AppColors.textGray, fontSize: 12),
              ),
            ],
          ),
        ),
        Switch(
          value: _openToSwap,
          onChanged: (v) => setState(() => _openToSwap = v),
          activeColor: Colors.white,
          activeTrackColor: AppColors.orange,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: AppColors.textGray.withOpacity(0.4),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: () => _save(publish: false),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.navy,
                backgroundColor: Colors.white,
                side: const BorderSide(color: AppColors.navy, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Save as Draft',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: () => _save(publish: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.orange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
