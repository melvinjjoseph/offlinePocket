import '../entities/card_entry.dart';
import '../repositories/card_repository.dart';

class GetCards {
  final CardRepository _repository;
  GetCards(this._repository);

  Future<List<CardEntry>> call() => _repository.getAll();
}
