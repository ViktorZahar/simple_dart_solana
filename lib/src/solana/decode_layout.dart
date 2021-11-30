import 'dart:math';
import 'dart:typed_data';

import '../../simple_dart_solana.dart';

class Decoder {
  Decoder(this.data);

  int currentOffset = 0;
  late Uint8List data;

  String address() {
    final arr = data.buffer.asUint8List(currentOffset, 32);
    currentOffset += 32;
    return publicKeyFromArray(arr);
  }

  Uint8List blob(int size) {
    final arr = data.buffer.asUint8List(currentOffset, size);
    currentOffset += size;
    return arr;
  }

  bool boolean() {
    final ret = data.buffer.asUint8List(currentOffset, 1)[0];
    currentOffset += 1;
    return ret == 1;
  }

  int u8() {
    final ret = data.buffer.asUint8List(currentOffset, 1)[0];
    currentOffset += 1;
    return ret;
  }

  int u16() {
    final arr = data.buffer.asUint8List(currentOffset, 2);
    currentOffset += 2;
    var ret = BigInt.zero;
    for (var i = 0; i < 2; i++) {
      ret += BigInt.from(arr[i]) * BigInt.from(pow(256, i));
    }
    return ret.toInt();
  }

  int u32() {
    final arr = data.buffer.asUint8List(currentOffset, 4);
    currentOffset += 4;
    var ret = BigInt.zero;
    for (var i = 0; i < 4; i++) {
      ret += BigInt.from(arr[i]) * BigInt.from(pow(256, i));
    }
    return ret.toInt();
  }

  BigInt u64() {
    final arr = data.buffer.asUint8List(currentOffset, 8);
    currentOffset += 8;
    var ret = BigInt.zero;
    for (var i = 0; i < 8; i++) {
      ret += BigInt.from(arr[i]) * BigInt.from(pow(256, i));
    }
    return ret;
  }

  BigInt u128() {
    final arr = data.buffer.asUint8List(currentOffset, 16);
    currentOffset += 16;
    var ret = BigInt.zero;
    for (var i = 0; i < 16; i++) {
      ret += BigInt.from(arr[i]) * BigInt.from(pow(256, i));
    }
    return ret;
  }
}