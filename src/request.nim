import std/[osproc, httpclient, strutils, net, strformat, json, uri]

type
    GitlabClient* = object
        ## A container for Gitlab things that we pass between functions

        api_endpoint*: string
        api_key*: string
        project_id*: int
        trigger_token*: string

proc getRemote*(): string =
    ## Returns the origin remote of a git repository

    var remote = execCmdEx("git remote get-url origin")[0]
    stripLineEnd(remote)

    result = remote

proc getApiEndpoint*(remote: string): string =
    ## Parses a remote string (like origin) and builds
    ## an API endpoint for Gitlab. Currently this is hardcoded
    ## to use /api/v4
    ## In the future we could also make this configurable

    let scheme = parseUri(remote).scheme
    let host = parseUri(remote).hostname
    let port = parseUri(remote).port

    let endpoint = scheme & "://" & host & port & "/api/v4"
    result = endpoint

proc getProjectpath*(remote: string): string =
    ## Parses a remote string (like origin) and returns
    ## the path of the project.
    ## For example if your remote is: https://gitlab.com/test/project.git
    ## then the project path returned would be test/project

    let project_path = parseUri(remote).path.split(".git")[0]
    result = project_path[1 .. ^1]

proc getBranch*(): string =
    ## Returns the current HEAD of the git project in the current working directory

    var branch = execCmdEx("git rev-parse --abbrev-ref HEAD")[0]
    stripLineEnd(branch)
    result = branch

proc getProjectID*(project_url: string, gl_client: var GitlabClient) =
    ## Gets a project ID based on a project URL from the
    ## Gitlab API

    let encoded_url = encodeUrl(project_url)
    var client = newHttpClient(sslContext = newContext(
            verifyMode = CVerifyNone))
    client.headers = newHttpHeaders({"PRIVATE-TOKEN": gl_client.api_key})
    try:
        let response = client.getContent(fmt"{gl_client.api_endpoint}/projects/{encoded_url}")
        let project_id = parseJSON(response)["id"].getInt()

        gl_client.project_id = project_id
    except HttpRequestError as e:
        echo "Failed to get project ID: ", e.msg
        quit(1)
    except:
        echo "Unknown exception!"
        raise

proc setTriggerToken*(gl_client: var GitlabClient) =
    ## Creates a Pipeline Trigger token in the Gitlab project
    var client = newHttpClient(sslContext = newContext(
            verifyMode = CVerifyNone))
    client.headers = newHttpHeaders({"PRIVATE-TOKEN": gl_client.api_key})
    var data = newMultipartData()
    data["description"] = "Token created via tap CLI"

    try:
        let response = client.postContent(
                fmt"{gl_client.api_endpoint}/projects/{gl_client.project_id}/triggers",
                 multipart = data)
        gl_client.trigger_token = parseJSON(response)["token"].getStr()
    except HttpRequestError as e:
        echo "Failed to set trigger tokens: ", e.msg
        quit(1)
    except:
        echo "Unknown exception!"
        raise

proc getTriggerToken*(gl_client: var GitlabClient) =
    ## Attempts to find an existing Pipeline trigger token.
    ## If none exist then we create one.

    var client = newHttpClient(sslContext = newContext(
            verifyMode = CVerifyNone))
    client.headers = newHttpHeaders({"PRIVATE-TOKEN": gl_client.api_key})
    try:
        let response = client.getContent(fmt"{gl_client.api_endpoint}/projects/{gl_client.project_id}/triggers")
        for item in parseJSON(response):
            if len(item["token"].getStr()) > 4:
                gl_client.trigger_token = item["token"].getStr()
                return
    except HttpRequestError as e:
        echo "Failed to get trigger tokens: ", e.msg
        quit(1)
    except:
        echo "Unknown exception!"
        raise

    setTriggerToken(gl_client)

proc triggerPipeline*(variables: seq[string], gl_client: var GitlabClient,
        branch: string): string =
    ## Triggers the pipeline based on the information in GitlabClient
    ## Accepts a list of variables to pass to the pipeline. If no variables
    ## are defined then we do not pass any

    getTriggerToken(gl_client)

    var client = newHttpClient(sslContext = newContext(
            verifyMode = CVerifyNone))
    var data = newMultipartData()
    for variable in variables:
        var var_key = variable.split("=")[0]
        var_key = fmt"variables[{var_key}]"
        var var_val = variable.split("=")[1]
        data[var_key] = var_val

    data["ref"] = branch
    data["token"] = gl_client.trigger_token
    try:
        let response = client.postContent(
                fmt"{gl_client.api_endpoint}/projects/{gl_client.project_id}/trigger/pipeline",
                 multipart = data)

        result = parseJSON(response)["web_url"].getStr()
    except HttpRequestError as e:
        echo "Failed to trigger pipeline: ", e.msg
        quit(1)
    except:
        echo "Unknown exception!"
        raise
