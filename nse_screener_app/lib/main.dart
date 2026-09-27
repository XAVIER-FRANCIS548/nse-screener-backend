import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'NSE Stock Screener',
      theme: ThemeData.dark(),
      home: const StockScreenerScreen(),
    );
  }
}

class StockScreenerScreen extends StatefulWidget {
  const StockScreenerScreen({super.key});

  @override
  State<StockScreenerScreen> createState() => _StockScreenerScreenState();
}

class _StockScreenerScreenState extends State<StockScreenerScreen> {
  List<dynamic> stocks = [];
  bool isLoading = true;

  final String apiUrl = "http://127.0.0.1:8000/api/scan-all";

  @override
  void initState() {
    super.initState();
    fetchStockData();
  }

  Future<void> fetchStockData() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(apiUrl));
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        setState(() {
          stocks = jsonResponse['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Color _getVerdictColor(String verdict) {
    switch (verdict) {
      case 'STRONG BUY':
        return Colors.green;
      case 'MODERATE BUY':
        return Colors.lightGreen;
      case 'NEUTRAL / HOLD':
        return Colors.orange;
      default:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NSE Technical Screener'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchStockData,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: stocks.length,
              itemBuilder: (context, index) {
                final stock = stocks[index];
                final verdict = stock['Signal Verdict'] ?? 'N/A';
                final rsi = stock['1 HOUR RSI'] ?? 0.0;
                final closePrice = stock['Today Close (INR)'] ?? 0.0;
                final changePct = stock['Daily Change %'] ?? 0.0;
                final macroTrend = stock['Macro Trend'] ?? 'N/A';
                
                final targetPrice = stock['Target Price'] ?? 0.0;
                final stopLoss = stock['Stop Loss'] ?? 0.0;
                final macdStatus = stock['MACD Status'] ?? 'N/A';
                final pattern = stock['Channel Pattern'] ?? 'N/A';
                final downAth = stock['Down % from ATH'] ?? 0.0;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                  child: ExpansionTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stock['Ticker'] ?? 'UNKNOWN',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '₹$closePrice ($changePct%)',
                              style: TextStyle(
                                color: changePct >= 0 ? Colors.greenAccent : Colors.redAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _getVerdictColor(verdict).withOpacity(0.15),
                            border: Border.all(color: _getVerdictColor(verdict)),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            verdict,
                            style: TextStyle(
                              color: _getVerdictColor(verdict),
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          children: [
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('1H RSI: $rsi', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.cyanAccent)),
                                Text('Macro: $macroTrend'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Target: ₹$targetPrice', style: const TextStyle(color: Colors.greenAccent)),
                                Text('Stop Loss: ₹$stopLoss', style: const TextStyle(color: Colors.redAccent)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('MACD: $macdStatus'),
                                Text('Pattern: $pattern'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text('Down from ATH: $downAth%', style: const TextStyle(color: Colors.grey)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}