extends RefCounted
## The sect's learning interpreter: a custom interpreter, written for this lesson, that supports a
## limited subset of Python, C and Java syntax. It tokenizes and parses the learner's statements,
## checks C and Java programs before running them (declarations, initialization, types, known
## functions), then evaluates the statements in order:
##   Python  name = expr | call
##   C/Java  int name [= expr]; | name = expr; | call;
## Expressions: whole numbers, "text", names, calls, + - *, ( ), ==, True/False/None (Java
## true/false/null). Commands: the game's awaken / qi_reserve / channel_basin (Java: Sect.awaken /
## Sect.qiReserve / Sect.channelBasin) and the standard print / printf / System.out.println / print.
## It is not Python, gcc or javac: its messages imitate each language's style and are approximate.
## Every failure has a category:
##   language     an error the real language would also report
##   game         a Qi rule enforced by the game's commands while the program runs
##   exercise     valid code that does not meet this lesson's requirement
##   unsupported  real language syntax this interpreter does not handle
##   limit        the program goes past one of the limits below
## Main quests 3/4 add if blocks and bounded for loops. Nested blocks, loop iterations and total
## executed statements are limited; every run finishes synchronously. No function definitions.
const BASIN_NEEDS := 3
const FIRST_RESERVE := 3
const MAX_SOURCE := 2000        # characters
const MAX_TOKENS := 400         # words, numbers, text and symbols
const MAX_STATEMENTS := 40
const MAX_NESTING := 12         # brackets, call arguments and signs inside one another
const MAX_OUTPUT := 30          # console lines
const MAX_TEXT := 200           # characters shown per console line
const MAX_NUMBER := 999999999
const NAMES := {"python": "Python", "c": "C", "java": "Java"}

# Command table: name as written -> [action, fewest arguments, most arguments].
const COMMANDS := {
	"python": {"awaken": ["awaken", 1, 1], "qi_reserve": ["reserve", 0, 0], "channel_basin": ["channel", 1, 1], "seal_charge": ["charge", 0, 0], "unseal_bridge": ["bridge", 0, 0], "pulse_ward": ["ward", 0, 0], "print": ["print", 0, 99]},
	"c": {"awaken": ["awaken", 1, 1], "qi_reserve": ["reserve", 0, 0], "channel_basin": ["channel", 1, 1], "seal_charge": ["charge", 0, 0], "unseal_bridge": ["bridge", 0, 0], "pulse_ward": ["ward", 0, 0], "printf": ["printf", 1, 99]},
	"java": {"Sect.awaken": ["awaken", 1, 1], "Sect.qiReserve": ["reserve", 0, 0], "Sect.channelBasin": ["channel", 1, 1], "Sect.sealCharge": ["charge", 0, 0], "Sect.unsealBridge": ["bridge", 0, 0], "Sect.pulseWard": ["ward", 0, 0],
		"System.out.println": ["println", 0, 1], "System.out.print": ["print_no_newline", 1, 1]},
}
const VOID_ACTIONS := ["awaken", "channel", "bridge", "ward", "println", "print_no_newline"]
# C and Java type words. Only int is used in this exercise.
const TYPES := {"c": ["int", "double", "float", "long", "short", "char", "unsigned", "signed"],
	"java": ["int", "double", "float", "long", "short", "char", "byte", "boolean", "String", "var"]}
# Real language words, symbols and library names outside the subset: reported as unsupported, not as errors.
const UNSUPPORTED_WORDS := {
	"python": ["if", "elif", "else", "for", "while", "def", "return", "lambda", "yield", "import", "from", "class", "try",
		"except", "finally", "raise", "with", "pass", "break", "continue", "global", "nonlocal", "del", "assert", "and",
		"or", "not", "in", "is", "async", "await"],
	"c": ["if", "else", "switch", "case", "default", "for", "while", "do", "break", "continue", "return", "goto",
		"struct", "union", "enum", "typedef", "sizeof", "const", "static", "extern", "void"],
	"java": ["if", "else", "switch", "case", "default", "for", "while", "do", "break", "continue", "return", "class",
		"interface", "public", "private", "protected", "static", "final", "void", "new", "try", "catch", "finally",
		"throw", "import", "package", "this", "super", "instanceof"],
}
const UNSUPPORTED_SYMBOLS := {"python": "/%<>!&|^~[]{}:@", "c": "/%<>!&|^~[]?:'#", "java": "/%<>!&|^~[]?:'@"}
const LIBRARY := {
	"python": ["len", "input", "range", "int", "str", "float", "bool", "abs", "max", "min", "sum", "round", "pow", "type",
		"list", "dict", "set", "tuple", "sorted", "reversed", "enumerate", "zip", "map", "filter", "open", "repr", "chr",
		"ord", "help", "exit"],
	"c": ["puts", "putchar", "getchar", "scanf", "sprintf", "snprintf", "fprintf", "fputs", "fgets", "perror"],    # <stdio.h>
	"java": ["Math", "Integer", "String", "Double", "Long", "Character", "Boolean", "System", "Arrays", "Thread", "Objects"],
}

class Fail extends RefCounted:
	var kind := ""
	var category := ""
	var line := 0
	var message := ""
	var detail := ""
	func _init(k: String, c: String, l: int, m: String, d: String) -> void:
		kind = k
		category = c
		line = l
		message = m
		detail = d

