import 'package:flutter/material.dart';

/// Inline selector that expands/collapses without using nested modals
/// Replaces BottomSheetDropdown for use inside bottom sheets
class InlineSelector<T> extends StatefulWidget {
  final T? value;
  final String hint;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final TextStyle? style;
  final Color borderColor;
  final Color backgroundColor;

  const InlineSelector({
    Key? key,
    required this.value,
    required this.hint,
    required this.items,
    required this.onChanged,
    this.style,
    this.borderColor = const Color(0xFFD4AF37),
    this.backgroundColor = const Color(0xFF1A1A1A),
  }) : super(key: key);

  @override
  State<InlineSelector<T>> createState() => _InlineSelectorState<T>();
}

class _InlineSelectorState<T> extends State<InlineSelector<T>> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Selector button
        GestureDetector(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: widget.borderColor.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    _getDisplayText(),
                    style: widget.style ?? const TextStyle(color: Colors.white),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _isExpanded ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                  color: widget.borderColor.withOpacity(0.7),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
        // Expanded list
        if (_isExpanded)
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
              border: Border(
                left: BorderSide(
                  color: widget.borderColor.withOpacity(0.3),
                  width: 1,
                ),
                right: BorderSide(
                  color: widget.borderColor.withOpacity(0.3),
                  width: 1,
                ),
                bottom: BorderSide(
                  color: widget.borderColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
            ),
            constraints: const BoxConstraints(maxHeight: 300),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: widget.items.length,
              itemBuilder: (BuildContext context, int index) {
                final item = widget.items[index];
                final isSelected = item.value == widget.value;
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
                  onTap: () {
                    widget.onChanged(item.value);
                    setState(() {
                      _isExpanded = false;
                    });
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  String _getDisplayText() {
    if (widget.value == null) {
      return widget.hint;
    }
    final selectedItem = widget.items.firstWhere(
      (item) => item.value == widget.value,
      orElse: () => DropdownMenuItem(
        value: widget.value,
        child: Text(widget.hint),
      ),
    );
    if (selectedItem.child is Text) {
      return (selectedItem.child as Text).data ?? widget.hint;
    }
    return widget.hint;
  }
}
