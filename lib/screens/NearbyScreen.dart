import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class NearbyPlacesScreen extends StatefulWidget {
  @override
  _NearbyPlacesScreenState createState() => _NearbyPlacesScreenState();
}

class _NearbyPlacesScreenState extends State<NearbyPlacesScreen>
    with TickerProviderStateMixin {
  Position? _currentPosition;
  List<Place> _places = [];
  bool _isLoading = true;
  String _userName = "Aayush"; // You can get this from user preferences
  String _currentCity = "";
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Categories for filtering
  List<String> _categories = [
    'All',
    'Restaurant',
    'Tourist Attraction',
    'Park',
    'Shopping',
    'Hospital',
    'Gas Station',
  ];
  String _selectedCategory = 'All';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showErrorDialog('Location permission denied');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _showErrorDialog('Location permissions permanently denied');
        return;
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });

      await _getCurrentCity();
      await _fetchNearbyPlaces();
      _animationController.forward();
    } catch (e) {
      print('Error getting location: $e');
      _showErrorDialog('Failed to get current location');
    }
  }

  Future<void> _getCurrentCity() async {
    if (_currentPosition == null) return;

    try {
      // Using reverse geocoding API (you can use Google Maps Geocoding API)
      final response = await http.get(
        Uri.parse(
          'https://api.opencagedata.com/geocode/v1/json?q=${_currentPosition!.latitude}+${_currentPosition!.longitude}&key=OPENCAGE',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'].isNotEmpty) {
          setState(() {
            _currentCity =
                data['results'][0]['components']['city'] ??
                data['results'][0]['components']['town'] ??
                data['results'][0]['components']['village'] ??
                'Unknown';
          });
        }
      }
    } catch (e) {
      print('Error getting city: $e');
      setState(() {
        _currentCity = "Your Location";
      });
    }
  }

  Future<void> _fetchNearbyPlaces() async {
    if (_currentPosition == null) return;

    try {
      // Using Google Places API Nearby Search
      // Replace YOUR_GOOGLE_PLACES_API_KEY with your actual API key
      String apiKey = 'Place';
      String baseUrl =
          'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

      String url =
          '$baseUrl?location=${_currentPosition!.latitude},${_currentPosition!.longitude}'
          '&radius=5000&key=$apiKey';

      if (_selectedCategory != 'All') {
        String type = _getCategoryType(_selectedCategory);
        url += '&type=$type';
      }

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Place> places = [];

        for (var result in data['results']) {
          places.add(Place.fromJson(result, _currentPosition!));
        }

        // Sort by distance
        places.sort((a, b) => a.distance.compareTo(b.distance));

        setState(() {
          _places = places.take(20).toList(); // Limit to 20 places
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load places');
      }
    } catch (e) {
      print('Error fetching places: $e');
      // Fallback to mock data for demonstration
      _loadMockData();
    }
  }

  void _loadMockData() {
    // Mock data for demonstration
    List<Place> mockPlaces = [
      Place(
        name: 'Sukhna Lake',
        vicinity: 'Sector 1, Chandigarh',
        rating: 4.5,
        photoUrl:
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400',
        distance: 3.2,
        isOpen: true,
        category: 'Tourist Attraction',
        placeId: 'mock_1',
      ),
      Place(
        name: 'Rock Garden',
        vicinity: 'Sector 1, Chandigarh',
        rating: 4.3,
        photoUrl:
            'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=400',
        distance: 4.1,
        isOpen: true,
        category: 'Tourist Attraction',
        placeId: 'mock_2',
      ),
      Place(
        name: 'Sector 17 Market',
        vicinity: 'Sector 17, Chandigarh',
        rating: 4.2,
        photoUrl:
            'https://images.unsplash.com/photo-1441986300917-64674bd600d8?w=400',
        distance: 2.8,
        isOpen: true,
        category: 'Shopping',
        placeId: 'mock_3',
      ),
      Place(
        name: 'Rose Garden',
        vicinity: 'Sector 16, Chandigarh',
        rating: 4.4,
        photoUrl:
            'https://images.unsplash.com/photo-1518709268805-4e9042af2176?w=400',
        distance: 5.2,
        isOpen: true,
        category: 'Park',
        placeId: 'mock_4',
      ),
    ];

    setState(() {
      _places = mockPlaces;
      _isLoading = false;
      _currentCity = "Chandigarh";
    });
  }

  String _getCategoryType(String category) {
    switch (category) {
      case 'Restaurant':
        return 'restaurant';
      case 'Tourist Attraction':
        return 'tourist_attraction';
      case 'Park':
        return 'park';
      case 'Shopping':
        return 'shopping_mall';
      case 'Hospital':
        return 'hospital';
      case 'Gas Station':
        return 'gas_station';
      default:
        return '';
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F9FA),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            children: [
              _buildHeader(),
              _buildCategories(),
              Expanded(
                child: _isLoading ? _buildLoadingState() : _buildPlacesList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.white.withOpacity(0.2),
                child: Icon(Icons.person, color: Colors.white, size: 30),
              ),
              SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hey $_userName! 👋',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Discover amazing places in $_currentCity',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.location_on, color: Colors.white, size: 18),
                SizedBox(width: 5),
                Text(
                  _currentPosition != null
                      ? '${_currentPosition!.latitude.toStringAsFixed(4)}, ${_currentPosition!.longitude.toStringAsFixed(4)}'
                      : 'Getting location...',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(vertical: 10),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          bool isSelected = _categories[index] == _selectedCategory;
          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = _categories[index];
                _isLoading = true;
              });
              _fetchNearbyPlaces();
            },
            child: Container(
              margin: EdgeInsets.only(right: 15),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                      )
                    : null,
                color: isSelected ? null : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? Colors.transparent : Colors.grey[300]!,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Color(0xFF667EEA).withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                _categories[index],
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey[600],
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: 6,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }

  Widget _buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: EdgeInsets.only(bottom: 15),
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
        ),
      ),
    );
  }

  Widget _buildPlacesList() {
    if (_places.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No places found nearby',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            SizedBox(height: 8),
            Text(
              'Try changing the category or check your location',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(20),
      itemCount: _places.length,
      itemBuilder: (context, index) {
        return _buildPlaceCard(_places[index], index);
      },
    );
  }

  Widget _buildPlaceCard(Place place, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showPlaceDetails(place),
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: EdgeInsets.all(15),
          child: Row(
            children: [
              // Place Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(
                  imageUrl: place.photoUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Icon(Icons.image, color: Colors.grey[500]),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[300],
                    child: Icon(Icons.place, color: Colors.grey[500]),
                  ),
                ),
              ),
              SizedBox(width: 15),
              // Place Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[800],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    Text(
                      place.vicinity,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        RatingBarIndicator(
                          rating: place.rating,
                          itemBuilder: (context, index) =>
                              Icon(Icons.star, color: Colors.amber),
                          itemCount: 5,
                          itemSize: 16.0,
                        ),
                        SizedBox(width: 8),
                        Text(
                          place.rating.toString(),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Spacer(),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: place.isOpen
                                ? Colors.green[50]
                                : Colors.red[50],
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: place.isOpen
                                  ? Colors.green[200]!
                                  : Colors.red[200]!,
                            ),
                          ),
                          child: Text(
                            place.isOpen ? 'Open' : 'Closed',
                            style: TextStyle(
                              fontSize: 12,
                              color: place.isOpen
                                  ? Colors.green[700]
                                  : Colors.red[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(width: 10),
              // Distance
              Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF667EEA).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.navigation,
                      color: Color(0xFF667EEA),
                      size: 20,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${place.distance.toStringAsFixed(1)} km',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
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

  void _showPlaceDetails(Place place) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPlaceDetailsSheet(place),
    );
  }

  Widget _buildPlaceDetailsSheet(Place place) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: EdgeInsets.only(top: 10),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Image
          ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            child: CachedNetworkImage(
              imageUrl: place.photoUrl,
              width: double.infinity,
              height: 200,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                height: 200,
                color: Colors.grey[300],
                child: Icon(Icons.image, size: 50, color: Colors.grey[500]),
              ),
            ),
          ),
          // Details
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        color: Colors.grey[600],
                        size: 16,
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          place.vicinity,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      RatingBarIndicator(
                        rating: place.rating,
                        itemBuilder: (context, index) =>
                            Icon(Icons.star, color: Colors.amber),
                        itemCount: 5,
                        itemSize: 20.0,
                      ),
                      SizedBox(width: 8),
                      Text(
                        place.rating.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Spacer(),
                      Text(
                        '${place.distance.toStringAsFixed(1)} km away',
                        style: TextStyle(
                          fontSize: 16,
                          color: Color(0xFF667EEA),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _launchMaps(place),
                          icon: Icon(Icons.directions),
                          label: Text('Directions'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF667EEA),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _sharePlace(place),
                          icon: Icon(Icons.share),
                          label: Text('Share'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFF667EEA),
                            padding: EdgeInsets.symmetric(vertical: 12),
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
        ],
      ),
    );
  }

  void _launchMaps(Place place) async {
    final url =
        'https://www.google.com/maps/search/?api=1&query=${place.name.replaceAll(' ', '+')}';
    if (await canLaunch(url)) {
      await launch(url);
    }
  }

  void _sharePlace(Place place) {
    // Implement share functionality
    print('Sharing: ${place.name}');
  }
}

