
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:travel_app/theme/theme.dart';
class Place {
  final String id;
  final String name;
  final String type; // e.g., "city", "attraction", "landmark"
  final String country;
  final String imageUrl;
  final String description;

  Place({
    required this.id,
    required this.name,
    required this.type,
    required this.country,
    required this.imageUrl,
    required this.description,
  });

  // Helper method to create from JSON
  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      country: json['country'],
      imageUrl: json['imageUrl'],
      description: json['description'],
    );
  }
}
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  void _showPlaceDetails(Place place) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (context) {
      return Container(
        padding: const EdgeInsets.all(16),
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              place.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${place.type} in ${place.country}",
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              width: double.infinity,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  place.imageUrl,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              place.description,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Navigate to full details screen
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: lightColorScheme.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
              child: const Text('View Full Details'),
            ),
          ],
        ),
      );
    },
  );
}
Widget _buildSearchResults() {
  if (!_isSearching) {
    return const SizedBox.shrink();
  }

  return Expanded(
    child: ListView.builder(
      itemCount: _filteredPlaces.length,
      itemBuilder: (context, index) {
        final place = _filteredPlaces[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: NetworkImage(place.imageUrl),
          ),
          title: Text(place.name),
          subtitle: Text("${place.type} • ${place.country}"),
          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
          onTap: () {
            // Navigate to place details screen
            _showPlaceDetails(place);
          },
        );
      },
    ),
  );
}
  String _currentCity = "Your City";
  final TextEditingController _searchController = TextEditingController();
  List<String> popularDestinations = [
    "Dubai", "Thailand", "Malaysia", "Sri Lanka", "Singapore",
    "Paris", "Bali", "Tokyo", "New York", "London"
  ];

  int _currentIndex = 0;
  bool _isLocationLoading = false;

  // ADD THESE VARIABLES FOR SEARCH FUNCTIONALITY:
  final List<Place> _allPlaces = [
    Place(
      id: '1',
      name: 'Dubai',
      type: 'city',
      country: 'United Arab Emirates',
      imageUrl: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
      description: 'A vibrant city known for luxury shopping, ultramodern architecture and a lively nightlife scene.',
    ),
    Place(
      id: '2',
      name: 'Thailand',
      type: 'country',
      country: 'Thailand',
      imageUrl: 'https://images.unsplash.com/photo-1528181304800-259b08848526?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
      description: 'Known for tropical beaches, opulent royal palaces, ancient ruins and ornate temples.',
    ),
    Place(
      id: '3',
      name: 'Malaysia',
      type: 'country',
      country: 'Malaysia',
      imageUrl: 'https://images.unsplash.com/photo-1596422846543-75c6fc197f07?ixlib=rb-4.0.3&auto=format&fit=crop&w=500&q=60',
      description: 'A Southeast Asian country occupying parts of the Malay Peninsula and the island of Borneo.',
    ),
    // Add more places as needed...
  ];

  List<Place> _filteredPlaces = [];
  bool _isSearching = false;