var lang := ""
var stage := 1
var file := ""
var offset := 0           # learner line 1 is file line offset+1
var tokens: Array = []
var pos := 0
var depth := 0
var fail: Fail = null
# run state
var vars := {}            # name -> value, initialized?, source bits (1 = Qi reserve, 2 = seal charge)
var reserve := 0
var output: Array = []    # [kind, text]: out, sect, note
var guard_depth := 0
var loop_depth := 0
var executed := 0
const MAX_ITERATIONS := 16
const MAX_EXECUTED := 256
var pending := ""         # printed text not yet ended by a newline
var effects := {"awaken": 0, "awaken_from_variable": false, "channel": 0, "channel_from_reserve": false, "bridge": 0, "ward": 0}

# ---------------------------------------------------------------- entry point
func run(language: String, stage_number: int, code: String, file_name: String, header_lines: int, current_reserve: int) -> Dictionary:
	"""Returns {phase: "compile"|"run"|"done", ok, fail (kind,category,line,message,detail) or {}, output, effects}."""
	lang = language
	stage = stage_number
	file = file_name
	offset = header_lines
	reserve = current_reserve
	tokens = []
	pos = 0
	depth = 0
	vars = {}
	output = []
	pending = ""
	guard_depth = 0
	loop_depth = 0
	executed = 0
	fail = null
	effects = {"awaken": 0, "awaken_from_variable": false, "channel": 0, "channel_from_reserve": false, "bridge": 0, "ward": 0}
	if code.length() > MAX_SOURCE:
		limit(0, "Not run: the program is %d characters long; this learning interpreter accepts up to %d." % [code.length(), MAX_SOURCE])
		return result("compile")
	var statements: Array = []
	tokenize(code)
	if fail == null: statements = parse_program()
	if fail == null and lang != "python": check_program(statements)
	if fail != null: return result("compile")
	for s: Dictionary in statements:
		execute(s)
		if fail != null: return result("run")
	if stage == 4 and effects.ward > 0 and effects.ward != 3:
		rule("ward_count", last_line(), "the ward needs exactly 3 pulses; your loop delivered %d." % effects.ward)
	return result("done")

func result(phase: String) -> Dictionary:
	flush()
	var f := {}
	if fail != null: f = {"kind": fail.kind, "category": fail.category, "line": fail.line, "message": fail.message, "detail": fail.detail}
	return {"phase": phase, "ok": fail == null, "fail": f, "output": output, "effects": effects}

func error(kind: String, line: int, message: String, detail := "", category := "language") -> void:
	if fail == null: fail = Fail.new(kind, category, line, message, detail)

func rule(kind: String, line: int, text: String) -> void:
	error(kind, line, "Valid %s, but %s" % [NAMES[lang], text], "", "exercise")

func unsupported(line: int, feature: String) -> void:
	error("unsupported", line, "Not supported by this learning interpreter: %s." % feature, feature, "unsupported")

func limit(line: int, text: String) -> void:
	error("limit", line, text, "", "limit")

func game_error(line: int, message: String, kind: String) -> Array:
	match lang:
		"python": error(kind, line, "SectError: "+message, "", "game")
		"c": error(kind, line, "[sect] error: "+message, "", "game")
		_: error(kind, line, "Exception in thread \"main\" SectException: "+message, "", "game")
	return [null, false]

# ---------------------------------------------------------------- output
func emit(kind: String, text: String, line: int) -> void:
	if output.size() >= MAX_OUTPUT:
		limit(line, "Stopped: the program printed more than %d lines; this learning interpreter shows at most %d." % [MAX_OUTPUT, MAX_OUTPUT])
		return
	output.append([kind, text if text.length() <= MAX_TEXT else text.left(MAX_TEXT)+" ..."])

func write(text: String, line: int) -> void:
	var lines := (pending+text).split("\n")
	pending = lines[lines.size()-1]
	for i in lines.size()-1: emit("out", lines[i], line)

func flush() -> void:
	if pending != "":
		var text := pending
		pending = ""
		emit("out", text, 0)

# ---------------------------------------------------------------- tokens
func tokenize(code: String) -> void:
	var lines := code.split("\n")
	var in_block := false
	var count := 0
	for li in lines.size():
		var text: String = lines[li].replace("\t", "    ")
		var line := li+1
		var i := 0
		var first := true
		while i < text.length():
			var c := text[i]
			if in_block:
				var close := text.find("*/", i)
				if close < 0: i = text.length()
				else:
					in_block = false
					i = close+2
				continue
			if c == " ":
				i += 1
				continue
			if lang == "python" and c == "#": break
			if lang != "python" and text.substr(i, 2) == "//": break
			if lang != "python" and text.substr(i, 2) == "/*":
				in_block = true
				i += 2
				continue
			var tok := {"line": line, "col": i, "first": first}
			first = false
			var two := text.substr(i, 2)
			if is_letter(c):
				var j := i
				while j < text.length() and (is_letter(text[j]) or is_digit(text[j])): j += 1
				tok.t = "id"
				tok.v = text.substr(i, j-i)
				i = j
			elif is_digit(c):
				var j := i
				while j < text.length() and is_digit(text[j]): j += 1
				if j+1 < text.length() and text[j] == "." and is_digit(text[j+1]):
					j += 1
					while j < text.length() and is_digit(text[j]): j += 1
					unsupported_token(tok, text.substr(i, j-i), "decimal numbers (this exercise uses whole numbers)")
				elif j-i > 9:
					limit(line, "Not run: %s is too large; this learning interpreter keeps whole numbers between -%d and %d." % [text.substr(i, j-i), MAX_NUMBER, MAX_NUMBER])
					return
				else:
					tok.t = "num"
					tok.v = text.substr(i, j-i)
				i = j
			elif c == "\"" or (c == "'" and lang == "python"):
				var j := i+1
				var s := ""
				while j < text.length() and text[j] != c:
					if text[j] == "\\" and j+1 < text.length():
						var e := text[j+1]
						s += "\n" if e == "n" else e
						j += 2
					else:
						s += text[j]
						j += 1
				if j >= text.length():
					error("syntax", line, unterminated_message(), "text that opens with a quote must close with the same quote")
					return
				tok.t = "str"
				tok.v = s
				i = j+1
			elif two == "==":
				tok.t = "sym"
				tok.v = "=="
				i += 2
			elif two in ["+=", "-=", "*="] or (two == "**" and lang == "python") or (two in ["++", "--"] and lang != "python"):
				unsupported_token(tok, two, symbol_feature(two))
				i += 2
			elif stage >= 3 and c in ":<":
				tok.t = "sym"
				tok.v = c
				i += 1
			elif c in UNSUPPORTED_SYMBOLS[lang]:
				unsupported_token(tok, c, symbol_feature(c))
				i += 1
			elif c in "()=,;+-*.{}":
				tok.t = "sym"
				tok.v = c
				i += 1
			else:
				error("syntax", line, stray_message(c), "the character %s is not part of this inscription" % c)
				return
			tokens.append(tok)
			count += 1
			if count > MAX_TOKENS:
				limit(line, "Not run: the program has more than %d words, numbers and symbols; this learning interpreter accepts up to %d." % [MAX_TOKENS, MAX_TOKENS])
				return
		if lang == "python": tokens.append({"t": "nl", "v": "", "line": line, "col": text.length(), "first": false})

