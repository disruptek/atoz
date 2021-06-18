
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS X-Ray
## version: 2016-04-12
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS X-Ray provides APIs for managing debug traces and retrieving service maps and other data created by processing those traces.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/xray/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "xray.ap-northeast-1.amazonaws.com", "ap-southeast-1": "xray.ap-southeast-1.amazonaws.com",
                               "us-west-2": "xray.us-west-2.amazonaws.com",
                               "eu-west-2": "xray.eu-west-2.amazonaws.com", "ap-northeast-3": "xray.ap-northeast-3.amazonaws.com", "eu-central-1": "xray.eu-central-1.amazonaws.com",
                               "us-east-2": "xray.us-east-2.amazonaws.com",
                               "us-east-1": "xray.us-east-1.amazonaws.com", "cn-northwest-1": "xray.cn-northwest-1.amazonaws.com.cn",
                               "ap-south-1": "xray.ap-south-1.amazonaws.com",
                               "eu-north-1": "xray.eu-north-1.amazonaws.com", "ap-northeast-2": "xray.ap-northeast-2.amazonaws.com",
                               "us-west-1": "xray.us-west-1.amazonaws.com", "us-gov-east-1": "xray.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "xray.eu-west-3.amazonaws.com", "cn-north-1": "xray.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "xray.sa-east-1.amazonaws.com",
                               "eu-west-1": "xray.eu-west-1.amazonaws.com", "us-gov-west-1": "xray.us-gov-west-1.amazonaws.com", "ap-southeast-2": "xray.ap-southeast-2.amazonaws.com", "ca-central-1": "xray.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "xray.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "xray.ap-southeast-1.amazonaws.com",
      "us-west-2": "xray.us-west-2.amazonaws.com",
      "eu-west-2": "xray.eu-west-2.amazonaws.com",
      "ap-northeast-3": "xray.ap-northeast-3.amazonaws.com",
      "eu-central-1": "xray.eu-central-1.amazonaws.com",
      "us-east-2": "xray.us-east-2.amazonaws.com",
      "us-east-1": "xray.us-east-1.amazonaws.com",
      "cn-northwest-1": "xray.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "xray.ap-south-1.amazonaws.com",
      "eu-north-1": "xray.eu-north-1.amazonaws.com",
      "ap-northeast-2": "xray.ap-northeast-2.amazonaws.com",
      "us-west-1": "xray.us-west-1.amazonaws.com",
      "us-gov-east-1": "xray.us-gov-east-1.amazonaws.com",
      "eu-west-3": "xray.eu-west-3.amazonaws.com",
      "cn-north-1": "xray.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "xray.sa-east-1.amazonaws.com",
      "eu-west-1": "xray.eu-west-1.amazonaws.com",
      "us-gov-west-1": "xray.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "xray.ap-southeast-2.amazonaws.com",
      "ca-central-1": "xray.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "xray"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_BatchGetTraces_402656294 = ref object of OpenApiRestCall_402656044
