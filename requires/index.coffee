utils = require 'js_ast_utils'
Expression = require '../expression'
ExpressionSet = require '../expression_set'
fileMemoize = require 'file_memoize'
path = require 'path'
glob = require 'glob'
async = require 'async'
ug = require 'uglify-js-fork'
regexFirstWord = /^\S*\s*/
regexBrowserMin = /^\S*(?:[-\._]min)\b/
regexMin = /(?:[-\._]min)\b/
require 'debug-fork'
debug = global.debug "bundle_categories:requires"

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

recurseRequiredPath = (set, requiredPath, cb) ->
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

  async.eachSeries requiredPaths, ((requiredPath, next) -> recurseRequiredPath set, requiredPath, next), cb

module.exports = (codeOrFilePaths, callback) ->
  set = new ExpressionSet(new Expression)

  async.series [
    (next) ->
      if Array.isArray codeOrFilePaths
        async.eachSeries codeOrFilePaths, ((filePath, next1) -> recurseRequiredPath set, require.resolve(filePath), next1), next
      else
        recurseAst set, ug.parse(codeOrFilePaths), next

  ], (err) -> callback err, set.toArray()


module.exports.resolveBrowser = (filePath, expression, cb) ->
  expression = new Expression expression unless expression instanceof Expression
  dir = path.dirname filePath
  ret = []
  isMin = false

  async.waterfall [
    (next1) -> glob 'browser*', cwd: dir, next1

    (fileNames, next1) ->
      unless fileNames.length
        ret.indexPath = filePath
        cb null, ret
      else
        expressions = fileNames.map (expr) -> expr = expr.replace(regexFirstWord,''); new Expression path.basename(expr, path.extname expr)
        for expr,i in expressions when expression.test expr
          filePath = "#{dir}/#{fileNames[i]}"
          unless isMin = regexBrowserMin.test fileNames[i]
            try
              ret.indexPath = require.resolve filePath
            catch _error
          return glob '*.js', cwd: filePath, next1
        cb null, ret

    (minFiles, next1) ->
      for fileName in minFiles when isMin or regexMin.test fileName
        ret.push "#{filePath}/#{fileName}"
      cb null, ret

  ], cb
