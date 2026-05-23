import 'package:flutter/material.dart';

class RoleGuard extends StatelessWidget {
  final String userRole;
  final List<String> allowedRoles;
  final Widget child;
  final Widget? fallback;

  const RoleGuard({
    super.key,
    required this.userRole,
    required this.allowedRoles,
    required this.child,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final hasAccess = allowedRoles.contains(userRole);

    if (hasAccess) {
      return child;
    }

    return fallback ??
        const Scaffold(
          body: Center(
            child: Text(
              "Access Denied",
              style: TextStyle(
                fontSize: 18,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
  }
}