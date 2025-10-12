/// Subscription model
class Subscription {
  /// Subscription ID
  final String id;

  /// Subscription name
  final String name;

  /// Subscription URL
  final String url;

  /// Last update time (Unix timestamp)
  final int? lastUpdate;

  /// Server count
  final int serverCount;

  /// Subscription status
  final String status;

  const Subscription({
    required this.id,
    required this.name,
    required this.url,
    this.lastUpdate,
    required this.serverCount,
    required this.status,
  });

  /// Create from JSON
  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      lastUpdate: json['last_update'] as int?,
      serverCount: json['server_count'] as int,
      status: json['status'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'last_update': lastUpdate,
      'server_count': serverCount,
      'status': status,
    };
  }

  /// Copy with
  Subscription copyWith({
    String? id,
    String? name,
    String? url,
    int? lastUpdate,
    int? serverCount,
    String? status,
  }) {
    return Subscription(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      serverCount: serverCount ?? this.serverCount,
      status: status ?? this.status,
    );
  }

  /// Get status display text
  String get statusText {
    if (status.startsWith('error:')) {
      return 'Error';
    }
    switch (status) {
      case 'active':
        return 'Active';
      case 'inactive':
        return 'Inactive';
      case 'updating':
        return 'Updating';
      default:
        return status;
    }
  }

  /// Check if subscription is active
  bool get isActive => status == 'active';

  /// Check if subscription is updating
  bool get isUpdating => status == 'updating';

  /// Check if subscription has error
  bool get hasError => status.startsWith('error:');

  /// Get error message
  String? get errorMessage {
    if (hasError) {
      return status.substring(6); // Remove 'error:' prefix
    }
    return null;
  }

  @override
  String toString() {
    return 'Subscription(id: $id, name: $name, serverCount: $serverCount, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Subscription &&
        other.id == id &&
        other.name == name &&
        other.url == url &&
        other.lastUpdate == lastUpdate &&
        other.serverCount == serverCount &&
        other.status == status;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      name,
      url,
      lastUpdate,
      serverCount,
      status,
    );
  }
}

/// Server model
class Server {
  /// Server ID
  final String id;

  /// Subscription ID
  final String subscriptionId;

  /// Server name
  final String name;

  /// Server address
  final String address;

  /// Port
  final int port;

  /// Protocol
  final String protocol;

  const Server({
    required this.id,
    required this.subscriptionId,
    required this.name,
    required this.address,
    required this.port,
    required this.protocol,
  });

  /// Create from JSON
  factory Server.fromJson(Map<String, dynamic> json) {
    return Server(
      id: json['id'] as String,
      subscriptionId: json['subscription_id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      port: json['port'] as int,
      protocol: json['protocol'] as String,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subscription_id': subscriptionId,
      'name': name,
      'address': address,
      'port': port,
      'protocol': protocol,
    };
  }

  /// Copy with
  Server copyWith({
    String? id,
    String? subscriptionId,
    String? name,
    String? address,
    int? port,
    String? protocol,
  }) {
    return Server(
      id: id ?? this.id,
      subscriptionId: subscriptionId ?? this.subscriptionId,
      name: name ?? this.name,
      address: address ?? this.address,
      port: port ?? this.port,
      protocol: protocol ?? this.protocol,
    );
  }

  /// Get server display name
  String get displayName => name.isNotEmpty ? name : '$address:$port';

  /// Get protocol display name
  String get protocolDisplayName {
    switch (protocol.toLowerCase()) {
      case 'vmess':
        return 'VMess';
      case 'vless':
        return 'VLESS';
      case 'trojan':
        return 'Trojan';
      case 'shadowsocks':
      case 'ss':
        return 'Shadowsocks';
      default:
        return protocol.toUpperCase();
    }
  }

  @override
  String toString() {
    return 'Server(id: $id, name: $name, address: $address:$port, protocol: $protocol)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Server &&
        other.id == id &&
        other.subscriptionId == subscriptionId &&
        other.name == name &&
        other.address == address &&
        other.port == port &&
        other.protocol == protocol;
  }

  @override
  int get hashCode {
    return Object.hash(
      id,
      subscriptionId,
      name,
      address,
      port,
      protocol,
    );
  }
}
