import google.generativeai as genai
import time
import random
from typing import Optional, List, Dict, Any
import datetime
import base64
import os

class SahayakAI:
    def __init__(self):
        """Initialize the Gemini client"""
        # Configure API with your key
        api_key = os.environ.get('GEMINI_API_KEY', 'AIzaSyCq4h2kDkAHRC0DrUCtpGf7X83s2fLBf8Y')
        genai.configure(api_key=api_key)
        
        # Initialize the model
        self.model = genai.GenerativeModel(
            model_name='gemini-1.5-flash',
            generation_config={
                'temperature': 0.7,
                'top_p': 0.95,
                'top_k': 40,
                'max_output_tokens': 8000,
            },
            safety_settings=[
                {
                    "category": "HARM_CATEGORY_HARASSMENT",
                    "threshold": "BLOCK_NONE"
                },
                {
                    "category": "HARM_CATEGORY_HATE_SPEECH",
                    "threshold": "BLOCK_NONE"
                },
                {
                    "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
                    "threshold": "BLOCK_NONE"
                },
                {
                    "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
                    "threshold": "BLOCK_NONE"
                }
            ]
        )
        
        # System instruction
        self.system_instruction = """You are an AI teaching assistant for rural Indian schools, helping teachers create educational content for multi-grade classrooms. You specialize in:
        - Creating content in local languages (Hindi, Marathi, etc.)
        - Generating grade-appropriate worksheets
        - Explaining concepts using rural Indian contexts
        - Creating simple visual descriptions for blackboard drawing
        - Designing educational games and activities
        - Creating lesson plans for multi-grade classrooms
        - Generating assessment criteria and rubrics
        Always use simple language and culturally relevant examples from rural Indian life."""
        
        # Rate limiting based on your quota (10 requests per minute)
        self.requests_per_minute = 10
        self.min_delay_between_requests = 60 / self.requests_per_minute  # 6 seconds
        self.last_request_time = 0
        
        # Request tracking
        self.request_count = 0
        self.request_log = []
        self.start_time = datetime.datetime.now()
    
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
    
    def _generate_with_retry(self, prompt_text, image_data=None, max_retries=3):
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
                
                # Add system instruction to prompt
                full_prompt = f"{self.system_instruction}\n\n{prompt_text}"
                
                # Generate content
                if image_data:
                    # For image-based generation
                    import PIL.Image
                    import io
                    image = PIL.Image.open(io.BytesIO(image_data))
                    response = self.model.generate_content([full_prompt, image])
                else:
                    # For text-only generation
                    response = self.model.generate_content(full_prompt)
                
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
    
    def generate_story(self, language: str, grade: int, topic: str, context: str) -> str:
        """Generate educational story in local language"""
        prompt = f"""Create a short educational story in {language} for grade {grade} students about {topic}. 
        The story should:
        - Be 150-200 words
        - Include a farmer or village character
        - Use simple vocabulary appropriate for grade {grade}
        - Include local context from {context}
        - Have a clear educational message
        - End with a moral or learning point"""
        
        return self._generate_with_retry(prompt)
    
    def create_worksheet_from_image(self, image_data: str, grades: List[int]) -> str:
        """Create differentiated worksheets from textbook image"""
        prompt = f"""Look at this textbook page and create differentiated worksheets for grades: {', '.join(map(str, grades))}.
        
        For each grade, create:
        - 3-5 questions appropriate for their level
        - Include fill-in-the-blanks, multiple choice, and short answer questions
        - Make questions progressively harder for higher grades
        - Use simple English that rural Indian students can understand
        - Add a fun activity or drawing exercise at the end"""
        
        # Decode base64 image if it's a string
        if isinstance(image_data, str):
            image_bytes = base64.b64decode(image_data)
        else:
            image_bytes = image_data
        
        return self._generate_with_retry(prompt, image_bytes)
    
    def explain_concept(self, question: str, language: str, grade_level: int) -> str:
        """Explain concepts using rural analogies"""
        prompt = f"""A grade {grade_level} student asks: "{question}"
        
        Explain this in {language} using:
        - A simple analogy from village/rural life
        - Examples they can relate to (farming, nature, daily village activities)
        - Keep it under 100 words
        - Make it memorable and easy to understand
        - Use story-telling if it helps"""
        
        return self._generate_with_retry(prompt)
    
    def create_visual_aid(self, concept: str, drawing_medium: str = "blackboard") -> str:
        """Create simple visual aid descriptions"""
        prompt = f"""Create simple {drawing_medium} drawing instructions for teaching the concept: {concept}.
        
        Provide:
        1. Step-by-step drawing instructions using basic shapes (circles, lines, squares)
        2. Each step should be completable in 30 seconds
        3. Labels in both English and Hindi/local language
        4. Tips for making it colorful and memorable
        5. Total drawing time should not exceed 5 minutes
        6. Alternative simpler version if students want to copy
        
        Format as clear, numbered steps."""
        
        return self._generate_with_retry(prompt)
    
    def generate_audio_assessment(self, text: str, language: str, grade_level: int) -> str:
        """Generate reading assessment criteria"""
        prompt = f"""Create a reading assessment for grade {grade_level} students reading this text in {language}:
        
        Text: "{text}"
        
        Provide:
        1. Key words to check for pronunciation
        2. Expected reading speed (words per minute)
        3. Common mistakes to watch for
        4. Encouraging feedback suggestions in {language}
        5. Simple scoring rubric (1-5 scale)
        6. Follow-up comprehension questions
        7. Tips for helping struggling readers"""
        
        return self._generate_with_retry(prompt)
    
    def generate_educational_game(self, game_type: str, topic: str, grade: int, language: str = "English") -> str:
        """Generate educational games like vocabulary bingo, math puzzles"""
        game_descriptions = {
            "vocabulary_bingo": "Vocabulary Bingo - a word recognition game",
            "math_puzzle": "Math Puzzle - number and calculation game",
            "science_quiz": "Science Quiz - question-based learning game",
            "memory_game": "Memory Game - matching pairs for better recall",
            "word_building": "Word Building - create words from letters",
            "number_race": "Number Race - competitive math practice",
            "story_sequence": "Story Sequencing - arrange events in order",
            "shape_hunt": "Shape Hunt - identify shapes in surroundings"
        }
        
        game_desc = game_descriptions.get(game_type, game_type)
        
        prompt = f"""Create a {game_desc} game for grade {grade} students about {topic} in {language}.
        
        Include:
        1. Clear game objective and learning goals
        2. Materials needed (use simple, locally available items like stones, sticks, chalk)
        3. Step-by-step instructions for teachers
        4. Game rules that are easy to understand
        5. Variations for different skill levels (easier and harder versions)
        6. Time duration (keep it within 15-20 minutes)
        7. How to assess learning through the game
        8. Tips for making it more engaging
        9. How to play with limited resources
        
        Make it suitable for rural Indian classroom with 20-40 students and minimal resources."""
        
        return self._generate_with_retry(prompt)
    
    def create_lesson_plan(self, weekly_goals: str, subjects: List[str], grades: List[int], 
                          duration: str = "week", language: str = "English") -> str:
        """Create structured, curriculum-aligned lesson plans"""
        prompt = f"""Create a detailed {duration} lesson plan for a multi-grade classroom with grades {', '.join(map(str, grades))}.
        
        Subjects to cover: {', '.join(subjects)}
        Weekly goals: {weekly_goals}
        
        Structure the plan with:
        1. Daily breakdown (Monday to Saturday - as per Indian schools)
        2. Time table with specific time slots (9 AM to 3 PM typical rural school timing)
        3. Grade-specific activities that can run simultaneously
        4. Common activities for all grades (assembly, lunch, games)
        5. Materials needed (focus on locally available/low-cost items)
        6. Quick assessment methods for each day
        7. Homework assignments (grade-appropriate, considering home environment)
        8. Tips for managing multi-grade instruction effectively
        9. Backup activities if main plan doesn't work
        10. Integration of local culture and examples
        
        Format in {language} and make it practical for rural Indian schools with limited resources."""
        
        return self._generate_with_retry(prompt)
    
    def generate_parent_message(self, message_type: str, student_name: str, 
                               details: Dict[str, Any], language: str = "Hindi") -> str:
        """Generate messages for parent communication"""
        templates = {
            "progress_report": f"Create a progress report message for {student_name}'s parents",
            "homework_reminder": f"Create a homework reminder for {student_name}'s parents",
            "achievement": f"Create an achievement celebration message for {student_name}",
            "attendance": f"Create an attendance-related message for {student_name}'s parents",
            "meeting_invite": f"Create a parent-teacher meeting invitation"
        }
        
        base_prompt = templates.get(message_type, f"Create a message for {student_name}'s parents")
        
        prompt = f"""{base_prompt} in {language}.
        
        Details: {details}
        
        The message should:
        1. Be respectful and warm (use appropriate greetings like Namaste)
        2. Be concise (suitable for WhatsApp - under 200 words)
        3. Use simple language that rural parents can understand
        4. Include specific actionable items if needed
        5. End with teacher's name and contact time
        6. Be encouraging and positive in tone
        
        Format for WhatsApp message."""
        
        return self._generate_with_retry(prompt)
    
    def generate_intervention_strategy(self, student_profile: Dict[str, Any], 
                                     areas_of_concern: List[str]) -> str:
        """Generate intervention strategies for struggling students"""
        prompt = f"""Create specific intervention strategies for a student with the following profile:
        
        Profile: {student_profile}
        Areas needing improvement: {', '.join(areas_of_concern)}
        
        Provide:
        1. 3-5 specific, actionable intervention strategies
        2. Each strategy should be implementable in a rural classroom
        3. Include peer learning opportunities
        4. Suggest simple activities using local materials
        5. Parent involvement ideas (considering rural parent literacy)
        6. Timeline for each intervention (daily/weekly)
        7. How to measure progress
        8. Motivational techniques suitable for the child
        9. Alternative approaches if first attempt doesn't work
        
        Keep strategies practical and resource-light."""
        
        return self._generate_with_retry(prompt)
    
    def create_offline_content_pack(self, grade: int, subjects: List[str], 
                                   pack_type: str = "weekly") -> str:
        """Generate content pack for offline use"""
        prompt = f"""Create a {pack_type} offline content pack for grade {grade} covering {', '.join(subjects)}.
        
        Include:
        1. Daily worksheets (printable format)
        2. Story reading materials
        3. Simple games and activities
        4. Parent guidance notes
        5. Self-assessment checklists for students
        6. Art and craft ideas using local materials
        7. Physical exercise activities
        8. Value education stories
        
        Format everything to be:
        - Printer-friendly (minimal graphics)
        - Clear instructions in simple language
        - Usable without internet or electricity
        - Engaging without digital devices
        
        Organize by day/subject for easy use."""
        
        return self._generate_with_retry(prompt)
    
    def generate_multilingual_content(self, content: str, target_languages: List[str], 
                                    maintain_context: bool = True) -> Dict[str, str]:
        """Translate content to multiple Indian languages"""
        prompt = f"""Translate the following educational content to these languages: {', '.join(target_languages)}
        
        Original content: {content}
        
        Requirements:
        1. Maintain educational accuracy
        2. Use simple, grade-appropriate vocabulary
        3. Adapt cultural references appropriately
        4. Keep the same friendly, encouraging tone
        5. Ensure numbers and technical terms are consistent
        
        Provide translations in a clear format with language labels."""
        
        response = self._generate_with_retry(prompt)
        
        # Parse response into dictionary (simplified - in production, use proper parsing)
        translations = {"original": content}
        for lang in target_languages:
            # This is simplified - you'd need to parse the actual response
            translations[lang] = response
        
        return translations
    
    def analyze_image_for_learning(self, image_data: str, analysis_type: str = "general") -> str:
        """Analyze images for educational content creation"""
        prompt_types = {
            "general": "Analyze this image and suggest educational activities",
            "textbook": "Extract key concepts from this textbook page",
            "student_work": "Assess this student's work and provide feedback",
            "nature": "Create nature-based learning activities from this image",
            "local_culture": "Design lessons incorporating this cultural element"
        }
        
        base_prompt = prompt_types.get(analysis_type, prompt_types["general"])
        
        prompt = f"""{base_prompt}.
        
        Provide:
        1. Key observations from the image
        2. Educational opportunities identified
        3. Grade-appropriate activities (for grades 1-5)
        4. Questions to ask students
        5. Cross-curricular connections
        6. Local context integration ideas
        
        Keep suggestions practical for rural classrooms."""
        
        if isinstance(image_data, str):
            image_bytes = base64.b64decode(image_data)
        else:
            image_bytes = image_data
        
        return self._generate_with_retry(prompt, image_bytes)

    def generate_assessment_rubric(self, subject: str, topic: str, grade: int, assessment_type: str = "written") -> str:
        """Generate assessment rubrics for various activities"""
        prompt = f"""Create a detailed assessment rubric for {assessment_type} assessment in {subject} for grade {grade} students on the topic: {topic}.
        
        Include:
        1. Clear criteria for evaluation (4-5 criteria)
        2. Performance levels (Excellent, Good, Satisfactory, Needs Improvement)
        3. Specific descriptors for each level
        4. Point values or scoring guide
        5. Space for teacher comments
        6. Tips for fair assessment in rural contexts
        7. Accommodation suggestions for struggling students
        
        Make it simple for teachers to use and understand."""
        
        return self._generate_with_retry(prompt)
    
    def create_remedial_content(self, topic: str, grade: int, difficulty_areas: List[str], language: str = "English") -> str:
        """Create remedial content for students struggling with specific topics"""
        prompt = f"""Create remedial teaching content for grade {grade} students struggling with {topic} in {language}.
        
        Specific difficulty areas: {', '.join(difficulty_areas)}
        
        Provide:
        1. Simplified explanation of the concept
        2. Step-by-step breakdown
        3. Visual learning aids description
        4. Hands-on activities using local materials
        5. Practice exercises (start very simple)
        6. Memory tricks or mnemonics
        7. Peer tutoring suggestions
        8. Parent guidance (for low-literacy parents)
        
        Keep language very simple and use familiar examples."""
        
        return self._generate_with_retry(prompt)
    
    def generate_festival_activity(self, festival: str, grades: List[int], subjects: List[str]) -> str:
        """Generate educational activities related to Indian festivals"""
        prompt = f"""Create educational activities for {festival} celebration suitable for grades {', '.join(map(str, grades))} covering subjects: {', '.join(subjects)}.
        
        Include:
        1. Festival story in simple language
        2. Math activities related to festival (counting, patterns)
        3. Language activities (vocabulary, writing)
        4. Art and craft with local materials
        5. Science connections (if applicable)
        6. Values and morals from the festival
        7. Group activities for multi-grade classroom
        8. Take-home activities for family involvement
        
        Ensure cultural sensitivity and inclusivity."""
        
        return self._generate_with_retry(prompt)
    
    def create_morning_assembly_content(self, theme: str, duration: str = "week") -> str:
        """Generate content for morning school assembly"""
        prompt = f"""Create morning assembly content for a {duration} on the theme: {theme}.
        
        For each day include:
        1. Prayer/thought for the day (secular and inclusive)
        2. News headlines (child-friendly)
        3. Word of the day with meaning
        4. Simple exercise routine (2-3 minutes)
        5. Student presentation topic
        6. Motivational message
        7. Important announcements template
        8. Birthday wishes format
        
        Keep it engaging and suitable for rural schools."""
        
        return self._generate_with_retry(prompt)
    
    def generate_co_curricular_activity(self, activity_type: str, resources: List[str], group_size: int) -> str:
        """Generate co-curricular activity plans"""
        activity_types = {
            "sports": "physical education and sports",
            "music": "music and rhythm activities",
            "drama": "drama and role play",
            "art": "art and craft",
            "gardening": "school gardening",
            "life_skills": "practical life skills"
        }
        
        activity_desc = activity_types.get(activity_type, activity_type)
        
        prompt = f"""Create a detailed plan for {activity_desc} activity for a group of {group_size} students.
        
        Available resources: {', '.join(resources)}
        
        Include:
        1. Activity objectives
        2. Step-by-step instructions
        3. Time allocation (30-45 minutes)
        4. Safety considerations
        5. Skill development aspects
        6. Variations for different age groups
        7. Assessment of participation
        8. Connection to academic learning
        
        Make it fun and feasible for rural schools."""
        
        return self._generate_with_retry(prompt)
    
    def create_teacher_training_module(self, topic: str, duration_hours: int) -> str:
        """Create teacher training content"""
        prompt = f"""Create a {duration_hours}-hour teacher training module on: {topic}.
        
        Structure:
        1. Learning objectives for teachers
        2. Session plan with time breakdown
        3. Interactive activities
        4. Case studies from rural schools
        5. Hands-on practice sessions
        6. Discussion points
        7. Take-away resources
        8. Action plan template
        9. Follow-up activities
        
        Focus on practical application in multi-grade rural classrooms."""
        
        return self._generate_with_retry(prompt)
    
    def generate_school_event_plan(self, event: str, budget: str, expected_attendance: int) -> str:
        """Generate plans for school events"""
        prompt = f"""Create a detailed plan for organizing {event} in a rural school.
        
        Budget: {budget}
        Expected attendance: {expected_attendance}
        
        Include:
        1. Event objectives
        2. Planning timeline (2-4 weeks before)
        3. Committee structure and responsibilities
        4. Resource list within budget
        5. Program schedule
        6. Student involvement opportunities
        7. Parent/community participation
        8. Safety and logistics
        9. Documentation plan
        10. Post-event follow-up
        
        Keep it simple and community-oriented."""
        
        return self._generate_with_retry(prompt)
    
    def create_health_hygiene_content(self, topic: str, grade_range: str, local_context: str) -> str:
        """Create health and hygiene educational content"""
        prompt = f"""Create health and hygiene education content on {topic} for {grade_range} students in {local_context} context.
        
        Include:
        1. Simple explanation of the health topic
        2. Why it's important (relatable reasons)
        3. Step-by-step hygiene practices
        4. Local challenges and solutions
        5. Home practices to involve family
        6. Myths vs facts (address local beliefs)
        7. Fun activities and games
        8. Monitoring checklist for teachers
        9. Visual aid descriptions
        
        Use culturally sensitive language and examples."""
        
        return self._generate_with_retry(prompt)
    
    def generate_peer_learning_activity(self, subject: str, topic: str, mixed_grades: List[int]) -> str:
        """Generate peer learning activities for multi-grade classrooms"""
        prompt = f"""Create peer learning activities for {subject} on topic {topic} for mixed grade classroom with grades: {', '.join(map(str, mixed_grades))}.
        
        Design activities where:
        1. Older students can teach younger ones
        2. Mixed-ability groups work together
        3. Each grade level has a specific role
        4. Learning happens through collaboration
        5. Assessment includes peer feedback
        6. Materials are shared efficiently
        7. Time is managed for all groups
        8. Teacher acts as facilitator
        
        Include 3-4 different peer learning formats."""
        
        return self._generate_with_retry(prompt)
    
    def create_local_curriculum_content(self, standard_topic: str, local_context: str, grade: int) -> str:
        """Adapt standard curriculum to local context"""
        prompt = f"""Adapt the standard curriculum topic "{standard_topic}" for grade {grade} to fit the local context of {local_context}.
        
        Include:
        1. Local examples replacing textbook examples
        2. Community-based learning activities
        3. Local language terms and translations
        4. Cultural connections
        5. Local problem-solving scenarios
        6. Field trip suggestions (nearby locations)
        7. Guest speaker ideas (local professionals)
        8. Home-school connection activities
        
        Maintain curriculum standards while making it relevant."""
        
        return self._generate_with_retry(prompt)