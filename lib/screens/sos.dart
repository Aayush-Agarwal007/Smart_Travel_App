import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class SosScreen extends StatefulWidget {
  @override
  _SosScreenState createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  Position? _currentPosition;
  String _locationMessage = "Location not available";

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndGetLocation();
  }

  Future<void> _checkPermissionsAndGetLocation() async {
    var status = await Permission.location.status;
    if (!status.isGranted) {
      status = await Permission.location.request();
      if (!status.isGranted) {
        setState(() {
          _locationMessage = "Location permission denied";
        });
        return;
      }
    }
    _getCurrentLocation();
  }

  void _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _locationMessage =
            "Lat: ${position.latitude.toStringAsFixed(5)}, Lon: ${position.longitude.toStringAsFixed(5)}";
      });
    } catch (e) {
      setState(() {
        _locationMessage = "Error getting location: $e";
      });
    }
  }

  // Example function to send location to authorities
  // You need to implement your backend or SMS sending here
  void _sendLocationToAuthorities() {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Location not available to send")));
      return;
    }
    // For demo, just show a snackbar
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            "Location sent: Lat ${_currentPosition!.latitude}, Lon ${_currentPosition!.longitude}")));
    // TODO: Implement actual sending logic (API call or SMS)
  }

  // Call emergency number (e.g., 911 or local emergency)
  void _callEmergencyNumber() async {
    const emergencyNumber = 'tel:7496801214'; // Change to your local emergency number
    if (await canLaunch(emergencyNumber)) {
      await launch(emergencyNumber);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Could not launch phone dialer")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[900],
      appBar: AppBar(
  title: Text("SOS Emergency"),
  backgroundColor: Colors.red[700],
  centerTitle: true,
  leading: IconButton(
    icon: Icon(Icons.arrow_back),
    onPressed: () => Navigator.pop(context),
  ),
),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Your Current Location:",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              _locationMessage,
              style: TextStyle(color: Colors.white70, fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton.icon(
              icon: Icon(Icons.location_on),
              label: Text("Refresh Location"),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.red[900], backgroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                textStyle: TextStyle(fontSize: 18),
              ),
              onPressed: _getCurrentLocation,
            ),
            SizedBox(height: 30),
            ElevatedButton(
              child: Text(
                "SEND SOS",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.red[900], backgroundColor: Colors.white,
                minimumSize: Size(double.infinity, 70),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 10,
              ),
              onPressed: () {
                _sendLocationToAuthorities();
                _callEmergencyNumber();
              },
            ),
            SizedBox(height: 20),
            Text(
              "Press SEND SOS to share your location and call emergency services.",
              style: TextStyle(color: Colors.white70),
              textAlign: TextAlign.center,
            )
          ],
        ),
      ),
    );
  }
}