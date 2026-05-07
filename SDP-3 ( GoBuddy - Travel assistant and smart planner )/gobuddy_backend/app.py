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

try:
    from dotenv import load_dotenv
    load_dotenv()
except ImportError:
    print(" python-dotenv not installed. Skipping .env file loading.")

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
GROQ_API_KEY = os.getenv("GROQ_API_KEY", "")
GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"

if not GROQ_API_KEY:
    print("WARNING: GROQ_API_KEY not set! Please set it in your .env file")


# --- DATABASE INITIALIZATION ---
def init_db():
    """
    Initializes the SQLite database and creates necessary tables if they do not exist.

    Creates tables for: users, user_names, locations, favourites,
    tour_packages, itineraries, expenses, avatars, and user_avatars.

    Parameters:
    None

    Returns:
    None
    """
    conn = sqlite3.connect("gobuddy.db")
    cursor = conn.cursor()

    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            password TEXT NOT NULL
        )
    ''')

    cursor.execute('''
        CREATE TABLE IF NOT EXISTS user_names (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT UNIQUE NOT NULL,
            first_name TEXT DEFAULT '',
            last_name TEXT DEFAULT '',
            FOREIGN KEY (email) REFERENCES users (email)
        )
    ''')

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

    cursor.execute('''
        CREATE TABLE IF NOT EXISTS expenses (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            email TEXT NOT NULL,
            title TEXT NOT NULL,
            amount REAL NOT NULL,
            FOREIGN KEY (email) REFERENCES users (email)
        )
    ''')

    cursor.execute('''
        CREATE TABLE IF NOT EXISTS avatars (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            avatar_name TEXT NOT NULL,
            avatar_link TEXT NOT NULL UNIQUE
        )
    ''')

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

class ChatMessage(BaseModel):
    role: str
    content: str

class ChatRequest(BaseModel):
    messages: List[ChatMessage]


# --- HELPER FUNCTIONS ---
def is_valid_email(email):
    """
    Validates if the provided string is a valid Gmail address.

    Parameters:
    email (str): The email address to validate.

    Returns:
    bool: True if valid, False otherwise.
    """
    pattern = r'^[a-z0-9](\.?[a-z0-9]){5,}@gmail\.com$'
    return re.match(pattern, email)

def get_db_connection():
    """
    Creates and returns a connection to the SQLite database.
    Configured to return rows as dictionaries for easier data handling.

    Parameters:
    None

    Returns:
    sqlite3.Connection: Database connection object.
    """
    conn = sqlite3.connect("gobuddy.db")
    conn.row_factory = sqlite3.Row
    return conn


# --- ROUTES ---

@app.post("/ask-gobuddy")
async def ask_ai_with_history(chat_request: ChatRequest):
    """
    Handles AI chatbot queries while maintaining conversation history.
    Communicates with the Groq API.

    Parameters:
    chat_request (ChatRequest): A list of previous and current messages.

    Returns:
    dict: The AI's response text or an error message.
    """
    try:
        messages = chat_request.messages
        if not messages:
            return {"error": "No messages provided"}

        api_messages = []
        system_prompt = None

        for msg in messages:
            if msg.role == "system":
                system_prompt = msg.content
            elif msg.role in ["user", "bot"]:
                role = "assistant" if msg.role == "bot" else "user"
                api_messages.append({"role": role, "content": msg.content})

        if system_prompt and api_messages:
            first_msg = api_messages[0]
            if first_msg["role"] == "user":
                api_messages[0]["content"] = f"{system_prompt}\n\n{first_msg['content']}"

        headers = {
            "Authorization": f"Bearer {GROQ_API_KEY}",
            "Content-Type": "application/json"
        }
        payload = {
            "model": "llama-3.1-8b-instant",
            "messages": api_messages,
            "max_tokens": 1000,
            "temperature": 0.6,
            "top_p": 0.8
        }

        response = requests.post(GROQ_API_URL, json=payload, headers=headers, timeout=10)

        if response.status_code == 200:
            data = response.json()
            reply = data.get("choices", [{}])[0].get("message", {}).get("content", "No response")
            return {"reply": reply}
        else:
            return {"error": f"Groq API Error: {response.status_code}"}
    except Exception as e:
        return {"error": f"AI Error: {str(e)}"}


@app.get("/ask-gobuddy")
async def ask_ai(prompt: str):
    """
    Handles a single-prompt AI query without saving conversation history.

    Parameters:
    prompt (str): The user's question or instruction.

    Returns:
    dict: The AI's response text or an error message.
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
            "max_tokens": 1000,
            "temperature": 0.6,
            "top_p": 0.8
        }

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
    """
    Registers a new user into the database.

    Parameters:
    request_data (UserAuth): Contains the user's email and password.

    Returns:
    dict: Success or error status message based on validation and db insertion.
    """
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
    """
    Authenticates a user by checking their email and hashed password.

    Parameters:
    request_data (UserAuth): Contains the user's login email and password.

    Returns:
    dict: Success message if valid, error message if invalid credentials.
    """
    email = request_data.email.lower().strip()
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT password FROM users WHERE email=?", (email,))
        user = cursor.fetchone()

    if user and pwd_context.verify(request_data.password, user[0]):
        return {"status": "success", "message": "Login Successful"}
    return {"status": "error", "message": "Invalid credentials"}


@app.post("/change_password")
async def change_password(data: ChangePasswordRequest):
    """
    Updates an existing user's password after verifying the current one.

    Parameters:
    data (ChangePasswordRequest): Contains email, current password, and new password.

    Returns:
    dict: Success or error message.
    """
    try:
        email = data.email.lower().strip()
        current_password = data.current_password
        new_password = data.new_password

        if len(new_password) < 8 or " " in new_password:
            return {"status": "error", "message": "Password must be 8+ chars & no spaces."}

        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT password FROM users WHERE email=?", (email,))
            user = cursor.fetchone()

            if not user:
                return {"status": "error", "message": "User not found"}
            if not pwd_context.verify(current_password, user[0]):
                return {"status": "error", "message": "Current password is incorrect"}

            hashed_new_password = pwd_context.hash(new_password)
            cursor.execute("UPDATE users SET password=? WHERE email=?", (hashed_new_password, email))
            conn.commit()

        return {"status": "success", "message": "Password changed successfully!"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


@app.post("/delete_account")
async def delete_account(data: dict):
    """
    Permanently deletes a user and all their associated data across all tables.

    Parameters:
    data (dict): Contains the user's email and password for verification.

    Returns:
    dict: Success or error message.
    """
    try:
        email = data.get("email", "").lower().strip()
        password = data.get("password", "")

        if not email or not password:
            return {"status": "error", "message": "Email and password required"}

        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT password FROM users WHERE email=?", (email,))
            user = cursor.fetchone()

            if not user:
                return {"status": "error", "message": "User not found"}
            if not pwd_context.verify(password, user[0]):
                return {"status": "error", "message": "Incorrect password"}

            cursor.execute("DELETE FROM user_avatars WHERE email=?", (email,))
            cursor.execute("DELETE FROM user_names WHERE email=?", (email,))
            cursor.execute("DELETE FROM favourites WHERE user_email=?", (email,))
            cursor.execute("DELETE FROM itineraries WHERE user_email=?", (email,))
            cursor.execute("DELETE FROM expenses WHERE email=?", (email,))
            cursor.execute("DELETE FROM users WHERE email=?", (email,))
            conn.commit()

        return {"status": "success", "message": "Account deleted successfully"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


@app.get("/get_all_packages")
async def get_all_packages():
    """
    Retrieves all available tour packages from the database.

    Parameters:
    None

    Returns:
    list: A list of dictionaries representing the tour packages.
    """
    with get_db_connection() as conn:
        cursor = conn.cursor()
        cursor.execute("SELECT * FROM tour_packages")
        rows = cursor.fetchall()
        return [dict(row) for row in rows]


@app.post("/update_package")
async def update_package(data: UpdatePackageRequest):
    """
    Updates the details of a specific tour package based on the city.

    Parameters:
    data (UpdatePackageRequest): Package details to be updated.

    Returns:
    dict: Success message.
    """
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
    """
    Searches for locations in the database by name or address, optionally filtered by category.

    Parameters:
    request_data (SearchRequest): Contains the search query and category.

    Returns:
    dict: Search results or an error message.
    """
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


@app.post("/save_itinerary")
async def save_itinerary(data: dict):
    """
    Saves a generated travel itinerary (day-by-day plans) into the database.

    Parameters:
    data (dict): Trip info including email, trip_name, destination, and nested plans.

    Returns:
    dict: Success or error message.
    """
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


@app.get("/get_csv_data/{email}")
async def get_csv_data(email: str):
    """
    Fetches itinerary data and formats it to match legacy CSV structures
    required by the frontend Flutter app.

    Parameters:
    email (str): The user's email address.

    Returns:
    list: A list of dictionaries mapped to the expected frontend format.
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM itineraries WHERE user_email=?", (email,))
            rows = cursor.fetchall()

            results = []
            for row in rows:
                results.append({
                    "Email": row["user_email"],
                    "Destination": row["destination"],
                    "trip_name": row["trip_name"],
                    "Day": row["day"],
                    "Activity": row["activity"],
                    "Cost": row["cost"],
                    "start_date": "N/A"
                })
            return results
    except Exception as e:
        print(f"Fetch Error: {e}")
        return []


@app.get("/get_itineraries/{email}")
async def get_itineraries(email: str):
    """
    Retrieves all stored itineraries for a specific user.

    Parameters:
    email (str): The user's email address.

    Returns:
    list: A list of itinerary records as dictionaries.
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM itineraries WHERE user_email=?", (email,))
            rows = cursor.fetchall()
            return [dict(row) for row in rows]
    except Exception as e:
        return []


@app.post("/add_favourite")
async def add_favourite(data: dict):
    """
    Adds a specified location to the user's favourites list.

    Parameters:
    data (dict): Location details including id, name, and user's email.

    Returns:
    dict: Success message or error message.
    """
    try:
        email = data.get('email')
        location_id = data.get('location_id', 0)
        name = data.get('name')
        location = data.get('location')
        category = data.get('category')
        image_url = data.get('image_url')
        description = data.get('description')

        if not email or not name:
            return {"status": "error", "message": "Missing required fields: email and name"}

        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT id FROM favourites WHERE user_email=? AND name=?", (email, name))
            existing = cursor.fetchone()

            if existing:
                return {"status": "success", "message": "Already in Favourites!"}

            cursor.execute('''
                INSERT INTO favourites (user_email, location_id, name, location, category, image_url, description)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (email, location_id, name, location, category, image_url, description))
            conn.commit()
        return {"status": "success", "message": "Added to Favourites!", "is_new": True}
    except Exception as e:
        return {"status": "error", "message": str(e)}


