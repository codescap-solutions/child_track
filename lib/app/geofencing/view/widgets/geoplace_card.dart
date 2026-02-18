import 'package:flutter/material.dart';

import 'toggle_switch.dart';

class GeoPlaceCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isPrimary;
  final bool toggleValue;
  final String? geofenceId;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggle;
  final VoidCallback? onDelete;

  const GeoPlaceCard({
    super.key,
    required this.title,
    this.subtitle,
    this.toggleValue = false,
    this.isPrimary = false,
    this.geofenceId,
    this.onTap,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isAddCard = title.contains('Add');

    return GestureDetector(
      onTap: onTap ?? (isAddCard ? _defaultNavigate : null),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8.04),
              height: 50,
              width: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isPrimary
                    ? const Color(0xFF0C5391)
                    : const Color(0xFF666363),
              ),
              child: Container(
                decoration: isPrimary && !isAddCard
                    ? null
                    : BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2.5),
                      ),
                child: Icon(
                  isPrimary && !isAddCard ? getIconByName(title) : Icons.add,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        subtitle!,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Color(0xFF0070F0),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (!isAddCard) ...[
              PopupMenuButton(
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text('Delete', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'delete' && onDelete != null) {
                    onDelete!();
                  }
                },
              ),
              CustomToggleSwitch(
                value: toggleValue,
                onChanged: onToggle ?? (value) {},
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _defaultNavigate() {
    // This won't be called if onTap is provided
  }
}

IconData getIconByName(String name) {
  switch (name.toLowerCase()) {
    case 'home':
      return Icons.home;
    case 'school':
      return Icons.school;
    case 'office':
      return Icons.business;
    case 'hospital':
      return Icons.local_hospital;
    case 'park':
      return Icons.park;
    case 'shop':
      return Icons.store;
    case 'gym':
      return Icons.fitness_center;
    case 'mosque':
      return Icons.mosque;
    case 'church':
      return Icons.church;
    default:
      return Icons.location_on; // default fallback
  }
}
