from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
import uvicorn
import requests
import os

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    print("python-dotenv not installed. Skipping .env file loading.")

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"

if not GROQ_API_KEY:
    print("WARNING: GROQ_API_KEY not set! Please set it in your .env file")


@app.get("/")
def home():
    """
    Health check endpoint to verify the API is successfully running.

    Parameters:
    None

    Returns:
    dict: A simple welcome message indicating the server status.
    """
    return {"message": "GoBuddy AI Backend is Running!"}


@app.get("/ask-gobuddy")
async def ask_ai(prompt: str):
    """
    Sends a user prompt to the Groq AI API and returns the generated response.

    Parameters:
    prompt (str): The user's question or instruction.

    Returns:
    dict: The AI's response text, or an error message if the request fails or times out.
    """
    if not prompt:
        return {"error": "Prompt cannot be empty"}

    try:
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


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)