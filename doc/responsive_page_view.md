# Responsive Page View Documentation

This document provides comprehensive documentation for building responsive pages in PrivacyGUI using the UI Kit library's page view system.

## Architecture Overview

The responsive page system consists of three main layers:

```
┌─────────────────────────────────────────────────────────────┐
│                    UiKitPageView                            │
│              (PrivacyGUI Wrapper Layer)                     │
├─────────────────────────────────────────────────────────────┤
│                     AppPageView                             │
│                  (UI Kit Core Layer)                        │
├─────────────────────────────────────────────────────────────┤
│   Layout Extensions  │  AppResponsiveLayout  │  Providers   │
│    (Grid System)     │  (Responsive Builder) │  (Config)    │
└─────────────────────────────────────────────────────────────┘
```

---

## 1. UiKitPageView (PrivacyGUI Wrapper)

**File:** `lib/page/components/ui_kit_page_view.dart`

`UiKitPageView` is the PrivacyGUI-specific page container that wraps UI Kit's `AppPageView` with native PrivacyGUI integrations.

### Key Features

| Feature | Description |
|---------|-------------|
| TopBar Integration | Automatically handles PrivacyGUI's `TopBar` component |
| Bottom Bar | Configurable Save/Cancel button bar |
| Menu System | Responsive sidebar/menu configuration |
| Tabs Support | Built-in tabbed interface |
| Sliver Mode | Supports collapsible AppBar |

### Factory Constructors

```dart
// Standard page with full configuration
UiKitPageView(...)

// Inner page (no TopBar/AppBar) - for nested views
UiKitPageView.innerPage(...)

// Sliver mode page - for collapsible scrolling
UiKitPageView.withSliver(...)
```

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `title` | `String?` | Page title displayed in AppBar |
| `child` | `Widget Function(BuildContext, BoxConstraints)?` | Content builder with constraints |
| `appBarStyle` | `UiKitAppBarStyle` | AppBar style: `none`, `back`, `close` |
| `backState` | `UiKitBackState` | Back button state: `none`, `enabled`, `disabled` |
| `bottomBar` | `UiKitBottomBarConfig?` | Bottom action bar configuration |
| `menu` | `UiKitMenuConfig?` | Menu configuration |
| `menuPosition` | `MenuPosition` | Menu position: `left`, `right`, `top`, `fab`, `none` |
| `menuView` | `PageMenuView?` | Custom menu view panel |
| `tabs` | `List<Widget>?` | Tab widgets |
| `tabContentViews` | `List<Widget>?` | Tab content views |
| `tabController` | `TabController?` | Tab controller |
| `topbar` | `Widget?` | Custom TopBar widget |
| `hideTopbar` | `bool` | Hide TopBar (default: `false`) |
| `scrollable` | `bool?` | Enable scrolling |
| `padding` | `EdgeInsets?` | Additional padding |
| `useMainPadding` | `bool` | Apply grid margins (default: `true`) |
| `enableSliverAppBar` | `bool` | Use sliver layout |
| `pageFooter` | `Widget?` | Custom footer widget |

---

## 2. AppPageView (UI Kit Core)

**File:** `ui_kit/lib/src/layout/app_page_view.dart`

The core page container providing comprehensive responsive page architecture.

### Factory Methods

```dart
// Simple page with title and content
AppPageView.basic(title: 'Settings', child: content)

// Page with bottom action bar
AppPageView.withBottomBar(
  title: 'Edit Profile',
  child: ProfileForm(),
  positiveLabel: 'Save',
  onPositiveTap: () => _save(),
)

// Page with responsive menu
AppPageView.withMenu(
  title: 'Dashboard',
  child: content,
  menuTitle: 'Navigation',
  menuItems: [...],
)

// Page with tabbed navigation
AppPageView.withTabs(
  title: 'Settings',
  tabs: [Tab(text: 'General'), Tab(text: 'Privacy')],
  tabViews: [GeneralSettings(), PrivacySettings()],
)

// Page with custom slivers
AppPageView.withSlivers(
  title: 'Products',
  slivers: [SliverGrid(...), SliverList(...)],
)
```

