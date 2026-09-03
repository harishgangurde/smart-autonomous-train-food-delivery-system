class CartItem {
  final String foodId;
  final String name;
  int quantity;
  final double price;

  CartItem({
    required this.foodId,
    required this.name,
    required this.quantity,
    required this.price,
  });

  double get lineTotal => price * quantity;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        foodId: json['foodId'],
        name: json['name'],
        quantity: json['quantity'],
        price: (json['price'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {
        'foodId': foodId,
        'name': name,
        'quantity': quantity,
        'price': price,
      };
}

/// Mirrors backend OrderStatus exactly — keep the two in lockstep.
const List<String> kOrderStatusFlow = [
  'PLACED', 'CONFIRMED', 'PREPARING', 'READY',
  'LOADED', 'DISPATCHED', 'ARRIVED', 'OTP_VERIFIED', 'DELIVERED',
];

class Order {
  final String orderId;
  final String authId;
  final String passengerId;
  final String passengerName;
  final String coachNo;
  final String seatNo;
  final List<CartItem> items;
  final double totalAmount;
  final String paymentMethod;
  final String paymentStatus;
  final String orderStatus;
  final int preparationMinutes;
  final int estimatedDeliveryMinutes;
  final String? robotId;
  final String? otp;
  final bool otpVerified;
  final double createdAt;

  Order({
    required this.orderId,
    required this.authId,
    required this.passengerId,
    required this.passengerName,
    required this.coachNo,
    required this.seatNo,
    required this.items,
    required this.totalAmount,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.orderStatus,
    required this.preparationMinutes,
    required this.estimatedDeliveryMinutes,
    this.robotId,
    this.otp,
    this.otpVerified = false,
    required this.createdAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        orderId: json['orderId'],
        authId: json['authId'],
        passengerId: json['passengerId'],
        passengerName: json['passengerName'],
        coachNo: json['coachNo'],
        seatNo: json['seatNo'],
        items: (json['items'] as List).map((e) => CartItem.fromJson(e)).toList(),
        totalAmount: (json['totalAmount'] as num).toDouble(),
        paymentMethod: json['paymentMethod'],
        paymentStatus: json['paymentStatus'],
        orderStatus: json['orderStatus'],
        preparationMinutes: json['preparationMinutes'] ?? 0,
        estimatedDeliveryMinutes: json['estimatedDeliveryMinutes'] ?? 0,
        robotId: json['robotId'],
        otp: json['otp'],
        otpVerified: json['otpVerified'] ?? false,
        createdAt: (json['createdAt'] as num).toDouble(),
      );

  int get statusIndex => kOrderStatusFlow.indexOf(orderStatus);
}
