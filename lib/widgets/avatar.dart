import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class Avatar extends StatelessWidget {
  const Avatar({Key? key, this.radius}) : super(key: key);

  final double? radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      // backgroundColor: Colors.black12,
      radius: radius,
      child: SvgPicture.asset('lib/icons/google-gemini-icon.svg', width: radius, height: radius,),
    );
  }
}