---

## 3. Tab Navigation

Tabs organize multiple related content views within a single page.

### Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `tabs` | `List<Widget>?` | Tab label widgets |
| `tabContentViews` | `List<Widget>?` | Corresponding content views |
| `tabController` | `TabController?` | Controller (requires `SingleTickerProviderStateMixin`) |
| `onTabTap` | `void Function(int)?` | Tab tap callback |
| `isTabScrollable` | `bool` | Enable horizontal scrolling for tabs |

### Example

```dart
class _MyViewState extends ConsumerState<MyView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UiKitPageView.withSliver(
      title: 'Settings',
      tabController: _tabController,
      tabs: [
        _buildTab('Host Name', selected: _selectedTabIndex == 0),
        _buildTab('IP Address', selected: _selectedTabIndex == 1),
        _buildTab('DHCP Server', selected: _selectedTabIndex == 2),
      ],
      tabContentViews: [
        HostNameView(),
        IPAddressView(),
        DHCPServerView(),
      ],
      onTabTap: (index) => setState(() => _selectedTabIndex = index),
      bottomBar: UiKitBottomBarConfig(
        isPositiveEnabled: isDirty && !hasError,
        onPositiveTap: _saveSettings,
      ),
    );
  }

  Widget _buildTab(String title, {required bool selected, bool hasError = false}) {
    return Tab(
      child: Row(
        children: [
          if (hasError) ...[
            Icon(AppFontIcons.error, color: Theme.of(context).colorScheme.error),
            AppGap.xs(),
          ],
          AppText.titleSmall(
            title,
            color: selected ? Theme.of(context).colorScheme.primary : null,
          ),
        ],
      ),
    );
  }
}
```

---

## 4. Bottom Bar Configuration

The bottom action bar provides Save/Cancel buttons for form pages.

### UiKitBottomBarConfig

```dart
class UiKitBottomBarConfig {
  final String? positiveLabel;      // Primary button text (default: "Save")
  final String? negativeLabel;      // Secondary button text (e.g., "Cancel")
  final VoidCallback? onPositiveTap;
  final VoidCallback? onNegativeTap;
  final bool isPositiveEnabled;     // Default: true
  final bool isNegativeEnabled;     // Default: true
  final bool isDestructive;         // Use danger button style
}
```

### Examples

```dart
// Basic save button
UiKitPageView(
  bottomBar: UiKitBottomBarConfig(
    isPositiveEnabled: notifier.isDirty() && !hasError,
    onPositiveTap: _saveSettings,
  ),
  child: (ctx, constraints) => SettingsForm(),
)

// With cancel button
UiKitPageView(
  bottomBar: UiKitBottomBarConfig(
    positiveLabel: 'Update',
    negativeLabel: 'Cancel',
    isPositiveEnabled: isFormValid,
    onPositiveTap: () async {
      await _save();
      context.pop();
    },
    onNegativeTap: () => context.pop(),
  ),
  child: (ctx, constraints) => ProfileForm(),
)

// Destructive action
UiKitPageView(
  bottomBar: UiKitBottomBarConfig(
    positiveLabel: 'Delete',
    negativeLabel: 'Cancel',
    isDestructive: true,  // Button displays in red
    onPositiveTap: _deleteAccount,
    onNegativeTap: () => context.pop(),
  ),
  child: (ctx, constraints) => DeleteConfirmation(),
)
```

---

## 5. Menu System

The menu system provides responsive navigation that adapts to screen size.

### Menu Position Options

```dart
enum MenuPosition {
  left,   // Sidebar on left (Desktop)
  right,  // Sidebar on right (Desktop)
  top,    // Items in AppBar
  fab,    // FloatingActionButton
  none,   // No menu
}
```

### Behavior Matrix

