from gemini.sahayak_ai import SahayakAI
import time

def test_all_features():
    """Test all Sahayak AI features with delays to avoid rate limiting"""
    try:
        # Initialize AI
        print("Initializing Sahayak AI...")
        ai = SahayakAI()
        print("✅ Successfully initialized!\n")
        
        # Test 1: Story Generation
        print("=== Test 1: Story Generation ===")
        story = ai.generate_story(
            language="Hindi",
            grade="3",
            topic="water conservation",
            context="Rajasthan village with water scarcity"
        )
        print(story)
        print("\n" + "="*50 + "\n")
        
        # Add delay to avoid rate limiting
        print("Waiting 5 seconds before next request...")
        time.sleep(5)
        
        # Test 2: Concept Explanation
        print("=== Test 2: Concept Explanation ===")
        explanation = ai.explain_concept(
            question="Why do plants need sunlight?",
            language="Hindi",
            grade_level="4"
        )
        print(explanation)
        print("\n" + "="*50 + "\n")
        
        # Add delay
        print("Waiting 5 seconds before next request...")
        time.sleep(5)
        
        # Test 3: Visual Aid
        print("=== Test 3: Visual Aid Creation ===")
        visual = ai.create_visual_aid(
            concept="water cycle",
            drawing_medium="blackboard"
        )
        print(visual)
        print("\n" + "="*50 + "\n")
        
        # Add delay
        print("Waiting 5 seconds before next request...")
        time.sleep(5)
        
        # Test 4: Audio Assessment
        print("=== Test 4: Reading Assessment ===")
        assessment = ai.generate_audio_assessment(
            text="The sun rises in the east every morning.",
            language="English",
            grade_level="2"
        )
        print(assessment)
        
        print("\n✅ All tests completed successfully!")
        
    except Exception as e:
        print(f"❌ Error occurred: {str(e)}")
        print("\nTroubleshooting:")
        print("1. Make sure you ran: gcloud auth application-default login")
        print("2. Check if Vertex AI API is enabled in your project")
        print("3. Verify project ID is correct: sahayak-mvp-466309")

def test_single_feature():
    """Test a single feature to check if everything is working"""
    try:
        print("Testing story generation only...")
        ai = SahayakAI()
        
        story = ai.generate_story(
            language="Marathi",
            grade="4",
            topic="importance of trees",
            context="Maharashtra village"
        )
        
        print("Generated Story:")
        print(story)
        print("\n✅ Test successful!")
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")

if __name__ == "__main__":
    # Test single feature first
    test_single_feature()
    
    # Uncomment to test all features
    # print("\n" + "="*50 + "\n")
    # test_all_features()