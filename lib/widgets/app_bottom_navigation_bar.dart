import 'package:flutter/material.dart';

class AppBottomNavigationBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _tabs = [
    (Icons.home_outlined, Icons.home_rounded, 'หน้าแรก'),
    (Icons.shopping_bag_outlined, Icons.shopping_bag, 'ตะกร้า'),
    (
      Icons.collections_bookmark_outlined,
      Icons.collections_bookmark,
      'คอลเลกชัน',
    ),
    (Icons.person_outline, Icons.person, 'โปรไฟล์'),
  ];

  @override
  Widget build(BuildContext context) {
    const surface = Color(0xFF1D1D1D);
    const line = Color(0xFF383838);
    const accent = Color(0xFFFF5500);
    const accentSoft = Color(0xFF302016);
    const inkSoft = Color(0xFFAAAAAA);

    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: surface,
          border: Border(top: BorderSide(color: line)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(_tabs.length, (index) {
            final selected = index == currentIndex;
            final tab = _tabs[index];

            return GestureDetector(
              onTap: () => onTap(index),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? accentSoft : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      selected ? tab.$2 : tab.$1,
                      size: 26,
                      color: selected ? accent : inkSoft,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    tab.$3,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                      color: selected ? accent : inkSoft,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}
