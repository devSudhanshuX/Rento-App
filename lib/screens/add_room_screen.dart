import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/room.dart';
import '../providers/auth_provider.dart';
import '../providers/room_provider.dart';
import '../utils/constants.dart';
import '../utils/supabase_queries.dart';
import '../widgets/room_image.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key, this.initialRoom});

  final Room? initialRoom;

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _depositController = TextEditingController();
  final _cityController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _contactController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final List<String> _selectedAmenities = [];
  final List<String> _selectedRules = [];
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  String _selectedRoomType = roomTypes[0];
  String _selectedFurnishing = furnishingOptions[1];
  String _selectedTenant = tenantPreferences[0];
  DateTime? _availableFrom;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    final room = widget.initialRoom;

    if (room == null) {
      _ownerNameController.text = user?.name ?? '';
      _contactController.text = user?.phone ?? '';
      return;
    }

    _titleController.text = room.title;
    _descriptionController.text = room.description;
    _priceController.text = room.price.toStringAsFixed(0);
    _depositController.text = room.securityDeposit.toStringAsFixed(0);
    _cityController.text = room.city;
    _locationController.text = room.location;
    _addressController.text = room.address;
    _contactController.text = room.contactNumber;
    _ownerNameController.text = room.ownerName;
    _selectedRoomType = room.roomType.isEmpty ? roomTypes[0] : room.roomType;
    _selectedFurnishing = room.furnishing.isEmpty
        ? furnishingOptions[1]
        : room.furnishing;
    _selectedTenant = room.preferredTenant.isEmpty
        ? tenantPreferences[0]
        : room.preferredTenant;
    _availableFrom = room.availableFrom == null
        ? null
        : DateTime.tryParse(room.availableFrom!);
    _selectedAmenities.addAll(room.amenities);
    _selectedRules.addAll(room.rules);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _depositController.dispose();
    _cityController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _contactController.dispose();
    _ownerNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        title: Text(
          widget.initialRoom == null ? 'List your room' : 'Edit listing',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _FormHero(),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Room basics',
                children: [
                  _TextInput(
                    controller: _titleController,
                    label: 'Room title',
                    icon: Icons.title_rounded,
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  _TextInput(
                    controller: _descriptionController,
                    label: 'Description',
                    icon: Icons.notes_rounded,
                    maxLines: 4,
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _TextInput(
                          controller: _priceController,
                          label: 'Monthly rent',
                          icon: Icons.currency_rupee_rounded,
                          keyboardType: TextInputType.number,
                          validator: _numberRequired,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TextInput(
                          controller: _depositController,
                          label: 'Deposit',
                          icon: Icons.savings_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _DropdownInput(
                          label: 'Type',
                          value: _selectedRoomType,
                          options: roomTypes,
                          onChanged: (value) =>
                              setState(() => _selectedRoomType = value),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DropdownInput(
                          label: 'Furnishing',
                          value: _selectedFurnishing,
                          options: furnishingOptions,
                          onChanged: (value) =>
                              setState(() => _selectedFurnishing = value),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _DropdownInput(
                    label: 'Preferred tenant',
                    value: _selectedTenant,
                    options: tenantPreferences,
                    onChanged: (value) =>
                        setState(() => _selectedTenant = value),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Location and contact',
                children: [
                  _TextInput(
                    controller: _cityController,
                    label: 'City',
                    icon: Icons.location_city_rounded,
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  _TextInput(
                    controller: _locationController,
                    label: 'Area / locality',
                    icon: Icons.place_outlined,
                    validator: _required,
                  ),
                  const SizedBox(height: 14),
                  _TextInput(
                    controller: _addressController,
                    label: 'Full address',
                    icon: Icons.map_outlined,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _TextInput(
                          controller: _ownerNameController,
                          label: 'Owner name',
                          icon: Icons.person_outline_rounded,
                          validator: _required,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _TextInput(
                          controller: _contactController,
                          label: 'Contact number',
                          icon: Icons.call_outlined,
                          keyboardType: TextInputType.phone,
                          validator: _required,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: _pickAvailableDate,
                    icon: const Icon(Icons.event_available_rounded),
                    label: Text(
                      _availableFrom == null
                          ? 'Select available from'
                          : 'Available from ${_formatDate(_availableFrom!)}',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Amenities',
                children: [
                  _ChipSelector(
                    values: amenities,
                    selectedValues: _selectedAmenities,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'House rules',
                children: [
                  _ChipSelector(
                    values: roomRules,
                    selectedValues: _selectedRules,
                    onChanged: () => setState(() {}),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Photos',
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: const Text('Add room photo'),
                  ),
                  if (_images.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _images.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          return RoomImage(
                            imagePath: _images[index].path,
                            width: 110,
                            height: 92,
                            borderRadius: 8,
                          );
                        },
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: ElevatedButton.icon(
                  onPressed: _isSaving ? null : _saveRoom,
                  icon: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.publish_rounded),
                  label: Text(
                    _isSaving
                        ? (widget.initialRoom == null
                              ? 'Publishing...'
                              : 'Saving...')
                        : (widget.initialRoom == null
                              ? 'Publish listing'
                              : 'Save changes'),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) setState(() => _images.add(pickedFile));
  }

  Future<void> _pickAvailableDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _availableFrom = picked);
  }

  Future<void> _saveRoom() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final roomProvider = context.read<RoomProvider>();
    final user = authProvider.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);
    final existingRoom = widget.initialRoom;
    final roomId =
        existingRoom?.id ?? DateTime.now().millisecondsSinceEpoch.toString();

    try {
      final imageUrls = await _uploadImages(roomId);
      final room = Room(
        id: roomId,
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.parse(_priceController.text.trim()),
        securityDeposit: double.tryParse(_depositController.text.trim()) ?? 0,
        location: _locationController.text.trim(),
        city: _cityController.text.trim(),
        address: _addressController.text.trim(),
        contactNumber: _contactController.text.trim(),
        ownerName: _ownerNameController.text.trim(),
        images: [...?existingRoom?.images, ...imageUrls],
        roomType: _selectedRoomType,
        furnishing: _selectedFurnishing,
        preferredTenant: _selectedTenant,
        availableFrom: _availableFrom?.toIso8601String().split('T').first,
        rules: _selectedRules,
        isAvailable: existingRoom?.isAvailable ?? true,
        ownerId: existingRoom?.ownerId ?? user.id,
        amenities: _selectedAmenities,
      );

      if (existingRoom == null) {
        await roomProvider.addRoom(room);
      } else {
        await roomProvider.updateRoom(room);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not publish listing: $error'),
          backgroundColor: const Color(0xFFB91C1C),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<List<String>> _uploadImages(String roomId) async {
    final uploadedUrls = <String>[];

    for (var index = 0; index < _images.length; index++) {
      final image = _images[index];
      final bytes = await image.readAsBytes();
      final imageUrl = await SupabaseQueries.uploadRoomImage(
        roomId,
        bytes,
        _buildStorageFileName(image, index),
        _contentTypeFor(image),
      );
      uploadedUrls.add(imageUrl);
    }

    return uploadedUrls;
  }

  String _buildStorageFileName(XFile image, int index) {
    final originalName = image.name.isEmpty ? 'room-photo.jpg' : image.name;
    final safeName = originalName.replaceAll(RegExp(r'[^A-Za-z0-9_.-]'), '_');
    return '${DateTime.now().microsecondsSinceEpoch}_${index}_$safeName';
  }

  String _contentTypeFor(XFile image) {
    final mimeType = image.mimeType;
    if (mimeType != null && mimeType.startsWith('image/')) return mimeType;

    final name = image.name.toLowerCase();
    if (name.endsWith('.png')) return 'image/png';
    if (name.endsWith('.webp')) return 'image/webp';
    if (name.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }

  String? _required(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Required';
    return null;
  }

  String? _numberRequired(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return 'Required';
    if (double.tryParse(text) == null) return 'Enter a valid number';
    return null;
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}

class _FormHero extends StatelessWidget {
  const _FormHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF2563EB)],
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Row(
        children: [
          Icon(Icons.add_home_work_rounded, color: Colors.white, size: 34),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Create a complete listing so seekers can find and contact you faster.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _TextInput extends StatelessWidget {
  const _TextInput({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines = 1,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB)),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
    );
  }
}

class _DropdownInput extends StatelessWidget {
  const _DropdownInput({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
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

class _ChipSelector extends StatelessWidget {
  const _ChipSelector({
    required this.values,
    required this.selectedValues,
    required this.onChanged,
  });

  final List<String> values;
  final List<String> selectedValues;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: values.map((value) {
        final selected = selectedValues.contains(value);
        return FilterChip(
          label: Text(value),
          selected: selected,
          selectedColor: const Color(0xFFE0F2FE),
          checkmarkColor: const Color(0xFF2563EB),
          onSelected: (isSelected) {
            if (isSelected) {
              selectedValues.add(value);
            } else {
              selectedValues.remove(value);
            }
            onChanged();
          },
        );
      }).toList(),
    );
  }
}
