import 'package:flutter/material.dart';
import 'package:incanteen/pages/error/no_internet_page.dart';
import 'package:incanteen/pages/landing_page.dart';
import 'package:incanteen/pages/splash_page.dart';
import 'package:incanteen/pages/undefinited_page.dart';
import 'package:incanteen/routes/routes_constants.dart';
import 'package:incanteen/pages/auth/login_page.dart';
import 'package:incanteen/pages/auth/signup_page.dart';
import 'package:incanteen/pages/order/place_order_page.dart';
import 'package:incanteen/pages/test_auth_page.dart';

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

    // case RoutesConstants.signupRoute:
    //   return MaterialPageRoute(builder: (_) => const SignupPage());

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

    case "/testAuth":
      return MaterialPageRoute(builder: (_) => const TestAuthPage());

    default:
      return MaterialPageRoute(
        builder: (_) => UndefinitedPage(name: settings.name),
      );
  }
}
