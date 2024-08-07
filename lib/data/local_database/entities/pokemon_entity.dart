import 'package:drift/drift.dart';
import 'package:pokedex/data/local_database/appDatabase.dart';
import 'package:pokedex/data/local_database/entities/pokemon_with_pokemon_type_entity.dart';
import 'package:pokedex/data/local_database/entities/pokemon_type_entity.dart';
import 'package:pokedex/data/local_database/entities/pokemon_with_stats_entity.dart';
import 'package:pokedex/data/local_database/entities/stats_entity.dart';
import 'package:pokedex/utils/constants.dart';
import 'package:pokedex/utils/get_it_initialization.dart';

@UseRowClass(PokemonEntity)
class PokemonTable extends Table {
  IntColumn get id => integer()();

  TextColumn? get name => text().nullable()();

  TextColumn? get extraInfoUrl => text().nullable()();

  IntColumn? get order => integer().nullable()();

  TextColumn? get photoUrl => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class PokemonEntity {
  int id = 0;
  String? name;
  String? extraInfoUrl;
  int? order;
  String? photoUrl;
  List<StatsEntity>? statsEntityList;
  List<PokemonTypeEntity>? pokemonTypeEntityList;

  PokemonEntity(
      {this.id = 0,
      this.name,
      this.extraInfoUrl,
      this.order,
      this.photoUrl,
      this.statsEntityList,
      this.pokemonTypeEntityList});

  PokemonEntity.fromJson(Map<String, dynamic> json) {
    if (json['id'] != null) {
      id = json['id'];
    }
    name = json['name'];
    if(json['url'] != null) {
      extraInfoUrl = json['url'];
    }
    order = json['order'];
    if (json['stats'] != null) {
      statsEntityList = StatsEntity.fromList(json['stats']);
    }
    if(extraInfoUrl != null && extraInfoUrl?.isNotEmpty == true) {
      photoUrl = _getPokemonImageUrl(extraInfoUrl ?? '');
    } else if(id != null) {
      photoUrl = '${Constants.pokemonGifBaseUrl}$id.gif';
    }
    if (json['types'] != null) {
      pokemonTypeEntityList = PokemonTypeEntity.fromList(json['types']);
    }
  }

  static List<PokemonEntity> fromList(List jsonArray) {
    return jsonArray.map((e) => PokemonEntity.fromJson(e)).toList();
  }

  static Future<void> addSinglePokemonToDatabase(
      PokemonEntity pokemonEntity) async {
    AppDatabase db = getIt.get<AppDatabase>();
    if (pokemonEntity.statsEntityList != null) {
      await PokemonWithStatsEntity.deletePokemonWithStatsBasedOnPokemonId(
          pokemonEntity.id);
      await StatsEntity.addStatEntityListToDatabase(
          pokemonEntity.statsEntityList ?? [], pokemonEntity.id);
    }
    if (pokemonEntity.pokemonTypeEntityList != null) {
      await PokemonWithPokemonTypeEntity
          .deletePokemonWithPokemonTypeBasedOnPokemonId(pokemonEntity.id);
      await PokemonTypeEntity.addListOfPokemonTypeToDatabase(
          pokemonEntity.pokemonTypeEntityList ?? [], pokemonEntity.id);
    }
    await db.into(db.pokemonTable).insertOnConflictUpdate(PokemonTableCompanion(
        id: Value(pokemonEntity.id),
        name: Value(pokemonEntity.name),
        extraInfoUrl: Value(pokemonEntity.extraInfoUrl),
        order: Value(pokemonEntity.order),
        photoUrl: Value(pokemonEntity.photoUrl)));
  }

  static Future<void> addPokemonListToDatabase(
      List<PokemonEntity> pokemonEntityList) async {
    await PokemonTypeEntity.deletePokemonType();
    await Future.forEach(pokemonEntityList, (pokemonEntity) async {
      await addSinglePokemonToDatabase(pokemonEntity);
    });
  }

  static Future<PokemonEntity?> queryPokemonEntityById(int pokemonId) async {
    AppDatabase db = getIt.get<AppDatabase>();
    List<PokemonTypeEntity> pokemonTypeEntityList = [];
    PokemonEntity? pokemonEntity = await (db.select(db.pokemonTable)
          ..where((tbl) => tbl.id.equals(pokemonId)))
        .getSingleOrNull();
    if (pokemonEntity != null) {
      List<PokemonWithPokemonTypeEntity> pokemonWithPokemonTypeEntityList =
          await PokemonWithPokemonTypeEntity
              .getListOfPokemonWithPokemonTypeBasedOnPokemonId(
                  pokemonEntity.id);
      await Future.forEach(pokemonWithPokemonTypeEntityList,
          (pokemonWithPokemonTypeEntity) async {
        PokemonTypeEntity? pokemonTypeEntity =
            await PokemonTypeEntity.getPokemonTypeEntityBasedOnId(
                pokemonWithPokemonTypeEntity.pokemonTypeId ?? -1);
        if (pokemonTypeEntity != null) {
          pokemonTypeEntityList.add(pokemonTypeEntity);
        }
      });
      pokemonEntity.pokemonTypeEntityList = pokemonTypeEntityList;
      List<PokemonWithStatsEntity> pokemonWithStatsEntityList =
          await PokemonWithStatsEntity
              .getListOfPokemonWithStatsBasedOnPokemonId(pokemonEntity.id);
      List<StatsEntity> tempStatsEntityList = [];
      await Future.forEach(pokemonWithStatsEntityList,
          (pokemonWithStatsEntity) async {
        StatsEntity? statsEntity = await StatsEntity.getStatBasedOnName(
            pokemonWithStatsEntity.statName ?? '');
        if (statsEntity != null) {
          tempStatsEntityList.add(statsEntity);
        }
      });
      pokemonEntity.statsEntityList = tempStatsEntityList;
    }

    return pokemonEntity;
  }

  static Future<List<PokemonEntity>> getListOfAllPokemon() async {
    AppDatabase db = getIt.get<AppDatabase>();
    List<PokemonEntity> pokemonEntityList =
        await db.select(db.pokemonTable).get();
    await Future.forEach(pokemonEntityList, (pokemonEntity) async {
      List<PokemonWithPokemonTypeEntity> pokemonWithPokemonTypeEntityList =
          await PokemonWithPokemonTypeEntity
              .getListOfPokemonWithPokemonTypeBasedOnPokemonId(
                  pokemonEntity.id);
      List<PokemonTypeEntity> tempPokemonTypeEntityList = [];
      await Future.forEach(pokemonWithPokemonTypeEntityList,
          (pokemonWithPokemonTypeEntity) async {
        PokemonTypeEntity? pokemonTypeEntity =
            await PokemonTypeEntity.getPokemonTypeEntityBasedOnId(
                pokemonWithPokemonTypeEntity.pokemonTypeId ?? -1);
        if (pokemonTypeEntity != null) {
          tempPokemonTypeEntityList.add(pokemonTypeEntity);
        }
      });
      pokemonEntity.pokemonTypeEntityList = tempPokemonTypeEntityList;
      List<PokemonWithStatsEntity> pokemonWithStatsEntityList =
          await PokemonWithStatsEntity
              .getListOfPokemonWithStatsBasedOnPokemonId(pokemonEntity.id);
      List<StatsEntity> tempStatsEntityList = [];
      await Future.forEach(pokemonWithStatsEntityList,
          (pokemonWithStatsEntity) async {
        StatsEntity? statsEntity = await StatsEntity.getStatBasedOnName(
            pokemonWithStatsEntity.statName ?? '');
        if (statsEntity != null) {
          tempStatsEntityList.add(statsEntity);
        }
      });
      pokemonEntity.statsEntityList = tempStatsEntityList;
    });
    return pokemonEntityList;
  }

  static String _getPokemonImageUrl(String extraInfoUrl) {
    Uri pokemonUri =  Uri.parse(extraInfoUrl ?? '');
    List<String> pathSegments = pokemonUri.pathSegments;
    String pokemonId = pathSegments[pathSegments.length - 2];
    return '${Constants.pokemonImagesBaseUrl}$pokemonId.png';
  }
}
