import 'package:go_router/go_router.dart';
import '../services/permission_service.dart';
import '../../shared/widgets/access_denied_widget.dart';

class RouteGuard {
  static const Map<String, String> routePermissions = {
    '/dashboard': 'Dashboard',
    '/inventory': 'Inventory',
    '/purchases': 'Purchase Records',
    '/sales': 'Sales',
    '/expenses': 'Expenses',
    '/workers': 'Workers',
    '/customers': 'Customers',
    '/reports': 'Reports',
    '/audit-log': 'Audit Log',
    '/settings': 'Settings',
  };

  static bool canAccessRoute(String route) {
    if (!PermissionService.isLoggedIn()) return false;
    if (PermissionService.isSuperAdmin()) return true;

    final requiredPermission = routePermissions[route];
    if (requiredPermission == null) return true;

    return PermissionService.hasPermission(requiredPermission);
  }

  static Widget buildAccessDeniedPage() {
    return const AccessDeniedWidget();
  }
}
