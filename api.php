<?php
require __DIR__ . '/config.php';
session_set_cookie_params(['httponly' => true, 'samesite' => 'Strict']);
session_start();
header('Content-Type: application/json; charset=utf-8');
header('X-Content-Type-Options: nosniff');
header('Cache-Control: no-store');

function out($d, $c = 200) { http_response_code($c); echo json_encode($d, JSON_UNESCAPED_UNICODE); exit; }
function fail($m, $c = 400) { out(['error' => $m], $c); }
function need_admin() { if (empty($_SESSION['admin'])) fail('Please log in with the admin passkey.', 401); }
function s($v, $max) { $v = trim((string)$v); return function_exists('mb_substr') ? mb_substr($v, 0, $max) : substr($v, 0, $max); }
// function nu_id($v) { $v = strtoupper(trim((string)$v)); return preg_match('/^\d{2}K-\d{4}$/', $v) ? $v : null; }
  function nu_id($v) { $v = strtoupper(trim((string)$v)); return preg_match('/^\d{2}[KLIMFP]-\d{4}$/', $v) ? $v : null; }
function slen($v) { return function_exists('mb_strlen') ? mb_strlen($v) : strlen($v); }

try {
  $db = new PDO('mysql:host=' . DB_HOST . ';dbname=' . DB_NAME . ';charset=utf8mb4', DB_USER, DB_PASS,
    [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION, PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC]);
} catch (Exception $e) { fail('Cannot connect to MySQL. Start MySQL in XAMPP and import schema.sql.', 500); }

$a = $_GET['a'] ?? '';
$in = json_decode(file_get_contents('php://input'), true) ?: [];
$CATS = ['Cpp', 'CS', 'Logic', 'FAST'];
$QCOLS = 'category,text,code,correct,w1,w2,w3,explanation';

function clean_question($in, $CATS) {
  $q = ['category' => s($in['category'] ?? '', 10), 'text' => s($in['text'] ?? '', 500), 'code' => s($in['code'] ?? '', 2000),
        'correct' => s($in['correct'] ?? '', 200), 'w1' => s($in['w1'] ?? '', 200), 'w2' => s($in['w2'] ?? '', 200),
        'w3' => s($in['w3'] ?? '', 200), 'explanation' => s($in['explanation'] ?? '', 500)];
  if (!in_array($q['category'], $CATS, true)) fail('Pick a valid category.');
  foreach (['text' => 'question', 'correct' => 'correct answer', 'w1' => 'wrong option 1', 'w2' => 'wrong option 2', 'w3' => 'wrong option 3'] as $k => $n)
    if ($q[$k] === '') fail("The $n is required.");
  if (count(array_unique([$q['correct'], $q['w1'], $q['w2'], $q['w3']])) < 4) fail('All four options must be different.');
  if ($q['code'] === '') $q['code'] = null;
  return $q;
}

