#!/usr/bin/env coffee#--nodejs --debug-brk

Expression = require '../expression'
debugger

a = new Expression
a.add 'ie'
a.add 'ie<11'
a.add 'ie>=10'
a.add 'release'
a.add 'ie>6'
console.log ''+a

