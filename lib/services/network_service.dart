import 'dart:io';

class NetworkService {
  /// 获取第一个 Tailscale 虚拟网卡的 IP（100.x.x.x 段）
  static Future<String?> getTailscaleIp() async {
    final interfaces = await NetworkInterface.list();
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (addr.type == InternetAddressType.IPv4 && addr.address.startsWith('100.')) {
          return addr.address;
        }
      }
    }
    return null;
  }
}