func unsupported_token(tok: Dictionary, text: String, feature: String) -> void:
	"""Real syntax outside the subset. Reported when the parser reaches it, so keywords such as
	for or if on the same line are named first."""
	tok.t = "bad"
	tok.v = text
	tok.feature = feature

func is_letter(c: String) -> bool:
	return (c >= "a" and c <= "z") or (c >= "A" and c <= "Z") or c == "_"

func is_digit(c: String) -> bool:
	return c >= "0" and c <= "9"

func unterminated_message() -> String:
	match lang:
		"python": return "SyntaxError: unterminated string literal"
		"c": return "error: missing terminating \" character"
	return "error: unclosed string literal"

func stray_message(c: String) -> String:
	match lang:
		"python": return "SyntaxError: invalid character '%s'" % c
		"c": return "error: stray '%s' in program" % c
	return "error: illegal character: '%s'" % c

func symbol_feature(s: String) -> String:
	match s:
		"/", "%": return "division and remainder (/ and %)"
		"<", ">", "!": return "comparisons other than == (such as <, > and !=)"
		"&", "|", "^", "~": return "logical and bitwise operators"
		"[", "]": return "lists, arrays and indexing ([ ])"
		"{", "}": return "dictionaries and sets ({ })"
		":": return "blocks that end with a colon (if, for, def)" if lang == "python" else "the ? : operator"
		"?": return "the ? : operator"
		"@": return "decorators and annotations (@)"
		"'": return "single-quoted characters (use double quotes for text)"
		"#": return "preprocessor lines (the #include lines are already written)"
		"+=", "-=", "*=": return "compound assignment (%s)" % s
		"++", "--": return "increment and decrement (++ and --)"
		"**": return "powers (**)"
	return s

func word_feature(w: String) -> String:
	match w:
		"if", "elif", "else", "switch", "case", "default": return "decisions such as if and else"
		"for", "while", "do", "break", "continue": return "loops such as for and while"
		"def", "lambda", "return", "yield", "void": return "defining functions or returning from them"
		"import", "from", "package": return "imports (the game's commands are already available)"
		"class", "interface", "public", "private", "protected", "static", "final", "new", "this", "super", "instanceof", "struct", "union", "enum", "typedef":
			return "classes, objects and other declarations (the program structure is already written)"
		"try", "except", "catch", "finally", "raise", "throw", "assert", "with": return "exception handling"
		"and", "or", "not", "in", "is": return "logical operators such as and, or and not"
	return "the keyword '%s'" % w

# ---------------------------------------------------------------- parsing
func peek(k := 0) -> Dictionary:
	return tokens[pos+k] if pos+k < tokens.size() else {"t": "end", "v": "", "line": last_line(), "col": 0, "first": false}

func last_line() -> int:
	return tokens[-1].line if tokens.size() else 1

func take() -> Dictionary:
	var t := peek()
	pos += 1
	return t

func is_sym(t: Dictionary, v: String) -> bool:
	return t.t == "sym" and t.v == v

func parse_program() -> Array:
	pos = 0
	if stage >= 3:
		return preload("res://proposal_demo_living_sect/control_flow.gd").new(self).sequence()
	var out: Array = []
	while fail == null and peek().t != "end":
		if lang == "python":
			if peek().t == "nl":
				take()
				continue
			if peek().col > 0 and peek().first:
				error("indent", peek().line, "IndentationError: unexpected indent", "")
				return out
			var s := parse_statement()
			if fail: return out
			out.append(s)
			if is_sym(peek(), ";"):
				take()
			elif peek().t != "nl" and peek().t != "end":
				syntax_error_at(peek())
				return out
		else:
			if is_sym(peek(), ";"):
				take()
				continue
			var s := parse_statement()
			if fail: return out
			out.append(s)
			if not is_sym(peek(), ";"):
				missing_semicolon(s.end_line, peek())
				return out
			take()
		if out.size() > MAX_STATEMENTS:
			limit(out[-1].line, "Not run: the program has more than %d statements; this learning interpreter accepts up to %d." % [MAX_STATEMENTS, MAX_STATEMENTS])
	return out

