import std/[os, json, strutils]
import argparse
import request

proc cli*() =
    var parser = newParser:
        help("Starts GitlabCI pipelines from the CLI. Tries to auto detect things")
        option("-k", "--insecure",
                help = "Allow insecure server connections when using SSL")

        command("run"):
            option("-b", "--branch", help = "The name of the branch. Will use current branch if not provided")
            option("-p", "--api-key", help = "API key to use for authentication",
                    env = "GITLAB_API_KEY")
            arg("variables", nargs = -1)
            run:
                let remote = getRemote()
                let branch = (if len(opts.branch) >
                        0: opts.branch else: getBranch())
                let project_id = getProjectID(remote, opts.api_key)
                let token = getTriggerToken(project_id, opts.api_key)
                echo triggerPipeline(opts.variables, token, project_id, branch)

    try:
        parser.run(commandLineParams())

    except ShortCircuit as e:
        if e.flag == "argparse_help":
            echo parser.help
            quit(0)
    except UsageError as e:
        echo parser.help
        stderr.writeLine getCurrentExceptionMsg()
        quit(1)
