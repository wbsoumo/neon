import 'package:flutter/material.dart';

class BlinkitNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const BlinkitNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(
            color: Color(0XFFE0E0E0),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            index: 0,
            label: "Home",
            customIcon: _buildHomeIcon(currentIndex == 0),
          ),
          _buildNavItem(
            index: 1,
            label: "Order Again",
            customIcon: Icon(
              Icons.shopping_bag_outlined,
              size: 26,
              color: currentIndex == 1 ? Colors.black : const Color(0XFF616161),
            ),
          ),
          _buildNavItem(
            index: 2,
            label: "Categories",
            customIcon: _buildCategoriesIcon(currentIndex == 2),
          ),
          _buildNavItem(
            index: 3,
            label: "Profile",
            customIcon: Icon(
              currentIndex == 3 ? Icons.person : Icons.person_outline_rounded,
              size: 26,
              color: currentIndex == 3 ? Colors.black : const Color(0XFF616161),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required Widget customIcon,
  }) {
    final bool isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTap(index),
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top Active Indicator Black Bar
          Container(
            height: 3,
            width: 36,
            decoration: BoxDecoration(
              color: isSelected ? Colors.black : Colors.transparent,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(3)),
            ),
          ),

          customIcon,

          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? Colors.black : const Color(0XFF616161),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Custom Yellow House Icon matching screenshot
  Widget _buildHomeIcon(bool isSelected) {
    return Container(
      height: 26,
      width: 26,
      decoration: BoxDecoration(
        color: isSelected ? const Color(0XFFFFD54F) : Colors.transparent,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(10),
          topRight: Radius.circular(10),
          bottomLeft: Radius.circular(4),
          bottomRight: Radius.circular(4),
        ),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Center(
        child: Container(
          height: 8,
          width: 7,
          margin: const EdgeInsets.only(top: 8),
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(3)),
          ),
        ),
      ),
    );
  }

  // Custom 4 Circles Categories Icon matching screenshot
  Widget _buildCategoriesIcon(bool isSelected) {
    final Color color = isSelected ? Colors.black : const Color(0XFF616161);
    return SizedBox(
      height: 24,
      width: 24,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: color, width: 1.5),
                ),
              ),
              const SizedBox(width: 3),
              Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color,
                ),
              ),
              const SizedBox(width: 3),
              Container(
                height: 8,
                width: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: color, width: 1.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
