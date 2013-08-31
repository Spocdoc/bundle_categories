_ = require 'lodash-fork'
Expression = require './expression'

# assumes only only 'ie' expressions
module.exports = class ExpressionSet
  constructor: (arr) ->
    @expressions = {}

    if arr
      for expr in arr
        expr = new Expression expr unless expr instanceof Expression
        @expressions[expr.id ||= _.makeId()] = expr

  # others must be a "complete" set of alternative expressions.
  # they're mutated and returned
  splitExpression: (expr, others) ->
    delete @expressions[id] if expr.id?
    expr = new Expression expr unless expr instanceof Expression
    for e,i in others
      e = others[i] = new Expression e unless e instanceof Expression
      e.id ||= _.makeId()
      e.merge expr
      @expressions[e.id] = e unless e.impossible
    others

  toArray: ->
    # to ensure uniqueness
    obj = {}
    obj[expr] = expr for id,expr of @expressions

    arr = []; i = 0
    arr[i++] = expr for str, expr of obj
    arr

