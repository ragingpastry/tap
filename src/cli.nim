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
            option("-u", "--url", help = "The API endpoint for Gitlab. Defaults to the origin")
            arg("variables", nargs = -1)
            run:
                let remote = getRemote()
                let api_endpoint = (if len(opts.url) >
                        0: opts.url else: getApiEndpoint(remote))
                var gl_client = GitlabClient(api_endpoint: api_endpoint,
                        api_key: opts.api_key)
                let project_path = getProjectPath(remote)
                getProjectID(project_path, gl_client)
                let branch = (if len(opts.branch) >
                        0: opts.branch else: getBranch())

                echo triggerPipeline(opts.variables, gl_client, branch)

    try:
        parser.run(commandLineParams())

    except ShortCircuit as e:
        if e.flag == "argparse_help":
            echo parser.help
            quit(0)
    except UsageError:
        echo parser.help
        stderr.writeLine getCurrentExceptionMsg()
        quit(1)
