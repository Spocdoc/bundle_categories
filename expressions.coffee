Expression = requrie './expression'

# assumes only only 'ie' expressions
module.exports = class Expressions
  constructor: ->
    @length = 0
    @expressions = {}

  add: do ->
    regex = /\S+/
    (expression) ->
      return false if 0 is (words = regex.exec expression).length

      c = new Criterion words[0]
      throw new Error "only 'IE' criteria are supported" unless c.cat is 'ie'

      c.normalize()

      if @criteria[c]
        false
      else
        @[@length++] = @criteria[c] = c
        true