func parse_statement() -> Dictionary:
	var t := peek()
	var line: int = t.line
	if t.t == "id" and t.v in UNSUPPORTED_WORDS[lang]:
		unsupported(line, word_feature(t.v))
		return {}
	if t.t == "id" and peek(1).t == "id":
		if lang != "python": return parse_declaration()
		if t.v in ["int", "double", "float", "long", "char", "String", "boolean", "var", "auto"]:
			error("python_type", line, "SyntaxError: invalid syntax", t.v)
			return {}
	if t.t == "id" and is_sym(peek(1), "="):
		take()
		take()
		var e = parse_expr()
		return {"k": "assign", "name": t.v, "expr": e, "line": line, "end_line": prev_line()}
	if t.t == "sym" and t.v in ["{", "}"]:
		unsupported(line, "extra { } blocks (main's braces are already written)")
		return {}
	var e = parse_expr()
	return {"k": "expr", "expr": e, "line": line, "end_line": prev_line()}

func parse_declaration() -> Dictionary:
	"""C/Java: a type word followed by a name."""
	var t := take()
	var line: int = t.line
	if not t.v in TYPES[lang]:
		error("unknown_type", line, ("error: unknown type name '%s'" if lang == "c" else "error: cannot find symbol (class %s)") % t.v, t.v)
		return {}
	if t.v != "int":
		rule("type", line, "this exercise uses whole numbers, so declare the variable as int.")
		return {}
	var name := take()
	if is_sym(peek(), "("):
		error("structure", line, "error: a function definition is not allowed here" if lang == "c" else "error: illegal start of expression", name.v)
		return {}
	var init = null
	if is_sym(peek(), "="):
		take()
		init = parse_expr()
	if fail == null and is_sym(peek(), ","):
		unsupported(line, "declaring several variables in one statement")
		return {}
	return {"k": "decl", "name": name.v, "init": init, "line": line, "end_line": prev_line()}

func prev_line() -> int:
	return tokens[pos-1].line if pos > 0 and pos-1 < tokens.size() else last_line()

func parse_expr():
	var a = parse_sum()
	if fail: return null
	if is_sym(peek(), "==") or (stage >= 3 and is_sym(peek(), "<")):
		var comparison := take()
		var l: int = comparison.line
		var b = parse_sum()
		return {"k": "cmp", "a": a, "b": b, "op": comparison.v, "line": l}
	return a

func parse_sum():
	var a = parse_term()
	while fail == null and (is_sym(peek(), "+") or is_sym(peek(), "-")):
		var op: String = take().v
		var b = parse_term()
		a = {"k": "bin", "op": op, "a": a, "b": b, "line": prev_line()}
	return a

func parse_term():
	var a = parse_factor()
	while fail == null and is_sym(peek(), "*"):
		take()
		var b = parse_factor()
		a = {"k": "bin", "op": "*", "a": a, "b": b, "line": prev_line()}
	return a

func parse_factor():
	"""Counts how deeply brackets, call arguments and signs are nested."""
	depth += 1
	var e = null
	if depth > MAX_NESTING:
		limit(peek().line, "Not run: brackets, calls or signs are nested more than %d deep; this learning interpreter accepts up to %d." % [MAX_NESTING, MAX_NESTING])
	else: e = factor()
	depth -= 1
	return e

func factor():
	var t := peek()
	var e = null
	if t.t == "num":
		take()
		e = {"k": "num", "v": int(t.v), "line": t.line}
	elif t.t == "str":
		take()
		e = {"k": "str", "v": t.v, "line": t.line}
	elif is_sym(t, "-") or is_sym(t, "+"):
		take()
		return {"k": "neg", "op": t.v, "a": parse_factor(), "line": t.line}
	elif is_sym(t, "("):
		take()
		e = parse_expr()
		if fail: return null
		if not is_sym(peek(), ")"):
			syntax_error_at(peek())
			return null
		take()
	elif t.t == "id":
		return name_or_call()
	elif t.t == "bad":
		unsupported(t.line, t.feature)
		return null
	else:
		syntax_error_at(t)
		return null
	if is_sym(peek(), "."):
		unsupported(t.line, "calling methods on values, such as .length() or .upper()")
		return null
	return e

func name_or_call():
	var t := take()
	var name: String = t.v
	if name in UNSUPPORTED_WORDS[lang]:
		unsupported(t.line, word_feature(name))
		return null
	if (lang == "python" and name in ["True", "False", "None"]) or (lang == "java" and name in ["true", "false", "null"]):
		return {"k": "lit", "v": {"True": true, "true": true, "False": false, "false": false}.get(name), "line": t.line}
	if lang == "python" and peek().t == "str" and peek().line == t.line and peek().col == t.col+name.length():
		unsupported(t.line, "string prefixes such as f\"...\"")
		return null
	while is_sym(peek(), ".") and peek(1).t == "id":
		take()
		name += "."+take().v
	if is_sym(peek(), "("):
		take()
		var args := []
		if not is_sym(peek(), ")"):
			while fail == null:
				if lang == "python" and peek().t == "id" and is_sym(peek(1), "="):
					unsupported(peek().line, "keyword arguments such as end=\"\"")
					return null
				args.append(parse_expr())
				if is_sym(peek(), ","):
					take()
					continue
				break
		if fail: return null
		if not is_sym(peek(), ")"):
			syntax_error_at(peek(), "')'")
			return null
		take()
		return {"k": "call", "f": name, "args": args, "line": t.line}
	if lang == "python" and peek().t == "id" and peek().line == t.line and not peek().v in UNSUPPORTED_WORDS.python:
		# e.g. "awaken qi": a name followed directly by another name
		error("call_syntax", t.line, "SyntaxError: invalid syntax. Perhaps you forgot a comma or parentheses?", name)
		return null
	if "." in name:
		unsupported(t.line, "attributes and fields such as %s" % name)
		return null
	return {"k": "name", "n": name, "line": t.line}

