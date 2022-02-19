import 'package:barcode_bill_scanner/barcode_bill_scanner.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BarcodeBillScanner Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String? barcode;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        BarcodeBillScanner(
          onActionLabel: "You can set a message to cancel an action",
          onSuccess: (String value) async {
            setState(() => barcode = value);
          },
          onCancel: () {
            setState(() => barcode = null);
          },
        ),
        if (barcode != null)
          Text(
            barcode!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 20.0,
              color: Colors.amber,
            ),
          ),
      ],
    );
  }
}
