import 'dart:io';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/profile/profile_image/model/image_helper.dart';
import 'package:foam_mobile/core/Screens/profile/profile_image/controller/profile_pic_auth.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:provider/provider.dart';

class ProfileImage extends StatefulWidget {
  const ProfileImage({
    super.key,
    required this.initials,
    required this.radius,
  });

  final String initials;
  final double radius;

  @override
  State<ProfileImage> createState() => _ProfileImageState();
}

class _ProfileImageState extends State<ProfileImage> {
  File? _image;
  final imageHelper = ImageHelper();

  @override
  void initState() {
    var profileAuth = Provider.of<ProfilePicAuth>(context, listen: false);
    setState(() {
      _image = profileAuth.image;
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        var profileAuth = Provider.of<ProfilePicAuth>(context, listen: false);
        final files = await imageHelper.pickImage();
        if (files.isNotEmpty) {
          final croppedFile = await imageHelper.crop(
            file: files.first,
            cropStyle: CropStyle.circle,
          );
          if (croppedFile != null) {
            setState(() {
              _image = File(
                croppedFile.path,
              );
              profileAuth.updateFile(
                File(
                  croppedFile.path,
                ),
                croppedFile.path,
              );
            });
          }
        }
      },
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: CircleAvatar(
            radius: widget.radius,
            foregroundImage: _image != null ? FileImage(_image!) : null,
            child: Text(
              widget.initials,
              style: Constants.headingStyle,
            ),
          ),
        ),
      ),
    );
  }
}
