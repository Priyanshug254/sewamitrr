import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:latlong2/latlong.dart';
import '../../widgets/map_picker.dart';
import '../../services/language_service.dart';
import '../../services/issue_service.dart';
import '../../services/location_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/animations.dart';
import '../../utils/image_optimizer.dart';
import '../../models/issue_model.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key});

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  String _selectedCategory = 'road';
  List<XFile> _imageFiles = [];
  String? _audioPath;
  bool _isLoading = false;
  bool _locationLoading = false;
  bool _isRecording = false;
  String _address = '';
  double? _latitude;
  double? _longitude;
  int _recordingSeconds = 0;
  
  final AudioRecorder _audioRecorder = AudioRecorder();
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  final List<Map<String, dynamic>> _categories = [
    {'id': 'road', 'name': 'Road', 'icon': Icons.add_road, 'color': Colors.orange},
    {'id': 'water', 'name': 'Water', 'icon': Icons.water_drop, 'color': Colors.blue},
    {'id': 'electricity', 'name': 'Electricity', 'icon': Icons.electric_bolt, 'color': Colors.amber},
    {'id': 'garbage', 'name': 'Garbage', 'icon': Icons.delete_outline, 'color': Colors.green},
    {'id': 'street_light', 'name': 'Street Light', 'icon': Icons.lightbulb_outline, 'color': Colors.purple},
    {'id': 'drainage', 'name': 'Drainage', 'icon': Icons.water_damage, 'color': Colors.brown},
    {'id': 'park', 'name': 'Park', 'icon': Icons.park, 'color': Colors.lightGreen},
    {'id': 'traffic', 'name': 'Traffic', 'icon': Icons.traffic, 'color': Colors.red},
    {'id': 'noise', 'name': 'Noise', 'icon': Icons.volume_up, 'color': Colors.deepOrange},
    {'id': 'other', 'name': 'Other', 'icon': Icons.more_horiz, 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _audioRecorder.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _locationLoading = true);
    try {
      final position = await LocationService().getCurrentLocation();
      final address = await LocationService().getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _address = address;
        _locationLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _locationLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
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

  Future<void> _toggleRecording() async {
    try {
      if (_isRecording) {
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _audioPath = path;
          _recordingSeconds = 0;
        });
      } else {
        if (await _audioRecorder.hasPermission()) {
          final directory = await getApplicationDocumentsDirectory();
          final path = '${directory.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
          
          await _audioRecorder.start(
            const RecordConfig(
              encoder: AudioEncoder.aacLc,
              bitRate: 64000,
              sampleRate: 22050,
            ),
            path: path,
          );
          setState(() {
            _isRecording = true;
            _recordingSeconds = 0;
          });
          _startTimer();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error recording audio: $e')),
      );
    }
  }

  void _startTimer() {
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (_isRecording && mounted) {
        setState(() => _recordingSeconds++);
        return true;
      }
      return false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageService = context.watch<LanguageService>();

    return Scaffold(
      appBar: AppBar(
        title: Text(languageService.translate('report_issue')),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Media Section (Image & Audio)
              FadeInSlide(
                delay: 0.1,
                child: Row(
                  children: [
                    // Image Picker
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showImageSourceDialog(),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.grey[300]!),
                          ),
                          child: _imageFiles.isNotEmpty && _imageFiles.first != null
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
                                    Icon(Icons.camera_alt, size: 32, color: Colors.grey[400]),
                                    const SizedBox(height: 4),
                                    Text('Add Photos', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                                  ],
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Audio Recorder
                    Expanded(
                      child: GestureDetector(
                        onTap: _toggleRecording,
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: _isRecording ? Colors.red[50] : Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _isRecording ? Colors.red : Colors.grey[300]!,
                              width: _isRecording ? 2 : 1,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isRecording && _pulseAnimation != null)
                                AnimatedBuilder(
                                  animation: _pulseAnimation!,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _pulseAnimation!.value,
                                      child: Icon(
                                        Icons.mic,
                                        size: 32,
                                        color: Colors.red,
                                      ),
                                    );
                                  },
                                )
                              else
                                Icon(
                                  _audioPath != null ? Icons.check_circle : Icons.mic,
                                  size: 32,
                                  color: _audioPath != null ? Colors.green : Colors.grey[400],
                                ),
                              const SizedBox(height: 4),
                              Text(
                                _isRecording 
                                    ? '${_recordingSeconds}s' 
                                    : (_audioPath != null ? 'Audio Recorded' : 'Add Audio'),
                                style: TextStyle(
                                  color: _isRecording ? Colors.red : (_audioPath != null ? Colors.green : Colors.grey[600]),
                                  fontSize: 12,
                                  fontWeight: _isRecording ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                              if (_isRecording && _pulseController != null && _pulseAnimation != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: List.generate(3, (index) {
                                      return AnimatedBuilder(
                                        animation: _pulseController!,
                                        builder: (context, child) {
                                          return Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 2),
                                            width: 4,
                                            height: 12 + (8 * _pulseAnimation!.value * ((index + 1) / 3)),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(2),
                                            ),
                                          );
                                        },
                                      );
                                    }),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Location Section
              FadeInSlide(
                delay: 0.2,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue[50]!, Colors.blue[100]!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.blue.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _locationLoading
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2.5),
                                  )
                                : const Icon(Icons.location_on, color: Colors.blue, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  languageService.translate('location'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _address.isEmpty ? 'Fetching location...' : _address,
                                  style: TextStyle(
                                    color: Colors.blue[900],
                                    fontSize: 13,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _getCurrentLocation,
                              icon: const Icon(Icons.my_location, size: 18),
                              label: const Text(
                                'Current\nLocation',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, height: 1.2),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: Colors.blue[200]!),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                if (_latitude == null || _longitude == null) {
                                  await _getCurrentLocation();
                                }
                                
                                if (!mounted) return;
                                
                                final LatLng? result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => MapPicker(
                                      initialLat: _latitude ?? 28.6139,
                                      initialLng: _longitude ?? 77.2090,
                                    ),
                                  ),
                                );

                                if (result != null) {
                                  setState(() => _locationLoading = true);
                                  try {
                                    final address = await LocationService().getAddressFromCoordinates(
                                      result.latitude,
                                      result.longitude,
                                    );
                                    
                                    if (!mounted) return;
                                    setState(() {
                                      _latitude = result.latitude;
                                      _longitude = result.longitude;
                                      _address = address;
                                      _locationLoading = false;
                                    });
                                  } catch (e) {
                                    if (!mounted) return;
                                    setState(() {
                                      _latitude = result.latitude;
                                      _longitude = result.longitude;
                                      _address = '${result.latitude.toStringAsFixed(4)}, ${result.longitude.toStringAsFixed(4)}';
                                      _locationLoading = false;
                                    });
                                  }
                                }
                              },
                              icon: const Icon(Icons.map, size: 18),
                              label: const Text(
                                'Pick on\nMap',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 11, height: 1.2),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                elevation: 2,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Category Selection (Icons)
              FadeInSlide(
                delay: 0.3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      languageService.translate('category'),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final itemWidth = (constraints.maxWidth - 48) / 4;
                        return Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: _categories.map((category) {
                            final isSelected = _selectedCategory == category['id'];
                            return GestureDetector(
                              onTap: () => setState(() => _selectedCategory = category['id']),
                              child: Container(
                                width: itemWidth,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? (category['color'] as Color).withOpacity(0.1) 
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected 
                                    ? (category['color'] as Color) 
                                    : Colors.grey[200]!,
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Icon(
                                  category['icon'],
                                  color: isSelected 
                                      ? (category['color'] as Color) 
                                      : Colors.grey[400],
                                  size: 28,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  category['name'] ?? category['id'].toString().toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected 
                                        ? (category['color'] as Color) 
                                        : Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                              ),
                            );
                          }).toList(),
                        );
                      },
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
                  decoration: InputDecoration(
                    labelText: languageService.translate('description'),
                    alignLabelWithHint: true,
                    prefixIcon: const Icon(Icons.description_outlined),
                  ),
                  maxLines: 4,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return languageService.translate('please_enter_description');
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
                    onPressed: _isLoading ? null : _submitIssue,
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
                              languageService.translate('submit_report'),
                              style: const TextStyle(
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
    );
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

  Future<void> _submitIssue() async {
    if (!_formKey.currentState!.validate()) return;
    if (_latitude == null || _longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location is required')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final issueService = IssueService();

      final issue = IssueModel(
        userId: authService.currentUser!.id,
        category: _selectedCategory,
        description: _descriptionController.text,
        latitude: _latitude!,
        longitude: _longitude!,
        address: _address,
        mediaUrls: [],
        audioUrl: null,
        createdAt: DateTime.now(),
        status: 'pending',
      );

      final issueId = await issueService.createIssue(issue);

      List<String> mediaUrls = [];
      for (var imageFile in _imageFiles) {
        final url = await issueService.uploadFile(imageFile, 'issues', issueId);
        if (url != null) mediaUrls.add(url);
      }

      String? audioUrl;
      if (_audioPath != null) {
        final audioFile = XFile(_audioPath!);
        audioUrl = await issueService.uploadFile(audioFile, 'audio', issueId);
      }

      await issueService.updateIssueMedia(issueId, mediaUrls, audioUrl);

      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.read<LanguageService>().translate('issue_reported_successfully')),
          backgroundColor: Colors.green,
        ),
      );
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
}