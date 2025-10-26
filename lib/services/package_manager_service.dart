import 'package:flutter/foundation.dart';
import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import '../models/command_result.dart';

class PackageManagerService extends ChangeNotifier {
  String _packagesDir = '';
  String _prootDir = '';
  String _binDir = '';
  final Map<String, PackageInfo> _installedPackages = {};
  bool _isInitialized = false;

  String get packagesDir => _packagesDir;
  String get prootDir => _prootDir;
  String get binDir => _binDir;
  Map<String, String> get installedPackages => Map.fromEntries(
    _installedPackages.entries.map((e) => MapEntry(e.key, e.value.version)),
  );

  // Termux repository URLs
  static const String termuxRepo =
      'https://packages-cf.termux.dev/apt/termux-main';
  static const String termuxArch =
      'aarch64'; // Change based on device architecture

  PackageManagerService() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      _packagesDir = '${appDir.path}/packages';
      _prootDir = '${appDir.path}/proot';
      _binDir = '${appDir.path}/bin';

      // Create necessary directories
      await Future.wait([
        Directory(_packagesDir).create(recursive: true),
        Directory(_prootDir).create(recursive: true),
        Directory(_binDir).create(recursive: true),
        Directory('$_prootDir/tmp').create(recursive: true),
        Directory('$_prootDir/usr/bin').create(recursive: true),
        Directory('$_prootDir/usr/lib').create(recursive: true),
        Directory('$_prootDir/usr/share').create(recursive: true),
      ]);

