import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_constants.dart';
import '../constants/app_strings.dart';
import '../../app/router.dart';
import '../../features/auth/providers/auth_provider.dart';

class AppScaffold extends ConsumerWidget {
  final Widget child;
  const AppScaffold({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAdmin = ref.watch(isAdminProvider);
    final currentUser = ref.watch(currentAppUserProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Row(
        children: [
          // Sidebar (right side in RTL — Directionality handles this)
          AppSidebar(isAdmin: isAdmin, currentUser: currentUser),
          // Vertical divider
          const VerticalDivider(width: 1, thickness: 1, color: AppColors.divider),
          // Main content area
          Expanded(child: child),
        ],
      ),
    );
  }
}

class AppSidebar extends ConsumerStatefulWidget {
  final bool isAdmin;
  final dynamic currentUser;
  const AppSidebar({super.key, required this.isAdmin, this.currentUser});

  @override
  ConsumerState<AppSidebar> createState() => _AppSidebarState();
}

class _AppSidebarState extends ConsumerState<AppSidebar> {
  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    final navItems = _buildNavItems();

    return Container(
      width: AppConstants.sidebarWidth,
      color: AppColors.sidebarBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Brand header
          _buildSidebarHeader(),
          const Divider(height: 1, color: AppColors.sidebarBorder),
          const SizedBox(height: 8),
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              children: navItems
                  .map((item) => _NavItem(
                        item: item,
                        isActive: location == item.route,
                        onTap: () => context.go(item.route),
                      ))
                  .toList(),
            ),
          ),
          const Divider(height: 1, color: AppColors.sidebarBorder),
          // User info + Logout
          _buildUserFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryLight, AppColors.primaryDark],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.water_drop_rounded,
                color: AppColors.onPrimary, size: 20),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.appName,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              Text(
                widget.isAdmin ? AppStrings.roleAdmin : AppStrings.roleStandard,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserFooter() {
    final user = widget.currentUser;
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.primaryContainer,
                child: Text(
                  user?.name.isNotEmpty == true
                      ? user!.name[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                    color: AppColors.primaryLight,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? '',
                      style: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      user?.email ?? '',
                      style: const TextStyle(
                        color: AppColors.onSurfaceMuted,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              onPressed: () async {
                await ref.read(authNotifierProvider.notifier).signOut();
              },
              icon: const Icon(Icons.logout_rounded,
                  size: 16, color: AppColors.error),
              label: Text(
                AppStrings.navLogout,
                style: const TextStyle(color: AppColors.error, fontSize: 13),
              ),
              style: TextButton.styleFrom(
                alignment: AlignmentDirectional.centerStart,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<_NavItemData> _buildNavItems() {
    return [
      if (widget.isAdmin)
        const _NavItemData(
          label: AppStrings.navDashboard,
          icon: Icons.dashboard_outlined,
          activeIcon: Icons.dashboard_rounded,
          route: AppRoutes.dashboard,
        ),
      const _NavItemData(
        label: AppStrings.navPos,
        icon: Icons.point_of_sale_outlined,
        activeIcon: Icons.point_of_sale_rounded,
        route: AppRoutes.pos,
      ),
      const _NavItemData(
        label: AppStrings.navOrderHistory,
        icon: Icons.receipt_long_outlined,
        activeIcon: Icons.receipt_long_rounded,
        route: AppRoutes.orders,
      ),
      const _NavItemData(
        label: AppStrings.navProducts,
        icon: Icons.inventory_2_outlined,
        activeIcon: Icons.inventory_2_rounded,
        route: AppRoutes.products,
      ),
      if (widget.isAdmin)
        const _NavItemData(
          label: AppStrings.navUsers,
          icon: Icons.people_outline_rounded,
          activeIcon: Icons.people_rounded,
          route: AppRoutes.users,
        ),
      if (widget.isAdmin)
        const _NavItemData(
          label: AppStrings.navReports,
          icon: Icons.analytics_outlined,
          activeIcon: Icons.analytics_rounded,
          route: AppRoutes.reports,
        ),
    ];
  }
}

class _NavItemData {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  final String route;
  const _NavItemData({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.route,
  });
}

class _NavItem extends StatefulWidget {
  final _NavItemData item;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.item,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isActive
        ? AppColors.sidebarActive
        : _hovered
            ? AppColors.surfaceHighlight.withValues(alpha: 0.4)
            : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: widget.isActive
              ? Border.all(color: AppColors.primary.withValues(alpha: 0.3))
              : null,
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            child: Row(
              children: [
                Icon(
                  widget.isActive ? widget.item.activeIcon : widget.item.icon,
                  size: 20,
                  color: widget.isActive
                      ? AppColors.primary
                      : AppColors.onSurfaceMuted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.item.label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: widget.isActive
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: widget.isActive
                          ? AppColors.onSurface
                          : AppColors.onSurfaceMuted,
                    ),
                  ),
                ),
                if (widget.isActive)
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
