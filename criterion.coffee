ops = require './ops'
_ = require 'lodash-fork'

regex = /^(-)?(\w+?)([<>][=]?)?(\d+)?$/
NEG = 1
CAT = 2
OP = 3
NUM = 4

module.exports = class Criterion
  constructor: (str) ->
    [str, words...] = str.split ' '

    if m = str.match regex
      @cat = m[CAT]
      @_normalize m[NEG] || '', ops[m[OP]] || '', m[NUM] && (m[NUM]|0)
    else
      @cat = @op = @neg = ''
      @impossible = true

    @merge word for word in words

    # TODO
    # catMatch = new RegExp "^#{_.regexpEscape @cat}(\\d+)?$"
    # if @num
    #   unless @op
    #     opMatch = (num) -> num is @num
    #   else
    #     opMatch = (num) -> eval "#{num} #{@op} #{@num}"
    # @test = (category) ->
    #   matches = (n = catMatch.exec category) and (!@num? or opMatch? n[1])
    #   return if @neg then 0|!!matches else !!matches

  merge: (rhs) ->
    if rhs
      if @impossible or rhs.impossible or rhs.neg isnt @neg
        @impossible = true
      else unless @neg
        @lower = lower if (lower = rhs.lower)? and (!@lower? or lower > @lower)
        @upper = upper if (upper = rhs.upper)? and (!@upper? or upper < @upper)
        @impossible = true if @upper? and @lower? and @upper < @lower
    return !@impossible

  clone: ->
    new Criterion @toString()

  @compare: (lhs, rhs) ->
    if lhs.neg isnt rhs.neg
      if lhs.neg
        -1
      else
        1
    else if lhs.cat isnt rhs.cat
      lhs.cat.localeCompare rhs.cat
    else if (lhs1 = 0|lhs.num) isnt (rhs1 = 0|rhs.num)
      if lhs1 < rhs1
        -1
      else
        1
    else if (lhs1 = lhs.op.toString()) isnt rhs1 = rhs.op.toString()
      lhs1.localeCompare rhs1
    else
      0

  toString: ->
    return '' if @impossible
    return "#{@neg}#{@cat}#{@lower ? ''}" if `this.upper == this.lower`
    str = if @lower? then "#{@cat}>=#{@lower}" else ''
    str += "#{if str then ' ' else ''}#{@cat}<=#{@upper}" if @upper?
    str

  # - removes negation if possible
  # - changes <= into < and > into >=
  _normalize: (neg, op, num) ->
    if @cat is 'release'
      @cat = 'debug'
      neg = if neg then '' else '-'

    if op
      if neg
        op = op.inverse
        neg = ''
      switch op.toString()
        when '>='
          @lower = num
        when '<='
          @upper num
        when '<'
          @upper = num-1
        when '>'
          @lower = num+1
    else if num?
      @upper = @lower = num

    @neg = neg
    this

