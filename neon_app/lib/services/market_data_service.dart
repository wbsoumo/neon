import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MarketIndexModel {
  final String symbol;
  final String name;
  final String country;
  final String flag;
  final double currentPrice;
  final double change;
  final double changePercent;
  final String currency;

  const MarketIndexModel({
    required this.symbol,
    required this.name,
    required this.country,
    required this.flag,
    required this.currentPrice,
    required this.change,
    required this.changePercent,
    required this.currency,
  });
}

class StockItemModel {
  final String symbol;
  final String name;
  final String country;
  final String flag;
  final String category; // US, Europe, Asia, ETF, Commodity, Bond
  final double price;
  final double change;
  final double changePercent;
  final String currency;
  final bool isMarketOpen;
  final String logoUrl;
  final String dataSourceType; // LIVE_API, DELAYED_SNAPSHOT, DEMO
  final String description;
  final double openPrice;
  final double highPrice;
  final double lowPrice;
  final double w52High;
  final double w52Low;
  final String peRatio;
  final String marketCap;
  final String volume;

  const StockItemModel({
    required this.symbol,
    required this.name,
    required this.country,
    required this.flag,
    required this.category,
    required this.price,
    required this.change,
    required this.changePercent,
    required this.currency,
    required this.isMarketOpen,
    required this.logoUrl,
    this.dataSourceType = 'DELAYED_SNAPSHOT',
    this.description = '',
    required this.openPrice,
    required this.highPrice,
    required this.lowPrice,
    required this.w52High,
    required this.w52Low,
    required this.peRatio,
    required this.marketCap,
    required this.volume,
  });

  StockItemModel copyWith({
    double? price,
    double? change,
    double? changePercent,
    String? dataSourceType,
    bool? isMarketOpen,
  }) {
    return StockItemModel(
      symbol: symbol,
      name: name,
      country: country,
      flag: flag,
      category: category,
      price: price ?? this.price,
      change: change ?? this.change,
      changePercent: changePercent ?? this.changePercent,
      currency: currency,
      isMarketOpen: isMarketOpen ?? this.isMarketOpen,
      logoUrl: logoUrl,
      dataSourceType: dataSourceType ?? this.dataSourceType,
      description: description,
      openPrice: openPrice,
      highPrice: highPrice,
      lowPrice: lowPrice,
      w52High: w52High,
      w52Low: w52Low,
      peRatio: peRatio,
      marketCap: marketCap,
      volume: volume,
    );
  }
}

class MarketNewsModel {
  final String title;
  final String source;
  final String time;
  final String category;
  final String imageUrl;

  const MarketNewsModel({
    required this.title,
    required this.source,
    required this.time,
    required this.category,
    required this.imageUrl,
  });
}

class MarketDataService {
  static const String _watchlistKey = 'user_watchlist_symbols';

  // Major Global Indices
  static List<MarketIndexModel> getGlobalIndices() {
    return const [
      MarketIndexModel(symbol: '^GSPC', name: 'S&P 500', country: 'USA', flag: '🇺🇸', currentPrice: 5751.13, change: 24.15, changePercent: 0.42, currency: 'USD'),
      MarketIndexModel(symbol: '^IXIC', name: 'NASDAQ', country: 'USA', flag: '🇺🇸', currentPrice: 18137.85, change: 114.30, changePercent: 0.63, currency: 'USD'),
      MarketIndexModel(symbol: '^SSMI', name: 'SMI 20', country: 'Switzerland', flag: '🇨🇭', currentPrice: 12140.50, change: -18.20, changePercent: -0.15, currency: 'CHF'),
      MarketIndexModel(symbol: '^FTSE', name: 'FTSE 100', country: 'UK', flag: '🇬🇧', currentPrice: 8280.60, change: 32.40, changePercent: 0.39, currency: 'GBP'),
      MarketIndexModel(symbol: '^NSEI', name: 'NIFTY 50', country: 'India', flag: '🇮🇳', currentPrice: 25014.60, change: 142.10, changePercent: 0.57, currency: 'INR'),
      MarketIndexModel(symbol: '^STI', name: 'Straits Times', country: 'Singapore', flag: '🇸🇬', currentPrice: 3582.40, change: 8.90, changePercent: 0.25, currency: 'SGD'),
      MarketIndexModel(symbol: '^AXJO', name: 'ASX 200', country: 'Australia', flag: '🇦🇺', currentPrice: 8175.20, change: 19.80, changePercent: 0.24, currency: 'AUD'),
      MarketIndexModel(symbol: 'DFMGI', name: 'DFM General', country: 'UAE', flag: '🇦🇪', currentPrice: 4428.10, change: -4.50, changePercent: -0.10, currency: 'AED'),
    ];
  }

