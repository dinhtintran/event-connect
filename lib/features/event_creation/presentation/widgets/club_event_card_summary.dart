import 'package:flutter/material.dart';

class ClubEventCardSummary extends StatelessWidget {
  final String title;
  final String status;
  final int registered;
  final int capacity;
  final bool isLive;
  final VoidCallback onManage;
  final VoidCallback onRegister;
  final VoidCallback onEdit;

  const ClubEventCardSummary({
    super.key,
    required this.title,
    required this.status,
    required this.registered,
    required this.capacity,
    required this.isLive,
    required this.onManage,
    required this.onRegister,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isLive ? Colors.green[50] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isLive ? Colors.green : Colors.black54,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text('Đăng ký', style: TextStyle(color: Colors.black54)),
          const SizedBox(height: 4),
          Text(
            '$registered/$capacity',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),

          const SizedBox(height: 10),

          Row(
            children: [
              OutlinedButton(
                onPressed: onManage,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Quản lý'),
              ),
              const SizedBox(width: 8),
              OutlinedButton(
                onPressed: onRegister,
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Đăng ký'),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, size: 20),
                color: Colors.black54,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

