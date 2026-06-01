import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import '../../core/network/dio_client.dart';
import '../../core/storage/user_prefs.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'restaurant_detail_screen.dart';

enum _SortMode { safest, mostReviewed }

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  final bool _showPanel = true;
  final Location _location = Location();
  LatLng _currentPosition = const LatLng(37.5664, 126.9778);
  List<dynamic> _restaurants = [];
  final DioClient _dioClient = DioClient();
  String _searchQuery = '';
  final PanelController _panelController = PanelController();
  _SortMode _sortMode = _SortMode.mostReviewed;
  bool _hasAllergySettings = false;
  bool _isSearchMode = false;
  bool _isSearchLoading = false;
  List<dynamic> _nearbyRestaurants = [];
  Timer? _debounceTimer;

  // 지도 이동 / 다시 검색
  LatLng _cameraCenter = const LatLng(37.5664, 126.9778);
  bool _showResearchButton = false;
  bool _isProgrammaticMove = false;

  @override
  void initState() {
    super.initState();
    _loadAllergySettings();
    _checkPermissionAndFetchLocation();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadAllergySettings() async {
    final ids = await UserPrefs.loadAllergyIds();
    if (mounted) setState(() => _hasAllergySettings = ids.isNotEmpty);
  }

  Future<void> _checkPermissionAndFetchLocation() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        await _fetchNearbyRestaurants(_currentPosition);
        return;
      }
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) {
        // 권한 거부 시 기본 위치(서울)로 음식점 로드
        await _fetchNearbyRestaurants(_currentPosition);
        return;
      }
    }

    final locationData = await _location.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      setState(() {
        _currentPosition = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
        _cameraCenter = _currentPosition;
      });
    } else {
      if (kDebugMode) print("Cannot fetch location data.");
      await _fetchNearbyRestaurants(_currentPosition);
      return;
    }

    _isProgrammaticMove = true;
    final controller = await _controllerCompleter.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition, 14),
    );

    await _fetchNearbyRestaurants(_currentPosition);

    _isProgrammaticMove = true;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition, 16),
    );
  }

  List<Map<String, dynamic>> _mapRestaurants(List<dynamic> data) {
    return data.map((r) => {
      'id': r['place_id'] ?? 'unknown_id',
      'name': r['name'] ?? 'Unknown Restaurant',
      'address': r['address'] ?? '주소 정보 없음',
      'latitude': (r['latitude'] ?? 0.0).toDouble(),
      'longitude': (r['longitude'] ?? 0.0).toDouble(),
      'type': r['business_type'] ?? '기타',
      'positive_count': r['positive_count'] ?? 0,
      'negative_count': r['negative_count'] ?? 0,
      'safe_count': r['safe_count'],
    }).toList();
  }

  Future<void> _fetchNearbyRestaurants(LatLng position) async {
    try {
      final allergyIds = await UserPrefs.loadAllergyIds();
      final response = await _dioClient.get(
        '/restaurants/nearby-restaurants',
        queryParams: {
          'lat': position.latitude,
          'lng': position.longitude,
          if (allergyIds.isNotEmpty) 'allergy_ids': allergyIds.join(','),
        },
      );
      if (response != null && response.statusCode == 200) {
        final mapped = _mapRestaurants(response.data as List<dynamic>);
        if (mounted) {
          setState(() {
            _restaurants = mapped;
            _nearbyRestaurants = List.from(mapped);
            _showResearchButton = false;
          });
        }
      }
    } catch (e) {
      if (kDebugMode) print("Error fetching restaurants: $e");
    }
  }

  Future<void> _fetchSearchResults(String query) async {
    setState(() => _isSearchLoading = true);
    try {
      final allergyIds = await UserPrefs.loadAllergyIds();
      final response = await _dioClient.get(
        '/restaurants/search',
        queryParams: {
          'q': query,
          'lat': _currentPosition.latitude,
          'lng': _currentPosition.longitude,
          if (allergyIds.isNotEmpty) 'allergy_ids': allergyIds.join(','),
        },
      );
      if (response != null && response.statusCode == 200) {
        final mapped = _mapRestaurants(response.data as List<dynamic>);
        if (mounted) {
          setState(() {
            _restaurants = mapped;
            _isSearchMode = true;
            _isSearchLoading = false;
          });
          // 검색 결과 마커들이 모두 보이도록 카메라 자동 맞춤
          if (mapped.isNotEmpty) {
            _isProgrammaticMove = true;
            final controller = await _controllerCompleter.future;
            if (mapped.length == 1) {
              final r = mapped.first;
              controller.animateCamera(
                CameraUpdate.newLatLngZoom(
                  LatLng(r['latitude'] as double, r['longitude'] as double),
                  16,
                ),
              );
            } else {
              double minLat = double.infinity, maxLat = -double.infinity;
              double minLng = double.infinity, maxLng = -double.infinity;
              for (final r in mapped) {
                final lat = r['latitude'] as double;
                final lng = r['longitude'] as double;
                if (lat < minLat) minLat = lat;
                if (lat > maxLat) maxLat = lat;
                if (lng < minLng) minLng = lng;
                if (lng > maxLng) maxLng = lng;
              }
              controller.animateCamera(
                CameraUpdate.newLatLngBounds(
                  LatLngBounds(
                    southwest: LatLng(minLat, minLng),
                    northeast: LatLng(maxLat, maxLng),
                  ),
                  80,
                ),
              );
            }
          }
        }
      } else {
        if (mounted) setState(() => _isSearchLoading = false);
      }
    } catch (e) {
      if (kDebugMode) print('Search error: $e');
      if (mounted) setState(() => _isSearchLoading = false);
    }
  }

  IconData _iconForType(String type) {
    final t = type.toLowerCase();
    if (t.contains('카페') || t.contains('커피') || t.contains('cafe')) return Icons.local_cafe;
    if (t.contains('베이커리') || t.contains('빵') || t.contains('bakery')) return Icons.bakery_dining;
    if (t.contains('피자')) return Icons.local_pizza;
    if (t.contains('치킨') || t.contains('닭')) return Icons.set_meal;
    if (t.contains('라멘') || t.contains('일식') || t.contains('초밥') || t.contains('스시') || t.contains('중국 음식점')) return Icons.ramen_dining;
    if (t.contains('편의점') || t.contains('마트')) return Icons.store;
    if (t.contains('패스트푸드') || t.contains('햄버거') || t.contains('버거')) return Icons.fastfood;
    if (t.contains('한식당')) return Icons.rice_bowl;
    if (t.contains('바') || t.contains('이자카야') || t.contains('주점')) return Icons.local_bar;
    if (t.contains('분식') || t.contains('김밥')) return Icons.rice_bowl;
    return Icons.restaurant;
  }

  Set<Marker> _buildMarkers() {
    return _restaurants
        .where((r) => r['name']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase()))
        .map((r) {
      return Marker(
        markerId: MarkerId(r['id']),
        position: LatLng(r['latitude'], r['longitude']),
        infoWindow: InfoWindow(
          title: r['name'],
          snippet: '탭하여 리뷰 보러가기 →',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RestaurantDetailScreen(
                placeId: r['id'] as String,
                name: r['name'] as String,
                address: r['address'] as String,
                businessType: r['type'] as String,
              ),
            ),
          ),
        ),
      );
    }).toSet();
  }

  @override
  Widget build(BuildContext context) {
    const double panelMinHeight = 160;
    const double mapBottomOffset = panelMinHeight + 80;
    final double panelMaxHeight = MediaQuery.of(context).size.height * 0.6;

    final mapBody = Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          bottom: mapBottomOffset,
          left: 0,
          right: 0,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 16.0,
            ),
            myLocationEnabled: true,
            markers: _buildMarkers(),
            mapType: MapType.normal,
            padding: const EdgeInsets.only(top: 60),
            onMapCreated: (GoogleMapController controller) {
              if (!_controllerCompleter.isCompleted) {
                _controllerCompleter.complete(controller);
              }
            },
            onCameraMove: (CameraPosition pos) {
              _cameraCenter = pos.target;
            },
            onCameraIdle: () {
              if (_isProgrammaticMove) {
                _isProgrammaticMove = false;
                return;
              }
              if (mounted) setState(() => _showResearchButton = true);
            },
          ),
        ),

        // 검색창
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: Colors.white.withValues(alpha: 0.9),
            child: Row(
              children: [
                const BackButton(color: Colors.black),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                      _debounceTimer?.cancel();
                      if (value.trim().isEmpty) {
                        setState(() {
                          _restaurants = _nearbyRestaurants;
                          _isSearchMode = false;
                          _isSearchLoading = false;
                        });
                      } else {
                        _debounceTimer = Timer(
                          const Duration(milliseconds: 500),
                          () => _fetchSearchResults(value.trim()),
                        );
                      }
                    },
                    style: const TextStyle(fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "식당 이름을 검색하세요...",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black),
                  onPressed: () => FocusScope.of(context).unfocus(),
                ),
              ],
            ),
          ),
        ),

        // "다시 검색" 버튼 — 검색창 아래
        if (_showResearchButton)
          Positioned(
            top: 68,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () async {
                  setState(() {
                    _showResearchButton = false;
                  });
                  _isProgrammaticMove = true;
                  final controller = await _controllerCompleter.future;
                  controller.animateCamera(
                    CameraUpdate.newLatLng(_cameraCenter),
                  );
                  await _fetchNearbyRestaurants(_cameraCenter);
                  if (mounted) {
                    setState(() {
                      _isSearchMode = false;
                      _searchQuery = '';
                    });
                  }
                },
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('이 위치에서 다시 검색'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 4,
                  shape: const StadiumBorder(),
                ),
              ),
            ),
          ),

      ],
    );

    return Scaffold(
      body: SafeArea(
        child: _showPanel
            ? SlidingUpPanel(
                controller: _panelController,
                minHeight: panelMinHeight,
                maxHeight: panelMaxHeight,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                panel: _buildRestaurantList(),
                body: mapBody,
              )
            : mapBody,
      ),
    );
  }

  Widget _buildRestaurantList() {
    final filtered = _restaurants
        .where(
          (r) => _searchQuery.isEmpty ||
              r['name']
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()),
        )
        .toList();

    final sorted = List<dynamic>.from(filtered);
    if (_sortMode == _SortMode.safest) {
      sorted.sort((a, b) =>
          ((b['safe_count'] ?? 0) as int)
              .compareTo((a['safe_count'] ?? 0) as int));
    } else if (_sortMode == _SortMode.mostReviewed) {
      sorted.sort((a, b) {
        final bTotal = (b['positive_count'] as int) + (b['negative_count'] as int);
        final aTotal = (a['positive_count'] as int) + (a['negative_count'] as int);
        return bTotal.compareTo(aTotal);
      });
    }

    return Column(
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Text(
                _isSearchMode
                    ? '검색 결과 ${sorted.length}곳'
                    : '주변 식당 ${sorted.length}곳',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              DropdownButton<_SortMode>(
                value: _sortMode,
                underline: const SizedBox.shrink(),
                isDense: true,
                style: const TextStyle(fontSize: 13, color: Colors.black87),
                items: [
                  const DropdownMenuItem(
                    value: _SortMode.mostReviewed,
                    child: Text('리뷰 많은 순'),
                  ),
                  if (_hasAllergySettings)
                    const DropdownMenuItem(
                      value: _SortMode.safest,
                      child: Text('안전 많은 순'),
                    ),
                ],
                onChanged: (mode) {
                  if (mode != null) setState(() => _sortMode = mode);
                },
              ),
            ],
          ),
        ),
        Expanded(
          child: _isSearchLoading
              ? const Center(child: CircularProgressIndicator())
              : sorted.isEmpty
                  ? Center(
                      child: Text(
                        _isSearchMode ? '검색 결과가 없습니다' : '근처 식당 정보를 불러오는 중...',
                      ),
                    )
                  : ListView.builder(
                      itemCount: sorted.length,
                      itemBuilder: (context, index) {
                        final r = sorted[index];
                        return GestureDetector(
                          onTap: () async {
                            _isProgrammaticMove = true;
                            final controller = await _controllerCompleter.future;
                            await controller.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(
                                  r['latitude'] as double,
                                  r['longitude'] as double,
                                ),
                                16,
                              ),
                            );
                            controller.showMarkerInfoWindow(
                              MarkerId(r['id'] as String),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.07),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _iconForType(r['type'] as String),
                                  size: 32,
                                  color: Colors.pink[300],
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r['name'],
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        r['type'],
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.check_circle,
                                            size: 14, color: Colors.green),
                                        const SizedBox(width: 3),
                                        Text(
                                          '안전 ${r['positive_count']}건',
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.green),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.cancel,
                                            size: 14, color: Colors.red),
                                        const SizedBox(width: 3),
                                        Text(
                                          '위험 ${r['negative_count']}건',
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
