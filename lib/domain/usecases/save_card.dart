import '../entities/card_entry.dart';
import '../repositories/card_repository.dart';

class SaveCard {
  final CardRepository _repository;
  SaveCard(this._repository);

  Future<void> call(CardEntry card) => _repository.save(card);
}
