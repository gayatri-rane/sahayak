# AFTER (Enhanced):
from flask import Flask, request, jsonify, send_file, Response
from flask_cors import CORS
from werkzeug.utils import secure_filename
from werkzeug.security import generate_password_hash, check_password_hash
from gemini.sahayak_ai import SahayakAI
import base64
import json
import os
import uuid
from datetime import datetime, timedelta, timezone
import logging
from functools import wraps
import time
import secrets
import jwt
# NEW IMPORTS FOR ENHANCED FEATURES:
import redis
import asyncio
from typing import Dict, List, Any, Optional
import mimetypes
import zipfile
import io
import traceback
from PIL import Image, ImageDraw, ImageFont
import numpy as np
import cv2
import qrcode
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
import smtplib
import hashlib
from collections import defaultdict
import schedule
import threading
import math

# Initialize Flask app
app = Flask(__name__)
CORS(app)  # Enable CORS for frontend communication

# Add these configurations
valid_tokens = {}  # In production, use Redis or database

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize AI
ai = SahayakAI()

# ==================== 3. CONFIGURATION ====================
app.config.update({
    'SECRET_KEY': os.environ.get('SECRET_KEY', secrets.token_urlsafe(32)),
    'JWT_SECRET_KEY': os.environ.get('JWT_SECRET_KEY', secrets.token_urlsafe(32)),
    'JWT_ACCESS_TOKEN_EXPIRES': timedelta(hours=24),
    'JWT_REFRESH_TOKEN_EXPIRES': timedelta(days=30),
    'MAX_CONTENT_LENGTH': 50 * 1024 * 1024,  # Increased to 50MB
    'UPLOAD_FOLDER': 'uploads',
    'TEMP_FOLDER': 'temp',
    'EXPORT_FOLDER': 'exports',
    'ALLOWED_EXTENSIONS': {'png', 'jpg', 'jpeg', 'gif', 'mp3', 'wav', 'ogg', 'webm', 'pdf', 'docx', 'xlsx'},
    'ALLOWED_VIDEO_EXTENSIONS': {'mp4', 'avi', 'mov', 'webm'},
    'REDIS_URL': os.environ.get('REDIS_URL', 'redis://localhost:6379/0'),
    'RATE_LIMIT_PER_MINUTE': 30,
    'RATE_LIMIT_PER_HOUR': 500,
    # Email configuration
    'SMTP_SERVER': os.environ.get('SMTP_SERVER', 'smtp.gmail.com'),
    'SMTP_PORT': int(os.environ.get('SMTP_PORT', 587)),
    'SMTP_USERNAME': os.environ.get('SMTP_USERNAME'),
    'SMTP_PASSWORD': os.environ.get('SMTP_PASSWORD'),
    'ADMIN_EMAIL': os.environ.get('ADMIN_EMAIL', 'admin@sahayak-ai.com'),
    # Feature flags
    'ENABLE_ANALYTICS': True,
    'ENABLE_CACHING': True,
    'CACHE_TTL': 3600,
    'SESSION_TIMEOUT': 3600,
    'ENABLE_NOTIFICATIONS': True,
    'WEBHOOK_URL': os.environ.get('WEBHOOK_URL'),
    # Extended language support
    'SUPPORTED_LANGUAGES': [
        'Hindi', 'English', 'Marathi', 'Tamil', 'Telugu', 'Kannada',
        'Malayalam', 'Bengali', 'Gujarati', 'Punjabi', 'Odia', 'Urdu',
        'Assamese', 'Kashmiri', 'Nepali', 'Sanskrit'
    ],
    'GRADE_LEVELS': list(range(1, 13)),  # Classes 1-12
    'DIFFICULTY_LEVELS': ['Beginner', 'Intermediate', 'Advanced', 'Expert'],
    'ASSESSMENT_TYPES': ['Formative', 'Summative', 'Diagnostic', 'Performance-based'],
    'CONTENT_CATEGORIES': [
        'Story', 'Worksheet', 'Lesson Plan', 'Assessment', 'Game', 
        'Visual Aid', 'Experiment', 'Project', 'Assignment', 'Quiz'
    ]
})

# Create upload folder if it doesn't exist
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

# In-memory storage (replace with Firebase in production)
# Replace the PersistentStorage class in your app.py with this fixed version:

# ==================== 4. CREATE DIRECTORIES ====================

# Also add this function to create directories at startup
def create_required_directories():
    """Create all necessary directories"""
    directories = [
        'uploads',
        'temp', 
        'exports',
        'data',
        'logs'
    ]
    
    for directory in directories:
        os.makedirs(directory, exist_ok=True)
        print(f"✓ Created directory: {directory}")

# Call this immediately
create_required_directories()

# ==================== 5. STORAGE CLASS DEFINITION ====================
class PersistentStorage:
    def __init__(self):
        self.community_library = {}
        self.student_progress = {}
        self.class_analytics = {
            '_system': {
                'api_calls': 0,
                'content_generated': 0,
                'content_types': {},
                'avg_generation_time': 0,
                'generation_count': 0
            }
        }
        self.resource_ratings = defaultdict(list)
        self.offline_queue = []
        self.user_sessions = {}
        # Knowledge base structure
        self.knowledge_base = {
            'pedagogy': [],
            'curriculum': [],
            'classroom_management': [],
            'assessment': [],
            'technology': [],
            'special_needs': [],
            'parent_engagement': [],
            'professional_development': [],
            'health_safety': [],
            'extracurricular': []
        }
        self.user_preferences = {}
        self.notification_queue = defaultdict(list)
        self.collaboration_rooms = {}
        self.achievement_badges = {}
        self.curriculum_mappings = {}
        
        # Load existing data if available
        self.load_from_disk()
    
    def load_from_disk(self):
        """Load persisted data from disk if available"""
        try:
            data_file = 'data/storage_backup.json'
            if os.path.exists(data_file):
                with open(data_file, 'r') as f:
                    data = json.load(f)
                    
                # Load each component safely
                self.community_library = data.get('community_library', {})
                self.student_progress = data.get('student_progress', {})
                self.knowledge_base = data.get('knowledge_base', self.knowledge_base)
                self.resource_ratings = defaultdict(list, data.get('resource_ratings', {}))
                self.user_preferences = data.get('user_preferences', {})
                self.curriculum_mappings = data.get('curriculum_mappings', {})
                
                app.logger.info(f'Loaded storage from disk: {len(self.community_library)} resources')
        except Exception as e:
            app.logger.warning(f'Could not load storage from disk: {str(e)}')
            # Continue with empty storage
    
    def save_to_disk(self):
        """Periodically save to disk for persistence"""
        try:
            # Ensure data directory exists
            os.makedirs('data', exist_ok=True)
            
            data = {
                'community_library': self.community_library,
                'student_progress': self.student_progress,
                'knowledge_base': self.knowledge_base,
                'resource_ratings': dict(self.resource_ratings),
                'user_preferences': self.user_preferences,
                'curriculum_mappings': self.curriculum_mappings,
                'last_saved': get_utc_now().isoformat()  # Use the helper function
            }
            
            # Write to temporary file first
            temp_file = 'data/storage_backup.tmp'
            with open(temp_file, 'w') as f:
                json.dump(data, f, default=str, indent=2)
            
            # Move to actual file (atomic operation)
            final_file = 'data/storage_backup.json'
            if os.path.exists(temp_file):
                if os.path.exists(final_file):
                    os.remove(final_file)
                os.rename(temp_file, final_file)
                
            app.logger.info(f'Saved storage to disk: {len(self.community_library)} resources')
        except Exception as e:
            app.logger.error(f'Failed to save storage: {str(e)}')

# ==================== 6. INITIALIZE STORAGE ====================
storage = PersistentStorage()

# Set up periodic saving
def setup_periodic_save():
    """Set up periodic saving of storage"""
    def save_task():
        while True:
            time.sleep(300)  # 5 minutes
            try:
                storage.save_to_disk()
            except Exception as e:
                app.logger.error(f"Periodic save failed: {e}")
    
    save_thread = threading.Thread(target=save_task, daemon=True)
    save_thread.start()

# Start periodic saving
setup_periodic_save()

# ==================== 7. REDIS CONNECTION ====================
try:
    redis_client = redis.from_url(app.config['REDIS_URL'])
    redis_client.ping()
    app.logger.info('Redis connected successfully')
    REDIS_AVAILABLE = True
except Exception as e:
    app.logger.warning(f'Redis not available: {str(e)} - Running without caching')
    redis_client = None
    REDIS_AVAILABLE = False
    # Disable Redis-dependent features
    app.config['ENABLE_CACHING'] = False

