// lib/modules/reports/widgets/report_loading.dart
import 'package:flutter/material.dart';

class ReportLoading extends StatelessWidget {
  final String? message;
  final double size;
  
  const ReportLoading({
    Key? key,
    this.message,
    this.size = 40,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(strokeWidth: 3),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ],
      ),
    );
  }
}

/// شاشة تحميل للجدول (شريط تقدم)
class TableLoadingState extends StatelessWidget {
  final int rows;
  
  const TableLoadingState({
    Key? key,
    this.rows = 5,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(rows, (index) => _buildShimmerRow()),
    );
  }
  
  Widget _buildShimmerRow() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(
        child: SizedBox(
          width: 100,
          height: 16,
          child: LinearProgressIndicator(
            backgroundColor: Colors.transparent,
          ),
        ),
      ),
    );
  }
}

/// شاشة تحميل للرسم البياني
class ChartLoadingState extends StatelessWidget {
  final double height;
  
  const ChartLoadingState({
    Key? key,
    this.height = 250,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// شاشة تحميل للبطاقات (شبكة من الـ Shimmer)
class CardsLoadingState extends StatelessWidget {
  final int count;
  
  const CardsLoadingState({
    Key? key,
    this.count = 4,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: count,
      itemBuilder: (context, index) => _buildShimmerCard(),
    );
  }
  
  Widget _buildShimmerCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: SizedBox(
          width: 40,
          height: 40,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}