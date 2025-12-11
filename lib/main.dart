import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_selector/file_selector.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GUI Wrapper for yt-dlp',
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF8A7BEA),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF8A7BEA),
        brightness: Brightness.dark,
      ),
      home: HomePage(
        onThemeToggle: (isDark) {
          setState(() {
            _isDarkMode = isDark;
          });
        },
        isDarkMode: _isDarkMode,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final Function(bool) onThemeToggle;
  final bool isDarkMode;

  const HomePage({
    super.key,
    required this.onThemeToggle,
    required this.isDarkMode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _urlController = TextEditingController();
  final TextEditingController _customArgsController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _log = '';
  bool _isDownloading = false;
  double? _progress;
  String? _outputDir;
  String _selectedPreset = 'mp3';
  String _selectedQuality = 'best';
  bool _downloadSubtitles = false;
  bool _downloadThumbnail = false;
  String? _videoInfo;
  bool _showAdvancedOptions = false;
  String _audioBitrate = '192';

  bool _checkedForUpdates = false;

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

  void _showCustomOptionsGuide() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'yt-dlp Custom Options Guide',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Common Options',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildOptionCard(
                  flag: '--socket-timeout 30',
                  description: 'Set socket timeout in seconds (default: 30)',
                ),
                _buildOptionCard(
                  flag: '--retries 5',
                  description: 'Number of retries for failed downloads',
                ),
                _buildOptionCard(
                  flag: '--retry-sleep 5',
                  description: 'Sleep time (seconds) between retries',
                ),
                _buildOptionCard(
                  flag: '--no-abort-on-unavailable-fragment',
                  description: 'Continue download if some fragments fail',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Quality & Format Options',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildOptionCard(
                  flag: '-f "bv+ba/best"',
                  description:
                      'Download best video and audio separately, then merge',
                ),
                _buildOptionCard(
                  flag: '-f "bv*[height<=1080]+ba/best"',
                  description: 'Max 1080p video + best audio',
                ),
                _buildOptionCard(
                  flag: '-f "worst"',
                  description: 'Download worst quality (smallest file)',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Post-Processing Options',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildOptionCard(
                  flag: '--embed-subs',
                  description: 'Embed subtitles in the video file',
                ),
                _buildOptionCard(
                  flag: '--embed-thumbnail',
                  description: 'Embed thumbnail in the media file',
                ),
                _buildOptionCard(
                  flag: '-x --audio-format opus --audio-quality 128',
                  description: 'Extract audio in Opus format at 128kbps',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Other Useful Options',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                _buildOptionCard(
                  flag: '--download-archive archive.txt',
                  description: 'Skip videos already in archive file',
                ),
                _buildOptionCard(
                  flag: '--playlist-items "1-10"',
                  description:
                      'Download specific items from playlist (1st to 10th)',
                ),
                _buildOptionCard(
                  flag: '--dateafter now-1month',
                  description: 'Only download videos from the last month',
                ),
                _buildOptionCard(
                  flag: '--match-filters "duration>600"',
                  description: 'Only download videos longer than 10 minutes',
                ),
                _buildOptionCard(
                  flag: '-N 4 --fragment-retries 3',
                  description: 'Use 4 concurrent fragments with 3 retries each',
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    '💡 Tip: Combine multiple options with spaces. '
                    'For example: --socket-timeout 30 --retries 5 --no-abort-on-unavailable-fragment',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({required String flag, required String description}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              flag,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _urlController.dispose();
    _customArgsController.dispose();
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

  Future<void> _fetchVideoInfo(String url) async {
    if (url.isEmpty) return;

    try {
      setState(() {
        _videoInfo = 'Fetching video info...';
      });

      final exePath = await _prepareYtDlp();
      final result = await Process.run(exePath, [
        '-j',
        '--no-warnings',
        url,
      ], runInShell: true).timeout(const Duration(seconds: 15));

      if (result.exitCode == 0) {
        final output = result.stdout.toString();
        try {
          // Simple parsing to extract title and duration
          final titleMatch = RegExp(
            r'"title"\s*:\s*"([^"]+)"',
          ).firstMatch(output);
          final durationMatch = RegExp(
            r'"duration"\s*:\s*(\d+)',
          ).firstMatch(output);

          if (titleMatch != null) {
            final title = titleMatch.group(1);
            final duration = durationMatch != null
                ? '${(int.parse(durationMatch.group(1)!) / 60).toStringAsFixed(1)} min'
                : 'Unknown';

            setState(() {
              _videoInfo = '📹 $title\n⏱️ Duration: $duration';
            });
          }
        } catch (e) {
          setState(() {
            _videoInfo = 'Video found - ready to download';
          });
        }
      } else {
        setState(() {
          _videoInfo = '❌ Could not fetch video info';
        });
      }
    } catch (e) {
      setState(() {
        _videoInfo = '❌ Error: ${e.toString().split('\n').first}';
      });
    }
  }

  Future<void> _openDownloadFolder() async {
    if (_outputDir == null || _outputDir!.isEmpty) {
      _showNotification('No output folder selected');
      return;
    }

    try {
      if (Platform.isLinux) {
        await Process.run('xdg-open', [_outputDir!]);
      } else if (Platform.isWindows) {
        await Process.run('explorer', [_outputDir!]);
      } else if (Platform.isMacOS) {
        await Process.run('open', [_outputDir!]);
      }
    } catch (e) {
      _showNotification('Could not open folder: $e');
    }
  }

  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
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

      // quality selection
      if (_selectedQuality != 'best') {
        args.addAll(['-f', _selectedQuality]);
      }

      // subtitles
      if (_downloadSubtitles) {
        args.addAll(['--write-subs', '--sub-langs', 'en']);
      }

      // thumbnail
      if (_downloadThumbnail) {
        args.add('--write-thumbnail');
      }

      // audio bitrate for audio presets
      if ((_selectedPreset == 'mp3' || _selectedPreset == 'aac') &&
          _selectedPreset != 'sleep') {
        args.addAll([
          '-o',
          '%(title)s.%(ext)s',
          '-x',
          '--audio-format',
          _selectedPreset.replaceFirst('mp', 'm'),
          '--audio-quality',
          _audioBitrate,
        ]);
      }

      // custom arguments
      if (_customArgsController.text.trim().isNotEmpty) {
        args.addAll(_customArgsController.text.trim().split(' '));
      }

      // output directory
      if (_outputDir != null && _outputDir!.isNotEmpty) {
        args.addAll(['-P', _outputDir!]);
      }

      // URL last
      args.add(url);

      setState(() {
        _log += 'Starting yt-dlp...\n';
        _log += 'Preset: $_selectedPreset\n';
        _log += 'Quality: $_selectedQuality\n';
        if (_downloadSubtitles) _log += 'Subtitles: Enabled\n';
        if (_downloadThumbnail) _log += 'Thumbnail: Enabled\n';
        if (_outputDir != null) {
          _log += 'Output directory: $_outputDir\n';
        }
        _log += 'Command: $exePath ${args.join(' ')}\n\n';
      });

      final process = await Process.start(exePath, args, runInShell: true);

      process.stdout
          .transform(SystemEncoding().decoder)
          .listen(_handleYtDlpOutput);

      process.stderr
          .transform(SystemEncoding().decoder)
          .listen(_handleYtDlpOutput);

      final exitCode = await process.exitCode;

      setState(() {
        _log += '\nyt-dlp finished with exit code: $exitCode\n';
        if (exitCode == 0) {
          _showNotification('✅ Download completed successfully!');
        }
      });
    } catch (e) {
      setState(() {
        _log += '\nError while running yt-dlp: $e\n';
      });
      _showNotification('❌ Download failed: $e');
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
        title: const Text(
          'YT Downloader',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 2,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            tooltip: 'Custom Options Guide',
            onPressed: _showCustomOptionsGuide,
          ),
          IconButton(
            icon: Icon(widget.isDarkMode ? Icons.light_mode : Icons.dark_mode),
            tooltip: 'Toggle Dark Mode',
            onPressed: () => widget.onThemeToggle(!widget.isDarkMode),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'About',
            onPressed: _showAbout,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // URL Input Section
              _buildSectionTitle('YouTube URL'),
              const SizedBox(height: 10),
              Listener(
                onPointerMove: (event) {
                  // Drag and drop support through URL paste
                },
                child: TextField(
                  controller: _urlController,
                  enabled: !_isDownloading,
                  onChanged: (value) {
                    if (value.isNotEmpty && value.contains('youtube')) {
                      _fetchVideoInfo(value);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Paste a YouTube link here',
                    prefixIcon: const Icon(Icons.link),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                ),
              ),
              if (_videoInfo != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  ),
                  child: Text(
                    _videoInfo!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Output Folder Section
              _buildSectionTitle('Output Folder'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          _outputDir ?? 'No Directory Selected',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: _outputDir == null
                                ? Theme.of(context).colorScheme.outline
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: FilledButton.tonal(
                        onPressed: _isDownloading ? null : _pickOutputDir,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Text('Choose'),
                        ),
                      ),
                    ),
                    if (_outputDir != null)
                      Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: IconButton(
                          icon: const Icon(Icons.folder_open),
                          tooltip: 'Open folder',
                          onPressed: _openDownloadFolder,
                          constraints: const BoxConstraints(minWidth: 40),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Format Preset Section
              _buildSectionTitle('Format Preset'),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  value: _selectedPreset,
                  isExpanded: true,
                  underline: const SizedBox(),
                  items: const [
                    DropdownMenuItem(value: 'mp3', child: Text('MP3 (audio)')),
                    DropdownMenuItem(value: 'aac', child: Text('AAC (audio)')),
                    DropdownMenuItem(value: 'mp4', child: Text('MP4 (video)')),
                    DropdownMenuItem(value: 'mkv', child: Text('MKV (video)')),
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
              ),
              const SizedBox(height: 16),

              // Advanced Options Toggle
              FilledButton.tonal(
                onPressed: () {
                  setState(() {
                    _showAdvancedOptions = !_showAdvancedOptions;
                  });
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Advanced Options'),
                    const SizedBox(width: 8),
                    Icon(
                      _showAdvancedOptions
                          ? Icons.expand_less
                          : Icons.expand_more,
                    ),
                  ],
                ),
              ),

              if (_showAdvancedOptions) ...[
                const SizedBox(height: 16),
                _buildSectionTitle('Video Quality'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: _selectedQuality,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(
                        value: 'best',
                        child: Text('Best available'),
                      ),
                      DropdownMenuItem(value: '1080', child: Text('1080p')),
                      DropdownMenuItem(value: '720', child: Text('720p')),
                      DropdownMenuItem(value: '480', child: Text('480p')),
                      DropdownMenuItem(value: '360', child: Text('360p')),
                    ],
                    onChanged: _isDownloading
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _selectedQuality = value;
                            });
                          },
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('Additional Options'),
                const SizedBox(height: 10),
                CheckboxListTile(
                  title: const Text('Download Subtitles'),
                  subtitle: const Text('English subtitles'),
                  value: _downloadSubtitles,
                  onChanged: _isDownloading
                      ? null
                      : (value) {
                          setState(() {
                            _downloadSubtitles = value ?? false;
                          });
                        },
                  contentPadding: EdgeInsets.zero,
                ),
                CheckboxListTile(
                  title: const Text('Download Thumbnail'),
                  value: _downloadThumbnail,
                  onChanged: _isDownloading
                      ? null
                      : (value) {
                          setState(() {
                            _downloadThumbnail = value ?? false;
                          });
                        },
                  contentPadding: EdgeInsets.zero,
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('Audio Bitrate'),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: _audioBitrate,
                    isExpanded: true,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: '128', child: Text('128 kbps')),
                      DropdownMenuItem(value: '192', child: Text('192 kbps')),
                      DropdownMenuItem(value: '256', child: Text('256 kbps')),
                      DropdownMenuItem(value: '320', child: Text('320 kbps')),
                    ],
                    onChanged: _isDownloading
                        ? null
                        : (value) {
                            if (value == null) return;
                            setState(() {
                              _audioBitrate = value;
                            });
                          },
                  ),
                ),
                const SizedBox(height: 16),
                _buildSectionTitle('Custom Arguments'),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: Theme.of(context).colorScheme.surfaceContainerLowest,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap the help icon (?) to view common options',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _customArgsController,
                  enabled: !_isDownloading,
                  decoration: InputDecoration(
                    hintText: 'e.g., --socket-timeout 30 --retries 5',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 24),

              // Download Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: _isDownloading ? null : _onDownloadPressed,
                  icon: Icon(
                    _isDownloading ? Icons.hourglass_empty : Icons.download,
                  ),
                  label: Text(
                    _isDownloading ? 'Downloading...' : 'Download',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),

              if (_isDownloading) ...[
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Progress',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _progress,
                        minHeight: 8,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 20),

              // Log Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Download Log'),
                  Row(
                    children: [
                      FilledButton.tonal(
                        onPressed: _log.isEmpty
                            ? null
                            : () {
                                Clipboard.setData(ClipboardData(text: _log));
                                _showNotification('Log copied to clipboard');
                              },
                        child: const Text('Copy'),
                      ),
                      const SizedBox(width: 8),
                      FilledButton.tonal(
                        onPressed: () {
                          setState(() {
                            _log = '';
                          });
                        },
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: Theme.of(context).colorScheme.surfaceContainerLowest,
                ),
                padding: const EdgeInsets.all(12),
                height: 300,
                child: SingleChildScrollView(
                  controller: _scrollController,
                  child: Text(
                    _log.isEmpty
                        ? 'Log output will appear here once you start a download.'
                        : _log,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      height: 1.5,
                    ),
                    softWrap: true,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
    );
  }
}
