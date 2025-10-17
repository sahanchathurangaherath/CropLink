import 'package:flutter/material.dart';
import '../screens/auth/auth_gate.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/buyer/buyer_item_screen.dart';
import '../screens/buyer/buyer_subcategory_screen.dart';
import '../screens/seller/seller_item_screen.dart';
import '../screens/seller/seller_subcategory_screen.dart';
import '../screens/home.dart';
import '../screens/post_item.dart';
import '../screens/welcome.dart';
import 'app_routes.dart';

class RouteGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    // Getting arguments passed in while calling Navigator.pushNamed
    final args = settings.arguments;

    switch (settings.name) {
      case AppRoutes.welcome:
        return MaterialPageRoute(
          builder: (_) => const WelcomeScreen(),
        );

      case AppRoutes.signIn:
        return MaterialPageRoute(
          builder: (_) => const SignInScreen(),
        );

      case AppRoutes.signUp:
        return MaterialPageRoute(
          builder: (_) => const SignUpScreen(),
        );

      case AppRoutes.authGate:
        return MaterialPageRoute(
          builder: (_) => const AuthGate(),
        );

      case AppRoutes.home:
        return MaterialPageRoute(
          builder: (_) => const HomeScreen(),
        );

      case AppRoutes.postItem:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => PostItemScreen(category: args),
          );
        }
        return _errorRoute();

      case AppRoutes.buyerSubcategories:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => BuyerSubcategoryScreen(category: args),
          );
        }
        return _errorRoute();

      case AppRoutes.sellerSubcategories:
        if (args is String) {
          return MaterialPageRoute(
            builder: (_) => SellerSubcategoryScreen(category: args),
          );
        }
        return _errorRoute();

      case AppRoutes.buyerItems:
        if (args is Map<String, String>) {
          return MaterialPageRoute(
            builder: (_) => BuyerItemScreen(
              category: args['category']!,
              subcategory: args['subcategory']!,
            ),
          );
        }
        return _errorRoute();

      case AppRoutes.sellerItems:
        if (args is Map<String, String>) {
          return MaterialPageRoute(
            builder: (_) => SellerItemScreen(
              category: args['category']!,
              subcategory: args['subcategory']!,
            ),
          );
        }
        return _errorRoute();

      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Error'),
        ),
        body: const Center(
          child: Text('Page not found!'),
        ),
      );
    });
  }
}
