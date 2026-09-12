import 'dart:io';
import 'package:flutter/material.dart';
import 'package:foam_mobile/core/Screens/profile/profile_image/model/image_helper.dart';
import 'package:foam_mobile/core/Screens/profile/profile_image/controller/profile_pic_auth.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:google_fonts/google_fonts.dart';
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
    super.initState();
    var profileAuth = Provider.of<ProfilePicAuth>(context, listen: false);
    setState(() {
      _image = profileAuth.image;
    });
  }

  @override
  Widget build(BuildContext context) {
    final double avatarSize = widget.radius * 2;
    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          InkWell(
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
                    _image = File(croppedFile.path);
                    profileAuth.updateFile(
                      File(croppedFile.path),
                      croppedFile.path,
                    );
                  });
                }
              }
            },
            borderRadius: BorderRadius.circular(avatarSize),
            child: Container(
              width: avatarSize,
              height: avatarSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryAccentColor,
                    AppColors.oceanBlueColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryAccentColor.withValues(alpha: 0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(3.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(avatarSize),
                child: Container(
                  color: Colors.white,
                  child: _image != null
                      ? Image.file(
                          _image!,
                          fit: BoxFit.cover,
                          width: avatarSize,
                          height: avatarSize,
                        )
                      : Container(
                          color: AppColors.fadeBlueAccentColor,
                          alignment: Alignment.center,
                          child: Text(
                            widget.initials.trim().isEmpty ? 'U' : widget.initials.trim(),
                            style: GoogleFonts.dmSans(
                              fontSize: widget.radius * 0.75,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primaryAccentColor,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primaryAccentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

