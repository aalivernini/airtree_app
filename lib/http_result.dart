class HttpResult {
    final String msg;
    final int statusCode;
    Map<String, dynamic> data;

    HttpResult(this.msg, this.statusCode, {this.data = const {}});
}

