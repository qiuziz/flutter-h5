/*
 * @Author: qiuz
 * @Github: <https://github.com/qiuziz>
 * @Date: 2019-04-23 20:47:53
 * @Last Modified by: qiuz
 * @Last Modified time: 2019-05-30 18:01:42
 */

import 'dart:convert';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:extended_image/extended_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker_saver/image_picker_saver.dart';
import 'package:flutter_h5/component/custom-route/custom-route.dart';
import 'package:flutter_h5/container/imge-preview/imge-preview.dart';
import 'package:flutter_h5/container/login/login.dart';
import 'package:flutter_h5/net/http-utils.dart';
import 'package:flutter_h5/net/resource-api.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ImageList extends StatefulWidget {
  const ImageList({Key key, this.type, this.userId}) : super(key: key);
  final type;
  final userId;
  @override
  _ImageListState createState() => new _ImageListState();
}

class _ImageListState extends State<ImageList> {
  var _images = [];
  static const loadingTag = "Loading...";
  var _loading = false;
  var imageData = [];
  var _currentIndex = 1;
  int _page = 1;
  bool _loadMore = true;
  Map<String, dynamic> userInfo;

  Image image;
  ScrollController _controller = new ScrollController();
  @override
  void initState() {
    super.initState();
    getImages(_page);
    _controller.addListener(() {
      double maxScroll = _controller.position.maxScrollExtent;
      double currentScroll = _controller.position.pixels;
      double delta = 400.0;
      if (maxScroll - currentScroll < delta && _loadMore) {
        getImages(_page);
      }
    });
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

  void getImages([int page]) {
    if (_loading) {
      return;
    }
    setState(() {
      _loading = true;
    });
    Map<String, String> queryParams = {'page': page.toString()};
    bool islikePage = widget.type == 'like';
    !islikePage
        ? HttpUtil.get(ResourceApi.IMAGES, (result) async {
            var data = result['data'];
            _images.addAll(data);
            setState(() {
              _page = ++page;
              _loading = false;
              _currentIndex = _images.length;
            });
          }, params: queryParams)
        : HttpUtil.post(
            ResourceApi.LIKE_LIST, {'userId': widget.userId, 'page': page},
            (result) async {
            var data = result['data'];
            _images.addAll(data);
            final len = data.length;
            print(data);
            setState(() {
              _page = ++page;
              _loading = false;
              _loadMore = len < 10 ? false : true;
              _currentIndex = _images.length;
            });
          });
  }

  Future<Null> _refresh() async {
    _images.clear();
    _currentIndex = 1;
    _page = 1;
    _loadMore = true;
    getImages(1);
  }

  Widget loading() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      alignment: Alignment.center,
      child: SizedBox(
        width: 24.0,
        height: 24.0,
        child: CircularProgressIndicator(
          strokeWidth: 2.0,
        ),
      ),
    );
  }

  void viewPhoto(BuildContext context, url) async {
    final result = await Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (BuildContext context, Animation animation, Animation secondaryAnimation) {
          return new FadeTransition(
            opacity: animation,
            child: ImagePreview(url: url,),
          );
        }
      )
    );
    _images.retainWhere((img) => img['src'] != result);
  }

  void _delete(String url) {
    HttpUtil.post(
        ResourceApi.DELETE, {'userId': userInfo['userId'], 'src': url},
        (result) async {
      Navigator.pop(context);
      Fluttertoast.showToast(
          msg: '删除成功',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIos: 1,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0);
      setState(() {
        _images.retainWhere((img) => img['src'] != url);
      });
    }, errorCallback: (error) {
      Navigator.pop(context);
      return Fluttertoast.showToast(
          msg: '操作失败',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIos: 1,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0);
    });
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
        fontSize: 16.0);
  }

  void _likeOrNot(String url) {
    if (null == userInfo['userId']) {
      Navigator.pop(context);
      Navigator.push(
        context,
        new CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => new Login(),
        ),
      );
      return;
    }

    bool islikePage = widget.type == 'like';
    HttpUtil.post(islikePage ? ResourceApi.UNLIKE : ResourceApi.LIKE,
        {'userId': userInfo['userId'], 'src': url}, (result) async {
      Navigator.pop(context);
      Fluttertoast.showToast(
          msg: '操作成功',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIos: 1,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0);

      if (islikePage) {
        _images.retainWhere((img) => img['src'] != url);
      }
    }, errorCallback: (error) {
      Navigator.pop(context);
      return Fluttertoast.showToast(
          msg: '操作失败',
          toastLength: Toast.LENGTH_LONG,
          gravity: ToastGravity.CENTER,
          timeInSecForIos: 1,
          backgroundColor: Colors.black54,
          textColor: Colors.white,
          fontSize: 16.0);
    });
  }

  void _handleLongPress(String url) {
    var deleteWidget;
    if (null != userInfo['userId'] && userInfo['auth'] == 'admin') {
      deleteWidget = new ListTile(
        leading: new Icon(Icons.save),
        title: new Text("删除"),
        onTap: () => _delete(url),
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
                onTap: () => _saved(url),
              ),
              deleteWidget,
              new ListTile(
                leading: new Icon(Icons.favorite),
                title: new Text(likeTitle),
                onTap: () => _likeOrNot(url),
              ),
            ],
          ));
        });
  }

  Widget _createDialog(
      String _confirmContent, Function sureFunction, Function cancelFunction) {
    return CupertinoAlertDialog(
      title: Text('提示'),
      content: Text(_confirmContent),
      actions: <Widget>[
        FlatButton(
          onPressed: sureFunction,
          child: Text('确定', style: TextStyle(color: Colors.blue)),
        ),
        FlatButton(
          onPressed: cancelFunction,
          child: Text('取消', style: TextStyle(color: Colors.blue)),
        ),
      ],
    );
  }

  Widget itemBuilder(BuildContext context, int index) {
    if (index >= _currentIndex - 1 && _loadMore) {
      return loading();
    }
    final _src = _images[index]['src'];
    return new Dismissible(
      direction: userInfo['auth'] == 'admin'
          ? DismissDirection.horizontal
          : DismissDirection.startToEnd,
      key: new Key(_images[index]['_id']),
      background: Container(
        child: Padding(
          padding: const EdgeInsets.only(left: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('收藏',
                  style: Theme.of(context)
                      .primaryTextTheme
                      .subhead
                      .copyWith(color: Colors.green)),
              Icon(
                Icons.bookmark_border,
                color: Colors.green,
              ),
            ],
          ),
        ),
      ),
      secondaryBackground: Container(
        child: Padding(
          padding: const EdgeInsets.only(right: 20.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text('删除',
                  style: Theme.of(context)
                      .primaryTextTheme
                      .subhead
                      .copyWith(color: Colors.red)),
              Icon(
                Icons.delete,
                color: Colors.red,
              ),
            ],
          ),
        ),
      ),
      confirmDismiss: (direction) async {
        print(direction);

        var _confirmContent;

        var _alertDialog;

        if (direction == DismissDirection.endToStart) {
          // 从右向左  也就是删除
          _confirmContent = '确认删除？';
          _alertDialog =
              _createDialog(_confirmContent, () => _delete(_src), () {
            Navigator.of(context).pop(false);
          });
        } else if (direction == DismissDirection.startToEnd) {
          _confirmContent = '确认收藏？';
          _alertDialog = _createDialog(
            _confirmContent,
            () => _likeOrNot(_src),
            () {
              Navigator.of(context).pop(false);
            },
          );
        }

        var isDismiss = await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) {
              return _alertDialog;
            });
        return isDismiss;
      },
      child: Hero(
        tag: _src,
        child: GestureDetector(
          onTap: () => viewPhoto(context, _src),
          onLongPress: () => _handleLongPress(_src),
          child: Container(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: new ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: CachedNetworkImage(
                    imageUrl: _src,
                    placeholder: (context, url) => loading(),
                    errorWidget: (context, url, error) => new Icon(Icons.error),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        body: SafeArea(
            child: RefreshIndicator(
      onRefresh: _refresh,
      child: new ListView.builder(
        itemCount: _images.length == 0 ? 1 : _images.length,
        controller: _controller,
        itemBuilder: (context, index) => itemBuilder(context, index),
      ),
    )));
  }
}
