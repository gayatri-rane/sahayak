from flask import Flask, request, jsonify
from gemini.sahayak_ai import SahayakAI
import base64

app = Flask(__name__)
ai = SahayakAI()

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
            }
        })
    except Exception as e:
        return jsonify({
            'success': False,
            'status': 'error',
            'error': str(e)
        })

@app.route('/generate-story', methods=['POST'])
def generate_story():
    try:
        data = request.json
        story = ai.generate_story(
            language=data['language'],
            grade=data['grade'],
            topic=data['topic'],
            context=data['context']
        )
        return jsonify({'success': True, 'story': story})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/create-worksheet', methods=['POST'])
def create_worksheet():
    try:
        data = request.json
        # Handle base64 image
        image_data = data['image'].split(',')[1] if ',' in data['image'] else data['image']
        
        worksheet = ai.create_worksheet_from_image(
            image_data=image_data,
            grades=data['grades']
        )
        return jsonify({'success': True, 'worksheet': worksheet})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

@app.route('/explain-concept', methods=['POST'])
def explain_concept():
    try:
        data = request.json
        explanation = ai.explain_concept(
            question=data['question'],
            language=data['language'],
            grade_level=data['grade_level']
        )
        return jsonify({'success': True, 'explanation': explanation})
    except Exception as e:
        return jsonify({'success': False, 'error': str(e)})

if __name__ == '__main__':
    app.run(debug=True, port=5000)