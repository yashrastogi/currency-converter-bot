import 'dart:async';
import 'dart:io';
import 'package:teledart/model.dart';
import 'package:dio/dio.dart';
import 'package:teledart/teledart.dart';
import 'package:teledart/telegram.dart';
import 'data.dart';

CurrencyData currencyData;
Dio dio;

double convertCurrency(double amount, String sourceCurrency, String destCurrency) {
  double rate = currencyData.getRate(sourceCurrency, destCurrency);
  return amount / rate;
}

void updateCurrencyData() async {
  String apiPath = "https://api.exchangeratesapi.io/latest";
  currencyData = CurrencyData.fromJson((await dio.get(apiPath)).data);
}

void main() async {
  dio = new Dio();
  await updateCurrencyData();
  new Timer.periodic(Duration(hours: 6), (Timer t) async => await updateCurrencyData());

  TeleDart teledart = TeleDart(Telegram(Platform.environment['TELEGRAM_API_TOKEN']), Event());
  teledart.start().then((me) => print('${me.username} is initialised.'));

  teledart.onCommand('start').listen(((message) => {
        teledart.replyMessage(message,
            'Hello, Sir ${message.from.first_name}${message.from.last_name == null ? "" : " " + message.from.last_name}!'),
        teledart.replyMessage(message, 'To get started, enter a query like so:'),
        teledart.replyMessage(message, '300 inr to usd'),
        teledart.replyMessage(message, 'Inline mode is also supported, try @CurrenciConvBot <query> in chat')
      }));

  List<String> queryList;
  teledart.onMessage().listen((message) => {
        print("Incoming ${message.runtimeType} \"" +
            message.text +
            "\" from ${message.from.first_name}${message.from.last_name == null ? "" : " " + message.from.last_name}"),
        if (currencyData.validateMessage(message.text))
          {
            queryList = message.text.toUpperCase().split(' '),
            teledart.replyMessage(message,
                '${convertCurrency(double.parse(queryList[0]), queryList[1], queryList[3]).toStringAsFixed(2)} ${queryList[3]}')
          }
      });

  teledart.onCommand('author').listen((message) => teledart.replyMessage(message, '@yash02'));
  teledart.onCommand('currencies').listen((message) => teledart.replyMessage(message, currencyData.getCurrencies()));
  teledart
      .onCommand('supports')
      .listen((message) => teledart.replyMessage(message, currencyData.hasCurrency(message.text)));
  teledart
      .onCommand('updatetime')
      .listen((message) => teledart.replyMessage(message, currencyData.updateTime.toUtc().toString() + " UTC"));

  teledart.onInlineQuery().listen((inlineQuery) => {
        print("Incoming ${inlineQuery.runtimeType} \"" +
            inlineQuery.query +
            "\" from ${inlineQuery.from.first_name}${inlineQuery.from.last_name == null ? "" : " " + inlineQuery.from.last_name}"),
        if (currencyData.validateMessage(inlineQuery.query))
          {
            queryList = inlineQuery.query.toUpperCase().split(' '),
            teledart.answerInlineQuery(inlineQuery, [
              InlineQueryResultArticle(
                  id: queryList[3] + queryList[0] + queryList[1],
                  title:
                      '${convertCurrency(double.parse(queryList[0]), queryList[1], queryList[3]).toStringAsFixed(2)} ${queryList[3]}',
                  input_message_content: InputTextMessageContent(
                      message_text:
                          "${queryList[0]} ${queryList[1]} = ${convertCurrency(double.parse(queryList[0]), queryList[1], queryList[3]).toStringAsFixed(2)} ${queryList[3]}"))
            ])
          }
      });
}
