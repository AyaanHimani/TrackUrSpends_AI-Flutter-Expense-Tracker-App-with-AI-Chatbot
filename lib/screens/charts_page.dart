import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models.dart';

class ChartsPage extends StatefulWidget {
  final List<TransactionModel> allTransactions;
  final String userId;

  const ChartsPage({super.key, required this.allTransactions, required this.userId});

  @override
  _ChartsPageState createState() => _ChartsPageState();
}

class _ChartsPageState extends State<ChartsPage> {
  List<TransactionModel> _transactions = [];
  List<TransactionModel> _filteredTransactions = [];
  String _selectedPeriod = 'Overall';
  DateTimeRange? _customDateRange;
  String _selectedChartType = 'Expense';

  @override
  void initState() {
    super.initState();
    _transactions = widget.allTransactions;
    _filteredTransactions = _transactions;
  }

  void _filterTransactions(String period) {
    DateTime now = DateTime.now();
    DateTime startDate = DateTime(now.year, now.month, now.day, 0, 0, 0, 1);

    switch (period) {
      case 'Today':
        startDate = DateTime(now.year, now.month, now.day);
        break;
      case 'This Week':
        startDate = startDate.subtract(Duration(days: now.weekday - 1));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      case 'Custom':
        if (_customDateRange != null) {
          startDate = _customDateRange!.start;
          setState(() {
            _filteredTransactions = _transactions.where((transaction) {
              DateTime transactionDate = transaction.date.toDate();
              return transactionDate.isAfter(startDate) &&
                  transactionDate.isBefore(
                      _customDateRange!.end.add(const Duration(hours: 23, minutes: 59)));
            }).toList();
          });
          return;
        } else {
          startDate = DateTime(1970);
        }
        break;
      default:
        startDate = DateTime(1970);
    }

    setState(() {
      _selectedPeriod = period;
      _filteredTransactions = _transactions
          .where((transaction) => transaction.date.toDate().isAfter(startDate))
          .toList();
    });
  }

