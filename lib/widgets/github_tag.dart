import 'package:flutter/material.dart';

const TAG_PRIORITIES = [
  'highest priority',
  'high priority',
  'low priority'
];

const List<String> VALID_TAGS = [
  'highest priority',
  'high priority',
  'low priority',
  'blocked'
];

class GithubTag extends StatelessWidget {
  const GithubTag(this.text, this.color, {Key? key}) : super(key: key);

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(.5),
          border: Border.all(color: color, width: 1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text, style: const TextStyle(fontSize: 12),)
    );
  }
}