# ==================== 8. INITIALIZE AI ====================
try:
    from gemini.sahayak_ai import SahayakAI  # Adjust import path as needed
    ai = SahayakAI()
    print("✓ SahayakAI initialized successfully")
except Exception as e:
    print(f"✗ Error with SahayakAI: {e}")
    class MockAI:
        def _generate_with_retry(self, *args, **kwargs):
            return "Mock response - Please configure SahayakAI properly"
    ai = MockAI()

# ==================== 9. HELPER FUNCTIONS AND DECORATORS ====================

def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in app.config['ALLOWED_EXTENSIONS']

def require_auth(f):
    """Enhanced auth decorator with role-based access"""
    @wraps(f)
    def decorated_function(*args, **kwargs):
        auth_header = request.headers.get('Authorization')
        if not auth_header or not auth_header.startswith('Bearer '):
            return jsonify({'success': False, 'error': 'No valid authorization header'}), 401
        
        try:
            token = auth_header.split(' ')[1]
            payload = jwt.decode(token, app.config['JWT_SECRET_KEY'], algorithms=['HS256'])
            
            if payload.get('type') != 'access':
                return jsonify({'success': False, 'error': 'Invalid token type'}), 401
            
            request.user_id = payload['user_id']
            request.user_role = storage.user_sessions.get(payload['user_id'], {}).get('role', 'teacher')
            
            return f(*args, **kwargs)
        except jwt.ExpiredSignatureError:
            return jsonify({'success': False, 'error': 'Token expired'}), 401
        except jwt.InvalidTokenError:
            return jsonify({'success': False, 'error': 'Invalid token'}), 401
    
    return decorated_function

def rate_limit(max_requests_per_minute: int = None, max_requests_per_hour: int = None):
    """Enhanced rate limiting decorator"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if not redis_client:
                return f(*args, **kwargs)
            
            client_id = request.remote_addr
            if hasattr(request, 'user_id'):
                client_id = request.user_id
            
            # Check minute limit
            if max_requests_per_minute:
                minute_key = f"rate_limit:minute:{client_id}:{datetime.now(timezone.utc).minute}"
                try:
                    requests = redis_client.incr(minute_key)
                    if requests == 1:
                        redis_client.expire(minute_key, 60)
                    if requests > max_requests_per_minute:
                        return jsonify({
                            'success': False, 
                            'error': 'Rate limit exceeded',
                            'retry_after': 60
                        }), 429
                except:
                    pass
            
            return f(*args, **kwargs)
        return decorated_function
    return decorator

def generate_tokens(user_id: str) -> Dict[str, str]:
    """Generate access and refresh tokens"""
    access_payload = {
        'user_id': user_id,
        'exp': datetime.now(timezone.utc) + app.config['JWT_ACCESS_TOKEN_EXPIRES'],
        'type': 'access'
    }
    refresh_payload = {
        'user_id': user_id,
        'exp': datetime.now(timezone.utc) + app.config['JWT_REFRESH_TOKEN_EXPIRES'],
        'type': 'refresh'
    }
    
    access_token = jwt.encode(access_payload, app.config['JWT_SECRET_KEY'], algorithm='HS256')
    refresh_token = jwt.encode(refresh_payload, app.config['JWT_SECRET_KEY'], algorithm='HS256')
    
    return {
        'access_token': access_token,
        'refresh_token': refresh_token,
        'token_type': 'Bearer',
        'expires_in': app.config['JWT_ACCESS_TOKEN_EXPIRES'].total_seconds()
    }



# NEW: Role-based access control
def require_role(allowed_roles: List[str]):
    """Role-based access control decorator"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if hasattr(request, 'user_role') and request.user_role in allowed_roles:
                return f(*args, **kwargs)
            return jsonify({'success': False, 'error': 'Insufficient permissions'}), 403
        return decorated_function
    return decorator


# ============ NEW VISUAL AID ENDPOINTS ============
# This is completely new functionality

@app.route('/create-visual-aid-complete', methods=['POST'])
@require_auth
@rate_limit(max_requests_per_minute=5)
def create_complete_visual_aid():
    """Create visual aid with instructions, image, and multiple formats"""
    try:
        data = request.json
        concept = data['concept']
        medium = data.get('drawing_medium', 'blackboard')
        include_ar = data.get('include_ar', False)
        
        app.logger.info(f"Creating visual aid for concept: {concept}, medium: {medium}")
        
        # Generate comprehensive visual aid
        visual_aid_data = ai.create_visual_aid_with_description(
            concept=concept,
            drawing_medium=medium,
            include_variations=True
        )
        
        app.logger.info(f"Visual aid data generated: {bool(visual_aid_data)}")
        
        # Generate actual image using custom generation
        app.logger.info("Generating educational diagram...")
        image_data = generate_educational_diagram(
            concept=concept,
            style=medium,
            instructions=visual_aid_data.get('drawing_instructions', '')
        )
        
        app.logger.info(f"Image data generated: {bool(image_data)}, has base64: {bool(image_data and image_data.get('base64'))}")
        
        # Initialize variables
        formats = {}
        image_id = str(uuid.uuid4())
        
        # Save image in multiple formats
        if image_data and image_data.get('base64'):
            try:
                base_path = os.path.join(app.config['UPLOAD_FOLDER'], image_id)
                
                # Save as PNG
                png_path = f"{base_path}.png"
                app.logger.info(f"Saving PNG to: {png_path}")
                
                # Decode base64 and save
                image_bytes = base64.b64decode(image_data['base64'])
                with open(png_path, 'wb') as f:
                    f.write(image_bytes)
                formats['png'] = f"/download/{image_id}.png"
                
                # Convert to SVG (simplified)
                try:
                    svg_content = create_svg_from_concept(concept)
                    svg_path = f"{base_path}.svg"
                    with open(svg_path, 'w', encoding='utf-8') as f:
                        f.write(svg_content)
                    formats['svg'] = f"/download/{image_id}.svg"
                except Exception as e:
                    app.logger.error(f"SVG creation failed: {str(e)}")
                
                # Create PDF with instructions and image
                try:
                    pdf_path = create_visual_aid_pdf(
                        concept=concept,
                        instructions=visual_aid_data.get('drawing_instructions', ''),
                        image_path=png_path
                    )
                    formats['pdf'] = f"/download/{os.path.basename(pdf_path)}"
                except Exception as e:
                    app.logger.error(f"PDF creation failed: {str(e)}")
                
                app.logger.info(f"All formats saved: {formats}")
                
            except Exception as e:
                app.logger.error(f"Error saving files: {str(e)}")
                import traceback
                app.logger.error(traceback.format_exc())
        else:
            app.logger.warning("No image data generated, creating placeholder")
            # Create a simple placeholder if image generation failed
            image_data = create_placeholder_image(concept)
        
        # Generate AR marker if requested
        ar_marker = None
        if include_ar and image_data:
            try:
                ar_marker = generate_ar_marker(concept, image_id)
            except Exception as e:
                app.logger.error(f"AR marker generation failed: {str(e)}")
        
        # Generate QR code
        qr_code = None
        try:
            if image_data:
                qr_code = generate_qr_code(f"https://sahayak-ai.com/visual/{image_id}")
        except Exception as e:
            app.logger.error(f"QR code generation failed: {str(e)}")
        
        # Create interactive version
        interactive_data = None
        try:
            interactive_data = ai.create_interactive_visual_aid(
                concept=concept,
                interaction_type='labeling'
            )
        except Exception as e:
            app.logger.error(f"Interactive visual aid generation failed: {str(e)}")
            interactive_data = {
                'concept': concept,
                'interaction_type': 'labeling',
                'template': 'Interactive template would go here',
                'materials_needed': ['pencil', 'paper'],
                'time_estimate': {'total': 20},
                'learning_outcomes': ['Understanding of ' + concept]
            }
        
        # Package complete response
        response_data = {
            'success': True,
            'visual_aid': {
                'concept': concept,
                'instructions': visual_aid_data.get('drawing_instructions', 'No instructions generated'),
                'variations': visual_aid_data.get('variations', []),
                'teaching_tips': visual_aid_data.get('teaching_tips', []),
                'image': {
                    'base64': image_data.get('base64') if image_data else None,
                    'source': 'custom',
                    'formats': formats
                },
                'interactive': interactive_data,
                'accessibility': {
                    'alt_text': f"Educational diagram showing {concept}",
                    'description': visual_aid_data.get('accessibility_description', ''),
                    'tactile_instructions': generate_tactile_instructions(concept)
                },
                'qr_code': qr_code,
                'ar_marker': ar_marker
            }
        }
        
        app.logger.info("Response data prepared successfully")
        return jsonify(response_data)
        
    except Exception as e:
        app.logger.error(f"Visual aid creation failed: {str(e)}")
        import traceback
        app.logger.error(traceback.format_exc())
        return jsonify({'success': False, 'error': str(e), 'traceback': traceback.format_exc()}), 500