| Position | Desktop | Mobile/Tablet |
|----------|---------|---------------|
| `left` | Left sidebar | AppBar actions or popup menu |
| `right` | Right sidebar | AppBar actions or popup menu |
| `top` | AppBar actions | AppBar actions or popup menu |
| `fab` | FAB + Sidebar (menuView) | Expandable FAB |
| `none` | No menu | No menu |

### Sidebar Layout

- **Standard Menu**: Sidebar occupies 3 columns, Content occupies 9 columns
- **Large Menu** (`largeMenu: true`): Sidebar occupies 4 columns, Content occupies 8 columns

### UiKitMenuConfig

```dart
class UiKitMenuConfig {
  final String title;               // Menu title (shown in sidebar header)
  final List<UiKitMenuItem> items;  // Menu items
  final bool largeMenu;             // Use large menu (4 cols vs 3 cols)
}

class UiKitMenuItem {
  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool isSelected;
}
```

### PageMenuView (Custom Menu Panel)

Used to display fully custom menu content (e.g., user profile panel).

```dart
class PageMenuView {
  final IconData icon;    // Trigger button icon
  final String label;     // Accessibility label
  final Widget content;   // Actual content widget
}
```

**Behavior:**
- **Desktop (left/right)**: Content displays in sidebar
- **Mobile**: Tap trigger button shows BottomSheet
- **FAB mode**: Appears as a FAB menu item

### Menu Examples

**Navigation Menu**

```dart
UiKitPageView(
  title: 'Dashboard',
  menuPosition: MenuPosition.left,
  menu: UiKitMenuConfig(
    title: 'Navigation',
    items: [
      UiKitMenuItem(
        label: 'Overview',
        icon: Icons.dashboard,
        onTap: () => context.go('/overview'),
        isSelected: currentRoute == '/overview',
      ),
      UiKitMenuItem(
        label: 'Settings',
        icon: Icons.settings,
        onTap: () => context.go('/settings'),
      ),
    ],
  ),
  child: (ctx, constraints) => DashboardContent(),
)
```

**User Profile Panel + Action Buttons**

```dart
UiKitPageView(
  title: 'Account',
  menuPosition: MenuPosition.left,
  menuView: PageMenuView(
    icon: Icons.account_circle,
    label: 'User Profile',
    content: Column(
      children: [
        CircleAvatar(radius: 40, child: Icon(Icons.person)),
        AppText.headlineSmall(user.name),
        AppButton.secondary(label: 'Logout', onTap: _logout),
      ],
    ),
  ),
  menu: UiKitMenuConfig(
    items: [
      UiKitMenuItem(label: 'Edit', icon: Icons.edit, onTap: _edit),
      UiKitMenuItem(label: 'Share', icon: Icons.share, onTap: _share),
    ],
  ),
  child: (ctx, constraints) => AccountContent(),
)
```

---

## 6. Responsive Layout Utilities

### AppResponsiveLayout

A widget that adapts its child based on screen size.

```dart
AppResponsiveLayout(
  mobile: (context) => MobileWidget(),
  desktop: (context) => DesktopWidget(width: context.colWidth(8)),
  tablet: (context) => TabletWidget(),  // Optional, defaults to desktop
)
```

### Layout Context Extensions

```dart
// Screen type checks
if (context.isMobileLayout) { ... }
if (context.isTabletLayout) { ... }
if (context.isDesktopLayout) { ... }

// Responsive value selection
final padding = context.responsive<double>(
  mobile: 8.0,
  tablet: 16.0,
  desktop: 24.0,
);

// Grid calculations
final colWidth = context.colWidth(6);   // 6-column span width
final splitWidth = context.split(3);    // Split into 3 equal parts
final margin = context.pageMargin;      // Current page margin
final gutter = context.currentGutter;   // Current gutter width
final cols = context.currentMaxColumns; // Mobile:4, Tablet:8, Desktop:12
```

### Breakpoints (Default)

