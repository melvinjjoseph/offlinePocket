import '../repositories/card_repository.dart';

class DeleteCard {
  final CardRepository _repository;
  DeleteCard(this._repository);

  Future<void> call(String id) => _repository.delete(id);
}
