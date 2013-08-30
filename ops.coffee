module.exports = ops =
  ">": toString: -> ">"
  "<=": toString: -> "<="
  "<": toString: -> "<"
  ">=": toString: -> ">="

ops[">"].inverse = ops["<="]
ops["<="].inverse = ops[">"]
ops["<"].inverse = ops[">="]
ops[">="].inverse = ops["<"]
