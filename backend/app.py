from flask import Flask, request, jsonify, send_file
from flask_cors import CORS
from werkzeug.utils import secure_filename
from gemini.sahayak_ai_v2 import SahayakAI
import base64
import json
import os
import uuid
from datetime import datetime
import logging
from functools import wraps
import time
import secrets
import jwt
from datetime import datetime, timedelta

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for frontend communication

# Add these configurations
app.config['SECRET_KEY'] = 'your-secret-key-here'  # Change in production
valid_tokens = {}  # In production, use Redis or database

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize AI
ai = SahayakAI()

# Configuration
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16MB max file size
app.config['UPLOAD_FOLDER'] = 'uploads'
app.config['ALLOWED_EXTENSIONS'] = {'png', 'jpg', 'jpeg', 'gif', 'mp3', 'wav', 'ogg'}

# Create upload folder if it doesn't exist
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

# In-memory storage (replace with Firebase in production)
community_library = {}
student_progress = {}
class_analytics = {}
resource_ratings = {}
offline_queue = []
user_sessions = {}

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in app.config['ALLOWED_EXTENSIONS']

def require_auth(f):
    """Simple auth decorator - replace with Firebase Auth in production"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header:
            return jsonify({'success': False, 'error': 'No authorization header'}), 401
        # In production, verify Firebase token here
        return f(*args, **kwargs)
    return decorated_function

# ==================== HEALTH & STATUS ENDPOINTS ====================

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint with usage stats"""
    try:
        stats = ai.get_usage_stats()
        return jsonify({
            'success': True,
            'status': 'healthy',
            'usage_stats': stats,
            'rate_limit_info': {
                'requests_per_minute_limit': ai.requests_per_minute,
                'min_seconds_between_requests': ai.min_delay_between_requests
            },
            'features': {
                'content_generation': True,
                'worksheet_creation': True,
                'visual_aids': True,
                'audio_assessment': True,
                'game_generation': True,
                'lesson_planning': True,
                'community_library': True,
                'analytics': True,
                'parent_communication': True,
                'offline_support': True,
                'multi_modal_input': True
            }
        })
    except Exception as e:
        logger.error(f"Health check failed: {str(e)}")
        return jsonify({
            'success': False,
            'status': 'error',
            'error': str(e)
        }), 500

# ==================== CONTENT GENERATION ENDPOINTS ====================

