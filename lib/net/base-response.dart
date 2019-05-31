/*
 * @Author: qiuz
 * @Github: <https://github.com/qiuziz>
 * @Date: 2019-04-23 17:35:34
 * @Last Modified by: qiuz
 * @Last Modified time: 2019-04-23 17:35:34
 */

/*{
"data": ...,
"errorCode": 0,
"errorMsg": ""
}*/

class GitClubResp<T> {

  int code;

  String msg;

  T data;

  GitClubResp({this.code, this.msg, this.data});

  factory GitClubResp.fromJson(Map<String, dynamic> json) {
    return new GitClubResp(
        code: json['code'],
        msg: json['msg'],
        data: json['data']
    );
  }
}
