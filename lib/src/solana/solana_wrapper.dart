@JS()
library solana_wrapper;

import 'dart:convert';
import 'dart:js_util';

import 'package:js/js.dart';

const solanaMainnet = 'https://api.mainnet-beta.solana.com';

@JS('JSON.stringify')
// ignore: avoid_annotating_with_dynamic
external String stringify(dynamic obj);
// ignore: type_annotate_public_apis
Map<String, dynamic> jsObjectToMap(jsObject) =>
    json.decode(stringify(jsObject));

List<Map<String, dynamic>> jsObjectToList(jsList) {
  final ret = <Map<String, dynamic>>[];
  if (jsList is List) {
    for (final jsObject in jsList) {
      ret.add(json.decode(stringify(jsObject)));
    }
  }
  return ret;
}

List<String> jsObjectToStringList(jsList) {
  if (jsList is List) {
    return jsList.map((e) => e.toString()).toList();
  } else {
    throw Exception('js object is not list');
  }
}

@JS('SolanaWrapper')
class SolanaWrapperRaw {
  external factory SolanaWrapperRaw(String url);

  external dynamic getBalance(String address);

  external dynamic getTokenAccountBalance(String address);

  external dynamic getAllTokenAccountsByOwner(String address);

  external dynamic getAccountOwner(String address);

  external dynamic getStaked(String address);
}

class SolanaWrapper {
  SolanaWrapper(String url) {
    _solanaWrapperRaw = SolanaWrapperRaw(url);
  }

  factory SolanaWrapper.mainNet() => SolanaWrapper(solanaMainnet);

  late SolanaWrapperRaw _solanaWrapperRaw;

  Future<double> getBalance(String address) async =>
      promiseToFuture(_solanaWrapperRaw.getBalance(address));

  Future<double> getTokenAccountBalance(String address) async {
    final resObj = await promiseToFuture(
        _solanaWrapperRaw.getTokenAccountBalance(address));
    final retMap = jsObjectToMap(resObj);
    return retMap['value']['uiAmount']!;
  }

  Future<Map<String, double>> getAllTokenAccountsByOwner(String address) async {
    final resObj = await promiseToFuture(
        _solanaWrapperRaw.getAllTokenAccountsByOwner(address));
    final resList = jsObjectToStringList(resObj);
    final ret = <String, double>{};
    for (final resRow in resList) {
      final spl = resRow.split('|');
      ret[spl[0]] = double.parse(spl[1]);
    }
    return ret;
  }

  Future<String> getAccountOwner(String address) async =>
      promiseToFuture(_solanaWrapperRaw.getAccountOwner(address));

  Future<Map<String, double>> getStaked(String address) async {
    final resObj = await promiseToFuture(_solanaWrapperRaw.getStaked(address));
    final resMap = jsObjectToMap(resObj);
    final ret = <String, double>{};
    resMap.forEach((key, value) {
      ret[key] = value;
    });
    return ret;
  }
}
