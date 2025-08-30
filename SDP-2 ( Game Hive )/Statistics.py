import pygame
import mysql.connector

pygame.init()
WIDTH, HEIGHT = 800, 600
screen = pygame.display.set_mode((WIDTH, HEIGHT))
pygame.display.set_caption("Game Hive Statistics")

BLACK = (0, 0, 0)
WHITE = (255, 255, 255)
RED = (255, 0, 0)
GREEN = (0, 255, 0)
BLUE = (0, 0, 255)

# Cyberpunk color scheme
BG_COLOR = (15, 15, 26)
BOX_COLOR = (20, 20, 40)
HOVER_COLOR = (255, 20, 147)
CIRCLE_COLORS = [
    (0, 255, 255),
    (255, 0, 255),
    (0, 255, 128),
    (255, 255, 0),
    (0, 128, 255)
]
BASE_TEXT_COLORS = [
    (0, 255, 255),  # Tic Tac Toe
    (255, 0, 255),  # Hangman
    (0, 255, 128),  # Trapper
    (255, 255, 0),  # Maze
    (0, 128, 255),  # Brick Buster
    (255, 105, 180),# Leaderboard
    (255, 0, 255)   # Statistics
]

# Fonts
FONT = pygame.font.SysFont("Consolas", 20)
HEADER_FONT = pygame.font.SysFont("Arial", 28, bold=True)
SECTION_TITLE_FONT = pygame.font.SysFont("Arial", 25, bold=True)
LABEL_FONT = pygame.font.SysFont("Arial", 20)
VALUE_FONT = pygame.font.SysFont("Consolas", 20)

# Layout constants
BOX_PADDING = 20
BOX_MARGIN = 25
LINE_SPACING = 30
LABEL_X_OFFSET = 30
VALUE_X_OFFSET = 400

# Connect to database
conn = mysql.connector.connect(
    host='localhost',
    user='root',
    password='',
    database='db_game'
)
cursor = conn.cursor()

def fetchone_dict(query):
    cursor.execute(query)
    row = cursor.fetchone()
    if row:
        cols = [desc[0] for desc in cursor.description]
        return dict(zip(cols, row))
    return None

def fetchall_dict(query):
    cursor.execute(query)
    rows = cursor.fetchall()
    cols = [desc[0] for desc in cursor.description]
    return [dict(zip(cols, row)) for row in rows]

def get_stats():
    stats = {}

    # Brickbuster stats
    total_players = fetchone_dict("SELECT COUNT(DISTINCT player_id) AS cnt FROM brickbuster_leaderboard")['cnt']
    avg_score = fetchone_dict("SELECT AVG(total_score) AS avg_score FROM brickbuster_leaderboard")['avg_score']
    most_levels = fetchone_dict(
        "SELECT p.player_name, b.highest_level FROM brickbuster_leaderboard b JOIN players p ON b.player_id = p.player_uid ORDER BY b.highest_level DESC LIMIT 1")
    difficulty_counts = fetchall_dict("SELECT difficulty, COUNT(*) AS count FROM brickbuster_leaderboard GROUP BY difficulty")
    stats['Brickbuster'] = {
        "Total Players": total_players,
        "Average Score": f"{avg_score:.2f}" if avg_score else "N/A",
        "Top Player by Highest Level": f"{most_levels['player_name']} (Level {most_levels['highest_level']})" if most_levels else "N/A",
        "Players per Difficulty": {d['difficulty']: d['count'] for d in difficulty_counts}
    }

    # Hangman stats
    total_players = fetchone_dict("SELECT COUNT(DISTINCT player_id) AS cnt FROM hangman_leaderboard")['cnt']
    avg_score = fetchone_dict("SELECT AVG(score) AS avg_score FROM hangman_leaderboard")['avg_score']
    top_player = fetchone_dict(
        "SELECT p.player_name, h.score FROM hangman_leaderboard h JOIN players p ON h.player_id = p.player_uid ORDER BY h.score DESC LIMIT 1")
    stats['Hangman'] = {
        "Total Players": total_players,
        "Average Score": f"{avg_score:.2f}" if avg_score else "N/A",
        "Top Player": f"{top_player['player_name']} (Score {top_player['score']})" if top_player else "N/A"
    }

    # Maze stats
    total_players = fetchone_dict("SELECT COUNT(DISTINCT player_id) AS cnt FROM maze_leaderboard")['cnt']
    avg_points = fetchone_dict("SELECT AVG(points) AS avg_points FROM maze_leaderboard")['avg_points']
    top_player = fetchone_dict(
        "SELECT p.player_name, m.points FROM maze_leaderboard m JOIN players p ON m.player_id = p.player_uid ORDER BY m.points DESC LIMIT 1")
    stats['Maze'] = {
        "Total Players": total_players,
        "Average Points": f"{avg_points:.2f}" if avg_points else "N/A",
        "Top Player": f"{top_player['player_name']} (Points {top_player['points']})" if top_player else "N/A"
    }

    # Tic Tac Toe stats
    total_players = fetchone_dict("SELECT COUNT(DISTINCT player_id) AS cnt FROM tictactoe_leaderboard")['cnt']
    top_wins = fetchone_dict(
        "SELECT p.player_name, t.wins FROM tictactoe_leaderboard t JOIN players p ON t.player_id = p.player_uid ORDER BY t.wins DESC LIMIT 1")
    total_games = fetchone_dict("SELECT SUM(wins + losses + ties) AS total_games FROM tictactoe_leaderboard")['total_games']
    stats['Tic Tac Toe'] = {
        "Total Players": total_players,
        "Total Games Played": total_games if total_games else 0,
        "Top Player by Wins": f"{top_wins['player_name']} (Wins {top_wins['wins']})" if top_wins else "N/A"
    }

    # Trapper stats
    total_players = fetchone_dict("SELECT COUNT(DISTINCT player_id) AS cnt FROM trapper_leaderboard")['cnt']
    avg_time = fetchone_dict("SELECT AVG(time_survived) AS avg_time FROM trapper_leaderboard")['avg_time']
    top_time = fetchone_dict(
        "SELECT p.player_name, t.time_survived FROM trapper_leaderboard t JOIN players p ON t.player_id = p.player_uid ORDER BY t.time_survived DESC LIMIT 1")
    stats['Trapper'] = {
        "Total Players": total_players,
        "Average Time Survived": f"{avg_time:.2f} seconds" if avg_time else "N/A",
        "Top Player by Survival Time": f"{top_time['player_name']} ({top_time['time_survived']} seconds)" if top_time else "N/A"
    }

    return stats

