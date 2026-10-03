import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../theme/app_theme.dart';
import '../services/market_data_service.dart';

class StockDetailsScreen extends StatefulWidget {
  final StockItemModel stock;
  final bool isWatchlisted;
  final VoidCallback onToggleWatchlist;

  const StockDetailsScreen({
    super.key,
    required this.stock,
    required this.isWatchlisted,
    required this.onToggleWatchlist,
  });

  @override
  State<StockDetailsScreen> createState() => _StockDetailsScreenState();
}

class _StockDetailsScreenState extends State<StockDetailsScreen> {
  late bool _isWatchlisted;
  String _selectedPeriod = '1M';
  bool _isLoadingChart = false;
  List<FlSpot> _chartSpots = [];

  @override
  void initState() {
    super.initState();
    _isWatchlisted = widget.isWatchlisted;
    _generateChartData(_selectedPeriod);
  }

  void _generateChartData(String period) {
    setState(() => _isLoadingChart = true);
    final basePrice = widget.stock.price;
    final isPositive = widget.stock.changePercent >= 0;

    List<FlSpot> spots = [];
    int points = 10;
    if (period == '1D') points = 8;
    if (period == '1W') points = 12;
    if (period == '1M') points = 15;
    if (period == '1Y') points = 20;
    if (period == '5Y') points = 25;

    double currentVal = isPositive ? basePrice * 0.92 : basePrice * 1.08;
    final step = (basePrice - currentVal) / (points - 1);

    for (int i = 0; i < points; i++) {
      double noise = (i % 2 == 0 ? 1 : -1) * (basePrice * 0.012 * ((i * 7) % 5));
      if (i == points - 1) {
        spots.add(FlSpot(i.toDouble(), basePrice));
      } else {
        spots.add(FlSpot(i.toDouble(), currentVal + (step * i) + noise));
      }
    }

    setState(() {
      _chartSpots = spots;
      _isLoadingChart = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final stock = widget.stock;
    final isPositive = stock.changePercent >= 0;
    final changeColor = isPositive ? AppTheme.successGreen : AppTheme.dangerRed;

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Text(stock.flag, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stock.symbol,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                ),
                Text(
                  "${stock.country} • ${stock.currency}",
                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isWatchlisted ? Icons.star_rounded : Icons.star_outline_rounded,
              color: _isWatchlisted ? Colors.amber : Colors.grey,
              size: 26,
            ),
            onPressed: () {
              setState(() => _isWatchlisted = !_isWatchlisted);
              widget.onToggleWatchlist();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Header Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          stock.logoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              stock.symbol[0],
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: AppTheme.neonPink),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stock.name,
                            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: stock.isMarketOpen ? Colors.green[50] : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  stock.isMarketOpen ? "● MARKET OPEN" : "● MARKET CLOSED",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: stock.isMarketOpen ? AppTheme.successGreen : AppTheme.textMuted,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: stock.dataSourceType == 'LIVE_API' 
                                      ? Colors.blue[50] 
                                      : Colors.amber[50],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  stock.dataSourceType == 'LIVE_API' ? "LIVE API" : "DELAYED SNAPSHOT",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: stock.dataSourceType == 'LIVE_API' ? Colors.blue[800] : Colors.amber[900],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Price & Daily Change Display
              Text("Current Price", style: TextStyle(color: AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    "${stock.currency} ${stock.price.toStringAsFixed(2)}",
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppTheme.darkNavy),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: changeColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "${isPositive ? '+' : ''}${stock.change.toStringAsFixed(2)} (${isPositive ? '+' : ''}${stock.changePercent.toStringAsFixed(2)}%)",
                      style: TextStyle(color: changeColor, fontWeight: FontWeight.w800, fontSize: 13),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Interactive Timeframe Switcher (1D, 1W, 1M, 1Y, 5Y)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['1D', '1W', '1M', '1Y', '5Y'].map((p) {
                    final isSelected = _selectedPeriod == p;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          if (!isSelected) {
                            setState(() => _selectedPeriod = p);
                            _generateChartData(p);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: isSelected
                                ? [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 4)]
                                : [],
                          ),
                          child: Text(
                            p,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSelected ? AppTheme.neonPink : AppTheme.textMuted,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),

              // Interactive Stock Chart Card
              Container(
                height: 220,
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12)],
                ),
                child: _isLoadingChart
                    ? const Center(child: CircularProgressIndicator(color: AppTheme.neonPink))
                    : LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[200]!, strokeWidth: 1),
                          ),
                          titlesData: const FlTitlesData(show: false),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _chartSpots,
                              isCurved: true,
                              color: changeColor,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: const FlDotData(show: false),
                              belowBarData: BarAreaData(
                                show: true,
                                color: changeColor.withOpacity(0.12),
                              ),
                            ),
                          ],
                        ),
                      ),
              ),

              const SizedBox(height: 24),

              // Fundamentals Grid Section
              const Text(
                "Key Market Fundamentals",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.darkNavy),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.8,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildFundamentalItem("Open", "${stock.currency} ${stock.openPrice.toStringAsFixed(2)}"),
                  _buildFundamentalItem("Day Range", "${stock.lowPrice.toStringAsFixed(2)} - ${stock.highPrice.toStringAsFixed(2)}"),
                  _buildFundamentalItem("52-Wk Range", "${stock.w52Low.toStringAsFixed(2)} - ${stock.w52High.toStringAsFixed(2)}"),
                  _buildFundamentalItem("Market Cap", stock.marketCap),
                  _buildFundamentalItem("P/E Ratio", stock.peRatio),
                  _buildFundamentalItem("Volume", stock.volume),
                ],
              ),

              const SizedBox(height: 24),

              // About Company Section
              if (stock.description.isNotEmpty) ...[
                const Text(
                  "About Company",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.darkNavy),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Text(
                    stock.description,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.5),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // CTA Action Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Order request for ${stock.symbol} placed via Swiss Brokerage Portal."),
                        backgroundColor: AppTheme.neonPink,
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.neonPink,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 2,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.show_chart_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text("Trade ${stock.symbol}", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFundamentalItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, color: AppTheme.darkNavy, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
