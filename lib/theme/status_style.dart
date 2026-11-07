import 'package:flutter/material.dart';

import 'app_icons.dart';

// One icon and one colour per status, so a status looks the same everywhere it appears.
class StatusStyle {
  const StatusStyle(this.icon, this.color, this.label);
  final IconData icon;
  final Color color;
  final String label;
}

StatusStyle statusStyle(String status) => switch (status) {
  'In Progress' => const StatusStyle(
    Ph.wrenchFill,
    Color(0xFFD08A14),
    'In progress',
  ),
  'Resolved' => const StatusStyle(
    Ph.checkCircleFill,
    Color(0xFF1E8E4E),
    'Resolved',
  ),
  'Rejected' => const StatusStyle(
    Ph.xCircleFill,
    Color(0xFFD7403A),
    'Rejected',
  ),
  _ => const StatusStyle(Ph.paperPlaneTiltFill, Color(0xFF7A62C9), 'Submitted'),
};

const _shortMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String monthShort(int month) => _shortMonths[month - 1];
