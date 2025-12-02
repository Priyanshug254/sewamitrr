import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../services/auth_service.dart';
import '../../services/issue_service.dart';
import '../../services/language_service.dart';
import '../../models/issue_model.dart';
import '../../theme/app_theme.dart';
import '../../utils/animations.dart';
import '../../utils/category_helper.dart';
import '../../utils/image_optimizer.dart';

class UpdateIssueScreen extends StatefulWidget {
  final IssueModel issue;

  const UpdateIssueScreen({super.key, required this.issue});

  @override
  State<UpdateIssueScreen> createState() => _UpdateIssueScreenState();
}

class _UpdateIssueScreenState extends State<UpdateIssueScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final List<XFile> _imageFiles = [];
  bool _isLoading = false;
  late String _selectedStatus;
  late double _progress;

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.issue.status;
    _progress = widget.issue.progress.toDouble();
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    if (source == ImageSource.gallery) {
      final pickedFiles = await picker.pickMultiImage();
      if (pickedFiles.isNotEmpty && mounted) {
        for (var file in pickedFiles) {
          if (kIsWeb) {
            setState(() => _imageFiles.add(file));
          } else {
            final compressed = await ImageOptimizer.compressImage(file, quality: 70, maxWidth: 1024, maxHeight: 1024);
            if (mounted) setState(() => _imageFiles.add(compressed ?? file));
          }
        }
      }
    } else {
      final pickedFile = await picker.pickImage(source: source);
      if (pickedFile != null && mounted) {
        if (kIsWeb) {
          setState(() => _imageFiles.add(pickedFile));
        } else {
          final compressed = await ImageOptimizer.compressImage(pickedFile, quality: 70, maxWidth: 1024, maxHeight: 1024);
          setState(() => _imageFiles.add(compressed ?? pickedFile));
        }
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () async {
                Navigator.pop(context);
                await _pickImage(ImageSource.camera);
                if (mounted) _showImageSourceDialog();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_imageFiles.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.check, color: Colors.green),
                title: Text('Done (${_imageFiles.length} photos)'),
                onTap: () => Navigator.pop(context),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final issueService = IssueService();

      // Upload images
      List<String> imageUrls = [];
      for (var imageFile in _imageFiles) {
        final url = await issueService.uploadFile(imageFile, 'updates', widget.issue.id!);
        if (url != null) imageUrls.add(url);
      }

      // Update issue
      final success = await issueService.updateIssueProgress(
        issueId: widget.issue.id!,
        workerId: authService.workerId!,
        description: _descriptionController.text,
        imageUrls: imageUrls,
        progress: _progress.toInt(),
        status: _selectedStatus,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Issue updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update issue'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Issue'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Original Issue Details
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: CategoryHelper.getCategoryColor(widget.issue.category).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          CategoryHelper.getCategoryIcon(widget.issue.category),
                          color: CategoryHelper.getCategoryColor(widget.issue.category),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.issue.category.toUpperCase(),
                              style: TextStyle(
                                color: CategoryHelper.getCategoryColor(widget.issue.category),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                            Text(
                              widget.issue.description,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          widget.issue.address,
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Map View
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: LatLng(widget.issue.latitude, widget.issue.longitude),
                    initialZoom: 15.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.sewamitr.worker',
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(widget.issue.latitude, widget.issue.longitude),
                          width: 40,
                          height: 40,
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.location_on, color: Colors.white, size: 24),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Update Form
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Update Progress',
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Image Upload
                    FadeInSlide(
                      delay: 0.1,
                      child: GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _imageFiles.isNotEmpty
                              ? Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: kIsWeb
                                          ? Image.network(_imageFiles.first.path, fit: BoxFit.cover, width: double.infinity)
                                          : Image.file(File(_imageFiles.first.path), fit: BoxFit.cover, width: double.infinity),
                                    ),
                                    if (_imageFiles.length > 1)
                                      Positioned(
                                        bottom: 8, right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                                          child: Text('+${_imageFiles.length - 1}', style: const TextStyle(color: Colors.white, fontSize: 12)),
                                        ),
                                      ),
                                  ],
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate, size: 32, color: Colors.grey[400]),
                                    const SizedBox(height: 4),
                                    Text('Add Progress Photos', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Status Display (Read-only)
                    FadeInSlide(
                      delay: 0.2,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _getStatusColor(_selectedStatus).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _getStatusColor(_selectedStatus).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _getStatusIcon(_selectedStatus),
                              color: _getStatusColor(_selectedStatus),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  _selectedStatus.toUpperCase().replaceAll('_', ' '),
                                  style: GoogleFonts.outfit(
                                    color: _getStatusColor(_selectedStatus),
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Progress Slider
                    FadeInSlide(
                      delay: 0.3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Progress',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey[700],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_progress.toInt()}%',
                                  style: const TextStyle(
                                    color: AppTheme.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: AppTheme.primary,
                              inactiveTrackColor: Colors.grey[200],
                              thumbColor: AppTheme.primary,
                              overlayColor: AppTheme.primary.withOpacity(0.2),
                              trackHeight: 8,
                            ),
                            child: Slider(
                              value: _progress,
                              min: 0,
                              max: 100,
                              divisions: 20,
                              onChanged: (value) {
                                setState(() {
                                  _progress = value;
                                  if (_progress == 100) {
                                    _selectedStatus = 'completed';
                                  } else if (_progress > 0) {
                                    _selectedStatus = 'in_progress';
                                  } else {
                                    _selectedStatus = 'pending';
                                  }
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Description Field
                    FadeInSlide(
                      delay: 0.4,
                      child: TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Update Notes',
                          alignLabelWithHint: true,
                          prefixIcon: Icon(Icons.notes_outlined),
                          hintText: 'Describe the work done...',
                        ),
                        maxLines: 4,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter update notes';
                          }
                          return null;
                        },
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Submit Button
                    FadeInSlide(
                      delay: 0.5,
                      child: SizedBox(
                        width: double.infinity,
                        child: ScaleButton(
                          onPressed: _isLoading ? null : _submitUpdate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            decoration: BoxDecoration(
                              gradient: AppTheme.primaryGradient,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.primary.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: _isLoading
                                ? const Center(
                                    child: SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  )
                                : Text(
                                    'Submit Update',
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'in_progress': return Colors.orange;
      default: return Colors.red;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'completed': return Icons.check_circle;
      case 'in_progress': return Icons.pending;
      default: return Icons.schedule;
    }
  }
}
