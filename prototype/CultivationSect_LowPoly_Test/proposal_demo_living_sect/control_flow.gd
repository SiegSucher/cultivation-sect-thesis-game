extends RefCounted
## Parser extension for the two main quests. Expressions and ordinary statements still use
## the original interpreter. Every block, loop and execution has an explicit small limit.
var runner: RefCounted
var statements := 0

func _init(owner: RefCounted) -> void:
	runner = owner

func require_symbol(symbol: String) -> bool:
	if not runner.is_sym(runner.peek(), symbol):
		runner.error("block_syntax", runner.peek().line, "Expected '%s' here." % symbol, "")
		return false
	runner.take()
	return true

func sequence(indent := 0, braced := false, level := 0) -> Array:
	var result: Array = []
	if level > 8:
		runner.limit(runner.peek().line, "Not run: at most 8 nested control blocks are supported.")
		return result
	while runner.fail == null:
		while runner.peek().t == "nl": runner.take()
		var token: Dictionary = runner.peek()
		if token.t == "end":
			if braced: runner.error("block_syntax", token.line, "Expected '}' to close this block.", "")
			return result
		if braced and runner.is_sym(token, "}"):
			runner.take()
			return result
		if runner.lang == "python" and token.first:
			if token.col < indent: return result
			if token.col > indent:
				runner.error("indent", token.line, "IndentationError: unexpected indent", "")
				return result
		if runner.is_sym(token, ";"):
			runner.take()
			continue
		statements += 1
		if statements > runner.MAX_STATEMENTS:
			runner.limit(token.line, "Not run: at most 40 statements are supported.")
			return result
		if token.t == "id" and token.v in ["if", "for"]:
			result.append(control(level))
			continue
		var statement: Dictionary = runner.parse_statement()
		if runner.fail: return result
		result.append(statement)
		if runner.lang == "python":
			if runner.is_sym(runner.peek(), ";"): runner.take()
			elif runner.peek().t not in ["nl", "end"]:
				runner.syntax_error_at(runner.peek())
		else:
			if not require_symbol(";"): return result
	return result

func body(parent: Dictionary, level: int) -> Array:
	if runner.lang != "python":
		if not require_symbol("{"): return []
		return sequence(0, true, level+1)
	if not require_symbol(":"): return []
	if runner.peek().t != "nl":
		runner.error("block_syntax", parent.line, "Put the body on the next line and indent it with four spaces.", "")
		return []
	while runner.peek().t == "nl": runner.take()
	if runner.peek().t == "end" or runner.peek().col <= parent.col:
		runner.error("indent", parent.line, "IndentationError: expected an indented block", "")
		return []
	return sequence(runner.peek().col, false, level+1)

func control(level: int) -> Dictionary:
	var token: Dictionary = runner.take()
	if token.v == "if":
		if runner.lang != "python" and not require_symbol("("): return {}
		var condition = runner.parse_expr()
		if runner.lang != "python" and not require_symbol(")"): return {}
		return {"k": "if", "condition": condition, "body": body(token, level), "line": token.line}
	if runner.lang == "python":
		var variable: Dictionary = runner.take()
		if variable.v in runner.UNSUPPORTED_WORDS.python or variable.v in ["True", "False", "None"]:
			runner.error("syntax", token.line, "SyntaxError: a keyword cannot be the loop variable", "")
			return {}
		if variable.t != "id" or runner.peek().v != "in":
			runner.error("loop_syntax", token.line, "Use: for seal in range(count):", "")
			return {}
		runner.take()
		if runner.take().v != "range":
			runner.error("loop_syntax", token.line, "This lesson supports for loops with range(count).", "")
			return {}
		if not require_symbol("("): return {}
		var count = runner.parse_expr()
		if not require_symbol(")"): return {}
		return {"k": "repeat", "name": variable.v, "count": count, "body": body(token, level), "line": token.line}
	if not require_symbol("("): return {}
	var initial: Dictionary = runner.parse_statement()
	if runner.fail or not require_symbol(";"): return {}
	if initial.k not in ["decl", "assign"]:
		runner.error("loop_syntax", token.line, "Start the for loop with an integer counter, such as int seal = 0.", "")
		return {}
	var condition = runner.parse_expr()
	if not require_symbol(";"): return {}
	var step: Dictionary = runner.parse_statement()
	if runner.fail or not require_symbol(")"): return {}
	if step.k != "assign":
		runner.error("loop_syntax", token.line, "Update the counter with an assignment, such as seal = seal + 1.", "")
		return {}
	return {"k": "for", "initial": initial, "condition": condition, "step": step, "body": body(token, level), "line": token.line}