@override
void initState() {
  super.initState();
  _checkLocationStatus();
   _filteredPlaces = _allPlaces; // Initially show all places
}

  Future<void> _checkLocationStatus() async {
    // Check if location services are enabled
    bool isLocationServiceEnabled = await Geolocator.isLocationServiceEnabled();
    
    if (!isLocationServiceEnabled) {
      // Show dialog to enable location services
      _showLocationServiceDialog();
      return;
    }
    
    // If services are enabled, request permission
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLocationLoading = true;
    });
    
    final status = await Permission.location.request();
    
    if (status.isGranted) {
      await _getCurrentLocation();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied')),
      );
    }
    
    setState(() {
      _isLocationLoading = false;
    });
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      
      if (placemarks.isNotEmpty) {
        setState(() {
          _currentCity = placemarks[0].locality ?? "Your City";
        });
      }
    } catch (e) {
      print("Error getting location: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to get location')),
      );
    }
  }

  void _showLocationServiceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Location Services Disabled"),
          content: const Text("Please enable location services to use this feature."),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Geolocator.openLocationSettings();
              },
              child: const Text("Enable"),
            ),
          ],
        );
      },
    );
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      backgroundColor: lightColorScheme.primary,
      foregroundColor: Colors.white,
      title: Row(
        children: [
          // Your City Button with improved design
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: _isLocationLoading
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : TextButton.icon(
                    onPressed: _checkLocationStatus,
                    icon: const Icon(Icons.location_on, size: 18),
                    label: Text(
                      _currentCity,
                      style: TextStyle(
                        fontSize: 14,
                        color: lightColorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
          ),
          const Spacer(),
          // Hamburger Menu
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () {
              Scaffold.of(context).openEndDrawer();
            },
          ),
        ],
      ),
      elevation: 2,
      shadowColor: Colors.black.withOpacity(0.3),
    ),
    body: Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search for destinations or attractions...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _isSearching
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: _clearSearch,
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 20),
              ),
              onChanged: _searchPlaces, // This will trigger search as user types
              onSubmitted: (value) {
                _searchPlaces(value);
              },
            ),
          ),
        ),
        
        // Show search results if searching, otherwise show normal content
        if (_isSearching) 
          _buildSearchResults()
        else 
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Popular Destinations Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Popular Destinations",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: Text(
                            "See all",
                            style: TextStyle(color: lightColorScheme.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  
                  // Horizontal list of popular destinations
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: popularDestinations.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        return GestureDetector(
                          onTap: () {
                            // Search for this destination when tapped
                            _searchController.text = popularDestinations[index];
                            _searchPlaces(popularDestinations[index]);
                          },
                          child: Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 100,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircleAvatar(
                                  radius: 30,
                                  backgroundColor: lightColorScheme.primary.withOpacity(0.1),
                                  child: Icon(
                                    Icons.location_city,
                                    size: 24,
                                    color: lightColorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  popularDestinations[index],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Plan Detailed Itineraries Section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Plan Detailed Itineraries",
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              "Organize your day-to-day travel activities and create perfect travel plans.",
                              style: TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            const SizedBox(height: 15),
                            ElevatedButton(
                              onPressed: () {
                                // Navigate to itinerary planner
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: lightColorScheme.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              ),
                              child: const Text("Create Itinerary"),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    ),
    
    // Bottom Navigation Bar with improved design
    bottomNavigationBar: Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _navigateToSection(index);
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: lightColorScheme.primary,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome_outlined),
            activeIcon: Icon(Icons.auto_awesome),
            label: 'AI',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emergency_outlined),
            activeIcon: Icon(Icons.emergency),
            label: 'SOS',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.near_me_outlined),
            activeIcon: Icon(Icons.near_me),
            label: 'Nearby',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outlined),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    ),
    
    // Hamburger Menu Drawer
    endDrawer: Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: lightColorScheme.primary,
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 30, color: Colors.blue),
                ),
                SizedBox(height: 10),
                Text(
                  'Travel App',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(Icons.explore, 'Discover', () {}),
          _buildDrawerItem(Icons.favorite, 'Favorites', () {}),
          _buildDrawerItem(Icons.history, 'Travel History', () {}),
          _buildDrawerItem(Icons.bookmark, 'Bookmarks', () {}),
          const Divider(),
          _buildDrawerItem(Icons.settings, 'Settings', () {}),
          _buildDrawerItem(Icons.help, 'Help & Support', () {}),
          _buildDrawerItem(Icons.info, 'About', () {}),
          const Divider(),
          _buildDrawerItem(Icons.exit_to_app, 'Logout', () {}),
        ],
      ),
    ),
  );
}

  Widget _buildDrawerItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[700]),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      onTap: onTap,
    );
  }

 void _searchPlaces(String query) {
  if (query.isEmpty) {
    setState(() {
      _isSearching = false;
      _filteredPlaces = _allPlaces;
    });
    return;
  }

  setState(() {
    _isSearching = true;
  });

  // Filter places based on the search query
  final results = _allPlaces.where((place) {
    final name = place.name.toLowerCase();
    final country = place.country.toLowerCase();
    final type = place.type.toLowerCase();
    final searchLower = query.toLowerCase();

    return name.contains(searchLower) ||
        country.contains(searchLower) ||
        type.contains(searchLower);
  }).toList();

  setState(() {
    _filteredPlaces = results;
  });
}

void _clearSearch() {
  setState(() {
    _searchController.clear();
    _isSearching = false;
    _filteredPlaces = _allPlaces;
  });
}

  void _navigateToSection(int index) {
    switch (index) {
      case 0: // Home
        // Already on home
        break;
      case 1: // AI
        // Navigate to AI section
        break;
      case 2: // SOS
        // Navigate to SOS/emergency section
        break;
      case 3: // Nearby
        // Navigate to nearby places
        break;
      case 4: // Profile
        // Navigate to profile
        break;
    }
  }
}