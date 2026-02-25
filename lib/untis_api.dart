import 'dart:convert';
import 'package:http/http.dart' as http;

class UntisApi {
  String? sessionId;
  String schoolUrl;
  String schoolName;

  UntisApi({required this.schoolUrl, required this.schoolName});

  // 1. Einloggen
  Future<bool> login(String user, String password) async {
    final url = Uri.parse('https://$schoolUrl/WebUntis/jsonrpc.do?school=$schoolName');
    
    final response = await http.post(url, body: jsonEncode({
      "id": "login_1",
      "method": "authenticate",
      "params": {"user": user, "password": password, "client": "UntisPlus"},
      "jsonrpc": "2.0"
    }));

    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['result'] != null) {
        sessionId = data['result']['sessionId'];
        return true;
      }
    }
    return false;
  }
}