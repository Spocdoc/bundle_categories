ops = require './ops'
_ = require 'lodash-fork'

regex = /^(-)?(\w+?)([<>][=]?)?(\d+)?$/
NEG = 1
CAT = 2
OP = 3
NUM = 4

module.exports = class Criterion
  constructor: (str) ->
    if m = regex.exec str
      @neg = m[NEG] || ''
      @cat = m[CAT]
      @op = ops[m[OP]] || ''
      @num = m[NUM] ? ''
      @num ||= 0 if @op
    else
      @cat = @op = @num = @neg = ''

    catMatch = new RegExp "^#{_.regexpEscape @cat}(\\d+)?$"

    if @num
      unless @op
        opMatch = (num) -> num is @num
      else
        opMatch = (num) -> eval "#{num} #{@op} #{@num}"

    @test = (category) ->
      matches = (n = catMatch.exec category) and (!@num? or opMatch? n[1])
      return if @neg then 0|!!matches else !!matches

  empty: -> !!@cat

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

  toString: -> "#{@neg}#{@cat}#{@op}#{@num}"

  # - removes negation if possible
  # - changes <= into < and > into >=
  normalize: ->
    if @cat is 'release'
      @cat = 'debug'
      @neg = if @neg then '' else '-'

    if @neg
      if @op
        @op = @op.inverse
        @neg = ''

    switch @op.toString()
      when '>=','<','' then
      when '<='
        ++@num
        @op = ops['<']
      when '>'
        ++@num
        @op = ops['>=']

    this

