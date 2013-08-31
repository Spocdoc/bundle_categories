#!/usr/bin/env coffee#--nodejs --debug-brk

Expression = require '../expression'
ExpressionSet = require '../expression_set'
debugger

# a = new Expression
# a.merge 'ie'
# a.merge 'ie<11'
# a.merge 'ie>=10'
# a.merge 'release'
# a.merge 'ie<6'
# console.log ''+a

a = [
  new Expression '-debug ie>8'
]

for expr in ExpressionSet.complete a
  console.log expr.toString()

