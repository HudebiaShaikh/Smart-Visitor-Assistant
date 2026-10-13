import 'package:flutter/material.dart';

import 'app_scope.dart';
import 'app_state.dart';
import 'screens/alerts_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/visitors_screen.dart';
import 'theme.dart';
import 'widgets/alert_overlay.dart';
import 'widgets/brand_logo.dart';
import 'widgets/control_panel.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const VisitorApp());
}

class VisitorApp extends StatefulWidget {
  const VisitorApp({super.key});

  @override
  State<VisitorApp> createState() => _VisitorAppState();
}

class _VisitorAppState extends State<VisitorApp> {
  final AppState _state = AppState();

  @override
  void initState() {
    super.initState();
    _state.init();
  }

  @override
  void dispose() {
    _state.dispose();
    super.dispose();
  }

  ThemeData _theme(bool highContrast) => buildAppTheme(highContrast: highContrast);

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: _state,
      child: ListenableBuilder(
        listenable: _state,
        builder: (context, _) {
          return MaterialApp(
            title: 'Smart Visitor Assistant',
            debugShowCheckedModeBanner: false,
            theme: _theme(_state.highContrast),
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              final overlay = _state.overlay;
              return MediaQuery(
                data: mq.copyWith(textScaler: TextScaler.linear(_state.textScale)),
                child: Stack(children: [
                  child ?? const SizedBox.shrink(),
                  if (overlay != null) Positioned.fill(child: AlertOverlay(key: ValueKey(overlay.id), alert: overlay)),
                ]),
              );
            },
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  static const _titles = ['Home', 'Alerts', 'Visitors', 'Settings'];
  static const _pages = <Widget>[DashboardScreen(), AlertsScreen(), VisitorsScreen(), SettingsScreen()];

  void _select(int i) {
    setState(() => _index = i);
    // On narrow screens close the drawer after choosing.
    if (MediaQuery.of(context).size.width < 900) _scaffoldKey.currentState?.closeDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final s = AppScope.of(context);
    final wide = MediaQuery.of(context).size.width >= 900;

    final sidebar = _Sidebar(
      index: _index,
      unread: s.unread,
      pending: s.pending,
      connected: s.connected,
      mode: s.mode,
      onSelect: _select,
    );

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Brand.bg,
      // On wide screens the sidebar is fixed; on narrow screens it is a drawer.
      drawer: wide ? null : Drawer(child: sidebar),
      body: SafeArea(
        child: Row(children: [
          if (wide) sidebar,
          Expanded(
            child: Column(children: [
              _TopBar(
                title: _titles[_index],
                connected: s.connected,
                onMenu: wide ? null : () => _scaffoldKey.currentState?.openDrawer(),
              ),
              if (!s.connected && !s.loading)
                Material(
                  color: Brand.squidInk,
                  child: InkWell(
                    onTap: s.refresh,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(children: [
                        const Icon(Icons.wifi_off, color: Brand.orange),
                        const SizedBox(width: 10),
                        Expanded(child: Text('${s.error ?? 'Not connected'}  Tap to retry.', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600))),
                        const Icon(Icons.refresh, color: Brand.orange),
                      ]),
                    ),
                  ),
                ),
              Expanded(
                child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  // Main content area
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0.03, 0), end: Offset.zero).animate(anim),
                          child: child,
                        ),
                      ),
                      child: s.loading
                          ? const Center(child: CircularProgressIndicator(color: Brand.orange))
                          : KeyedSubtree(key: ValueKey(_index), child: _pages[_index]),
                    ),
                  ),
                  // Right side: live camera + device controls (wide screens only)
                  if (wide) const SizedBox(width: 360, child: ControlPanel()),
                ]),
              ),
              if (!wide) _BottomNav(index: _index, unread: s.unread, pending: s.pending, onSelect: _select),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Top header bar for the content area (title + connection status + menu button).
class _TopBar extends StatelessWidget {
  final String title;
  final bool connected;
  final VoidCallback? onMenu;
  const _TopBar({required this.title, required this.connected, this.onMenu});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: Brand.surface,
        border: Border(bottom: BorderSide(color: Brand.divider)),
      ),
      child: Row(children: [
        if (onMenu != null)
          IconButton(icon: const Icon(Icons.menu, color: Brand.textPrimary), onPressed: onMenu, tooltip: 'Menu')
        else
          const SizedBox(width: 12),
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        const Spacer(),
        _ConnPill(connected: connected),
        const SizedBox(width: 16),
      ]),
    );
  }
}

