import pygame 
import random
import sys
import mysql.connector
from mysql.connector import Error

pygame.init()

WIDTH, HEIGHT = 810, 600
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Brick Buster")

clock = pygame.time.Clock()
font = pygame.font.SysFont(None, 40)
big_font = pygame.font.SysFont(None, 50)

WHITE = (255, 255, 255)
BLACK = (0, 0, 0)
Nevy_Blue = (20, 40, 40)
PADDLE_COLOR = (0, 255, 255)
BALL_COLOR = (255, 105, 180)
BULLET_COLOR = (255, 255, 0)

BG_COLORS = [
    (15, 15, 40),
    (30, 60, 30),
    (60, 30, 30),
    (40, 40, 70),
    (50, 50, 20),
    (0, 0, 64)
]

BRICK_COLORS = [
    (70, 130, 180),
    (180, 130, 70),
    (130, 70, 180),
    (180, 70, 130),
    (70, 180, 130),
]

POWERUP_COLORS = {
    "extend": (173, 216, 230),
    "life": (144, 238, 144),
    "slow": (255, 255, 224),
    "gun": (255, 182, 193),
    "fire": (255, 200, 150)
}

powerup_cooldowns = {p: -10000 for p in POWERUP_COLORS}
powerup_images = {}
for name, color in POWERUP_COLORS.items():
    surf = pygame.Surface((20, 20))
    surf.fill(color)
    pygame.draw.rect(surf, (0, 0, 0), surf.get_rect(), 2)
    powerup_images[name] = surf

