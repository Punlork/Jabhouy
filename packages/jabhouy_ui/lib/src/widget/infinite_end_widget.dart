import 'package:flutter/material.dart';

class EndOfListIndicator extends StatelessWidget {
  const EndOfListIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: const Center(
        child: Text(
          'No more items',
          style: TextStyle(
            fontSize: 16,
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}
