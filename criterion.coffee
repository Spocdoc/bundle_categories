ops = require './ops'
_ = require 'lodash-fork'

regex = /^(-)?(\w+?)([<>][=]?)?(\d+)?$/
NEG = 1
CAT = 2
OP = 3
NUM = 4

module.exports = (str) ->
  return null unless m = regex.match str

  catMatch = new RegExp "^#{_.regexpEscape m[CAT]}(\\d+)?$"

  if m[NUM]
    unless m[OP]
      opMatch = (num) -> num is m[NUM]
    else
      opMatch = (num) -> eval "#{num} #{m[OP]} #{m[NUM]}"

  return {
    toString: -> str
    neg: !!m[NEG]
    cat: m[CAT]
    op: ops[m[OP]]
    num: m[NUM] && (m[NUM]|0)
    match: (category) ->
      matches = (n = catMatch.exec category) and (!m[NUM]? or opMatch? n[1])
      return if m[NEG] then 0|!!matches else !!matches
  }