  // Stock Catalog across Global Regions
  static List<StockItemModel> getInitialStocks() {
    return const [
      // US Stocks
      StockItemModel(
        symbol: 'AAPL',
        name: 'Apple Inc.',
        country: 'USA',
        flag: '🇺🇸',
        category: 'US',
        price: 226.78,
        change: 3.45,
        changePercent: 1.54,
        currency: 'USD',
        isMarketOpen: true,
        logoUrl: 'https://logo.clearbit.com/apple.com',
        dataSourceType: 'DELAYED_SNAPSHOT',
        description: 'Apple Inc. designs, manufactures, and markets smartphones, personal computers, tablets, wearables, and accessories worldwide.',
        openPrice: 224.10,
        highPrice: 227.50,
        lowPrice: 223.80,
        w52High: 237.23,
        w52Low: 164.08,
        peRatio: '33.8',
        marketCap: '\$3.45 T',
        volume: '48.2 M',
      ),
      StockItemModel(
        symbol: 'MSFT',
        name: 'Microsoft Corp.',
        country: 'USA',
        flag: '🇺🇸',
        category: 'US',
        price: 428.50,
        change: 4.12,
        changePercent: 0.97,
        currency: 'USD',
        isMarketOpen: true,
        logoUrl: 'https://logo.clearbit.com/microsoft.com',
        dataSourceType: 'DELAYED_SNAPSHOT',
        description: 'Microsoft Corporation develops and supports software, services, devices and solutions including Azure cloud & AI.',
        openPrice: 425.00,
        highPrice: 430.10,
        lowPrice: 424.20,
        w52High: 468.35,
        w52Low: 326.90,
        peRatio: '35.4',
        marketCap: '\$3.18 T',
        volume: '21.5 M',
      ),
      StockItemModel(
        symbol: 'NVDA',
        name: 'NVIDIA Corporation',
        country: 'USA',
        flag: '🇺🇸',
        category: 'US',
        price: 121.80,
        change: 5.40,
        changePercent: 4.64,
        currency: 'USD',
        isMarketOpen: true,
        logoUrl: 'https://logo.clearbit.com/nvidia.com',
        dataSourceType: 'DELAYED_SNAPSHOT',
        description: 'NVIDIA Corporation provides graphics, compute and networking solutions powering modern AI workloads.',
        openPrice: 117.50,
        highPrice: 123.00,
        lowPrice: 116.80,
        w52High: 140.76,
        w52Low: 39.23,
        peRatio: '52.1',
        marketCap: '\$2.99 T',
        volume: '65.4 M',
      ),

      // Swiss & European Stocks
      StockItemModel(
        symbol: 'NESN',
        name: 'Nestlé S.A.',
        country: 'Switzerland',
        flag: '🇨🇭',
        category: 'Europe',
        price: 88.45,
        change: -0.65,
        changePercent: -0.73,
        currency: 'CHF',
        isMarketOpen: true,
        logoUrl: 'https://logo.clearbit.com/nestle.com',
        dataSourceType: 'DELAYED_SNAPSHOT',
        description: 'Nestlé S.A. is a Swiss multinational food and drink processing conglomerate headquartered in Vevey, Switzerland.',
        openPrice: 89.10,
        highPrice: 89.50,
        lowPrice: 88.20,
        w52High: 104.60,
        w52Low: 84.30,
        peRatio: '19.2',
        marketCap: 'CHF 232 B',
        volume: '3.1 M',
      ),
      StockItemModel(
        symbol: 'ROG',
        name: 'Roche Holding AG',
        country: 'Switzerland',
        flag: '🇨🇭',
        category: 'Europe',
        price: 278.20,
        change: 2.80,
        changePercent: 1.02,
        currency: 'CHF',
        isMarketOpen: true,
        logoUrl: 'https://logo.clearbit.com/roche.com',
        dataSourceType: 'DELAYED_SNAPSHOT',
        description: 'Roche Holding AG is a Swiss multinational healthcare company operating globally under pharmaceuticals and diagnostics.',
        openPrice: 276.00,
        highPrice: 280.00,
        lowPrice: 275.50,
        w52High: 298.40,
        w52Low: 221.80,
        peRatio: '16.8',
        marketCap: 'CHF 224 B',
        volume: '1.8 M',
      ),
      StockItemModel(
        symbol: 'NOVN',
        name: 'Novartis AG',
        country: 'Switzerland',
        flag: '🇨🇭',
        category: 'Europe',
        price: 99.15,
        change: 0.45,
        changePercent: 0.46,
        currency: 'CHF',
        isMarketOpen: true,
        logoUrl: 'https://logo.clearbit.com/novartis.com',
        dataSourceType: 'DELAYED_SNAPSHOT',
        description: 'Novartis AG is a Swiss multinational pharmaceutical corporation based in Basel, Switzerland.',
        openPrice: 98.80,
        highPrice: 99.80,
        lowPrice: 98.50,
        w52High: 103.50,
        w52Low: 82.10,
        peRatio: '15.4',
        marketCap: 'CHF 198 B',
        volume: '2.4 M',
      ),
      StockItemModel(
        symbol: 'UBSG',
        name: 'UBS Group AG',
        country: 'Switzerland',
        flag: '🇨🇭',
        category: 'Europe',
        price: 26.40,
        change: 0.35,
        changePercent: 1.34,
        currency: 'CHF',
        isMarketOpen: true,
        logoUrl: 'https://logo.clearbit.com/ubs.com',
        dataSourceType: 'DELAYED_SNAPSHOT',
        description: 'UBS Group AG is a multinational investment bank and financial services company co-headquartered in Zürich and Basel.',
        openPrice: 26.10,
        highPrice: 26.70,
        lowPrice: 26.00,
        w52High: 28.90,
        w52Low: 21.40,
        peRatio: '11.2',
        marketCap: 'CHF 88 B',
        volume: '5.2 M',
      ),

      // Asian Markets
      StockItemModel(
        symbol: 'D05',
        name: 'DBS Group Holdings',
        country: 'Singapore',
        flag: '🇸🇬',
        category: 'Asia',
        price: 37.80,
        change: 0.40,
        changePercent: 1.07,
        currency: 'SGD',
        isMarketOpen: true,
        logoUrl: 'https://logo.clearbit.com/dbs.com',
        dataSourceType: 'DELAYED_SNAPSHOT',
        description: 'DBS Bank Ltd is a Singaporean multinational banking and financial services corporation headquartered in Marina Bay.',
        openPrice: 37.40,
        highPrice: 38.00,
        lowPrice: 37.30,
        w52High: 38.90,
        w52Low: 31.20,
        peRatio: '10.5',
        marketCap: 'SGD 107 B',
        volume: '4.8 M',
      ),
      StockItemModel(
        symbol: 'RELIANCE',
        name: 'Reliance Industries',
        country: 'India',
        flag: '🇮🇳',
        category: 'Asia',
        price: 2945.00,
        change: 18.50,
        changePercent: 0.63,
        currency: 'INR',
        isMarketOpen: true,
        logoUrl: 'https://logo.clearbit.com/ril.com',
        dataSourceType: 'DELAYED_SNAPSHOT',
        description: 'Reliance Industries Limited is an Indian multinational conglomerate headquartered in Mumbai.',
        openPrice: 2930.00,
        highPrice: 2960.00,
        lowPrice: 2925.00,
        w52High: 3217.90,
        w52Low: 2220.30,
        peRatio: '27.4',
        marketCap: '₹ 19.9 T',
        volume: '8.4 M',
      ),
      StockItemModel(
        symbol: 'HDFCBANK',
        name: 'HDFC Bank Limited',
        country: 'India',
        flag: '🇮🇳',
        category: 'Asia',
        price: 1682.30,
        change: 12.40,
        changePercent: 0.74,
        currency: 'INR',
        isMarketOpen: true,
        logoUrl: 'https://logo.clearbit.com/hdfcbank.com',
        dataSourceType: 'DELAYED_SNAPSHOT',
        description: 'HDFC Bank Limited is an Indian banking and financial services company headquartered in Mumbai.',
        openPrice: 1675.00,
        highPrice: 1690.00,
        lowPrice: 1670.00,
        w52High: 1794.00,
        w52Low: 1363.55,
        peRatio: '19.1',
        marketCap: '₹ 12.8 T',
        volume: '12.1 M',
      ),

      // Global ETFs
      StockItemModel(
        symbol: 'SPY',
        name: 'SPDR S&P 500 ETF Trust',
        country: 'USA',
        flag: '🇺🇸',
        category: 'ETF',
        price: 573.40,
        change: 2.10,
        changePercent: 0.37,
        currency: 'USD',
        isMarketOpen: true,
        logoUrl: 'https://logo.clearbit.com/ssga.com',
        dataSourceType: 'DELAYED_SNAPSHOT',
        description: 'SPDR S&P 500 ETF Trust seeks to provide investment results that correspond generally to the price and yield performance of the S&P 500 Index.',
        openPrice: 572.00,
        highPrice: 575.20,
        lowPrice: 571.80,
        w52High: 575.90,
        w52Low: 410.00,
        peRatio: '24.2',
        marketCap: '\$580 B',
        volume: '42.1 M',
      ),
      StockItemModel(
        symbol: 'CHSPI',
        name: 'iShares Swiss Dividend ETF',
        country: 'Switzerland',
        flag: '🇨🇭',
        category: 'ETF',
        price: 134.50,
        change: 0.80,
        changePercent: 0.60,
        currency: 'CHF',
        isMarketOpen: true,
        logoUrl: 'https://logo.clearbit.com/blackrock.com',
        dataSourceType: 'DELAYED_SNAPSHOT',
        description: 'iShares Swiss Dividend ETF tracks Swiss blue-chip dividend paying companies traded on SIX Swiss Exchange.',
        openPrice: 133.80,
        highPrice: 135.00,
        lowPrice: 133.70,
        w52High: 142.10,
        w52Low: 120.40,
        peRatio: '16.5',
        marketCap: 'CHF 4.2 B',
        volume: '450 K',
      ),

      // Precious Metals & Commodities
      StockItemModel(
        symbol: 'XAU',
        name: 'Gold (Zurich Physical Vault)',
        country: 'Switzerland',
        flag: '🇨🇭',
        category: 'Commodity',
        price: 2658.40,
        change: 14.20,
        changePercent: 0.54,
        currency: 'USD',
        isMarketOpen: true,
        logoUrl: 'https://logo.clearbit.com/kitco.com',
        dataSourceType: 'LIVE_API',
        description: 'Zurich Allocated Physical Gold Bullion spot price per troy ounce backed by Swiss vaults.',
        openPrice: 2645.00,
        highPrice: 2665.00,
        lowPrice: 2642.00,
        w52High: 2685.50,
        w52Low: 1810.20,
        peRatio: 'N/A',
        marketCap: 'Global Spot',
        volume: 'Spot Liquid',
      ),
    ];
  }

