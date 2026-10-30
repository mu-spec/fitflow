import 'package:fitflow/l10n/fitflow_l10n.dart';
import 'package:flutter/material.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});
  @override
  Widget build(BuildContext context) => Semantics(
        header: true,
        child: Text(context.l10n.homeBrand,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontSize: 28, fontWeight: FontWeight.w700)),
      );
}
