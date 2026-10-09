# The Vanishing at Blackthorn Manor

A mystery adventure, hidden-object, and puzzle game for Godot 4.7.2.

## Play

Open this folder in Godot 4.7.2 and run the project. The game starts at the manor's
case-notes screen; choose **Enter the Manor** to begin exploring.

## The case

Explore 100 connected rooms across ten wings. Each room is generated from a
reusable scene and has its own location, passages, and investigation. Search for
objects from their clues, answer household riddles, and navigate the manor's
labyrinth of corridors. Find the three journal seals to unlock the final archive
and solve the mystery.

Choose a passage button to travel between rooms. There are no timed challenges;
incorrect object choices and riddle answers can be tried again. The room counter
tracks discoveries, and completed investigations remain recorded while the game
is open.

## Project layout

- `project.godot` — Godot project settings and launch scene.
- `scenes/main.tscn` — reusable game entry scene.
- `scripts/main.gd` — manor generation, room content, navigation, and interface.

The manor and its passages are generated deterministically, so each playthrough
uses the same connected maze.