paddle = pygame.Rect(WIDTH // 2 - 60, HEIGHT - 30, 120, 15)
ball = pygame.Rect(0, 0, 20, 20)
ball.centerx = paddle.centerx
ball.bottom = paddle.top

lives = 3
score = 0
level = 1
max_level = 5
fireball = False
gun_mode = False
ball_speed = [0, 0]
ball_in_play = False
dev_mode = False

powerups = []
bullets = []

def get_input(prompt, y):
    input_text = ""
    active = True
    while active:
        screen.fill(BLACK)
        draw_text_center(prompt, y, font)
        draw_text_center(input_text, y + 60, font, WHITE)
        pygame.display.flip()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_RETURN:
                    active = False
                elif event.key == pygame.K_BACKSPACE:
                    input_text = input_text[:-1]
                elif event.key == pygame.K_ESCAPE:
                    active = False
                else:
                    if len(input_text) < 20:
                        input_text += event.unicode
        clock.tick(30)
    return input_text

def get_initial_ball_speed():
    speed_x = random.choice([-1, 1]) * 4
    speed_y = -7
    return [speed_x, speed_y]

def create_level(lv):
    bricks = []
    rows = 5 + lv
    color = BRICK_COLORS[(lv - 1) % len(BRICK_COLORS)]
    for row in range(rows):
        for col in range(10):
            place_brick = False
            if lv == 1:
                place_brick = (row + col) % 2 == 0
            elif lv == 2:
                place_brick = (row % 2 == 0)
            elif lv == 3:
                place_brick = (row % 2 == 1 and 1 < col < 8)
            elif lv == 4:
                place_brick = (col % 3 != 0)
            elif lv == 5:
                max_cols = 10 - row * 2
                place_brick = (col >= row and col < row + max_cols)
            if place_brick:
                brick = pygame.Rect(col * 80 + 5, row * 30 + 50, 75, 25)
                bricks.append((brick, color))
    return bricks

bricks = create_level(level)

def draw_bricks():
    for b, c in bricks:
        pygame.draw.rect(screen, c, b)
        pygame.draw.rect(screen, BLACK, b, 2)

def draw_powerups():
    for p_rect, p_type in powerups:
        screen.blit(powerup_images[p_type], (p_rect.x, p_rect.y))

def draw_bullets():
    for b in bullets:
        pygame.draw.rect(screen, BULLET_COLOR, b)

def handle_powerup(p_type):
    global paddle, lives, ball_speed, fireball, gun_mode
    current_time = pygame.time.get_ticks()
    if current_time - powerup_cooldowns[p_type] < 15000:
        return
    powerup_cooldowns[p_type] = current_time

    if p_type == "extend":
        paddle.width = min(paddle.width + 40, WIDTH)
    elif p_type == "life":
        lives += 1
    elif p_type == "slow":
        ball_speed[0] *= 0.7
        ball_speed[1] *= 0.7
    elif p_type == "gun":
        gun_mode = True
    elif p_type == "fire":
        fireball = True

def reset_ball():
    global ball, ball_speed, ball_in_play, fireball, gun_mode
    ball.centerx = paddle.centerx
    ball.bottom = paddle.top
    ball_speed = [0, 0]
    ball_in_play = False
    fireball = False
    gun_mode = False

def draw_ui():
    txt = font.render(f"Score: {score}  Lives: {lives}  Level: {level}", True, WHITE)
    screen.blit(txt, (10, 10))
    if dev_mode:
        devtxt = font.render("DEVELOPER MODE - 1-5 to view levels, D to resume", True, (255, 255, 0))
        screen.blit(devtxt, (10, HEIGHT - 30))

def draw_text_center(text, y, font_obj, color=WHITE):
    txt = font_obj.render(text, True, color)
    screen.blit(txt, (WIDTH // 2 - txt.get_width() // 2, y))

def show_game_over():
    screen.fill(Nevy_Blue)
    text = big_font.render("Game Over!", True, WHITE)
    text1 = font.render("Press Enter to Submit Score and Exit", True, WHITE)
    screen.blit(text, (WIDTH // 2 - text.get_width() // 2, HEIGHT - 200))
    screen.blit(text1, (WIDTH // 2 - text1.get_width() // 2, HEIGHT // 2))
    pygame.display.flip()

import mysql.connector

def submit_score(score, level):
    name = get_input("Enter your name:", HEIGHT // 2 - 60)
    pid = get_input("Enter your ID:", HEIGHT // 2 + 20)
    
    try:
        con = mysql.connector.connect(host="localhost", user="root", password="", database="db_game")
        cur = con.cursor()
        
        # Check if player exists in players table
        cur.execute("SELECT player_name FROM players WHERE player_uid = %s", (pid,))
        res = cur.fetchone()
        
        if res:
            # Player exists, check name
            if res[0] != name:
                print("ID already used with a different name.")
                con.close()
                return
        else:
            # Insert new player
            cur.execute("INSERT INTO players (player_uid, player_name) VALUES (%s, %s)", (pid, name))
        
        # Check if player already has a leaderboard entry
        cur.execute("SELECT player_id FROM brickbuster_leaderboard WHERE player_id = %s", (pid,))
        leaderboard_entry = cur.fetchone()
        
        if leaderboard_entry:
            # Update leaderboard entry
            cur.execute("""
                UPDATE brickbuster_leaderboard 
                SET total_score = total_score + %s, 
                    highest_level = GREATEST(highest_level, %s),
                    last_played = NOW()
                WHERE player_id = %s
            """, (score, level, pid))
        else:
            # Insert new leaderboard entry
            cur.execute("""
                INSERT INTO brickbuster_leaderboard 
                (player_id, total_score, highest_level, difficulty, last_played) 
                VALUES (%s, %s, %s, %s, NOW())
            """, (pid, score, level, 'normal'))
        
        con.commit()
        con.close()
        print("Score submitted successfully!")
    
    except mysql.connector.Error as e:
        print(f"Database error: {e}")


def show_leaderboard():
    try:
        con = mysql.connector.connect(host="localhost", user="root", password="", database="db_game")
        cur = con.cursor()
        cur.execute("""
            SELECT b.player_id, p.player_name, b.total_score, b.highest_level, b.difficulty, b.last_played
            FROM brickbuster_leaderboard b
            JOIN players p ON b.player_id = p.player_uid
            ORDER BY b.total_score DESC
            LIMIT 10
        """)
        results = cur.fetchall()
        con.close()
    except Exception as e:
        results = []
        print(f"Database error: {e}")

    showing = True
    while showing:
        screen.fill(Nevy_Blue)
        draw_text_center("Leaderboard - Top 10 Players", 40, big_font)
        y_offset = 120

        if results:
            header = "ID       Name          Score      Level    Difficulty   Last Played"
            draw_text_center(header, y_offset - 40, font, (255, 255, 0))
            for i, (pid, name_, score_, lvl_, diff_, last_played_) in enumerate(results, 1):
                # Format the line for neat display; adjust spacing as needed
                line = f"{pid:<5} {name_:<20} {score_:<18} {lvl_:<7} {diff_:<11} {last_played_.strftime('%Y-%m-%d')}"
                draw_text_center(line, y_offset, font)
                y_offset += 40
        else:
            draw_text_center("No data available", HEIGHT // 2, font)

        draw_text_center("Press ESC to return", HEIGHT - 80, font, (255, 255, 0))
        pygame.display.flip()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            elif event.type == pygame.KEYDOWN and event.key == pygame.K_ESCAPE:
                showing = False


def fire_bullet():
    bullet = pygame.Rect(paddle.centerx - 4, paddle.top - 10, 8, 15)
    bullets.append(bullet)

def check_bullet_brick_collision():
    global score, bricks
    new_bullets = []
    for b in bullets:
        b.y -= 12
        if b.y < 0:
            continue
        hit_brick = None
        for i, (brick, color) in enumerate(bricks):
            if brick.colliderect(b):
                hit_brick = i
                break
        if hit_brick is not None:
            del bricks[hit_brick]
            score += 20
            continue
        new_bullets.append(b)
    return new_bullets

def check_ball_brick_collision():
    global ball_speed, score, bricks
    hit_index = None
    for i, (brick, color) in enumerate(bricks):
        if brick.colliderect(ball):
            hit_index = i
            break
    if hit_index is not None:
        if fireball:
            del bricks[hit_index]
            score += 20
        else:
            if abs(ball.bottom - bricks[hit_index][0].top) < 10 and ball_speed[1] > 0:
                ball_speed[1] = -ball_speed[1]
            elif abs(ball.top - bricks[hit_index][0].bottom) < 10 and ball_speed[1] < 0:
                ball_speed[1] = -ball_speed[1]
            elif abs(ball.right - bricks[hit_index][0].left) < 10 and ball_speed[0] > 0:
                ball_speed[0] = -ball_speed[0]
            elif abs(ball.left - bricks[hit_index][0].right) < 10 and ball_speed[0] < 0:
                ball_speed[0] = -ball_speed[0]
            else:
                ball_speed[1] = -ball_speed[1]

            del bricks[hit_index]
            score += 10

def check_powerup_spawn():
    if len(bricks) > 0:
        spawn_chance = 0.002
        if random.random() < spawn_chance:
            brick, _ = random.choice(bricks)
            p_type = random.choice(list(POWERUP_COLORS.keys()))
            powerup_rect = pygame.Rect(brick.x + brick.width // 2 - 10, brick.y, 20, 20)
            powerups.append((powerup_rect, p_type))

def check_powerup_collection():
    global powerups
    paddle_rect = paddle
    collected = []
    for i, (p_rect, p_type) in enumerate(powerups):
        p_rect.y += 3
        if p_rect.colliderect(paddle_rect):
            handle_powerup(p_type)
            collected.append(i)
        elif p_rect.y > HEIGHT:
            collected.append(i)
    powerups = [p for i, p in enumerate(powerups) if i not in collected]

def advance_level():
    global level, bricks, ball_in_play, ball_speed
    level += 1
    if level > max_level:
        return False
    bricks = create_level(level)
    reset_ball()
    return True

def dev_mode_keys(event):
    global level, bricks, ball_in_play, ball_speed, dev_mode
    if event.key == pygame.K_d:
        dev_mode = False
        reset_ball()
    elif event.key in (pygame.K_1, pygame.K_2, pygame.K_3, pygame.K_4, pygame.K_5):
        lvl_num = int(event.unicode)
        if 1 <= lvl_num <= max_level:
            level = lvl_num
            bricks = create_level(level)
            ball_in_play = False
            ball_speed = [0, 0]

def main_menu():
    menu = True
    selected = 0
    options = ["Start Game", "Leaderboard", "Exit"]
    while menu:
        screen.fill(Nevy_Blue)
        draw_text_center("Brick Buster", 100, big_font)
        for i, option in enumerate(options):
            color = WHITE if i == selected else (150, 150, 150)
            draw_text_center(option, 250 + i * 60, font, color)

        pygame.display.flip()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_UP:
                    selected = (selected - 1) % len(options)
                elif event.key == pygame.K_DOWN:
                    selected = (selected + 1) % len(options)
                elif event.key == pygame.K_RETURN:
                    if options[selected] == "Start Game":
                        return True
                    elif options[selected] == "Leaderboard":
                        show_leaderboard()
                    elif options[selected] == "Exit":
                        pygame.quit()
                        sys.exit()

def game_loop():
    global ball_in_play, ball_speed, lives, score, bricks, fireball, gun_mode, bullets, powerups, paddle, dev_mode

    running = True
    while running:
        screen.fill(BG_COLORS[(level-1) % len(BG_COLORS)])
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
                pygame.quit()
                sys.exit()
            elif event.type == pygame.KEYDOWN:
                if dev_mode:
                    dev_mode_keys(event)
                else:
                    if event.key == pygame.K_SPACE and not ball_in_play:
                        ball_in_play = True
                        ball_speed = get_initial_ball_speed()
                    elif event.key == pygame.K_d:
                        dev_mode = True
                        ball_in_play = False
                        ball_speed = [0, 0]
                    elif event.key == pygame.K_RETURN and gun_mode:
                        fire_bullet()

        keys = pygame.key.get_pressed()
        if keys[pygame.K_LEFT]:
            paddle.x -= 9
            if paddle.left < 0:
                paddle.left = 0
            if not ball_in_play:
                ball.centerx = paddle.centerx
        if keys[pygame.K_RIGHT]:
            paddle.x += 9
            if paddle.right > WIDTH:
                paddle.right = WIDTH
            if not ball_in_play:
                ball.centerx = paddle.centerx

        if ball_in_play:
            ball.x += int(ball_speed[0])
            ball.y += int(ball_speed[1])

            if ball.left <= 0 or ball.right >= WIDTH:
                ball_speed[0] = -ball_speed[0]
            if ball.top <= 0:
                ball_speed[1] = -ball_speed[1]
            if ball.colliderect(paddle):
                ball_speed[1] = -abs(ball_speed[1])
                hit_pos = (ball.centerx - paddle.left) / paddle.width
                ball_speed[0] = (hit_pos - 0.5) * 14

            check_ball_brick_collision()

            if ball.bottom > HEIGHT:
                lives -= 1
                if lives == 0:
                    show_game_over()
                    submit_score(score, level)
                    pygame.quit()
                    sys.exit()
                else:
                    reset_ball()

        check_powerup_spawn()
        check_powerup_collection()

        if gun_mode:
            bullets = check_bullet_brick_collision()

        for i, b in enumerate(bullets):
            if b.bottom < 0:
                bullets.pop(i)

        draw_bricks()
        pygame.draw.rect(screen, PADDLE_COLOR, paddle)
        pygame.draw.ellipse(screen, BALL_COLOR if not fireball else (255, 69, 0), ball)

        draw_powerups()
        draw_bullets()
        draw_ui()

        if not bricks:
            advanced = advance_level()
            if not advanced:
                screen.fill(Nevy_Blue)
                draw_text_center("You Win!", HEIGHT // 2 - 40, big_font)
                draw_text_center("Press Enter to Submit Score and Exit", HEIGHT // 2 + 40, font)
                pygame.display.flip()
                waiting = True
                while waiting:
                    for event in pygame.event.get():
                        if event.type == pygame.QUIT:
                            pygame.quit()
                            sys.exit()
                        elif event.type == pygame.KEYDOWN and event.key == pygame.K_RETURN:
                            submit_score(score, level)
                            pygame.quit()
                            sys.exit()

        pygame.display.flip()
        clock.tick(60)


if __name__ == "__main__":
    while True:
        start = main_menu()
        if start:
            level = 1
            lives = 3
            score = 0
            fireball = False
            gun_mode = False
            powerups.clear()
            bullets.clear()
            paddle.width = 120
            bricks = create_level(level)
            reset_ball()
            game_loop()


