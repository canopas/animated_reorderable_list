import 'package:flutter/cupertino.dart';

import 'animation_effect.dart';

class AnimationItemBuilder extends StatefulWidget {
   List<AnimationEffect> effects=[];
   AnimationItemBuilder({super.key,required this.effects});

  @override
  State<AnimationItemBuilder> createState() => _AnimationItemBuilderState();
}

class _AnimationItemBuilderState extends State<AnimationItemBuilder> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
