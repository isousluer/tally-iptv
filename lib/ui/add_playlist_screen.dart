import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/models.dart';
import '../data/repository.dart';
import '../l10n/strings.dart';
import '../state/providers.dart';
import 'loading_view.dart';
import 'theme.dart';

class AddPlaylistScreen extends ConsumerStatefulWidget {
  const AddPlaylistScreen({super.key, this.firstRun = false});

  /// Shown as the welcome screen when no playlist exists yet.
  final bool firstRun;

  @override
  ConsumerState<AddPlaylistScreen> createState() => _AddPlaylistScreenState();
}

class _AddPlaylistScreenState extends ConsumerState<AddPlaylistScreen> {
  final _form = GlobalKey<FormState>();
  SourceType _type = SourceType.m3uUrl;
  final _name = TextEditingController();
  final _url = TextEditingController();
  final _server = TextEditingController();
  final _user = TextEditingController();
  final _pass = TextEditingController();
  final _epg = TextEditingController();
  String? _filePath;
  String? _fileName;
  bool _showPassword = false;
  bool _showAdvanced = false;
  bool _busy = false;
  String? _error;
  LoadProgress? _progress;

  @override
  void dispose() {
    for (final c in [_name, _url, _server, _user, _pass, _epg]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFile() async {
    final file = await FilePicker.pickFile(
      dialogTitle: context.l10n.chooseM3uPlaylist,
      type: FileType.custom,
      allowedExtensions: const ['m3u', 'm3u8', 'txt'],
    );
    if (file == null) return;
    // Copy into app storage: content:// URIs on Android are not durable.
    final dir = Directory(p.join((await getApplicationSupportDirectory()).path, 'playlists'));
    await dir.create(recursive: true);
    final target = File(p.join(dir.path, '${DateTime.now().millisecondsSinceEpoch}.m3u'));
    await target.writeAsBytes(await file.readAsBytes());
    setState(() {
      _filePath = target.path;
      _fileName = file.name;
      _error = null;
      if (_name.text.isEmpty) _name.text = p.basenameWithoutExtension(file.name);
    });
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_type == SourceType.m3uFile && _filePath == null) {
      setState(() => _error = context.l10n.chooseFileFirst);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _progress = null;
    });
    final name = _name.text.trim().isEmpty ? _defaultName() : _name.text.trim();
    final epg = _epg.text.trim().isEmpty ? null : _epg.text.trim();
    final draft = Playlist(
      id: 0,
      name: name,
      type: _type,
      url: switch (_type) {
        SourceType.m3uUrl => _url.text.trim(),
        SourceType.m3uFile => _filePath,
        SourceType.xtream => null,
      },
      server: _type == SourceType.xtream ? _server.text.trim() : null,
      username: _type == SourceType.xtream ? _user.text.trim() : null,
      password: _type == SourceType.xtream ? _pass.text : null,
      epgUrl: epg,
    );
    try {
      await ref
          .read(playlistsProvider.notifier)
          .add(
            draft,
            onProgress: (p) {
              if (mounted) setState(() => _progress = p);
            },
          );
      if (!mounted) return;
      if (!widget.firstRun) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _defaultName() => switch (_type) {
    SourceType.xtream => Uri.tryParse(_server.text.trim())?.host ?? 'Xtream',
    SourceType.m3uUrl => Uri.tryParse(_url.text.trim())?.host ?? context.l10n.defaultPlaylistName,
    SourceType.m3uFile => _fileName ?? context.l10n.defaultPlaylistName,
  };

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? context.l10n.required : null;

  String? _validUrl(String? v) {
    if (_required(v) != null) return context.l10n.required;
    final s = v!.trim();
    final uri = Uri.tryParse(s.contains('://') ? s : 'http://$s');
    return (uri == null || uri.host.isEmpty) ? context.l10n.enterValidAddress : null;
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final l = context.l10n;
    if (_busy) return LoadingPlaylistView(name: _name.text.trim(), progress: _progress);
    return Scaffold(
      appBar: widget.firstRun ? null : AppBar(title: Text(l.addPlaylist)),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                children: [
                  if (widget.firstRun) ...[
                    Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(color: AppColors.tally, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text('Tally', style: t.titleMedium!.copyWith(fontWeight: FontWeight.w700)),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Text(l.addYourPlaylist, style: t.headlineLarge),
                    const SizedBox(height: 8),
                  ],
                  Text(l.playlistStaysHere, style: t.bodyMedium!.copyWith(color: AppColors.muted)),
                  const SizedBox(height: 22),
                  SegmentedButton<SourceType>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(value: SourceType.m3uUrl, label: Text(l.m3uLink)),
                      ButtonSegment(value: SourceType.m3uFile, label: Text(l.m3uFile)),
                      const ButtonSegment(value: SourceType.xtream, label: Text('Xtream Codes')),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) => setState(() {
                      _type = s.first;
                      _error = null;
                    }),
                  ),
                  const SizedBox(height: 22),
                  _Field(
                    label: l.playlistName,
                    child: TextFormField(
                      controller: _name,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(hintText: l.playlistNameHint),
                    ),
                  ),
                  ..._sourceFields(t),
                  const SizedBox(height: 4),
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => setState(() => _showAdvanced = !_showAdvanced),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          const Icon(Icons.tune, size: 20, color: AppColors.muted),
                          const SizedBox(width: 10),
                          Expanded(child: Text(l.advanced, style: t.titleSmall)),
                          Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more, color: AppColors.muted),
                        ],
                      ),
                    ),
                  ),
                  if (_showAdvanced)
                    _Field(
                      label: l.guideLinkField,
                      help: _type == SourceType.xtream ? l.guideHelpXtream : l.guideHelpM3u,
                      child: TextFormField(
                        controller: _epg,
                        keyboardType: TextInputType.url,
                        decoration: const InputDecoration(hintText: 'https://example.com/guide.xml.gz'),
                      ),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.live.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.live.withValues(alpha: 0.5)),
                      ),
                      child: Text(_error!, style: t.bodyMedium),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2.4, color: AppColors.onTally),
                          )
                        : Text(l.addPlaylist),
                  ),
                  if (_busy) ...[
                    const SizedBox(height: 10),
                    Text(
                      l.loadingChannelsHint,
                      textAlign: TextAlign.center,
                      style: t.bodySmall!.copyWith(color: AppColors.muted),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _sourceFields(TextTheme t) {
    final l = context.l10n;
    switch (_type) {
      case SourceType.m3uUrl:
        return [
          _Field(
            label: l.playlistLink,
            child: TextFormField(
              controller: _url,
              keyboardType: TextInputType.url,
              validator: _validUrl,
              decoration: const InputDecoration(hintText: 'https://example.com/playlist.m3u'),
            ),
          ),
        ];
      case SourceType.m3uFile:
        return [
          _Field(
            label: l.playlistFile,
            child: OutlinedButton.icon(
              onPressed: _pickFile,
              style: OutlinedButton.styleFrom(alignment: Alignment.centerLeft),
              icon: const Icon(Icons.folder_open_outlined),
              label: Text(_fileName ?? l.chooseM3uFile, overflow: TextOverflow.ellipsis),
            ),
          ),
        ];
      case SourceType.xtream:
        return [
          _Field(
            label: l.serverUrl,
            child: TextFormField(
              controller: _server,
              keyboardType: TextInputType.url,
              validator: _validUrl,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(hintText: 'http://example.com:8080'),
            ),
          ),
          _Field(
            label: l.username,
            child: TextFormField(
              controller: _user,
              validator: _required,
              autocorrect: false,
              textInputAction: TextInputAction.next,
            ),
          ),
          _Field(
            label: l.password,
            child: TextFormField(
              controller: _pass,
              validator: _required,
              obscureText: !_showPassword,
              autocorrect: false,
              enableSuggestions: false,
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                suffixIcon: IconButton(
                  tooltip: _showPassword ? l.hidePassword : l.showPassword,
                  onPressed: () => setState(() => _showPassword = !_showPassword),
                  icon: Icon(_showPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                ),
              ),
            ),
          ),
        ];
    }
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child, this.help});
  final String label;
  final String? help;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: t.labelLarge),
          const SizedBox(height: 6),
          child,
          if (help != null) ...[
            const SizedBox(height: 6),
            Text(help!, style: t.bodySmall!.copyWith(color: AppColors.muted)),
          ],
        ],
      ),
    );
  }
}
