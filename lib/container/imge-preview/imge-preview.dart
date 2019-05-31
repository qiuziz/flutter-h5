/*
 * @Author: qiuz
 * @Github: <https://github.com/qiuziz>
 * @Date: 2019-04-23 20:47:53
 * @Last Modified by: qiuz
 * @Last Modified time: 2019-05-30 17:45:27
 */

import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:extended_image/extended_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker_saver/image_picker_saver.dart';
import 'package:flutter_h5/net/http-utils.dart';
import 'package:flutter_h5/net/resource-api.dart';
import 'package:shared_preferences/shared_preferences.dart';
class ImagePreview extends StatefulWidget {
  const ImagePreview({Key key, this.url, this.type}) : super(key: key);
  final url;
  final type;
  @override
  State<StatefulWidget> createState() {
    return ImagePreviewState();
  }
}

class ImagePreviewState extends State<ImagePreview> with SingleTickerProviderStateMixin {
  AnimationController _controller;
  Animation<Offset> _animation;
  Offset _offset = Offset.zero;
  double _scale = 1.0;
  bool _scaleTwo = false;
  Offset _normalizedOffset;
  double _previousScale;
  double _kMinFlingVelocity = 600.0;
  Map<String, dynamic> userInfo;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
    _controller.addListener(() {
      setState(() {
        _offset = _animation.value;
      });
    });
    SystemChrome.setEnabledSystemUIOverlays([]);
    getUserInfo();
  }

  void getUserInfo() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userInfoStr = prefs.get('userInfo');
    userInfo = null != userInfoStr ? json.decode(userInfoStr) : {};
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  Offset _clampOffset(Offset offset) {
    final Size size = context.size;
    // widget的屏幕宽度
    final Offset minOffset = Offset(size.width, size.height) * (1.0 - _scale);
    // 限制他的最小尺寸
    return Offset(
        offset.dx.clamp(minOffset.dx, 0.0), offset.dy.clamp(minOffset.dy, 0.0));
    
  }

  void _handleOnScaleStart(ScaleStartDetails details) {
    setState(() {
      _previousScale = _scale;
      _normalizedOffset = (details.focalPoint - _offset) / _scale;
      // 计算图片放大后的位置
      _controller.stop();
    });
  }

  void _handleOnScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _scale = (_previousScale * details.scale).clamp(1.0, 3.0);
      // 限制放大倍数 1~3倍
      // print(details.focalPoint);
      print(details.focalPoint - _normalizedOffset * _scale);
      _offset = _clampOffset(details.focalPoint - _normalizedOffset * _scale);
      // 更新当前位置
    });
  }

  void _handleOnScaleEnd(ScaleEndDetails details) {
    final double magnitude = details.velocity.pixelsPerSecond.distance;
    if (magnitude < _kMinFlingVelocity) return;
    final Offset direction = details.velocity.pixelsPerSecond / magnitude;
    // 计算当前的方向
    final double distance = (Offset.zero & context.size).shortestSide;
    // 计算放大倍速，并相应的放大宽和高，比如原来是600*480的图片，放大后倍数为1.25倍时，宽和高是同时变化的
    _animation = _controller.drive(Tween<Offset>(
        begin: _offset, end: _clampOffset(_offset + direction * distance)));
    _controller
      ..value = 0.0
      ..fling(velocity: magnitude / 1000.0);
  }

  void _back() {
    Navigator.pop(context);
  }

  void _handleDoubleTap() {
    setState(() {
       _scale =  _scaleTwo ? _scale / 2 : _scale * 2;
       _offset = _clampOffset(Offset(-(context.size.width / 4 * _scale), -(context.size.height / 4 * _scale)));
       _scaleTwo = !_scaleTwo;
    });
  }

  void _delete(String url) {
    HttpUtil.post(ResourceApi.DELETE, {'userId': userInfo['userId'], 'src': url}, (result)  async {
      Navigator.pop(context);
      Fluttertoast.showToast(
        msg: '删除成功',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 1,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 16.0
      );
      return Navigator.pop(context, url);
    }, errorCallback: (error) {
      Navigator.pop(context);
      return Fluttertoast.showToast(
        msg: '操作失败',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 1,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 16.0
      );
    });
  }

  void _likeOrNot(String url) {
    bool islikePage = widget.type == 'like';
     HttpUtil.post(islikePage ? ResourceApi.UNLIKE : ResourceApi.LIKE , {'userId': userInfo['userId'], 'src': url}, (result)  async {
      Navigator.pop(context);
      Fluttertoast.showToast(
        msg: '操作成功',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 1,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 16.0
      );

      return Navigator.pop(context, islikePage ? url : '');
     }, errorCallback: (error) {
      Navigator.pop(context);
      return Fluttertoast.showToast(
        msg: '操作失败',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 1,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 16.0
      );
    });
  }

  void _handleLongPress() {
    var deleteWidget;
    if (null != userInfo['userId'] && userInfo['auth'] == 'admin') {
      deleteWidget =  new ListTile(
        leading: new Icon(Icons.save),
        title: new Text("删除"),
        onTap: () => _delete(widget.url),
      );
    }
    String likeTitle = widget.type != 'like' ? '收藏' : '取消收藏';
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return new SafeArea(
          child: new Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new ListTile(
                leading: new Icon(Icons.save),
                title: new Text("保存到相册"),
                onTap: () => _saved(widget.url),
              ),
              deleteWidget,
              new ListTile(
                leading: new Icon(Icons.favorite),
                title: new Text(likeTitle),
                onTap: () => _likeOrNot(widget.url),
              ),
            ],
          )
        ); 
      }
    );
  }

 
 Future<bool> _saved(String url, {bool useCache: true}) async {
  var data = await getNetworkImageData(url, useCache: useCache);
  var filePath = await ImagePickerSaver.saveFile(fileData: data);
  Navigator.pop(context);
  return Fluttertoast.showToast(
        msg: filePath != null && filePath != "" ? '保存成功' : '保存失败',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 1,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 16.0
      );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        decoration: BoxDecoration(color: Colors.black),
        height: window.physicalSize.height,
          child: new Hero(
            tag: widget.url,
            child: GestureDetector(
              onScaleStart: _handleOnScaleStart,
              onScaleUpdate: _handleOnScaleUpdate,
              onScaleEnd: _handleOnScaleEnd,
              onLongPress: _handleLongPress,
              onTap: _back,
              onDoubleTap: _handleDoubleTap,
              child: ClipRect(
                child: Transform(
                  transform: Matrix4.identity()..translate(_offset.dx, _offset.dy)
                    ..scale(_scale),
                    child: CachedNetworkImage(
                        imageUrl: widget.url,
                      ),
                ),
                // child: Image.network(widget.url,fit: BoxFit.cover,),
              ),
            ),
          ) 
      );
  }
}