| Type | Width |
|------|-------|
| Mobile | <= 744.0 |
| Tablet | 744.0 - 1200.0 |
| Desktop | > 1200.0 |
| Desktop Large | > 1440.0 |
| Desktop Extra Large | > 1680.0 |

---

## 7. Complete Usage Examples

### Basic Responsive Page

```dart
class MyResponsivePage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return UiKitPageView(
      title: 'My Page',
      appBarStyle: UiKitAppBarStyle.back,
      child: (context, constraints) {
        return AppResponsiveLayout(
          mobile: (ctx) => _buildMobileLayout(ctx),
          desktop: (ctx) => _buildDesktopLayout(ctx),
        );
      },
    );
  }
  
  Widget _buildMobileLayout(BuildContext context) {
    return Column(children: [...]);
  }
  
  Widget _buildDesktopLayout(BuildContext context) {
    return Row(
      children: [
        SizedBox(width: context.colWidth(4), child: SidePanel()),
        Expanded(child: MainContent()),
      ],
    );
  }
}
```

### Form Page with Tabs

```dart
class SettingsView extends ConsumerStatefulWidget {
  @override
  ConsumerState<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends ConsumerState<SettingsView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return UiKitPageView.withSliver(
      title: loc(context).settings,
      tabController: _tabController,
      tabs: [
        Tab(text: 'General'),
        Tab(text: 'Advanced'),
        Tab(text: 'Privacy'),
      ],
      tabContentViews: [
        GeneralSettingsTab(),
        AdvancedSettingsTab(),
        PrivacySettingsTab(),
      ],
      bottomBar: UiKitBottomBarConfig(
        isPositiveEnabled: isDirty && isValid,
        onPositiveTap: _save,
      ),
    );
  }
}
```

### Dashboard with Navigation Sidebar

```dart
class DashboardPage extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentRoute = ref.watch(currentRouteProvider);
    
    return UiKitPageView(
      title: 'Dashboard',
      menuPosition: MenuPosition.left,
      largeMenu: false,
      menu: UiKitMenuConfig(
        title: 'Navigation',
        items: [
          UiKitMenuItem(
            label: 'Overview',
            icon: Icons.dashboard,
            onTap: () => context.go('/dashboard/overview'),
            isSelected: currentRoute == '/dashboard/overview',
          ),
          UiKitMenuItem(
            label: 'Devices',
            icon: Icons.devices,
            onTap: () => context.go('/dashboard/devices'),
            isSelected: currentRoute == '/dashboard/devices',
          ),
          UiKitMenuItem(
            label: 'Settings',
            icon: Icons.settings,
            onTap: () => context.go('/settings'),
          ),
        ],
      ),
      child: (context, constraints) => CurrentPageContent(),
    );
  }
}
```

---

## 8. Related Files

### PrivacyGUI
- `lib/page/components/ui_kit_page_view.dart` - UiKitPageView wrapper

### UI Kit Library
- `lib/src/layout/app_page_view.dart` - Core AppPageView
- `lib/src/layout/app_responsive_layout.dart` - AppResponsiveLayout
- `lib/src/layout/layout_extensions.dart` - Grid system extensions
- `lib/src/layout/models/page_app_bar_config.dart` - AppBar configuration
- `lib/src/layout/models/page_bottom_bar_config.dart` - BottomBar configuration
- `lib/src/layout/models/page_menu_config.dart` - Menu configuration
- `lib/src/layout/models/page_menu_item.dart` - Menu item and MenuPosition
- `lib/src/layout/models/page_menu_view.dart` - Custom menu view panel
- `lib/src/layout/widgets/page_sidebar.dart` - Sidebar widget
- `lib/src/layout/widgets/page_bottom_bar.dart` - BottomBar widget
- `lib/src/layout/widgets/page_menu_content.dart` - Menu content widget
- `lib/src/layout/renderers/menu_position_renderer.dart` - Menu position renderers
- `lib/src/foundation/config/app_layout_provider.dart` - Layout configuration provider
