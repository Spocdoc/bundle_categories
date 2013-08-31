Criterion = require './criterion'
regexWords = /\S+/g
regexSpaces = /\ +/

# OK to extend array. this is V8-only code
module.exports = class Expression extends Array
  constructor: (expression) ->
    super
    @criteria = {}
    @merge expression if expression

  toString: ->
    return '' if @impossible
    @join ' '

  test: (rhs) ->
    rhs = new Expression rhs unless rhs instanceof Expression
    for c in this
      return false unless c.test rhs.criteria[c.cat]
    true

  clone: ->
    result = new Expression @toString()
    result.impossible = true if @impossible
    result

  merge: (expression) ->
    return false if @impossible

    if typeof expression is 'string'
      words = expression.match regexWords
      expression = []
      expression[i] = new Criterion word for word,i in words
    else unless Array.isArray
      expression = [expression]

    added = 0

    for c in expression
      c = if c instanceof Criterion then c else new Criterion c
      if current = @criteria[c.cat]
        current.merge c
      else
        current = @criteria[c.cat] = c
        @push c
        ++added
      @impossible = true if current.impossible

    @sort Criterion.compare if added
    return !@impossible

