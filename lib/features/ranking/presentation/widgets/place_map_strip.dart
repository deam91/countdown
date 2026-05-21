import 'package:countdown/core/theme/color_tokens.dart';
import 'package:countdown/core/theme/radii.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Read-only 40pt-tall OSM mini-map for a `PlaceItem`'s row in the
/// ranking screen. Single brand-purple pin centered on (lat, lng).
/// All interaction disabled — taps fall through to the card.
class PlaceMapStrip extends StatelessWidget {
  const PlaceMapStrip({
    required this.lat,
    required this.lng,
    super.key,
  });

  final double lat;
  final double lng;

  static const double _height = 40;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(lat, lng);
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(Radii.image)),
      child: SizedBox(
        height: _height,
        child: IgnorePointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: point,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'app.countdown.dev',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 24,
                    height: 24,
                    child: const Icon(
                      LucideIcons.mapPin,
                      size: 20,
                      color: ColorTokens.brandPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
