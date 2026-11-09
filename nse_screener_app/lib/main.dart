import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

void main() {
  runApp(const StockApp());
}

class StockApp extends StatelessWidget {
  const StockApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Custom Portfolio Strategy Screener',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          surface: Color(0xFF1E293B),
        ),
      ),
      home: const StockDashboard(),
    );
  }
}

class StockDashboard extends StatefulWidget {
  const StockDashboard({super.key});

  @override
  State<StockDashboard> createState() => _StockDashboardState();
}

class _StockDashboardState extends State<StockDashboard> {
  final TextEditingController _codeController = TextEditingController(text: 'KARURVYSYA');

  final List _customStocks = [
    "KRISHANA.NS", "KARURVYSYA.NS", "SKYGOLD.NS", "LAURUSLABS.NS", "PREMIERPOL.NS",
    "FREDUN.NS", "JAYKAY.NS", "MARINE.NS", "QPOWER.NS", "BCCFUBA.NS",
    "MACPOWER.NS", "RAMRAT.NS", "AXISCADES.NS", "TDPOWERSYS.NS", "SYRMA.NS",
    "PGIL.NS", "SHRIPISTON.NS", "STEELCAS.NS", "ARTEMISMED.NS", "MCX.NS",
    "RPGLIFE.NS", "CAPLIPOINT.NS", "LUMAXTECH.NS", "SANSERA.NS", "TI.NS",
    "APARINDS.NS", "TALBROAUTO.NS", "KPL.NS", "ANANDRATHI.NS", "RACLGEAR.NS",
    "DEEPINDS.NS", "KRN.NS", "NAVINFLUOR.NS", "SAILIFE.NS", "SHREEPUSHK.NS",
    "MANORAMA.NS", "DYCL.NS", "PRECWIRE.NS", "GOKULAGRO.NS", "SENORES.NS",
    "INDOTECH.NS", "RRKABEL.NS", "PARAS.NS", "PRICOLLTD.NS", "RADICO.NS",
    "TANFACIND.NS", "BELRISE.NS", "FIEMIND.NS", "THYROCARE.NS", "SHAILY.NS",
    "GRWRHITECH.NS", "SHRIRAMFIN.NS", "SJS.NS", "GABRIEL.NS", "THANGAMAYL.NS",
    "CEMPRO.NS", "HSCL.NS", "HIRECT.NS", "ACUTAAS.NS", "APOLLO.NS",
    "AVL.NS", "GVT&D.NS", "KIRLOSENG.NS", "KRISHNADEF.NS", "POLYCAB.NS",
    "ADVAIT.NS", "KRONECOMM.NS", "BSE.NS", "POCL.NS", "FRONTSP.NS",
    "GALLANTT.NS", "MUTHOOTFIN.NS", "MOTILALOFS.NS", "GUJTHEM.NS", "MARKSANS.NS",
    "TIMEX.NS", "TITANBIO.NS", "TVSMOTOR.NS", "UNIABEXAL.NS", "UNIVCABLES.NS",
    "USHAMART.NS", "V2RETAIL.NS", "VALIANT.NS", "WELCORP.NS", "WELENT.NS", "WINDLAS.NS"
  ];

  String _activeTicker = 'KARURVYSYA';
  String _stockName = 'The Karur Vysya Bank Limited';
  double _cmp = 0.0;
  double _athPrice = 0.0;
  String _athDate = 'Recent Peak';
  List _history = [];
  
  bool _isLoading = false;
  String _serverStatus = 'Connecting to Server...';

  @override
  void initState() {
    super.initState();
    _checkExternalServer();
    _fetchStockData('KARURVYSYA');
  }

