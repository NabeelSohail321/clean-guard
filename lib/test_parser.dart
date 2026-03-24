import 'dart:convert';
import 'package:mobile_app/models/inspection.dart';

void main() {
  final jsonString = '''
  {
    "template": "60d5ec49f1b2c8001594g456",
    "location": "60d5ec49f1b2c8001594g789",
    "inspector": "60d5ec49f1b2c8001594g111",
    "status": "completed",
    "score": 85,
    "totalScore": 85,
    "sections": [
      {
        "name": "General Cleanliness",
        "items": [
          {
            "itemId": "60d5ec49f1b2c8001594g333",
            "name": "Floors",
            "type": "pass_fail",
            "score": 1,
            "status": "pass",
            "_id": "60d5ec49f1b2c8001594g333"
          }
        ],
        "subsections": [
          {
            "name": "Break Room",
            "items": [],
            "_id": "60d5ec49f1b2c8001594g444"
          }
        ],
        "_id": "60d5ec49f1b2c8001594g222"
      }
    ],
    "_id": "60d5ec49f1b2c8001594g123",
    "createdAt": "2023-01-01T00:00:00Z",
    "updatedAt": "2023-01-01T00:00:00Z",
    "__v": 0
  }
  ''';

  try {
    final Map<String, dynamic> json = jsonDecode(jsonString);
    final inspection = Inspection.fromJson(json);
    print('Parsed successfully: \${inspection.id}');
  } catch (e, stack) {
    print('Error: $e');
    print(stack);
  }
}
