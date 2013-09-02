_ = require 'lodash-fork'
Expression = require './expression'

# assumes only only 'ie' expressions
module.exports = class ExpressionSet
  constructor: (arr) ->
    @expressions = {}

    if arr instanceof ExpressionSet
      @parent = arr
      arr = arguments[1]

    if Array.isArray arr
      @add expr for expr in arr
    else if arr
      @add arr

  add: (expr) ->
    expr = new Expression expr unless expr instanceof Expression
    @expressions[expr.id ||= _.makeId()] = expr
    this

  # others must be a "complete" set of alternative expressions.
  # they're mutated and returned
  splitExpression: (expr, others) ->
    if expr.id?
      delete @expressions[expr.id]
      parent = this
      delete parent.expressions[expr.id] while parent = parent.parent

    expr = new Expression expr unless expr instanceof Expression
    for e,i in others
      e = others[i] = new Expression e unless e instanceof Expression
      e.id ||= _.makeId()
      if e.merge expr
        @expressions[e.id] = e
        parent = this
        parent.expressions[e.id] = e while parent = parent.parent
      else
        others[i] = undefined

    others

  toArray: ->
    arr = []; i = 0
    arr[i++] = expr for id, expr of @expressions
    arr

