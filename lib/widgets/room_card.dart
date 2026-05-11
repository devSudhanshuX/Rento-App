import 'package:flutter/material.dart';
import '../models/room.dart';
import '../utils/app_theme.dart';
import 'room_image.dart';

class RoomCard extends StatefulWidget {
  const RoomCard({
    super.key,
    required this.room,
    required this.onTap,
    this.onSaveTap,
    this.isSaved = false,
    this.actions = const [],
    this.onActionSelected,
  });

  final Room room;
  final VoidCallback onTap;
  final VoidCallback? onSaveTap;
  final bool isSaved;
  final List<RoomCardAction> actions;
  final ValueChanged<String>? onActionSelected;

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  void _setPressed(bool value) {
    if (_isPressed == value) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final isActive = _isHovered || _isPressed;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) {
        setState(() {
          _isHovered = false;
          _isPressed = false;
        });
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.985 : (_isHovered ? 1.012 : 1),
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOutCubic,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: isActive ? 0.99 : 0.94),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive ? const Color(0xFFBFD4FF) : AppColors.line,
            ),
            boxShadow: isActive ? AppShadows.lift : AppShadows.soft,
          ),
          child: InkWell(
            onTap: widget.onTap,
            onTapDown: (_) => _setPressed(true),
            onTapUp: (_) => _setPressed(false),
            onTapCancel: () => _setPressed(false),
            borderRadius: BorderRadius.circular(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ImageSection(
                  room: widget.room,
                  onSaveTap: widget.onSaveTap,
                  isSaved: widget.isSaved,
                  actions: widget.actions,
                  onActionSelected: widget.onActionSelected,
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              widget.room.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          Text(
                            '₹${widget.room.price.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_outlined,
                            color: AppColors.muted,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              [
                                widget.room.location,
                                widget.room.city,
                              ].where((e) => e.isNotEmpty).join(', '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Pill(text: widget.room.roomType),
                          if (widget.room.furnishing.isNotEmpty)
                            _Pill(text: widget.room.furnishing),
                          if (widget.room.preferredTenant.isNotEmpty)
                            _Pill(text: widget.room.preferredTenant),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        widget.room.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.softText,
                          height: 1.35,
                        ),
                      ),
                    ],
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

class _ImageSection extends StatelessWidget {
  const _ImageSection({
    required this.room,
    required this.onSaveTap,
    required this.isSaved,
    required this.actions,
    required this.onActionSelected,
  });

  final Room room;
  final VoidCallback? onSaveTap;
  final bool isSaved;
  final List<RoomCardAction> actions;
  final ValueChanged<String>? onActionSelected;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
          child: AspectRatio(
            aspectRatio: 16 / 10,
            child: RoomImage(
              imagePath: room.images.isEmpty ? null : room.images.first,
              height: double.infinity,
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(8),
              ),
              gradient: LinearGradient(
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
                begin: Alignment.topCenter,
                end: Alignment.center,
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          top: 12,
          child: _Badge(
            text: room.isAvailable ? 'Available' : 'Booked',
            color: room.isAvailable ? AppColors.success : AppColors.warning,
          ),
        ),
        if (onSaveTap != null)
          Positioned(
            right: 10,
            top: 10,
            child: _RoundActionButton(
              tooltip: isSaved ? 'Remove saved room' : 'Save room',
              icon: isSaved
                  ? Icons.bookmark_rounded
                  : Icons.bookmark_border_rounded,
              onPressed: onSaveTap,
            ),
          ),
        if (onSaveTap == null && actions.isNotEmpty)
          Positioned(
            right: 10,
            top: 10,
            child: Material(
              color: AppColors.surface,
              shape: const CircleBorder(),
              child: PopupMenuButton<String>(
                tooltip: 'Room options',
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.ink),
                onSelected: onActionSelected,
                itemBuilder: (context) => actions
                    .map(
                      (action) => PopupMenuItem<String>(
                        value: action.value,
                        child: Row(
                          children: [
                            Icon(
                              action.icon,
                              size: 19,
                              color: action.isDestructive
                                  ? AppColors.danger
                                  : AppColors.softText,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              action.label,
                              style: TextStyle(
                                color: action.isDestructive
                                    ? AppColors.danger
                                    : AppColors.ink,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
      ],
    );
  }
}

class _RoundActionButton extends StatefulWidget {
  const _RoundActionButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  State<_RoundActionButton> createState() => _RoundActionButtonState();
}

class _RoundActionButtonState extends State<_RoundActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        scale: _hovered ? 1.08 : 1,
        duration: const Duration(milliseconds: 150),
        child: Material(
          color: AppColors.surface,
          shape: const CircleBorder(),
          child: IconButton(
            tooltip: widget.tooltip,
            onPressed: widget.onPressed,
            icon: Icon(widget.icon, color: AppColors.primary),
          ),
        ),
      ),
    );
  }
}

class RoomCardAction {
  const RoomCardAction({
    required this.value,
    required this.label,
    required this.icon,
    this.isDestructive = false,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool isDestructive;
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(99),
        boxShadow: AppShadows.soft,
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F7),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: AppColors.line),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.softText,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