proc url_BatchGetTraces_402656296(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_BatchGetTraces_402656295(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a list of traces specified by ID. Each trace is a collection of segment documents that originates from a single request. Use <code>GetTraceSummaries</code> to get a list of trace IDs.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
                                  ##            : Pagination token
  section = newJObject()
  var valid_402656378 = query.getOrDefault("NextToken")
  valid_402656378 = validateParameter(valid_402656378, JString,
                                      required = false, default = nil)
  if valid_402656378 != nil:
    section.add "NextToken", valid_402656378
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656379 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656379 = validateParameter(valid_402656379, JString,
                                      required = false, default = nil)
  if valid_402656379 != nil:
    section.add "X-Amz-Security-Token", valid_402656379
  var valid_402656380 = header.getOrDefault("X-Amz-Signature")
  valid_402656380 = validateParameter(valid_402656380, JString,
                                      required = false, default = nil)
  if valid_402656380 != nil:
    section.add "X-Amz-Signature", valid_402656380
  var valid_402656381 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656381 = validateParameter(valid_402656381, JString,
                                      required = false, default = nil)
  if valid_402656381 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656381
  var valid_402656382 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656382 = validateParameter(valid_402656382, JString,
                                      required = false, default = nil)
  if valid_402656382 != nil:
    section.add "X-Amz-Algorithm", valid_402656382
  var valid_402656383 = header.getOrDefault("X-Amz-Date")
  valid_402656383 = validateParameter(valid_402656383, JString,
                                      required = false, default = nil)
  if valid_402656383 != nil:
    section.add "X-Amz-Date", valid_402656383
  var valid_402656384 = header.getOrDefault("X-Amz-Credential")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Credential", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656385
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

proc call*(call_402656400: Call_BatchGetTraces_402656294; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a list of traces specified by ID. Each trace is a collection of segment documents that originates from a single request. Use <code>GetTraceSummaries</code> to get a list of trace IDs.
                                                                                         ## 
  let valid = call_402656400.validator(path, query, header, formData, body, _)
  let scheme = call_402656400.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656400.makeUrl(scheme.get, call_402656400.host, call_402656400.base,
                                   call_402656400.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656400, uri, valid, _)

proc call*(call_402656449: Call_BatchGetTraces_402656294; body: JsonNode;
           NextToken: string = ""): Recallable =
  ## batchGetTraces
  ## Retrieves a list of traces specified by ID. Each trace is a collection of segment documents that originates from a single request. Use <code>GetTraceSummaries</code> to get a list of trace IDs.
  ##   
                                                                                                                                                                                                      ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                 ## NextToken: string
                                                                                                                                                                                                                                 ##            
                                                                                                                                                                                                                                 ## : 
                                                                                                                                                                                                                                 ## Pagination 
                                                                                                                                                                                                                                 ## token
  var query_402656450 = newJObject()
  var body_402656452 = newJObject()
  if body != nil:
    body_402656452 = body
  add(query_402656450, "NextToken", newJString(NextToken))
  result = call_402656449.call(nil, query_402656450, nil, nil, body_402656452)

var batchGetTraces* = Call_BatchGetTraces_402656294(name: "batchGetTraces",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com", route: "/Traces",
    validator: validate_BatchGetTraces_402656295, base: "/",
    makeUrl: url_BatchGetTraces_402656296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateGroup_402656478 = ref object of OpenApiRestCall_402656044
proc url_CreateGroup_402656480(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateGroup_402656479(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a group resource with a name and a filter expression. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656481 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656481 = validateParameter(valid_402656481, JString,
                                      required = false, default = nil)
  if valid_402656481 != nil:
    section.add "X-Amz-Security-Token", valid_402656481
  var valid_402656482 = header.getOrDefault("X-Amz-Signature")
  valid_402656482 = validateParameter(valid_402656482, JString,
                                      required = false, default = nil)
  if valid_402656482 != nil:
    section.add "X-Amz-Signature", valid_402656482
  var valid_402656483 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656483 = validateParameter(valid_402656483, JString,
                                      required = false, default = nil)
  if valid_402656483 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656483
  var valid_402656484 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656484 = validateParameter(valid_402656484, JString,
                                      required = false, default = nil)
  if valid_402656484 != nil:
    section.add "X-Amz-Algorithm", valid_402656484
  var valid_402656485 = header.getOrDefault("X-Amz-Date")
  valid_402656485 = validateParameter(valid_402656485, JString,
                                      required = false, default = nil)
  if valid_402656485 != nil:
    section.add "X-Amz-Date", valid_402656485
  var valid_402656486 = header.getOrDefault("X-Amz-Credential")
  valid_402656486 = validateParameter(valid_402656486, JString,
                                      required = false, default = nil)
  if valid_402656486 != nil:
    section.add "X-Amz-Credential", valid_402656486
  var valid_402656487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656487
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

proc call*(call_402656489: Call_CreateGroup_402656478; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a group resource with a name and a filter expression. 
                                                                                         ## 
  let valid = call_402656489.validator(path, query, header, formData, body, _)
  let scheme = call_402656489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656489.makeUrl(scheme.get, call_402656489.host, call_402656489.base,
                                   call_402656489.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656489, uri, valid, _)

proc call*(call_402656490: Call_CreateGroup_402656478; body: JsonNode): Recallable =
  ## createGroup
  ## Creates a group resource with a name and a filter expression. 
  ##   body: JObject (required)
  var body_402656491 = newJObject()
  if body != nil:
    body_402656491 = body
  result = call_402656490.call(nil, nil, nil, nil, body_402656491)

var createGroup* = Call_CreateGroup_402656478(name: "createGroup",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com",
    route: "/CreateGroup", validator: validate_CreateGroup_402656479, base: "/",
    makeUrl: url_CreateGroup_402656480, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateSamplingRule_402656492 = ref object of OpenApiRestCall_402656044
proc url_CreateSamplingRule_402656494(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateSamplingRule_402656493(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a rule to control sampling behavior for instrumented applications. Services retrieve rules with <a>GetSamplingRules</a>, and evaluate each rule in ascending order of <i>priority</i> for each request. If a rule matches, the service records a trace, borrowing it from the reservoir size. After 10 seconds, the service reports back to X-Ray with <a>GetSamplingTargets</a> to get updated versions of each in-use rule. The updated rule contains a trace quota that the service can use instead of borrowing from the reservoir.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656495 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Security-Token", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-Signature")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-Signature", valid_402656496
  var valid_402656497 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656497 = validateParameter(valid_402656497, JString,
                                      required = false, default = nil)
  if valid_402656497 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656497
  var valid_402656498 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656498 = validateParameter(valid_402656498, JString,
                                      required = false, default = nil)
  if valid_402656498 != nil:
    section.add "X-Amz-Algorithm", valid_402656498
  var valid_402656499 = header.getOrDefault("X-Amz-Date")
  valid_402656499 = validateParameter(valid_402656499, JString,
                                      required = false, default = nil)
  if valid_402656499 != nil:
    section.add "X-Amz-Date", valid_402656499
  var valid_402656500 = header.getOrDefault("X-Amz-Credential")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Credential", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656501
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

proc call*(call_402656503: Call_CreateSamplingRule_402656492;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a rule to control sampling behavior for instrumented applications. Services retrieve rules with <a>GetSamplingRules</a>, and evaluate each rule in ascending order of <i>priority</i> for each request. If a rule matches, the service records a trace, borrowing it from the reservoir size. After 10 seconds, the service reports back to X-Ray with <a>GetSamplingTargets</a> to get updated versions of each in-use rule. The updated rule contains a trace quota that the service can use instead of borrowing from the reservoir.
                                                                                         ## 
  let valid = call_402656503.validator(path, query, header, formData, body, _)
  let scheme = call_402656503.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656503.makeUrl(scheme.get, call_402656503.host, call_402656503.base,
                                   call_402656503.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656503, uri, valid, _)

proc call*(call_402656504: Call_CreateSamplingRule_402656492; body: JsonNode): Recallable =
  ## createSamplingRule
  ## Creates a rule to control sampling behavior for instrumented applications. Services retrieve rules with <a>GetSamplingRules</a>, and evaluate each rule in ascending order of <i>priority</i> for each request. If a rule matches, the service records a trace, borrowing it from the reservoir size. After 10 seconds, the service reports back to X-Ray with <a>GetSamplingTargets</a> to get updated versions of each in-use rule. The updated rule contains a trace quota that the service can use instead of borrowing from the reservoir.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  var body_402656505 = newJObject()
  if body != nil:
    body_402656505 = body
  result = call_402656504.call(nil, nil, nil, nil, body_402656505)

var createSamplingRule* = Call_CreateSamplingRule_402656492(
    name: "createSamplingRule", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/CreateSamplingRule",
    validator: validate_CreateSamplingRule_402656493, base: "/",
    makeUrl: url_CreateSamplingRule_402656494,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteGroup_402656506 = ref object of OpenApiRestCall_402656044
proc url_DeleteGroup_402656508(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteGroup_402656507(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a group resource.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656509 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-Security-Token", valid_402656509
  var valid_402656510 = header.getOrDefault("X-Amz-Signature")
  valid_402656510 = validateParameter(valid_402656510, JString,
                                      required = false, default = nil)
  if valid_402656510 != nil:
    section.add "X-Amz-Signature", valid_402656510
  var valid_402656511 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656511 = validateParameter(valid_402656511, JString,
                                      required = false, default = nil)
  if valid_402656511 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656511
  var valid_402656512 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656512 = validateParameter(valid_402656512, JString,
                                      required = false, default = nil)
  if valid_402656512 != nil:
    section.add "X-Amz-Algorithm", valid_402656512
  var valid_402656513 = header.getOrDefault("X-Amz-Date")
  valid_402656513 = validateParameter(valid_402656513, JString,
                                      required = false, default = nil)
  if valid_402656513 != nil:
    section.add "X-Amz-Date", valid_402656513
  var valid_402656514 = header.getOrDefault("X-Amz-Credential")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Credential", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656515
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

proc call*(call_402656517: Call_DeleteGroup_402656506; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a group resource.
                                                                                         ## 
  let valid = call_402656517.validator(path, query, header, formData, body, _)
  let scheme = call_402656517.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656517.makeUrl(scheme.get, call_402656517.host, call_402656517.base,
                                   call_402656517.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656517, uri, valid, _)

proc call*(call_402656518: Call_DeleteGroup_402656506; body: JsonNode): Recallable =
  ## deleteGroup
  ## Deletes a group resource.
  ##   body: JObject (required)
  var body_402656519 = newJObject()
  if body != nil:
    body_402656519 = body
  result = call_402656518.call(nil, nil, nil, nil, body_402656519)

var deleteGroup* = Call_DeleteGroup_402656506(name: "deleteGroup",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com",
    route: "/DeleteGroup", validator: validate_DeleteGroup_402656507, base: "/",
    makeUrl: url_DeleteGroup_402656508, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSamplingRule_402656520 = ref object of OpenApiRestCall_402656044
proc url_DeleteSamplingRule_402656522(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_DeleteSamplingRule_402656521(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a sampling rule.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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

proc call*(call_402656531: Call_DeleteSamplingRule_402656520;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a sampling rule.
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

proc call*(call_402656532: Call_DeleteSamplingRule_402656520; body: JsonNode): Recallable =
  ## deleteSamplingRule
  ## Deletes a sampling rule.
  ##   body: JObject (required)
  var body_402656533 = newJObject()
  if body != nil:
    body_402656533 = body
  result = call_402656532.call(nil, nil, nil, nil, body_402656533)

var deleteSamplingRule* = Call_DeleteSamplingRule_402656520(
    name: "deleteSamplingRule", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/DeleteSamplingRule",
    validator: validate_DeleteSamplingRule_402656521, base: "/",
    makeUrl: url_DeleteSamplingRule_402656522,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetEncryptionConfig_402656534 = ref object of OpenApiRestCall_402656044
proc url_GetEncryptionConfig_402656536(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetEncryptionConfig_402656535(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves the current encryption configuration for X-Ray data.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656537 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Security-Token", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-Signature")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-Signature", valid_402656538
  var valid_402656539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656539 = validateParameter(valid_402656539, JString,
                                      required = false, default = nil)
  if valid_402656539 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656539
  var valid_402656540 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656540 = validateParameter(valid_402656540, JString,
                                      required = false, default = nil)
  if valid_402656540 != nil:
    section.add "X-Amz-Algorithm", valid_402656540
  var valid_402656541 = header.getOrDefault("X-Amz-Date")
  valid_402656541 = validateParameter(valid_402656541, JString,
                                      required = false, default = nil)
  if valid_402656541 != nil:
    section.add "X-Amz-Date", valid_402656541
  var valid_402656542 = header.getOrDefault("X-Amz-Credential")
  valid_402656542 = validateParameter(valid_402656542, JString,
                                      required = false, default = nil)
  if valid_402656542 != nil:
    section.add "X-Amz-Credential", valid_402656542
  var valid_402656543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656543
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656544: Call_GetEncryptionConfig_402656534;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves the current encryption configuration for X-Ray data.
                                                                                         ## 
  let valid = call_402656544.validator(path, query, header, formData, body, _)
  let scheme = call_402656544.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656544.makeUrl(scheme.get, call_402656544.host, call_402656544.base,
                                   call_402656544.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656544, uri, valid, _)

proc call*(call_402656545: Call_GetEncryptionConfig_402656534): Recallable =
  ## getEncryptionConfig
  ## Retrieves the current encryption configuration for X-Ray data.
  result = call_402656545.call(nil, nil, nil, nil, nil)

var getEncryptionConfig* = Call_GetEncryptionConfig_402656534(
    name: "getEncryptionConfig", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/EncryptionConfig",
    validator: validate_GetEncryptionConfig_402656535, base: "/",
    makeUrl: url_GetEncryptionConfig_402656536,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroup_402656546 = ref object of OpenApiRestCall_402656044
proc url_GetGroup_402656548(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGroup_402656547(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves group resource details.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656549 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Security-Token", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Signature")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Signature", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-Algorithm", valid_402656552
  var valid_402656553 = header.getOrDefault("X-Amz-Date")
  valid_402656553 = validateParameter(valid_402656553, JString,
                                      required = false, default = nil)
  if valid_402656553 != nil:
    section.add "X-Amz-Date", valid_402656553
  var valid_402656554 = header.getOrDefault("X-Amz-Credential")
  valid_402656554 = validateParameter(valid_402656554, JString,
                                      required = false, default = nil)
  if valid_402656554 != nil:
    section.add "X-Amz-Credential", valid_402656554
  var valid_402656555 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656555 = validateParameter(valid_402656555, JString,
                                      required = false, default = nil)
  if valid_402656555 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656555
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

proc call*(call_402656557: Call_GetGroup_402656546; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves group resource details.
                                                                                         ## 
  let valid = call_402656557.validator(path, query, header, formData, body, _)
  let scheme = call_402656557.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656557.makeUrl(scheme.get, call_402656557.host, call_402656557.base,
                                   call_402656557.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656557, uri, valid, _)

proc call*(call_402656558: Call_GetGroup_402656546; body: JsonNode): Recallable =
  ## getGroup
  ## Retrieves group resource details.
  ##   body: JObject (required)
  var body_402656559 = newJObject()
  if body != nil:
    body_402656559 = body
  result = call_402656558.call(nil, nil, nil, nil, body_402656559)

var getGroup* = Call_GetGroup_402656546(name: "getGroup",
                                        meth: HttpMethod.HttpPost,
                                        host: "xray.amazonaws.com",
                                        route: "/GetGroup",
                                        validator: validate_GetGroup_402656547,
                                        base: "/", makeUrl: url_GetGroup_402656548,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetGroups_402656560 = ref object of OpenApiRestCall_402656044
proc url_GetGroups_402656562(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetGroups_402656561(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves all active group details.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
                                  ##            : Pagination token
  section = newJObject()
  var valid_402656563 = query.getOrDefault("NextToken")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "NextToken", valid_402656563
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656564 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Security-Token", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-Signature")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Signature", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Algorithm", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Date")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Date", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Credential")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Credential", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656570
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

proc call*(call_402656572: Call_GetGroups_402656560; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves all active group details.
                                                                                         ## 
  let valid = call_402656572.validator(path, query, header, formData, body, _)
  let scheme = call_402656572.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656572.makeUrl(scheme.get, call_402656572.host, call_402656572.base,
                                   call_402656572.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656572, uri, valid, _)

proc call*(call_402656573: Call_GetGroups_402656560; body: JsonNode;
           NextToken: string = ""): Recallable =
  ## getGroups
  ## Retrieves all active group details.
  ##   body: JObject (required)
  ##   NextToken: string
                               ##            : Pagination token
  var query_402656574 = newJObject()
  var body_402656575 = newJObject()
  if body != nil:
    body_402656575 = body
  add(query_402656574, "NextToken", newJString(NextToken))
  result = call_402656573.call(nil, query_402656574, nil, nil, body_402656575)

var getGroups* = Call_GetGroups_402656560(name: "getGroups",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com", route: "/Groups",
    validator: validate_GetGroups_402656561, base: "/", makeUrl: url_GetGroups_402656562,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSamplingRules_402656576 = ref object of OpenApiRestCall_402656044
proc url_GetSamplingRules_402656578(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSamplingRules_402656577(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves all sampling rules.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
                                  ##            : Pagination token
  section = newJObject()
  var valid_402656579 = query.getOrDefault("NextToken")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "NextToken", valid_402656579
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656580 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Security-Token", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Signature")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Signature", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Algorithm", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Date")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Date", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-Credential")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-Credential", valid_402656585
  var valid_402656586 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656586 = validateParameter(valid_402656586, JString,
                                      required = false, default = nil)
  if valid_402656586 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656586
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

proc call*(call_402656588: Call_GetSamplingRules_402656576;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves all sampling rules.
                                                                                         ## 
  let valid = call_402656588.validator(path, query, header, formData, body, _)
  let scheme = call_402656588.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656588.makeUrl(scheme.get, call_402656588.host, call_402656588.base,
                                   call_402656588.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656588, uri, valid, _)

proc call*(call_402656589: Call_GetSamplingRules_402656576; body: JsonNode;
           NextToken: string = ""): Recallable =
  ## getSamplingRules
  ## Retrieves all sampling rules.
  ##   body: JObject (required)
  ##   NextToken: string
                               ##            : Pagination token
  var query_402656590 = newJObject()
  var body_402656591 = newJObject()
  if body != nil:
    body_402656591 = body
  add(query_402656590, "NextToken", newJString(NextToken))
  result = call_402656589.call(nil, query_402656590, nil, nil, body_402656591)

var getSamplingRules* = Call_GetSamplingRules_402656576(
    name: "getSamplingRules", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/GetSamplingRules",
    validator: validate_GetSamplingRules_402656577, base: "/",
    makeUrl: url_GetSamplingRules_402656578,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSamplingStatisticSummaries_402656592 = ref object of OpenApiRestCall_402656044
proc url_GetSamplingStatisticSummaries_402656594(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSamplingStatisticSummaries_402656593(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Retrieves information about recent sampling results for all sampling rules.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
                                  ##            : Pagination token
  section = newJObject()
  var valid_402656595 = query.getOrDefault("NextToken")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "NextToken", valid_402656595
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656596 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Security-Token", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-Signature")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Signature", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-Algorithm", valid_402656599
  var valid_402656600 = header.getOrDefault("X-Amz-Date")
  valid_402656600 = validateParameter(valid_402656600, JString,
                                      required = false, default = nil)
  if valid_402656600 != nil:
    section.add "X-Amz-Date", valid_402656600
  var valid_402656601 = header.getOrDefault("X-Amz-Credential")
  valid_402656601 = validateParameter(valid_402656601, JString,
                                      required = false, default = nil)
  if valid_402656601 != nil:
    section.add "X-Amz-Credential", valid_402656601
  var valid_402656602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656602 = validateParameter(valid_402656602, JString,
                                      required = false, default = nil)
  if valid_402656602 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656602
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

proc call*(call_402656604: Call_GetSamplingStatisticSummaries_402656592;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves information about recent sampling results for all sampling rules.
                                                                                         ## 
  let valid = call_402656604.validator(path, query, header, formData, body, _)
  let scheme = call_402656604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656604.makeUrl(scheme.get, call_402656604.host, call_402656604.base,
                                   call_402656604.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656604, uri, valid, _)

proc call*(call_402656605: Call_GetSamplingStatisticSummaries_402656592;
           body: JsonNode; NextToken: string = ""): Recallable =
  ## getSamplingStatisticSummaries
  ## Retrieves information about recent sampling results for all sampling rules.
  ##   
                                                                                ## body: JObject (required)
  ##   
                                                                                                           ## NextToken: string
                                                                                                           ##            
                                                                                                           ## : 
                                                                                                           ## Pagination 
                                                                                                           ## token
  var query_402656606 = newJObject()
  var body_402656607 = newJObject()
  if body != nil:
    body_402656607 = body
  add(query_402656606, "NextToken", newJString(NextToken))
  result = call_402656605.call(nil, query_402656606, nil, nil, body_402656607)

var getSamplingStatisticSummaries* = Call_GetSamplingStatisticSummaries_402656592(
    name: "getSamplingStatisticSummaries", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/SamplingStatisticSummaries",
    validator: validate_GetSamplingStatisticSummaries_402656593, base: "/",
    makeUrl: url_GetSamplingStatisticSummaries_402656594,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetSamplingTargets_402656608 = ref object of OpenApiRestCall_402656044
proc url_GetSamplingTargets_402656610(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetSamplingTargets_402656609(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Requests a sampling quota for rules that the service is using to sample requests. 
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656611 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Security-Token", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Signature")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Signature", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Algorithm", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Date")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Date", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-Credential")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-Credential", valid_402656616
  var valid_402656617 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656617 = validateParameter(valid_402656617, JString,
                                      required = false, default = nil)
  if valid_402656617 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656617
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

proc call*(call_402656619: Call_GetSamplingTargets_402656608;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Requests a sampling quota for rules that the service is using to sample requests. 
                                                                                         ## 
  let valid = call_402656619.validator(path, query, header, formData, body, _)
  let scheme = call_402656619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656619.makeUrl(scheme.get, call_402656619.host, call_402656619.base,
                                   call_402656619.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656619, uri, valid, _)

proc call*(call_402656620: Call_GetSamplingTargets_402656608; body: JsonNode): Recallable =
  ## getSamplingTargets
  ## Requests a sampling quota for rules that the service is using to sample requests. 
  ##   
                                                                                       ## body: JObject (required)
  var body_402656621 = newJObject()
  if body != nil:
    body_402656621 = body
  result = call_402656620.call(nil, nil, nil, nil, body_402656621)

var getSamplingTargets* = Call_GetSamplingTargets_402656608(
    name: "getSamplingTargets", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/SamplingTargets",
    validator: validate_GetSamplingTargets_402656609, base: "/",
    makeUrl: url_GetSamplingTargets_402656610,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetServiceGraph_402656622 = ref object of OpenApiRestCall_402656044
proc url_GetServiceGraph_402656624(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode;
                                   query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetServiceGraph_402656623(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a document that describes services that process incoming requests, and downstream services that they call as a result. Root services process incoming requests and make calls to downstream services. Root services are applications that use the <a href="https://docs.aws.amazon.com/xray/index.html">AWS X-Ray SDK</a>. Downstream services can be other applications, AWS resources, HTTP web APIs, or SQL databases.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
                                  ##            : Pagination token
  section = newJObject()
  var valid_402656625 = query.getOrDefault("NextToken")
  valid_402656625 = validateParameter(valid_402656625, JString,
                                      required = false, default = nil)
  if valid_402656625 != nil:
    section.add "NextToken", valid_402656625
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656626 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656626 = validateParameter(valid_402656626, JString,
                                      required = false, default = nil)
  if valid_402656626 != nil:
    section.add "X-Amz-Security-Token", valid_402656626
  var valid_402656627 = header.getOrDefault("X-Amz-Signature")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Signature", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Algorithm", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Date")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Date", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Credential")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Credential", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656632
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

proc call*(call_402656634: Call_GetServiceGraph_402656622; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a document that describes services that process incoming requests, and downstream services that they call as a result. Root services process incoming requests and make calls to downstream services. Root services are applications that use the <a href="https://docs.aws.amazon.com/xray/index.html">AWS X-Ray SDK</a>. Downstream services can be other applications, AWS resources, HTTP web APIs, or SQL databases.
                                                                                         ## 
  let valid = call_402656634.validator(path, query, header, formData, body, _)
  let scheme = call_402656634.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656634.makeUrl(scheme.get, call_402656634.host, call_402656634.base,
                                   call_402656634.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656634, uri, valid, _)

proc call*(call_402656635: Call_GetServiceGraph_402656622; body: JsonNode;
           NextToken: string = ""): Recallable =
  ## getServiceGraph
  ## Retrieves a document that describes services that process incoming requests, and downstream services that they call as a result. Root services process incoming requests and make calls to downstream services. Root services are applications that use the <a href="https://docs.aws.amazon.com/xray/index.html">AWS X-Ray SDK</a>. Downstream services can be other applications, AWS resources, HTTP web APIs, or SQL databases.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                        ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                   ## token
  var query_402656636 = newJObject()
  var body_402656637 = newJObject()
  if body != nil:
    body_402656637 = body
  add(query_402656636, "NextToken", newJString(NextToken))
  result = call_402656635.call(nil, query_402656636, nil, nil, body_402656637)

var getServiceGraph* = Call_GetServiceGraph_402656622(name: "getServiceGraph",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com",
    route: "/ServiceGraph", validator: validate_GetServiceGraph_402656623,
    base: "/", makeUrl: url_GetServiceGraph_402656624,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTimeSeriesServiceStatistics_402656638 = ref object of OpenApiRestCall_402656044
proc url_GetTimeSeriesServiceStatistics_402656640(protocol: Scheme;
    host: string; base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTimeSeriesServiceStatistics_402656639(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Get an aggregation of service statistics defined by a specific time range.
                                            ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
                                  ##            : Pagination token
  section = newJObject()
  var valid_402656641 = query.getOrDefault("NextToken")
  valid_402656641 = validateParameter(valid_402656641, JString,
                                      required = false, default = nil)
  if valid_402656641 != nil:
    section.add "NextToken", valid_402656641
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656642 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656642 = validateParameter(valid_402656642, JString,
                                      required = false, default = nil)
  if valid_402656642 != nil:
    section.add "X-Amz-Security-Token", valid_402656642
  var valid_402656643 = header.getOrDefault("X-Amz-Signature")
  valid_402656643 = validateParameter(valid_402656643, JString,
                                      required = false, default = nil)
  if valid_402656643 != nil:
    section.add "X-Amz-Signature", valid_402656643
  var valid_402656644 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656644 = validateParameter(valid_402656644, JString,
                                      required = false, default = nil)
  if valid_402656644 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656644
  var valid_402656645 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656645 = validateParameter(valid_402656645, JString,
                                      required = false, default = nil)
  if valid_402656645 != nil:
    section.add "X-Amz-Algorithm", valid_402656645
  var valid_402656646 = header.getOrDefault("X-Amz-Date")
  valid_402656646 = validateParameter(valid_402656646, JString,
                                      required = false, default = nil)
  if valid_402656646 != nil:
    section.add "X-Amz-Date", valid_402656646
  var valid_402656647 = header.getOrDefault("X-Amz-Credential")
  valid_402656647 = validateParameter(valid_402656647, JString,
                                      required = false, default = nil)
  if valid_402656647 != nil:
    section.add "X-Amz-Credential", valid_402656647
  var valid_402656648 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656648 = validateParameter(valid_402656648, JString,
                                      required = false, default = nil)
  if valid_402656648 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656648
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

proc call*(call_402656650: Call_GetTimeSeriesServiceStatistics_402656638;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get an aggregation of service statistics defined by a specific time range.
                                                                                         ## 
  let valid = call_402656650.validator(path, query, header, formData, body, _)
  let scheme = call_402656650.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656650.makeUrl(scheme.get, call_402656650.host, call_402656650.base,
                                   call_402656650.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656650, uri, valid, _)

proc call*(call_402656651: Call_GetTimeSeriesServiceStatistics_402656638;
           body: JsonNode; NextToken: string = ""): Recallable =
  ## getTimeSeriesServiceStatistics
  ## Get an aggregation of service statistics defined by a specific time range.
  ##   
                                                                               ## body: JObject (required)
  ##   
                                                                                                          ## NextToken: string
                                                                                                          ##            
                                                                                                          ## : 
                                                                                                          ## Pagination 
                                                                                                          ## token
  var query_402656652 = newJObject()
  var body_402656653 = newJObject()
  if body != nil:
    body_402656653 = body
  add(query_402656652, "NextToken", newJString(NextToken))
  result = call_402656651.call(nil, query_402656652, nil, nil, body_402656653)

var getTimeSeriesServiceStatistics* = Call_GetTimeSeriesServiceStatistics_402656638(
    name: "getTimeSeriesServiceStatistics", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/TimeSeriesServiceStatistics",
    validator: validate_GetTimeSeriesServiceStatistics_402656639, base: "/",
    makeUrl: url_GetTimeSeriesServiceStatistics_402656640,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTraceGraph_402656654 = ref object of OpenApiRestCall_402656044
proc url_GetTraceGraph_402656656(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTraceGraph_402656655(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieves a service graph for one or more specific trace IDs.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
                                  ##            : Pagination token
  section = newJObject()
  var valid_402656657 = query.getOrDefault("NextToken")
  valid_402656657 = validateParameter(valid_402656657, JString,
                                      required = false, default = nil)
  if valid_402656657 != nil:
    section.add "NextToken", valid_402656657
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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

proc call*(call_402656666: Call_GetTraceGraph_402656654; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieves a service graph for one or more specific trace IDs.
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

proc call*(call_402656667: Call_GetTraceGraph_402656654; body: JsonNode;
           NextToken: string = ""): Recallable =
  ## getTraceGraph
  ## Retrieves a service graph for one or more specific trace IDs.
  ##   body: JObject (required)
  ##   NextToken: string
                               ##            : Pagination token
  var query_402656668 = newJObject()
  var body_402656669 = newJObject()
  if body != nil:
    body_402656669 = body
  add(query_402656668, "NextToken", newJString(NextToken))
  result = call_402656667.call(nil, query_402656668, nil, nil, body_402656669)

var getTraceGraph* = Call_GetTraceGraph_402656654(name: "getTraceGraph",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com", route: "/TraceGraph",
    validator: validate_GetTraceGraph_402656655, base: "/",
    makeUrl: url_GetTraceGraph_402656656, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetTraceSummaries_402656670 = ref object of OpenApiRestCall_402656044
proc url_GetTraceSummaries_402656672(protocol: Scheme; host: string;
                                     base: string; route: string;
                                     path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_GetTraceSummaries_402656671(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Retrieves IDs and annotations for traces available for a specified time frame using an optional filter. To get the full traces, pass the trace IDs to <code>BatchGetTraces</code>.</p> <p>A filter expression can target traced requests that hit specific service nodes or edges, have errors, or come from a known user. For example, the following filter expression targets traces that pass through <code>api.example.com</code>:</p> <p> <code>service("api.example.com")</code> </p> <p>This filter expression finds traces that have an annotation named <code>account</code> with the value <code>12345</code>:</p> <p> <code>annotation.account = "12345"</code> </p> <p>For a full list of indexed fields and keywords that you can use in filter expressions, see <a href="https://docs.aws.amazon.com/xray/latest/devguide/xray-console-filters.html">Using Filter Expressions</a> in the <i>AWS X-Ray Developer Guide</i>.</p>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
                                  ##            : Pagination token
  section = newJObject()
  var valid_402656673 = query.getOrDefault("NextToken")
  valid_402656673 = validateParameter(valid_402656673, JString,
                                      required = false, default = nil)
  if valid_402656673 != nil:
    section.add "NextToken", valid_402656673
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656674 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656674 = validateParameter(valid_402656674, JString,
                                      required = false, default = nil)
  if valid_402656674 != nil:
    section.add "X-Amz-Security-Token", valid_402656674
  var valid_402656675 = header.getOrDefault("X-Amz-Signature")
  valid_402656675 = validateParameter(valid_402656675, JString,
                                      required = false, default = nil)
  if valid_402656675 != nil:
    section.add "X-Amz-Signature", valid_402656675
  var valid_402656676 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656676 = validateParameter(valid_402656676, JString,
                                      required = false, default = nil)
  if valid_402656676 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656676
  var valid_402656677 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656677 = validateParameter(valid_402656677, JString,
                                      required = false, default = nil)
  if valid_402656677 != nil:
    section.add "X-Amz-Algorithm", valid_402656677
  var valid_402656678 = header.getOrDefault("X-Amz-Date")
  valid_402656678 = validateParameter(valid_402656678, JString,
                                      required = false, default = nil)
  if valid_402656678 != nil:
    section.add "X-Amz-Date", valid_402656678
  var valid_402656679 = header.getOrDefault("X-Amz-Credential")
  valid_402656679 = validateParameter(valid_402656679, JString,
                                      required = false, default = nil)
  if valid_402656679 != nil:
    section.add "X-Amz-Credential", valid_402656679
  var valid_402656680 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656680 = validateParameter(valid_402656680, JString,
                                      required = false, default = nil)
  if valid_402656680 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656680
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

proc call*(call_402656682: Call_GetTraceSummaries_402656670;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Retrieves IDs and annotations for traces available for a specified time frame using an optional filter. To get the full traces, pass the trace IDs to <code>BatchGetTraces</code>.</p> <p>A filter expression can target traced requests that hit specific service nodes or edges, have errors, or come from a known user. For example, the following filter expression targets traces that pass through <code>api.example.com</code>:</p> <p> <code>service("api.example.com")</code> </p> <p>This filter expression finds traces that have an annotation named <code>account</code> with the value <code>12345</code>:</p> <p> <code>annotation.account = "12345"</code> </p> <p>For a full list of indexed fields and keywords that you can use in filter expressions, see <a href="https://docs.aws.amazon.com/xray/latest/devguide/xray-console-filters.html">Using Filter Expressions</a> in the <i>AWS X-Ray Developer Guide</i>.</p>
                                                                                         ## 
  let valid = call_402656682.validator(path, query, header, formData, body, _)
  let scheme = call_402656682.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656682.makeUrl(scheme.get, call_402656682.host, call_402656682.base,
                                   call_402656682.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656682, uri, valid, _)

proc call*(call_402656683: Call_GetTraceSummaries_402656670; body: JsonNode;
           NextToken: string = ""): Recallable =
  ## getTraceSummaries
  ## <p>Retrieves IDs and annotations for traces available for a specified time frame using an optional filter. To get the full traces, pass the trace IDs to <code>BatchGetTraces</code>.</p> <p>A filter expression can target traced requests that hit specific service nodes or edges, have errors, or come from a known user. For example, the following filter expression targets traces that pass through <code>api.example.com</code>:</p> <p> <code>service("api.example.com")</code> </p> <p>This filter expression finds traces that have an annotation named <code>account</code> with the value <code>12345</code>:</p> <p> <code>annotation.account = "12345"</code> </p> <p>For a full list of indexed fields and keywords that you can use in filter expressions, see <a href="https://docs.aws.amazon.com/xray/latest/devguide/xray-console-filters.html">Using Filter Expressions</a> in the <i>AWS X-Ray Developer Guide</i>.</p>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                    ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## NextToken: string
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## token
  var query_402656684 = newJObject()
  var body_402656685 = newJObject()
  if body != nil:
    body_402656685 = body
  add(query_402656684, "NextToken", newJString(NextToken))
  result = call_402656683.call(nil, query_402656684, nil, nil, body_402656685)

var getTraceSummaries* = Call_GetTraceSummaries_402656670(
    name: "getTraceSummaries", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/TraceSummaries",
    validator: validate_GetTraceSummaries_402656671, base: "/",
    makeUrl: url_GetTraceSummaries_402656672,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutEncryptionConfig_402656686 = ref object of OpenApiRestCall_402656044
proc url_PutEncryptionConfig_402656688(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutEncryptionConfig_402656687(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the encryption configuration for X-Ray data.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656689 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Security-Token", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Signature")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Signature", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Algorithm", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-Date")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-Date", valid_402656693
  var valid_402656694 = header.getOrDefault("X-Amz-Credential")
  valid_402656694 = validateParameter(valid_402656694, JString,
                                      required = false, default = nil)
  if valid_402656694 != nil:
    section.add "X-Amz-Credential", valid_402656694
  var valid_402656695 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656695 = validateParameter(valid_402656695, JString,
                                      required = false, default = nil)
  if valid_402656695 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656695
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

proc call*(call_402656697: Call_PutEncryptionConfig_402656686;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the encryption configuration for X-Ray data.
                                                                                         ## 
  let valid = call_402656697.validator(path, query, header, formData, body, _)
  let scheme = call_402656697.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656697.makeUrl(scheme.get, call_402656697.host, call_402656697.base,
                                   call_402656697.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656697, uri, valid, _)

proc call*(call_402656698: Call_PutEncryptionConfig_402656686; body: JsonNode): Recallable =
  ## putEncryptionConfig
  ## Updates the encryption configuration for X-Ray data.
  ##   body: JObject (required)
  var body_402656699 = newJObject()
  if body != nil:
    body_402656699 = body
  result = call_402656698.call(nil, nil, nil, nil, body_402656699)

var putEncryptionConfig* = Call_PutEncryptionConfig_402656686(
    name: "putEncryptionConfig", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/PutEncryptionConfig",
    validator: validate_PutEncryptionConfig_402656687, base: "/",
    makeUrl: url_PutEncryptionConfig_402656688,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutTelemetryRecords_402656700 = ref object of OpenApiRestCall_402656044
proc url_PutTelemetryRecords_402656702(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutTelemetryRecords_402656701(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Used by the AWS X-Ray daemon to upload telemetry.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
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

proc call*(call_402656711: Call_PutTelemetryRecords_402656700;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Used by the AWS X-Ray daemon to upload telemetry.
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

proc call*(call_402656712: Call_PutTelemetryRecords_402656700; body: JsonNode): Recallable =
  ## putTelemetryRecords
  ## Used by the AWS X-Ray daemon to upload telemetry.
  ##   body: JObject (required)
  var body_402656713 = newJObject()
  if body != nil:
    body_402656713 = body
  result = call_402656712.call(nil, nil, nil, nil, body_402656713)

var putTelemetryRecords* = Call_PutTelemetryRecords_402656700(
    name: "putTelemetryRecords", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/TelemetryRecords",
    validator: validate_PutTelemetryRecords_402656701, base: "/",
    makeUrl: url_PutTelemetryRecords_402656702,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PutTraceSegments_402656714 = ref object of OpenApiRestCall_402656044
proc url_PutTraceSegments_402656716(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_PutTraceSegments_402656715(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## <p>Uploads segment documents to AWS X-Ray. The <a href="https://docs.aws.amazon.com/xray/index.html">X-Ray SDK</a> generates segment documents and sends them to the X-Ray daemon, which uploads them in batches. A segment document can be a completed segment, an in-progress segment, or an array of subsegments.</p> <p>Segments must include the following fields. For the full segment document schema, see <a href="https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html">AWS X-Ray Segment Documents</a> in the <i>AWS X-Ray Developer Guide</i>.</p> <p class="title"> <b>Required Segment Document Fields</b> </p> <ul> <li> <p> <code>name</code> - The name of the service that handled the request.</p> </li> <li> <p> <code>id</code> - A 64-bit identifier for the segment, unique among segments in the same trace, in 16 hexadecimal digits.</p> </li> <li> <p> <code>trace_id</code> - A unique identifier that connects all segments and subsegments originating from a single client request.</p> </li> <li> <p> <code>start_time</code> - Time the segment or subsegment was created, in floating point seconds in epoch time, accurate to milliseconds. For example, <code>1480615200.010</code> or <code>1.480615200010E9</code>.</p> </li> <li> <p> <code>end_time</code> - Time the segment or subsegment was closed. For example, <code>1480615200.090</code> or <code>1.480615200090E9</code>. Specify either an <code>end_time</code> or <code>in_progress</code>.</p> </li> <li> <p> <code>in_progress</code> - Set to <code>true</code> instead of specifying an <code>end_time</code> to record that a segment has been started, but is not complete. Send an in progress segment when your application receives a request that will take a long time to serve, to trace the fact that the request was received. When the response is sent, send the complete segment to overwrite the in-progress segment.</p> </li> </ul> <p>A <code>trace_id</code> consists of three numbers separated by hyphens. For example, 1-58406520-a006649127e371903a2de979. This includes:</p> <p class="title"> <b>Trace ID Format</b> </p> <ul> <li> <p>The version number, i.e. <code>1</code>.</p> </li> <li> <p>The time of the original request, in Unix epoch time, in 8 hexadecimal digits. For example, 10:00AM December 2nd, 2016 PST in epoch time is <code>1480615200</code> seconds, or <code>58406520</code> in hexadecimal.</p> </li> <li> <p>A 96-bit identifier for the trace, globally unique, in 24 hexadecimal digits.</p> </li> </ul>
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656717 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656717 = validateParameter(valid_402656717, JString,
                                      required = false, default = nil)
  if valid_402656717 != nil:
    section.add "X-Amz-Security-Token", valid_402656717
  var valid_402656718 = header.getOrDefault("X-Amz-Signature")
  valid_402656718 = validateParameter(valid_402656718, JString,
                                      required = false, default = nil)
  if valid_402656718 != nil:
    section.add "X-Amz-Signature", valid_402656718
  var valid_402656719 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656719 = validateParameter(valid_402656719, JString,
                                      required = false, default = nil)
  if valid_402656719 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656719
  var valid_402656720 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656720 = validateParameter(valid_402656720, JString,
                                      required = false, default = nil)
  if valid_402656720 != nil:
    section.add "X-Amz-Algorithm", valid_402656720
  var valid_402656721 = header.getOrDefault("X-Amz-Date")
  valid_402656721 = validateParameter(valid_402656721, JString,
                                      required = false, default = nil)
  if valid_402656721 != nil:
    section.add "X-Amz-Date", valid_402656721
  var valid_402656722 = header.getOrDefault("X-Amz-Credential")
  valid_402656722 = validateParameter(valid_402656722, JString,
                                      required = false, default = nil)
  if valid_402656722 != nil:
    section.add "X-Amz-Credential", valid_402656722
  var valid_402656723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656723 = validateParameter(valid_402656723, JString,
                                      required = false, default = nil)
  if valid_402656723 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656723
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

proc call*(call_402656725: Call_PutTraceSegments_402656714;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## <p>Uploads segment documents to AWS X-Ray. The <a href="https://docs.aws.amazon.com/xray/index.html">X-Ray SDK</a> generates segment documents and sends them to the X-Ray daemon, which uploads them in batches. A segment document can be a completed segment, an in-progress segment, or an array of subsegments.</p> <p>Segments must include the following fields. For the full segment document schema, see <a href="https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html">AWS X-Ray Segment Documents</a> in the <i>AWS X-Ray Developer Guide</i>.</p> <p class="title"> <b>Required Segment Document Fields</b> </p> <ul> <li> <p> <code>name</code> - The name of the service that handled the request.</p> </li> <li> <p> <code>id</code> - A 64-bit identifier for the segment, unique among segments in the same trace, in 16 hexadecimal digits.</p> </li> <li> <p> <code>trace_id</code> - A unique identifier that connects all segments and subsegments originating from a single client request.</p> </li> <li> <p> <code>start_time</code> - Time the segment or subsegment was created, in floating point seconds in epoch time, accurate to milliseconds. For example, <code>1480615200.010</code> or <code>1.480615200010E9</code>.</p> </li> <li> <p> <code>end_time</code> - Time the segment or subsegment was closed. For example, <code>1480615200.090</code> or <code>1.480615200090E9</code>. Specify either an <code>end_time</code> or <code>in_progress</code>.</p> </li> <li> <p> <code>in_progress</code> - Set to <code>true</code> instead of specifying an <code>end_time</code> to record that a segment has been started, but is not complete. Send an in progress segment when your application receives a request that will take a long time to serve, to trace the fact that the request was received. When the response is sent, send the complete segment to overwrite the in-progress segment.</p> </li> </ul> <p>A <code>trace_id</code> consists of three numbers separated by hyphens. For example, 1-58406520-a006649127e371903a2de979. This includes:</p> <p class="title"> <b>Trace ID Format</b> </p> <ul> <li> <p>The version number, i.e. <code>1</code>.</p> </li> <li> <p>The time of the original request, in Unix epoch time, in 8 hexadecimal digits. For example, 10:00AM December 2nd, 2016 PST in epoch time is <code>1480615200</code> seconds, or <code>58406520</code> in hexadecimal.</p> </li> <li> <p>A 96-bit identifier for the trace, globally unique, in 24 hexadecimal digits.</p> </li> </ul>
                                                                                         ## 
  let valid = call_402656725.validator(path, query, header, formData, body, _)
  let scheme = call_402656725.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656725.makeUrl(scheme.get, call_402656725.host, call_402656725.base,
                                   call_402656725.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656725, uri, valid, _)

proc call*(call_402656726: Call_PutTraceSegments_402656714; body: JsonNode): Recallable =
  ## putTraceSegments
  ## <p>Uploads segment documents to AWS X-Ray. The <a href="https://docs.aws.amazon.com/xray/index.html">X-Ray SDK</a> generates segment documents and sends them to the X-Ray daemon, which uploads them in batches. A segment document can be a completed segment, an in-progress segment, or an array of subsegments.</p> <p>Segments must include the following fields. For the full segment document schema, see <a href="https://docs.aws.amazon.com/xray/latest/devguide/xray-api-segmentdocuments.html">AWS X-Ray Segment Documents</a> in the <i>AWS X-Ray Developer Guide</i>.</p> <p class="title"> <b>Required Segment Document Fields</b> </p> <ul> <li> <p> <code>name</code> - The name of the service that handled the request.</p> </li> <li> <p> <code>id</code> - A 64-bit identifier for the segment, unique among segments in the same trace, in 16 hexadecimal digits.</p> </li> <li> <p> <code>trace_id</code> - A unique identifier that connects all segments and subsegments originating from a single client request.</p> </li> <li> <p> <code>start_time</code> - Time the segment or subsegment was created, in floating point seconds in epoch time, accurate to milliseconds. For example, <code>1480615200.010</code> or <code>1.480615200010E9</code>.</p> </li> <li> <p> <code>end_time</code> - Time the segment or subsegment was closed. For example, <code>1480615200.090</code> or <code>1.480615200090E9</code>. Specify either an <code>end_time</code> or <code>in_progress</code>.</p> </li> <li> <p> <code>in_progress</code> - Set to <code>true</code> instead of specifying an <code>end_time</code> to record that a segment has been started, but is not complete. Send an in progress segment when your application receives a request that will take a long time to serve, to trace the fact that the request was received. When the response is sent, send the complete segment to overwrite the in-progress segment.</p> </li> </ul> <p>A <code>trace_id</code> consists of three numbers separated by hyphens. For example, 1-58406520-a006649127e371903a2de979. This includes:</p> <p class="title"> <b>Trace ID Format</b> </p> <ul> <li> <p>The version number, i.e. <code>1</code>.</p> </li> <li> <p>The time of the original request, in Unix epoch time, in 8 hexadecimal digits. For example, 10:00AM December 2nd, 2016 PST in epoch time is <code>1480615200</code> seconds, or <code>58406520</code> in hexadecimal.</p> </li> <li> <p>A 96-bit identifier for the trace, globally unique, in 24 hexadecimal digits.</p> </li> </ul>
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ## body: JObject (required)
  var body_402656727 = newJObject()
  if body != nil:
    body_402656727 = body
  result = call_402656726.call(nil, nil, nil, nil, body_402656727)

var putTraceSegments* = Call_PutTraceSegments_402656714(
    name: "putTraceSegments", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/TraceSegments",
    validator: validate_PutTraceSegments_402656715, base: "/",
    makeUrl: url_PutTraceSegments_402656716,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateGroup_402656728 = ref object of OpenApiRestCall_402656044
proc url_UpdateGroup_402656730(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateGroup_402656729(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a group resource.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656731 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656731 = validateParameter(valid_402656731, JString,
                                      required = false, default = nil)
  if valid_402656731 != nil:
    section.add "X-Amz-Security-Token", valid_402656731
  var valid_402656732 = header.getOrDefault("X-Amz-Signature")
  valid_402656732 = validateParameter(valid_402656732, JString,
                                      required = false, default = nil)
  if valid_402656732 != nil:
    section.add "X-Amz-Signature", valid_402656732
  var valid_402656733 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656733 = validateParameter(valid_402656733, JString,
                                      required = false, default = nil)
  if valid_402656733 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656733
  var valid_402656734 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656734 = validateParameter(valid_402656734, JString,
                                      required = false, default = nil)
  if valid_402656734 != nil:
    section.add "X-Amz-Algorithm", valid_402656734
  var valid_402656735 = header.getOrDefault("X-Amz-Date")
  valid_402656735 = validateParameter(valid_402656735, JString,
                                      required = false, default = nil)
  if valid_402656735 != nil:
    section.add "X-Amz-Date", valid_402656735
  var valid_402656736 = header.getOrDefault("X-Amz-Credential")
  valid_402656736 = validateParameter(valid_402656736, JString,
                                      required = false, default = nil)
  if valid_402656736 != nil:
    section.add "X-Amz-Credential", valid_402656736
  var valid_402656737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656737 = validateParameter(valid_402656737, JString,
                                      required = false, default = nil)
  if valid_402656737 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656737
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

proc call*(call_402656739: Call_UpdateGroup_402656728; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a group resource.
                                                                                         ## 
  let valid = call_402656739.validator(path, query, header, formData, body, _)
  let scheme = call_402656739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656739.makeUrl(scheme.get, call_402656739.host, call_402656739.base,
                                   call_402656739.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656739, uri, valid, _)

proc call*(call_402656740: Call_UpdateGroup_402656728; body: JsonNode): Recallable =
  ## updateGroup
  ## Updates a group resource.
  ##   body: JObject (required)
  var body_402656741 = newJObject()
  if body != nil:
    body_402656741 = body
  result = call_402656740.call(nil, nil, nil, nil, body_402656741)

var updateGroup* = Call_UpdateGroup_402656728(name: "updateGroup",
    meth: HttpMethod.HttpPost, host: "xray.amazonaws.com",
    route: "/UpdateGroup", validator: validate_UpdateGroup_402656729, base: "/",
    makeUrl: url_UpdateGroup_402656730, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateSamplingRule_402656742 = ref object of OpenApiRestCall_402656044
proc url_UpdateSamplingRule_402656744(protocol: Scheme; host: string;
                                      base: string; route: string;
                                      path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_UpdateSamplingRule_402656743(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Modifies a sampling rule's configuration.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_402656745 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656745 = validateParameter(valid_402656745, JString,
                                      required = false, default = nil)
  if valid_402656745 != nil:
    section.add "X-Amz-Security-Token", valid_402656745
  var valid_402656746 = header.getOrDefault("X-Amz-Signature")
  valid_402656746 = validateParameter(valid_402656746, JString,
                                      required = false, default = nil)
  if valid_402656746 != nil:
    section.add "X-Amz-Signature", valid_402656746
  var valid_402656747 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656747 = validateParameter(valid_402656747, JString,
                                      required = false, default = nil)
  if valid_402656747 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656747
  var valid_402656748 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656748 = validateParameter(valid_402656748, JString,
                                      required = false, default = nil)
  if valid_402656748 != nil:
    section.add "X-Amz-Algorithm", valid_402656748
  var valid_402656749 = header.getOrDefault("X-Amz-Date")
  valid_402656749 = validateParameter(valid_402656749, JString,
                                      required = false, default = nil)
  if valid_402656749 != nil:
    section.add "X-Amz-Date", valid_402656749
  var valid_402656750 = header.getOrDefault("X-Amz-Credential")
  valid_402656750 = validateParameter(valid_402656750, JString,
                                      required = false, default = nil)
  if valid_402656750 != nil:
    section.add "X-Amz-Credential", valid_402656750
  var valid_402656751 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656751 = validateParameter(valid_402656751, JString,
                                      required = false, default = nil)
  if valid_402656751 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656751
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

proc call*(call_402656753: Call_UpdateSamplingRule_402656742;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Modifies a sampling rule's configuration.
                                                                                         ## 
  let valid = call_402656753.validator(path, query, header, formData, body, _)
  let scheme = call_402656753.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656753.makeUrl(scheme.get, call_402656753.host, call_402656753.base,
                                   call_402656753.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656753, uri, valid, _)

proc call*(call_402656754: Call_UpdateSamplingRule_402656742; body: JsonNode): Recallable =
  ## updateSamplingRule
  ## Modifies a sampling rule's configuration.
  ##   body: JObject (required)
  var body_402656755 = newJObject()
  if body != nil:
    body_402656755 = body
  result = call_402656754.call(nil, nil, nil, nil, body_402656755)

var updateSamplingRule* = Call_UpdateSamplingRule_402656742(
    name: "updateSamplingRule", meth: HttpMethod.HttpPost,
    host: "xray.amazonaws.com", route: "/UpdateSamplingRule",
    validator: validate_UpdateSamplingRule_402656743, base: "/",
    makeUrl: url_UpdateSamplingRule_402656744,
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