/*
 * @Author: qiuz
 * @Github: <https://github.com/qiuziz>
 * @Date: 2019-05-29 15:22:38
 * @Last Modified by: qiuz
 * @Last Modified time: 2019-05-29 17:58:38
 */

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_h5/container/login/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyDrawer extends StatefulWidget {
  const MyDrawer({Key key, this.login}) : super(key: key);
  final bool login;
  

  @override
  _MyDrawerState createState() => _MyDrawerState();
}

class _MyDrawerState extends State<MyDrawer> {
  bool login = false;
  @override
  initState() {
    super.initState();
    changeView();
  }

  Future changeView() async {
    login = await isLogin() != null;
    setState(() {
    });
  }


  Future<String> isLogin() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String userInfoStr = prefs.get('userInfo');
    Map<String, dynamic> userInfo = null != userInfoStr ? json.decode(userInfoStr) : {};
    return userInfo['userId'];
  }

  void _signInOut() async {
    if (await isLogin() != null) {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      prefs.remove('userInfo');
      Navigator.pop(context, true);
    } else {
      Navigator.pop(context);
      Navigator.push(
        context,
        new CupertinoPageRoute(
          fullscreenDialog: true,
          builder: (context) => new Login(),
        ),
      );
    }
   
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: MediaQuery.removePadding(
        context: context,
        // removeTop: true,
        child: Column(
          textDirection: TextDirection.ltr,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              height: 250.0,
              child: DrawerHeader(
                decoration: BoxDecoration(
                  color: Colors.black45,
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage("assets/images/logo.png"),
                  ),
                ),
                child: null,
              ),
            ),
            Expanded(
              child: ListView(
                children: <Widget>[
                  ListTile(
                    leading: Icon(!login? Icons.person : Icons.exit_to_app),
                    title: Text(login? '退出' : '登录'),
                    onTap: _signInOut,
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
