import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class WeatherService {
  final String apiKey = "18077ee081a871756e3c26d109247f8c";

  double calculateHeatIndex(double tempCelsius, double humidity) {
    // Convert Celsius to Fahrenheit for the calculation
    double tempF = (tempCelsius * 9 / 5) + 32;
    
    // Rothfusz regression equation for heat index
    double hi = -42.379 +
        2.04901523 * tempF +
        10.14333127 * humidity -
        0.22475541 * tempF * humidity -
        6.83783e-3 * pow(tempF, 2) -
        5.481717e-2 * pow(humidity, 2) +
        1.22874e-3 * pow(tempF, 2) * humidity +
        8.5282e-4 * tempF * pow(humidity, 2) -
        1.99e-6 * pow(tempF, 2) * pow(humidity, 2);
    
    // Convert back to Celsius
    return (hi - 32) * 5 / 9;
  }

  String getHeatIndexAdvice(double heatIndex) {
    if (heatIndex < 27) {
      return "🟢 Normal - Safe to be outdoors. Stay hydrated!";
    } else if (heatIndex < 32) {
      return "🟡 Caution - Possible fatigue with prolonged exposure. Drink plenty of water.";
    } else if (heatIndex < 41) {
      return "🟠 Extreme Caution - Heat exhaustion possible. Limit outdoor activities and stay in shade.";
    } else if (heatIndex < 54) {
      return "🔴 Danger - Heat stroke likely. Avoid strenuous activities and stay indoors if possible.";
    } else {
      return "🔴 Extreme Danger - Heat stroke imminent! Stay indoors in air-conditioned spaces.";
    }
  }

  Future<Map<String, dynamic>> getWeather(String city, String province) async {
    final url = Uri.parse(
      "https://api.openweathermap.org/data/2.5/weather?q=$city,$province,PH&appid=$apiKey&units=metric",
    );

    try {
      final response = await http.get(url);

      print('Status Code: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Calculate and add heat index
        final temp = data['main']['temp'].toDouble();
        final humidity = data['main']['humidity'].toDouble();
        final heatIndex = calculateHeatIndex(temp, humidity);
        data['main']['heat_index'] = heatIndex;
        data['main']['heat_index_advice'] = getHeatIndexAdvice(heatIndex);
        
        return data;
      } else if (response.statusCode == 401) {
        throw Exception("Invalid API Key. Please check your API key.");
      } else if (response.statusCode == 404) {
        throw Exception("Location not found. Please check the city and province names.");
      } else {
        throw Exception("Failed to load weather data: ${response.statusCode}");
      }
    } catch (e) {
      print('Error: $e');
      rethrow;
    }
  }
}