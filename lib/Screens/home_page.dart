import 'dart:io';

import 'package:anuvaadak/constants/lang_list.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_tesseract_ocr/flutter_tesseract_ocr.dart';
import 'package:flutter/foundation.dart';
import 'package:translator/translator.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _ocrText = '';
  // String _ocrHocr = '';
  final translator = GoogleTranslator();
  var selectList = [
    "eng",
    "hin",
    "guj",
  ];
  String path = "";
  bool bload = false;

  bool bDownloadtessFile = false;
  var urlEditController = TextEditingController()
    ..text = "https://tesseract.projectnaptha.com/img/eng_bw.png";

  Future<void> writeToFile(ByteData data, String path) {
    final buffer = data.buffer;
    return File(path).writeAsBytes(
        buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
  }

  void runFilePiker() async {
    // android && ios only
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      path = pickedFile.path;
      _ocr(pickedFile.path);
    }
  }

  void _ocr(url) async {
    if (selectList.isEmpty) {
      print("Please select language");
      return;
    }
    path = url;
    if (kIsWeb == false &&
        (url.indexOf("http://") == 0 || url.indexOf("https://") == 0)) {
      Directory tempDir = await getTemporaryDirectory();
      HttpClient httpClient = HttpClient();
      HttpClientRequest request = await httpClient.getUrl(Uri.parse(url));
      HttpClientResponse response = await request.close();
      Uint8List bytes = await consolidateHttpClientResponseBytes(response);
      String dir = tempDir.path;
      print('$dir/test.jpg');
      File file = File('$dir/test.jpg');
      await file.writeAsBytes(bytes);
      url = file.path;
    }
    var langs = selectList.join("+");

    bload = true;
    setState(() {});

    _ocrText =
        await FlutterTesseractOcr.extractText(url, language: langs, args: {
      "preserve_interword_spaces": "1",
    });

    bload = false;
    setState(() {});
  }

  void translateText({from = "en", to}) {
    translator.translate(_ocrText, to: 'hi').then((result) => {
          print("\nTranslated: $result"),
          _ocrText = result.text,
          setState(() {}),
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.title,
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepPurple,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'input image url',
                        ),
                        controller: urlEditController,
                      ),
                    ),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () {
                          _ocr(urlEditController.text);
                        },
                        child: const Text("Run"),
                      ),
                    ),
                  ],
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...LangList.map((e) {
                        return Row(children: [
                          Checkbox(
                              value: selectList.contains(e),
                              onChanged: (v) async {
                                // dynamic add Tessdata
                                if (kIsWeb == false) {
                                  Directory dir = Directory(
                                      await FlutterTesseractOcr
                                          .getTessdataPath());
                                  if (!dir.existsSync()) {
                                    dir.create();
                                  }
                                  bool isInstalled = false;
                                  dir.listSync().forEach((element) {
                                    String name = element.path.split('/').last;
                                    isInstalled |= name == '$e.traineddata';
                                  });
                                  if (!isInstalled) {
                                    bDownloadtessFile = true;
                                    setState(() {});
                                    HttpClient httpClient = HttpClient();
                                    HttpClientRequest request =
                                        await httpClient.getUrl(Uri.parse(
                                            'https://github.com/tesseract-ocr/tessdata/raw/main/${e}.traineddata'));
                                    HttpClientResponse response =
                                        await request.close();
                                    Uint8List bytes =
                                        await consolidateHttpClientResponseBytes(
                                            response);
                                    String dir = await FlutterTesseractOcr
                                        .getTessdataPath();
                                    print('$dir/${e}.traineddata');
                                    File file = File('$dir/${e}.traineddata');
                                    await file.writeAsBytes(bytes);
                                    bDownloadtessFile = false;
                                    setState(() {});
                                  }
                                  print(isInstalled);
                                }
                                if (!selectList.contains(e)) {
                                  selectList.add(e);
                                } else {
                                  selectList.remove(e);
                                }
                                setState(() {});
                              }),
                          Text(e)
                        ]);
                      }),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: [
                      path.isEmpty
                          ? Padding(
                              padding: EdgeInsets.only(left: 16),
                              child: Text(
                                "Insert image url or pick image from gallery",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 28,
                                ),
                              ),
                            )
                          : path.contains("http")
                              ? Image.network(path)
                              : Image.file(File(path)),
                      bload
                          ? const Column(
                              children: [
                                CircularProgressIndicator(),
                              ],
                            )
                          : TextField(
                              keyboardType: TextInputType.multiline,
                              maxLines: null,
                              controller: TextEditingController(text: _ocrText),
                              decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                label: Text("Output"),
                              ),
                            ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 36,
                        child: Expanded(
                          child: ElevatedButton(
                            onPressed: () => translateText(to: 'hi'),
                            child: Text(
                              "Translate",
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 36,
                        child: Expanded(
                          child: ElevatedButton(
                            onPressed: () => {_ocr(path)},
                            child: Text(
                              "Re-read",
                              style: TextStyle(
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Container(
            color: Colors.black26,
            child: bDownloadtessFile
                ? const Center(
                    child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      Text('download Trained language files')
                    ],
                  ))
                : const SizedBox(),
          )
        ],
      ),
      floatingActionButton: kIsWeb
          ? Container()
          : Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: FloatingActionButton(
                onPressed: () {
                  runFilePiker();
                },
                tooltip: 'OCR',
                child: const Icon(Icons.add),
              ),
            ),
    );
  }
}
