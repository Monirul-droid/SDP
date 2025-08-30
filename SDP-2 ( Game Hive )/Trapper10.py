import pygame
import random
import time
import sys
import mysql.connector

pygame.init()

WIDTH, HEIGHT = 800, 600
GRID_SIZE = 10
CELL_SIZE = 40
FPS = 10
FONT = pygame.font.SysFont('Arial',30)
BIG_FONT = pygame.font.SysFont('Arial', 50)
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Trapper Game")

player = [0, 0]
enemies = [[random.randint(1, GRID_SIZE-1), random.randint(1, GRID_SIZE-1)] for _ in range(3)]
walls = []
health = 6
walls_placed = 0
start_time = time.time()
clock = pygame.time.Clock()
game_over = False
in_main_menu = True
showing_leaderboard = False
snowflakes = [[random.randint(0, WIDTH), random.randint(0, HEIGHT)] for _ in range(100)]

leaderboard_data = []


def draw_grid():
    for row in range(GRID_SIZE):
        for col in range(GRID_SIZE):
            pygame.draw.rect(screen, (200, 200, 200), (col*CELL_SIZE, row*CELL_SIZE, CELL_SIZE, CELL_SIZE), 1)

def draw_entities():
    for wall in walls:
        pygame.draw.rect(screen, (0, 0, 0), (wall[0]*CELL_SIZE, wall[1]*CELL_SIZE, CELL_SIZE, CELL_SIZE))
    for enemy in enemies:
        pygame.draw.rect(screen, (255, 0, 0), (enemy[0]*CELL_SIZE, enemy[1]*CELL_SIZE, CELL_SIZE, CELL_SIZE))
    pygame.draw.ellipse(screen, (0, 0, 255), (player[0]*CELL_SIZE, player[1]*CELL_SIZE, CELL_SIZE, CELL_SIZE))

def draw_ui():
    pygame.draw.rect(screen, (230, 230, 250), (GRID_SIZE * CELL_SIZE, 0, WIDTH - GRID_SIZE * CELL_SIZE, HEIGHT))
    elapsed = int(time.time() - start_time)
    texts = [
        f"Health: {health}",
        f"Walls: {walls_placed}",
        f"Time: {elapsed}s",
        "R: Restart",
        "Q: Quit",
        "L: Leaderboard"
    ]
    for i, t in enumerate(texts):
        text = FONT.render(t, True, (0, 0, 0))
        screen.blit(text, (GRID_SIZE * CELL_SIZE + 10, 70 + i*70))

def move_enemies():
    moved = False
    for enemy in enemies:
        dirs = ['up', 'down', 'left', 'right']
        random.shuffle(dirs)
        for d in dirs:
            nx, ny = enemy[0], enemy[1]
            if d == 'up' and ny > 0: ny -= 1
            elif d == 'down' and ny < GRID_SIZE-1: ny += 1
            elif d == 'left' and nx > 0: nx -= 1
            elif d == 'right' and nx < GRID_SIZE-1: nx += 1
            if [nx, ny] not in walls and [nx, ny] not in enemies:
                enemy[0], enemy[1] = nx, ny
                moved = True
                break
    return moved

# Add this new function:
def are_all_enemies_trapped():
    for enemy in enemies:
        x, y = enemy
        trapped = True
        for dx, dy in [(-1,0),(1,0),(0,-1),(0,1)]:
            nx, ny = x + dx, y + dy
            if 0 <= nx < GRID_SIZE and 0 <= ny < GRID_SIZE:
                if [nx, ny] not in walls and [nx, ny] not in enemies:
                    trapped = False
                    break
        if not trapped:
            return False
    return True


def check_collision():
    global health, player
    if player in enemies:
        health -= 1
        player = [0, 0]

def save_to_db(walls, elapsed):
    import tkinter as tk
    from tkinter import simpledialog
    root = tk.Tk()
    root.withdraw()
    name = simpledialog.askstring("Name", "Enter your name:")
    uid = simpledialog.askstring("ID", "Enter your ID:")
    if not name or not uid:
        return
    db = mysql.connector.connect(host="localhost", user="root", password="", database="db_game")
    cursor = db.cursor()
    # First, ensure the player exists in the players table
    cursor.execute("SELECT player_name FROM players WHERE player_uid = %s", (uid,))
    existing_player = cursor.fetchone()
    if existing_player:
        if existing_player[0] != name:
            db.close()
            return  # ID exists but name mismatch
    else:
        cursor.execute("INSERT INTO players (player_uid, player_name) VALUES (%s, %s)", (uid, name))
    
    # Then, update the trapper_leaderboard
    cursor.execute("SELECT * FROM trapper_leaderboard WHERE player_id = %s", (uid,))
    existing = cursor.fetchone()
    if existing:
        cursor.execute(
            "UPDATE trapper_leaderboard SET walls_placed = walls_placed + %s, time_survived = time_survived + %s WHERE player_id = %s",
            (walls, elapsed, uid)
        )
    else:
        cursor.execute(
            "INSERT INTO trapper_leaderboard (player_id, time_survived, walls_placed) VALUES (%s, %s, %s)",
            (uid, elapsed, walls)
        )
    db.commit()
    db.close()


def show_end_message(win):
    elapsed = int(time.time() - start_time)
    save_to_db(walls_placed, elapsed)

def restart():
    global player, enemies, walls, health, walls_placed, start_time, game_over
    player = [0, 0]
    enemies.clear()
    enemies.extend([[random.randint(1, GRID_SIZE-1), random.randint(1, GRID_SIZE-1)] for _ in range(3)])
    walls.clear()
    health = 3
    walls_placed = 0
    start_time = time.time()
    game_over = False

