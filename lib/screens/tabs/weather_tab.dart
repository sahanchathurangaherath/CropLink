import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:geolocator/geolocator.dart';

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

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _error = 'Location services are disabled. Please enable the services';
      });
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          _error = 'Location permissions are denied';
        });
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _error =
            'Location permissions are permanently denied, we cannot request permissions.';
      });
      return false;
    }

    return true;
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) return;

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
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

  String _getWeatherIcon(String? iconCode) {
    if (iconCode == null) return '🌤';
    switch (iconCode) {
      case '01d':
        return '☀️';
      case '01n':
        return '🌙';
      case '02d':
      case '02n':
        return '⛅️';
      case '03d':
      case '03n':
      case '04d':
      case '04n':
        return '☁️';
      case '09d':
      case '09n':
        return '🌧';
      case '10d':
      case '10n':
        return '🌦';
      case '11d':
      case '11n':
        return '⛈';
      case '13d':
      case '13n':
        return '🌨';
      case '50d':
      case '50n':
        return '🌫';
      default:
        return '🌤';
    }
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
    final description = weather['weather'][0]['description'];
    final iconCode = weather['weather'][0]['icon'];
    final humidity = weather['main']['humidity'];
    final windSpeed = weather['wind']['speed'];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF17904A),
            Color.fromRGBO(23, 144, 74, 0.7),
          ],
        ),
      ),
      child: RefreshIndicator(
        onRefresh: _fetchWeather,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      _locationName ?? 'Loading location...',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _getWeatherIcon(iconCode),
                      style: const TextStyle(fontSize: 64),
                    ),
                    Text(
                      '${temp.round()}°C',
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    Text(
                      condition,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.water_drop,
                              color: Color(0xFF17904A)),
                          const SizedBox(height: 8),
                          const Text('Humidity'),
                          Text(
                            '$humidity%',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          const Icon(Icons.air, color: Color(0xFF17904A)),
                          const SizedBox(height: 8),
                          const Text('Wind Speed'),
                          Text(
                            '${windSpeed.toStringAsFixed(1)} m/s',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
