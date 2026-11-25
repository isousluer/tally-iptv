import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:tally/data/database.dart';
import 'package:tally/data/models.dart';

MediaItem channel(int playlistId, String key, String name, {String group = 'News'}) =>
    MediaItem(playlistId: playlistId, kind: ContentKind.live, key: key, name: name, group: group, url: 'http://x/$key');

void main() {
  late AppDatabase db;
  late int pid;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    db = await AppDatabase.open(path: inMemoryDatabasePath, factory: databaseFactoryFfi);
    pid = await db.insertPlaylist(const Playlist(id: 0, name: 'Test', type: SourceType.m3uUrl, url: 'http://x'));
    await db.replaceItems(pid, [channel(pid, 'a', 'A'), channel(pid, 'b', 'B'), channel(pid, 'c', 'C')]);
  });

  tearDown(() => db.db.close());

  test('keeps channels in the order they were added and reordered', () async {
    final sports = await db.createChannelList(pid, 'Sports');
    await db.setInChannelList(sports, 'c', true);
    await db.setInChannelList(sports, 'a', true);
    await db.setInChannelList(sports, 'a', true); // twice is harmless
    expect([for (final c in await db.channelListItems(pid, sports)) c.key], ['c', 'a']);

    await db.reorderChannelListItems(sports, ['a', 'c']);
    expect([for (final c in await db.channelListItems(pid, sports)) c.key], ['a', 'c']);

    await db.setInChannelList(sports, 'a', false);
    expect([for (final c in await db.channelListItems(pid, sports)) c.key], ['c']);
    expect(await db.listsWith(pid, 'c'), {sports});
  });

  test('lists survive a playlist update and count only channels still there', () async {
    final news = await db.createChannelList(pid, 'News');
    await db.setInChannelList(news, 'a', true);
    await db.setInChannelList(news, 'b', true);
    await db.replaceItems(pid, [channel(pid, 'a', 'A'), channel(pid, 'c', 'C')]);
    final lists = await db.channelLists(pid);
    expect(lists.single.count, 1);
    expect([for (final c in await db.channelListItems(pid, news)) c.key], ['a']);
  });

  test('lists keep their order and go with their playlist', () async {
    final one = await db.createChannelList(pid, 'One');
    final two = await db.createChannelList(pid, 'Two');
    expect([for (final l in await db.channelLists(pid)) l.id], [one, two]);
    await db.reorderChannelLists([two, one]);
    expect([for (final l in await db.channelLists(pid)) l.name], ['Two', 'One']);
    await db.deletePlaylist(pid);
    expect(await db.db.query('channel_lists'), isEmpty);
  });
}
