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
import '../../features/broker_consignment/presentation/pages/broker_details_page.dart';
import '../../features/broker_consignment/presentation/pages/broker_list_page.dart';
import '../../features/broker_consignment/presentation/pages/broker_detail_page.dart';
import '../../features/customers/presentation/pages/customers_page.dart';
import '../../features/settings/presentation/pages/business_profile_page.dart';
import '../../features/broker_profile/presentation/pages/broker_list_page.dart' as profile;
import '../../features/broker_profile/presentation/pages/add_broker_page.dart';
import '../../features/broker_profile/presentation/pages/broker_detail_page.dart' as profile_detail;
import '../../features/broker_profile/presentation/pages/broker_voucher_list_page.dart';
import '../../features/license/presentation/license_placeholder_page.dart';

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
      builder: (context, state) => const BrokerListPage(),
      routes: [
        GoRoute(
          path: 'form',
          name: 'broker-form',
          builder: (context, state) => const BrokerFormPage(),
        ),
        GoRoute(
          path: 'detail',
          name: 'broker-detail',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return BrokerDetailPage(
              brokerName: extra?['brokerName'] ?? '',
              brokerPhone: extra?['brokerPhone'] ?? '',
              brokerAddress: extra?['brokerAddress'] ?? '',
              vouchers: extra?['vouchers'] ?? [],
            );
          },
        ),
        GoRoute(
          path: ':id',
          name: 'broker-details',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return BrokerDetailsPage(brokerId: id ?? '');
          },
        ),
      ],
    ),
    GoRoute(
      path: '/customers',
      name: 'customers',
      builder: (context, state) => const CustomersPage(),
    ),
    GoRoute(
      path: '/business-profile',
      name: 'business-profile',
      builder: (context, state) => const BusinessProfilePage(),
    ),
    GoRoute(
      path: '/license',
      name: 'license',
      builder: (context, state) => const LicensePlaceholderPage(),
    ),
    GoRoute(
      path: '/brokers',
      name: 'brokers',
      builder: (context, state) => const profile.BrokerListPage(),
      routes: [
        GoRoute(
          path: 'add',
          name: 'add-broker',
          builder: (context, state) => const AddBrokerPage(),
        ),
        GoRoute(
          path: ':id',
          name: 'broker-detail',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return profile_detail.BrokerProfileDetailPage(brokerId: id ?? '');
          },
        ),
        GoRoute(
          path: ':id/vouchers',
          name: 'broker-vouchers',
          builder: (context, state) {
            final id = state.pathParameters['id'];
            return BrokerVoucherListPage(brokerId: id ?? '');
          },
        ),
      ],
    ),
  ],
);
