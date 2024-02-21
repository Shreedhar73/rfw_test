import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:rfw/formats.dart';
// import 'package:path/path.dart' as path;
// import 'package:path_provider/path_provider.dart';
import 'package:rfw/rfw.dart';

const String url =
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
    _runtime.update(localName, _createLocalWidgets());
    _runtime.update(remoteName, parseLibraryFile('''
      import local;
      widget root = GreenBox(
        child: Hello(name: "World"),
      );
    '''));
    _runtime.update(
        const LibraryName(<String>['core', 'widgets']), createCoreWidgets());
    _runtime.update(const LibraryName(<String>['core', 'material']),
        createMaterialWidgets());
    _updateData();
    _updateWidgets();
  }

  static const LibraryName localName = LibraryName(<String>['local']);
  static const LibraryName remoteName = LibraryName(<String>['remote']);

  static WidgetLibrary _createLocalWidgets() {
    return LocalWidgetLibrary(<String, LocalWidgetBuilder>{
      'GreenBox': (BuildContext context, DataSource source) {
        return ColoredBox(
          color: const Color(0xFF002211),
          child: source.child(<Object>['child']),
        );
      },
      'Hello': (BuildContext context, DataSource source) {
        return Center(
          child: Text(
            'Hello, ${source.v<String>(<Object>["name"])}!',
            textDirection: TextDirection.ltr,
          ),
        );
      },
    });
  }

  void _updateData() {
    _data.update('counter', _counter.toString());
  }

  Future<void> _updateWidgets() async {
    try {
      await readRemoteFile();
    } catch (e, stack) {
      FlutterError.reportError(FlutterErrorDetails(exception: e, stack: stack));
    }
  }

  readRemoteFile() async {
    try {
      final HttpClientResponse client =
          await (await HttpClient().getUrl(Uri.parse(url))).close();
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
                    _updateData();
                    _counter += 1;
                  }
                },
              );
            } else {
              result = const Material(
                child: SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Center(
                      child: CircularProgressIndicator(),
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
