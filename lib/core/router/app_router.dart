import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../local/local_db.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/inventory/presentation/pages/inventory_page.dart';
import '../../features/sales/presentation/pages/sales_page.dart';
import '../../features/expenses/presentation/pages/expenses_page.dart';
import '../../features/workers/presentation/pages/workers_page.dart';
import '../../features/branches/presentation/pages/branches_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/account_settings/presentation/pages/account_settings_page.dart';
import '../../features/broker_consignment/presentation/pages/broker_consignment_page.dart';
import '../../features/broker_consignment/presentation/pages/broker_form_page.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  redirect: (context, state) {
    final loggedIn = LocalDb.isLoggedIn();
    final goingToLogin = state.matchedLocation == '/login';
    if (!loggedIn && !goingToLogin) return '/login';
    if (loggedIn && goingToLogin) return '/dashboard';
    return null;
  },
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Text('Error: ${state.error}'),
    ),
  ),
  routes: [
    GoRoute(
      path: '/login',
      name: 'login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/dashboard',
      name: 'dashboard',
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: '/inventory',
      name: 'inventory',
      builder: (context, state) => const InventoryPage(),
    ),
    GoRoute(
      path: '/sales',
      name: 'sales',
      builder: (context, state) => const SalesPage(),
    ),
    GoRoute(
      path: '/expenses',
      name: 'expenses',
      builder: (context, state) => const ExpensesPage(),
    ),
    GoRoute(
      path: '/workers',
      name: 'workers',
      builder: (context, state) => const WorkersPage(),
    ),
    GoRoute(
      path: '/branches',
      name: 'branches',
      builder: (context, state) => const BranchesPage(),
    ),
    GoRoute(
      path: '/reports',
      name: 'reports',
      builder: (context, state) => ReportsPage(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/account-settings',
      name: 'account-settings',
      builder: (context, state) => const AccountSettingsPage(),
    ),
    GoRoute(
      path: '/broker-consignment',
      name: 'broker-consignment',
      builder: (context, state) => const BrokerConsignmentPage(),
      routes: [
        GoRoute(
          path: 'form',
          name: 'broker-form',
          builder: (context, state) => BrokerFormPage(
            brokerId: state.pathParameters['brokerId'],
          ),
        ),
      ],
    ),
  ],
);
