from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import requests
import os

# Try to load from .env file, but don't fail if dotenv is not installed
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    print("⚠️  python-dotenv not installed. Skipping .env file loading.")

app = FastAPI()

# --- CORS MIDDLEWARE ---
# Flutter app theke request allow korar jonno eti proyojon
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- GROQ AI CONFIGURATION ---
# ⚡ Basic HTTP setup - No SDK needed
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"

if not GROQ_API_KEY:
    print("⚠️  WARNING: GROQ_API_KEY not set! Please set it in your .env file")

@app.get("/")
def home():
    return {"message": "GoBuddy AI Backend is Running!"}

@app.get("/ask-gobuddy")
async def ask_ai(prompt: str):
    if not prompt:
        return {"error": "Prompt cannot be empty"}

    try:
        # ⚡ Basic HTTP request to Groq API
        headers = {
            "Authorization": f"Bearer {GROQ_API_KEY}",
            "Content-Type": "application/json"
        }
        
        payload = {
            "model": "llama-3.1-8b-instant",
            "messages": [{"role": "user", "content": prompt}],
            "max_tokens": 1024,
            "temperature": 0.7
        }
        
        response = requests.post(GROQ_API_URL, json=payload, headers=headers, timeout=30)
        
        if response.status_code == 200:
            data = response.json()
            reply = data.get("choices", [{}])[0].get("message", {}).get("content", "No response")
            return {"reply": reply}
        else:
            return {"error": f"Groq API Error: {response.status_code}"}

    except requests.exceptions.Timeout:
        return {"error": "Request timeout: Groq API is taking too long"}
    except requests.exceptions.RequestException as e:
        return {"error": f"AI Error: {str(e)}"}

# --- SERVER RUN ---
if __name__ == "__main__":
    # Host 0.0.0.0 kora holo jeno local network theke pawa jay
    # App.py 5000 port-e cholle eti onno port-e (e.g., 8000) run kora bhalo
    uvicorn.run(app, host="192.168.0.106", port=8000)