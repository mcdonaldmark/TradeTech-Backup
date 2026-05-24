import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
import '../core/auth/auth_service.dart';
import '../models/user.dart';

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  List<User> users = [];
  bool loading = true;
  String? error;

  String get currentRole => AuthService.currentRole ?? "unknown";

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  bool canViewRole(String role) {
    if (currentRole == "manager") {
      return role == "user" || role == "cashier";
    }

    if (currentRole == "cashier") {
      return role == "user";
    }

    return true;
  }

  bool canEditRole(String role) {
    if (currentRole == "manager") {
      return role == "user" || role == "cashier";
    }

    if (currentRole == "cashier") {
      return role == "user";
    }

    return true;
  }

  bool canCreateRole(String role) {
    if (currentRole == "manager") {
      return role == "user" || role == "cashier";
    }

    if (currentRole == "cashier") {
      return role == "user";
    }

    return true;
  }

  Future<void> fetchUsers() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final res = await ApiService.get("users");
      final List data = res as List;

      setState(() {
        users = data.map((e) => User.fromJson(e)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> deleteUser(User user) async {
    if (!canEditRole(user.role)) return;

    try {
      await ApiService.delete("users/${user.id}");
      fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $e")),
      );
    }
  }

  Future<void> updateUser(
    User user,
    String name,
    String email,
    String role,
  ) async {
    if (!canEditRole(user.role) || !canCreateRole(role)) return;

    try {
      await ApiService.put("users/${user.id}", {
        "name": name,
        "email": email,
        "role": role,
      });

      fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Update failed: $e")),
      );
    }
  }

  void showEditDialog(User user) {
    if (!canEditRole(user.role)) return;

    final name = TextEditingController(text: user.name);
    final email = TextEditingController(text: user.email);
    String role = user.role;

    final allowedRoles = <String>[];

    if (currentRole == "manager") {
      allowedRoles.addAll(["user", "cashier"]);
    } else if (currentRole == "cashier") {
      allowedRoles.add("user");
    } else {
      allowedRoles.addAll(["user", "cashier", "manager", "director"]);
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name),
            TextField(controller: email),

            DropdownButtonFormField(
              value: role,
              items: allowedRoles
                  .map(
                    (r) => DropdownMenuItem(
                      value: r,
                      child: Text(r),
                    ),
                  )
                  .toList(),
              onChanged: (v) => role = v!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              await updateUser(user, name.text, email.text, role);

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void showCreateDialog() {
    String role = "user";

    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();

    List<String> allowedRoles = [];

    if (currentRole == "manager") {
      allowedRoles = ["user", "cashier"];
    } else if (currentRole == "cashier") {
      allowedRoles = ["user"];
    } else {
      allowedRoles = ["user", "cashier", "manager", "director"];
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Create User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: email, decoration: const InputDecoration(labelText: "Email")),
            TextField(controller: password, obscureText: true, decoration: const InputDecoration(labelText: "Password")),

            DropdownButtonFormField(
              value: role,
              items: allowedRoles
                  .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                  .toList(),
              onChanged: (v) => role = v!,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await ApiService.post("users", {
                  "name": name.text,
                  "email": email.text,
                  "password": password.text,
                  "role": role,
                });

                fetchUsers();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Create failed: $e")),
                );
              }

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleUsers = users.where((u) => canViewRole(u.role)).toList();

    return Scaffold(
      appBar: AppBar(title: const Text("Users")),

      floatingActionButton: FloatingActionButton(
        onPressed: showCreateDialog,
        child: const Icon(Icons.add),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : RefreshIndicator(
                  onRefresh: fetchUsers,
                  child: ListView.builder(
                    itemCount: visibleUsers.length,
                    itemBuilder: (context, index) {
                      final u = visibleUsers[index];

                      final canEdit = canEditRole(u.role);

                      return Card(
                        child: ListTile(
                          title: Text(u.name),
                          subtitle: Text(u.email),

                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(u.role),

                              if (canEdit)
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => showEditDialog(u),
                                ),

                              if (canEdit)
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => deleteUser(u),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}