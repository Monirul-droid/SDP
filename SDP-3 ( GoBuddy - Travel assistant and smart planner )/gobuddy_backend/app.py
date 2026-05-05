import sqlite3
import re
from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from fastapi.middleware.cors import CORSMiddleware
from passlib.context import CryptContext
import uvicorn
import requests
from typing import List
import os

# Try to load from .env file, but don't fail if dotenv is not installed
try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    print("⚠️  python-dotenv not installed. Skipping .env file loading.")

app = FastAPI()

# --- PASSWORD HASHING SETUP ---
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# --- CORS MIDDLEWARE ---
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

# --- DATABASE INITIALIZATION ---
def init_db():
    conn = sqlite3.connect("gobuddy.db")
    cursor = conn.cursor()

    # 1. Users Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL
        )
    ''')

    # Full Names Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS user_names (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            first_name TEXT DEFAULT '',
            last_name TEXT DEFAULT '',
            FOREIGN KEY (email) REFERENCES users (email)
        )
    ''')

    # 2. Locations Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS locations (
            location_id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            location_address TEXT,
            category TEXT,
            image_url TEXT,
            description TEXT,
            rating REAL DEFAULT 0.0
        )
    ''')

    # 3. Favourites Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS favourites (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_email TEXT NOT NULL,
            location_id INTEGER NOT NULL,
            name TEXT NOT NULL,
            location TEXT,
            category TEXT,
            image_url TEXT,
            description TEXT
        )
    ''')

    # 4. Tour Packages Table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS tour_packages (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            city TEXT UNIQUE NOT NULL,
            hotel TEXT,
            budget TEXT,
            places TEXT,
            restaurants TEXT,
            travel_way TEXT,
            image_url TEXT
        )
    ''')

    # 5. Itineraries Table (Substituted CSV logic)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS itineraries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_email TEXT NOT NULL,
            trip_name TEXT,
            destination TEXT,
            day TEXT,
            activity TEXT,
            cost TEXT
        )
    ''')

    # ২. বাজেট এক্সপেন্স টেবিল (নতুন যেটা লাগবে)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            FOREIGN KEY (email) REFERENCES users (email)
        )
    ''')

    # 6. Avatars Table (সব অ্যাভাটার স্টোর করবে)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS avatars (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            avatar_name TEXT NOT NULL,
            avatar_link TEXT NOT NULL UNIQUE
        )
    ''')

    # 7. User Avatars Table (ইউজারের সিলেক্টেড অ্যাভাটার স্টোর করবে)
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS user_avatars (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            avatar_id INTEGER NOT NULL,
            FOREIGN KEY (email) REFERENCES users (email),
            FOREIGN KEY (avatar_id) REFERENCES avatars (id)
        )
    ''')

    conn.commit()
    conn.close()

init_db()

# --- DATA MODELS ---
class UserAuth(BaseModel):
    email: str
    password: str

class SearchRequest(BaseModel):
    query: str
    category: str = "All"

class UpdatePackageRequest(BaseModel):
    city: str
    hotel: str
    budget: str
    places: str
    restaurants: str
    travel_way: str

class UpdateProfileRequest(BaseModel):
    email: str
    firstName: str
    lastName: str
    
    class Config:
        populate_by_name = True

class ChangePasswordRequest(BaseModel):
    email: str
    current_password: str
    new_password: str

# --- HELPER FUNCTIONS ---
def is_valid_email(email):
    pattern = r'^[a-z0-9](\.?[a-z0-9]){5,}@gmail\.com$'
    return re.match(pattern, email)

def get_db_connection():
    conn = sqlite3.connect("gobuddy.db")
    conn.row_factory = sqlite3.Row
    return conn

# --- ROUTES ---

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]

# --- AI CHATBOT WITH CONVERSATION HISTORY ---
@app.post("/ask-gobuddy")
async def ask_ai_with_history(chat_request: ChatRequest):
    """Handle AI requests with full conversation history"""
    try:
        messages = chat_request.messages
        
        if not messages:
            return {"error": "No messages provided"}
        
        # Convert to Groq-compatible format, handling system messages
        api_messages = []
        system_prompt = None
        
        for msg in messages:
            if msg.role == "system":
                # Store system message for use as context
                system_prompt = msg.content
            elif msg.role in ["user", "bot"]:
                # Convert "bot" role to "assistant" for Groq compatibility
                role = "assistant" if msg.role == "bot" else "user"
                api_messages.append({
                    "role": role,
                    "content": msg.content
                })
        
        # If we have system prompt and user messages, prepend it as context
        if system_prompt and api_messages:
            # Inject system context into the first user message
            first_msg = api_messages[0]
            if first_msg["role"] == "user":
                api_messages[0]["content"] = f"{system_prompt}\n\n{first_msg['content']}"
        
        headers = {
            "Authorization": f"Bearer {GROQ_API_KEY}",
            "Content-Type": "application/json"
        }
        
        # Send to Groq API
        payload = {
            "model": "llama-3.1-8b-instant",
            "messages": api_messages,
            "max_tokens": 1000,
            "temperature": 0.6,
            "top_p": 0.8
        }
        
        print(f"📤 Sending {len(api_messages)} messages to Groq (system prompt injected)")
        response = requests.post(GROQ_API_URL, json=payload, headers=headers, timeout=10)
        print(f"📥 Groq response: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            reply = data.get("choices", [{}])[0].get("message", {}).get("content", "No response")
            return {"reply": reply}
        else:
            error_detail = response.text[:500]
            print(f"❌ Groq Error: {error_detail}")
            return {"error": f"Groq API Error: {response.status_code}"}
    except Exception as e:
        print(f"❌ Exception: {str(e)}")
        return {"error": f"AI Error: {str(e)}"}


@app.get("/ask-gobuddy")
async def ask_ai(prompt: str):
    if not prompt:
        return {"error": "Prompt cannot be empty"}
    try:
        # ⚡ OPTIMIZED: Balanced speed (10s) + quality answers
        headers = {
            "Authorization": f"Bearer {GROQ_API_KEY}",
            "Content-Type": "application/json"
        }
        
        # ⚡ BALANCED OPTIMIZATION: More tokens for better answers, 10s timeout
        payload = {
            "model": "llama-3.1-8b-instant",
            "messages": [{"role": "user", "content": prompt}],
            "max_tokens": 1000,  # ⚡ Increased to 1000 for full multi-day itineraries
            "temperature": 0.6,  # ⚡ Slightly higher for better quality
            "top_p": 0.8  # ⚡ More natural responses
        }
        
        # ⚡ Timeout: 10s for balanced speed + quality
        response = requests.post(GROQ_API_URL, json=payload, headers=headers, timeout=10)
        
        if response.status_code == 200:
            data = response.json()
            reply = data.get("choices", [{}])[0].get("message", {}).get("content", "No response")
            return {"reply": reply}
        else:
            return {"error": f"Groq API Error: {response.status_code}"}
    except requests.exceptions.Timeout:
        return {"error": "Request timeout: Backend is taking too long"}
    except requests.exceptions.RequestException as e:
        return {"error": f"AI Error: {str(e)}"}


@app.post("/register")
async def register(request_data: UserAuth):
    email = request_data.email.lower().strip()
    password = request_data.password
    if not is_valid_email(email):
        return {"status": "error", "message": "Invalid Gmail format!"}
    if len(password) < 8 or " " in password:
        return {"status": "error", "message": "Password must be 8+ chars & no spaces."}
    hashed_password = pwd_context.hash(password)
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("INSERT INTO users (email, password) VALUES (?, ?)", (email, hashed_password))
            conn.commit()
        return {"status": "success", "message": "Registration Successful!"}
    except sqlite3.IntegrityError:
        return {"status": "error", "message": "Email already exists!"}

@app.post("/login")
async def login(request_data: UserAuth):
    # ⚡ FIXED: Normalize email (lowercase + trim) to match registration
    email = request_data.email.lower().strip()
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT password FROM users WHERE email=?", (email,))
        user = cursor.fetchone()
    if user and pwd_context.verify(request_data.password, user[0]):
        return {"status": "success", "message": "Login Successful"}
    return {"status": "error", "message": "Invalid credentials"}

# CHANGE PASSWORD
@app.post("/change_password")
async def change_password(data: ChangePasswordRequest):
    try:
        email = data.email.lower().strip()
        current_password = data.current_password
        new_password = data.new_password
        
        # Validate new password
        if len(new_password) < 8 or " " in new_password:
            return {"status": "error", "message": "Password must be 8+ chars & no spaces."}
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            # Get current password hash
            cursor.execute("SELECT password FROM users WHERE email=?", (email,))
            user = cursor.fetchone()
            
            if not user:
                return {"status": "error", "message": "User not found"}
            
            # Verify current password
            if not pwd_context.verify(current_password, user[0]):
                return {"status": "error", "message": "Current password is incorrect"}
            
            # Update with new password
            hashed_new_password = pwd_context.hash(new_password)
            cursor.execute("UPDATE users SET password=? WHERE email=?", (hashed_new_password, email))
            conn.commit()
        
        return {"status": "success", "message": "Password changed successfully!"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

# DELETE ACCOUNT
@app.post("/delete_account")
async def delete_account(data: dict):
    try:
        email = data.get("email", "").lower().strip()
        password = data.get("password", "")
        
        if not email or not password:
            return {"status": "error", "message": "Email and password required"}
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            # Get user from database
            cursor.execute("SELECT password FROM users WHERE email=?", (email,))
            user = cursor.fetchone()
            
            if not user:
                return {"status": "error", "message": "User not found"}
            
            # Verify password
            if not pwd_context.verify(password, user[0]):
                return {"status": "error", "message": "Incorrect password"}
            
            # Delete user data from all related tables
            # Delete user avatars
            cursor.execute("DELETE FROM user_avatars WHERE email=?", (email,))
            
            # Delete user names
            cursor.execute("DELETE FROM user_names WHERE email=?", (email,))
            
            # Delete favourites
            cursor.execute("DELETE FROM favourites WHERE user_email=?", (email,))
            
            # Delete itineraries
            cursor.execute("DELETE FROM itineraries WHERE user_email=?", (email,))
            
            # Delete expenses
            cursor.execute("DELETE FROM expenses WHERE email=?", (email,))
            
            # Delete user account
            cursor.execute("DELETE FROM users WHERE email=?", (email,))
            
            conn.commit()
        
        return {"status": "success", "message": "Account deleted successfully"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/get_all_packages")
async def get_all_packages():
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM tour_packages")
        rows = cursor.fetchall()
        return [dict(row) for row in rows]

@app.post("/update_package")
async def update_package(data: UpdatePackageRequest):
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                UPDATE tour_packages 
                SET hotel=?, budget=?, places=?, restaurants=?, travel_way=? 
                WHERE city=?''', (data.hotel, data.budget, data.places, data.restaurants, data.travel_way, data.city))
            conn.commit()
        return {"status": "success", "message": f"Package for {data.city} updated!"}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/search")
