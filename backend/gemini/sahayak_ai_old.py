from google import genai
from google.genai import types
import time
import random
from typing import Optional
import datetime

class SahayakAI:
    def __init__(self):
        """Initialize the Gemini client"""
        # Initialize client with Vertex AI
        self.client = genai.Client(
            vertexai=True,
            project="sahayak-mvp-466309",
            location="us-central1"
        )
        self.model = "gemini-2.0-flash-exp"
        
        # Rate limiting based on your quota (10 requests per minute)
        self.requests_per_minute = 10
        self.min_delay_between_requests = 60 / self.requests_per_minute  # 6 seconds
        self.last_request_time = 0
        
        # Request tracking
        self.request_count = 0
        self.request_log = []
        self.start_time = datetime.datetime.now()
        
        # System instruction for the teaching assistant
        self.system_instruction = """You are an AI teaching assistant for rural Indian schools, helping teachers create educational content for multi-grade classrooms. You specialize in:
        - Creating content in local languages (Hindi, Marathi, etc.)
        - Generating grade-appropriate worksheets
        - Explaining concepts using rural Indian contexts
        - Creating simple visual descriptions for blackboard drawing
        Always use simple language and culturally relevant examples."""
        
    def _get_config(self):
        """Get generation configuration"""
        return types.GenerateContentConfig(
            temperature=0.7,
            top_p=0.95,
            max_output_tokens=8000,
            safety_settings=[
                types.SafetySetting(
                    category="HARM_CATEGORY_HATE_SPEECH",
                    threshold="OFF"
                ),
                types.SafetySetting(
                    category="HARM_CATEGORY_DANGEROUS_CONTENT",
                    threshold="OFF"
                ),
                types.SafetySetting(
                    category="HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    threshold="OFF"
                ),
                types.SafetySetting(
                    category="HARM_CATEGORY_HARASSMENT",
                    threshold="OFF"
                )
            ],
            system_instruction=[types.Part.from_text(text=self.system_instruction)]
        )
    
    def _wait_if_needed(self):
        """Implement rate limiting to stay within quota"""
        current_time = time.time()
        time_since_last_request = current_time - self.last_request_time
        
        if time_since_last_request < self.min_delay_between_requests:
            sleep_time = self.min_delay_between_requests - time_since_last_request
            print(f"Rate limiting: waiting {sleep_time:.1f} seconds...")
            time.sleep(sleep_time)
        
        self.last_request_time = time.time()
    
    def get_usage_stats(self):
        """Get current usage statistics"""
        runtime = datetime.datetime.now() - self.start_time
        runtime_seconds = runtime.total_seconds()
        return {
            "total_requests": self.request_count,
            "runtime_minutes": runtime_seconds / 60,
            "requests_per_minute": self.request_count / (runtime_seconds / 60) if runtime_seconds > 0 else 0,
            "quota_limit": self.requests_per_minute,
            "quota_usage_percent": (self.request_count / (runtime_seconds / 60) / self.requests_per_minute * 100) if runtime_seconds > 0 else 0,
            "last_requests": self.request_log[-5:]  # Last 5 requests
        }
    
    def _generate_with_retry(self, contents, max_retries=3):
        """Generate content with retry logic for rate limiting"""
        # Track request
        self.request_count += 1
        self.request_log.append({
            "timestamp": datetime.datetime.now().isoformat(),
            "request_number": self.request_count
        })
        
        for attempt in range(max_retries):
            try:
                # Wait if needed to respect rate limits
                self._wait_if_needed()
                
                print(f"Making request #{self.request_count} (attempt {attempt + 1}/{max_retries})")
                
                response = self.client.models.generate_content(
                    model=self.model,
                    contents=contents,
                    config=self._get_config()
                )
                
                print(f"Request successful!")
                return response.text
                
            except Exception as e:
                error_str = str(e)
                print(f"Error on attempt {attempt + 1}: {error_str}")
                
                if "429" in error_str or "RESOURCE_EXHAUSTED" in error_str:
                    if attempt < max_retries - 1:
                        # Exponential backoff with jitter
                        wait_time = (2 ** (attempt + 1)) * self.min_delay_between_requests + random.uniform(0, 2)
                        print(f"Rate limit hit. Waiting {wait_time:.1f} seconds before retry...")
                        time.sleep(wait_time)
                        continue
                    else:
                        raise Exception(f"Rate limit exceeded after {max_retries} attempts. Please wait a minute and try again.")
                else:
                    raise Exception(f"Error generating content: {error_str}")
        
        raise Exception("Max retries exceeded")
    
    def generate_story(self, language, grade, topic, context):
        """Generate educational story in local language"""
        prompt = f"""Create a short educational story in {language} for grade {grade} students about {topic}. 
        The story should:
        - Be 150-200 words
        - Include a farmer or village character
        - Use simple vocabulary appropriate for grade {grade}
        - Include local context from {context}
        - Have a clear educational message"""
        
        contents = [
            types.Content(
                role="user",
                parts=[types.Part.from_text(text=prompt)]
            )
        ]
        
        return self._generate_with_retry(contents)
    
    def create_worksheet_from_image(self, image_data, grades):
        """Create differentiated worksheets from textbook image"""
        prompt = f"""Look at this textbook page and create differentiated worksheets for grades: {', '.join(map(str, grades))}.
        
        For each grade, create:
        - 3-5 questions appropriate for their level
        - Include fill-in-the-blanks, multiple choice, and short answer questions
        - Make questions progressively harder for higher grades
        - Use simple English that rural Indian students can understand"""
        
        # Decode base64 image if it's a string
        if isinstance(image_data, str):
            import base64
            image_bytes = base64.b64decode(image_data)
        else:
            image_bytes = image_data
            
        contents = [
            types.Content(
                role="user",
                parts=[
                    types.Part.from_bytes(
                        data=image_bytes,
                        mime_type="image/jpeg"
                    ),
                    types.Part.from_text(text=prompt)
                ]
            )
        ]
        
        return self._generate_with_retry(contents)
    
    def explain_concept(self, question, language, grade_level):
        """Explain concepts using rural analogies"""
        prompt = f"""A grade {grade_level} student asks: "{question}"
        
        Explain this in {language} using:
        - A simple analogy from village/rural life
        - Examples they can relate to (farming, nature, daily village activities)
        - Keep it under 100 words
        - Make it memorable and easy to understand"""
        
        contents = [
            types.Content(
                role="user",
                parts=[types.Part.from_text(text=prompt)]
            )
        ]
        
        return self._generate_with_retry(contents)
    
    def create_visual_aid(self, concept, drawing_medium="blackboard"):
        """Create simple visual aid descriptions"""
        prompt = f"""Create simple {drawing_medium} drawing instructions for teaching the concept: {concept}.
        
        Provide:
        1. Step-by-step drawing instructions using basic shapes (circles, lines, squares)
        2. Each step should be completable in 30 seconds
        3. Labels in both English and Hindi/local language
        4. Tips for making it colorful and memorable
        5. Total drawing time should not exceed 5 minutes
        
        Format as clear, numbered steps."""
        
        contents = [
            types.Content(
                role="user",
                parts=[types.Part.from_text(text=prompt)]
            )
        ]
        
        return self._generate_with_retry(contents)
    
    def generate_audio_assessment(self, text, language, grade_level):
        """Generate reading assessment criteria"""
        prompt = f"""Create a reading assessment for grade {grade_level} students reading this text in {language}:
        
        Text: "{text}"
        
        Provide:
        1. Key words to check for pronunciation
        2. Expected reading speed (words per minute)
        3. Common mistakes to watch for
        4. Encouraging feedback suggestions in {language}
        5. Simple scoring rubric (1-5 scale)"""
        
        contents = [
            types.Content(
                role="user",
                parts=[types.Part.from_text(text=prompt)]
            )
        ]
        
        return self._generate_with_retry(contents)