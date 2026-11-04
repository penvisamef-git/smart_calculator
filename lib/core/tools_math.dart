import 'dart:math';

/// Pure math for the Quick tools. No Flutter imports, easy to unit test.
class ToolsMath {
  ToolsMath._();

  /// 85 with 20% off → pay 68, save 17.
  static ({double pay, double save}) discount(double price, double percent) {
    final save = price * percent / 100;
    return (pay: price - save, save: save);
  }

  /// Add VAT to a price, or take VAT out of a price that already includes it.
  static ({double before, double vat, double total}) vat(
    double amount,
    double ratePercent, {
    required bool add,
  }) {
    final r = ratePercent / 100;
    if (add) {
      final vat = amount * r;
      return (before: amount, vat: vat, total: amount + vat);
    }
    final before = amount / (1 + r);
    return (before: before, vat: amount - before, total: amount);
  }

  /// Bill + tip shared by [people].
  static ({double tip, double total, double each}) tipSplit(
    double bill,
    double tipPercent,
    int people,
  ) {
    final tip = bill * tipPercent / 100;
    final total = bill + tip;
    return (tip: tip, total: total, each: total / max(1, people));
  }

  /// Equal monthly payments (standard amortized loan).
  static ({double monthly, double total, double interest}) loan(
    double amount,
    double yearRatePercent,
    int months,
  ) {
    if (months <= 0) return (monthly: 0, total: 0, interest: 0);
    final r = yearRatePercent / 100 / 12;
    final monthly = r == 0
        ? amount / months
        : amount * r / (1 - pow(1 + r, -months));
    final total = monthly * months;
    return (monthly: monthly, total: total, interest: total - amount);
  }

  /// Profit, margin (% of price) and markup (% of cost).
  static ({double profit, double margin, double markup}) margin(
    double cost,
    double price,
  ) {
    final profit = price - cost;
    return (
      profit: profit,
      margin: price == 0 ? 0 : profit / price * 100,
      markup: cost == 0 ? 0 : profit / cost * 100,
    );
  }

  static double usdToKhr(double usd, double rate) => usd * rate;
  static double khrToUsd(double khr, double rate) => rate == 0 ? 0 : khr / rate;
}
