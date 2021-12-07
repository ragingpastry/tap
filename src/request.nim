import std/[osproc, httpclient, strutils, net, strformat, json, uri, strtabs]

proc getRemote*(): string =
    var remote = execCmdEx("git remote get-url origin")[0]
    stripLineEnd(remote)

    let project_path = parseUri(remote).path.split(".git")[0]
    result = project_path[1 .. ^1]

proc getBranch*(): string =
    var branch = execCmdEx("git rev-parse --abbrev-ref HEAD")[0]
    stripLineEnd(branch)
    result = branch


proc getProjectID*(project_url: string, api_key: string): string =
    ### Gets a project ID based on a project URL

    let encoded_url = encodeUrl(project_url)
    var client = newHttpClient(sslContext = newContext(
            verifyMode = CVerifyNone))
    client.headers = newHttpHeaders({"PRIVATE-TOKEN": api_key})
    let response = client.getContent(fmt"https://repo1.dso.mil/api/v4/projects/{encoded_url}")
    let project_id = parseJSON(response)["id"].getInt()
    result = $project_id

proc setTriggerToken*(project_id: string, api_key: string): string =
    var client = newHttpClient(sslContext = newContext(
            verifyMode = CVerifyNone))
    client.headers = newHttpHeaders({"PRIVATE-TOKEN": api_key})
    var data = newMultipartData()
    data["description"] = "Token created via tap CLI"
    let response = client.postContent(fmt"https://repo1.dso.mil/api/v4/projects/{project_id}/triggers",
            multipart = data)
    result = parseJSON(response)["token"].getStr()

proc getTriggerToken*(project_id: string, api_key: string): string =
    ## Gets a trigger token. Must exist
    ## We might be able to auto create in the future
    var client = newHttpClient(sslContext = newContext(
            verifyMode = CVerifyNone))
    client.headers = newHttpHeaders({"PRIVATE-TOKEN": api_key})
    let response = client.getContent(fmt"https://repo1.dso.mil/api/v4/projects/{project_id}/triggers")

    for item in parseJSON(response):
        if len(item["token"].getStr()) > 4:
            return item["token"].getStr()

    result = setTriggerToken(project_id, api_key)

proc triggerPipeline*(variables: seq[string], token: string, project_id: string,
        branch: string): string =

    var client = newHttpClient(sslContext = newContext(
            verifyMode = CVerifyNone))
    var data = newMultipartData()
    for variable in variables:
        var var_key = variable.split("=")[0]
        var_key = fmt"variables[{var_key}]"
        var var_val = variable.split("=")[1]
        data[var_key] = var_val

    data["ref"] = branch
    data["token"] = token
    let response = client.postContent(fmt"https://repo1.dso.mil/api/v4/projects/{project_id}/trigger/pipeline",
            multipart = data)

    result = parseJSON(response)["web_url"].getStr()
