
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: Amazon Simple Systems Manager (SSM)
## version: 2014-11-06
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## <fullname>AWS Systems Manager</fullname> <p>AWS Systems Manager is a collection of capabilities that helps you automate management tasks such as collecting system inventory, applying operating system (OS) patches, automating the creation of Amazon Machine Images (AMIs), and configuring operating systems (OSs) and applications at scale. Systems Manager lets you remotely and securely manage the configuration of your managed instances. A <i>managed instance</i> is any Amazon EC2 instance or on-premises machine in your hybrid environment that has been configured for Systems Manager.</p> <p>This reference is intended to be used with the <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/">AWS Systems Manager User Guide</a>.</p> <p>To get started, verify prerequisites and configure managed instances. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-setting-up.html">Setting Up AWS Systems Manager</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>For information about other API actions you can perform on Amazon EC2 instances, see the <a href="http://docs.aws.amazon.com/AWSEC2/latest/APIReference/">Amazon EC2 API Reference</a>. For information about how to use a Query API, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/APIReference/making-api-requests.html">Making API Requests</a>. </p>
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/ssm/
type
  Scheme* {.pure.} = enum
    Https = "https", Http = "http", Wss = "wss", Ws = "ws"
  ValidatorSignature = proc (path: JsonNode = nil; query: JsonNode = nil;
                             header: JsonNode = nil; formData: JsonNode = nil;
                             body: JsonNode = nil; _: string = ""): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                    path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_402656044 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656044](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656044): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low .. Scheme.high:
    if scheme notin t.schemes:
      continue
    if scheme in [Scheme.Https, Scheme.Wss]:
      when defined(ssl):
        return some(scheme)
      else:
        continue
    return some(scheme)

proc validateParameter(js: JsonNode; kind: JsonNodeKind; required: bool;
                       default: JsonNode = nil): JsonNode =
  ## ensure an input is of the correct json type and yield
                                                            ## a suitable default value when appropriate
  if js == nil:
    if required:
      if default != nil:
        return validateParameter(default, kind, required = required)
  result = js
  if result == nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind == kind, $kind & " expected; received " & $js.kind

type
  KeyVal {.used.} = tuple[key: string, val: string]
  PathTokenKind = enum
    ConstantSegment, VariableSegment
  PathToken = tuple[kind: PathTokenKind, value: string]
proc queryString(query: JsonNode): string {.used.} =
  var qs: seq[KeyVal]
  if query == nil:
    return ""
  for k, v in query.pairs:
    qs.add (key: k, val: v.getStr)
  result = encodeQuery(qs)

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.
    used.} =
  ## reconstitute a path with constants and variable values taken from json
  var head: string
  if segments.len == 0:
    return some("")
  head = segments[0].value
  case segments[0].kind
  of ConstantSegment:
    discard
  of VariableSegment:
    if head notin input:
      return
    let js = input[head]
    case js.kind
    of JInt, JFloat, JNull, JBool:
      head = $js
    of JString:
      head = js.getStr
    else:
      return
  var remainder = input.hydratePath(segments[1 ..^ 1])
  if remainder.isNone:
    return
  result = some(head & remainder.get)

const
  awsServers = {Scheme.Https: {"ap-northeast-1": "ssm.ap-northeast-1.amazonaws.com", "ap-southeast-1": "ssm.ap-southeast-1.amazonaws.com",
                               "us-west-2": "ssm.us-west-2.amazonaws.com",
                               "eu-west-2": "ssm.eu-west-2.amazonaws.com", "ap-northeast-3": "ssm.ap-northeast-3.amazonaws.com", "eu-central-1": "ssm.eu-central-1.amazonaws.com",
                               "us-east-2": "ssm.us-east-2.amazonaws.com",
                               "us-east-1": "ssm.us-east-1.amazonaws.com", "cn-northwest-1": "ssm.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "ssm.ap-south-1.amazonaws.com",
                               "eu-north-1": "ssm.eu-north-1.amazonaws.com", "ap-northeast-2": "ssm.ap-northeast-2.amazonaws.com",
                               "us-west-1": "ssm.us-west-1.amazonaws.com", "us-gov-east-1": "ssm.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "ssm.eu-west-3.amazonaws.com",
                               "cn-north-1": "ssm.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "ssm.sa-east-1.amazonaws.com",
                               "eu-west-1": "ssm.eu-west-1.amazonaws.com", "us-gov-west-1": "ssm.us-gov-west-1.amazonaws.com", "ap-southeast-2": "ssm.ap-southeast-2.amazonaws.com",
                               "ca-central-1": "ssm.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "ssm.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "ssm.ap-southeast-1.amazonaws.com",
      "us-west-2": "ssm.us-west-2.amazonaws.com",
      "eu-west-2": "ssm.eu-west-2.amazonaws.com",
      "ap-northeast-3": "ssm.ap-northeast-3.amazonaws.com",
      "eu-central-1": "ssm.eu-central-1.amazonaws.com",
      "us-east-2": "ssm.us-east-2.amazonaws.com",
      "us-east-1": "ssm.us-east-1.amazonaws.com",
      "cn-northwest-1": "ssm.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "ssm.ap-south-1.amazonaws.com",
      "eu-north-1": "ssm.eu-north-1.amazonaws.com",
      "ap-northeast-2": "ssm.ap-northeast-2.amazonaws.com",
      "us-west-1": "ssm.us-west-1.amazonaws.com",
      "us-gov-east-1": "ssm.us-gov-east-1.amazonaws.com",
      "eu-west-3": "ssm.eu-west-3.amazonaws.com",
      "cn-north-1": "ssm.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "ssm.sa-east-1.amazonaws.com",
      "eu-west-1": "ssm.eu-west-1.amazonaws.com",
      "us-gov-west-1": "ssm.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "ssm.ap-southeast-2.amazonaws.com",
      "ca-central-1": "ssm.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "ssm"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AddTagsToResource_402656294 = ref object of OpenApiRestCall_402656044
proc url_AddTagsToResource_402656296(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_AddTagsToResource_402656295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656390 = header.getOrDefault("X-Amz-Target")
  valid_402656390 = validateParameter(valid_402656390, JString, required = true, default = newJString(
      "AmazonSSM.AddTagsToResource"))
  if valid_402656390 != nil:
    section.add "X-Amz-Target", valid_402656390
  var valid_402656391 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656391 = validateParameter(valid_402656391, JString,
                                      required = false, default = nil)
  if valid_402656391 != nil:
    section.add "X-Amz-Security-Token", valid_402656391
  var valid_402656392 = header.getOrDefault("X-Amz-Signature")
  valid_402656392 = validateParameter(valid_402656392, JString,
                                      required = false, default = nil)
  if valid_402656392 != nil:
    section.add "X-Amz-Signature", valid_402656392
  var valid_402656393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656393 = validateParameter(valid_402656393, JString,
                                      required = false, default = nil)
  if valid_402656393 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656393
  var valid_402656394 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656394 = validateParameter(valid_402656394, JString,
                                      required = false, default = nil)
  if valid_402656394 != nil:
    section.add "X-Amz-Algorithm", valid_402656394
  var valid_402656395 = header.getOrDefault("X-Amz-Date")
  valid_402656395 = validateParameter(valid_402656395, JString,
                                      required = false, default = nil)
  if valid_402656395 != nil:
    section.add "X-Amz-Date", valid_402656395
  var valid_402656396 = header.getOrDefault("X-Amz-Credential")
  valid_402656396 = validateParameter(valid_402656396, JString,
                                      required = false, default = nil)
  if valid_402656396 != nil:
    section.add "X-Amz-Credential", valid_402656396
  var valid_402656397 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656397 = validateParameter(valid_402656397, JString,
                                      required = false, default = nil)
  if valid_402656397 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656412: Call_AddTagsToResource_402656294;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656412.validator(path, query, header, formData, body, _)
  let scheme = call_402656412.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656412.makeUrl(scheme.get, call_402656412.host, call_402656412.base,
                                   call_402656412.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656412, uri, valid, _)

proc call*(call_402656461: Call_AddTagsToResource_402656294; body: JsonNode): Recallable =
  ## addTagsToResource
  ## <p>Adds or overwrites one or more tags for the specified resource. Tags are metadata that you can assign to your documents, managed instances, maintenance windows, Parameter Store parameters, and patch baselines. Tags enable you to categorize your resources in different ways, for example, by purpose, owner, or environment. Each tag consists of a key and an optional value, both of which you define. For example, you could define a set of tags for your account's managed instances that helps you track each instance's owner and stack level. For example: Key=Owner and Value=DbAdmin, SysAdmin, or Dev. Or Key=Stack and Value=Production, Pre-Production, or Test.</p> <p>Each resource can have a maximum of 50 tags. </p> <p>We recommend that you devise a set of tag keys that meets your needs for each resource type. Using a consistent set of tag keys makes it easier for you to manage your resources. You can search and filter the resources based on the tags you add. Tags don't have any semantic meaning to Amazon EC2 and are interpreted strictly as a string of characters. </p> <p>For more information about tags, see <a href="http://docs.aws.amazon.com/AWSEC2/latest/UserGuide/Using_Tags.html">Tagging Your Amazon EC2 Resources</a> in the <i>Amazon EC2 User Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656462 = newJObject()
  if body != nil:
    body_402656462 = body
  result = call_402656461.call(nil, nil, nil, nil, body_402656462)

var addTagsToResource* = Call_AddTagsToResource_402656294(
    name: "addTagsToResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.AddTagsToResource",
    validator: validate_AddTagsToResource_402656295, base: "/",
    makeUrl: url_AddTagsToResource_402656296,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelCommand_402656489 = ref object of OpenApiRestCall_402656044
proc url_CancelCommand_402656491(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelCommand_402656490(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656492 = header.getOrDefault("X-Amz-Target")
  valid_402656492 = validateParameter(valid_402656492, JString, required = true, default = newJString(
      "AmazonSSM.CancelCommand"))
  if valid_402656492 != nil:
    section.add "X-Amz-Target", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Security-Token", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Signature")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Signature", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Algorithm", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Date")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Date", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Credential")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Credential", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656501: Call_CancelCommand_402656489; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
                                                                                         ## 
  let valid = call_402656501.validator(path, query, header, formData, body, _)
  let scheme = call_402656501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656501.makeUrl(scheme.get, call_402656501.host, call_402656501.base,
                                   call_402656501.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656501, uri, valid, _)

proc call*(call_402656502: Call_CancelCommand_402656489; body: JsonNode): Recallable =
  ## cancelCommand
  ## Attempts to cancel the command specified by the Command ID. There is no guarantee that the command will be terminated and the underlying process stopped.
  ##   
                                                                                                                                                              ## body: JObject (required)
  var body_402656503 = newJObject()
  if body != nil:
    body_402656503 = body
  result = call_402656502.call(nil, nil, nil, nil, body_402656503)

var cancelCommand* = Call_CancelCommand_402656489(name: "cancelCommand",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelCommand",
    validator: validate_CancelCommand_402656490, base: "/",
    makeUrl: url_CancelCommand_402656491, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CancelMaintenanceWindowExecution_402656504 = ref object of OpenApiRestCall_402656044
proc url_CancelMaintenanceWindowExecution_402656506(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CancelMaintenanceWindowExecution_402656505(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656507 = header.getOrDefault("X-Amz-Target")
  valid_402656507 = validateParameter(valid_402656507, JString, required = true, default = newJString(
      "AmazonSSM.CancelMaintenanceWindowExecution"))
  if valid_402656507 != nil:
    section.add "X-Amz-Target", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Security-Token", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-Signature")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Signature", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Algorithm", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Date")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Date", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Credential")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Credential", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656516: Call_CancelMaintenanceWindowExecution_402656504;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
                                                                                         ## 
  let valid = call_402656516.validator(path, query, header, formData, body, _)
  let scheme = call_402656516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656516.makeUrl(scheme.get, call_402656516.host, call_402656516.base,
                                   call_402656516.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656516, uri, valid, _)

proc call*(call_402656517: Call_CancelMaintenanceWindowExecution_402656504;
           body: JsonNode): Recallable =
  ## cancelMaintenanceWindowExecution
  ## Stops a maintenance window execution that is already in progress and cancels any tasks in the window that have not already starting running. (Tasks already in progress will continue to completion.)
  ##   
                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656518 = newJObject()
  if body != nil:
    body_402656518 = body
  result = call_402656517.call(nil, nil, nil, nil, body_402656518)

var cancelMaintenanceWindowExecution* = Call_CancelMaintenanceWindowExecution_402656504(
    name: "cancelMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CancelMaintenanceWindowExecution",
    validator: validate_CancelMaintenanceWindowExecution_402656505, base: "/",
    makeUrl: url_CancelMaintenanceWindowExecution_402656506,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateActivation_402656519 = ref object of OpenApiRestCall_402656044
proc url_CreateActivation_402656521(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateActivation_402656520(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Generates an activation code and activation ID you can use to register your on-premises server or virtual machine (VM) with Systems Manager. Registering these machines with Systems Manager makes it possible to manage them using Systems Manager capabilities. You use the activation code and ID when installing SSM Agent on machines in your hybrid environment. For more information about requirements for managing on-premises instances and VMs using Systems Manager, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a> in the <i>AWS Systems Manager User Guide</i>. </p> <note> <p>On-premises servers or VMs that are registered with Systems Manager and Amazon EC2 instances that you manage with Systems Manager are all called <i>managed instances</i>.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656522 = header.getOrDefault("X-Amz-Target")
  valid_402656522 = validateParameter(valid_402656522, JString, required = true, default = newJString(
      "AmazonSSM.CreateActivation"))
  if valid_402656522 != nil:
    section.add "X-Amz-Target", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Security-Token", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-Signature")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-Signature", valid_402656524
  var valid_402656525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656525 = validateParameter(valid_402656525, JString,
                                      required = false, default = nil)
  if valid_402656525 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656525
  var valid_402656526 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656526 = validateParameter(valid_402656526, JString,
                                      required = false, default = nil)
  if valid_402656526 != nil:
    section.add "X-Amz-Algorithm", valid_402656526
  var valid_402656527 = header.getOrDefault("X-Amz-Date")
  valid_402656527 = validateParameter(valid_402656527, JString,
                                      required = false, default = nil)
  if valid_402656527 != nil:
    section.add "X-Amz-Date", valid_402656527
  var valid_402656528 = header.getOrDefault("X-Amz-Credential")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Credential", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656529
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656531: Call_CreateActivation_402656519;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Generates an activation code and activation ID you can use to register your on-premises server or virtual machine (VM) with Systems Manager. Registering these machines with Systems Manager makes it possible to manage them using Systems Manager capabilities. You use the activation code and ID when installing SSM Agent on machines in your hybrid environment. For more information about requirements for managing on-premises instances and VMs using Systems Manager, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a> in the <i>AWS Systems Manager User Guide</i>. </p> <note> <p>On-premises servers or VMs that are registered with Systems Manager and Amazon EC2 instances that you manage with Systems Manager are all called <i>managed instances</i>.</p> </note>
                                                                                         ## 
  let valid = call_402656531.validator(path, query, header, formData, body, _)
  let scheme = call_402656531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656531.makeUrl(scheme.get, call_402656531.host, call_402656531.base,
                                   call_402656531.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656531, uri, valid, _)

proc call*(call_402656532: Call_CreateActivation_402656519; body: JsonNode): Recallable =
  ## createActivation
  ## <p>Generates an activation code and activation ID you can use to register your on-premises server or virtual machine (VM) with Systems Manager. Registering these machines with Systems Manager makes it possible to manage them using Systems Manager capabilities. You use the activation code and ID when installing SSM Agent on machines in your hybrid environment. For more information about requirements for managing on-premises instances and VMs using Systems Manager, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-managedinstances.html">Setting Up AWS Systems Manager for Hybrid Environments</a> in the <i>AWS Systems Manager User Guide</i>. </p> <note> <p>On-premises servers or VMs that are registered with Systems Manager and Amazon EC2 instances that you manage with Systems Manager are all called <i>managed instances</i>.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var createActivation* = Call_CreateActivation_402656519(
    name: "createActivation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateActivation",
    validator: validate_CreateActivation_402656520, base: "/",
    makeUrl: url_CreateActivation_402656521,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociation_402656534 = ref object of OpenApiRestCall_402656044
proc url_CreateAssociation_402656536(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAssociation_402656535(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656537 = header.getOrDefault("X-Amz-Target")
  valid_402656537 = validateParameter(valid_402656537, JString, required = true, default = newJString(
      "AmazonSSM.CreateAssociation"))
  if valid_402656537 != nil:
    section.add "X-Amz-Target", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Security-Token", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Signature")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Signature", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Algorithm", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Date")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Date", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-Credential")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-Credential", valid_402656543
  var valid_402656544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656546: Call_CreateAssociation_402656534;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
                                                                                         ## 
  let valid = call_402656546.validator(path, query, header, formData, body, _)
  let scheme = call_402656546.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656546.makeUrl(scheme.get, call_402656546.host, call_402656546.base,
                                   call_402656546.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656546, uri, valid, _)

proc call*(call_402656547: Call_CreateAssociation_402656534; body: JsonNode): Recallable =
  ## createAssociation
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656548 = newJObject()
  if body != nil:
    body_402656548 = body
  result = call_402656547.call(nil, nil, nil, nil, body_402656548)

var createAssociation* = Call_CreateAssociation_402656534(
    name: "createAssociation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociation",
    validator: validate_CreateAssociation_402656535, base: "/",
    makeUrl: url_CreateAssociation_402656536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateAssociationBatch_402656549 = ref object of OpenApiRestCall_402656044
proc url_CreateAssociationBatch_402656551(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateAssociationBatch_402656550(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656552 = header.getOrDefault("X-Amz-Target")
  valid_402656552 = validateParameter(valid_402656552, JString, required = true, default = newJString(
      "AmazonSSM.CreateAssociationBatch"))
  if valid_402656552 != nil:
    section.add "X-Amz-Target", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Security-Token", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Signature")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Signature", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656555
  var valid_402656556 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656556 = validateParameter(valid_402656556, JString,
                                      required = false, default = nil)
  if valid_402656556 != nil:
    section.add "X-Amz-Algorithm", valid_402656556
  var valid_402656557 = header.getOrDefault("X-Amz-Date")
  valid_402656557 = validateParameter(valid_402656557, JString,
                                      required = false, default = nil)
  if valid_402656557 != nil:
    section.add "X-Amz-Date", valid_402656557
  var valid_402656558 = header.getOrDefault("X-Amz-Credential")
  valid_402656558 = validateParameter(valid_402656558, JString,
                                      required = false, default = nil)
  if valid_402656558 != nil:
    section.add "X-Amz-Credential", valid_402656558
  var valid_402656559 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656559
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656561: Call_CreateAssociationBatch_402656549;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
                                                                                         ## 
  let valid = call_402656561.validator(path, query, header, formData, body, _)
  let scheme = call_402656561.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656561.makeUrl(scheme.get, call_402656561.host, call_402656561.base,
                                   call_402656561.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656561, uri, valid, _)

proc call*(call_402656562: Call_CreateAssociationBatch_402656549; body: JsonNode): Recallable =
  ## createAssociationBatch
  ## <p>Associates the specified Systems Manager document with the specified instances or targets.</p> <p>When you associate a document with one or more instances using instance IDs or tags, SSM Agent running on the instance processes the document and configures the instance as specified.</p> <p>If you associate a document with an instance that already has an associated document, the system returns the AssociationAlreadyExists exception.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402656563 = newJObject()
  if body != nil:
    body_402656563 = body
  result = call_402656562.call(nil, nil, nil, nil, body_402656563)

var createAssociationBatch* = Call_CreateAssociationBatch_402656549(
    name: "createAssociationBatch", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateAssociationBatch",
    validator: validate_CreateAssociationBatch_402656550, base: "/",
    makeUrl: url_CreateAssociationBatch_402656551,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateDocument_402656564 = ref object of OpenApiRestCall_402656044
proc url_CreateDocument_402656566(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateDocument_402656565(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656567 = header.getOrDefault("X-Amz-Target")
  valid_402656567 = validateParameter(valid_402656567, JString, required = true, default = newJString(
      "AmazonSSM.CreateDocument"))
  if valid_402656567 != nil:
    section.add "X-Amz-Target", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Security-Token", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Signature")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Signature", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-Algorithm", valid_402656571
  var valid_402656572 = header.getOrDefault("X-Amz-Date")
  valid_402656572 = validateParameter(valid_402656572, JString,
                                      required = false, default = nil)
  if valid_402656572 != nil:
    section.add "X-Amz-Date", valid_402656572
  var valid_402656573 = header.getOrDefault("X-Amz-Credential")
  valid_402656573 = validateParameter(valid_402656573, JString,
                                      required = false, default = nil)
  if valid_402656573 != nil:
    section.add "X-Amz-Credential", valid_402656573
  var valid_402656574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656574 = validateParameter(valid_402656574, JString,
                                      required = false, default = nil)
  if valid_402656574 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656576: Call_CreateDocument_402656564; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
                                                                                         ## 
  let valid = call_402656576.validator(path, query, header, formData, body, _)
  let scheme = call_402656576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656576.makeUrl(scheme.get, call_402656576.host, call_402656576.base,
                                   call_402656576.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656576, uri, valid, _)

proc call*(call_402656577: Call_CreateDocument_402656564; body: JsonNode): Recallable =
  ## createDocument
  ## <p>Creates a Systems Manager document.</p> <p>After you create a document, you can use CreateAssociation to associate it with one or more running instances.</p>
  ##   
                                                                                                                                                                     ## body: JObject (required)
  var body_402656578 = newJObject()
  if body != nil:
    body_402656578 = body
  result = call_402656577.call(nil, nil, nil, nil, body_402656578)

var createDocument* = Call_CreateDocument_402656564(name: "createDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateDocument",
    validator: validate_CreateDocument_402656565, base: "/",
    makeUrl: url_CreateDocument_402656566, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMaintenanceWindow_402656579 = ref object of OpenApiRestCall_402656044
proc url_CreateMaintenanceWindow_402656581(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMaintenanceWindow_402656580(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a new maintenance window.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656582 = header.getOrDefault("X-Amz-Target")
  valid_402656582 = validateParameter(valid_402656582, JString, required = true, default = newJString(
      "AmazonSSM.CreateMaintenanceWindow"))
  if valid_402656582 != nil:
    section.add "X-Amz-Target", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Security-Token", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Signature")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Signature", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-Algorithm", valid_402656586
  var valid_402656587 = header.getOrDefault("X-Amz-Date")
  valid_402656587 = validateParameter(valid_402656587, JString,
                                      required = false, default = nil)
  if valid_402656587 != nil:
    section.add "X-Amz-Date", valid_402656587
  var valid_402656588 = header.getOrDefault("X-Amz-Credential")
  valid_402656588 = validateParameter(valid_402656588, JString,
                                      required = false, default = nil)
  if valid_402656588 != nil:
    section.add "X-Amz-Credential", valid_402656588
  var valid_402656589 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656589 = validateParameter(valid_402656589, JString,
                                      required = false, default = nil)
  if valid_402656589 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656589
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656591: Call_CreateMaintenanceWindow_402656579;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new maintenance window.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
                                                                                         ## 
  let valid = call_402656591.validator(path, query, header, formData, body, _)
  let scheme = call_402656591.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656591.makeUrl(scheme.get, call_402656591.host, call_402656591.base,
                                   call_402656591.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656591, uri, valid, _)

proc call*(call_402656592: Call_CreateMaintenanceWindow_402656579;
           body: JsonNode): Recallable =
  ## createMaintenanceWindow
  ## <p>Creates a new maintenance window.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656593 = newJObject()
  if body != nil:
    body_402656593 = body
  result = call_402656592.call(nil, nil, nil, nil, body_402656593)

var createMaintenanceWindow* = Call_CreateMaintenanceWindow_402656579(
    name: "createMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateMaintenanceWindow",
    validator: validate_CreateMaintenanceWindow_402656580, base: "/",
    makeUrl: url_CreateMaintenanceWindow_402656581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOpsItem_402656594 = ref object of OpenApiRestCall_402656044
proc url_CreateOpsItem_402656596(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateOpsItem_402656595(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656597 = header.getOrDefault("X-Amz-Target")
  valid_402656597 = validateParameter(valid_402656597, JString, required = true, default = newJString(
      "AmazonSSM.CreateOpsItem"))
  if valid_402656597 != nil:
    section.add "X-Amz-Target", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Security-Token", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Signature")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Signature", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Algorithm", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-Date")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-Date", valid_402656602
  var valid_402656603 = header.getOrDefault("X-Amz-Credential")
  valid_402656603 = validateParameter(valid_402656603, JString,
                                      required = false, default = nil)
  if valid_402656603 != nil:
    section.add "X-Amz-Credential", valid_402656603
  var valid_402656604 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656604 = validateParameter(valid_402656604, JString,
                                      required = false, default = nil)
  if valid_402656604 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656604
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656606: Call_CreateOpsItem_402656594; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
                                                                                         ## 
  let valid = call_402656606.validator(path, query, header, formData, body, _)
  let scheme = call_402656606.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656606.makeUrl(scheme.get, call_402656606.host, call_402656606.base,
                                   call_402656606.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656606, uri, valid, _)

proc call*(call_402656607: Call_CreateOpsItem_402656594; body: JsonNode): Recallable =
  ## createOpsItem
  ## <p>Creates a new OpsItem. You must have permission in AWS Identity and Access Management (IAM) to create a new OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656608 = newJObject()
  if body != nil:
    body_402656608 = body
  result = call_402656607.call(nil, nil, nil, nil, body_402656608)

var createOpsItem* = Call_CreateOpsItem_402656594(name: "createOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateOpsItem",
    validator: validate_CreateOpsItem_402656595, base: "/",
    makeUrl: url_CreateOpsItem_402656596, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreatePatchBaseline_402656609 = ref object of OpenApiRestCall_402656044
proc url_CreatePatchBaseline_402656611(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreatePatchBaseline_402656610(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656612 = header.getOrDefault("X-Amz-Target")
  valid_402656612 = validateParameter(valid_402656612, JString, required = true, default = newJString(
      "AmazonSSM.CreatePatchBaseline"))
  if valid_402656612 != nil:
    section.add "X-Amz-Target", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Security-Token", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Signature")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Signature", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Algorithm", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-Date")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-Date", valid_402656617
  var valid_402656618 = header.getOrDefault("X-Amz-Credential")
  valid_402656618 = validateParameter(valid_402656618, JString,
                                      required = false, default = nil)
  if valid_402656618 != nil:
    section.add "X-Amz-Credential", valid_402656618
  var valid_402656619 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656619 = validateParameter(valid_402656619, JString,
                                      required = false, default = nil)
  if valid_402656619 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656619
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656621: Call_CreatePatchBaseline_402656609;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
                                                                                         ## 
  let valid = call_402656621.validator(path, query, header, formData, body, _)
  let scheme = call_402656621.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656621.makeUrl(scheme.get, call_402656621.host, call_402656621.base,
                                   call_402656621.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656621, uri, valid, _)

proc call*(call_402656622: Call_CreatePatchBaseline_402656609; body: JsonNode): Recallable =
  ## createPatchBaseline
  ## <p>Creates a patch baseline.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                     ## body: JObject (required)
  var body_402656623 = newJObject()
  if body != nil:
    body_402656623 = body
  result = call_402656622.call(nil, nil, nil, nil, body_402656623)

var createPatchBaseline* = Call_CreatePatchBaseline_402656609(
    name: "createPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreatePatchBaseline",
    validator: validate_CreatePatchBaseline_402656610, base: "/",
    makeUrl: url_CreatePatchBaseline_402656611,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateResourceDataSync_402656624 = ref object of OpenApiRestCall_402656044
proc url_CreateResourceDataSync_402656626(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateResourceDataSync_402656625(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>A resource data sync helps you view data from multiple sources in a single location. Systems Manager offers two types of resource data sync: <code>SyncToDestination</code> and <code>SyncFromSource</code>.</p> <p>You can configure Systems Manager Inventory to use the <code>SyncToDestination</code> type to synchronize Inventory data from multiple AWS Regions to a single Amazon S3 bucket. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>You can configure Systems Manager Explorer to use the <code>SyncFromSource</code> type to synchronize operational work items (OpsItems) and operational data (OpsData) from multiple AWS Regions to a single Amazon S3 bucket. This type can synchronize OpsItems and OpsData from multiple AWS accounts and Regions or <code>EntireOrganization</code> by using AWS Organizations. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/Explorer-resource-data-sync.html">Setting Up Explorer to Display Data from Multiple Accounts and Regions</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>A resource data sync is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data. To check the status of a sync, use the <a>ListResourceDataSync</a>.</p> <note> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. </p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656627 = header.getOrDefault("X-Amz-Target")
  valid_402656627 = validateParameter(valid_402656627, JString, required = true, default = newJString(
      "AmazonSSM.CreateResourceDataSync"))
  if valid_402656627 != nil:
    section.add "X-Amz-Target", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Security-Token", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Signature")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Signature", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Algorithm", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Date")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Date", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-Credential")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-Credential", valid_402656633
  var valid_402656634 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656634 = validateParameter(valid_402656634, JString,
                                      required = false, default = nil)
  if valid_402656634 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656634
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656636: Call_CreateResourceDataSync_402656624;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>A resource data sync helps you view data from multiple sources in a single location. Systems Manager offers two types of resource data sync: <code>SyncToDestination</code> and <code>SyncFromSource</code>.</p> <p>You can configure Systems Manager Inventory to use the <code>SyncToDestination</code> type to synchronize Inventory data from multiple AWS Regions to a single Amazon S3 bucket. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>You can configure Systems Manager Explorer to use the <code>SyncFromSource</code> type to synchronize operational work items (OpsItems) and operational data (OpsData) from multiple AWS Regions to a single Amazon S3 bucket. This type can synchronize OpsItems and OpsData from multiple AWS accounts and Regions or <code>EntireOrganization</code> by using AWS Organizations. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/Explorer-resource-data-sync.html">Setting Up Explorer to Display Data from Multiple Accounts and Regions</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>A resource data sync is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data. To check the status of a sync, use the <a>ListResourceDataSync</a>.</p> <note> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. </p> </note>
                                                                                         ## 
  let valid = call_402656636.validator(path, query, header, formData, body, _)
  let scheme = call_402656636.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656636.makeUrl(scheme.get, call_402656636.host, call_402656636.base,
                                   call_402656636.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656636, uri, valid, _)

proc call*(call_402656637: Call_CreateResourceDataSync_402656624; body: JsonNode): Recallable =
  ## createResourceDataSync
  ## <p>A resource data sync helps you view data from multiple sources in a single location. Systems Manager offers two types of resource data sync: <code>SyncToDestination</code> and <code>SyncFromSource</code>.</p> <p>You can configure Systems Manager Inventory to use the <code>SyncToDestination</code> type to synchronize Inventory data from multiple AWS Regions to a single Amazon S3 bucket. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/sysman-inventory-datasync.html">Configuring Resource Data Sync for Inventory</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>You can configure Systems Manager Explorer to use the <code>SyncFromSource</code> type to synchronize operational work items (OpsItems) and operational data (OpsData) from multiple AWS Regions to a single Amazon S3 bucket. This type can synchronize OpsItems and OpsData from multiple AWS accounts and Regions or <code>EntireOrganization</code> by using AWS Organizations. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/Explorer-resource-data-sync.html">Setting Up Explorer to Display Data from Multiple Accounts and Regions</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>A resource data sync is an asynchronous operation that returns immediately. After a successful initial sync is completed, the system continuously syncs data. To check the status of a sync, use the <a>ListResourceDataSync</a>.</p> <note> <p>By default, data is not encrypted in Amazon S3. We strongly recommend that you enable encryption in Amazon S3 to ensure secure data storage. We also recommend that you secure access to the Amazon S3 bucket by creating a restrictive bucket policy. </p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  var body_402656638 = newJObject()
  if body != nil:
    body_402656638 = body
  result = call_402656637.call(nil, nil, nil, nil, body_402656638)

var createResourceDataSync* = Call_CreateResourceDataSync_402656624(
    name: "createResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.CreateResourceDataSync",
    validator: validate_CreateResourceDataSync_402656625, base: "/",
    makeUrl: url_CreateResourceDataSync_402656626,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteActivation_402656639 = ref object of OpenApiRestCall_402656044
proc url_DeleteActivation_402656641(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteActivation_402656640(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656642 = header.getOrDefault("X-Amz-Target")
  valid_402656642 = validateParameter(valid_402656642, JString, required = true, default = newJString(
      "AmazonSSM.DeleteActivation"))
  if valid_402656642 != nil:
    section.add "X-Amz-Target", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Security-Token", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Signature")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Signature", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Algorithm", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Date")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Date", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-Credential")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-Credential", valid_402656648
  var valid_402656649 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656649 = validateParameter(valid_402656649, JString,
                                      required = false, default = nil)
  if valid_402656649 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656649
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656651: Call_DeleteActivation_402656639;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
                                                                                         ## 
  let valid = call_402656651.validator(path, query, header, formData, body, _)
  let scheme = call_402656651.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656651.makeUrl(scheme.get, call_402656651.host, call_402656651.base,
                                   call_402656651.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656651, uri, valid, _)

proc call*(call_402656652: Call_DeleteActivation_402656639; body: JsonNode): Recallable =
  ## deleteActivation
  ## Deletes an activation. You are not required to delete an activation. If you delete an activation, you can no longer use it to register additional managed instances. Deleting an activation does not de-register managed instances. You must manually de-register managed instances.
  ##   
                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656653 = newJObject()
  if body != nil:
    body_402656653 = body
  result = call_402656652.call(nil, nil, nil, nil, body_402656653)

var deleteActivation* = Call_DeleteActivation_402656639(
    name: "deleteActivation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteActivation",
    validator: validate_DeleteActivation_402656640, base: "/",
    makeUrl: url_DeleteActivation_402656641,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteAssociation_402656654 = ref object of OpenApiRestCall_402656044
proc url_DeleteAssociation_402656656(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteAssociation_402656655(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656657 = header.getOrDefault("X-Amz-Target")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true, default = newJString(
      "AmazonSSM.DeleteAssociation"))
  if valid_402656657 != nil:
    section.add "X-Amz-Target", valid_402656657
  var valid_402656658 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656658 = validateParameter(valid_402656658, JString,
                                      required = false, default = nil)
  if valid_402656658 != nil:
    section.add "X-Amz-Security-Token", valid_402656658
  var valid_402656659 = header.getOrDefault("X-Amz-Signature")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Signature", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Algorithm", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Date")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Date", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Credential")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Credential", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656664
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656666: Call_DeleteAssociation_402656654;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
                                                                                         ## 
  let valid = call_402656666.validator(path, query, header, formData, body, _)
  let scheme = call_402656666.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656666.makeUrl(scheme.get, call_402656666.host, call_402656666.base,
                                   call_402656666.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656666, uri, valid, _)

proc call*(call_402656667: Call_DeleteAssociation_402656654; body: JsonNode): Recallable =
  ## deleteAssociation
  ## <p>Disassociates the specified Systems Manager document from the specified instance.</p> <p>When you disassociate a document from an instance, it does not change the configuration of the instance. To change the configuration state of an instance after you disassociate a document, you must create a new document with the desired configuration and associate it with the instance.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402656668 = newJObject()
  if body != nil:
    body_402656668 = body
  result = call_402656667.call(nil, nil, nil, nil, body_402656668)

var deleteAssociation* = Call_DeleteAssociation_402656654(
    name: "deleteAssociation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteAssociation",
    validator: validate_DeleteAssociation_402656655, base: "/",
    makeUrl: url_DeleteAssociation_402656656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteDocument_402656669 = ref object of OpenApiRestCall_402656044
proc url_DeleteDocument_402656671(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteDocument_402656670(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656672 = header.getOrDefault("X-Amz-Target")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true, default = newJString(
      "AmazonSSM.DeleteDocument"))
  if valid_402656672 != nil:
    section.add "X-Amz-Target", valid_402656672
  var valid_402656673 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "X-Amz-Security-Token", valid_402656673
  var valid_402656674 = header.getOrDefault("X-Amz-Signature")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Signature", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Algorithm", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Date")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Date", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Credential")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Credential", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656679
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656681: Call_DeleteDocument_402656669; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
                                                                                         ## 
  let valid = call_402656681.validator(path, query, header, formData, body, _)
  let scheme = call_402656681.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656681.makeUrl(scheme.get, call_402656681.host, call_402656681.base,
                                   call_402656681.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656681, uri, valid, _)

proc call*(call_402656682: Call_DeleteDocument_402656669; body: JsonNode): Recallable =
  ## deleteDocument
  ## <p>Deletes the Systems Manager document and all instance associations to the document.</p> <p>Before you delete the document, we recommend that you use <a>DeleteAssociation</a> to disassociate all instances that are associated with the document.</p>
  ##   
                                                                                                                                                                                                                                                              ## body: JObject (required)
  var body_402656683 = newJObject()
  if body != nil:
    body_402656683 = body
  result = call_402656682.call(nil, nil, nil, nil, body_402656683)

var deleteDocument* = Call_DeleteDocument_402656669(name: "deleteDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteDocument",
    validator: validate_DeleteDocument_402656670, base: "/",
    makeUrl: url_DeleteDocument_402656671, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInventory_402656684 = ref object of OpenApiRestCall_402656044
proc url_DeleteInventory_402656686(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteInventory_402656685(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656687 = header.getOrDefault("X-Amz-Target")
  valid_402656687 = validateParameter(valid_402656687, JString, required = true, default = newJString(
      "AmazonSSM.DeleteInventory"))
  if valid_402656687 != nil:
    section.add "X-Amz-Target", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Security-Token", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Signature")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Signature", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Algorithm", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Date")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Date", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Credential")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Credential", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656694
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656696: Call_DeleteInventory_402656684; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
                                                                                         ## 
  let valid = call_402656696.validator(path, query, header, formData, body, _)
  let scheme = call_402656696.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656696.makeUrl(scheme.get, call_402656696.host, call_402656696.base,
                                   call_402656696.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656696, uri, valid, _)

proc call*(call_402656697: Call_DeleteInventory_402656684; body: JsonNode): Recallable =
  ## deleteInventory
  ## Delete a custom inventory type, or the data associated with a custom Inventory type. Deleting a custom inventory type is also referred to as deleting a custom inventory schema.
  ##   
                                                                                                                                                                                     ## body: JObject (required)
  var body_402656698 = newJObject()
  if body != nil:
    body_402656698 = body
  result = call_402656697.call(nil, nil, nil, nil, body_402656698)

var deleteInventory* = Call_DeleteInventory_402656684(name: "deleteInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteInventory",
    validator: validate_DeleteInventory_402656685, base: "/",
    makeUrl: url_DeleteInventory_402656686, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMaintenanceWindow_402656699 = ref object of OpenApiRestCall_402656044
proc url_DeleteMaintenanceWindow_402656701(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteMaintenanceWindow_402656700(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a maintenance window.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656702 = header.getOrDefault("X-Amz-Target")
  valid_402656702 = validateParameter(valid_402656702, JString, required = true, default = newJString(
      "AmazonSSM.DeleteMaintenanceWindow"))
  if valid_402656702 != nil:
    section.add "X-Amz-Target", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Security-Token", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Signature")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Signature", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Algorithm", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Date")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Date", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-Credential")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-Credential", valid_402656708
  var valid_402656709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656709 = validateParameter(valid_402656709, JString,
                                      required = false, default = nil)
  if valid_402656709 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656711: Call_DeleteMaintenanceWindow_402656699;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a maintenance window.
                                                                                         ## 
  let valid = call_402656711.validator(path, query, header, formData, body, _)
  let scheme = call_402656711.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656711.makeUrl(scheme.get, call_402656711.host, call_402656711.base,
                                   call_402656711.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656711, uri, valid, _)

proc call*(call_402656712: Call_DeleteMaintenanceWindow_402656699;
           body: JsonNode): Recallable =
  ## deleteMaintenanceWindow
  ## Deletes a maintenance window.
  ##   body: JObject (required)
  var body_402656713 = newJObject()
  if body != nil:
    body_402656713 = body
  result = call_402656712.call(nil, nil, nil, nil, body_402656713)

var deleteMaintenanceWindow* = Call_DeleteMaintenanceWindow_402656699(
    name: "deleteMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteMaintenanceWindow",
    validator: validate_DeleteMaintenanceWindow_402656700, base: "/",
    makeUrl: url_DeleteMaintenanceWindow_402656701,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameter_402656714 = ref object of OpenApiRestCall_402656044
proc url_DeleteParameter_402656716(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteParameter_402656715(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete a parameter from the system.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656717 = header.getOrDefault("X-Amz-Target")
  valid_402656717 = validateParameter(valid_402656717, JString, required = true, default = newJString(
      "AmazonSSM.DeleteParameter"))
  if valid_402656717 != nil:
    section.add "X-Amz-Target", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Security-Token", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Signature")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Signature", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Algorithm", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Date")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Date", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-Credential")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-Credential", valid_402656723
  var valid_402656724 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656724 = validateParameter(valid_402656724, JString,
                                      required = false, default = nil)
  if valid_402656724 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656724
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656726: Call_DeleteParameter_402656714; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a parameter from the system.
                                                                                         ## 
  let valid = call_402656726.validator(path, query, header, formData, body, _)
  let scheme = call_402656726.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656726.makeUrl(scheme.get, call_402656726.host, call_402656726.base,
                                   call_402656726.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656726, uri, valid, _)

proc call*(call_402656727: Call_DeleteParameter_402656714; body: JsonNode): Recallable =
  ## deleteParameter
  ## Delete a parameter from the system.
  ##   body: JObject (required)
  var body_402656728 = newJObject()
  if body != nil:
    body_402656728 = body
  result = call_402656727.call(nil, nil, nil, nil, body_402656728)

var deleteParameter* = Call_DeleteParameter_402656714(name: "deleteParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameter",
    validator: validate_DeleteParameter_402656715, base: "/",
    makeUrl: url_DeleteParameter_402656716, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteParameters_402656729 = ref object of OpenApiRestCall_402656044
proc url_DeleteParameters_402656731(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteParameters_402656730(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete a list of parameters.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656732 = header.getOrDefault("X-Amz-Target")
  valid_402656732 = validateParameter(valid_402656732, JString, required = true, default = newJString(
      "AmazonSSM.DeleteParameters"))
  if valid_402656732 != nil:
    section.add "X-Amz-Target", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Security-Token", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Signature")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Signature", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Algorithm", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-Date")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-Date", valid_402656737
  var valid_402656738 = header.getOrDefault("X-Amz-Credential")
  valid_402656738 = validateParameter(valid_402656738, JString,
                                      required = false, default = nil)
  if valid_402656738 != nil:
    section.add "X-Amz-Credential", valid_402656738
  var valid_402656739 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656739 = validateParameter(valid_402656739, JString,
                                      required = false, default = nil)
  if valid_402656739 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656739
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656741: Call_DeleteParameters_402656729;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a list of parameters.
                                                                                         ## 
  let valid = call_402656741.validator(path, query, header, formData, body, _)
  let scheme = call_402656741.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656741.makeUrl(scheme.get, call_402656741.host, call_402656741.base,
                                   call_402656741.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656741, uri, valid, _)

proc call*(call_402656742: Call_DeleteParameters_402656729; body: JsonNode): Recallable =
  ## deleteParameters
  ## Delete a list of parameters.
  ##   body: JObject (required)
  var body_402656743 = newJObject()
  if body != nil:
    body_402656743 = body
  result = call_402656742.call(nil, nil, nil, nil, body_402656743)

var deleteParameters* = Call_DeleteParameters_402656729(
    name: "deleteParameters", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteParameters",
    validator: validate_DeleteParameters_402656730, base: "/",
    makeUrl: url_DeleteParameters_402656731,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeletePatchBaseline_402656744 = ref object of OpenApiRestCall_402656044
proc url_DeletePatchBaseline_402656746(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeletePatchBaseline_402656745(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a patch baseline.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656747 = header.getOrDefault("X-Amz-Target")
  valid_402656747 = validateParameter(valid_402656747, JString, required = true, default = newJString(
      "AmazonSSM.DeletePatchBaseline"))
  if valid_402656747 != nil:
    section.add "X-Amz-Target", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Security-Token", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Signature")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Signature", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-Algorithm", valid_402656751
  var valid_402656752 = header.getOrDefault("X-Amz-Date")
  valid_402656752 = validateParameter(valid_402656752, JString,
                                      required = false, default = nil)
  if valid_402656752 != nil:
    section.add "X-Amz-Date", valid_402656752
  var valid_402656753 = header.getOrDefault("X-Amz-Credential")
  valid_402656753 = validateParameter(valid_402656753, JString,
                                      required = false, default = nil)
  if valid_402656753 != nil:
    section.add "X-Amz-Credential", valid_402656753
  var valid_402656754 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656754 = validateParameter(valid_402656754, JString,
                                      required = false, default = nil)
  if valid_402656754 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656754
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656756: Call_DeletePatchBaseline_402656744;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a patch baseline.
                                                                                         ## 
  let valid = call_402656756.validator(path, query, header, formData, body, _)
  let scheme = call_402656756.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656756.makeUrl(scheme.get, call_402656756.host, call_402656756.base,
                                   call_402656756.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656756, uri, valid, _)

proc call*(call_402656757: Call_DeletePatchBaseline_402656744; body: JsonNode): Recallable =
  ## deletePatchBaseline
  ## Deletes a patch baseline.
  ##   body: JObject (required)
  var body_402656758 = newJObject()
  if body != nil:
    body_402656758 = body
  result = call_402656757.call(nil, nil, nil, nil, body_402656758)

var deletePatchBaseline* = Call_DeletePatchBaseline_402656744(
    name: "deletePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeletePatchBaseline",
    validator: validate_DeletePatchBaseline_402656745, base: "/",
    makeUrl: url_DeletePatchBaseline_402656746,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteResourceDataSync_402656759 = ref object of OpenApiRestCall_402656044
proc url_DeleteResourceDataSync_402656761(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteResourceDataSync_402656760(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to data on managed instances are no longer synced to or from the target. Deleting a sync configuration does not delete data.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656762 = header.getOrDefault("X-Amz-Target")
  valid_402656762 = validateParameter(valid_402656762, JString, required = true, default = newJString(
      "AmazonSSM.DeleteResourceDataSync"))
  if valid_402656762 != nil:
    section.add "X-Amz-Target", valid_402656762
  var valid_402656763 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656763 = validateParameter(valid_402656763, JString,
                                      required = false, default = nil)
  if valid_402656763 != nil:
    section.add "X-Amz-Security-Token", valid_402656763
  var valid_402656764 = header.getOrDefault("X-Amz-Signature")
  valid_402656764 = validateParameter(valid_402656764, JString,
                                      required = false, default = nil)
  if valid_402656764 != nil:
    section.add "X-Amz-Signature", valid_402656764
  var valid_402656765 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656765 = validateParameter(valid_402656765, JString,
                                      required = false, default = nil)
  if valid_402656765 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656765
  var valid_402656766 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656766 = validateParameter(valid_402656766, JString,
                                      required = false, default = nil)
  if valid_402656766 != nil:
    section.add "X-Amz-Algorithm", valid_402656766
  var valid_402656767 = header.getOrDefault("X-Amz-Date")
  valid_402656767 = validateParameter(valid_402656767, JString,
                                      required = false, default = nil)
  if valid_402656767 != nil:
    section.add "X-Amz-Date", valid_402656767
  var valid_402656768 = header.getOrDefault("X-Amz-Credential")
  valid_402656768 = validateParameter(valid_402656768, JString,
                                      required = false, default = nil)
  if valid_402656768 != nil:
    section.add "X-Amz-Credential", valid_402656768
  var valid_402656769 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656769 = validateParameter(valid_402656769, JString,
                                      required = false, default = nil)
  if valid_402656769 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656769
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656771: Call_DeleteResourceDataSync_402656759;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to data on managed instances are no longer synced to or from the target. Deleting a sync configuration does not delete data.
                                                                                         ## 
  let valid = call_402656771.validator(path, query, header, formData, body, _)
  let scheme = call_402656771.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656771.makeUrl(scheme.get, call_402656771.host, call_402656771.base,
                                   call_402656771.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656771, uri, valid, _)

proc call*(call_402656772: Call_DeleteResourceDataSync_402656759; body: JsonNode): Recallable =
  ## deleteResourceDataSync
  ## Deletes a Resource Data Sync configuration. After the configuration is deleted, changes to data on managed instances are no longer synced to or from the target. Deleting a sync configuration does not delete data.
  ##   
                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402656773 = newJObject()
  if body != nil:
    body_402656773 = body
  result = call_402656772.call(nil, nil, nil, nil, body_402656773)

var deleteResourceDataSync* = Call_DeleteResourceDataSync_402656759(
    name: "deleteResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeleteResourceDataSync",
    validator: validate_DeleteResourceDataSync_402656760, base: "/",
    makeUrl: url_DeleteResourceDataSync_402656761,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterManagedInstance_402656774 = ref object of OpenApiRestCall_402656044
proc url_DeregisterManagedInstance_402656776(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterManagedInstance_402656775(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656777 = header.getOrDefault("X-Amz-Target")
  valid_402656777 = validateParameter(valid_402656777, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterManagedInstance"))
  if valid_402656777 != nil:
    section.add "X-Amz-Target", valid_402656777
  var valid_402656778 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656778 = validateParameter(valid_402656778, JString,
                                      required = false, default = nil)
  if valid_402656778 != nil:
    section.add "X-Amz-Security-Token", valid_402656778
  var valid_402656779 = header.getOrDefault("X-Amz-Signature")
  valid_402656779 = validateParameter(valid_402656779, JString,
                                      required = false, default = nil)
  if valid_402656779 != nil:
    section.add "X-Amz-Signature", valid_402656779
  var valid_402656780 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656780 = validateParameter(valid_402656780, JString,
                                      required = false, default = nil)
  if valid_402656780 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656780
  var valid_402656781 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656781 = validateParameter(valid_402656781, JString,
                                      required = false, default = nil)
  if valid_402656781 != nil:
    section.add "X-Amz-Algorithm", valid_402656781
  var valid_402656782 = header.getOrDefault("X-Amz-Date")
  valid_402656782 = validateParameter(valid_402656782, JString,
                                      required = false, default = nil)
  if valid_402656782 != nil:
    section.add "X-Amz-Date", valid_402656782
  var valid_402656783 = header.getOrDefault("X-Amz-Credential")
  valid_402656783 = validateParameter(valid_402656783, JString,
                                      required = false, default = nil)
  if valid_402656783 != nil:
    section.add "X-Amz-Credential", valid_402656783
  var valid_402656784 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656784 = validateParameter(valid_402656784, JString,
                                      required = false, default = nil)
  if valid_402656784 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656784
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656786: Call_DeregisterManagedInstance_402656774;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
                                                                                         ## 
  let valid = call_402656786.validator(path, query, header, formData, body, _)
  let scheme = call_402656786.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656786.makeUrl(scheme.get, call_402656786.host, call_402656786.base,
                                   call_402656786.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656786, uri, valid, _)

proc call*(call_402656787: Call_DeregisterManagedInstance_402656774;
           body: JsonNode): Recallable =
  ## deregisterManagedInstance
  ## Removes the server or virtual machine from the list of registered servers. You can reregister the instance again at any time. If you don't plan to use Run Command on the server, we suggest uninstalling SSM Agent first.
  ##   
                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402656788 = newJObject()
  if body != nil:
    body_402656788 = body
  result = call_402656787.call(nil, nil, nil, nil, body_402656788)

var deregisterManagedInstance* = Call_DeregisterManagedInstance_402656774(
    name: "deregisterManagedInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterManagedInstance",
    validator: validate_DeregisterManagedInstance_402656775, base: "/",
    makeUrl: url_DeregisterManagedInstance_402656776,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterPatchBaselineForPatchGroup_402656789 = ref object of OpenApiRestCall_402656044
proc url_DeregisterPatchBaselineForPatchGroup_402656791(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterPatchBaselineForPatchGroup_402656790(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Removes a patch group from a patch baseline.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656792 = header.getOrDefault("X-Amz-Target")
  valid_402656792 = validateParameter(valid_402656792, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterPatchBaselineForPatchGroup"))
  if valid_402656792 != nil:
    section.add "X-Amz-Target", valid_402656792
  var valid_402656793 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656793 = validateParameter(valid_402656793, JString,
                                      required = false, default = nil)
  if valid_402656793 != nil:
    section.add "X-Amz-Security-Token", valid_402656793
  var valid_402656794 = header.getOrDefault("X-Amz-Signature")
  valid_402656794 = validateParameter(valid_402656794, JString,
                                      required = false, default = nil)
  if valid_402656794 != nil:
    section.add "X-Amz-Signature", valid_402656794
  var valid_402656795 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656795 = validateParameter(valid_402656795, JString,
                                      required = false, default = nil)
  if valid_402656795 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656795
  var valid_402656796 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656796 = validateParameter(valid_402656796, JString,
                                      required = false, default = nil)
  if valid_402656796 != nil:
    section.add "X-Amz-Algorithm", valid_402656796
  var valid_402656797 = header.getOrDefault("X-Amz-Date")
  valid_402656797 = validateParameter(valid_402656797, JString,
                                      required = false, default = nil)
  if valid_402656797 != nil:
    section.add "X-Amz-Date", valid_402656797
  var valid_402656798 = header.getOrDefault("X-Amz-Credential")
  valid_402656798 = validateParameter(valid_402656798, JString,
                                      required = false, default = nil)
  if valid_402656798 != nil:
    section.add "X-Amz-Credential", valid_402656798
  var valid_402656799 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656799 = validateParameter(valid_402656799, JString,
                                      required = false, default = nil)
  if valid_402656799 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656799
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656801: Call_DeregisterPatchBaselineForPatchGroup_402656789;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a patch group from a patch baseline.
                                                                                         ## 
  let valid = call_402656801.validator(path, query, header, formData, body, _)
  let scheme = call_402656801.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656801.makeUrl(scheme.get, call_402656801.host, call_402656801.base,
                                   call_402656801.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656801, uri, valid, _)

proc call*(call_402656802: Call_DeregisterPatchBaselineForPatchGroup_402656789;
           body: JsonNode): Recallable =
  ## deregisterPatchBaselineForPatchGroup
  ## Removes a patch group from a patch baseline.
  ##   body: JObject (required)
  var body_402656803 = newJObject()
  if body != nil:
    body_402656803 = body
  result = call_402656802.call(nil, nil, nil, nil, body_402656803)

var deregisterPatchBaselineForPatchGroup* = Call_DeregisterPatchBaselineForPatchGroup_402656789(
    name: "deregisterPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterPatchBaselineForPatchGroup",
    validator: validate_DeregisterPatchBaselineForPatchGroup_402656790,
    base: "/", makeUrl: url_DeregisterPatchBaselineForPatchGroup_402656791,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTargetFromMaintenanceWindow_402656804 = ref object of OpenApiRestCall_402656044
proc url_DeregisterTargetFromMaintenanceWindow_402656806(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterTargetFromMaintenanceWindow_402656805(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Removes a target from a maintenance window.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656807 = header.getOrDefault("X-Amz-Target")
  valid_402656807 = validateParameter(valid_402656807, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTargetFromMaintenanceWindow"))
  if valid_402656807 != nil:
    section.add "X-Amz-Target", valid_402656807
  var valid_402656808 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656808 = validateParameter(valid_402656808, JString,
                                      required = false, default = nil)
  if valid_402656808 != nil:
    section.add "X-Amz-Security-Token", valid_402656808
  var valid_402656809 = header.getOrDefault("X-Amz-Signature")
  valid_402656809 = validateParameter(valid_402656809, JString,
                                      required = false, default = nil)
  if valid_402656809 != nil:
    section.add "X-Amz-Signature", valid_402656809
  var valid_402656810 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656810 = validateParameter(valid_402656810, JString,
                                      required = false, default = nil)
  if valid_402656810 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656810
  var valid_402656811 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656811 = validateParameter(valid_402656811, JString,
                                      required = false, default = nil)
  if valid_402656811 != nil:
    section.add "X-Amz-Algorithm", valid_402656811
  var valid_402656812 = header.getOrDefault("X-Amz-Date")
  valid_402656812 = validateParameter(valid_402656812, JString,
                                      required = false, default = nil)
  if valid_402656812 != nil:
    section.add "X-Amz-Date", valid_402656812
  var valid_402656813 = header.getOrDefault("X-Amz-Credential")
  valid_402656813 = validateParameter(valid_402656813, JString,
                                      required = false, default = nil)
  if valid_402656813 != nil:
    section.add "X-Amz-Credential", valid_402656813
  var valid_402656814 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656814 = validateParameter(valid_402656814, JString,
                                      required = false, default = nil)
  if valid_402656814 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656814
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656816: Call_DeregisterTargetFromMaintenanceWindow_402656804;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a target from a maintenance window.
                                                                                         ## 
  let valid = call_402656816.validator(path, query, header, formData, body, _)
  let scheme = call_402656816.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656816.makeUrl(scheme.get, call_402656816.host, call_402656816.base,
                                   call_402656816.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656816, uri, valid, _)

proc call*(call_402656817: Call_DeregisterTargetFromMaintenanceWindow_402656804;
           body: JsonNode): Recallable =
  ## deregisterTargetFromMaintenanceWindow
  ## Removes a target from a maintenance window.
  ##   body: JObject (required)
  var body_402656818 = newJObject()
  if body != nil:
    body_402656818 = body
  result = call_402656817.call(nil, nil, nil, nil, body_402656818)

var deregisterTargetFromMaintenanceWindow* = Call_DeregisterTargetFromMaintenanceWindow_402656804(
    name: "deregisterTargetFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTargetFromMaintenanceWindow",
    validator: validate_DeregisterTargetFromMaintenanceWindow_402656805,
    base: "/", makeUrl: url_DeregisterTargetFromMaintenanceWindow_402656806,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeregisterTaskFromMaintenanceWindow_402656819 = ref object of OpenApiRestCall_402656044
proc url_DeregisterTaskFromMaintenanceWindow_402656821(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeregisterTaskFromMaintenanceWindow_402656820(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Removes a task from a maintenance window.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656822 = header.getOrDefault("X-Amz-Target")
  valid_402656822 = validateParameter(valid_402656822, JString, required = true, default = newJString(
      "AmazonSSM.DeregisterTaskFromMaintenanceWindow"))
  if valid_402656822 != nil:
    section.add "X-Amz-Target", valid_402656822
  var valid_402656823 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656823 = validateParameter(valid_402656823, JString,
                                      required = false, default = nil)
  if valid_402656823 != nil:
    section.add "X-Amz-Security-Token", valid_402656823
  var valid_402656824 = header.getOrDefault("X-Amz-Signature")
  valid_402656824 = validateParameter(valid_402656824, JString,
                                      required = false, default = nil)
  if valid_402656824 != nil:
    section.add "X-Amz-Signature", valid_402656824
  var valid_402656825 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656825 = validateParameter(valid_402656825, JString,
                                      required = false, default = nil)
  if valid_402656825 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656825
  var valid_402656826 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656826 = validateParameter(valid_402656826, JString,
                                      required = false, default = nil)
  if valid_402656826 != nil:
    section.add "X-Amz-Algorithm", valid_402656826
  var valid_402656827 = header.getOrDefault("X-Amz-Date")
  valid_402656827 = validateParameter(valid_402656827, JString,
                                      required = false, default = nil)
  if valid_402656827 != nil:
    section.add "X-Amz-Date", valid_402656827
  var valid_402656828 = header.getOrDefault("X-Amz-Credential")
  valid_402656828 = validateParameter(valid_402656828, JString,
                                      required = false, default = nil)
  if valid_402656828 != nil:
    section.add "X-Amz-Credential", valid_402656828
  var valid_402656829 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656829 = validateParameter(valid_402656829, JString,
                                      required = false, default = nil)
  if valid_402656829 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656829
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656831: Call_DeregisterTaskFromMaintenanceWindow_402656819;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes a task from a maintenance window.
                                                                                         ## 
  let valid = call_402656831.validator(path, query, header, formData, body, _)
  let scheme = call_402656831.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656831.makeUrl(scheme.get, call_402656831.host, call_402656831.base,
                                   call_402656831.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656831, uri, valid, _)

proc call*(call_402656832: Call_DeregisterTaskFromMaintenanceWindow_402656819;
           body: JsonNode): Recallable =
  ## deregisterTaskFromMaintenanceWindow
  ## Removes a task from a maintenance window.
  ##   body: JObject (required)
  var body_402656833 = newJObject()
  if body != nil:
    body_402656833 = body
  result = call_402656832.call(nil, nil, nil, nil, body_402656833)

var deregisterTaskFromMaintenanceWindow* = Call_DeregisterTaskFromMaintenanceWindow_402656819(
    name: "deregisterTaskFromMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DeregisterTaskFromMaintenanceWindow",
    validator: validate_DeregisterTaskFromMaintenanceWindow_402656820,
    base: "/", makeUrl: url_DeregisterTaskFromMaintenanceWindow_402656821,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeActivations_402656834 = ref object of OpenApiRestCall_402656044
proc url_DescribeActivations_402656836(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeActivations_402656835(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402656837 = query.getOrDefault("MaxResults")
  valid_402656837 = validateParameter(valid_402656837, JString,
                                      required = false, default = nil)
  if valid_402656837 != nil:
    section.add "MaxResults", valid_402656837
  var valid_402656838 = query.getOrDefault("NextToken")
  valid_402656838 = validateParameter(valid_402656838, JString,
                                      required = false, default = nil)
  if valid_402656838 != nil:
    section.add "NextToken", valid_402656838
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656839 = header.getOrDefault("X-Amz-Target")
  valid_402656839 = validateParameter(valid_402656839, JString, required = true, default = newJString(
      "AmazonSSM.DescribeActivations"))
  if valid_402656839 != nil:
    section.add "X-Amz-Target", valid_402656839
  var valid_402656840 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656840 = validateParameter(valid_402656840, JString,
                                      required = false, default = nil)
  if valid_402656840 != nil:
    section.add "X-Amz-Security-Token", valid_402656840
  var valid_402656841 = header.getOrDefault("X-Amz-Signature")
  valid_402656841 = validateParameter(valid_402656841, JString,
                                      required = false, default = nil)
  if valid_402656841 != nil:
    section.add "X-Amz-Signature", valid_402656841
  var valid_402656842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656842 = validateParameter(valid_402656842, JString,
                                      required = false, default = nil)
  if valid_402656842 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656842
  var valid_402656843 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656843 = validateParameter(valid_402656843, JString,
                                      required = false, default = nil)
  if valid_402656843 != nil:
    section.add "X-Amz-Algorithm", valid_402656843
  var valid_402656844 = header.getOrDefault("X-Amz-Date")
  valid_402656844 = validateParameter(valid_402656844, JString,
                                      required = false, default = nil)
  if valid_402656844 != nil:
    section.add "X-Amz-Date", valid_402656844
  var valid_402656845 = header.getOrDefault("X-Amz-Credential")
  valid_402656845 = validateParameter(valid_402656845, JString,
                                      required = false, default = nil)
  if valid_402656845 != nil:
    section.add "X-Amz-Credential", valid_402656845
  var valid_402656846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656846 = validateParameter(valid_402656846, JString,
                                      required = false, default = nil)
  if valid_402656846 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656848: Call_DescribeActivations_402656834;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
                                                                                         ## 
  let valid = call_402656848.validator(path, query, header, formData, body, _)
  let scheme = call_402656848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656848.makeUrl(scheme.get, call_402656848.host, call_402656848.base,
                                   call_402656848.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656848, uri, valid, _)

proc call*(call_402656849: Call_DescribeActivations_402656834; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeActivations
  ## Describes details about the activation, such as the date and time the activation was created, its expiration date, the IAM role assigned to the instances in the activation, and the number of instances registered by using this activation.
  ##   
                                                                                                                                                                                                                                                  ## MaxResults: string
                                                                                                                                                                                                                                                  ##             
                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                                                                                  ## limit
  ##   
                                                                                                                                                                                                                                                          ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                     ## NextToken: string
                                                                                                                                                                                                                                                                                     ##            
                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                     ## Pagination 
                                                                                                                                                                                                                                                                                     ## token
  var query_402656850 = newJObject()
  var body_402656851 = newJObject()
  add(query_402656850, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402656851 = body
  add(query_402656850, "NextToken", newJString(NextToken))
  result = call_402656849.call(nil, query_402656850, nil, nil, body_402656851)

var describeActivations* = Call_DescribeActivations_402656834(
    name: "describeActivations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeActivations",
    validator: validate_DescribeActivations_402656835, base: "/",
    makeUrl: url_DescribeActivations_402656836,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociation_402656852 = ref object of OpenApiRestCall_402656044
proc url_DescribeAssociation_402656854(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAssociation_402656853(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656855 = header.getOrDefault("X-Amz-Target")
  valid_402656855 = validateParameter(valid_402656855, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociation"))
  if valid_402656855 != nil:
    section.add "X-Amz-Target", valid_402656855
  var valid_402656856 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656856 = validateParameter(valid_402656856, JString,
                                      required = false, default = nil)
  if valid_402656856 != nil:
    section.add "X-Amz-Security-Token", valid_402656856
  var valid_402656857 = header.getOrDefault("X-Amz-Signature")
  valid_402656857 = validateParameter(valid_402656857, JString,
                                      required = false, default = nil)
  if valid_402656857 != nil:
    section.add "X-Amz-Signature", valid_402656857
  var valid_402656858 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656858 = validateParameter(valid_402656858, JString,
                                      required = false, default = nil)
  if valid_402656858 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656858
  var valid_402656859 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656859 = validateParameter(valid_402656859, JString,
                                      required = false, default = nil)
  if valid_402656859 != nil:
    section.add "X-Amz-Algorithm", valid_402656859
  var valid_402656860 = header.getOrDefault("X-Amz-Date")
  valid_402656860 = validateParameter(valid_402656860, JString,
                                      required = false, default = nil)
  if valid_402656860 != nil:
    section.add "X-Amz-Date", valid_402656860
  var valid_402656861 = header.getOrDefault("X-Amz-Credential")
  valid_402656861 = validateParameter(valid_402656861, JString,
                                      required = false, default = nil)
  if valid_402656861 != nil:
    section.add "X-Amz-Credential", valid_402656861
  var valid_402656862 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656862 = validateParameter(valid_402656862, JString,
                                      required = false, default = nil)
  if valid_402656862 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656862
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656864: Call_DescribeAssociation_402656852;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
                                                                                         ## 
  let valid = call_402656864.validator(path, query, header, formData, body, _)
  let scheme = call_402656864.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656864.makeUrl(scheme.get, call_402656864.host, call_402656864.base,
                                   call_402656864.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656864, uri, valid, _)

proc call*(call_402656865: Call_DescribeAssociation_402656852; body: JsonNode): Recallable =
  ## describeAssociation
  ## Describes the association for the specified target or instance. If you created the association by using the <code>Targets</code> parameter, then you must retrieve the association by using the association ID. If you created the association by specifying an instance ID and a Systems Manager document, then you retrieve the association by specifying the document name and the instance ID. 
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402656866 = newJObject()
  if body != nil:
    body_402656866 = body
  result = call_402656865.call(nil, nil, nil, nil, body_402656866)

var describeAssociation* = Call_DescribeAssociation_402656852(
    name: "describeAssociation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociation",
    validator: validate_DescribeAssociation_402656853, base: "/",
    makeUrl: url_DescribeAssociation_402656854,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutionTargets_402656867 = ref object of OpenApiRestCall_402656044
proc url_DescribeAssociationExecutionTargets_402656869(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAssociationExecutionTargets_402656868(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Use this API action to view information about a specific execution of a specific association.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656870 = header.getOrDefault("X-Amz-Target")
  valid_402656870 = validateParameter(valid_402656870, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutionTargets"))
  if valid_402656870 != nil:
    section.add "X-Amz-Target", valid_402656870
  var valid_402656871 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656871 = validateParameter(valid_402656871, JString,
                                      required = false, default = nil)
  if valid_402656871 != nil:
    section.add "X-Amz-Security-Token", valid_402656871
  var valid_402656872 = header.getOrDefault("X-Amz-Signature")
  valid_402656872 = validateParameter(valid_402656872, JString,
                                      required = false, default = nil)
  if valid_402656872 != nil:
    section.add "X-Amz-Signature", valid_402656872
  var valid_402656873 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656873 = validateParameter(valid_402656873, JString,
                                      required = false, default = nil)
  if valid_402656873 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656873
  var valid_402656874 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656874 = validateParameter(valid_402656874, JString,
                                      required = false, default = nil)
  if valid_402656874 != nil:
    section.add "X-Amz-Algorithm", valid_402656874
  var valid_402656875 = header.getOrDefault("X-Amz-Date")
  valid_402656875 = validateParameter(valid_402656875, JString,
                                      required = false, default = nil)
  if valid_402656875 != nil:
    section.add "X-Amz-Date", valid_402656875
  var valid_402656876 = header.getOrDefault("X-Amz-Credential")
  valid_402656876 = validateParameter(valid_402656876, JString,
                                      required = false, default = nil)
  if valid_402656876 != nil:
    section.add "X-Amz-Credential", valid_402656876
  var valid_402656877 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656877 = validateParameter(valid_402656877, JString,
                                      required = false, default = nil)
  if valid_402656877 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656877
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656879: Call_DescribeAssociationExecutionTargets_402656867;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Use this API action to view information about a specific execution of a specific association.
                                                                                         ## 
  let valid = call_402656879.validator(path, query, header, formData, body, _)
  let scheme = call_402656879.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656879.makeUrl(scheme.get, call_402656879.host, call_402656879.base,
                                   call_402656879.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656879, uri, valid, _)

proc call*(call_402656880: Call_DescribeAssociationExecutionTargets_402656867;
           body: JsonNode): Recallable =
  ## describeAssociationExecutionTargets
  ## Use this API action to view information about a specific execution of a specific association.
  ##   
                                                                                                  ## body: JObject (required)
  var body_402656881 = newJObject()
  if body != nil:
    body_402656881 = body
  result = call_402656880.call(nil, nil, nil, nil, body_402656881)

var describeAssociationExecutionTargets* = Call_DescribeAssociationExecutionTargets_402656867(
    name: "describeAssociationExecutionTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutionTargets",
    validator: validate_DescribeAssociationExecutionTargets_402656868,
    base: "/", makeUrl: url_DescribeAssociationExecutionTargets_402656869,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAssociationExecutions_402656882 = ref object of OpenApiRestCall_402656044
proc url_DescribeAssociationExecutions_402656884(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAssociationExecutions_402656883(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Use this API action to view all executions for a specific association ID. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656885 = header.getOrDefault("X-Amz-Target")
  valid_402656885 = validateParameter(valid_402656885, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAssociationExecutions"))
  if valid_402656885 != nil:
    section.add "X-Amz-Target", valid_402656885
  var valid_402656886 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656886 = validateParameter(valid_402656886, JString,
                                      required = false, default = nil)
  if valid_402656886 != nil:
    section.add "X-Amz-Security-Token", valid_402656886
  var valid_402656887 = header.getOrDefault("X-Amz-Signature")
  valid_402656887 = validateParameter(valid_402656887, JString,
                                      required = false, default = nil)
  if valid_402656887 != nil:
    section.add "X-Amz-Signature", valid_402656887
  var valid_402656888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656888 = validateParameter(valid_402656888, JString,
                                      required = false, default = nil)
  if valid_402656888 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656888
  var valid_402656889 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656889 = validateParameter(valid_402656889, JString,
                                      required = false, default = nil)
  if valid_402656889 != nil:
    section.add "X-Amz-Algorithm", valid_402656889
  var valid_402656890 = header.getOrDefault("X-Amz-Date")
  valid_402656890 = validateParameter(valid_402656890, JString,
                                      required = false, default = nil)
  if valid_402656890 != nil:
    section.add "X-Amz-Date", valid_402656890
  var valid_402656891 = header.getOrDefault("X-Amz-Credential")
  valid_402656891 = validateParameter(valid_402656891, JString,
                                      required = false, default = nil)
  if valid_402656891 != nil:
    section.add "X-Amz-Credential", valid_402656891
  var valid_402656892 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656892 = validateParameter(valid_402656892, JString,
                                      required = false, default = nil)
  if valid_402656892 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656894: Call_DescribeAssociationExecutions_402656882;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Use this API action to view all executions for a specific association ID. 
                                                                                         ## 
  let valid = call_402656894.validator(path, query, header, formData, body, _)
  let scheme = call_402656894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656894.makeUrl(scheme.get, call_402656894.host, call_402656894.base,
                                   call_402656894.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656894, uri, valid, _)

proc call*(call_402656895: Call_DescribeAssociationExecutions_402656882;
           body: JsonNode): Recallable =
  ## describeAssociationExecutions
  ## Use this API action to view all executions for a specific association ID. 
  ##   
                                                                               ## body: JObject (required)
  var body_402656896 = newJObject()
  if body != nil:
    body_402656896 = body
  result = call_402656895.call(nil, nil, nil, nil, body_402656896)

var describeAssociationExecutions* = Call_DescribeAssociationExecutions_402656882(
    name: "describeAssociationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAssociationExecutions",
    validator: validate_DescribeAssociationExecutions_402656883, base: "/",
    makeUrl: url_DescribeAssociationExecutions_402656884,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationExecutions_402656897 = ref object of OpenApiRestCall_402656044
proc url_DescribeAutomationExecutions_402656899(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAutomationExecutions_402656898(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Provides details about all active and terminated Automation executions.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656900 = header.getOrDefault("X-Amz-Target")
  valid_402656900 = validateParameter(valid_402656900, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationExecutions"))
  if valid_402656900 != nil:
    section.add "X-Amz-Target", valid_402656900
  var valid_402656901 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656901 = validateParameter(valid_402656901, JString,
                                      required = false, default = nil)
  if valid_402656901 != nil:
    section.add "X-Amz-Security-Token", valid_402656901
  var valid_402656902 = header.getOrDefault("X-Amz-Signature")
  valid_402656902 = validateParameter(valid_402656902, JString,
                                      required = false, default = nil)
  if valid_402656902 != nil:
    section.add "X-Amz-Signature", valid_402656902
  var valid_402656903 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656903 = validateParameter(valid_402656903, JString,
                                      required = false, default = nil)
  if valid_402656903 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656903
  var valid_402656904 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656904 = validateParameter(valid_402656904, JString,
                                      required = false, default = nil)
  if valid_402656904 != nil:
    section.add "X-Amz-Algorithm", valid_402656904
  var valid_402656905 = header.getOrDefault("X-Amz-Date")
  valid_402656905 = validateParameter(valid_402656905, JString,
                                      required = false, default = nil)
  if valid_402656905 != nil:
    section.add "X-Amz-Date", valid_402656905
  var valid_402656906 = header.getOrDefault("X-Amz-Credential")
  valid_402656906 = validateParameter(valid_402656906, JString,
                                      required = false, default = nil)
  if valid_402656906 != nil:
    section.add "X-Amz-Credential", valid_402656906
  var valid_402656907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656907 = validateParameter(valid_402656907, JString,
                                      required = false, default = nil)
  if valid_402656907 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656909: Call_DescribeAutomationExecutions_402656897;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Provides details about all active and terminated Automation executions.
                                                                                         ## 
  let valid = call_402656909.validator(path, query, header, formData, body, _)
  let scheme = call_402656909.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656909.makeUrl(scheme.get, call_402656909.host, call_402656909.base,
                                   call_402656909.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656909, uri, valid, _)

proc call*(call_402656910: Call_DescribeAutomationExecutions_402656897;
           body: JsonNode): Recallable =
  ## describeAutomationExecutions
  ## Provides details about all active and terminated Automation executions.
  ##   
                                                                            ## body: JObject (required)
  var body_402656911 = newJObject()
  if body != nil:
    body_402656911 = body
  result = call_402656910.call(nil, nil, nil, nil, body_402656911)

var describeAutomationExecutions* = Call_DescribeAutomationExecutions_402656897(
    name: "describeAutomationExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationExecutions",
    validator: validate_DescribeAutomationExecutions_402656898, base: "/",
    makeUrl: url_DescribeAutomationExecutions_402656899,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAutomationStepExecutions_402656912 = ref object of OpenApiRestCall_402656044
proc url_DescribeAutomationStepExecutions_402656914(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAutomationStepExecutions_402656913(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Information about all active and terminated step executions in an Automation workflow.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656915 = header.getOrDefault("X-Amz-Target")
  valid_402656915 = validateParameter(valid_402656915, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAutomationStepExecutions"))
  if valid_402656915 != nil:
    section.add "X-Amz-Target", valid_402656915
  var valid_402656916 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656916 = validateParameter(valid_402656916, JString,
                                      required = false, default = nil)
  if valid_402656916 != nil:
    section.add "X-Amz-Security-Token", valid_402656916
  var valid_402656917 = header.getOrDefault("X-Amz-Signature")
  valid_402656917 = validateParameter(valid_402656917, JString,
                                      required = false, default = nil)
  if valid_402656917 != nil:
    section.add "X-Amz-Signature", valid_402656917
  var valid_402656918 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656918 = validateParameter(valid_402656918, JString,
                                      required = false, default = nil)
  if valid_402656918 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656918
  var valid_402656919 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656919 = validateParameter(valid_402656919, JString,
                                      required = false, default = nil)
  if valid_402656919 != nil:
    section.add "X-Amz-Algorithm", valid_402656919
  var valid_402656920 = header.getOrDefault("X-Amz-Date")
  valid_402656920 = validateParameter(valid_402656920, JString,
                                      required = false, default = nil)
  if valid_402656920 != nil:
    section.add "X-Amz-Date", valid_402656920
  var valid_402656921 = header.getOrDefault("X-Amz-Credential")
  valid_402656921 = validateParameter(valid_402656921, JString,
                                      required = false, default = nil)
  if valid_402656921 != nil:
    section.add "X-Amz-Credential", valid_402656921
  var valid_402656922 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656922 = validateParameter(valid_402656922, JString,
                                      required = false, default = nil)
  if valid_402656922 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656922
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656924: Call_DescribeAutomationStepExecutions_402656912;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Information about all active and terminated step executions in an Automation workflow.
                                                                                         ## 
  let valid = call_402656924.validator(path, query, header, formData, body, _)
  let scheme = call_402656924.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656924.makeUrl(scheme.get, call_402656924.host, call_402656924.base,
                                   call_402656924.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656924, uri, valid, _)

proc call*(call_402656925: Call_DescribeAutomationStepExecutions_402656912;
           body: JsonNode): Recallable =
  ## describeAutomationStepExecutions
  ## Information about all active and terminated step executions in an Automation workflow.
  ##   
                                                                                           ## body: JObject (required)
  var body_402656926 = newJObject()
  if body != nil:
    body_402656926 = body
  result = call_402656925.call(nil, nil, nil, nil, body_402656926)

var describeAutomationStepExecutions* = Call_DescribeAutomationStepExecutions_402656912(
    name: "describeAutomationStepExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAutomationStepExecutions",
    validator: validate_DescribeAutomationStepExecutions_402656913, base: "/",
    makeUrl: url_DescribeAutomationStepExecutions_402656914,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeAvailablePatches_402656927 = ref object of OpenApiRestCall_402656044
proc url_DescribeAvailablePatches_402656929(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeAvailablePatches_402656928(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists all patches eligible to be included in a patch baseline.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656930 = header.getOrDefault("X-Amz-Target")
  valid_402656930 = validateParameter(valid_402656930, JString, required = true, default = newJString(
      "AmazonSSM.DescribeAvailablePatches"))
  if valid_402656930 != nil:
    section.add "X-Amz-Target", valid_402656930
  var valid_402656931 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656931 = validateParameter(valid_402656931, JString,
                                      required = false, default = nil)
  if valid_402656931 != nil:
    section.add "X-Amz-Security-Token", valid_402656931
  var valid_402656932 = header.getOrDefault("X-Amz-Signature")
  valid_402656932 = validateParameter(valid_402656932, JString,
                                      required = false, default = nil)
  if valid_402656932 != nil:
    section.add "X-Amz-Signature", valid_402656932
  var valid_402656933 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656933 = validateParameter(valid_402656933, JString,
                                      required = false, default = nil)
  if valid_402656933 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656933
  var valid_402656934 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656934 = validateParameter(valid_402656934, JString,
                                      required = false, default = nil)
  if valid_402656934 != nil:
    section.add "X-Amz-Algorithm", valid_402656934
  var valid_402656935 = header.getOrDefault("X-Amz-Date")
  valid_402656935 = validateParameter(valid_402656935, JString,
                                      required = false, default = nil)
  if valid_402656935 != nil:
    section.add "X-Amz-Date", valid_402656935
  var valid_402656936 = header.getOrDefault("X-Amz-Credential")
  valid_402656936 = validateParameter(valid_402656936, JString,
                                      required = false, default = nil)
  if valid_402656936 != nil:
    section.add "X-Amz-Credential", valid_402656936
  var valid_402656937 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656937 = validateParameter(valid_402656937, JString,
                                      required = false, default = nil)
  if valid_402656937 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656937
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656939: Call_DescribeAvailablePatches_402656927;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all patches eligible to be included in a patch baseline.
                                                                                         ## 
  let valid = call_402656939.validator(path, query, header, formData, body, _)
  let scheme = call_402656939.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656939.makeUrl(scheme.get, call_402656939.host, call_402656939.base,
                                   call_402656939.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656939, uri, valid, _)

proc call*(call_402656940: Call_DescribeAvailablePatches_402656927;
           body: JsonNode): Recallable =
  ## describeAvailablePatches
  ## Lists all patches eligible to be included in a patch baseline.
  ##   body: JObject (required)
  var body_402656941 = newJObject()
  if body != nil:
    body_402656941 = body
  result = call_402656940.call(nil, nil, nil, nil, body_402656941)

var describeAvailablePatches* = Call_DescribeAvailablePatches_402656927(
    name: "describeAvailablePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeAvailablePatches",
    validator: validate_DescribeAvailablePatches_402656928, base: "/",
    makeUrl: url_DescribeAvailablePatches_402656929,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocument_402656942 = ref object of OpenApiRestCall_402656044
proc url_DescribeDocument_402656944(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDocument_402656943(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Describes the specified Systems Manager document.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656945 = header.getOrDefault("X-Amz-Target")
  valid_402656945 = validateParameter(valid_402656945, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocument"))
  if valid_402656945 != nil:
    section.add "X-Amz-Target", valid_402656945
  var valid_402656946 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656946 = validateParameter(valid_402656946, JString,
                                      required = false, default = nil)
  if valid_402656946 != nil:
    section.add "X-Amz-Security-Token", valid_402656946
  var valid_402656947 = header.getOrDefault("X-Amz-Signature")
  valid_402656947 = validateParameter(valid_402656947, JString,
                                      required = false, default = nil)
  if valid_402656947 != nil:
    section.add "X-Amz-Signature", valid_402656947
  var valid_402656948 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656948 = validateParameter(valid_402656948, JString,
                                      required = false, default = nil)
  if valid_402656948 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656948
  var valid_402656949 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656949 = validateParameter(valid_402656949, JString,
                                      required = false, default = nil)
  if valid_402656949 != nil:
    section.add "X-Amz-Algorithm", valid_402656949
  var valid_402656950 = header.getOrDefault("X-Amz-Date")
  valid_402656950 = validateParameter(valid_402656950, JString,
                                      required = false, default = nil)
  if valid_402656950 != nil:
    section.add "X-Amz-Date", valid_402656950
  var valid_402656951 = header.getOrDefault("X-Amz-Credential")
  valid_402656951 = validateParameter(valid_402656951, JString,
                                      required = false, default = nil)
  if valid_402656951 != nil:
    section.add "X-Amz-Credential", valid_402656951
  var valid_402656952 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656952 = validateParameter(valid_402656952, JString,
                                      required = false, default = nil)
  if valid_402656952 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656952
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656954: Call_DescribeDocument_402656942;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the specified Systems Manager document.
                                                                                         ## 
  let valid = call_402656954.validator(path, query, header, formData, body, _)
  let scheme = call_402656954.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656954.makeUrl(scheme.get, call_402656954.host, call_402656954.base,
                                   call_402656954.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656954, uri, valid, _)

proc call*(call_402656955: Call_DescribeDocument_402656942; body: JsonNode): Recallable =
  ## describeDocument
  ## Describes the specified Systems Manager document.
  ##   body: JObject (required)
  var body_402656956 = newJObject()
  if body != nil:
    body_402656956 = body
  result = call_402656955.call(nil, nil, nil, nil, body_402656956)

var describeDocument* = Call_DescribeDocument_402656942(
    name: "describeDocument", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocument",
    validator: validate_DescribeDocument_402656943, base: "/",
    makeUrl: url_DescribeDocument_402656944,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeDocumentPermission_402656957 = ref object of OpenApiRestCall_402656044
proc url_DescribeDocumentPermission_402656959(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeDocumentPermission_402656958(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656960 = header.getOrDefault("X-Amz-Target")
  valid_402656960 = validateParameter(valid_402656960, JString, required = true, default = newJString(
      "AmazonSSM.DescribeDocumentPermission"))
  if valid_402656960 != nil:
    section.add "X-Amz-Target", valid_402656960
  var valid_402656961 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656961 = validateParameter(valid_402656961, JString,
                                      required = false, default = nil)
  if valid_402656961 != nil:
    section.add "X-Amz-Security-Token", valid_402656961
  var valid_402656962 = header.getOrDefault("X-Amz-Signature")
  valid_402656962 = validateParameter(valid_402656962, JString,
                                      required = false, default = nil)
  if valid_402656962 != nil:
    section.add "X-Amz-Signature", valid_402656962
  var valid_402656963 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656963 = validateParameter(valid_402656963, JString,
                                      required = false, default = nil)
  if valid_402656963 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656963
  var valid_402656964 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656964 = validateParameter(valid_402656964, JString,
                                      required = false, default = nil)
  if valid_402656964 != nil:
    section.add "X-Amz-Algorithm", valid_402656964
  var valid_402656965 = header.getOrDefault("X-Amz-Date")
  valid_402656965 = validateParameter(valid_402656965, JString,
                                      required = false, default = nil)
  if valid_402656965 != nil:
    section.add "X-Amz-Date", valid_402656965
  var valid_402656966 = header.getOrDefault("X-Amz-Credential")
  valid_402656966 = validateParameter(valid_402656966, JString,
                                      required = false, default = nil)
  if valid_402656966 != nil:
    section.add "X-Amz-Credential", valid_402656966
  var valid_402656967 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656967 = validateParameter(valid_402656967, JString,
                                      required = false, default = nil)
  if valid_402656967 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656967
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656969: Call_DescribeDocumentPermission_402656957;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
                                                                                         ## 
  let valid = call_402656969.validator(path, query, header, formData, body, _)
  let scheme = call_402656969.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656969.makeUrl(scheme.get, call_402656969.host, call_402656969.base,
                                   call_402656969.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656969, uri, valid, _)

proc call*(call_402656970: Call_DescribeDocumentPermission_402656957;
           body: JsonNode): Recallable =
  ## describeDocumentPermission
  ## Describes the permissions for a Systems Manager document. If you created the document, you are the owner. If a document is shared, it can either be shared privately (by specifying a user's AWS account ID) or publicly (<i>All</i>). 
  ##   
                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402656971 = newJObject()
  if body != nil:
    body_402656971 = body
  result = call_402656970.call(nil, nil, nil, nil, body_402656971)

var describeDocumentPermission* = Call_DescribeDocumentPermission_402656957(
    name: "describeDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeDocumentPermission",
    validator: validate_DescribeDocumentPermission_402656958, base: "/",
    makeUrl: url_DescribeDocumentPermission_402656959,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectiveInstanceAssociations_402656972 = ref object of OpenApiRestCall_402656044
proc url_DescribeEffectiveInstanceAssociations_402656974(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEffectiveInstanceAssociations_402656973(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## All associations for the instance(s).
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656975 = header.getOrDefault("X-Amz-Target")
  valid_402656975 = validateParameter(valid_402656975, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectiveInstanceAssociations"))
  if valid_402656975 != nil:
    section.add "X-Amz-Target", valid_402656975
  var valid_402656976 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656976 = validateParameter(valid_402656976, JString,
                                      required = false, default = nil)
  if valid_402656976 != nil:
    section.add "X-Amz-Security-Token", valid_402656976
  var valid_402656977 = header.getOrDefault("X-Amz-Signature")
  valid_402656977 = validateParameter(valid_402656977, JString,
                                      required = false, default = nil)
  if valid_402656977 != nil:
    section.add "X-Amz-Signature", valid_402656977
  var valid_402656978 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656978 = validateParameter(valid_402656978, JString,
                                      required = false, default = nil)
  if valid_402656978 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656978
  var valid_402656979 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656979 = validateParameter(valid_402656979, JString,
                                      required = false, default = nil)
  if valid_402656979 != nil:
    section.add "X-Amz-Algorithm", valid_402656979
  var valid_402656980 = header.getOrDefault("X-Amz-Date")
  valid_402656980 = validateParameter(valid_402656980, JString,
                                      required = false, default = nil)
  if valid_402656980 != nil:
    section.add "X-Amz-Date", valid_402656980
  var valid_402656981 = header.getOrDefault("X-Amz-Credential")
  valid_402656981 = validateParameter(valid_402656981, JString,
                                      required = false, default = nil)
  if valid_402656981 != nil:
    section.add "X-Amz-Credential", valid_402656981
  var valid_402656982 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656982 = validateParameter(valid_402656982, JString,
                                      required = false, default = nil)
  if valid_402656982 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656982
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656984: Call_DescribeEffectiveInstanceAssociations_402656972;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## All associations for the instance(s).
                                                                                         ## 
  let valid = call_402656984.validator(path, query, header, formData, body, _)
  let scheme = call_402656984.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656984.makeUrl(scheme.get, call_402656984.host, call_402656984.base,
                                   call_402656984.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656984, uri, valid, _)

proc call*(call_402656985: Call_DescribeEffectiveInstanceAssociations_402656972;
           body: JsonNode): Recallable =
  ## describeEffectiveInstanceAssociations
  ## All associations for the instance(s).
  ##   body: JObject (required)
  var body_402656986 = newJObject()
  if body != nil:
    body_402656986 = body
  result = call_402656985.call(nil, nil, nil, nil, body_402656986)

var describeEffectiveInstanceAssociations* = Call_DescribeEffectiveInstanceAssociations_402656972(
    name: "describeEffectiveInstanceAssociations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectiveInstanceAssociations",
    validator: validate_DescribeEffectiveInstanceAssociations_402656973,
    base: "/", makeUrl: url_DescribeEffectiveInstanceAssociations_402656974,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeEffectivePatchesForPatchBaseline_402656987 = ref object of OpenApiRestCall_402656044
proc url_DescribeEffectivePatchesForPatchBaseline_402656989(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeEffectivePatchesForPatchBaseline_402656988(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656990 = header.getOrDefault("X-Amz-Target")
  valid_402656990 = validateParameter(valid_402656990, JString, required = true, default = newJString(
      "AmazonSSM.DescribeEffectivePatchesForPatchBaseline"))
  if valid_402656990 != nil:
    section.add "X-Amz-Target", valid_402656990
  var valid_402656991 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656991 = validateParameter(valid_402656991, JString,
                                      required = false, default = nil)
  if valid_402656991 != nil:
    section.add "X-Amz-Security-Token", valid_402656991
  var valid_402656992 = header.getOrDefault("X-Amz-Signature")
  valid_402656992 = validateParameter(valid_402656992, JString,
                                      required = false, default = nil)
  if valid_402656992 != nil:
    section.add "X-Amz-Signature", valid_402656992
  var valid_402656993 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656993 = validateParameter(valid_402656993, JString,
                                      required = false, default = nil)
  if valid_402656993 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656993
  var valid_402656994 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656994 = validateParameter(valid_402656994, JString,
                                      required = false, default = nil)
  if valid_402656994 != nil:
    section.add "X-Amz-Algorithm", valid_402656994
  var valid_402656995 = header.getOrDefault("X-Amz-Date")
  valid_402656995 = validateParameter(valid_402656995, JString,
                                      required = false, default = nil)
  if valid_402656995 != nil:
    section.add "X-Amz-Date", valid_402656995
  var valid_402656996 = header.getOrDefault("X-Amz-Credential")
  valid_402656996 = validateParameter(valid_402656996, JString,
                                      required = false, default = nil)
  if valid_402656996 != nil:
    section.add "X-Amz-Credential", valid_402656996
  var valid_402656997 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656997 = validateParameter(valid_402656997, JString,
                                      required = false, default = nil)
  if valid_402656997 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656997
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402656999: Call_DescribeEffectivePatchesForPatchBaseline_402656987;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
                                                                                         ## 
  let valid = call_402656999.validator(path, query, header, formData, body, _)
  let scheme = call_402656999.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656999.makeUrl(scheme.get, call_402656999.host, call_402656999.base,
                                   call_402656999.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656999, uri, valid, _)

proc call*(call_402657000: Call_DescribeEffectivePatchesForPatchBaseline_402656987;
           body: JsonNode): Recallable =
  ## describeEffectivePatchesForPatchBaseline
  ## Retrieves the current effective patches (the patch and the approval state) for the specified patch baseline. Note that this API applies only to Windows patch baselines.
  ##   
                                                                                                                                                                             ## body: JObject (required)
  var body_402657001 = newJObject()
  if body != nil:
    body_402657001 = body
  result = call_402657000.call(nil, nil, nil, nil, body_402657001)

var describeEffectivePatchesForPatchBaseline* = Call_DescribeEffectivePatchesForPatchBaseline_402656987(
    name: "describeEffectivePatchesForPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeEffectivePatchesForPatchBaseline",
    validator: validate_DescribeEffectivePatchesForPatchBaseline_402656988,
    base: "/", makeUrl: url_DescribeEffectivePatchesForPatchBaseline_402656989,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceAssociationsStatus_402657002 = ref object of OpenApiRestCall_402656044
proc url_DescribeInstanceAssociationsStatus_402657004(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInstanceAssociationsStatus_402657003(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## The status of the associations for the instance(s).
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657005 = header.getOrDefault("X-Amz-Target")
  valid_402657005 = validateParameter(valid_402657005, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceAssociationsStatus"))
  if valid_402657005 != nil:
    section.add "X-Amz-Target", valid_402657005
  var valid_402657006 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657006 = validateParameter(valid_402657006, JString,
                                      required = false, default = nil)
  if valid_402657006 != nil:
    section.add "X-Amz-Security-Token", valid_402657006
  var valid_402657007 = header.getOrDefault("X-Amz-Signature")
  valid_402657007 = validateParameter(valid_402657007, JString,
                                      required = false, default = nil)
  if valid_402657007 != nil:
    section.add "X-Amz-Signature", valid_402657007
  var valid_402657008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657008 = validateParameter(valid_402657008, JString,
                                      required = false, default = nil)
  if valid_402657008 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657008
  var valid_402657009 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657009 = validateParameter(valid_402657009, JString,
                                      required = false, default = nil)
  if valid_402657009 != nil:
    section.add "X-Amz-Algorithm", valid_402657009
  var valid_402657010 = header.getOrDefault("X-Amz-Date")
  valid_402657010 = validateParameter(valid_402657010, JString,
                                      required = false, default = nil)
  if valid_402657010 != nil:
    section.add "X-Amz-Date", valid_402657010
  var valid_402657011 = header.getOrDefault("X-Amz-Credential")
  valid_402657011 = validateParameter(valid_402657011, JString,
                                      required = false, default = nil)
  if valid_402657011 != nil:
    section.add "X-Amz-Credential", valid_402657011
  var valid_402657012 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657012 = validateParameter(valid_402657012, JString,
                                      required = false, default = nil)
  if valid_402657012 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657012
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657014: Call_DescribeInstanceAssociationsStatus_402657002;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## The status of the associations for the instance(s).
                                                                                         ## 
  let valid = call_402657014.validator(path, query, header, formData, body, _)
  let scheme = call_402657014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657014.makeUrl(scheme.get, call_402657014.host, call_402657014.base,
                                   call_402657014.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657014, uri, valid, _)

proc call*(call_402657015: Call_DescribeInstanceAssociationsStatus_402657002;
           body: JsonNode): Recallable =
  ## describeInstanceAssociationsStatus
  ## The status of the associations for the instance(s).
  ##   body: JObject (required)
  var body_402657016 = newJObject()
  if body != nil:
    body_402657016 = body
  result = call_402657015.call(nil, nil, nil, nil, body_402657016)

var describeInstanceAssociationsStatus* = Call_DescribeInstanceAssociationsStatus_402657002(
    name: "describeInstanceAssociationsStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceAssociationsStatus",
    validator: validate_DescribeInstanceAssociationsStatus_402657003, base: "/",
    makeUrl: url_DescribeInstanceAssociationsStatus_402657004,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstanceInformation_402657017 = ref object of OpenApiRestCall_402656044
proc url_DescribeInstanceInformation_402657019(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInstanceInformation_402657018(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657020 = query.getOrDefault("MaxResults")
  valid_402657020 = validateParameter(valid_402657020, JString,
                                      required = false, default = nil)
  if valid_402657020 != nil:
    section.add "MaxResults", valid_402657020
  var valid_402657021 = query.getOrDefault("NextToken")
  valid_402657021 = validateParameter(valid_402657021, JString,
                                      required = false, default = nil)
  if valid_402657021 != nil:
    section.add "NextToken", valid_402657021
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657022 = header.getOrDefault("X-Amz-Target")
  valid_402657022 = validateParameter(valid_402657022, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstanceInformation"))
  if valid_402657022 != nil:
    section.add "X-Amz-Target", valid_402657022
  var valid_402657023 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657023 = validateParameter(valid_402657023, JString,
                                      required = false, default = nil)
  if valid_402657023 != nil:
    section.add "X-Amz-Security-Token", valid_402657023
  var valid_402657024 = header.getOrDefault("X-Amz-Signature")
  valid_402657024 = validateParameter(valid_402657024, JString,
                                      required = false, default = nil)
  if valid_402657024 != nil:
    section.add "X-Amz-Signature", valid_402657024
  var valid_402657025 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657025 = validateParameter(valid_402657025, JString,
                                      required = false, default = nil)
  if valid_402657025 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657025
  var valid_402657026 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657026 = validateParameter(valid_402657026, JString,
                                      required = false, default = nil)
  if valid_402657026 != nil:
    section.add "X-Amz-Algorithm", valid_402657026
  var valid_402657027 = header.getOrDefault("X-Amz-Date")
  valid_402657027 = validateParameter(valid_402657027, JString,
                                      required = false, default = nil)
  if valid_402657027 != nil:
    section.add "X-Amz-Date", valid_402657027
  var valid_402657028 = header.getOrDefault("X-Amz-Credential")
  valid_402657028 = validateParameter(valid_402657028, JString,
                                      required = false, default = nil)
  if valid_402657028 != nil:
    section.add "X-Amz-Credential", valid_402657028
  var valid_402657029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657029 = validateParameter(valid_402657029, JString,
                                      required = false, default = nil)
  if valid_402657029 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657031: Call_DescribeInstanceInformation_402657017;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
                                                                                         ## 
  let valid = call_402657031.validator(path, query, header, formData, body, _)
  let scheme = call_402657031.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657031.makeUrl(scheme.get, call_402657031.host, call_402657031.base,
                                   call_402657031.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657031, uri, valid, _)

proc call*(call_402657032: Call_DescribeInstanceInformation_402657017;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeInstanceInformation
  ## <p>Describes one or more of your instances. You can use this to get information about instances like the operating system platform, the SSM Agent version (Linux), status etc. If you specify one or more instance IDs, it returns information for those instances. If you do not specify instance IDs, it returns information for all your instances. If you specify an instance ID that is not valid or an instance that you do not own, you receive an error. </p> <note> <p>The IamRole field for this API action is the Amazon Identity and Access Management (IAM) role assigned to on-premises instances. This call does not return the IAM role for Amazon EC2 instances.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                          ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     ## token
  var query_402657033 = newJObject()
  var body_402657034 = newJObject()
  add(query_402657033, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657034 = body
  add(query_402657033, "NextToken", newJString(NextToken))
  result = call_402657032.call(nil, query_402657033, nil, nil, body_402657034)

var describeInstanceInformation* = Call_DescribeInstanceInformation_402657017(
    name: "describeInstanceInformation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstanceInformation",
    validator: validate_DescribeInstanceInformation_402657018, base: "/",
    makeUrl: url_DescribeInstanceInformation_402657019,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStates_402657035 = ref object of OpenApiRestCall_402656044
proc url_DescribeInstancePatchStates_402657037(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInstancePatchStates_402657036(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves the high-level patch state of one or more instances.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657038 = header.getOrDefault("X-Amz-Target")
  valid_402657038 = validateParameter(valid_402657038, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStates"))
  if valid_402657038 != nil:
    section.add "X-Amz-Target", valid_402657038
  var valid_402657039 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657039 = validateParameter(valid_402657039, JString,
                                      required = false, default = nil)
  if valid_402657039 != nil:
    section.add "X-Amz-Security-Token", valid_402657039
  var valid_402657040 = header.getOrDefault("X-Amz-Signature")
  valid_402657040 = validateParameter(valid_402657040, JString,
                                      required = false, default = nil)
  if valid_402657040 != nil:
    section.add "X-Amz-Signature", valid_402657040
  var valid_402657041 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657041 = validateParameter(valid_402657041, JString,
                                      required = false, default = nil)
  if valid_402657041 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657041
  var valid_402657042 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657042 = validateParameter(valid_402657042, JString,
                                      required = false, default = nil)
  if valid_402657042 != nil:
    section.add "X-Amz-Algorithm", valid_402657042
  var valid_402657043 = header.getOrDefault("X-Amz-Date")
  valid_402657043 = validateParameter(valid_402657043, JString,
                                      required = false, default = nil)
  if valid_402657043 != nil:
    section.add "X-Amz-Date", valid_402657043
  var valid_402657044 = header.getOrDefault("X-Amz-Credential")
  valid_402657044 = validateParameter(valid_402657044, JString,
                                      required = false, default = nil)
  if valid_402657044 != nil:
    section.add "X-Amz-Credential", valid_402657044
  var valid_402657045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657045 = validateParameter(valid_402657045, JString,
                                      required = false, default = nil)
  if valid_402657045 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657047: Call_DescribeInstancePatchStates_402657035;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the high-level patch state of one or more instances.
                                                                                         ## 
  let valid = call_402657047.validator(path, query, header, formData, body, _)
  let scheme = call_402657047.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657047.makeUrl(scheme.get, call_402657047.host, call_402657047.base,
                                   call_402657047.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657047, uri, valid, _)

proc call*(call_402657048: Call_DescribeInstancePatchStates_402657035;
           body: JsonNode): Recallable =
  ## describeInstancePatchStates
  ## Retrieves the high-level patch state of one or more instances.
  ##   body: JObject (required)
  var body_402657049 = newJObject()
  if body != nil:
    body_402657049 = body
  result = call_402657048.call(nil, nil, nil, nil, body_402657049)

var describeInstancePatchStates* = Call_DescribeInstancePatchStates_402657035(
    name: "describeInstancePatchStates", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStates",
    validator: validate_DescribeInstancePatchStates_402657036, base: "/",
    makeUrl: url_DescribeInstancePatchStates_402657037,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatchStatesForPatchGroup_402657050 = ref object of OpenApiRestCall_402656044
proc url_DescribeInstancePatchStatesForPatchGroup_402657052(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInstancePatchStatesForPatchGroup_402657051(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves the high-level patch state for the instances in the specified patch group.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657053 = header.getOrDefault("X-Amz-Target")
  valid_402657053 = validateParameter(valid_402657053, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatchStatesForPatchGroup"))
  if valid_402657053 != nil:
    section.add "X-Amz-Target", valid_402657053
  var valid_402657054 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657054 = validateParameter(valid_402657054, JString,
                                      required = false, default = nil)
  if valid_402657054 != nil:
    section.add "X-Amz-Security-Token", valid_402657054
  var valid_402657055 = header.getOrDefault("X-Amz-Signature")
  valid_402657055 = validateParameter(valid_402657055, JString,
                                      required = false, default = nil)
  if valid_402657055 != nil:
    section.add "X-Amz-Signature", valid_402657055
  var valid_402657056 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657056 = validateParameter(valid_402657056, JString,
                                      required = false, default = nil)
  if valid_402657056 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657056
  var valid_402657057 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657057 = validateParameter(valid_402657057, JString,
                                      required = false, default = nil)
  if valid_402657057 != nil:
    section.add "X-Amz-Algorithm", valid_402657057
  var valid_402657058 = header.getOrDefault("X-Amz-Date")
  valid_402657058 = validateParameter(valid_402657058, JString,
                                      required = false, default = nil)
  if valid_402657058 != nil:
    section.add "X-Amz-Date", valid_402657058
  var valid_402657059 = header.getOrDefault("X-Amz-Credential")
  valid_402657059 = validateParameter(valid_402657059, JString,
                                      required = false, default = nil)
  if valid_402657059 != nil:
    section.add "X-Amz-Credential", valid_402657059
  var valid_402657060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657060 = validateParameter(valid_402657060, JString,
                                      required = false, default = nil)
  if valid_402657060 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657062: Call_DescribeInstancePatchStatesForPatchGroup_402657050;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the high-level patch state for the instances in the specified patch group.
                                                                                         ## 
  let valid = call_402657062.validator(path, query, header, formData, body, _)
  let scheme = call_402657062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657062.makeUrl(scheme.get, call_402657062.host, call_402657062.base,
                                   call_402657062.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657062, uri, valid, _)

proc call*(call_402657063: Call_DescribeInstancePatchStatesForPatchGroup_402657050;
           body: JsonNode): Recallable =
  ## describeInstancePatchStatesForPatchGroup
  ## Retrieves the high-level patch state for the instances in the specified patch group.
  ##   
                                                                                         ## body: JObject (required)
  var body_402657064 = newJObject()
  if body != nil:
    body_402657064 = body
  result = call_402657063.call(nil, nil, nil, nil, body_402657064)

var describeInstancePatchStatesForPatchGroup* = Call_DescribeInstancePatchStatesForPatchGroup_402657050(
    name: "describeInstancePatchStatesForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatchStatesForPatchGroup",
    validator: validate_DescribeInstancePatchStatesForPatchGroup_402657051,
    base: "/", makeUrl: url_DescribeInstancePatchStatesForPatchGroup_402657052,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInstancePatches_402657065 = ref object of OpenApiRestCall_402656044
proc url_DescribeInstancePatches_402657067(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInstancePatches_402657066(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657068 = header.getOrDefault("X-Amz-Target")
  valid_402657068 = validateParameter(valid_402657068, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInstancePatches"))
  if valid_402657068 != nil:
    section.add "X-Amz-Target", valid_402657068
  var valid_402657069 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657069 = validateParameter(valid_402657069, JString,
                                      required = false, default = nil)
  if valid_402657069 != nil:
    section.add "X-Amz-Security-Token", valid_402657069
  var valid_402657070 = header.getOrDefault("X-Amz-Signature")
  valid_402657070 = validateParameter(valid_402657070, JString,
                                      required = false, default = nil)
  if valid_402657070 != nil:
    section.add "X-Amz-Signature", valid_402657070
  var valid_402657071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657071 = validateParameter(valid_402657071, JString,
                                      required = false, default = nil)
  if valid_402657071 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657071
  var valid_402657072 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657072 = validateParameter(valid_402657072, JString,
                                      required = false, default = nil)
  if valid_402657072 != nil:
    section.add "X-Amz-Algorithm", valid_402657072
  var valid_402657073 = header.getOrDefault("X-Amz-Date")
  valid_402657073 = validateParameter(valid_402657073, JString,
                                      required = false, default = nil)
  if valid_402657073 != nil:
    section.add "X-Amz-Date", valid_402657073
  var valid_402657074 = header.getOrDefault("X-Amz-Credential")
  valid_402657074 = validateParameter(valid_402657074, JString,
                                      required = false, default = nil)
  if valid_402657074 != nil:
    section.add "X-Amz-Credential", valid_402657074
  var valid_402657075 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657075 = validateParameter(valid_402657075, JString,
                                      required = false, default = nil)
  if valid_402657075 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657077: Call_DescribeInstancePatches_402657065;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
                                                                                         ## 
  let valid = call_402657077.validator(path, query, header, formData, body, _)
  let scheme = call_402657077.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657077.makeUrl(scheme.get, call_402657077.host, call_402657077.base,
                                   call_402657077.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657077, uri, valid, _)

proc call*(call_402657078: Call_DescribeInstancePatches_402657065;
           body: JsonNode): Recallable =
  ## describeInstancePatches
  ## Retrieves information about the patches on the specified instance and their state relative to the patch baseline being used for the instance.
  ##   
                                                                                                                                                  ## body: JObject (required)
  var body_402657079 = newJObject()
  if body != nil:
    body_402657079 = body
  result = call_402657078.call(nil, nil, nil, nil, body_402657079)

var describeInstancePatches* = Call_DescribeInstancePatches_402657065(
    name: "describeInstancePatches", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInstancePatches",
    validator: validate_DescribeInstancePatches_402657066, base: "/",
    makeUrl: url_DescribeInstancePatches_402657067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInventoryDeletions_402657080 = ref object of OpenApiRestCall_402656044
proc url_DescribeInventoryDeletions_402657082(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeInventoryDeletions_402657081(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Describes a specific delete inventory operation.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657083 = header.getOrDefault("X-Amz-Target")
  valid_402657083 = validateParameter(valid_402657083, JString, required = true, default = newJString(
      "AmazonSSM.DescribeInventoryDeletions"))
  if valid_402657083 != nil:
    section.add "X-Amz-Target", valid_402657083
  var valid_402657084 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657084 = validateParameter(valid_402657084, JString,
                                      required = false, default = nil)
  if valid_402657084 != nil:
    section.add "X-Amz-Security-Token", valid_402657084
  var valid_402657085 = header.getOrDefault("X-Amz-Signature")
  valid_402657085 = validateParameter(valid_402657085, JString,
                                      required = false, default = nil)
  if valid_402657085 != nil:
    section.add "X-Amz-Signature", valid_402657085
  var valid_402657086 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657086 = validateParameter(valid_402657086, JString,
                                      required = false, default = nil)
  if valid_402657086 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657086
  var valid_402657087 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657087 = validateParameter(valid_402657087, JString,
                                      required = false, default = nil)
  if valid_402657087 != nil:
    section.add "X-Amz-Algorithm", valid_402657087
  var valid_402657088 = header.getOrDefault("X-Amz-Date")
  valid_402657088 = validateParameter(valid_402657088, JString,
                                      required = false, default = nil)
  if valid_402657088 != nil:
    section.add "X-Amz-Date", valid_402657088
  var valid_402657089 = header.getOrDefault("X-Amz-Credential")
  valid_402657089 = validateParameter(valid_402657089, JString,
                                      required = false, default = nil)
  if valid_402657089 != nil:
    section.add "X-Amz-Credential", valid_402657089
  var valid_402657090 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657090 = validateParameter(valid_402657090, JString,
                                      required = false, default = nil)
  if valid_402657090 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657090
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657092: Call_DescribeInventoryDeletions_402657080;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Describes a specific delete inventory operation.
                                                                                         ## 
  let valid = call_402657092.validator(path, query, header, formData, body, _)
  let scheme = call_402657092.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657092.makeUrl(scheme.get, call_402657092.host, call_402657092.base,
                                   call_402657092.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657092, uri, valid, _)

proc call*(call_402657093: Call_DescribeInventoryDeletions_402657080;
           body: JsonNode): Recallable =
  ## describeInventoryDeletions
  ## Describes a specific delete inventory operation.
  ##   body: JObject (required)
  var body_402657094 = newJObject()
  if body != nil:
    body_402657094 = body
  result = call_402657093.call(nil, nil, nil, nil, body_402657094)

var describeInventoryDeletions* = Call_DescribeInventoryDeletions_402657080(
    name: "describeInventoryDeletions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeInventoryDeletions",
    validator: validate_DescribeInventoryDeletions_402657081, base: "/",
    makeUrl: url_DescribeInventoryDeletions_402657082,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTaskInvocations_402657095 = ref object of OpenApiRestCall_402656044
proc url_DescribeMaintenanceWindowExecutionTaskInvocations_402657097(
    protocol: Scheme; host: string; base: string; route: string; path: JsonNode;
    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowExecutionTaskInvocations_402657096(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
                                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657098 = header.getOrDefault("X-Amz-Target")
  valid_402657098 = validateParameter(valid_402657098, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations"))
  if valid_402657098 != nil:
    section.add "X-Amz-Target", valid_402657098
  var valid_402657099 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657099 = validateParameter(valid_402657099, JString,
                                      required = false, default = nil)
  if valid_402657099 != nil:
    section.add "X-Amz-Security-Token", valid_402657099
  var valid_402657100 = header.getOrDefault("X-Amz-Signature")
  valid_402657100 = validateParameter(valid_402657100, JString,
                                      required = false, default = nil)
  if valid_402657100 != nil:
    section.add "X-Amz-Signature", valid_402657100
  var valid_402657101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657101 = validateParameter(valid_402657101, JString,
                                      required = false, default = nil)
  if valid_402657101 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657101
  var valid_402657102 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657102 = validateParameter(valid_402657102, JString,
                                      required = false, default = nil)
  if valid_402657102 != nil:
    section.add "X-Amz-Algorithm", valid_402657102
  var valid_402657103 = header.getOrDefault("X-Amz-Date")
  valid_402657103 = validateParameter(valid_402657103, JString,
                                      required = false, default = nil)
  if valid_402657103 != nil:
    section.add "X-Amz-Date", valid_402657103
  var valid_402657104 = header.getOrDefault("X-Amz-Credential")
  valid_402657104 = validateParameter(valid_402657104, JString,
                                      required = false, default = nil)
  if valid_402657104 != nil:
    section.add "X-Amz-Credential", valid_402657104
  var valid_402657105 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657105 = validateParameter(valid_402657105, JString,
                                      required = false, default = nil)
  if valid_402657105 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657107: Call_DescribeMaintenanceWindowExecutionTaskInvocations_402657095;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
                                                                                         ## 
  let valid = call_402657107.validator(path, query, header, formData, body, _)
  let scheme = call_402657107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657107.makeUrl(scheme.get, call_402657107.host, call_402657107.base,
                                   call_402657107.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657107, uri, valid, _)

proc call*(call_402657108: Call_DescribeMaintenanceWindowExecutionTaskInvocations_402657095;
           body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTaskInvocations
  ## Retrieves the individual task executions (one per target) for a particular task run as part of a maintenance window execution.
  ##   
                                                                                                                                   ## body: JObject (required)
  var body_402657109 = newJObject()
  if body != nil:
    body_402657109 = body
  result = call_402657108.call(nil, nil, nil, nil, body_402657109)

var describeMaintenanceWindowExecutionTaskInvocations* = Call_DescribeMaintenanceWindowExecutionTaskInvocations_402657095(
    name: "describeMaintenanceWindowExecutionTaskInvocations",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTaskInvocations",
    validator: validate_DescribeMaintenanceWindowExecutionTaskInvocations_402657096,
    base: "/", makeUrl: url_DescribeMaintenanceWindowExecutionTaskInvocations_402657097,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutionTasks_402657110 = ref object of OpenApiRestCall_402656044
proc url_DescribeMaintenanceWindowExecutionTasks_402657112(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowExecutionTasks_402657111(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## For a given maintenance window execution, lists the tasks that were run.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657113 = header.getOrDefault("X-Amz-Target")
  valid_402657113 = validateParameter(valid_402657113, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutionTasks"))
  if valid_402657113 != nil:
    section.add "X-Amz-Target", valid_402657113
  var valid_402657114 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657114 = validateParameter(valid_402657114, JString,
                                      required = false, default = nil)
  if valid_402657114 != nil:
    section.add "X-Amz-Security-Token", valid_402657114
  var valid_402657115 = header.getOrDefault("X-Amz-Signature")
  valid_402657115 = validateParameter(valid_402657115, JString,
                                      required = false, default = nil)
  if valid_402657115 != nil:
    section.add "X-Amz-Signature", valid_402657115
  var valid_402657116 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657116 = validateParameter(valid_402657116, JString,
                                      required = false, default = nil)
  if valid_402657116 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657116
  var valid_402657117 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657117 = validateParameter(valid_402657117, JString,
                                      required = false, default = nil)
  if valid_402657117 != nil:
    section.add "X-Amz-Algorithm", valid_402657117
  var valid_402657118 = header.getOrDefault("X-Amz-Date")
  valid_402657118 = validateParameter(valid_402657118, JString,
                                      required = false, default = nil)
  if valid_402657118 != nil:
    section.add "X-Amz-Date", valid_402657118
  var valid_402657119 = header.getOrDefault("X-Amz-Credential")
  valid_402657119 = validateParameter(valid_402657119, JString,
                                      required = false, default = nil)
  if valid_402657119 != nil:
    section.add "X-Amz-Credential", valid_402657119
  var valid_402657120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657120 = validateParameter(valid_402657120, JString,
                                      required = false, default = nil)
  if valid_402657120 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657122: Call_DescribeMaintenanceWindowExecutionTasks_402657110;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## For a given maintenance window execution, lists the tasks that were run.
                                                                                         ## 
  let valid = call_402657122.validator(path, query, header, formData, body, _)
  let scheme = call_402657122.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657122.makeUrl(scheme.get, call_402657122.host, call_402657122.base,
                                   call_402657122.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657122, uri, valid, _)

proc call*(call_402657123: Call_DescribeMaintenanceWindowExecutionTasks_402657110;
           body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutionTasks
  ## For a given maintenance window execution, lists the tasks that were run.
  ##   
                                                                             ## body: JObject (required)
  var body_402657124 = newJObject()
  if body != nil:
    body_402657124 = body
  result = call_402657123.call(nil, nil, nil, nil, body_402657124)

var describeMaintenanceWindowExecutionTasks* = Call_DescribeMaintenanceWindowExecutionTasks_402657110(
    name: "describeMaintenanceWindowExecutionTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutionTasks",
    validator: validate_DescribeMaintenanceWindowExecutionTasks_402657111,
    base: "/", makeUrl: url_DescribeMaintenanceWindowExecutionTasks_402657112,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowExecutions_402657125 = ref object of OpenApiRestCall_402656044
proc url_DescribeMaintenanceWindowExecutions_402657127(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowExecutions_402657126(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657128 = header.getOrDefault("X-Amz-Target")
  valid_402657128 = validateParameter(valid_402657128, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowExecutions"))
  if valid_402657128 != nil:
    section.add "X-Amz-Target", valid_402657128
  var valid_402657129 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657129 = validateParameter(valid_402657129, JString,
                                      required = false, default = nil)
  if valid_402657129 != nil:
    section.add "X-Amz-Security-Token", valid_402657129
  var valid_402657130 = header.getOrDefault("X-Amz-Signature")
  valid_402657130 = validateParameter(valid_402657130, JString,
                                      required = false, default = nil)
  if valid_402657130 != nil:
    section.add "X-Amz-Signature", valid_402657130
  var valid_402657131 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657131 = validateParameter(valid_402657131, JString,
                                      required = false, default = nil)
  if valid_402657131 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657131
  var valid_402657132 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657132 = validateParameter(valid_402657132, JString,
                                      required = false, default = nil)
  if valid_402657132 != nil:
    section.add "X-Amz-Algorithm", valid_402657132
  var valid_402657133 = header.getOrDefault("X-Amz-Date")
  valid_402657133 = validateParameter(valid_402657133, JString,
                                      required = false, default = nil)
  if valid_402657133 != nil:
    section.add "X-Amz-Date", valid_402657133
  var valid_402657134 = header.getOrDefault("X-Amz-Credential")
  valid_402657134 = validateParameter(valid_402657134, JString,
                                      required = false, default = nil)
  if valid_402657134 != nil:
    section.add "X-Amz-Credential", valid_402657134
  var valid_402657135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657135 = validateParameter(valid_402657135, JString,
                                      required = false, default = nil)
  if valid_402657135 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657137: Call_DescribeMaintenanceWindowExecutions_402657125;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
                                                                                         ## 
  let valid = call_402657137.validator(path, query, header, formData, body, _)
  let scheme = call_402657137.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657137.makeUrl(scheme.get, call_402657137.host, call_402657137.base,
                                   call_402657137.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657137, uri, valid, _)

proc call*(call_402657138: Call_DescribeMaintenanceWindowExecutions_402657125;
           body: JsonNode): Recallable =
  ## describeMaintenanceWindowExecutions
  ## Lists the executions of a maintenance window. This includes information about when the maintenance window was scheduled to be active, and information about tasks registered and run with the maintenance window.
  ##   
                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402657139 = newJObject()
  if body != nil:
    body_402657139 = body
  result = call_402657138.call(nil, nil, nil, nil, body_402657139)

var describeMaintenanceWindowExecutions* = Call_DescribeMaintenanceWindowExecutions_402657125(
    name: "describeMaintenanceWindowExecutions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowExecutions",
    validator: validate_DescribeMaintenanceWindowExecutions_402657126,
    base: "/", makeUrl: url_DescribeMaintenanceWindowExecutions_402657127,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowSchedule_402657140 = ref object of OpenApiRestCall_402656044
proc url_DescribeMaintenanceWindowSchedule_402657142(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowSchedule_402657141(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about upcoming executions of a maintenance window.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657143 = header.getOrDefault("X-Amz-Target")
  valid_402657143 = validateParameter(valid_402657143, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowSchedule"))
  if valid_402657143 != nil:
    section.add "X-Amz-Target", valid_402657143
  var valid_402657144 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657144 = validateParameter(valid_402657144, JString,
                                      required = false, default = nil)
  if valid_402657144 != nil:
    section.add "X-Amz-Security-Token", valid_402657144
  var valid_402657145 = header.getOrDefault("X-Amz-Signature")
  valid_402657145 = validateParameter(valid_402657145, JString,
                                      required = false, default = nil)
  if valid_402657145 != nil:
    section.add "X-Amz-Signature", valid_402657145
  var valid_402657146 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657146 = validateParameter(valid_402657146, JString,
                                      required = false, default = nil)
  if valid_402657146 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657146
  var valid_402657147 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657147 = validateParameter(valid_402657147, JString,
                                      required = false, default = nil)
  if valid_402657147 != nil:
    section.add "X-Amz-Algorithm", valid_402657147
  var valid_402657148 = header.getOrDefault("X-Amz-Date")
  valid_402657148 = validateParameter(valid_402657148, JString,
                                      required = false, default = nil)
  if valid_402657148 != nil:
    section.add "X-Amz-Date", valid_402657148
  var valid_402657149 = header.getOrDefault("X-Amz-Credential")
  valid_402657149 = validateParameter(valid_402657149, JString,
                                      required = false, default = nil)
  if valid_402657149 != nil:
    section.add "X-Amz-Credential", valid_402657149
  var valid_402657150 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657150 = validateParameter(valid_402657150, JString,
                                      required = false, default = nil)
  if valid_402657150 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657150
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657152: Call_DescribeMaintenanceWindowSchedule_402657140;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about upcoming executions of a maintenance window.
                                                                                         ## 
  let valid = call_402657152.validator(path, query, header, formData, body, _)
  let scheme = call_402657152.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657152.makeUrl(scheme.get, call_402657152.host, call_402657152.base,
                                   call_402657152.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657152, uri, valid, _)

proc call*(call_402657153: Call_DescribeMaintenanceWindowSchedule_402657140;
           body: JsonNode): Recallable =
  ## describeMaintenanceWindowSchedule
  ## Retrieves information about upcoming executions of a maintenance window.
  ##   
                                                                             ## body: JObject (required)
  var body_402657154 = newJObject()
  if body != nil:
    body_402657154 = body
  result = call_402657153.call(nil, nil, nil, nil, body_402657154)

var describeMaintenanceWindowSchedule* = Call_DescribeMaintenanceWindowSchedule_402657140(
    name: "describeMaintenanceWindowSchedule", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowSchedule",
    validator: validate_DescribeMaintenanceWindowSchedule_402657141, base: "/",
    makeUrl: url_DescribeMaintenanceWindowSchedule_402657142,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTargets_402657155 = ref object of OpenApiRestCall_402656044
proc url_DescribeMaintenanceWindowTargets_402657157(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowTargets_402657156(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists the targets registered with the maintenance window.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657158 = header.getOrDefault("X-Amz-Target")
  valid_402657158 = validateParameter(valid_402657158, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTargets"))
  if valid_402657158 != nil:
    section.add "X-Amz-Target", valid_402657158
  var valid_402657159 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657159 = validateParameter(valid_402657159, JString,
                                      required = false, default = nil)
  if valid_402657159 != nil:
    section.add "X-Amz-Security-Token", valid_402657159
  var valid_402657160 = header.getOrDefault("X-Amz-Signature")
  valid_402657160 = validateParameter(valid_402657160, JString,
                                      required = false, default = nil)
  if valid_402657160 != nil:
    section.add "X-Amz-Signature", valid_402657160
  var valid_402657161 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657161 = validateParameter(valid_402657161, JString,
                                      required = false, default = nil)
  if valid_402657161 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657161
  var valid_402657162 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657162 = validateParameter(valid_402657162, JString,
                                      required = false, default = nil)
  if valid_402657162 != nil:
    section.add "X-Amz-Algorithm", valid_402657162
  var valid_402657163 = header.getOrDefault("X-Amz-Date")
  valid_402657163 = validateParameter(valid_402657163, JString,
                                      required = false, default = nil)
  if valid_402657163 != nil:
    section.add "X-Amz-Date", valid_402657163
  var valid_402657164 = header.getOrDefault("X-Amz-Credential")
  valid_402657164 = validateParameter(valid_402657164, JString,
                                      required = false, default = nil)
  if valid_402657164 != nil:
    section.add "X-Amz-Credential", valid_402657164
  var valid_402657165 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657165 = validateParameter(valid_402657165, JString,
                                      required = false, default = nil)
  if valid_402657165 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657165
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657167: Call_DescribeMaintenanceWindowTargets_402657155;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the targets registered with the maintenance window.
                                                                                         ## 
  let valid = call_402657167.validator(path, query, header, formData, body, _)
  let scheme = call_402657167.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657167.makeUrl(scheme.get, call_402657167.host, call_402657167.base,
                                   call_402657167.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657167, uri, valid, _)

proc call*(call_402657168: Call_DescribeMaintenanceWindowTargets_402657155;
           body: JsonNode): Recallable =
  ## describeMaintenanceWindowTargets
  ## Lists the targets registered with the maintenance window.
  ##   body: JObject (required)
  var body_402657169 = newJObject()
  if body != nil:
    body_402657169 = body
  result = call_402657168.call(nil, nil, nil, nil, body_402657169)

var describeMaintenanceWindowTargets* = Call_DescribeMaintenanceWindowTargets_402657155(
    name: "describeMaintenanceWindowTargets", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTargets",
    validator: validate_DescribeMaintenanceWindowTargets_402657156, base: "/",
    makeUrl: url_DescribeMaintenanceWindowTargets_402657157,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowTasks_402657170 = ref object of OpenApiRestCall_402656044
proc url_DescribeMaintenanceWindowTasks_402657172(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowTasks_402657171(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists the tasks in a maintenance window.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657173 = header.getOrDefault("X-Amz-Target")
  valid_402657173 = validateParameter(valid_402657173, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowTasks"))
  if valid_402657173 != nil:
    section.add "X-Amz-Target", valid_402657173
  var valid_402657174 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657174 = validateParameter(valid_402657174, JString,
                                      required = false, default = nil)
  if valid_402657174 != nil:
    section.add "X-Amz-Security-Token", valid_402657174
  var valid_402657175 = header.getOrDefault("X-Amz-Signature")
  valid_402657175 = validateParameter(valid_402657175, JString,
                                      required = false, default = nil)
  if valid_402657175 != nil:
    section.add "X-Amz-Signature", valid_402657175
  var valid_402657176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657176 = validateParameter(valid_402657176, JString,
                                      required = false, default = nil)
  if valid_402657176 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657176
  var valid_402657177 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657177 = validateParameter(valid_402657177, JString,
                                      required = false, default = nil)
  if valid_402657177 != nil:
    section.add "X-Amz-Algorithm", valid_402657177
  var valid_402657178 = header.getOrDefault("X-Amz-Date")
  valid_402657178 = validateParameter(valid_402657178, JString,
                                      required = false, default = nil)
  if valid_402657178 != nil:
    section.add "X-Amz-Date", valid_402657178
  var valid_402657179 = header.getOrDefault("X-Amz-Credential")
  valid_402657179 = validateParameter(valid_402657179, JString,
                                      required = false, default = nil)
  if valid_402657179 != nil:
    section.add "X-Amz-Credential", valid_402657179
  var valid_402657180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657180 = validateParameter(valid_402657180, JString,
                                      required = false, default = nil)
  if valid_402657180 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657180
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657182: Call_DescribeMaintenanceWindowTasks_402657170;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tasks in a maintenance window.
                                                                                         ## 
  let valid = call_402657182.validator(path, query, header, formData, body, _)
  let scheme = call_402657182.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657182.makeUrl(scheme.get, call_402657182.host, call_402657182.base,
                                   call_402657182.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657182, uri, valid, _)

proc call*(call_402657183: Call_DescribeMaintenanceWindowTasks_402657170;
           body: JsonNode): Recallable =
  ## describeMaintenanceWindowTasks
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_402657184 = newJObject()
  if body != nil:
    body_402657184 = body
  result = call_402657183.call(nil, nil, nil, nil, body_402657184)

var describeMaintenanceWindowTasks* = Call_DescribeMaintenanceWindowTasks_402657170(
    name: "describeMaintenanceWindowTasks", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowTasks",
    validator: validate_DescribeMaintenanceWindowTasks_402657171, base: "/",
    makeUrl: url_DescribeMaintenanceWindowTasks_402657172,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindows_402657185 = ref object of OpenApiRestCall_402656044
proc url_DescribeMaintenanceWindows_402657187(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindows_402657186(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves the maintenance windows in an AWS account.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657188 = header.getOrDefault("X-Amz-Target")
  valid_402657188 = validateParameter(valid_402657188, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindows"))
  if valid_402657188 != nil:
    section.add "X-Amz-Target", valid_402657188
  var valid_402657189 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657189 = validateParameter(valid_402657189, JString,
                                      required = false, default = nil)
  if valid_402657189 != nil:
    section.add "X-Amz-Security-Token", valid_402657189
  var valid_402657190 = header.getOrDefault("X-Amz-Signature")
  valid_402657190 = validateParameter(valid_402657190, JString,
                                      required = false, default = nil)
  if valid_402657190 != nil:
    section.add "X-Amz-Signature", valid_402657190
  var valid_402657191 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657191 = validateParameter(valid_402657191, JString,
                                      required = false, default = nil)
  if valid_402657191 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657191
  var valid_402657192 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657192 = validateParameter(valid_402657192, JString,
                                      required = false, default = nil)
  if valid_402657192 != nil:
    section.add "X-Amz-Algorithm", valid_402657192
  var valid_402657193 = header.getOrDefault("X-Amz-Date")
  valid_402657193 = validateParameter(valid_402657193, JString,
                                      required = false, default = nil)
  if valid_402657193 != nil:
    section.add "X-Amz-Date", valid_402657193
  var valid_402657194 = header.getOrDefault("X-Amz-Credential")
  valid_402657194 = validateParameter(valid_402657194, JString,
                                      required = false, default = nil)
  if valid_402657194 != nil:
    section.add "X-Amz-Credential", valid_402657194
  var valid_402657195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657195 = validateParameter(valid_402657195, JString,
                                      required = false, default = nil)
  if valid_402657195 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657197: Call_DescribeMaintenanceWindows_402657185;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the maintenance windows in an AWS account.
                                                                                         ## 
  let valid = call_402657197.validator(path, query, header, formData, body, _)
  let scheme = call_402657197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657197.makeUrl(scheme.get, call_402657197.host, call_402657197.base,
                                   call_402657197.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657197, uri, valid, _)

proc call*(call_402657198: Call_DescribeMaintenanceWindows_402657185;
           body: JsonNode): Recallable =
  ## describeMaintenanceWindows
  ## Retrieves the maintenance windows in an AWS account.
  ##   body: JObject (required)
  var body_402657199 = newJObject()
  if body != nil:
    body_402657199 = body
  result = call_402657198.call(nil, nil, nil, nil, body_402657199)

var describeMaintenanceWindows* = Call_DescribeMaintenanceWindows_402657185(
    name: "describeMaintenanceWindows", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindows",
    validator: validate_DescribeMaintenanceWindows_402657186, base: "/",
    makeUrl: url_DescribeMaintenanceWindows_402657187,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMaintenanceWindowsForTarget_402657200 = ref object of OpenApiRestCall_402656044
proc url_DescribeMaintenanceWindowsForTarget_402657202(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeMaintenanceWindowsForTarget_402657201(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657203 = header.getOrDefault("X-Amz-Target")
  valid_402657203 = validateParameter(valid_402657203, JString, required = true, default = newJString(
      "AmazonSSM.DescribeMaintenanceWindowsForTarget"))
  if valid_402657203 != nil:
    section.add "X-Amz-Target", valid_402657203
  var valid_402657204 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657204 = validateParameter(valid_402657204, JString,
                                      required = false, default = nil)
  if valid_402657204 != nil:
    section.add "X-Amz-Security-Token", valid_402657204
  var valid_402657205 = header.getOrDefault("X-Amz-Signature")
  valid_402657205 = validateParameter(valid_402657205, JString,
                                      required = false, default = nil)
  if valid_402657205 != nil:
    section.add "X-Amz-Signature", valid_402657205
  var valid_402657206 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657206 = validateParameter(valid_402657206, JString,
                                      required = false, default = nil)
  if valid_402657206 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657206
  var valid_402657207 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657207 = validateParameter(valid_402657207, JString,
                                      required = false, default = nil)
  if valid_402657207 != nil:
    section.add "X-Amz-Algorithm", valid_402657207
  var valid_402657208 = header.getOrDefault("X-Amz-Date")
  valid_402657208 = validateParameter(valid_402657208, JString,
                                      required = false, default = nil)
  if valid_402657208 != nil:
    section.add "X-Amz-Date", valid_402657208
  var valid_402657209 = header.getOrDefault("X-Amz-Credential")
  valid_402657209 = validateParameter(valid_402657209, JString,
                                      required = false, default = nil)
  if valid_402657209 != nil:
    section.add "X-Amz-Credential", valid_402657209
  var valid_402657210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657210 = validateParameter(valid_402657210, JString,
                                      required = false, default = nil)
  if valid_402657210 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657210
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657212: Call_DescribeMaintenanceWindowsForTarget_402657200;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
                                                                                         ## 
  let valid = call_402657212.validator(path, query, header, formData, body, _)
  let scheme = call_402657212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657212.makeUrl(scheme.get, call_402657212.host, call_402657212.base,
                                   call_402657212.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657212, uri, valid, _)

proc call*(call_402657213: Call_DescribeMaintenanceWindowsForTarget_402657200;
           body: JsonNode): Recallable =
  ## describeMaintenanceWindowsForTarget
  ## Retrieves information about the maintenance window targets or tasks that an instance is associated with.
  ##   
                                                                                                             ## body: JObject (required)
  var body_402657214 = newJObject()
  if body != nil:
    body_402657214 = body
  result = call_402657213.call(nil, nil, nil, nil, body_402657214)

var describeMaintenanceWindowsForTarget* = Call_DescribeMaintenanceWindowsForTarget_402657200(
    name: "describeMaintenanceWindowsForTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeMaintenanceWindowsForTarget",
    validator: validate_DescribeMaintenanceWindowsForTarget_402657201,
    base: "/", makeUrl: url_DescribeMaintenanceWindowsForTarget_402657202,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOpsItems_402657215 = ref object of OpenApiRestCall_402656044
proc url_DescribeOpsItems_402657217(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeOpsItems_402657216(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657218 = header.getOrDefault("X-Amz-Target")
  valid_402657218 = validateParameter(valid_402657218, JString, required = true, default = newJString(
      "AmazonSSM.DescribeOpsItems"))
  if valid_402657218 != nil:
    section.add "X-Amz-Target", valid_402657218
  var valid_402657219 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657219 = validateParameter(valid_402657219, JString,
                                      required = false, default = nil)
  if valid_402657219 != nil:
    section.add "X-Amz-Security-Token", valid_402657219
  var valid_402657220 = header.getOrDefault("X-Amz-Signature")
  valid_402657220 = validateParameter(valid_402657220, JString,
                                      required = false, default = nil)
  if valid_402657220 != nil:
    section.add "X-Amz-Signature", valid_402657220
  var valid_402657221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657221 = validateParameter(valid_402657221, JString,
                                      required = false, default = nil)
  if valid_402657221 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657221
  var valid_402657222 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657222 = validateParameter(valid_402657222, JString,
                                      required = false, default = nil)
  if valid_402657222 != nil:
    section.add "X-Amz-Algorithm", valid_402657222
  var valid_402657223 = header.getOrDefault("X-Amz-Date")
  valid_402657223 = validateParameter(valid_402657223, JString,
                                      required = false, default = nil)
  if valid_402657223 != nil:
    section.add "X-Amz-Date", valid_402657223
  var valid_402657224 = header.getOrDefault("X-Amz-Credential")
  valid_402657224 = validateParameter(valid_402657224, JString,
                                      required = false, default = nil)
  if valid_402657224 != nil:
    section.add "X-Amz-Credential", valid_402657224
  var valid_402657225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657225 = validateParameter(valid_402657225, JString,
                                      required = false, default = nil)
  if valid_402657225 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657227: Call_DescribeOpsItems_402657215;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
                                                                                         ## 
  let valid = call_402657227.validator(path, query, header, formData, body, _)
  let scheme = call_402657227.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657227.makeUrl(scheme.get, call_402657227.host, call_402657227.base,
                                   call_402657227.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657227, uri, valid, _)

proc call*(call_402657228: Call_DescribeOpsItems_402657215; body: JsonNode): Recallable =
  ## describeOpsItems
  ## <p>Query a set of OpsItems. You must have permission in AWS Identity and Access Management (IAM) to query a list of OpsItems. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402657229 = newJObject()
  if body != nil:
    body_402657229 = body
  result = call_402657228.call(nil, nil, nil, nil, body_402657229)

var describeOpsItems* = Call_DescribeOpsItems_402657215(
    name: "describeOpsItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeOpsItems",
    validator: validate_DescribeOpsItems_402657216, base: "/",
    makeUrl: url_DescribeOpsItems_402657217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeParameters_402657230 = ref object of OpenApiRestCall_402656044
proc url_DescribeParameters_402657232(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeParameters_402657231(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Get information about a parameter.</p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657233 = query.getOrDefault("MaxResults")
  valid_402657233 = validateParameter(valid_402657233, JString,
                                      required = false, default = nil)
  if valid_402657233 != nil:
    section.add "MaxResults", valid_402657233
  var valid_402657234 = query.getOrDefault("NextToken")
  valid_402657234 = validateParameter(valid_402657234, JString,
                                      required = false, default = nil)
  if valid_402657234 != nil:
    section.add "NextToken", valid_402657234
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657235 = header.getOrDefault("X-Amz-Target")
  valid_402657235 = validateParameter(valid_402657235, JString, required = true, default = newJString(
      "AmazonSSM.DescribeParameters"))
  if valid_402657235 != nil:
    section.add "X-Amz-Target", valid_402657235
  var valid_402657236 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657236 = validateParameter(valid_402657236, JString,
                                      required = false, default = nil)
  if valid_402657236 != nil:
    section.add "X-Amz-Security-Token", valid_402657236
  var valid_402657237 = header.getOrDefault("X-Amz-Signature")
  valid_402657237 = validateParameter(valid_402657237, JString,
                                      required = false, default = nil)
  if valid_402657237 != nil:
    section.add "X-Amz-Signature", valid_402657237
  var valid_402657238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657238 = validateParameter(valid_402657238, JString,
                                      required = false, default = nil)
  if valid_402657238 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657238
  var valid_402657239 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657239 = validateParameter(valid_402657239, JString,
                                      required = false, default = nil)
  if valid_402657239 != nil:
    section.add "X-Amz-Algorithm", valid_402657239
  var valid_402657240 = header.getOrDefault("X-Amz-Date")
  valid_402657240 = validateParameter(valid_402657240, JString,
                                      required = false, default = nil)
  if valid_402657240 != nil:
    section.add "X-Amz-Date", valid_402657240
  var valid_402657241 = header.getOrDefault("X-Amz-Credential")
  valid_402657241 = validateParameter(valid_402657241, JString,
                                      required = false, default = nil)
  if valid_402657241 != nil:
    section.add "X-Amz-Credential", valid_402657241
  var valid_402657242 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657242 = validateParameter(valid_402657242, JString,
                                      required = false, default = nil)
  if valid_402657242 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657244: Call_DescribeParameters_402657230;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Get information about a parameter.</p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
                                                                                         ## 
  let valid = call_402657244.validator(path, query, header, formData, body, _)
  let scheme = call_402657244.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657244.makeUrl(scheme.get, call_402657244.host, call_402657244.base,
                                   call_402657244.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657244, uri, valid, _)

proc call*(call_402657245: Call_DescribeParameters_402657230; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## describeParameters
  ## <p>Get information about a parameter.</p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                  ## token
  var query_402657246 = newJObject()
  var body_402657247 = newJObject()
  add(query_402657246, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657247 = body
  add(query_402657246, "NextToken", newJString(NextToken))
  result = call_402657245.call(nil, query_402657246, nil, nil, body_402657247)

var describeParameters* = Call_DescribeParameters_402657230(
    name: "describeParameters", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeParameters",
    validator: validate_DescribeParameters_402657231, base: "/",
    makeUrl: url_DescribeParameters_402657232,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchBaselines_402657248 = ref object of OpenApiRestCall_402656044
proc url_DescribePatchBaselines_402657250(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePatchBaselines_402657249(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the patch baselines in your AWS account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657251 = header.getOrDefault("X-Amz-Target")
  valid_402657251 = validateParameter(valid_402657251, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchBaselines"))
  if valid_402657251 != nil:
    section.add "X-Amz-Target", valid_402657251
  var valid_402657252 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657252 = validateParameter(valid_402657252, JString,
                                      required = false, default = nil)
  if valid_402657252 != nil:
    section.add "X-Amz-Security-Token", valid_402657252
  var valid_402657253 = header.getOrDefault("X-Amz-Signature")
  valid_402657253 = validateParameter(valid_402657253, JString,
                                      required = false, default = nil)
  if valid_402657253 != nil:
    section.add "X-Amz-Signature", valid_402657253
  var valid_402657254 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657254 = validateParameter(valid_402657254, JString,
                                      required = false, default = nil)
  if valid_402657254 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657254
  var valid_402657255 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657255 = validateParameter(valid_402657255, JString,
                                      required = false, default = nil)
  if valid_402657255 != nil:
    section.add "X-Amz-Algorithm", valid_402657255
  var valid_402657256 = header.getOrDefault("X-Amz-Date")
  valid_402657256 = validateParameter(valid_402657256, JString,
                                      required = false, default = nil)
  if valid_402657256 != nil:
    section.add "X-Amz-Date", valid_402657256
  var valid_402657257 = header.getOrDefault("X-Amz-Credential")
  valid_402657257 = validateParameter(valid_402657257, JString,
                                      required = false, default = nil)
  if valid_402657257 != nil:
    section.add "X-Amz-Credential", valid_402657257
  var valid_402657258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657258 = validateParameter(valid_402657258, JString,
                                      required = false, default = nil)
  if valid_402657258 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657260: Call_DescribePatchBaselines_402657248;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the patch baselines in your AWS account.
                                                                                         ## 
  let valid = call_402657260.validator(path, query, header, formData, body, _)
  let scheme = call_402657260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657260.makeUrl(scheme.get, call_402657260.host, call_402657260.base,
                                   call_402657260.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657260, uri, valid, _)

proc call*(call_402657261: Call_DescribePatchBaselines_402657248; body: JsonNode): Recallable =
  ## describePatchBaselines
  ## Lists the patch baselines in your AWS account.
  ##   body: JObject (required)
  var body_402657262 = newJObject()
  if body != nil:
    body_402657262 = body
  result = call_402657261.call(nil, nil, nil, nil, body_402657262)

var describePatchBaselines* = Call_DescribePatchBaselines_402657248(
    name: "describePatchBaselines", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchBaselines",
    validator: validate_DescribePatchBaselines_402657249, base: "/",
    makeUrl: url_DescribePatchBaselines_402657250,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroupState_402657263 = ref object of OpenApiRestCall_402656044
proc url_DescribePatchGroupState_402657265(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePatchGroupState_402657264(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns high-level aggregated patch compliance state for a patch group.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657266 = header.getOrDefault("X-Amz-Target")
  valid_402657266 = validateParameter(valid_402657266, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroupState"))
  if valid_402657266 != nil:
    section.add "X-Amz-Target", valid_402657266
  var valid_402657267 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657267 = validateParameter(valid_402657267, JString,
                                      required = false, default = nil)
  if valid_402657267 != nil:
    section.add "X-Amz-Security-Token", valid_402657267
  var valid_402657268 = header.getOrDefault("X-Amz-Signature")
  valid_402657268 = validateParameter(valid_402657268, JString,
                                      required = false, default = nil)
  if valid_402657268 != nil:
    section.add "X-Amz-Signature", valid_402657268
  var valid_402657269 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657269 = validateParameter(valid_402657269, JString,
                                      required = false, default = nil)
  if valid_402657269 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657269
  var valid_402657270 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657270 = validateParameter(valid_402657270, JString,
                                      required = false, default = nil)
  if valid_402657270 != nil:
    section.add "X-Amz-Algorithm", valid_402657270
  var valid_402657271 = header.getOrDefault("X-Amz-Date")
  valid_402657271 = validateParameter(valid_402657271, JString,
                                      required = false, default = nil)
  if valid_402657271 != nil:
    section.add "X-Amz-Date", valid_402657271
  var valid_402657272 = header.getOrDefault("X-Amz-Credential")
  valid_402657272 = validateParameter(valid_402657272, JString,
                                      required = false, default = nil)
  if valid_402657272 != nil:
    section.add "X-Amz-Credential", valid_402657272
  var valid_402657273 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657273 = validateParameter(valid_402657273, JString,
                                      required = false, default = nil)
  if valid_402657273 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657273
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657275: Call_DescribePatchGroupState_402657263;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns high-level aggregated patch compliance state for a patch group.
                                                                                         ## 
  let valid = call_402657275.validator(path, query, header, formData, body, _)
  let scheme = call_402657275.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657275.makeUrl(scheme.get, call_402657275.host, call_402657275.base,
                                   call_402657275.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657275, uri, valid, _)

proc call*(call_402657276: Call_DescribePatchGroupState_402657263;
           body: JsonNode): Recallable =
  ## describePatchGroupState
  ## Returns high-level aggregated patch compliance state for a patch group.
  ##   
                                                                            ## body: JObject (required)
  var body_402657277 = newJObject()
  if body != nil:
    body_402657277 = body
  result = call_402657276.call(nil, nil, nil, nil, body_402657277)

var describePatchGroupState* = Call_DescribePatchGroupState_402657263(
    name: "describePatchGroupState", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroupState",
    validator: validate_DescribePatchGroupState_402657264, base: "/",
    makeUrl: url_DescribePatchGroupState_402657265,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchGroups_402657278 = ref object of OpenApiRestCall_402656044
proc url_DescribePatchGroups_402657280(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePatchGroups_402657279(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists all patch groups that have been registered with patch baselines.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657281 = header.getOrDefault("X-Amz-Target")
  valid_402657281 = validateParameter(valid_402657281, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchGroups"))
  if valid_402657281 != nil:
    section.add "X-Amz-Target", valid_402657281
  var valid_402657282 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657282 = validateParameter(valid_402657282, JString,
                                      required = false, default = nil)
  if valid_402657282 != nil:
    section.add "X-Amz-Security-Token", valid_402657282
  var valid_402657283 = header.getOrDefault("X-Amz-Signature")
  valid_402657283 = validateParameter(valid_402657283, JString,
                                      required = false, default = nil)
  if valid_402657283 != nil:
    section.add "X-Amz-Signature", valid_402657283
  var valid_402657284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657284 = validateParameter(valid_402657284, JString,
                                      required = false, default = nil)
  if valid_402657284 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657284
  var valid_402657285 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657285 = validateParameter(valid_402657285, JString,
                                      required = false, default = nil)
  if valid_402657285 != nil:
    section.add "X-Amz-Algorithm", valid_402657285
  var valid_402657286 = header.getOrDefault("X-Amz-Date")
  valid_402657286 = validateParameter(valid_402657286, JString,
                                      required = false, default = nil)
  if valid_402657286 != nil:
    section.add "X-Amz-Date", valid_402657286
  var valid_402657287 = header.getOrDefault("X-Amz-Credential")
  valid_402657287 = validateParameter(valid_402657287, JString,
                                      required = false, default = nil)
  if valid_402657287 != nil:
    section.add "X-Amz-Credential", valid_402657287
  var valid_402657288 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657288 = validateParameter(valid_402657288, JString,
                                      required = false, default = nil)
  if valid_402657288 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657288
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657290: Call_DescribePatchGroups_402657278;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists all patch groups that have been registered with patch baselines.
                                                                                         ## 
  let valid = call_402657290.validator(path, query, header, formData, body, _)
  let scheme = call_402657290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657290.makeUrl(scheme.get, call_402657290.host, call_402657290.base,
                                   call_402657290.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657290, uri, valid, _)

proc call*(call_402657291: Call_DescribePatchGroups_402657278; body: JsonNode): Recallable =
  ## describePatchGroups
  ## Lists all patch groups that have been registered with patch baselines.
  ##   body: 
                                                                           ## JObject (required)
  var body_402657292 = newJObject()
  if body != nil:
    body_402657292 = body
  result = call_402657291.call(nil, nil, nil, nil, body_402657292)

var describePatchGroups* = Call_DescribePatchGroups_402657278(
    name: "describePatchGroups", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchGroups",
    validator: validate_DescribePatchGroups_402657279, base: "/",
    makeUrl: url_DescribePatchGroups_402657280,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribePatchProperties_402657293 = ref object of OpenApiRestCall_402656044
proc url_DescribePatchProperties_402657295(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribePatchProperties_402657294(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657296 = header.getOrDefault("X-Amz-Target")
  valid_402657296 = validateParameter(valid_402657296, JString, required = true, default = newJString(
      "AmazonSSM.DescribePatchProperties"))
  if valid_402657296 != nil:
    section.add "X-Amz-Target", valid_402657296
  var valid_402657297 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657297 = validateParameter(valid_402657297, JString,
                                      required = false, default = nil)
  if valid_402657297 != nil:
    section.add "X-Amz-Security-Token", valid_402657297
  var valid_402657298 = header.getOrDefault("X-Amz-Signature")
  valid_402657298 = validateParameter(valid_402657298, JString,
                                      required = false, default = nil)
  if valid_402657298 != nil:
    section.add "X-Amz-Signature", valid_402657298
  var valid_402657299 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657299 = validateParameter(valid_402657299, JString,
                                      required = false, default = nil)
  if valid_402657299 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657299
  var valid_402657300 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657300 = validateParameter(valid_402657300, JString,
                                      required = false, default = nil)
  if valid_402657300 != nil:
    section.add "X-Amz-Algorithm", valid_402657300
  var valid_402657301 = header.getOrDefault("X-Amz-Date")
  valid_402657301 = validateParameter(valid_402657301, JString,
                                      required = false, default = nil)
  if valid_402657301 != nil:
    section.add "X-Amz-Date", valid_402657301
  var valid_402657302 = header.getOrDefault("X-Amz-Credential")
  valid_402657302 = validateParameter(valid_402657302, JString,
                                      required = false, default = nil)
  if valid_402657302 != nil:
    section.add "X-Amz-Credential", valid_402657302
  var valid_402657303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657303 = validateParameter(valid_402657303, JString,
                                      required = false, default = nil)
  if valid_402657303 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657305: Call_DescribePatchProperties_402657293;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
                                                                                         ## 
  let valid = call_402657305.validator(path, query, header, formData, body, _)
  let scheme = call_402657305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657305.makeUrl(scheme.get, call_402657305.host, call_402657305.base,
                                   call_402657305.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657305, uri, valid, _)

proc call*(call_402657306: Call_DescribePatchProperties_402657293;
           body: JsonNode): Recallable =
  ## describePatchProperties
  ## <p>Lists the properties of available patches organized by product, product family, classification, severity, and other properties of available patches. You can use the reported properties in the filters you specify in requests for actions such as <a>CreatePatchBaseline</a>, <a>UpdatePatchBaseline</a>, <a>DescribeAvailablePatches</a>, and <a>DescribePatchBaselines</a>.</p> <p>The following section lists the properties that can be used in filters for each major operating system type:</p> <dl> <dt>WINDOWS</dt> <dd> <p>Valid properties: PRODUCT, PRODUCT_FAMILY, CLASSIFICATION, MSRC_SEVERITY</p> </dd> <dt>AMAZON_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>AMAZON_LINUX_2</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>UBUNTU </dt> <dd> <p>Valid properties: PRODUCT, PRIORITY</p> </dd> <dt>REDHAT_ENTERPRISE_LINUX</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>SUSE</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> <dt>CENTOS</dt> <dd> <p>Valid properties: PRODUCT, CLASSIFICATION, SEVERITY</p> </dd> </dl>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402657307 = newJObject()
  if body != nil:
    body_402657307 = body
  result = call_402657306.call(nil, nil, nil, nil, body_402657307)

var describePatchProperties* = Call_DescribePatchProperties_402657293(
    name: "describePatchProperties", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribePatchProperties",
    validator: validate_DescribePatchProperties_402657294, base: "/",
    makeUrl: url_DescribePatchProperties_402657295,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSessions_402657308 = ref object of OpenApiRestCall_402656044
proc url_DescribeSessions_402657310(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DescribeSessions_402657309(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657311 = header.getOrDefault("X-Amz-Target")
  valid_402657311 = validateParameter(valid_402657311, JString, required = true, default = newJString(
      "AmazonSSM.DescribeSessions"))
  if valid_402657311 != nil:
    section.add "X-Amz-Target", valid_402657311
  var valid_402657312 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657312 = validateParameter(valid_402657312, JString,
                                      required = false, default = nil)
  if valid_402657312 != nil:
    section.add "X-Amz-Security-Token", valid_402657312
  var valid_402657313 = header.getOrDefault("X-Amz-Signature")
  valid_402657313 = validateParameter(valid_402657313, JString,
                                      required = false, default = nil)
  if valid_402657313 != nil:
    section.add "X-Amz-Signature", valid_402657313
  var valid_402657314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657314 = validateParameter(valid_402657314, JString,
                                      required = false, default = nil)
  if valid_402657314 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657314
  var valid_402657315 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657315 = validateParameter(valid_402657315, JString,
                                      required = false, default = nil)
  if valid_402657315 != nil:
    section.add "X-Amz-Algorithm", valid_402657315
  var valid_402657316 = header.getOrDefault("X-Amz-Date")
  valid_402657316 = validateParameter(valid_402657316, JString,
                                      required = false, default = nil)
  if valid_402657316 != nil:
    section.add "X-Amz-Date", valid_402657316
  var valid_402657317 = header.getOrDefault("X-Amz-Credential")
  valid_402657317 = validateParameter(valid_402657317, JString,
                                      required = false, default = nil)
  if valid_402657317 != nil:
    section.add "X-Amz-Credential", valid_402657317
  var valid_402657318 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657318 = validateParameter(valid_402657318, JString,
                                      required = false, default = nil)
  if valid_402657318 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657318
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657320: Call_DescribeSessions_402657308;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
                                                                                         ## 
  let valid = call_402657320.validator(path, query, header, formData, body, _)
  let scheme = call_402657320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657320.makeUrl(scheme.get, call_402657320.host, call_402657320.base,
                                   call_402657320.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657320, uri, valid, _)

proc call*(call_402657321: Call_DescribeSessions_402657308; body: JsonNode): Recallable =
  ## describeSessions
  ## Retrieves a list of all active sessions (both connected and disconnected) or terminated sessions from the past 30 days.
  ##   
                                                                                                                            ## body: JObject (required)
  var body_402657322 = newJObject()
  if body != nil:
    body_402657322 = body
  result = call_402657321.call(nil, nil, nil, nil, body_402657322)

var describeSessions* = Call_DescribeSessions_402657308(
    name: "describeSessions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.DescribeSessions",
    validator: validate_DescribeSessions_402657309, base: "/",
    makeUrl: url_DescribeSessions_402657310,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetAutomationExecution_402657323 = ref object of OpenApiRestCall_402656044
proc url_GetAutomationExecution_402657325(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetAutomationExecution_402657324(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get detailed information about a particular Automation execution.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657326 = header.getOrDefault("X-Amz-Target")
  valid_402657326 = validateParameter(valid_402657326, JString, required = true, default = newJString(
      "AmazonSSM.GetAutomationExecution"))
  if valid_402657326 != nil:
    section.add "X-Amz-Target", valid_402657326
  var valid_402657327 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657327 = validateParameter(valid_402657327, JString,
                                      required = false, default = nil)
  if valid_402657327 != nil:
    section.add "X-Amz-Security-Token", valid_402657327
  var valid_402657328 = header.getOrDefault("X-Amz-Signature")
  valid_402657328 = validateParameter(valid_402657328, JString,
                                      required = false, default = nil)
  if valid_402657328 != nil:
    section.add "X-Amz-Signature", valid_402657328
  var valid_402657329 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657329 = validateParameter(valid_402657329, JString,
                                      required = false, default = nil)
  if valid_402657329 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657329
  var valid_402657330 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657330 = validateParameter(valid_402657330, JString,
                                      required = false, default = nil)
  if valid_402657330 != nil:
    section.add "X-Amz-Algorithm", valid_402657330
  var valid_402657331 = header.getOrDefault("X-Amz-Date")
  valid_402657331 = validateParameter(valid_402657331, JString,
                                      required = false, default = nil)
  if valid_402657331 != nil:
    section.add "X-Amz-Date", valid_402657331
  var valid_402657332 = header.getOrDefault("X-Amz-Credential")
  valid_402657332 = validateParameter(valid_402657332, JString,
                                      required = false, default = nil)
  if valid_402657332 != nil:
    section.add "X-Amz-Credential", valid_402657332
  var valid_402657333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657333 = validateParameter(valid_402657333, JString,
                                      required = false, default = nil)
  if valid_402657333 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657335: Call_GetAutomationExecution_402657323;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get detailed information about a particular Automation execution.
                                                                                         ## 
  let valid = call_402657335.validator(path, query, header, formData, body, _)
  let scheme = call_402657335.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657335.makeUrl(scheme.get, call_402657335.host, call_402657335.base,
                                   call_402657335.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657335, uri, valid, _)

proc call*(call_402657336: Call_GetAutomationExecution_402657323; body: JsonNode): Recallable =
  ## getAutomationExecution
  ## Get detailed information about a particular Automation execution.
  ##   body: JObject (required)
  var body_402657337 = newJObject()
  if body != nil:
    body_402657337 = body
  result = call_402657336.call(nil, nil, nil, nil, body_402657337)

var getAutomationExecution* = Call_GetAutomationExecution_402657323(
    name: "getAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetAutomationExecution",
    validator: validate_GetAutomationExecution_402657324, base: "/",
    makeUrl: url_GetAutomationExecution_402657325,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCalendarState_402657338 = ref object of OpenApiRestCall_402656044
proc url_GetCalendarState_402657340(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCalendarState_402657339(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the state of the AWS Systems Manager Change Calendar at an optional, specified time. If you specify a time, <code>GetCalendarState</code> returns the state of the calendar at a specific time, and returns the next time that the Change Calendar state will transition. If you do not specify a time, <code>GetCalendarState</code> assumes the current time. Change Calendar entries have two possible states: <code>OPEN</code> or <code>CLOSED</code>. For more information about Systems Manager Change Calendar, see <a href="https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar.html">AWS Systems Manager Change Calendar</a> in the <i>AWS Systems Manager User Guide</i>.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657341 = header.getOrDefault("X-Amz-Target")
  valid_402657341 = validateParameter(valid_402657341, JString, required = true, default = newJString(
      "AmazonSSM.GetCalendarState"))
  if valid_402657341 != nil:
    section.add "X-Amz-Target", valid_402657341
  var valid_402657342 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657342 = validateParameter(valid_402657342, JString,
                                      required = false, default = nil)
  if valid_402657342 != nil:
    section.add "X-Amz-Security-Token", valid_402657342
  var valid_402657343 = header.getOrDefault("X-Amz-Signature")
  valid_402657343 = validateParameter(valid_402657343, JString,
                                      required = false, default = nil)
  if valid_402657343 != nil:
    section.add "X-Amz-Signature", valid_402657343
  var valid_402657344 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657344 = validateParameter(valid_402657344, JString,
                                      required = false, default = nil)
  if valid_402657344 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657344
  var valid_402657345 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657345 = validateParameter(valid_402657345, JString,
                                      required = false, default = nil)
  if valid_402657345 != nil:
    section.add "X-Amz-Algorithm", valid_402657345
  var valid_402657346 = header.getOrDefault("X-Amz-Date")
  valid_402657346 = validateParameter(valid_402657346, JString,
                                      required = false, default = nil)
  if valid_402657346 != nil:
    section.add "X-Amz-Date", valid_402657346
  var valid_402657347 = header.getOrDefault("X-Amz-Credential")
  valid_402657347 = validateParameter(valid_402657347, JString,
                                      required = false, default = nil)
  if valid_402657347 != nil:
    section.add "X-Amz-Credential", valid_402657347
  var valid_402657348 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657348 = validateParameter(valid_402657348, JString,
                                      required = false, default = nil)
  if valid_402657348 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657348
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657350: Call_GetCalendarState_402657338;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the state of the AWS Systems Manager Change Calendar at an optional, specified time. If you specify a time, <code>GetCalendarState</code> returns the state of the calendar at a specific time, and returns the next time that the Change Calendar state will transition. If you do not specify a time, <code>GetCalendarState</code> assumes the current time. Change Calendar entries have two possible states: <code>OPEN</code> or <code>CLOSED</code>. For more information about Systems Manager Change Calendar, see <a href="https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar.html">AWS Systems Manager Change Calendar</a> in the <i>AWS Systems Manager User Guide</i>.
                                                                                         ## 
  let valid = call_402657350.validator(path, query, header, formData, body, _)
  let scheme = call_402657350.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657350.makeUrl(scheme.get, call_402657350.host, call_402657350.base,
                                   call_402657350.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657350, uri, valid, _)

proc call*(call_402657351: Call_GetCalendarState_402657338; body: JsonNode): Recallable =
  ## getCalendarState
  ## Gets the state of the AWS Systems Manager Change Calendar at an optional, specified time. If you specify a time, <code>GetCalendarState</code> returns the state of the calendar at a specific time, and returns the next time that the Change Calendar state will transition. If you do not specify a time, <code>GetCalendarState</code> assumes the current time. Change Calendar entries have two possible states: <code>OPEN</code> or <code>CLOSED</code>. For more information about Systems Manager Change Calendar, see <a href="https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-change-calendar.html">AWS Systems Manager Change Calendar</a> in the <i>AWS Systems Manager User Guide</i>.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## body: JObject (required)
  var body_402657352 = newJObject()
  if body != nil:
    body_402657352 = body
  result = call_402657351.call(nil, nil, nil, nil, body_402657352)

var getCalendarState* = Call_GetCalendarState_402657338(
    name: "getCalendarState", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetCalendarState",
    validator: validate_GetCalendarState_402657339, base: "/",
    makeUrl: url_GetCalendarState_402657340,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetCommandInvocation_402657353 = ref object of OpenApiRestCall_402656044
proc url_GetCommandInvocation_402657355(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetCommandInvocation_402657354(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns detailed information about command execution for an invocation or plugin. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657356 = header.getOrDefault("X-Amz-Target")
  valid_402657356 = validateParameter(valid_402657356, JString, required = true, default = newJString(
      "AmazonSSM.GetCommandInvocation"))
  if valid_402657356 != nil:
    section.add "X-Amz-Target", valid_402657356
  var valid_402657357 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657357 = validateParameter(valid_402657357, JString,
                                      required = false, default = nil)
  if valid_402657357 != nil:
    section.add "X-Amz-Security-Token", valid_402657357
  var valid_402657358 = header.getOrDefault("X-Amz-Signature")
  valid_402657358 = validateParameter(valid_402657358, JString,
                                      required = false, default = nil)
  if valid_402657358 != nil:
    section.add "X-Amz-Signature", valid_402657358
  var valid_402657359 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657359 = validateParameter(valid_402657359, JString,
                                      required = false, default = nil)
  if valid_402657359 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657359
  var valid_402657360 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657360 = validateParameter(valid_402657360, JString,
                                      required = false, default = nil)
  if valid_402657360 != nil:
    section.add "X-Amz-Algorithm", valid_402657360
  var valid_402657361 = header.getOrDefault("X-Amz-Date")
  valid_402657361 = validateParameter(valid_402657361, JString,
                                      required = false, default = nil)
  if valid_402657361 != nil:
    section.add "X-Amz-Date", valid_402657361
  var valid_402657362 = header.getOrDefault("X-Amz-Credential")
  valid_402657362 = validateParameter(valid_402657362, JString,
                                      required = false, default = nil)
  if valid_402657362 != nil:
    section.add "X-Amz-Credential", valid_402657362
  var valid_402657363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657363 = validateParameter(valid_402657363, JString,
                                      required = false, default = nil)
  if valid_402657363 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657365: Call_GetCommandInvocation_402657353;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns detailed information about command execution for an invocation or plugin. 
                                                                                         ## 
  let valid = call_402657365.validator(path, query, header, formData, body, _)
  let scheme = call_402657365.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657365.makeUrl(scheme.get, call_402657365.host, call_402657365.base,
                                   call_402657365.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657365, uri, valid, _)

proc call*(call_402657366: Call_GetCommandInvocation_402657353; body: JsonNode): Recallable =
  ## getCommandInvocation
  ## Returns detailed information about command execution for an invocation or plugin. 
  ##   
                                                                                       ## body: JObject (required)
  var body_402657367 = newJObject()
  if body != nil:
    body_402657367 = body
  result = call_402657366.call(nil, nil, nil, nil, body_402657367)

var getCommandInvocation* = Call_GetCommandInvocation_402657353(
    name: "getCommandInvocation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetCommandInvocation",
    validator: validate_GetCommandInvocation_402657354, base: "/",
    makeUrl: url_GetCommandInvocation_402657355,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetConnectionStatus_402657368 = ref object of OpenApiRestCall_402656044
proc url_GetConnectionStatus_402657370(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetConnectionStatus_402657369(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657371 = header.getOrDefault("X-Amz-Target")
  valid_402657371 = validateParameter(valid_402657371, JString, required = true, default = newJString(
      "AmazonSSM.GetConnectionStatus"))
  if valid_402657371 != nil:
    section.add "X-Amz-Target", valid_402657371
  var valid_402657372 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657372 = validateParameter(valid_402657372, JString,
                                      required = false, default = nil)
  if valid_402657372 != nil:
    section.add "X-Amz-Security-Token", valid_402657372
  var valid_402657373 = header.getOrDefault("X-Amz-Signature")
  valid_402657373 = validateParameter(valid_402657373, JString,
                                      required = false, default = nil)
  if valid_402657373 != nil:
    section.add "X-Amz-Signature", valid_402657373
  var valid_402657374 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657374 = validateParameter(valid_402657374, JString,
                                      required = false, default = nil)
  if valid_402657374 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657374
  var valid_402657375 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657375 = validateParameter(valid_402657375, JString,
                                      required = false, default = nil)
  if valid_402657375 != nil:
    section.add "X-Amz-Algorithm", valid_402657375
  var valid_402657376 = header.getOrDefault("X-Amz-Date")
  valid_402657376 = validateParameter(valid_402657376, JString,
                                      required = false, default = nil)
  if valid_402657376 != nil:
    section.add "X-Amz-Date", valid_402657376
  var valid_402657377 = header.getOrDefault("X-Amz-Credential")
  valid_402657377 = validateParameter(valid_402657377, JString,
                                      required = false, default = nil)
  if valid_402657377 != nil:
    section.add "X-Amz-Credential", valid_402657377
  var valid_402657378 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657378 = validateParameter(valid_402657378, JString,
                                      required = false, default = nil)
  if valid_402657378 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657378
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657380: Call_GetConnectionStatus_402657368;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
                                                                                         ## 
  let valid = call_402657380.validator(path, query, header, formData, body, _)
  let scheme = call_402657380.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657380.makeUrl(scheme.get, call_402657380.host, call_402657380.base,
                                   call_402657380.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657380, uri, valid, _)

proc call*(call_402657381: Call_GetConnectionStatus_402657368; body: JsonNode): Recallable =
  ## getConnectionStatus
  ## Retrieves the Session Manager connection status for an instance to determine whether it is connected and ready to receive Session Manager connections.
  ##   
                                                                                                                                                           ## body: JObject (required)
  var body_402657382 = newJObject()
  if body != nil:
    body_402657382 = body
  result = call_402657381.call(nil, nil, nil, nil, body_402657382)

var getConnectionStatus* = Call_GetConnectionStatus_402657368(
    name: "getConnectionStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetConnectionStatus",
    validator: validate_GetConnectionStatus_402657369, base: "/",
    makeUrl: url_GetConnectionStatus_402657370,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDefaultPatchBaseline_402657383 = ref object of OpenApiRestCall_402656044
proc url_GetDefaultPatchBaseline_402657385(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDefaultPatchBaseline_402657384(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657386 = header.getOrDefault("X-Amz-Target")
  valid_402657386 = validateParameter(valid_402657386, JString, required = true, default = newJString(
      "AmazonSSM.GetDefaultPatchBaseline"))
  if valid_402657386 != nil:
    section.add "X-Amz-Target", valid_402657386
  var valid_402657387 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657387 = validateParameter(valid_402657387, JString,
                                      required = false, default = nil)
  if valid_402657387 != nil:
    section.add "X-Amz-Security-Token", valid_402657387
  var valid_402657388 = header.getOrDefault("X-Amz-Signature")
  valid_402657388 = validateParameter(valid_402657388, JString,
                                      required = false, default = nil)
  if valid_402657388 != nil:
    section.add "X-Amz-Signature", valid_402657388
  var valid_402657389 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657389 = validateParameter(valid_402657389, JString,
                                      required = false, default = nil)
  if valid_402657389 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657389
  var valid_402657390 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657390 = validateParameter(valid_402657390, JString,
                                      required = false, default = nil)
  if valid_402657390 != nil:
    section.add "X-Amz-Algorithm", valid_402657390
  var valid_402657391 = header.getOrDefault("X-Amz-Date")
  valid_402657391 = validateParameter(valid_402657391, JString,
                                      required = false, default = nil)
  if valid_402657391 != nil:
    section.add "X-Amz-Date", valid_402657391
  var valid_402657392 = header.getOrDefault("X-Amz-Credential")
  valid_402657392 = validateParameter(valid_402657392, JString,
                                      required = false, default = nil)
  if valid_402657392 != nil:
    section.add "X-Amz-Credential", valid_402657392
  var valid_402657393 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657393 = validateParameter(valid_402657393, JString,
                                      required = false, default = nil)
  if valid_402657393 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657393
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657395: Call_GetDefaultPatchBaseline_402657383;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
                                                                                         ## 
  let valid = call_402657395.validator(path, query, header, formData, body, _)
  let scheme = call_402657395.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657395.makeUrl(scheme.get, call_402657395.host, call_402657395.base,
                                   call_402657395.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657395, uri, valid, _)

proc call*(call_402657396: Call_GetDefaultPatchBaseline_402657383;
           body: JsonNode): Recallable =
  ## getDefaultPatchBaseline
  ## <p>Retrieves the default patch baseline. Note that Systems Manager supports creating multiple default patch baselines. For example, you can create a default patch baseline for each operating system.</p> <p>If you do not specify an operating system value, the default patch baseline for Windows is returned.</p>
  ##   
                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402657397 = newJObject()
  if body != nil:
    body_402657397 = body
  result = call_402657396.call(nil, nil, nil, nil, body_402657397)

var getDefaultPatchBaseline* = Call_GetDefaultPatchBaseline_402657383(
    name: "getDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDefaultPatchBaseline",
    validator: validate_GetDefaultPatchBaseline_402657384, base: "/",
    makeUrl: url_GetDefaultPatchBaseline_402657385,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDeployablePatchSnapshotForInstance_402657398 = ref object of OpenApiRestCall_402656044
proc url_GetDeployablePatchSnapshotForInstance_402657400(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDeployablePatchSnapshotForInstance_402657399(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657401 = header.getOrDefault("X-Amz-Target")
  valid_402657401 = validateParameter(valid_402657401, JString, required = true, default = newJString(
      "AmazonSSM.GetDeployablePatchSnapshotForInstance"))
  if valid_402657401 != nil:
    section.add "X-Amz-Target", valid_402657401
  var valid_402657402 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657402 = validateParameter(valid_402657402, JString,
                                      required = false, default = nil)
  if valid_402657402 != nil:
    section.add "X-Amz-Security-Token", valid_402657402
  var valid_402657403 = header.getOrDefault("X-Amz-Signature")
  valid_402657403 = validateParameter(valid_402657403, JString,
                                      required = false, default = nil)
  if valid_402657403 != nil:
    section.add "X-Amz-Signature", valid_402657403
  var valid_402657404 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657404 = validateParameter(valid_402657404, JString,
                                      required = false, default = nil)
  if valid_402657404 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657404
  var valid_402657405 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657405 = validateParameter(valid_402657405, JString,
                                      required = false, default = nil)
  if valid_402657405 != nil:
    section.add "X-Amz-Algorithm", valid_402657405
  var valid_402657406 = header.getOrDefault("X-Amz-Date")
  valid_402657406 = validateParameter(valid_402657406, JString,
                                      required = false, default = nil)
  if valid_402657406 != nil:
    section.add "X-Amz-Date", valid_402657406
  var valid_402657407 = header.getOrDefault("X-Amz-Credential")
  valid_402657407 = validateParameter(valid_402657407, JString,
                                      required = false, default = nil)
  if valid_402657407 != nil:
    section.add "X-Amz-Credential", valid_402657407
  var valid_402657408 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657408 = validateParameter(valid_402657408, JString,
                                      required = false, default = nil)
  if valid_402657408 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657408
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657410: Call_GetDeployablePatchSnapshotForInstance_402657398;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
                                                                                         ## 
  let valid = call_402657410.validator(path, query, header, formData, body, _)
  let scheme = call_402657410.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657410.makeUrl(scheme.get, call_402657410.host, call_402657410.base,
                                   call_402657410.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657410, uri, valid, _)

proc call*(call_402657411: Call_GetDeployablePatchSnapshotForInstance_402657398;
           body: JsonNode): Recallable =
  ## getDeployablePatchSnapshotForInstance
  ## Retrieves the current snapshot for the patch baseline the instance uses. This API is primarily used by the AWS-RunPatchBaseline Systems Manager document. 
  ##   
                                                                                                                                                               ## body: JObject (required)
  var body_402657412 = newJObject()
  if body != nil:
    body_402657412 = body
  result = call_402657411.call(nil, nil, nil, nil, body_402657412)

var getDeployablePatchSnapshotForInstance* = Call_GetDeployablePatchSnapshotForInstance_402657398(
    name: "getDeployablePatchSnapshotForInstance", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDeployablePatchSnapshotForInstance",
    validator: validate_GetDeployablePatchSnapshotForInstance_402657399,
    base: "/", makeUrl: url_GetDeployablePatchSnapshotForInstance_402657400,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetDocument_402657413 = ref object of OpenApiRestCall_402656044
proc url_GetDocument_402657415(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetDocument_402657414(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets the contents of the specified Systems Manager document.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657416 = header.getOrDefault("X-Amz-Target")
  valid_402657416 = validateParameter(valid_402657416, JString, required = true, default = newJString(
      "AmazonSSM.GetDocument"))
  if valid_402657416 != nil:
    section.add "X-Amz-Target", valid_402657416
  var valid_402657417 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657417 = validateParameter(valid_402657417, JString,
                                      required = false, default = nil)
  if valid_402657417 != nil:
    section.add "X-Amz-Security-Token", valid_402657417
  var valid_402657418 = header.getOrDefault("X-Amz-Signature")
  valid_402657418 = validateParameter(valid_402657418, JString,
                                      required = false, default = nil)
  if valid_402657418 != nil:
    section.add "X-Amz-Signature", valid_402657418
  var valid_402657419 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657419 = validateParameter(valid_402657419, JString,
                                      required = false, default = nil)
  if valid_402657419 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657419
  var valid_402657420 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657420 = validateParameter(valid_402657420, JString,
                                      required = false, default = nil)
  if valid_402657420 != nil:
    section.add "X-Amz-Algorithm", valid_402657420
  var valid_402657421 = header.getOrDefault("X-Amz-Date")
  valid_402657421 = validateParameter(valid_402657421, JString,
                                      required = false, default = nil)
  if valid_402657421 != nil:
    section.add "X-Amz-Date", valid_402657421
  var valid_402657422 = header.getOrDefault("X-Amz-Credential")
  valid_402657422 = validateParameter(valid_402657422, JString,
                                      required = false, default = nil)
  if valid_402657422 != nil:
    section.add "X-Amz-Credential", valid_402657422
  var valid_402657423 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657423 = validateParameter(valid_402657423, JString,
                                      required = false, default = nil)
  if valid_402657423 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657423
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657425: Call_GetDocument_402657413; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets the contents of the specified Systems Manager document.
                                                                                         ## 
  let valid = call_402657425.validator(path, query, header, formData, body, _)
  let scheme = call_402657425.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657425.makeUrl(scheme.get, call_402657425.host, call_402657425.base,
                                   call_402657425.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657425, uri, valid, _)

proc call*(call_402657426: Call_GetDocument_402657413; body: JsonNode): Recallable =
  ## getDocument
  ## Gets the contents of the specified Systems Manager document.
  ##   body: JObject (required)
  var body_402657427 = newJObject()
  if body != nil:
    body_402657427 = body
  result = call_402657426.call(nil, nil, nil, nil, body_402657427)

var getDocument* = Call_GetDocument_402657413(name: "getDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetDocument",
    validator: validate_GetDocument_402657414, base: "/",
    makeUrl: url_GetDocument_402657415, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventory_402657428 = ref object of OpenApiRestCall_402656044
proc url_GetInventory_402657430(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInventory_402657429(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Query inventory information.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657431 = header.getOrDefault("X-Amz-Target")
  valid_402657431 = validateParameter(valid_402657431, JString, required = true, default = newJString(
      "AmazonSSM.GetInventory"))
  if valid_402657431 != nil:
    section.add "X-Amz-Target", valid_402657431
  var valid_402657432 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657432 = validateParameter(valid_402657432, JString,
                                      required = false, default = nil)
  if valid_402657432 != nil:
    section.add "X-Amz-Security-Token", valid_402657432
  var valid_402657433 = header.getOrDefault("X-Amz-Signature")
  valid_402657433 = validateParameter(valid_402657433, JString,
                                      required = false, default = nil)
  if valid_402657433 != nil:
    section.add "X-Amz-Signature", valid_402657433
  var valid_402657434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657434 = validateParameter(valid_402657434, JString,
                                      required = false, default = nil)
  if valid_402657434 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657434
  var valid_402657435 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657435 = validateParameter(valid_402657435, JString,
                                      required = false, default = nil)
  if valid_402657435 != nil:
    section.add "X-Amz-Algorithm", valid_402657435
  var valid_402657436 = header.getOrDefault("X-Amz-Date")
  valid_402657436 = validateParameter(valid_402657436, JString,
                                      required = false, default = nil)
  if valid_402657436 != nil:
    section.add "X-Amz-Date", valid_402657436
  var valid_402657437 = header.getOrDefault("X-Amz-Credential")
  valid_402657437 = validateParameter(valid_402657437, JString,
                                      required = false, default = nil)
  if valid_402657437 != nil:
    section.add "X-Amz-Credential", valid_402657437
  var valid_402657438 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657438 = validateParameter(valid_402657438, JString,
                                      required = false, default = nil)
  if valid_402657438 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657438
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657440: Call_GetInventory_402657428; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Query inventory information.
                                                                                         ## 
  let valid = call_402657440.validator(path, query, header, formData, body, _)
  let scheme = call_402657440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657440.makeUrl(scheme.get, call_402657440.host, call_402657440.base,
                                   call_402657440.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657440, uri, valid, _)

proc call*(call_402657441: Call_GetInventory_402657428; body: JsonNode): Recallable =
  ## getInventory
  ## Query inventory information.
  ##   body: JObject (required)
  var body_402657442 = newJObject()
  if body != nil:
    body_402657442 = body
  result = call_402657441.call(nil, nil, nil, nil, body_402657442)

var getInventory* = Call_GetInventory_402657428(name: "getInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventory",
    validator: validate_GetInventory_402657429, base: "/",
    makeUrl: url_GetInventory_402657430, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetInventorySchema_402657443 = ref object of OpenApiRestCall_402656044
proc url_GetInventorySchema_402657445(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetInventorySchema_402657444(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657446 = header.getOrDefault("X-Amz-Target")
  valid_402657446 = validateParameter(valid_402657446, JString, required = true, default = newJString(
      "AmazonSSM.GetInventorySchema"))
  if valid_402657446 != nil:
    section.add "X-Amz-Target", valid_402657446
  var valid_402657447 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657447 = validateParameter(valid_402657447, JString,
                                      required = false, default = nil)
  if valid_402657447 != nil:
    section.add "X-Amz-Security-Token", valid_402657447
  var valid_402657448 = header.getOrDefault("X-Amz-Signature")
  valid_402657448 = validateParameter(valid_402657448, JString,
                                      required = false, default = nil)
  if valid_402657448 != nil:
    section.add "X-Amz-Signature", valid_402657448
  var valid_402657449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657449 = validateParameter(valid_402657449, JString,
                                      required = false, default = nil)
  if valid_402657449 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657449
  var valid_402657450 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657450 = validateParameter(valid_402657450, JString,
                                      required = false, default = nil)
  if valid_402657450 != nil:
    section.add "X-Amz-Algorithm", valid_402657450
  var valid_402657451 = header.getOrDefault("X-Amz-Date")
  valid_402657451 = validateParameter(valid_402657451, JString,
                                      required = false, default = nil)
  if valid_402657451 != nil:
    section.add "X-Amz-Date", valid_402657451
  var valid_402657452 = header.getOrDefault("X-Amz-Credential")
  valid_402657452 = validateParameter(valid_402657452, JString,
                                      required = false, default = nil)
  if valid_402657452 != nil:
    section.add "X-Amz-Credential", valid_402657452
  var valid_402657453 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657453 = validateParameter(valid_402657453, JString,
                                      required = false, default = nil)
  if valid_402657453 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657453
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657455: Call_GetInventorySchema_402657443;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
                                                                                         ## 
  let valid = call_402657455.validator(path, query, header, formData, body, _)
  let scheme = call_402657455.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657455.makeUrl(scheme.get, call_402657455.host, call_402657455.base,
                                   call_402657455.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657455, uri, valid, _)

proc call*(call_402657456: Call_GetInventorySchema_402657443; body: JsonNode): Recallable =
  ## getInventorySchema
  ## Return a list of inventory type names for the account, or return a list of attribute names for a specific Inventory item type. 
  ##   
                                                                                                                                    ## body: JObject (required)
  var body_402657457 = newJObject()
  if body != nil:
    body_402657457 = body
  result = call_402657456.call(nil, nil, nil, nil, body_402657457)

var getInventorySchema* = Call_GetInventorySchema_402657443(
    name: "getInventorySchema", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetInventorySchema",
    validator: validate_GetInventorySchema_402657444, base: "/",
    makeUrl: url_GetInventorySchema_402657445,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindow_402657458 = ref object of OpenApiRestCall_402656044
proc url_GetMaintenanceWindow_402657460(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMaintenanceWindow_402657459(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a maintenance window.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657461 = header.getOrDefault("X-Amz-Target")
  valid_402657461 = validateParameter(valid_402657461, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindow"))
  if valid_402657461 != nil:
    section.add "X-Amz-Target", valid_402657461
  var valid_402657462 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657462 = validateParameter(valid_402657462, JString,
                                      required = false, default = nil)
  if valid_402657462 != nil:
    section.add "X-Amz-Security-Token", valid_402657462
  var valid_402657463 = header.getOrDefault("X-Amz-Signature")
  valid_402657463 = validateParameter(valid_402657463, JString,
                                      required = false, default = nil)
  if valid_402657463 != nil:
    section.add "X-Amz-Signature", valid_402657463
  var valid_402657464 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657464 = validateParameter(valid_402657464, JString,
                                      required = false, default = nil)
  if valid_402657464 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657464
  var valid_402657465 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657465 = validateParameter(valid_402657465, JString,
                                      required = false, default = nil)
  if valid_402657465 != nil:
    section.add "X-Amz-Algorithm", valid_402657465
  var valid_402657466 = header.getOrDefault("X-Amz-Date")
  valid_402657466 = validateParameter(valid_402657466, JString,
                                      required = false, default = nil)
  if valid_402657466 != nil:
    section.add "X-Amz-Date", valid_402657466
  var valid_402657467 = header.getOrDefault("X-Amz-Credential")
  valid_402657467 = validateParameter(valid_402657467, JString,
                                      required = false, default = nil)
  if valid_402657467 != nil:
    section.add "X-Amz-Credential", valid_402657467
  var valid_402657468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657468 = validateParameter(valid_402657468, JString,
                                      required = false, default = nil)
  if valid_402657468 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657468
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657470: Call_GetMaintenanceWindow_402657458;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a maintenance window.
                                                                                         ## 
  let valid = call_402657470.validator(path, query, header, formData, body, _)
  let scheme = call_402657470.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657470.makeUrl(scheme.get, call_402657470.host, call_402657470.base,
                                   call_402657470.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657470, uri, valid, _)

proc call*(call_402657471: Call_GetMaintenanceWindow_402657458; body: JsonNode): Recallable =
  ## getMaintenanceWindow
  ## Retrieves a maintenance window.
  ##   body: JObject (required)
  var body_402657472 = newJObject()
  if body != nil:
    body_402657472 = body
  result = call_402657471.call(nil, nil, nil, nil, body_402657472)

var getMaintenanceWindow* = Call_GetMaintenanceWindow_402657458(
    name: "getMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindow",
    validator: validate_GetMaintenanceWindow_402657459, base: "/",
    makeUrl: url_GetMaintenanceWindow_402657460,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecution_402657473 = ref object of OpenApiRestCall_402656044
proc url_GetMaintenanceWindowExecution_402657475(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMaintenanceWindowExecution_402657474(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves details about a specific a maintenance window execution.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657476 = header.getOrDefault("X-Amz-Target")
  valid_402657476 = validateParameter(valid_402657476, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecution"))
  if valid_402657476 != nil:
    section.add "X-Amz-Target", valid_402657476
  var valid_402657477 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657477 = validateParameter(valid_402657477, JString,
                                      required = false, default = nil)
  if valid_402657477 != nil:
    section.add "X-Amz-Security-Token", valid_402657477
  var valid_402657478 = header.getOrDefault("X-Amz-Signature")
  valid_402657478 = validateParameter(valid_402657478, JString,
                                      required = false, default = nil)
  if valid_402657478 != nil:
    section.add "X-Amz-Signature", valid_402657478
  var valid_402657479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657479 = validateParameter(valid_402657479, JString,
                                      required = false, default = nil)
  if valid_402657479 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657479
  var valid_402657480 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657480 = validateParameter(valid_402657480, JString,
                                      required = false, default = nil)
  if valid_402657480 != nil:
    section.add "X-Amz-Algorithm", valid_402657480
  var valid_402657481 = header.getOrDefault("X-Amz-Date")
  valid_402657481 = validateParameter(valid_402657481, JString,
                                      required = false, default = nil)
  if valid_402657481 != nil:
    section.add "X-Amz-Date", valid_402657481
  var valid_402657482 = header.getOrDefault("X-Amz-Credential")
  valid_402657482 = validateParameter(valid_402657482, JString,
                                      required = false, default = nil)
  if valid_402657482 != nil:
    section.add "X-Amz-Credential", valid_402657482
  var valid_402657483 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657483 = validateParameter(valid_402657483, JString,
                                      required = false, default = nil)
  if valid_402657483 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657483
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657485: Call_GetMaintenanceWindowExecution_402657473;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves details about a specific a maintenance window execution.
                                                                                         ## 
  let valid = call_402657485.validator(path, query, header, formData, body, _)
  let scheme = call_402657485.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657485.makeUrl(scheme.get, call_402657485.host, call_402657485.base,
                                   call_402657485.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657485, uri, valid, _)

proc call*(call_402657486: Call_GetMaintenanceWindowExecution_402657473;
           body: JsonNode): Recallable =
  ## getMaintenanceWindowExecution
  ## Retrieves details about a specific a maintenance window execution.
  ##   body: JObject 
                                                                       ## (required)
  var body_402657487 = newJObject()
  if body != nil:
    body_402657487 = body
  result = call_402657486.call(nil, nil, nil, nil, body_402657487)

var getMaintenanceWindowExecution* = Call_GetMaintenanceWindowExecution_402657473(
    name: "getMaintenanceWindowExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecution",
    validator: validate_GetMaintenanceWindowExecution_402657474, base: "/",
    makeUrl: url_GetMaintenanceWindowExecution_402657475,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTask_402657488 = ref object of OpenApiRestCall_402656044
proc url_GetMaintenanceWindowExecutionTask_402657490(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMaintenanceWindowExecutionTask_402657489(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657491 = header.getOrDefault("X-Amz-Target")
  valid_402657491 = validateParameter(valid_402657491, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTask"))
  if valid_402657491 != nil:
    section.add "X-Amz-Target", valid_402657491
  var valid_402657492 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657492 = validateParameter(valid_402657492, JString,
                                      required = false, default = nil)
  if valid_402657492 != nil:
    section.add "X-Amz-Security-Token", valid_402657492
  var valid_402657493 = header.getOrDefault("X-Amz-Signature")
  valid_402657493 = validateParameter(valid_402657493, JString,
                                      required = false, default = nil)
  if valid_402657493 != nil:
    section.add "X-Amz-Signature", valid_402657493
  var valid_402657494 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657494 = validateParameter(valid_402657494, JString,
                                      required = false, default = nil)
  if valid_402657494 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657494
  var valid_402657495 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657495 = validateParameter(valid_402657495, JString,
                                      required = false, default = nil)
  if valid_402657495 != nil:
    section.add "X-Amz-Algorithm", valid_402657495
  var valid_402657496 = header.getOrDefault("X-Amz-Date")
  valid_402657496 = validateParameter(valid_402657496, JString,
                                      required = false, default = nil)
  if valid_402657496 != nil:
    section.add "X-Amz-Date", valid_402657496
  var valid_402657497 = header.getOrDefault("X-Amz-Credential")
  valid_402657497 = validateParameter(valid_402657497, JString,
                                      required = false, default = nil)
  if valid_402657497 != nil:
    section.add "X-Amz-Credential", valid_402657497
  var valid_402657498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657498 = validateParameter(valid_402657498, JString,
                                      required = false, default = nil)
  if valid_402657498 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657498
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657500: Call_GetMaintenanceWindowExecutionTask_402657488;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
                                                                                         ## 
  let valid = call_402657500.validator(path, query, header, formData, body, _)
  let scheme = call_402657500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657500.makeUrl(scheme.get, call_402657500.host, call_402657500.base,
                                   call_402657500.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657500, uri, valid, _)

proc call*(call_402657501: Call_GetMaintenanceWindowExecutionTask_402657488;
           body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTask
  ## Retrieves the details about a specific task run as part of a maintenance window execution.
  ##   
                                                                                               ## body: JObject (required)
  var body_402657502 = newJObject()
  if body != nil:
    body_402657502 = body
  result = call_402657501.call(nil, nil, nil, nil, body_402657502)

var getMaintenanceWindowExecutionTask* = Call_GetMaintenanceWindowExecutionTask_402657488(
    name: "getMaintenanceWindowExecutionTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTask",
    validator: validate_GetMaintenanceWindowExecutionTask_402657489, base: "/",
    makeUrl: url_GetMaintenanceWindowExecutionTask_402657490,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowExecutionTaskInvocation_402657503 = ref object of OpenApiRestCall_402656044
proc url_GetMaintenanceWindowExecutionTaskInvocation_402657505(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMaintenanceWindowExecutionTaskInvocation_402657504(
    path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about a specific task running on a specific target.
                                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657506 = header.getOrDefault("X-Amz-Target")
  valid_402657506 = validateParameter(valid_402657506, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation"))
  if valid_402657506 != nil:
    section.add "X-Amz-Target", valid_402657506
  var valid_402657507 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657507 = validateParameter(valid_402657507, JString,
                                      required = false, default = nil)
  if valid_402657507 != nil:
    section.add "X-Amz-Security-Token", valid_402657507
  var valid_402657508 = header.getOrDefault("X-Amz-Signature")
  valid_402657508 = validateParameter(valid_402657508, JString,
                                      required = false, default = nil)
  if valid_402657508 != nil:
    section.add "X-Amz-Signature", valid_402657508
  var valid_402657509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657509 = validateParameter(valid_402657509, JString,
                                      required = false, default = nil)
  if valid_402657509 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657509
  var valid_402657510 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657510 = validateParameter(valid_402657510, JString,
                                      required = false, default = nil)
  if valid_402657510 != nil:
    section.add "X-Amz-Algorithm", valid_402657510
  var valid_402657511 = header.getOrDefault("X-Amz-Date")
  valid_402657511 = validateParameter(valid_402657511, JString,
                                      required = false, default = nil)
  if valid_402657511 != nil:
    section.add "X-Amz-Date", valid_402657511
  var valid_402657512 = header.getOrDefault("X-Amz-Credential")
  valid_402657512 = validateParameter(valid_402657512, JString,
                                      required = false, default = nil)
  if valid_402657512 != nil:
    section.add "X-Amz-Credential", valid_402657512
  var valid_402657513 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657513 = validateParameter(valid_402657513, JString,
                                      required = false, default = nil)
  if valid_402657513 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657515: Call_GetMaintenanceWindowExecutionTaskInvocation_402657503;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a specific task running on a specific target.
                                                                                         ## 
  let valid = call_402657515.validator(path, query, header, formData, body, _)
  let scheme = call_402657515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657515.makeUrl(scheme.get, call_402657515.host, call_402657515.base,
                                   call_402657515.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657515, uri, valid, _)

proc call*(call_402657516: Call_GetMaintenanceWindowExecutionTaskInvocation_402657503;
           body: JsonNode): Recallable =
  ## getMaintenanceWindowExecutionTaskInvocation
  ## Retrieves information about a specific task running on a specific target.
  ##   
                                                                              ## body: JObject (required)
  var body_402657517 = newJObject()
  if body != nil:
    body_402657517 = body
  result = call_402657516.call(nil, nil, nil, nil, body_402657517)

var getMaintenanceWindowExecutionTaskInvocation* = Call_GetMaintenanceWindowExecutionTaskInvocation_402657503(
    name: "getMaintenanceWindowExecutionTaskInvocation",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com", route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowExecutionTaskInvocation",
    validator: validate_GetMaintenanceWindowExecutionTaskInvocation_402657504,
    base: "/", makeUrl: url_GetMaintenanceWindowExecutionTaskInvocation_402657505,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetMaintenanceWindowTask_402657518 = ref object of OpenApiRestCall_402656044
proc url_GetMaintenanceWindowTask_402657520(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetMaintenanceWindowTask_402657519(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Lists the tasks in a maintenance window.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657521 = header.getOrDefault("X-Amz-Target")
  valid_402657521 = validateParameter(valid_402657521, JString, required = true, default = newJString(
      "AmazonSSM.GetMaintenanceWindowTask"))
  if valid_402657521 != nil:
    section.add "X-Amz-Target", valid_402657521
  var valid_402657522 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657522 = validateParameter(valid_402657522, JString,
                                      required = false, default = nil)
  if valid_402657522 != nil:
    section.add "X-Amz-Security-Token", valid_402657522
  var valid_402657523 = header.getOrDefault("X-Amz-Signature")
  valid_402657523 = validateParameter(valid_402657523, JString,
                                      required = false, default = nil)
  if valid_402657523 != nil:
    section.add "X-Amz-Signature", valid_402657523
  var valid_402657524 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657524 = validateParameter(valid_402657524, JString,
                                      required = false, default = nil)
  if valid_402657524 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657524
  var valid_402657525 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657525 = validateParameter(valid_402657525, JString,
                                      required = false, default = nil)
  if valid_402657525 != nil:
    section.add "X-Amz-Algorithm", valid_402657525
  var valid_402657526 = header.getOrDefault("X-Amz-Date")
  valid_402657526 = validateParameter(valid_402657526, JString,
                                      required = false, default = nil)
  if valid_402657526 != nil:
    section.add "X-Amz-Date", valid_402657526
  var valid_402657527 = header.getOrDefault("X-Amz-Credential")
  valid_402657527 = validateParameter(valid_402657527, JString,
                                      required = false, default = nil)
  if valid_402657527 != nil:
    section.add "X-Amz-Credential", valid_402657527
  var valid_402657528 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657528 = validateParameter(valid_402657528, JString,
                                      required = false, default = nil)
  if valid_402657528 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657528
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657530: Call_GetMaintenanceWindowTask_402657518;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the tasks in a maintenance window.
                                                                                         ## 
  let valid = call_402657530.validator(path, query, header, formData, body, _)
  let scheme = call_402657530.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657530.makeUrl(scheme.get, call_402657530.host, call_402657530.base,
                                   call_402657530.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657530, uri, valid, _)

proc call*(call_402657531: Call_GetMaintenanceWindowTask_402657518;
           body: JsonNode): Recallable =
  ## getMaintenanceWindowTask
  ## Lists the tasks in a maintenance window.
  ##   body: JObject (required)
  var body_402657532 = newJObject()
  if body != nil:
    body_402657532 = body
  result = call_402657531.call(nil, nil, nil, nil, body_402657532)

var getMaintenanceWindowTask* = Call_GetMaintenanceWindowTask_402657518(
    name: "getMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetMaintenanceWindowTask",
    validator: validate_GetMaintenanceWindowTask_402657519, base: "/",
    makeUrl: url_GetMaintenanceWindowTask_402657520,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsItem_402657533 = ref object of OpenApiRestCall_402656044
proc url_GetOpsItem_402657535(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOpsItem_402657534(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657536 = header.getOrDefault("X-Amz-Target")
  valid_402657536 = validateParameter(valid_402657536, JString, required = true, default = newJString(
      "AmazonSSM.GetOpsItem"))
  if valid_402657536 != nil:
    section.add "X-Amz-Target", valid_402657536
  var valid_402657537 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657537 = validateParameter(valid_402657537, JString,
                                      required = false, default = nil)
  if valid_402657537 != nil:
    section.add "X-Amz-Security-Token", valid_402657537
  var valid_402657538 = header.getOrDefault("X-Amz-Signature")
  valid_402657538 = validateParameter(valid_402657538, JString,
                                      required = false, default = nil)
  if valid_402657538 != nil:
    section.add "X-Amz-Signature", valid_402657538
  var valid_402657539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657539 = validateParameter(valid_402657539, JString,
                                      required = false, default = nil)
  if valid_402657539 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657539
  var valid_402657540 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657540 = validateParameter(valid_402657540, JString,
                                      required = false, default = nil)
  if valid_402657540 != nil:
    section.add "X-Amz-Algorithm", valid_402657540
  var valid_402657541 = header.getOrDefault("X-Amz-Date")
  valid_402657541 = validateParameter(valid_402657541, JString,
                                      required = false, default = nil)
  if valid_402657541 != nil:
    section.add "X-Amz-Date", valid_402657541
  var valid_402657542 = header.getOrDefault("X-Amz-Credential")
  valid_402657542 = validateParameter(valid_402657542, JString,
                                      required = false, default = nil)
  if valid_402657542 != nil:
    section.add "X-Amz-Credential", valid_402657542
  var valid_402657543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657543 = validateParameter(valid_402657543, JString,
                                      required = false, default = nil)
  if valid_402657543 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657545: Call_GetOpsItem_402657533; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
                                                                                         ## 
  let valid = call_402657545.validator(path, query, header, formData, body, _)
  let scheme = call_402657545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657545.makeUrl(scheme.get, call_402657545.host, call_402657545.base,
                                   call_402657545.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657545, uri, valid, _)

proc call*(call_402657546: Call_GetOpsItem_402657533; body: JsonNode): Recallable =
  ## getOpsItem
  ## <p>Get information about an OpsItem by using the ID. You must have permission in AWS Identity and Access Management (IAM) to view information about an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402657547 = newJObject()
  if body != nil:
    body_402657547 = body
  result = call_402657546.call(nil, nil, nil, nil, body_402657547)

var getOpsItem* = Call_GetOpsItem_402657533(name: "getOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetOpsItem",
    validator: validate_GetOpsItem_402657534, base: "/",
    makeUrl: url_GetOpsItem_402657535, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOpsSummary_402657548 = ref object of OpenApiRestCall_402656044
proc url_GetOpsSummary_402657550(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetOpsSummary_402657549(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## View a summary of OpsItems based on specified filters and aggregators.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657551 = header.getOrDefault("X-Amz-Target")
  valid_402657551 = validateParameter(valid_402657551, JString, required = true, default = newJString(
      "AmazonSSM.GetOpsSummary"))
  if valid_402657551 != nil:
    section.add "X-Amz-Target", valid_402657551
  var valid_402657552 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657552 = validateParameter(valid_402657552, JString,
                                      required = false, default = nil)
  if valid_402657552 != nil:
    section.add "X-Amz-Security-Token", valid_402657552
  var valid_402657553 = header.getOrDefault("X-Amz-Signature")
  valid_402657553 = validateParameter(valid_402657553, JString,
                                      required = false, default = nil)
  if valid_402657553 != nil:
    section.add "X-Amz-Signature", valid_402657553
  var valid_402657554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657554 = validateParameter(valid_402657554, JString,
                                      required = false, default = nil)
  if valid_402657554 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657554
  var valid_402657555 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657555 = validateParameter(valid_402657555, JString,
                                      required = false, default = nil)
  if valid_402657555 != nil:
    section.add "X-Amz-Algorithm", valid_402657555
  var valid_402657556 = header.getOrDefault("X-Amz-Date")
  valid_402657556 = validateParameter(valid_402657556, JString,
                                      required = false, default = nil)
  if valid_402657556 != nil:
    section.add "X-Amz-Date", valid_402657556
  var valid_402657557 = header.getOrDefault("X-Amz-Credential")
  valid_402657557 = validateParameter(valid_402657557, JString,
                                      required = false, default = nil)
  if valid_402657557 != nil:
    section.add "X-Amz-Credential", valid_402657557
  var valid_402657558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657558 = validateParameter(valid_402657558, JString,
                                      required = false, default = nil)
  if valid_402657558 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657560: Call_GetOpsSummary_402657548; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## View a summary of OpsItems based on specified filters and aggregators.
                                                                                         ## 
  let valid = call_402657560.validator(path, query, header, formData, body, _)
  let scheme = call_402657560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657560.makeUrl(scheme.get, call_402657560.host, call_402657560.base,
                                   call_402657560.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657560, uri, valid, _)

proc call*(call_402657561: Call_GetOpsSummary_402657548; body: JsonNode): Recallable =
  ## getOpsSummary
  ## View a summary of OpsItems based on specified filters and aggregators.
  ##   body: 
                                                                           ## JObject (required)
  var body_402657562 = newJObject()
  if body != nil:
    body_402657562 = body
  result = call_402657561.call(nil, nil, nil, nil, body_402657562)

var getOpsSummary* = Call_GetOpsSummary_402657548(name: "getOpsSummary",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetOpsSummary",
    validator: validate_GetOpsSummary_402657549, base: "/",
    makeUrl: url_GetOpsSummary_402657550, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameter_402657563 = ref object of OpenApiRestCall_402656044
proc url_GetParameter_402657565(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetParameter_402657564(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657566 = header.getOrDefault("X-Amz-Target")
  valid_402657566 = validateParameter(valid_402657566, JString, required = true, default = newJString(
      "AmazonSSM.GetParameter"))
  if valid_402657566 != nil:
    section.add "X-Amz-Target", valid_402657566
  var valid_402657567 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657567 = validateParameter(valid_402657567, JString,
                                      required = false, default = nil)
  if valid_402657567 != nil:
    section.add "X-Amz-Security-Token", valid_402657567
  var valid_402657568 = header.getOrDefault("X-Amz-Signature")
  valid_402657568 = validateParameter(valid_402657568, JString,
                                      required = false, default = nil)
  if valid_402657568 != nil:
    section.add "X-Amz-Signature", valid_402657568
  var valid_402657569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657569 = validateParameter(valid_402657569, JString,
                                      required = false, default = nil)
  if valid_402657569 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657569
  var valid_402657570 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657570 = validateParameter(valid_402657570, JString,
                                      required = false, default = nil)
  if valid_402657570 != nil:
    section.add "X-Amz-Algorithm", valid_402657570
  var valid_402657571 = header.getOrDefault("X-Amz-Date")
  valid_402657571 = validateParameter(valid_402657571, JString,
                                      required = false, default = nil)
  if valid_402657571 != nil:
    section.add "X-Amz-Date", valid_402657571
  var valid_402657572 = header.getOrDefault("X-Amz-Credential")
  valid_402657572 = validateParameter(valid_402657572, JString,
                                      required = false, default = nil)
  if valid_402657572 != nil:
    section.add "X-Amz-Credential", valid_402657572
  var valid_402657573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657573 = validateParameter(valid_402657573, JString,
                                      required = false, default = nil)
  if valid_402657573 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657573
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657575: Call_GetParameter_402657563; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
                                                                                         ## 
  let valid = call_402657575.validator(path, query, header, formData, body, _)
  let scheme = call_402657575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657575.makeUrl(scheme.get, call_402657575.host, call_402657575.base,
                                   call_402657575.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657575, uri, valid, _)

proc call*(call_402657576: Call_GetParameter_402657563; body: JsonNode): Recallable =
  ## getParameter
  ## Get information about a parameter by using the parameter name. Don't confuse this API action with the <a>GetParameters</a> API action.
  ##   
                                                                                                                                           ## body: JObject (required)
  var body_402657577 = newJObject()
  if body != nil:
    body_402657577 = body
  result = call_402657576.call(nil, nil, nil, nil, body_402657577)

var getParameter* = Call_GetParameter_402657563(name: "getParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameter",
    validator: validate_GetParameter_402657564, base: "/",
    makeUrl: url_GetParameter_402657565, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameterHistory_402657578 = ref object of OpenApiRestCall_402656044
proc url_GetParameterHistory_402657580(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetParameterHistory_402657579(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Query a list of all parameters used by the AWS account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657581 = query.getOrDefault("MaxResults")
  valid_402657581 = validateParameter(valid_402657581, JString,
                                      required = false, default = nil)
  if valid_402657581 != nil:
    section.add "MaxResults", valid_402657581
  var valid_402657582 = query.getOrDefault("NextToken")
  valid_402657582 = validateParameter(valid_402657582, JString,
                                      required = false, default = nil)
  if valid_402657582 != nil:
    section.add "NextToken", valid_402657582
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657583 = header.getOrDefault("X-Amz-Target")
  valid_402657583 = validateParameter(valid_402657583, JString, required = true, default = newJString(
      "AmazonSSM.GetParameterHistory"))
  if valid_402657583 != nil:
    section.add "X-Amz-Target", valid_402657583
  var valid_402657584 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657584 = validateParameter(valid_402657584, JString,
                                      required = false, default = nil)
  if valid_402657584 != nil:
    section.add "X-Amz-Security-Token", valid_402657584
  var valid_402657585 = header.getOrDefault("X-Amz-Signature")
  valid_402657585 = validateParameter(valid_402657585, JString,
                                      required = false, default = nil)
  if valid_402657585 != nil:
    section.add "X-Amz-Signature", valid_402657585
  var valid_402657586 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657586 = validateParameter(valid_402657586, JString,
                                      required = false, default = nil)
  if valid_402657586 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657586
  var valid_402657587 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657587 = validateParameter(valid_402657587, JString,
                                      required = false, default = nil)
  if valid_402657587 != nil:
    section.add "X-Amz-Algorithm", valid_402657587
  var valid_402657588 = header.getOrDefault("X-Amz-Date")
  valid_402657588 = validateParameter(valid_402657588, JString,
                                      required = false, default = nil)
  if valid_402657588 != nil:
    section.add "X-Amz-Date", valid_402657588
  var valid_402657589 = header.getOrDefault("X-Amz-Credential")
  valid_402657589 = validateParameter(valid_402657589, JString,
                                      required = false, default = nil)
  if valid_402657589 != nil:
    section.add "X-Amz-Credential", valid_402657589
  var valid_402657590 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657590 = validateParameter(valid_402657590, JString,
                                      required = false, default = nil)
  if valid_402657590 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657590
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657592: Call_GetParameterHistory_402657578;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Query a list of all parameters used by the AWS account.
                                                                                         ## 
  let valid = call_402657592.validator(path, query, header, formData, body, _)
  let scheme = call_402657592.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657592.makeUrl(scheme.get, call_402657592.host, call_402657592.base,
                                   call_402657592.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657592, uri, valid, _)

proc call*(call_402657593: Call_GetParameterHistory_402657578; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getParameterHistory
  ## Query a list of all parameters used by the AWS account.
  ##   MaxResults: string
                                                            ##             : Pagination limit
  ##   
                                                                                             ## body: JObject (required)
  ##   
                                                                                                                        ## NextToken: string
                                                                                                                        ##            
                                                                                                                        ## : 
                                                                                                                        ## Pagination 
                                                                                                                        ## token
  var query_402657594 = newJObject()
  var body_402657595 = newJObject()
  add(query_402657594, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657595 = body
  add(query_402657594, "NextToken", newJString(NextToken))
  result = call_402657593.call(nil, query_402657594, nil, nil, body_402657595)

var getParameterHistory* = Call_GetParameterHistory_402657578(
    name: "getParameterHistory", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameterHistory",
    validator: validate_GetParameterHistory_402657579, base: "/",
    makeUrl: url_GetParameterHistory_402657580,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParameters_402657596 = ref object of OpenApiRestCall_402656044
proc url_GetParameters_402657598(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetParameters_402657597(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657599 = header.getOrDefault("X-Amz-Target")
  valid_402657599 = validateParameter(valid_402657599, JString, required = true, default = newJString(
      "AmazonSSM.GetParameters"))
  if valid_402657599 != nil:
    section.add "X-Amz-Target", valid_402657599
  var valid_402657600 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657600 = validateParameter(valid_402657600, JString,
                                      required = false, default = nil)
  if valid_402657600 != nil:
    section.add "X-Amz-Security-Token", valid_402657600
  var valid_402657601 = header.getOrDefault("X-Amz-Signature")
  valid_402657601 = validateParameter(valid_402657601, JString,
                                      required = false, default = nil)
  if valid_402657601 != nil:
    section.add "X-Amz-Signature", valid_402657601
  var valid_402657602 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657602 = validateParameter(valid_402657602, JString,
                                      required = false, default = nil)
  if valid_402657602 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657602
  var valid_402657603 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657603 = validateParameter(valid_402657603, JString,
                                      required = false, default = nil)
  if valid_402657603 != nil:
    section.add "X-Amz-Algorithm", valid_402657603
  var valid_402657604 = header.getOrDefault("X-Amz-Date")
  valid_402657604 = validateParameter(valid_402657604, JString,
                                      required = false, default = nil)
  if valid_402657604 != nil:
    section.add "X-Amz-Date", valid_402657604
  var valid_402657605 = header.getOrDefault("X-Amz-Credential")
  valid_402657605 = validateParameter(valid_402657605, JString,
                                      required = false, default = nil)
  if valid_402657605 != nil:
    section.add "X-Amz-Credential", valid_402657605
  var valid_402657606 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657606 = validateParameter(valid_402657606, JString,
                                      required = false, default = nil)
  if valid_402657606 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657606
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657608: Call_GetParameters_402657596; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
                                                                                         ## 
  let valid = call_402657608.validator(path, query, header, formData, body, _)
  let scheme = call_402657608.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657608.makeUrl(scheme.get, call_402657608.host, call_402657608.base,
                                   call_402657608.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657608, uri, valid, _)

proc call*(call_402657609: Call_GetParameters_402657596; body: JsonNode): Recallable =
  ## getParameters
  ## Get details of a parameter. Don't confuse this API action with the <a>GetParameter</a> API action.
  ##   
                                                                                                       ## body: JObject (required)
  var body_402657610 = newJObject()
  if body != nil:
    body_402657610 = body
  result = call_402657609.call(nil, nil, nil, nil, body_402657610)

var getParameters* = Call_GetParameters_402657596(name: "getParameters",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParameters",
    validator: validate_GetParameters_402657597, base: "/",
    makeUrl: url_GetParameters_402657598, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetParametersByPath_402657611 = ref object of OpenApiRestCall_402656044
proc url_GetParametersByPath_402657613(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetParametersByPath_402657612(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieve information about one or more parameters in a specific hierarchy. </p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657614 = query.getOrDefault("MaxResults")
  valid_402657614 = validateParameter(valid_402657614, JString,
                                      required = false, default = nil)
  if valid_402657614 != nil:
    section.add "MaxResults", valid_402657614
  var valid_402657615 = query.getOrDefault("NextToken")
  valid_402657615 = validateParameter(valid_402657615, JString,
                                      required = false, default = nil)
  if valid_402657615 != nil:
    section.add "NextToken", valid_402657615
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657616 = header.getOrDefault("X-Amz-Target")
  valid_402657616 = validateParameter(valid_402657616, JString, required = true, default = newJString(
      "AmazonSSM.GetParametersByPath"))
  if valid_402657616 != nil:
    section.add "X-Amz-Target", valid_402657616
  var valid_402657617 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657617 = validateParameter(valid_402657617, JString,
                                      required = false, default = nil)
  if valid_402657617 != nil:
    section.add "X-Amz-Security-Token", valid_402657617
  var valid_402657618 = header.getOrDefault("X-Amz-Signature")
  valid_402657618 = validateParameter(valid_402657618, JString,
                                      required = false, default = nil)
  if valid_402657618 != nil:
    section.add "X-Amz-Signature", valid_402657618
  var valid_402657619 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657619 = validateParameter(valid_402657619, JString,
                                      required = false, default = nil)
  if valid_402657619 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657619
  var valid_402657620 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657620 = validateParameter(valid_402657620, JString,
                                      required = false, default = nil)
  if valid_402657620 != nil:
    section.add "X-Amz-Algorithm", valid_402657620
  var valid_402657621 = header.getOrDefault("X-Amz-Date")
  valid_402657621 = validateParameter(valid_402657621, JString,
                                      required = false, default = nil)
  if valid_402657621 != nil:
    section.add "X-Amz-Date", valid_402657621
  var valid_402657622 = header.getOrDefault("X-Amz-Credential")
  valid_402657622 = validateParameter(valid_402657622, JString,
                                      required = false, default = nil)
  if valid_402657622 != nil:
    section.add "X-Amz-Credential", valid_402657622
  var valid_402657623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657623 = validateParameter(valid_402657623, JString,
                                      required = false, default = nil)
  if valid_402657623 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657625: Call_GetParametersByPath_402657611;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieve information about one or more parameters in a specific hierarchy. </p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
                                                                                         ## 
  let valid = call_402657625.validator(path, query, header, formData, body, _)
  let scheme = call_402657625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657625.makeUrl(scheme.get, call_402657625.host, call_402657625.base,
                                   call_402657625.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657625, uri, valid, _)

proc call*(call_402657626: Call_GetParametersByPath_402657611; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## getParametersByPath
  ## <p>Retrieve information about one or more parameters in a specific hierarchy. </p> <note> <p>Request results are returned on a best-effort basis. If you specify <code>MaxResults</code> in the request, the response includes information up to the limit specified. The number of items returned, however, can be between zero and the value of <code>MaxResults</code>. If the service reaches an internal limit while processing the results, it stops the operation and returns the matching values up to that point and a <code>NextToken</code>. You can specify the <code>NextToken</code> in a subsequent call to get the next set of results.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## token
  var query_402657627 = newJObject()
  var body_402657628 = newJObject()
  add(query_402657627, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657628 = body
  add(query_402657627, "NextToken", newJString(NextToken))
  result = call_402657626.call(nil, query_402657627, nil, nil, body_402657628)

var getParametersByPath* = Call_GetParametersByPath_402657611(
    name: "getParametersByPath", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetParametersByPath",
    validator: validate_GetParametersByPath_402657612, base: "/",
    makeUrl: url_GetParametersByPath_402657613,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaseline_402657629 = ref object of OpenApiRestCall_402656044
proc url_GetPatchBaseline_402657631(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPatchBaseline_402657630(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves information about a patch baseline.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657632 = header.getOrDefault("X-Amz-Target")
  valid_402657632 = validateParameter(valid_402657632, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaseline"))
  if valid_402657632 != nil:
    section.add "X-Amz-Target", valid_402657632
  var valid_402657633 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657633 = validateParameter(valid_402657633, JString,
                                      required = false, default = nil)
  if valid_402657633 != nil:
    section.add "X-Amz-Security-Token", valid_402657633
  var valid_402657634 = header.getOrDefault("X-Amz-Signature")
  valid_402657634 = validateParameter(valid_402657634, JString,
                                      required = false, default = nil)
  if valid_402657634 != nil:
    section.add "X-Amz-Signature", valid_402657634
  var valid_402657635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657635 = validateParameter(valid_402657635, JString,
                                      required = false, default = nil)
  if valid_402657635 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657635
  var valid_402657636 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657636 = validateParameter(valid_402657636, JString,
                                      required = false, default = nil)
  if valid_402657636 != nil:
    section.add "X-Amz-Algorithm", valid_402657636
  var valid_402657637 = header.getOrDefault("X-Amz-Date")
  valid_402657637 = validateParameter(valid_402657637, JString,
                                      required = false, default = nil)
  if valid_402657637 != nil:
    section.add "X-Amz-Date", valid_402657637
  var valid_402657638 = header.getOrDefault("X-Amz-Credential")
  valid_402657638 = validateParameter(valid_402657638, JString,
                                      required = false, default = nil)
  if valid_402657638 != nil:
    section.add "X-Amz-Credential", valid_402657638
  var valid_402657639 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657639 = validateParameter(valid_402657639, JString,
                                      required = false, default = nil)
  if valid_402657639 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657639
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657641: Call_GetPatchBaseline_402657629;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about a patch baseline.
                                                                                         ## 
  let valid = call_402657641.validator(path, query, header, formData, body, _)
  let scheme = call_402657641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657641.makeUrl(scheme.get, call_402657641.host, call_402657641.base,
                                   call_402657641.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657641, uri, valid, _)

proc call*(call_402657642: Call_GetPatchBaseline_402657629; body: JsonNode): Recallable =
  ## getPatchBaseline
  ## Retrieves information about a patch baseline.
  ##   body: JObject (required)
  var body_402657643 = newJObject()
  if body != nil:
    body_402657643 = body
  result = call_402657642.call(nil, nil, nil, nil, body_402657643)

var getPatchBaseline* = Call_GetPatchBaseline_402657629(
    name: "getPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaseline",
    validator: validate_GetPatchBaseline_402657630, base: "/",
    makeUrl: url_GetPatchBaseline_402657631,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetPatchBaselineForPatchGroup_402657644 = ref object of OpenApiRestCall_402656044
proc url_GetPatchBaselineForPatchGroup_402657646(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetPatchBaselineForPatchGroup_402657645(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves the patch baseline that should be used for the specified patch group.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657647 = header.getOrDefault("X-Amz-Target")
  valid_402657647 = validateParameter(valid_402657647, JString, required = true, default = newJString(
      "AmazonSSM.GetPatchBaselineForPatchGroup"))
  if valid_402657647 != nil:
    section.add "X-Amz-Target", valid_402657647
  var valid_402657648 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657648 = validateParameter(valid_402657648, JString,
                                      required = false, default = nil)
  if valid_402657648 != nil:
    section.add "X-Amz-Security-Token", valid_402657648
  var valid_402657649 = header.getOrDefault("X-Amz-Signature")
  valid_402657649 = validateParameter(valid_402657649, JString,
                                      required = false, default = nil)
  if valid_402657649 != nil:
    section.add "X-Amz-Signature", valid_402657649
  var valid_402657650 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657650 = validateParameter(valid_402657650, JString,
                                      required = false, default = nil)
  if valid_402657650 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657650
  var valid_402657651 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657651 = validateParameter(valid_402657651, JString,
                                      required = false, default = nil)
  if valid_402657651 != nil:
    section.add "X-Amz-Algorithm", valid_402657651
  var valid_402657652 = header.getOrDefault("X-Amz-Date")
  valid_402657652 = validateParameter(valid_402657652, JString,
                                      required = false, default = nil)
  if valid_402657652 != nil:
    section.add "X-Amz-Date", valid_402657652
  var valid_402657653 = header.getOrDefault("X-Amz-Credential")
  valid_402657653 = validateParameter(valid_402657653, JString,
                                      required = false, default = nil)
  if valid_402657653 != nil:
    section.add "X-Amz-Credential", valid_402657653
  var valid_402657654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657654 = validateParameter(valid_402657654, JString,
                                      required = false, default = nil)
  if valid_402657654 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657656: Call_GetPatchBaselineForPatchGroup_402657644;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the patch baseline that should be used for the specified patch group.
                                                                                         ## 
  let valid = call_402657656.validator(path, query, header, formData, body, _)
  let scheme = call_402657656.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657656.makeUrl(scheme.get, call_402657656.host, call_402657656.base,
                                   call_402657656.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657656, uri, valid, _)

proc call*(call_402657657: Call_GetPatchBaselineForPatchGroup_402657644;
           body: JsonNode): Recallable =
  ## getPatchBaselineForPatchGroup
  ## Retrieves the patch baseline that should be used for the specified patch group.
  ##   
                                                                                    ## body: JObject (required)
  var body_402657658 = newJObject()
  if body != nil:
    body_402657658 = body
  result = call_402657657.call(nil, nil, nil, nil, body_402657658)

var getPatchBaselineForPatchGroup* = Call_GetPatchBaselineForPatchGroup_402657644(
    name: "getPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetPatchBaselineForPatchGroup",
    validator: validate_GetPatchBaselineForPatchGroup_402657645, base: "/",
    makeUrl: url_GetPatchBaselineForPatchGroup_402657646,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceSetting_402657659 = ref object of OpenApiRestCall_402656044
proc url_GetServiceSetting_402657661(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetServiceSetting_402657660(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657662 = header.getOrDefault("X-Amz-Target")
  valid_402657662 = validateParameter(valid_402657662, JString, required = true, default = newJString(
      "AmazonSSM.GetServiceSetting"))
  if valid_402657662 != nil:
    section.add "X-Amz-Target", valid_402657662
  var valid_402657663 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657663 = validateParameter(valid_402657663, JString,
                                      required = false, default = nil)
  if valid_402657663 != nil:
    section.add "X-Amz-Security-Token", valid_402657663
  var valid_402657664 = header.getOrDefault("X-Amz-Signature")
  valid_402657664 = validateParameter(valid_402657664, JString,
                                      required = false, default = nil)
  if valid_402657664 != nil:
    section.add "X-Amz-Signature", valid_402657664
  var valid_402657665 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657665 = validateParameter(valid_402657665, JString,
                                      required = false, default = nil)
  if valid_402657665 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657665
  var valid_402657666 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657666 = validateParameter(valid_402657666, JString,
                                      required = false, default = nil)
  if valid_402657666 != nil:
    section.add "X-Amz-Algorithm", valid_402657666
  var valid_402657667 = header.getOrDefault("X-Amz-Date")
  valid_402657667 = validateParameter(valid_402657667, JString,
                                      required = false, default = nil)
  if valid_402657667 != nil:
    section.add "X-Amz-Date", valid_402657667
  var valid_402657668 = header.getOrDefault("X-Amz-Credential")
  valid_402657668 = validateParameter(valid_402657668, JString,
                                      required = false, default = nil)
  if valid_402657668 != nil:
    section.add "X-Amz-Credential", valid_402657668
  var valid_402657669 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657669 = validateParameter(valid_402657669, JString,
                                      required = false, default = nil)
  if valid_402657669 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657669
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657671: Call_GetServiceSetting_402657659;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
                                                                                         ## 
  let valid = call_402657671.validator(path, query, header, formData, body, _)
  let scheme = call_402657671.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657671.makeUrl(scheme.get, call_402657671.host, call_402657671.base,
                                   call_402657671.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657671, uri, valid, _)

proc call*(call_402657672: Call_GetServiceSetting_402657659; body: JsonNode): Recallable =
  ## getServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>UpdateServiceSetting</a> API action to change the default setting. Or use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Query the current service setting for the account. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402657673 = newJObject()
  if body != nil:
    body_402657673 = body
  result = call_402657672.call(nil, nil, nil, nil, body_402657673)

var getServiceSetting* = Call_GetServiceSetting_402657659(
    name: "getServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.GetServiceSetting",
    validator: validate_GetServiceSetting_402657660, base: "/",
    makeUrl: url_GetServiceSetting_402657661,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_LabelParameterVersion_402657674 = ref object of OpenApiRestCall_402656044
proc url_LabelParameterVersion_402657676(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_LabelParameterVersion_402657675(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657677 = header.getOrDefault("X-Amz-Target")
  valid_402657677 = validateParameter(valid_402657677, JString, required = true, default = newJString(
      "AmazonSSM.LabelParameterVersion"))
  if valid_402657677 != nil:
    section.add "X-Amz-Target", valid_402657677
  var valid_402657678 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657678 = validateParameter(valid_402657678, JString,
                                      required = false, default = nil)
  if valid_402657678 != nil:
    section.add "X-Amz-Security-Token", valid_402657678
  var valid_402657679 = header.getOrDefault("X-Amz-Signature")
  valid_402657679 = validateParameter(valid_402657679, JString,
                                      required = false, default = nil)
  if valid_402657679 != nil:
    section.add "X-Amz-Signature", valid_402657679
  var valid_402657680 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657680 = validateParameter(valid_402657680, JString,
                                      required = false, default = nil)
  if valid_402657680 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657680
  var valid_402657681 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657681 = validateParameter(valid_402657681, JString,
                                      required = false, default = nil)
  if valid_402657681 != nil:
    section.add "X-Amz-Algorithm", valid_402657681
  var valid_402657682 = header.getOrDefault("X-Amz-Date")
  valid_402657682 = validateParameter(valid_402657682, JString,
                                      required = false, default = nil)
  if valid_402657682 != nil:
    section.add "X-Amz-Date", valid_402657682
  var valid_402657683 = header.getOrDefault("X-Amz-Credential")
  valid_402657683 = validateParameter(valid_402657683, JString,
                                      required = false, default = nil)
  if valid_402657683 != nil:
    section.add "X-Amz-Credential", valid_402657683
  var valid_402657684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657684 = validateParameter(valid_402657684, JString,
                                      required = false, default = nil)
  if valid_402657684 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657686: Call_LabelParameterVersion_402657674;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402657686.validator(path, query, header, formData, body, _)
  let scheme = call_402657686.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657686.makeUrl(scheme.get, call_402657686.host, call_402657686.base,
                                   call_402657686.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657686, uri, valid, _)

proc call*(call_402657687: Call_LabelParameterVersion_402657674; body: JsonNode): Recallable =
  ## labelParameterVersion
  ## <p>A parameter label is a user-defined alias to help you manage different versions of a parameter. When you modify a parameter, Systems Manager automatically saves a new version and increments the version number by one. A label can help you remember the purpose of a parameter when there are multiple versions. </p> <p>Parameter labels have the following requirements and restrictions.</p> <ul> <li> <p>A version of a parameter can have a maximum of 10 labels.</p> </li> <li> <p>You can't attach the same label to different versions of the same parameter. For example, if version 1 has the label Production, then you can't attach Production to version 2.</p> </li> <li> <p>You can move a label from one version of a parameter to another.</p> </li> <li> <p>You can't create a label when you create a new parameter. You must attach a label to a specific version of a parameter.</p> </li> <li> <p>You can't delete a parameter label. If you no longer want to use a parameter label, then you must move it to a different version of a parameter.</p> </li> <li> <p>A label can have a maximum of 100 characters.</p> </li> <li> <p>Labels can contain letters (case sensitive), numbers, periods (.), hyphens (-), or underscores (_).</p> </li> <li> <p>Labels can't begin with a number, "aws," or "ssm" (not case sensitive). If a label fails to meet these requirements, then the label is not associated with a parameter and the system displays it in the list of InvalidLabels.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                           ## body: JObject (required)
  var body_402657688 = newJObject()
  if body != nil:
    body_402657688 = body
  result = call_402657687.call(nil, nil, nil, nil, body_402657688)

var labelParameterVersion* = Call_LabelParameterVersion_402657674(
    name: "labelParameterVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.LabelParameterVersion",
    validator: validate_LabelParameterVersion_402657675, base: "/",
    makeUrl: url_LabelParameterVersion_402657676,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociationVersions_402657689 = ref object of OpenApiRestCall_402656044
proc url_ListAssociationVersions_402657691(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAssociationVersions_402657690(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves all versions of an association for a specific association ID.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657692 = header.getOrDefault("X-Amz-Target")
  valid_402657692 = validateParameter(valid_402657692, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociationVersions"))
  if valid_402657692 != nil:
    section.add "X-Amz-Target", valid_402657692
  var valid_402657693 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657693 = validateParameter(valid_402657693, JString,
                                      required = false, default = nil)
  if valid_402657693 != nil:
    section.add "X-Amz-Security-Token", valid_402657693
  var valid_402657694 = header.getOrDefault("X-Amz-Signature")
  valid_402657694 = validateParameter(valid_402657694, JString,
                                      required = false, default = nil)
  if valid_402657694 != nil:
    section.add "X-Amz-Signature", valid_402657694
  var valid_402657695 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657695 = validateParameter(valid_402657695, JString,
                                      required = false, default = nil)
  if valid_402657695 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657695
  var valid_402657696 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657696 = validateParameter(valid_402657696, JString,
                                      required = false, default = nil)
  if valid_402657696 != nil:
    section.add "X-Amz-Algorithm", valid_402657696
  var valid_402657697 = header.getOrDefault("X-Amz-Date")
  valid_402657697 = validateParameter(valid_402657697, JString,
                                      required = false, default = nil)
  if valid_402657697 != nil:
    section.add "X-Amz-Date", valid_402657697
  var valid_402657698 = header.getOrDefault("X-Amz-Credential")
  valid_402657698 = validateParameter(valid_402657698, JString,
                                      required = false, default = nil)
  if valid_402657698 != nil:
    section.add "X-Amz-Credential", valid_402657698
  var valid_402657699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657699 = validateParameter(valid_402657699, JString,
                                      required = false, default = nil)
  if valid_402657699 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657701: Call_ListAssociationVersions_402657689;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves all versions of an association for a specific association ID.
                                                                                         ## 
  let valid = call_402657701.validator(path, query, header, formData, body, _)
  let scheme = call_402657701.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657701.makeUrl(scheme.get, call_402657701.host, call_402657701.base,
                                   call_402657701.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657701, uri, valid, _)

proc call*(call_402657702: Call_ListAssociationVersions_402657689;
           body: JsonNode): Recallable =
  ## listAssociationVersions
  ## Retrieves all versions of an association for a specific association ID.
  ##   
                                                                            ## body: JObject (required)
  var body_402657703 = newJObject()
  if body != nil:
    body_402657703 = body
  result = call_402657702.call(nil, nil, nil, nil, body_402657703)

var listAssociationVersions* = Call_ListAssociationVersions_402657689(
    name: "listAssociationVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociationVersions",
    validator: validate_ListAssociationVersions_402657690, base: "/",
    makeUrl: url_ListAssociationVersions_402657691,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListAssociations_402657704 = ref object of OpenApiRestCall_402656044
proc url_ListAssociations_402657706(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListAssociations_402657705(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns all State Manager associations in the current AWS account and Region. You can limit the results to a specific State Manager association document or instance by specifying a filter.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657707 = query.getOrDefault("MaxResults")
  valid_402657707 = validateParameter(valid_402657707, JString,
                                      required = false, default = nil)
  if valid_402657707 != nil:
    section.add "MaxResults", valid_402657707
  var valid_402657708 = query.getOrDefault("NextToken")
  valid_402657708 = validateParameter(valid_402657708, JString,
                                      required = false, default = nil)
  if valid_402657708 != nil:
    section.add "NextToken", valid_402657708
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657709 = header.getOrDefault("X-Amz-Target")
  valid_402657709 = validateParameter(valid_402657709, JString, required = true, default = newJString(
      "AmazonSSM.ListAssociations"))
  if valid_402657709 != nil:
    section.add "X-Amz-Target", valid_402657709
  var valid_402657710 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657710 = validateParameter(valid_402657710, JString,
                                      required = false, default = nil)
  if valid_402657710 != nil:
    section.add "X-Amz-Security-Token", valid_402657710
  var valid_402657711 = header.getOrDefault("X-Amz-Signature")
  valid_402657711 = validateParameter(valid_402657711, JString,
                                      required = false, default = nil)
  if valid_402657711 != nil:
    section.add "X-Amz-Signature", valid_402657711
  var valid_402657712 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657712 = validateParameter(valid_402657712, JString,
                                      required = false, default = nil)
  if valid_402657712 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657712
  var valid_402657713 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657713 = validateParameter(valid_402657713, JString,
                                      required = false, default = nil)
  if valid_402657713 != nil:
    section.add "X-Amz-Algorithm", valid_402657713
  var valid_402657714 = header.getOrDefault("X-Amz-Date")
  valid_402657714 = validateParameter(valid_402657714, JString,
                                      required = false, default = nil)
  if valid_402657714 != nil:
    section.add "X-Amz-Date", valid_402657714
  var valid_402657715 = header.getOrDefault("X-Amz-Credential")
  valid_402657715 = validateParameter(valid_402657715, JString,
                                      required = false, default = nil)
  if valid_402657715 != nil:
    section.add "X-Amz-Credential", valid_402657715
  var valid_402657716 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657716 = validateParameter(valid_402657716, JString,
                                      required = false, default = nil)
  if valid_402657716 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657716
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657718: Call_ListAssociations_402657704;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns all State Manager associations in the current AWS account and Region. You can limit the results to a specific State Manager association document or instance by specifying a filter.
                                                                                         ## 
  let valid = call_402657718.validator(path, query, header, formData, body, _)
  let scheme = call_402657718.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657718.makeUrl(scheme.get, call_402657718.host, call_402657718.base,
                                   call_402657718.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657718, uri, valid, _)

proc call*(call_402657719: Call_ListAssociations_402657704; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listAssociations
  ## Returns all State Manager associations in the current AWS account and Region. You can limit the results to a specific State Manager association document or instance by specifying a filter.
  ##   
                                                                                                                                                                                                 ## MaxResults: string
                                                                                                                                                                                                 ##             
                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                 ## limit
  ##   
                                                                                                                                                                                                         ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                    ## NextToken: string
                                                                                                                                                                                                                                    ##            
                                                                                                                                                                                                                                    ## : 
                                                                                                                                                                                                                                    ## Pagination 
                                                                                                                                                                                                                                    ## token
  var query_402657720 = newJObject()
  var body_402657721 = newJObject()
  add(query_402657720, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657721 = body
  add(query_402657720, "NextToken", newJString(NextToken))
  result = call_402657719.call(nil, query_402657720, nil, nil, body_402657721)

var listAssociations* = Call_ListAssociations_402657704(
    name: "listAssociations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListAssociations",
    validator: validate_ListAssociations_402657705, base: "/",
    makeUrl: url_ListAssociations_402657706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommandInvocations_402657722 = ref object of OpenApiRestCall_402656044
proc url_ListCommandInvocations_402657724(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCommandInvocations_402657723(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657725 = query.getOrDefault("MaxResults")
  valid_402657725 = validateParameter(valid_402657725, JString,
                                      required = false, default = nil)
  if valid_402657725 != nil:
    section.add "MaxResults", valid_402657725
  var valid_402657726 = query.getOrDefault("NextToken")
  valid_402657726 = validateParameter(valid_402657726, JString,
                                      required = false, default = nil)
  if valid_402657726 != nil:
    section.add "NextToken", valid_402657726
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657727 = header.getOrDefault("X-Amz-Target")
  valid_402657727 = validateParameter(valid_402657727, JString, required = true, default = newJString(
      "AmazonSSM.ListCommandInvocations"))
  if valid_402657727 != nil:
    section.add "X-Amz-Target", valid_402657727
  var valid_402657728 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657728 = validateParameter(valid_402657728, JString,
                                      required = false, default = nil)
  if valid_402657728 != nil:
    section.add "X-Amz-Security-Token", valid_402657728
  var valid_402657729 = header.getOrDefault("X-Amz-Signature")
  valid_402657729 = validateParameter(valid_402657729, JString,
                                      required = false, default = nil)
  if valid_402657729 != nil:
    section.add "X-Amz-Signature", valid_402657729
  var valid_402657730 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657730 = validateParameter(valid_402657730, JString,
                                      required = false, default = nil)
  if valid_402657730 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657730
  var valid_402657731 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657731 = validateParameter(valid_402657731, JString,
                                      required = false, default = nil)
  if valid_402657731 != nil:
    section.add "X-Amz-Algorithm", valid_402657731
  var valid_402657732 = header.getOrDefault("X-Amz-Date")
  valid_402657732 = validateParameter(valid_402657732, JString,
                                      required = false, default = nil)
  if valid_402657732 != nil:
    section.add "X-Amz-Date", valid_402657732
  var valid_402657733 = header.getOrDefault("X-Amz-Credential")
  valid_402657733 = validateParameter(valid_402657733, JString,
                                      required = false, default = nil)
  if valid_402657733 != nil:
    section.add "X-Amz-Credential", valid_402657733
  var valid_402657734 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657734 = validateParameter(valid_402657734, JString,
                                      required = false, default = nil)
  if valid_402657734 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657734
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657736: Call_ListCommandInvocations_402657722;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
                                                                                         ## 
  let valid = call_402657736.validator(path, query, header, formData, body, _)
  let scheme = call_402657736.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657736.makeUrl(scheme.get, call_402657736.host, call_402657736.base,
                                   call_402657736.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657736, uri, valid, _)

proc call*(call_402657737: Call_ListCommandInvocations_402657722;
           body: JsonNode; MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCommandInvocations
  ## An invocation is copy of a command sent to a specific instance. A command can apply to one or more instances. A command invocation applies to one instance. For example, if a user runs SendCommand against three instances, then a command invocation is created for each requested instance ID. ListCommandInvocations provide status about command execution.
  ##   
                                                                                                                                                                                                                                                                                                                                                                     ## MaxResults: string
                                                                                                                                                                                                                                                                                                                                                                     ##             
                                                                                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                                                                                     ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                     ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                        ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                        ##            
                                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                                        ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                        ## token
  var query_402657738 = newJObject()
  var body_402657739 = newJObject()
  add(query_402657738, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657739 = body
  add(query_402657738, "NextToken", newJString(NextToken))
  result = call_402657737.call(nil, query_402657738, nil, nil, body_402657739)

var listCommandInvocations* = Call_ListCommandInvocations_402657722(
    name: "listCommandInvocations", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommandInvocations",
    validator: validate_ListCommandInvocations_402657723, base: "/",
    makeUrl: url_ListCommandInvocations_402657724,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListCommands_402657740 = ref object of OpenApiRestCall_402656044
proc url_ListCommands_402657742(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListCommands_402657741(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the commands requested by users of the AWS account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657743 = query.getOrDefault("MaxResults")
  valid_402657743 = validateParameter(valid_402657743, JString,
                                      required = false, default = nil)
  if valid_402657743 != nil:
    section.add "MaxResults", valid_402657743
  var valid_402657744 = query.getOrDefault("NextToken")
  valid_402657744 = validateParameter(valid_402657744, JString,
                                      required = false, default = nil)
  if valid_402657744 != nil:
    section.add "NextToken", valid_402657744
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657745 = header.getOrDefault("X-Amz-Target")
  valid_402657745 = validateParameter(valid_402657745, JString, required = true, default = newJString(
      "AmazonSSM.ListCommands"))
  if valid_402657745 != nil:
    section.add "X-Amz-Target", valid_402657745
  var valid_402657746 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657746 = validateParameter(valid_402657746, JString,
                                      required = false, default = nil)
  if valid_402657746 != nil:
    section.add "X-Amz-Security-Token", valid_402657746
  var valid_402657747 = header.getOrDefault("X-Amz-Signature")
  valid_402657747 = validateParameter(valid_402657747, JString,
                                      required = false, default = nil)
  if valid_402657747 != nil:
    section.add "X-Amz-Signature", valid_402657747
  var valid_402657748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657748 = validateParameter(valid_402657748, JString,
                                      required = false, default = nil)
  if valid_402657748 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657748
  var valid_402657749 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657749 = validateParameter(valid_402657749, JString,
                                      required = false, default = nil)
  if valid_402657749 != nil:
    section.add "X-Amz-Algorithm", valid_402657749
  var valid_402657750 = header.getOrDefault("X-Amz-Date")
  valid_402657750 = validateParameter(valid_402657750, JString,
                                      required = false, default = nil)
  if valid_402657750 != nil:
    section.add "X-Amz-Date", valid_402657750
  var valid_402657751 = header.getOrDefault("X-Amz-Credential")
  valid_402657751 = validateParameter(valid_402657751, JString,
                                      required = false, default = nil)
  if valid_402657751 != nil:
    section.add "X-Amz-Credential", valid_402657751
  var valid_402657752 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657752 = validateParameter(valid_402657752, JString,
                                      required = false, default = nil)
  if valid_402657752 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657752
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657754: Call_ListCommands_402657740; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the commands requested by users of the AWS account.
                                                                                         ## 
  let valid = call_402657754.validator(path, query, header, formData, body, _)
  let scheme = call_402657754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657754.makeUrl(scheme.get, call_402657754.host, call_402657754.base,
                                   call_402657754.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657754, uri, valid, _)

proc call*(call_402657755: Call_ListCommands_402657740; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listCommands
  ## Lists the commands requested by users of the AWS account.
  ##   MaxResults: string
                                                              ##             : Pagination limit
  ##   
                                                                                               ## body: JObject (required)
  ##   
                                                                                                                          ## NextToken: string
                                                                                                                          ##            
                                                                                                                          ## : 
                                                                                                                          ## Pagination 
                                                                                                                          ## token
  var query_402657756 = newJObject()
  var body_402657757 = newJObject()
  add(query_402657756, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657757 = body
  add(query_402657756, "NextToken", newJString(NextToken))
  result = call_402657755.call(nil, query_402657756, nil, nil, body_402657757)

var listCommands* = Call_ListCommands_402657740(name: "listCommands",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListCommands",
    validator: validate_ListCommands_402657741, base: "/",
    makeUrl: url_ListCommands_402657742, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceItems_402657758 = ref object of OpenApiRestCall_402656044
proc url_ListComplianceItems_402657760(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListComplianceItems_402657759(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657761 = header.getOrDefault("X-Amz-Target")
  valid_402657761 = validateParameter(valid_402657761, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceItems"))
  if valid_402657761 != nil:
    section.add "X-Amz-Target", valid_402657761
  var valid_402657762 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657762 = validateParameter(valid_402657762, JString,
                                      required = false, default = nil)
  if valid_402657762 != nil:
    section.add "X-Amz-Security-Token", valid_402657762
  var valid_402657763 = header.getOrDefault("X-Amz-Signature")
  valid_402657763 = validateParameter(valid_402657763, JString,
                                      required = false, default = nil)
  if valid_402657763 != nil:
    section.add "X-Amz-Signature", valid_402657763
  var valid_402657764 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657764 = validateParameter(valid_402657764, JString,
                                      required = false, default = nil)
  if valid_402657764 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657764
  var valid_402657765 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657765 = validateParameter(valid_402657765, JString,
                                      required = false, default = nil)
  if valid_402657765 != nil:
    section.add "X-Amz-Algorithm", valid_402657765
  var valid_402657766 = header.getOrDefault("X-Amz-Date")
  valid_402657766 = validateParameter(valid_402657766, JString,
                                      required = false, default = nil)
  if valid_402657766 != nil:
    section.add "X-Amz-Date", valid_402657766
  var valid_402657767 = header.getOrDefault("X-Amz-Credential")
  valid_402657767 = validateParameter(valid_402657767, JString,
                                      required = false, default = nil)
  if valid_402657767 != nil:
    section.add "X-Amz-Credential", valid_402657767
  var valid_402657768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657768 = validateParameter(valid_402657768, JString,
                                      required = false, default = nil)
  if valid_402657768 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657770: Call_ListComplianceItems_402657758;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
                                                                                         ## 
  let valid = call_402657770.validator(path, query, header, formData, body, _)
  let scheme = call_402657770.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657770.makeUrl(scheme.get, call_402657770.host, call_402657770.base,
                                   call_402657770.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657770, uri, valid, _)

proc call*(call_402657771: Call_ListComplianceItems_402657758; body: JsonNode): Recallable =
  ## listComplianceItems
  ## For a specified resource ID, this API action returns a list of compliance statuses for different resource types. Currently, you can only specify one resource ID per call. List results depend on the criteria specified in the filter. 
  ##   
                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402657772 = newJObject()
  if body != nil:
    body_402657772 = body
  result = call_402657771.call(nil, nil, nil, nil, body_402657772)

var listComplianceItems* = Call_ListComplianceItems_402657758(
    name: "listComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceItems",
    validator: validate_ListComplianceItems_402657759, base: "/",
    makeUrl: url_ListComplianceItems_402657760,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListComplianceSummaries_402657773 = ref object of OpenApiRestCall_402656044
proc url_ListComplianceSummaries_402657775(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListComplianceSummaries_402657774(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657776 = header.getOrDefault("X-Amz-Target")
  valid_402657776 = validateParameter(valid_402657776, JString, required = true, default = newJString(
      "AmazonSSM.ListComplianceSummaries"))
  if valid_402657776 != nil:
    section.add "X-Amz-Target", valid_402657776
  var valid_402657777 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657777 = validateParameter(valid_402657777, JString,
                                      required = false, default = nil)
  if valid_402657777 != nil:
    section.add "X-Amz-Security-Token", valid_402657777
  var valid_402657778 = header.getOrDefault("X-Amz-Signature")
  valid_402657778 = validateParameter(valid_402657778, JString,
                                      required = false, default = nil)
  if valid_402657778 != nil:
    section.add "X-Amz-Signature", valid_402657778
  var valid_402657779 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657779 = validateParameter(valid_402657779, JString,
                                      required = false, default = nil)
  if valid_402657779 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657779
  var valid_402657780 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657780 = validateParameter(valid_402657780, JString,
                                      required = false, default = nil)
  if valid_402657780 != nil:
    section.add "X-Amz-Algorithm", valid_402657780
  var valid_402657781 = header.getOrDefault("X-Amz-Date")
  valid_402657781 = validateParameter(valid_402657781, JString,
                                      required = false, default = nil)
  if valid_402657781 != nil:
    section.add "X-Amz-Date", valid_402657781
  var valid_402657782 = header.getOrDefault("X-Amz-Credential")
  valid_402657782 = validateParameter(valid_402657782, JString,
                                      required = false, default = nil)
  if valid_402657782 != nil:
    section.add "X-Amz-Credential", valid_402657782
  var valid_402657783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657783 = validateParameter(valid_402657783, JString,
                                      required = false, default = nil)
  if valid_402657783 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657785: Call_ListComplianceSummaries_402657773;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
                                                                                         ## 
  let valid = call_402657785.validator(path, query, header, formData, body, _)
  let scheme = call_402657785.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657785.makeUrl(scheme.get, call_402657785.host, call_402657785.base,
                                   call_402657785.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657785, uri, valid, _)

proc call*(call_402657786: Call_ListComplianceSummaries_402657773;
           body: JsonNode): Recallable =
  ## listComplianceSummaries
  ## Returns a summary count of compliant and non-compliant resources for a compliance type. For example, this call can return State Manager associations, patches, or custom compliance types according to the filter criteria that you specify. 
  ##   
                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402657787 = newJObject()
  if body != nil:
    body_402657787 = body
  result = call_402657786.call(nil, nil, nil, nil, body_402657787)

var listComplianceSummaries* = Call_ListComplianceSummaries_402657773(
    name: "listComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListComplianceSummaries",
    validator: validate_ListComplianceSummaries_402657774, base: "/",
    makeUrl: url_ListComplianceSummaries_402657775,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocumentVersions_402657788 = ref object of OpenApiRestCall_402656044
proc url_ListDocumentVersions_402657790(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDocumentVersions_402657789(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List all versions for a document.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657791 = header.getOrDefault("X-Amz-Target")
  valid_402657791 = validateParameter(valid_402657791, JString, required = true, default = newJString(
      "AmazonSSM.ListDocumentVersions"))
  if valid_402657791 != nil:
    section.add "X-Amz-Target", valid_402657791
  var valid_402657792 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657792 = validateParameter(valid_402657792, JString,
                                      required = false, default = nil)
  if valid_402657792 != nil:
    section.add "X-Amz-Security-Token", valid_402657792
  var valid_402657793 = header.getOrDefault("X-Amz-Signature")
  valid_402657793 = validateParameter(valid_402657793, JString,
                                      required = false, default = nil)
  if valid_402657793 != nil:
    section.add "X-Amz-Signature", valid_402657793
  var valid_402657794 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657794 = validateParameter(valid_402657794, JString,
                                      required = false, default = nil)
  if valid_402657794 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657794
  var valid_402657795 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657795 = validateParameter(valid_402657795, JString,
                                      required = false, default = nil)
  if valid_402657795 != nil:
    section.add "X-Amz-Algorithm", valid_402657795
  var valid_402657796 = header.getOrDefault("X-Amz-Date")
  valid_402657796 = validateParameter(valid_402657796, JString,
                                      required = false, default = nil)
  if valid_402657796 != nil:
    section.add "X-Amz-Date", valid_402657796
  var valid_402657797 = header.getOrDefault("X-Amz-Credential")
  valid_402657797 = validateParameter(valid_402657797, JString,
                                      required = false, default = nil)
  if valid_402657797 != nil:
    section.add "X-Amz-Credential", valid_402657797
  var valid_402657798 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657798 = validateParameter(valid_402657798, JString,
                                      required = false, default = nil)
  if valid_402657798 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657798
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657800: Call_ListDocumentVersions_402657788;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List all versions for a document.
                                                                                         ## 
  let valid = call_402657800.validator(path, query, header, formData, body, _)
  let scheme = call_402657800.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657800.makeUrl(scheme.get, call_402657800.host, call_402657800.base,
                                   call_402657800.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657800, uri, valid, _)

proc call*(call_402657801: Call_ListDocumentVersions_402657788; body: JsonNode): Recallable =
  ## listDocumentVersions
  ## List all versions for a document.
  ##   body: JObject (required)
  var body_402657802 = newJObject()
  if body != nil:
    body_402657802 = body
  result = call_402657801.call(nil, nil, nil, nil, body_402657802)

var listDocumentVersions* = Call_ListDocumentVersions_402657788(
    name: "listDocumentVersions", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocumentVersions",
    validator: validate_ListDocumentVersions_402657789, base: "/",
    makeUrl: url_ListDocumentVersions_402657790,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListDocuments_402657803 = ref object of OpenApiRestCall_402656044
proc url_ListDocuments_402657805(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListDocuments_402657804(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns all Systems Manager (SSM) documents in the current AWS account and Region. You can limit the results of this request by using a filter.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JString
                                  ##             : Pagination limit
  ##   NextToken: JString
                                                                   ##            : Pagination token
  section = newJObject()
  var valid_402657806 = query.getOrDefault("MaxResults")
  valid_402657806 = validateParameter(valid_402657806, JString,
                                      required = false, default = nil)
  if valid_402657806 != nil:
    section.add "MaxResults", valid_402657806
  var valid_402657807 = query.getOrDefault("NextToken")
  valid_402657807 = validateParameter(valid_402657807, JString,
                                      required = false, default = nil)
  if valid_402657807 != nil:
    section.add "NextToken", valid_402657807
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657808 = header.getOrDefault("X-Amz-Target")
  valid_402657808 = validateParameter(valid_402657808, JString, required = true, default = newJString(
      "AmazonSSM.ListDocuments"))
  if valid_402657808 != nil:
    section.add "X-Amz-Target", valid_402657808
  var valid_402657809 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657809 = validateParameter(valid_402657809, JString,
                                      required = false, default = nil)
  if valid_402657809 != nil:
    section.add "X-Amz-Security-Token", valid_402657809
  var valid_402657810 = header.getOrDefault("X-Amz-Signature")
  valid_402657810 = validateParameter(valid_402657810, JString,
                                      required = false, default = nil)
  if valid_402657810 != nil:
    section.add "X-Amz-Signature", valid_402657810
  var valid_402657811 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657811 = validateParameter(valid_402657811, JString,
                                      required = false, default = nil)
  if valid_402657811 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657811
  var valid_402657812 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657812 = validateParameter(valid_402657812, JString,
                                      required = false, default = nil)
  if valid_402657812 != nil:
    section.add "X-Amz-Algorithm", valid_402657812
  var valid_402657813 = header.getOrDefault("X-Amz-Date")
  valid_402657813 = validateParameter(valid_402657813, JString,
                                      required = false, default = nil)
  if valid_402657813 != nil:
    section.add "X-Amz-Date", valid_402657813
  var valid_402657814 = header.getOrDefault("X-Amz-Credential")
  valid_402657814 = validateParameter(valid_402657814, JString,
                                      required = false, default = nil)
  if valid_402657814 != nil:
    section.add "X-Amz-Credential", valid_402657814
  var valid_402657815 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657815 = validateParameter(valid_402657815, JString,
                                      required = false, default = nil)
  if valid_402657815 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657815
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657817: Call_ListDocuments_402657803; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns all Systems Manager (SSM) documents in the current AWS account and Region. You can limit the results of this request by using a filter.
                                                                                         ## 
  let valid = call_402657817.validator(path, query, header, formData, body, _)
  let scheme = call_402657817.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657817.makeUrl(scheme.get, call_402657817.host, call_402657817.base,
                                   call_402657817.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657817, uri, valid, _)

proc call*(call_402657818: Call_ListDocuments_402657803; body: JsonNode;
           MaxResults: string = ""; NextToken: string = ""): Recallable =
  ## listDocuments
  ## Returns all Systems Manager (SSM) documents in the current AWS account and Region. You can limit the results of this request by using a filter.
  ##   
                                                                                                                                                    ## MaxResults: string
                                                                                                                                                    ##             
                                                                                                                                                    ## : 
                                                                                                                                                    ## Pagination 
                                                                                                                                                    ## limit
  ##   
                                                                                                                                                            ## body: JObject (required)
  ##   
                                                                                                                                                                                       ## NextToken: string
                                                                                                                                                                                       ##            
                                                                                                                                                                                       ## : 
                                                                                                                                                                                       ## Pagination 
                                                                                                                                                                                       ## token
  var query_402657819 = newJObject()
  var body_402657820 = newJObject()
  add(query_402657819, "MaxResults", newJString(MaxResults))
  if body != nil:
    body_402657820 = body
  add(query_402657819, "NextToken", newJString(NextToken))
  result = call_402657818.call(nil, query_402657819, nil, nil, body_402657820)

var listDocuments* = Call_ListDocuments_402657803(name: "listDocuments",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListDocuments",
    validator: validate_ListDocuments_402657804, base: "/",
    makeUrl: url_ListDocuments_402657805, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInventoryEntries_402657821 = ref object of OpenApiRestCall_402656044
proc url_ListInventoryEntries_402657823(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInventoryEntries_402657822(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## A list of inventory items returned by the request.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657824 = header.getOrDefault("X-Amz-Target")
  valid_402657824 = validateParameter(valid_402657824, JString, required = true, default = newJString(
      "AmazonSSM.ListInventoryEntries"))
  if valid_402657824 != nil:
    section.add "X-Amz-Target", valid_402657824
  var valid_402657825 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657825 = validateParameter(valid_402657825, JString,
                                      required = false, default = nil)
  if valid_402657825 != nil:
    section.add "X-Amz-Security-Token", valid_402657825
  var valid_402657826 = header.getOrDefault("X-Amz-Signature")
  valid_402657826 = validateParameter(valid_402657826, JString,
                                      required = false, default = nil)
  if valid_402657826 != nil:
    section.add "X-Amz-Signature", valid_402657826
  var valid_402657827 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657827 = validateParameter(valid_402657827, JString,
                                      required = false, default = nil)
  if valid_402657827 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657827
  var valid_402657828 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657828 = validateParameter(valid_402657828, JString,
                                      required = false, default = nil)
  if valid_402657828 != nil:
    section.add "X-Amz-Algorithm", valid_402657828
  var valid_402657829 = header.getOrDefault("X-Amz-Date")
  valid_402657829 = validateParameter(valid_402657829, JString,
                                      required = false, default = nil)
  if valid_402657829 != nil:
    section.add "X-Amz-Date", valid_402657829
  var valid_402657830 = header.getOrDefault("X-Amz-Credential")
  valid_402657830 = validateParameter(valid_402657830, JString,
                                      required = false, default = nil)
  if valid_402657830 != nil:
    section.add "X-Amz-Credential", valid_402657830
  var valid_402657831 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657831 = validateParameter(valid_402657831, JString,
                                      required = false, default = nil)
  if valid_402657831 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657831
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657833: Call_ListInventoryEntries_402657821;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## 
                                                                                         ## A list of inventory items returned by the request.
                                                                                         ## 
  let valid = call_402657833.validator(path, query, header, formData, body, _)
  let scheme = call_402657833.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657833.makeUrl(scheme.get, call_402657833.host, call_402657833.base,
                                   call_402657833.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657833, uri, valid, _)

proc call*(call_402657834: Call_ListInventoryEntries_402657821; body: JsonNode): Recallable =
  ## listInventoryEntries
  ## A list of inventory items returned by the request.
  ##   body: JObject (required)
  var body_402657835 = newJObject()
  if body != nil:
    body_402657835 = body
  result = call_402657834.call(nil, nil, nil, nil, body_402657835)

var listInventoryEntries* = Call_ListInventoryEntries_402657821(
    name: "listInventoryEntries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListInventoryEntries",
    validator: validate_ListInventoryEntries_402657822, base: "/",
    makeUrl: url_ListInventoryEntries_402657823,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceComplianceSummaries_402657836 = ref object of OpenApiRestCall_402656044
proc url_ListResourceComplianceSummaries_402657838(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceComplianceSummaries_402657837(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657839 = header.getOrDefault("X-Amz-Target")
  valid_402657839 = validateParameter(valid_402657839, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceComplianceSummaries"))
  if valid_402657839 != nil:
    section.add "X-Amz-Target", valid_402657839
  var valid_402657840 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657840 = validateParameter(valid_402657840, JString,
                                      required = false, default = nil)
  if valid_402657840 != nil:
    section.add "X-Amz-Security-Token", valid_402657840
  var valid_402657841 = header.getOrDefault("X-Amz-Signature")
  valid_402657841 = validateParameter(valid_402657841, JString,
                                      required = false, default = nil)
  if valid_402657841 != nil:
    section.add "X-Amz-Signature", valid_402657841
  var valid_402657842 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657842 = validateParameter(valid_402657842, JString,
                                      required = false, default = nil)
  if valid_402657842 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657842
  var valid_402657843 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657843 = validateParameter(valid_402657843, JString,
                                      required = false, default = nil)
  if valid_402657843 != nil:
    section.add "X-Amz-Algorithm", valid_402657843
  var valid_402657844 = header.getOrDefault("X-Amz-Date")
  valid_402657844 = validateParameter(valid_402657844, JString,
                                      required = false, default = nil)
  if valid_402657844 != nil:
    section.add "X-Amz-Date", valid_402657844
  var valid_402657845 = header.getOrDefault("X-Amz-Credential")
  valid_402657845 = validateParameter(valid_402657845, JString,
                                      required = false, default = nil)
  if valid_402657845 != nil:
    section.add "X-Amz-Credential", valid_402657845
  var valid_402657846 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657846 = validateParameter(valid_402657846, JString,
                                      required = false, default = nil)
  if valid_402657846 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657846
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657848: Call_ListResourceComplianceSummaries_402657836;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
                                                                                         ## 
  let valid = call_402657848.validator(path, query, header, formData, body, _)
  let scheme = call_402657848.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657848.makeUrl(scheme.get, call_402657848.host, call_402657848.base,
                                   call_402657848.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657848, uri, valid, _)

proc call*(call_402657849: Call_ListResourceComplianceSummaries_402657836;
           body: JsonNode): Recallable =
  ## listResourceComplianceSummaries
  ## Returns a resource-level summary count. The summary includes information about compliant and non-compliant statuses and detailed compliance-item severity counts, according to the filter criteria you specify.
  ##   
                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402657850 = newJObject()
  if body != nil:
    body_402657850 = body
  result = call_402657849.call(nil, nil, nil, nil, body_402657850)

var listResourceComplianceSummaries* = Call_ListResourceComplianceSummaries_402657836(
    name: "listResourceComplianceSummaries", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceComplianceSummaries",
    validator: validate_ListResourceComplianceSummaries_402657837, base: "/",
    makeUrl: url_ListResourceComplianceSummaries_402657838,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListResourceDataSync_402657851 = ref object of OpenApiRestCall_402656044
proc url_ListResourceDataSync_402657853(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListResourceDataSync_402657852(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657854 = header.getOrDefault("X-Amz-Target")
  valid_402657854 = validateParameter(valid_402657854, JString, required = true, default = newJString(
      "AmazonSSM.ListResourceDataSync"))
  if valid_402657854 != nil:
    section.add "X-Amz-Target", valid_402657854
  var valid_402657855 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657855 = validateParameter(valid_402657855, JString,
                                      required = false, default = nil)
  if valid_402657855 != nil:
    section.add "X-Amz-Security-Token", valid_402657855
  var valid_402657856 = header.getOrDefault("X-Amz-Signature")
  valid_402657856 = validateParameter(valid_402657856, JString,
                                      required = false, default = nil)
  if valid_402657856 != nil:
    section.add "X-Amz-Signature", valid_402657856
  var valid_402657857 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657857 = validateParameter(valid_402657857, JString,
                                      required = false, default = nil)
  if valid_402657857 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657857
  var valid_402657858 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657858 = validateParameter(valid_402657858, JString,
                                      required = false, default = nil)
  if valid_402657858 != nil:
    section.add "X-Amz-Algorithm", valid_402657858
  var valid_402657859 = header.getOrDefault("X-Amz-Date")
  valid_402657859 = validateParameter(valid_402657859, JString,
                                      required = false, default = nil)
  if valid_402657859 != nil:
    section.add "X-Amz-Date", valid_402657859
  var valid_402657860 = header.getOrDefault("X-Amz-Credential")
  valid_402657860 = validateParameter(valid_402657860, JString,
                                      required = false, default = nil)
  if valid_402657860 != nil:
    section.add "X-Amz-Credential", valid_402657860
  var valid_402657861 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657861 = validateParameter(valid_402657861, JString,
                                      required = false, default = nil)
  if valid_402657861 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657861
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657863: Call_ListResourceDataSync_402657851;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
                                                                                         ## 
  let valid = call_402657863.validator(path, query, header, formData, body, _)
  let scheme = call_402657863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657863.makeUrl(scheme.get, call_402657863.host, call_402657863.base,
                                   call_402657863.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657863, uri, valid, _)

proc call*(call_402657864: Call_ListResourceDataSync_402657851; body: JsonNode): Recallable =
  ## listResourceDataSync
  ## <p>Lists your resource data sync configurations. Includes information about the last time a sync attempted to start, the last sync status, and the last time a sync successfully completed.</p> <p>The number of sync configurations might be too large to return using a single call to <code>ListResourceDataSync</code>. You can limit the number of sync configurations returned by using the <code>MaxResults</code> parameter. To determine whether there are more sync configurations to list, check the value of <code>NextToken</code> in the output. If there are more sync configurations to list, you can request them by specifying the <code>NextToken</code> returned in the call to the parameter of a subsequent call. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402657865 = newJObject()
  if body != nil:
    body_402657865 = body
  result = call_402657864.call(nil, nil, nil, nil, body_402657865)

var listResourceDataSync* = Call_ListResourceDataSync_402657851(
    name: "listResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListResourceDataSync",
    validator: validate_ListResourceDataSync_402657852, base: "/",
    makeUrl: url_ListResourceDataSync_402657853,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402657866 = ref object of OpenApiRestCall_402656044
proc url_ListTagsForResource_402657868(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListTagsForResource_402657867(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a list of the tags assigned to the specified resource.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657869 = header.getOrDefault("X-Amz-Target")
  valid_402657869 = validateParameter(valid_402657869, JString, required = true, default = newJString(
      "AmazonSSM.ListTagsForResource"))
  if valid_402657869 != nil:
    section.add "X-Amz-Target", valid_402657869
  var valid_402657870 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657870 = validateParameter(valid_402657870, JString,
                                      required = false, default = nil)
  if valid_402657870 != nil:
    section.add "X-Amz-Security-Token", valid_402657870
  var valid_402657871 = header.getOrDefault("X-Amz-Signature")
  valid_402657871 = validateParameter(valid_402657871, JString,
                                      required = false, default = nil)
  if valid_402657871 != nil:
    section.add "X-Amz-Signature", valid_402657871
  var valid_402657872 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657872 = validateParameter(valid_402657872, JString,
                                      required = false, default = nil)
  if valid_402657872 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657872
  var valid_402657873 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657873 = validateParameter(valid_402657873, JString,
                                      required = false, default = nil)
  if valid_402657873 != nil:
    section.add "X-Amz-Algorithm", valid_402657873
  var valid_402657874 = header.getOrDefault("X-Amz-Date")
  valid_402657874 = validateParameter(valid_402657874, JString,
                                      required = false, default = nil)
  if valid_402657874 != nil:
    section.add "X-Amz-Date", valid_402657874
  var valid_402657875 = header.getOrDefault("X-Amz-Credential")
  valid_402657875 = validateParameter(valid_402657875, JString,
                                      required = false, default = nil)
  if valid_402657875 != nil:
    section.add "X-Amz-Credential", valid_402657875
  var valid_402657876 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657876 = validateParameter(valid_402657876, JString,
                                      required = false, default = nil)
  if valid_402657876 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657876
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657878: Call_ListTagsForResource_402657866;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a list of the tags assigned to the specified resource.
                                                                                         ## 
  let valid = call_402657878.validator(path, query, header, formData, body, _)
  let scheme = call_402657878.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657878.makeUrl(scheme.get, call_402657878.host, call_402657878.base,
                                   call_402657878.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657878, uri, valid, _)

proc call*(call_402657879: Call_ListTagsForResource_402657866; body: JsonNode): Recallable =
  ## listTagsForResource
  ## Returns a list of the tags assigned to the specified resource.
  ##   body: JObject (required)
  var body_402657880 = newJObject()
  if body != nil:
    body_402657880 = body
  result = call_402657879.call(nil, nil, nil, nil, body_402657880)

var listTagsForResource* = Call_ListTagsForResource_402657866(
    name: "listTagsForResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ListTagsForResource",
    validator: validate_ListTagsForResource_402657867, base: "/",
    makeUrl: url_ListTagsForResource_402657868,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ModifyDocumentPermission_402657881 = ref object of OpenApiRestCall_402656044
proc url_ModifyDocumentPermission_402657883(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ModifyDocumentPermission_402657882(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657884 = header.getOrDefault("X-Amz-Target")
  valid_402657884 = validateParameter(valid_402657884, JString, required = true, default = newJString(
      "AmazonSSM.ModifyDocumentPermission"))
  if valid_402657884 != nil:
    section.add "X-Amz-Target", valid_402657884
  var valid_402657885 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657885 = validateParameter(valid_402657885, JString,
                                      required = false, default = nil)
  if valid_402657885 != nil:
    section.add "X-Amz-Security-Token", valid_402657885
  var valid_402657886 = header.getOrDefault("X-Amz-Signature")
  valid_402657886 = validateParameter(valid_402657886, JString,
                                      required = false, default = nil)
  if valid_402657886 != nil:
    section.add "X-Amz-Signature", valid_402657886
  var valid_402657887 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657887 = validateParameter(valid_402657887, JString,
                                      required = false, default = nil)
  if valid_402657887 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657887
  var valid_402657888 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657888 = validateParameter(valid_402657888, JString,
                                      required = false, default = nil)
  if valid_402657888 != nil:
    section.add "X-Amz-Algorithm", valid_402657888
  var valid_402657889 = header.getOrDefault("X-Amz-Date")
  valid_402657889 = validateParameter(valid_402657889, JString,
                                      required = false, default = nil)
  if valid_402657889 != nil:
    section.add "X-Amz-Date", valid_402657889
  var valid_402657890 = header.getOrDefault("X-Amz-Credential")
  valid_402657890 = validateParameter(valid_402657890, JString,
                                      required = false, default = nil)
  if valid_402657890 != nil:
    section.add "X-Amz-Credential", valid_402657890
  var valid_402657891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657891 = validateParameter(valid_402657891, JString,
                                      required = false, default = nil)
  if valid_402657891 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657891
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657893: Call_ModifyDocumentPermission_402657881;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
                                                                                         ## 
  let valid = call_402657893.validator(path, query, header, formData, body, _)
  let scheme = call_402657893.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657893.makeUrl(scheme.get, call_402657893.host, call_402657893.base,
                                   call_402657893.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657893, uri, valid, _)

proc call*(call_402657894: Call_ModifyDocumentPermission_402657881;
           body: JsonNode): Recallable =
  ## modifyDocumentPermission
  ## Shares a Systems Manager document publicly or privately. If you share a document privately, you must specify the AWS user account IDs for those people who can use the document. If you share a document publicly, you must specify <i>All</i> as the account ID.
  ##   
                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402657895 = newJObject()
  if body != nil:
    body_402657895 = body
  result = call_402657894.call(nil, nil, nil, nil, body_402657895)

var modifyDocumentPermission* = Call_ModifyDocumentPermission_402657881(
    name: "modifyDocumentPermission", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ModifyDocumentPermission",
    validator: validate_ModifyDocumentPermission_402657882, base: "/",
    makeUrl: url_ModifyDocumentPermission_402657883,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutComplianceItems_402657896 = ref object of OpenApiRestCall_402656044
proc url_PutComplianceItems_402657898(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutComplianceItems_402657897(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657899 = header.getOrDefault("X-Amz-Target")
  valid_402657899 = validateParameter(valid_402657899, JString, required = true, default = newJString(
      "AmazonSSM.PutComplianceItems"))
  if valid_402657899 != nil:
    section.add "X-Amz-Target", valid_402657899
  var valid_402657900 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657900 = validateParameter(valid_402657900, JString,
                                      required = false, default = nil)
  if valid_402657900 != nil:
    section.add "X-Amz-Security-Token", valid_402657900
  var valid_402657901 = header.getOrDefault("X-Amz-Signature")
  valid_402657901 = validateParameter(valid_402657901, JString,
                                      required = false, default = nil)
  if valid_402657901 != nil:
    section.add "X-Amz-Signature", valid_402657901
  var valid_402657902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657902 = validateParameter(valid_402657902, JString,
                                      required = false, default = nil)
  if valid_402657902 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657902
  var valid_402657903 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657903 = validateParameter(valid_402657903, JString,
                                      required = false, default = nil)
  if valid_402657903 != nil:
    section.add "X-Amz-Algorithm", valid_402657903
  var valid_402657904 = header.getOrDefault("X-Amz-Date")
  valid_402657904 = validateParameter(valid_402657904, JString,
                                      required = false, default = nil)
  if valid_402657904 != nil:
    section.add "X-Amz-Date", valid_402657904
  var valid_402657905 = header.getOrDefault("X-Amz-Credential")
  valid_402657905 = validateParameter(valid_402657905, JString,
                                      required = false, default = nil)
  if valid_402657905 != nil:
    section.add "X-Amz-Credential", valid_402657905
  var valid_402657906 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657906 = validateParameter(valid_402657906, JString,
                                      required = false, default = nil)
  if valid_402657906 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657908: Call_PutComplianceItems_402657896;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
                                                                                         ## 
  let valid = call_402657908.validator(path, query, header, formData, body, _)
  let scheme = call_402657908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657908.makeUrl(scheme.get, call_402657908.host, call_402657908.base,
                                   call_402657908.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657908, uri, valid, _)

proc call*(call_402657909: Call_PutComplianceItems_402657896; body: JsonNode): Recallable =
  ## putComplianceItems
  ## <p>Registers a compliance type and other compliance details on a designated resource. This action lets you register custom compliance details with a resource. This call overwrites existing compliance information on the resource, so you must provide a full list of compliance items each time that you send the request.</p> <p>ComplianceType can be one of the following:</p> <ul> <li> <p>ExecutionId: The execution ID when the patch, association, or custom compliance item was applied.</p> </li> <li> <p>ExecutionType: Specify patch, association, or Custom:<code>string</code>.</p> </li> <li> <p>ExecutionTime. The time the patch, association, or custom compliance item was applied to the instance.</p> </li> <li> <p>Id: The patch, association, or custom compliance ID.</p> </li> <li> <p>Title: A title.</p> </li> <li> <p>Status: The status of the compliance item. For example, <code>approved</code> for patches, or <code>Failed</code> for associations.</p> </li> <li> <p>Severity: A patch severity. For example, <code>critical</code>.</p> </li> <li> <p>DocumentName: A SSM document name. For example, AWS-RunPatchBaseline.</p> </li> <li> <p>DocumentVersion: An SSM document version number. For example, 4.</p> </li> <li> <p>Classification: A patch classification. For example, <code>security updates</code>.</p> </li> <li> <p>PatchBaselineId: A patch baseline ID.</p> </li> <li> <p>PatchSeverity: A patch severity. For example, <code>Critical</code>.</p> </li> <li> <p>PatchState: A patch state. For example, <code>InstancesWithFailedPatches</code>.</p> </li> <li> <p>PatchGroup: The name of a patch group.</p> </li> <li> <p>InstalledTime: The time the association, patch, or custom compliance item was applied to the resource. Specify the time by using the following format: yyyy-MM-dd'T'HH:mm:ss'Z'</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            ## body: JObject (required)
  var body_402657910 = newJObject()
  if body != nil:
    body_402657910 = body
  result = call_402657909.call(nil, nil, nil, nil, body_402657910)

var putComplianceItems* = Call_PutComplianceItems_402657896(
    name: "putComplianceItems", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutComplianceItems",
    validator: validate_PutComplianceItems_402657897, base: "/",
    makeUrl: url_PutComplianceItems_402657898,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutInventory_402657911 = ref object of OpenApiRestCall_402656044
proc url_PutInventory_402657913(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutInventory_402657912(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657914 = header.getOrDefault("X-Amz-Target")
  valid_402657914 = validateParameter(valid_402657914, JString, required = true, default = newJString(
      "AmazonSSM.PutInventory"))
  if valid_402657914 != nil:
    section.add "X-Amz-Target", valid_402657914
  var valid_402657915 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657915 = validateParameter(valid_402657915, JString,
                                      required = false, default = nil)
  if valid_402657915 != nil:
    section.add "X-Amz-Security-Token", valid_402657915
  var valid_402657916 = header.getOrDefault("X-Amz-Signature")
  valid_402657916 = validateParameter(valid_402657916, JString,
                                      required = false, default = nil)
  if valid_402657916 != nil:
    section.add "X-Amz-Signature", valid_402657916
  var valid_402657917 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657917 = validateParameter(valid_402657917, JString,
                                      required = false, default = nil)
  if valid_402657917 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657917
  var valid_402657918 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657918 = validateParameter(valid_402657918, JString,
                                      required = false, default = nil)
  if valid_402657918 != nil:
    section.add "X-Amz-Algorithm", valid_402657918
  var valid_402657919 = header.getOrDefault("X-Amz-Date")
  valid_402657919 = validateParameter(valid_402657919, JString,
                                      required = false, default = nil)
  if valid_402657919 != nil:
    section.add "X-Amz-Date", valid_402657919
  var valid_402657920 = header.getOrDefault("X-Amz-Credential")
  valid_402657920 = validateParameter(valid_402657920, JString,
                                      required = false, default = nil)
  if valid_402657920 != nil:
    section.add "X-Amz-Credential", valid_402657920
  var valid_402657921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657921 = validateParameter(valid_402657921, JString,
                                      required = false, default = nil)
  if valid_402657921 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657923: Call_PutInventory_402657911; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
                                                                                         ## 
  let valid = call_402657923.validator(path, query, header, formData, body, _)
  let scheme = call_402657923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657923.makeUrl(scheme.get, call_402657923.host, call_402657923.base,
                                   call_402657923.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657923, uri, valid, _)

proc call*(call_402657924: Call_PutInventory_402657911; body: JsonNode): Recallable =
  ## putInventory
  ## Bulk update custom inventory items on one more instance. The request adds an inventory item, if it doesn't already exist, or updates an inventory item, if it does exist.
  ##   
                                                                                                                                                                              ## body: JObject (required)
  var body_402657925 = newJObject()
  if body != nil:
    body_402657925 = body
  result = call_402657924.call(nil, nil, nil, nil, body_402657925)

var putInventory* = Call_PutInventory_402657911(name: "putInventory",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutInventory",
    validator: validate_PutInventory_402657912, base: "/",
    makeUrl: url_PutInventory_402657913, schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutParameter_402657926 = ref object of OpenApiRestCall_402656044
proc url_PutParameter_402657928(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutParameter_402657927(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Add a parameter to the system.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657929 = header.getOrDefault("X-Amz-Target")
  valid_402657929 = validateParameter(valid_402657929, JString, required = true, default = newJString(
      "AmazonSSM.PutParameter"))
  if valid_402657929 != nil:
    section.add "X-Amz-Target", valid_402657929
  var valid_402657930 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657930 = validateParameter(valid_402657930, JString,
                                      required = false, default = nil)
  if valid_402657930 != nil:
    section.add "X-Amz-Security-Token", valid_402657930
  var valid_402657931 = header.getOrDefault("X-Amz-Signature")
  valid_402657931 = validateParameter(valid_402657931, JString,
                                      required = false, default = nil)
  if valid_402657931 != nil:
    section.add "X-Amz-Signature", valid_402657931
  var valid_402657932 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657932 = validateParameter(valid_402657932, JString,
                                      required = false, default = nil)
  if valid_402657932 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657932
  var valid_402657933 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657933 = validateParameter(valid_402657933, JString,
                                      required = false, default = nil)
  if valid_402657933 != nil:
    section.add "X-Amz-Algorithm", valid_402657933
  var valid_402657934 = header.getOrDefault("X-Amz-Date")
  valid_402657934 = validateParameter(valid_402657934, JString,
                                      required = false, default = nil)
  if valid_402657934 != nil:
    section.add "X-Amz-Date", valid_402657934
  var valid_402657935 = header.getOrDefault("X-Amz-Credential")
  valid_402657935 = validateParameter(valid_402657935, JString,
                                      required = false, default = nil)
  if valid_402657935 != nil:
    section.add "X-Amz-Credential", valid_402657935
  var valid_402657936 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657936 = validateParameter(valid_402657936, JString,
                                      required = false, default = nil)
  if valid_402657936 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657936
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657938: Call_PutParameter_402657926; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Add a parameter to the system.
                                                                                         ## 
  let valid = call_402657938.validator(path, query, header, formData, body, _)
  let scheme = call_402657938.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657938.makeUrl(scheme.get, call_402657938.host, call_402657938.base,
                                   call_402657938.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657938, uri, valid, _)

proc call*(call_402657939: Call_PutParameter_402657926; body: JsonNode): Recallable =
  ## putParameter
  ## Add a parameter to the system.
  ##   body: JObject (required)
  var body_402657940 = newJObject()
  if body != nil:
    body_402657940 = body
  result = call_402657939.call(nil, nil, nil, nil, body_402657940)

var putParameter* = Call_PutParameter_402657926(name: "putParameter",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.PutParameter",
    validator: validate_PutParameter_402657927, base: "/",
    makeUrl: url_PutParameter_402657928, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterDefaultPatchBaseline_402657941 = ref object of OpenApiRestCall_402656044
proc url_RegisterDefaultPatchBaseline_402657943(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterDefaultPatchBaseline_402657942(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657944 = header.getOrDefault("X-Amz-Target")
  valid_402657944 = validateParameter(valid_402657944, JString, required = true, default = newJString(
      "AmazonSSM.RegisterDefaultPatchBaseline"))
  if valid_402657944 != nil:
    section.add "X-Amz-Target", valid_402657944
  var valid_402657945 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657945 = validateParameter(valid_402657945, JString,
                                      required = false, default = nil)
  if valid_402657945 != nil:
    section.add "X-Amz-Security-Token", valid_402657945
  var valid_402657946 = header.getOrDefault("X-Amz-Signature")
  valid_402657946 = validateParameter(valid_402657946, JString,
                                      required = false, default = nil)
  if valid_402657946 != nil:
    section.add "X-Amz-Signature", valid_402657946
  var valid_402657947 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657947 = validateParameter(valid_402657947, JString,
                                      required = false, default = nil)
  if valid_402657947 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657947
  var valid_402657948 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657948 = validateParameter(valid_402657948, JString,
                                      required = false, default = nil)
  if valid_402657948 != nil:
    section.add "X-Amz-Algorithm", valid_402657948
  var valid_402657949 = header.getOrDefault("X-Amz-Date")
  valid_402657949 = validateParameter(valid_402657949, JString,
                                      required = false, default = nil)
  if valid_402657949 != nil:
    section.add "X-Amz-Date", valid_402657949
  var valid_402657950 = header.getOrDefault("X-Amz-Credential")
  valid_402657950 = validateParameter(valid_402657950, JString,
                                      required = false, default = nil)
  if valid_402657950 != nil:
    section.add "X-Amz-Credential", valid_402657950
  var valid_402657951 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657951 = validateParameter(valid_402657951, JString,
                                      required = false, default = nil)
  if valid_402657951 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657951
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657953: Call_RegisterDefaultPatchBaseline_402657941;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
                                                                                         ## 
  let valid = call_402657953.validator(path, query, header, formData, body, _)
  let scheme = call_402657953.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657953.makeUrl(scheme.get, call_402657953.host, call_402657953.base,
                                   call_402657953.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657953, uri, valid, _)

proc call*(call_402657954: Call_RegisterDefaultPatchBaseline_402657941;
           body: JsonNode): Recallable =
  ## registerDefaultPatchBaseline
  ## <p>Defines the default patch baseline for the relevant operating system.</p> <p>To reset the AWS predefined patch baseline as the default, specify the full patch baseline ARN as the baseline ID value. For example, for CentOS, specify <code>arn:aws:ssm:us-east-2:733109147000:patchbaseline/pb-0574b43a65ea646ed</code> instead of <code>pb-0574b43a65ea646ed</code>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402657955 = newJObject()
  if body != nil:
    body_402657955 = body
  result = call_402657954.call(nil, nil, nil, nil, body_402657955)

var registerDefaultPatchBaseline* = Call_RegisterDefaultPatchBaseline_402657941(
    name: "registerDefaultPatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterDefaultPatchBaseline",
    validator: validate_RegisterDefaultPatchBaseline_402657942, base: "/",
    makeUrl: url_RegisterDefaultPatchBaseline_402657943,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterPatchBaselineForPatchGroup_402657956 = ref object of OpenApiRestCall_402656044
proc url_RegisterPatchBaselineForPatchGroup_402657958(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterPatchBaselineForPatchGroup_402657957(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Registers a patch baseline for a patch group.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657959 = header.getOrDefault("X-Amz-Target")
  valid_402657959 = validateParameter(valid_402657959, JString, required = true, default = newJString(
      "AmazonSSM.RegisterPatchBaselineForPatchGroup"))
  if valid_402657959 != nil:
    section.add "X-Amz-Target", valid_402657959
  var valid_402657960 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657960 = validateParameter(valid_402657960, JString,
                                      required = false, default = nil)
  if valid_402657960 != nil:
    section.add "X-Amz-Security-Token", valid_402657960
  var valid_402657961 = header.getOrDefault("X-Amz-Signature")
  valid_402657961 = validateParameter(valid_402657961, JString,
                                      required = false, default = nil)
  if valid_402657961 != nil:
    section.add "X-Amz-Signature", valid_402657961
  var valid_402657962 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657962 = validateParameter(valid_402657962, JString,
                                      required = false, default = nil)
  if valid_402657962 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657962
  var valid_402657963 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657963 = validateParameter(valid_402657963, JString,
                                      required = false, default = nil)
  if valid_402657963 != nil:
    section.add "X-Amz-Algorithm", valid_402657963
  var valid_402657964 = header.getOrDefault("X-Amz-Date")
  valid_402657964 = validateParameter(valid_402657964, JString,
                                      required = false, default = nil)
  if valid_402657964 != nil:
    section.add "X-Amz-Date", valid_402657964
  var valid_402657965 = header.getOrDefault("X-Amz-Credential")
  valid_402657965 = validateParameter(valid_402657965, JString,
                                      required = false, default = nil)
  if valid_402657965 != nil:
    section.add "X-Amz-Credential", valid_402657965
  var valid_402657966 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657966 = validateParameter(valid_402657966, JString,
                                      required = false, default = nil)
  if valid_402657966 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657966
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657968: Call_RegisterPatchBaselineForPatchGroup_402657956;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Registers a patch baseline for a patch group.
                                                                                         ## 
  let valid = call_402657968.validator(path, query, header, formData, body, _)
  let scheme = call_402657968.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657968.makeUrl(scheme.get, call_402657968.host, call_402657968.base,
                                   call_402657968.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657968, uri, valid, _)

proc call*(call_402657969: Call_RegisterPatchBaselineForPatchGroup_402657956;
           body: JsonNode): Recallable =
  ## registerPatchBaselineForPatchGroup
  ## Registers a patch baseline for a patch group.
  ##   body: JObject (required)
  var body_402657970 = newJObject()
  if body != nil:
    body_402657970 = body
  result = call_402657969.call(nil, nil, nil, nil, body_402657970)

var registerPatchBaselineForPatchGroup* = Call_RegisterPatchBaselineForPatchGroup_402657956(
    name: "registerPatchBaselineForPatchGroup", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterPatchBaselineForPatchGroup",
    validator: validate_RegisterPatchBaselineForPatchGroup_402657957, base: "/",
    makeUrl: url_RegisterPatchBaselineForPatchGroup_402657958,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTargetWithMaintenanceWindow_402657971 = ref object of OpenApiRestCall_402656044
proc url_RegisterTargetWithMaintenanceWindow_402657973(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterTargetWithMaintenanceWindow_402657972(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Registers a target with a maintenance window.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657974 = header.getOrDefault("X-Amz-Target")
  valid_402657974 = validateParameter(valid_402657974, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTargetWithMaintenanceWindow"))
  if valid_402657974 != nil:
    section.add "X-Amz-Target", valid_402657974
  var valid_402657975 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657975 = validateParameter(valid_402657975, JString,
                                      required = false, default = nil)
  if valid_402657975 != nil:
    section.add "X-Amz-Security-Token", valid_402657975
  var valid_402657976 = header.getOrDefault("X-Amz-Signature")
  valid_402657976 = validateParameter(valid_402657976, JString,
                                      required = false, default = nil)
  if valid_402657976 != nil:
    section.add "X-Amz-Signature", valid_402657976
  var valid_402657977 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657977 = validateParameter(valid_402657977, JString,
                                      required = false, default = nil)
  if valid_402657977 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657977
  var valid_402657978 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657978 = validateParameter(valid_402657978, JString,
                                      required = false, default = nil)
  if valid_402657978 != nil:
    section.add "X-Amz-Algorithm", valid_402657978
  var valid_402657979 = header.getOrDefault("X-Amz-Date")
  valid_402657979 = validateParameter(valid_402657979, JString,
                                      required = false, default = nil)
  if valid_402657979 != nil:
    section.add "X-Amz-Date", valid_402657979
  var valid_402657980 = header.getOrDefault("X-Amz-Credential")
  valid_402657980 = validateParameter(valid_402657980, JString,
                                      required = false, default = nil)
  if valid_402657980 != nil:
    section.add "X-Amz-Credential", valid_402657980
  var valid_402657981 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657981 = validateParameter(valid_402657981, JString,
                                      required = false, default = nil)
  if valid_402657981 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657981
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657983: Call_RegisterTargetWithMaintenanceWindow_402657971;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Registers a target with a maintenance window.
                                                                                         ## 
  let valid = call_402657983.validator(path, query, header, formData, body, _)
  let scheme = call_402657983.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657983.makeUrl(scheme.get, call_402657983.host, call_402657983.base,
                                   call_402657983.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657983, uri, valid, _)

proc call*(call_402657984: Call_RegisterTargetWithMaintenanceWindow_402657971;
           body: JsonNode): Recallable =
  ## registerTargetWithMaintenanceWindow
  ## Registers a target with a maintenance window.
  ##   body: JObject (required)
  var body_402657985 = newJObject()
  if body != nil:
    body_402657985 = body
  result = call_402657984.call(nil, nil, nil, nil, body_402657985)

var registerTargetWithMaintenanceWindow* = Call_RegisterTargetWithMaintenanceWindow_402657971(
    name: "registerTargetWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTargetWithMaintenanceWindow",
    validator: validate_RegisterTargetWithMaintenanceWindow_402657972,
    base: "/", makeUrl: url_RegisterTargetWithMaintenanceWindow_402657973,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RegisterTaskWithMaintenanceWindow_402657986 = ref object of OpenApiRestCall_402656044
proc url_RegisterTaskWithMaintenanceWindow_402657988(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RegisterTaskWithMaintenanceWindow_402657987(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Adds a new task to a maintenance window.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402657989 = header.getOrDefault("X-Amz-Target")
  valid_402657989 = validateParameter(valid_402657989, JString, required = true, default = newJString(
      "AmazonSSM.RegisterTaskWithMaintenanceWindow"))
  if valid_402657989 != nil:
    section.add "X-Amz-Target", valid_402657989
  var valid_402657990 = header.getOrDefault("X-Amz-Security-Token")
  valid_402657990 = validateParameter(valid_402657990, JString,
                                      required = false, default = nil)
  if valid_402657990 != nil:
    section.add "X-Amz-Security-Token", valid_402657990
  var valid_402657991 = header.getOrDefault("X-Amz-Signature")
  valid_402657991 = validateParameter(valid_402657991, JString,
                                      required = false, default = nil)
  if valid_402657991 != nil:
    section.add "X-Amz-Signature", valid_402657991
  var valid_402657992 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402657992 = validateParameter(valid_402657992, JString,
                                      required = false, default = nil)
  if valid_402657992 != nil:
    section.add "X-Amz-Content-Sha256", valid_402657992
  var valid_402657993 = header.getOrDefault("X-Amz-Algorithm")
  valid_402657993 = validateParameter(valid_402657993, JString,
                                      required = false, default = nil)
  if valid_402657993 != nil:
    section.add "X-Amz-Algorithm", valid_402657993
  var valid_402657994 = header.getOrDefault("X-Amz-Date")
  valid_402657994 = validateParameter(valid_402657994, JString,
                                      required = false, default = nil)
  if valid_402657994 != nil:
    section.add "X-Amz-Date", valid_402657994
  var valid_402657995 = header.getOrDefault("X-Amz-Credential")
  valid_402657995 = validateParameter(valid_402657995, JString,
                                      required = false, default = nil)
  if valid_402657995 != nil:
    section.add "X-Amz-Credential", valid_402657995
  var valid_402657996 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402657996 = validateParameter(valid_402657996, JString,
                                      required = false, default = nil)
  if valid_402657996 != nil:
    section.add "X-Amz-SignedHeaders", valid_402657996
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402657998: Call_RegisterTaskWithMaintenanceWindow_402657986;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds a new task to a maintenance window.
                                                                                         ## 
  let valid = call_402657998.validator(path, query, header, formData, body, _)
  let scheme = call_402657998.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402657998.makeUrl(scheme.get, call_402657998.host, call_402657998.base,
                                   call_402657998.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402657998, uri, valid, _)

proc call*(call_402657999: Call_RegisterTaskWithMaintenanceWindow_402657986;
           body: JsonNode): Recallable =
  ## registerTaskWithMaintenanceWindow
  ## Adds a new task to a maintenance window.
  ##   body: JObject (required)
  var body_402658000 = newJObject()
  if body != nil:
    body_402658000 = body
  result = call_402657999.call(nil, nil, nil, nil, body_402658000)

var registerTaskWithMaintenanceWindow* = Call_RegisterTaskWithMaintenanceWindow_402657986(
    name: "registerTaskWithMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RegisterTaskWithMaintenanceWindow",
    validator: validate_RegisterTaskWithMaintenanceWindow_402657987, base: "/",
    makeUrl: url_RegisterTaskWithMaintenanceWindow_402657988,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveTagsFromResource_402658001 = ref object of OpenApiRestCall_402656044
proc url_RemoveTagsFromResource_402658003(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_RemoveTagsFromResource_402658002(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes tag keys from the specified resource.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658004 = header.getOrDefault("X-Amz-Target")
  valid_402658004 = validateParameter(valid_402658004, JString, required = true, default = newJString(
      "AmazonSSM.RemoveTagsFromResource"))
  if valid_402658004 != nil:
    section.add "X-Amz-Target", valid_402658004
  var valid_402658005 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658005 = validateParameter(valid_402658005, JString,
                                      required = false, default = nil)
  if valid_402658005 != nil:
    section.add "X-Amz-Security-Token", valid_402658005
  var valid_402658006 = header.getOrDefault("X-Amz-Signature")
  valid_402658006 = validateParameter(valid_402658006, JString,
                                      required = false, default = nil)
  if valid_402658006 != nil:
    section.add "X-Amz-Signature", valid_402658006
  var valid_402658007 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658007 = validateParameter(valid_402658007, JString,
                                      required = false, default = nil)
  if valid_402658007 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658007
  var valid_402658008 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658008 = validateParameter(valid_402658008, JString,
                                      required = false, default = nil)
  if valid_402658008 != nil:
    section.add "X-Amz-Algorithm", valid_402658008
  var valid_402658009 = header.getOrDefault("X-Amz-Date")
  valid_402658009 = validateParameter(valid_402658009, JString,
                                      required = false, default = nil)
  if valid_402658009 != nil:
    section.add "X-Amz-Date", valid_402658009
  var valid_402658010 = header.getOrDefault("X-Amz-Credential")
  valid_402658010 = validateParameter(valid_402658010, JString,
                                      required = false, default = nil)
  if valid_402658010 != nil:
    section.add "X-Amz-Credential", valid_402658010
  var valid_402658011 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658011 = validateParameter(valid_402658011, JString,
                                      required = false, default = nil)
  if valid_402658011 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658011
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658013: Call_RemoveTagsFromResource_402658001;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes tag keys from the specified resource.
                                                                                         ## 
  let valid = call_402658013.validator(path, query, header, formData, body, _)
  let scheme = call_402658013.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658013.makeUrl(scheme.get, call_402658013.host, call_402658013.base,
                                   call_402658013.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658013, uri, valid, _)

proc call*(call_402658014: Call_RemoveTagsFromResource_402658001; body: JsonNode): Recallable =
  ## removeTagsFromResource
  ## Removes tag keys from the specified resource.
  ##   body: JObject (required)
  var body_402658015 = newJObject()
  if body != nil:
    body_402658015 = body
  result = call_402658014.call(nil, nil, nil, nil, body_402658015)

var removeTagsFromResource* = Call_RemoveTagsFromResource_402658001(
    name: "removeTagsFromResource", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.RemoveTagsFromResource",
    validator: validate_RemoveTagsFromResource_402658002, base: "/",
    makeUrl: url_RemoveTagsFromResource_402658003,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResetServiceSetting_402658016 = ref object of OpenApiRestCall_402656044
proc url_ResetServiceSetting_402658018(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResetServiceSetting_402658017(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658019 = header.getOrDefault("X-Amz-Target")
  valid_402658019 = validateParameter(valid_402658019, JString, required = true, default = newJString(
      "AmazonSSM.ResetServiceSetting"))
  if valid_402658019 != nil:
    section.add "X-Amz-Target", valid_402658019
  var valid_402658020 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658020 = validateParameter(valid_402658020, JString,
                                      required = false, default = nil)
  if valid_402658020 != nil:
    section.add "X-Amz-Security-Token", valid_402658020
  var valid_402658021 = header.getOrDefault("X-Amz-Signature")
  valid_402658021 = validateParameter(valid_402658021, JString,
                                      required = false, default = nil)
  if valid_402658021 != nil:
    section.add "X-Amz-Signature", valid_402658021
  var valid_402658022 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658022 = validateParameter(valid_402658022, JString,
                                      required = false, default = nil)
  if valid_402658022 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658022
  var valid_402658023 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658023 = validateParameter(valid_402658023, JString,
                                      required = false, default = nil)
  if valid_402658023 != nil:
    section.add "X-Amz-Algorithm", valid_402658023
  var valid_402658024 = header.getOrDefault("X-Amz-Date")
  valid_402658024 = validateParameter(valid_402658024, JString,
                                      required = false, default = nil)
  if valid_402658024 != nil:
    section.add "X-Amz-Date", valid_402658024
  var valid_402658025 = header.getOrDefault("X-Amz-Credential")
  valid_402658025 = validateParameter(valid_402658025, JString,
                                      required = false, default = nil)
  if valid_402658025 != nil:
    section.add "X-Amz-Credential", valid_402658025
  var valid_402658026 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658026 = validateParameter(valid_402658026, JString,
                                      required = false, default = nil)
  if valid_402658026 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658026
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658028: Call_ResetServiceSetting_402658016;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
                                                                                         ## 
  let valid = call_402658028.validator(path, query, header, formData, body, _)
  let scheme = call_402658028.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658028.makeUrl(scheme.get, call_402658028.host, call_402658028.base,
                                   call_402658028.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658028, uri, valid, _)

proc call*(call_402658029: Call_ResetServiceSetting_402658016; body: JsonNode): Recallable =
  ## resetServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Use the <a>UpdateServiceSetting</a> API action to change the default setting. </p> <p>Reset the service setting for the account to the default value as provisioned by the AWS service team. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         ## body: JObject (required)
  var body_402658030 = newJObject()
  if body != nil:
    body_402658030 = body
  result = call_402658029.call(nil, nil, nil, nil, body_402658030)

var resetServiceSetting* = Call_ResetServiceSetting_402658016(
    name: "resetServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResetServiceSetting",
    validator: validate_ResetServiceSetting_402658017, base: "/",
    makeUrl: url_ResetServiceSetting_402658018,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ResumeSession_402658031 = ref object of OpenApiRestCall_402656044
proc url_ResumeSession_402658033(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ResumeSession_402658032(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658034 = header.getOrDefault("X-Amz-Target")
  valid_402658034 = validateParameter(valid_402658034, JString, required = true, default = newJString(
      "AmazonSSM.ResumeSession"))
  if valid_402658034 != nil:
    section.add "X-Amz-Target", valid_402658034
  var valid_402658035 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658035 = validateParameter(valid_402658035, JString,
                                      required = false, default = nil)
  if valid_402658035 != nil:
    section.add "X-Amz-Security-Token", valid_402658035
  var valid_402658036 = header.getOrDefault("X-Amz-Signature")
  valid_402658036 = validateParameter(valid_402658036, JString,
                                      required = false, default = nil)
  if valid_402658036 != nil:
    section.add "X-Amz-Signature", valid_402658036
  var valid_402658037 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658037 = validateParameter(valid_402658037, JString,
                                      required = false, default = nil)
  if valid_402658037 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658037
  var valid_402658038 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658038 = validateParameter(valid_402658038, JString,
                                      required = false, default = nil)
  if valid_402658038 != nil:
    section.add "X-Amz-Algorithm", valid_402658038
  var valid_402658039 = header.getOrDefault("X-Amz-Date")
  valid_402658039 = validateParameter(valid_402658039, JString,
                                      required = false, default = nil)
  if valid_402658039 != nil:
    section.add "X-Amz-Date", valid_402658039
  var valid_402658040 = header.getOrDefault("X-Amz-Credential")
  valid_402658040 = validateParameter(valid_402658040, JString,
                                      required = false, default = nil)
  if valid_402658040 != nil:
    section.add "X-Amz-Credential", valid_402658040
  var valid_402658041 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658041 = validateParameter(valid_402658041, JString,
                                      required = false, default = nil)
  if valid_402658041 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658041
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658043: Call_ResumeSession_402658031; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
                                                                                         ## 
  let valid = call_402658043.validator(path, query, header, formData, body, _)
  let scheme = call_402658043.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658043.makeUrl(scheme.get, call_402658043.host, call_402658043.base,
                                   call_402658043.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658043, uri, valid, _)

proc call*(call_402658044: Call_ResumeSession_402658031; body: JsonNode): Recallable =
  ## resumeSession
  ## <p>Reconnects a session to an instance after it has been disconnected. Connections can be resumed for disconnected sessions, but not terminated sessions.</p> <note> <p>This command is primarily for use by client machines to automatically reconnect during intermittent network issues. It is not intended for any other use.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                  ## body: JObject (required)
  var body_402658045 = newJObject()
  if body != nil:
    body_402658045 = body
  result = call_402658044.call(nil, nil, nil, nil, body_402658045)

var resumeSession* = Call_ResumeSession_402658031(name: "resumeSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.ResumeSession",
    validator: validate_ResumeSession_402658032, base: "/",
    makeUrl: url_ResumeSession_402658033, schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendAutomationSignal_402658046 = ref object of OpenApiRestCall_402656044
proc url_SendAutomationSignal_402658048(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendAutomationSignal_402658047(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658049 = header.getOrDefault("X-Amz-Target")
  valid_402658049 = validateParameter(valid_402658049, JString, required = true, default = newJString(
      "AmazonSSM.SendAutomationSignal"))
  if valid_402658049 != nil:
    section.add "X-Amz-Target", valid_402658049
  var valid_402658050 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658050 = validateParameter(valid_402658050, JString,
                                      required = false, default = nil)
  if valid_402658050 != nil:
    section.add "X-Amz-Security-Token", valid_402658050
  var valid_402658051 = header.getOrDefault("X-Amz-Signature")
  valid_402658051 = validateParameter(valid_402658051, JString,
                                      required = false, default = nil)
  if valid_402658051 != nil:
    section.add "X-Amz-Signature", valid_402658051
  var valid_402658052 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658052 = validateParameter(valid_402658052, JString,
                                      required = false, default = nil)
  if valid_402658052 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658052
  var valid_402658053 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658053 = validateParameter(valid_402658053, JString,
                                      required = false, default = nil)
  if valid_402658053 != nil:
    section.add "X-Amz-Algorithm", valid_402658053
  var valid_402658054 = header.getOrDefault("X-Amz-Date")
  valid_402658054 = validateParameter(valid_402658054, JString,
                                      required = false, default = nil)
  if valid_402658054 != nil:
    section.add "X-Amz-Date", valid_402658054
  var valid_402658055 = header.getOrDefault("X-Amz-Credential")
  valid_402658055 = validateParameter(valid_402658055, JString,
                                      required = false, default = nil)
  if valid_402658055 != nil:
    section.add "X-Amz-Credential", valid_402658055
  var valid_402658056 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658056 = validateParameter(valid_402658056, JString,
                                      required = false, default = nil)
  if valid_402658056 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658056
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658058: Call_SendAutomationSignal_402658046;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
                                                                                         ## 
  let valid = call_402658058.validator(path, query, header, formData, body, _)
  let scheme = call_402658058.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658058.makeUrl(scheme.get, call_402658058.host, call_402658058.base,
                                   call_402658058.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658058, uri, valid, _)

proc call*(call_402658059: Call_SendAutomationSignal_402658046; body: JsonNode): Recallable =
  ## sendAutomationSignal
  ## Sends a signal to an Automation execution to change the current behavior or status of the execution. 
  ##   
                                                                                                          ## body: JObject (required)
  var body_402658060 = newJObject()
  if body != nil:
    body_402658060 = body
  result = call_402658059.call(nil, nil, nil, nil, body_402658060)

var sendAutomationSignal* = Call_SendAutomationSignal_402658046(
    name: "sendAutomationSignal", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.SendAutomationSignal",
    validator: validate_SendAutomationSignal_402658047, base: "/",
    makeUrl: url_SendAutomationSignal_402658048,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_SendCommand_402658061 = ref object of OpenApiRestCall_402656044
proc url_SendCommand_402658063(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_SendCommand_402658062(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Runs commands on one or more managed instances.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658064 = header.getOrDefault("X-Amz-Target")
  valid_402658064 = validateParameter(valid_402658064, JString, required = true, default = newJString(
      "AmazonSSM.SendCommand"))
  if valid_402658064 != nil:
    section.add "X-Amz-Target", valid_402658064
  var valid_402658065 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658065 = validateParameter(valid_402658065, JString,
                                      required = false, default = nil)
  if valid_402658065 != nil:
    section.add "X-Amz-Security-Token", valid_402658065
  var valid_402658066 = header.getOrDefault("X-Amz-Signature")
  valid_402658066 = validateParameter(valid_402658066, JString,
                                      required = false, default = nil)
  if valid_402658066 != nil:
    section.add "X-Amz-Signature", valid_402658066
  var valid_402658067 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658067 = validateParameter(valid_402658067, JString,
                                      required = false, default = nil)
  if valid_402658067 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658067
  var valid_402658068 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658068 = validateParameter(valid_402658068, JString,
                                      required = false, default = nil)
  if valid_402658068 != nil:
    section.add "X-Amz-Algorithm", valid_402658068
  var valid_402658069 = header.getOrDefault("X-Amz-Date")
  valid_402658069 = validateParameter(valid_402658069, JString,
                                      required = false, default = nil)
  if valid_402658069 != nil:
    section.add "X-Amz-Date", valid_402658069
  var valid_402658070 = header.getOrDefault("X-Amz-Credential")
  valid_402658070 = validateParameter(valid_402658070, JString,
                                      required = false, default = nil)
  if valid_402658070 != nil:
    section.add "X-Amz-Credential", valid_402658070
  var valid_402658071 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658071 = validateParameter(valid_402658071, JString,
                                      required = false, default = nil)
  if valid_402658071 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658071
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658073: Call_SendCommand_402658061; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Runs commands on one or more managed instances.
                                                                                         ## 
  let valid = call_402658073.validator(path, query, header, formData, body, _)
  let scheme = call_402658073.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658073.makeUrl(scheme.get, call_402658073.host, call_402658073.base,
                                   call_402658073.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658073, uri, valid, _)

proc call*(call_402658074: Call_SendCommand_402658061; body: JsonNode): Recallable =
  ## sendCommand
  ## Runs commands on one or more managed instances.
  ##   body: JObject (required)
  var body_402658075 = newJObject()
  if body != nil:
    body_402658075 = body
  result = call_402658074.call(nil, nil, nil, nil, body_402658075)

var sendCommand* = Call_SendCommand_402658061(name: "sendCommand",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.SendCommand",
    validator: validate_SendCommand_402658062, base: "/",
    makeUrl: url_SendCommand_402658063, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAssociationsOnce_402658076 = ref object of OpenApiRestCall_402656044
proc url_StartAssociationsOnce_402658078(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartAssociationsOnce_402658077(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658079 = header.getOrDefault("X-Amz-Target")
  valid_402658079 = validateParameter(valid_402658079, JString, required = true, default = newJString(
      "AmazonSSM.StartAssociationsOnce"))
  if valid_402658079 != nil:
    section.add "X-Amz-Target", valid_402658079
  var valid_402658080 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658080 = validateParameter(valid_402658080, JString,
                                      required = false, default = nil)
  if valid_402658080 != nil:
    section.add "X-Amz-Security-Token", valid_402658080
  var valid_402658081 = header.getOrDefault("X-Amz-Signature")
  valid_402658081 = validateParameter(valid_402658081, JString,
                                      required = false, default = nil)
  if valid_402658081 != nil:
    section.add "X-Amz-Signature", valid_402658081
  var valid_402658082 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658082 = validateParameter(valid_402658082, JString,
                                      required = false, default = nil)
  if valid_402658082 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658082
  var valid_402658083 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658083 = validateParameter(valid_402658083, JString,
                                      required = false, default = nil)
  if valid_402658083 != nil:
    section.add "X-Amz-Algorithm", valid_402658083
  var valid_402658084 = header.getOrDefault("X-Amz-Date")
  valid_402658084 = validateParameter(valid_402658084, JString,
                                      required = false, default = nil)
  if valid_402658084 != nil:
    section.add "X-Amz-Date", valid_402658084
  var valid_402658085 = header.getOrDefault("X-Amz-Credential")
  valid_402658085 = validateParameter(valid_402658085, JString,
                                      required = false, default = nil)
  if valid_402658085 != nil:
    section.add "X-Amz-Credential", valid_402658085
  var valid_402658086 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658086 = validateParameter(valid_402658086, JString,
                                      required = false, default = nil)
  if valid_402658086 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658086
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658088: Call_StartAssociationsOnce_402658076;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
                                                                                         ## 
  let valid = call_402658088.validator(path, query, header, formData, body, _)
  let scheme = call_402658088.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658088.makeUrl(scheme.get, call_402658088.host, call_402658088.base,
                                   call_402658088.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658088, uri, valid, _)

proc call*(call_402658089: Call_StartAssociationsOnce_402658076; body: JsonNode): Recallable =
  ## startAssociationsOnce
  ## Use this API action to run an association immediately and only one time. This action can be helpful when troubleshooting associations.
  ##   
                                                                                                                                           ## body: JObject (required)
  var body_402658090 = newJObject()
  if body != nil:
    body_402658090 = body
  result = call_402658089.call(nil, nil, nil, nil, body_402658090)

var startAssociationsOnce* = Call_StartAssociationsOnce_402658076(
    name: "startAssociationsOnce", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAssociationsOnce",
    validator: validate_StartAssociationsOnce_402658077, base: "/",
    makeUrl: url_StartAssociationsOnce_402658078,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartAutomationExecution_402658091 = ref object of OpenApiRestCall_402656044
proc url_StartAutomationExecution_402658093(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartAutomationExecution_402658092(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Initiates execution of an Automation document.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658094 = header.getOrDefault("X-Amz-Target")
  valid_402658094 = validateParameter(valid_402658094, JString, required = true, default = newJString(
      "AmazonSSM.StartAutomationExecution"))
  if valid_402658094 != nil:
    section.add "X-Amz-Target", valid_402658094
  var valid_402658095 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658095 = validateParameter(valid_402658095, JString,
                                      required = false, default = nil)
  if valid_402658095 != nil:
    section.add "X-Amz-Security-Token", valid_402658095
  var valid_402658096 = header.getOrDefault("X-Amz-Signature")
  valid_402658096 = validateParameter(valid_402658096, JString,
                                      required = false, default = nil)
  if valid_402658096 != nil:
    section.add "X-Amz-Signature", valid_402658096
  var valid_402658097 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658097 = validateParameter(valid_402658097, JString,
                                      required = false, default = nil)
  if valid_402658097 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658097
  var valid_402658098 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658098 = validateParameter(valid_402658098, JString,
                                      required = false, default = nil)
  if valid_402658098 != nil:
    section.add "X-Amz-Algorithm", valid_402658098
  var valid_402658099 = header.getOrDefault("X-Amz-Date")
  valid_402658099 = validateParameter(valid_402658099, JString,
                                      required = false, default = nil)
  if valid_402658099 != nil:
    section.add "X-Amz-Date", valid_402658099
  var valid_402658100 = header.getOrDefault("X-Amz-Credential")
  valid_402658100 = validateParameter(valid_402658100, JString,
                                      required = false, default = nil)
  if valid_402658100 != nil:
    section.add "X-Amz-Credential", valid_402658100
  var valid_402658101 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658101 = validateParameter(valid_402658101, JString,
                                      required = false, default = nil)
  if valid_402658101 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658101
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658103: Call_StartAutomationExecution_402658091;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Initiates execution of an Automation document.
                                                                                         ## 
  let valid = call_402658103.validator(path, query, header, formData, body, _)
  let scheme = call_402658103.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658103.makeUrl(scheme.get, call_402658103.host, call_402658103.base,
                                   call_402658103.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658103, uri, valid, _)

proc call*(call_402658104: Call_StartAutomationExecution_402658091;
           body: JsonNode): Recallable =
  ## startAutomationExecution
  ## Initiates execution of an Automation document.
  ##   body: JObject (required)
  var body_402658105 = newJObject()
  if body != nil:
    body_402658105 = body
  result = call_402658104.call(nil, nil, nil, nil, body_402658105)

var startAutomationExecution* = Call_StartAutomationExecution_402658091(
    name: "startAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartAutomationExecution",
    validator: validate_StartAutomationExecution_402658092, base: "/",
    makeUrl: url_StartAutomationExecution_402658093,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartSession_402658106 = ref object of OpenApiRestCall_402656044
proc url_StartSession_402658108(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StartSession_402658107(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>AWS Tools for PowerShell usage: Start-SSMSession is not currently supported by AWS Tools for PowerShell on Windows local machines.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658109 = header.getOrDefault("X-Amz-Target")
  valid_402658109 = validateParameter(valid_402658109, JString, required = true, default = newJString(
      "AmazonSSM.StartSession"))
  if valid_402658109 != nil:
    section.add "X-Amz-Target", valid_402658109
  var valid_402658110 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658110 = validateParameter(valid_402658110, JString,
                                      required = false, default = nil)
  if valid_402658110 != nil:
    section.add "X-Amz-Security-Token", valid_402658110
  var valid_402658111 = header.getOrDefault("X-Amz-Signature")
  valid_402658111 = validateParameter(valid_402658111, JString,
                                      required = false, default = nil)
  if valid_402658111 != nil:
    section.add "X-Amz-Signature", valid_402658111
  var valid_402658112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658112 = validateParameter(valid_402658112, JString,
                                      required = false, default = nil)
  if valid_402658112 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658112
  var valid_402658113 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658113 = validateParameter(valid_402658113, JString,
                                      required = false, default = nil)
  if valid_402658113 != nil:
    section.add "X-Amz-Algorithm", valid_402658113
  var valid_402658114 = header.getOrDefault("X-Amz-Date")
  valid_402658114 = validateParameter(valid_402658114, JString,
                                      required = false, default = nil)
  if valid_402658114 != nil:
    section.add "X-Amz-Date", valid_402658114
  var valid_402658115 = header.getOrDefault("X-Amz-Credential")
  valid_402658115 = validateParameter(valid_402658115, JString,
                                      required = false, default = nil)
  if valid_402658115 != nil:
    section.add "X-Amz-Credential", valid_402658115
  var valid_402658116 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658116 = validateParameter(valid_402658116, JString,
                                      required = false, default = nil)
  if valid_402658116 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658118: Call_StartSession_402658106; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>AWS Tools for PowerShell usage: Start-SSMSession is not currently supported by AWS Tools for PowerShell on Windows local machines.</p> </note>
                                                                                         ## 
  let valid = call_402658118.validator(path, query, header, formData, body, _)
  let scheme = call_402658118.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658118.makeUrl(scheme.get, call_402658118.host, call_402658118.base,
                                   call_402658118.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658118, uri, valid, _)

proc call*(call_402658119: Call_StartSession_402658106; body: JsonNode): Recallable =
  ## startSession
  ## <p>Initiates a connection to a target (for example, an instance) for a Session Manager session. Returns a URL and token that can be used to open a WebSocket connection for sending input and receiving outputs.</p> <note> <p>AWS CLI usage: <code>start-session</code> is an interactive command that requires the Session Manager plugin to be installed on the client machine making the call. For information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html"> Install the Session Manager Plugin for the AWS CLI</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>AWS Tools for PowerShell usage: Start-SSMSession is not currently supported by AWS Tools for PowerShell on Windows local machines.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## body: JObject (required)
  var body_402658120 = newJObject()
  if body != nil:
    body_402658120 = body
  result = call_402658119.call(nil, nil, nil, nil, body_402658120)

var startSession* = Call_StartSession_402658106(name: "startSession",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StartSession",
    validator: validate_StartSession_402658107, base: "/",
    makeUrl: url_StartSession_402658108, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopAutomationExecution_402658121 = ref object of OpenApiRestCall_402656044
proc url_StopAutomationExecution_402658123(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_StopAutomationExecution_402658122(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Stop an Automation that is currently running.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658124 = header.getOrDefault("X-Amz-Target")
  valid_402658124 = validateParameter(valid_402658124, JString, required = true, default = newJString(
      "AmazonSSM.StopAutomationExecution"))
  if valid_402658124 != nil:
    section.add "X-Amz-Target", valid_402658124
  var valid_402658125 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658125 = validateParameter(valid_402658125, JString,
                                      required = false, default = nil)
  if valid_402658125 != nil:
    section.add "X-Amz-Security-Token", valid_402658125
  var valid_402658126 = header.getOrDefault("X-Amz-Signature")
  valid_402658126 = validateParameter(valid_402658126, JString,
                                      required = false, default = nil)
  if valid_402658126 != nil:
    section.add "X-Amz-Signature", valid_402658126
  var valid_402658127 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658127 = validateParameter(valid_402658127, JString,
                                      required = false, default = nil)
  if valid_402658127 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658127
  var valid_402658128 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658128 = validateParameter(valid_402658128, JString,
                                      required = false, default = nil)
  if valid_402658128 != nil:
    section.add "X-Amz-Algorithm", valid_402658128
  var valid_402658129 = header.getOrDefault("X-Amz-Date")
  valid_402658129 = validateParameter(valid_402658129, JString,
                                      required = false, default = nil)
  if valid_402658129 != nil:
    section.add "X-Amz-Date", valid_402658129
  var valid_402658130 = header.getOrDefault("X-Amz-Credential")
  valid_402658130 = validateParameter(valid_402658130, JString,
                                      required = false, default = nil)
  if valid_402658130 != nil:
    section.add "X-Amz-Credential", valid_402658130
  var valid_402658131 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658131 = validateParameter(valid_402658131, JString,
                                      required = false, default = nil)
  if valid_402658131 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658131
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658133: Call_StopAutomationExecution_402658121;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stop an Automation that is currently running.
                                                                                         ## 
  let valid = call_402658133.validator(path, query, header, formData, body, _)
  let scheme = call_402658133.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658133.makeUrl(scheme.get, call_402658133.host, call_402658133.base,
                                   call_402658133.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658133, uri, valid, _)

proc call*(call_402658134: Call_StopAutomationExecution_402658121;
           body: JsonNode): Recallable =
  ## stopAutomationExecution
  ## Stop an Automation that is currently running.
  ##   body: JObject (required)
  var body_402658135 = newJObject()
  if body != nil:
    body_402658135 = body
  result = call_402658134.call(nil, nil, nil, nil, body_402658135)

var stopAutomationExecution* = Call_StopAutomationExecution_402658121(
    name: "stopAutomationExecution", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.StopAutomationExecution",
    validator: validate_StopAutomationExecution_402658122, base: "/",
    makeUrl: url_StopAutomationExecution_402658123,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TerminateSession_402658136 = ref object of OpenApiRestCall_402656044
proc url_TerminateSession_402658138(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_TerminateSession_402658137(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658139 = header.getOrDefault("X-Amz-Target")
  valid_402658139 = validateParameter(valid_402658139, JString, required = true, default = newJString(
      "AmazonSSM.TerminateSession"))
  if valid_402658139 != nil:
    section.add "X-Amz-Target", valid_402658139
  var valid_402658140 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658140 = validateParameter(valid_402658140, JString,
                                      required = false, default = nil)
  if valid_402658140 != nil:
    section.add "X-Amz-Security-Token", valid_402658140
  var valid_402658141 = header.getOrDefault("X-Amz-Signature")
  valid_402658141 = validateParameter(valid_402658141, JString,
                                      required = false, default = nil)
  if valid_402658141 != nil:
    section.add "X-Amz-Signature", valid_402658141
  var valid_402658142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658142 = validateParameter(valid_402658142, JString,
                                      required = false, default = nil)
  if valid_402658142 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658142
  var valid_402658143 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658143 = validateParameter(valid_402658143, JString,
                                      required = false, default = nil)
  if valid_402658143 != nil:
    section.add "X-Amz-Algorithm", valid_402658143
  var valid_402658144 = header.getOrDefault("X-Amz-Date")
  valid_402658144 = validateParameter(valid_402658144, JString,
                                      required = false, default = nil)
  if valid_402658144 != nil:
    section.add "X-Amz-Date", valid_402658144
  var valid_402658145 = header.getOrDefault("X-Amz-Credential")
  valid_402658145 = validateParameter(valid_402658145, JString,
                                      required = false, default = nil)
  if valid_402658145 != nil:
    section.add "X-Amz-Credential", valid_402658145
  var valid_402658146 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658146 = validateParameter(valid_402658146, JString,
                                      required = false, default = nil)
  if valid_402658146 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658146
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658148: Call_TerminateSession_402658136;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
                                                                                         ## 
  let valid = call_402658148.validator(path, query, header, formData, body, _)
  let scheme = call_402658148.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658148.makeUrl(scheme.get, call_402658148.host, call_402658148.base,
                                   call_402658148.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658148, uri, valid, _)

proc call*(call_402658149: Call_TerminateSession_402658136; body: JsonNode): Recallable =
  ## terminateSession
  ## Permanently ends a session and closes the data connection between the Session Manager client and SSM Agent on the instance. A terminated session cannot be resumed.
  ##   
                                                                                                                                                                        ## body: JObject (required)
  var body_402658150 = newJObject()
  if body != nil:
    body_402658150 = body
  result = call_402658149.call(nil, nil, nil, nil, body_402658150)

var terminateSession* = Call_TerminateSession_402658136(
    name: "terminateSession", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.TerminateSession",
    validator: validate_TerminateSession_402658137, base: "/",
    makeUrl: url_TerminateSession_402658138,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociation_402658151 = ref object of OpenApiRestCall_402656044
proc url_UpdateAssociation_402658153(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateAssociation_402658152(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658154 = header.getOrDefault("X-Amz-Target")
  valid_402658154 = validateParameter(valid_402658154, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociation"))
  if valid_402658154 != nil:
    section.add "X-Amz-Target", valid_402658154
  var valid_402658155 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658155 = validateParameter(valid_402658155, JString,
                                      required = false, default = nil)
  if valid_402658155 != nil:
    section.add "X-Amz-Security-Token", valid_402658155
  var valid_402658156 = header.getOrDefault("X-Amz-Signature")
  valid_402658156 = validateParameter(valid_402658156, JString,
                                      required = false, default = nil)
  if valid_402658156 != nil:
    section.add "X-Amz-Signature", valid_402658156
  var valid_402658157 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658157 = validateParameter(valid_402658157, JString,
                                      required = false, default = nil)
  if valid_402658157 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658157
  var valid_402658158 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658158 = validateParameter(valid_402658158, JString,
                                      required = false, default = nil)
  if valid_402658158 != nil:
    section.add "X-Amz-Algorithm", valid_402658158
  var valid_402658159 = header.getOrDefault("X-Amz-Date")
  valid_402658159 = validateParameter(valid_402658159, JString,
                                      required = false, default = nil)
  if valid_402658159 != nil:
    section.add "X-Amz-Date", valid_402658159
  var valid_402658160 = header.getOrDefault("X-Amz-Credential")
  valid_402658160 = validateParameter(valid_402658160, JString,
                                      required = false, default = nil)
  if valid_402658160 != nil:
    section.add "X-Amz-Credential", valid_402658160
  var valid_402658161 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658161 = validateParameter(valid_402658161, JString,
                                      required = false, default = nil)
  if valid_402658161 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658161
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658163: Call_UpdateAssociation_402658151;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
                                                                                         ## 
  let valid = call_402658163.validator(path, query, header, formData, body, _)
  let scheme = call_402658163.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658163.makeUrl(scheme.get, call_402658163.host, call_402658163.base,
                                   call_402658163.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658163, uri, valid, _)

proc call*(call_402658164: Call_UpdateAssociation_402658151; body: JsonNode): Recallable =
  ## updateAssociation
  ## <p>Updates an association. You can update the association name and version, the document version, schedule, parameters, and Amazon S3 output. </p> <p>In order to call this API action, your IAM user account, group, or role must be configured with permission to call the <a>DescribeAssociation</a> API action. If you don't have permission to call DescribeAssociation, then you receive the following error: <code>An error occurred (AccessDeniedException) when calling the UpdateAssociation operation: User: &lt;user_arn&gt; is not authorized to perform: ssm:DescribeAssociation on resource: &lt;resource_arn&gt;</code> </p> <important> <p>When you update an association, the association immediately runs against the specified targets.</p> </important>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 ## body: JObject (required)
  var body_402658165 = newJObject()
  if body != nil:
    body_402658165 = body
  result = call_402658164.call(nil, nil, nil, nil, body_402658165)

var updateAssociation* = Call_UpdateAssociation_402658151(
    name: "updateAssociation", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociation",
    validator: validate_UpdateAssociation_402658152, base: "/",
    makeUrl: url_UpdateAssociation_402658153,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateAssociationStatus_402658166 = ref object of OpenApiRestCall_402656044
proc url_UpdateAssociationStatus_402658168(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateAssociationStatus_402658167(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the status of the Systems Manager document associated with the specified instance.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658169 = header.getOrDefault("X-Amz-Target")
  valid_402658169 = validateParameter(valid_402658169, JString, required = true, default = newJString(
      "AmazonSSM.UpdateAssociationStatus"))
  if valid_402658169 != nil:
    section.add "X-Amz-Target", valid_402658169
  var valid_402658170 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658170 = validateParameter(valid_402658170, JString,
                                      required = false, default = nil)
  if valid_402658170 != nil:
    section.add "X-Amz-Security-Token", valid_402658170
  var valid_402658171 = header.getOrDefault("X-Amz-Signature")
  valid_402658171 = validateParameter(valid_402658171, JString,
                                      required = false, default = nil)
  if valid_402658171 != nil:
    section.add "X-Amz-Signature", valid_402658171
  var valid_402658172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658172 = validateParameter(valid_402658172, JString,
                                      required = false, default = nil)
  if valid_402658172 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658172
  var valid_402658173 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658173 = validateParameter(valid_402658173, JString,
                                      required = false, default = nil)
  if valid_402658173 != nil:
    section.add "X-Amz-Algorithm", valid_402658173
  var valid_402658174 = header.getOrDefault("X-Amz-Date")
  valid_402658174 = validateParameter(valid_402658174, JString,
                                      required = false, default = nil)
  if valid_402658174 != nil:
    section.add "X-Amz-Date", valid_402658174
  var valid_402658175 = header.getOrDefault("X-Amz-Credential")
  valid_402658175 = validateParameter(valid_402658175, JString,
                                      required = false, default = nil)
  if valid_402658175 != nil:
    section.add "X-Amz-Credential", valid_402658175
  var valid_402658176 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658176 = validateParameter(valid_402658176, JString,
                                      required = false, default = nil)
  if valid_402658176 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658176
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658178: Call_UpdateAssociationStatus_402658166;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the status of the Systems Manager document associated with the specified instance.
                                                                                         ## 
  let valid = call_402658178.validator(path, query, header, formData, body, _)
  let scheme = call_402658178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658178.makeUrl(scheme.get, call_402658178.host, call_402658178.base,
                                   call_402658178.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658178, uri, valid, _)

proc call*(call_402658179: Call_UpdateAssociationStatus_402658166;
           body: JsonNode): Recallable =
  ## updateAssociationStatus
  ## Updates the status of the Systems Manager document associated with the specified instance.
  ##   
                                                                                               ## body: JObject (required)
  var body_402658180 = newJObject()
  if body != nil:
    body_402658180 = body
  result = call_402658179.call(nil, nil, nil, nil, body_402658180)

var updateAssociationStatus* = Call_UpdateAssociationStatus_402658166(
    name: "updateAssociationStatus", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateAssociationStatus",
    validator: validate_UpdateAssociationStatus_402658167, base: "/",
    makeUrl: url_UpdateAssociationStatus_402658168,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocument_402658181 = ref object of OpenApiRestCall_402656044
proc url_UpdateDocument_402658183(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDocument_402658182(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates one or more values for an SSM document.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658184 = header.getOrDefault("X-Amz-Target")
  valid_402658184 = validateParameter(valid_402658184, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocument"))
  if valid_402658184 != nil:
    section.add "X-Amz-Target", valid_402658184
  var valid_402658185 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658185 = validateParameter(valid_402658185, JString,
                                      required = false, default = nil)
  if valid_402658185 != nil:
    section.add "X-Amz-Security-Token", valid_402658185
  var valid_402658186 = header.getOrDefault("X-Amz-Signature")
  valid_402658186 = validateParameter(valid_402658186, JString,
                                      required = false, default = nil)
  if valid_402658186 != nil:
    section.add "X-Amz-Signature", valid_402658186
  var valid_402658187 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658187 = validateParameter(valid_402658187, JString,
                                      required = false, default = nil)
  if valid_402658187 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658187
  var valid_402658188 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658188 = validateParameter(valid_402658188, JString,
                                      required = false, default = nil)
  if valid_402658188 != nil:
    section.add "X-Amz-Algorithm", valid_402658188
  var valid_402658189 = header.getOrDefault("X-Amz-Date")
  valid_402658189 = validateParameter(valid_402658189, JString,
                                      required = false, default = nil)
  if valid_402658189 != nil:
    section.add "X-Amz-Date", valid_402658189
  var valid_402658190 = header.getOrDefault("X-Amz-Credential")
  valid_402658190 = validateParameter(valid_402658190, JString,
                                      required = false, default = nil)
  if valid_402658190 != nil:
    section.add "X-Amz-Credential", valid_402658190
  var valid_402658191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658191 = validateParameter(valid_402658191, JString,
                                      required = false, default = nil)
  if valid_402658191 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658193: Call_UpdateDocument_402658181; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates one or more values for an SSM document.
                                                                                         ## 
  let valid = call_402658193.validator(path, query, header, formData, body, _)
  let scheme = call_402658193.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658193.makeUrl(scheme.get, call_402658193.host, call_402658193.base,
                                   call_402658193.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658193, uri, valid, _)

proc call*(call_402658194: Call_UpdateDocument_402658181; body: JsonNode): Recallable =
  ## updateDocument
  ## Updates one or more values for an SSM document.
  ##   body: JObject (required)
  var body_402658195 = newJObject()
  if body != nil:
    body_402658195 = body
  result = call_402658194.call(nil, nil, nil, nil, body_402658195)

var updateDocument* = Call_UpdateDocument_402658181(name: "updateDocument",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocument",
    validator: validate_UpdateDocument_402658182, base: "/",
    makeUrl: url_UpdateDocument_402658183, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateDocumentDefaultVersion_402658196 = ref object of OpenApiRestCall_402656044
proc url_UpdateDocumentDefaultVersion_402658198(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateDocumentDefaultVersion_402658197(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Set the default version of a document. 
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658199 = header.getOrDefault("X-Amz-Target")
  valid_402658199 = validateParameter(valid_402658199, JString, required = true, default = newJString(
      "AmazonSSM.UpdateDocumentDefaultVersion"))
  if valid_402658199 != nil:
    section.add "X-Amz-Target", valid_402658199
  var valid_402658200 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658200 = validateParameter(valid_402658200, JString,
                                      required = false, default = nil)
  if valid_402658200 != nil:
    section.add "X-Amz-Security-Token", valid_402658200
  var valid_402658201 = header.getOrDefault("X-Amz-Signature")
  valid_402658201 = validateParameter(valid_402658201, JString,
                                      required = false, default = nil)
  if valid_402658201 != nil:
    section.add "X-Amz-Signature", valid_402658201
  var valid_402658202 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658202 = validateParameter(valid_402658202, JString,
                                      required = false, default = nil)
  if valid_402658202 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658202
  var valid_402658203 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658203 = validateParameter(valid_402658203, JString,
                                      required = false, default = nil)
  if valid_402658203 != nil:
    section.add "X-Amz-Algorithm", valid_402658203
  var valid_402658204 = header.getOrDefault("X-Amz-Date")
  valid_402658204 = validateParameter(valid_402658204, JString,
                                      required = false, default = nil)
  if valid_402658204 != nil:
    section.add "X-Amz-Date", valid_402658204
  var valid_402658205 = header.getOrDefault("X-Amz-Credential")
  valid_402658205 = validateParameter(valid_402658205, JString,
                                      required = false, default = nil)
  if valid_402658205 != nil:
    section.add "X-Amz-Credential", valid_402658205
  var valid_402658206 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658206 = validateParameter(valid_402658206, JString,
                                      required = false, default = nil)
  if valid_402658206 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658206
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658208: Call_UpdateDocumentDefaultVersion_402658196;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Set the default version of a document. 
                                                                                         ## 
  let valid = call_402658208.validator(path, query, header, formData, body, _)
  let scheme = call_402658208.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658208.makeUrl(scheme.get, call_402658208.host, call_402658208.base,
                                   call_402658208.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658208, uri, valid, _)

proc call*(call_402658209: Call_UpdateDocumentDefaultVersion_402658196;
           body: JsonNode): Recallable =
  ## updateDocumentDefaultVersion
  ## Set the default version of a document. 
  ##   body: JObject (required)
  var body_402658210 = newJObject()
  if body != nil:
    body_402658210 = body
  result = call_402658209.call(nil, nil, nil, nil, body_402658210)

var updateDocumentDefaultVersion* = Call_UpdateDocumentDefaultVersion_402658196(
    name: "updateDocumentDefaultVersion", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateDocumentDefaultVersion",
    validator: validate_UpdateDocumentDefaultVersion_402658197, base: "/",
    makeUrl: url_UpdateDocumentDefaultVersion_402658198,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindow_402658211 = ref object of OpenApiRestCall_402656044
proc url_UpdateMaintenanceWindow_402658213(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMaintenanceWindow_402658212(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Updates an existing maintenance window. Only specified parameters are modified.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658214 = header.getOrDefault("X-Amz-Target")
  valid_402658214 = validateParameter(valid_402658214, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindow"))
  if valid_402658214 != nil:
    section.add "X-Amz-Target", valid_402658214
  var valid_402658215 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658215 = validateParameter(valid_402658215, JString,
                                      required = false, default = nil)
  if valid_402658215 != nil:
    section.add "X-Amz-Security-Token", valid_402658215
  var valid_402658216 = header.getOrDefault("X-Amz-Signature")
  valid_402658216 = validateParameter(valid_402658216, JString,
                                      required = false, default = nil)
  if valid_402658216 != nil:
    section.add "X-Amz-Signature", valid_402658216
  var valid_402658217 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658217 = validateParameter(valid_402658217, JString,
                                      required = false, default = nil)
  if valid_402658217 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658217
  var valid_402658218 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658218 = validateParameter(valid_402658218, JString,
                                      required = false, default = nil)
  if valid_402658218 != nil:
    section.add "X-Amz-Algorithm", valid_402658218
  var valid_402658219 = header.getOrDefault("X-Amz-Date")
  valid_402658219 = validateParameter(valid_402658219, JString,
                                      required = false, default = nil)
  if valid_402658219 != nil:
    section.add "X-Amz-Date", valid_402658219
  var valid_402658220 = header.getOrDefault("X-Amz-Credential")
  valid_402658220 = validateParameter(valid_402658220, JString,
                                      required = false, default = nil)
  if valid_402658220 != nil:
    section.add "X-Amz-Credential", valid_402658220
  var valid_402658221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658221 = validateParameter(valid_402658221, JString,
                                      required = false, default = nil)
  if valid_402658221 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658223: Call_UpdateMaintenanceWindow_402658211;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Updates an existing maintenance window. Only specified parameters are modified.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
                                                                                         ## 
  let valid = call_402658223.validator(path, query, header, formData, body, _)
  let scheme = call_402658223.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658223.makeUrl(scheme.get, call_402658223.host, call_402658223.base,
                                   call_402658223.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658223, uri, valid, _)

proc call*(call_402658224: Call_UpdateMaintenanceWindow_402658211;
           body: JsonNode): Recallable =
  ## updateMaintenanceWindow
  ## <p>Updates an existing maintenance window. Only specified parameters are modified.</p> <note> <p>The value you specify for <code>Duration</code> determines the specific end time for the maintenance window based on the time it begins. No maintenance window tasks are permitted to start after the resulting endtime minus the number of hours you specify for <code>Cutoff</code>. For example, if the maintenance window starts at 3 PM, the duration is three hours, and the value you specify for <code>Cutoff</code> is one hour, no maintenance window tasks can start after 5 PM.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                             ## body: JObject (required)
  var body_402658225 = newJObject()
  if body != nil:
    body_402658225 = body
  result = call_402658224.call(nil, nil, nil, nil, body_402658225)

var updateMaintenanceWindow* = Call_UpdateMaintenanceWindow_402658211(
    name: "updateMaintenanceWindow", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindow",
    validator: validate_UpdateMaintenanceWindow_402658212, base: "/",
    makeUrl: url_UpdateMaintenanceWindow_402658213,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTarget_402658226 = ref object of OpenApiRestCall_402656044
proc url_UpdateMaintenanceWindowTarget_402658228(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMaintenanceWindowTarget_402658227(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658229 = header.getOrDefault("X-Amz-Target")
  valid_402658229 = validateParameter(valid_402658229, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTarget"))
  if valid_402658229 != nil:
    section.add "X-Amz-Target", valid_402658229
  var valid_402658230 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658230 = validateParameter(valid_402658230, JString,
                                      required = false, default = nil)
  if valid_402658230 != nil:
    section.add "X-Amz-Security-Token", valid_402658230
  var valid_402658231 = header.getOrDefault("X-Amz-Signature")
  valid_402658231 = validateParameter(valid_402658231, JString,
                                      required = false, default = nil)
  if valid_402658231 != nil:
    section.add "X-Amz-Signature", valid_402658231
  var valid_402658232 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658232 = validateParameter(valid_402658232, JString,
                                      required = false, default = nil)
  if valid_402658232 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658232
  var valid_402658233 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658233 = validateParameter(valid_402658233, JString,
                                      required = false, default = nil)
  if valid_402658233 != nil:
    section.add "X-Amz-Algorithm", valid_402658233
  var valid_402658234 = header.getOrDefault("X-Amz-Date")
  valid_402658234 = validateParameter(valid_402658234, JString,
                                      required = false, default = nil)
  if valid_402658234 != nil:
    section.add "X-Amz-Date", valid_402658234
  var valid_402658235 = header.getOrDefault("X-Amz-Credential")
  valid_402658235 = validateParameter(valid_402658235, JString,
                                      required = false, default = nil)
  if valid_402658235 != nil:
    section.add "X-Amz-Credential", valid_402658235
  var valid_402658236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658236 = validateParameter(valid_402658236, JString,
                                      required = false, default = nil)
  if valid_402658236 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658238: Call_UpdateMaintenanceWindowTarget_402658226;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
                                                                                         ## 
  let valid = call_402658238.validator(path, query, header, formData, body, _)
  let scheme = call_402658238.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658238.makeUrl(scheme.get, call_402658238.host, call_402658238.base,
                                   call_402658238.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658238, uri, valid, _)

proc call*(call_402658239: Call_UpdateMaintenanceWindowTarget_402658226;
           body: JsonNode): Recallable =
  ## updateMaintenanceWindowTarget
  ## <p>Modifies the target of an existing maintenance window. You can change the following:</p> <ul> <li> <p>Name</p> </li> <li> <p>Description</p> </li> <li> <p>Owner</p> </li> <li> <p>IDs for an ID target</p> </li> <li> <p>Tags for a Tag target</p> </li> <li> <p>From any supported tag type to another. The three supported tag types are ID target, Tag target, and resource group. For more information, see <a>Target</a>.</p> </li> </ul> <note> <p>If a parameter is null, then the corresponding field is not modified.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## body: JObject (required)
  var body_402658240 = newJObject()
  if body != nil:
    body_402658240 = body
  result = call_402658239.call(nil, nil, nil, nil, body_402658240)

var updateMaintenanceWindowTarget* = Call_UpdateMaintenanceWindowTarget_402658226(
    name: "updateMaintenanceWindowTarget", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTarget",
    validator: validate_UpdateMaintenanceWindowTarget_402658227, base: "/",
    makeUrl: url_UpdateMaintenanceWindowTarget_402658228,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMaintenanceWindowTask_402658241 = ref object of OpenApiRestCall_402656044
proc url_UpdateMaintenanceWindowTask_402658243(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateMaintenanceWindowTask_402658242(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658244 = header.getOrDefault("X-Amz-Target")
  valid_402658244 = validateParameter(valid_402658244, JString, required = true, default = newJString(
      "AmazonSSM.UpdateMaintenanceWindowTask"))
  if valid_402658244 != nil:
    section.add "X-Amz-Target", valid_402658244
  var valid_402658245 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658245 = validateParameter(valid_402658245, JString,
                                      required = false, default = nil)
  if valid_402658245 != nil:
    section.add "X-Amz-Security-Token", valid_402658245
  var valid_402658246 = header.getOrDefault("X-Amz-Signature")
  valid_402658246 = validateParameter(valid_402658246, JString,
                                      required = false, default = nil)
  if valid_402658246 != nil:
    section.add "X-Amz-Signature", valid_402658246
  var valid_402658247 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658247 = validateParameter(valid_402658247, JString,
                                      required = false, default = nil)
  if valid_402658247 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658247
  var valid_402658248 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658248 = validateParameter(valid_402658248, JString,
                                      required = false, default = nil)
  if valid_402658248 != nil:
    section.add "X-Amz-Algorithm", valid_402658248
  var valid_402658249 = header.getOrDefault("X-Amz-Date")
  valid_402658249 = validateParameter(valid_402658249, JString,
                                      required = false, default = nil)
  if valid_402658249 != nil:
    section.add "X-Amz-Date", valid_402658249
  var valid_402658250 = header.getOrDefault("X-Amz-Credential")
  valid_402658250 = validateParameter(valid_402658250, JString,
                                      required = false, default = nil)
  if valid_402658250 != nil:
    section.add "X-Amz-Credential", valid_402658250
  var valid_402658251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658251 = validateParameter(valid_402658251, JString,
                                      required = false, default = nil)
  if valid_402658251 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658253: Call_UpdateMaintenanceWindowTask_402658241;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
                                                                                         ## 
  let valid = call_402658253.validator(path, query, header, formData, body, _)
  let scheme = call_402658253.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658253.makeUrl(scheme.get, call_402658253.host, call_402658253.base,
                                   call_402658253.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658253, uri, valid, _)

proc call*(call_402658254: Call_UpdateMaintenanceWindowTask_402658241;
           body: JsonNode): Recallable =
  ## updateMaintenanceWindowTask
  ## <p>Modifies a task assigned to a maintenance window. You can't change the task type, but you can change the following values:</p> <ul> <li> <p>TaskARN. For example, you can change a RUN_COMMAND task from AWS-RunPowerShellScript to AWS-RunShellScript.</p> </li> <li> <p>ServiceRoleArn</p> </li> <li> <p>TaskInvocationParameters</p> </li> <li> <p>Priority</p> </li> <li> <p>MaxConcurrency</p> </li> <li> <p>MaxErrors</p> </li> </ul> <p>If a parameter is null, then the corresponding field is not modified. Also, if you set Replace to true, then all fields required by the <a>RegisterTaskWithMaintenanceWindow</a> action are required for this request. Optional fields that aren't specified are set to null.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402658255 = newJObject()
  if body != nil:
    body_402658255 = body
  result = call_402658254.call(nil, nil, nil, nil, body_402658255)

var updateMaintenanceWindowTask* = Call_UpdateMaintenanceWindowTask_402658241(
    name: "updateMaintenanceWindowTask", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateMaintenanceWindowTask",
    validator: validate_UpdateMaintenanceWindowTask_402658242, base: "/",
    makeUrl: url_UpdateMaintenanceWindowTask_402658243,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateManagedInstanceRole_402658256 = ref object of OpenApiRestCall_402656044
proc url_UpdateManagedInstanceRole_402658258(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateManagedInstanceRole_402658257(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658259 = header.getOrDefault("X-Amz-Target")
  valid_402658259 = validateParameter(valid_402658259, JString, required = true, default = newJString(
      "AmazonSSM.UpdateManagedInstanceRole"))
  if valid_402658259 != nil:
    section.add "X-Amz-Target", valid_402658259
  var valid_402658260 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658260 = validateParameter(valid_402658260, JString,
                                      required = false, default = nil)
  if valid_402658260 != nil:
    section.add "X-Amz-Security-Token", valid_402658260
  var valid_402658261 = header.getOrDefault("X-Amz-Signature")
  valid_402658261 = validateParameter(valid_402658261, JString,
                                      required = false, default = nil)
  if valid_402658261 != nil:
    section.add "X-Amz-Signature", valid_402658261
  var valid_402658262 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658262 = validateParameter(valid_402658262, JString,
                                      required = false, default = nil)
  if valid_402658262 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658262
  var valid_402658263 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658263 = validateParameter(valid_402658263, JString,
                                      required = false, default = nil)
  if valid_402658263 != nil:
    section.add "X-Amz-Algorithm", valid_402658263
  var valid_402658264 = header.getOrDefault("X-Amz-Date")
  valid_402658264 = validateParameter(valid_402658264, JString,
                                      required = false, default = nil)
  if valid_402658264 != nil:
    section.add "X-Amz-Date", valid_402658264
  var valid_402658265 = header.getOrDefault("X-Amz-Credential")
  valid_402658265 = validateParameter(valid_402658265, JString,
                                      required = false, default = nil)
  if valid_402658265 != nil:
    section.add "X-Amz-Credential", valid_402658265
  var valid_402658266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658266 = validateParameter(valid_402658266, JString,
                                      required = false, default = nil)
  if valid_402658266 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658266
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658268: Call_UpdateManagedInstanceRole_402658256;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
                                                                                         ## 
  let valid = call_402658268.validator(path, query, header, formData, body, _)
  let scheme = call_402658268.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658268.makeUrl(scheme.get, call_402658268.host, call_402658268.base,
                                   call_402658268.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658268, uri, valid, _)

proc call*(call_402658269: Call_UpdateManagedInstanceRole_402658256;
           body: JsonNode): Recallable =
  ## updateManagedInstanceRole
  ## Assigns or changes an Amazon Identity and Access Management (IAM) role for the managed instance.
  ##   
                                                                                                     ## body: JObject (required)
  var body_402658270 = newJObject()
  if body != nil:
    body_402658270 = body
  result = call_402658269.call(nil, nil, nil, nil, body_402658270)

var updateManagedInstanceRole* = Call_UpdateManagedInstanceRole_402658256(
    name: "updateManagedInstanceRole", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateManagedInstanceRole",
    validator: validate_UpdateManagedInstanceRole_402658257, base: "/",
    makeUrl: url_UpdateManagedInstanceRole_402658258,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOpsItem_402658271 = ref object of OpenApiRestCall_402656044
proc url_UpdateOpsItem_402658273(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateOpsItem_402658272(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658274 = header.getOrDefault("X-Amz-Target")
  valid_402658274 = validateParameter(valid_402658274, JString, required = true, default = newJString(
      "AmazonSSM.UpdateOpsItem"))
  if valid_402658274 != nil:
    section.add "X-Amz-Target", valid_402658274
  var valid_402658275 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658275 = validateParameter(valid_402658275, JString,
                                      required = false, default = nil)
  if valid_402658275 != nil:
    section.add "X-Amz-Security-Token", valid_402658275
  var valid_402658276 = header.getOrDefault("X-Amz-Signature")
  valid_402658276 = validateParameter(valid_402658276, JString,
                                      required = false, default = nil)
  if valid_402658276 != nil:
    section.add "X-Amz-Signature", valid_402658276
  var valid_402658277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658277 = validateParameter(valid_402658277, JString,
                                      required = false, default = nil)
  if valid_402658277 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658277
  var valid_402658278 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658278 = validateParameter(valid_402658278, JString,
                                      required = false, default = nil)
  if valid_402658278 != nil:
    section.add "X-Amz-Algorithm", valid_402658278
  var valid_402658279 = header.getOrDefault("X-Amz-Date")
  valid_402658279 = validateParameter(valid_402658279, JString,
                                      required = false, default = nil)
  if valid_402658279 != nil:
    section.add "X-Amz-Date", valid_402658279
  var valid_402658280 = header.getOrDefault("X-Amz-Credential")
  valid_402658280 = validateParameter(valid_402658280, JString,
                                      required = false, default = nil)
  if valid_402658280 != nil:
    section.add "X-Amz-Credential", valid_402658280
  var valid_402658281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658281 = validateParameter(valid_402658281, JString,
                                      required = false, default = nil)
  if valid_402658281 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658283: Call_UpdateOpsItem_402658271; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
                                                                                         ## 
  let valid = call_402658283.validator(path, query, header, formData, body, _)
  let scheme = call_402658283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658283.makeUrl(scheme.get, call_402658283.host, call_402658283.base,
                                   call_402658283.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658283, uri, valid, _)

proc call*(call_402658284: Call_UpdateOpsItem_402658271; body: JsonNode): Recallable =
  ## updateOpsItem
  ## <p>Edit or change an OpsItem. You must have permission in AWS Identity and Access Management (IAM) to update an OpsItem. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter-getting-started.html">Getting Started with OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>.</p> <p>Operations engineers and IT professionals use OpsCenter to view, investigate, and remediate operational issues impacting the performance and health of their AWS resources. For more information, see <a href="http://docs.aws.amazon.com/systems-manager/latest/userguide/OpsCenter.html">AWS Systems Manager OpsCenter</a> in the <i>AWS Systems Manager User Guide</i>. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402658285 = newJObject()
  if body != nil:
    body_402658285 = body
  result = call_402658284.call(nil, nil, nil, nil, body_402658285)

var updateOpsItem* = Call_UpdateOpsItem_402658271(name: "updateOpsItem",
    meth: HttpMethod.HttpPost, host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateOpsItem",
    validator: validate_UpdateOpsItem_402658272, base: "/",
    makeUrl: url_UpdateOpsItem_402658273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdatePatchBaseline_402658286 = ref object of OpenApiRestCall_402656044
proc url_UpdatePatchBaseline_402658288(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdatePatchBaseline_402658287(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658289 = header.getOrDefault("X-Amz-Target")
  valid_402658289 = validateParameter(valid_402658289, JString, required = true, default = newJString(
      "AmazonSSM.UpdatePatchBaseline"))
  if valid_402658289 != nil:
    section.add "X-Amz-Target", valid_402658289
  var valid_402658290 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658290 = validateParameter(valid_402658290, JString,
                                      required = false, default = nil)
  if valid_402658290 != nil:
    section.add "X-Amz-Security-Token", valid_402658290
  var valid_402658291 = header.getOrDefault("X-Amz-Signature")
  valid_402658291 = validateParameter(valid_402658291, JString,
                                      required = false, default = nil)
  if valid_402658291 != nil:
    section.add "X-Amz-Signature", valid_402658291
  var valid_402658292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658292 = validateParameter(valid_402658292, JString,
                                      required = false, default = nil)
  if valid_402658292 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658292
  var valid_402658293 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658293 = validateParameter(valid_402658293, JString,
                                      required = false, default = nil)
  if valid_402658293 != nil:
    section.add "X-Amz-Algorithm", valid_402658293
  var valid_402658294 = header.getOrDefault("X-Amz-Date")
  valid_402658294 = validateParameter(valid_402658294, JString,
                                      required = false, default = nil)
  if valid_402658294 != nil:
    section.add "X-Amz-Date", valid_402658294
  var valid_402658295 = header.getOrDefault("X-Amz-Credential")
  valid_402658295 = validateParameter(valid_402658295, JString,
                                      required = false, default = nil)
  if valid_402658295 != nil:
    section.add "X-Amz-Credential", valid_402658295
  var valid_402658296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658296 = validateParameter(valid_402658296, JString,
                                      required = false, default = nil)
  if valid_402658296 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658296
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658298: Call_UpdatePatchBaseline_402658286;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
                                                                                         ## 
  let valid = call_402658298.validator(path, query, header, formData, body, _)
  let scheme = call_402658298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658298.makeUrl(scheme.get, call_402658298.host, call_402658298.base,
                                   call_402658298.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658298, uri, valid, _)

proc call*(call_402658299: Call_UpdatePatchBaseline_402658286; body: JsonNode): Recallable =
  ## updatePatchBaseline
  ## <p>Modifies an existing patch baseline. Fields not specified in the request are left unchanged.</p> <note> <p>For information about valid key and value pairs in <code>PatchFilters</code> for each supported operating system type, see <a href="http://docs.aws.amazon.com/systems-manager/latest/APIReference/API_PatchFilter.html">PatchFilter</a>.</p> </note>
  ##   
                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  var body_402658300 = newJObject()
  if body != nil:
    body_402658300 = body
  result = call_402658299.call(nil, nil, nil, nil, body_402658300)

var updatePatchBaseline* = Call_UpdatePatchBaseline_402658286(
    name: "updatePatchBaseline", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdatePatchBaseline",
    validator: validate_UpdatePatchBaseline_402658287, base: "/",
    makeUrl: url_UpdatePatchBaseline_402658288,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateResourceDataSync_402658301 = ref object of OpenApiRestCall_402656044
proc url_UpdateResourceDataSync_402658303(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateResourceDataSync_402658302(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Update a resource data sync. After you create a resource data sync for a Region, you can't change the account options for that sync. For example, if you create a sync in the us-east-2 (Ohio) Region and you choose the Include only the current account option, you can't edit that sync later and choose the Include all accounts from my AWS Organizations configuration option. Instead, you must delete the first resource data sync, and create a new one.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658304 = header.getOrDefault("X-Amz-Target")
  valid_402658304 = validateParameter(valid_402658304, JString, required = true, default = newJString(
      "AmazonSSM.UpdateResourceDataSync"))
  if valid_402658304 != nil:
    section.add "X-Amz-Target", valid_402658304
  var valid_402658305 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658305 = validateParameter(valid_402658305, JString,
                                      required = false, default = nil)
  if valid_402658305 != nil:
    section.add "X-Amz-Security-Token", valid_402658305
  var valid_402658306 = header.getOrDefault("X-Amz-Signature")
  valid_402658306 = validateParameter(valid_402658306, JString,
                                      required = false, default = nil)
  if valid_402658306 != nil:
    section.add "X-Amz-Signature", valid_402658306
  var valid_402658307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658307 = validateParameter(valid_402658307, JString,
                                      required = false, default = nil)
  if valid_402658307 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658307
  var valid_402658308 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658308 = validateParameter(valid_402658308, JString,
                                      required = false, default = nil)
  if valid_402658308 != nil:
    section.add "X-Amz-Algorithm", valid_402658308
  var valid_402658309 = header.getOrDefault("X-Amz-Date")
  valid_402658309 = validateParameter(valid_402658309, JString,
                                      required = false, default = nil)
  if valid_402658309 != nil:
    section.add "X-Amz-Date", valid_402658309
  var valid_402658310 = header.getOrDefault("X-Amz-Credential")
  valid_402658310 = validateParameter(valid_402658310, JString,
                                      required = false, default = nil)
  if valid_402658310 != nil:
    section.add "X-Amz-Credential", valid_402658310
  var valid_402658311 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658311 = validateParameter(valid_402658311, JString,
                                      required = false, default = nil)
  if valid_402658311 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658313: Call_UpdateResourceDataSync_402658301;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update a resource data sync. After you create a resource data sync for a Region, you can't change the account options for that sync. For example, if you create a sync in the us-east-2 (Ohio) Region and you choose the Include only the current account option, you can't edit that sync later and choose the Include all accounts from my AWS Organizations configuration option. Instead, you must delete the first resource data sync, and create a new one.
                                                                                         ## 
  let valid = call_402658313.validator(path, query, header, formData, body, _)
  let scheme = call_402658313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658313.makeUrl(scheme.get, call_402658313.host, call_402658313.base,
                                   call_402658313.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658313, uri, valid, _)

proc call*(call_402658314: Call_UpdateResourceDataSync_402658301; body: JsonNode): Recallable =
  ## updateResourceDataSync
  ## Update a resource data sync. After you create a resource data sync for a Region, you can't change the account options for that sync. For example, if you create a sync in the us-east-2 (Ohio) Region and you choose the Include only the current account option, you can't edit that sync later and choose the Include all accounts from my AWS Organizations configuration option. Instead, you must delete the first resource data sync, and create a new one.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402658315 = newJObject()
  if body != nil:
    body_402658315 = body
  result = call_402658314.call(nil, nil, nil, nil, body_402658315)

var updateResourceDataSync* = Call_UpdateResourceDataSync_402658301(
    name: "updateResourceDataSync", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateResourceDataSync",
    validator: validate_UpdateResourceDataSync_402658302, base: "/",
    makeUrl: url_UpdateResourceDataSync_402658303,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateServiceSetting_402658316 = ref object of OpenApiRestCall_402656044
proc url_UpdateServiceSetting_402658318(protocol: Scheme; host: string;
                                        base: string; route: string;
                                        path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateServiceSetting_402658317(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Target: JString (required)
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402658319 = header.getOrDefault("X-Amz-Target")
  valid_402658319 = validateParameter(valid_402658319, JString, required = true, default = newJString(
      "AmazonSSM.UpdateServiceSetting"))
  if valid_402658319 != nil:
    section.add "X-Amz-Target", valid_402658319
  var valid_402658320 = header.getOrDefault("X-Amz-Security-Token")
  valid_402658320 = validateParameter(valid_402658320, JString,
                                      required = false, default = nil)
  if valid_402658320 != nil:
    section.add "X-Amz-Security-Token", valid_402658320
  var valid_402658321 = header.getOrDefault("X-Amz-Signature")
  valid_402658321 = validateParameter(valid_402658321, JString,
                                      required = false, default = nil)
  if valid_402658321 != nil:
    section.add "X-Amz-Signature", valid_402658321
  var valid_402658322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402658322 = validateParameter(valid_402658322, JString,
                                      required = false, default = nil)
  if valid_402658322 != nil:
    section.add "X-Amz-Content-Sha256", valid_402658322
  var valid_402658323 = header.getOrDefault("X-Amz-Algorithm")
  valid_402658323 = validateParameter(valid_402658323, JString,
                                      required = false, default = nil)
  if valid_402658323 != nil:
    section.add "X-Amz-Algorithm", valid_402658323
  var valid_402658324 = header.getOrDefault("X-Amz-Date")
  valid_402658324 = validateParameter(valid_402658324, JString,
                                      required = false, default = nil)
  if valid_402658324 != nil:
    section.add "X-Amz-Date", valid_402658324
  var valid_402658325 = header.getOrDefault("X-Amz-Credential")
  valid_402658325 = validateParameter(valid_402658325, JString,
                                      required = false, default = nil)
  if valid_402658325 != nil:
    section.add "X-Amz-Credential", valid_402658325
  var valid_402658326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402658326 = validateParameter(valid_402658326, JString,
                                      required = false, default = nil)
  if valid_402658326 != nil:
    section.add "X-Amz-SignedHeaders", valid_402658326
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  if `==`(_, ""): assert body != nil, "body argument is necessary"
  if `==`(_, ""):
    section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_402658328: Call_UpdateServiceSetting_402658316;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
                                                                                         ## 
  let valid = call_402658328.validator(path, query, header, formData, body, _)
  let scheme = call_402658328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402658328.makeUrl(scheme.get, call_402658328.host, call_402658328.base,
                                   call_402658328.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402658328, uri, valid, _)

proc call*(call_402658329: Call_UpdateServiceSetting_402658316; body: JsonNode): Recallable =
  ## updateServiceSetting
  ## <p> <code>ServiceSetting</code> is an account-level setting for an AWS service. This setting defines how a user interacts with or uses a service or a feature of a service. For example, if an AWS service charges money to the account based on feature or service usage, then the AWS service team might create a default setting of "false". This means the user can't use this feature unless they change the setting to "true" and intentionally opt in for a paid feature.</p> <p>Services map a <code>SettingId</code> object to a setting value. AWS services teams define the default value for a <code>SettingId</code>. You can't create a new <code>SettingId</code>, but you can overwrite the default value if you have the <code>ssm:UpdateServiceSetting</code> permission for the setting. Use the <a>GetServiceSetting</a> API action to view the current value. Or, use the <a>ResetServiceSetting</a> to change the value back to the original value defined by the AWS service team.</p> <p>Update the service setting for the account. </p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402658330 = newJObject()
  if body != nil:
    body_402658330 = body
  result = call_402658329.call(nil, nil, nil, nil, body_402658330)

var updateServiceSetting* = Call_UpdateServiceSetting_402658316(
    name: "updateServiceSetting", meth: HttpMethod.HttpPost,
    host: "ssm.amazonaws.com",
    route: "/#X-Amz-Target=AmazonSSM.UpdateServiceSetting",
    validator: validate_UpdateServiceSetting_402658317, base: "/",
    makeUrl: url_UpdateServiceSetting_402658318,
    schemes: {Scheme.Https, Scheme.Http})
export
  rest

type
  EnvKind = enum
    BakeIntoBinary = "Baking $1 into the binary",
    FetchFromEnv = "Fetch $1 from the environment"
template sloppyConst(via: EnvKind; name: untyped): untyped =
  import
    macros

  const
    name {.strdefine.}: string = case via
    of BakeIntoBinary:
      getEnv(astToStr(name), "")
    of FetchFromEnv:
      ""
  static :
    let msg = block:
      if name == "":
        "Missing $1 in the environment"
      else:
        $via
    warning msg % [astToStr(name)]

sloppyConst FetchFromEnv, AWS_ACCESS_KEY_ID
sloppyConst FetchFromEnv, AWS_SECRET_ACCESS_KEY
sloppyConst BakeIntoBinary, AWS_REGION
sloppyConst FetchFromEnv, AWS_ACCOUNT_ID
type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token",
    ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode;
              algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", AWS_ACCESS_KEY_ID)
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", AWS_SECRET_ACCESS_KEY)
    region = os.getEnv("AWS_REGION", AWS_REGION)
  assert secret != "", "need $AWS_SECRET_ACCESS_KEY in environment"
  assert access != "", "need $AWS_ACCESS_KEY_ID in environment"
  assert region != "", "need $AWS_REGION in environment"
  var
    normal: PathNormal
    url = normalizeUrl(recall.url, query, normalize = normal)
    scheme = parseEnum[Scheme](url.scheme)
  assert scheme in awsServers, "unknown scheme `" & $scheme & "`"
  assert region in awsServers[scheme], "unknown region `" & region & "`"
  url.hostname = awsServers[scheme][region]
  case awsServiceName.toLowerAscii
  of "s3":
    normal = PathNormal.S3
  else:
    normal = PathNormal.Default
  recall.headers["Host"] = url.hostname
  recall.headers["X-Amz-Date"] = date
  recall.headers[$ContentSha256] = hash(recall.body, SHA256)
  let
    scope = credentialScope(region = region, service = awsServiceName,
                            date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers,
                               recall.body, normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date,
                                   region = region, service = awsServiceName,
                                   sts, digest = algo)
  var auth = $algo & " "
  auth &= "Credential=" & access / scope & ", "
  auth &= "SignedHeaders=" & recall.headers.signedHeaders & ", "
  auth &= "Signature=" & signature
  recall.headers["Authorization"] = auth
  recall.headers.del "Host"
  recall.url = $url

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body = ""): Recallable {.
    base.} =
  ## the hook is a terrible earworm
  var
    headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
    text = body
  if text.len == 0 and "body" in input:
    text = input.getOrDefault("body").getStr
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  else:
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}