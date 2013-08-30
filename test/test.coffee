#!/usr/bin/env coffee#--nodejs --debug-brk

Expression = require '../expression'
debugger

a = new Expression
a.add 'ie>7'
a.add 'ie<10'
a.add 'ie>=7'
a.add '-debug'
console.log ''+a

