import '../../domain/entities/app_language.dart';
import '../../domain/repositories/locale_repository.dart';
import '../data_sources/locale_local_data_source.dart';

/// [LocaleRepository] backed by local device storage.
class LocaleRepositoryImpl implements LocaleRepository {
  LocaleRepositoryImpl(this._dataSource);

  final LocaleLocalDataSource _dataSource;

  @override
  Future<AppLanguage?> loadLanguage() async => _dataSource.read();

  @override
  Future<void> saveLanguage(AppLanguage language) =>
      _dataSource.write(language);
}
