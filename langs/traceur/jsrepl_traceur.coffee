class @JSREPL::Engines::Traceur
  constructor: (input, output, @result, @error, @sandbox, ready) ->
    @sandbox.console.log = (obj) => output obj + '\n'
    @sandbox.console.dir = (obj) => output @sandbox._inspect(obj) + '\n'
    @sandbox.console.read = input
    @traceur = @sandbox.traceur
    ready()

  Destroy: ->

  Eval: (command) ->
    # Compile.
    try
      source = @_Compile command
    catch e
      @error e
      return

    # Evaluate.
    try
      @result @sandbox._inspect @sandbox.eval source
    catch e
      @error e

  GetNextLineIndent: (command) ->
    # Check if it compiles.
    try
      @_Compile command
      last_line = command.split('\n')[-1..][0]
      # If current line is indented, we may still want to continue.
      return if /^\s+/.test last_line then 0 else false
    catch e
      if /[\[\{\(]$/.test command
        # A block or an opening brace, bracket or paren; indent.
        return 1
      else
        return 0

  _Compile: (command) ->
    errors = []
    reporter = new @traceur.util.ErrorReporter
    reporter.reportMessageInternal = (location, kind, format, args) ->
      i = 0
      message = format.replace /%s/g, -> return args[i++]
      errors.push if location then "#{location}: #{message}" else message

    project = new @traceur.semantics.symbols.Project
    project.addFile new @traceur.syntax.SourceFile 'REPL', command
    res = @traceur.codegeneration.Compiler.compile reporter, project, false

    if reporter.hadError()
      throw new Error errors.join '\n'
    else
      return @traceur.codegeneration.ProjectWriter.write res