  Future<void> _selectCustomDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _customDateRange) {
      setState(() {
        _customDateRange = picked;
        _selectedPeriod = 'Custom';
        _filterTransactions('Custom');
      });
    }
  }

  void _toggleChartType() {
    setState(() {
      _selectedChartType = _selectedChartType == 'Expense' ? 'Income' : 'Expense';
    });
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return const Color(0xFFFFD507);
      case 'Bills':
        return Colors.purpleAccent;
      case 'Transport':
        return Colors.pink;
      case 'Shopping':
        return Colors.green;
      case 'Entertainment':
        return Colors.cyan;
      case 'Other':
        return const Color(0xFFEF6C06);
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildChartsPageBody(),
    );
  }

  Widget _buildChartsPageBody() {
    return Column(
      children: [
        _buildPeriodSelector(),
        _buildChartTypeToggle(),
        Expanded(child: _buildCharts()),
      ],
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5B4),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...['Overall', 'Today', 'This Week', 'This Month', 'This Year']
                .map((period) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: TextButton(
                onPressed: () => _filterTransactions(period),
                style: TextButton.styleFrom(
                  foregroundColor: _selectedPeriod == period ? Colors.white : Colors.grey,
                  backgroundColor: _selectedPeriod == period ? const Color(0xFFEF6C06) : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(period),
              ),
            ))
                .toList(),
            IconButton(
              icon: const Icon(Icons.date_range, color: Color(0xFFEF6C06)),
              onPressed: () => _selectCustomDateRange(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartTypeToggle() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5B4),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: _toggleChartType,
            style: TextButton.styleFrom(
              foregroundColor: _selectedChartType == 'Expense' ? Colors.white : Colors.grey,
              backgroundColor: _selectedChartType == 'Expense' ? Colors.redAccent : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Expense'),
          ),
          TextButton(
            onPressed: _toggleChartType,
            style: TextButton.styleFrom(
              foregroundColor: _selectedChartType == 'Income' ? Colors.white : Colors.grey,
              backgroundColor: _selectedChartType == 'Income' ? Colors.green : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            child: const Text('Income'),
          ),
        ],
      ),
    );
  }

  Widget _buildCharts() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildChartContainer('Income vs. Expense', _buildIncomeExpenseBarChart()),
          const SizedBox(height: 20),
          _buildChartContainer('Monthly Transactions', _buildMonthlyLineChart()),
          const SizedBox(height: 20),
          _buildChartContainer('Category Breakdown', _buildCategoryBarChart()),
        ],
      ),
    );
  }

  Widget _buildChartContainer(String title, Widget chart) {
    return Container(
      margin: const EdgeInsets.all(16.0),
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE5B4),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        children: [
          _buildChartTitle(title),
          chart,
        ],
      ),
    );
  }

  Widget _buildChartTitle(String title) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFFEF6C06),
        ),
      ),
    );
  }

  Widget _buildIncomeExpenseBarChart() {
    double totalIncome = 0.0;
    double totalExpense = 0.0;

    for (var transaction in _filteredTransactions) {
      if (transaction.type == 'Income') {
        totalIncome += transaction.amount;
      } else {
        totalExpense += transaction.amount;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    switch (value.toInt()) {
                      case 0:
                        return const Text('Income');
                      case 1:
                        return const Text('Expense');
                      default:
                        return const Text('');
                    }
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 50),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: const FlGridData(show: true),
            borderData: FlBorderData(show: false),
            barGroups: [
              BarChartGroupData(
                x: 0,
                barRods: [
                  BarChartRodData(
                    toY: totalIncome,
                    color: Colors.green,
                    width: 20,
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                  ),
                ],
              ),
              BarChartGroupData(
                x: 1,
                barRods: [
                  BarChartRodData(
                    toY: totalExpense,
                    color: Colors.redAccent,
                    width: 20,
                    borderRadius: const BorderRadius.all(Radius.circular(6)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyLineChart() {
    Map<int, double> monthlyTotals = {};
    for (var transaction in _transactions) {
      if (_selectedChartType == 'Expense' && transaction.type == 'Expense') {
        int month = transaction.date.toDate().month;
        monthlyTotals.update(month, (value) => value + transaction.amount,
            ifAbsent: () => transaction.amount);
      } else if (_selectedChartType == 'Income' && transaction.type == 'Income') {
        int month = transaction.date.toDate().month;
        monthlyTotals.update(month, (value) => value + transaction.amount,
            ifAbsent: () => transaction.amount);
      }
    }

    List<FlSpot> spots = List.generate(12, (index) {
      double total = monthlyTotals[index + 1] ?? 0.0;
      return FlSpot(index.toDouble(), total);
    });

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 250,
        child: LineChart(
          LineChartData(
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final month = DateFormat.MMM().format(DateTime(0, value.toInt() + 1));
                    return Text(month, style: const TextStyle(fontSize: 12));
                  },
                  interval: 1,
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 50),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: const FlGridData(show: true),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: const Color(0xFFFFE5B4), width: 2),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                barWidth: 4,
                preventCurveOverShooting: true,
                curveSmoothness: 0.30,
                color: _selectedChartType == 'Expense' ? Colors.redAccent : Colors.green,
                belowBarData: BarAreaData(
                  show: true,
                  color:  (_selectedChartType == 'Expense' ? Colors.redAccent : Colors.green).withOpacity(0.45),
                ),
                dotData: const FlDotData(show: true),
              ),
            ],
            extraLinesData: ExtraLinesData(
              horizontalLines: [
                HorizontalLine(
                  y: 0,
                  color: Colors.black,
                  strokeWidth: 1,
                ),
              ],
            ),
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
                getTooltipItems: (List<LineBarSpot> touchedSpots) {
                  return touchedSpots.map((spot) {
                    final month = DateFormat.MMMM().format(DateTime(0, spot.x.toInt() + 1));
                    return LineTooltipItem(
                      '$month: ${spot.y.toStringAsFixed(2)}',
                      TextStyle(color: _selectedChartType == 'Expense' ? Colors.redAccent : Colors.green),
                    );
                  }).toList();
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBarChart() {
    Map<String, double> categoryTotals = {};

    for (var transaction in _filteredTransactions) {
      if (_selectedChartType == 'Expense' && transaction.type == 'Expense') {
        categoryTotals.update(transaction.category, (value) => value + transaction.amount,
            ifAbsent: () => transaction.amount);
      } else if (_selectedChartType == 'Income' && transaction.type == 'Income') {
        categoryTotals.update(transaction.category, (value) => value + transaction.amount,
            ifAbsent: () => transaction.amount);
      }
    }

    List<BarChartGroupData> barGroups = categoryTotals.entries.map((entry) {
      return BarChartGroupData(
        x: entry.key.hashCode,
        barRods: [
          BarChartRodData(
            toY: entry.value,
            color: _getCategoryColor(entry.key),
            width: 20,
            borderRadius: const BorderRadius.all(Radius.circular(6)),
          ),
        ],
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 200,
        child: BarChart(
          BarChartData(
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    String category = categoryTotals.keys.firstWhere(
                          (key) => key.hashCode == value.toInt(),
                      orElse: () => '',
                    );
                    return Transform.rotate(
                        angle: -pi / 6,
                        child: Text(category, style: const TextStyle(fontSize: 12)),
                    );
                  },
                ),
              ),
              leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: true, reservedSize: 50),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            gridData: const FlGridData(show: true),
            borderData: FlBorderData(show: false),
            barGroups: barGroups,
          ),
        ),
      ),
    );
  }
}
