import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:zia/constants/secrets.dart';

class OpenAPIService {
  final List<Map<String, String>> messages = [];
  Future<String> isArtPromptAPI(String prompt) async {
    print("promt:${prompt}");
    try {
      final res = await http.post(
          Uri.parse("https://api.openai.com/v1/chat/completions"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $openAIAPIKEY"
          },
          body: jsonEncode({
            "model": "gpt-3.5-turbo",
            "messages": [
              {
                "role": "user",
                "content":
                    'Does this message want generate an AI picture, image, art or anything similar? -> $prompt, simily answer with a yer or no.'
              }
            ]
          }));
      print(res.body);
      if (res.statusCode == 200) {
        String content =
            jsonDecode(res.body)['choices'][0]['message']['content'];
        content = content.trim();
        content = content.replaceAll(".", '');
        content = content.toLowerCase();

        switch (content) {
          case 'yes':
            final res = await dallEAPT(prompt);

            return res;
          default:
            final res = await chatGPTAPI(prompt);
            return res;
        }
      }
      return 'Internal Error';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> chatGPTAPI(String prompt) async {
    messages.add({'role': 'user', 'content': prompt});
    try {
      final res = await http.post(
          Uri.parse("https://api.openai.com/v1/chat/completions"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $openAIAPIKEY"
          },
          body: jsonEncode({"model": "gpt-3.5-turbo", "messages": messages}));
      if (res.statusCode == 200) {
        String content =
            jsonDecode(res.body)['choices'][0]['message']['content'];
        content = content.trim();

        messages.add({'role': 'assistant', "content": content});
        return content;
      }
      return 'Internal Error';
    } catch (e) {
      return e.toString();
    }
  }

  Future<String> dallEAPT(String prompt) async {
    messages.add({'role': 'user', 'content': prompt});
    try {
      final res = await http.post(
          Uri.parse("https://api.openai.com/v1/images/generations"),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $openAIAPIKEY"
          },
          body: jsonEncode({'prompt': prompt, 'n': 1}));
      if (res.statusCode == 200) {
        String imageUrl = jsonDecode(res.body)['data'][0]['url'];
       

        messages.add({'role': 'assistant', "content": imageUrl});
        return imageUrl;
      }
      return 'Internal Error';
    } catch (e) {
      return e.toString();
    }
  }
}
