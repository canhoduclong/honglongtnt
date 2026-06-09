class CustomerModel {
  const CustomerModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.address,
  });

  final int id;
  final String name;
  final String phone;
  final String address;

  factory CustomerModel.fromJson(Map<String, dynamic>? json) {
    final data = json ?? const <String, dynamic>{};
    return CustomerModel(
      id: int.tryParse('${data['id'] ?? 0}') ?? 0,
      name: (data['name'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
    );
  }
}
