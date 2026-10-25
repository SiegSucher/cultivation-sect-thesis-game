extends RefCounted
## "The First Current" content: Guide and Mentor lines, the Mentor's syntax teaching, and the two
## typed-code stages (1 awaken your Qi, 2 channel it into the basin) in Python, C and Java.
## Qi commands are game-provided, never presented as standard language features.
## A card is [title, text, code] or [title, text, code, "signature"]. Code without the fourth item
## is a short program that runs in its step without solving it; a "signature" shows a command's
## shape with placeholder arguments and is labelled as a reference, not a program. Complete answers
## appear only in "solution", behind the Hints tab's "Show worked solution".

const GUIDE_INTRO := [
	"Welcome, apprentice. You have just arrived at the Split-Cloud Sect.",
	"Here, cultivators direct Qi, the world's spiritual energy, through programming inscriptions.",
	"Every cultivator's training begins the same way: by awakening and controlling their own Qi. The Mentor will supervise your first practical exercise.",
	"You will find the Mentor beside the basin in the living court. Go through the gate and up the second stair.",
]
const GUIDE_AGAIN := "The Mentor is waiting beside the basin in the living court: through the gate, then up the second stair."

const MENTOR_GREETING := "Welcome, apprentice. I supervise every new cultivator's first practical exercise."
const MENTOR_OFFER := "First you will awaken your own Qi by writing a short inscription. Then you will channel that Qi into this public basin to start its flow. You may run your code and correct it as often as you need. Shall we begin?"
const MENTOR_DECLINE := "No rush. Look around the sect, and speak to me when you are ready."
const MENTOR_STAGE1 := "Your awakening inscription is waiting. Shall we continue?"
const MENTOR_STAGE2_INTRO := "Your Qi is awake, and your reserve holds 3. Now apply it to something outside yourself: the basin needs 3 Qi to start flowing. Let me show you how to read your reserve and channel it."
const MENTOR_STAGE2 := "Your reserve is ready. Walk to the basin and press E to write the channelling inscription."
const MENTOR_DONE := "The basin flows for every traveller now, and you have already been welcomed into training. I replenished your Qi reserve after your practice. Use Reset Demo in the Esc menu to replay in another language."
const RECOGNITION := "“You stored your Qi before you used it, then applied it to something beyond yourself. Every current begins that way. Welcome into training, apprentice. Your reserve is spent, so I am replenishing it after practice.”"

const ORDER := ["python", "c", "java"]
const OBJECTIVE := {
	1: "Store 3 in a variable named qi, then call the awakening command with qi.",
	2: "Read your Qi reserve into a variable, then channel that amount into the basin.",
}
const INTERPRETER_NOTE := "Your code runs in the sect's learning interpreter, a custom interpreter for a small subset of %s. Its messages imitate %s's style and are approximate."

