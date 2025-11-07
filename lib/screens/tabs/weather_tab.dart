import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class WeatherTab extends StatefulWidget {
  const WeatherTab({super.key});

  @override
  State<WeatherTab> createState() => _WeatherTabState();
}

class _WeatherTabState extends State<WeatherTab> {
  bool _loading = false;
  Map<String, dynamic>? _weatherData;
  String? _error;
  final String _apiKey = '64eea0111baa4433023448eee26e5f6b';
  String? _locationName;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Show location services dialog
        if (!mounted) return;
        final bool? result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location Services Disabled'),
            content: const Text(
                'Please enable location services to get weather information for your area.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Geolocator.openLocationSettings();
                  Navigator.pop(context, true);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        if (result != true) {
          setState(() {
            _error = 'Location services are required';
            _loading = false;
          });
          return;
        }
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _error = 'Location permissions are denied';
            _loading = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        final bool? result = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Location Permission Required'),
            content: const Text(
                'Location permissions are permanently denied. Please enable them in your phone settings.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Geolocator.openAppSettings();
                  Navigator.pop(context, true);
                },
                child: const Text('Open Settings'),
              ),
            ],
          ),
        );
        if (result != true) {
          setState(() {
            _error = 'Location permissions are required';
            _loading = false;
          });
          return;
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });
      await _fetchWeather();
    } catch (e) {
      setState(() {
        _error = 'Error getting location: $e';
        _loading = false;
      });
    }
  }

  Future<void> _fetchWeather() async {
    if (_currentPosition == null) return;

    try {
      final response = await http.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${_currentPosition!.latitude}&lon=${_currentPosition!.longitude}&appid=$_apiKey&units=metric'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _weatherData = data;
          _locationName = data['name'];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to fetch weather data';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  String _getCurrentDate() {
    final now = DateTime.now();
    return '${DateFormat('EEEE').format(now)} | ${DateFormat('MMM dd').format(now)}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _fetchWeather,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_weatherData == null) {
      return const Center(child: Text('No weather data available'));
    }

    final weather = _weatherData!;
    final temp = weather['main']['temp'];
    final condition = weather['weather'][0]['main'];
    final humidity = weather['main']['humidity'];
    final windSpeed = weather['wind']['speed'];
    final pressure = weather['main']['pressure'];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4A90E2), Color(0xFF357ABD)],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _getCurrentLocation,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Location and Date Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _locationName ?? 'Loading...',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _getCurrentDate(),
                      style: TextStyle(
                        color: const Color.fromRGBO(255, 255, 255, 0.8),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Main Weather Display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${temp.round()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 72,
                            fontWeight: FontWeight.w200,
                          ),
                        ),
                        const Text(
                          '°',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 72,
                            fontWeight: FontWeight.w200,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      condition,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ],
                ),
                Image.asset(
                  'assets/weather/${_getWeatherImage(weather['weather'][0]['icon'])}.png',
                  width: 120,
                  height: 120,
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Weather Details
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildWeatherDetail(
                    Icons.air,
                    '${windSpeed.toStringAsFixed(1)} km/h',
                    'Wind',
                  ),
                  _buildWeatherDetail(
                    Icons.water_drop,
                    '$humidity%',
                    'Humidity',
                  ),
                  _buildWeatherDetail(
                    Icons.compress,
                    '${pressure}hPa',
                    'Pressure',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Hourly Forecast
            _buildHourlyForecast(temp),
            const SizedBox(height: 32),

            // 7 Day Forecast
            _buildWeeklyForecast(),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherDetail(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: const Color.fromRGBO(255, 255, 255, 0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyForecast(double currentTemp) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Today',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: 24,
            itemBuilder: (context, index) {
              return Container(
                width: 60,
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color.fromRGBO(255, 255, 255, 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      '${index + 1}:00',
                      style: const TextStyle(color: Colors.white),
                    ),
                    const Icon(Icons.cloud, color: Colors.white),
                    Text(
                      '${currentTemp.round()}°',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeeklyForecast() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Next 7 Days',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 7,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color.fromRGBO(255, 255, 255, 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _getDayName(index),
                    style: const TextStyle(color: Colors.white),
                  ),
                  const Row(
                    children: [
                      Icon(Icons.cloud, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        '24°',
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  String _getDayName(int index) {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final now = DateTime.now();
    final day = now.add(Duration(days: index));
    return days[day.weekday - 1];
  }

  String _getWeatherImage(String iconCode) {
    // Map OpenWeather icon codes to your asset images
    switch (iconCode) {
      case '01d':
        return 'sunny';
      case '02d':
      case '03d':
      case '04d':
        return 'cloudy';
      case '09d':
      case '10d':
        return 'rainy';
      default:
        return 'cloudy';
    }
  }
}
