import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room.dart';
import '../providers/auth_provider.dart';
import '../utils/django_api.dart';
import '../widgets/room_image.dart';

class RoomDetails extends StatefulWidget {
  final Room room;

  const RoomDetails({super.key, required this.room});

  @override
  State<RoomDetails> createState() => _RoomDetailsState();
}

class _RoomDetailsState extends State<RoomDetails> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    final isOwner = user?.id == widget.room.ownerId;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(widget.room.title),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
            children: [
              _ImageGallery(images: widget.room.images),
              const SizedBox(height: 16),
              _InfoCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            widget.room.title,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: widget.room.isAvailable
                                ? const Color(0xFFDCFCE7)
                                : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            widget.room.isAvailable ? 'Available' : 'Booked',
                            style: TextStyle(
                              color: widget.room.isAvailable
                                  ? const Color(0xFF166534)
                                  : const Color(0xFF991B1B),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '₹${widget.room.price.toStringAsFixed(0)}/month',
                      style: const TextStyle(
                        color: Color(0xFF2563EB),
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (widget.room.securityDeposit > 0)
                      Text(
                        'Deposit ₹${widget.room.securityDeposit.toStringAsFixed(0)}',
                        style: const TextStyle(color: Color(0xFF64748B)),
                      ),
                    const SizedBox(height: 14),
                    _IconLine(
                      icon: Icons.location_on_outlined,
                      text: [
                        widget.room.address,
                        widget.room.location,
                        widget.room.city,
                      ].where((item) => item.isNotEmpty).join(', '),
                    ),
                    const SizedBox(height: 8),
                    _IconLine(
                      icon: Icons.call_outlined,
                      text: widget.room.contactNumber.isEmpty
                          ? 'Contact available after inquiry'
                          : widget.room.contactNumber,
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _Pill(widget.room.roomType),
                        if (widget.room.furnishing.isNotEmpty)
                          _Pill(widget.room.furnishing),
                        if (widget.room.preferredTenant.isNotEmpty)
                          _Pill(widget.room.preferredTenant),
                        if (widget.room.availableFrom != null)
                          _Pill('From ${widget.room.availableFrom}'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Description',
                child: Text(
                  widget.room.description,
                  style: const TextStyle(
                    color: Color(0xFF475569),
                    height: 1.45,
                    fontSize: 15,
                  ),
                ),
              ),
              if (widget.room.amenities.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'Amenities',
                  child: _TagWrap(values: widget.room.amenities),
                ),
              ],
              if (widget.room.rules.isNotEmpty) ...[
                const SizedBox(height: 16),
                _InfoCard(
                  title: 'House rules',
                  child: _TagWrap(values: widget.room.rules),
                ),
              ],
              const SizedBox(height: 16),
              _InfoCard(
                title: 'Owner',
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Color(0xFFE0F2FE),
                      child: Icon(
                        Icons.person_rounded,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.room.ownerName.isEmpty
                            ? 'Room owner'
                            : widget.room.ownerName,
                        style: const TextStyle(
                          color: Color(0xFF0F172A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!isOwner)
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: SafeArea(
                child: SizedBox(
                  height: 54,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _contactOwner,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.chat_bubble_outline_rounded),
                    label: Text(_isLoading ? 'Sending...' : 'Contact Owner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2563EB),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _contactOwner() async {
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    final messageController = TextEditingController(
      text: 'Hi, I am interested in this room. Please contact me.',
    );
    final phoneController = TextEditingController(text: user.phone);
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact owner'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Your phone number',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: messageController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Message',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send'),
          ),
        ],
      ),
    );

    if (result != true || messageController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      await DjangoApi.createInquiry({
        'roomId': widget.room.id,
        'tenantId': user.id,
        'tenantName': user.name,
        'tenantEmail': user.email,
        'tenantPhone': phoneController.text.trim(),
        'message': messageController.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inquiry sent to owner')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Unable to send inquiry: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _ImageGallery extends StatelessWidget {
  const _ImageGallery({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    if (images.isEmpty) {
      return const _ImagePlaceholder(height: 240);
    }

    return SizedBox(
      height: 240,
      child: PageView.builder(
        itemCount: images.length,
        itemBuilder: (context, index) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: RoomImage(imagePath: images[index], height: 240),
          );
        },
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE0F2FE),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(
        Icons.apartment_rounded,
        size: 64,
        color: Color(0xFF2563EB),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.child, this.title});

  final String? title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F0F172A),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                color: Color(0xFF0F172A),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 10),
          ],
          child,
        ],
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF64748B), size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(text, style: const TextStyle(color: Color(0xFF475569))),
        ),
      ],
    );
  }
}

class _TagWrap extends StatelessWidget {
  const _TagWrap({required this.values});

  final List<String> values;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map(_Pill.new).toList(),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(text),
      backgroundColor: const Color(0xFFF1F5F9),
      side: BorderSide.none,
    );
  }
}
