-- TechLudo (Hogwarts edition) database. Import in phpMyAdmin (Import tab) or run: mysql -u root < schema.sql
-- NOTE: this file starts fresh. It DROPS the old `techludo` database (old questions, players and scores) and recreates it.
SET NAMES utf8mb4;
DROP DATABASE IF EXISTS techludo;
CREATE DATABASE techludo CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE techludo;
CREATE TABLE settings(k VARCHAR(40) PRIMARY KEY, v VARCHAR(255) NOT NULL) ENGINE=InnoDB;
CREATE TABLE players(
  id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(14) NOT NULL UNIQUE,
  games INT NOT NULL DEFAULT 0, wins INT NOT NULL DEFAULT 0, best_score INT NOT NULL DEFAULT 0,
  total_score INT NOT NULL DEFAULT 0, correct INT NOT NULL DEFAULT 0, wrong INT NOT NULL DEFAULT 0,
  created TIMESTAMP DEFAULT CURRENT_TIMESTAMP) ENGINE=InnoDB;
-- Categories (tile colours): Cpp = green (C++ output prediction), CS = red (General CS / Data Structures / AI / Cybersecurity),
--   Logic = white (challenging code logic / missing line), FAST = blue (FAST-NUCES Karachi trivia)
CREATE TABLE questions(
  id INT AUTO_INCREMENT PRIMARY KEY, category ENUM('Cpp','CS','Logic','FAST') NOT NULL,
  text VARCHAR(500) NOT NULL, code TEXT NULL, correct VARCHAR(200) NOT NULL,
  w1 VARCHAR(200) NOT NULL, w2 VARCHAR(200) NOT NULL, w3 VARCHAR(200) NOT NULL, explanation VARCHAR(500) NOT NULL DEFAULT '') ENGINE=InnoDB;
CREATE TABLE games(
  id INT AUTO_INCREMENT PRIMARY KEY, mode ENUM('multi','solo') NOT NULL DEFAULT 'solo', turns INT NOT NULL DEFAULT 0,
  winner_id INT NULL, played TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY(winner_id) REFERENCES players(id) ON DELETE SET NULL) ENGINE=InnoDB;
CREATE TABLE game_players(
  game_id INT NOT NULL, player_id INT NOT NULL, score INT NOT NULL, ok INT NOT NULL, bad INT NOT NULL, won TINYINT NOT NULL,
  PRIMARY KEY(game_id,player_id),
  FOREIGN KEY(game_id) REFERENCES games(id) ON DELETE CASCADE,
  FOREIGN KEY(player_id) REFERENCES players(id) ON DELETE CASCADE) ENGINE=InnoDB;
