import 'package:flutter/material.dart';
import '../../models/activity.dart';

class ActivityItem extends StatelessWidget {
  final Activity activity;

  const ActivityItem({
    super.key,
    required this.activity,
  });

  IconData _getIcon(String iconName) {
    switch (iconName) {
      case 'check_circle':
        return Icons.check_circle_outline;
      case 'attach_money':
        return Icons.attach_money;
      case 'person_add':
        return Icons.person_add_outlined;
      case 'warning':
        return Icons.warning_amber_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _getIconColor(String iconName) {
    switch (iconName) {
      case 'check_circle':
        return Colors.green;
      case 'attach_money':
        return Colors.amber;
      case 'person_add':
        return Colors.blue;
      case 'warning':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getIconColor(activity.icon).withAlpha(26),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _getIcon(activity.icon),
              color: _getIconColor(activity.icon),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activity.subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Text(
            activity.timestamp,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

