#!/bin/bash
# Save as create_complete_lesson.sh

echo "1. Creating story..."
STORY_RESPONSE=$(curl -s -X POST "$BASE_URL/generate-story" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -d '{
    "language": "Hindi",
    "grade": 3,
    "topic": "Water Conservation",
    "context": "Village life",
    "save_to_library": true
  }')
echo "Story created!"

sleep 7

echo "2. Creating visual aid..."
curl -s -X POST "$BASE_URL/create-visual-aid" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -d '{
    "concept": "Water Cycle",
    "drawing_medium": "blackboard"
  }' > /dev/null
echo "Visual aid created!"

sleep 7

echo "3. Creating game..."
curl -s -X POST "$BASE_URL/generate-game" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $AUTH_TOKEN" \
  -d '{
    "game_type": "memory_game",
    "topic": "Water Conservation",
    "grade": 3,
    "language": "Hindi"
  }' > /dev/null
echo "Game created!"

echo "Complete lesson created successfully!"