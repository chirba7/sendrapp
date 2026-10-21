import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class MapScreen extends StatefulWidget {
  final LatLng currentLocation;
  final LatLng destinationLocation;

  MapScreen({required this.currentLocation, required this.destinationLocation});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController _controller;
  Set<Marker> _markers = Set();
  Set<Polyline> _polylines = Set();
  bool _isLoading = true;
  String? _routeInfo;

  @override
  void initState() {
    super.initState();
    _fetchRoute();
  }

  Future<void> _fetchRoute() async {
    String url =
        'https://maps.googleapis.com/maps/api/directions/json?origin=${widget.currentLocation.latitude},${widget.currentLocation.longitude}&destination=${widget.destinationLocation.latitude},${widget.destinationLocation.longitude}&key=AIzaSyAQVcDF4d-55AqWUlwEfQ3-3ZM7FInCkAA';
        //j'ai générée une nouvelle clé dans le cloud, faudra donc remplacer par la nouvelle clé générée ici
    
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      var routes = data['routes'];
      if (routes.isNotEmpty) {
        var route = routes[0];
        var legs = route['legs'][0];

        List<LatLng> routePoints = [];
        routePoints.add(widget.currentLocation);  // Start from the current location marker
        for (var step in legs['steps']) {
          var polylinePoints = decodePolyline(step['polyline']['points']);
          routePoints.addAll(polylinePoints);
        }
        routePoints.add(widget.destinationLocation);  // End at the destination marker

        setState(() {
          _polylines.add(Polyline(
            polylineId: PolylineId('route'),
            points: routePoints,
            color: Colors.blueAccent,
            width: 6,
            startCap: Cap.roundCap,  // Round cap at the start
            endCap: Cap.roundCap,    // Round cap at the end
          ));

          _markers.add(Marker(
            markerId: MarkerId('start'),
            position: widget.currentLocation,
            infoWindow: InfoWindow(title: 'Départ'),
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          ));

          // Add the destination marker without infoWindow
          _markers.add(Marker(
            markerId: MarkerId('end'),
            position: widget.destinationLocation,
            infoWindow: InfoWindow(title: 'Arrivée'),  // No distance and duration here
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          ));

          _routeInfo = 'Distance: ${legs['distance']['text']}, Durée: ${legs['duration']['text']}';

          _isLoading = false;
        });

        // Ajuster la caméra pour englober les deux marqueurs
        _controller.animateCamera(
          CameraUpdate.newLatLngBounds(
            LatLngBounds(
              southwest: LatLng(
                widget.currentLocation.latitude < widget.destinationLocation.latitude
                    ? widget.currentLocation.latitude
                    : widget.destinationLocation.latitude,
                widget.currentLocation.longitude < widget.destinationLocation.longitude
                    ? widget.currentLocation.longitude
                    : widget.destinationLocation.longitude,
              ),
              northeast: LatLng(
                widget.currentLocation.latitude > widget.destinationLocation.latitude
                    ? widget.currentLocation.latitude
                    : widget.destinationLocation.latitude,
                widget.currentLocation.longitude > widget.destinationLocation.longitude
                    ? widget.currentLocation.longitude
                    : widget.destinationLocation.longitude,
              ),
            ),
            100, // Padding autour de la vue
          ),
        );
      }
    } else {
      print("Erreur lors de la récupération des itinéraires.");
    }
  }

  List<LatLng> decodePolyline(String polyline) {
    List<LatLng> polylinePoints = [];
    int index = 0, len = polyline.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int shift = 0, result = 0;
      while (true) {
        int byte = polyline.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
        if (byte < 0x20) break;
      }
      int deltaLat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += deltaLat;

      shift = 0;
      result = 0;
      while (true) {
        int byte = polyline.codeUnitAt(index++) - 63;
        result |= (byte & 0x1f) << shift;
        shift += 5;
        if (byte < 0x20) break;
      }
      int deltaLng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += deltaLng;

      polylinePoints.add(LatLng(lat / 1E5, lng / 1E5));
    }

    return polylinePoints;
  }

  void _onMapCreated(GoogleMapController controller) {
    _controller = controller;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Itinéraire détaillé'),
        backgroundColor: Colors.green,
      ),
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            initialCameraPosition: CameraPosition(
              target: widget.currentLocation,
              zoom: 14,
            ),
            markers: _markers,
            polylines: _polylines,
            mapType: MapType.normal,
            myLocationButtonEnabled: true,
            myLocationEnabled: true,
          ),
          if (_isLoading)
            Center(
              child: CircularProgressIndicator(),
            ),
          // Custom rectangle with route info at the destination marker
          if (_routeInfo != null)
            Positioned(
              bottom: 80,
              left: 10,
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  _routeInfo!,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
