import 'package:flutter/material.dart';
import 'package:foam_mobile/utils/values.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class DiscountSlider extends StatefulWidget {
  const DiscountSlider({
    super.key,
    required this.onPressed,
    required this.isLoading,
    required this.imageAsset,
  });

  final Function()? onPressed;
  final bool isLoading;
  final String imageAsset;

  @override
  State<DiscountSlider> createState() => _DiscountSliderState();
}

class _DiscountSliderState extends State<DiscountSlider> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(MediaQuery.sizeOf(context).height / 90),
      padding: EdgeInsets.all(MediaQuery.sizeOf(context).height / 90),
      child: Stack(
        children: [
          //image content
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  widget.imageAsset,
                ),
                fit: BoxFit.fill,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          //color gradient
          Container(
            decoration: BoxDecoration(
              color: AppColors.primaryAccentColor.withOpacity(0.24),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          Container(
            margin: EdgeInsets.all(MediaQuery.sizeOf(context).height / 150),
            padding: EdgeInsets.all(MediaQuery.sizeOf(context).height / 76),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppSpaces.verticalSpace10,
                Expanded(
                  flex: 1,
                  child: Text(
                    'Discount Deals',
                    style: Constants.subHeadingStyle.copyWith(
                      color: Colors.white,
                      fontSize: MediaQuery.sizeOf(context).height / 45,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'up to',
                                  style: Constants.textStyle.copyWith(
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.sizeOf(context).height / 50,
                                  ),
                                ),
                                Text(
                                  ' 40% off',
                                  style: Constants.headingStyle.copyWith(
                                    color: Colors.white,
                                    fontSize:
                                        MediaQuery.sizeOf(context).height / 40,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'all laundry services available!',
                              overflow: TextOverflow.ellipsis,
                              style: Constants.textStyle.copyWith(
                                color: Colors.white,
                                fontSize:
                                    MediaQuery.sizeOf(context).height / 50,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: InkWell(
                          onTap: widget.onPressed,
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: const BorderRadius.all(
                                Radius.circular(
                                  12.0,
                                ),
                              ),
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  ...AppColors.gradientColor,
                                ],
                              ),
                            ),
                            child: Stack(
                              children: [
                                Text(
                                  'Claim',
                                  overflow: TextOverflow.ellipsis,
                                  style: Constants.subHeadingStyle.copyWith(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (widget.isLoading)
                                  Positioned(
                                    right: 10,
                                    top: 56 / 4,
                                    child:
                                        LoadingAnimationWidget.fourRotatingDots(
                                      color: Colors.white,
                                      // rightDotColor: Constant.generalColor,
                                      size: 20,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
