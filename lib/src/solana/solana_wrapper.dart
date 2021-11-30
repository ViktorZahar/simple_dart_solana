@JS()
library solana_wrapper;

import 'dart:convert';
import 'dart:js_util';
import 'dart:typed_data';

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

class AccountInfo {
  AccountInfo();

  late Uint8List data;
  bool executable = false;
  int lamports = 0;
  String owner = '';
  int rentEpoch = 0;
  String address = '';
}

class StakeActivationData {
  String state = '';
  double active = 0;
  double inactive = 0;
}

List<String> jsObjectToStringList(jsList) {
  if (jsList is List) {
    return jsList.map((e) => e.toString()).toList();
  } else {
    throw Exception('js object is not list');
  }
}

@JS('publicKeyFromArray')
external dynamic publicKeyFromArrayRaw(dynamic arr);

String publicKeyFromArray(Uint8List byteData) {
  final arr = <int>[];
  for (final b in byteData) {
    arr.add(b);
  }
  return publicKeyFromArrayRaw(jsify(arr));
}

@JS('SolanaWrapper')
class SolanaWrapperRaw {
  external factory SolanaWrapperRaw(String url);

  external dynamic getBalance(String address);

  external dynamic getTokenAccountBalance(String address);

  external dynamic getAllTokenAccountsByOwner(String address);

  external dynamic getAccountOwner(String address);

  external dynamic getStaked(String address, String programAddress);

  external dynamic getStakeActivation(String address);

  external dynamic getMultipleAccountsInfo(dynamic addresses);

  external dynamic getProgramAccounts(
      dynamic programAddress, String filterAddress, int offset);

  external dynamic findFarmsolObligationAddress(
      String address,
      String programAddress,
      int farmIndex,
      int obligationIndex,
      int userAddressIndex);
}

class SolanaWrapper {
  SolanaWrapper(String url) {
    _solanaWrapperRaw = SolanaWrapperRaw(url);
  }

  bool debug = true;

  factory SolanaWrapper.mainNet() => SolanaWrapper(solanaMainnet);

  late SolanaWrapperRaw _solanaWrapperRaw;

  Future<double> getBalance(String address) async =>
      promiseToFuture(_solanaWrapperRaw.getBalance(address));