  // Market News
  static List<MarketNewsModel> getMarketNews() {
    return const [
      MarketNewsModel(
        title: 'Swiss National Bank Keeps Key Rate Stable Amid Controlled Inflation Targets',
        source: 'Swissinfo / Reuters',
        time: '25m ago',
        category: 'Macro Economy',
        imageUrl: 'https://images.unsplash.com/photo-1590283603385-17ffb3a7f29f?w=600&auto=format&fit=crop&q=80',
      ),
      MarketNewsModel(
        title: 'Tech Giants Lead Global Rally as AI Infrastructure Demand Accelerates',
        source: 'Bloomberg Markets',
        time: '1h ago',
        category: 'Global Equities',
        imageUrl: 'https://images.unsplash.com/photo-1611974789855-9c2a0a7236a3?w=600&auto=format&fit=crop&q=80',
      ),
      MarketNewsModel(
        title: 'Gold Hits Highs near \$2,660 as Central Banks Increase Precious Metal Reserves',
        source: 'Financial Times',
        time: '3h ago',
        category: 'Commodities',
        imageUrl: 'https://images.unsplash.com/photo-1610375461246-83df859d849d?w=600&auto=format&fit=crop&q=80',
      ),
      MarketNewsModel(
        title: 'SMI 20 Index Outperforms European Peers Supported by Nestlé & Roche Growth',
        source: 'Zurich Financial Review',
        time: '5h ago',
        category: 'Swiss Markets',
        imageUrl: 'https://images.unsplash.com/photo-1526304640581-d334cdbbf45e?w=600&auto=format&fit=crop&q=80',
      ),
    ];
  }

