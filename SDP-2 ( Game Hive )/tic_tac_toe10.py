import pygame
import sys
import random
import mysql.connector

pygame.init()

WIDTH, HEIGHT = 800, 600
LINE_WIDTH = 15
BOARD_ROWS, BOARD_COLS = 3, 3
SQUARE_SIZE = 500 // BOARD_COLS
CIRCLE_RADIUS = SQUARE_SIZE // 3
CIRCLE_WIDTH = 15
CROSS_WIDTH = 25
SPACE = SQUARE_SIZE // 5

BG_COLOR = (10, 10, 30)
LINE_COLOR = (255, 215, 0)
CIRCLE_COLOR = (0, 204, 204)
CROSS_COLOR = (255, 102, 102)
WIN_COLOR = (255, 255, 0)
BUTTON_COLOR = (50, 50, 50)
BUTTON_HOVER = (70, 70, 70)
TEXT_COLOR = (255, 255, 255)
BUTTON_BORDER_COLOR = (255, 215, 0)

screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption('Tic Tac Toe')

board = [[0 for _ in range(BOARD_COLS)] for _ in range(BOARD_ROWS)]
player = 1
game_over = False
bot_mode = False

font = pygame.font.SysFont(None, 80)
button_font = pygame.font.SysFont(None, 40)
input_font = pygame.font.SysFont(None, 36)

offset_x = (WIDTH - (SQUARE_SIZE * BOARD_COLS)) // 2
offset_y = (HEIGHT - (SQUARE_SIZE * BOARD_ROWS)) // 2

db_config = {
    'host': 'localhost',
    'user': 'root',
    'password':'',  # change as needed
    'database': 'db_game'
}

def connect_db():
    try:
        conn = mysql.connector.connect(**db_config)
        return conn
    except mysql.connector.Error as e:
        print(f"DB connection error: {e}")
        return None

def update_leaderboard(player_id, player_name, result):
    conn = connect_db()
    if not conn:
        return
    cursor = conn.cursor()

    # Check player name in the players table instead
    cursor.execute("SELECT player_name FROM players WHERE player_uid=%s", (player_id,))
    row = cursor.fetchone()
    if row:
        if row[0] != player_name:
            print("Player ID and name do not match!")
            conn.close()
            return
        # Update leaderboard
        if result == 'win':
            cursor.execute("UPDATE tictactoe_leaderboard SET wins=wins+1 WHERE player_id=%s", (player_id,))
        elif result == 'loss':
            cursor.execute("UPDATE tictactoe_leaderboard SET losses=losses+1 WHERE player_id=%s", (player_id,))
        elif result == 'tie':
            cursor.execute("UPDATE tictactoe_leaderboard SET ties=ties+1 WHERE player_id=%s", (player_id,))

        # If the player is not in leaderboard table, create a new row
        cursor.execute("SELECT * FROM tictactoe_leaderboard WHERE player_id=%s", (player_id,))
        leaderboard_row = cursor.fetchone()
        if not leaderboard_row:
            wins = 1 if result == 'win' else 0
            losses = 1 if result == 'loss' else 0
            ties = 1 if result == 'tie' else 0
            cursor.execute(
                "INSERT INTO tictactoe_leaderboard (player_id, wins, losses, ties) VALUES (%s, %s, %s, %s)",
                (player_id, wins, losses, ties)
            )
    else:
        # If player doesn't exist in players table, add to players and leaderboard
        cursor.execute(
            "INSERT INTO players (player_uid, player_name) VALUES (%s, %s)", (player_id, player_name)
        )
        wins = 1 if result == 'win' else 0
        losses = 1 if result == 'loss' else 0
        ties = 1 if result == 'tie' else 0
        cursor.execute(
            "INSERT INTO tictactoe_leaderboard (player_id, wins, losses, ties) VALUES (%s, %s, %s, %s)",
            (player_id, wins, losses, ties)
        )

    conn.commit()
    conn.close()