  Future<BigInt> getTokenAccountBalance(String address) async {
    final resObj = await promiseToFuture(
        _solanaWrapperRaw.getTokenAccountBalance(address));
    final retMap = jsObjectToMap(resObj);
    final resStr = retMap['value']['amount']!;
    return BigInt.parse(resStr);
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

  Future<Map<String, double>> getStaked(
      String address, String programAddress) async {
    var ret = <String, double>{};
    final stakeAccounts = await getProgramAccounts(programAddress, address, 12);

    for (final stakeAccount in stakeAccounts) {
      final resp = await getStakeActivation(stakeAccount.address);
      ret[stakeAccount.address] = resp.active;
    }
    return ret;
  }

  Future<List<AccountInfo>> getProgramAccounts(
      String programAddress, String filterAddress, int offset) async {
    final resObj = await promiseToFuture(_solanaWrapperRaw.getProgramAccounts(
        programAddress, filterAddress, offset));
    final ret = <AccountInfo>[];
    if (resObj is List) {
      for (final resRow in resObj) {
        final accountInfo = AccountInfo()
          ..owner = resRow.owner
          ..executable = resRow.executable
          ..lamports = resRow.lamports
          ..rentEpoch = resRow.rentEpoch
          ..address = resRow.address;
        final dataStr = resRow.data.toString();
        final dataIntList = <int>[];
        if (dataStr.isNotEmpty) {
          for (final numStr in dataStr.split(',')) {
            dataIntList.add(int.parse(numStr));
          }
          accountInfo.data = Uint8List.fromList(dataIntList);
        } else {
          accountInfo.data = Uint8List(0);
        }
        ret.add(accountInfo);
      }
    }
    return ret;
  }

  Future<StakeActivationData> getStakeActivation(String address) async {
    final resObj =
        await promiseToFuture(_solanaWrapperRaw.getStakeActivation(address));
    final ret = StakeActivationData()
      ..active = resObj.active
      ..inactive = resObj.inactive
      ..state = resObj.state;
    return ret;
  }

  Future<String> findFarmsolObligationAddress(String address, String programId,
      int farmIndex, int obligationIndex, int userAddressIndex) async {
    final resObj = await promiseToFuture(
        _solanaWrapperRaw.findFarmsolObligationAddress(
            address, programId, farmIndex, obligationIndex, userAddressIndex));
    return resObj.toString();
  }

  Future<List<AccountInfo?>> getMultipleAccountsInfoRaw(
      List<String> addresses) async {
    final resObj = await promiseToFuture(
        _solanaWrapperRaw.getMultipleAccountsInfo(jsify(addresses)));
    final ret = <AccountInfo?>[];
    if (resObj is List) {
      var i = 0;
      for (final resRow in resObj) {
        if (resRow == null) {
          ret.add(null);
        } else {
          final accountInfo = AccountInfo()
            ..owner = resRow.owner
            ..executable = resRow.executable
            ..lamports = resRow.lamports
            ..rentEpoch = resRow.rentEpoch
            ..address = addresses[i];
          final dataStr = resRow.data.toString();
          final dataIntList = <int>[];
          if (dataStr.isNotEmpty) {
            for (final numStr in dataStr.split(',')) {
              dataIntList.add(int.parse(numStr));
            }
            accountInfo.data = Uint8List.fromList(dataIntList);
          } else {
            accountInfo.data = Uint8List(0);
          }
          ret.add(accountInfo);
        }
        i++;
      }
    }
    return ret;
  }

  Future<List<AccountInfo?>> getMultipleAccountsInfo(List<String> addresses,
      {batchSize = 100, maxThreads = 8}) async {
    if (addresses.isEmpty) {
      return <AccountInfo?>[];
    }
    final callResult = <AccountInfo?>[];
    try {
      final chunks = groupByBatch(addresses, batchSize, 1);
      for (final chunk in chunks) {
        // final futureList = <Future<List<AccountInfo>>>[];
        // for (final batch in chunk) {
        //   Future<List<AccountInfo>> fut =
        //       promiseToFuture(getMultipleAccountsInfoRaw(batch));
        //   futureList.add(fut);
        // }
        // final chunkResult = await Future.wait(futureList);
        // if (chunkResult is List) {
        //   for (final chunkResultRow in chunkResult) {
        //     callResult.addAll(chunkResultRow);
        //   }
        // }
        final chunkResult = await getMultipleAccountsInfoRaw(chunk[0]);
        callResult.addAll(chunkResult);
      }
    } catch (e) {
      print(e.toString());
      if (debug) {
        for (final address in addresses) {
          try {
            await promiseToFuture(getMultipleAccountsInfoRaw([address]));
          } catch (e) {
            print('bad address address');
            rethrow;
          }
        }
        throw Exception('too big batch size $batchSize');
      }
      throw Exception(
          'execution getMultipleAccountsInfo error (solana): ${e.toString()}');
    }
    if (callResult is List) {
      return callResult;
    } else {
      throw Exception('Unknown multicall result type');
    }
  }

  Future<List<List<AccountInfo?>>> getMultipleAccountsInfo2(
      List<List<String>> callsList,
      {batchSize = 100}) async {
    final addresses = <String>[];
    for (final list in callsList) {
      addresses.addAll(list);
    }
    final result0 =
        await getMultipleAccountsInfo(addresses, batchSize: batchSize);
    final res = <List<AccountInfo?>>[];
    var callNum = 0;
    for (final list in callsList) {
      final resultRow = <AccountInfo?>[];
      for (var i = 0; i < list.length; i++) {
        resultRow.add(result0[callNum]);
        callNum++;
      }
      res.add(resultRow);
    }
    return res;
  }

  Future<List<List<List<AccountInfo?>>>> getMultipleAccountsInfo3(
      List<List<List<String>>> callsList,
      {batchSize = 100}) async {
    final addresses = <String>[];
    for (final list0 in callsList) {
      for (final list1 in list0) {
        addresses.addAll(list1);
      }
    }
    final result0 =
        await getMultipleAccountsInfo(addresses, batchSize: batchSize);
    final res = <List<List<AccountInfo?>>>[];
    var callNum = 0;
    for (final list0 in callsList) {
      final resultRow0 = <List<AccountInfo?>>[];
      for (final list1 in list0) {
        final resultRow1 = <AccountInfo?>[];
        for (var i = 0; i < list1.length; i++) {
          resultRow1.add(result0[callNum]);
          callNum++;
        }
        resultRow0.add(resultRow1);
      }
      res.add(resultRow0);
    }
    return res;
  }
}

List<List<List<String>>> groupByBatch(
    List<String> addresses, int batchSize, int maxThreads) {
  final chanks = <List<String>>[];
  for (var i = 0; i < addresses.length; i += batchSize) {
    var lastIdx = i + batchSize;
    if (lastIdx > addresses.length) {
      lastIdx = addresses.length;
    }
    chanks.add(addresses.getRange(i, lastIdx).toList());
  }
  final ret = <List<List<String>>>[];
  for (var j = 0; j < chanks.length; j += maxThreads) {
    var lastIdx = j + maxThreads;
    if (lastIdx > chanks.length) {
      lastIdx = chanks.length;
    }
    ret.add(chanks.getRange(j, lastIdx).toList());
  }
  return ret;
}
