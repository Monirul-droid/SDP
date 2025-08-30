import pygame
import random
import time
import mysql.connector
import threading
pygame.init()

WIDTH, HEIGHT = 800,800
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Maze Game")

WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
DEEP_BLACK = (0, 0, 0, 255)
RED = (255, 0, 0)
GREEN = (0, 255, 0)
BLUE = (0, 100, 255)
NAVY_BLUE = (0, 0, 128)
YELLOW = (255, 255, 0)
CYAN = (0, 255, 255)
MAGENTA = (255, 0, 255)
ORANGE = (255, 165, 0)
PURPLE = (128, 0, 128)
GRAY = (128, 128, 128)
LIGHT_BLUE = (173, 216, 230)
LIGHT_GREEN = (144, 238, 144)
LIGHT_YELLOW = (255, 255, 224)
LIGHT_RED = (255, 182, 193)
LIGHT_CYAN = (224, 255, 255)
LIGHT_MAGENTA = (255, 153, 255)
LIGHT_ORANGE = (255, 200, 150)
LIGHT_PURPLE = (216, 191, 216)
LIGHT_GRAY = (211, 211, 211)

GRID_SIZE = 20
GRID_WIDTH = WIDTH // GRID_SIZE
GRID_HEIGHT = (HEIGHT - 40) // GRID_SIZE

player_size = GRID_SIZE
player_pos = (1, 1)

walls = []
goal_pos = None

time_limit = 60
start_time = None

font = pygame.font.SysFont("Arial", 80, bold=True)
timer_font = pygame.font.SysFont("Arial", 30, bold=True)

DIRECTIONS = [(0, 1), (1, 0), (0, -1), (-1, 0)]

# Connect to MySQL database
db_connection = mysql.connector.connect(
    host="localhost",
    user="root",
    password="",  # put your MySQL root password here
    database="db_game"
)
cursor = db_connection.cursor()

