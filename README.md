# TechLudo – Hogwarts Code Quest (XAMPP + MySQL edition)

Solo quest: roll the dice, answer a code question in **15 seconds**, reach tile 36 (the Great Hall) with an exact roll.

## Setup (5 minutes)
1. Open XAMPP Control Panel and **start Apache and MySQL**.
2. Copy this `techludo` folder to `C:\xampp\htdocs\` (so you have `C:\xampp\htdocs\techludo\index.html`). Replace the old files.
3. Open **http://localhost/phpmyadmin** → **Import** → choose `schema.sql` → **Go**.
   ⚠️ This **recreates** the `techludo` database: the old questions, players and scores are deleted. Import it once.
4. Open **http://localhost/techludo/** and play.

Opening `index.html` by double-click still works (built-in questions, scores saved in the browser), but the database needs Apache.

## Rules
- 3 lives (♥). A **wrong answer or a timeout** sends you back to where the turn started and costs one life. Lose all 3 and the game ends.
- Correct: +10 points (+15 for questions with code). Three in a row: +10 bonus.
- Roll a 6 and answer correctly to roll again. One 50:50 charm per game.
- Closing or refreshing the page while a question is open counts as a timeout.

## Hall of Fame
Shows each player's best run: **score** and **turns** (higher score first, fewer turns wins ties).

## Question topics
HTML · C Output · Python · CS & Web · **C Fill-in · Basics** · **C Fill-in · Pointers** (60 questions; every fill-in-the-blank answer was compiled and tested).
Fill-in-the-blank questions show the code with `____`; add your own from Home → Question bank (admin).

## Admin passkey
Default **admin123**. Change it: Home → Question bank → Change passkey. Forgot it? In phpMyAdmin run `DELETE FROM settings WHERE k='admin_key';` – it resets to `admin123`.

## Troubleshooting
- "Database offline": Apache/MySQL not started, or the folder isn't in `htdocs`.
- "Cannot connect to MySQL": you set a MySQL root password → put it in `config.php` (`DB_PASS`).
- "Database error. Did you import schema.sql?": do step 3.
