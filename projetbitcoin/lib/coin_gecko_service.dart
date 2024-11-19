import 'dart:convert';
import 'package:http/http.dart' as http;

class CoinGeckoService {
  Map<String, List<CryptoData>> _cachedCoinHistory = {};  // Cache des données

  Future<List<CryptoData>> fetchCoinHistory(String coinId, String period) async {
    String days = '7';
    if (period == 'weeks') {
      days = '30';
    } else if (period == 'months') {
      days = '180';
    } else if (period == 'years') {
      days = '365';
    }

    // Vérifier si les données sont déjà en cache
    if (_cachedCoinHistory.containsKey('$coinId-$period')) {
      return _cachedCoinHistory['$coinId-$period']!;
    }

    try {
      final response = await http.get(Uri.parse(
          'https://api.coingecko.com/api/v3/coins/$coinId/market_chart?vs_currency=usd&days=$days&interval=daily'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        List<dynamic> prices = data['prices'];

        if (prices.isEmpty) {
          print('Aucune donnée disponible pour cette période.');
        }

        List<CryptoData> historyData = prices.map((e) {
          return CryptoData(
            coinId,
            e[1].toDouble(),
            DateTime.fromMillisecondsSinceEpoch(e[0]),
          );
        }).toList();

        // Mettre les données en cache
        _cachedCoinHistory['$coinId-$period'] = historyData;

        return historyData;
      } else {
        throw Exception('Erreur lors de la récupération des données');
      }
    } catch (error) {
      print('Erreur de récupération de l\'historique : $error');
      return [];
    }
  }
}

class CryptoData {
  final String name;
  final double price;
  final DateTime date;

  CryptoData(this.name, this.price, this.date);
}
import 'dart:convert';
import 'package:http/http.dart' as http;

class CoinGeckoService {
  final String _baseUrl = 'https://api.coingecko.com/api/v3';

  // Méthode pour récupérer les données de cryptomonnaies
  Future<List<dynamic>> fetchCoinData() async {
    final url = Uri.parse('$_baseUrl/coins/markets?vs_currency=usd');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Erreur lors de la récupération des données des cryptomonnaies');
    }
  }

  // Méthode pour récupérer l'historique des prix d'une cryptomonnaie
  Future<List<double>> fetchCoinHistory(String coinId) async {
    final url = Uri.parse('$_baseUrl/coins/$coinId/market_chart?vs_currency=usd&days=30');
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List<double> prices = (data['prices'] as List)
          .map((priceData) => priceData[1] as double)
          .toList();
      return prices;
    } else {
      throw Exception('Erreur lors de la récupération de l\'historique des prix');
    }
  }
}
