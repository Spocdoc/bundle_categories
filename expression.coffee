Criterion = require './criterion'
regexWords = /\S+/g

# OK to extend array. this is V8-only code
module.exports = class Expression extends Array
  constructor: (expression) ->
    super
    @criteria = {}
    @add expression if expression

  toString: -> @join ' '

  add: (expression) ->
    if typeof expression is 'string'
      words = expression.match regexWords
      expression = []
      expression[i] = new Criterion word for word,i in words
    else unless Array.isArray
      expression = [expression]

    added = 0

    for c in expression when !@criteria[(c = if c instanceof Criterion then c else new Criterion c).normalize()]
      @push @criteria[c] = c
      ++added

    @sort Criterion.compare if added
    added

