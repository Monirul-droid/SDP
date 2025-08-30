import pygame
import sys
import random
import math
import subprocess  # Added to launch external game files

pygame.init()

WIDTH, HEIGHT = 800, 600
screen = pygame.display.set_mode((WIDTH, HEIGHT), pygame.RESIZABLE)
pygame.display.set_caption("Game Hive Selection")

# Cyberpunk color scheme
BG_COLOR = (15, 15, 26)  # Dark futuristic background
BOX_COLOR = (20, 20, 40)  # Dim button color
HOVER_COLOR = (255, 20, 147)  # Neon pink for hover
CIRCLE_COLORS = [
    (0, 255, 255),  # Neon cyan
    (255, 0, 255),  # Magenta
    (0, 255, 128),  # Bright green
    (255, 255, 0),  # Yellow
    (0, 128, 255)  # Electric blue
]

# Neon-style base text colors
BASE_TEXT_COLORS = [
    (0, 255, 255),  # Tic Tac Toe - Neon Cyan
    (255, 0, 255),  # Hangman - Neon Magenta
    (0, 255, 128),  # Trapper - Neon Green
    (255, 255, 0),  # Maze - Neon Yellow
    (0, 128, 255),  # Brick Buster - Electric Blue
    (255, 105, 180), # Leaderboard - Hot Pink (or any neon color you want)
    (255, 0, 255)  # Statisctics - Neon Magenta
]



def pulse_color(base_color, t):
    factor = (math.sin(t) + 1) / 2
    return tuple(min(255, int(c + (255 - c) * factor)) for c in base_color)


class Button:
    def __init__(self, text, x, y, width, height, color, hover_color, base_text_color):
        self.text = text
        self.rect = pygame.Rect(x, y, width, height)
        self.color = color
        self.hover_color = hover_color
        self.base_text_color = base_text_color

    def draw(self, screen, time_value):
        mouse_pos = pygame.mouse.get_pos()
        current_color = self.hover_color if self.rect.collidepoint(mouse_pos) else self.color
        pygame.draw.rect(screen, current_color, self.rect, border_radius=8)

        font = pygame.font.SysFont("Consolas", 30, bold=True)
        pulsing_color = pulse_color(self.base_text_color, time_value / 500.0)
        text_surface = font.render(self.text, True, pulsing_color)
        text_rect = text_surface.get_rect(center=self.rect.center)
        screen.blit(text_surface, text_rect)

    def is_pressed(self):
        return self.rect.collidepoint(pygame.mouse.get_pos()) and pygame.mouse.get_pressed()[0]


class MovingCircle:
    def __init__(self, x, y, radius, color, dx, dy):
        self.x = x
        self.y = y
        self.radius = radius
        self.color = color
        self.dx = dx
        self.dy = dy

    def update(self, width, height):
        self.x += self.dx
        self.y += self.dy

        if self.x - self.radius <= 0 or self.x + self.radius >= width:
            self.dx *= -1
        if self.y - self.radius <= 0 or self.y + self.radius >= height:
            self.dy *= -1

    def draw(self, surface):
        pygame.draw.circle(surface, self.color, (int(self.x), int(self.y)), self.radius)


circles = [
    MovingCircle(random.randint(0, WIDTH), random.randint(0, HEIGHT),
                 random.randint(10, 25),
                 random.choice(CIRCLE_COLORS),
                 random.choice([-1, 1]) * random.uniform(0.5, 1.5),
                 random.choice([-1, 1]) * random.uniform(0.5, 1.5))
    for _ in range(20)
]


def show_menu():
    global screen, WIDTH, HEIGHT

    running = True
    clock = pygame.time.Clock()
    clicked = False  # Flag to handle single click

    while running:
        time_value = pygame.time.get_ticks()
        screen.fill(BG_COLOR)

        # Draw the title "Game Hive" at the top
        title_font = pygame.font.SysFont("Consolas", 100, bold=True)
        title_surface = title_font.render("Game Hive", True, (255, 20, 147))  # Hot pink neon color
        title_rect = title_surface.get_rect(center=(WIDTH // 2, 50))
        screen.blit(title_surface, title_rect)

        for circle in circles:
            circle.update(WIDTH, HEIGHT)
            circle.draw(screen)

        button_width, button_height = 300, 80
        spacing = 100
        start_y = 100
        game_names = ["Tic Tac Toe", "Hangman", "Trapper", "Maze", "Brick Buster", "Leaderboard", "Statistics"]

        buttons = [
            Button(name, (WIDTH - button_width) // 2, start_y + i * spacing, button_width, button_height,
                   BOX_COLOR, HOVER_COLOR, BASE_TEXT_COLORS[i])
            for i, name in enumerate(game_names)
        ]

        for button in buttons:
            button.draw(screen, time_value)

        pygame.display.update()
        clock.tick(60)

        for event in pygame.event.get():
            if event.type == pygame.QUIT:
                running = False
            elif event.type == pygame.VIDEORESIZE:
                WIDTH, HEIGHT = event.w, event.h
                screen = pygame.display.set_mode((WIDTH, HEIGHT), pygame.RESIZABLE)

        # Handle click only once
        if pygame.mouse.get_pressed()[0]:
            if not clicked:
                clicked = True
                for button in buttons:
                    if button.is_pressed():
                        print(f"{button.text} selected")
                        match button.text:
                            case "Tic Tac Toe":
                                subprocess.Popen(["python", "tic_tac_toe10.py"])
                            case "Hangman":
                                subprocess.Popen(["python", "hangman10.py"])
                            case "Trapper":
                                subprocess.Popen(["python", "Trapper10.py"])
                            case "Maze":
                                subprocess.Popen(["python", "Maze10.py"])
                            case "Brick Buster":
                                subprocess.Popen(["python", "brickbuster10.py"])
                            case "Leaderboard":
                                subprocess.Popen(["python", "Leaderboard.py"])
                            case "Statistics":
                                subprocess.Popen(["python", "Statistics.py"])
        else:
            clicked = False

    pygame.quit()
    sys.exit()



show_menu()
