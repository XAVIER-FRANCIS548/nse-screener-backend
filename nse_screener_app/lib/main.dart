import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:math';

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
      home: const MainNavigationWrapper(),
    );
  }
}

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;

  final List _screens = [
    const StockDashboard(),
    const CagrLookupScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        backgroundColor: const Color(0xFF1E293B),
        selectedItemColor: Colors.indigoAccent,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.show_chart),
            label: 'Screener & Signals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics),
            label: 'CAGR Lookup',
          ),
        ],
      ),
    );
  }
}

// ==================== SCREEN 1: MAIN SCREENER ====================
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
  double _prevClose = 0.0;
  List _history = [];
  
  bool _isLoading = false;
  String _serverStatus = 'Server Status: Not Verified';
  Color _statusColor = Colors.orangeAccent;

  @override
  void initState() {
    super.initState();
    _verifyWebConnection();
    _fetchStockData('KARURVYSYA');
  }

  Future<void> _verifyWebConnection() async {
    setState(() {
      _serverStatus = 'Verifying Web API Server...';
      _statusColor = Colors.orangeAccent;
    });

    try {
      final response = await http.get(
        Uri.parse('https://query1.finance.yahoo.com/v1/finance/search?q=RELIANCE.NS'),
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        setState(() {
          _serverStatus = 'Web API Online (200 OK)';
          _statusColor = Colors.greenAccent;
        });
      } else {
        setState(() {
          _serverStatus = 'Web API Warning: HTTP ${response.statusCode}';
          _statusColor = Colors.redAccent;
        });
      }
    } catch (e) {
      setState(() {
        _serverStatus = 'Web API Offline / Network Restricted';
        _statusColor = Colors.redAccent;
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
        double previousClose = (meta['previousClose'] ?? meta['chartPreviousClose'] ?? (closeList.length > 1 ? closeList[closeList.length - 2] : currentPrice)).toDouble();

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
          _prevClose = previousClose;
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
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final double athDiff = _athPrice > 0 ? (((_cmp - _athPrice) / _athPrice) * 100) : 0.0;
    final double dailyChangeAmt = _cmp - _prevClose;
    final double dailyChangePct = _prevClose > 0 ? (dailyChangeAmt / _prevClose) * 100 : 0.0;

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
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_sync, size: 18, color: _statusColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _serverStatus,
                      style: TextStyle(fontSize: 11, color: _statusColor, fontWeight: FontWeight.bold),
                    ),
                  ),
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
                            labelText: 'Enter Ticker (e.g. ITC, RELIANCE)',
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
                _metricCard(
                  'Daily Change (₹)',
                  '${dailyChangeAmt >= 0 ? "+" : ""}₹${dailyChangeAmt.toStringAsFixed(2)}',
                  dailyChangeAmt < 0 ? Colors.redAccent : Colors.greenAccent,
                ),
                _metricCard(
                  'Daily Change (%)',
                  '${dailyChangePct >= 0 ? "+" : ""}${dailyChangePct.toStringAsFixed(2)}%',
                  dailyChangePct < 0 ? Colors.redAccent : Colors.greenAccent,
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

// ==================== SCREEN 2: LIVE DYNAMIC CAGR LOOKUP TAB ====================
class CagrLookupScreen extends StatefulWidget {
  const CagrLookupScreen({super.key});

  @override
  State<CagrLookupScreen> createState() => _CagrLookupScreenState();
}

class _CagrLookupScreenState extends State<CagrLookupScreen> {
  final TextEditingController _cagrSearchController = TextEditingController(text: 'ITC');

  String _stockName = 'ITC Limited';
  double _cmp = 0.0;
  double? _cagr1y;
  double? _cagr3y;
  double? _cagr5y;
  double? _cagr10y;
  String _industry = 'Consumer Goods';
  String _mcap = 'Largecap';
  bool _isLoading = false;
  String _errorMsg = '';

  @override
  void initState() {
    super.initState();
    _fetchLiveCagrData('ITC');
  }

  Future<void> _fetchLiveCagrData(String symbol) async {
    String cleanSymbol = symbol.toUpperCase().replaceAll('NSE:', '').replaceAll('.NS', '').trim();
    if (cleanSymbol.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMsg = '';
    });

    try {
      final url = Uri.parse('https://query1.finance.yahoo.com/v8/finance/chart/$cleanSymbol.NS?range=max&interval=1d');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['chart']['result'][0];
        final meta = result['meta'];
        final timestamps = result['timestamp'] ?? [];
        final quotes = result['indicators']['quote'][0];
        final closeList = quotes['close'] ?? [];

        double currentPrice = (meta['regularMarketPrice'] ?? (closeList.isNotEmpty ? closeList.last : 0.0)).toDouble();
        
        List historicalPrices = [];
        for (int i = 0; i < timestamps.length; i++) {
          if (i < closeList.length && closeList[i] != null && timestamps[i] != null) {
            historicalPrices.add({
              'time': DateTime.fromMillisecondsSinceEpoch(timestamps[i] * 1000),
              'close': (closeList[i] as num).toDouble(),
            });
          }
        }

        double? cagr1 = _calculateCagr(historicalPrices, currentPrice, 1);
        double? cagr3 = _calculateCagr(historicalPrices, currentPrice, 3);
        double? cagr5 = _calculateCagr(historicalPrices, currentPrice, 5);
        double? cagr10 = _calculateCagr(historicalPrices, currentPrice, 10);

        setState(() {
          _stockName = meta['longName'] ?? meta['shortName'] ?? '$cleanSymbol (NSE)';
          _cmp = currentPrice;
          _cagr1y = cagr1;
          _cagr3y = cagr3;
          _cagr5y = cagr5;
          _cagr10y = cagr10;
          _industry = meta['sector'] ?? 'NSE Listed Equity';
          _mcap = currentPrice > 1000 ? 'Largecap' : 'Midcap';
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMsg = 'Stock ticker not found on exchange.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMsg = 'Error connecting to market server.';
        _isLoading = false;
      });
    }
  }

  double? _calculateCagr(List history, double currentPrice, int years) {
    if (history.isEmpty) return null;
    DateTime targetDate = DateTime.now().subtract(Duration(days: years * 365));
    
    dynamic pastRecord;
    for (var record in history) {
      DateTime dt = record['time'];
      if (dt.isBefore(targetDate) || dt.isAtSameMomentAs(targetDate)) {
        pastRecord = record;
      } else {
        if (pastRecord == null) pastRecord = record;
        break;
      }
    }

    if (pastRecord == null || pastRecord['close'] <= 0) return null;
    double pastPrice = pastRecord['close'];

    double cagr = (pow((currentPrice / pastPrice), (1 / years)) - 1) * 100;
    return double.parse(cagr.toStringAsFixed(1));
  }

  Color _getCagrColor(double? val) {
    if (val == null) return Colors.grey.shade800;
    if (val > 20) return Colors.green.shade800;
    if (val > 0) return Colors.green.shade900.withOpacity(0.5);
    return Colors.red.shade900.withOpacity(0.6);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live Interactive CAGR Lookup'),
        backgroundColor: const Color(0xFF1E293B),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Lookup Stock Live CAGR',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.indigoAccent),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _cagrSearchController,
                          decoration: const InputDecoration(
                            labelText: 'Enter Stock Code (e.g. ITC, RELIANCE, TCS)',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onSubmitted: (val) => _fetchLiveCagrData(val),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                        onPressed: () => _fetchLiveCagrData(_cagrSearchController.text),
                        child: _isLoading 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Lookup', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            
            if (_isLoading)
              const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))
            else if (_errorMsg.isNotEmpty)
              Center(child: Padding(padding: EdgeInsets.all(32.0), child: Text(_errorMsg, style: const TextStyle(color: Colors.redAccent))))
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF6366F1), width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _stockName,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Industry: $_industry  |  Segment: $_mcap',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Divider(height: 24, color: Color(0xFF334155)),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Market Price (CMP):', style: TextStyle(color: Colors.white70)),
                        Text('₹${_cmp.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.yellowAccent)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text('Compound Annual Growth Rate (CAGR):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.indigoAccent)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _cagrBadge('10Y', _cagr10y),
                        _cagrBadge('5Y', _cagr5y),
                        _cagrBadge('3Y', _cagr3y),
                        _cagrBadge('1Y', _cagr1y),
                      ],
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _cagrBadge(String label, double? val) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: _getCagrColor(val),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            val != null ? '$val%' : 'N/A',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      ],
    );
  }
}