def draw_text(surface, text, font, color, x, y):
    rendered = font.render(text, True, color)
    surface.blit(rendered, (x, y))

def draw_separator(surface, x, y, width, color):
    pygame.draw.line(surface, color, (x, y), (x + width, y), 1)

def draw_boxed_section(surface, title, content_dict, x, y, width, title_color):
    lines_count = 1
    for key, val in content_dict.items():
        if isinstance(val, dict):
            lines_count += 1 + len(val)
        else:
            lines_count += 1
    height = lines_count * LINE_SPACING + 2 * BOX_PADDING + 40

    pygame.draw.rect(surface, BOX_COLOR, (x, y, width, height), border_radius=10)
    pygame.draw.rect(surface, HOVER_COLOR, (x, y, width, height), 2, border_radius=10)

    title_bar_height = 40
    pygame.draw.rect(surface, (30, 30, 60), (x, y, width, title_bar_height), border_top_left_radius=10, border_top_right_radius=10)
    draw_text(surface, title, SECTION_TITLE_FONT, title_color, x + BOX_PADDING, y + 7)

    current_y = y + title_bar_height + 10
    for key, val in content_dict.items():
        if key != list(content_dict.keys())[0]:
            draw_separator(surface, x + BOX_PADDING, current_y - 8, width - 2 * BOX_PADDING, (40, 40, 60))

        if isinstance(val, dict):
            draw_text(surface, f"{key}:", LABEL_FONT, WHITE, x + LABEL_X_OFFSET, current_y)
            current_y += LINE_SPACING
            for subkey, subval in val.items():
                draw_text(surface, f"- {subkey}:", FONT, WHITE, x + LABEL_X_OFFSET + 20, current_y)
                draw_text(surface, str(subval), VALUE_FONT, WHITE, x + VALUE_X_OFFSET, current_y)
                current_y += LINE_SPACING
        else:
            draw_text(surface, f"{key}:", LABEL_FONT, WHITE, x + LABEL_X_OFFSET, current_y)
            draw_text(surface, str(val), VALUE_FONT, WHITE, x + VALUE_X_OFFSET, current_y)
            current_y += LINE_SPACING

def main():
    clock = pygame.time.Clock()
    running = True

    stats = get_stats()
    offset_y = 0
    scroll_speed = 25

    box_width = WIDTH - 2 * BOX_MARGIN
    box_heights = []
    total_height = 0
    for title, content in stats.items():
        lines_count = 1
        for key, val in content.items():
            if isinstance(val, dict):
                lines_count += 1 + len(val)
            else:
                lines_count += 1
        height = lines_count * LINE_SPACING + 2 * BOX_PADDING + 40
        box_heights.append(height)
        total_height += height + BOX_MARGIN

    max_scroll = max(0, total_height - HEIGHT + BOX_MARGIN + 60)

    while running:
        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.KEYDOWN:
                if event.key == pygame.K_UP:
                    offset_y = min(offset_y + scroll_speed, 0)
                elif event.key == pygame.K_DOWN:
                    offset_y = max(offset_y - scroll_speed, -max_scroll)
            elif event.type == pygame.MOUSEWHEEL:
                offset_y += event.y * scroll_speed
                if offset_y > 0:
                    offset_y = 0
                elif offset_y < -max_scroll:
                    offset_y = -max_scroll

        screen.fill(BG_COLOR)

        pygame.draw.rect(screen, (30, 30, 60), (0, 0, WIDTH, 60))
        draw_text(screen, "Game Hive Statistics", HEADER_FONT, (255, 20, 147), 20, 10)

        current_y = BOX_MARGIN + offset_y + 60
        for i, (title, content) in enumerate(stats.items()):
            color_index = i % len(BASE_TEXT_COLORS)
            title_color = BASE_TEXT_COLORS[color_index]
            draw_boxed_section(screen, title, content, BOX_MARGIN, current_y, box_width, title_color)
            current_y += box_heights[i] + BOX_MARGIN

        pygame.display.flip()
        clock.tick(60)

    cursor.close()
    conn.close()
    pygame.quit()

if __name__ == "__main__":
    main()