@app.get("/get_favourites/{email}")
async def get_favourites(email: str):
    """
    Retrieves all favourite locations for a specific user.

    Parameters:
    email (str): The user's email address.

    Returns:
    list: A list of favourite locations as dictionaries.
    """
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
    """
    Deletes a specific itinerary record by its ID.

    Parameters:
    id (int): The ID of the itinerary to delete.

    Returns:
    dict: Success or error message.
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM itineraries WHERE id = ?", (id,))
            conn.commit()
        return {"status": "success", "message": "Deleted successfully"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


@app.post("/add_expense")
async def add_expense(data: dict):
    """
    Adds a new expense entry for a specific user.

    Parameters:
    data (dict): Contains the user's email, expense title, and amount.

    Returns:
    dict: Success or error message.
    """
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
    """
    Retrieves all expense records for a specific user.

    Parameters:
    email (str): The user's email address.

    Returns:
    list: A list of expense records or an error dictionary.
    """
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
    """
    Deletes a specific expense record by its ID.

    Parameters:
    id (int): The ID of the expense to delete.

    Returns:
    dict: Success or error message.
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM expenses WHERE id = ?", (id,))
            conn.commit()
        return {"status": "success", "message": "Expense deleted successfully"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


@app.get("/check_favourite/{email}/{name}")
async def check_favourite(email: str, name: str):
    """
    Checks if a specific location is already in the user's favourites list.

    Parameters:
    email (str): The user's email address.
    name (str): The name of the location.

    Returns:
    dict: Status containing boolean 'is_favorite' and item ID if true.
    """
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


@app.delete("/delete_favourite/{id}")
async def delete_favourite(id: int):
    """
    Deletes a specific location from favourites by its ID.

    Parameters:
    id (int): The ID of the favourite record to delete.

    Returns:
    dict: Success or error message.
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM favourites WHERE id = ?", (id,))
            conn.commit()
        return {"status": "success", "message": "Removed from Favourites!"}
    except Exception as e:
        return {"status": "error", "message": str(e)}


@app.post("/update_profile")
async def update_profile(data: UpdateProfileRequest):
    """
    Updates or inserts a user's first and last name in the user_names table.

    Parameters:
    data (UpdateProfileRequest): Contains user's email, firstName, and lastName.

    Returns:
    dict: Success or error message.
    """
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


@app.get("/get_user_info/{email}")
async def get_user_info(email: str):
    """
    Retrieves the first and last name for a user (Standard Python convention).

    Parameters:
    email (str): The user's email address.

    Returns:
    dict: Contains 'first_name' and 'last_name'.
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT first_name, last_name FROM user_names WHERE email=?", (email,))
            user = cursor.fetchone()
            if user: return dict(user)
            return {"first_name": "", "last_name": ""}
    except Exception as e:
        return {"error": str(e)}


@app.get("/get_profile")
async def get_profile(email: str):
    """
    Retrieves the first and last name for a user (Formatted for Flutter App).

    Parameters:
    email (str): The user's email address.

    Returns:
    dict: Contains 'firstName' and 'lastName' in camelCase.
    """
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

@app.get("/get_all_avatars")
async def get_all_avatars():
    """
    Fetches all available system avatars from the database.

    Parameters:
    None

    Returns:
    list: A list of available avatars (id, name, link).
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()
            cursor.execute("SELECT id, avatar_name, avatar_link FROM avatars ORDER BY id")
            avatars = cursor.fetchall()
            return [{"id": row[0], "name": row[1], "link": row[2]} for row in avatars]
    except Exception as e:
        return {"error": str(e)}


@app.post("/save_user_avatar")
async def save_user_avatar(data: dict):
    """
    Saves or updates the selected avatar for a specific user.

    Parameters:
    data (dict): Contains the user's email and chosen avatar_id.

    Returns:
    dict: Success or error message.
    """
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


@app.get("/get_user_avatar")
async def get_user_avatar(email: str):
    """
    Retrieves the assigned avatar details for a specific user.

    Parameters:
    email (str): The user's email address.

    Returns:
    dict: The avatar details (id, name, link) or a default placeholder.
    """
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
    uvicorn.run(app, host="0.0.0.0", port=5000)