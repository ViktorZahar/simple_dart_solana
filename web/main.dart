import 'dart:html';

import 'package:simple_dart_solana/simple_dart_solana.dart';

Future<void> main() async {
  final body = querySelector('body');
  final solanaWrapper = SolanaWrapper.mainNet();
  if (body != null) {
    var solAddress = await solanaWrapper.findFarmsolObligationAddress(
        '7fSNtTYLtxLAnG2vzK7MX8ndcizjBieRaLDj5NLbhnLH',
        'Bt2WPMmbwHPk36i4CRucNDyLcmoGdC7xEdrVuxgJaNE6',0,0,0);
    body.children.add(DivElement()..text = 'soladdress1 => $solAddress');

    solAddress = await solanaWrapper.findFarmsolObligationAddress(
        '7fSNtTYLtxLAnG2vzK7MX8ndcizjBieRaLDj5NLbhnLH',
        'Bt2WPMmbwHPk36i4CRucNDyLcmoGdC7xEdrVuxgJaNE6',1,0,0);
    body.children.add(DivElement()..text = 'soladdress2 => $solAddress');

    solAddress = await solanaWrapper.findFarmsolObligationAddress(
        '7fSNtTYLtxLAnG2vzK7MX8ndcizjBieRaLDj5NLbhnLH',
        'Bt2WPMmbwHPk36i4CRucNDyLcmoGdC7xEdrVuxgJaNE6',0,1,0);
    body.children.add(DivElement()..text = 'soladdress3 => $solAddress');

    solAddress = await solanaWrapper.findFarmsolObligationAddress(
        '7fSNtTYLtxLAnG2vzK7MX8ndcizjBieRaLDj5NLbhnLH',
        'Bt2WPMmbwHPk36i4CRucNDyLcmoGdC7xEdrVuxgJaNE6',0,0,1);
    body.children.add(DivElement()..text = 'soladdress4 => $solAddress');

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

    final staked = await solanaWrapper.getStaked(
        '4SyWon3CXL6oYrpXdY5XZfyK84ZYYG6ZDWkDeu32YVoP',
        'Stake11111111111111111111111111111111111111');
    final mappedStaked = staked.entries
        .map((ent) => '${ent.key}=${ent.value.toStringAsFixed(5)}');
    body.children.add(DivElement()..text = 'getStaked() => $mappedStaked');

  }
}
