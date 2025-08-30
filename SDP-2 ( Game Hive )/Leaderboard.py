import pygame 
import mysql.connector

# Database config
db_config = {
    'host': 'localhost',
    'user': 'root',
    'password': '',
    'database': 'db_game'
}

# Pygame setup
pygame.init()
WIDTH, HEIGHT = 1000, 700  # Increased height for search results
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Game Hive Leaderboards")
clock = pygame.time.Clock()

# Fonts
FONT = pygame.font.SysFont("Arial", 24, bold=True)
HEADER_FONT = pygame.font.SysFont("Arial", 18, bold=True)
SMALL_FONT = pygame.font.SysFont("Arial", 16)

# Cyberpunk Color Scheme
BG_COLOR = (15, 15, 26)
BOX_COLOR = (0, 128, 255)        # Electric blue
HOVER_COLOR = (255, 105, 180)    # Hot pink
ROW_BG_COLOR = (20, 20, 40)      # Dark navy for rows
ROW_BORDER_COLOR = (0, 255, 255) # Neon cyan
HEADER_TEXT_COLOR = (255, 0, 255) # Magenta
ROW_TEXT_COLOR = (255, 255, 0)    # Neon yellow
TITLE_COLOR = (0, 255, 128)      # Bright green
INPUT_BG_COLOR = (30, 30, 50)
INPUT_ACTIVE_COLOR = (0, 255, 128)
INPUT_INACTIVE_COLOR = (100, 100, 100)
TEXT_COLOR = (255, 255, 255)

# Leaderboard configurations
leaderboards = [
    {'title': 'Brick Buster', 'table': 'brickbuster_leaderboard',
     'columns': ['player_id', 'player_name', 'total_score', 'highest_level', 'difficulty', 'last_played']},
    {'title': 'Hangman', 'table': 'hangman_leaderboard',
     'columns': ['player_id', 'player_name', 'score']},
    {'title': 'Maze', 'table': 'maze_leaderboard',
     'columns': ['player_id', 'player_name', 'points']},
    {'title': 'Tic Tac Toe', 'table': 'tictactoe_leaderboard',
     'columns': ['player_id', 'player_name', 'wins', 'losses', 'ties']},
    {'title': 'Trapper', 'table': 'trapper_leaderboard',
     'columns': ['player_id', 'player_name', 'time_survived', 'walls_placed']}
]

# Button setup
button_width = 180
button_height = 50
button_margin = 10
button_rects = []
for i, lb in enumerate(leaderboards):
    x = 30 + (button_width + button_margin) * i
    y = 30
    button_rects.append(pygame.Rect(x, y, button_width, button_height))

current_lb_index = 0

# Search input box
input_box = pygame.Rect(30, 100, 200, 40)
input_active = False
input_text = ""
search_results = None  # will hold dict {game_title: [(columns, values), ...]}

def fetch_leaderboard_data(table, columns):
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()

    # Build the column list for SQL
    # We remove 'player_name' because it's not in leaderboard tables but in players table
    leaderboard_cols = [col for col in columns if col != 'player_name']

    # Compose SQL query with JOIN to get player_name from players table
    # Assuming 'player_id' is always present in leaderboard table
    query = f"""
        SELECT lb.player_id, p.player_name, {', '.join(['lb.' + col for col in leaderboard_cols if col != 'player_id'])}
        FROM {table} lb
        LEFT JOIN players p ON lb.player_id = p.player_uid
        ORDER BY {leaderboard_cols[1] if len(leaderboard_cols) > 1 else leaderboard_cols[0]} DESC
        LIMIT 15
    """
    cursor.execute(query)
    data = cursor.fetchall()
    conn.close()
    return data

def fetch_player_info(player_id):
    """Fetches player info from all leaderboards for given player_id."""
    conn = mysql.connector.connect(**db_config)
    cursor = conn.cursor()
    results = {}
    for lb in leaderboards:
        table = lb['table']
        cols = lb['columns']
        leaderboard_cols = [c for c in cols if c != 'player_name']

        # Compose query for single player_id
        query = f"""
            SELECT lb.player_id, p.player_name, {', '.join(['lb.' + col for col in leaderboard_cols if col != 'player_id'])}
            FROM {table} lb
            LEFT JOIN players p ON lb.player_id = p.player_uid
            WHERE lb.player_id = %s
            LIMIT 1
        """
        cursor.execute(query, (player_id,))
        row = cursor.fetchone()
        if row:
            results[lb['title']] = (cols, row)
        else:
            results[lb['title']] = (cols, None)
    conn.close()
    return results

def draw_buttons():
    for i, lb in enumerate(leaderboards):
        color = HOVER_COLOR if i == current_lb_index else BOX_COLOR
        pygame.draw.rect(screen, color, button_rects[i], border_radius=8)
        text_surf = FONT.render(lb['title'], True, (0, 0, 0))
        text_rect = text_surf.get_rect(center=button_rects[i].center)
        screen.blit(text_surf, text_rect)

