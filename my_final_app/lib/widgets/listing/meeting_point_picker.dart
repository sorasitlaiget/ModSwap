import 'package:flutter/material.dart';
import '../../models/listing.dart';
import '../../theme/app_colors.dart';

/// Picker for KMUTT meeting points (pre-defined list)
class MeetingPointPicker extends StatelessWidget {
  final MeetingPoint? selected;
  final ValueChanged<MeetingPoint?> onChanged;

  const MeetingPointPicker({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showPicker(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.textGray.withValues(alpha: 0.5)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 20,
              color: AppColors.textGray,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selected?.name ?? 'Select meeting point on campus',
                style: TextStyle(
                  fontSize: 13,
                  color: selected != null
                      ? AppColors.navy
                      : AppColors.textGray.withValues(alpha: 0.7),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.keyboard_arrow_down, color: AppColors.navy),
          ],
        ),
      ),
    );
  }

  Future<void> _showPicker(BuildContext context) async {
    final picked = await showModalBottomSheet<MeetingPoint>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (_, scrollController) => Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textGray.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Icon(Icons.location_on, color: AppColors.orange),
                  SizedBox(width: 8),
                  Text(
                    'KMUTT Meeting Points',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Choose a safe place inside KMUTT campus',
                style: TextStyle(color: AppColors.textGray, fontSize: 12),
              ),
            ),
            const SizedBox(height: 12),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: KmuttPlaces.all.length,
                itemBuilder: (_, i) {
                  final place = KmuttPlaces.all[i];
                  final isSelected = selected == place;
                  return ListTile(
                    leading: Icon(
                      Icons.place,
                      color: isSelected ? AppColors.orange : AppColors.textGray,
                    ),
                    title: Text(
                      place.name,
                      style: TextStyle(
                        color: AppColors.navy,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    // subtitle: Text(
                    //   '${place.latitude.toStringAsFixed(4)}, ${place.longitude.toStringAsFixed(4)}',
                    //   style: const TextStyle(
                    //     color: AppColors.textGray,
                    //     fontSize: 11,
                    //   ),
                    // ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.orange)
                        : null,
                    onTap: () => Navigator.pop(ctx, place),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );

    if (picked != null) onChanged(picked);
  }
}

// ============================================================================
// หมายเหตุ: นำคลาส KmuttPlaces ด้านล่างนี้ไปวางไว้ในไฟล์ models/listing.dart
// หรือถ้าต้องการเก็บไว้ไฟล์นี้ก็สามารถวางต่อท้ายได้เลยครับ (แล้วลบอันเก่าทิ้ง)
// ============================================================================

class KmuttPlaces {
  static const List<MeetingPoint> all = [
    // --- Zone N (North / Yellow Buildings) ---
    // MeetingPoint(name: "N1 Welcome Center Building", latitude: 13.6510, longitude: 100.4940),
    // MeetingPoint(name: "N2 Office of The President Building", latitude: 13.6512, longitude: 100.4942),
    MeetingPoint(
      name: "N3 Department of Chemistry Building",
      latitude: 13.6515,
      longitude: 100.4945,
    ),
    MeetingPoint(
      name: "N4 Department of Physics-Mathematics Building",
      latitude: 13.6518,
      longitude: 100.4948,
    ),
    MeetingPoint(
      name:
          "N5 Scientific Instrument Center for Standards and Industry Building",
      latitude: 13.6520,
      longitude: 100.4950,
    ),
    MeetingPoint(
      name: "N6 Department of Microbiology Building",
      latitude: 13.6522,
      longitude: 100.4952,
    ),
    // MeetingPoint(name: "N7 Fundamental Science Laboratory Building", latitude: 13.6525, longitude: 100.4955),
    // MeetingPoint(name: "N8 Water Pump Station", latitude: 13.6528, longitude: 100.4958),
    MeetingPoint(
      name: "N9 Institute of Field Robotics Building (FIBO)",
      latitude: 13.6530,
      longitude: 100.4960,
    ),
    MeetingPoint(
      name: "N10 KMUTT Library Building",
      latitude: 13.6532,
      longitude: 100.4962,
    ),
    MeetingPoint(
      name: "N11 School of Information Technology Building (SIT)",
      latitude: 13.6535,
      longitude: 100.4965,
    ),
    // MeetingPoint(name: "N12 Utility Exchange Building", latitude: 13.6538, longitude: 100.4968),
    // MeetingPoint(name: "N13 Workshop & Greenhouse Building", latitude: 13.6540, longitude: 100.4970),
    // MeetingPoint(name: "N14 Hi-Voltage Building", latitude: 13.6542, longitude: 100.4972),
    MeetingPoint(
      name: "N15 School of Liberal Arts Building (SoLA)",
      latitude: 13.6545,
      longitude: 100.4975,
    ),
    MeetingPoint(
      name: "N16 Learning Exchange Building (LX)",
      latitude: 13.6548,
      longitude: 100.4978,
    ),
    MeetingPoint(
      name: "N17 Classroom Building 2 (CB2)",
      latitude: 13.6550,
      longitude: 100.4980,
    ),
    // MeetingPoint(name: "N18 Production Engineering Laboratory Building 4", latitude: 13.6552, longitude: 100.4982),
    // MeetingPoint(name: "N19 Production Engineering Laboratory Building 5", latitude: 13.6555, longitude: 100.4985),
    MeetingPoint(
      name: "N20 Classroom Building 1 (CB1)",
      latitude: 13.6558,
      longitude: 100.4988,
    ),

    // --- Zone S (South / Orange Buildings) ---
    MeetingPoint(
      name: "S1 Mechanical Engineering Building 4",
      latitude: 13.6490,
      longitude: 100.4930,
    ),
    MeetingPoint(
      name: "S2 Car Parking Building",
      latitude: 13.6488,
      longitude: 100.4928,
    ),
    // MeetingPoint(name: "S3 Darunsikkhalai School For Innovative Learning", latitude: 13.6485, longitude: 100.4925),
    MeetingPoint(
      name: "S4 Engineering Building (Wissawa Wattana)",
      latitude: 13.6482,
      longitude: 100.4922,
    ),
    MeetingPoint(
      name: "S5 Dhammaraksa Residence Hall 2 (Male Dormitory)",
      latitude: 13.6480,
      longitude: 100.4920,
    ),
    MeetingPoint(
      name: "S6 Dhammaraksa Residence Hall 1 (Female Dormitory)",
      latitude: 13.6478,
      longitude: 100.4918,
    ),
    // MeetingPoint(name: "S7 KMUTT Child Development Building", latitude: 13.6475, longitude: 100.4915),
    // MeetingPoint(name: "S8 Materials Technology Research and Development Building", latitude: 13.6472, longitude: 100.4912),
    // MeetingPoint(name: "S9 School of Energy Environment and Materials Building", latitude: 13.6470, longitude: 100.4910),
    // MeetingPoint(name: "S10 KMUTT Green Society Building", latitude: 13.6468, longitude: 100.4908),
    MeetingPoint(
      name: "S11 Classroom Building 5 (CB5)",
      latitude: 13.6465,
      longitude: 100.4905,
    ),
    MeetingPoint(
      name: "S12 Classroom Building 4 (CB4)",
      latitude: 13.6462,
      longitude: 100.4902,
    ),
    MeetingPoint(
      name: "S13 Classroom Building 3 (CB3)",
      latitude: 13.6460,
      longitude: 100.4900,
    ),
    MeetingPoint(
      name: "S14 King Mongkut's 190th Anniversary Memorial Building (KFC)",
      latitude: 13.6458,
      longitude: 100.4898,
    ),
    MeetingPoint(
      name: "S15 Department of Chemical Engineering Building",
      latitude: 13.6455,
      longitude: 100.4895,
    ),
  ];
}