def choose_difficulty():
    choosing = True
    font_menu = pygame.font.SysFont("Arial", 50, )
    title_font = pygame.font.SysFont("Arial", 90, )
    color_shift = 0
    direction = 1
    pulse = 0
    pulse_direction = 1
    clock = pygame.time.Clock()

    while choosing:
        grey_value = 128 + int(color_shift)
        screen.fill((grey_value, grey_value, grey_value))
        color_shift += direction * 2
        if color_shift > 50 or color_shift < -50:
            direction *= -1

        pulse += pulse_direction * 0.5
        if pulse > 5 or pulse < -5:
            pulse_direction *= -1

        text = title_font.render("Maze Game", True, DEEP_BLACK)
        text1 = font_menu.render("Choose Difficulty", True, DEEP_BLACK)
        easy = font_menu.render("E: Easy (4 minutes)", True, BLACK)
        hard = font_menu.render("H: Hard (1.5 minute)", True, BLACK)
        leaderboard = font_menu.render("L: Leaderboard", True, BLACK)
        quit_game = font_menu.render("Q: Quit", True, BLACK)

        screen.blit(text, (WIDTH // 2 - text.get_width() // 2, 40 + int(pulse)))

        pygame.draw.rect(screen, ORANGE, (WIDTH // 2 - text1.get_width() // 2, 200, text1.get_width() + 35, 65), border_radius=16)
        pygame.draw.rect(screen, ORANGE, (WIDTH // 2 - easy.get_width() // 2 - 10, 295, easy.get_width() + 35, 65), border_radius=16)
        pygame.draw.rect(screen, ORANGE, (WIDTH // 2 - hard.get_width() // 2 - 10, 375, hard.get_width() + 35, 65), border_radius=16)
        pygame.draw.rect(screen, ORANGE, (WIDTH // 2 - leaderboard.get_width() // 2 - 10, 455, leaderboard.get_width() + 35, 65), border_radius=16)
        pygame.draw.rect(screen, ORANGE, (WIDTH // 2 - quit_game.get_width() // 2 - 10, 535, quit_game.get_width() + 35, 65), border_radius=16)

        screen.blit(text1, (WIDTH // 2 - text1.get_width() // 2, 202))
        screen.blit(easy, (WIDTH // 2 - easy.get_width() // 2, 300))
        screen.blit(hard, (WIDTH // 2 - hard.get_width() // 2, 380))
        screen.blit(leaderboard, (WIDTH // 2 - leaderboard.get_width() // 2, 460))
        screen.blit(quit_game, (WIDTH // 2 - quit_game.get_width() // 2, 540))

        pygame.display.update()
        clock.tick(30)

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_e:
                    return 240  # 4 minutes
                elif event.key == pygame.K_h:
                    return 90   # 1.5 minutes
                elif event.key == pygame.K_l:
                    show_leaderboard()
                elif event.key == pygame.K_q:
                    pygame.quit()
                    exit()

def show_leaderboard():
    import mysql.connector
    import pygame
    from pygame.locals import QUIT, KEYDOWN, K_ESCAPE

    try:
        db_connection = mysql.connector.connect(
            host="localhost",
            user="root",
            password="",
            database="db_game"
        )
        cursor = db_connection.cursor()
        cursor.execute("""
            SELECT players.player_uid, players.player_name, maze_leaderboard.points
            FROM players
            JOIN maze_leaderboard ON players.player_uid = maze_leaderboard.player_id
            ORDER BY maze_leaderboard.points DESC
            LIMIT 10
        """)
        leaderboard_data = cursor.fetchall()
        cursor.close()
        db_connection.close()
    except mysql.connector.Error as e:
        print(f"Database error: {e}")
        return

    screen.fill(LIGHT_YELLOW)
    font_title = pygame.font.SysFont("Arial", 50)
    font_entry = pygame.font.SysFont("Arial", 30)

    title_surface = font_title.render("Leaderboard - Top 10", True, BLACK)
    screen.blit(title_surface, (WIDTH // 2 - title_surface.get_width() // 2, 50))

    y = 130
    for idx, (player_uid, player_name, points) in enumerate(leaderboard_data):
        entry_text = f"{idx + 1}. {player_name} ({player_uid}) - {points} pts"
        entry_surface = font_entry.render(entry_text, True, BLACK)
        screen.blit(entry_surface, (WIDTH // 2 - entry_surface.get_width() // 2, y))
        y += 40

    info_surface = font_entry.render("Press ESC to return", True, RED)
    screen.blit(info_surface, (WIDTH // 2 - info_surface.get_width() // 2, y + 40))

    pygame.display.update()

    # Wait in this leaderboard screen until user presses ESC or closes window
    showing = True
    clock = pygame.time.Clock()
    while showing:
        for event in pygame.event.get():
            if event.type == QUIT:
                pygame.quit()
                exit()
            if event.type == KEYDOWN:
                if event.key == K_ESCAPE:
                    showing = False
        clock.tick(30)



def generate_maze():
    global walls, goal_pos
    walls = []
    maze = [[1 for _ in range(GRID_WIDTH)] for _ in range(GRID_HEIGHT)]

    def carve_path(x, y):
        maze[y][x] = 0
        random.shuffle(DIRECTIONS)
        for dx, dy in DIRECTIONS:
            nx, ny = x + dx * 2, y + dy * 2
            if 0 <= nx < GRID_WIDTH and 0 <= ny < GRID_HEIGHT and maze[ny][nx] == 1:
                maze[ny][nx] = 0
                maze[y + dy][x + dx] = 0
                carve_path(nx, ny)

    start_x, start_y = random.randrange(1, GRID_WIDTH, 2), random.randrange(1, GRID_HEIGHT, 2)
    carve_path(start_x, start_y)

    walls = [(x, y) for x in range(GRID_WIDTH) for y in range(GRID_HEIGHT) if maze[y][x] == 1]
    goal_pos = (random.randint(1, GRID_WIDTH - 2), random.randint(1, GRID_HEIGHT - 2))
    while goal_pos in walls:
        goal_pos = (random.randint(1, GRID_WIDTH - 2), random.randint(1, GRID_HEIGHT - 2))

def draw_maze():
    for x in range(GRID_WIDTH):
        for y in range(GRID_HEIGHT):
            screen_y = (y + 2) * GRID_SIZE
            if (x, y) in walls:
                pygame.draw.rect(screen, BLACK, (x * GRID_SIZE, screen_y, GRID_SIZE, GRID_SIZE))
            elif (x, y) == goal_pos:
                pygame.draw.rect(screen, RED, (x * GRID_SIZE, screen_y, GRID_SIZE, GRID_SIZE))

def draw_player():
    screen_y = (player_pos[1] + 2) * GRID_SIZE
    pygame.draw.rect(screen, GREEN, (player_pos[0] * GRID_SIZE, screen_y, player_size, player_size))

def check_collision(x, y):
    return (x, y) in walls

def game_win():
    text = font.render("You Win!", True, NAVY_BLUE)
    screen.blit(text, (WIDTH // 2 - text.get_width() // 2, HEIGHT // 2 - text.get_height() // 2))
    pygame.display.update()

def game_over(message="Game Over"):
    text = font.render(message, True, RED)
    screen.blit(text, (WIDTH // 2 - text.get_width() // 2, HEIGHT // 2 - text.get_height() // 2))
    pygame.display.update()

def draw_timer(time_left):
    pygame.draw.rect(screen, LIGHT_YELLOW, (0, 0, WIDTH, 40))
    timer_text = timer_font.render(f"Time Left: {time_left}s", True, PURPLE)
    screen.blit(timer_text, (10, 5))
    controls_text = timer_font.render("R =Restart   Q =Exit   M =Main Menu", True, NAVY_BLUE)
    screen.blit(controls_text, (WIDTH - controls_text.get_width() - 10, 5))



def save_score(points):
    try:
        db_connection = mysql.connector.connect(
            host="localhost",
            user="root",
            password="",
            database="db_game"
        )
        cursor = db_connection.cursor()
    except mysql.connector.Error as e:
        print(f"Database connection error: {e}")
        return

    input_active = {"id": True, "name": False}
    player_id = ""
    player_name = ""
    input_font = pygame.font.SysFont("Arial", 40)
    input_box_id = pygame.Rect(WIDTH // 2 - 150, HEIGHT // 2 - 60, 300, 50)
    input_box_name = pygame.Rect(WIDTH // 2 - 150, HEIGHT // 2 + 30, 300, 50)
    color_inactive = GRAY
    color_active = ORANGE
    color_id = color_active
    color_name = color_inactive

    clock = pygame.time.Clock()
    done = False
    error_msg = ""

    while not done:
        screen.fill(LIGHT_YELLOW)
        prompt_text1 = input_font.render("Enter Player ID:", True, BLACK)
        prompt_text2 = input_font.render("Enter Player Name:", True, BLACK)
        screen.blit(prompt_text1, (input_box_id.x, input_box_id.y - 40))
        screen.blit(prompt_text2, (input_box_name.x, input_box_name.y - 40))

        pygame.draw.rect(screen, color_id, input_box_id, 3)
        pygame.draw.rect(screen, color_name, input_box_name, 3)

        id_surface = input_font.render(player_id, True, BLACK)
        name_surface = input_font.render(player_name, True, BLACK)
        screen.blit(id_surface, (input_box_id.x + 5, input_box_id.y + 5))
        screen.blit(name_surface, (input_box_name.x + 5, input_box_name.y + 5))

        if error_msg:
            error_surface = input_font.render(error_msg, True, RED)
            screen.blit(error_surface, (WIDTH // 2 - error_surface.get_width() // 2, input_box_name.y + 80))

        pygame.display.update()
        clock.tick(30)

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                exit()

            if event.type == pygame.MOUSEBUTTONDOWN:
                if input_box_id.collidepoint(event.pos):
                    input_active["id"] = True
                    input_active["name"] = False
                elif input_box_name.collidepoint(event.pos):
                    input_active["id"] = False
                    input_active["name"] = True
                else:
                    input_active["id"] = False
                    input_active["name"] = False

            if event.type == pygame.KEYDOWN:
                if input_active["id"]:
                    if event.key == pygame.K_BACKSPACE:
                        player_id = player_id[:-1]
                    elif event.key == pygame.K_RETURN:
                        if player_id.strip():
                            input_active["id"] = False
                            input_active["name"] = True
                    else:
                        if len(player_id) < 20 and event.unicode.isalnum():
                            player_id += event.unicode

                elif input_active["name"]:
                    if event.key == pygame.K_BACKSPACE:
                        player_name = player_name[:-1]
                    elif event.key == pygame.K_RETURN:
                        if player_name.strip():
                            try:
                                # Check if player ID exists
                                cursor.execute("SELECT player_name FROM players WHERE player_uid = %s", (player_id,))
                                result = cursor.fetchone()
                                if result:
                                    if result[0] != player_name:
                                        error_msg = "ID exists with different name. Use another ID."
                                    else:
                                        # Update or insert into maze_leaderboard
                                        cursor.execute("SELECT points FROM maze_leaderboard WHERE player_id = %s", (player_id,))
                                        lb_result = cursor.fetchone()
                                        if lb_result:
                                            if points > lb_result[0]:
                                                cursor.execute("UPDATE maze_leaderboard SET points = %s WHERE player_id = %s",
                                                               (points, player_id))
                                        else:
                                            cursor.execute("INSERT INTO maze_leaderboard (player_id, points) VALUES (%s, %s)",
                                                           (player_id, points))
                                        db_connection.commit()
                                        done = True
                                else:
                                    # New player: insert into players and maze_leaderboard
                                    cursor.execute("INSERT INTO players (player_uid, player_name) VALUES (%s, %s)",
                                                   (player_id, player_name))
                                    cursor.execute("INSERT INTO maze_leaderboard (player_id, points) VALUES (%s, %s)",
                                                   (player_id, points))
                                    db_connection.commit()
                                    done = True
                            except mysql.connector.Error as e:
                                error_msg = f"Database error: {e}"
                    else:
                        if len(player_name) < 20 and (event.unicode.isalpha() or event.unicode.isspace()):
                            player_name += event.unicode

            color_id = color_active if input_active["id"] else color_inactive
            color_name = color_active if input_active["name"] else color_inactive

    cursor.close()
    db_connection.close()



def main_game(time_limit):
    global player_pos, start_time
    generate_maze()
    player_pos = (1, 1)
    start_time = time.time()

    running = True
    clock = pygame.time.Clock()
    while running:
        elapsed = time.time() - start_time
        time_left = max(0, int(time_limit - elapsed))

        screen.fill(LIGHT_YELLOW)

        draw_maze()
        draw_player()
        draw_timer(time_left)

        if time_left <= 0:
            game_over("Time's Up!")
            pygame.display.update()
            pygame.time.wait(1500)
            running = False

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
                pygame.quit()
                exit()
            if event.type == pygame.KEYDOWN:
                x, y = player_pos
                if event.key == pygame.K_LEFT:
                    if not check_collision(x - 1, y):
                        player_pos = (x - 1, y)
                elif event.key == pygame.K_RIGHT:
                    if not check_collision(x + 1, y):
                        player_pos = (x + 1, y)
                elif event.key == pygame.K_UP:
                    if not check_collision(x, y - 1):
                        player_pos = (x, y - 1)
                elif event.key == pygame.K_DOWN:
                    if not check_collision(x, y + 1):
                        player_pos = (x, y + 1)
                elif event.key == pygame.K_r:
                    main_game(time_limit)  # restart
                    return
                elif event.key == pygame.K_q:
                    pygame.quit()
                    exit()
                elif event.key == pygame.K_m:
                    return  # back to difficulty menu

        if player_pos == goal_pos:
            game_win()
            pygame.display.update()
            pygame.time.wait(1500)
            # save score as remaining seconds
            points = time_left
            save_score(points)
            running = False

        pygame.display.update()
        clock.tick(60)

def main():
    while True:
        selected_time = choose_difficulty()
        if selected_time:
            main_game(selected_time)

if __name__ == "__main__":
    main()
