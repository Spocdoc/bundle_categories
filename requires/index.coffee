_ = require 'lodash-fork'
utils = require 'js_ast_utils'
Expression = require '../expression'
ExpressionSet = require '../expression_set'
path = require 'path'
glob = require 'glob'
async = require 'async'
resolve = require 'resolve-fork'
regexFirstWord = /^\S*\s*/
regexBrowserMin = /^\S*(?:[-\._]min)\b/
regexMin = /(?:[-\._]min)\b/

recurseFilePath = (set, filePath) ->
  for requiredPath in requiredPaths = utils.getRequiresSync filePath
    recurseRequiredPath set, requiredPath
  return

recurseRequiredPath = do ->
  cacheTimes = {}
  cache = {}

  (set, requiredPath) ->
    if cacheTimes[requiredPath] is mtime = _.getModTimeSync requiredPath
      {dir,fileNames,subexpressions} = cache[requiredPath]
    else
      dir = path.dirname requiredPath
      fileNames = glob.sync 'browser*', cwd: dir

      subexpressions = []
      for fileName, i in fileNames
        expr = fileName.replace regexFirstWord,''
        subexpressions[i] = path.basename expr, path.extname expr
        if regexBrowserMin.test fileName
          delete fileNames[i]
        else
          try
            fileNames[i] = resolve "#{dir}/#{fileName}"
          catch _error
            delete fileNames[i]

      cacheTimes[requiredPath] = mtime
      cache[requiredPath] = {dir,fileNames,subexpressions}

    return recurseFilePath set, requiredPath unless fileNames.length

    for id, expr of set.expressions
      for expr, i in set.splitExpression expr, subexpressions.concat() when expr and resolved = fileNames[i]
        recurseFilePath new ExpressionSet(set, expr), resolved

    return

module.exports = (codeOrFilePaths) ->
  set = new ExpressionSet(new Expression)
  codeOrFilePaths = utils.getCodeRequires(codeOrFilePaths) unless Array.isArray codeOrFilePaths
  recurseRequiredPath set, resolve(filePath) for filePath in codeOrFilePaths
  set.toArray()

module.exports.resolveBrowser = (filePath, expression) ->
  dir = path.dirname filePath
  ret = []

  unless (fileNames = glob.sync 'browser*', cwd: dir).length
    ret.indexPath = filePath
    return ret

  expression = new Expression expression unless expression instanceof Expression

  for fileName,i in fileNames
    expr = fileName.replace regexFirstWord,''
    expr = new Expression path.basename expr, path.extname expr
    continue unless expr.test expression

    filePath = "#{dir}/#{fileName}"

    unless isMin = regexBrowserMin.test fileName
      try
        ret.indexPath = require.resolve filePath
      catch _error

    minFiles = glob.sync '*.js', cwd: filePath
    ret.push "#{filePath}/#{fileName}" for fileName in minFiles when isMin or regexMin.test fileName

  ret
