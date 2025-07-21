#!/bin/bash
# Save as test_all_gets.sh

echo "Testing Health..."
curl -s "$BASE_URL/health" | jq .

echo -e "\nTesting Languages..."
curl -s "$BASE_URL/languages" | jq .

echo -e "\nTesting Subjects..."
curl -s "$BASE_URL/subjects" | jq .

echo -e "\nTesting Game Types..."
curl -s "$BASE_URL/game-types" | jq .

echo -e "\nTesting Parent Templates..."
curl -s "$BASE_URL/parent-communication/templates" | jq .

echo -e "\nTesting Student Progress..."
curl -s "$BASE_URL/analytics/student-progress?student_id=$STUDENT_ID" \
  -H "Authorization: Bearer $AUTH_TOKEN" | jq .

echo -e "\nTesting Class Dashboard..."
curl -s "$BASE_URL/analytics/class-dashboard?class_id=$CLASS_ID" \
  -H "Authorization: Bearer $AUTH_TOKEN" | jq .