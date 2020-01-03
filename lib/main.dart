import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tflite/tflite.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

void main(){
  runApp(
      MyApp()
  );
}

const String ssd = "SSD MobileNet";
const String yolo = "Tiny YOLOv2";


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: TfliteHome(),
    );
  }
}

class TfliteHome extends StatefulWidget {
  @override
  _TfliteHomeState createState() => _TfliteHomeState();
}

class _TfliteHomeState extends State<TfliteHome> {
  String _model = ssd;
  File _image;
  bool _busy = false;

  List _recognitions;

  double _imageWidth;
  double _imageHeight;

  @override
  void initState(){
    super.initState();
    _busy = true;
    loadModel().then((val){
      setState(() {
        _busy = false;
      });
    });

  }

  loadModel() async {
    Tflite.close();
    try{
      String res;
      if(_model == yolo){
        res = await Tflite.loadModel(
          model: "assets/tflite/yolov2_tiny.tflite",
          labels: "assets/tflite/yolov2_tiny.txt"
        );
      } else {
        res = await Tflite.loadModel(
            model: "assets/tflite/ssd_mobilenet.tflite",
            labels: "assets/tflite/ssd_mobilenet.txt",
        );
      }
      print(res);
    }on PlatformException{
      print("Failed to load model");
    }
  }

  selectFromImagePickerGallery() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    if (image == null) return;
    setState(() {
      _busy = true;
    });
    predictImage(image);
  }

  selectFromImagePickerCamera() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    if (image == null) return;
    setState(() {
      _busy = true;
    });
    predictImage(image);
  }

  predictImage(File image) async {
    if (image == null) return;
    if (_model == yolo) {
      await yolov2Tiny(image);
    } else {
      await ssdMobileNet(image);
    }

    FileImage(image).resolve(ImageConfiguration()).addListener(
        (ImageStreamListener((ImageInfo info, bool _) {
          setState(() {
            _imageWidth = info.image.width.toDouble();
            _imageHeight = info.image.height.toDouble();
          });
        })));
    setState(() {
      _image = image;
      _busy = false;
    });
  }

  yolov2Tiny(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
        path: image.path,
        model: "YOLO",
        threshold: 0.3,
        imageMean: 0.0,
        imageStd: 255.0,
        numResultsPerClass: 1
    );
    setState(() {
      _recognitions = recognitions;
    });
  }

  ssdMobileNet(File image) async {
    var recognitions = await Tflite.detectObjectOnImage(
        path: image.path,
        numResultsPerClass: 1
    );
    setState(() {
      _recognitions = recognitions;
    });
  }

  List<Widget> renderBoxes (Size screen){
    if (_recognitions == null) return [];
    if (_imageWidth == null || _imageHeight == null) return [];

    double factorX = screen.width;
    double factorY = _imageHeight/_imageWidth * screen.width;

    Color blue = Colors.red;

    return _recognitions.map((re){
      return Positioned(
        left: re["rect"]["x"] * factorX,
        top: re["rect"]["y"] * factorY,
        width: re["rect"]["w"] * factorX,
        height: re["rect"]["h"] * factorY,
        child: Container(
          decoration: BoxDecoration(border: Border.all(
            color: blue,
            width: 3,
          )),
          child: Text("${re["detectedClass"]} ${(re["confidenceInClass"]*100).toStringAsFixed(0)} %",
            style: TextStyle(
              background: Paint() ..color = blue,
              color: Colors.white,
              fontSize: 15,
            ),),
        ),

      );
    }).toList();
  }


  Widget mainScreen(){
    return Container (
      child: Column(
        children: <Widget>[
          Container(
            padding: EdgeInsets.all(80.0),
          ),
          Text("Please select a Image type",style: TextStyle(fontSize: 24.0,fontWeight: FontWeight.bold),),
          Container(
            padding: EdgeInsets.all(16.0),
          ),
          imageType(),
          Container(
            padding: EdgeInsets.all(40.0) ,
          ),
          Text("Please select a model type",style: TextStyle(fontSize: 24.0,fontWeight: FontWeight.bold),),
        Container(
          padding: EdgeInsets.all(16.0),
        ),
          modelType()
        ],
      ),
    );
  }

  Widget modelType (){
    return Row(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(40.0),
        ),
        RaisedButton(
          shape: RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(18.0),

              side: BorderSide(color: Colors.blue,width: 2.0)
          ),
          color: Colors.white,
          onPressed: selectFromImagePickerGallery,
          child: Column(
            children: <Widget>[
              Container(padding: EdgeInsets.all(4.0),),
              Icon(Icons.adjust),
              Container(padding: EdgeInsets.all(4.0),),
              Text("YOLO"),
              Container(padding: EdgeInsets.all(4.0),),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.all(30.0),
        ),
        RaisedButton(
          shape: RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(18.0),

              side: BorderSide(color: Colors.blue,width: 2.0)
          ),
          color: Colors.white,
          onPressed: selectFromImagePickerCamera,
          child:Column(
            children: <Widget>[
              Container(padding: EdgeInsets.all(4.0),),
              Icon(Icons.album,),
              Container(padding: EdgeInsets.all(4.0),),
              Text("SSD"),
              Container(padding: EdgeInsets.all(4.0),),
            ],
          ),)
      ],
    );
  }

  Widget imageType () {
    return Row(
      children: <Widget>[
        Container(
          padding: EdgeInsets.all(40.0),
        ),
        RaisedButton(
          shape: RoundedRectangleBorder(
            borderRadius: new BorderRadius.circular(18.0),

            side: BorderSide(color: Colors.blue,width: 2.0)
          ),
          color: Colors.white,
          onPressed: selectFromImagePickerGallery,
          child: Column(
            children: <Widget>[
              Container(padding: EdgeInsets.all(4.0),),
              Icon(Icons.image),
              Container(padding: EdgeInsets.all(4.0),),
              Text("GALLERY"),
              Container(padding: EdgeInsets.all(4.0),),
            ],
          ),
          splashColor:Colors.amber,
        ),
        Container(
          padding: EdgeInsets.all(30.0),
        ),
        RaisedButton(
          shape: RoundedRectangleBorder(
              borderRadius: new BorderRadius.circular(18.0),

              side: BorderSide(color: Colors.blue,width: 2.0)
          ),
          color: Colors.white,
          onPressed: selectFromImagePickerCamera,
          child:Column(
            children: <Widget>[
              Container(padding: EdgeInsets.all(4.0),),
              Icon(Icons.camera,),
              Container(padding: EdgeInsets.all(4.0),),
              Text("CAMERA"),
              Container(padding: EdgeInsets.all(4.0),),
            ],
          ),
          splashColor:Colors.amber,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {

    Size size = MediaQuery.of(context).size;
    List<Widget> stackChildren = [];


    stackChildren.add(Positioned(
      top: 10.0,
      left: 0.0,
      width: size.width,
      child: _image == null ? mainScreen(): Image.file(_image),
    ));

    stackChildren.addAll(renderBoxes(size));

//    if (_busy = true){
//      stackChildren.add(Center(child: CircularProgressIndicator(),));
//    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Object Detection"),
      ),
      body: Stack(
        children: stackChildren,
      ),
    );
  }
}
