import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'dart:typed_data';

class ImageConversionService {
  // 将 CameraImage (YUV420) 转为 JPEG Uint8List
  Future<Uint8List?> convertCameraImageToJpeg(CameraImage cameraImage, {int quality = 75}) async {
    try {
      img.Image? image;
      if (cameraImage.format.group == ImageFormatGroup.yuv420) {
        image = _convertYUV420toRGBImage(cameraImage);
        if (image == null) return null;
      } else if (cameraImage.format.group == ImageFormatGroup.bgra8888) {
        image = img.Image.fromBytes(
          width: cameraImage.width,
          height: cameraImage.height,
          bytes: cameraImage.planes[0].bytes.buffer,
          order: img.ChannelOrder.bgra,
        );
      } else {
        print('不支持的 CameraImage 格式: [33m[1m${cameraImage.format.group}[0m');
        return null;
      }
      return Uint8List.fromList(img.encodeJpg(image, quality: quality));
    } catch (e) {
      print('CameraImage 转 JPEG 失败: $e');
      return null;
    }
  }

  // 简化版 YUV420 转 RGB，生产环境建议用原生实现
  img.Image? _convertYUV420toRGBImage(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final img.Image rgbImage = img.Image(width: width, height: height);
    final yPlane = image.planes[0].bytes;
    final uPlane = image.planes[1].bytes;
    final vPlane = image.planes[2].bytes;
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final int uvIndex = (y >> 1) * (width >> 1) + (x >> 1);
        final int yp = y * width + x;
        final int yValue = yPlane[yp];
        final int uValue = uPlane[uvIndex];
        final int vValue = vPlane[uvIndex];
        int r = (yValue + 1.370705 * (vValue - 128)).round().clamp(0, 255);
        int g = (yValue - 0.337633 * (uValue - 128) - 0.698001 * (vValue - 128)).round().clamp(0, 255);
        int b = (yValue + 1.732446 * (uValue - 128)).round().clamp(0, 255);
        rgbImage.setPixelRgb(x, y, r, g, b);
      }
    }
    return rgbImage;
  }
} 