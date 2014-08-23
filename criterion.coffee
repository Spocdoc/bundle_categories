ops = require './ops'
_ = require 'underscore-folly'
maxInt = 9007199254740992
minInt = -9007199254740992

regex = /^(-)?(\w+?)([<>][=]?)?(\d+)?$/
NEG = 1
CAT = 2
OP = 3
NUM = 4

module.exports = class Criterion
  constructor: (str) ->
    [str, words...] = (str||'').split ' '

    if m = str.match regex
      @cat = m[CAT]
      @_normalize m[NEG] || '', m[OP], m[NUM] && (m[NUM]|0)
    else
      @cat = @op = @neg = ''
      @impossible = true

    @merge word for word in words

    @test = (rhs) ->
      return !!@neg unless rhs
      rhs = new Criterion rhs unless rhs instanceof Criterion
      return true if @neg and rhs.neg
      lhsLower = @lower
      lhsUpper = @upper
      if @neg
        return false if !lhsLower? and !lhsUpper?
        ++lhsLower if lhsLower
        --lhsUpper if lhsUpper
      rhsLower = rhs.lower
      rhsUpper = rhs.upper
      if rhs.neg
        return false if !rhsLower? and !rhsUpper?
        ++rhsLower if rhsLower
        --rhsUpper if rhsUpper

      lhsLower ?= minInt
      rhsLower ?= minInt
      lhsUpper ?= maxInt
      rhsUpper ?= maxInt
      (lhsLower <= rhsUpper) and (lhsUpper >= rhsLower)

  merge: (rhs) ->
    if rhs
      return !(@impossible = true) if @impossible or rhs.impossible
      {upper,lower} = rhs

      if rhs.neg isnt @neg
        if rhs.neg
          return !(@impossible = true) if !upper? and !lower?
          ++lower if lower?
          --upper if upper?
        else
          return !(@impossible = true) if !@upper? and !@lower?
          @neg = ''
          ++@lower if @lower?
          --@upper if @upper?

      @lower = lower if lower? and (!@lower? or lower > @lower)
      @upper = upper if upper? and (!@upper? or upper < @upper)

      if @upper? and @lower?
        if @upper < @lower
          @impossible = true
        else if @neg and @upper is @lower
          delete @upper
          delete @lower

    return !@impossible

  clone: ->
    new Criterion @toString()

  @compare: (lhs, rhs) ->
    if lhs.neg isnt rhs.neg
      if lhs.neg then -1 else 1
    else if lhs.cat isnt rhs.cat
      if lhs.cat < rhs.cat then -1 else if lhs.cat > rhs.cat then 1 else 0
    else if (lhs1 = 0|lhs.lower) isnt (rhs1 = 0|rhs.lower)
      if lhs1 < rhs1 then -1 else 1
    else if (lhs1 = 0|lhs.upper) isnt (rhs1 = 0|rhs.upper)
      if lhs1 < rhs1 then -1 else 1
    else
      0

  toString: ->
    return '' if @impossible
    return "#{@neg}#{@cat}#{@lower ? ''}" if `this.upper == this.lower`
    str = if @lower? then "#{@neg}#{@cat}#{if @neg then '<=' else '>='}#{@lower}" else ''
    str += "#{if str then ' ' else ''}#{@neg}#{@cat}#{if @neg then '>=' else '<='}#{@upper}" if @upper?
    str

  # - removes negation if possible
  # - changes <= into < and > into >=
  _normalize: (neg, op, num) ->
    if @cat is 'release'
      @cat = 'debug'
      neg = if neg then '' else '-'

    if op
      switch op.charAt(0)
        when '>'
          ++num unless op.charAt(1) is '='
          if neg
            @upper = num
          else
            @lower = num

        when '<'
          --num unless op.charAt(1) is '='
          if neg
            @lower = num
          else
            @upper = num

    else if num?
      throw new Error "Can't create a hole in Criterion (adding [#{neg}#{@cat}#{num}])" if neg
      @upper = @lower = num

    @neg = neg
    this

