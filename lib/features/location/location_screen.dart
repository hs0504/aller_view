import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';

import '../../core/network/dio_client.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'restaurant_detail_screen.dart';

class LocationScreen extends StatefulWidget {
  const LocationScreen({super.key});

  @override
  State<LocationScreen> createState() => _LocationScreenState();
}

class _LocationScreenState extends State<LocationScreen> {
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  // 패널 표시 여부를 제어하는 상태 변수. 필요에 따라 true/false로 바꿔 테스트할 수 있습니다.
  final bool _showPanel = true;
  final Location _location = Location();
  LatLng _currentPosition = const LatLng(37.5664, 126.9778); // 기본 위치 (서울)
  List<dynamic> _restaurants = [];
  final DioClient _dioClient = DioClient();
  String _searchQuery = '';
  final PanelController _panelController = PanelController();
  double _panelPosition = 0.0; // 0.0(접힘) ~ 1.0(완전히 열림)

  @override
  void initState() {
    super.initState();
    _checkPermissionAndFetchLocation();
  }

  Future<void> _checkPermissionAndFetchLocation() async {
    // 위치 권한 요청
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) return;
    }

    PermissionStatus permissionGranted = await _location.hasPermission();
    if (permissionGranted == PermissionStatus.denied) {
      permissionGranted = await _location.requestPermission();
      if (permissionGranted != PermissionStatus.granted) return;
    }

    // 위치 가져오기
    final locationData = await _location.getLocation();
    if (locationData.latitude != null && locationData.longitude != null) {
      setState(() {
        _currentPosition = LatLng(
          locationData.latitude!,
          locationData.longitude!,
        );
      });
    } else {
      if (kDebugMode) {
        print("Cannot fetch location data.");
      }
      return;
    }

    // 지도 초기화 완료 후 카메라 이동
    final controller = await _controllerCompleter.future;
    controller.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition, 14),
    );

    try {
      final response = await _dioClient.get(
        '/restaurants/nearby-restaurants',
        queryParams: {
          'lat': _currentPosition.latitude,
          'lng': _currentPosition.longitude,
        },
      );
      if (response != null && response.statusCode == 200) {
        final List<dynamic> data = response.data;
        setState(() {
          _restaurants = data.map((restaurant) {
            return {
              'id': restaurant['place_id'] ?? 'unknown_id',
              'name': restaurant['name'] ?? 'Unknown Restaurant',
              'address': restaurant['address'] ?? '주소 정보 없음',
              'latitude': (restaurant['latitude'] ?? 0.0).toDouble(),
              'longitude': (restaurant['longitude'] ?? 0.0).toDouble(),
              'type': restaurant['business_type'] ?? '기타',
              'positive_count': restaurant['positive_count'] ?? 0,
              'negative_count': restaurant['negative_count'] ?? 0,
            };
          }).toList();
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error fetching restaurants: $e");
      }
    }

    controller.animateCamera(
      CameraUpdate.newLatLngZoom(_currentPosition, 16),
    );
  }

  Set<Marker> _buildMarkers() {
    return _restaurants
        .where(
          (r) => r['name']
          .toString()
          .toLowerCase()
          .contains(_searchQuery.toLowerCase()),
    )
        .map((r) {
      return Marker(
          markerId: MarkerId(r['id']),
          position: LatLng(r['latitude'], r['longitude']),
          infoWindow: InfoWindow(
            title: r['name'],
            snippet: '${r['type']} · 안전 ${r['positive_count']}개 위험 ${r['negative_count']}개',
          ),
          onTap: () {
            // 마커를 탭했을 때 패널을 열고 싶다면 이 코드를 사용하세요.
            if (!_panelController.isPanelOpen) {
              _panelController.open();
            }
          }
      );
    })
        .toSet();
  }

  @override
  Widget build(BuildContext context) {
    const double panelMinHeight = 160;
    // const double panelTopBuffer = 8.0;
    final double panelMaxHeight = MediaQuery.of(context).size.height * 0.5;
    final double mapBottomPadding =
        panelMinHeight  + (panelMaxHeight - panelMinHeight) * _panelPosition;

    // 1. 지도와 검색창을 포함하는 body 부분을 별도 변수로 추출
    final mapBody = Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          top: 0,
          bottom: mapBottomPadding,
          left: 0,
          right: 0,
          child: GoogleMap(
            padding: EdgeInsets.only(bottom: _showPanel ? mapBottomPadding : 0), // <--- 이 줄을 추가하세요.
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 16.0,
            ),
            myLocationEnabled: true,
            markers: _buildMarkers(),
            mapType: MapType.normal,
            onMapCreated: (GoogleMapController controller) {
              if (!_controllerCompleter.isCompleted) {
                _controllerCompleter.complete(controller);
              }
            },
          ),
        ),

        // 검색창
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            color: Colors.white.withOpacity(0.9),
            child: Row(
              children: [
                const BackButton(color: Colors.black),
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
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
                  onPressed: () {
                    // 키보드 숨기기 등 검색 로직 추가 가능
                    FocusScope.of(context).unfocus();
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );

    return Scaffold(
      body: SafeArea(
        // 2. _showPanel 값에 따라 조건부로 위젯 렌더링
        child: _showPanel
            ? SlidingUpPanel(
          controller: _panelController,
          minHeight: panelMinHeight,
          maxHeight: panelMaxHeight,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          onPanelSlide: (pos) => setState(() => _panelPosition = pos),
          panel: _buildRestaurantList(),
          body: mapBody,
        )
            : mapBody, // _showPanel이 false이면 패널 없이 mapBody만 표시
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

    return Column(
      children: [
        // 드래그 핸들
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
                "주변 식당 ${filtered.length}곳",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(child: Text("근처 식당 정보를 불러오는 중..."))
              : ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final r = filtered[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => RestaurantDetailScreen(
                      placeId: r['id'],
                      name: r['name'],
                      address: r['address'],
                      businessType: r['type'],
                    ),
                  ),
                ),
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
                        color: Colors.black.withOpacity(0.07),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.restaurant,
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
                                '안전 ${r['positive_count']}개',
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
                                '위험 ${r['negative_count']}개',
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
