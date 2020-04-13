class CurrencyData {
  Map<String, double> rates;
  String base;
  DateTime date;
  DateTime updateTime;

  CurrencyData(this.rates, this.base, this.date, this.updateTime);

  factory CurrencyData.fromJson(dynamic json) {
    Map rates = json['rates'];
    rates[json['base']] = 1.0;
    return CurrencyData(rates.map((a, b) => MapEntry(a as String, b as double)), json['base'] as String,
        DateTime.parse(json['date']), DateTime.now());
  }

  @override
  String toString() {
    return '{ ${this.base}, ${this.rates}, ${this.date.day}-${this.date.month}-${this.date.year} }';
  }

  double getRate(String sourceCurrency, String destCurrency) {
    return (rates[sourceCurrency] / rates[destCurrency]);
  }

  bool validateMessage(String message) {
    List<String> queryList = message.toUpperCase().split(' ');
    if (queryList.length > 3) {
      if (rates.containsKey(queryList[1])) {
        if (rates.containsKey(queryList[3])) {
          return true;
        }
      }
    }
    return false;
  }

  String getCurrencies() {
    return rates.keys.toList().toString().replaceAll('[', '').replaceAll(']', '');
  }

  String hasCurrency(String text) {
    List<String> textList = text.toUpperCase().split(' ');
    if (textList.length > 1) {
      if (rates.containsKey(textList[1])) return '${textList[1]} is supported';
    } else if (textList.length < 2) {
      return 'Insufficient arguments, try /supports gbp';
    }
    return "This currency is not supported";
  }
}
