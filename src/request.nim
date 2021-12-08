import std/[osproc, httpclient, strutils, net, strformat, json, uri]

type
    GitlabClient* = object
        api_endpoint*: string
        api_key*: string
        project_id*: int
        trigger_token*: string

proc getRemote*(): string =
    var remote = execCmdEx("git remote get-url origin")[0]
    stripLineEnd(remote)

    result = remote

proc getApiEndpoint*(remote: string): string =
    let scheme = parseUri(remote).scheme
    let host = parseUri(remote).hostname
    let port = parseUri(remote).port

    let endpoint = scheme & "://" & host & port & "/api/v4"
    result = endpoint

proc getProjectpath*(remote: string): string =

    let project_path = parseUri(remote).path.split(".git")[0]
    result = project_path[1 .. ^1]

proc getBranch*(): string =
    var branch = execCmdEx("git rev-parse --abbrev-ref HEAD")[0]
    stripLineEnd(branch)
    result = branch

proc getProjectID*(project_url: string, gl_client: var GitlabClient) =
    ### Gets a project ID based on a project URL

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
    ## Gets a trigger token. Must exist
    ## We might be able to auto create in the future
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
