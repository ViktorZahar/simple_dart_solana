import 'dart:html';

import 'package:simple_dart_solana/simple_dart_solana.dart';

Future<void> main() async {
  final body = querySelector('body');
  final solanaWrapper = SolanaWrapper.mainNet();
  if (body != null) {
    final balanceResult = await solanaWrapper
        .getBalance('FV6ik6NgbspFDEkmKT57Ra3QMBkq8aX1LcTnbK8jcYcQ');
    body.children.add(DivElement()..text = 'getBalance() => $balanceResult');

    final tokenAccBalanceResult = await solanaWrapper
        .getTokenAccountBalance('FV6ik6NgbspFDEkmKT57Ra3QMBkq8aX1LcTnbK8jcYcQ');
    body.children.add(DivElement()
      ..text = 'getTokenAccountBalance() => $tokenAccBalanceResult');

    final allAccounts = await solanaWrapper.getAllTokenAccountsByOwner(
        'C3Arh8v7XxwZnwWukUcs51hNqyf4nSJGkjvL8h4M6khT');
    final mappedAccounts = allAccounts.entries
        .map((ent) => '${ent.key}=${ent.value.toStringAsFixed(5)}');
    body.children.add(DivElement()
      ..text = 'getAllTokenAccountsByOwner() => ${mappedAccounts.join(', ')}');

    final owner = await solanaWrapper
        .getAccountOwner('FV6ik6NgbspFDEkmKT57Ra3QMBkq8aX1LcTnbK8jcYcQ');
    body.children.add(DivElement()..text = 'getAccountOwner() => $owner');

    final emptyOwner = await solanaWrapper
        .getAccountOwner('C3Arh8v7XxwZnwWukUcs51hNqyf4nSJGkjvL8h4M6khT');
    body.children
        .add(DivElement()..text = 'getAccountOwner() empty => $emptyOwner');
  }
}
