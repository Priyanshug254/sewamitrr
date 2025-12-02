import 'package:flutter/material.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'dart:js' as js;
import '../../services/location_service.dart';

class WebMapPicker extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const WebMapPicker({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<WebMapPicker> createState() => _WebMapPickerState();
}

class _WebMapPickerState extends State<WebMapPicker> {
  double? _selectedLat;
  double? _selectedLng;
  String _address = '';
  bool _loadingAddress = false;
  final String _mapDivId = 'map-${DateTime.now().millisecondsSinceEpoch}';
  dynamic _map;
  dynamic _marker;

  @override
  void initState() {
    super.initState();
    _selectedLat = widget.initialLat ?? 28.6139;
    _selectedLng = widget.initialLng ?? 77.2090;
    _initMap();
  }

  void _initMap() {
    // Register the map div
    ui_web.platformViewRegistry.registerViewFactory(_mapDivId, (int viewId) {
      final mapDiv = html.DivElement()
        ..id = _mapDivId
        ..style.width = '100%'
        ..style.height = '100%';

      // Initialize map after a short delay
      Future.delayed(const Duration(milliseconds: 100), () {
        _createMap(mapDiv);
      });

      return mapDiv;
    });

    if (widget.initialLat != null && widget.initialLng != null) {
      _getAddress(_selectedLat!, _selectedLng!);
    }
  }

  void _createMap(html.DivElement mapDiv) {
    try {
      // Create Leaflet map
      _map = js.context['L'].callMethod('map', [mapDiv]);

      // Set view to selected location
      _map.callMethod('setView', [
        js.JsArray.from([_selectedLat, _selectedLng]),
        15
      ]);

      // Add OpenStreetMap tiles
      js.context['L'].callMethod('tileLayer', [
        'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
        js.JsObject.jsify({
          'attribution': '© OpenStreetMap',
          'maxZoom': 19,
        })
      ]).callMethod('addTo', [_map]);

      // Add draggable marker
      _marker = js.context['L'].callMethod('marker', [
        js.JsArray.from([_selectedLat, _selectedLng]),
        js.JsObject.jsify({'draggable': true})
      ]).callMethod('addTo', [_map]);

      // Listen to marker drag
      _marker.callMethod('on', [
        'dragend',
        js.allowInterop((event) {
          try {
            final latlng = event['target'].callMethod('getLatLng');
            final lat = latlng['lat'] as double;
            final lng = latlng['lng'] as double;
            _updateLocation(lat, lng);
          } catch (e) {
            print('Drag error: $e');
          }
        })
      ]);

      // Listen to map clicks
      _map.callMethod('on', [
        'click',
        js.allowInterop((event) {
          try {
            final latlng = event['latlng'];
            final lat = latlng['lat'] as double;
            final lng = latlng['lng'] as double;
            
            // Update marker position
            _marker.callMethod('setLatLng', [
              js.JsArray.from([lat, lng])
            ]);
            
            _updateLocation(lat, lng);
          } catch (e) {
            print('Click error: $e');
          }
        })
      ]);
    } catch (e) {
      print('Map creation error: $e');
    }
  }

  void _updateLocation(double lat, double lng) {
    if (!mounted) return;
    setState(() {
      _selectedLat = lat;
      _selectedLng = lng;
    });
    _getAddress(lat, lng);
  }

  Future<void> _getAddress(double lat, double lng) async {
    if (!mounted) return;
    setState(() => _loadingAddress = true);
    try {
      final address = await LocationService().getAddressFromCoordinates(lat, lng);
      if (!mounted) return;
      setState(() {
        _address = address;
        _loadingAddress = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _address = 'Unable to get address';
        _loadingAddress = false;
      });
    }
  }

  void _confirmLocation() {
    Navigator.pop(context, {
      'latitude': _selectedLat,
      'longitude': _selectedLng,
      'address': _address,
    });
  }

  Future<void> _useMyLocation() async {
    try {
      final position = await LocationService().getCurrentLocation();
      if (!mounted) return;
      final lat = position.latitude;
      final lng = position.longitude;
      
      // Update marker and map
      if (_marker != null && _map != null) {
        _marker.callMethod('setLatLng', [js.JsArray.from([lat, lng])]);
        _map.callMethod('setView', [js.JsArray.from([lat, lng]), 15]);
      }
      
      _updateLocation(lat, lng);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to get location: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Location'),
        actions: [
          IconButton(
            onPressed: _useMyLocation,
            icon: const Icon(Icons.my_location),
            tooltip: 'Use My Location',
          ),
          TextButton(
            onPressed: _confirmLocation,
            child: const Text(
              'CONFIRM',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          HtmlElementView(viewType: _mapDivId),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selected Location',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  if (_loadingAddress)
                    const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 8),
                        Text('Getting address...'),
                      ],
                    )
                  else
                    Text(
                      _address,
                      style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    ),
                  const SizedBox(height: 8),
                  Text(
                    'Lat: ${_selectedLat?.toStringAsFixed(6)}, Lng: ${_selectedLng?.toStringAsFixed(6)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap on map or drag marker to change location',
                    style: TextStyle(fontSize: 12, color: Colors.blue, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _confirmLocation,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2196F3),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'CONFIRM LOCATION',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