class Place {
  final String name;
  final String vicinity;
  final double rating;
  final String photoUrl;
  final double distance;
  final bool isOpen;
  final String category;
  final String placeId;

  Place({
    required this.name,
    required this.vicinity,
    required this.rating,
    required this.photoUrl,
    required this.distance,
    required this.isOpen,
    required this.category,
    required this.placeId,
  });

  factory Place.fromJson(Map<String, dynamic> json, Position currentPosition) {
    // Calculate distance
    double lat = json['geometry']['location']['lat'];
    double lng = json['geometry']['location']['lng'];
    double distance =
        Geolocator.distanceBetween(
          currentPosition.latitude,
          currentPosition.longitude,
          lat,
          lng,
        ) /
        1000; // Convert to km

    // Get photo URL
    String photoUrl =
        'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400';
    if (json['photos'] != null && json['photos'].isNotEmpty) {
      String photoReference = json['photos'][0]['photo_reference'];
      photoUrl =
          'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoReference&key=Place';
    }

    return Place(
      name: json['name'] ?? 'Unknown',
      vicinity: json['vicinity'] ?? 'Unknown location',
      rating: (json['rating'] ?? 0.0).toDouble(),
      photoUrl: photoUrl,
      distance: distance,
      isOpen: json['opening_hours']?['open_now'] ?? true,
      category: json['types']?[0] ?? 'place',
      placeId: json['place_id'] ?? '',
    );
  }
}