const LESSONS := {
	"python": {
		"name": "Python",
		"files": ["awakening.py", "basin.py"],
		"header": [["from sect import *        # the game's Qi commands", ""], ["from sect import *        # the game's Qi commands", ""]],
		"footer": [[], []],
		"starter": ["# Awaken your Qi below\n", "# Channel your Qi into the basin\n"],
		"keywords": ["from", "import", "True", "False", "None"],
		"comment": "#",
		"cards": [[
			["A variable stores a value", "A variable is a name that holds a value. In Python you create one by assigning: the name, then =, then the value. You write no type word and no semicolon.", "steps = 5"],
			["Give it a value before you use it", "Assignment is also initialization: it gives the variable its first value. A line can only use a variable after an earlier line has assigned it.", "steps = 5\nprint(steps)     # prints 5"],
			["A function call performs an action", "Write the function's name, then parentheses holding its arguments. The call tells the program to act on those values.", "steps = 5\nprint(\"Ready\")\nprint(steps)"],
			["Statements run in order", "Python runs one line at a time, from top to bottom. Each statement goes on its own line and starts at the left edge.", "steps = 5        # runs first\nprint(steps)     # runs second"],
			["The game's awakening command", "awaken(amount) belongs to this game, not to Python. The top line imports it from the game's sect module. It awakens your Qi with amount as your first reserve. Prepare the amount in a variable first, then pass the variable.", "awaken(amount)          # amount: a whole number of Qi", "signature"],
		], [
			["Calls can give back a value", "Some functions return a value. Store it in a variable so later lines can use it. qi_reserve() is a game command that returns how much Qi you hold.", "reserve = qi_reserve()\nprint(reserve)     # prints 3"],
			["Channelling Qi into the basin", "channel_basin(amount) is a game command that sends that much Qi into the basin, which needs 3 to start. You cannot send more than you hold, so pass what qi_reserve() gave you.", "channel_basin(amount)   # amount: how much Qi to send", "signature"],
		]],
		"reference": "GAME COMMANDS (from the game's sect module, not built into Python)\n  awaken(amount)         awaken your Qi with amount as your first reserve\n  qi_reserve()           returns your current Qi\n  channel_basin(amount)  send amount Qi into the basin (it needs 3)\n\nPYTHON\n  name = value           assignment creates and initializes a variable\n  name(arguments)        a function call\n  print(value)           show a value in the output\n  # text                 a comment\n\nTHIS LEARNING INTERPRETER (a small subset of Python)\n  Supports: assignment, calls, whole numbers, \"text\",\n  True/False/None, + - * ( ) and ==\n  Not supported: if, loops, def, imports, lists,\n  decimals, / and %",
		"hints": [[
			"First give qi its value with an assignment. On the next line, call the command and pass qi inside the parentheses.",
			"Two lines:\nqi = ___\nawaken(___)",
		], [
			"Call qi_reserve() and store what it returns in a variable. Then pass that variable to channel_basin().",
			"Two lines:\nreserve = qi_reserve()\nchannel_basin(_______)",
		]],
		"solution": ["qi = 3\nawaken(qi)", "reserve = qi_reserve()\nchannel_basin(reserve)"],
	},
	"c": {
		"name": "C",
		"files": ["awakening.c", "basin.c"],
		"header": [["#include <stdio.h>", "#include \"sect.h\"     /* the game's Qi commands */", "", "int main(void) {"], ["#include <stdio.h>", "#include \"sect.h\"     /* the game's Qi commands */", "", "int main(void) {"]],
		"footer": [["    return 0;", "}"], ["    return 0;", "}"]],
		"starter": ["/* Awaken your Qi below */\n", "/* Channel your Qi into the basin */\n"],
		"keywords": ["int", "return", "void", "include"],
		"comment": "//",
		"cards": [[
			["A variable stores a value", "In C every variable has a type. int holds whole numbers. A declaration gives the type, then the name, and ends with a semicolon.", "int steps;"],
			["Initialize it before use", "Give the variable its first value when you declare it. Until then a C variable holds an unpredictable value, so never read it first.", "int steps = 5;"],
			["A function call performs an action", "Write the function's name, then its arguments in parentheses. printf is a standard C function that prints.", "int steps = 5;\nprintf(\"%d\\n\", steps);"],
			["Statements run in order; each ends with ;", "Inside main, statements run from top to bottom, and every statement ends with a semicolon. The #include lines, main and return 0 are already written for you.", "int steps = 5;            /* first */\nprintf(\"%d\\n\", steps);   /* second */"],
			["The game's awakening command", "awaken(amount) comes from the game's sect.h, not from standard C. It awakens your Qi with amount as your first reserve. Prepare the amount in an int variable first, then pass the variable.", "void awaken(int amount);   /* declared in sect.h */", "signature"],
		], [
			["Calls can return a value", "A function can return (hand back) a value. Store it in a variable of the right type. qi_reserve() is a game command from sect.h that returns your Qi as an int.", "int reserve = qi_reserve();\nprintf(\"%d\\n\", reserve);   /* prints 3 */"],
			["Channelling Qi into the basin", "channel_basin(amount) comes from the game's sect.h. It sends that much Qi into the basin, which needs 3 to start. You cannot send more than you hold, so pass what qi_reserve() returned.", "void channel_basin(int amount);   /* declared in sect.h */", "signature"],
		]],
		"reference": "GAME COMMANDS (from the game's sect.h, not standard C)\n  void awaken(int amount);         first Qi reserve\n  int  qi_reserve(void);           your current Qi\n  void channel_basin(int amount);  send Qi to the basin (needs 3)\n\nC\n  int name = value;      declare and initialize\n  name = value;          assign a declared variable\n  name(arguments);       a function call\n  printf(\"%d\\n\", x);     print a whole number\n  /* text */  // text    comments\n\nTHIS LEARNING INTERPRETER (a small subset of C)\n  Supports: int declarations, assignment, calls,\n  whole numbers, \"text\", + - * ( ) and ==\n  Not supported: if, loops, other types, arrays,\n  pointers, / and %",
		"hints": [[
			"Declare an int named qi and initialize it to 3 in one statement. Then call awaken with qi. End both statements with a semicolon.",
			"Two statements:\nint qi = ___;\nawaken(___);",
		], [
			"Declare an int and initialize it with what qi_reserve() returns. Then pass it to channel_basin.",
			"Two statements:\nint reserve = qi_reserve();\nchannel_basin(_______);",
		]],
		"solution": ["int qi = 3;\nawaken(qi);", "int reserve = qi_reserve();\nchannel_basin(reserve);"],
	},
	"java": {
		"name": "Java",
		"files": ["Awakening.java", "Basin.java"],
		"header": [["// Sect holds the game's Qi commands (not standard Java)", "public class Awakening {", "    public static void main(String[] args) {"],
			["// Sect holds the game's Qi commands (not standard Java)", "public class Basin {", "    public static void main(String[] args) {"]],
		"footer": [["    }", "}"], ["    }", "}"]],
		"starter": ["// Awaken your Qi below\n", "// Channel your Qi into the basin\n"],
		"keywords": ["int", "public", "class", "static", "void", "String"],
		"comment": "//",
		"cards": [[
			["A variable stores a value", "Java variables have a type. int holds whole numbers. A declaration gives the type, then the name, and ends with a semicolon.", "int steps;"],
			["Initialize it before use", "Java will not compile code that reads a local variable before it has a value. Initialize it, giving it its first value, when you declare it.", "int steps = 5;"],
			["A method call performs an action", "A call names the method and passes its arguments in parentheses. System.out.println is part of standard Java.", "int steps = 5;\nSystem.out.println(steps);"],
			["Statements run in order; each ends with ;", "Statements inside main run from top to bottom, and each ends with a semicolon. The class and main are already written for you.", "int steps = 5;               // first\nSystem.out.println(steps);   // second"],
			["The game's awakening command", "Sect.awaken(amount) belongs to the game's Sect class, not to Java's standard library, so you call it through Sect. It awakens your Qi with amount as your first reserve. Prepare the amount in an int variable first, then pass the variable.", "Sect.awaken(int amount)   // in the game's Sect class", "signature"],
		], [
			["Methods can return a value", "A method can return (hand back) a value. Store it in a variable of the right type. Sect.qiReserve() is a game method that returns your Qi as an int.", "int reserve = Sect.qiReserve();\nSystem.out.println(reserve);   // prints 3"],
			["Channelling Qi into the basin", "Sect.channelBasin(amount) belongs to the game's Sect class. It sends that much Qi into the basin, which needs 3 to start. You cannot send more than you hold, so pass what Sect.qiReserve() returned.", "Sect.channelBasin(int amount)   // in the game's Sect class", "signature"],
		]],
		"reference": "GAME COMMANDS (the game's Sect class, not standard Java)\n  Sect.awaken(int amount)        first Qi reserve\n  Sect.qiReserve()               returns your current Qi (int)\n  Sect.channelBasin(int amount)  send Qi to the basin (needs 3)\n\nJAVA\n  int name = value;              declare and initialize\n  name = value;                  assign a declared variable\n  Sect.method(arguments);        call a method\n  System.out.println(x);         print a value\n  // text                        a comment\n\nTHIS LEARNING INTERPRETER (a small subset of Java)\n  Supports: int declarations, assignment, calls,\n  whole numbers, \"text\", true/false, + - * ( ) and ==\n  Not supported: if, loops, other types, arrays,\n  objects, methods on values, / and %",
		"hints": [[
			"Declare an int named qi and initialize it to 3. Then call Sect.awaken with qi. End both statements with a semicolon.",
			"Two statements:\nint qi = ___;\nSect.awaken(___);",
		], [
			"Declare an int and initialize it with what Sect.qiReserve() returns. Then pass it to Sect.channelBasin.",
			"Two statements:\nint reserve = Sect.qiReserve();\nSect.channelBasin(_______);",
		]],
		"solution": ["int qi = 3;\nSect.awaken(qi);", "int reserve = Sect.qiReserve();\nSect.channelBasin(reserve);"],
	},
}

