Criterion = require './criterion'
regexWords = /\S+/g

# OK to extend array. this is V8-only code
module.exports = class Expression extends Array
  constructor: (expression) ->
    super
    @criteria = {}
    @add expression if expression

  toString: -> @join ' '

  clone: ->
    # TODO 

  add: (expression) ->
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
      if current.impossible
        @impossible = true
        @criteria = {}
        @length = 0
        return false

    @sort Criterion.compare if added
    true

