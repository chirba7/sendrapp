import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GoogleMapRouteScreen extends StatefulWidget {
  final LatLng userLocation;
  final LatLng destination;

  GoogleMapRouteScreen({
    required this.userLocation,
    required this.destination,
  });

  @override
  _GoogleMapRouteScreenState createState() => _GoogleMapRouteScreenState();
}

class _GoogleMapRouteScreenState extends State<GoogleMapRouteScreen> {
  late GoogleMapController mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Itinéraire vers le signalement'),
        backgroundColor: Colors.green,
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: widget.userLocation,
          zoom: 12.0,
        ),
        markers: _createMarkers(),
        polylines: _createPolyline(),
        onMapCreated: (controller) {
          mapController = controller;
        },
      ),
    );
  }

  Set<Marker> _createMarkers() {
    return {
      Marker(
        markerId: MarkerId('userLocation'),
        position: widget.userLocation,
        infoWindow: InfoWindow(title: 'Votre position'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
      Marker(
        markerId: MarkerId('destination'),
        position: widget.destination,
        infoWindow: InfoWindow(title: 'Signalement'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
      ),
    };
  }

  Set<Polyline> _createPolyline() {
    // Exemple de polyline (vous pouvez utiliser un service de calcul d'itinéraire pour générer une polyline entre les deux points)
    return {
      Polyline(
        polylineId: PolylineId('route'),
        points: [widget.userLocation, widget.destination],
        color: Colors.green,
        width: 5,
      ),
    };
  }
}