def get_leaderboard(top):
    conn = mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="db_game"
    )
    cursor = conn.cursor()
    query = """
        SELECT t.player_id, p.player_name, t.wins, t.losses, t.ties
        FROM tictactoe_leaderboard t
        JOIN players p ON t.player_id = p.player_uid
        ORDER BY t.wins DESC, t.ties DESC
        LIMIT %s
    """
    cursor.execute(query, (top,))
    leaders = cursor.fetchall()
    cursor.close()
    conn.close()
    return leaders


def search_player(player_id):
    conn = connect_db()
    if not conn:
        return None
    cursor = conn.cursor()
    cursor.execute("""
        SELECT t.player_id, p.player_name, t.wins, t.losses, t.ties
        FROM tictactoe_leaderboard t
        JOIN players p ON t.player_id = p.player_uid
        WHERE t.player_id = %s
    """, (player_id,))
    result = cursor.fetchone()
    conn.close()
    return result


def text_input_box(prompt):
    input_text = ''
    clock = pygame.time.Clock()
    active = True
    while active:
        screen.fill(BG_COLOR)
        prompt_surface = input_font.render(prompt, True, TEXT_COLOR)
        input_surface = input_font.render(input_text, True, TEXT_COLOR)
        screen.blit(prompt_surface, (WIDTH // 2 - prompt_surface.get_width() // 2, HEIGHT // 3))
        pygame.draw.rect(screen, TEXT_COLOR, (WIDTH // 4, HEIGHT // 2, WIDTH // 2, 50), 2)
        screen.blit(input_surface, (WIDTH // 4 + 10, HEIGHT // 2 + 10))
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_RETURN and input_text.strip():
                    active = False
                elif event.key == pygame.K_BACKSPACE:
                    input_text = input_text[:-1]
                else:
                    if len(input_text) < 20:
                        input_text += event.unicode
        pygame.display.update()
        clock.tick(30)
    return input_text.strip()

def display_leaderboard():
    clock = pygame.time.Clock()
    while True:
        screen.fill(BG_COLOR)
        title = font.render("Leaderboard - Top 10", True, TEXT_COLOR)
        screen.blit(title, (WIDTH // 2 - title.get_width() // 2, 30))
        leaders = get_leaderboard(10)
        y_start = 150
        line_height = 40
        header = "Rank | ID | Name | Wins | Losses | Ties"
        header_surf = input_font.render(header, True, TEXT_COLOR)
        screen.blit(header_surf, (WIDTH // 2 - header_surf.get_width() // 2, y_start - 50))
        for i, (pid, pname, wins, losses, ties) in enumerate(leaders):
            line = f"{i+1}. {pid} | {pname} | {wins} | {losses} | {ties}"
            text_surf = input_font.render(line, True, TEXT_COLOR)
            screen.blit(text_surf, (WIDTH // 2 - text_surf.get_width() // 2, y_start + i * line_height))
        info = input_font.render("Press 'S' to search, 'B' to go back", True, TEXT_COLOR)
        screen.blit(info, (WIDTH // 2 - info.get_width() // 2, HEIGHT - 70))
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                if event.key == pygame.K_b:
                    return
                if event.key == pygame.K_s:
                    pid = text_input_box("Enter Player ID:")
                    player_data = search_player(pid)
                    show_search_result(player_data)
        pygame.display.update()
        clock.tick(30)

def show_search_result(player_data):
    clock = pygame.time.Clock()
    while True:
        screen.fill(BG_COLOR)
        if player_data:
            pid, pname, wins, losses, ties = player_data
            lines = [f"Player ID: {pid}", f"Name: {pname}", f"Wins: {wins}", f"Losses: {losses}", f"Ties: {ties}"]
        else:
            lines = ["Player not found!"]
        for i, line in enumerate(lines):
            text_surf = input_font.render(line, True, TEXT_COLOR)
            screen.blit(text_surf, (WIDTH // 2 - text_surf.get_width() // 2, HEIGHT // 3 + i * 40))
        info = input_font.render("Press any key to go back", True, TEXT_COLOR)
        screen.blit(info, (WIDTH // 2 - info.get_width() // 2, HEIGHT - 70))
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.KEYDOWN:
                return
        pygame.display.update()
        clock.tick(30)

def draw_lines():
    for i in range(1, BOARD_ROWS):
        pygame.draw.line(screen, LINE_COLOR, (offset_x, offset_y + i * SQUARE_SIZE), (offset_x + BOARD_COLS * SQUARE_SIZE, offset_y + i * SQUARE_SIZE), LINE_WIDTH)
    for j in range(1, BOARD_COLS):
        pygame.draw.line(screen, LINE_COLOR, (offset_x + j * SQUARE_SIZE, offset_y), (offset_x + j * SQUARE_SIZE, offset_y + BOARD_ROWS * SQUARE_SIZE), LINE_WIDTH)

def draw_figures():
    for row in range(BOARD_ROWS):
        for col in range(BOARD_COLS):
            if board[row][col] == 1:
                pygame.draw.line(screen, CROSS_COLOR, (offset_x + col * SQUARE_SIZE + SPACE, offset_y + row * SQUARE_SIZE + SPACE), (offset_x + (col + 1) * SQUARE_SIZE - SPACE, offset_y + (row + 1) * SQUARE_SIZE - SPACE), CROSS_WIDTH)
                pygame.draw.line(screen, CROSS_COLOR, (offset_x + col * SQUARE_SIZE + SPACE, offset_y + (row + 1) * SQUARE_SIZE - SPACE), (offset_x + (col + 1) * SQUARE_SIZE - SPACE, offset_y + row * SQUARE_SIZE + SPACE), CROSS_WIDTH)
            elif board[row][col] == 2:
                pygame.draw.circle(screen, CIRCLE_COLOR, (offset_x + col * SQUARE_SIZE + SQUARE_SIZE // 2, offset_y + row * SQUARE_SIZE + SQUARE_SIZE // 2), CIRCLE_RADIUS, CIRCLE_WIDTH)

def check_winner(player):
    for row in range(BOARD_ROWS):
        if board[row] == [player] * BOARD_COLS:
            pygame.draw.line(screen, WIN_COLOR, (offset_x, offset_y + row * SQUARE_SIZE + SQUARE_SIZE // 2), (offset_x + BOARD_COLS * SQUARE_SIZE, offset_y + row * SQUARE_SIZE + SQUARE_SIZE // 2), 10)
            return True
    for col in range(BOARD_COLS):
        if [board[row][col] for row in range(BOARD_ROWS)] == [player] * BOARD_ROWS:
            pygame.draw.line(screen, WIN_COLOR, (offset_x + col * SQUARE_SIZE + SQUARE_SIZE // 2, offset_y), (offset_x + col * SQUARE_SIZE + SQUARE_SIZE // 2, offset_y + BOARD_ROWS * SQUARE_SIZE), 10)
            return True
    if all(board[i][i] == player for i in range(BOARD_ROWS)):
        pygame.draw.line(screen, WIN_COLOR, (offset_x, offset_y), (offset_x + BOARD_COLS * SQUARE_SIZE, offset_y + BOARD_ROWS * SQUARE_SIZE), 10)
        return True
    if all(board[i][BOARD_ROWS - 1 - i] == player for i in range(BOARD_ROWS)):
        pygame.draw.line(screen, WIN_COLOR, (offset_x, offset_y + BOARD_ROWS * SQUARE_SIZE), (offset_x + BOARD_COLS * SQUARE_SIZE, offset_y), 10)
        return True
    return False

def is_board_full():
    return all(cell != 0 for row in board for cell in row)

def bot_move():
    empty = [(r, c) for r in range(BOARD_ROWS) for c in range(BOARD_COLS) if board[r][c] == 0]
    if empty:
        row, col = random.choice(empty)
        board[row][col] = 2

def draw_menu_title():
    font = pygame.font.SysFont(None, 72)  # None = default font, 72 = font size
    text_surface = font.render("TIC TAC TOE", True, (255, 255, 255))  # White color
    text_rect = text_surface.get_rect(center=(screen.get_width() // 2, 50))  # Centered horizontally, 50 px from top
    screen.blit(text_surface, text_rect)

def main_menu():
    clock = pygame.time.Clock()
    play_button = pygame.Rect(WIDTH // 2 - 100, HEIGHT // 2 - 80, 200, 60)
    bot_button = pygame.Rect(WIDTH // 2 - 100, HEIGHT // 2, 200, 60)
    leaderboard_button = pygame.Rect(WIDTH // 2 - 100, HEIGHT // 2 + 80, 200, 60)
    quit_button = pygame.Rect(WIDTH // 2 - 100, HEIGHT // 2 + 160, 200, 60)
    title_font = pygame.font.SysFont(None, 72)

    while True:
        screen.fill(BG_COLOR)
        mouse_pos = pygame.mouse.get_pos()

        # Draw title
        title_surface = title_font.render("TIC TAC TOE", True, (255, 255, 255))
        title_rect = title_surface.get_rect(center=(WIDTH // 2, 80))
        screen.blit(title_surface, title_rect)

        def draw_button(rect, text):
            color = BUTTON_HOVER if rect.collidepoint(mouse_pos) else BUTTON_COLOR
            pygame.draw.rect(screen, color, rect)
            pygame.draw.rect(screen, BUTTON_BORDER_COLOR, rect, 2)
            text_surf = button_font.render(text, True, TEXT_COLOR)
            screen.blit(text_surf, (rect.centerx - text_surf.get_width() // 2, rect.centery - text_surf.get_height() // 2))

        draw_button(play_button, "Play PvP")
        draw_button(bot_button, "Play vs Bot")
        draw_button(leaderboard_button, "Leaderboard")
        draw_button(quit_button, "Quit")

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
            if event.type == pygame.MOUSEBUTTONDOWN:
                if play_button.collidepoint(event.pos):
                    return 'pvp'
                elif bot_button.collidepoint(event.pos):
                    return 'bot'
                elif leaderboard_button.collidepoint(event.pos):
                    display_leaderboard()
                elif quit_button.collidepoint(event.pos):
                    pygame.quit()
                    sys.exit()

        pygame.display.update()
        clock.tick(30)


def game_loop():
    global player, game_over, board, bot_mode
    clock = pygame.time.Clock()
    
    if bot_mode:
        player_id = text_input_box("Enter your Player ID:")
        player_name = text_input_box("Enter your Name:")
    else:
        player_id = None
        player_name = None
    
    while True:
        screen.fill(BG_COLOR)
        draw_lines()
        draw_figures()
        
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                pygame.quit()
                sys.exit()
                
            if not game_over and event.type == pygame.MOUSEBUTTONDOWN:
                mx, my = event.pos
                if offset_x <= mx <= offset_x + BOARD_COLS * SQUARE_SIZE and offset_y <= my <= offset_y + BOARD_ROWS * SQUARE_SIZE:
                    col = (mx - offset_x) // SQUARE_SIZE
                    row = (my - offset_y) // SQUARE_SIZE
                    if board[row][col] == 0:
                        board[row][col] = player
                        
                        screen.fill(BG_COLOR)
                        draw_lines()
                        draw_figures()
                        pygame.display.update()
                        
                        if check_winner(player):
                            game_over = True
                            if bot_mode:
                                update_leaderboard(player_id, player_name, 'win')
                        elif is_board_full():
                            game_over = True
                            if bot_mode:
                                update_leaderboard(player_id, player_name, 'tie')
                        else:
                            player = 2 if player == 1 else 1
                            if bot_mode and player == 2:
                                bot_move()
                                screen.fill(BG_COLOR)
                                draw_lines()
                                draw_figures()
                                pygame.display.update()
                                
                                if check_winner(2):
                                    game_over = True
                                    update_leaderboard(player_id, player_name, 'loss')
                                elif is_board_full():
                                    game_over = True
                                    update_leaderboard(player_id, player_name, 'tie')
                                else:
                                    player = 1
        
        pygame.display.update()
        clock.tick(30)
        
        if game_over:
            pygame.time.wait(2000)
            board = [[0 for _ in range(BOARD_COLS)] for _ in range(BOARD_ROWS)]
            player = 1
            game_over = False
            return



if __name__ == '__main__':
    while True:
        mode = main_menu()
        bot_mode = (mode == 'bot')
        game_loop()