func syntax_error_at(t: Dictionary, wanted := "") -> void:
	var line: int = t.line
	if t.t == "bad":
		unsupported(line, t.feature)
		return
	if t.t == "id" and t.v in UNSUPPORTED_WORDS[lang]:
		unsupported(line, word_feature(t.v))
		return
	if lang != "python" and (is_sym(t, "{") or is_sym(t, "}")):
		unsupported(line, "extra { } blocks (main's braces are already written)")
		return
	match lang:
		"python":
			error("syntax", line, "SyntaxError: invalid syntax" if wanted == "" else "SyntaxError: '(' was never closed", t.v)
		"c":
			error("syntax", line, ("error: expected %s before '%s' token" % [wanted, t.v]) if wanted != "" and t.t != "end" else ("error: expected expression before '%s' token" % t.v if t.t != "end" else "error: expected expression at end of input"), t.v)
		_:
			error("syntax", line, ("error: %s expected" % wanted) if wanted != "" else "error: illegal start of expression", t.v)

func missing_semicolon(line: int, next: Dictionary) -> void:
	if next.t == "bad" or (next.t == "id" and next.v in UNSUPPORTED_WORDS[lang]) or is_sym(next, "{") or is_sym(next, "}"):
		syntax_error_at(next)
		return
	if lang == "c":
		error("semicolon", line, "error: expected ';' before '%s'" % next.v if next.t != "end" else "error: expected ';' at end of input", "")
	else:
		error("semicolon", line, "error: ';' expected", "")

# ---------------------------------------------------------------- C/Java checks before running
func check_program(statements: Array) -> void:
	check_block(statements, {})

func check_condition(expr, declared: Dictionary, line: int) -> void:
	check_expr(expr, declared)
	if fail == null and lang == "java" and type_of(expr) != "boolean":
		error("type_mismatch", line, "error: an if/for condition must be boolean; compare with == or <", "")

func check_block(statements: Array, declared: Dictionary) -> void:
	for s: Dictionary in statements:
		match s.k:
			"if":
				check_condition(s.condition, declared, s.line)
				check_block(s.body, declared.duplicate())
			"for":
				var scoped := declared.duplicate()
				check_block([s.initial], scoped)
				check_condition(s.condition, scoped, s.line)
				check_block(s.body, scoped.duplicate())
				check_block([s.step], scoped)
			"decl":
				if s.init != null:
					check_expr(s.init, declared)
					expect_int(s.init, s.line, true)
				if fail == null and declared.has(s.name):
					error("redeclared", s.line, ("error: redefinition of '%s'" if lang == "c" else "error: variable %s is already defined in method main(String[])") % s.name, s.name)
				declared[s.name] = s.init != null
			"assign":
				check_expr(s.expr, declared)
				if fail == null and not declared.has(s.name): undeclared(s.name, s.line)
				expect_int(s.expr, s.line, false)
				declared[s.name] = true
			"expr":
				check_expr(s.expr, declared)
				if fail == null and s.expr.k != "call" and lang == "java": error("not_statement", s.line, "error: not a statement", "")
		if fail: return

func check_expr(e, declared: Dictionary) -> void:
	if e == null or fail: return
	match e.k:
		"name":
			if not declared.has(e.n): undeclared(e.n, e.line)
			elif not declared[e.n]:
				if lang == "java": error("uninitialized", e.line, "error: variable %s might not have been initialized" % e.n, e.n)
				else: error("uninitialized", e.line, "warning: '%s' is used uninitialized (its value is unpredictable)" % e.n, e.n)
		"call":
			for a in e.args: check_expr(a, declared)
			if fail: return
			var cmd = COMMANDS[lang].get(e.f)
			if cmd == null:
				unknown_function(e.f, e.line, declared)
				return
			if e.args.size() < cmd[1] or e.args.size() > cmd[2]:
				error("arity", e.line, ("error: too %s arguments to function '%s'" % ["many" if e.args.size() > cmd[2] else "few", e.f]) if lang == "c"
					else "error: method %s cannot be applied to given types" % e.f.get_slice(".", e.f.get_slice_count(".")-1), e.f)
				return
			for i in e.args.size():
				var t := type_of(e.args[i])
				if t == "void": void_value(e.line, false)
				elif cmd[0] in ["awaken", "channel", "bridge", "ward"] and t != "int":
					error("type_mismatch", e.line, ("error: passing argument %d of '%s' makes integer from pointer without a cast" % [i+1, e.f]) if lang == "c"
						else "error: incompatible types: %s cannot be converted to int" % t, e.f)
				elif cmd[0] == "printf" and i == 0 and t != "String":
					error("type_mismatch", e.line, "error: passing argument 1 of 'printf' makes pointer from integer without a cast", e.f)
		"bin", "cmp":
			check_expr(e.a, declared)
			check_expr(e.b, declared)
			if fail == null and e.k == "cmp" and e.get("op", "==") == "<" and (type_of(e.a) != "int" or type_of(e.b) != "int"):
				error("type_mismatch", e.line, "error: this comparison needs two whole numbers", "")
			if fail == null and type_of(e) == "invalid":
				if "void" in [type_of(e.a), type_of(e.b)]: void_value(e.line, false)
				else: error("type_mismatch", e.line, ("error: invalid operands to binary %s" if lang == "c" else "error: bad operand types for binary operator '%s'") % e.op, "")
		"neg":
			check_expr(e.a, declared)
			if fail == null and type_of(e.a) != "int":
				error("type_mismatch", e.line, "error: wrong type argument to unary minus" if lang == "c" else "error: bad operand type %s for unary operator '%s'" % [type_of(e.a), e.op], "")

