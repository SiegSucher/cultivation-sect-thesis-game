# Thesis proposal demo: The First Current

This is one playable programming-learning quest in the Split-Cloud Sect, ready for gameplay review.
- **The route:** the arrival Guide, then the Mentor's syntax lesson, then two typed-code steps (awaken your Qi, then channel it into the basin), then recognition.
- **Scene:** it inherits the Phase 4D sect scene (`phase4d_valley.tscn`) unchanged. Phase 4D is not approved by this work.
- **Report:** [review/REVIEW.md](review/REVIEW.md) covers files, checks, placeholders, limitations and recovery.

## Launch

You can start the demo in either of two ways:
- Double-click **`Launch Proposal Demo.cmd`** in this folder. It uses the workspace's Godot 4.7.2.
- Or open the test project in Godot 4.7.2, select `res://proposal_demo/proposal_demo.tscn` and press **F6**.

The window opens at 1280 × 720 and scales. No standalone `.exe` exists yet; see "Packaging" in the report.

## Controls

| Key | Action |
| --- | --- |
| W A S D, mouse | Move, look |
| Tab | First / third person |
| E | Talk to the Guide or Mentor, or use the basin. Only the nearest relevant prompt is shown. |
| Mouse / Enter / Space | Buttons in dialogue, lessons and the editor |
| Ctrl+Enter | Run the code in the editor (same as the **Run** button) |
| Esc | Close the open panel (code drafts are kept). While exploring, open the demo menu: **Resume, Reset Demo, Exit demo**. |
| M / V | Map / valley overview (inherited) |

**While a panel is open:**
- Movement and camera look are paused, and the mouse is free.
- In the editor, every key types text.
- Closing restores the same first- or third-person view and normal controls.

**Inherited review keys:** 2–8 jump to districts and R returns to the forest start. They work while exploring. R only moves the player; use **Reset Demo** to restart the quest.

**On-screen guidance:** the panel at top right shows:
- the objective;
- an arrow and distance to the current target (Guide → Mentor → basin);
- the **Qi** indicator;
- the language, step and recognition status.

A small gold marker floats above the same target.

## Presenter walkthrough (Python, about 3½–5 minutes with narration)

The automated rehearsal of exactly this route took **3 min 14 s** from the spawn to completion, typing at about 7 characters per second. Allow extra time for slower typing and talking.

1. **Arrival** (third person, forest path). A gold marker sits over the **Guide** beside the path. Walk up until **[E] Talk to the Guide** appears.
2. **Guide, about 25 s.** Press E and read the four short pages with **Next**: you are a new apprentice; the sect directs Qi through programming inscriptions; training begins by awakening your own Qi; the Mentor supervises the first exercise. **Skip** also works, and you can talk to the Guide again later.
3. **Walk to the Mentor, about 30 s.** The objective and arrow now point to the **Mentor**. Go through the open Sect Gate and up the second stair; the Mentor stands beside the dry basin.
4. **Accept.** Press E, then **Next**, then **Accept the task**. To show the decline path, choose **Not yet** and talk again.
5. **Choose Python.** The Mentor's lesson opens: five short cards. Each shows either an **EXAMPLE** (a short program that runs but does not solve the exercise) or a **REFERENCE** (a command signature whose `amount` is a placeholder). They cover:
   - a variable stores a value;
   - assignment gives it its first value before use;
   - a function call performs an action;
   - statements run top to bottom;
   - `awaken(amount)` is **the game's** command, not Python's. It is shown as a labelled reference signature, not as a program to copy.

   **Write the inscription** opens the editor.
6. **Step 1, awaken.**
   - **Point out the screen:** the fixed `from sect import *` line, the editor, the Lesson / Commands / Hints tabs, and the Output console. The console's first line, `[sect runner] running awakening.py · learning interpreter, Python subset`, says what runs the code (see "Explaining the code runner" below).
   - **Hints tab, if asked:** a first hint in words, then a stronger hint with blanks, then an optional **Show worked solution**. It only displays the answer: nothing is typed, run or changed, and the student still types and runs it. The reveal is kept for that step until Reset Demo.
   - **Show a mistake:** type the lines in the wrong order, `awaken(qi)` then `qi = 3`, and press **Run** (or Ctrl+Enter). The console shows a `NameError` in Python's style, and the Mentor's note explains that statements run in order.
   - **Fix it:** `qi = 3` then `awaken(qi)`, and Run. The result is `[sect] Qi awakened. Reserve: 3`.
   - **Feel your Qi awaken:** a ring and motes appear around the apprentice, and the Qi bar fills to 3/3.
7. **The Mentor introduces step 2.** **Show me** opens two cards: calls can return a value (a runnable example that prints your reserve), and the `channel_basin(amount)` reference signature; the basin needs 3. **Go to the basin.**
8. **Step 2, at the basin.** Walk a few steps to the basin; the marker is now on it. Press E at **[E] Channel Qi into the basin**.
   - **Show a mistake:** `reserve = qi_reserve()` then `channel_basin(5)`. The run fails with **not enough Qi**, and the basin stays dry.
   - **Fix it:** `channel_basin(reserve)`, then Run, then **Channel into the basin**.
   - **The result:** a Qi orb flies into the basin, the water rises and the spout flows. **Quest complete** recognition appears once. The Mentor says your spent reserve is being replenished, and the Qi bar refills to 3.
9. **Continue exploring**, then **Esc → Reset Demo** to restart cleanly. Repeat with **C** or **Java** if the panel asks; the C and Java structure (`#include`, `main`, the class) is already written.

**If anything goes wrong mid-demo:** use **Esc, then Reset Demo**. Nothing is saved between runs.

## Explaining the code runner (for the panel)

**In one breath:** "The code is run by the game's own *learning interpreter*. I wrote it for this lesson. It reads a small subset of Python, C and Java (variables, assignment, function calls, whole numbers, text and simple arithmetic) and runs the statements in order against the game's Qi rules. It is not real Python, gcc or javac, so its messages are modelled on theirs but are approximate."

**If asked, show or say:**
- **It really runs the code.** In step 1, `qi = 1 + 2` works too. `qi = 2 + 2` is refused with a message that names the 4 it received.
- **The console separates four kinds of feedback:**

  | Colour | Kind | Example |
  | --- | --- | --- |
  | Red | Language error, as the real language would report it | `NameError`, `expected ';'`, `might not have been initialized` |
  | Red | Game rule, raised by a Qi command while running | `not enough Qi` |
  | Amber | **"Valid Python, but…"**: correct code that misses the exercise's requirement | `awaken(3)`, which skips storing the Qi in a variable |
  | Amber | **"Not supported by this learning interpreter"**: real syntax outside the subset, never called an error | `if`, loops, `/`, lists, `len()` |

- **Why not the real compilers?** The demo must run offline on any machine with nothing installed, and its feedback has to be in beginner language and tied to the game world. A restricted interpreter keeps every program safe and instant.
- **Why is there no Stop button?** The subset has no loops or function definitions, so every program finishes at once. Size limits reject anything larger with a readable message: 2,000 characters, 400 tokens, 40 statements, 12 levels of nesting and 30 output lines. The slowest test program took about 2 ms.
- **What is not claimed:** full Python, C or Java compatibility. The **Commands** tab lists what the interpreter supports and what it does not.
