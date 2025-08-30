import pygame
import random
import string
import json
import sys
import mysql.connector
import time

game_name = "hangman10"  # Change this accordingly in each game

start_time = time.time()
# MySQL connection
conn = mysql.connector.connect(
    host="localhost",
    user="root",
    password="",
    database="db_game"
)
cursor = conn.cursor()

pygame.init()
screen_width, screen_height = 900, 800
screen = pygame.display.set_mode((screen_width, screen_height), pygame.RESIZABLE)
pygame.display.set_caption("Hangman Word Game")
font = pygame.font.SysFont(None, 96)
small_font = pygame.font.SysFont(None, 60)
input_font = pygame.font.SysFont(None, 48)
clock = pygame.time.Clock()

with open("words.json", "r") as f:
    words = json.load(f)

class Particle:
    def __init__(self):
        self.x = random.randint(0, screen_width)
        self.y = random.randint(0, screen_height)
        self.size = random.randint(2, 6)
        self.color = random.choice([(0, 255, 255), (255, 100, 255), (150, 150, 255)])
        self.speed = random.uniform(0.5, 1.5)

    def move(self):
        self.y -= self.speed
        if self.y < 0:
            self.y = screen_height
            self.x = random.randint(0, screen_width)

    def draw(self, screen):
        pygame.draw.circle(screen, self.color, (int(self.x), int(self.y)), self.size)

particles = [Particle() for _ in range(40)]

def select_word():
    category = random.choice(list(words.keys()))
    word = random.choice(words[category])
    return category, word.upper()

def draw_text(text, x, y, font, color=(255, 255, 255), center=True):
    surface = font.render(text, True, color)
    rect = surface.get_rect(center=(x, y)) if center else surface.get_rect(topleft=(x, y))
    screen.blit(surface, rect)

