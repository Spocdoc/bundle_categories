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

# note: eachSeries is used to avoid open file descriptor limit (may not be necessary)

getAst = fileMemoize (filePath, cb) ->
  async.waterfall [
    (next) -> utils.readCode filePath, next
    (code, next) -> next null, ug.parse code
  ], cb

recurseFilepath = (set, expression, filePath, cb) ->
  async.waterfall [
    (next1) -> getAst filePath, next1
    (ast, next1) -> recurseRequires set, expression, ast, next1
  ], cb

recurseAst = (set, expression, ast, cb) ->
  return cb() if (ast.seen ||= {})[expression]
  ast.seen[expression] = true

  requiredPaths = []

  utils.transformRequires (node) ->
    requiredPaths.push utils.resolveRequirePath node
    node

  fn = (requiredPath, next) ->
    dir = path.dirname requiredPath
    async.waterfall [
      (next1) -> glob 'browser*', cwd: dir, next1
      (fileNames, next1) ->
        if fileNames.length
          expressions set.splitExpression expression, fileNames.map (expr) -> expr = expr.replace(regexFirstWord,''); path.basename expr, path.extname expr
          i = -1

          fn1 = (expr, next2) ->
            ++i
            return next2() unless regexBrowserMin.test fileNames[i]
            try
              resolved = require.resolve("#{dir}/#{fileNames[i]}")
            catch _error
              return next2()
            recurseFilepath set, expr, resolved, next2

          async.eachSeries expressions, fn1, next1
        else
          recurseFilepath set, expression, requiredPath, next1
    ], next

  async.eachSeries requiredPaths, fn, cb

module.exports = (codeOrFilePaths, callback) ->
  set = new ExpressionSet
  emptyExpression = new Expression
  
  async.series [
    (next) ->
      if Array.isArray codeOrFilePaths
        async.eachSeries codeOrFilePaths, ((filePath, next1) -> recurseFilepath set, emptyExpression, filePath, next1), next
      else
        recurseAst set, emptyExpression, ug.parse(codeOrFilePaths), next

  ], (err) -> callback err, set.toArray()

