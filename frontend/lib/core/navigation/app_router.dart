import 'package:go_router/go_router.dart';
import '../../presentation/pages/dashboard_page.dart';
import '../../presentation/pages/inventory_page.dart';
import '../../presentation/pages/lot_page.dart';
import '../../presentation/pages/expense_page.dart';
import '../../presentation/pages/sales_page.dart';
import '../../presentation/pages/reports_page.dart';
import '../../presentation/pages/qr_scanner_impl.dart';
import '../../presentation/pages/settings_page.dart';
import '../../presentation/pages/order_create_page.dart';
import '../../presentation/pages/orders_list_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/order-create',
      builder: (context, state) => const OrderCreatePage(),
    ),
    GoRoute(
      path: '/orders',
      builder: (context, state) => const OrdersListPage(),
    ),
    GoRoute(
      path: '/inventory',
      builder: (context, state) => const InventoryPage(),
    ),
    GoRoute(
      path: '/lots',
      builder: (context, state) => const LotPage(),
    ),
    GoRoute(
      path: '/expenses',
      builder: (context, state) => const ExpensePage(),
    ),
    GoRoute(
      path: '/sales',
      builder: (context, state) => const SalesPage(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsPage(),
    ),
    GoRoute(
      path: '/qr-scanner',
      builder: (context, state) => const QrScannerImpl(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);
