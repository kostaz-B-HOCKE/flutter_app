import 'package:flutter/material.dart';

class FilteringWidget extends StatelessWidget {
  final VoidCallback onFilterPressed;
  final int? activeFiltersCount;

  const FilteringWidget({
    required this.onFilterPressed,
    this.activeFiltersCount,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.filter_list),
          onPressed: onFilterPressed,
          tooltip: 'Фильтры',
          color: Colors.white, // Белая иконка для контраста с зеленым AppBar
        ),
        if (activeFiltersCount != null && activeFiltersCount! > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Text(
                activeFiltersCount!.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// Альтернативная версия с более сложным виджетом
class AdvancedFilteringWidget extends StatelessWidget {
  final VoidCallback onFilterPressed;
  final int activeFiltersCount;
  final String filterSummary;

  const AdvancedFilteringWidget({
    required this.onFilterPressed,
    this.activeFiltersCount = 0,
    this.filterSummary = '',
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onFilterPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: activeFiltersCount > 0 ? Color(0xFF4CAF50).withOpacity(0.1) : null, // Светло-зеленый фон
          border: Border.all(
            color: activeFiltersCount > 0 ? Color(0xFF388E3C) : Colors.grey, // Темно-зеленая граница
            width: 1,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.filter_list,
              size: 18,
              color: activeFiltersCount > 0 ? Color(0xFF388E3C) : Colors.grey, // Темно-зеленая иконка
            ),
            const SizedBox(width: 4),
            if (activeFiltersCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Color(0xFF388E3C), // Темно-зеленый фон
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  activeFiltersCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            if (filterSummary.isNotEmpty) ...[
              const SizedBox(width: 8),
              Text(
                filterSummary,
                style: TextStyle(
                  fontSize: 12,
                  color: activeFiltersCount > 0 ? Color(0xFF388E3C) : Colors.grey, // Темно-зеленый текст
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Простая версия только с иконкой
class SimpleFilterIcon extends StatelessWidget {
  final VoidCallback onFilterPressed;
  final bool hasActiveFilters;

  const SimpleFilterIcon({
    required this.onFilterPressed,
    this.hasActiveFilters = false,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        Icons.filter_list,
        color: hasActiveFilters ? Color(0xFF388E3C) : Colors.white, // Темно-зеленая или белая иконка
      ),
      onPressed: onFilterPressed,
      tooltip: 'Фильтры',
    );
  }
}