func type_of(e) -> String:
	"""C/Java type of an expression. Every variable in this exercise is an int."""
	match e.k:
		"str": return "String"
		"lit": return "boolean" if e.v is bool else "<null>"
		"neg": return type_of(e.a)
		"cmp": return "int" if lang == "c" else "boolean"
		"bin":
			var a := type_of(e.a)
			var b := type_of(e.b)
			if lang == "java" and e.op == "+" and "String" in [a, b] and not "void" in [a, b]: return "String"
			return "int" if a == "int" and b == "int" else "invalid"
		"call":
			var cmd = COMMANDS[lang].get(e.f)
			return "void" if cmd != null and cmd[0] in VOID_ACTIONS else "int"
	return "int"

func expect_int(e, line: int, declaring: bool) -> void:
	if fail: return
	var t := type_of(e)
	if t == "int": return
	if lang == "java": error("type_mismatch", line, "error: incompatible types: %s cannot be converted to int" % t, "")
	elif t == "void": void_value(line, true)
	else: error("type_mismatch", line, "error: %s 'int' from 'char *' makes integer from pointer without a cast" % ("initialization of" if declaring else "assignment to"), "")

func void_value(line: int, stored: bool) -> void:
	if lang == "c": error("type_mismatch", line, "error: void value not ignored as it ought to be", "")
	elif stored: error("type_mismatch", line, "error: incompatible types: void cannot be converted to int", "")
	else: error("type_mismatch", line, "error: 'void' type not allowed here", "")

func undeclared(name: String, line: int) -> void:
	if lang == "c": error("undeclared", line, "error: '%s' undeclared (first use in this function)" % name, name)
	else: error("undeclared", line, "error: cannot find symbol (variable %s)" % name, name)

func unknown_function(name: String, line: int, known: Dictionary) -> void:
	"""A call to something that is not a command here: a typo, a variable, or real library code we do not run."""
	var parts := name.split(".")
	var guess := suggest(name)
	match lang:
		"python":
			if parts.size() > 1:
				if known.has(parts[0]): unsupported(line, "calling methods on values, such as %s()" % name)
				else: error("name_error", line, "NameError: name '%s' is not defined" % parts[0], parts[0])
			elif known.has(name): error("type_mismatch", line, "TypeError: '%s' object is not callable" % py_type(known[name].value), name)
			elif name in LIBRARY.python: unsupported(line, "%s() from Python's built-in functions (only print() and the game's commands are available here)" % name)
			else: error("unknown", line, "NameError: name '%s' is not defined%s" % [name, (". Did you mean: '%s'?" % guess) if guess != "" else ""], guess)
		"c":
			if parts.size() > 1: unsupported(line, "the . operator (structures)")
			elif known.has(name): error("unknown", line, "error: called object '%s' is not a function or function pointer" % name, name)
			elif name in LIBRARY.c: unsupported(line, "%s() from <stdio.h> (only printf() and the game's commands are available here)" % name)
			else: error("unknown", line, "error: implicit declaration of function '%s'%s" % [name, ("; did you mean '%s'?" % guess) if guess != "" else ""], guess)
		_:
			if parts.size() > 1 and known.has(parts[0]): error("type_mismatch", line, "error: int cannot be dereferenced", parts[0])
			elif name in ["System.out.printf", "System.out.format"] or (parts.size() > 1 and parts[0] in LIBRARY.java and guess == ""):
				unsupported(line, "%s from Java's standard library (only System.out.println, System.out.print and Sect are available here)" % name)
			elif parts.size() > 1 and not parts[0] in ["Sect", "System"] and guess == "": error("undeclared", line, "error: cannot find symbol (variable %s)" % parts[0], parts[0])
			else: error("unknown", line, "error: cannot find symbol (method %s)" % parts[-1], guess)

func suggest(name: String) -> String:
	var best := ""
	var best_d := 3
	for known: String in COMMANDS[lang]:
		var d := distance(name.to_lower(), known.to_lower())
		var short: String = known.get_slice(".", known.get_slice_count(".")-1)
		d = mini(d, distance(name.to_lower(), short.to_lower())+(0 if lang != "java" else 1))
		if d < best_d:
			best_d = d
			best = known
	return best

func distance(a: String, b: String) -> int:
	var prev := []
	for j in b.length()+1: prev.append(j)
	for i in a.length():
		var cur := [i+1]
		for j in b.length():
			cur.append(mini(mini(cur[j]+1, prev[j+1]+1), prev[j]+(0 if a[i] == b[j] else 1)))
		prev = cur
	return prev[b.length()]

# ---------------------------------------------------------------- execution
func execute_body(body: Array) -> void:
	var outer := vars.keys()
	for statement: Dictionary in body:
		execute(statement)
		if fail: break
	# C/Java block declarations do not leak outside their braces. Python has no block scope.
	if lang != "python":
		for name: String in vars.keys():
			if name not in outer: vars.erase(name)

