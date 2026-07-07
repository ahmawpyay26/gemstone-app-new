import 'package:flutter/material.dart';

/// Custom dropdown picker that works properly inside bottom sheets
/// Replaces DropdownButton to avoid grey overlay and stuck screen issues
class BottomSheetDropdown<T> extends StatelessWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final Color? dropdownColor;
  final TextStyle? style;
  final Color borderColor;
  final Color backgroundColor;

  const BottomSheetDropdown({
    Key? key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.dropdownColor,
    this.style,
    this.borderColor = const Color(0xFFD4AF37),
    this.backgroundColor = const Color(0xFF1A1A1A),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPickerBottomSheet(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                _getDisplayText(),
                style: style ?? const TextStyle(color: Colors.white),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_drop_down,
              color: borderColor.withOpacity(0.7),
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  String _getDisplayText() {
    if (value == null) {
      return hint;
    }
    final selectedItem = items.firstWhere(
      (item) => item.value == value,
      orElse: () => DropdownMenuItem(
        value: value,
        child: Text(hint),
      ),
    );
    if (selectedItem.child is Text) {
      return (selectedItem.child as Text).data ?? hint;
    }
    return hint;
  }

  void _showPickerBottomSheet(BuildContext context) async {
    final selectedValue = await showModalBottomSheet<T?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (BuildContext context, ScrollController scrollController) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  // Drag handle
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 16),
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[700],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      hint,
                      style: const TextStyle(
                        color: Color(0xFFD4AF37),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Divider(color: Colors.grey, height: 1),
                  // Items list
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: items.length,
                      itemBuilder: (BuildContext context, int index) {
                        final item = items[index];
                        final isSelected = item.value == value;
                        return ListTile(
                          title: item.child,
                          selected: isSelected,
                          selectedTileColor: const Color(0xFFD4AF37).withOpacity(0.1),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: Color(0xFFD4AF37),
                                )
                              : null,
                          onTap: () => Navigator.pop(context, item.value),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    
    // Only call onChanged after the bottom sheet has fully closed
    if (selectedValue != null) {
      onChanged(selectedValue);
    }
  }
}
