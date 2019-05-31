/*
 * @Author: qiuz
 * @Github: <https://github.com/qiuziz>
 * @Date: 2019-05-23 10:47:44
 * @Last Modified by: qiuz
 * @Last Modified time: 2019-05-29 17:39:48
 */

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_h5/net/http-utils.dart';
import 'package:flutter_h5/net/resource-api.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class Login extends StatefulWidget {
  @override
  _LoginState createState() => new _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController _usernameController = new TextEditingController();
  TextEditingController _pwdController = new TextEditingController();
  GlobalKey _formKey = new GlobalKey<FormState>();

  FocusNode focusNode1 = new FocusNode();
  FocusNode focusNode2 = new FocusNode();
  FocusScopeNode focusScopeNode;

  var _loading = false;
  @override
  void initState() {
    super.initState();
  }

  void save(Map<String, dynamic> userInfo) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('userInfo', json.encode(userInfo));
  }

  void login() {
    if (_loading) return;
    setState(() {
      _loading = true;
    });
    focusNode1.unfocus();
    focusNode2.unfocus();
    HttpUtil.post(ResourceApi.LOGIN, {'username': _usernameController.text, 'password': _pwdController.text}, (result)  async {
       setState(() {
        _loading = false;
      });
      var data = result['data'];
      save(data);
      Navigator.pop(context, true);
    }, errorCallback: (error) {
      setState(() {
        _loading = false;
      });
      Fluttertoast.showToast(
        msg: error,
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.CENTER,
        timeInSecForIos: 1,
        backgroundColor: Colors.black54,
        textColor: Colors.white,
        fontSize: 16.0
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
      ),
      resizeToAvoidBottomPadding: false,
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        child: Form(
          key: _formKey,
          autovalidate: true,
          child: Column(
            children: <Widget>[
              Image.asset('assets/images/logo.png', width: 100.0,),
              // ClipOval(
              //    child: Image.asset('assets/images/logo.png', width: 150.0,),
              // ),
              Container(
                child: TextFormField(
                  controller: _usernameController,
                  focusNode: focusNode1,
                  decoration: InputDecoration(
                    labelText: '用户名',
                    hintText: '请输入用户名',
                    prefixIcon: Icon(Icons.person, color: Colors.black,),
                    border: InputBorder.none
                  ),
                  validator: (v) {
                    return v
                      .trim()
                      .length > 0 ? null : '用户名不能为空';
                  },
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[700], width: 1.0))
                ),
              ),
              Container(
                child: TextFormField(
                  controller: _pwdController,
                  focusNode: focusNode2,
                  decoration: InputDecoration(
                  labelText: '密码',
                  hintText: '请输入登录密码',
                  prefixIcon: Icon(Icons.lock, color: Colors.black,),
                  border: InputBorder.none
                ),
                obscureText: true,
                validator: (v) {
                  return v.trim().length > 5 ? null : '密码不能少于6位';
                },
                ),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.grey[700], width: 1.0))
                ),
              ),
              
              Padding(
                padding: const EdgeInsets.only(top: 28.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: RaisedButton(
                        padding: EdgeInsets.all(10.0),
                        child: _loading
                          ? Container(
                              alignment: Alignment.center,
                              child: SizedBox(
                                width: 24.0,
                                height: 24.0,
                                child: CircularProgressIndicator(strokeWidth: 2.0, backgroundColor: Colors.transparent, valueColor: new AlwaysStoppedAnimation<Color>(Colors.white),),
                              ),
                            )
                           : Text('登录'),
                        color: Colors.red,
                        textColor: Colors.white,
                        onPressed: login,
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
      
    );
  }
}


