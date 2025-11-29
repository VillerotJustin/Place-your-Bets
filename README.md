# 🎲 Place Your Bets - Pathfinding Algorithm Showdown

A **Godot 4.5** interactive visualization and betting game that pits two classic pathfinding algorithms against each other: **A*** vs **Dijkstra**!

## 🎮 What is This?

Watch as A* and Dijkstra algorithms race to find the optimal path through randomly generated mazes, then place your bets on which algorithm will perform better! This project combines computer science education with gamification, making algorithm comparison both visual and engaging.

## ✨ Features

### 🏁 Algorithm Racing

- **A* Algorithm**: Heuristic-based pathfinding with intelligent goal-seeking
- **Dijkstra Algorithm**: Guaranteed shortest path with exhaustive exploration
- **Real-time visualization**: Watch both algorithms build and traverse their paths simultaneously

### 🗺️ Dynamic Maze Generation

- **Iterative Randomized Prim's Algorithm** for maze generation
- **Configurable maze size** (width × height)
- **Variable difficulty terrain**:
  - Difficulty 0: Normal passages
  - Difficulty 2: Moderate terrain (slower movement)
  - Difficulty 5: Challenging terrain (much slower movement)

### 💰 Betting System

- Start with **10 coins**
- Place bets on A* or Dijkstra before each race
- **Win conditions**: Algorithm with more points wins
  - 1 point for faster path building
  - 1 point for faster path traversal
- **Payouts**: 2:1 on wins, lose your bet on losses, ties return your bet

### 🎨 Visual Polish

- **Aseprite pixel art** for maze tiles and characters
- **Real-time HUD** showing:
  - Build times for both algorithms
  - Walk times for both algorithms
  - Current scores and money
  - Betting interface

## 🎯 Educational Value

This project demonstrates:

- **Algorithm Performance Comparison**: See how different algorithms perform under various conditions
- **Pathfinding Concepts**: Visualize how A* uses heuristics vs Dijkstra's exhaustive search
- **Terrain Cost Impact**: Understand how movement costs affect pathfinding decisions
- **Time vs Space Complexity**: Observe real-world performance differences

## 🚀 Getting Started

### Prerequisites

- **Godot Engine 4.5** or later
- Git (for cloning)

### Installation

1. **Clone the repository**:

   ```bash
   git clone https://github.com/VillerotJustin/Place-your--Bets.git
   cd Place-your--Bets
   ```

2. **Open in Godot**:
   - Launch Godot Engine
   - Click "Import"
   - Navigate to the project folder
   - Select `project.godot`
   - Click "Import & Edit"

3. **Run the project**:
   - Press `F5` or click the play button
   - Select the main scene if prompted

## 🎮 How to Play

1. **Place Your Bet**:
   - Click the **A***button to bet on A* algorithm
   - Click the **Dijkstra** button to bet on Dijkstra algorithm
   - Each click increases your bet by 1 (up to your available money)

2. **Generate a New Maze**:
   - Press `Space` to generate a new random maze
   - Watch the maze generation process in real-time

3. **Watch the Race**:
   - Both algorithms will automatically start building their paths
   - Green paths show A* exploration, red paths show Dijkstra
   - After building, both algorithms traverse their found paths

4. **See Results**:
   - Points are awarded for faster building and faster traversal
   - Bet results are calculated and money is updated
   - Press `Space` for another round!

## ⚙️ Configuration Options

### Maze Generation

- **Width/Height**: Adjust maze dimensions
- **Generation Algorithm**: Currently supports Prim's algorithm

### Difficulty Paths

- **Add Difficulty Paths**: Enable/disable terrain difficulty
- **Difficulty Pattern**: Choose between "Random Scattered" or "Clustered Areas"
- **Path Percentage**: Control what percentage of paths get higher difficulty (0.1-0.5)
- **Min/Max Difficulty**: Set the range of terrain difficulty (default: 2-5)
- **Low Difficulty Bias**: Control the probability of getting easier terrain (0.7 = 70% easy, 30% hard)

## 🏗️ Project Structure

```text
Place-your--Bets/
├── explorers/
│   ├── a_star/          # A* algorithm implementation
│   └── dijkstra/        # Dijkstra algorithm implementation
├── HUD/
│   ├── hud.gd          # User interface logic
│   └── UX_Manager.gd   # Game state and betting management
├── world/
│   ├── world.gd        # Main game controller
│   ├── labyrinth_generator.gd  # Maze generation logic
│   └── tile/           # Tile graphics and components
└── project.godot       # Godot project configuration
```

## 🔧 Technical Details

### Algorithms Implemented

- **A* Pathfinding**: Uses Manhattan distance heuristic for efficiency
- **Dijkstra's Algorithm**: Guarantees shortest path through exhaustive search
- **Prim's Maze Generation**: Creates perfect mazes with single solutions

### Performance Metrics

- **Build Time**: Milliseconds to construct the optimal path
- **Walk Time**: Milliseconds to traverse the found path (affected by terrain difficulty)
- **Path Quality**: Both algorithms find optimal paths, but A* typically builds faster

### Betting Logic

- Race completion requires both algorithms to finish building AND walking
- Points awarded independently for building speed and walking speed
- Ties return bets, wins pay 2:1, losses subtract the bet amount

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is open source. Feel free to use it for educational purposes, modify it, or contribute improvements!

## 🎓 Learning Resources

Want to learn more about the algorithms featured in this project?

- [A* Search Algorithm - Wikipedia](https://en.wikipedia.org/wiki/A*_search_algorithm)
- [Dijkstra's Algorithm - Wikipedia](https://en.wikipedia.org/wiki/Dijkstra%27s_algorithm)
- [Maze Generation Algorithms](https://en.wikipedia.org/wiki/Maze_generation_algorithm)

---