# Plain-language explanations shown under the console, keyed by the runner's failure kind.
const NOTES := {
	"syntax": "The line could not be read as a statement. Compare it with the examples in the Lesson tab.",
	"indent": "Python statements at the top level must start at the left edge. Remove the spaces before this line.",
	"python_type": "Python never puts a type word such as int before a name. To create the variable, just assign it: name = value.",
	"call_syntax": "A call needs parentheses around its argument, for example awaken(qi).",
	"semicolon": "Every statement must end with a semicolon. Add ; at the end of this line.",
	"type": "Other types are real, but this exercise uses whole numbers only, so declare the variable as int.",
	"unknown_type": "This is not a type the program knows. Declare whole numbers with int.",
	"unsupported": "The learning interpreter understands only part of the language. Use what the Lesson and Commands tabs show: assignments, calls, whole numbers and text.",
	"limit": "The learning interpreter runs only short programs, and this exercise needs just two lines.",
	"structure": "The program structure is already written for you. Type only the statements that go inside main.",
	"undeclared": "This name has not been declared yet. Give it a type, then a value, on an earlier line, for example int qi = 3;",
	"uninitialized": "This variable was declared but never given a value, so it cannot be read safely. Initialize it when you declare it.",
	"name_error": "This name is used before any line gives it a value. Statements run top to bottom, so assign it on an earlier line.",
	"unknown": "That command does not exist here. Check its exact spelling in the Commands tab.",
	"arity": "This command was given the wrong number of arguments. The Commands tab shows what it expects.",
	"type_mismatch": "These values have different types and cannot be combined this way.",
	"redeclared": "This variable is already declared. Declare it once, then assign it with name = value; if you need to change it.",
	"not_statement": "This line computes a value but does nothing with it. Store it in a variable or pass it to a command.",
	"wrong_amount": "The awakening needs exactly 3 Qi. Initialize your variable with 3.",
	"awaken_type": "Qi is counted in whole numbers. Pass a number, not text.",
	"channel_type": "Qi is counted in whole numbers. Pass a number, not text.",
	"already_awake": "Your Qi is already awake. This step reads your reserve and channels it.",
	"not_awake": "The basin comes later. Awaken your own Qi first.",
	"not_enough": "You cannot channel more Qi than your reserve holds. Read the reserve and pass that amount.",
	"too_small": "The basin needs 3 Qi to start. Pass your whole reserve.",
	"literal_arg": "Prepare the Qi first: store the value in a variable on one line, then pass that variable to the command on the next.",
	"literal_channel": "Read your reserve with the reserve command, store it, and pass that value, so the inscription uses the Qi you actually hold.",
}
const NOTE_C_UNINITIALIZED := "A real C compiler would only warn here, but the program would read an unpredictable value. The sect's checker stops it before it runs."
