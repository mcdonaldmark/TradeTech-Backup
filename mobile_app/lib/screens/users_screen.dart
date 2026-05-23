import 'package:flutter/material.dart';
import '../core/api/api_service.dart';
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

  @override
  void initState() {
    super.initState();
    fetchUsers();
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
        users = data.map((item) => User.fromJson(item)).toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> createUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      await ApiService.post("users", {
        "name": name,
        "email": email,
        "password": password,
        "role": role,
      });

      fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Create failed: $e")),
      );
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      await ApiService.delete("users/$id");
      fetchUsers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Delete failed: $e")),
      );
    }
  }

  Future<void> updateUser({
    required int id,
    required String name,
    required String email,
    required String role,
  }) async {
    try {
      await ApiService.put("users/$id", {
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

  void showCreateDialog() {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    String role = "user";

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
              items: const [
                DropdownMenuItem(value: "user", child: Text("User")),
                DropdownMenuItem(value: "cashier", child: Text("Cashier")),
                DropdownMenuItem(value: "manager", child: Text("Manager")),
                DropdownMenuItem(value: "director", child: Text("Director")),
              ],
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
              await createUser(
                name: name.text,
                email: email.text,
                password: password.text,
                role: role,
              );

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Create"),
          ),
        ],
      ),
    );
  }

  void showEditDialog(User user) {
    final name = TextEditingController(text: user.name);
    final email = TextEditingController(text: user.email);
    String role = user.role;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Update User"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: name),
            TextField(controller: email),
            DropdownButtonFormField(
              value: role,
              items: const [
                DropdownMenuItem(value: "user", child: Text("User")),
                DropdownMenuItem(value: "cashier", child: Text("Cashier")),
                DropdownMenuItem(value: "manager", child: Text("Manager")),
                DropdownMenuItem(value: "director", child: Text("Director")),
              ],
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
              await updateUser(
                id: user.id,
                name: name.text,
                email: email.text,
                role: role,
              );

              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final u = users[index];

                      return Card(
                        child: ListTile(
                          title: Text(u.name),
                          subtitle: Text(u.email),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(u.role),

                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => showEditDialog(u),
                              ),

                              IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => deleteUser(u.id),
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