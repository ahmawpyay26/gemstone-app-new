import 'package:flutter/material.dart';
import '../services/permission_service.dart';

class DynamicBottomNavigation {
  static List<BottomNavigationBarItem> buildItems() {
    final items = <BottomNavigationBarItem>[];

    if (PermissionService.isSuperAdmin() || PermissionService.hasPermission('Dashboard')) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.dashboard),
        label: 'Dashboard',
      ));
    }

    if (PermissionService.isSuperAdmin() || PermissionService.hasPermission('Inventory')) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.inventory),
        label: 'Inventory',
      ));
    }

    if (PermissionService.isSuperAdmin() || PermissionService.hasPermission('Sales')) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.shopping_cart),
        label: 'Sales',
      ));
    }

    if (PermissionService.isSuperAdmin() || PermissionService.hasPermission('Reports')) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.bar_chart),
        label: 'Reports',
      ));
    }

    if (PermissionService.isSuperAdmin() || PermissionService.hasPermission('Settings')) {
      items.add(const BottomNavigationBarItem(
        icon: Icon(Icons.settings),
        label: 'Settings',
      ));
    }

    return items;
  }

  static List<DrawerItem> buildDrawerItems() {
    final items = <DrawerItem>[];

    if (PermissionService.isSuperAdmin() || PermissionService.hasPermission('Dashboard')) {
      items.add(DrawerItem(
        icon: Icons.dashboard,
        label: 'Dashboard',
        route: '/dashboard',
      ));
    }

    if (PermissionService.isSuperAdmin() || PermissionService.hasPermission('Inventory')) {
      items.add(DrawerItem(
        icon: Icons.inventory,
        label: 'Inventory',
        route: '/inventory',
      ));
    }

    if (PermissionService.isSuperAdmin() || PermissionService.hasPermission('Purchase Records')) {
      items.add(DrawerItem(
        icon: Icons.shopping_bag,
        label: 'Purchases',
        route: '/purchases',
      ));
    }

    if (PermissionService.isSuperAdmin() || PermissionService.hasPermission('Sales')) {
      items.add(DrawerItem(
        icon: Icons.shopping_cart,
        label: 'Sales',
        route: '/sales',
      ));
    }

    if (PermissionService.isSuperAdmin() || PermissionService.hasPermission('Expenses')) {
      items.add(DrawerItem(
        icon: Icons.money_off,
        label: 'Expenses',
        route: '/expenses',
      ));
    }

    if (PermissionService.isSuperAdmin() || PermissionService.hasPermission('Workers')) {
      items.add(DrawerItem(
        icon: Icons.people,
        label: 'Workers',
        route: '/workers',
      ));
    }

    if (PermissionService.isSuperAdmin() || PermissionService.hasPermission('Customers')) {
      items.add(DrawerItem(
        icon: Icons.person,
        label: 'Customers',
        route: '/customers',
      ));
    }

    if (PermissionService.isSuperAdmin() || PermissionService.hasPermission('Reports')) {
      items.add(DrawerItem(
        icon: Icons.bar_chart,
        label: 'Reports',
        route: '/reports',
      ));
    }

    if (PermissionService.isSuperAdmin() || PermissionService.hasPermission('Audit Log')) {
      items.add(DrawerItem(
        icon: Icons.history,
        label: 'Audit Log',
        route: '/audit-log',
      ));
    }

    if (PermissionService.isSuperAdmin() || PermissionService.hasPermission('Settings')) {
      items.add(DrawerItem(
        icon: Icons.settings,
        label: 'Settings',
        route: '/settings',
      ));
    }

    return items;
  }
}

class DrawerItem {
  final IconData icon;
  final String label;
  final String route;

  DrawerItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}
