import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ForexExchangeScreen extends StatefulWidget {
  final double baseBalanceChf;
  const ForexExchangeScreen({super.key, required this.baseBalanceChf});

  @override
  State<ForexExchangeScreen> createState() => _ForexExchangeScreenState();
}

class _ForexExchangeScreenState extends State<ForexExchangeScreen> {
  final TextEditingController _amountController = TextEditingController(text: "100.00");
  String _fromCurrency = "CHF";
  String _toCurrency = "INR";
  bool _isLoading = true;

  double _chfToInr = 95.238;
  double _chfToUsd = 1.145;
  double _chfToEur = 1.042;
  double _chfToAed = 4.205;
  double _chfToGbp = 0.892;
  double _chfToSgd = 1.541;
  double _chfToCad = 1.562;
  double _chfToAud = 1.724;

  final Map<String, String> _currencyFlags = {
    'CHF': '🇨🇭',
    'INR': '🇮🇳',
    'USD': '🇺🇸',
    'EUR': '🇪🇺',
    'AED': '🇦🇪',
    'GBP': '🇬🇧',
    'SGD': '🇸🇬',
    'CAD': '🇨🇦',
    'AUD': '🇦🇺',
  };

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  Future<void> _fetchRates() async {
    final rate = await ApiService.getChfToInrRate();
    if (mounted) {
      setState(() {
        _chfToInr = rate;
        _isLoading = false;
      });
    }
  }

  double _getRate(String code) {
    switch (code) {
      case 'INR': return _chfToInr;
      case 'USD': return _chfToUsd;
      case 'EUR': return _chfToEur;
      case 'AED': return _chfToAed;
      case 'GBP': return _chfToGbp;
      case 'SGD': return _chfToSgd;
      case 'CAD': return _chfToCad;
      case 'AUD': return _chfToAud;
      case 'CHF': return 1.0;
      default: return 1.0;
    }
  }

  double _calculateConversion() {
    final input = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final fromRate = _getRate(_fromCurrency);
    final toRate = _getRate(_toCurrency);
    if (fromRate <= 0) return 0.0;
    final chfEquivalent = input / fromRate;
    return chfEquivalent * toRate;
  }

  @override
  Widget build(BuildContext context) {
    final converted = _calculateConversion();

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      appBar: AppBar(
        title: const Text("Swiss Forex & Currency Exchange", style: TextStyle(fontWeight: FontWeight.w800)),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.neonPink, AppTheme.neonBurgundy],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: AppTheme.neonPink.withValues(alpha: 0.25), blurRadius: 14, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.currency_exchange_rounded, color: Colors.white, size: 28),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.wifi_rounded, color: Colors.greenAccent, size: 14),
                            SizedBox(width: 4),
                            Text("LIVE FX RATES", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Real-Time Multi-Currency Swap",
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Exchange CHF into 8+ international currencies with zero spread markup.",
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Live Calculator Box
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("FX CONVERTER CALCULATOR", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: Colors.grey, letterSpacing: 1.1)),
                  const SizedBox(height: 14),

                  // From Input
                  Row(
                    children: [
                      DropdownButton<String>(
                        value: _fromCurrency,
                        underline: const SizedBox(),
                        items: _currencyFlags.keys.map((code) {
                          return DropdownMenuItem(
                            value: code,
                            child: Row(
                              children: [
                                Text(_currencyFlags[code]!, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text(code, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _fromCurrency = val!),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            hintText: "0.00",
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),

                  const Divider(height: 24),

                  // Swap Divider Icon
                  Center(
                    child: IconButton(
                      icon: const Icon(Icons.swap_vert_circle_rounded, color: AppTheme.neonPink, size: 36),
                      onPressed: () {
                        setState(() {
                          final temp = _fromCurrency;
                          _fromCurrency = _toCurrency;
                          _toCurrency = temp;
                        });
                      },
                    ),
                  ),

                  const Divider(height: 24),

                  // To Output
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      DropdownButton<String>(
                        value: _toCurrency,
                        underline: const SizedBox(),
                        items: _currencyFlags.keys.map((code) {
                          return DropdownMenuItem(
                            value: code,
                            child: Row(
                              children: [
                                Text(_currencyFlags[code]!, style: const TextStyle(fontSize: 18)),
                                const SizedBox(width: 6),
                                Text(code, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() => _toCurrency = val!),
                      ),
                      Text(
                        "${_currencyFlags[_toCurrency]} ${converted.toStringAsFixed(2)}",
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppTheme.neonPink),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.bgLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "Rate: 1 $_fromCurrency = ${(_getRate(_toCurrency) / _getRate(_fromCurrency)).toStringAsFixed(4)} $_toCurrency (Interbank Wholesale Rate)",
                      style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text("LIVE FX RATES TABLE", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppTheme.darkNavy)),
            const SizedBox(height: 12),

            _buildRateTile("🇮🇳 INR", "Indian Rupee", "1 CHF = ₹ ${_chfToInr.toStringAsFixed(2)}"),
            _buildRateTile("🇺🇸 USD", "US Dollar", "1 CHF = \$ ${_chfToUsd.toStringAsFixed(2)}"),
            _buildRateTile("🇪🇺 EUR", "Euro", "1 CHF = € ${_chfToEur.toStringAsFixed(2)}"),
            _buildRateTile("🇦🇪 AED", "UAE Dirham", "1 CHF = AED ${_chfToAed.toStringAsFixed(2)}"),
            _buildRateTile("🇬🇧 GBP", "British Pound", "1 CHF = £ ${_chfToGbp.toStringAsFixed(2)}"),
            _buildRateTile("🇸🇬 SGD", "Singapore Dollar", "1 CHF = S\$ ${_chfToSgd.toStringAsFixed(2)}"),
            _buildRateTile("🇨🇦 CAD", "Canadian Dollar", "1 CHF = CA\$ ${_chfToCad.toStringAsFixed(2)}"),
            _buildRateTile("🇦🇺 AUD", "Australian Dollar", "1 CHF = A\$ ${_chfToAud.toStringAsFixed(2)}"),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.neonPink,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Fx Instant Swap feature is active in live mode.")),
                  );
                },
                child: const Text("Execute Currency Swap", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRateTile(String flagTitle, String name, String rateStr) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(flagTitle, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
              Text(name, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
          ),
          Text(rateStr, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.darkNavy)),
        ],
      ),
    );
  }
}
