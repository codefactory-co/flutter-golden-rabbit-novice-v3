import 'package:flutter/material.dart';

class PointNotification extends StatelessWidget {
  final int point;

  const PointNotification({
    super.key,
    required this.point,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '$point 포인트가 적립되었습니다!',
      style: TextStyle(
        color: Colors.blueAccent,
        fontStyle: FontStyle.italic,
      ),
    );
  }
}
