import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/shared_widgets.dart';
import '../../../models/app_user.dart';
import '../providers/users_provider.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(usersStreamProvider);

    return Padding(
      padding: const EdgeInsets.all(AppConstants.contentPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PageHeader(
            title: AppStrings.usersTitle,
            subtitle: 'إدارة حسابات الموظفين والمسؤولين',
            action: ElevatedButton.icon(
              onPressed: () => showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) => const UserFormDialog(),
              ),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text(AppStrings.addUser),
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: usersAsync.when(
              loading: () => const LoadingWidget(),
              error: (e, _) => EmptyStateWidget(
                  message: '${AppStrings.error}: $e',
                  icon: Icons.error_outline),
              data: (users) => users.isEmpty
                  ? const EmptyStateWidget(
                      message: 'لا يوجد مستخدمون',
                      icon: Icons.people_outline,
                    )
                  : _UsersTable(users: users),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Users Table ───────────────────────────────────────────────────────────────

class _UsersTable extends StatelessWidget {
  final List<AppUser> users;
  const _UsersTable({required this.users});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          child: DataTable(
            columnSpacing: 24,
            horizontalMargin: 20,
            columns: const [
              DataColumn(label: Text(AppStrings.userName)),
              DataColumn(label: Text(AppStrings.userEmail)),
              DataColumn(label: Text(AppStrings.userRole)),
              DataColumn(label: Text(AppStrings.createdAt)),
            ],
            rows: users.map((user) {
              final isAdmin = user.role == AppConstants.roleAdmin;
              return DataRow(
                cells: [
                  DataCell(Row(
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor:
                            AppColors.primaryContainer,
                        child: Text(
                          user.name.isNotEmpty
                              ? user.name[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(user.name,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  )),
                  DataCell(Text(user.email,
                      style: const TextStyle(
                          color: AppColors.onSurfaceMuted, fontSize: 13))),
                  DataCell(_RoleBadge(isAdmin: isAdmin)),
                  DataCell(Text(
                    DateFormatter.formatDate(user.createdAt),
                    style: const TextStyle(
                        color: AppColors.onSurfaceMuted, fontSize: 13),
                  )),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final bool isAdmin;
  const _RoleBadge({required this.isAdmin});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isAdmin
            ? AppColors.primaryContainer
            : AppColors.info.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isAdmin
              ? AppColors.primary.withOpacity(0.4)
              : AppColors.info.withOpacity(0.4),
        ),
      ),
      child: Text(
        isAdmin ? AppStrings.roleAdmin : AppStrings.roleStandard,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isAdmin ? AppColors.primaryLight : AppColors.info,
        ),
      ),
    );
  }
}

// ── User Form Dialog ──────────────────────────────────────────────────────────

class UserFormDialog extends ConsumerStatefulWidget {
  const UserFormDialog({super.key});

  @override
  ConsumerState<UserFormDialog> createState() => _UserFormDialogState();
}

class _UserFormDialogState extends ConsumerState<UserFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _selectedRole = AppConstants.roleStandard;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(usersNotifierProvider.notifier).createUser(
          email: _emailController.text,
          password: _passwordController.text,
          name: _nameController.text,
          role: _selectedRole,
        );

    final state = ref.read(usersNotifierProvider);
    if (mounted) {
      if (state.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('${AppStrings.userCreatedError}: ${state.error}'),
          backgroundColor: AppColors.error,
        ));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(AppStrings.userCreatedSuccess),
          backgroundColor: AppColors.success,
        ));
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(usersNotifierProvider).isLoading;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
            maxWidth: AppConstants.dialogMaxWidth, maxHeight: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  AppStrings.addUser,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 20),
                _buildField(_nameController, AppStrings.userName,
                    Icons.person_outline),
                const SizedBox(height: 12),
                _buildField(
                  _emailController,
                  AppStrings.userEmail,
                  Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.requiredField;
                    if (!v.contains('@')) return AppStrings.invalidEmail;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.onSurface),
                  decoration: InputDecoration(
                    labelText: AppStrings.userPassword,
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppColors.onSurfaceMuted, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.onSurfaceMuted,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return AppStrings.requiredField;
                    if (v.length < 6) return AppStrings.setupPasswordTooShort;
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                // Role selector
                DropdownButtonFormField<String>(
                  initialValue: _selectedRole,
                  style: const TextStyle(color: AppColors.onSurface),
                  dropdownColor: AppColors.surfaceElevated,
                  decoration: const InputDecoration(
                    labelText: AppStrings.userRole,
                    prefixIcon: Icon(Icons.badge_outlined,
                        color: AppColors.onSurfaceMuted, size: 18),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: AppConstants.roleStandard,
                        child: const Text(AppStrings.roleStandard)),
                    DropdownMenuItem(
                        value: AppConstants.roleAdmin,
                        child: const Text(AppStrings.roleAdmin)),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedRole = v ?? _selectedRole),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(AppStrings.cancel),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: isLoading ? null : _submit,
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.onPrimary))
                          : const Text(AppStrings.add),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.onSurface),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.onSurfaceMuted, size: 18),
      ),
      validator: validator ??
          (v) => (v == null || v.trim().isEmpty)
              ? AppStrings.requiredField
              : null,
    );
  }
}
