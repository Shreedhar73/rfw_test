import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';
import 'package:rfw/rfw.dart';

const String urlPrefix =
    'https://raw.githubusercontent.com/Shreedhar73/rfw_test/main/remote_widgets/text_data.rfw';

void main() {
  runApp(const MaterialApp(home: Example()));
}

class Example extends StatefulWidget {
  const Example({super.key});

  @override
  State<Example> createState() => _ExampleState();
}

class _ExampleState extends State<Example> {
  final Runtime _runtime = Runtime();
  final DynamicContent _data = DynamicContent();

  final _ready = ValueNotifier(false);
  int _counter = 0;

  @override
  void initState() {
    super.initState();
    _runtime.update(
        const LibraryName(<String>['core', 'widgets']), createCoreWidgets());
    _runtime.update(const LibraryName(<String>['core', 'material']),
        createMaterialWidgets());
    _updateData();
    _updateWidgets();
  }

  void _updateData() {
    _data.update('counter', _counter.toString());
  }

  Future<void> _updateWidgets() async {
    // final Directory home = await getApplicationSupportDirectory();
    // final File settingsFile = File(path.join(home.path, 'settings.txt'));
    // String nextFile = '';
    // if (settingsFile.existsSync()) {
    //   final String settings = await settingsFile.readAsString();
    //   if (settings == nextFile) {
    //     nextFile = '';
    //   }
    // }
    // final File currentFile = File(path.join(home.path, 'current.rfw'));
    // if (currentFile.existsSync()) {

    // }
    try {
      await readRemoteFile();
      // _runtime.update(const LibraryName(<String>['main']),
      //     decodeLibraryBlob(await currentFile.readAsBytes()));
      // setState(() {
      //   _ready = true;
      // });
    } catch (e, stack) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: stack));
    }
    // print('Fetching: $urlPrefix$nextFile'); // ignore: avoid_print
    // final HttpClientResponse client =
    //     await (await HttpClient().getUrl(Uri.parse('$urlPrefix$nextFile')))
    //         .close();
    // await currentFile
    //     .writeAsBytes(await client.expand((List<int> chunk) => chunk).toList());
    // await settingsFile.writeAsString(nextFile);
  }

  readRemoteFile() async {
    try {
      final HttpClientResponse client =
          await (await HttpClient().getUrl(Uri.parse('$urlPrefix'))).close();
      final data = await client.expand((List<int> chunk) => chunk).toList();

      _runtime.update(const LibraryName(<String>['main']),
          decodeLibraryBlob(Uint8List.fromList(data)));
      _ready.value = true;
    } catch (e) {
      _ready.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        _ready.value = false;
        await readRemoteFile();
      },
      child: ValueListenableBuilder(
          valueListenable: _ready,
          builder: (context, value, _) {
            final Widget result;
            if (value) {
              result = RemoteWidget(
                runtime: _runtime,
                data: _data,
                widget: const FullyQualifiedWidgetName(
                    LibraryName(<String>['main']), 'Counter'),
                onEvent: (String name, DynamicMap arguments) {
                  if (name == 'increment') {
                    _counter += 1;
                    _updateData();
                  }
                },
              );
            } else {
              result = const Material(
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Padding(
                            padding: EdgeInsets.only(right: 100.0),
                            child: Text('REMOTE',
                                textAlign: TextAlign.center,
                                style: TextStyle(letterSpacing: 12.0))),
                        Expanded(
                            child: DecoratedBox(
                                decoration: FlutterLogoDecoration(
                                    style: FlutterLogoStyle.horizontal))),
                        Padding(
                            padding: EdgeInsets.only(left: 100.0),
                            child: Text('WIDGETS',
                                textAlign: TextAlign.center,
                                style: TextStyle(letterSpacing: 12.0))),
                        Spacer(),
                        Expanded(
                            child: Text(
                                'Every time this program is run, it fetches a new remote widgets library.',
                                textAlign: TextAlign.center)),
                        Expanded(
                            child: Text(
                                'The interface that it shows is whatever library was last fetched.',
                                textAlign: TextAlign.center)),
                        Expanded(
                            child: Text(
                                'Restart this application to see the new interface!',
                                textAlign: TextAlign.center)),
                      ],
                    ),
                  ),
                ),
              );
            }
            return AnimatedSwitcher(
                duration: const Duration(milliseconds: 1250),
                switchOutCurve: Curves.easeOut,
                switchInCurve: Curves.easeOut,
                child: result);
          }),
    );
  }
}