def show_leaderboard():
    global leaderboard_data, showing_leaderboard
    showing_leaderboard = True
    leaderboard_data.clear()
    
    db = mysql.connector.connect(host="localhost", user="root", password="", database="db_game")
    cursor = db.cursor()
    
    # Fetch all relevant data, sorting by walls_placed ASC, then time_survived ASC
    cursor.execute(
        "SELECT t.player_id, p.player_name, t.time_survived, t.walls_placed "
        "FROM trapper_leaderboard t "
        "JOIN players p ON t.player_id = p.player_uid "
        "ORDER BY t.walls_placed ASC, t.time_survived ASC "
        "LIMIT 10"
    )
    leaderboard_data = cursor.fetchall()
    db.close()
    
    # Display part (assuming you want to render the leaderboard right after fetching)
    screen.fill((0, 0, 0))
    title = BIG_FONT.render("Leaderboard (Least Walls & Time)", True, (255, 255, 255))
    screen.blit(title, (WIDTH // 2 - title.get_width() // 2, 50))
    
    for idx, entry in enumerate(leaderboard_data):
        player_id, player_name, time_survived, walls_placed = entry
        text = FONT.render(
            f"{idx + 1}. {player_name} - Walls: {walls_placed} - Time: {time_survived}s",
            True, (255, 255, 255)
        )
        screen.blit(text, (WIDTH // 2 - text.get_width() // 2, 150 + idx * 40))
    
    back_text = FONT.render("B: Back", True, (255, 255, 255))
    screen.blit(back_text, (WIDTH // 2 - back_text.get_width() // 2, HEIGHT - 50))
    
    pygame.display.flip()



def draw_leaderboard():
    screen.fill((245, 245, 245))
    title = BIG_FONT.render("Leaderboard (Top 10)", True, (0, 0, 0))
    screen.blit(title, (WIDTH//2 - title.get_width()//2, 30))
    for i, (uid, name, time_s, walls) in enumerate(leaderboard_data):
        line = f"{i+1}. {name} (ID: {uid}) - Time: {time_s}s, Walls: {walls}"
        text = FONT.render(line, True, (0, 0, 0))
        screen.blit(text, (100, 120 + i*80))
    back_text = FONT.render("Press B to go back", True, (100, 0, 0))
    screen.blit(back_text, (WIDTH//2 - back_text.get_width()//2, HEIGHT - 40))


def show_main_menu():
    screen.fill((170, 30, 75))
    for flake in snowflakes:
        pygame.draw.circle(screen, (200, 200, 255),flake, 2)
        flake[1] += 1
        if flake[1] > HEIGHT:
            flake[0] = random.randint(0, WIDTH)
            flake[1] = random.randint(-20, -1)
    title = pygame.font.SysFont('Arial',70).render("Trapper Game", True, (255, 255, 255))
    play_txt = BIG_FONT.render("P: Play", True, (255, 255, 255))
    lead_txt = BIG_FONT.render("L: Leaderboard", True, (255, 255, 255))
    exit_txt = BIG_FONT.render("Q: Quit", True, (255, 255, 255))
    screen.blit(title, (WIDTH//2 - title.get_width()//2, 50))
    screen.blit(play_txt, (WIDTH//2 - play_txt.get_width()//2, 150))
    screen.blit(lead_txt, (WIDTH//2 - lead_txt.get_width()//2, 230))
    screen.blit(exit_txt, (WIDTH//2 - exit_txt.get_width()//2, 310))
    pygame.display.flip()

running = True
enemy_timer = 0
while running:
    if in_main_menu:
        show_main_menu()
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_p:
                    in_main_menu = False
                    restart()
                elif event.key == pygame.K_l:
                    show_leaderboard()
                elif event.key == pygame.K_q:
                    running = False
        pygame.display.flip()
        clock.tick(FPS)
        continue

    if showing_leaderboard:
        draw_leaderboard()
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN and event.key == pygame.K_b:
                showing_leaderboard = False
                in_main_menu = True
        pygame.display.flip()
        clock.tick(FPS)
        continue

    screen.fill((255, 255, 255))
    draw_grid()
    draw_entities()
    draw_ui()

    if not game_over and pygame.time.get_ticks() - enemy_timer > 500:
        moved = move_enemies()
        check_collision()
        if health <= 0:
            game_over = True
            show_end_message(False)
        elif not moved:
            game_over = True
            show_end_message(True)
        enemy_timer = pygame.time.get_ticks()

    for event in pygame.event.get():
        if event.type == pygame.QUIT:
            running = False

        if event.type == pygame.KEYDOWN and not game_over:
            if event.key == pygame.K_UP and player[1] > 0:
                player[1] -= 1
            elif event.key == pygame.K_DOWN and player[1] < GRID_SIZE-1:
                player[1] += 1
            elif event.key == pygame.K_LEFT and player[0] > 0:
                player[0] -= 1
            elif event.key == pygame.K_RIGHT and player[0] < GRID_SIZE-1:
                player[0] += 1
            elif event.key == pygame.K_SPACE and player not in walls and player not in enemies:
                walls.append(list(player))
                walls_placed += 1

        if event.type == pygame.KEYDOWN:
            if event.key == pygame.K_r:
                restart()
            elif event.key == pygame.K_q:
                running = False
            elif event.key == pygame.K_l:
                show_leaderboard()

    pygame.display.flip()
    clock.tick(FPS)

pygame.quit()