@app.route('/generate-story', methods=['POST'])
@require_auth
def generate_story():
    """Generate educational story in local language"""
    try:
        data = request.json
        story = ai.generate_story(
            language=data['language'],
            grade=data['grade'],
            topic=data['topic'],
            context=data['context']
        )
        
        # Save to community library if requested
        if data.get('save_to_library', False):
            resource_id = str(uuid.uuid4())
            community_library[resource_id] = {
                'id': resource_id,
                'type': 'story',
                'content': story,
                'metadata': {
                    'language': data['language'],
                    'grade': data['grade'],
                    'topic': data['topic'],
                    'context': data['context'],
                    'created_at': datetime.now().isoformat(),
                    'teacher_id': data.get('teacher_id', 'anonymous'),
                    'ratings': [],
                    'downloads': 0
                }
            }
            return jsonify({'success': True, 'story': story, 'resource_id': resource_id})
        
        return jsonify({'success': True, 'story': story})
    except Exception as e:
        logger.error(f"Story generation failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/create-worksheet', methods=['POST'])
@require_auth
def create_worksheet():
    """Create differentiated worksheets from textbook image"""
    try:
        data = request.json
        # Handle base64 image
        image_data = data['image'].split(',')[1] if ',' in data['image'] else data['image']
        
        worksheet = ai.create_worksheet_from_image(
            image_data=image_data,
            grades=data['grades']
        )
        
        # Track analytics
        for grade in data['grades']:
            if grade not in class_analytics:
                class_analytics[grade] = {'worksheets_created': 0}
            class_analytics[grade]['worksheets_created'] += 1
        
        return jsonify({'success': True, 'worksheet': worksheet})
    except Exception as e:
        logger.error(f"Worksheet creation failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/explain-concept', methods=['POST'])
@require_auth
def explain_concept():
    """Explain concepts using rural analogies"""
    try:
        data = request.json
        explanation = ai.explain_concept(
            question=data['question'],
            language=data['language'],
            grade_level=data['grade_level']
        )
        return jsonify({'success': True, 'explanation': explanation})
    except Exception as e:
        logger.error(f"Concept explanation failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/create-visual-aid', methods=['POST'])
@require_auth
def create_visual_aid():
    """Create simple visual aid descriptions for blackboard drawing"""
    try:
        data = request.json
        visual_aid = ai.create_visual_aid(
            concept=data['concept'],
            drawing_medium=data.get('drawing_medium', 'blackboard')
        )
        return jsonify({'success': True, 'visual_aid': visual_aid})
    except Exception as e:
        logger.error(f"Visual aid creation failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

# ==================== AUDIO & ASSESSMENT ENDPOINTS ====================

@app.route('/audio-assessment', methods=['POST'])
@require_auth
def audio_assessment():
    """Generate reading assessment criteria for audio evaluations"""
    try:
        data = request.json
        assessment = ai.generate_audio_assessment(
            text=data['text'],
            language=data['language'],
            grade_level=data['grade_level']
        )
        
        # Store assessment criteria for student tracking
        student_id = data.get('student_id')
        if student_id:
            if student_id not in student_progress:
                student_progress[student_id] = {'assessments': []}
            student_progress[student_id]['assessments'].append({
                'criteria': assessment,
                'date': datetime.now().isoformat(),
                'text': data['text'][:100] + '...'  # Store preview
            })
        
        return jsonify({'success': True, 'assessment': assessment})
    except Exception as e:
        logger.error(f"Audio assessment generation failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/speech-to-text', methods=['POST'])
@require_auth
def speech_to_text():
    """Convert speech input to text for queries"""
    try:
        if 'audio' not in request.files:
            return jsonify({'success': False, 'error': 'No audio file provided'}), 400
        
        audio_file = request.files['audio']
        if audio_file.filename == '':
            return jsonify({'success': False, 'error': 'No file selected'}), 400
        
        if audio_file and allowed_file(audio_file.filename):
            filename = secure_filename(audio_file.filename)
            filepath = os.path.join(app.config['UPLOAD_FOLDER'], f"{uuid.uuid4()}_{filename}")
            audio_file.save(filepath)
            
            language = request.form.get('language', 'Hindi')
            
            # TODO: Implement actual Vertex AI Speech-to-Text
            # For now, return mock response
            mock_text = f"[Speech-to-text would process audio in {language}]"
            
            # Clean up file
            os.remove(filepath)
            
            return jsonify({'success': True, 'text': mock_text})
        
        return jsonify({'success': False, 'error': 'Invalid file type'}), 400
    except Exception as e:
        logger.error(f"Speech-to-text failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

# ==================== EDUCATIONAL GAME ENDPOINTS ====================

@app.route('/generate-game', methods=['POST'])
@require_auth
def generate_game():
    """Generate educational games like vocabulary bingo, math puzzles"""
    try:
        data = request.json
        
        # Use the general generation method to create games
        prompt = f"""Create a {data['game_type']} game for grade {data['grade']} students about {data['topic']} in {data.get('language', 'English')}.
        
        Include:
        - Clear game rules and objectives
        - Materials needed (use simple, locally available items)
        - Step-by-step instructions for teachers
        - Learning objectives aligned with curriculum
        - Variations for different skill levels
        - Time duration
        - Assessment criteria
        
        Make it engaging and suitable for rural Indian classroom context."""
        
        contents = [
            {
                'role': 'user',
                'parts': [{'text': prompt}]
            }
        ]
        
        # Use the existing generate method
        game_content = ai._generate_with_retry(contents)
        
        return jsonify({'success': True, 'game': game_content})
    except Exception as e:
        logger.error(f"Game generation failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

# ==================== LESSON PLANNING ENDPOINTS ====================

@app.route('/create-lesson-plan', methods=['POST'])
@require_auth
def create_lesson_plan():
    """Create structured, curriculum-aligned lesson plans"""
    try:
        data = request.json
        
        # Generate lesson plan using AI
        prompt = f"""Create a detailed {data.get('duration', 'week')} lesson plan for a multi-grade classroom with grades {', '.join(map(str, data['grades']))}.
        
        Subjects to cover: {', '.join(data['subjects'])}
        Weekly goals: {data['weekly_goals']}
        
        Structure the plan with:
        1. Daily breakdown (Monday to Friday/Saturday)
        2. Time slots for each activity
        3. Grade-specific activities that can run simultaneously
        4. Common activities for all grades
        5. Materials needed (locally available)
        6. Assessment methods for each grade
        7. Homework assignments (grade-appropriate)
        8. Tips for managing multi-grade instruction
        
        Format in {data.get('language', 'English')} and make it practical for rural Indian schools."""
        
        contents = [
            {
                'role': 'user',
                'parts': [{'text': prompt}]
            }
        ]
        
        lesson_plan = ai._generate_with_retry(contents)
        
        # Save lesson plan
        plan_id = str(uuid.uuid4())
        if data.get('save', True):
            community_library[plan_id] = {
                'id': plan_id,
                'type': 'lesson_plan',
                'content': lesson_plan,
                'metadata': {
                    'grades': data['grades'],
                    'subjects': data['subjects'],
                    'duration': data.get('duration', 'week'),
                    'created_at': datetime.now().isoformat(),
                    'teacher_id': data.get('teacher_id', 'anonymous')
                }
            }
        
        return jsonify({'success': True, 'lesson_plan': lesson_plan, 'plan_id': plan_id})
    except Exception as e:
        logger.error(f"Lesson plan creation failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

# ==================== COMMUNITY LIBRARY ENDPOINTS ====================

@app.route('/resources/share', methods=['POST'])
@require_auth
def share_resource():
    """Share teaching materials with the community"""
    try:
        data = request.json
        resource_id = str(uuid.uuid4())
        
        community_library[resource_id] = {
            'id': resource_id,
            'type': data['type'],
            'content': data['content'],
            'metadata': {
                **data.get('metadata', {}),
                'created_at': datetime.now().isoformat(),
                'teacher_id': data.get('teacher_id', 'anonymous'),
                'ratings': [],
                'downloads': 0,
                'remixes': 0
            }
        }
        
        return jsonify({'success': True, 'resource_id': resource_id})
    except Exception as e:
        logger.error(f"Resource sharing failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/resources/search', methods=['GET'])
def search_resources():
    """Search community resources"""
    try:
        query = request.args.get('query', '').lower()
        grade = request.args.get('grade')
        subject = request.args.get('subject')
        language = request.args.get('language')
        resource_type = request.args.get('type')
        
        results = []
        for resource_id, resource in community_library.items():
            # Simple search implementation
            if query and query not in json.dumps(resource).lower():
                continue
            
            metadata = resource.get('metadata', {})
            if grade and str(grade) not in str(metadata.get('grades', [])):
                continue
            if subject and subject != metadata.get('subject'):
                continue
            if language and language != metadata.get('language'):
                continue
            if resource_type and resource_type != resource.get('type'):
                continue
            
            results.append({
                'id': resource_id,
                'type': resource['type'],
                'preview': resource['content'][:200] + '...' if len(resource['content']) > 200 else resource['content'],
                'metadata': metadata
            })
        
        # Sort by ratings and downloads
        results.sort(key=lambda x: (
            -sum(r['rating'] for r in x['metadata'].get('ratings', [])) / max(len(x['metadata'].get('ratings', [])), 1),
            -x['metadata'].get('downloads', 0)
        ))
        
        return jsonify({'success': True, 'resources': results[:50]})  # Limit to 50 results
    except Exception as e:
        logger.error(f"Resource search failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/resources/<resource_id>', methods=['GET'])
def get_resource(resource_id):
    """Get a specific resource"""
    try:
        if resource_id not in community_library:
            return jsonify({'success': False, 'error': 'Resource not found'}), 404
        
        resource = community_library[resource_id]
        resource['metadata']['downloads'] += 1
        
        return jsonify({'success': True, 'resource': resource})
    except Exception as e:
        logger.error(f"Resource retrieval failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/resources/<resource_id>/remix', methods=['POST'])
@require_auth
def remix_resource(resource_id):
    """Create a remix of an existing resource"""
    try:
        if resource_id not in community_library:
            return jsonify({'success': False, 'error': 'Original resource not found'}), 404
        
        data = request.json
        original = community_library[resource_id]
        new_resource_id = str(uuid.uuid4())
        
        community_library[new_resource_id] = {
            'id': new_resource_id,
            'type': original['type'],
            'content': data['content'],
            'metadata': {
                **data.get('metadata', {}),
                'original_resource_id': resource_id,
                'created_at': datetime.now().isoformat(),
                'teacher_id': data.get('teacher_id', 'anonymous'),
                'ratings': [],
                'downloads': 0,
                'remixes': 0
            }
        }
        
        # Update original resource remix count
        original['metadata']['remixes'] = original['metadata'].get('remixes', 0) + 1
        
        return jsonify({'success': True, 'resource_id': new_resource_id})
    except Exception as e:
        logger.error(f"Resource remix failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/resources/<resource_id>/rate', methods=['POST'])
@require_auth
def rate_resource(resource_id):
    """Rate and provide feedback on community resources"""
    try:
        if resource_id not in community_library:
            return jsonify({'success': False, 'error': 'Resource not found'}), 404
        
        data = request.json
        rating = {
            'rating': data['rating'],  # 1-5 stars
            'feedback': data.get('feedback', ''),
            'teacher_id': data.get('teacher_id', 'anonymous'),
            'date': datetime.now().isoformat()
        }
        
        community_library[resource_id]['metadata']['ratings'].append(rating)
        
        return jsonify({'success': True, 'message': 'Rating saved successfully'})
    except Exception as e:
        logger.error(f"Resource rating failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

# ==================== ANALYTICS ENDPOINTS ====================

@app.route('/analytics/student-progress', methods=['GET'])
@require_auth
def get_student_progress():
    """Get student progress analytics"""
    try:
        student_id = request.args.get('student_id')
        if not student_id:
            return jsonify({'success': False, 'error': 'Student ID required'}), 400
        
        progress = student_progress.get(student_id, {
            'assessments': [],
            'activities_completed': 0,
            'reading_level': 'Not assessed',
            'strengths': [],
            'areas_for_improvement': []
        })
        
        return jsonify({'success': True, 'progress': progress})
    except Exception as e:
        logger.error(f"Student progress retrieval failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/analytics/student-progress', methods=['POST'])
@require_auth
def update_student_progress():
    """Update student progress data"""
    try:
        data = request.json
        student_id = data['student_id']
        
        if student_id not in student_progress:
            student_progress[student_id] = {
                'assessments': [],
                'activities_completed': 0,
                'reading_level': 'Not assessed',
                'strengths': [],
                'areas_for_improvement': []
            }
        
        # Update progress
        if 'assessment' in data:
            student_progress[student_id]['assessments'].append({
                **data['assessment'],
                'date': datetime.now().isoformat()
            })
        
        if 'activity_completed' in data:
            student_progress[student_id]['activities_completed'] += 1
        
        if 'reading_level' in data:
            student_progress[student_id]['reading_level'] = data['reading_level']
        
        if 'strengths' in data:
            student_progress[student_id]['strengths'] = data['strengths']
        
        if 'areas_for_improvement' in data:
            student_progress[student_id]['areas_for_improvement'] = data['areas_for_improvement']
        
        return jsonify({'success': True, 'message': 'Progress updated successfully'})
    except Exception as e:
        logger.error(f"Student progress update failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/analytics/class-dashboard', methods=['GET'])
@require_auth
def get_class_dashboard():
    """Get class performance dashboard data"""
    try:
        class_id = request.args.get('class_id', 'default')
        
        # Calculate class statistics
        total_students = len(student_progress)
        avg_activities = sum(p.get('activities_completed', 0) for p in student_progress.values()) / max(total_students, 1)
        
        reading_levels = {}
        for progress in student_progress.values():
            level = progress.get('reading_level', 'Not assessed')
            reading_levels[level] = reading_levels.get(level, 0) + 1
        
        dashboard_data = {
            'class_id': class_id,
            'total_students': total_students,
            'average_activities_completed': avg_activities,
            'reading_level_distribution': reading_levels,
            'resources_created': len(community_library),
            'class_analytics': class_analytics,
            'last_updated': datetime.now().isoformat()
        }
        
        return jsonify({'success': True, 'dashboard': dashboard_data})
    except Exception as e:
        logger.error(f"Class dashboard retrieval failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/analytics/intervention-suggestions', methods=['GET'])
@require_auth
def get_intervention_suggestions():
    """Get AI-powered intervention suggestions for struggling students"""
    try:
        class_id = request.args.get('class_id', 'default')
        
        # Identify students needing help
        students_needing_help = []
        for student_id, progress in student_progress.items():
            if progress.get('activities_completed', 0) < 5 or progress.get('reading_level') == 'Below Grade Level':
                students_needing_help.append({
                    'student_id': student_id,
                    'areas': progress.get('areas_for_improvement', []),
                    'completed_activities': progress.get('activities_completed', 0)
                })
        
        # Generate intervention suggestions
        suggestions = []
        for student in students_needing_help:
            prompt = f"""Suggest 3 specific intervention strategies for a student who:
            - Has completed only {student['completed_activities']} activities
            - Needs improvement in: {', '.join(student['areas'])}
            
            Provide practical, easy-to-implement strategies for a rural Indian classroom."""
            
            # Mock suggestion for now
            suggestions.append({
                'student_id': student['student_id'],
                'strategies': [
                    "Pair with a peer tutor for 15 minutes daily",
                    "Use visual aids and local language explanations",
                    "Provide extra practice with simplified worksheets"
                ]
            })
        
        return jsonify({'success': True, 'interventions': suggestions})
    except Exception as e:
        logger.error(f"Intervention suggestions failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

# ==================== PARENT COMMUNICATION ENDPOINTS ====================

@app.route('/parent-communication/send', methods=['POST'])
@require_auth
def send_to_parents():
    """Send audio stories or exercises to parents via WhatsApp"""
    try:
        data = request.json
        
        # Mock WhatsApp integration
        message_record = {
            'id': str(uuid.uuid4()),
            'parent_phone': data['phone'],
            'content_type': data['type'],  # 'audio_story', 'exercise', 'progress_report'
            'content': data['content'],
            'student_name': data['student_name'],
            'sent_at': datetime.now().isoformat(),
            'status': 'sent'  # In production, track delivery status
        }
        
        # In production, integrate with WhatsApp Business API
        # For now, just log the message
        logger.info(f"Parent message queued: {message_record}")
        
        return jsonify({
            'success': True, 
            'message_id': message_record['id'],
            'status': 'Message queued for delivery'
        })
    except Exception as e:
        logger.error(f"Parent communication failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/parent-communication/templates', methods=['GET'])
def get_parent_templates():
    """Get pre-made templates for parent communication"""
    try:
        templates = [
            {
                'id': 'daily_update',
                'name': 'Daily Progress Update',
                'content': 'Dear Parent, {student_name} completed {activities} activities today. Areas of focus: {focus_areas}.'
            },
            {
                'id': 'homework_reminder',
                'name': 'Homework Reminder',
                'content': 'Namaste! Please help {student_name} complete the homework: {homework_details}'
            },
            {
                'id': 'achievement',
                'name': 'Achievement Celebration',
                'content': 'Congratulations! {student_name} achieved {achievement}. Keep encouraging!'
            }
        ]
        
        return jsonify({'success': True, 'templates': templates})
    except Exception as e:
        logger.error(f"Template retrieval failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

# ==================== OFFLINE SUPPORT ENDPOINTS ====================

@app.route('/offline/sync', methods=['POST'])
@require_auth
def sync_offline_data():
    """Sync offline data when connection is restored"""
    try:
        data = request.json
        offline_data = data.get('offline_data', [])
        
        sync_results = {
            'synced': 0,
            'failed': 0,
            'errors': []
        }
        
        for item in offline_data:
            try:
                # Process each offline item based on its type
                if item['type'] == 'resource':
                    resource_id = str(uuid.uuid4())
                    community_library[resource_id] = item['data']
                    sync_results['synced'] += 1
                elif item['type'] == 'progress':
                    student_id = item['data']['student_id']
                    if student_id not in student_progress:
                        student_progress[student_id] = {}
                    student_progress[student_id].update(item['data'])
                    sync_results['synced'] += 1
                else:
                    offline_queue.append(item)
                    sync_results['synced'] += 1
            except Exception as e:
                sync_results['failed'] += 1
                sync_results['errors'].append(str(e))
        
        return jsonify({
            'success': True,
            'sync_result': sync_results,
            'timestamp': datetime.now().isoformat()
        })
    except Exception as e:
        logger.error(f"Offline sync failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/offline/download-pack', methods=['GET'])
@require_auth
def download_offline_pack():
    """Download essential resources for offline use"""
    try:
        grade = request.args.get('grade')
        subjects = request.args.getlist('subjects')
        
        # Prepare offline content pack
        offline_pack = {
            'version': '1.0',
            'generated_at': datetime.now().isoformat(),
            'resources': [],
            'templates': {
                'worksheet_templates': [],
                'story_templates': [],
                'game_templates': []
            }
        }
        
        # Include relevant resources from community library
        for resource_id, resource in community_library.items():
            metadata = resource.get('metadata', {})
            if grade and str(grade) in str(metadata.get('grades', [])):
                offline_pack['resources'].append({
                    'id': resource_id,
                    'type': resource['type'],
                    'content': resource['content'],
                    'metadata': metadata
                })
        
        # Limit pack size
        offline_pack['resources'] = offline_pack['resources'][:50]
        
        return jsonify({
            'success': True,
            'offline_pack': offline_pack,
            'size_mb': len(json.dumps(offline_pack)) / (1024 * 1024)
        })
    except Exception as e:
        logger.error(f"Offline pack generation failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

# ==================== USER SESSION ENDPOINTS ====================

@app.route('/session/classroom-context', methods=['POST'])
@require_auth
def set_classroom_context():
    """Set classroom context for personalized content"""
    try:
        data = request.json
        teacher_id = data.get('teacher_id', 'anonymous')
        
        user_sessions[teacher_id] = {
            'grades': data['grades'],
            'subjects': data['subjects'],
            'language': data['language'],
            'total_students': data.get('total_students', 0),
            'classroom_resources': data.get('resources', []),
            'last_updated': datetime.now().isoformat()
        }
        
        return jsonify({'success': True, 'message': 'Classroom context saved'})
    except Exception as e:
        logger.error(f"Context setting failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/session/classroom-context', methods=['GET'])
@require_auth
def get_classroom_context():
    """Get saved classroom context"""
    try:
        teacher_id = request.args.get('teacher_id', 'anonymous')
        context = user_sessions.get(teacher_id, {})
        
        return jsonify({'success': True, 'context': context})
    except Exception as e:
        logger.error(f"Context retrieval failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

# ==================== UTILITY ENDPOINTS ====================

@app.route('/languages', methods=['GET'])
def get_supported_languages():
    """Get list of supported languages"""
    languages = [
        'Hindi', 'English', 'Marathi', 'Tamil', 'Telugu', 'Kannada',
        'Malayalam', 'Bengali', 'Gujarati', 'Punjabi', 'Odia'
    ]
    return jsonify({'success': True, 'languages': languages})

@app.route('/subjects', methods=['GET'])
def get_subjects():
    """Get list of subjects"""
    subjects = [
        'Mathematics', 'Science', 'Social Studies', 'Language',
        'Environmental Studies', 'Computer Basics', 'Art & Craft',
        'Physical Education', 'Moral Science'
    ]
    return jsonify({'success': True, 'subjects': subjects})

@app.route('/game-types', methods=['GET'])
def get_game_types():
    """Get available educational game types"""
    game_types = [
        {'id': 'vocabulary_bingo', 'name': 'Vocabulary Bingo', 'subjects': ['Language', 'English']},
        {'id': 'math_puzzle', 'name': 'Math Puzzles', 'subjects': ['Mathematics']},
        {'id': 'science_quiz', 'name': 'Science Quiz', 'subjects': ['Science']},
        {'id': 'memory_game', 'name': 'Memory Game', 'subjects': ['All']},
        {'id': 'word_building', 'name': 'Word Building', 'subjects': ['Language']},
        {'id': 'number_race', 'name': 'Number Race', 'subjects': ['Mathematics']},
        {'id': 'story_sequence', 'name': 'Story Sequencing', 'subjects': ['Language']},
        {'id': 'shape_hunt', 'name': 'Shape Hunt', 'subjects': ['Mathematics', 'Art & Craft']}
    ]
    return jsonify({'success': True, 'game_types': game_types})

# ==================== AUTHENTICATION ENDPOINTS ====================

@app.route('/auth/login', methods=['POST'])
def login():
    """Simple login endpoint to get a token"""
    data = request.json
    username = data.get('username')
    password = data.get('password')
    
    # Simple validation (in production, check against database)
    if username and password:  # Add real validation here
        # Generate token
        token_data = {
            'username': username,
            'exp': datetime.utcnow() + timedelta(hours=24),
            'iat': datetime.utcnow()
        }
        token = jwt.encode(token_data, app.config['SECRET_KEY'], algorithm='HS256')
        
        return jsonify({
            'success': True,
            'token': token,
            'expires_in': 86400  # 24 hours
        })
    
    return jsonify({'success': False, 'error': 'Invalid credentials'}), 401

@app.route('/auth/register', methods=['POST'])
def register():
    """Simple registration endpoint"""
    data = request.json
    # In production, save to database
    return jsonify({
        'success': True,
        'message': 'Registration successful. Please login to get your token.'
    })

# ==================== ERROR HANDLERS ====================

@app.errorhandler(404)
def not_found(error):
    return jsonify({'success': False, 'error': 'Endpoint not found'}), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Internal server error: {str(error)}")
    return jsonify({'success': False, 'error': 'Internal server error'}), 500

@app.errorhandler(413)
def request_entity_too_large(error):
    return jsonify({'success': False, 'error': 'File too large. Maximum size is 16MB'}), 413

# ==================== MAIN ====================

if __name__ == '__main__':
    # Development server
    app.run(debug=True, port=5000, host='0.0.0.0')
    
    # Production notes:
    # 1. Use gunicorn or similar WSGI server
    # 2. Enable HTTPS
    # 3. Implement proper Firebase authentication
    # 4. Replace in-memory storage with Firebase Firestore
    # 5. Implement actual WhatsApp Business API integration
    # 6. Implement actual Vertex AI Speech-to-Text
    # 7. Add request rate limiting
    # 8. Add comprehensive logging and monitoring
    # 9. Implement data validation and sanitization
    # 10. Add API versioning (/api/v1/)