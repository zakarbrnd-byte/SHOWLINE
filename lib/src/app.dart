import 'package:flutter/material.dart';

import '../main.dart';
import 'routing/buyer_invite.dart';
import 'views/buyer_view.dart';
import 'views/seller_view.dart';
import 'widgets/showline_logo.dart';

class ShowlineApp extends StatelessWidget {
  const ShowlineApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Showline',
      debugShowCheckedModeBanner: false,
      theme: buildShowlineTheme(),
      home: const ShowlineShell(),
    );
  }
}

class ShowlineShell extends StatelessWidget {
  const ShowlineShell({super.key});

  @override
  Widget build(BuildContext context) {
    final buyerInvite = isBuyerInvite(Uri.base);
    if (buyerInvite) {
      return const Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ShowlineLogo(),
                ),
              ),
              Expanded(child: BuyerView()),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 12),
              child: Row(
                children: [
                  const ShowlineLogo(),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE5ECE7),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.cast_outlined, size: 16),
                        SizedBox(width: 7),
                        Text(
                          'SELLER',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                child: const SellerView(key: ValueKey('seller')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
