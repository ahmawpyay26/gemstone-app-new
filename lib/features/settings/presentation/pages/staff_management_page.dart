import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/local/local_db.dart';
import '../../../../core/local/models.dart';
import '../../../../core/services/password_service.dart';

class StaffManagementPage extends StatefulWidget {
  const StaffManagementPage({Key? key}) : super(key: key);

  @override
  State<StaffManagementPage> createState() => _StaffManagementPageState();
}

class _StaffManagementPageState extends State<StaffManagementPage> {
  late Box<StaffUser> staffBox;
  late Box<Role> roleBox;

  @override
  void initState() {
    super.initState();
    staffBox = Hive.box<StaffUser>(LocalDb.staffUsersBox);
    roleBox = Hive.box<Role>(LocalDb.rolesBox);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Management')),
      body: ValueListenableBuilder<Box<StaffUser>>(
        valueListenable: staffBox.listenable(),
        builder: (context, box, _) {
          final staffList = box.values.toList();
          return ListView.builder(
            itemCount: staffList.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: () => _showStaffDialog(context),
                    child: const Text('Add New Staff'),
                  ),
                );
              }
              final staff = staffList[index - 1];
              return StaffCard(
                staff: staff,
                onEdit: () => _showStaffDialog(context, staff),
                onDelete: () => _deleteStaff(staff),
                onToggle: () => _toggleStaffStatus(staff),
              );
            },
          );
        },
      ),
    );
  }

  void _showStaffDialog(BuildContext context, [StaffUser? staff]) {
    showDialog(
      context: context,
      builder: (context) => StaffFormDialog(
        staff: staff,
        roles: roleBox.values.toList(),
        onSave: (newStaff) {
          if (staff == null) {
            staffBox.add(newStaff);
          } else {
            final index = staffBox.values.toList().indexOf(staff);
            staffBox.putAt(index, newStaff);
          }
          Navigator.pop(context);
        },
      ),
    );
  }

  void _deleteStaff(StaffUser staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Staff'),
        content: Text('Delete ${staff.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final index = staffBox.values.toList().indexOf(staff);
              staffBox.deleteAt(index);
              Navigator.pop(context);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _toggleStaffStatus(StaffUser staff) {
    final updated = StaffUser(
      id: staff.id,
      fullName: staff.fullName,
      username: staff.username,
      passwordHash: staff.passwordHash,
      phoneNumber: staff.phoneNumber,
      position: staff.position,
      roleId: staff.roleId,
      permissionIds: staff.permissionIds,
      isActive: !staff.isActive,
      createdAt: staff.createdAt,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      createdBy: staff.createdBy,
      lastLoginAt: staff.lastLoginAt,
    );
    final index = staffBox.values.toList().indexOf(staff);
    staffBox.putAt(index, updated);
  }
}

class StaffCard extends StatelessWidget {
  final StaffUser staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  const StaffCard({
    Key? key,
    required this.staff,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        title: Text(staff.fullName),
        subtitle: Text('${staff.position} (${staff.username})'),
        trailing: PopupMenuButton(
          itemBuilder: (context) => [
            PopupMenuItem(
              onTap: onEdit,
              child: const Text('Edit'),
            ),
            PopupMenuItem(
              onTap: onToggle,
              child: Text(staff.isActive ? 'Disable' : 'Enable'),
            ),
            PopupMenuItem(
              onTap: onDelete,
              child: const Text('Delete'),
            ),
          ],
        ),
        leading: Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: staff.isActive ? Colors.green : Colors.red,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

class StaffFormDialog extends StatefulWidget {
  final StaffUser? staff;
  final List<Role> roles;
  final Function(StaffUser) onSave;

  const StaffFormDialog({
    Key? key,
    this.staff,
    required this.roles,
    required this.onSave,
  }) : super(key: key);

  @override
  State<StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends State<StaffFormDialog> {
  late TextEditingController fullNameController;
  late TextEditingController usernameController;
  late TextEditingController phoneController;
  late TextEditingController positionController;
  late TextEditingController passwordController;
  String? selectedRoleId;

  @override
  void initState() {
    super.initState();
    fullNameController = TextEditingController(text: widget.staff?.fullName ?? '');
    usernameController = TextEditingController(text: widget.staff?.username ?? '');
    phoneController = TextEditingController(text: widget.staff?.phoneNumber ?? '');
    positionController = TextEditingController(text: widget.staff?.position ?? '');
    passwordController = TextEditingController();
    selectedRoleId = widget.staff?.roleId ?? widget.roles.firstOrNull?.id;
  }

  @override
  void dispose() {
    fullNameController.dispose();
    usernameController.dispose();
    phoneController.dispose();
    positionController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.staff == null ? 'Add Staff' : 'Edit Staff'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: fullNameController,
              decoration: const InputDecoration(labelText: 'Full Name'),
            ),
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(labelText: 'Phone'),
            ),
            TextField(
              controller: positionController,
              decoration: const InputDecoration(labelText: 'Position'),
            ),
            if (widget.staff == null)
              TextField(
                controller: passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
              ),
            DropdownButton<String>(
              value: selectedRoleId,
              items: widget.roles
                  .map((r) => DropdownMenuItem(value: r.id, child: Text(r.name)))
                  .toList(),
              onChanged: (value) => setState(() => selectedRoleId = value),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (fullNameController.text.isEmpty ||
                usernameController.text.isEmpty ||
                selectedRoleId == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please fill all fields')),
              );
              return;
            }

            final now = DateTime.now().millisecondsSinceEpoch;
            final passwordHash = widget.staff != null
                ? widget.staff!.passwordHash
                : PasswordService.hashPassword(
                    passwordController.text.isEmpty ? 'password123' : passwordController.text);

            final newStaff = StaffUser(
              id: widget.staff?.id ?? LocalDb.genId(),
              fullName: fullNameController.text,
              username: usernameController.text,
              passwordHash: passwordHash,
              phoneNumber: phoneController.text,
              position: positionController.text,
              roleId: selectedRoleId!,
              isActive: widget.staff?.isActive ?? true,
              createdAt: widget.staff?.createdAt ?? now,
              updatedAt: now,
              createdBy: widget.staff?.createdBy ?? 'admin',
              lastLoginAt: widget.staff?.lastLoginAt,
            );

            widget.onSave(newStaff);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