async def search_places(request_data: SearchRequest):
    query = f"%{request_data.query.lower().strip()}%"
    category = request_data.category
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            sql = "SELECT * FROM locations WHERE (LOWER(name) LIKE ? OR LOWER(location_address) LIKE ?)"
            params = [query, query]
            if category != "All":
                sql += " AND category = ?"
                params.append(category)
            cursor.execute(sql, params)
            rows = cursor.fetchall()
            results = [dict(row) for row in rows]
        return {"status": "success", "results": results}
    except Exception as e:
        return {"status": "error", "message": str(e)}

# --- SAVE ITINERARY (Database focus) ---
@app.post("/save_itinerary")
async def save_itinerary(data: dict):
    try:
        email = data.get('email')
        trip_name = data.get('trip_name')
        destination = data.get('destination')
        plans = data.get('plans', {})

        with get_db_connection() as conn:
            cursor = conn.cursor()
            for day, activities in plans.items():
                for act in activities:
                    cursor.execute('''
                        INSERT INTO itineraries (user_email, trip_name, destination, day, activity, cost)
                        VALUES (?, ?, ?, ?, ?, ?)
                    ''', (email, trip_name, destination, day, act['name'], str(act['cost'])))
            conn.commit()
        return {"status": "success", "message": "Saved to SQLite Database!"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

# ✅ FETCH BOOKMARK / CSV DATA FROM SQLITE
# Ei function ti purono nam-i rakha hoyeche jeno Flutter code breakdown na kore
@app.get("/get_csv_data/{email}")
async def get_csv_data(email: str):
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM itineraries WHERE user_email=?", (email,))
            rows = cursor.fetchall()

            # Flutter side-er format onujayi map kora
            results = []
            for row in rows:
                results.append({
                    "Email": row["user_email"],
                    "Destination": row["destination"],
                    "trip_name": row["trip_name"],
                    "Day": row["day"],
                    "Activity": row["activity"],
                    "Cost": row["cost"],
                    "start_date": "N/A" # Default placeholder
                })
            return results
    except Exception as e:
        print(f"Fetch Error: {e}")
        return []

# --- FETCH ITINERARY (Generic) ---
@app.get("/get_itineraries/{email}")
async def get_itineraries(email: str):
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM itineraries WHERE user_email=?", (email,))
            rows = cursor.fetchall()
            return [dict(row) for row in rows]
    except Exception as e:
        return []
# --- ADD TO FAVOURITE ---
@app.post("/add_favourite")
async def add_favourite(data: dict):
    try:
        email = data.get('email')
        location_id = data.get('location_id', 0)
        name = data.get('name')
        location = data.get('location')
        category = data.get('category')
        image_url = data.get('image_url')
        description = data.get('description')
        
        # Validate required fields
        if not email or not name:
            return {"status": "error", "message": "Missing required fields: email and name"}
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            # Check if favorite already exists
            cursor.execute("SELECT id FROM favourites WHERE user_email=? AND name=?", (email, name))
            existing = cursor.fetchone()
            
            if existing:
                return {"status": "success", "message": "Already in Favourites!"}
            
            # Insert only if it doesn't exist
            cursor.execute('''
                INSERT INTO favourites (user_email, location_id, name, location, category, image_url, description)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (email, location_id, name, location, category, image_url, description))
            conn.commit()
        return {"status": "success", "message": "Added to Favourites!", "is_new": True}
    except Exception as e:
        print(f"Add Favourite Error: {str(e)}")
        return {"status": "error", "message": str(e)}

# --- GET ALL FAVOURITES ---
@app.get("/get_favourites/{email}")
async def get_favourites(email: str):
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM favourites WHERE user_email=?", (email,))
            rows = cursor.fetchall()
            return [dict(row) for row in rows]
    except Exception as e:
        return []
@app.delete("/delete_itinerary/{id}")
async def delete_itinerary(id: int):
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM itineraries WHERE id = ?", (id,))
            conn.commit()
        return {"status": "success", "message": "Deleted successfully"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

# --- EXPENSE MANAGEMENT ---
@app.post("/add_expense")
async def add_expense(data: dict):
    try:
        email = data.get('email')
        title = data.get('title')
        amount = data.get('amount')
        
        if not email or not title or amount is None:
            return {"status": "error", "message": "Missing required fields"}
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO expenses (email, title, amount)
                VALUES (?, ?, ?)
            ''', (email, title, float(amount)))
            conn.commit()
        return {"status": "success", "message": "Expense added successfully"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.get("/get_expenses/{email}")
async def get_expenses(email: str):
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM expenses WHERE email=?", (email,))
            rows = cursor.fetchall()
            return [dict(row) for row in rows]
    except Exception as e:
        return {"status": "error", "message": str(e)}

@app.delete("/delete_expense/{id}")
async def delete_expense(id: int):
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM expenses WHERE id = ?", (id,))
            conn.commit()
        return {"status": "success", "message": "Expense deleted successfully"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

# --- CHECK IF FAVORITE EXISTS ---
@app.get("/check_favourite/{email}/{name}")
async def check_favourite(email: str, name: str):
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT id FROM favourites WHERE user_email=? AND name=?", (email, name))
            result = cursor.fetchone()
            if result:
                return {"status": "success", "is_favorite": True, "id": result[0]}
            else:
                return {"status": "success", "is_favorite": False}
    except Exception as e:
        return {"status": "error", "message": str(e)}

# --- DELETE FAVOURITE ---
@app.delete("/delete_favourite/{id}")
async def delete_favourite(id: int):
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM favourites WHERE id = ?", (id,))
            conn.commit()
        return {"status": "success", "message": "Removed from Favourites!"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

# PROFILE UPDATE (user_names টেবিলে ডেটা সেভ হবে)
@app.post("/update_profile")
async def update_profile(data: UpdateProfileRequest):
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO user_names (email, first_name, last_name) 
                VALUES(?, ?, ?) 
                ON CONFLICT(email) DO UPDATE SET first_name=excluded.first_name, last_name=excluded.last_name''',
                           (data.email, data.firstName, data.lastName))
            conn.commit()
        return {"status": "success", "message": "Profile updated in new table!"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

# GET PROFILE INFO (user_names টেবিল থেকে ডেটা আনবে)
@app.get("/get_user_info/{email}")
async def get_user_info(email: str):
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT first_name, last_name FROM user_names WHERE email=?", (email,))
            user = cursor.fetchone()
            if user: return dict(user)
            return {"first_name": "", "last_name": ""}
    except Exception as e: return {"error": str(e)}

# GET PROFILE (for Flutter Flutter app - returns camelCase)
@app.get("/get_profile")
async def get_profile(email: str):
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT first_name, last_name FROM user_names WHERE email=?", (email,))
            user = cursor.fetchone()
            if user:
                return {"firstName": user[0], "lastName": user[1]}
            return {"firstName": "", "lastName": ""}
    except Exception as e: 
        return {"error": str(e)}

# --- AVATAR ENDPOINTS ---

# GET ALL AVAILABLE AVATARS
@app.get("/get_all_avatars")
async def get_all_avatars():
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT id, avatar_name, avatar_link FROM avatars ORDER BY id")
            avatars = cursor.fetchall()
            return [{"id": row[0], "name": row[1], "link": row[2]} for row in avatars]
    except Exception as e:
        return {"error": str(e)}

# SAVE USER AVATAR
@app.post("/save_user_avatar")
async def save_user_avatar(data: dict):
    try:
        email = data.get("email")
        avatar_id = data.get("avatar_id")
        
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO user_avatars (email, avatar_id) 
                VALUES(?, ?) 
                ON CONFLICT(email) DO UPDATE SET avatar_id=excluded.avatar_id''',
                           (email, avatar_id))
            conn.commit()
        return {"status": "success", "message": "Avatar saved successfully!"}
    except Exception as e:
        return {"status": "error", "message": str(e)}

# GET USER AVATAR
@app.get("/get_user_avatar")
async def get_user_avatar(email: str):
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute('''
                SELECT a.id, a.avatar_name, a.avatar_link 
                FROM user_avatars ua
                JOIN avatars a ON ua.avatar_id = a.id
                WHERE ua.email = ?''', (email,))
            result = cursor.fetchone()
            if result:
                return {"id": result[0], "name": result[1], "link": result[2]}
            return {"id": None, "name": "Default", "link": ""}
    except Exception as e:
        return {"error": str(e)}

if __name__ == "__main__":
    uvicorn.run(app, host="192.168.0.106", port=5000)