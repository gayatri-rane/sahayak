# Sahayak API - cURL Commands with Variables

## SET THESE VARIABLES FIRST
```bash
# Set in your terminal
export BASE_URL="http://localhost:5000"
export AUTH_TOKEN="test-token-123"
```

## 1. HEALTH & STATUS

### Health Check
```bash
curl -X GET "{{BASE_URL}}/health" \
  -H "Content-Type: application/json"
```

---

## 2. CONTENT GENERATION

### Generate Story
```bash
curl -X POST "{{BASE_URL}}/generate-story" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "language": "Hindi",
    "grade": 3,
    "topic": "Water Conservation",
    "context": "Rural village in Maharashtra",
    "save_to_library": true,
    "teacher_id": "teacher123"
  }'
```

### Create Worksheet from Image
```bash
curl -X POST "{{BASE_URL}}/create-worksheet" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "image": "data:image/jpeg;base64,/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAMCAgICAgMCAgIDAwMDBAYEBAQEBAgGBgUGCQgKCgkICQkKDA8MCgsOCwkJDRENDg8QEBEQCgwSExIQEw8QEBD/yQALCAABAAEBAREA/8wABgAQEAX/2gAIAQEAAD8A0s8g/9k=",
    "grades": [2, 3, 4]
  }'
```

### Explain Concept
```bash
curl -X POST "{{BASE_URL}}/explain-concept" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "question": "Why does it rain?",
    "language": "Hindi",
    "grade_level": 4
  }'
```

### Create Visual Aid
```bash
curl -X POST "{{BASE_URL}}/create-visual-aid" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "concept": "Water Cycle",
    "drawing_medium": "blackboard"
  }'
```

---

## 3. AUDIO & ASSESSMENT

### Generate Audio Assessment
```bash
curl -X POST "{{BASE_URL}}/audio-assessment" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "text": "The farmer went to the market to sell vegetables.",
    "language": "English",
    "grade_level": 3,
    "student_id": "student456"
  }'
```

### Speech to Text
```bash
curl -X POST "{{BASE_URL}}/speech-to-text" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -F "audio=@audio_file.mp3" \
  -F "language=Hindi"
```

---

## 4. EDUCATIONAL GAMES

### Generate Vocabulary Bingo
```bash
curl -X POST "{{BASE_URL}}/generate-game" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "game_type": "vocabulary_bingo",
    "topic": "Animals",
    "grade": 2,
    "language": "Marathi"
  }'
```

### Generate Math Puzzle
```bash
curl -X POST "{{BASE_URL}}/generate-game" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "game_type": "math_puzzle",
    "topic": "Addition and Subtraction",
    "grade": 3,
    "language": "Hindi"
  }'
```

### Generate Science Quiz
```bash
curl -X POST "{{BASE_URL}}/generate-game" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "game_type": "science_quiz",
    "topic": "Plants and Trees",
    "grade": 4,
    "language": "Telugu"
  }'
```

### Generate Memory Game
```bash
curl -X POST "{{BASE_URL}}/generate-game" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "game_type": "memory_game",
    "topic": "Shapes and Colors",
    "grade": 1,
    "language": "Hindi"
  }'
```

---

## 5. LESSON PLANNING

### Create Weekly Lesson Plan
```bash
curl -X POST "{{BASE_URL}}/create-lesson-plan" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "grades": [2, 3, 4],
    "subjects": ["Mathematics", "Science", "Language"],
    "weekly_goals": "Teach addition/subtraction, introduce plant life cycle, improve reading fluency",
    "duration": "week",
    "language": "Hindi",
    "save": true,
    "teacher_id": "teacher123"
  }'
```

### Create Daily Lesson Plan
```bash
curl -X POST "{{BASE_URL}}/create-lesson-plan" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "grades": [3],
    "subjects": ["Environmental Studies"],
    "weekly_goals": "Learn about local birds and animals",
    "duration": "day",
    "language": "Kannada",
    "save": false
  }'
```

---

## 6. COMMUNITY LIBRARY

### Share Worksheet Resource
```bash
curl -X POST "{{BASE_URL}}/resources/share" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "type": "worksheet",
    "content": "Math Worksheet:\n1. 5 + 3 = ?\n2. 10 - 4 = ?\n3. 2 x 3 = ?",
    "metadata": {
      "grades": [3, 4],
      "subject": "Mathematics",
      "language": "Hindi",
      "topic": "Basic Operations"
    },
    "teacher_id": "teacher123"
  }'
```