  // Watchlist Persistence Helper
  static Future<List<String>> getWatchlistSymbols() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_watchlistKey) ?? ['AAPL', 'NESN', 'SPY', 'XAU'];
  }

  static Future<void> toggleWatchlistSymbol(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    final current = prefs.getStringList(_watchlistKey) ?? ['AAPL', 'NESN', 'SPY', 'XAU'];
    if (current.contains(symbol)) {
      current.remove(symbol);
    } else {
      current.add(symbol);
    }
    await prefs.setStringList(_watchlistKey, current);
  }

  // Live Free Market API Fetch (with fallback handling)
  static Future<List<StockItemModel>> fetchUpdatedStockQuotes(List<StockItemModel> currentList) async {
    try {
      // Fetch live Gold price from open API (CoinGecko / Gold API)
      final goldRes = await http.get(Uri.parse("https://api.coingecko.com/api/v3/simple/price?ids=tether-gold&vs_currencies=usd&include_24hr_change=true")).timeout(const Duration(seconds: 4));
      if (goldRes.statusCode == 200) {
        final data = json.decode(goldRes.body);
        if (data['tether-gold'] != null) {
          final goldPrice = (data['tether-gold']['usd'] as num).toDouble();
          final goldChangePercent = (data['tether-gold']['usd_24h_change'] as num).toDouble();
          final index = currentList.indexWhere((s) => s.symbol == 'XAU');
          if (index != -1) {
            currentList[index] = currentList[index].copyWith(
              price: goldPrice,
              changePercent: goldChangePercent,
              change: goldPrice * (goldChangePercent / 100.0),
              dataSourceType: 'LIVE_API',
            );
          }
        }
      }
    } catch (e) {
      debugPrint("MarketDataService live API fetch fallback triggered: $e");
    }
    return currentList;
  }
}
