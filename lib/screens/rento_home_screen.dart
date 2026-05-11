import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/room.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../utils/app_theme.dart';
import '../utils/constants.dart';
import '../utils/django_api.dart';
import '../widgets/app_logo.dart';
import '../widgets/room_card.dart';
import 'add_room_screen.dart';
import 'room_details.dart';

class RentoHomeScreen extends StatefulWidget {
  const RentoHomeScreen({super.key});

  @override
  State<RentoHomeScreen> createState() => _RentoHomeScreenState();
}

class _RentoHomeScreenState extends State<RentoHomeScreen> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _notifications = [];
  List<Room> _savedRooms = [];
  bool _isLoadingSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomProvider>().loadRooms();
      _loadNotifications();
      _loadSavedRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 76,
        titleSpacing: 16,
        title: Row(
          children: [
            const AppLogo(height: 42),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    'Rento',
                    style: TextStyle(
                      color: AppColors.ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Rooms that feel right',
                    style: TextStyle(
                      color: AppColors.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.line),
                    boxShadow: AppShadows.soft,
                  ),
                  child: IconButton(
                    tooltip: 'Notifications',
                    onPressed: _showNotifications,
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.ink,
                    ),
                  ),
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        border: Border.all(color: Colors.white, width: 1.5),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final offset = Tween<Offset>(
            begin: const Offset(0.035, 0),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: offset, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey(_selectedIndex),
          child: [
            _HomeTab(onListRoom: _openAddRoom, onRoomTap: _openRoomDetails),
            _RoomListTab(
              variant: _TabSurfaceVariant.listings,
              title: 'My Listings',
              subtitle: 'Manage rooms you have published',
              rooms: _myListings,
              emptyIcon: Icons.home_work_outlined,
              emptyTitle: 'No listings yet',
              emptySubtitle:
                  'List your first room and start receiving inquiries.',
              onRoomTap: _openRoomDetails,
              showOwnerActions: true,
              onEditRoom: _openEditRoom,
              onDeleteRoom: _deleteListing,
              onToggleAvailability: _toggleListingAvailability,
            ),
            _RoomListTab(
              variant: _TabSurfaceVariant.saved,
              title: 'Saved Rooms',
              subtitle: 'Your shortlisted places',
              rooms: _savedRooms,
              isLoading: _isLoadingSaved,
              emptyIcon: Icons.bookmark_border_rounded,
              emptyTitle: 'No saved rooms',
              emptySubtitle: 'Tap the bookmark on rooms you want to revisit.',
              onRoomTap: _openRoomDetails,
              onSaveTap: _toggleSavedRoom,
            ),
            _ProfileTab(
              onLogout: _logout,
              onOpenListings: () => setState(() => _selectedIndex = 1),
              onOpenSaved: () {
                setState(() => _selectedIndex = 2);
                _loadSavedRooms();
              },
            ),
          ][_selectedIndex],
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFFFFF), Color(0xFFF2F6FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          border: Border(top: BorderSide(color: Color(0xFFD7E3FF))),
          boxShadow: [
            BoxShadow(
              color: Color(0x142563EB),
              blurRadius: 18,
              offset: Offset(0, -8),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
            if (index == 2) _loadSavedRooms();
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.apartment_outlined),
              selectedIcon: Icon(Icons.apartment_rounded),
              label: 'Listings',
            ),
            NavigationDestination(
              icon: Icon(Icons.bookmark_border_rounded),
              selectedIcon: Icon(Icons.bookmark_rounded),
              label: 'Saved',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded),
              selectedIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }

  int get _unreadNotificationCount {
    return _notifications.where((item) => item['isRead'] != true).length;
  }

  List<Room> get _myListings {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return [];
    return context.watch<RoomProvider>().getRoomsByOwner(user.id);
  }

  Future<void> _loadNotifications() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    try {
      final notifications = await DjangoApi.getNotifications(user.id);
      if (mounted) setState(() => _notifications = notifications);
    } catch (e) {
      debugPrint('Load notifications error: $e');
    }
  }

  Future<void> _loadSavedRooms() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || _isLoadingSaved) return;

    setState(() => _isLoadingSaved = true);
    try {
      final savedItems = await DjangoApi.getSavedRooms(user.id);
      final rooms = savedItems
          .map((item) => item['room'])
          .whereType<Map<String, dynamic>>()
          .map(Room.fromJson)
          .toList();
      if (mounted) setState(() => _savedRooms = rooms);
    } catch (e) {
      debugPrint('Load saved rooms error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSaved = false);
    }
  }

  Future<void> _showNotifications() async {
    await _loadNotifications();
    if (!mounted) return;

    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                if (_notifications.isEmpty)
                  const _EmptyPanel(icon: Icons.notifications_none_rounded)
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _notifications.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = _notifications[index];
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(item['title']?.toString() ?? ''),
                          subtitle: Text(item['body']?.toString() ?? ''),
                          trailing: item['isRead'] == true
                              ? null
                              : const Icon(
                                  Icons.circle,
                                  size: 10,
                                  color: Color(0xFF2563EB),
                                ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openAddRoom() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const AddRoomScreen()));
    if (mounted) context.read<RoomProvider>().loadRooms();
  }

  Future<void> _openEditRoom(Room room) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => AddRoomScreen(initialRoom: room)),
    );
    if (mounted) context.read<RoomProvider>().loadRooms();
  }

  void _openRoomDetails(Room room) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => RoomDetails(room: room)));
  }

  Future<void> _toggleListingAvailability(Room room) async {
    final updatedRoom = room.copyWith(isAvailable: !room.isAvailable);
    try {
      await context.read<RoomProvider>().updateRoom(updatedRoom);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            updatedRoom.isAvailable
                ? 'Listing marked as available.'
                : 'Listing marked as booked.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to update listing: $e')));
    }
  }

  Future<void> _toggleSavedRoom(Room room) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;

    try {
      final result = await DjangoApi.toggleSavedRoom(user.id, room.id);
      await _loadSavedRooms();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update saved room: $e')),
      );
    }
  }

  Future<void> _deleteListing(Room room) async {
    final roomProvider = context.read<RoomProvider>();
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete listing?'),
          content: Text(
            'This will permanently remove "${room.title}" from your listed rooms.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    try {
      await roomProvider.deleteRoom(room.id);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Listing deleted.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to delete listing: $e')));
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (mounted) context.go('/login');
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab({required this.onListRoom, required this.onRoomTap});

  final VoidCallback onListRoom;
  final ValueChanged<Room> onRoomTap;

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final _searchController = TextEditingController();
  final _maxPriceController = TextEditingController();
  String _selectedCity = 'All';
  String _selectedRoomType = 'All';
  String _selectedAmenity = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    _maxPriceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rooms = context.watch<RoomProvider>().rooms;

    return SafeArea(
      top: false,
      child: _TabSurface(
        variant: _TabSurfaceVariant.home,
        child: RefreshIndicator(
          onRefresh: () => context.read<RoomProvider>().loadRooms(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            children: [
              const _HomeHero(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.search_rounded,
                      label: 'Find Rooms',
                      onPressed: _applyFilters,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionButton(
                      icon: Icons.add_home_work_outlined,
                      label: 'List Room',
                      onPressed: widget.onListRoom,
                      isSecondary: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _SearchPanel(
                searchController: _searchController,
                maxPriceController: _maxPriceController,
                selectedCity: _selectedCity,
                selectedRoomType: _selectedRoomType,
                selectedAmenity: _selectedAmenity,
                onCityChanged: (value) => setState(() => _selectedCity = value),
                onRoomTypeChanged: (value) =>
                    setState(() => _selectedRoomType = value),
                onAmenityChanged: (value) =>
                    setState(() => _selectedAmenity = value),
                onApply: _applyFilters,
                onClear: _clearFilters,
              ),
              const SizedBox(height: 18),
              _SectionHeader(
                title: 'Available rooms',
                subtitle: rooms.isEmpty
                    ? 'No matches yet'
                    : '${rooms.length} places near you',
              ),
              const SizedBox(height: 12),
              if (rooms.isEmpty)
                const _EmptyListingPanel()
              else
                ...rooms.map(
                  (room) => RoomCard(
                    room: room,
                    onTap: () => widget.onRoomTap(room),
                    onSaveTap: () => _toggleSaved(room),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyFilters() async {
    FocusScope.of(context).unfocus();
    await context.read<RoomProvider>().loadRooms(
      query: _searchController.text,
      city: _selectedCity,
      roomType: _selectedRoomType,
      maxPrice: double.tryParse(_maxPriceController.text.trim()),
      amenity: _selectedAmenity,
    );
  }

  Future<void> _clearFilters() async {
    _searchController.clear();
    _maxPriceController.clear();
    setState(() {
      _selectedCity = 'All';
      _selectedRoomType = 'All';
      _selectedAmenity = 'All';
    });
    await context.read<RoomProvider>().loadRooms();
  }

  Future<void> _toggleSaved(Room room) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) return;
    try {
      final result = await DjangoApi.toggleSavedRoom(user.id, room.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']?.toString() ?? 'Updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to save room: $e')));
    }
  }
}

class _RoomListTab extends StatelessWidget {
  const _RoomListTab({
    required this.variant,
    required this.title,
    required this.subtitle,
    required this.rooms,
    required this.emptyIcon,
    required this.emptyTitle,
    required this.emptySubtitle,
    required this.onRoomTap,
    this.isLoading = false,
    this.showOwnerActions = false,
    this.onEditRoom,
    this.onDeleteRoom,
    this.onToggleAvailability,
    this.onSaveTap,
  });

  final _TabSurfaceVariant variant;
  final String title;
  final String subtitle;
  final List<Room> rooms;
  final IconData emptyIcon;
  final String emptyTitle;
  final String emptySubtitle;
  final ValueChanged<Room> onRoomTap;
  final bool isLoading;
  final bool showOwnerActions;
  final ValueChanged<Room>? onEditRoom;
  final ValueChanged<Room>? onDeleteRoom;
  final ValueChanged<Room>? onToggleAvailability;
  final ValueChanged<Room>? onSaveTap;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _TabSurface(
        variant: variant,
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    return _TabSurface(
      variant: variant,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SectionHeader(
            title: title,
            subtitle: rooms.isEmpty ? subtitle : '$subtitle • ${rooms.length}',
          ),
          const SizedBox(height: 14),
          if (rooms.isEmpty)
            _EmptyStateCard(
              icon: emptyIcon,
              title: emptyTitle,
              subtitle: emptySubtitle,
            )
          else
            ...rooms.map(
              (room) => RoomCard(
                room: room,
                onTap: () => onRoomTap(room),
                onSaveTap: onSaveTap == null ? null : () => onSaveTap!(room),
                isSaved: onSaveTap != null,
                actions: showOwnerActions
                    ? [
                        const RoomCardAction(
                          value: 'view',
                          label: 'View details',
                          icon: Icons.visibility_outlined,
                        ),
                        const RoomCardAction(
                          value: 'edit',
                          label: 'Edit listing',
                          icon: Icons.edit_outlined,
                        ),
                        RoomCardAction(
                          value: 'availability',
                          label: room.isAvailable
                              ? 'Mark as booked'
                              : 'Mark as available',
                          icon: room.isAvailable
                              ? Icons.event_busy_outlined
                              : Icons.event_available_outlined,
                        ),
                        const RoomCardAction(
                          value: 'delete',
                          label: 'Delete listing',
                          icon: Icons.delete_outline_rounded,
                          isDestructive: true,
                        ),
                      ]
                    : const [],
                onActionSelected: (value) {
                  switch (value) {
                    case 'view':
                      onRoomTap(room);
                      break;
                    case 'edit':
                      onEditRoom?.call(room);
                      break;
                    case 'availability':
                      onToggleAvailability?.call(room);
                      break;
                    case 'delete':
                      onDeleteRoom?.call(room);
                      break;
                  }
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatefulWidget {
  const _ProfileTab({
    required this.onLogout,
    required this.onOpenListings,
    required this.onOpenSaved,
  });

  final VoidCallback onLogout;
  final VoidCallback onOpenListings;
  final VoidCallback onOpenSaved;

  @override
  State<_ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<_ProfileTab> {
  final _picker = ImagePicker();
  Map<String, dynamic> _summary = {};
  bool _isLoadingSummary = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSummary());
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    if (user == null) return const _EmptyPanel(icon: Icons.person_off_rounded);

    return SafeArea(
      top: false,
      child: _TabSurface(
        variant: _TabSurfaceVariant.profile,
        child: RefreshIndicator(
          onRefresh: _loadSummary,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _buildHeader(user),
              const SizedBox(height: 14),
              _buildPersonalInfo(user),
              const SizedBox(height: 14),
              _buildActivity(),
              const SizedBox(height: 14),
              _buildReviews(),
              const SizedBox(height: 14),
              _buildPreferences(user),
              const SizedBox(height: 14),
              _buildSecurity(user),
              const SizedBox(height: 14),
              _buildSettings(user),
              const SizedBox(height: 14),
              _buildSupport(user),
              const SizedBox(height: 14),
              _ProfileCard(
                child: _MenuTile(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  subtitle: 'Sign out from this device',
                  iconColor: const Color(0xFFDC2626),
                  onTap: _confirmLogout,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          title: const Text('Logout?'),
          content: const Text(
            'Are you sure you want to sign out from this device?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.danger,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true) widget.onLogout();
  }

  Widget _buildHeader(User user) {
    final completion = user.profileCompletion.clamp(0, 100);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppGradients.trust,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppShadows.lift,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: Colors.white24,
                    backgroundImage: user.profilePhotoUrl.isEmpty
                        ? null
                        : NetworkImage(user.profilePhotoUrl),
                    child: user.profilePhotoUrl.isEmpty
                        ? Text(
                            _initials(user.name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: IconButton.filled(
                      tooltip: 'Edit profile photo',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF2563EB),
                        minimumSize: const Size(34, 34),
                        fixedSize: const Size(34, 34),
                      ),
                      onPressed: _pickProfilePhoto,
                      icon: const Icon(Icons.camera_alt_rounded, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            user.name.isNotEmpty ? user.name : 'Rento user',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        if (user.isVerified)
                          const Icon(
                            Icons.verified_rounded,
                            color: Color(0xFFA7F3D0),
                            size: 22,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFFE0F2FE)),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _ProfilePill(
                          icon: _roleIcon(user.role),
                          label: user.roleLabel,
                        ),
                        _ProfilePill(
                          icon: user.isVerified
                              ? Icons.verified_user_rounded
                              : Icons.shield_outlined,
                          label: user.isVerified ? 'Verified' : 'Unverified',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$completion% profile complete',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: completion / 100,
                        minHeight: 8,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFA7F3D0),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              FilledButton.icon(
                onPressed: () => _openEditProfile(user),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1D4ED8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.edit_rounded, size: 18),
                label: const Text('Edit'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfo(User user) {
    return _ProfileCard(
      title: 'Personal Info',
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.phone_rounded,
            label: 'Phone Number',
            value: _fallback(user.phone),
          ),
          _InfoRow(
            icon: Icons.call_outlined,
            label: 'Alternate Contact',
            value: _fallback(user.alternateContact),
          ),
          _InfoRow(
            icon: Icons.wc_rounded,
            label: 'Gender',
            value: _formatGender(user.gender),
          ),
          _InfoRow(
            icon: Icons.cake_outlined,
            label: 'Date of Birth',
            value: user.dateOfBirth == null
                ? 'Not added'
                : _dateLabel(user.dateOfBirth!),
          ),
        ],
      ),
    );
  }

  Widget _buildActivity() {
    return _ProfileCard(
      title: 'My Activity',
      trailing: _isLoadingSummary
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.event_available_rounded,
                  label: 'My Bookings',
                  value: _summaryInt('myBookings').toString(),
                  onTap: () => _openActivityDetails('My Bookings'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  icon: Icons.apartment_rounded,
                  label: 'My Listings',
                  value: _summaryInt('myListings').toString(),
                  onTap: widget.onOpenListings,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  icon: Icons.history_rounded,
                  label: 'Booking History',
                  value: _summaryInt('bookingHistory').toString(),
                  onTap: () => _openActivityDetails('Booking History'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MetricTile(
                  icon: Icons.bookmark_rounded,
                  label: 'Saved Rooms',
                  value: _summaryInt('savedRooms').toString(),
                  onTap: widget.onOpenSaved,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviews() {
    final rating = (_summary['ratingsReceivedAverage'] ?? 0).toString();
    final receivedCount = _summaryInt('ratingsReceivedCount');

    return _ProfileCard(
      title: 'Reviews & Ratings',
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.star_rounded,
            title: 'Ratings received',
            subtitle: receivedCount == 0
                ? 'No ratings yet'
                : '$rating average from $receivedCount reviews',
            onTap: () => _openActivityDetails('Ratings received'),
          ),
          _MenuTile(
            icon: Icons.rate_review_outlined,
            title: 'Reviews given',
            subtitle: '${_summaryInt('reviewsGiven')} reviews written',
            onTap: () => _openActivityDetails('Reviews given'),
          ),
        ],
      ),
    );
  }

  Widget _buildPreferences(User user) {
    return _ProfileCard(
      title: 'Notifications & Preferences',
      child: Column(
        children: [
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const _MenuIcon(
              icon: Icons.email_outlined,
              color: Color(0xFF2563EB),
            ),
            title: const Text('Email notifications'),
            subtitle: const Text('Booking, listing, and review updates'),
            value: user.emailNotifications,
            onChanged: (value) => _updateUser({'emailNotifications': value}),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const _MenuIcon(
              icon: Icons.sms_outlined,
              color: Color(0xFF0F766E),
            ),
            title: const Text('SMS notifications'),
            subtitle: const Text('Important alerts on your phone'),
            value: user.smsNotifications,
            onChanged: (value) => _updateUser({'smsNotifications': value}),
          ),
          _MenuTile(
            icon: Icons.language_rounded,
            title: 'Language',
            subtitle: user.language,
            onTap: () => _openStringPicker(
              title: 'Language',
              values: const ['English', 'Hindi', 'Tamil', 'Telugu', 'Marathi'],
              current: user.language,
              onSelected: (value) => _updateUser({'language': value}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurity(User user) {
    return _ProfileCard(
      title: 'Security',
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.lock_reset_rounded,
            title: 'Change Password',
            subtitle: 'Update your account password',
            onTap: _openChangePassword,
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const _MenuIcon(
              icon: Icons.verified_user_outlined,
              color: Color(0xFF7C3AED),
            ),
            title: const Text('Two-Factor Authentication'),
            subtitle: const Text('Store your 2FA preference'),
            value: user.twoFactorEnabled,
            onChanged: (value) => _updateUser({'twoFactorEnabled': value}),
          ),
          _MenuTile(
            icon: Icons.devices_rounded,
            title: 'Login Devices / Sessions',
            subtitle: 'Current device active',
            onTap: () => _showMessage('You are signed in on this device.'),
          ),
        ],
      ),
    );
  }

  Widget _buildSettings(User user) {
    return _ProfileCard(
      title: 'Settings',
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.dark_mode_outlined,
            title: 'App Theme',
            subtitle: _capitalize(user.appTheme),
            onTap: () => _openStringPicker(
              title: 'App Theme',
              values: const ['system', 'light', 'dark'],
              current: user.appTheme,
              onSelected: (value) => _updateUser({'appTheme': value}),
            ),
          ),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            secondary: const _MenuIcon(
              icon: Icons.location_on_outlined,
              color: Color(0xFF0EA5E9),
            ),
            title: const Text('Location Settings'),
            subtitle: const Text('Allow location based room suggestions'),
            value: user.locationEnabled,
            onChanged: (value) => _updateUser({'locationEnabled': value}),
          ),
          _MenuTile(
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy Controls',
            subtitle: _privacyLabel(user.profileVisibility),
            onTap: () => _openStringPicker(
              title: 'Privacy Controls',
              values: const ['public', 'contacts', 'private'],
              current: user.profileVisibility,
              onSelected: (value) => _updateUser({'profileVisibility': value}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupport(User user) {
    return _ProfileCard(
      title: 'Support & Help',
      child: Column(
        children: [
          _MenuTile(
            icon: Icons.help_outline_rounded,
            title: 'Help Center',
            subtitle: 'Browse common questions',
            onTap: () => _showMessage('Help Center will open here.'),
          ),
          _MenuTile(
            icon: Icons.support_agent_rounded,
            title: 'Contact Support',
            subtitle: 'Send the support team a message',
            onTap: () => _openSupportDialog(user, 'Contact Support'),
          ),
          _MenuTile(
            icon: Icons.report_problem_outlined,
            title: 'Report Issue',
            subtitle: 'Tell us what went wrong',
            onTap: () => _openSupportDialog(user, 'Report Issue'),
          ),
        ],
      ),
    );
  }

  Future<void> _loadSummary() async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null || _isLoadingSummary) return;

    setState(() => _isLoadingSummary = true);
    try {
      final summary = await DjangoApi.getProfileSummary(user.id);
      if (mounted) setState(() => _summary = summary);
    } catch (e) {
      debugPrint('Load profile summary error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingSummary = false);
    }
  }

  Future<void> _pickProfilePhoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 86,
    );
    if (image == null || !mounted) return;

    final success = await context.read<AuthProvider>().uploadProfilePhoto(
      image,
    );
    if (!mounted) return;
    _showMessage(
      success ? 'Profile photo updated.' : 'Unable to upload photo.',
    );
  }

  Future<void> _updateUser(Map<String, dynamic> data) async {
    final success = await context.read<AuthProvider>().updateProfile(data);
    if (!mounted || !success) return;
    await _loadSummary();
  }

  Future<void> _openEditProfile(User user) async {
    final nameController = TextEditingController(text: user.name);
    final phoneController = TextEditingController(text: user.phone);
    final alternateController = TextEditingController(
      text: user.alternateContact,
    );
    final dobController = TextEditingController(
      text: user.dateOfBirth == null ? '' : _dateLabel(user.dateOfBirth!),
    );
    var role = user.role;
    var gender = user.gender;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                4,
                20,
                20 + MediaQuery.of(context).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _profileInput(nameController, 'Full name', Icons.person),
                    const SizedBox(height: 12),
                    _profileInput(
                      phoneController,
                      'Phone number',
                      Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    _profileInput(
                      alternateController,
                      'Alternate contact',
                      Icons.call_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<UserRole>(
                      initialValue: role,
                      decoration: _fieldDecoration('User type', Icons.badge),
                      items: UserRole.values
                          .map(
                            (item) => DropdownMenuItem(
                              value: item,
                              child: Text(_roleLabel(item)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => role = value);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: gender,
                      decoration: _fieldDecoration('Gender', Icons.wc_rounded),
                      items: const [
                        DropdownMenuItem(
                          value: '',
                          child: Text('Prefer not to say'),
                        ),
                        DropdownMenuItem(
                          value: 'female',
                          child: Text('Female'),
                        ),
                        DropdownMenuItem(value: 'male', child: Text('Male')),
                        DropdownMenuItem(
                          value: 'non_binary',
                          child: Text('Non-binary'),
                        ),
                        DropdownMenuItem(value: 'other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        setSheetState(() => gender = value ?? '');
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dobController,
                      readOnly: true,
                      decoration: _fieldDecoration(
                        'Date of birth',
                        Icons.cake_outlined,
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: user.dateOfBirth ?? DateTime(2000),
                          firstDate: DateTime(1940),
                          lastDate: DateTime.now(),
                        );
                        if (picked != null) {
                          dobController.text = _dateLabel(picked);
                        }
                      },
                    ),
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: () async {
                        final data = {
                          'name': nameController.text.trim(),
                          'phone': phoneController.text.trim(),
                          'alternateContact': alternateController.text.trim(),
                          'role': role.name,
                          'gender': gender,
                          'dateOfBirth': dobController.text.trim().isEmpty
                              ? null
                              : dobController.text.trim(),
                        };
                        Navigator.pop(context);
                        await _updateUser(data);
                      },
                      icon: const Icon(Icons.save_rounded),
                      label: const Text('Save Profile'),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameController.dispose();
    phoneController.dispose();
    alternateController.dispose();
    dobController.dispose();
  }

  Future<void> _openChangePassword() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    var obscure = true;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Change Password'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: passwordController,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'New password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: obscure ? 'Show password' : 'Hide password',
                        icon: Icon(
                          obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setDialogState(() => obscure = !obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmController,
                    obscureText: obscure,
                    decoration: const InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: Icon(Icons.lock_reset_outlined),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () async {
                    final password = passwordController.text;
                    if (password.length < 6 ||
                        password != confirmController.text) {
                      _showMessage(
                        'Use matching passwords with 6+ characters.',
                      );
                      return;
                    }
                    final success = await context
                        .read<AuthProvider>()
                        .changePassword(password);
                    if (!context.mounted) return;
                    Navigator.pop(context);
                    _showMessage(
                      success
                          ? 'Password updated.'
                          : 'Unable to update password.',
                    );
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    passwordController.dispose();
    confirmController.dispose();
  }

  Future<void> _openSupportDialog(User user, String subject) async {
    final messageController = TextEditingController();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            20 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                subject,
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: messageController,
                maxLines: 5,
                decoration: _fieldDecoration('Message', Icons.message_outlined),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () async {
                  if (messageController.text.trim().isEmpty) return;
                  await DjangoApi.createSupportTicket({
                    'userId': user.id,
                    'subject': subject,
                    'message': messageController.text.trim(),
                    'contactEmail': user.email,
                  });
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  _showMessage('Support request submitted.');
                },
                icon: const Icon(Icons.send_rounded),
                label: const Text('Submit'),
              ),
            ],
          ),
        );
      },
    );

    messageController.dispose();
  }

  void _openStringPicker({
    required String title,
    required List<String> values,
    required String current,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                ...values.map(
                  (value) => ListTile(
                    title: Text(_pickerLabel(title, value)),
                    trailing: current == value
                        ? const Icon(Icons.check_rounded)
                        : null,
                    onTap: () {
                      Navigator.pop(context);
                      onSelected(value);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openActivityDetails(String title) {
    _showMessage('$title is connected to your profile activity.');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  TextField _profileInput(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: _fieldDecoration(label, icon),
    );
  }

  InputDecoration _fieldDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    );
  }

  int _summaryInt(String key) {
    final value = _summary[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  IconData _roleIcon(UserRole role) {
    switch (role) {
      case UserRole.tenant:
        return Icons.person_search_outlined;
      case UserRole.landowner:
        return Icons.home_work_outlined;
      case UserRole.both:
        return Icons.handshake_outlined;
    }
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.tenant:
        return 'Tenant';
      case UserRole.landowner:
        return 'Owner';
      case UserRole.both:
        return 'Owner & Tenant';
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'R';
    final first = parts.first[0];
    final second = parts.length > 1 && parts[1].isNotEmpty ? parts[1][0] : '';
    return '$first$second'.toUpperCase();
  }

  String _fallback(String value) => value.trim().isEmpty ? 'Not added' : value;

  String _dateLabel(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _formatGender(String gender) {
    switch (gender) {
      case 'female':
        return 'Female';
      case 'male':
        return 'Male';
      case 'non_binary':
        return 'Non-binary';
      case 'other':
        return 'Other';
      default:
        return 'Not added';
    }
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  String _privacyLabel(String value) {
    switch (value) {
      case 'contacts':
        return 'Contacts only';
      case 'private':
        return 'Private';
      default:
        return 'Public';
    }
  }

  String _pickerLabel(String title, String value) {
    if (title == 'Privacy Controls') return _privacyLabel(value);
    if (title == 'App Theme') return _capitalize(value);
    return value;
  }
}

enum _TabSurfaceVariant { home, listings, saved, profile }

class _TabSurface extends StatefulWidget {
  const _TabSurface({required this.variant, required this.child});

  final _TabSurfaceVariant variant;
  final Widget child;

  @override
  State<_TabSurface> createState() => _TabSurfaceState();
}

class _TabSurfaceState extends State<_TabSurface>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> get _colors {
    switch (widget.variant) {
      case _TabSurfaceVariant.home:
        return const [
          Color(0xFFDCEBFF),
          Color(0xFFF0E8FF),
          Color(0xFFE8F7FF),
          AppColors.background,
        ];
      case _TabSurfaceVariant.listings:
        return const [
          Color(0xFFE9DDFF),
          Color(0xFFFFEDF5),
          Color(0xFFF5F0FF),
          AppColors.background,
        ];
      case _TabSurfaceVariant.saved:
        return const [
          Color(0xFFDDF8F2),
          Color(0xFFEAF7D7),
          Color(0xFFEAF4FF),
          AppColors.background,
        ];
      case _TabSurfaceVariant.profile:
        return const [
          Color(0xFFFFE8D6),
          Color(0xFFFFE8F0),
          Color(0xFFF0E7FF),
          AppColors.background,
        ];
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final progress = _controller.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: colors,
              stops: const [0, 0.34, 0.68, 1],
              begin: Alignment(-1 + progress * 0.26, -1),
              end: Alignment(1 - progress * 0.18, 1),
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _SurfaceBandPainter(
                      primary: colors.first,
                      secondary: colors[1],
                      progress: progress,
                    ),
                  ),
                ),
              ),
              widget.child,
            ],
          ),
        );
      },
    );
  }
}

class _SurfaceBandPainter extends CustomPainter {
  const _SurfaceBandPainter({
    required this.primary,
    required this.secondary,
    required this.progress,
  });

  final Color primary;
  final Color secondary;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final topPaint = Paint()
      ..color = primary.withValues(alpha: 0.46)
      ..style = PaintingStyle.fill;
    final topPath = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height * (0.18 + progress * 0.04))
      ..quadraticBezierTo(
        size.width * (0.46 + progress * 0.16),
        size.height * (0.32 - progress * 0.04),
        0,
        size.height * (0.22 + progress * 0.03),
      )
      ..close();
    canvas.drawPath(topPath, topPaint);

    final lowerPaint = Paint()
      ..color = secondary.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;
    final lowerPath = Path()
      ..moveTo(0, size.height * (0.24 + progress * 0.02))
      ..quadraticBezierTo(
        size.width * 0.5,
        size.height * (0.15 + progress * 0.06),
        size.width,
        size.height * (0.3 - progress * 0.02),
      )
      ..lineTo(size.width, size.height * (0.42 + progress * 0.03))
      ..quadraticBezierTo(
        size.width * 0.48,
        size.height * (0.34 + progress * 0.04),
        0,
        size.height * (0.48 - progress * 0.03),
      )
      ..close();
    canvas.drawPath(lowerPath, lowerPaint);
  }

  @override
  bool shouldRepaint(covariant _SurfaceBandPainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.progress != progress;
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.child, this.title, this.trailing});

  final String? title;
  final Widget? trailing;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    title!,
                    style: const TextStyle(
                      color: AppColors.ink,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                trailing ?? const SizedBox.shrink(),
              ],
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}

class _ProfilePill extends StatelessWidget {
  const _ProfilePill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          _MenuIcon(icon: icon, color: const Color(0xFF2563EB)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF8FAFC),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: AppColors.primary, size: 20),
                  const Spacer(),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.muted,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatefulWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor = AppColors.primary,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color iconColor;

  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovered || _pressed;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) {
        setState(() {
          _hovered = false;
          _pressed = false;
        });
      },
      child: AnimatedScale(
        scale: _pressed ? 0.99 : (_hovered ? 1.01 : 1),
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          decoration: BoxDecoration(
            color: active
                ? AppColors.primary.withValues(alpha: 0.04)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 6),
              onTap: widget.onTap,
              leading: _MenuIcon(icon: widget.icon, color: widget.iconColor),
              title: Text(
                widget.title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                widget.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.muted,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuIcon extends StatelessWidget {
  const _MenuIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _HomeHero extends StatelessWidget {
  const _HomeHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.premium,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppShadows.glow,
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -18,
            child: Transform.rotate(
              angle: -0.28,
              child: Container(
                width: 136,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Find a room faster',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Comfortable rooms, clear prices, easy decisions.',
                      style: TextStyle(
                        color: Color(0xFFEDE9FE),
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _HeroChip(
                          icon: Icons.verified_rounded,
                          label: 'Verified',
                        ),
                        _HeroChip(
                          icon: Icons.bolt_rounded,
                          label: 'Fast search',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.17),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white30),
                ),
                child: const Icon(
                  Icons.apartment_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppColors.muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isSecondary = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isSecondary;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final gradient = widget.isSecondary
        ? AppGradients.primary
        : AppGradients.calm;
    final scale = _pressed ? 0.98 : (_hovered ? 1.025 : 1.0);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) {
        setState(() {
          _hovered = false;
          _pressed = false;
        });
      },
      child: AnimatedScale(
        scale: scale,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        child: Listener(
          onPointerDown: (_) => setState(() => _pressed = true),
          onPointerUp: (_) => setState(() => _pressed = false),
          onPointerCancel: (_) => setState(() => _pressed = false),
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(8),
              boxShadow: _hovered ? AppShadows.lift : AppShadows.soft,
            ),
            child: ElevatedButton.icon(
              onPressed: widget.onPressed,
              onHover: (value) => setState(() => _hovered = value),
              icon: Icon(widget.icon),
              label: Text(widget.label),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                shadowColor: Colors.transparent,
                minimumSize: const Size.fromHeight(52),
                textStyle: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchPanel extends StatelessWidget {
  const _SearchPanel({
    required this.searchController,
    required this.maxPriceController,
    required this.selectedCity,
    required this.selectedRoomType,
    required this.selectedAmenity,
    required this.onCityChanged,
    required this.onRoomTypeChanged,
    required this.onAmenityChanged,
    required this.onApply,
    required this.onClear,
  });

  final TextEditingController searchController;
  final TextEditingController maxPriceController;
  final String selectedCity;
  final String selectedRoomType;
  final String selectedAmenity;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String> onRoomTypeChanged;
  final ValueChanged<String> onAmenityChanged;
  final VoidCallback onApply;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => onApply(),
            decoration: InputDecoration(
              hintText: 'Search by locality, city, or room title',
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _MiniDropdown(
                  value: selectedCity,
                  options: const [
                    'All',
                    'Delhi',
                    'Mumbai',
                    'Bangalore',
                    'Chennai',
                    'Pune',
                  ],
                  onChanged: onCityChanged,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _MiniDropdown(
                  value: selectedRoomType,
                  options: ['All', ...roomTypes],
                  onChanged: onRoomTypeChanged,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: maxPriceController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Maximum monthly rent',
              prefixIcon: const Icon(
                Icons.currency_rupee_rounded,
                color: AppColors.primary,
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Amenities',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ['All', ...amenities.take(6)].map((amenity) {
                final selected = amenity == selectedAmenity;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(amenity),
                    selected: selected,
                    onSelected: (_) => onAmenityChanged(amenity),
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : AppColors.softText,
                      fontWeight: FontWeight.w800,
                    ),
                    selectedColor: AppColors.primary,
                    backgroundColor: const Color(0xFFF2F4F7),
                    side: BorderSide(
                      color: selected ? AppColors.primary : AppColors.line,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onClear,
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text('Clear'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Apply'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniDropdown extends StatelessWidget {
  const _MiniDropdown({
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        prefixIcon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.primary,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
      items: options
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _EmptyListingPanel extends StatelessWidget {
  const _EmptyListingPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.soft,
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _EmptyIllustration(icon: Icons.search_off_rounded),
          SizedBox(height: 16),
          Text(
            'No rooms found yet',
            style: TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Try a different filter or list the first room.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.line),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          _EmptyIllustration(icon: icon),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.ink,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.muted, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _EmptyIllustration extends StatelessWidget {
  const _EmptyIllustration({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        gradient: AppGradients.calm,
        borderRadius: BorderRadius.circular(8),
        boxShadow: AppShadows.lift,
      ),
      child: Icon(icon, size: 34, color: Colors.white),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(child: _EmptyIllustration(icon: icon));
  }
}
