import 'package:flutter/material.dart';
import 'package:opengo/src/widgets/common/app_loader.dart';

class SplashScreen extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Image(
            //   image: AssetImage('assets/images/logo.png'),
            //   width: 200,
            //   fit: BoxFit.fitWidth,
            // ),
            // const SizedBox(height: spacing16),
            const AppLoader(),
          ],
        ),
      ),
    );
  }
}
