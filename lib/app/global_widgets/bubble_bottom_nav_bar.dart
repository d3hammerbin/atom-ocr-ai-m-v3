import 'package:flutter/material.dart';
import 'bubble_nav_item.dart';

class BubbleBottomNavBar extends StatefulWidget {
  final List<BubbleNavItem> items;
  final int currentIndex;
  final void Function(int) onItemTapped;
  final Color activeColor;
  final Color inactiveColor;
  final Color backgroundColor;

  const BubbleBottomNavBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onItemTapped,
    this.activeColor = const Color(0xFF18DAA3), // Color activo del tema
    this.inactiveColor = Colors.black54,
    this.backgroundColor = Colors.white,
  });

  @override
  State<BubbleBottomNavBar> createState() => _BubbleBottomNavBarState();
}

class _BubbleBottomNavBarState extends State<BubbleBottomNavBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12.0),
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      decoration: BoxDecoration(
        color: widget.backgroundColor,
        borderRadius: BorderRadius.circular(50.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double itemWidth = constraints.maxWidth / widget.items.length;

          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 350),
                curve: Curves.elasticOut,
                left: widget.currentIndex * itemWidth,
                top: 0,
                child: Container(
                  width: itemWidth,
                  height: kBottomNavigationBarHeight,
                  alignment: Alignment.center,
                  child: Container(
                    width: itemWidth * 0.7,
                    height: kBottomNavigationBarHeight * 0.7,
                    decoration: BoxDecoration(
                      color: widget.activeColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(widget.items.length, (index) {
                  final item = widget.items[index];
                  final bool isSelected = index == widget.currentIndex;
                  
                  return GestureDetector(
                    onTap: () => widget.onItemTapped(index),
                    behavior: HitTestBehavior.opaque,
                    child: SizedBox(
                      width: itemWidth,
                      height: kBottomNavigationBarHeight,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isSelected ? item.activeIcon : item.inactiveIcon,
                            color: isSelected ? widget.activeColor : widget.inactiveColor,
                            size: 26,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ],
          );
        },
      ),
    );
  }
}
