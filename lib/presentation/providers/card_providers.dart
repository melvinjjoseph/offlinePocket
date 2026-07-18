import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/crypto/crypto_service.dart';
import '../../core/keystore/keystore_service.dart';
import '../../core/services/backup_service.dart';
import '../../core/services/image_service.dart';
import '../../data/local/db/app_database.dart';
import '../../data/repositories/card_repository_impl.dart';
import '../../domain/entities/card_entry.dart';
import '../../domain/repositories/card_repository.dart';

final cryptoServiceProvider = Provider<CryptoService>((ref) => CryptoService());
final keystoreServiceProvider = Provider<KeystoreService>((ref) => KeystoreService());
final imageServiceProvider = Provider<ImageService>((ref) =>
    ImageService(ref.read(cryptoServiceProvider), ref.read(keystoreServiceProvider)));
final backupServiceProvider = Provider<BackupService>(
    (ref) => BackupService(ref.read(cryptoServiceProvider)));

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase.create());

final cardRepositoryProvider = FutureProvider<CardRepository>((ref) async {
  final db = ref.read(databaseProvider);
  return CardRepositoryImpl(
    db,
    ref.read(cryptoServiceProvider),
    ref.read(keystoreServiceProvider),
  );
});

class CardsNotifier extends AsyncNotifier<List<CardEntry>> {
  @override
  Future<List<CardEntry>> build() async {
    final repo = await ref.watch(cardRepositoryProvider.future);
    return repo.getAll();
  }

  Future<void> save(CardEntry card) async {
    final repo = await ref.read(cardRepositoryProvider.future);
    await repo.save(card);
    ref.invalidateSelf();
  }

  Future<void> updateCard(CardEntry card) async {
    final repo = await ref.read(cardRepositoryProvider.future);
    await repo.update(card);
    ref.invalidateSelf();
  }

  Future<void> delete(String id) async {
    final repo = await ref.read(cardRepositoryProvider.future);
    await repo.delete(id);
    ref.invalidateSelf();
  }
}

final cardsNotifierProvider =
    AsyncNotifierProvider<CardsNotifier, List<CardEntry>>(CardsNotifier.new);