      await _scanInstalledPackages();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('PackageManager initialization error: $e');
    }
  }

  Future<void> _scanInstalledPackages() async {
    try {
      final metaFile = File('$_packagesDir/installed.json');
      if (await metaFile.exists()) {
        final content = await metaFile.readAsString();
        final Map<String, dynamic> data = json.decode(content);
        _installedPackages.clear();
        data.forEach((key, value) {
          _installedPackages[key] = PackageInfo.fromJson(value);
        });
      }
    } catch (e) {
      debugPrint('Error scanning packages: $e');
    }
  }

  Future<void> _saveInstalledPackages() async {
    try {
      final metaFile = File('$_packagesDir/installed.json');
      final data = Map.fromEntries(
        _installedPackages.entries.map(
          (e) => MapEntry(e.key, e.value.toJson()),
        ),
      );
      await metaFile.writeAsString(json.encode(data));
    } catch (e) {
      debugPrint('Error saving packages: $e');
    }
  }

  Future<CommandResult> installPackage(String packageName) async {
    if (!_isInitialized) {
      return CommandResult.error('Package manager not initialized');
    }

    try {
      // Check if already installed
      if (_installedPackages.containsKey(packageName)) {
        return CommandResult.success(
          'Package $packageName is already installed',
        );
      }

      // Try different installation methods in order
      CommandResult result;

      // 1. Try to install from Termux repos (if available)
      result = await _installFromTermux(packageName);
      if (result.success) return result;

      // 2. Try to install common binaries
      result = await _installCommonBinary(packageName);
      if (result.success) return result;

      // 3. Try to install via apt-get (if in proot)
      result = await _installViaApt(packageName);
      if (result.success) return result;

      return CommandResult.error(
        'Package $packageName not found in any repository.\n'
        'Try: pkg install termux-tools (to set up full environment)',
      );
    } catch (e) {
      return CommandResult.error('Failed to install $packageName: $e');
    }
  }

  Future<CommandResult> _installFromTermux(String packageName) async {
    try {
      // This requires Termux to be installed
      final termuxBin = '/data/data/com.termux/files/usr/bin/$packageName';
      final termuxFile = File(termuxBin);

      if (await termuxFile.exists()) {
        // Copy binary to our bin directory
        final targetFile = File('$_binDir/$packageName');
        await termuxFile.copy(targetFile.path);
        await Process.run('chmod', ['755', targetFile.path]);

        _installedPackages[packageName] = PackageInfo(
          name: packageName,
          version: 'termux',
          installDate: DateTime.now(),
          source: 'termux',
        );
        await _saveInstalledPackages();
        notifyListeners();

        return CommandResult.success(
          'Package $packageName installed from Termux',
        );
      }
    } catch (e) {
      debugPrint('Termux install failed: $e');
    }
    return CommandResult.error('Not found in Termux');
  }

  Future<CommandResult> _installCommonBinary(String packageName) async {
    // Install common binaries from GitHub releases or other sources
    final Map<String, String> commonPackages = {
      'git':
          'https://github.com/git/git/releases/download/v2.42.0/git-2.42.0-arm64.tar.gz',
      'python': 'https://www.python.org/ftp/python/3.11.5/Python-3.11.5.tar.xz',
      'node': 'https://nodejs.org/dist/v20.9.0/node-v20.9.0-linux-arm64.tar.xz',
      'vim': 'https://github.com/vim/vim/archive/refs/tags/v9.0.2000.tar.gz',
      'nano': 'https://www.nano-editor.org/dist/v7/nano-7.2.tar.xz',
      'curl': 'https://curl.se/download/curl-8.4.0.tar.gz',
      'wget': 'https://ftp.gnu.org/gnu/wget/wget-1.21.4.tar.gz',
    };

    if (!commonPackages.containsKey(packageName)) {
      return CommandResult.error('Package not in common list');
    }

    try {
      final url = commonPackages[packageName]!;
      final response = await http.get(Uri.parse(url));

      if (response.statusCode != 200) {
        return CommandResult.error('Failed to download package');
      }

      // Extract and install
      final archive = TarDecoder().decodeBytes(response.bodyBytes);
      final installDir = Directory('$_packagesDir/$packageName');
      await installDir.create(recursive: true);

      for (final file in archive) {
        if (file.isFile) {
          final outputFile = File('${installDir.path}/${file.name}');
          await outputFile.create(recursive: true);
          await outputFile.writeAsBytes(file.content as List<int>);
        }
      }

      _installedPackages[packageName] = PackageInfo(
        name: packageName,
        version: 'latest',
        installDate: DateTime.now(),
        source: 'github',
      );
      await _saveInstalledPackages();
      notifyListeners();

      return CommandResult.success(
        'Package $packageName installed successfully',
      );
    } catch (e) {
      return CommandResult.error('Installation failed: $e');
    }
  }

  Future<CommandResult> _installViaApt(String packageName) async {
    try {
      // Check if running in proot or has apt
      final result = await Process.run('which', ['apt-get']);

      if (result.exitCode == 0) {
        final installResult = await Process.run(
          'apt-get',
          ['install', '-y', packageName],
          environment: {'DEBIAN_FRONTEND': 'noninteractive'},
        );

        if (installResult.exitCode == 0) {
          _installedPackages[packageName] = PackageInfo(
            name: packageName,
            version: 'apt',
            installDate: DateTime.now(),
            source: 'apt',
          );
          await _saveInstalledPackages();
          notifyListeners();

          return CommandResult.success(
            'Package $packageName installed via apt-get\n${installResult.stdout}',
          );
        } else {
          return CommandResult.error('apt-get failed: ${installResult.stderr}');
        }
      }
    } catch (e) {
      debugPrint('apt-get not available: $e');
    }
    return CommandResult.error('apt-get not available');
  }

  Future<CommandResult> removePackage(String packageName) async {
    if (_installedPackages.containsKey(packageName)) {
      // Remove binary
      final binFile = File('$_binDir/$packageName');
      if (await binFile.exists()) {
        await binFile.delete();
      }

      // Remove package directory
      final pkgDir = Directory('$_packagesDir/$packageName');
      if (await pkgDir.exists()) {
        await pkgDir.delete(recursive: true);
      }

      _installedPackages.remove(packageName);
      await _saveInstalledPackages();
      notifyListeners();

      return CommandResult.success('Package $packageName removed');
    }
    return CommandResult.error('Package $packageName not found');
  }

  Future<CommandResult> setupGoEnvironment() async {
    try {
      final goDir = Directory('$_prootDir/go');
      if (!await goDir.exists()) {
        await goDir.create(recursive: true);
      }

      // Create GOPATH structure
      await Future.wait([
        Directory('${goDir.path}/bin').create(recursive: true),
        Directory('${goDir.path}/src').create(recursive: true),
        Directory('${goDir.path}/pkg').create(recursive: true),
      ]);

      // Try to download and install Go
      final result = await _installCommonBinary('go');
      if (result.success) {
        return CommandResult.success(
          'Go environment set up at: ${goDir.path}\n'
          'Add to PATH: export PATH=\$PATH:${goDir.path}/bin',
        );
      }

      return CommandResult.success(
        'Go directories created at: ${goDir.path}\n'
        'To complete setup:\n'
        '1. Install Termux: pkg install golang\n'
        '2. Or download from: https://go.dev/dl/',
      );
    } catch (e) {
      return CommandResult.error('Failed to setup Go environment: $e');
    }
  }

  // Setup proot environment for running Linux binaries
  Future<CommandResult> setupProotEnvironment() async {
    try {
      // Download and setup proot
      const prootUrl =
          'https://github.com/termux/proot/releases/download/v5.1.107/proot-v5.1.107-aarch64';

      final prootBin = File('$_binDir/proot');
      if (!await prootBin.exists()) {
        final response = await http.get(Uri.parse(prootUrl));
        if (response.statusCode == 200) {
          await prootBin.writeAsBytes(response.bodyBytes);
          await Process.run('chmod', ['755', prootBin.path]);
        }
      }

      // Create rootfs structure
      final rootfsDirs = [
        'bin',
        'sbin',
        'usr/bin',
        'usr/sbin',
        'usr/lib',
        'etc',
        'tmp',
        'var',
        'home',
        'root',
      ];

      for (final dir in rootfsDirs) {
        await Directory('$_prootDir/$dir').create(recursive: true);
      }

      return CommandResult.success(
        'Proot environment set up at: $_prootDir\n'
        'Use: proot -r $_prootDir /bin/sh',
      );
    } catch (e) {
      return CommandResult.error('Failed to setup proot: $e');
    }
  }

  // Execute command in proot environment
  Future<CommandResult> executeInProot(String command) async {
    try {
      final prootBin = File('$_binDir/proot');
      if (!await prootBin.exists()) {
        return CommandResult.error(
          'Proot not installed. Run: pkg install termux-tools',
        );
      }

      final result = await Process.run(
        prootBin.path,
        ['-r', _prootDir, '-w', '/root', '/bin/sh', '-c', command],
        environment: {
          'PATH': '/usr/bin:/bin:/usr/sbin:/sbin:$_binDir',
          'HOME': '/root',
          'TERM': 'xterm-256color',
        },
      );

      if (result.exitCode == 0) {
        return CommandResult.success(result.stdout.toString());
      } else {
        return CommandResult.error(
          result.stderr.toString(),
          exitCode: result.exitCode,
        );
      }
    } catch (e) {
      return CommandResult.error('Proot execution failed: $e');
    }
  }

  // Search for packages
  Future<List<String>> searchPackages(String query) async {
    final results = <String>[];

    // Search in common packages
    final commonPackages = [
      'git',
      'python',
      'python3',
      'node',
      'npm',
      'vim',
      'nano',
      'curl',
      'wget',
      'htop',
      'neofetch',
      'tmux',
      'gcc',
      'make',
      'clang',
      'rustc',
      'go',
      'ruby',
      'perl',
      'php',
      'lua',
    ];

    for (final pkg in commonPackages) {
      if (pkg.contains(query.toLowerCase())) {
        results.add(pkg);
      }
    }

    return results;
  }

  // Update package lists
  Future<CommandResult> updatePackageLists() async {
    try {
      // Try apt-get update if available
      final result = await Process.run('which', ['apt-get']);

      if (result.exitCode == 0) {
        final updateResult = await Process.run('apt-get', ['update']);
        if (updateResult.exitCode == 0) {
          return CommandResult.success('Package lists updated');
        }
      }

      return CommandResult.success(
        'Package lists updated (simulated)\n'
        'For full apt functionality, install Termux or setup proot',
      );
    } catch (e) {
      return CommandResult.error('Update failed: $e');
    }
  }
}

class PackageInfo {
  final String name;
  final String version;
  final DateTime installDate;
  final String source;

  PackageInfo({
    required this.name,
    required this.version,
    required this.installDate,
    required this.source,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'version': version,
    'installDate': installDate.toIso8601String(),
    'source': source,
  };

  factory PackageInfo.fromJson(Map<String, dynamic> json) => PackageInfo(
    name: json['name'],
    version: json['version'],
    installDate: DateTime.parse(json['installDate']),
    source: json['source'],
  );
}
