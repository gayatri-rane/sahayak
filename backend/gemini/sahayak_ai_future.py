import google.generativeai as genai
import time
import random
from typing import Optional, List, Dict, Any
import datetime
import base64
import os
import json
class SahayakAI:
    def __init__(self):
        """Initialize the Gemini client with enhanced capabilities"""
        # Configure API with your key
        api_key = os.environ.get('GEMINI_API_KEY', 'AIzaSyCq4h2kDkAHRC0DrUCtpGf7X83s2fLBf8Y')
        genai.configure(api_key=api_key)
        
        # Initialize the text model (same as before)
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
        
        # NEW: Initialize vision model for image generation/analysis
        try:
            self.vision_model = genai.GenerativeModel('gemini-1.5-pro-vision')
        except:
            self.vision_model = None
            
        # NEW: Initialize embedding model for semantic search
        try:
            self.embedding_model = genai.GenerativeModel('embedding-001')
        except:
            self.embedding_model = None
        
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
        """Generate content with enhanced retry logic and error handling"""
        # Track request
        self.request_count += 1
        self.request_log.append({
            "timestamp": datetime.datetime.now().isoformat(),
            "request_number": self.request_count,
            "prompt_preview": prompt_text[:100] + "..." if len(prompt_text) > 100 else prompt_text,
            "has_image": image_data is not None
        })
        
        for attempt in range(max_retries):
            try:
                # Wait if needed to respect rate limits
                self._wait_if_needed()
                
                print(f"Making request #{self.request_count} (attempt {attempt + 1}/{max_retries})")
                
                # Add system instruction to prompt
                full_prompt = f"{self.system_instruction}\n\n{prompt_text}"
                
                # NEW: Add request metadata for better tracking
                request_metadata = {
                    'request_id': f"req_{self.request_count}_{attempt}",
                    'timestamp': datetime.datetime.now().isoformat(),
                    'prompt_length': len(full_prompt),
                    'has_image': image_data is not None
                }
                
                # Generate content
                if image_data:
                    # For image-based generation
                    import PIL.Image
                    import io
                    image = PIL.Image.open(io.BytesIO(image_data))
                    
                    # NEW: Validate image before sending
                    if image.size[0] > 4096 or image.size[1] > 4096:
                        # Resize if too large
                        image.thumbnail((4096, 4096), PIL.Image.Resampling.LANCZOS)
                    
                    response = self.model.generate_content([full_prompt, image])
                else:
                    # For text-only generation
                    response = self.model.generate_content(full_prompt)
                
                # NEW: Validate response
                if not response or not response.text:
                    raise Exception("Empty response received from model")
                
                print(f"Request successful! Response length: {len(response.text)} characters")
                
                # NEW: Log successful request
                self._log_successful_request(request_metadata, response)
                
                return response.text
                
            except Exception as e:
                error_str = str(e)
                print(f"Error on attempt {attempt + 1}: {error_str}")
                
                # NEW: Enhanced error categorization
                error_type = self._categorize_error(error_str)
                
                if error_type == 'rate_limit':
                    if attempt < max_retries - 1:
                        # Exponential backoff with jitter
                        wait_time = (2 ** (attempt + 1)) * self.min_delay_between_requests + random.uniform(0, 2)
                        print(f"Rate limit hit. Waiting {wait_time:.1f} seconds before retry...")
                        time.sleep(wait_time)
                        continue
                    else:
                        raise Exception(f"Rate limit exceeded after {max_retries} attempts. Please wait a minute and try again.")
                
                elif error_type == 'invalid_request':
                    # Don't retry for invalid requests
                    raise Exception(f"Invalid request: {error_str}")
                
                elif error_type == 'model_error':
                    # Retry with modified prompt
                    if attempt < max_retries - 1:
                        print("Model error detected. Modifying prompt and retrying...")
                        prompt_text = self._simplify_prompt(prompt_text)
                        continue
                    else:
                        raise Exception(f"Model error after {max_retries} attempts: {error_str}")
                
                else:
                    # Unknown error - retry with standard backoff
                    if attempt < max_retries - 1:
                        wait_time = (attempt + 1) * 2
                        print(f"Unknown error. Waiting {wait_time} seconds before retry...")
                        time.sleep(wait_time)
                        continue
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
    
    
    # ============ NEW METHODS FOR VISUAL AIDS ============
    # These are completely new methods added to the class

    def create_visual_aid_with_description(self, concept: str, drawing_medium: str = "blackboard", 
                                        include_variations: bool = True) -> Dict[str, Any]:
        """Create enhanced visual aid with both instructions and image description"""
        prompt = f"""Create comprehensive visual aid materials for teaching: {concept}
        
        Provide:
        1. DRAWING INSTRUCTIONS for {drawing_medium}:
        - Step-by-step instructions using basic shapes
        - Each step completable in 30 seconds
        - Labels in English and Hindi
        - Color suggestions if applicable
        
        2. IMAGE DESCRIPTION for digital generation:
        - Detailed description of what the final diagram should look like
        - Specific shapes, positions, and proportions
        - Text labels and their positions
        - Color scheme suitable for education
        
        3. VARIATIONS:
        - Simpler version for younger students
        - More complex version for advanced students
        - Alternative representations
        
        4. USAGE TIPS:
        - How to explain while drawing
        - Common misconceptions to address
        - Interactive elements students can add
        
        Format everything clearly with sections."""
        
        response = self._generate_with_retry(prompt)
        
        # Parse response into structured format
        return {
            'concept': concept,
            'drawing_instructions': response,
            'image_generation_prompt': self._extract_image_prompt(response, concept),
            'variations': self._extract_variations(response),
            'teaching_tips': self._extract_teaching_tips(response)
        }

    def generate_educational_image(self, prompt: str, style: str = "educational_diagram") -> Dict[str, Any]:
        """Generate educational images using Gemini's image capabilities"""
        try:
            # NEW: Using Gemini's image generation (when available)
            # Note: As of now, Gemini doesn't directly generate images, 
            # but can create detailed descriptions for other tools
            
            image_prompt = f"""Create a detailed description for an educational {style} image:
            {prompt}
            
            Describe:
            1. Layout and composition
            2. Specific visual elements and their positions
            3. Colors and styling
            4. Text labels and annotations
            5. Educational elements to highlight
            
            Make it suitable for educational purposes."""
            
            description = self._generate_with_retry(image_prompt)
            
            # In production, you would send this description to an image generation service
            # For now, return the description
            return {
                'description': description,
                'prompt': prompt,
                'style': style,
                'base64': None  # Would contain actual image data
            }
            
        except Exception as e:
            raise Exception(f"Image generation failed: {str(e)}")

    def create_interactive_visual_aid(self, concept: str, interaction_type: str = "drawing") -> Dict[str, Any]:
        """Create interactive visual aids that students can engage with"""
        interaction_prompts = {
            "drawing": "students can draw and complete",
            "labeling": "students can label parts",
            "coloring": "students can color to learn",
            "matching": "students can match items",
            "sequencing": "students can arrange in order"
        }
        
        interaction_desc = interaction_prompts.get(interaction_type, interaction_type)
        
        prompt = f"""Create an interactive visual aid for {concept} that {interaction_desc}.
        
        Provide:
        1. BASE TEMPLATE
        - What the teacher draws/prepares
        - Blank spaces for student interaction
        - Clear instructions
        
        2. STUDENT ACTIVITY
        - What students need to do
        - Materials needed (pencil, colors, etc.)
        - Time required
        
        3. LEARNING OBJECTIVES
        - What students will learn
        - Skills developed
        - Assessment criteria
        
        4. VARIATIONS BY GRADE
        - Grade 1-2 version
        - Grade 3-5 version
        - Grade 6-8 version
        
        5. EXTENSION ACTIVITIES
        - Follow-up tasks
        - Home assignments
        - Group activities
        
        Make it engaging and hands-on."""
        
        response = self._generate_with_retry(prompt)
        
        return {
            'concept': concept,
            'interaction_type': interaction_type,
            'template': response,
            'materials_needed': self._extract_materials(response),
            'time_estimate': self._estimate_activity_time(response),
            'learning_outcomes': self._extract_learning_outcomes(response)
        }

    # ============ NEW METHODS FOR KNOWLEDGE BASE ============

    def answer_complex_education_query(self, query: str, context: Dict[str, Any] = None) -> Dict[str, Any]:
        """Answer complex educational queries with research-backed responses"""
        context_str = ""
        if context:
            context_str = f"\nContext: Grade levels: {context.get('grades', 'multi-grade')}, Location: {context.get('location', 'rural India')}"
        
        prompt = f"""As an educational expert, provide a comprehensive answer to this query:
        
        Query: {query}{context_str}
        
        Structure your response with:
        
        1. DIRECT ANSWER
        - Clear, concise response to the question
        - Key points summarized
        
        2. THEORETICAL FOUNDATION
        - Educational theories that support this
        - Research findings (cite general research areas)
        - Best practices from education literature
        
        3. PRACTICAL IMPLEMENTATION
        - Step-by-step implementation guide
        - Required resources (focus on low-cost/free)
        - Timeline for implementation
        - Success metrics
        
        4. CHALLENGES & SOLUTIONS
        - Common challenges in rural Indian schools
        - Practical solutions for each challenge
        - Preventive measures
        
        5. CASE EXAMPLES
        - 2-3 brief examples of successful implementation
        - Lessons learned from each
        
        6. ADDITIONAL RESOURCES
        - Related topics to explore
        - Skills to develop
        - Free online resources
        
        7. QUICK TIPS
        - 5 actionable tips teachers can use immediately
        
        Make it practical and relevant for rural Indian teachers."""
        
        response = self._generate_with_retry(prompt)
        
        # Structure the response
        return {
            'query': query,
            'response': response,
            'category': self._categorize_query(query),
            'difficulty_level': self._assess_query_complexity(query),
            'related_queries': self._generate_related_queries(query),
            'implementation_checklist': self._create_implementation_checklist(response)
        }

    def analyze_educational_query(self, query: str) -> Dict[str, Any]:
        """Analyze an educational query to understand intent and context"""
        prompt = f"""Analyze this educational query: "{query}"
        
        Provide:
        1. Query type (how-to, conceptual, problem-solving, resource-request)
        2. Subject area
        3. Estimated grade level relevance
        4. Key concepts mentioned
        5. Implicit needs not directly stated
        6. Suggested response approach
        
        Format as structured analysis."""
        
        response = self._generate_with_retry(prompt)
        
        # Parse and return structured analysis
        return {
            'query': query,
            'analysis': response,
            'intent': 'educational_guidance',  # Would be parsed from response
            'priority': 'high'  # Based on keywords
        }

    def enhance_knowledge_contribution(self, title: str, content: str, category: str) -> Dict[str, Any]:
        """Enhance user-contributed knowledge with AI"""
        prompt = f"""Enhance this educational knowledge contribution:
        
        Title: {title}
        Category: {category}
        Original Content: {content}
        
        Enhance by:
        1. Adding missing important points
        2. Clarifying complex concepts
        3. Adding practical examples
        4. Including implementation tips
        5. Suggesting prerequisites
        6. Adding learning objectives
        7. Estimating time requirements
        8. Listing required resources
        
        Maintain the original author's voice while improving clarity and completeness."""
        
        enhanced_content = self._generate_with_retry(prompt)
        
        # Generate tags
        tags_prompt = f"Generate 5-10 relevant tags for this educational content about {title}"
        tags_response = self._generate_with_retry(tags_prompt)
        
        return {
            'content': enhanced_content,
            'tags': self._parse_tags(tags_response),
            'prerequisites': self._extract_prerequisites(enhanced_content),
            'learning_objectives': self._extract_learning_objectives(enhanced_content),
            'implementation_time': self._estimate_implementation_time(enhanced_content),
            'required_resources': self._extract_required_resources(enhanced_content)
        }

    # ============ NEW METHODS FOR AUDIO PROCESSING ============

    def process_audio_query(self, audio_data: bytes, language: str = "Hindi") -> Dict[str, Any]:
        """Process audio queries (requires Google Cloud Speech-to-Text setup)"""
        # This is a placeholder - in production, implement actual speech-to-text
        # using Google Cloud Speech-to-Text API
        
        # For demonstration, return structured response
        return {
            'transcription': 'मुझे कक्षा 3 के लिए गणित की वर्कशीट चाहिए',
            'language_detected': language,
            'confidence': 0.95,
            'query_type': 'content_request',
            'suggested_action': 'create_worksheet',
            'parsed_parameters': {
                'grade': 3,
                'subject': 'mathematics',
                'content_type': 'worksheet'
            }
        }

    def generate_audio_content(self, text: str, voice: str = "default", language: str = "English") -> Dict[str, Any]:
        """Generate audio content from text"""
        # Placeholder for text-to-speech functionality
        # In production, integrate with Google Cloud Text-to-Speech or similar
        
        prompt = f"""Create phonetic pronunciation guide for this text in {language}:
        "{text}"
        
        Provide:
        1. Simplified phonetic spelling
        2. Emphasis markers
        3. Pause locations
        4. Tone suggestions
        
        Make it easy for teachers to read aloud."""
        
        pronunciation_guide = self._generate_with_retry(prompt)
        
        return {
            'text': text,
            'pronunciation_guide': pronunciation_guide,
            'voice': voice,
            'language': language,
            'audio_url': None  # Would contain actual audio URL
        }

    # ============ NEW COMPREHENSIVE CONTENT METHODS ============

    def create_worksheet_advanced(self, **kwargs) -> Dict[str, Any]:
        """Create advanced worksheets with multiple features"""
        topic = kwargs.get('topic', '')
        grades = kwargs.get('grades', [3, 4, 5])
        include_answer_key = kwargs.get('include_answer_key', True)
        difficulty_levels = kwargs.get('difficulty_levels', ['basic', 'intermediate', 'advanced'])
        
        prompt = f"""Create comprehensive worksheets for topic: {topic}
        Grades: {grades}
        Difficulty levels: {difficulty_levels}
        
        For each grade and difficulty level, include:
        1. Conceptual understanding questions
        2. Application problems
        3. Critical thinking challenges
        4. Visual/diagram-based questions
        5. Real-world problem solving
        
        Format with clear sections and provide answer key with explanations."""
        
        worksheet_content = self._generate_with_retry(prompt)
        
        return {
            'topic': topic,
            'content': worksheet_content,
            'grades': grades,
            'difficulty_levels': difficulty_levels,
            'has_answer_key': include_answer_key,
            'printable_format': True
        }

    def create_comprehensive_lesson_plan(self, **kwargs) -> Dict[str, Any]:
        """Create detailed lesson plans with all components"""
        objectives = kwargs.get('objectives', [])
        duration = kwargs.get('duration', 'week')
        subjects = kwargs.get('subjects', [])
        grades = kwargs.get('grades', [])
        
        prompt = f"""Create a comprehensive {duration} lesson plan:
        Objectives: {objectives}
        Subjects: {subjects}
        Grades: {grades}
        
        Include:
        1. Daily learning objectives
        2. Warm-up activities
        3. Main teaching content
        4. Interactive activities
        5. Assessment strategies
        6. Differentiation for multiple grades
        7. Resource requirements
        8. Homework assignments
        9. Parent engagement ideas
        10. Extension activities
        
        Make it practical for rural multi-grade classrooms."""
        
        lesson_plan = self._generate_with_retry(prompt)
        
        return {
            'duration': duration,
            'content': lesson_plan,
            'subjects': subjects,
            'grades': grades,
            'resource_list': self._extract_resources(lesson_plan),
            'assessment_rubrics': self._generate_rubrics(objectives)
        }

    def generate_assessment_package(self, **kwargs) -> Dict[str, Any]:
        """Generate complete assessment package"""
        subject = kwargs.get('subject', '')
        topic = kwargs.get('topic', '')
        assessment_type = kwargs.get('assessment_type', 'formative')
        grades = kwargs.get('grades', [])
        
        prompt = f"""Create a complete {assessment_type} assessment package for:
        Subject: {subject}
        Topic: {topic}
        Grades: {grades}
        
        Include:
        1. Pre-assessment activities
        2. Main assessment tasks
        3. Rubrics for each task
        4. Differentiated assessments by grade
        5. Accommodation suggestions
        6. Self-assessment tools for students
        7. Parent feedback forms
        8. Data recording sheets
        
        Ensure assessments are fair and inclusive."""
        
        assessment_content = self._generate_with_retry(prompt)
        
        return {
            'type': assessment_type,
            'subject': subject,
            'topic': topic,
            'content': assessment_content,
            'components': [
                'pre_assessment',
                'main_tasks',
                'rubrics',
                'accommodations',
                'self_assessment',
                'parent_forms',
                'data_sheets'
            ]
        }

    def design_science_experiment(self, **kwargs) -> Dict[str, Any]:
        """Design hands-on science experiments"""
        concept = kwargs.get('concept', '')
        grade_level = kwargs.get('grade_level', 5)
        available_materials = kwargs.get('available_materials', [])
        
        prompt = f"""Design a hands-on science experiment for concept: {concept}
        Grade level: {grade_level}
        Available materials: {available_materials}
        
        Include:
        1. Learning objectives
        2. Materials list (use locally available items)
        3. Safety considerations
        4. Step-by-step procedure
        5. Observation sheet template
        6. Expected results
        7. Explanation of scientific principles
        8. Common mistakes to avoid
        9. Extension experiments
        10. Real-world connections
        
        Make it safe and engaging for rural classroom settings."""
        
        experiment_design = self._generate_with_retry(prompt)
        
        return {
            'concept': concept,
            'design': experiment_design,
            'safety_checklist': self._generate_safety_checklist(concept),
            'materials_alternatives': self._suggest_material_alternatives(available_materials)
        }

    def create_project_based_learning(self, **kwargs) -> Dict[str, Any]:
        """Create project-based learning modules"""
        theme = kwargs.get('theme', '')
        duration = kwargs.get('duration', '2 weeks')
        subjects_integrated = kwargs.get('subjects_integrated', [])
        
        prompt = f"""Design a project-based learning module:
        Theme: {theme}
        Duration: {duration}
        Integrated subjects: {subjects_integrated}
        
        Include:
        1. Project overview and goals
        2. Daily milestone plan
        3. Student roles and responsibilities
        4. Resource requirements
        5. Assessment criteria
        6. Parent/community involvement
        7. Presentation guidelines
        8. Reflection activities
        9. Cross-curricular connections
        10. Real-world applications
        
        Ensure it's feasible for rural schools with limited resources."""
        
        project_module = self._generate_with_retry(prompt)
        
        return {
            'theme': theme,
            'module': project_module,
            'duration': duration,
            'subjects': subjects_integrated,
            'milestones': self._extract_milestones(project_module),
            'community_connections': self._identify_community_connections(theme)
        }

    def generate_interactive_quiz(self, **kwargs) -> Dict[str, Any]:
        """Generate interactive quizzes"""
        topic = kwargs.get('topic', '')
        question_count = kwargs.get('question_count', 10)
        question_types = kwargs.get('question_types', ['mcq', 'true_false', 'fill_blanks'])
        
        prompt = f"""Create an interactive quiz on {topic}:
        Number of questions: {question_count}
        Question types: {question_types}
        
        For each question provide:
        1. The question
        2. Options (for MCQ)
        3. Correct answer
        4. Explanation
        5. Difficulty level
        6. Learning objective addressed
        7. Hint (optional)
        8. Common misconceptions
        
        Make questions engaging and culturally relevant."""
        
        quiz_content = self._generate_with_retry(prompt)
        
        return {
            'topic': topic,
            'quiz': quiz_content,
            'total_questions': question_count,
            'question_types': question_types,
            'can_shuffle': True,
            'time_limit': question_count * 2  # 2 minutes per question
        }

    def create_educational_video_script(self, **kwargs) -> Dict[str, Any]:
        """Create scripts for educational videos"""
        topic = kwargs.get('topic', '')
        duration = kwargs.get('duration', 5)  # minutes
        style = kwargs.get('style', 'animated')
        
        prompt = f"""Create a {duration}-minute educational video script about {topic}:
        Style: {style}
        
        Include:
        1. Hook/Introduction (30 seconds)
        2. Main content sections with timestamps
        3. Visual descriptions for each scene
        4. Narration text
        5. On-screen text/graphics
        6. Interactive moments
        7. Summary/Conclusion
        8. Call-to-action
        
        Make it engaging for young learners with short attention spans."""
        
        script = self._generate_with_retry(prompt)
        
        return {
            'topic': topic,
            'script': script,
            'duration_minutes': duration,
            'style': style,
            'scene_count': self._count_scenes(script),
            'graphics_needed': self._list_graphics_needed(script)
        }

    # ============ HELPER METHODS (NEW) ============

    def _extract_image_prompt(self, response: str, concept: str) -> str:
        """Extract or generate image generation prompt from response"""
        return f"""Educational diagram showing {concept}:
        - Clean, simple line drawing style
        - Clear labels in both English and Hindi
        - Use basic geometric shapes
        - Suitable for reproduction on blackboard
        - Educational and child-friendly
        - White background with black lines
        - Include arrows and annotations where needed"""

    def _categorize_query(self, query: str) -> str:
        """Categorize the educational query"""
        query_lower = query.lower()
        
        categories = {
            'pedagogy': ['teaching', 'method', 'approach', 'strategy', 'technique'],
            'curriculum': ['syllabus', 'content', 'subject', 'topic', 'lesson'],
            'classroom_management': ['discipline', 'behavior', 'management', 'control', 'rules'],
            'assessment': ['evaluation', 'test', 'exam', 'grading', 'marks'],
            'technology': ['digital', 'computer', 'online', 'app', 'software'],
            'special_needs': ['inclusive', 'disability', 'special', 'diverse', 'different'],
            'parent_engagement': ['parent', 'family', 'communication', 'home', 'community'],
            'professional_development': ['training', 'development', 'skill', 'growth', 'learning']
        }
        
        for category, keywords in categories.items():
            if any(keyword in query_lower for keyword in keywords):
                return category
        
        return 'general'

    def _generate_related_queries(self, query: str) -> List[str]:
        """Generate related queries for further exploration"""
        prompt = f"""Based on this educational query: "{query}"
        
        Suggest 5 related questions that teachers might want to explore next.
        Make them practical and relevant to rural Indian schools.
        Keep each question under 15 words."""
        
        response = self._generate_with_retry(prompt)
        
        # Parse response into list - in production, implement proper parsing
        return [
            "How to implement peer learning in multi-grade classrooms?",
            "What are effective assessment methods without tests?",
            "How to engage parents with low literacy?",
            "How to teach without electricity or internet?",
            "How to manage large class sizes effectively?"
        ]

    def _create_implementation_checklist(self, response: str) -> List[Dict[str, Any]]:
        """Create an implementation checklist from the response"""
        # In production, parse the response to extract actionable items
        return [
            {'task': 'Identify current challenges', 'timeframe': 'Week 1', 'completed': False},
            {'task': 'Gather required materials', 'timeframe': 'Week 1-2', 'completed': False},
            {'task': 'Start with pilot group', 'timeframe': 'Week 2', 'completed': False},
            {'task': 'Collect feedback', 'timeframe': 'Week 3', 'completed': False},
            {'task': 'Full implementation', 'timeframe': 'Week 4+', 'completed': False}
        ]

    # ============ NEW HELPER METHODS ============

    def _categorize_error(self, error_str: str) -> str:
        """Categorize error type for appropriate handling"""
        error_lower = error_str.lower()
        
        if "429" in error_str or "resource_exhausted" in error_lower or "rate limit" in error_lower:
            return 'rate_limit'
        elif "invalid" in error_lower or "bad request" in error_lower:
            return 'invalid_request'
        elif "model" in error_lower or "generation" in error_lower:
            return 'model_error'
        else:
            return 'unknown'

    def _simplify_prompt(self, prompt: str) -> str:
        """Simplify prompt to reduce complexity"""
        # Remove extra instructions if prompt is too complex
        simplified = prompt.split('\n\n')[0] + "\n\nProvide a clear and concise response."
        return simplified

    def _log_successful_request(self, metadata: Dict[str, Any], response: Any):
        """Log successful request for analytics"""
        # In production, this would save to a database
        success_log = {
            **metadata,
            'response_length': len(response.text),
            'success': True,
            'processing_time': time.time() - self.last_request_time
        }
        # Log to file or database
        print(f"Success log: {json.dumps(success_log, indent=2)}")

    def _extract_materials(self, response: str) -> List[str]:
        """Extract required materials from response"""
        # Simple implementation - enhance with NLP in production
        materials = []
        
        common_materials = [
            'pencil', 'eraser', 'colors', 'ruler', 'notebook', 'chalk',
            'paper', 'scissors', 'glue', 'cardboard', 'string', 'stones'
        ]
        
        response_lower = response.lower()
        for material in common_materials:
            if material in response_lower:
                materials.append(material)
        
        return materials

    def _estimate_activity_time(self, response: str) -> Dict[str, int]:
        """Estimate time required for activity"""
        # Parse response for time mentions
        # Simple implementation
        return {
            'preparation': 5,  # minutes
            'instruction': 10,
            'activity': 20,
            'review': 5,
            'total': 40
        }

    def _extract_learning_outcomes(self, response: str) -> List[str]:
        """Extract learning outcomes from response"""
        # In production, use NLP to extract actual outcomes
        return [
            "Students will be able to identify key concepts",
            "Students will understand relationships between elements",
            "Students will develop problem-solving skills",
            "Students will apply knowledge to real-world situations"
        ]

    def _extract_variations(self, response: str) -> List[Dict[str, str]]:
        """Extract variations from response"""
        # Simplified extraction - enhance with proper parsing
        return [
            {'level': 'basic', 'description': 'Simplified version for grades 1-2'},
            {'level': 'standard', 'description': 'Standard version for grades 3-5'},
            {'level': 'advanced', 'description': 'Detailed version for grades 6-8'}
        ]

    def _extract_teaching_tips(self, response: str) -> List[str]:
        """Extract teaching tips from response"""
        # Simplified extraction
        return [
            'Draw slowly while explaining each part',
            'Ask students to draw along',
            'Use local examples to relate the concept',
            'Encourage questions at each step'
        ]

    def _parse_tags(self, tags_response: str) -> List[str]:
        """Parse tags from response"""
        # Simple implementation - extract comma-separated values
        tags = []
        
        # Try to extract tags from response
        if ',' in tags_response:
            tags = [tag.strip() for tag in tags_response.split(',')]
        else:
            # Extract individual words that might be tags
            words = tags_response.split()
            tags = [word.lower() for word in words if len(word) > 3][:10]
        
        return tags

    def _extract_prerequisites(self, content: str) -> List[str]:
        """Extract prerequisites from enhanced content"""
        # Simplified implementation
        return [
            "Basic understanding of numbers",
            "Ability to read simple text",
            "Familiarity with basic shapes"
        ]

    def _extract_learning_objectives(self, content: str) -> List[str]:
        """Extract learning objectives"""
        return [
            "Understand the main concept",
            "Apply knowledge to solve problems",
            "Develop critical thinking skills"
        ]

    def _estimate_implementation_time(self, content: str) -> str:
        """Estimate time needed for implementation"""
        # Simple estimation based on content length
        content_length = len(content)
        
        if content_length < 1000:
            return "30-45 minutes"
        elif content_length < 2000:
            return "1-2 hours"
        else:
            return "2-3 hours"

    def _extract_required_resources(self, content: str) -> List[str]:
        """Extract required resources from content"""
        resources = []
        
        # Common educational resources
        resource_keywords = {
            'blackboard': ['blackboard', 'chalk board', 'board'],
            'chalk': ['chalk', 'white chalk', 'colored chalk'],
            'notebooks': ['notebook', 'exercise book', 'copy'],
            'textbooks': ['textbook', 'book', 'reading material'],
            'visual_aids': ['chart', 'poster', 'flashcard'],
            'manipulatives': ['blocks', 'counters', 'beads']
        }
        
        content_lower = content.lower()
        for resource, keywords in resource_keywords.items():
            if any(keyword in content_lower for keyword in keywords):
                resources.append(resource)
        
        return resources

    def _extract_resources(self, lesson_plan: str) -> List[Dict[str, Any]]:
        """Extract detailed resource list from lesson plan"""
        resources = []
        
        # Categories of resources
        categories = {
            'teaching_materials': ['blackboard', 'chalk', 'charts', 'flashcards'],
            'student_materials': ['notebooks', 'pencils', 'erasers', 'colors'],
            'activity_materials': ['paper', 'scissors', 'glue', 'craft items'],
            'reference_materials': ['textbooks', 'storybooks', 'worksheets']
        }
        
        for category, items in categories.items():
            category_resources = []
            for item in items:
                if item in lesson_plan.lower():
                    category_resources.append(item)
            
            if category_resources:
                resources.append({
                    'category': category,
                    'items': category_resources,
                    'estimated_cost': 'Low',  # Would calculate based on items
                    'availability': 'Local market'
                })
        
        return resources

    def _generate_rubrics(self, objectives: List[str]) -> List[Dict[str, Any]]:
        """Generate assessment rubrics for objectives"""
        rubrics = []
        
        for objective in objectives:
            rubric = {
                'objective': objective,
                'criteria': [
                    {
                        'level': 'Excellent',
                        'description': f'Fully achieves {objective} with deep understanding',
                        'points': 4
                    },
                    {
                        'level': 'Good',
                        'description': f'Mostly achieves {objective} with good understanding',
                        'points': 3
                    },
                    {
                        'level': 'Satisfactory',
                        'description': f'Partially achieves {objective} with basic understanding',
                        'points': 2
                    },
                    {
                        'level': 'Needs Improvement',
                        'description': f'Limited progress toward {objective}',
                        'points': 1
                    }
                ]
            }
            rubrics.append(rubric)
        
        return rubrics

    def _generate_safety_checklist(self, concept: str) -> List[str]:
        """Generate safety checklist for experiments"""
        # Basic safety items based on concept
        checklist = [
            "Ensure adult supervision at all times",
            "Check for student allergies before starting",
            "Keep first aid kit accessible",
            "Ensure proper ventilation in the room",
            "Have water available for emergencies"
        ]
        
        # Add concept-specific safety items
        concept_lower = concept.lower()
        
        if 'chemical' in concept_lower or 'acid' in concept_lower:
            checklist.extend([
                "Wear safety goggles",
                "Use diluted solutions only",
                "Keep chemicals away from skin",
                "Have neutralizing agents ready"
            ])
        
        if 'heat' in concept_lower or 'fire' in concept_lower:
            checklist.extend([
                "Keep flammable materials away",
                "Have fire extinguisher ready",
                "Use heat-resistant surfaces",
                "Allow cooling time before handling"
            ])
        
        if 'electric' in concept_lower:
            checklist.extend([
                "Check all connections before use",
                "Keep water away from electrical items",
                "Use low voltage only",
                "Ensure proper insulation"
            ])
        
        return checklist

    def _suggest_material_alternatives(self, available_materials: List[str]) -> Dict[str, List[str]]:
        """Suggest alternatives for materials"""
        alternatives = {
            'beakers': ['glass jars', 'plastic bottles', 'steel containers'],
            'thermometer': ['hand feeling for warm/cold', 'ice vs room temperature comparison'],
            'microscope': ['magnifying glass', 'water drop lens', 'phone camera zoom'],
            'weights': ['stones', 'filled water bottles', 'bags of grain'],
            'measuring_tape': ['string with knots', 'hand spans', 'foot lengths'],
            'stopwatch': ['counting seconds', 'pendulum', 'pulse counting']
        }
        
        suggestions = {}
        for material in available_materials:
            if material.lower() in alternatives:
                suggestions[material] = alternatives[material.lower()]
        
        return suggestions

    def _extract_milestones(self, project_module: str) -> List[Dict[str, Any]]:
        """Extract project milestones"""
        # Simple milestone extraction
        milestones = [
            {
                'day': 1,
                'milestone': 'Project introduction and team formation',
                'deliverable': 'Teams formed and topics chosen'
            },
            {
                'day': 3,
                'milestone': 'Research and planning phase',
                'deliverable': 'Project plan submitted'
            },
            {
                'day': 7,
                'milestone': 'Mid-project review',
                'deliverable': 'Progress report and prototype'
            },
            {
                'day': 10,
                'milestone': 'Final preparation',
                'deliverable': 'Presentation ready'
            },
            {
                'day': 14,
                'milestone': 'Project presentation',
                'deliverable': 'Final presentation and reflection'
            }
        ]
        
        return milestones

    def _identify_community_connections(self, theme: str) -> List[Dict[str, str]]:
        """Identify community connection opportunities"""
        connections = []
        
        theme_lower = theme.lower()
        
        # Agriculture themes
        if any(word in theme_lower for word in ['farming', 'agriculture', 'crop', 'soil']):
            connections.append({
                'type': 'Guest Speaker',
                'suggestion': 'Local farmer to discuss farming practices',
                'learning': 'Real-world agricultural knowledge'
            })
            connections.append({
                'type': 'Field Visit',
                'suggestion': 'Visit to local farm or agricultural field',
                'learning': 'Hands-on observation of concepts'
            })
        
        # Health themes
        if any(word in theme_lower for word in ['health', 'hygiene', 'nutrition', 'disease']):
            connections.append({
                'type': 'Guest Speaker',
                'suggestion': 'ANM/ASHA worker for health talk',
                'learning': 'Community health practices'
            })
            connections.append({
                'type': 'Campaign',
                'suggestion': 'Organize health awareness campaign',
                'learning': 'Community service and awareness'
            })
        
        # Environmental themes
        if any(word in theme_lower for word in ['environment', 'pollution', 'conservation', 'water']):
            connections.append({
                'type': 'Community Project',
                'suggestion': 'Village cleaning or tree planting drive',
                'learning': 'Environmental responsibility'
            })
            connections.append({
                'type': 'Survey',
                'suggestion': 'Water usage or waste management survey',
                'learning': 'Data collection and analysis'
            })
        
        # Default connections
        connections.extend([
            {
                'type': 'Parent Involvement',
                'suggestion': 'Parents share traditional knowledge related to theme',
                'learning': 'Cultural preservation and respect'
            },
            {
                'type': 'Exhibition',
                'suggestion': 'Display project work in village community center',
                'learning': 'Public presentation skills'
            }
        ])
        
        return connections

    def _count_scenes(self, script: str) -> int:
        """Count scenes in video script"""
        # Simple scene counting based on common markers
        scene_markers = ['scene', 'cut to', 'transition', 'next', 'fade']
        
        count = 1  # At least one scene
        script_lower = script.lower()
        
        for marker in scene_markers:
            count += script_lower.count(marker)
        
        return min(count, 20)  # Cap at reasonable number

    def _list_graphics_needed(self, script: str) -> List[str]:
        """List graphics needed for video"""
        graphics = []
        
        # Common educational graphics
        graphic_keywords = {
            'title_card': ['title', 'intro', 'beginning'],
            'diagram': ['diagram', 'chart', 'illustration'],
            'animation': ['animate', 'move', 'transition'],
            'text_overlay': ['text on screen', 'caption', 'subtitle'],
            'example': ['example', 'demonstration', 'show'],
            'summary': ['summary', 'conclusion', 'recap']
        }
        
        script_lower = script.lower()
        for graphic_type, keywords in graphic_keywords.items():
            if any(keyword in script_lower for keyword in keywords):
                graphics.append(graphic_type)
        
        return graphics

    # ============ ADDITIONAL ENHANCEMENT METHODS ============

    def _assess_query_complexity(self, query: str) -> str:
        """Assess the complexity level of the query"""
        # Simple heuristic based on query characteristics
        query_length = len(query.split())
        
        # Check for complexity indicators
        complex_indicators = [
            'how to implement', 'strategies for', 'best practices',
            'research shows', 'evidence-based', 'comprehensive'
        ]
        
        simple_indicators = [
            'what is', 'define', 'meaning of', 'example of'
        ]
        
        query_lower = query.lower()
        
        # Count indicators
        complex_count = sum(1 for indicator in complex_indicators if indicator in query_lower)
        simple_count = sum(1 for indicator in simple_indicators if indicator in query_lower)
        
        # Determine complexity
        if complex_count > 0 or query_length > 25:
            return 'advanced'
        elif simple_count > 0 or query_length < 10:
            return 'basic'
        else:
            return 'intermediate'

    def generate_content(self, content_type: str, **kwargs) -> Dict[str, Any]:
        """Universal content generation method"""
        # Map content types to specific methods
        content_generators = {
            'story': self.generate_story,
            'worksheet': self.create_worksheet_advanced,
            'lesson': self.create_comprehensive_lesson_plan,
            'assessment': self.generate_assessment_package,
            'game': self.generate_educational_game,
            'visual_aid': self.create_visual_aid_with_description,
            'experiment': self.design_science_experiment,
            'project': self.create_project_based_learning,
            'quiz': self.generate_interactive_quiz,
            'video_script': self.create_educational_video_script,
            'parent_message': self.generate_parent_message,
            'intervention': self.generate_intervention_strategy,
            'festival_activity': self.generate_festival_activity,
            'assembly_content': self.create_morning_assembly_content,
            'health_content': self.create_health_hygiene_content,
            'remedial_content': self.create_remedial_content
        }
        
        generator = content_generators.get(content_type)
        if not generator:
            raise ValueError(f"Unknown content type: {content_type}")
        
        # Generate content with provided parameters
        return generator(**kwargs)