def draw_input_box(prompt):
    input_str = ""
    while True:
        screen.fill((0, 0, 0))
        draw_text(prompt, screen_width // 2, screen_height // 2 - 50, input_font)
        draw_text(input_str, screen_width // 2, screen_height // 2 + 20, input_font)
        pygame.display.flip()
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_RETURN:
                    return input_str
                elif event.key == pygame.K_BACKSPACE:
                    input_str = input_str[:-1]
                else:
                    if len(input_str) < 20:
                        input_str += event.unicode

def show_leaderboard():
    while True:
        screen.fill((10, 10, 30))
        draw_text("Top 10 Players", screen_width // 2, 60, font, color=(255, 215, 0))

        # 🟢 FIX: JOIN to get player_name from players table
        cursor.execute("""
            SELECT hl.player_id, p.player_name, hl.score
            FROM hangman_leaderboard hl
            JOIN players p ON hl.player_id = p.player_uid
            ORDER BY hl.score DESC
            LIMIT 10
        """)
        top_players = cursor.fetchall()

        for idx, row in enumerate(top_players):
            draw_text(f"{idx + 1}. {row[1]} (ID: {row[0]}) - {row[2]}", screen_width // 2, 150 + idx * 50, input_font)

        draw_text("S: Search My Rank", 100, screen_height - 100, input_font, center=False)
        draw_text("B: Back", screen_width - 200, screen_height - 100, input_font, center=False)

        pygame.display.flip()
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_b:
                    return
                elif event.key == pygame.K_s:
                    player_id = draw_input_box("Enter your ID to search:")

                    # 🟢 FIX: JOIN to get name when searching rank
                    cursor.execute("""
                        SELECT hl.player_id, p.player_name, hl.score
                        FROM hangman_leaderboard hl
                        JOIN players p ON hl.player_id = p.player_uid
                        ORDER BY hl.score DESC
                    """)
                    all_players = cursor.fetchall()
                    found = False
                    for i, row in enumerate(all_players):
                        if str(row[0]) == player_id:
                            found = True
                            msg1 = f"Rank: {i + 1}"
                            msg2= f"Name: {row[1]}"
                            msg3= f"Score: {row[2]}"
                            break
                    if not found:
                        msg = "ID not found."

                    screen.fill((0, 0, 0))
                    draw_text(msg1, screen_width // 2, screen_height // 2-195, font, color=(0, 255, 255))
                    draw_text(msg2, screen_width // 2, screen_height // 2-100, font, color=(0, 255, 255))
                    draw_text(msg3, screen_width // 2, screen_height // 2-5, font, color=(0, 255, 255))
                    draw_text("Press any key to go back", screen_width // 2, screen_height // 2 + 200, input_font)
                    pygame.display.flip()
                    wait_for_key()


def wait_for_key():
    while True:
        for event in pygame.event.get():
            if event.type == pygame.KEYDOWN:
                return

category, word = "", ""
guessed = set()
attempts = 0
game_over = False
win = False
player_id = ""
player_name = ""
difficulty_selected = False
difficulty = None
score_updated = False

def draw_hangman(attempts_left):
    x = screen.get_width() // 8
    y = screen.get_height() // 1.3
    pygame.draw.line(screen, (255, 255, 255), (x - 60, y), (x + 60, y), 5)
    pygame.draw.line(screen, (255, 255, 255), (x, y), (x, y - 250), 5)
    pygame.draw.line(screen, (255, 255, 255), (x, y - 250), (x + 60, y - 250), 5)
    pygame.draw.line(screen, (255, 255, 255), (x + 60, y - 250), (x + 60, y - 200), 5)
    parts = 8 - attempts_left
    if parts > 0:
        pygame.draw.circle(screen, (255, 255, 255), (x + 60, y - 170), 25, 4)
    if parts > 1:
        pygame.draw.line(screen, (255, 255, 255), (x + 60, y - 145), (x + 60, y - 80), 4)
    if parts > 2:
        pygame.draw.line(screen, (255, 255, 255), (x + 60, y - 135), (x + 30, y - 110), 4)
    if parts > 3:
        pygame.draw.line(screen, (255, 255, 255), (x + 60, y - 135), (x + 90, y - 110), 4)
    if parts > 4:
        pygame.draw.line(screen, (255, 255, 255), (x + 60, y - 80), (x + 35, y - 40), 4)
    if parts > 5:
        pygame.draw.line(screen, (255, 255, 255), (x + 60, y - 80), (x + 85, y - 40), 4)
    if parts > 6:
        pygame.draw.circle(screen, (255, 0, 0), (x + 50, y - 180), 4)
    if parts > 7:
        pygame.draw.circle(screen, (255, 0, 0), (x + 70, y - 180), 4)

def draw_game():
    screen.fill((20, 20, 40))
    for p in particles:
        p.move()
        p.draw(screen)
    cx = screen.get_width() // 2
    draw_text(f"Category: {category}", cx, 100, small_font, color=(200, 200, 255))
    display = " ".join([c if c in guessed else "_" for c in word])
    draw_text(display, cx, 300, font, color=(0, 255, 255))
    draw_text(f"Attempts Left: {attempts}", cx, 500, small_font, color=(0, 255, 255))
    draw_text(f"Guessed: {' '.join(sorted(guessed))}", cx, 600, small_font, color=(0, 255, 255))
    if game_over:
        msg = "You Win!" if win else f"You Lose! Word was: {word}"
        draw_text(msg, cx, 650, font, color=(0, 255, 0) if win else (255, 0, 0))
        draw_text("R: Restart", screen_width - 300, 250, small_font, center=False)
        draw_text("Q: Quit", screen_width - 300, 320, small_font, center=False)
        draw_text("L: Leaderboard", screen_width - 300, 390, small_font, center=False)
    draw_hangman(attempts)




def game_loop():
    global category, word, guessed, attempts, game_over, win, difficulty, difficulty_selected, player_id, player_name, score_updated

    player_id = draw_input_box("Enter your ID:")
    player_name = draw_input_box("Enter your Name:")
    score_updated = False
    difficulty_selected = False

    while not difficulty_selected:
        screen.fill((20, 20, 40))
        draw_text("HANGMAN", screen_width // 2, screen_height // 4, font, color=(255, 100, 0))
        gap = 50
        center_y = screen_height // 2
        draw_text("1. Beginner (8 attempts)", screen_width // 2, center_y - 2 * gap, small_font, color=(0, 255, 0))
        draw_text("2. Advanced (6 attempts)", screen_width // 2, center_y - gap, small_font, color=(0, 255, 0))
        draw_text("3. Hard (4 attempts)", screen_width // 2, center_y, small_font, color=(0, 255, 0))
        draw_text("4. Leaderboard", screen_width // 2, center_y + gap, small_font, color=(255, 255, 0))
        draw_text("5. Quit", screen_width // 2, center_y + 2 * gap, small_font, color=(255, 0, 0))
        pygame.display.flip()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_1:
                    difficulty = "Beginner"
                    attempts = 8
                    difficulty_selected = True
                elif event.key == pygame.K_2:
                    difficulty = "Advanced"
                    attempts = 6
                    difficulty_selected = True
                elif event.key == pygame.K_3:
                    difficulty = "Hard"
                    attempts = 4
                    difficulty_selected = True
                elif event.key == pygame.K_4:
                    show_leaderboard()
                elif event.key == pygame.K_5:
                    pygame.quit()
                    sys.exit()

    category, word = select_word()
    guessed = set()
    game_over = False
    win = False

    while True:
        screen.fill((20, 20, 40))
        draw_game()
        pygame.display.flip()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()

            if not game_over and event.type == pygame.KEYDOWN:
                if event.unicode.isalpha():
                    letter = event.unicode.upper()
                    if letter not in guessed:
                        guessed.add(letter)
                        if letter not in word:
                            attempts -= 1

                if all(c in guessed for c in word):
                    win = True
                    game_over = True

                elif attempts <= 0:
                    game_over = True

            elif game_over and event.type == pygame.KEYDOWN:
                if event.key == pygame.K_r:  # Restart game
                    game_loop()
                    return
                elif event.key == pygame.K_q:  # Quit
                    pygame.quit()
                    sys.exit()
                elif event.key == pygame.K_l:  # Show leaderboard
                    show_leaderboard()

        if game_over and not score_updated:
            # Insert or update player info and scores in DB
            cursor.execute("SELECT player_name FROM players WHERE player_uid = %s", (player_id,))
            result = cursor.fetchone()
            if result:
                if result[0] != player_name:
                    # If ID exists but name mismatch, ask for new ID
                    player_id = draw_input_box("ID exists with different name! Enter new unique ID:")
                    cursor.execute("INSERT INTO players (player_uid, player_name) VALUES (%s, %s)", (player_id, player_name))
                    conn.commit()
            else:
                cursor.execute("INSERT INTO players (player_uid, player_name) VALUES (%s, %s)", (player_id, player_name))
                conn.commit()

            # Calculate score
            base_score = {"Beginner": 5, "Advanced": 20, "Hard": 50}
            score = base_score.get(difficulty, 0) if win else 0

            cursor.execute("SELECT score FROM hangman_leaderboard WHERE player_id = %s", (player_id,))
            result = cursor.fetchone()
            if result:
                if score > result[0]:
                    cursor.execute("UPDATE hangman_leaderboard SET score = %s WHERE player_id = %s", (score, player_id))
                    conn.commit()
            else:
                cursor.execute("INSERT INTO hangman_leaderboard (player_id, score) VALUES (%s, %s)", (player_id, score))
                conn.commit()

            score_updated = True



def update_score():
    global player_id, player_name, win, difficulty  # Declare the variables as global!

    end_time = time.time()
    time_taken = int(end_time - start_time)
    score = 0
    if win:
        if difficulty == "Beginner":
            score = 5
        elif difficulty == "Advanced":
            score = 20
        elif difficulty == "Hard":
            score = 50

    # Check if ID already exists
    cursor.execute("SELECT player_name FROM players WHERE player_uid=%s", (player_id,))
    result = cursor.fetchone()

    if result:
        if result[0] != player_name:
            player_id_new = draw_input_box("ID exists with different name! Enter a new ID:")
            cursor.execute("INSERT INTO players (player_uid, player_name) VALUES (%s, %s)", (player_id_new, player_name))
            conn.commit()
            player_id = player_id_new
        else:
            pass
    else:
        cursor.execute("INSERT INTO players (player_uid, player_name) VALUES (%s, %s)", (player_id, player_name))
        conn.commit()

    cursor.execute("SELECT score FROM hangman_leaderboard WHERE player_id=%s", (player_id,))
    result = cursor.fetchone()

    if result:
        cursor.execute("UPDATE hangman_leaderboard SET score = score + %s WHERE player_id=%s", (score, player_id))
    else:
        cursor.execute("INSERT INTO hangman_leaderboard (player_id, score) VALUES (%s, %s)", (player_id, score))
    conn.commit()
menu_options = ["Start Game", "Leaderboard", "Exit"]
selected_index = 0



game_loop()



