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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0E14),
        cardColor: const Color(0xFF151D2A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF2563EB),
          surface: Color(0xFF151D2A),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B0E14),
          elevation: 0,
        ),
      ),
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
  List<dynamic> allStocks = [];
  List<dynamic> filteredStocks = [];
  bool isLoading = true;
  String searchQuery = '';
  String selectedFilter = 'ALL';
  String errorMessage = '';

  final String apiUrl = "https://nse-screener-backend-qg5c.onrender.com/api/scan-all";

  @override
  void initState() {
    super.initState();
    fetchStockData();
  }

  Future<void> fetchStockData() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final freshUrl = Uri.parse('$apiUrl?t=$timestamp');

      final response = await http.get(
        freshUrl,
        headers: {
          'Cache-Control': 'no-cache, no-store, must-revalidate',
          'Pragma': 'no-cache',
          'Expires': '0',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body);
        final List<dynamic> data = jsonResponse['data'] ?? [];

        setState(() {
          allStocks = data;
          _applyFilters();
          isLoading = false;
        });
      } else {
        setState(() {
          errorMessage = 'Server error: Status Code ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load stock data. Ensure backend is running.\nError: $e';
        isLoading = false;
      });
    }
  }

  double _parseNum(dynamic val) {
    if (val == null) return 0.0;
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString().replaceAll(RegExp(r'[^\d.-]'), '')) ?? 0.0;
  }

  void _applyFilters() {
    setState(() {
      filteredStocks = allStocks.where((stock) {
        final ticker = (stock['Ticker'] ?? '').toString().toLowerCase();
        final verdict = (stock['Signal Verdict'] ?? '').toString().toUpperCase();
        final downAthVal = _parseNum(stock['Down % from ATH']);

        final matchesSearch = ticker.contains(searchQuery.toLowerCase().trim());
        bool matchesFilter = true;

        if (selectedFilter == 'STRONG BUY') {
          matchesFilter = verdict.contains('STRONG BUY');
        } else if (selectedFilter == 'BUY') {
          matchesFilter = verdict == 'BUY' || verdict == 'MODERATE BUY';
        } else if (selectedFilter == 'HOLD') {
          matchesFilter = verdict.contains('HOLD') || verdict.contains('NEUTRAL');
        } else if (selectedFilter == 'ATH <= 10%') {
          matchesFilter = downAthVal <= 10.0;
        } else if (selectedFilter == 'ATH <= 20%') {
          matchesFilter = downAthVal <= 20.0;
        } else if (selectedFilter == 'ATH <= 30%') {
          matchesFilter = downAthVal <= 30.0;
        }

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Color _getVerdictColor(String verdict) {
    if (verdict.contains('STRONG BUY')) return const Color(0xFF10B981);
    if (verdict.contains('BUY')) return const Color(0xFF34D399);
    if (verdict.contains('NEUTRAL') || verdict.contains('HOLD')) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }

  @override
  Widget build(BuildContext context) {
    final filterOptions = ['ALL', 'STRONG BUY', 'BUY', 'HOLD', 'ATH <= 10%', 'ATH <= 20%', 'ATH <= 30%'];

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'NSE Technical Screener',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: fetchStockData,
          )
        ],
      ),
      body: Column(
        children: [
          // Search & Filters Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                TextField(
                  onChanged: (value) {
                    searchQuery = value;
                    _applyFilters();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search ticker (e.g. RELIANCE)...',
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFF1E293B),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: filterOptions.map((filter) {
                      final isSelected = selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          selected: isSelected,
                          label: Text(filter),
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          backgroundColor: const Color(0xFF1E293B),
                          selectedColor: const Color(0xFF2563EB),
                          onSelected: (bool selected) {
                            setState(() {
                              selectedFilter = filter;
                              _applyFilters();
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Main Card View Body
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
                : errorMessage.isNotEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Text(
                            errorMessage,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.redAccent, fontSize: 14),
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: fetchStockData,
                        child: filteredStocks.isEmpty
                            ? const Center(
                                child: Text('No stocks match criteria', style: TextStyle(color: Colors.grey)))
                            : ListView.builder(
                                padding: const EdgeInsets.all(12),
                                itemCount: filteredStocks.length,
                                itemBuilder: (context, index) {
                                  return _buildStockCard(filteredStocks[index]);
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockCard(dynamic stock) {
    final verdict = (stock['Signal Verdict'] ?? 'N/A').toString();
    final closePrice = _parseNum(stock['Today Close (INR)']);
    final changePct = _parseNum(stock['Daily Change %']);
    final rsi = stock['1 HOUR RSI'] ?? 'N/A';

    final athPrice = stock['ATH Price'] ?? stock['ATH Value'] ?? 'N/A';
    final athDate = stock['ATH Date'] ?? 'N/A';
    final downAth = _parseNum(stock['Down % from ATH']);

    final isPositive = changePct >= 0;
    final verdictColor = _getVerdictColor(verdict);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF263346), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Ticker Name & Verdict Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  (stock['Ticker'] ?? 'UNKNOWN').toString(),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: verdictColor.withOpacity(0.15),
                    border: Border.all(color: verdictColor.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    verdict,
                    style: TextStyle(
                      color: verdictColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Middle Row: Price, Change %, and 1H RSI Badge
            Row(
              children: [
                Text(
                  '₹$closePrice',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444)).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}$changePct%',
                    style: TextStyle(
                      color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.cyan.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '1H RSI: $rsi',
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ATH Panel (Visible directly on card)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildMetricTile('ATH Price', '₹$athPrice', color: Colors.amberAccent),
                  _buildMetricTile('ATH Date', '$athDate', color: Colors.white70),
                  _buildMetricTile('Down from ATH', '$downAth%', color: const Color(0xFFEF4444)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, {Color? color}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color ?? Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}