func execute(s: Dictionary) -> void:
	if fail: return
	executed += 1
	if executed > MAX_EXECUTED:
		limit(s.line, "Stopped after 256 executed statements; shorten the loop or fix its counter.")
		return
	match s.k:
		"if":
			var condition := eval_expr(s.condition)
			if fail or not condition[0]: return
			# A bridge command must run inside a true guard derived from the actual seal reading.
			var guarded := 1 if (int(condition[1]) & 2) != 0 else 0
			guard_depth += guarded
			execute_body(s.body)
			guard_depth -= guarded
		"repeat":
			var count := eval_expr(s.count)
			if fail: return
			if not (count[0] is int):
				error("type_mismatch", s.line, "TypeError: range needs a whole-number count", "")
				return
			if count[0] > MAX_ITERATIONS:
				limit(s.line, "Not run: range count exceeds the 16-iteration lesson limit.")
				return
			loop_depth += 1
			for index in maxi(0, count[0]):
				vars[s.name] = {"value": index, "set": true, "reserve": false}
				execute_body(s.body)
				if fail: break
			loop_depth -= 1
		"for":
			var outer := vars.keys()
			execute(s.initial)
			var iterations := 0
			loop_depth += 1
			while fail == null:
				var condition := eval_expr(s.condition)
				if fail or not condition[0]: break
				if iterations >= MAX_ITERATIONS:
					limit(s.line, "Stopped after 16 loop iterations; check the counter update and stopping condition.")
					break
				iterations += 1
				execute_body(s.body)
				if fail: break
				execute(s.step)
			loop_depth -= 1
			for name: String in vars.keys():
				if name not in outer: vars.erase(name)
		"decl":
			var v := [null, false] if s.init == null else eval_expr(s.init)
			if fail: return
			vars[s.name] = {"value": v[0], "set": s.init != null, "reserve": v[1]}
		"assign":
			var v := eval_expr(s.expr)
			if fail: return
			vars[s.name] = {"value": v[0], "set": true, "reserve": v[1]}
		"expr":
			eval_expr(s.expr)
			if fail == null and s.expr.k != "call":
				flush()
				if lang == "python": emit("note", "(line %d computes a value but does nothing with it)" % (s.line+offset), s.line)
				else: emit("note", "%s:%d: warning: statement with no effect" % [file, s.line+offset], s.line)

func eval_expr(e) -> Array:
	"""Returns [value, source bits]: 1 for a Qi-reserve reading, 2 for a seal-charge reading."""
	if e == null or fail: return [null, false]
	match e.k:
		"num", "str", "lit": return [e.v, false]
		"neg":
			var a := eval_expr(e.a)
			if fail: return [null, false]
			if not (a[0] is int):
				error("type_mismatch", e.line, "TypeError: bad operand type for unary %s: '%s'" % [e.op, py_type(a[0])], "")
				return [null, false]
			return [a[0] if e.op == "+" else -a[0], a[1]]
		"name":
			if not vars.has(e.n):
				if lang == "python": error("name_error", e.line, "NameError: name '%s' is not defined" % e.n, e.n)
				else: undeclared(e.n, e.line)
				return [null, false]
			return [vars[e.n].value, vars[e.n].reserve]
		"cmp":
			var a := eval_expr(e.a)
			var b := eval_expr(e.b)
			if fail: return [null, false]
			var same: bool = typeof(a[0]) == typeof(b[0]) and a[0] == b[0]
			if e.get("op", "==") == "<":
				if not (a[0] is int and b[0] is int):
					error("type_mismatch", e.line, "This comparison needs two whole numbers.", "")
					return [null, false]
				same = a[0] < b[0]
			return [int(same) if lang == "c" else same, (int(a[1]) | int(b[1])) if stage >= 3 else false]
		"bin":
			var a := eval_expr(e.a)
			var b := eval_expr(e.b)
			if fail: return [null, false]
			if a[0] is int and b[0] is int:
				var v: int = a[0]+b[0] if e.op == "+" else (a[0]-b[0] if e.op == "-" else a[0]*b[0])
				if absi(v) > MAX_NUMBER:
					limit(e.line, "Stopped: %d is too large; this learning interpreter keeps whole numbers between -%d and %d." % [v, MAX_NUMBER, MAX_NUMBER])
					return [null, false]
				return [v, int(a[1]) | int(b[1])]
			if e.op == "+" and a[0] is String and b[0] is String: return [a[0]+b[0], false]
			if e.op == "+" and lang == "java": return [text_of(a[0])+text_of(b[0]), false]
			if lang == "python" and e.op == "*" and (a[0] is String or b[0] is String) and (a[0] is int or b[0] is int):
				unsupported(e.line, "repeating text with *")
			elif lang == "python" and e.op == "+" and a[0] is String:
				error("type_mismatch", e.line, "TypeError: can only concatenate str (not \"%s\") to str" % py_type(b[0]), "")
			elif lang == "python":
				error("type_mismatch", e.line, "TypeError: unsupported operand type(s) for %s: '%s' and '%s'" % [e.op, py_type(a[0]), py_type(b[0])], "")
			else: error("type_mismatch", e.line, "error: bad operand types for binary operator '%s'" % e.op, "")
			return [null, false]
		"call": return run_call(e)
	return [null, false]