try {
  // First run: create the admin passkey hash
  if ($db->query("SELECT COUNT(*) c FROM settings WHERE k='admin_key'")->fetch()['c'] == 0)
    $db->prepare("INSERT INTO settings(k,v) VALUES('admin_key',?)")->execute([password_hash(DEFAULT_PASSKEY, PASSWORD_DEFAULT)]);

  // One-time migration: NU ID column (one attempt per ID). Names may now repeat, so a UNIQUE index on `name` alone is dropped.
  if (!$db->query("SHOW COLUMNS FROM players LIKE 'nu_id'")->fetch()) {
    $db->exec("ALTER TABLE players ADD COLUMN nu_id VARCHAR(10) NULL DEFAULT NULL AFTER name");
    $db->exec("ALTER TABLE players ADD UNIQUE KEY uq_players_nu_id (nu_id)");
    foreach ($db->query("SHOW INDEX FROM players WHERE Non_unique = 0 AND Column_name = 'name'")->fetchAll() as $ix) {
      if ($ix['Key_name'] === 'PRIMARY') continue;
      if (count($db->query('SHOW INDEX FROM players WHERE Key_name = ' . $db->quote($ix['Key_name']))->fetchAll()) === 1)
        $db->exec('ALTER TABLE players DROP INDEX `' . str_replace('`', '', $ix['Key_name']) . '`');
    }
  }

  switch ($a) {
    case 'questions':
      out(['questions' => $db->query("SELECT $QCOLS FROM questions")->fetchAll()]);
    case 'me': out(['admin' => !empty($_SESSION['admin'])]);
    case 'login':
      $hash = $db->query("SELECT v FROM settings WHERE k='admin_key'")->fetch()['v'];
      if (!password_verify((string)($in['key'] ?? ''), $hash)) { sleep(1); fail('Wrong passkey.', 401); }
      session_regenerate_id(true); $_SESSION['admin'] = true; out(['ok' => true]);
    case 'logout': $_SESSION = []; session_destroy(); out(['ok' => true]);
    case 'leaderboard':
      // Hall of Fame: WINNERS ONLY. Each player's best winning run, ranked by score (higher first), then fewest turns. Top 10.
      $rows = $db->query('SELECT p.id pid, p.name, gp.score, g.turns
        FROM game_players gp
        JOIN games g ON g.id = gp.game_id
        JOIN players p ON p.id = gp.player_id
        JOIN (SELECT player_id, MAX(score) ms FROM game_players WHERE won = 1 GROUP BY player_id) b ON b.player_id = gp.player_id AND b.ms = gp.score
        WHERE gp.won = 1
        ORDER BY gp.score DESC, g.turns ASC, g.id ASC LIMIT 100')->fetchAll();
      $seen = []; $top = [];
      foreach ($rows as $r) {
        if (isset($seen[$r['pid']])) continue;
        $seen[$r['pid']] = 1; $top[] = ['name' => $r['name'], 'score' => (int)$r['score'], 'turns' => (int)$r['turns']];
        if (count($top) >= 10) break;
      }
      out(['players' => $top]);
    case 'players':
      out(['players' => $db->query('SELECT id,name,nu_id,games,wins,best_score,total_score,correct,wrong FROM players ORDER BY name')->fetchAll()]);
    case 'nu_start':
      // Reserve the NU ID before the game begins, so quitting or refreshing can't be used to play twice.
      $name = s($in['name'] ?? '', 14); if ($name === '') $name = 'Wizard';
      $nu = nu_id($in['nu_id'] ?? ''); if (!$nu) fail('Enter a valid NU ID like 26K-3058.');
      $chk = $db->prepare('SELECT 1 FROM players WHERE nu_id=?'); $chk->execute([$nu]);
      if ($chk->fetch()) fail('This NU ID has already played. One attempt per ID.', 409);
      try {
        $db->prepare('INSERT INTO players(name,nu_id,games,wins,best_score,total_score,correct,wrong) VALUES(?,?,0,0,0,0,0,0)')->execute([$name, $nu]);
      } catch (PDOException $e) {
        if ($e->getCode() === '23000' && stripos($e->getMessage(), 'nu_id') !== false) fail('This NU ID has already played. One attempt per ID.', 409);
        throw $e;
      }
      out(['ok' => true]);
    case 'game_end':
      $mode = ($in['mode'] ?? '') === 'solo' ? 'solo' : 'multi';
      $ps = $in['players'] ?? [];
      if (!is_array($ps) || count($ps) < 1 || count($ps) > 4) fail('Invalid players.');
      $rows = [];
      foreach ($ps as $p) {
        $nu = nu_id($p['nu_id'] ?? ''); if (!$nu) fail('Missing or invalid NU ID.');
        $f = $db->prepare('SELECT id,games FROM players WHERE nu_id=?'); $f->execute([$nu]); $pl = $f->fetch();
        if (!$pl) fail('Unknown NU ID.', 404);
        if ((int)$pl['games'] > 0) fail('This NU ID has already played. One attempt per ID.', 409);
        $rows[] = [$pl['id'], max(0, (int)($p['score'] ?? 0)), max(0, (int)($p['ok'] ?? 0)), max(0, (int)($p['bad'] ?? 0)), !empty($p['won']) ? 1 : 0];
      }
      $db->beginTransaction();
      $db->prepare('INSERT INTO games(mode,turns) VALUES(?,?)')->execute([$mode, max(0, (int)($in['turns'] ?? 0))]);
      $gid = $db->lastInsertId(); $winner = null;
      $up = $db->prepare('UPDATE players SET games=1,wins=?,best_score=?,total_score=?,correct=?,wrong=? WHERE id=?');
      $gp = $db->prepare('INSERT INTO game_players(game_id,player_id,score,ok,bad,won) VALUES(?,?,?,?,?,?)');
      foreach ($rows as [$pid, $sc, $ok, $bad, $won]) {
        $up->execute([$won, $sc, $sc, $ok, $bad, $pid]);
        $gp->execute([$gid, $pid, $sc, $ok, $bad, $won]);
        if ($won) $winner = $pid;
      }
      if ($winner) $db->prepare('UPDATE games SET winner_id=? WHERE id=?')->execute([$winner, $gid]);
      $db->commit(); out(['ok' => true]);
    // ---- admin only ----
    case 'q_list': need_admin(); out(['questions' => $db->query("SELECT id,$QCOLS FROM questions ORDER BY id")->fetchAll()]);
    case 'q_add':
      need_admin(); $q = clean_question($in, $CATS);
      $db->prepare("INSERT INTO questions($QCOLS) VALUES(:category,:text,:code,:correct,:w1,:w2,:w3,:explanation)")->execute($q);
      out(['ok' => true, 'id' => $db->lastInsertId()]);
    case 'q_update':
      need_admin(); $q = clean_question($in, $CATS); $q['id'] = (int)($in['id'] ?? 0);
      $db->prepare('UPDATE questions SET category=:category,text=:text,code=:code,correct=:correct,w1=:w1,w2=:w2,w3=:w3,explanation=:explanation WHERE id=:id')->execute($q);
      out(['ok' => true]);
    case 'q_delete':
      need_admin(); $db->prepare('DELETE FROM questions WHERE id=?')->execute([(int)($in['id'] ?? 0)]); out(['ok' => true]);
    case 'player_delete':
      need_admin(); $db->prepare('DELETE FROM players WHERE id=?')->execute([(int)($in['id'] ?? 0)]); out(['ok' => true]);
    case 'set_key':
      need_admin(); $k = (string)($in['key'] ?? '');
      if (slen($k) < 6) fail('Passkey must be at least 6 characters.');
      $db->prepare("UPDATE settings SET v=? WHERE k='admin_key'")->execute([password_hash($k, PASSWORD_DEFAULT)]); out(['ok' => true]);
    default: fail('Unknown action.', 404);
  }
} catch (PDOException $e) {
  if ($db->inTransaction()) $db->rollBack();
  fail('Database error. Did you import schema.sql?', 500);
}