### Search Resources (Simple)
```bash
curl -X GET "{{BASE_URL}}/resources/search?query=math" \
  -H "Content-Type: application/json"
```

### Search Resources (With All Filters)
```bash
curl -X GET "{{BASE_URL}}/resources/search?query=multiplication&grade=3&subject=Mathematics&language=Hindi&type=worksheet" \
  -H "Content-Type: application/json"
```

### Get Specific Resource
```bash
# Set resource ID first
export RESOURCE_ID="abc123"

curl -X GET "{{BASE_URL}}/resources/$RESOURCE_ID" \
  -H "Content-Type: application/json"
```

### Remix Resource
```bash
curl -X POST "{{BASE_URL}}/resources/$RESOURCE_ID/remix" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "content": "Modified Math Worksheet with local examples:\n1. Ram has 5 mangoes, Sita gives him 3 more. How many mangoes?",
    "metadata": {
      "grades": [3],
      "modifications": "Added local context with Indian names and mangoes"
    },
    "teacher_id": "teacher789"
  }'
```

### Rate Resource
```bash
curl -X POST "{{BASE_URL}}/resources/$RESOURCE_ID/rate" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "rating": 5,
    "feedback": "Excellent resource! Students loved the local examples.",
    "teacher_id": "teacher123"
  }'
```

---

## 7. ANALYTICS

### Get Student Progress
```bash
# Set student ID
export STUDENT_ID="student456"

curl -X GET "{{BASE_URL}}/analytics/student-progress?student_id=$STUDENT_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}"
```

### Update Student Progress (Full)
```bash
curl -X POST "{{BASE_URL}}/analytics/student-progress" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "student_id": "'$STUDENT_ID'",
    "assessment": {
      "type": "reading",
      "score": 85,
      "notes": "Good fluency, needs work on comprehension"
    },
    "activity_completed": true,
    "reading_level": "Grade Level",
    "strengths": ["Mathematics", "Creative Writing"],
    "areas_for_improvement": ["Science Concepts", "English Grammar"]
  }'
```

### Get Class Dashboard
```bash
# Set class ID
export CLASS_ID="class_3A"

curl -X GET "{{BASE_URL}}/analytics/class-dashboard?class_id=$CLASS_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}"
```

### Get Intervention Suggestions
```bash
curl -X GET "{{BASE_URL}}/analytics/intervention-suggestions?class_id=$CLASS_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}"
```

---

## 8. PARENT COMMUNICATION

### Send Progress Report
```bash
curl -X POST "{{BASE_URL}}/parent-communication/send" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "phone": "+919876543210",
    "type": "progress_report",
    "content": "आपका बेटा राज आज गणित में बहुत अच्छा कर रहा है। उसने सभी सवाल सही किए।",
    "student_name": "Raj Kumar"
  }'
```

### Send Homework Reminder
```bash
curl -X POST "{{BASE_URL}}/parent-communication/send" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "phone": "+919876543211",
    "type": "homework",
    "content": "नमस्ते! कृपया सुनिश्चित करें कि प्रिया अपना विज्ञान का होमवर्क पूरा करे।",
    "student_name": "Priya Sharma"
  }'
```

### Get Parent Templates
```bash
curl -X GET "{{BASE_URL}}/parent-communication/templates" \
  -H "Content-Type: application/json"
```

---

## 9. OFFLINE SUPPORT

### Sync Offline Data
```bash
curl -X POST "{{BASE_URL}}/offline/sync" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "offline_data": [
      {
        "type": "resource",
        "data": {
          "type": "worksheet",
          "content": "Offline created math worksheet with 10 problems",
          "metadata": {
            "created_offline": true,
            "timestamp": "2024-01-15T10:30:00Z",
            "grades": [3],
            "subject": "Mathematics"
          }
        }
      },
      {
        "type": "progress",
        "data": {
          "student_id": "student001",
          "activities_completed": 5,
          "offline_assessments": [
            {
              "date": "2024-01-15",
              "score": 92,
              "subject": "Mathematics"
            }
          ]
        }
      }
    ]
  }'
```

### Download Offline Pack
```bash
curl -X GET "{{BASE_URL}}/offline/download-pack?grade=3&subjects=Mathematics&subjects=Science" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}"
```

