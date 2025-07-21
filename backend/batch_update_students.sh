#!/bin/bash
# Save as batch_update_students.sh

STUDENTS=("student001" "student002" "student003" "student004" "student005")

for STUDENT in "${STUDENTS[@]}"; do
  echo "Updating $STUDENT..."
  curl -s -X POST "$BASE_URL/analytics/student-progress" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $AUTH_TOKEN" \
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