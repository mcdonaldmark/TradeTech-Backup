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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users")),
      body: RefreshIndicator(
        onRefresh: fetchUsers,
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
                ? ListView(
                    children: [
                      const SizedBox(height: 100),
                      Center(child: Text("Error: $error")),
                      const SizedBox(height: 20),
                      Center(
                        child: ElevatedButton(
                          onPressed: fetchUsers,
                          child: const Text("Retry"),
                        ),
                      )
                    ],
                  )
                : ListView.builder(
                    itemCount: users.length,
                    itemBuilder: (context, index) {
                      final u = users[index];

                      return Card(
                        child: ListTile(
                          title: Text(u.name),
                          subtitle: Text(u.email),
                          trailing: Text(u.role),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}