def cache_response(ttl: int = None):
    """Response caching decorator"""
    def decorator(f):
        @wraps(f)
        def decorated_function(*args, **kwargs):
            if not redis_client or not app.config['ENABLE_CACHING']:
                return f(*args, **kwargs)
            
            # Generate cache key
            cache_key = f"cache:{request.endpoint}:{request.path}:{str(request.args)}"
            
            try:
                # Check cache
                cached = redis_client.get(cache_key)
                if cached:
                    return json.loads(cached)
                
                # Generate response
                response = f(*args, **kwargs)
                
                # Cache response
                if isinstance(response, tuple):
                    response_data, status_code = response
                    if status_code == 200:
                        redis_client.setex(
                            cache_key, 
                            ttl or app.config['CACHE_TTL'], 
                            json.dumps(response_data.get_json())
                        )
                else:
                    redis_client.setex(
                        cache_key, 
                        ttl or app.config['CACHE_TTL'], 
                        json.dumps(response.get_json())
                    )
                
                return response
            except:
                return f(*args, **kwargs)
        return decorated_function
    return decorator

# NEW: Educational diagram generation function
def generate_educational_diagram(concept: str, style: str, instructions: str) -> Dict[str, Any]:
    """Generate educational diagram using PIL/OpenCV"""
    try:
        # Create base image
        width, height = 1200, 900
        if style == 'blackboard':
            bg_color = (0, 64, 0)
            fg_color = (255, 255, 255)
        elif style == 'whiteboard':
            bg_color = (255, 255, 255)
            fg_color = (0, 0, 0)
        else:
            bg_color = (255, 255, 240)
            fg_color = (0, 0, 0)
        
        # Create image with PIL
        img = Image.new('RGB', (width, height), bg_color)
        draw = ImageDraw.Draw(img)
        
        # Try to load font, fallback to default
        try:
            title_font = ImageFont.truetype("arial.ttf", 48)
            label_font = ImageFont.truetype("arial.ttf", 24)
        except:
            # Use default font if truetype fonts aren't available
            title_font = ImageFont.load_default()
            label_font = ImageFont.load_default()
        
        # Draw title
        # Calculate text position for centering
        title_bbox = draw.textbbox((0, 0), concept, font=title_font)
        title_width = title_bbox[2] - title_bbox[0]
        title_x = (width - title_width) // 2
        draw.text((title_x, 50), concept, fill=fg_color, font=title_font)
        
        # Concept-specific drawings
        concept_lower = concept.lower()
        
        if 'fraction' in concept_lower:
            draw_fractions_diagram(draw, width, height, fg_color, label_font)
        elif 'cell' in concept_lower:
            draw_cell_diagram(draw, width, height, fg_color, label_font)
        elif 'water cycle' in concept_lower:
            draw_water_cycle_advanced(draw, width, height, fg_color, label_font)
        elif 'triangle' in concept_lower or 'angle' in concept_lower:
            draw_geometry_diagram(draw, width, height, fg_color, label_font)
        elif 'plant' in concept_lower:
            draw_plant_anatomy(draw, width, height, fg_color, label_font)
        elif 'human body' in concept_lower:
            draw_human_body_systems(draw, width, height, fg_color, label_font)
        elif 'solar system' in concept_lower:
            draw_solar_system(draw, width, height, fg_color, label_font)
        elif 'food chain' in concept_lower:
            draw_food_chain(draw, width, height, fg_color, label_font)
        else:
            draw_concept_map(draw, width, height, fg_color, label_font, concept)
        
        # Add instructions overlay if provided
        if instructions:
            # Add a text box with instructions at the bottom
            instruction_y = height - 100
            instruction_text = "Instructions: " + instructions[:100] + "..."
            draw.text((20, instruction_y), instruction_text, fill=fg_color, font=label_font)
        
        # Convert to base64
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        buffer.seek(0)
        image_base64 = base64.b64encode(buffer.getvalue()).decode()
        
        return {
            'base64': image_base64,
            'width': width,
            'height': height,
            'format': 'png'
        }
        
    except Exception as e:
        app.logger.error(f"Diagram generation failed: {str(e)}")
        import traceback
        app.logger.error(traceback.format_exc())
        # Return a simple placeholder image on error
        return create_placeholder_image(concept)