  Future<void> _checkExternalServer() async {
    try {
      final response = await http.get(
        Uri.parse('https://query1.finance.yahoo.com/v1/finance/search?q=KARURVYSYA.NS'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        setState(() {
          _serverStatus = 'External Free Server: Online & Connected';
        });
      } else {
        setState(() {
          _serverStatus = 'External Server Warning: Status ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        _serverStatus = 'External Server: Offline / Restricted Network';
      });
    }
  }

  Future<void> _fetchStockData(String symbol) async {
    String cleanSymbol = symbol.toUpperCase().replaceAll('NSE:', '').replaceAll('.NS', '').trim();
    if (cleanSymbol.isEmpty) return;

    setState(() {
      _isLoading = true;
      _activeTicker = cleanSymbol;
    });

    try {
      final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$cleanSymbol.NS?range=1y&interval=1d');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['chart']['result'][0];
        final meta = result['meta'];
        final quotes = result['indicators']['quote'][0];
        final highList = quotes['high'] ?? [];
        final closeList = quotes['close'] ?? [];
        
        double currentPrice = (meta['regularMarketPrice'] ?? (closeList.isNotEmpty ? closeList.last : 100.0)).toDouble();

        double peakHigh = currentPrice;
        int peakDaysAgo = 1;
        
        if (highList.isNotEmpty) {
          for (int i = 0; i < highList.length; i++) {
            if (highList[i] != null) {
              double val = (highList[i] as num).toDouble();
              if (val > peakHigh) {
                peakHigh = val;
                peakDaysAgo = highList.length - i;
              }
            }
          }
        } else {
          peakHigh = (meta['fiftyTwoWeekHigh'] ?? (currentPrice * 1.15)).toDouble();
        }

        double dropPercentage = ((currentPrice - peakHigh) / peakHigh) * 100;
        
        int? buySignal;
        if (dropPercentage <= -25) {
          buySignal = 4;
        } else if (dropPercentage <= -20) {
          buySignal = 3;
        } else if (dropPercentage <= -15) {
          buySignal = 2;
        } else if (dropPercentage <= -10) {
          buySignal = 1;
        }

        setState(() {
          _stockName = meta['longName'] ?? meta['shortName'] ?? '$cleanSymbol (NSE)';
          _cmp = currentPrice;
          _athPrice = peakHigh;
          _athDate = '$peakDaysAgo days ago';
          
          _history = [
            {
              'date': 'Peak Pullback Signal',
              'duration': peakDaysAgo,
              'ath': peakHigh,
              'drop': dropPercentage,
              'signal': buySignal,
            }
          ];
          _isLoading = false;
        });
      } else {
        _loadFallbackData(cleanSymbol);
      }
    } catch (e) {
      _loadFallbackData(cleanSymbol);
    }
  }

  void _loadFallbackData(String cleanSymbol) {
    setState(() {
      _stockName = '$cleanSymbol (NSE Equity)';
      double simulatedCmp = 370.05;
      double simulatedAth = 374.60;
      double dropVal = ((simulatedCmp - simulatedAth) / simulatedAth) * 100;
      
      _cmp = simulatedCmp;
      _athPrice = simulatedAth;
      _athDate = 'Recent Peak';
      _history = [
        {
          'date': 'Current Pullback',
          'duration': 5,
          'ath': simulatedAth,
          'drop': dropVal,
          'signal': dropVal <= -10 ? 1 : null,
        }
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double athDiff = _athPrice > 0 ? (((_cmp - _athPrice) / _athPrice) * 100) : 0.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Custom Portfolio Strategy Screener'),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.cloud_done, size: 16, color: Colors.greenAccent),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_serverStatus, style: const TextStyle(fontSize: 12, color: Colors.white70))),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _stockName,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigoAccent,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _codeController,
                          decoration: const InputDecoration(
                            labelText: 'Enter Ticker (e.g. KRISHANA, LAURUSLABS)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (val) => _fetchStockData(val),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onPressed: () => _fetchStockData(_codeController.text),
                        child: _isLoading 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Scan', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Your Portfolio Watchlist:', style: TextStyle(fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 6),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _customStocks.length,
                itemBuilder: (context, index) {
                  String ticker = _customStocks[index].replaceAll('.NS', '');
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text(ticker, style: const TextStyle(fontSize: 11)),
                      backgroundColor: _activeTicker == ticker ? const Color(0xFF6366F1) : const Color(0xFF1E293B),
                      onPressed: () {
                        _codeController.text = ticker;
                        _fetchStockData(ticker);
                      },
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _metricCard('CMP', '₹${_cmp.toStringAsFixed(2)}', Colors.white),
                _metricCard('ATH Price', '₹${_athPrice.toStringAsFixed(2)}', Colors.white),
                _metricCard('ATH Date', _athDate, Colors.white70),
                _metricCard(
                  'ATH Diff',
                  '${athDiff.toStringAsFixed(2)}%',
                  athDiff < 0 ? Colors.redAccent : Colors.greenAccent,
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'Strategy Signals: $_activeTicker',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _history.length,
                separatorBuilder: (_, __) => const Divider(color: Color(0xFF334155), height: 1),
                itemBuilder: (context, index) {
                  final row = _history[index];
                  double dropVal = (row['drop'] as num).toDouble();
                  double athVal = (row['ath'] as num).toDouble();
                  
                  return ListTile(
                    dense: true,
                    title: Text(
                      '${row['date']}  (Days: ${row['duration']})',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      'ATH: ₹${athVal.toStringAsFixed(2)}  |  Drop: ${dropVal.toStringAsFixed(2)}%',
                      style: TextStyle(
                        color: dropVal < -20 ? Colors.redAccent : Colors.orangeAccent,
                      ),
                    ),
                    trailing: row['signal'] != null
                        ? Chip(
                            label: Text(
                              'Buy: ${row['signal']}',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            backgroundColor: Colors.green.shade700,
                          )
                        : Chip(
                            label: const Text(
                              'Hold',
                              style: TextStyle(color: Colors.white70, fontSize: 12),
                            ),
                            backgroundColor: Colors.grey.shade800,
                          ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metricCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF334155)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}