utils = require 'js_ast_utils'
Expression = require '../expression'
ExpressionSet = require '../expression_set'
fileMemoize = require 'file_memoize'
path = require 'path'
glob = require 'glob'
async = require 'async'
ug = require 'uglify-js-fork'
regexFirstWord = /^\S*\s*/
regexBrowserMin = /^\S*(?:[-\._]min)\S*\b/
debug = require('debug-fork') "bundle_categories:requires"

getAst = fileMemoize (filePath, cb) ->
  async.waterfall [
    (next) -> utils.readCode filePath, next
    (code, next) -> next null, ug.parse code, filename: filePath
  ], cb

recurseFilepath = (set, filePath, cb) ->
  async.waterfall [
    (next1) -> getAst filePath, next1
    (ast, next1) -> recurseAst set, ast, next1
  ], cb

recurseAst = (set, ast, cb) ->
  debug ast.start.file

  seen = ast.seen ||= {}
  unseen = 0
  for id, expr of set.expressions
    debug "    #{expr}"
    unless seen[expr]
      ++unseen
      seen[expr] = true
  unless unseen
    debug "    no unseen so returning"
    return cb()

  requiredPaths = []

  utils.transformRequires ast, (node) ->
    requiredPaths.push utils.resolveRequirePath node
    node

  fn = (requiredPath, next) ->
    dir = path.dirname requiredPath
    async.waterfall [
      (next1) -> glob 'browser*', cwd: dir, next1
      (fileNames, next1) ->
        unless fileNames.length
          recurseFilepath set, requiredPath, next1
        else
          fn1 = (id, next2) ->
            expressions = set.splitExpression set.expressions[id], fileNames.map (expr) -> expr = expr.replace(regexFirstWord,''); path.basename expr, path.extname expr

            i = -1

            fn2 = (expr, next3) ->
              ++i
              return next3() if !expr or regexBrowserMin.test fileNames[i]
              try
                resolved = require.resolve("#{dir}/#{fileNames[i]}")
              catch _error
                return next3()
              recurseFilepath new ExpressionSet(set, expr), resolved, next3

            async.eachSeries expressions, fn2, next2

          async.eachSeries Object.keys(set.expressions), fn1, next1

    ], next

  async.eachSeries requiredPaths, fn, cb

module.exports = (codeOrFilePaths, callback) ->
  set = new ExpressionSet(new Expression)

  async.series [
    (next) ->
      if Array.isArray codeOrFilePaths
        async.eachSeries codeOrFilePaths, ((filePath, next1) -> recurseFilepath set, filePath, next1), next
      else
        recurseAst set, ug.parse(codeOrFilePaths), next

  ], (err) -> callback err, set.toArray()