def create_placeholder_image(concept: str) -> Dict[str, Any]:
    """Create a simple placeholder image when generation fails"""
    try:
        width, height = 800, 600
        img = Image.new('RGB', (width, height), (255, 255, 255))
        draw = ImageDraw.Draw(img)
        
        # Draw border
        draw.rectangle([10, 10, width-10, height-10], outline=(0, 0, 0), width=3)
        
        # Add text
        font = ImageFont.load_default()
        text = f"Educational Diagram: {concept}"
        # Calculate text position
        bbox = draw.textbbox((0, 0), text, font=font)
        text_width = bbox[2] - bbox[0]
        text_height = bbox[3] - bbox[1]
        x = (width - text_width) // 2
        y = (height - text_height) // 2
        draw.text((x, y), text, fill=(0, 0, 0), font=font)
        
        # Add some basic shapes to make it look like a diagram
        # Circle
        draw.ellipse([width//4-50, height//2-50, width//4+50, height//2+50], outline=(0, 0, 255), width=2)
        # Rectangle
        draw.rectangle([3*width//4-50, height//2-50, 3*width//4+50, height//2+50], outline=(255, 0, 0), width=2)
        # Lines connecting them
        draw.line([width//4+50, height//2, 3*width//4-50, height//2], fill=(0, 255, 0), width=2)
        
        # Convert to base64
        buffer = io.BytesIO()
        img.save(buffer, format='PNG')
        buffer.seek(0)
        image_base64 = base64.b64encode(buffer.getvalue()).decode()
        
        return {
            'base64': image_base64,
            'width': width,
            'height': height,
            'format': 'png'
        }
    except Exception as e:
        app.logger.error(f"Placeholder image creation failed: {str(e)}")
        return None

def semantic_search(query: str, category: str) -> List[Dict[str, Any]]:
    """Perform semantic search in knowledge base"""
    results = []
    
    # Simple implementation - in production, use embeddings
    query_lower = query.lower()
    
    if category == 'all':
        search_categories = storage.knowledge_base.keys()
    else:
        search_categories = [category]
    
    for cat in search_categories:
        for entry in storage.knowledge_base.get(cat, []):
            # Calculate relevance score
            score = 0
            content_lower = entry.get('content', '').lower()
            title_lower = entry.get('title', '').lower()
            
            # Title match
            if query_lower in title_lower:
                score += 10
            
            # Content match
            for word in query_lower.split():
                if word in content_lower:
                    score += 1
            
            if score > 0:
                results.append({
                    **entry,
                    'relevance_score': score,
                    'category': cat
                })
    
    # Sort by relevance
    results.sort(key=lambda x: x['relevance_score'], reverse=True)
    return results

def keyword_search(query: str, category: str) -> List[Dict[str, Any]]:
    """Perform keyword search in knowledge base"""
    results = []
    keywords = query.lower().split()
    
    if category == 'all':
        search_categories = storage.knowledge_base.keys()
    else:
        search_categories = [category]
    
    for cat in search_categories:
        for entry in storage.knowledge_base.get(cat, []):
            content = f"{entry.get('title', '')} {entry.get('content', '')}".lower()
            
            # Check if all keywords are present
            if all(keyword in content for keyword in keywords):
                results.append({
                    **entry,
                    'category': cat
                })
    
    return results

def search_external_resources(query: str) -> List[Dict[str, Any]]:
    """Search for external educational resources"""
    # In production, integrate with educational databases/APIs
    return [
        {
            'title': 'NCERT Resources',
            'url': 'https://ncert.nic.in',
            'description': 'Official NCERT educational resources',
            'type': 'official'
        },
        {
            'title': 'DIKSHA Platform',
            'url': 'https://diksha.gov.in',
            'description': 'National platform for school education',
            'type': 'government'
        }
    ]

def create_implementation_roadmap(query: str, response: str, context: Dict[str, Any]) -> Dict[str, Any]:
    """Create implementation roadmap based on query and response"""
    return {
        'phases': [
            {
                'phase': 1,
                'name': 'Preparation',
                'duration': '1 week',
                'tasks': [
                    'Assess current situation',
                    'Gather required resources',
                    'Form implementation team'
                ]
            },
            {
                'phase': 2,
                'name': 'Pilot Implementation',
                'duration': '2 weeks',
                'tasks': [
                    'Start with small group',
                    'Document challenges',
                    'Collect feedback'
                ]
            },
            {
                'phase': 3,
                'name': 'Full Implementation',
                'duration': '4 weeks',
                'tasks': [
                    'Roll out to all students',
                    'Monitor progress',
                    'Make adjustments'
                ]
            }
        ],
        'total_duration': '7 weeks',
        'context_specific': True
    }

def generate_downloadable_resources(topic: str, response: str) -> List[Dict[str, Any]]:
    """Generate downloadable resources for a topic"""
    return [
        {
            'type': 'worksheet',
            'title': f'{topic} Practice Worksheet',
            'format': 'pdf',
            'url': f'/generate/worksheet?topic={topic}'
        },
        {
            'type': 'guide',
            'title': f'{topic} Implementation Guide',
            'format': 'pdf',
            'url': f'/generate/guide?topic={topic}'
        }
    ]

def track_knowledge_search(query: str, category: str, user_id: str):
    """Track knowledge base search analytics"""
    # Update search analytics
    if '_analytics' not in storage.knowledge_base:
        storage.knowledge_base['_analytics'] = {
            'searches': [],
            'popular_queries': {},
            'category_stats': {}
        }
    
    # Record search
    storage.knowledge_base['_analytics']['searches'].append({
        'query': query,
        'category': category,
        'user_id': user_id,
        'timestamp': datetime.now(timezone.utc).isoformat()
    })

def estimate_reading_time(text: str) -> int:
    """Estimate reading time in minutes"""
    words = len(text.split())
    # Average reading speed: 200 words per minute
    return max(1, words // 200)

# ============ NEW KNOWLEDGE BASE ENDPOINTS ============
# This is completely new functionality

@app.route('/knowledge-base/search', methods=['POST'])
@require_auth
@cache_response(ttl=300)  # Cache for 5 minutes
def search_knowledge_base_advanced():
    """Advanced knowledge base search with AI-powered responses"""
    try:
        data = request.json
        query = data['query']
        category = data.get('category', 'all')
        search_type = data.get('search_type', 'semantic')
        include_external = data.get('include_external', False)
        
        # Get user context for personalization
        user_context = {
            'grades': storage.user_preferences.get(request.user_id, {}).get('grades', []),
            'subjects': storage.user_preferences.get(request.user_id, {}).get('subjects', []),
            'language': storage.user_preferences.get(request.user_id, {}).get('language', 'English'),
            'location': storage.user_preferences.get(request.user_id, {}).get('location', 'rural India')
        }
        
        # AI-powered query understanding
        query_analysis = ai.analyze_educational_query(query)
        
        # Generate comprehensive answer
        ai_response = ai.answer_complex_education_query(
            query=query,
            context=user_context
        )
        
        # Search existing knowledge base
        if search_type == 'semantic':
            relevant_entries = semantic_search(query, category)
        else:
            relevant_entries = keyword_search(query, category)
        
        # Get related questions
        related_questions = ai_response.get('related_queries', [])
        
        # External resources if requested
        external_resources = []
        if include_external:
            external_resources = search_external_resources(query)
        
        # Create implementation roadmap
        implementation_roadmap = create_implementation_roadmap(
            query=query,
            response=ai_response['response'],
            context=user_context
        )
        
        # Generate downloadable resources
        downloadable_resources = generate_downloadable_resources(
            topic=query,
            response=ai_response['response']
        )
        
        # Track search analytics
        track_knowledge_search(query, category, request.user_id)
        
        return jsonify({
            'success': True,
            'query': query,
            'query_analysis': query_analysis,
            'ai_response': ai_response['response'],
            'implementation_checklist': ai_response.get('implementation_checklist', []),
            'related_articles': relevant_entries[:10],
            'related_questions': related_questions,
            'external_resources': external_resources,
            'implementation_roadmap': implementation_roadmap,
            'downloadable_resources': downloadable_resources,
            'category': ai_response['category'],
            'difficulty_level': ai_response['difficulty_level'],
            'estimated_reading_time': estimate_reading_time(ai_response['response']),
            'save_options': {
                'can_bookmark': True,
                'can_export': True,
                'can_share': True
            }
        })
        
    except Exception as e:
        app.logger.error(f"Knowledge base search failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/knowledge-base/contribute', methods=['POST'])
@require_auth
@rate_limit(max_requests_per_minute=5)
def contribute_to_knowledge_base():
    """Allow teachers to contribute to knowledge base"""
    try:
        data = request.json
        
        # Validate contribution
        validation_result = validate_knowledge_contribution(data)
        if not validation_result['is_valid']:
            return jsonify({
                'success': False, 
                'error': 'Invalid contribution',
                'validation_errors': validation_result['errors']
            }), 400
        
        # Enhance contribution with AI
        enhanced_content = ai.enhance_knowledge_contribution(
            title=data['title'],
            content=data['content'],
            category=data['category']
        )
        
        # Create entry
        entry = {
            'id': str(uuid.uuid4()),
            'title': data['title'],
            'content': enhanced_content['content'],
            'original_content': data['content'],
            'category': data['category'],
            'subcategory': data.get('subcategory'),
            'tags': enhanced_content['tags'],
            'author': {
                'id': request.user_id,
                'name': data.get('author_name', 'Anonymous'),
                'credentials': data.get('author_credentials', [])
            },
            'metadata': {
                'created_at': datetime.now(timezone.utc).isoformat(),
                'updated_at': datetime.now(timezone.utc).isoformat(),
                'version': 1,
                'language': data.get('language', 'English'),
                'grade_levels': data.get('grade_levels', []),
                'subject_areas': data.get('subject_areas', []),
                'prerequisites': enhanced_content.get('prerequisites', []),
                'learning_objectives': enhanced_content.get('learning_objectives', []),
                'estimated_implementation_time': enhanced_content.get('implementation_time'),
                'required_resources': enhanced_content.get('required_resources', []),
                'evidence_base': data.get('evidence_base', []),
                'case_studies': data.get('case_studies', [])
            },
            'quality_metrics': {
                'completeness_score': calculate_completeness_score(enhanced_content),
                'clarity_score': calculate_clarity_score(enhanced_content['content']),
                'practicality_score': calculate_practicality_score(enhanced_content),
                'peer_review_status': 'pending',
                'expert_verified': False
            },
            'engagement': {
                'views': 0,
                'helpful_votes': 0,
                'implementation_reports': 0,
                'questions': [],
                'success_stories': []
            }
        }
        
        # Add to knowledge base
        storage.knowledge_base[data['category']].append(entry)
        
        # Create notification for moderators
        notify_moderators_new_contribution(entry)
        
        # Award contribution badge
        award_contribution_badge(request.user_id, 'knowledge_contributor')
        
        # Generate shareable link
        share_link = f"https://sahayak-ai.com/knowledge/{entry['id']}"
        
        return jsonify({
            'success': True,
            'entry_id': entry['id'],
            'message': 'Thank you for your contribution!',
            'quality_metrics': entry['quality_metrics'],
            'share_link': share_link,
            'badge_earned': {
                'name': 'Knowledge Contributor',
                'description': 'Contributed to the community knowledge base',
                'icon': '🏆'
            }
        })
        
    except Exception as e:
        app.logger.error(f"Knowledge contribution failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

# ============ NEW AUDIO INPUT ENDPOINTS ============
# This is completely new functionality

@app.route('/audio-input/transcribe', methods=['POST'])
@require_auth
def transcribe_audio_input():
    """Transcribe audio input from teachers for queries or commands"""
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
            input_type = request.form.get('input_type', 'query')  # query, command, feedback
            
            # Here you would integrate with Google Cloud Speech-to-Text or similar
            # For demo purposes, using placeholder
            transcribed_text = transcribe_audio_file(filepath, language)
            
            # Process the transcribed text based on input type
            if input_type == 'command':
                command_result = process_voice_command(transcribed_text, language)
                response_data = {
                    'success': True,
                    'transcribed_text': transcribed_text,
                    'command_result': command_result
                }
            elif input_type == 'feedback':
                # Save audio feedback
                feedback_id = save_audio_feedback(filepath, transcribed_text, language)
                response_data = {
                    'success': True,
                    'transcribed_text': transcribed_text,
                    'feedback_id': feedback_id
                }
            else:  # query
                # Process as regular query
                response_data = {
                    'success': True,
                    'transcribed_text': transcribed_text,
                    'query_type': detect_query_type(transcribed_text)
                }
            
            # Clean up file after processing
            os.remove(filepath)
            
            return jsonify(response_data)
        
        return jsonify({'success': False, 'error': 'Invalid file type'}), 400
    except Exception as e:
        logger.error(f"Audio transcription failed: {str(e)}")
        return jsonify({'success': False, 'error': str(e)}), 500

@app.route('/audio-input/record-settings', methods=['GET'])
def get_audio_record_settings():
    """Get recommended audio recording settings"""
    return jsonify({
        'success': True,
        'settings': {
            'sample_rate': 16000,
            'channels': 1,
            'bit_depth': 16,
            'format': 'wav',
            'max_duration_seconds': 60,
            'supported_formats': ['wav', 'mp3', 'ogg', 'webm'],
            'supported_languages': app.config['SUPPORTED_LANGUAGES']
        }
    })

# ============ NEW UNIVERSAL CONTENT GENERATION ============
@app.route('/generate-content', methods=['POST'])
@require_auth
@rate_limit(max_requests_per_minute=10, max_requests_per_hour=100)
def generate_universal_content():
    """Universal content generation endpoint"""
    try:
        data = request.json
        content_type = data.get('type', 'story')
        
        # Initialize analytics structure if not exists
        if '_system' not in storage.class_analytics:
            storage.class_analytics['_system'] = {
                'api_calls': 0,
                'content_generated': 0,
                'content_types': defaultdict(int),
                'avg_generation_time': 0,
                'generation_count': 0
            }
        
        # Track analytics - Fixed to handle nested defaultdict properly
        storage.class_analytics['_system']['api_calls'] = storage.class_analytics['_system'].get('api_calls', 0) + 1
        storage.class_analytics['_system']['content_generated'] = storage.class_analytics['_system'].get('content_generated', 0) + 1
        
        # Handle content_types as a dict, not defaultdict
        if 'content_types' not in storage.class_analytics['_system']:
            storage.class_analytics['_system']['content_types'] = {}
        
        if content_type not in storage.class_analytics['_system']['content_types']:
            storage.class_analytics['_system']['content_types'][content_type] = 0
        
        storage.class_analytics['_system']['content_types'][content_type] += 1
        
        # Route to appropriate generator
        generators = {
            'story': ai.generate_story,
            'worksheet': ai.create_worksheet_advanced,
            'lesson_plan': ai.create_comprehensive_lesson_plan,
            'assessment': ai.generate_assessment_package,
            'game': ai.generate_educational_game,
            'visual_aid': ai.create_visual_aid_with_description,
            'experiment': ai.design_science_experiment,
            'project': ai.create_project_based_learning,
            'quiz': ai.generate_interactive_quiz,
            'video_script': ai.create_educational_video_script
        }
        
        generator = generators.get(content_type)
        if not generator:
            return jsonify({'success': False, 'error': f'Invalid content type: {content_type}'}), 400
        
        # Generate content
        start_time = time.time()
        
        # Get parameters and ensure they're passed correctly
        parameters = data.get('parameters', {})
        
        app.logger.info(f"Generating {content_type} with parameters: {parameters}")
        
        # Call the generator with parameters
        generated_content = generator(**parameters)
        
        generation_time = time.time() - start_time
        
        app.logger.info(f"Content generated successfully in {generation_time:.2f} seconds")
        
        # Update average generation time
        current_avg = storage.class_analytics['_system'].get('avg_generation_time', 0)
        total_count = storage.class_analytics['_system'].get('generation_count', 0)
        new_avg = ((current_avg * total_count) + generation_time) / (total_count + 1)
        storage.class_analytics['_system']['avg_generation_time'] = new_avg
        storage.class_analytics['_system']['generation_count'] = total_count + 1
        
        # Auto-save to library if requested
        if data.get('save_to_library', False):
            resource_id = str(uuid.uuid4())
            storage.community_library[resource_id] = {
                'id': resource_id,
                'type': content_type,
                'content': generated_content,
                'metadata': {
                    'created_at': datetime.utcnow().isoformat(),
                    'created_by': request.user_id,
                    'language': data.get('language', 'English'),
                    'tags': data.get('tags', []),
                    'curriculum_standards': data.get('curriculum_standards', []),
                    'accessibility_features': data.get('accessibility_features', []),
                    **data.get('metadata', {})
                },
                'analytics': {
                    'views': 0,
                    'downloads': 0,
                    'remixes': 0,
                    'ratings': []
                }
            }
            
            # Send notification
            if app.config['ENABLE_NOTIFICATIONS']:
                if request.user_id not in storage.notification_queue:
                    storage.notification_queue[request.user_id] = []
                
                storage.notification_queue[request.user_id].append({
                    'type': 'content_saved',
                    'message': f'Your {content_type} has been saved to the library',
                    'resource_id': resource_id,
                    'timestamp': datetime.utcnow().isoformat()
                })
            
            return jsonify({
                'success': True, 
                'content': generated_content,
                'resource_id': resource_id,
                'generation_time': generation_time
            })
        
        return jsonify({
            'success': True, 
            'content': generated_content,
            'generation_time': generation_time
        })
        
    except Exception as e:
        app.logger.error(f"Content generation failed: {str(e)}")
        import traceback
        app.logger.error(traceback.format_exc())
        return jsonify({'success': False, 'error': str(e)}), 500

# ==================== 10. ROUTES ====================

@app.route('/health', methods=['GET'])
def health_check():
    """Comprehensive health check"""
    health_status = {
        'success': True,
        'status': 'healthy',
        'timestamp': datetime.now(timezone.utc).isoformat(),
        'version': '2.0.0',
        'services': {
            'api': 'operational',
            'ai': 'operational',
            'redis': 'operational' if redis_client else 'degraded',
            'storage': 'operational'
        },
        'metrics': {
            'total_resources': len(storage.community_library),
            'active_users': len(storage.user_sessions),
            'knowledge_base_entries': sum(len(entries) for entries in storage.knowledge_base.values()),
            'queued_notifications': sum(len(queue) for queue in storage.notification_queue.values())
        },
        'usage_stats': ai.get_usage_stats(),
        'features': {
            'content_generation': True,
            'worksheet_creation': True,
            'visual_aids': True,
            'image_generation': True,  # NEW
            'audio_assessment': True,
            'game_generation': True,
            'lesson_planning': True,
            'community_library': True,
            'analytics': True,
            'parent_communication': True,
            'offline_support': True,
            'multi_modal_input': True,
            'knowledge_base': True,  # NEW
            'collaboration': True,  # NEW
            'gamification': True,  # NEW
            'curriculum_mapping': True,  # NEW
            'advanced_analytics': True,  # NEW
            'export_import': True,  # NEW
            'notifications': app.config['ENABLE_NOTIFICATIONS'],  # NEW
            'video_support': True,  # NEW
            'ar_vr_ready': True  # NEW
        }
    }
    
    # Check if any service is degraded
    if any(status != 'operational' for status in health_status['services'].values()):
        health_status['status'] = 'degraded'
    
    return jsonify(health_status)

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
            'exp': datetime.now(timezone.utc) + timedelta(hours=24),
            'iat': datetime.now(timezone.utc)
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

# ==================== MISSING DECORATORS ====================



# ==================== MISSING SEARCH FUNCTIONS ====================

def semantic_search(query: str, category: str) -> List[Dict[str, Any]]:
    """Perform semantic search in knowledge base"""
    results = []
    
    # Simple implementation - in production, use embeddings
    query_lower = query.lower()
    
    if category == 'all':
        search_categories = storage.knowledge_base.keys()
    else:
        search_categories = [category]
    
    for cat in search_categories:
        for entry in storage.knowledge_base.get(cat, []):
            # Calculate relevance score
            score = 0
            content_lower = entry.get('content', '').lower()
            title_lower = entry.get('title', '').lower()
            
            # Title match
            if query_lower in title_lower:
                score += 10
            
            # Content match
            for word in query_lower.split():
                if word in content_lower:
                    score += 1
            
            if score > 0:
                results.append({
                    **entry,
                    'relevance_score': score,
                    'category': cat
                })
    
    # Sort by relevance
    results.sort(key=lambda x: x['relevance_score'], reverse=True)
    return results

def keyword_search(query: str, category: str) -> List[Dict[str, Any]]:
    """Perform keyword search in knowledge base"""
    results = []
    keywords = query.lower().split()
    
    if category == 'all':
        search_categories = storage.knowledge_base.keys()
    else:
        search_categories = [category]
    
    for cat in search_categories:
        for entry in storage.knowledge_base.get(cat, []):
            content = f"{entry.get('title', '')} {entry.get('content', '')}".lower()
            
            # Check if all keywords are present
            if all(keyword in content for keyword in keywords):
                results.append({
                    **entry,
                    'category': cat
                })
    
    return results

def search_external_resources(query: str) -> List[Dict[str, Any]]:
    """Search for external educational resources"""
    # In production, integrate with educational databases/APIs
    return [
        {
            'title': 'NCERT Resources',
            'url': 'https://ncert.nic.in',
            'description': 'Official NCERT educational resources',
            'type': 'official'
        },
        {
            'title': 'DIKSHA Platform',
            'url': 'https://diksha.gov.in',
            'description': 'National platform for school education',
            'type': 'government'
        }
    ]

# ==================== MISSING HELPER FUNCTIONS ====================

def create_implementation_roadmap(query: str, response: str, context: Dict[str, Any]) -> Dict[str, Any]:
    """Create implementation roadmap based on query and response"""
    return {
        'phases': [
            {
                'phase': 1,
                'name': 'Preparation',
                'duration': '1 week',
                'tasks': [
                    'Assess current situation',
                    'Gather required resources',
                    'Form implementation team'
                ]
            },
            {
                'phase': 2,
                'name': 'Pilot Implementation',
                'duration': '2 weeks',
                'tasks': [
                    'Start with small group',
                    'Document challenges',
                    'Collect feedback'
                ]
            },
            {
                'phase': 3,
                'name': 'Full Implementation',
                'duration': '4 weeks',
                'tasks': [
                    'Roll out to all students',
                    'Monitor progress',
                    'Make adjustments'
                ]
            },
            {
                'phase': 4,
                'name': 'Evaluation',
                'duration': '1 week',
                'tasks': [
                    'Assess outcomes',
                    'Document learnings',
                    'Plan next steps'
                ]
            }
        ],
        'total_duration': '8 weeks',
        'context_specific': True
    }

def generate_downloadable_resources(topic: str, response: str) -> List[Dict[str, Any]]:
    """Generate downloadable resources for a topic"""
    return [
        {
            'type': 'worksheet',
            'title': f'{topic} Practice Worksheet',
            'format': 'pdf',
            'url': f'/generate/worksheet?topic={topic}'
        },
        {
            'type': 'guide',
            'title': f'{topic} Implementation Guide',
            'format': 'pdf',
            'url': f'/generate/guide?topic={topic}'
        },
        {
            'type': 'checklist',
            'title': f'{topic} Progress Checklist',
            'format': 'pdf',
            'url': f'/generate/checklist?topic={topic}'
        }
    ]

def track_knowledge_search(query: str, category: str, user_id: str):
    """Track knowledge base search analytics"""
    # Update search analytics
    if '_analytics' not in storage.knowledge_base:
        storage.knowledge_base['_analytics'] = {
            'searches': [],
            'popular_queries': {},
            'category_stats': {}
        }
    
    # Record search
    storage.knowledge_base['_analytics']['searches'].append({
        'query': query,
        'category': category,
        'user_id': user_id,
        'timestamp': datetime.now(timezone.utc).isoformat()
    })
    
    # Update popular queries
    if query in storage.knowledge_base['_analytics']['popular_queries']:
        storage.knowledge_base['_analytics']['popular_queries'][query] += 1
    else:
        storage.knowledge_base['_analytics']['popular_queries'][query] = 1
    
    # Update category stats
    if category in storage.knowledge_base['_analytics']['category_stats']:
        storage.knowledge_base['_analytics']['category_stats'][category] += 1
    else:
        storage.knowledge_base['_analytics']['category_stats'][category] = 1

def estimate_reading_time(text: str) -> int:
    """Estimate reading time in minutes"""
    words = len(text.split())
    # Average reading speed: 200 words per minute
    return max(1, words // 200)

def validate_knowledge_contribution(data: Dict[str, Any]) -> Dict[str, Any]:
    """Validate knowledge base contribution"""
    errors = []
    
    # Required fields
    required_fields = ['title', 'content', 'category']
    for field in required_fields:
        if field not in data or not data[field]:
            errors.append(f'{field} is required')
    
    # Title length
    if 'title' in data and len(data['title']) < 10:
        errors.append('Title must be at least 10 characters')
    
    # Content length
    if 'content' in data and len(data['content']) < 100:
        errors.append('Content must be at least 100 characters')
    
    # Valid category
    valid_categories = list(storage.knowledge_base.keys())
    if 'category' in data and data['category'] not in valid_categories:
        errors.append(f'Invalid category. Must be one of: {", ".join(valid_categories)}')
    
    return {
        'is_valid': len(errors) == 0,
        'errors': errors
    }

def calculate_completeness_score(content: Dict[str, Any]) -> float:
    """Calculate completeness score for content"""
    score = 0
    max_score = 100
    
    # Check for essential components
    if content.get('content'):
        score += 20
    if content.get('tags'):
        score += 10
    if content.get('prerequisites'):
        score += 10
    if content.get('learning_objectives'):
        score += 15
    if content.get('implementation_time'):
        score += 10
    if content.get('required_resources'):
        score += 15
    
    # Content length bonus
    content_length = len(content.get('content', ''))
    if content_length > 500:
        score += 10
    if content_length > 1000:
        score += 10
    
    return (score / max_score) * 100

def calculate_clarity_score(content: str) -> float:
    """Calculate clarity score based on readability"""
    # Simple implementation - in production use readability metrics
    score = 100
    
    # Penalize very long sentences
    sentences = content.split('.')
    avg_sentence_length = sum(len(s.split()) for s in sentences) / max(len(sentences), 1)
    if avg_sentence_length > 20:
        score -= 20
    
    # Penalize very long paragraphs
    paragraphs = content.split('\n\n')
    avg_paragraph_length = sum(len(p.split()) for p in paragraphs) / max(len(paragraphs), 1)
    if avg_paragraph_length > 100:
        score -= 20
    
    return max(0, score)

def calculate_practicality_score(content: Dict[str, Any]) -> float:
    """Calculate practicality score"""
    score = 0
    
    # Check for practical elements
    if content.get('required_resources'):
        resources = content['required_resources']
        # Higher score for fewer resources
        if len(resources) < 5:
            score += 30
        elif len(resources) < 10:
            score += 20
        else:
            score += 10
    
    # Implementation time
    impl_time = content.get('implementation_time', '')
    if '30' in impl_time or '45' in impl_time or 'hour' in impl_time:
        score += 30  # Short implementation time
    elif 'day' in impl_time:
        score += 20
    else:
        score += 10
    
    # Has examples or case studies
    content_text = content.get('content', '').lower()
    if 'example' in content_text or 'case study' in content_text:
        score += 20
    
    # Has step-by-step instructions
    if 'step' in content_text or 'procedure' in content_text:
        score += 20
    
    return min(100, score)

def notify_moderators_new_contribution(entry: Dict[str, Any]):
    """Notify moderators about new contribution"""
    # In production, send actual notifications
    moderator_notification = {
        'type': 'new_contribution',
        'entry_id': entry['id'],
        'title': entry['title'],
        'author': entry['author']['name'],
        'category': entry['category'],
        'timestamp': datetime.now(timezone.utc).isoformat()
    }
    
    # Add to moderator queues
    for mod_id in ['mod_1', 'mod_2']:  # Replace with actual moderator IDs
        storage.notification_queue[mod_id].append(moderator_notification)

def award_contribution_badge(user_id: str, badge_type: str):
    """Award badge to user"""
    if user_id not in storage.achievement_badges:
        storage.achievement_badges[user_id] = []
    
    badge = {
        'type': badge_type,
        'awarded_at': datetime.now(timezone.utc).isoformat(),
        'title': 'Knowledge Contributor',
        'description': 'Contributed valuable content to the knowledge base'
    }
    
    storage.achievement_badges[user_id].append(badge)

# ==================== MISSING DRAWING FUNCTIONS ====================

def draw_fractions_diagram(draw, width, height, color, font):
    """Draw fractions diagram"""
    y_center = height // 2
    spacing = width // 5
    
    fractions = [(1, 2), (1, 3), (1, 4), (2, 3), (3, 4)]
    
    for i, (num, den) in enumerate(fractions):
        x = spacing * (i + 1)
        radius = 60
        
        # Draw circle
        draw.ellipse([x-radius, y_center-radius, x+radius, y_center+radius], 
                     outline=color, width=3)
        
        # Fill fraction
        angle = 360 * num / den
        if angle > 0:
            draw.pieslice([x-radius, y_center-radius, x+radius, y_center+radius],
                         start=0, end=int(angle), fill=color)
        
        # Label
        draw.text((x, y_center + radius + 20), f"{num}/{den}", 
                 fill=color, font=font, anchor="mt")

def draw_cell_diagram(draw, width, height, color, font):
    """Draw cell diagram"""
    # Plant cell
    x1 = width // 3
    y = height // 2
    
    # Cell wall
    draw.rectangle([x1-100, y-80, x1+100, y+80], outline=color, width=3)
    draw.text((x1, y-100), "Plant Cell", fill=color, font=font, anchor="mt")
    
    # Nucleus
    draw.ellipse([x1-30, y-30, x1+30, y+30], outline=color, width=2)
    draw.text((x1, y), "Nucleus", fill=color, font=font, anchor="mm")
    
    # Animal cell
    x2 = 2 * width // 3
    draw.ellipse([x2-100, y-80, x2+100, y+80], outline=color, width=3)
    draw.text((x2, y-100), "Animal Cell", fill=color, font=font, anchor="mt")
    
    # Nucleus
    draw.ellipse([x2-30, y-30, x2+30, y+30], outline=color, width=2)

def draw_water_cycle_advanced(draw, width, height, color, font):
    """Draw water cycle diagram"""
    # Sun
    sun_x, sun_y = width - 150, 100
    draw.ellipse([sun_x-40, sun_y-40, sun_x+40, sun_y+40], fill=color)
    
    # Ocean
    ocean_y = height - 150
    draw.arc([50, ocean_y-50, width-50, ocean_y+100], 
             start=0, end=180, fill=color, width=4)
    # Use simple text positioning without anchor
    ocean_text_bbox = draw.textbbox((0, 0), "Ocean", font=font)
    ocean_text_width = ocean_text_bbox[2] - ocean_text_bbox[0]
    draw.text((width//2 - ocean_text_width//2, ocean_y+30), "Ocean", fill=color, font=font)
    
    # Evaporation arrows
    for x in range(200, width-200, 150):
        draw.line([x, ocean_y, x, ocean_y-100], fill=color, width=2)
        # Arrow head
        draw.polygon([(x, ocean_y-100), (x-10, ocean_y-80), (x+10, ocean_y-80)], fill=color)
    
    # Clouds
    cloud_y = 200
    for x in range(200, width-100, 200):
        # Simple cloud shape using circles
        draw.ellipse([x-30, cloud_y-20, x+30, cloud_y+20], outline=color, width=2)
        draw.ellipse([x-20, cloud_y-30, x+20, cloud_y], outline=color, width=2)
        draw.ellipse([x-40, cloud_y-15, x-10, cloud_y+15], outline=color, width=2)
        draw.ellipse([x+10, cloud_y-15, x+40, cloud_y+15], outline=color, width=2)
    
    # Label for clouds
    draw.text((width//2 - 30, cloud_y - 60), "Clouds", fill=color, font=font)
    
    # Rain
    rain_x = width // 2
    for i in range(5):
        x = rain_x + (i-2) * 20
        for y in range(cloud_y + 50, ocean_y - 50, 30):
            draw.line([x, y, x-5, y+15], fill=color, width=2)
    
    # Labels for process
    draw.text((100, ocean_y - 150), "Evaporation", fill=color, font=font)
    draw.text((rain_x - 30, cloud_y + 100), "Rain", fill=color, font=font)
    
    # Add arrows showing cycle
    # Evaporation arrow
    draw.line([150, ocean_y - 50, 150, cloud_y + 20], fill=color, width=2)
    draw.polygon([(150, cloud_y + 20), (145, cloud_y + 30), (155, cloud_y + 30)], fill=color)
    
    # Condensation arrow
    draw.line([width - 200, cloud_y, width - 100, cloud_y], fill=color, width=2)
    draw.text((width - 250, cloud_y - 30), "Condensation", fill=color, font=font)

def draw_geometry_diagram(draw, width, height, color, font):
    """Draw geometry diagram"""
    # Triangle
    cx, cy = width//2, height//2
    size = 150
    
    # Calculate triangle points
    points = [
        (cx, cy - size),  # Top
        (cx - size, cy + size//2),  # Bottom left
        (cx + size, cy + size//2)   # Bottom right
    ]
    
    # Draw triangle
    draw.polygon(points, outline=color, fill=None, width=3)
    
    # Label vertices
    labels = ['A', 'B', 'C']
    for i, (x, y) in enumerate(points):
        draw.text((x, y), labels[i], fill=color, font=font, anchor="mm")
    
    # Draw angle arc
    draw.arc([cx-30, cy-size-10, cx+30, cy-size+50], 
             start=225, end=315, fill=color, width=2)

def draw_plant_anatomy(draw, width, height, color, font):
    """Draw plant anatomy"""
    cx = width // 2
    
    # Stem
    stem_top = 150
    stem_bottom = height - 150
    draw.line([cx, stem_top, cx, stem_bottom], fill=color, width=5)
    
    # Roots
    for angle in [-30, -15, 0, 15, 30]:
        x_end = cx + angle * 2
        draw.line([cx, stem_bottom, x_end, height - 50], fill=color, width=3)
    
    # Leaves
    leaf_positions = [(cx-80, 250), (cx+80, 300), (cx-80, 350)]
    for x, y in leaf_positions:
        draw.ellipse([x-40, y-20, x+40, y+20], fill=color)
    
    # Flower
    flower_y = stem_top
    for angle in range(0, 360, 60):
        x = cx + 30 * math.cos(math.radians(angle))
        y = flower_y + 30 * math.sin(math.radians(angle))
        draw.ellipse([x-15, y-15, x+15, y+15], fill=color)
    
    # Labels
    draw.text((cx + 100, stem_bottom), "Roots", fill=color, font=font)
    draw.text((cx + 100, (stem_top + stem_bottom) // 2), "Stem", fill=color, font=font)
    draw.text((cx + 100, 300), "Leaves", fill=color, font=font)
    draw.text((cx + 100, flower_y), "Flower", fill=color, font=font)

def draw_human_body_systems(draw, width, height, color, font):
    """Draw human body systems"""
    # Simple human figure outline
    cx = width // 2
    
    # Head
    draw.ellipse([cx-50, 100, cx+50, 200], outline=color, width=3)
    
    # Body
    draw.rectangle([cx-80, 200, cx+80, 500], outline=color, width=3)
    
    # Arms
    draw.line([cx-80, 250, cx-150, 350], fill=color, width=3)
    draw.line([cx+80, 250, cx+150, 350], fill=color, width=3)
    
    # Legs
    draw.line([cx-30, 500, cx-30, 650], fill=color, width=3)
    draw.line([cx+30, 500, cx+30, 650], fill=color, width=3)
    
    # Organs (simplified)
    # Heart
    draw.ellipse([cx-20, 250, cx+20, 290], fill=color)
    draw.text((cx+100, 270), "Heart", fill=color, font=font)
    
    # Lungs
    draw.ellipse([cx-40, 230, cx-10, 310], outline=color, width=2)
    draw.ellipse([cx+10, 230, cx+40, 310], outline=color, width=2)
    draw.text((cx+100, 240), "Lungs", fill=color, font=font)
    
    # Stomach
    draw.ellipse([cx-30, 350, cx+30, 400], outline=color, width=2)
    draw.text((cx+100, 375), "Stomach", fill=color, font=font)

def draw_solar_system(draw, width, height, color, font):
    """Draw solar system"""
    cx, cy = width // 2, height // 2
    
    # Sun
    draw.ellipse([cx-50, cy-50, cx+50, cy+50], fill=color)
    draw.text((cx, cy), "Sun", fill=color, font=font, anchor="mm")
    
    # Planets (simplified)
    planets = [
        ("Mercury", 100, 15),
        ("Venus", 150, 20),
        ("Earth", 200, 22),
        ("Mars", 250, 18),
        ("Jupiter", 350, 40),
        ("Saturn", 450, 35)
    ]
    
    for name, distance, size in planets:
        # Orbit
        draw.ellipse([cx-distance, cy-distance, cx+distance, cy+distance], 
                     outline=color, width=1)
        
        # Planet (at top of orbit)
        planet_x = cx
        planet_y = cy - distance
        draw.ellipse([planet_x-size//2, planet_y-size//2, 
                     planet_x+size//2, planet_y+size//2], 
                     fill=color)
        
        # Label
        draw.text((planet_x + size, planet_y), name, fill=color, font=font)

def draw_food_chain(draw, width, height, color, font):
    """Draw food chain"""
    # Simple food chain
    items = [
        ("Sun", 100, height//2),
        ("Plant", 300, height//2),
        ("Herbivore", 500, height//2),
        ("Carnivore", 700, height//2),
        ("Decomposer", 900, height//2)
    ]
    
    for i, (name, x, y) in enumerate(items):
        # Draw box
        draw.rectangle([x-60, y-40, x+60, y+40], outline=color, width=2)
        draw.text((x, y), name, fill=color, font=font, anchor="mm")
        
        # Draw arrow to next
        if i < len(items) - 1:
            draw.line([x+60, y, items[i+1][1]-60, y], fill=color, width=2)
            # Arrow head
            next_x = items[i+1][1] - 60
            draw.polygon([(next_x, y), (next_x-10, y-5), (next_x-10, y+5)], fill=color)

def draw_concept_map(draw, width, height, color, font, concept):
    """Draw generic concept map"""
    cx, cy = width // 2, height // 2
    
    # Central concept
    draw.ellipse([cx-100, cy-50, cx+100, cy+50], outline=color, width=3)
    draw.text((cx, cy), concept, fill=color, font=font, anchor="mm")
    
    # Related concepts
    positions = [
        (cx-200, cy-150), (cx+200, cy-150),
        (cx-200, cy+150), (cx+200, cy+150)
    ]
    
    sub_concepts = ["Part 1", "Part 2", "Part 3", "Part 4"]
    
    for (x, y), sub in zip(positions, sub_concepts):
        # Draw connection
        draw.line([cx, cy, x, y], fill=color, width=2)
        
        # Draw sub-concept
        draw.ellipse([x-60, y-30, x+60, y+30], outline=color, width=2)
        draw.text((x, y), sub, fill=color, font=font, anchor="mm")

def add_instructions_overlay(img, instructions):
    """Add instructions overlay to image"""
    # This would add a semi-transparent overlay with instructions
    # For simplicity, we'll skip the actual implementation
    pass

def generate_tactile_instructions(concept: str) -> str:
    """Generate tactile instructions"""
    return f"""Tactile Instructions for {concept}:
1. Use cardboard as base (30cm x 30cm)
2. Create raised lines with string or yarn
3. Different textures for different parts:
   - Smooth paper for flat surfaces
   - Sandpaper for rough textures
   - Cotton for soft elements
   - Buttons for points of interest
4. Add Braille labels if possible
5. Create texture legend on side"""

def generate_qr_code(url: str) -> str:
    """Generate QR code"""
    qr = qrcode.QRCode(version=1, box_size=5, border=2)
    qr.add_data(url)
    qr.make(fit=True)
    
    img = qr.make_image(fill_color="black", back_color="white")
    buffer = io.BytesIO()
    img.save(buffer, format='PNG')
    buffer.seek(0)
    
    return base64.b64encode(buffer.getvalue()).decode()

def create_svg_from_concept(concept: str) -> str:
    """Create SVG from concept"""
    # Escape special characters for XML
    import html
    concept_escaped = html.escape(concept)
    
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<svg width="1200" height="900" xmlns="http://www.w3.org/2000/svg">
  <rect width="1200" height="900" fill="#ffffff" stroke="#000000" stroke-width="2"/>
  <text x="600" y="100" text-anchor="middle" font-size="36" font-weight="bold">{concept_escaped}</text>
  <circle cx="600" cy="450" r="150" fill="none" stroke="#000000" stroke-width="3"/>
  <text x="600" y="450" text-anchor="middle" font-size="24">Main Concept</text>
</svg>'''

def create_visual_aid_pdf(concept: str, instructions: str, image_path: str) -> str:
    """Create PDF visual aid"""
    # Simplified - in production use reportlab
    pdf_path = os.path.join(app.config['EXPORT_FOLDER'], f"{uuid.uuid4()}.pdf")
    
    try:
        # Use UTF-8 encoding to handle Unicode characters
        with open(pdf_path, 'w', encoding='utf-8') as f:
            f.write(f"Visual Aid for {concept}\n\n{instructions}")
        
        return pdf_path
    except Exception as e:
        app.logger.error(f"PDF creation failed: {str(e)}")
        # Return a dummy path if PDF creation fails
        return pdf_path

def generate_ar_marker(concept: str, image_id: str) -> Dict[str, Any]:
    """Generate AR marker"""
    ar_data = {
        'type': 'visual_aid',
        'concept': concept,
        'id': image_id,
        'ar_enabled': True
    }
    
    qr_code = generate_qr_code(json.dumps(ar_data))
    
    return {
        'marker_data': ar_data,
        'qr_code': qr_code,
        'instructions': 'Scan with Sahayak AR app'
    }

def transcribe_audio_file(filepath: str, language: str) -> str:
    """Transcribe audio file"""
    # Placeholder - implement Google Cloud Speech-to-Text
    transcriptions = {
        'Hindi': 'मुझे कक्षा ३ के लिए गणित की वर्कशीट चाहिए',
        'English': 'I need a math worksheet for class 3',
        'Marathi': 'मला तिसऱ्या वर्गासाठी गणिताची वर्कशीट हवी आहे'
    }
    return transcriptions.get(language, 'Audio transcription placeholder')

def process_voice_command(text: str, language: str) -> Dict[str, Any]:
    """Process voice command"""
    text_lower = text.lower()
    
    commands = {
        'worksheet': ['worksheet', 'वर्कशीट', 'कार्यपत्रक'],
        'story': ['story', 'कहानी', 'कथा'],
        'game': ['game', 'खेल', 'गेम'],
        'lesson': ['lesson', 'पाठ', 'धडा']
    }
    
    for command, keywords in commands.items():
        if any(keyword in text_lower for keyword in keywords):
            return {
                'command_detected': True,
                'command_type': command,
                'original_text': text
            }
    
    return {
        'command_detected': False,
        'original_text': text
    }

def save_audio_feedback(filepath: str, transcription: str, language: str) -> str:
    """Save audio feedback"""
    feedback_id = str(uuid.uuid4())
    
    # In production, save to cloud storage
    # For now, just return ID
    return feedback_id

def detect_query_type(text: str) -> str:
    """Detect query type from text"""
    text_lower = text.lower()
    
    if any(word in text_lower for word in ['how', 'कैसे', 'कसे']):
        return 'how_to'
    elif any(word in text_lower for word in ['what', 'क्या', 'काय']):
        return 'information'
    elif any(word in text_lower for word in ['create', 'make', 'बनाएं']):
        return 'creation_request'
    else:
        return 'general'

# ==================== MAIN EXECUTION FIX ====================

# Create necessary directories at startup
def create_directories():
    """Create all necessary directories"""
    directories = [
        app.config['UPLOAD_FOLDER'],
        app.config['TEMP_FOLDER'],
        app.config['EXPORT_FOLDER'],
        'data',
        'logs'
    ]
    
    for directory in directories:
        os.makedirs(directory, exist_ok=True)

# Call this after app initialization
create_directories()

# Add this temporary endpoint for testing (add it after your other auth routes)

@app.route('/auth/test-token', methods=['GET'])
def get_test_token():
    """Get a test token for development"""
    # Generate a test token that's valid for 24 hours
    test_user_id = "test_user_123"
    
    # Create tokens
    tokens = generate_tokens(test_user_id)
    
    # Store user session
    storage.user_sessions[test_user_id] = {
        'role': 'teacher',
        'name': 'Test Teacher',
        'created_at': datetime.now(timezone.utc).isoformat()
    }
    
    return jsonify({
        'success': True,
        'message': 'Test token generated',
        'access_token': tokens['access_token'],
        'refresh_token': tokens['refresh_token'],
        'expires_in': tokens['expires_in'],
        'usage': 'Use the access_token in Authorization header as: Bearer <access_token>'
    })

# Fix for deprecation warnings - replace all timezone.utcnow() with datetime.now(timezone.utc)
# Add this import at the top of your file if not already there:
from datetime import timezone

# Then create a helper function:
def get_utc_now():
    """Get current UTC time (compatible with Python 3.12+)"""
    try:
        # For Python 3.12+
        return datetime.now(timezone.utc)
    except AttributeError:
        # For older Python versions
        return timezone.utcnow()

        
# ==================== STARTUP TASKS ====================

def initialize_sample_data():
    """Initialize sample data for testing"""
    # Add sample knowledge base entry
    if not any(storage.knowledge_base.values()):
        sample_entry = {
            'id': 'sample_1',
            'title': 'Introduction to Multi-Grade Teaching',
            'content': 'Multi-grade teaching involves instructing students of different grades in the same classroom...',
            'category': 'pedagogy',
            'tags': ['multi-grade', 'teaching', 'methodology'],
            'author': {
                'id': 'system',
                'name': 'System',
                'credentials': ['System Generated']
            },
            'metadata': {
                'created_at': datetime.now(timezone.utc).isoformat(),
                'language': 'English',
                'grade_levels': [1, 2, 3, 4, 5],
                'subject_areas': ['General']
            }
        }
        storage.knowledge_base['pedagogy'].append(sample_entry)

# Initialize sample data
initialize_sample_data()

# ==================== MAIN ====================

# ==================== 12. MAIN EXECUTION ====================

if __name__ == '__main__':
    print("\n" + "="*50)
    print("🚀 Starting Sahayak AI Backend Server")
    print("="*50)
    print(f"✓ Redis available: {REDIS_AVAILABLE}")
    print(f"✓ AI initialized: {'Yes' if ai else 'No'}")
    print(f"✓ Storage loaded: {len(storage.community_library)} resources")
    print("="*50 + "\n")
    
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