import 'package:material_ui/material_ui.dart';

import '../domain/gear_logic.dart';

IconData gearIcon(GearCategory c) => switch (c) {
  GearCategory.sleep => Icons.bed_outlined,
  GearCategory.cook => Icons.outdoor_grill_outlined,
  GearCategory.clothing => Icons.checkroom_outlined,
  GearCategory.pack => Icons.backpack_outlined,
  GearCategory.electronics => Icons.flashlight_on_outlined,
  GearCategory.safety => Icons.medical_services_outlined,
  GearCategory.other => Icons.category_outlined,
};
