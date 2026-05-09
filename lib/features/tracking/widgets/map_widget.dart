import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../app/theme/app_colors.dart';
import '../../../core/services/tracking_service.dart';
import 'truck_marker.dart';

class MapWidget extends ConsumerStatefulWidget {
  const MapWidget({super.key});

  @override
  ConsumerState<MapWidget> createState() => _MapWidgetState();
}

class _MapWidgetState extends ConsumerState<MapWidget> {
  final _mapController = MapController();
  bool _isFollowing = true;

  @override
  Widget build(BuildContext context) {
    final tracking = ref.watch(trackingProvider);

    // Listen to unit movements to animate camera
    ref.listen(trackingProvider, (previous, next) {
      if (_isFollowing && next.activeUnit != null) {
        final pos = LatLng(next.activeUnit!.latitude, next.activeUnit!.longitude);
        _mapController.move(pos, _mapController.camera.zoom);
      }
    });

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: const LatLng(6.2442, -75.5812),
            initialZoom: 15,
            onPositionChanged: (position, hasGesture) {
              if (hasGesture && _isFollowing) {
                setState(() => _isFollowing = false);
              }
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.example.urbus',
            ),
            if (tracking.activeUnit != null)
              MarkerLayer(
                markers: [
                  Marker(
                    point: LatLng(
                      tracking.activeUnit!.latitude,
                      tracking.activeUnit!.longitude,
                    ),
                    width: 80,
                    height: 80,
                    child: TruckMarker(
                      unit: tracking.activeUnit!,
                    ),
                  ),
                ],
              ),
          ],
        ),

        // ── Map Controls ──────────────────────────────────────────
        Positioned(
          right: 16,
          top: 100, // Debajo de la TopBar
          child: Column(
            children: [
              _MapButton(
                icon: _isFollowing ? Icons.navigation_rounded : Icons.explore_rounded,
                isActive: _isFollowing,
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  setState(() => _isFollowing = !_isFollowing);
                  if (_isFollowing && tracking.activeUnit != null) {
                    _mapController.move(
                      LatLng(tracking.activeUnit!.latitude, tracking.activeUnit!.longitude),
                      16,
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _MapButton(
                icon: Icons.my_location_rounded,
                onPressed: () {
                  HapticFeedback.lightImpact();
                  if (tracking.activeUnit != null) {
                    _mapController.move(
                      LatLng(tracking.activeUnit!.latitude, tracking.activeUnit!.longitude),
                      16,
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MapButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final bool isActive;

  const _MapButton({
    required this.icon,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isActive ? AppColors.accent : AppColors.glassSurface,
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? AppColors.accent : AppColors.glassBorder,
          ),
          boxShadow: AppColors.shadowLow,
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : AppColors.textPrimary,
          size: 22,
        ),
      ),
    );
  }
}
