import 'package:flutter/material.dart';
import 'package:app/data/services/exchange_rate_service.dart';

class ExchangeRateSettingsScreen extends StatefulWidget {
  const ExchangeRateSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ExchangeRateSettingsScreen> createState() => _ExchangeRateSettingsScreenState();
}

class _ExchangeRateSettingsScreenState extends State<ExchangeRateSettingsScreen> {
  final _sarToYerController = TextEditingController();
  final _usdToYerController = TextEditingController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  Future<void> _loadRates() async {
    await ExchangeRateService.loadRates();
    setState(() {
      _sarToYerController.text = ExchangeRateService.sarToYerRate.toString();
      _usdToYerController.text = ExchangeRateService.usdToYerRate.toString();
      _isLoading = false;
    });
  }

  Future<void> _saveRates() async {
    final sarToYer = double.tryParse(_sarToYerController.text);
    final usdToYer = double.tryParse(_usdToYerController.text);
    
    if (sarToYer == null || sarToYer <= 0) {
      _showError('سعر صرف الريال السعودي غير صحيح');
      return;
    }
    
    if (usdToYer == null || usdToYer <= 0) {
      _showError('سعر صرف الدولار غير صحيح');
      return;
    }
    
    await ExchangeRateService.updateRates(
      sarToYer: sarToYer,
      usdToYer: usdToYer,
    );
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تم تحديث أسعار الصرف'), backgroundColor: Colors.green),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'saudi': return 'ر.س';
      case 'dollar': return 'دولار';
      default: return 'ر.ي';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('إعدادات أسعار الصرف'),
          centerTitle: true,
          backgroundColor: Colors.teal,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('إعدادات أسعار الصرف'),
        centerTitle: true,
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text(
                      'أسعار الصرف الحالية',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _sarToYerController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '1 ر.س = ? ر.ي',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    TextField(
                      controller: _usdToYerController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '1 دولار = ? ر.ي',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('دولار → سعودي:', style: TextStyle(fontSize: 12)),
                              Text('1 دولار = ${ExchangeRateService.usdToSarRate.toStringAsFixed(2)} ر.س', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('سعودي → دولار:', style: TextStyle(fontSize: 12)),
                              Text('1 ر.س = ${ExchangeRateService.sarToUsdRate.toStringAsFixed(2)} دولار', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            ElevatedButton(
              onPressed: _saveRates,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
              ),
              child: const Text('حفظ التغييرات'),
            ),
          ],
        ),
      ),
    );
  }
}