class _ConnPill extends StatelessWidget {
  final bool connected;
  const _ConnPill({required this.connected});

  @override
  Widget build(BuildContext context) {
    final c = connected ? Brand.low : Brand.critical;
    return Semantics(
      label: connected ? 'Connected to server' : 'Not connected',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: 0.4)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(connected ? 'Online' : 'Offline', style: TextStyle(color: c, fontWeight: FontWeight.w700)),
        ]),
      ),
    );
  }
}

/// Left navigation sidebar, like a website's side menu.
class _Sidebar extends StatelessWidget {
  final int index;
  final int unread;
  final int pending;
  final bool connected;
  final String mode;
  final ValueChanged<int> onSelect;
  const _Sidebar({
    required this.index,
    required this.unread,
    required this.pending,
    required this.connected,
    required this.mode,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      decoration: const BoxDecoration(gradient: Brand.headerGradient),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            const BrandMark(size: 34),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Smart Visitor', style: Theme.of(context).textTheme.titleMedium!.copyWith(color: Colors.white)),
                Text('Assistant', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white70)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('MENU', style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.white54, letterSpacing: 1.5, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(height: 8),
        _NavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Home', selected: index == 0, onTap: () => onSelect(0)),
        _NavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Alerts', selected: index == 1, badge: unread, onTap: () => onSelect(1)),
        _NavItem(icon: Icons.people_outline, activeIcon: Icons.people, label: 'Visitors', selected: index == 2, badge: pending, onTap: () => onSelect(2)),
        _NavItem(icon: Icons.settings_outlined, activeIcon: Icons.settings, label: 'Settings', selected: index == 3, onTap: () => onSelect(3)),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(14)),
            child: Row(children: [
              Icon(connected ? Icons.cloud_done : Icons.cloud_off, color: connected ? Brand.orangeLight : const Color(0xFFFF9A9A)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  connected ? (mode.isEmpty ? 'Connected' : '$mode mode') : 'Offline',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
            ]),
          ),
        ),
        const SizedBox(height: 8),
      ]),
    );
  }
}

/// One interactive entry inside the left sidebar.

/// One interactive entry inside the left sidebar.
class _NavItem extends StatefulWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool selected;
  final int badge;
  final VoidCallback onTap;
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.selected;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Semantics(
          button: true,
          selected: active,
          label: widget.label + (widget.badge > 0 ? ', ${widget.badge} new' : ''),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              decoration: BoxDecoration(
                color: active ? Brand.orange : (_hover ? Colors.white.withValues(alpha: 0.10) : Colors.transparent),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Icon(active ? widget.activeIcon : widget.icon, color: active ? Brand.squidInk : Colors.white, size: 22),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(widget.label,
                      style: TextStyle(
                          color: active ? Brand.squidInk : Colors.white,
                          fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 15.5)),
                ),
                if (widget.badge > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: active ? Brand.squidInk : Brand.orange,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('${widget.badge}',
                        style: TextStyle(
                            color: active ? Colors.white : Brand.squidInk, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom navigation for narrow (phone) screens.
class _BottomNav extends StatelessWidget {
  final int index;
  final int unread;
  final int pending;
  final ValueChanged<int> onSelect;
  const _BottomNav({required this.index, required this.unread, required this.pending, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: index,
      onDestinationSelected: onSelect,
      destinations: [
        const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
        NavigationDestination(
          icon: _BadgedIcon(icon: Icons.notifications_outlined, count: unread),
          selectedIcon: _BadgedIcon(icon: Icons.notifications, count: unread),
          label: 'Alerts',
        ),
        NavigationDestination(
          icon: _BadgedIcon(icon: Icons.people_outline, count: pending),
          selectedIcon: _BadgedIcon(icon: Icons.people, count: pending),
          label: 'Visitors',
        ),
        const NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }
}

class _BadgedIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  const _BadgedIcon({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return Icon(icon);
    return Badge(label: Text('$count'), child: Icon(icon));
  }
}