---

## 10. USER SESSIONS

### Set Classroom Context
```bash
# Set teacher ID
export TEACHER_ID="teacher123"

curl -X POST "{{BASE_URL}}/session/classroom-context" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "teacher_id": "'$TEACHER_ID'",
    "grades": [2, 3, 4],
    "subjects": ["Mathematics", "Science", "Hindi", "English"],
    "language": "Hindi",
    "total_students": 35,
    "resources": ["blackboard", "chalk", "basic_textbooks", "some_charts"]
  }'
```

### Get Classroom Context
```bash
curl -X GET "{{BASE_URL}}/session/classroom-context?teacher_id=$TEACHER_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}"
```

---

## 11. UTILITIES

### Get Supported Languages
```bash
curl -X GET "{{BASE_URL}}/languages" \
  -H "Content-Type: application/json"
```

### Get Subjects
```bash
curl -X GET "{{BASE_URL}}/subjects" \
  -H "Content-Type: application/json"
```

### Get Game Types
```bash
curl -X GET "{{BASE_URL}}/game-types" \
  -H "Content-Type: application/json"
```

---

## HELPFUL SCRIPTS

### Set All Variables at Once
```bash
# Save as setup_env.sh
#!/bin/bash

export BASE_URL="http://localhost:5000"
export AUTH_TOKEN="test-token-123"
export TEACHER_ID="teacher123"
export STUDENT_ID="student456"
export CLASS_ID="class_3A"
export RESOURCE_ID="abc123"

echo "Environment variables set:"
echo "BASE_URL={{BASE_URL}}"
echo "AUTH_TOKEN={{AUTH_TOKEN}}"
echo "TEACHER_ID=$TEACHER_ID"
echo "STUDENT_ID=$STUDENT_ID"
echo "CLASS_ID=$CLASS_ID"
echo "RESOURCE_ID=$RESOURCE_ID"
```

### Test All GET Endpoints
```bash
#!/bin/bash
# Save as test_all_gets.sh

echo "Testing Health..."
curl -s "{{BASE_URL}}/health" | jq .

echo -e "\nTesting Languages..."
curl -s "{{BASE_URL}}/languages" | jq .

echo -e "\nTesting Subjects..."
curl -s "{{BASE_URL}}/subjects" | jq .

echo -e "\nTesting Game Types..."
curl -s "{{BASE_URL}}/game-types" | jq .

echo -e "\nTesting Parent Templates..."
curl -s "{{BASE_URL}}/parent-communication/templates" | jq .

echo -e "\nTesting Student Progress..."
curl -s "{{BASE_URL}}/analytics/student-progress?student_id=$STUDENT_ID" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" | jq .

echo -e "\nTesting Class Dashboard..."
curl -s "{{BASE_URL}}/analytics/class-dashboard?class_id=$CLASS_ID" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" | jq .
```

### Batch Update Students
```bash
#!/bin/bash
# Save as batch_update_students.sh

STUDENTS=("student001" "student002" "student003" "student004" "student005")

for STUDENT in "${STUDENTS[@]}"; do
  echo "Updating $STUDENT..."
  curl -s -X POST "{{BASE_URL}}/analytics/student-progress" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer {{AUTH_TOKEN}}" \
    -d '{
      "student_id": "'$STUDENT'",
      "activity_completed": true,
      "assessment": {
        "type": "worksheet",
        "score": '$((RANDOM % 31 + 70))',
        "date": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'"
      }
    }' | jq -c .
  sleep 1
done
```

### Create Complete Lesson
```bash
#!/bin/bash
# Save as create_complete_lesson.sh

echo "1. Creating story..."
STORY_RESPONSE=$(curl -s -X POST "{{BASE_URL}}/generate-story" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
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
curl -s -X POST "{{BASE_URL}}/create-visual-aid" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "concept": "Water Cycle",
    "drawing_medium": "blackboard"
  }' > /dev/null
echo "Visual aid created!"

sleep 7

echo "3. Creating game..."
curl -s -X POST "{{BASE_URL}}/generate-game" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer {{AUTH_TOKEN}}" \
  -d '{
    "game_type": "memory_game",
    "topic": "Water Conservation",
    "grade": 3,
    "language": "Hindi"
  }' > /dev/null
echo "Game created!"

echo "Complete lesson created successfully!"
```