// carrinho_model.dart
class CarrinhoModel {
  final int? id;
  final int userId;
  final String name;
  final int quantity;
  final double price;
  final String? imageUrl; // NOVO CAMPO

  CarrinhoModel({
    this.id,
    required this.userId,
    required this.name,
    required this.quantity,
    required this.price,
    this.imageUrl,
  });

  factory CarrinhoModel.fromMap(Map<String, dynamic> map) {
    return CarrinhoModel(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      price: (map['price'] as num).toDouble(),
      imageUrl: map['image_url'] as String?, // LÊ DO BANCO
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'image_url': imageUrl,
    };
  }
}