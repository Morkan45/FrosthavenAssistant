import 'package:built_collection/built_collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:frosthaven_assistant/Model/campaign.dart';
import 'package:frosthaven_assistant/Resource/commands/reorder_list_command.dart';
import 'package:frosthaven_assistant/Resource/game_data.dart';
import 'package:frosthaven_assistant/Resource/scaling.dart';
import 'package:frosthaven_assistant/Resource/settings.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';
import 'package:frosthaven_assistant/services/service_locator.dart';

import '../MonsterBox/monster_box.dart';
import 'main_list_item_view_model.dart';

/// A fixed-capacity column plan whose boundaries never split a target row from
/// its immediately following linked notes. `ReorderableWrap` accepts one
/// capacity for every column, so this intentionally picks the smallest safe
/// capacity rather than pretending it supports independent breakpoints.
class ColumnPlan {
  const ColumnPlan._(this.itemsPerColumn);

  final int itemsPerColumn;

  factory ColumnPlan.forItems(
    List<ListItemData> items, {
    required int columnCount,
    int? preferredItemsPerColumn,
  }) {
    if (items.isEmpty) return const ColumnPlan._(1);
    var capacity =
        preferredItemsPerColumn ??
        (items.length / columnCount.clamp(1, items.length)).ceil();
    capacity = capacity.clamp(1, items.length).toInt();
    final groups = _groups(items);
    while (_splitsGroup(groups, capacity) && capacity < items.length) {
      capacity++;
    }
    return ColumnPlan._(capacity);
  }

  static List<_ColumnGroup> _groups(List<ListItemData> items) {
    final groups = <_ColumnGroup>[];
    for (var index = 0; index < items.length; index++) {
      final item = items[index];
      if (item is NoteRow && item.isLinked && groups.isNotEmpty) {
        groups.last = groups.last.extendTo(index + 1);
      } else {
        groups.add(_ColumnGroup(index, index + 1));
      }
    }
    return groups;
  }

  static bool _splitsGroup(List<_ColumnGroup> groups, int capacity) {
    for (
      var boundary = capacity;
      boundary < groups.last.end;
      boundary += capacity
    ) {
      if (groups.any((group) => group.contains(boundary))) {
        return true;
      }
    }
    return false;
  }
}

class _ColumnGroup {
  const _ColumnGroup(this.start, this.end);

  final int start;
  final int end;

  _ColumnGroup extendTo(int newEnd) => _ColumnGroup(start, newEnd);

  bool contains(int index) => start < index && index < end;
}

class MainListViewModel {
  static const double _kCharacterHeight = 60.0;
  static const double _kMonsterHeaderHeight = 96.0;
  static const double _kRowHeight = 32.0;
  static const double _kNoteRowHeight = 40.0;
  static const double _kTopBarHeight = 80.0;
  static const double _kAutoColumnOverflowAllowance = 120.0;
  static const int _kMaxAutoColumns = 3;
  MainListViewModel({
    GameState? gameState,
    GameData? gameData,
    Settings? settings,
  }) : _gameState = gameState ?? getIt<GameState>(),
       _gameData = gameData ?? getIt<GameData>(),
       _settings = settings ?? getIt<Settings>();

  final GameState _gameState;
  final GameData _gameData;
  final Settings _settings;

  // Notifiers the widget subscribes to
  ValueListenable<bool> get darkMode => _settings.darkMode;
  ValueListenable<Map<String, CampaignModel>> get modelData =>
      _gameData.modelData;
  ValueListenable<double> get userScalingMainList =>
      _settings.userScalingMainList;
  ValueListenable<double> get userScalingBarsNotifier =>
      _settings.userScalingBars;
  ValueListenable<bool> get fitMainListToWidth => _settings.fitMainListToWidth;
  ValueListenable<int> get mainListColumns => _settings.mainListColumns;
  Listenable get updateList => _gameState.updateList;
  ValueListenable<BuiltList<ListItemData>> get currentListNotifier =>
      _gameState.currentListNotifier;

  // Derived state
  int get currentListLength => _gameState.currentList.length;
  ListItemData itemAt(int index) => _gameState.currentList[index];
  String itemIdAt(int index) => _gameState.currentList[index].id;

  double get userScalingBars => _settings.userScalingBars.value;

  List<double> getItemHeights(BuildContext context) {
    double listHeight = 0;
    double scale = getScaleByReference(context);
    double mainListWidth = getMainListWidth(context);

    List<double> widgetPositions = [];
    for (int i = 0; i < _gameState.currentList.length; i++) {
      final item = _gameState.currentList[i];
      if (item is Character) {
        listHeight += _kCharacterHeight;
        final summonList = item.characterState.summonList;
        if (summonList.isNotEmpty) {
          double listWidth = 0;
          for (final monsterInstance in summonList) {
            listWidth += MonsterBox.getWidth(scale, monsterInstance);
          }
          double rows = listWidth / mainListWidth;
          listHeight += _kRowHeight * (rows.ceil());
        }
      }
      if (item is Monster) {
        listHeight += _kMonsterHeaderHeight;
        if (item.monsterInstances.isNotEmpty) {
          double listWidth = 0;
          for (final monsterInstance in item.monsterInstances) {
            listWidth += MonsterBox.getWidth(scale, monsterInstance);
          }
          double rows = listWidth / mainListWidth;
          listHeight += _kRowHeight * rows.ceil();
        }
      }
      if (item is NoteRow) {
        listHeight += _kNoteRowHeight;
      }
      widgetPositions.add(listHeight * scale);
    }
    return widgetPositions;
  }

  MainListLayout getLayoutForViewport(double width, double height) {
    if (!_settings.fitMainListToWidth.value ||
        _settings.mainListColumns.value != 0) {
      return calculateMainListLayout(width, settings: _settings);
    }

    final usableHeight =
        height - _kTopBarHeight * _settings.userScalingBars.value;
    for (var columns = 1; columns <= _kMaxAutoColumns; columns++) {
      final layout = calculateMainListLayout(
        width,
        settings: _settings,
        automaticColumnCount: columns,
      );
      if (_itemsFitInColumns(
        layout,
        usableHeight + _kAutoColumnOverflowAllowance,
      )) {
        return layout;
      }
    }

    return calculateMainListLayout(
      width,
      settings: _settings,
      automaticColumnCount: _kMaxAutoColumns,
    );
  }

  bool _itemsFitInColumns(MainListLayout layout, double usableHeight) {
    if (_gameState.currentList.isEmpty) return true;

    final plan = ColumnPlan.forItems(
      _gameState.currentList.toList(),
      columnCount: layout.columnCount,
    );
    final itemsPerColumn = plan.itemsPerColumn;
    for (
      var start = 0;
      start < _gameState.currentList.length;
      start += itemsPerColumn
    ) {
      var columnHeight = 0.0;
      final end = (start + itemsPerColumn < _gameState.currentList.length)
          ? start + itemsPerColumn
          : _gameState.currentList.length;
      for (var index = start; index < end; index++) {
        columnHeight += MainListItemViewModel(
          data: _gameState.currentList[index],
          scale: layout.scale,
          listWidth: layout.columnWidth,
        ).height;
      }
      if (columnHeight > usableHeight) return false;
    }
    return true;
  }

  void reorderItem(int oldIndex, int newIndex) {
    _gameState.action(
      ReorderListCommand(newIndex, oldIndex, gameState: _gameState),
    );
  }
}
