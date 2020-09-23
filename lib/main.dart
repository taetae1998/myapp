import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:image/image.dart' as imageLib;

import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myapp/splashscreen.dart';
import 'package:share/share.dart';
import 'package:photofilters/photofilters.dart';
import 'package:path/path.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'image picker',
      theme: ThemeData(brightness: Brightness.dark),
      home: MainPage()
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    Future.delayed(Duration(seconds: 2), () {
      this.setState(() {
        this._loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return (this._loading ? SplashScreenByLuke() : MyHomePage());
  }
}


class MyHomePage extends StatefulWidget {
  MyHomePage({Key key}) : super(key: key);

  createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  File _image;
  List<Filter> filters = presetFiltersList;
  String fileName;
  String _textInput;
  final controller = new TextEditingController();

  /// select an image via gallery or camera
  Future<Null> _getImage(ImageSource source) async {
    ImagePicker imagePicker = new ImagePicker();
    final imagePath = await imagePicker.getImage(source: source);
    final File rawImage = File(imagePath.path);

    setState(() {
      _image = rawImage;
    });
  }

  /// remove image
  void _clear() {
    setState(() {
      _image = null;
    });
  }

  /// cropper plugin
  Future<Null> _cropImage() async {
    final File cropped = await ImageCropper.cropImage(sourcePath: _image.path);

    this._addWatermark();
    setState(() {
      this._image = cropped ?? this._image;
    });

    AndroidUiSettings(
      toolbarTitle: 'Cropper',
      toolbarColor: Colors.pinkAccent,
      toolbarWidgetColor: Colors.pinkAccent,
    );
  }


  Future<Null> _addWatermark() async {
    imageLib.Image userSelectedImage;
    var data = await rootBundle.load("assets/logo.png");
    imageLib.Image logo = imageLib.readPng(data.buffer.asUint8List());

    /// Gets the image from the disk, and checks if it is jpeg or png
    final String path = this._image.path;
    final int extSep = path.lastIndexOf('.') + 1;
    final String ext = path.substring(extSep, path.length);
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        {
          userSelectedImage = imageLib.readJpg(await this._image.readAsBytes());
          break;
        }
      case 'png':
        {
          userSelectedImage = imageLib.readPng(await this._image.readAsBytes());
          break;
        }
      default:
        throw "Invalid file extension, jpg/jpeg/png is allowed";
    }

    /// Draws the lines onto the image, the thickness diff must be half
    ///  of the thickness itself, make sure that the thickness is a even
    ///  number
    final color = imageLib.getColor(233, 25, 109);
    final thickness = 50;
    final thicknessUpper = 80;
    final thicknessDiff = 20;

    ///upper border
    imageLib.drawLine(
        userSelectedImage, 0, 0, userSelectedImage.width - thicknessDiff, 0,
        color, thickness: thicknessUpper);
    imageLib.drawLine(
        userSelectedImage, userSelectedImage.width - thicknessDiff, 0,
        userSelectedImage.width - thicknessDiff, userSelectedImage.height,
        color, thickness: thickness);
    imageLib.drawLine(userSelectedImage, userSelectedImage.width,
        userSelectedImage.height - thicknessDiff, 0,
        userSelectedImage.height - thicknessDiff, color, thickness: thickness);
    imageLib.drawLine(
        userSelectedImage, thicknessDiff, userSelectedImage.height,
        thicknessDiff, thicknessDiff, color, thickness: thickness);

    /// Draws the logo to the image and saves it to the local storage
    imageLib.drawImage(userSelectedImage, logo, dstX: thickness + thicknessDiff,
        dstY: thickness + thicknessDiff);
    if (_textInput.isNotEmpty) {
      /// Calculates the length of the string in pixels, each char has an x advance
      ///  variable which will tell how many pixels the kinda-width is
      int backgroundWidth = 0;
      for (int i = 0; i < _textInput.length; ++i)
        backgroundWidth += imageLib.arial_48.characters[_textInput.codeUnitAt(i)].xadvance;

      /// Draws the background square after which we draw the text on the top of it
      final int startX = userSelectedImage.width ~/ 2 - backgroundWidth ~/ 2 - thickness ~/ 2, startY = userSelectedImage.height - 80 - thickness, padding = 30;
      imageLib.fillRect(userSelectedImage, startX, startY, startX + padding * 2 + backgroundWidth, startY + 48, imageLib.getColor(233, 25, 109, 120));
      imageLib.drawString(userSelectedImage, imageLib.arial_48, startX + padding, startY, _textInput);
    }

    switch (ext) {
      case 'jpg':
      case 'jpeg':
        {
          this._image.writeAsBytes(imageLib.encodeJpg(userSelectedImage));
          break;
        }
      case 'png':
        {
          this._image.writeAsBytes(imageLib.encodePng(userSelectedImage));
          break;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('biosagenda template'),
        backgroundColor: Colors.redAccent,
        actions: <Widget>[
          Padding(
            padding: EdgeInsets.only(right: 20.0),
            child: GestureDetector(
              child: Builder(
                builder: (BuildContext context) {
                  return IconButton(
                    icon: Icon(Icons.share),
                    onPressed: () => _onShare(context),
                  );
                },
              ),
            ),
          ),
        ],
        leading: IconButton(
          icon: Icon(Icons.delete),
          onPressed: () => _clear(),
        ),
      ),
      bottomNavigationBar: BottomAppBar(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            IconButton(
              icon: Icon(Icons.photo_camera),
              onPressed: () async {
                await this._getImage(ImageSource.camera);
                await this._cropImage();
              },
              color: Colors.red,
              iconSize: 36,
            ),
            IconButton(
              icon: Icon(Icons.add_a_photo),
              onPressed: () => _getImage(ImageSource.gallery),
              color: Colors.blue,
              iconSize: 36,
            ),
          ],
        ),
      ),
      body: Container(
        margin: new EdgeInsets.all(20.0),
        child: ListView(
          children: _image != null ? <Widget>[
                  Image.file(_image),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                FlatButton(
                  child: Icon(Icons.text_fields),
                  onPressed: () => textPopup(context),
                  padding: EdgeInsets.all(10),
                  color: Colors.black26,
                ),
                FlatButton(
                  child: Icon(Icons.filter),
                  onPressed: () => _filterImage(context),
                  padding: EdgeInsets.all(10),
                  color: Colors.black26,
                ),
                FlatButton(
                  child: Icon(Icons.crop),
                  onPressed: _cropImage,
                  padding: EdgeInsets.all(10),
                  color: Colors.black26,
                ),
              ],
            ),
          ] : <Widget>[],
        ),
      ),
    );
  }

  Future _filterImage(context) async{
    fileName = basename(_image.path);
    var image = imageLib.decodeImage(_image.readAsBytesSync());
    image = imageLib.copyResize(image, width: 600);
    Map imageFile = await Navigator.push(
      context,
      new MaterialPageRoute(
        builder: (context) =>
        new PhotoFilterSelector(
          image: image,
          filters: presetFiltersList,
          filename: fileName,
          loader: Center(child: CircularProgressIndicator()),
          fit: BoxFit.contain,
          title: Text('filter'),
        ),
      ),
    );
    if (imageFile != null && imageFile.containsKey('image_filtered')) {
      setState(() {
        _image = imageFile['image_filtered'];
      });
      print(_image.path);
    }
  }

  _onShare(BuildContext context) async {
    final RenderBox box = context.findRenderObject();
    if (_image.path.isNotEmpty) {
      await Share.shareFiles([_image.path],
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
    } else {
      await Share.share('',
          sharePositionOrigin: box.localToGlobal(Offset.zero) & box.size);
    }
  }
  ///get a pop up textField and input text that you want to use.
  void textPopup(BuildContext context) {
    var alertDialog = AlertDialog(
      content: TextField(
              decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter a search term'
              ),
              controller: controller,
            ),
      actions: [
        FlatButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: Text("cancel"),
        ),
        FlatButton(
          onPressed: () {
            setState(() {
              _textInput = controller.text;
            });
            TextSpan(
              text: _textInput,
              style:DefaultTextStyle.of(context).style.apply(fontSizeFactor: 2.0)
            );
            Navigator.of(context).pop();
          },
          child: Text("save"),
        )
      ],
    );

    showDialog(
        context: context,
        builder: (BuildContext context) => alertDialog);
  }
}

