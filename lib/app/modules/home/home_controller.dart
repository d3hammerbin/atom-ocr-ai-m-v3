import 'package:get/get.dart';
import 'package:flutter/material.dart';
import '../../routes/app_pages.dart';
import '../../global_widgets/bubble_nav_item.dart';

class HomeController extends GetxController {
  var selectedIndex = 0.obs;

  final List<BubbleNavItem> navItems = [
    BubbleNavItem(
      activeIcon: Icons.home,
      inactiveIcon: Icons.home_outlined,
      label: 'Inicio',
    ),
    BubbleNavItem(
      activeIcon: Icons.list_alt,
      inactiveIcon: Icons.list_alt_outlined,
      label: 'Lista',
    ),
    BubbleNavItem(
      activeIcon: Icons.qr_code_scanner,
      inactiveIcon: Icons.qr_code_scanner_outlined,
      label: 'Escaner',
    ),
    BubbleNavItem(
      activeIcon: Icons.settings,
      inactiveIcon: Icons.settings_outlined,
      label: 'Ajustes',
    ),
  ];


  void onItemTapped(int index) {
    selectedIndex.value = index;
  }
  



  
  void navigateToOcr() {
    Get.toNamed('/ocr');
  }
  
  void navigateToCamera() {
    Get.toNamed('/camera');
  }
  
  void navigateToCredentialsList() {
    Get.toNamed('/credentials-list');
  }
  
  void navigateToLocalProcess() {
    Get.toNamed('/local-process');
  }
}