func run_call(e: Dictionary) -> Array:
	var cmd = COMMANDS[lang].get(e.f)
	if cmd == null:
		unknown_function(e.f, e.line, vars)
		return [null, false]
	var action: String = cmd[0]
	if e.args.size() < cmd[1] or e.args.size() > cmd[2]:
		if lang == "python":
			error("arity", e.line, "TypeError: %s() takes %d positional argument%s but %d %s given" % [e.f, cmd[1], "" if cmd[1] == 1 else "s", e.args.size(), "was" if e.args.size() == 1 else "were"], e.f)
		else:
			error("arity", e.line, "error: wrong number of arguments to %s" % e.f, e.f)
		return [null, false]
	var args := []
	for a in e.args:
		var v := eval_expr(a)
		if fail: return [null, false]
		args.append(v)
	match action:
		"print":
			var parts := PackedStringArray()
			for a: Array in args: parts.append(text_of(a[0]))
			write(" ".join(parts)+"\n", e.line)
		"println":
			write((text_of(args[0][0]) if args.size() else "")+"\n", e.line)
		"print_no_newline":
			write(text_of(args[0][0]), e.line)
		"printf":
			var text := printf(args, e.line)
			if fail: return [null, false]
			write(text, e.line)
			return [text.length(), false]
		"charge":
			if stage < 3: return game_error(e.line, "restore the basin before reading the crossing seal", "seal_locked")
			# Source bits distinguish an actual seal reading (2) from the learner's Qi reserve (1).
			return [3, 2]
		"bridge":
			if stage != 3: return game_error(e.line, "the crossing belongs to the next main quest after the basin", "quest_order")
			if guard_depth == 0:
				rule("bridge_guard", e.line, "check the actual seal charge with an if condition before releasing the crossing.")
				return [null, false]
			if effects.bridge > 0: return game_error(e.line, "the crossing was already released in this run", "bridge_repeat")
			effects.bridge = 1
			flush()
			emit("sect", "[sect] Seal verified. The Silent Crossing is ready to open.", e.line)
		"ward":
			if stage != 4: return game_error(e.line, "release the crossing before tending the Threefold Ward", "quest_order")
			if loop_depth == 0:
				rule("ward_loop", e.line, "repeat the ward pulse using a for loop rather than copying the command.")
				return [null, false]
			if effects.ward >= 3:
				rule("ward_count", e.line, "the ward has exactly 3 stones; stop the loop after 3 pulses.")
				return [null, false]
			effects.ward += 1
			flush()
			emit("sect", "[sect] Ward pulse %d / 3 prepared." % effects.ward, e.line)
		"reserve":
			return [reserve, true]
		"awaken":
			var amount = args[0][0]
			if not (amount is int):
				return game_error(e.line, "awaken() needs a whole number of Qi", "awaken_type")
			if stage != 1 or effects.awaken > 0:
				return game_error(e.line, ("your Qi is already awake; this inscription uses %s" % ("Sect.qiReserve() and Sect.channelBasin()" if lang == "java" else "qi_reserve() and channel_basin()")) if stage != 1 else "awaken() may only be called once", "already_awake")
			if amount != FIRST_RESERVE:
				rule("wrong_amount", e.line, "the Mentor asked for a first reserve of exactly %d Qi, and %d was passed." % [FIRST_RESERVE, amount])
				return [null, false]
			if e.args[0].k != "name":
				rule("literal_arg", e.line, "this exercise asks you to prepare the Qi first: store the amount in a variable, then pass that variable.")
				return [null, false]
			effects.awaken = amount
			effects.awaken_from_variable = true
			reserve = amount
			flush()
			emit("sect", "[sect] Qi awakened. Reserve: %d" % amount, e.line)
		"channel":
			var amount = args[0][0]
			if not (amount is int):
				return game_error(e.line, "channel_basin() needs a whole number of Qi", "channel_type")
			if stage != 2:
				return game_error(e.line, "the basin cannot draw on Qi that is not awake yet; awaken your own Qi first", "not_awake")
			if amount <= 0:
				return game_error(e.line, "channel at least 1 Qi", "too_small")
			if amount > reserve:
				return game_error(e.line, "not enough Qi: your reserve is %d, but you tried to channel %d" % [reserve, amount], "not_enough")
			if amount < BASIN_NEEDS:
				return game_error(e.line, "the basin needs %d Qi to start; %d is not enough, and nothing was spent" % [BASIN_NEEDS, amount], "too_small")
			if not args[0][1]:
				rule("literal_channel", e.line, "this exercise asks you to channel the Qi you actually hold: pass the value read from %s." % ("Sect.qiReserve()" if lang == "java" else "qi_reserve()"))
				return [null, false]
			reserve -= amount
			effects.channel = amount
			effects.channel_from_reserve = true
			flush()
			emit("sect", "[sect] %d Qi channelled into the basin. Reserve: %d" % [amount, reserve], e.line)
	return [null, false]

func py_type(v) -> String:
	if v is bool: return "bool"
	if v is int: return "int"
	if v is String: return "str"
	return "NoneType"

func text_of(v) -> String:
	if v == null: return "None" if lang == "python" else "null"
	if v is bool: return ("True" if v else "False") if lang == "python" else ("true" if v else "false")
	return str(v)

func printf(args: Array, line: int) -> String:
	"""C printf with %d, %i, %s and %%."""
	var fmt: String = args[0][0]
	var out := ""
	var i := 1
	var k := 0
	while k < fmt.length():
		if fmt[k] != "%":
			out += fmt[k]
			k += 1
			continue
		var spec := fmt.substr(k+1, 1)
		if spec == "%": out += "%"
		elif spec in ["d", "i", "s"] and i < args.size():
			out += text_of(args[i][0])
			i += 1
		else:
			unsupported(line, "printf formats other than %d and %s with a matching value")
			return out
		k += 2
	return out