-- Starter question bank
INSERT INTO questions(category,text,code,correct,w1,w2,w3,explanation) VALUES
('Cpp','What is the output?','int a = 10;\ncout << a++;\ncout << a;','1011','1111','1010','1110','a++ yields the old value (10) first, then a becomes 11.'),
('Cpp','What is the output?','cout << 7 / 2.0;','3.5','3','3.0','4','One operand is a double, so there is no integer division.'),
('Cpp','What is the output?','cout << 7 / 2 << " " << 7 % 2;','3 1','3.5 1','4 1','3 0','Integer division gives 3 and % gives the remainder 1.'),
('Cpp','What is the output?','char s[] = "Hello";\ncout << sizeof(s);','6','5','4','8','5 letters plus the ''\\0'' terminator.'),
('Cpp','What is the output?','for (int i = 0; i < 3; i++)\n    cout << i << " ";','0 1 2','1 2 3','0 1 2 3','1 2','i takes 0, 1, 2 and stops when it reaches 3.'),
('Cpp','What is the output?','int x = 3;\nif (x = 0) cout << "A";\nelse cout << "B";','B','A','AB','Compile error','x = 0 assigns 0 (false), so the else branch runs. A classic bug.'),
('Cpp','What is the output?','int i = 5;\nwhile (i--)\n    cout << i;','43210','54321','5432','4321','i-- tests the old value, then decrements before the body runs.'),
('Cpp','What is the output?','cout << ''A'' + 1;','66','B','A','''B''','''A'' + 1 is an int (65 + 1), and cout prints ints as numbers. Unlike printf with %c, no char conversion happens.'),
('Cpp','What is the output?','char c = ''A'';\nc++;\ncout << c;','B','66','A','''B''','c stays a char, so cout prints the character B.'),
('Cpp','What is the output?','int x = 10;\nint *p = &x;\n*p = 20;\ncout << x;','20','10','An address','Error','*p = 20 writes through the pointer into x.'),
('Cpp','What is the output?','string s = "code";\ncout << s.length();','4','5','3','8','length() counts characters and not the terminator.'),
('Cpp','What is the output?','int a = 5;\nint &r = a;\nr = 9;\ncout << a;','9','5','14','Error','A reference is another name for a, so assigning to r changes a.'),
('Cpp','What is the output?','cout << 10 / 4 << " " << 10 / 4.0;','2 2.5','2.5 2.5','2 2','3 2.5','10 / 4 is integer division (2). 10 / 4.0 is floating point (2.5).'),
('Cpp','What is the output?','bool b = 5;\ncout << b;','1','5','0','true','Any non-zero value converts to true, and cout prints a bool as 1 (without boolalpha).'),
('Cpp','What is the output?','int x = 5;\ncout << x / 2 * 2.0;','4','5','2','4.0','x / 2 is 2 (integer), then 2 * 2.0 is the double 4, printed as 4.'),
('CS','What is decimal 10 in binary?',NULL,'1010','1001','1100','1110','8 + 2 = 10, so the bits are 1010.'),
('CS','What is the time complexity of binary search?',NULL,'O(log n)','O(n)','O(1)','O(n²)','Each step halves the search range.'),
('CS','Which data structure is LIFO (last in, first out)?',NULL,'Stack','Queue','Array','Tree','Think of a stack of plates.'),
('CS','Which data structure is FIFO (first in, first out)?',NULL,'Queue','Stack','Heap','Binary tree','The first element added is the first one removed, like a line at a counter.'),
('CS','Which data structure gives O(1) average lookup by key?',NULL,'Hash table','Linked list','Sorted array','Stack','A hash function maps the key straight to a bucket.'),
('CS','Which data structure does breadth-first search (BFS) use?',NULL,'Queue','Stack','Heap','Hash table','BFS explores level by level, so it needs FIFO order. DFS uses a stack.'),
('CS','Which sorting algorithm has O(n log n) time even in the worst case?',NULL,'Merge sort','Bubble sort','Insertion sort','Selection sort','Merge sort always splits in half and merges in linear time.'),
('CS','What does DNS do?',NULL,'Translates domain names to IP addresses','Encrypts traffic','Stores web pages','Assigns MAC addresses','It''s the internet''s phone book.'),
('CS','What is the default port for HTTPS?',NULL,'443','80','21','22','80 = HTTP, 21 = FTP, 22 = SSH.'),
('CS','Which Git command saves a snapshot of staged changes?',NULL,'git commit','git push','git clone','git fork','commit records; push uploads.'),
('CS','Which is an example of supervised learning?',NULL,'Classifying emails as spam using labelled examples','Grouping customers by similarity with no labels','Compressing an image','Defragmenting a disk','Supervised learning trains on inputs paired with known labels.'),
('CS','In machine learning, what is overfitting?',NULL,'The model memorises training data and does poorly on new data','The model is too simple to learn anything','Training finishes too quickly','The dataset is too small to store','An overfit model has low training error but high error on unseen data.'),
('CS','What does the Turing Test try to measure?',NULL,'Whether a machine can behave indistinguishably from a human','How fast a processor runs','How much memory a computer has','Whether code compiles','Alan Turing proposed it as a test of machine intelligence.'),
('CS','Which algorithm adjusts a neural network''s weights using error gradients?',NULL,'Backpropagation','Quick sort','Dijkstra''s algorithm','Huffman coding','Backpropagation pushes the error backwards to update each weight.'),
('CS','What is phishing?',NULL,'Tricking people into revealing secrets using fake messages or sites','Flooding a server with traffic','Guessing passwords by brute force','Encrypting files for ransom','It''s social engineering, usually via email or a cloned login page.'),
('CS','Which defence best prevents SQL injection?',NULL,'Parameterised queries (prepared statements)','Longer passwords','Using HTTP instead of HTTPS','Hiding the login button','Parameters keep user input as data, never as SQL code.'),
('CS','What does XSS stand for?',NULL,'Cross-Site Scripting','Extra Style Sheets','eXtended Server Security','Cross-Server Syntax','Attackers inject script that runs in other users'' browsers.'),
('CS','What does a firewall do?',NULL,'Filters network traffic using rules','Compresses files','Speeds up the CPU','Recovers deleted data','It allows or blocks packets based on configured rules.'),
('CS','Which of these is a hash function rather than an encryption algorithm?',NULL,'SHA-256','AES','RSA','Caesar cipher','Hashes are one-way. Encryption can be reversed with a key.'),
('CS','Which protocol encrypts HTTPS traffic?',NULL,'TLS','FTP','SMTP','DHCP','HTTPS is HTTP running over TLS.'),
('Logic','Fill in the blank so it prints the first six Fibonacci numbers (0 1 1 2 3 5).','int a = 0, b = 1;\nfor (int i = 0; i < 6; i++) {\n    cout << a << " ";\n    int next = a + b;\n    a = b;\n    ____;\n}','b = next','b = a','next = b','a = next','After a takes the old b, b must become the sum (next).'),
('Logic','Fill in the blank so fact(5) returns 120.','int fact(int n) {\n    if (n <= 1) return 1;\n    return ____;\n}\nint main() {\n    cout << fact(5);\n}','n * fact(n - 1)','n * fact(n)','fact(n - 1)','n + fact(n - 1)','n * fact(n) never shrinks and recurses forever. fact(n - 1) alone drops the multiplication.'),
('Logic','Fill in the blank so the values are really swapped (prints 2 1).','void swapVals(____) {\n    int t = a;\n    a = b;\n    b = t;\n}\nint main() {\n    int x = 1, y = 2;\n    swapVals(x, y);\n    cout << x << " " << y;\n}','int &a, int &b','int a, int b','int *a, int *b','const int &a, const int &b','References alias the caller''s variables. Pass by value only swaps copies.'),
('Logic','Fill in the blank to reverse the array in place.','int a[] = {1, 2, 3, 4, 5};\nint n = 5;\nfor (int i = 0; i < n / 2; i++) {\n    int t = a[i];\n    a[i] = a[____];\n    a[____] = t;\n}','n - 1 - i','n - i','n - 1','i - 1','The mirror of index i is n - 1 - i. n - i would go out of bounds at i = 0.'),
('Logic','Fill in the blank so the program prints the largest value (9).','int a[] = {3, 9, 4, 7};\nint mx = a[0];\nfor (int i = 1; i < 4; i++)\n    if (____) mx = a[i];\ncout << mx;','a[i] > mx','a[i] < mx','a[i] = mx','mx > a[i]','Update the maximum only when a larger element is found.'),
('Logic','Fill in the blank so it counts the even numbers from 1 to 9 (prints 4).','int count = 0;\nfor (int i = 1; i <= 9; i++)\n    if (____) count++;\ncout << count;','i % 2 == 0','i % 2 == 1','i / 2 == 0','i % 2','i % 2 == 0 is true when there is no remainder. The other tests count the odd numbers (5) or the wrong things.'),
('Logic','Fill in the blank so isPrime works correctly.','bool isPrime(int n) {\n    if (n < 2) return false;\n    for (int i = 2; i * i <= n; i++)\n        if (____) return false;\n    return true;\n}','n % i == 0','n / i == 0','i % n == 0','n % i != 0','If i divides n evenly, n has a divisor other than 1 and itself.'),
('Logic','Fill in the blank so binary search finds 8 and prints its index, 3.','int a[] = {2, 4, 6, 8, 10};\nint lo = 0, hi = 4, target = 8;\nwhile (lo <= hi) {\n    int mid = (lo + hi) / 2;\n    if (a[mid] == target) { cout << mid; break; }\n    else if (a[mid] < target) ____;\n    else hi = mid - 1;\n}','lo = mid + 1','lo = mid - 1','hi = mid + 1','mid = mid + 1','a[mid] is too small, so the answer lies to the right of mid. The wrong choices loop forever.'),
('Logic','Fill in the blank so bubble sort orders the array ascending (prints 2 3 4).','int a[] = {4, 2, 3}, n = 3;\nfor (int i = 0; i < n - 1; i++)\n    for (int j = 0; j < n - 1 - i; j++)\n        if (____) swap(a[j], a[j + 1]);\nfor (int x : a) cout << x << " ";','a[j] > a[j + 1]','a[j] < a[j + 1]','a[j] == a[j + 1]','a[j] > a[i]','Swap neighbours that are out of order: the left one is bigger than the right one.'),
('Logic','Fill in the blank to release memory allocated with new[].','int *p = new int[4];\np[0] = 7;\ncout << p[0];\n____;','delete[] p','delete p','free(p)','p = nullptr','Memory from new[] must be released with delete[]. Setting p = nullptr only leaks it.'),
('Logic','Fill in the blank so the vector ends up with 4 elements.','vector<int> v = {1, 2, 3};\nv.____(4);\ncout << v.size();','push_back','append','add','push','push_back adds one element at the end of a std::vector.'),
('Logic','Fill in the blank so the string prints backwards (CBA).','string s = "ABC";\nfor (int i = ____; i >= 0; i--)\n    cout << s[i];','s.size() - 1','s.size()','s.size() + 1','0','The last valid index is size() - 1. Index size() is past the end.'),
('Logic','Fill in the blank so only Tue is printed.','int d = 2;\nswitch (d) {\n    case 2: cout << "Tue";\n            ____;\n    case 3: cout << "Wed";\n}','break','continue','stop','exit','Without break, switch falls through into the next case and prints Wed too.'),
('Logic','Fill in the blank to print a triangle of 1, 2 and 3 stars.','for (int i = 1; i <= 3; i++) {\n    for (int j = 1; j <= ____; j++)\n        cout << "*";\n    cout << "\\n";\n}','i','3','j','i + 1','Row i must print i stars, so the inner loop runs up to i.'),
('Logic','Fill in the blank to print the last element (30).','int arr[] = {10, 20, 30};\nint *p = arr;\ncout << *(p + ____);','2','3','1','0','p + 2 points to arr[2]. Pointer arithmetic moves in whole elements.'),
('Logic','Fill in the blank to read a member through a pointer.','struct Wizard { int year; };\nWizard w = {7};\nWizard *p = &w;\ncout << p____year;','->','.','::','=>','Use -> with a pointer to a struct. The dot is for the object itself.'),
('FAST','What does FAST stand for in FAST-NUCES?',NULL,'Foundation for Advancement of Science and Technology','Federal Academy of Software and Technology','Faculty of Applied Science and Telecom','Forum for Advanced Studies and Training','FAST is the sponsoring foundation behind the university.'),
('FAST','What does NUCES stand for?',NULL,'National University of Computer and Emerging Sciences','National Union of Computer Engineering Schools','New University of Computing and Electronic Sciences','National Unit for Computer Education Standards','It was granted its charter as a university in 2000.'),
('FAST','In which year was the FAST foundation established?',NULL,'1980','1970','1990','2000','FAST was set up in 1980. The university itself followed in 2000.'),
('FAST','In which year did FAST receive its federal charter as a university?',NULL,'2000','1980','1990','2010','It was chartered in July 2000 as the National University of Computer and Emerging Sciences.'),
('FAST','FAST-NUCES was originally known as?',NULL,'FAST Institute of Computer Science','Karachi Institute of Technology','National Institute of Computing','Pakistan Computer College','The name changed when it became a chartered university.'),
('FAST','In which Karachi area is the FAST-NUCES main campus?',NULL,'Shah Latif Town','Clifton','Gulshan-e-Iqbal','Saddar','Sector 17-D, Shah Latif Town.'),
('FAST','On which highway is the FAST Karachi main campus located?',NULL,'National Highway','Super Highway','Northern Bypass','Lyari Expressway','It lies east of Karachi''s airport along the National Highway.'),
('FAST','In which Karachi neighbourhood is the FAST city campus?',NULL,'PECHS (Block 6)','North Nazimabad','Korangi','Defence Phase 8','The city campus is at 22-G, Block-6, PECHS.'),
('FAST','What is the yearly flagship tech event of FAST-NUCES Karachi, running since 1998?',NULL,'PROCOM','SOFTEC','Geek Week','TechFest','SOFTEC is the Lahore campus event.'),
('FAST','Which campus hosts the annual SOFTEC event?',NULL,'Lahore','Karachi','Islamabad','Peshawar','SOFTEC has been held at the Lahore campus since 1995, while PROCOM is Karachi''s event.'),
('FAST','Where is the central administration of the National University based?',NULL,'Islamabad','Karachi','Lahore','Peshawar','The head office is FAST House, Rohtas Road, G-9/4, Islamabad.'),
('FAST','Which FAST-NUCES campus was its first residential campus, with hostels inside?',NULL,'Chiniot-Faisalabad','Karachi','Peshawar','Lahore','It is the university''s fifth campus.'),
('FAST','Which of these undergraduate degrees is offered at FAST-NUCES Karachi?',NULL,'BS Computer Science','MBBS','LLB','BArch','FAST Karachi offers BSCS, BSEE and BSBA, plus other computing programmes.');
