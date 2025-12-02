import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GUI Wrapper for yt-dlp',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF8A7BEA),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _log = '';
  bool _isDownloading = false;
  double? _progress;
  String? _outputDir;
  String _selectedPreset = 'mp3'; // mp3, aac, mp4, mkv, sleep

  bool _checkedForUpdates = false; // ensure we run -U only once per app run

  void _showAbout() {
  showAboutDialog(
    context: context,
    applicationName: 'YT Downloader GUI',
    applicationVersion: '1.0.0',
    applicationLegalese:
        'MIT-licensed GUI wrapper.\n'
        'Bundles yt-dlp, which is licensed separately.\n'
        'See LICENSE and assets/yt-dlp/LICENSE.yt-dlp.txt.',
    children: const [
      SizedBox(height: 8),
      Text(
        'This application uses yt-dlp as the underlying downloader.\n'
        'Project page: https://github.com/yt-dlp/yt-dlp',
      ),
    ],
  );
}


  @override
  void dispose() {
    _urlController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _ytDlpAssetPath() {
    if (Platform.isWindows) {
      return 'assets/yt-dlp/win/yt-dlp.exe';
    } else if (Platform.isLinux) {
      return 'assets/yt-dlp/linux/yt-dlp';
    } else {
      throw UnsupportedError('yt-dlp only configured for Windows and Linux');
    }
  }

  /// Prepare yt-dlp:
  /// - use a persistent app-support directory
  /// - seed from bundled asset if missing
  /// - run `yt-dlp -U` once per app run to update in place
  Future<String> _prepareYtDlp() async {
    final supportDir = await getApplicationSupportDirectory();
    final exeName = Platform.isWindows ? 'yt-dlp.exe' : 'yt-dlp';
    final exePath = '${supportDir.path}/$exeName';
    final file = File(exePath);

    // 1) Seed from asset on first run
    if (!await file.exists()) {
      final assetPath = _ytDlpAssetPath();
      final byteData = await rootBundle.load(assetPath);

      await file.create(recursive: true);
      await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);

      if (!Platform.isWindows) {
        await Process.run('chmod', ['+x', exePath]);
      }

      setState(() {
        _log += 'Seeded yt-dlp binary from bundled asset.\n';
      });
    }

    // 2) Run self-updater once per app run
    if (!_checkedForUpdates) {
      _checkedForUpdates = true;
      try {
        setState(() {
          _log += '\n[yt-dlp] Checking for updates...\n';
        });

        final result = await Process.run(exePath, ['-U']);

        setState(() {
          if (result.stdout.toString().trim().isNotEmpty) {
            _log += '[yt-dlp] Update output:\n${result.stdout}\n';
          }
          final err = result.stderr.toString().trim();
          if (err.isNotEmpty) {
            _log += '[yt-dlp] Update stderr:\n$err\n';
          }
        });
      } catch (e) {
        setState(() {
          _log += '[yt-dlp] Update check failed: $e\n';
        });
      }
    }

    return exePath;
  }

  // Map preset -> yt-dlp flags (using built-in -t aliases)
  List<String> _buildPresetArgs() {
    switch (_selectedPreset) {
      case 'mp3':
      case 'aac':
      case 'mp4':
      case 'mkv':
      case 'sleep':
        return ['-t', _selectedPreset];
      default:
        return [];
    }
  }

  void _handleYtDlpOutput(String data) {
    // normalize carriage returns so each progress update becomes a new line
    final normalized = data.replaceAll('\r', '\n');

    setState(() {
      _log += normalized;

      final match = RegExp(r'(\d+(?:\.\d+)?)%').firstMatch(normalized);
      if (match != null) {
        final pct = double.tryParse(match.group(1)!);
        if (pct != null) {
          _progress = (pct / 100).clamp(0.0, 1.0);
        }
      }
    });

    // autoscroll after the frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickOutputDir() async {
    final String? path = await getDirectoryPath();
    if (path != null) {
      setState(() {
        _outputDir = path;
        _log += 'Output directory set to:\n$path\n\n';
      });
    }
  }

  Future<void> _onDownloadPressed() async {
    final url = _urlController.text.trim();

    if (url.isEmpty) {
      setState(() {
        _log = 'Please enter a YouTube URL before downloading.\n';
      });
      return;
    }

    setState(() {
      _isDownloading = true;
      _progress = 0.0;
      _log = 'Preparing yt-dlp binary...\n';
      _log += 'Selected preset: $_selectedPreset\n';
    });

    try {
      final exePath = await _prepareYtDlp();

      final args = <String>[];

      // preset (-t <preset>)
      args.addAll(_buildPresetArgs());

      // output directory
      if (_outputDir != null && _outputDir!.isNotEmpty) {
        args.addAll(['-P', _outputDir!]);
      }

      // URL last
      args.add(url);

      setState(() {
        _log += 'Starting yt-dlp...\n';
        _log += 'Preset: $_selectedPreset\n';
        if (_outputDir != null) {
          _log += 'Output directory: $_outputDir\n';
        }
        _log += 'Command: $exePath ${args.join(' ')}\n\n';
      });

      final process = await Process.start(
        exePath,
        args,
        runInShell: true,
      );

      process.stdout
          .transform(SystemEncoding().decoder)
          .listen(_handleYtDlpOutput);

      process.stderr
          .transform(SystemEncoding().decoder)
          .listen(_handleYtDlpOutput);

      final exitCode = await process.exitCode;

      setState(() {
        _log += '\nyt-dlp finished with exit code: $exitCode\n';
      });
    } catch (e) {
      setState(() {
        _log += '\nError while running yt-dlp: $e\n';
      });
    } finally {
      setState(() {
        _isDownloading = false;
        _progress = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('YT Downloader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: _showAbout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('YouTube URL'),
            const SizedBox(height: 8),
            TextField(
              controller: _urlController,
              decoration: const InputDecoration(
                hintText: 'Paste a YouTube link here',
              ),
            ),
            const SizedBox(height: 16),

            const Text('Output folder'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _outputDir ?? 'No Directory Selected',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _isDownloading ? null : _pickOutputDir,
                  child: const Text('Choose folder'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            const Text('Format preset'),
            const SizedBox(height: 8),
            DropdownButton<String>(
              value: _selectedPreset,
              items: const [
                DropdownMenuItem(
                  value: 'mp3',
                  child: Text('MP3 (audio)'),
                ),
                DropdownMenuItem(
                  value: 'aac',
                  child: Text('AAC (audio)'),
                ),
                DropdownMenuItem(
                  value: 'mp4',
                  child: Text('MP4 (video)'),
                ),
                DropdownMenuItem(
                  value: 'mkv',
                  child: Text('MKV (video)'),
                ),
                DropdownMenuItem(
                  value: 'sleep',
                  child: Text('Sleep preset'),
                ),
              ],
              onChanged: _isDownloading
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _selectedPreset = value;
                      });
                    },
            ),
            const SizedBox(height: 16),

            Center(
              child: ElevatedButton(
                onPressed: _isDownloading ? null : _onDownloadPressed,
                child: Text(_isDownloading ? 'Downloading...' : 'Download'),
              ),
            ),
            const SizedBox(height: 16),

            if (_isDownloading) ...[
              LinearProgressIndicator(
                value: _progress,
                minHeight: 6,
              ),
              const SizedBox(height: 16),
            ],

            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                child: Text(
                  _log.isEmpty
                      ? 'Log output will appear here later.'
                      : _log,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                  ),
                  softWrap: true,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
