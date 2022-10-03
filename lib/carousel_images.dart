library carouselimages;

import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:transparent_image/transparent_image.dart';
import 'dart:math' as math;

class CarouselImages extends StatefulWidget {
  ///List with assets path or url. Required
  final List<String> listImages;

  final List<ImageProvider> listImageProviders;

  ///OnTap function. Index = index of active page. Optional
  final Function(int index)? onTap;

  ///Height of whole carousel. Required
  final double height;

  ///Possibility to cached images from network. Optional
  final bool cachedNetworkImage;

  ///Height of nearby images. From 0.0 to 1.0. Optional
  final double scaleFactor;

  ///Border radius of image. Optional
  final double? borderRadius;

  ///Vertical alignment of nearby images. Optional
  final Alignment? verticalAlignment;

  final int itemCount;

  ///ViewportFraction. From 0.5 to 1.0. Optional
  final double viewportFraction;

  const CarouselImages({
    Key? key,
    required this.listImages,
    required this.height,
    this.onTap,
    this.cachedNetworkImage: false,
    this.scaleFactor = 1.0,
    this.borderRadius,
    this.verticalAlignment,
    this.viewportFraction = 0.9,
    this.itemCount = 3,
  })  : assert(scaleFactor > 0.0),
        assert(scaleFactor <= 1.0),
        listImageProviders = const [],
        super(key: key);

  const CarouselImages.providers({
    Key? key,
    required this.listImageProviders,
    required this.height,
    this.onTap,
    this.cachedNetworkImage: false,
    this.scaleFactor = 1.0,
    this.borderRadius,
    this.verticalAlignment,
    this.viewportFraction = 0.9,
    this.itemCount = 3,
  })  : assert(scaleFactor > 0.0),
        assert(scaleFactor <= 1.0),
        listImages = const [],
        super(key: key);

  @override
  _CarouselImagesState createState() => _CarouselImagesState();
}

class _CarouselImagesState extends State<CarouselImages> {
  late PageController _pageController;
  double _currentPageValue = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: widget.viewportFraction.clamp(0.5, 1.0));
    _pageController.addListener(() {
      setState(() {
        _currentPageValue = _pageController.page!;
      });
    });
  }

  @override
  void dispose() {
    super.dispose();
    _pageController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var items = List.from(widget.listImages)..addAll(widget.listImageProviders);
    int size = min(widget.itemCount, items.length);

    final width = MediaQuery.of(context).size.width;

    var widgetList = items
        .sublist(0, size)
        .asMap()
        .map((index, value) => MapEntry(
            index,
            Padding(
              padding: EdgeInsets.all(1),
              child: circularItem(value, index),
            )))
        .values
        .toList()
        .reversed
        .toList();

    return SizedBox(
      height: widget.height,
      child: Material(
        color: Colors.transparent,
        child: AnimatedBuilder(
          animation: _pageController,
          builder: (context, child) {
            return PageView.builder(
              physics: BouncingScrollPhysics(),
              controller: _pageController,
              itemCount: widgetList.length,
              itemBuilder: (context, position) {
                double value = (1 - ((_currentPageValue - position).abs() * (1 - widget.scaleFactor))).clamp(0.0, 1.0);
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 5.0),
                  child: Stack(
                    children: <Widget>[
                      SizedBox(height: Curves.ease.transform(value) * widget.height, child: child),
                      Align(
                        alignment: widget.verticalAlignment != null ? widget.verticalAlignment! : Alignment.center,
                        child: SizedBox(
                          height: Curves.ease.transform(value) * widget.height,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(widget.borderRadius != null ? widget.borderRadius! : 16.0),
                            child: Transform.translate(
                              offset: Offset((_currentPageValue - position) * width / 4 * math.pow(widget.viewportFraction, 3), 0),
                              //offset: Offset(20, 0),
                              child: widgetList[position]
                            ),
                          ),
                        ),
                      )
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget circularItem(dynamic item, position) {
    if (item is ImageProvider) {
      return circularProviders(item, position);
      // } else if (item is Widget) {
      //   return circularWidget(item);
    } else if (item is String) {
      return circularImage(item, position);
    }
    return Container();
  }

  Widget circularImage(String imageUrl, position) {
    return (imageUrl.startsWith("http://") || imageUrl.startsWith("https://"))
        ? widget.cachedNetworkImage
            ? CachedNetworkImage(
                imageUrl: imageUrl,
                imageBuilder: (context, image) => GestureDetector(
                  onTap: () => widget.onTap != null ? widget.onTap!(position) : () {},
                  child: Image(image: image, fit: BoxFit.fitHeight),
                ),
              )
            : GestureDetector(
                onTap: () => widget.onTap != null ? widget.onTap!(position) : () {},
                child: FadeInImage.memoryNetwork(
                  placeholder: kTransparentImage,
                  image: imageUrl,
                  fit: BoxFit.fitHeight,
                ),
              )
        : GestureDetector(
            onTap: () => widget.onTap != null ? widget.onTap!(position) : () {},
            child: Image.asset(
              widget.listImages[position],
              fit: BoxFit.fitHeight,
            ),
          );
  }

  Widget circularProviders(ImageProvider imageProvider, int position) {
    return GestureDetector(
        onTap: () => widget.onTap != null ? widget.onTap!(position) : () {},
        child: Container(decoration: BoxDecoration(image: DecorationImage(image: imageProvider))));
  }

// imageProvider(imageUrl) {
//   if (this.imageSource == ImageSource.Asset) {
//     return AssetImage(imageUrl);
//   } else if (this.imageSource == ImageSource.File) {
//     return FileImage(imageUrl);
//   }
//   return CachedNetworkImage(imageUrl);
// }
}
