import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_charts/charts.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Tracker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: CryptoList(),
    );
  }
}

class CryptoList extends StatefulWidget {
  @override
  _CryptoListState createState() => _CryptoListState();
}

class _CryptoListState extends State<CryptoList> {
  List<dynamic> _coins = [];
  List<CryptoData> _coinHistoryData = [];
  bool _isLoading = true;
  String _selectedCoin = 'bitcoin';
  String _selectedPeriod = 'days';
  List<CryptoData> _top5Coins = [];
  double _minPrice = double.infinity;
  double _maxPrice = -double.infinity;

  final List<String> _selectedCoins = [
    'bitcoin',
    'ethereum',
    'tether',
    'binancecoin',
    'dogecoin',
  ];

  @override
  void initState() {
    super.initState();
    _fetchCoins();
  }

  Future<void> _fetchCoins() async {
    try {
      final response = await http.get(Uri.parse('https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _coins = data;
          _isLoading = false;
        });
        _fetchTop5Coins();
        _fetchCoinHistory(_selectedCoin, _selectedPeriod);
      } else {
        throw Exception('Erreur lors de la récupération des données');
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });
      print('Erreur de récupération des données : $error');
    }
  }

  void _fetchTop5Coins() {
    _coins.sort((a, b) => b['current_price'].compareTo(a['current_price']));
    setState(() {
      _top5Coins = _coins.where((coin) => _selectedCoins.contains(coin['id'])).map((coin) {
        return CryptoData(coin['name'], coin['current_price'].toDouble(), DateTime.now());
      }).toList();
    });
  }

  Future<void> _fetchCoinHistory(String coinId, String period) async {
    String days = '7';
    if (period == 'weeks') {
      days = '30';
    } else if (period == 'months') {
      days = '180';
    } else if (period == 'years') {
      days = '365';
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
            _selectedCoin,
            e[1].toDouble(),
            DateTime.fromMillisecondsSinceEpoch(e[0]),
          );
        }).toList();

        double minPrice = historyData.map((e) => e.price).reduce((a, b) => a < b ? a : b);
        double maxPrice = historyData.map((e) => e.price).reduce((a, b) => a > b ? a : b);

        setState(() {
          _coinHistoryData = historyData;
          _minPrice = minPrice;
          _maxPrice = maxPrice;
        });
      } else {
        throw Exception('Erreur lors de la récupération de l\'historique des données');
      }
    } catch (error) {
      print('Erreur de récupération de l\'historique : $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Prix des Cryptomonnaies', style: TextStyle(fontSize: 18, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.black,
        elevation: 4,
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  Container(
                    color: Colors.black,
                    child: DropdownButton<String>(
                      value: _selectedCoin,
                      hint: Text('Choisir la cryptomonnaie', style: TextStyle(fontSize: 14, color: Colors.white)),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedCoin = newValue!;
                          _fetchCoinHistory(_selectedCoin, _selectedPeriod);
                        });
                      },
                      dropdownColor: Colors.black,
                      items: _coins.map<DropdownMenuItem<String>>((coin) {
                        return DropdownMenuItem<String>(
                          value: coin['id'],
                          child: Text(coin['name'], style: TextStyle(fontSize: 14, color: Colors.white)),
                        );
                      }).toList(),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    color: Colors.black,
                    child: DropdownButton<String>(
                      value: _selectedPeriod,
                      hint: Text('Choisir la période', style: TextStyle(fontSize: 14, color: Colors.white)),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPeriod = newValue!;
                          _fetchCoinHistory(_selectedCoin, _selectedPeriod);
                        });
                      },
                      dropdownColor: Colors.black,
                      items: [
                        DropdownMenuItem(value: 'days', child: Text('Jours', style: TextStyle(fontSize: 14, color: Colors.white))),
                        DropdownMenuItem(value: 'weeks', child: Text('Semaines', style: TextStyle(fontSize: 14, color: Colors.white))),
                        DropdownMenuItem(value: 'months', child: Text('Mois', style: TextStyle(fontSize: 14, color: Colors.white))),
                        DropdownMenuItem(value: 'years', child: Text('Années', style: TextStyle(fontSize: 14, color: Colors.white))),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 300,
                    color: Colors.black,
                    child: SfCartesianChart(
                      backgroundColor: Colors.black,
                      primaryXAxis: DateTimeAxis(
                        labelFormat: _selectedPeriod == 'years' ? 'yyyy' : 'd/M',
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      primaryYAxis: NumericAxis(
                        labelFormat: '\${value}',
                        minimum: _minPrice,
                        maximum: _maxPrice,
                        interval: (_maxPrice - _minPrice) / 5,
                        labelStyle: TextStyle(color: Colors.white),
                      ),
                      series: <ChartSeries>[
                        LineSeries<CryptoData, DateTime>(
                          dataSource: _coinHistoryData,
                          xValueMapper: (CryptoData data, _) => data.date,
                          yValueMapper: (CryptoData data, _) => data.price,
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  SizedBox(height: 8),
                  Text(
                    'Top 5 Cryptomonnaies Actuelles',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: DataTable(
                        columns: const [
                          DataColumn(label: Text('Cryptomonnaie', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                          DataColumn(label: Text('Prix actuel', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white))),
                        ],
                        rows: _top5Coins.map((coin) {
                          return DataRow(cells: [
                            DataCell(Text(coin.name, style: TextStyle(color: Colors.white))),
                            DataCell(Text('\$${coin.price.toStringAsFixed(2)}', style: TextStyle(color: Colors.white))),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CryptoData {

  final String name;
  final double price;
  final DateTime date;

  CryptoData(this.name, this.price, this.date);
}