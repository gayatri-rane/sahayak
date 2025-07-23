# Sahayak - GitHub Setup & Flutter Integration Guide

## Project Structure

```sahayak-project/
├── backend/
│   ├── app.py > Main file
│   ├── requirements.txt
│   ├── Dockerfile
│   ├── .dockerignore
│   ├── cloudbuild.yaml
│   ├── .env.example
│   ├── .gitignore
│   ├── gemini/
│   │   ├── __init__.py
│   │   └── sahayak_ai.py > helper functions
│   ├── tests/
│   │   ├── __init__.py
│   │   └── test_api.py
│   └── README.md
├── flutter/
│   └── (Flutter app will go here)
├── docs/
│   ├── API.md
│   ├── DEPLOYMENT.md
│   └── FLUTTER_INTEGRATION.md
├── .github/
│   └── workflows/
│       ├── backend-deploy.yml
│       └── flutter-build.yml
├── LICENSE
└── README.md```


