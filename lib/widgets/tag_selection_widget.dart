import 'package:flutter/material.dart';

class TagSelectionWidget extends StatefulWidget {
  final List<String> availableTags;
  final List<String> selectedTags;
  final Function(List<String>) onTagsChanged;
  final String hintText;
  final IconData icon;

  const TagSelectionWidget({
    Key? key,
    required this.availableTags,
    required this.selectedTags,
    required this.onTagsChanged,
    required this.hintText,
    required this.icon,
  }) : super(key: key);

  @override
  _TagSelectionWidgetState createState() => _TagSelectionWidgetState();
}

class _TagSelectionWidgetState extends State<TagSelectionWidget> {
  void _showMultiSelect() async {
    final List<String>? results = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return MultiSelectDialog(
          availableTags: widget.availableTags,
          selectedTags: widget.selectedTags,
        );
      },
    );

    if (results != null) {
      widget.onTagsChanged(results);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.hintText,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showMultiSelect,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(widget.icon, color: Colors.pinkAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: widget.selectedTags.isEmpty
                      ? Text(
                          widget.hintText,
                          style: TextStyle(color: Colors.grey[600]),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: widget.selectedTags.map((tag) {
                            return Chip(
                              label: Text(tag),
                              backgroundColor: Colors.pinkAccent.withOpacity(0.2),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                setState(() {
                                  widget.selectedTags.remove(tag);
                                  widget.onTagsChanged([...widget.selectedTags]);
                                });
                              },
                            );
                          }).toList(),
                        ),
                ),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class MultiSelectDialog extends StatefulWidget {
  final List<String> availableTags;
  final List<String> selectedTags;

  const MultiSelectDialog({
    Key? key,
    required this.availableTags,
    required this.selectedTags,
  }) : super(key: key);

  @override
  _MultiSelectDialogState createState() => _MultiSelectDialogState();
}

class _MultiSelectDialogState extends State<MultiSelectDialog> {
  List<String> _tempSelectedTags = [];

  @override
  void initState() {
    super.initState();
    _tempSelectedTags = List.from(widget.selectedTags);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Выберите теги'),
      content: Container(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: widget.availableTags.length,
          itemBuilder: (BuildContext context, int index) {
            final tag = widget.availableTags[index];
            return CheckboxListTile(
              title: Text(tag),
              value: _tempSelectedTags.contains(tag),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _tempSelectedTags.add(tag);
                  } else {
                    _tempSelectedTags.remove(tag);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _tempSelectedTags),
          child: Text('Готово'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pinkAccent,
          ),
        ),
      ],
    );
  }
}