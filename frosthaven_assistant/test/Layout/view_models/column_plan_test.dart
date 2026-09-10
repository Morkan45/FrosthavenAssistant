import 'package:flutter_test/flutter_test.dart';
import 'package:frosthaven_assistant/Layout/view_models/main_list_view_model.dart';
import 'package:frosthaven_assistant/Resource/state/game_state.dart';

void main() {
  NoteRow linked(String id) => NoteRow.create(id, linkedId: 'target');

  test('moves a fixed column boundary past linked notes', () {
    final items = <ListItemData>[
      NoteRow.create('target'),
      linked('note-1'),
      linked('note-2'),
      NoteRow.create('other'),
      NoteRow.create('third'),
    ];

    final plan = ColumnPlan.forItems(items, columnCount: 2);

    expect(plan.itemsPerColumn, 3);
  });

  test('keeps every repeated boundary outside linked-note runs', () {
    final items = <ListItemData>[
      NoteRow.create('a'),
      linked('a-note'),
      NoteRow.create('b'),
      linked('b-note'),
      NoteRow.create('c'),
      linked('c-note'),
      NoteRow.create('d'),
    ];

    final plan = ColumnPlan.forItems(
      items,
      columnCount: 3,
      preferredItemsPerColumn: 2,
    );

    expect(plan.itemsPerColumn, 2);
  });
}
