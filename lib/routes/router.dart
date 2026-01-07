import 'package:flutter/material.dart';
import 'package:incanteen/pages/error/no_internet_page.dart';
import 'package:incanteen/pages/landing_page.dart';
import 'package:incanteen/pages/splash_page.dart';
import 'package:incanteen/pages/undefinited_page.dart';
import 'package:incanteen/routes/routes_constants.dart';
import 'package:incanteen/pages/auth/login_page.dart';
import 'package:incanteen/pages/auth/signup_page.dart';
import 'package:incanteen/pages/auth/forgot_password_page.dart';
import 'package:incanteen/pages/auth/vendor_setup_page.dart';
import 'package:incanteen/pages/vendor_dashboard.dart';
import 'package:incanteen/pages/customer_home.dart';
import 'package:incanteen/pages/order/place_order_page.dart';
import 'package:incanteen/pages/admin/admin_dashboard.dart';
import 'package:incanteen/pages/admin/admin_manage_users_page.dart';
import 'package:incanteen/pages/admin/admin_user_detail_page.dart';
import 'package:incanteen/pages/admin/admin_manage_admins_page.dart';
import 'package:incanteen/pages/admin/admin_manage_vendors_page.dart';
import 'package:incanteen/pages/admin/admin_manage_vendor_detail_page.dart';

Route<dynamic> generateRoute(RouteSettings settings) {
  switch (settings.name) {
    case RoutesConstants.splashScreenRoute:
      return MaterialPageRoute(builder: (_) => const SplashPage());

    case RoutesConstants.landingRoute:
      return MaterialPageRoute(builder: (_) => const LandingPage());

    case RoutesConstants.noInternetRoute:
      return MaterialPageRoute(builder: (_) => const NoInternetPage());

    case RoutesConstants.loginRoute:
      return MaterialPageRoute(builder: (_) => const LoginPage());

    case RoutesConstants.signupRoute:
      return MaterialPageRoute(builder: (_) => const SignupPage());

    case RoutesConstants.forgotPasswordRoute:
      return MaterialPageRoute(builder: (_) => const ForgotPasswordPage());

    case RoutesConstants.vendorSetupRoute:
      return MaterialPageRoute(builder: (_) => const VendorSetupPage());

    case RoutesConstants.vendorDashboardRoute:
      return MaterialPageRoute(builder: (_) => const VendorDashboard());

    case RoutesConstants.customerHomeRoute:
      return MaterialPageRoute(builder: (_) => const CustomerHome());

    case RoutesConstants.orderPageRoute:
      final args = settings.arguments as Map<String, dynamic>?;

      if (args == null || !args.containsKey('vendorId')) {
        return MaterialPageRoute(
          builder: (_) => UndefinitedPage(name: settings.name),
        );
      }

      return MaterialPageRoute(
        builder: (_) =>
            PlaceOrderPage(vendorId: args['vendorId'], userId: args['userId']),
      );

    case RoutesConstants.adminDashboardRoute:
      return MaterialPageRoute(builder: (_) => const AdminDashboard());

    case RoutesConstants.adminManageUsersRoute:
      final args = settings.arguments as Map<String, dynamic>?;
      final roleFilter = args?['role'] as String?;
      return MaterialPageRoute(
        builder: (_) => AdminManageUsersPage(roleFilter: roleFilter),
      );

    case RoutesConstants.adminUserDetailRoute:
      final args = settings.arguments as Map<String, dynamic>?;
      if (args == null || !args.containsKey('userId')) {
        return MaterialPageRoute(
          builder: (_) => UndefinitedPage(name: settings.name),
        );
      }
      return MaterialPageRoute(
        builder: (_) => AdminUserDetailPage(userId: args['userId']),
      );

    case RoutesConstants.adminManageAdminsRoute:
      return MaterialPageRoute(builder: (_) => const AdminManageAdminsPage());

    case RoutesConstants.adminManageVendorsRoute:
      return MaterialPageRoute(builder: (_) => const AdminManageVendorsPage());

    case RoutesConstants.adminManageVendorDetailRoute:
      final args = settings.arguments as Map<String, dynamic>?;
      if (args == null || !args.containsKey('vendorId')) {
        return MaterialPageRoute(
          builder: (_) => UndefinitedPage(name: settings.name),
        );
      }
      return MaterialPageRoute(
        builder: (_) => AdminManageVendorDetailPage(vendorId: args['vendorId']),
      );

    default:
      return MaterialPageRoute(
        builder: (_) => UndefinitedPage(name: settings.name),
      );
  }
}