def draw_leaderboard():
    lb = leaderboards[current_lb_index]
    data = fetch_leaderboard_data(lb['table'], lb['columns'])

    # Column widths
    col_widths = []
    total_width = WIDTH - 40  # 20px margin each side
    num_cols = len(lb['columns'])
    base_col_width = total_width // num_cols
    for _ in lb['columns']:
        col_widths.append(base_col_width)

    # Starting positions
    start_x = 20
    header_y = 160
    entry_y = header_y + 40
    entry_height = 30
    row_padding = 10

    # Draw header row
    for i, col_name in enumerate(lb['columns']):
        header_text = col_name.upper()
        header_surf = HEADER_FONT.render(header_text, True, HEADER_TEXT_COLOR)
        header_rect = header_surf.get_rect(midleft=(start_x, header_y))
        screen.blit(header_surf, header_rect)
        start_x += col_widths[i]

    # Draw entries
    for row in data:
        start_x = 20
        # Row background
        row_rect = pygame.Rect(20, entry_y - entry_height // 2, total_width, entry_height)
        pygame.draw.rect(screen, ROW_BG_COLOR, row_rect, border_radius=5)
        pygame.draw.rect(screen, ROW_BORDER_COLOR, row_rect, 2, border_radius=5)

        for i, item in enumerate(row):
            text = str(item)
            text_surf = FONT.render(text, True, ROW_TEXT_COLOR)
            while text_surf.get_width() > col_widths[i] - 10 and len(text) > 3:
                text = text[:-4] + "..."
                text_surf = FONT.render(text, True, ROW_TEXT_COLOR)

            text_rect = text_surf.get_rect(midleft=(start_x + 5, entry_y))
            screen.blit(text_surf, text_rect)
            start_x += col_widths[i]

        entry_y += entry_height + row_padding

def draw_input_box():
    color = INPUT_ACTIVE_COLOR if input_active else INPUT_INACTIVE_COLOR
    pygame.draw.rect(screen, color, input_box, 2, border_radius=5)
    text_surf = FONT.render(input_text, True, TEXT_COLOR)
    screen.blit(text_surf, (input_box.x + 10, input_box.y + 5))

    prompt_surf = SMALL_FONT.render("Search Player ID:", True, TEXT_COLOR)
    screen.blit(prompt_surf, (input_box.x, input_box.y - 22))

def draw_player_search_results():
    if not search_results:
        return

    start_y = 220
    margin_y = 10
    block_width = WIDTH - 40
    block_height = 80

    for i, (game_title, (cols, data)) in enumerate(search_results.items()):
        y = start_y + i * (block_height + margin_y)
        # Draw block background
        rect = pygame.Rect(20, y, block_width, block_height)
        pygame.draw.rect(screen, ROW_BG_COLOR, rect, border_radius=8)
        pygame.draw.rect(screen, ROW_BORDER_COLOR, rect, 2, border_radius=8)

        # Title
        title_surf = FONT.render(game_title, True, TITLE_COLOR)
        screen.blit(title_surf, (rect.x + 10, rect.y + 5))

        if data is None:
            no_data_surf = FONT.render("No data found for this player.", True, ROW_TEXT_COLOR)
            screen.blit(no_data_surf, (rect.x + 10, rect.y + 40))
        else:
            # Draw columns and values in two lines (or one line if space)
            col_text = ", ".join(cols)
            val_text = ", ".join(str(v) for v in data)
            cols_surf = SMALL_FONT.render(col_text, True, ROW_TEXT_COLOR)
            vals_surf = SMALL_FONT.render(val_text, True, ROW_TEXT_COLOR)
            screen.blit(cols_surf, (rect.x + 10, rect.y + 35))
            screen.blit(vals_surf, (rect.x + 10, rect.y + 55))

def main():
    global current_lb_index, input_active, input_text, search_results
    running = True

    while running:
        screen.fill(BG_COLOR)
        draw_buttons()
        draw_input_box()
        draw_leaderboard()
        draw_player_search_results()

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.MOUSEBUTTONDOWN:
                if input_box.collidepoint(event.pos):
                    input_active = True
                else:
                    input_active = False
                for i, rect in enumerate(button_rects):
                    if rect.collidepoint(event.pos):
                        current_lb_index = i
            elif event.type == pygame.KEYDOWN and input_active:
                if event.key == pygame.K_RETURN:
                    # On Enter, fetch search results
                    if input_text.strip():
                        search_results = fetch_player_info(input_text.strip())
                    else:
                        search_results = None
                elif event.key == pygame.K_BACKSPACE:
                    input_text = input_text[:-1]
                else:
                    # Limit input length and allowed characters (alphanumeric and _)
                    if len(input_text) < 20 and (event.unicode.isalnum() or event.unicode == '_'):
                        input_text += event.unicode

        pygame.display.flip()
        clock.tick(30)

    pygame.quit()

if __name__ == "__main__":
    main()
