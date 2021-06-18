
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS MediaConnect
## version: 2018-11-14
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## API for AWS Elemental MediaConnect
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/mediaconnect/
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

  OpenApiRestCall_402656038 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_402656038](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base,
             route: t.route, schemes: t.schemes, validator: t.validator,
             url: t.url)

proc pickScheme(t: OpenApiRestCall_402656038): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "mediaconnect.ap-northeast-1.amazonaws.com", "ap-southeast-1": "mediaconnect.ap-southeast-1.amazonaws.com", "us-west-2": "mediaconnect.us-west-2.amazonaws.com", "eu-west-2": "mediaconnect.eu-west-2.amazonaws.com", "ap-northeast-3": "mediaconnect.ap-northeast-3.amazonaws.com", "eu-central-1": "mediaconnect.eu-central-1.amazonaws.com", "us-east-2": "mediaconnect.us-east-2.amazonaws.com", "us-east-1": "mediaconnect.us-east-1.amazonaws.com", "cn-northwest-1": "mediaconnect.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "mediaconnect.ap-south-1.amazonaws.com", "eu-north-1": "mediaconnect.eu-north-1.amazonaws.com", "ap-northeast-2": "mediaconnect.ap-northeast-2.amazonaws.com", "us-west-1": "mediaconnect.us-west-1.amazonaws.com", "us-gov-east-1": "mediaconnect.us-gov-east-1.amazonaws.com", "eu-west-3": "mediaconnect.eu-west-3.amazonaws.com", "cn-north-1": "mediaconnect.cn-north-1.amazonaws.com.cn", "sa-east-1": "mediaconnect.sa-east-1.amazonaws.com", "eu-west-1": "mediaconnect.eu-west-1.amazonaws.com", "us-gov-west-1": "mediaconnect.us-gov-west-1.amazonaws.com", "ap-southeast-2": "mediaconnect.ap-southeast-2.amazonaws.com", "ca-central-1": "mediaconnect.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "mediaconnect.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "mediaconnect.ap-southeast-1.amazonaws.com",
      "us-west-2": "mediaconnect.us-west-2.amazonaws.com",
      "eu-west-2": "mediaconnect.eu-west-2.amazonaws.com",
      "ap-northeast-3": "mediaconnect.ap-northeast-3.amazonaws.com",
      "eu-central-1": "mediaconnect.eu-central-1.amazonaws.com",
      "us-east-2": "mediaconnect.us-east-2.amazonaws.com",
      "us-east-1": "mediaconnect.us-east-1.amazonaws.com",
      "cn-northwest-1": "mediaconnect.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "mediaconnect.ap-south-1.amazonaws.com",
      "eu-north-1": "mediaconnect.eu-north-1.amazonaws.com",
      "ap-northeast-2": "mediaconnect.ap-northeast-2.amazonaws.com",
      "us-west-1": "mediaconnect.us-west-1.amazonaws.com",
      "us-gov-east-1": "mediaconnect.us-gov-east-1.amazonaws.com",
      "eu-west-3": "mediaconnect.eu-west-3.amazonaws.com",
      "cn-north-1": "mediaconnect.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "mediaconnect.sa-east-1.amazonaws.com",
      "eu-west-1": "mediaconnect.eu-west-1.amazonaws.com",
      "us-gov-west-1": "mediaconnect.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "mediaconnect.ap-southeast-2.amazonaws.com",
      "ca-central-1": "mediaconnect.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "mediaconnect"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_AddFlowOutputs_402656288 = ref object of OpenApiRestCall_402656038
proc url_AddFlowOutputs_402656290(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
                 (kind: VariableSegment, value: "flowArn"),
                 (kind: ConstantSegment, value: "/outputs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_AddFlowOutputs_402656289(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
                                 ##          : The flow that you want to add outputs to.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `flowArn` field"
  var valid_402656383 = path.getOrDefault("flowArn")
  valid_402656383 = validateParameter(valid_402656383, JString, required = true,
                                      default = nil)
  if valid_402656383 != nil:
    section.add "flowArn", valid_402656383
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
  var valid_402656384 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656384 = validateParameter(valid_402656384, JString,
                                      required = false, default = nil)
  if valid_402656384 != nil:
    section.add "X-Amz-Security-Token", valid_402656384
  var valid_402656385 = header.getOrDefault("X-Amz-Signature")
  valid_402656385 = validateParameter(valid_402656385, JString,
                                      required = false, default = nil)
  if valid_402656385 != nil:
    section.add "X-Amz-Signature", valid_402656385
  var valid_402656386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656386 = validateParameter(valid_402656386, JString,
                                      required = false, default = nil)
  if valid_402656386 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656386
  var valid_402656387 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656387 = validateParameter(valid_402656387, JString,
                                      required = false, default = nil)
  if valid_402656387 != nil:
    section.add "X-Amz-Algorithm", valid_402656387
  var valid_402656388 = header.getOrDefault("X-Amz-Date")
  valid_402656388 = validateParameter(valid_402656388, JString,
                                      required = false, default = nil)
  if valid_402656388 != nil:
    section.add "X-Amz-Date", valid_402656388
  var valid_402656389 = header.getOrDefault("X-Amz-Credential")
  valid_402656389 = validateParameter(valid_402656389, JString,
                                      required = false, default = nil)
  if valid_402656389 != nil:
    section.add "X-Amz-Credential", valid_402656389
  var valid_402656390 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656390 = validateParameter(valid_402656390, JString,
                                      required = false, default = nil)
  if valid_402656390 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656390
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

proc call*(call_402656405: Call_AddFlowOutputs_402656288; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
                                                                                         ## 
  let valid = call_402656405.validator(path, query, header, formData, body, _)
  let scheme = call_402656405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656405.makeUrl(scheme.get, call_402656405.host, call_402656405.base,
                                   call_402656405.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656405, uri, valid, _)

proc call*(call_402656454: Call_AddFlowOutputs_402656288; flowArn: string;
           body: JsonNode): Recallable =
  ## addFlowOutputs
  ## Adds outputs to an existing flow. You can create up to 20 outputs per flow.
  ##   
                                                                                ## flowArn: string (required)
                                                                                ##          
                                                                                ## : 
                                                                                ## The 
                                                                                ## flow 
                                                                                ## that 
                                                                                ## you 
                                                                                ## want 
                                                                                ## to 
                                                                                ## add 
                                                                                ## outputs 
                                                                                ## to.
  ##   
                                                                                      ## body: JObject (required)
  var path_402656455 = newJObject()
  var body_402656457 = newJObject()
  add(path_402656455, "flowArn", newJString(flowArn))
  if body != nil:
    body_402656457 = body
  result = call_402656454.call(path_402656455, nil, nil, nil, body_402656457)

var addFlowOutputs* = Call_AddFlowOutputs_402656288(name: "addFlowOutputs",
    meth: HttpMethod.HttpPost, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs", validator: validate_AddFlowOutputs_402656289,
    base: "/", makeUrl: url_AddFlowOutputs_402656290,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateFlow_402656500 = ref object of OpenApiRestCall_402656038
proc url_CreateFlow_402656502(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateFlow_402656501(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
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
  var valid_402656503 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Security-Token", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Signature")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Signature", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-Algorithm", valid_402656506
  var valid_402656507 = header.getOrDefault("X-Amz-Date")
  valid_402656507 = validateParameter(valid_402656507, JString,
                                      required = false, default = nil)
  if valid_402656507 != nil:
    section.add "X-Amz-Date", valid_402656507
  var valid_402656508 = header.getOrDefault("X-Amz-Credential")
  valid_402656508 = validateParameter(valid_402656508, JString,
                                      required = false, default = nil)
  if valid_402656508 != nil:
    section.add "X-Amz-Credential", valid_402656508
  var valid_402656509 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656509 = validateParameter(valid_402656509, JString,
                                      required = false, default = nil)
  if valid_402656509 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656509
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

proc call*(call_402656511: Call_CreateFlow_402656500; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
                                                                                         ## 
  let valid = call_402656511.validator(path, query, header, formData, body, _)
  let scheme = call_402656511.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656511.makeUrl(scheme.get, call_402656511.host, call_402656511.base,
                                   call_402656511.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656511, uri, valid, _)

proc call*(call_402656512: Call_CreateFlow_402656500; body: JsonNode): Recallable =
  ## createFlow
  ## Creates a new flow. The request must include one source. The request optionally can include outputs (up to 20) and entitlements (up to 50).
  ##   
                                                                                                                                                ## body: JObject (required)
  var body_402656513 = newJObject()
  if body != nil:
    body_402656513 = body
  result = call_402656512.call(nil, nil, nil, nil, body_402656513)

var createFlow* = Call_CreateFlow_402656500(name: "createFlow",
    meth: HttpMethod.HttpPost, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows", validator: validate_CreateFlow_402656501, base: "/",
    makeUrl: url_CreateFlow_402656502, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListFlows_402656483 = ref object of OpenApiRestCall_402656038
proc url_ListFlows_402656485(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListFlows_402656484(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Displays a list of flows that are associated with this account. This request returns a paginated result.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results to return per API request. For example, you submit a ListFlows request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 10 results per page.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## nextToken: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## token 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## identifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## which 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## batch 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## see. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## For 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## example, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## submit 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## ListFlows 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## request 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## with 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## MaxResults 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## at 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## 5. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## service 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## returns 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## first 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## batch 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## (up 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## 5) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## NextToken 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## value. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## To 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## see 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## next 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## batch 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## results, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## submit 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## ListFlows 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## request 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## second 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## time 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## specify 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## NextToken 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## value.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## MaxResults: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## NextToken: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                        ## token
  section = newJObject()
  var valid_402656486 = query.getOrDefault("maxResults")
  valid_402656486 = validateParameter(valid_402656486, JInt, required = false,
                                      default = nil)
  if valid_402656486 != nil:
    section.add "maxResults", valid_402656486
  var valid_402656487 = query.getOrDefault("nextToken")
  valid_402656487 = validateParameter(valid_402656487, JString,
                                      required = false, default = nil)
  if valid_402656487 != nil:
    section.add "nextToken", valid_402656487
  var valid_402656488 = query.getOrDefault("MaxResults")
  valid_402656488 = validateParameter(valid_402656488, JString,
                                      required = false, default = nil)
  if valid_402656488 != nil:
    section.add "MaxResults", valid_402656488
  var valid_402656489 = query.getOrDefault("NextToken")
  valid_402656489 = validateParameter(valid_402656489, JString,
                                      required = false, default = nil)
  if valid_402656489 != nil:
    section.add "NextToken", valid_402656489
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
  var valid_402656490 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656490 = validateParameter(valid_402656490, JString,
                                      required = false, default = nil)
  if valid_402656490 != nil:
    section.add "X-Amz-Security-Token", valid_402656490
  var valid_402656491 = header.getOrDefault("X-Amz-Signature")
  valid_402656491 = validateParameter(valid_402656491, JString,
                                      required = false, default = nil)
  if valid_402656491 != nil:
    section.add "X-Amz-Signature", valid_402656491
  var valid_402656492 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656492 = validateParameter(valid_402656492, JString,
                                      required = false, default = nil)
  if valid_402656492 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656492
  var valid_402656493 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656493 = validateParameter(valid_402656493, JString,
                                      required = false, default = nil)
  if valid_402656493 != nil:
    section.add "X-Amz-Algorithm", valid_402656493
  var valid_402656494 = header.getOrDefault("X-Amz-Date")
  valid_402656494 = validateParameter(valid_402656494, JString,
                                      required = false, default = nil)
  if valid_402656494 != nil:
    section.add "X-Amz-Date", valid_402656494
  var valid_402656495 = header.getOrDefault("X-Amz-Credential")
  valid_402656495 = validateParameter(valid_402656495, JString,
                                      required = false, default = nil)
  if valid_402656495 != nil:
    section.add "X-Amz-Credential", valid_402656495
  var valid_402656496 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656496 = validateParameter(valid_402656496, JString,
                                      required = false, default = nil)
  if valid_402656496 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656496
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656497: Call_ListFlows_402656483; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Displays a list of flows that are associated with this account. This request returns a paginated result.
                                                                                         ## 
  let valid = call_402656497.validator(path, query, header, formData, body, _)
  let scheme = call_402656497.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656497.makeUrl(scheme.get, call_402656497.host, call_402656497.base,
                                   call_402656497.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656497, uri, valid, _)

proc call*(call_402656498: Call_ListFlows_402656483; maxResults: int = 0;
           nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listFlows
  ## Displays a list of flows that are associated with this account. This request returns a paginated result.
  ##   
                                                                                                             ## maxResults: int
                                                                                                             ##             
                                                                                                             ## : 
                                                                                                             ## The 
                                                                                                             ## maximum 
                                                                                                             ## number 
                                                                                                             ## of 
                                                                                                             ## results 
                                                                                                             ## to 
                                                                                                             ## return 
                                                                                                             ## per 
                                                                                                             ## API 
                                                                                                             ## request. 
                                                                                                             ## For 
                                                                                                             ## example, 
                                                                                                             ## you 
                                                                                                             ## submit 
                                                                                                             ## a 
                                                                                                             ## ListFlows 
                                                                                                             ## request 
                                                                                                             ## with 
                                                                                                             ## MaxResults 
                                                                                                             ## set 
                                                                                                             ## at 
                                                                                                             ## 5. 
                                                                                                             ## Although 
                                                                                                             ## 20 
                                                                                                             ## items 
                                                                                                             ## match 
                                                                                                             ## your 
                                                                                                             ## request, 
                                                                                                             ## the 
                                                                                                             ## service 
                                                                                                             ## returns 
                                                                                                             ## no 
                                                                                                             ## more 
                                                                                                             ## than 
                                                                                                             ## the 
                                                                                                             ## first 
                                                                                                             ## 5 
                                                                                                             ## items. 
                                                                                                             ## (The 
                                                                                                             ## service 
                                                                                                             ## also 
                                                                                                             ## returns 
                                                                                                             ## a 
                                                                                                             ## NextToken 
                                                                                                             ## value 
                                                                                                             ## that 
                                                                                                             ## you 
                                                                                                             ## can 
                                                                                                             ## use 
                                                                                                             ## to 
                                                                                                             ## fetch 
                                                                                                             ## the 
                                                                                                             ## next 
                                                                                                             ## batch 
                                                                                                             ## of 
                                                                                                             ## results.) 
                                                                                                             ## The 
                                                                                                             ## service 
                                                                                                             ## might 
                                                                                                             ## return 
                                                                                                             ## fewer 
                                                                                                             ## results 
                                                                                                             ## than 
                                                                                                             ## the 
                                                                                                             ## MaxResults 
                                                                                                             ## value. 
                                                                                                             ## If 
                                                                                                             ## MaxResults 
                                                                                                             ## is 
                                                                                                             ## not 
                                                                                                             ## included 
                                                                                                             ## in 
                                                                                                             ## the 
                                                                                                             ## request, 
                                                                                                             ## the 
                                                                                                             ## service 
                                                                                                             ## defaults 
                                                                                                             ## to 
                                                                                                             ## pagination 
                                                                                                             ## with 
                                                                                                             ## a 
                                                                                                             ## maximum 
                                                                                                             ## of 
                                                                                                             ## 10 
                                                                                                             ## results 
                                                                                                             ## per 
                                                                                                             ## page.
  ##   
                                                                                                                     ## nextToken: string
                                                                                                                     ##            
                                                                                                                     ## : 
                                                                                                                     ## The 
                                                                                                                     ## token 
                                                                                                                     ## that 
                                                                                                                     ## identifies 
                                                                                                                     ## which 
                                                                                                                     ## batch 
                                                                                                                     ## of 
                                                                                                                     ## results 
                                                                                                                     ## that 
                                                                                                                     ## you 
                                                                                                                     ## want 
                                                                                                                     ## to 
                                                                                                                     ## see. 
                                                                                                                     ## For 
                                                                                                                     ## example, 
                                                                                                                     ## you 
                                                                                                                     ## submit 
                                                                                                                     ## a 
                                                                                                                     ## ListFlows 
                                                                                                                     ## request 
                                                                                                                     ## with 
                                                                                                                     ## MaxResults 
                                                                                                                     ## set 
                                                                                                                     ## at 
                                                                                                                     ## 5. 
                                                                                                                     ## The 
                                                                                                                     ## service 
                                                                                                                     ## returns 
                                                                                                                     ## the 
                                                                                                                     ## first 
                                                                                                                     ## batch 
                                                                                                                     ## of 
                                                                                                                     ## results 
                                                                                                                     ## (up 
                                                                                                                     ## to 
                                                                                                                     ## 5) 
                                                                                                                     ## and 
                                                                                                                     ## a 
                                                                                                                     ## NextToken 
                                                                                                                     ## value. 
                                                                                                                     ## To 
                                                                                                                     ## see 
                                                                                                                     ## the 
                                                                                                                     ## next 
                                                                                                                     ## batch 
                                                                                                                     ## of 
                                                                                                                     ## results, 
                                                                                                                     ## you 
                                                                                                                     ## can 
                                                                                                                     ## submit 
                                                                                                                     ## the 
                                                                                                                     ## ListFlows 
                                                                                                                     ## request 
                                                                                                                     ## a 
                                                                                                                     ## second 
                                                                                                                     ## time 
                                                                                                                     ## and 
                                                                                                                     ## specify 
                                                                                                                     ## the 
                                                                                                                     ## NextToken 
                                                                                                                     ## value.
  ##   
                                                                                                                              ## MaxResults: string
                                                                                                                              ##             
                                                                                                                              ## : 
                                                                                                                              ## Pagination 
                                                                                                                              ## limit
  ##   
                                                                                                                                      ## NextToken: string
                                                                                                                                      ##            
                                                                                                                                      ## : 
                                                                                                                                      ## Pagination 
                                                                                                                                      ## token
  var query_402656499 = newJObject()
  add(query_402656499, "maxResults", newJInt(maxResults))
  add(query_402656499, "nextToken", newJString(nextToken))
  add(query_402656499, "MaxResults", newJString(MaxResults))
  add(query_402656499, "NextToken", newJString(NextToken))
  result = call_402656498.call(nil, query_402656499, nil, nil, nil)

var listFlows* = Call_ListFlows_402656483(name: "listFlows",
    meth: HttpMethod.HttpGet, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows", validator: validate_ListFlows_402656484, base: "/",
    makeUrl: url_ListFlows_402656485, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeFlow_402656514 = ref object of OpenApiRestCall_402656038
proc url_DescribeFlow_402656516(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
                 (kind: VariableSegment, value: "flowArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeFlow_402656515(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
                                 ##          : The ARN of the flow that you want to describe.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `flowArn` field"
  var valid_402656517 = path.getOrDefault("flowArn")
  valid_402656517 = validateParameter(valid_402656517, JString, required = true,
                                      default = nil)
  if valid_402656517 != nil:
    section.add "flowArn", valid_402656517
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
  var valid_402656518 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Security-Token", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Signature")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Signature", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656520
  var valid_402656521 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656521 = validateParameter(valid_402656521, JString,
                                      required = false, default = nil)
  if valid_402656521 != nil:
    section.add "X-Amz-Algorithm", valid_402656521
  var valid_402656522 = header.getOrDefault("X-Amz-Date")
  valid_402656522 = validateParameter(valid_402656522, JString,
                                      required = false, default = nil)
  if valid_402656522 != nil:
    section.add "X-Amz-Date", valid_402656522
  var valid_402656523 = header.getOrDefault("X-Amz-Credential")
  valid_402656523 = validateParameter(valid_402656523, JString,
                                      required = false, default = nil)
  if valid_402656523 != nil:
    section.add "X-Amz-Credential", valid_402656523
  var valid_402656524 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656524 = validateParameter(valid_402656524, JString,
                                      required = false, default = nil)
  if valid_402656524 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656524
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656525: Call_DescribeFlow_402656514; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
                                                                                         ## 
  let valid = call_402656525.validator(path, query, header, formData, body, _)
  let scheme = call_402656525.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656525.makeUrl(scheme.get, call_402656525.host, call_402656525.base,
                                   call_402656525.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656525, uri, valid, _)

proc call*(call_402656526: Call_DescribeFlow_402656514; flowArn: string): Recallable =
  ## describeFlow
  ## Displays the details of a flow. The response includes the flow ARN, name, and Availability Zone, as well as details about the source, outputs, and entitlements.
  ##   
                                                                                                                                                                     ## flowArn: string (required)
                                                                                                                                                                     ##          
                                                                                                                                                                     ## : 
                                                                                                                                                                     ## The 
                                                                                                                                                                     ## ARN 
                                                                                                                                                                     ## of 
                                                                                                                                                                     ## the 
                                                                                                                                                                     ## flow 
                                                                                                                                                                     ## that 
                                                                                                                                                                     ## you 
                                                                                                                                                                     ## want 
                                                                                                                                                                     ## to 
                                                                                                                                                                     ## describe.
  var path_402656527 = newJObject()
  add(path_402656527, "flowArn", newJString(flowArn))
  result = call_402656526.call(path_402656527, nil, nil, nil, nil)

var describeFlow* = Call_DescribeFlow_402656514(name: "describeFlow",
    meth: HttpMethod.HttpGet, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}", validator: validate_DescribeFlow_402656515,
    base: "/", makeUrl: url_DescribeFlow_402656516,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteFlow_402656528 = ref object of OpenApiRestCall_402656038
proc url_DeleteFlow_402656530(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
                 (kind: VariableSegment, value: "flowArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteFlow_402656529(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
                                 ##          : The ARN of the flow that you want to delete.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `flowArn` field"
  var valid_402656531 = path.getOrDefault("flowArn")
  valid_402656531 = validateParameter(valid_402656531, JString, required = true,
                                      default = nil)
  if valid_402656531 != nil:
    section.add "flowArn", valid_402656531
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
  var valid_402656532 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Security-Token", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Signature")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Signature", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656534
  var valid_402656535 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656535 = validateParameter(valid_402656535, JString,
                                      required = false, default = nil)
  if valid_402656535 != nil:
    section.add "X-Amz-Algorithm", valid_402656535
  var valid_402656536 = header.getOrDefault("X-Amz-Date")
  valid_402656536 = validateParameter(valid_402656536, JString,
                                      required = false, default = nil)
  if valid_402656536 != nil:
    section.add "X-Amz-Date", valid_402656536
  var valid_402656537 = header.getOrDefault("X-Amz-Credential")
  valid_402656537 = validateParameter(valid_402656537, JString,
                                      required = false, default = nil)
  if valid_402656537 != nil:
    section.add "X-Amz-Credential", valid_402656537
  var valid_402656538 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656538 = validateParameter(valid_402656538, JString,
                                      required = false, default = nil)
  if valid_402656538 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656538
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656539: Call_DeleteFlow_402656528; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
                                                                                         ## 
  let valid = call_402656539.validator(path, query, header, formData, body, _)
  let scheme = call_402656539.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656539.makeUrl(scheme.get, call_402656539.host, call_402656539.base,
                                   call_402656539.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656539, uri, valid, _)

proc call*(call_402656540: Call_DeleteFlow_402656528; flowArn: string): Recallable =
  ## deleteFlow
  ## Deletes a flow. Before you can delete a flow, you must stop the flow.
  ##   
                                                                          ## flowArn: string (required)
                                                                          ##          
                                                                          ## : 
                                                                          ## The 
                                                                          ## ARN 
                                                                          ## of 
                                                                          ## the 
                                                                          ## flow 
                                                                          ## that 
                                                                          ## you 
                                                                          ## want 
                                                                          ## to 
                                                                          ## delete.
  var path_402656541 = newJObject()
  add(path_402656541, "flowArn", newJString(flowArn))
  result = call_402656540.call(path_402656541, nil, nil, nil, nil)

var deleteFlow* = Call_DeleteFlow_402656528(name: "deleteFlow",
    meth: HttpMethod.HttpDelete, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}", validator: validate_DeleteFlow_402656529,
    base: "/", makeUrl: url_DeleteFlow_402656530,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GrantFlowEntitlements_402656542 = ref object of OpenApiRestCall_402656038
proc url_GrantFlowEntitlements_402656544(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
                 (kind: VariableSegment, value: "flowArn"),
                 (kind: ConstantSegment, value: "/entitlements")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GrantFlowEntitlements_402656543(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Grants entitlements to an existing flow.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
                                 ##          : The flow that you want to grant entitlements on.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `flowArn` field"
  var valid_402656545 = path.getOrDefault("flowArn")
  valid_402656545 = validateParameter(valid_402656545, JString, required = true,
                                      default = nil)
  if valid_402656545 != nil:
    section.add "flowArn", valid_402656545
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
  var valid_402656546 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Security-Token", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Signature")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Signature", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Algorithm", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-Date")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-Date", valid_402656550
  var valid_402656551 = header.getOrDefault("X-Amz-Credential")
  valid_402656551 = validateParameter(valid_402656551, JString,
                                      required = false, default = nil)
  if valid_402656551 != nil:
    section.add "X-Amz-Credential", valid_402656551
  var valid_402656552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656552 = validateParameter(valid_402656552, JString,
                                      required = false, default = nil)
  if valid_402656552 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656552
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

proc call*(call_402656554: Call_GrantFlowEntitlements_402656542;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Grants entitlements to an existing flow.
                                                                                         ## 
  let valid = call_402656554.validator(path, query, header, formData, body, _)
  let scheme = call_402656554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656554.makeUrl(scheme.get, call_402656554.host, call_402656554.base,
                                   call_402656554.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656554, uri, valid, _)

proc call*(call_402656555: Call_GrantFlowEntitlements_402656542;
           flowArn: string; body: JsonNode): Recallable =
  ## grantFlowEntitlements
  ## Grants entitlements to an existing flow.
  ##   flowArn: string (required)
                                             ##          : The flow that you want to grant entitlements on.
  ##   
                                                                                                           ## body: JObject (required)
  var path_402656556 = newJObject()
  var body_402656557 = newJObject()
  add(path_402656556, "flowArn", newJString(flowArn))
  if body != nil:
    body_402656557 = body
  result = call_402656555.call(path_402656556, nil, nil, nil, body_402656557)

var grantFlowEntitlements* = Call_GrantFlowEntitlements_402656542(
    name: "grantFlowEntitlements", meth: HttpMethod.HttpPost,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/entitlements",
    validator: validate_GrantFlowEntitlements_402656543, base: "/",
    makeUrl: url_GrantFlowEntitlements_402656544,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListEntitlements_402656558 = ref object of OpenApiRestCall_402656038
proc url_ListEntitlements_402656560(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListEntitlements_402656559(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Displays a list of all entitlements that have been granted to this account. This request returns 20 results per page.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   maxResults: JInt
                                  ##             : The maximum number of results to return per API request. For example, you submit a ListEntitlements request with MaxResults set at 5. Although 20 items match your request, the service returns no more than the first 5 items. (The service also returns a NextToken value that you can use to fetch the next batch of results.) The service might return fewer results than the MaxResults value. If MaxResults is not included in the request, the service defaults to pagination with a maximum of 20 results per page.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## nextToken: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## token 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## identifies 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## which 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## batch 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## that 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## want 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## see. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## For 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## example, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## submit 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## ListEntitlements 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## request 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## with 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## MaxResults 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## set 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## at 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## 5. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## service 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## returns 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## first 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## batch 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## results 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## (up 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## 5) 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## NextToken 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## value. 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## To 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## see 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## next 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## batch 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## of 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## results, 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## you 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## can 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## submit 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## ListEntitlements 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## request 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## a 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## second 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## time 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## and 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## specify 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## the 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## NextToken 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                              ## value.
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## MaxResults: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ##             
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                       ## limit
  ##   
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## NextToken: JString
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ##            
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## : 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## Pagination 
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               ## token
  section = newJObject()
  var valid_402656561 = query.getOrDefault("maxResults")
  valid_402656561 = validateParameter(valid_402656561, JInt, required = false,
                                      default = nil)
  if valid_402656561 != nil:
    section.add "maxResults", valid_402656561
  var valid_402656562 = query.getOrDefault("nextToken")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "nextToken", valid_402656562
  var valid_402656563 = query.getOrDefault("MaxResults")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "MaxResults", valid_402656563
  var valid_402656564 = query.getOrDefault("NextToken")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "NextToken", valid_402656564
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
  var valid_402656565 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Security-Token", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-Signature")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-Signature", valid_402656566
  var valid_402656567 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656567 = validateParameter(valid_402656567, JString,
                                      required = false, default = nil)
  if valid_402656567 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656567
  var valid_402656568 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656568 = validateParameter(valid_402656568, JString,
                                      required = false, default = nil)
  if valid_402656568 != nil:
    section.add "X-Amz-Algorithm", valid_402656568
  var valid_402656569 = header.getOrDefault("X-Amz-Date")
  valid_402656569 = validateParameter(valid_402656569, JString,
                                      required = false, default = nil)
  if valid_402656569 != nil:
    section.add "X-Amz-Date", valid_402656569
  var valid_402656570 = header.getOrDefault("X-Amz-Credential")
  valid_402656570 = validateParameter(valid_402656570, JString,
                                      required = false, default = nil)
  if valid_402656570 != nil:
    section.add "X-Amz-Credential", valid_402656570
  var valid_402656571 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656571 = validateParameter(valid_402656571, JString,
                                      required = false, default = nil)
  if valid_402656571 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656571
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656572: Call_ListEntitlements_402656558;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Displays a list of all entitlements that have been granted to this account. This request returns 20 results per page.
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

proc call*(call_402656573: Call_ListEntitlements_402656558; maxResults: int = 0;
           nextToken: string = ""; MaxResults: string = "";
           NextToken: string = ""): Recallable =
  ## listEntitlements
  ## Displays a list of all entitlements that have been granted to this account. This request returns 20 results per page.
  ##   
                                                                                                                          ## maxResults: int
                                                                                                                          ##             
                                                                                                                          ## : 
                                                                                                                          ## The 
                                                                                                                          ## maximum 
                                                                                                                          ## number 
                                                                                                                          ## of 
                                                                                                                          ## results 
                                                                                                                          ## to 
                                                                                                                          ## return 
                                                                                                                          ## per 
                                                                                                                          ## API 
                                                                                                                          ## request. 
                                                                                                                          ## For 
                                                                                                                          ## example, 
                                                                                                                          ## you 
                                                                                                                          ## submit 
                                                                                                                          ## a 
                                                                                                                          ## ListEntitlements 
                                                                                                                          ## request 
                                                                                                                          ## with 
                                                                                                                          ## MaxResults 
                                                                                                                          ## set 
                                                                                                                          ## at 
                                                                                                                          ## 5. 
                                                                                                                          ## Although 
                                                                                                                          ## 20 
                                                                                                                          ## items 
                                                                                                                          ## match 
                                                                                                                          ## your 
                                                                                                                          ## request, 
                                                                                                                          ## the 
                                                                                                                          ## service 
                                                                                                                          ## returns 
                                                                                                                          ## no 
                                                                                                                          ## more 
                                                                                                                          ## than 
                                                                                                                          ## the 
                                                                                                                          ## first 
                                                                                                                          ## 5 
                                                                                                                          ## items. 
                                                                                                                          ## (The 
                                                                                                                          ## service 
                                                                                                                          ## also 
                                                                                                                          ## returns 
                                                                                                                          ## a 
                                                                                                                          ## NextToken 
                                                                                                                          ## value 
                                                                                                                          ## that 
                                                                                                                          ## you 
                                                                                                                          ## can 
                                                                                                                          ## use 
                                                                                                                          ## to 
                                                                                                                          ## fetch 
                                                                                                                          ## the 
                                                                                                                          ## next 
                                                                                                                          ## batch 
                                                                                                                          ## of 
                                                                                                                          ## results.) 
                                                                                                                          ## The 
                                                                                                                          ## service 
                                                                                                                          ## might 
                                                                                                                          ## return 
                                                                                                                          ## fewer 
                                                                                                                          ## results 
                                                                                                                          ## than 
                                                                                                                          ## the 
                                                                                                                          ## MaxResults 
                                                                                                                          ## value. 
                                                                                                                          ## If 
                                                                                                                          ## MaxResults 
                                                                                                                          ## is 
                                                                                                                          ## not 
                                                                                                                          ## included 
                                                                                                                          ## in 
                                                                                                                          ## the 
                                                                                                                          ## request, 
                                                                                                                          ## the 
                                                                                                                          ## service 
                                                                                                                          ## defaults 
                                                                                                                          ## to 
                                                                                                                          ## pagination 
                                                                                                                          ## with 
                                                                                                                          ## a 
                                                                                                                          ## maximum 
                                                                                                                          ## of 
                                                                                                                          ## 20 
                                                                                                                          ## results 
                                                                                                                          ## per 
                                                                                                                          ## page.
  ##   
                                                                                                                                  ## nextToken: string
                                                                                                                                  ##            
                                                                                                                                  ## : 
                                                                                                                                  ## The 
                                                                                                                                  ## token 
                                                                                                                                  ## that 
                                                                                                                                  ## identifies 
                                                                                                                                  ## which 
                                                                                                                                  ## batch 
                                                                                                                                  ## of 
                                                                                                                                  ## results 
                                                                                                                                  ## that 
                                                                                                                                  ## you 
                                                                                                                                  ## want 
                                                                                                                                  ## to 
                                                                                                                                  ## see. 
                                                                                                                                  ## For 
                                                                                                                                  ## example, 
                                                                                                                                  ## you 
                                                                                                                                  ## submit 
                                                                                                                                  ## a 
                                                                                                                                  ## ListEntitlements 
                                                                                                                                  ## request 
                                                                                                                                  ## with 
                                                                                                                                  ## MaxResults 
                                                                                                                                  ## set 
                                                                                                                                  ## at 
                                                                                                                                  ## 5. 
                                                                                                                                  ## The 
                                                                                                                                  ## service 
                                                                                                                                  ## returns 
                                                                                                                                  ## the 
                                                                                                                                  ## first 
                                                                                                                                  ## batch 
                                                                                                                                  ## of 
                                                                                                                                  ## results 
                                                                                                                                  ## (up 
                                                                                                                                  ## to 
                                                                                                                                  ## 5) 
                                                                                                                                  ## and 
                                                                                                                                  ## a 
                                                                                                                                  ## NextToken 
                                                                                                                                  ## value. 
                                                                                                                                  ## To 
                                                                                                                                  ## see 
                                                                                                                                  ## the 
                                                                                                                                  ## next 
                                                                                                                                  ## batch 
                                                                                                                                  ## of 
                                                                                                                                  ## results, 
                                                                                                                                  ## you 
                                                                                                                                  ## can 
                                                                                                                                  ## submit 
                                                                                                                                  ## the 
                                                                                                                                  ## ListEntitlements 
                                                                                                                                  ## request 
                                                                                                                                  ## a 
                                                                                                                                  ## second 
                                                                                                                                  ## time 
                                                                                                                                  ## and 
                                                                                                                                  ## specify 
                                                                                                                                  ## the 
                                                                                                                                  ## NextToken 
                                                                                                                                  ## value.
  ##   
                                                                                                                                           ## MaxResults: string
                                                                                                                                           ##             
                                                                                                                                           ## : 
                                                                                                                                           ## Pagination 
                                                                                                                                           ## limit
  ##   
                                                                                                                                                   ## NextToken: string
                                                                                                                                                   ##            
                                                                                                                                                   ## : 
                                                                                                                                                   ## Pagination 
                                                                                                                                                   ## token
  var query_402656574 = newJObject()
  add(query_402656574, "maxResults", newJInt(maxResults))
  add(query_402656574, "nextToken", newJString(nextToken))
  add(query_402656574, "MaxResults", newJString(MaxResults))
  add(query_402656574, "NextToken", newJString(NextToken))
  result = call_402656573.call(nil, query_402656574, nil, nil, nil)

var listEntitlements* = Call_ListEntitlements_402656558(
    name: "listEntitlements", meth: HttpMethod.HttpGet,
    host: "mediaconnect.amazonaws.com", route: "/v1/entitlements",
    validator: validate_ListEntitlements_402656559, base: "/",
    makeUrl: url_ListEntitlements_402656560,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_402656589 = ref object of OpenApiRestCall_402656038
proc url_TagResource_402656591(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_402656590(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource to which to add tags.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656592 = path.getOrDefault("resourceArn")
  valid_402656592 = validateParameter(valid_402656592, JString, required = true,
                                      default = nil)
  if valid_402656592 != nil:
    section.add "resourceArn", valid_402656592
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
  var valid_402656593 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656593 = validateParameter(valid_402656593, JString,
                                      required = false, default = nil)
  if valid_402656593 != nil:
    section.add "X-Amz-Security-Token", valid_402656593
  var valid_402656594 = header.getOrDefault("X-Amz-Signature")
  valid_402656594 = validateParameter(valid_402656594, JString,
                                      required = false, default = nil)
  if valid_402656594 != nil:
    section.add "X-Amz-Signature", valid_402656594
  var valid_402656595 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656595 = validateParameter(valid_402656595, JString,
                                      required = false, default = nil)
  if valid_402656595 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656595
  var valid_402656596 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656596 = validateParameter(valid_402656596, JString,
                                      required = false, default = nil)
  if valid_402656596 != nil:
    section.add "X-Amz-Algorithm", valid_402656596
  var valid_402656597 = header.getOrDefault("X-Amz-Date")
  valid_402656597 = validateParameter(valid_402656597, JString,
                                      required = false, default = nil)
  if valid_402656597 != nil:
    section.add "X-Amz-Date", valid_402656597
  var valid_402656598 = header.getOrDefault("X-Amz-Credential")
  valid_402656598 = validateParameter(valid_402656598, JString,
                                      required = false, default = nil)
  if valid_402656598 != nil:
    section.add "X-Amz-Credential", valid_402656598
  var valid_402656599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656599 = validateParameter(valid_402656599, JString,
                                      required = false, default = nil)
  if valid_402656599 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656599
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

proc call*(call_402656601: Call_TagResource_402656589; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
                                                                                         ## 
  let valid = call_402656601.validator(path, query, header, formData, body, _)
  let scheme = call_402656601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656601.makeUrl(scheme.get, call_402656601.host, call_402656601.base,
                                   call_402656601.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656601, uri, valid, _)

proc call*(call_402656602: Call_TagResource_402656589; body: JsonNode;
           resourceArn: string): Recallable =
  ## tagResource
  ## Associates the specified tags to a resource with the specified resourceArn. If existing tags on a resource are not specified in the request parameters, they are not changed. When a resource is deleted, the tags associated with that resource are deleted as well.
  ##   
                                                                                                                                                                                                                                                                          ## body: JObject (required)
  ##   
                                                                                                                                                                                                                                                                                                     ## resourceArn: string (required)
                                                                                                                                                                                                                                                                                                     ##              
                                                                                                                                                                                                                                                                                                     ## : 
                                                                                                                                                                                                                                                                                                     ## The 
                                                                                                                                                                                                                                                                                                     ## Amazon 
                                                                                                                                                                                                                                                                                                     ## Resource 
                                                                                                                                                                                                                                                                                                     ## Name 
                                                                                                                                                                                                                                                                                                     ## (ARN) 
                                                                                                                                                                                                                                                                                                     ## that 
                                                                                                                                                                                                                                                                                                     ## identifies 
                                                                                                                                                                                                                                                                                                     ## the 
                                                                                                                                                                                                                                                                                                     ## AWS 
                                                                                                                                                                                                                                                                                                     ## Elemental 
                                                                                                                                                                                                                                                                                                     ## MediaConnect 
                                                                                                                                                                                                                                                                                                     ## resource 
                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                     ## which 
                                                                                                                                                                                                                                                                                                     ## to 
                                                                                                                                                                                                                                                                                                     ## add 
                                                                                                                                                                                                                                                                                                     ## tags.
  var path_402656603 = newJObject()
  var body_402656604 = newJObject()
  if body != nil:
    body_402656604 = body
  add(path_402656603, "resourceArn", newJString(resourceArn))
  result = call_402656602.call(path_402656603, nil, nil, nil, body_402656604)

var tagResource* = Call_TagResource_402656589(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "mediaconnect.amazonaws.com",
    route: "/tags/{resourceArn}", validator: validate_TagResource_402656590,
    base: "/", makeUrl: url_TagResource_402656591,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_402656575 = ref object of OpenApiRestCall_402656038
proc url_ListTagsForResource_402656577(protocol: Scheme; host: string;
                                       base: string; route: string;
                                       path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_402656576(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List all tags on an AWS Elemental MediaConnect resource
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource for which to list the tags.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656578 = path.getOrDefault("resourceArn")
  valid_402656578 = validateParameter(valid_402656578, JString, required = true,
                                      default = nil)
  if valid_402656578 != nil:
    section.add "resourceArn", valid_402656578
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
  var valid_402656579 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656579 = validateParameter(valid_402656579, JString,
                                      required = false, default = nil)
  if valid_402656579 != nil:
    section.add "X-Amz-Security-Token", valid_402656579
  var valid_402656580 = header.getOrDefault("X-Amz-Signature")
  valid_402656580 = validateParameter(valid_402656580, JString,
                                      required = false, default = nil)
  if valid_402656580 != nil:
    section.add "X-Amz-Signature", valid_402656580
  var valid_402656581 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656581 = validateParameter(valid_402656581, JString,
                                      required = false, default = nil)
  if valid_402656581 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656581
  var valid_402656582 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656582 = validateParameter(valid_402656582, JString,
                                      required = false, default = nil)
  if valid_402656582 != nil:
    section.add "X-Amz-Algorithm", valid_402656582
  var valid_402656583 = header.getOrDefault("X-Amz-Date")
  valid_402656583 = validateParameter(valid_402656583, JString,
                                      required = false, default = nil)
  if valid_402656583 != nil:
    section.add "X-Amz-Date", valid_402656583
  var valid_402656584 = header.getOrDefault("X-Amz-Credential")
  valid_402656584 = validateParameter(valid_402656584, JString,
                                      required = false, default = nil)
  if valid_402656584 != nil:
    section.add "X-Amz-Credential", valid_402656584
  var valid_402656585 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656585 = validateParameter(valid_402656585, JString,
                                      required = false, default = nil)
  if valid_402656585 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656585
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656586: Call_ListTagsForResource_402656575;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List all tags on an AWS Elemental MediaConnect resource
                                                                                         ## 
  let valid = call_402656586.validator(path, query, header, formData, body, _)
  let scheme = call_402656586.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656586.makeUrl(scheme.get, call_402656586.host, call_402656586.base,
                                   call_402656586.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656586, uri, valid, _)

proc call*(call_402656587: Call_ListTagsForResource_402656575;
           resourceArn: string): Recallable =
  ## listTagsForResource
  ## List all tags on an AWS Elemental MediaConnect resource
  ##   resourceArn: string (required)
                                                            ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource for which to list the tags.
  var path_402656588 = newJObject()
  add(path_402656588, "resourceArn", newJString(resourceArn))
  result = call_402656587.call(path_402656588, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_402656575(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediaconnect.amazonaws.com", route: "/tags/{resourceArn}",
    validator: validate_ListTagsForResource_402656576, base: "/",
    makeUrl: url_ListTagsForResource_402656577,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowOutput_402656605 = ref object of OpenApiRestCall_402656038
proc url_UpdateFlowOutput_402656607(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  assert "outputArn" in path, "`outputArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
                 (kind: VariableSegment, value: "flowArn"),
                 (kind: ConstantSegment, value: "/outputs/"),
                 (kind: VariableSegment, value: "outputArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFlowOutput_402656606(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing flow output.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
                                 ##          : The flow that is associated with the output that you want to update.
  ##   
                                                                                                                   ## outputArn: JString (required)
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## ARN 
                                                                                                                   ## of 
                                                                                                                   ## the 
                                                                                                                   ## output 
                                                                                                                   ## that 
                                                                                                                   ## you 
                                                                                                                   ## want 
                                                                                                                   ## to 
                                                                                                                   ## update.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `flowArn` field"
  var valid_402656608 = path.getOrDefault("flowArn")
  valid_402656608 = validateParameter(valid_402656608, JString, required = true,
                                      default = nil)
  if valid_402656608 != nil:
    section.add "flowArn", valid_402656608
  var valid_402656609 = path.getOrDefault("outputArn")
  valid_402656609 = validateParameter(valid_402656609, JString, required = true,
                                      default = nil)
  if valid_402656609 != nil:
    section.add "outputArn", valid_402656609
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
  var valid_402656610 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656610 = validateParameter(valid_402656610, JString,
                                      required = false, default = nil)
  if valid_402656610 != nil:
    section.add "X-Amz-Security-Token", valid_402656610
  var valid_402656611 = header.getOrDefault("X-Amz-Signature")
  valid_402656611 = validateParameter(valid_402656611, JString,
                                      required = false, default = nil)
  if valid_402656611 != nil:
    section.add "X-Amz-Signature", valid_402656611
  var valid_402656612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656612 = validateParameter(valid_402656612, JString,
                                      required = false, default = nil)
  if valid_402656612 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656612
  var valid_402656613 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656613 = validateParameter(valid_402656613, JString,
                                      required = false, default = nil)
  if valid_402656613 != nil:
    section.add "X-Amz-Algorithm", valid_402656613
  var valid_402656614 = header.getOrDefault("X-Amz-Date")
  valid_402656614 = validateParameter(valid_402656614, JString,
                                      required = false, default = nil)
  if valid_402656614 != nil:
    section.add "X-Amz-Date", valid_402656614
  var valid_402656615 = header.getOrDefault("X-Amz-Credential")
  valid_402656615 = validateParameter(valid_402656615, JString,
                                      required = false, default = nil)
  if valid_402656615 != nil:
    section.add "X-Amz-Credential", valid_402656615
  var valid_402656616 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656616 = validateParameter(valid_402656616, JString,
                                      required = false, default = nil)
  if valid_402656616 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656616
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

proc call*(call_402656618: Call_UpdateFlowOutput_402656605;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing flow output.
                                                                                         ## 
  let valid = call_402656618.validator(path, query, header, formData, body, _)
  let scheme = call_402656618.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656618.makeUrl(scheme.get, call_402656618.host, call_402656618.base,
                                   call_402656618.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656618, uri, valid, _)

proc call*(call_402656619: Call_UpdateFlowOutput_402656605; flowArn: string;
           body: JsonNode; outputArn: string): Recallable =
  ## updateFlowOutput
  ## Updates an existing flow output.
  ##   flowArn: string (required)
                                     ##          : The flow that is associated with the output that you want to update.
  ##   
                                                                                                                       ## body: JObject (required)
  ##   
                                                                                                                                                  ## outputArn: string (required)
                                                                                                                                                  ##            
                                                                                                                                                  ## : 
                                                                                                                                                  ## The 
                                                                                                                                                  ## ARN 
                                                                                                                                                  ## of 
                                                                                                                                                  ## the 
                                                                                                                                                  ## output 
                                                                                                                                                  ## that 
                                                                                                                                                  ## you 
                                                                                                                                                  ## want 
                                                                                                                                                  ## to 
                                                                                                                                                  ## update.
  var path_402656620 = newJObject()
  var body_402656621 = newJObject()
  add(path_402656620, "flowArn", newJString(flowArn))
  if body != nil:
    body_402656621 = body
  add(path_402656620, "outputArn", newJString(outputArn))
  result = call_402656619.call(path_402656620, nil, nil, nil, body_402656621)

var updateFlowOutput* = Call_UpdateFlowOutput_402656605(
    name: "updateFlowOutput", meth: HttpMethod.HttpPut,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs/{outputArn}",
    validator: validate_UpdateFlowOutput_402656606, base: "/",
    makeUrl: url_UpdateFlowOutput_402656607,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RemoveFlowOutput_402656622 = ref object of OpenApiRestCall_402656038
proc url_RemoveFlowOutput_402656624(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  assert "outputArn" in path, "`outputArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
                 (kind: VariableSegment, value: "flowArn"),
                 (kind: ConstantSegment, value: "/outputs/"),
                 (kind: VariableSegment, value: "outputArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RemoveFlowOutput_402656623(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
                                 ##          : The flow that you want to remove an output from.
  ##   
                                                                                               ## outputArn: JString (required)
                                                                                               ##            
                                                                                               ## : 
                                                                                               ## The 
                                                                                               ## ARN 
                                                                                               ## of 
                                                                                               ## the 
                                                                                               ## output 
                                                                                               ## that 
                                                                                               ## you 
                                                                                               ## want 
                                                                                               ## to 
                                                                                               ## remove.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `flowArn` field"
  var valid_402656625 = path.getOrDefault("flowArn")
  valid_402656625 = validateParameter(valid_402656625, JString, required = true,
                                      default = nil)
  if valid_402656625 != nil:
    section.add "flowArn", valid_402656625
  var valid_402656626 = path.getOrDefault("outputArn")
  valid_402656626 = validateParameter(valid_402656626, JString, required = true,
                                      default = nil)
  if valid_402656626 != nil:
    section.add "outputArn", valid_402656626
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
  var valid_402656627 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656627 = validateParameter(valid_402656627, JString,
                                      required = false, default = nil)
  if valid_402656627 != nil:
    section.add "X-Amz-Security-Token", valid_402656627
  var valid_402656628 = header.getOrDefault("X-Amz-Signature")
  valid_402656628 = validateParameter(valid_402656628, JString,
                                      required = false, default = nil)
  if valid_402656628 != nil:
    section.add "X-Amz-Signature", valid_402656628
  var valid_402656629 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656629 = validateParameter(valid_402656629, JString,
                                      required = false, default = nil)
  if valid_402656629 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656629
  var valid_402656630 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656630 = validateParameter(valid_402656630, JString,
                                      required = false, default = nil)
  if valid_402656630 != nil:
    section.add "X-Amz-Algorithm", valid_402656630
  var valid_402656631 = header.getOrDefault("X-Amz-Date")
  valid_402656631 = validateParameter(valid_402656631, JString,
                                      required = false, default = nil)
  if valid_402656631 != nil:
    section.add "X-Amz-Date", valid_402656631
  var valid_402656632 = header.getOrDefault("X-Amz-Credential")
  valid_402656632 = validateParameter(valid_402656632, JString,
                                      required = false, default = nil)
  if valid_402656632 != nil:
    section.add "X-Amz-Credential", valid_402656632
  var valid_402656633 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656633 = validateParameter(valid_402656633, JString,
                                      required = false, default = nil)
  if valid_402656633 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656633
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656634: Call_RemoveFlowOutput_402656622;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
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

proc call*(call_402656635: Call_RemoveFlowOutput_402656622; flowArn: string;
           outputArn: string): Recallable =
  ## removeFlowOutput
  ## Removes an output from an existing flow. This request can be made only on an output that does not have an entitlement associated with it. If the output has an entitlement, you must revoke the entitlement instead. When an entitlement is revoked from a flow, the service automatically removes the associated output.
  ##   
                                                                                                                                                                                                                                                                                                                              ## flowArn: string (required)
                                                                                                                                                                                                                                                                                                                              ##          
                                                                                                                                                                                                                                                                                                                              ## : 
                                                                                                                                                                                                                                                                                                                              ## The 
                                                                                                                                                                                                                                                                                                                              ## flow 
                                                                                                                                                                                                                                                                                                                              ## that 
                                                                                                                                                                                                                                                                                                                              ## you 
                                                                                                                                                                                                                                                                                                                              ## want 
                                                                                                                                                                                                                                                                                                                              ## to 
                                                                                                                                                                                                                                                                                                                              ## remove 
                                                                                                                                                                                                                                                                                                                              ## an 
                                                                                                                                                                                                                                                                                                                              ## output 
                                                                                                                                                                                                                                                                                                                              ## from.
  ##   
                                                                                                                                                                                                                                                                                                                                      ## outputArn: string (required)
                                                                                                                                                                                                                                                                                                                                      ##            
                                                                                                                                                                                                                                                                                                                                      ## : 
                                                                                                                                                                                                                                                                                                                                      ## The 
                                                                                                                                                                                                                                                                                                                                      ## ARN 
                                                                                                                                                                                                                                                                                                                                      ## of 
                                                                                                                                                                                                                                                                                                                                      ## the 
                                                                                                                                                                                                                                                                                                                                      ## output 
                                                                                                                                                                                                                                                                                                                                      ## that 
                                                                                                                                                                                                                                                                                                                                      ## you 
                                                                                                                                                                                                                                                                                                                                      ## want 
                                                                                                                                                                                                                                                                                                                                      ## to 
                                                                                                                                                                                                                                                                                                                                      ## remove.
  var path_402656636 = newJObject()
  add(path_402656636, "flowArn", newJString(flowArn))
  add(path_402656636, "outputArn", newJString(outputArn))
  result = call_402656635.call(path_402656636, nil, nil, nil, nil)

var removeFlowOutput* = Call_RemoveFlowOutput_402656622(
    name: "removeFlowOutput", meth: HttpMethod.HttpDelete,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/outputs/{outputArn}",
    validator: validate_RemoveFlowOutput_402656623, base: "/",
    makeUrl: url_RemoveFlowOutput_402656624,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowEntitlement_402656637 = ref object of OpenApiRestCall_402656038
proc url_UpdateFlowEntitlement_402656639(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  assert "entitlementArn" in path,
         "`entitlementArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
                 (kind: VariableSegment, value: "flowArn"),
                 (kind: ConstantSegment, value: "/entitlements/"),
                 (kind: VariableSegment, value: "entitlementArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFlowEntitlement_402656638(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   entitlementArn: JString (required)
                                 ##                 : The ARN of the entitlement that you want to update.
  ##   
                                                                                                         ## flowArn: JString (required)
                                                                                                         ##          
                                                                                                         ## : 
                                                                                                         ## The 
                                                                                                         ## flow 
                                                                                                         ## that 
                                                                                                         ## is 
                                                                                                         ## associated 
                                                                                                         ## with 
                                                                                                         ## the 
                                                                                                         ## entitlement 
                                                                                                         ## that 
                                                                                                         ## you 
                                                                                                         ## want 
                                                                                                         ## to 
                                                                                                         ## update.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `entitlementArn` field"
  var valid_402656640 = path.getOrDefault("entitlementArn")
  valid_402656640 = validateParameter(valid_402656640, JString, required = true,
                                      default = nil)
  if valid_402656640 != nil:
    section.add "entitlementArn", valid_402656640
  var valid_402656641 = path.getOrDefault("flowArn")
  valid_402656641 = validateParameter(valid_402656641, JString, required = true,
                                      default = nil)
  if valid_402656641 != nil:
    section.add "flowArn", valid_402656641
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

proc call*(call_402656650: Call_UpdateFlowEntitlement_402656637;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
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

proc call*(call_402656651: Call_UpdateFlowEntitlement_402656637;
           entitlementArn: string; flowArn: string; body: JsonNode): Recallable =
  ## updateFlowEntitlement
  ## You can change an entitlement's description, subscribers, and encryption. If you change the subscribers, the service will remove the outputs that are are used by the subscribers that are removed.
  ##   
                                                                                                                                                                                                        ## entitlementArn: string (required)
                                                                                                                                                                                                        ##                 
                                                                                                                                                                                                        ## : 
                                                                                                                                                                                                        ## The 
                                                                                                                                                                                                        ## ARN 
                                                                                                                                                                                                        ## of 
                                                                                                                                                                                                        ## the 
                                                                                                                                                                                                        ## entitlement 
                                                                                                                                                                                                        ## that 
                                                                                                                                                                                                        ## you 
                                                                                                                                                                                                        ## want 
                                                                                                                                                                                                        ## to 
                                                                                                                                                                                                        ## update.
  ##   
                                                                                                                                                                                                                  ## flowArn: string (required)
                                                                                                                                                                                                                  ##          
                                                                                                                                                                                                                  ## : 
                                                                                                                                                                                                                  ## The 
                                                                                                                                                                                                                  ## flow 
                                                                                                                                                                                                                  ## that 
                                                                                                                                                                                                                  ## is 
                                                                                                                                                                                                                  ## associated 
                                                                                                                                                                                                                  ## with 
                                                                                                                                                                                                                  ## the 
                                                                                                                                                                                                                  ## entitlement 
                                                                                                                                                                                                                  ## that 
                                                                                                                                                                                                                  ## you 
                                                                                                                                                                                                                  ## want 
                                                                                                                                                                                                                  ## to 
                                                                                                                                                                                                                  ## update.
  ##   
                                                                                                                                                                                                                            ## body: JObject (required)
  var path_402656652 = newJObject()
  var body_402656653 = newJObject()
  add(path_402656652, "entitlementArn", newJString(entitlementArn))
  add(path_402656652, "flowArn", newJString(flowArn))
  if body != nil:
    body_402656653 = body
  result = call_402656651.call(path_402656652, nil, nil, nil, body_402656653)

var updateFlowEntitlement* = Call_UpdateFlowEntitlement_402656637(
    name: "updateFlowEntitlement", meth: HttpMethod.HttpPut,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/entitlements/{entitlementArn}",
    validator: validate_UpdateFlowEntitlement_402656638, base: "/",
    makeUrl: url_UpdateFlowEntitlement_402656639,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RevokeFlowEntitlement_402656654 = ref object of OpenApiRestCall_402656038
proc url_RevokeFlowEntitlement_402656656(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  assert "entitlementArn" in path,
         "`entitlementArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
                 (kind: VariableSegment, value: "flowArn"),
                 (kind: ConstantSegment, value: "/entitlements/"),
                 (kind: VariableSegment, value: "entitlementArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RevokeFlowEntitlement_402656655(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   entitlementArn: JString (required)
                                 ##                 : The ARN of the entitlement that you want to revoke.
  ##   
                                                                                                         ## flowArn: JString (required)
                                                                                                         ##          
                                                                                                         ## : 
                                                                                                         ## The 
                                                                                                         ## flow 
                                                                                                         ## that 
                                                                                                         ## you 
                                                                                                         ## want 
                                                                                                         ## to 
                                                                                                         ## revoke 
                                                                                                         ## an 
                                                                                                         ## entitlement 
                                                                                                         ## from.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `entitlementArn` field"
  var valid_402656657 = path.getOrDefault("entitlementArn")
  valid_402656657 = validateParameter(valid_402656657, JString, required = true,
                                      default = nil)
  if valid_402656657 != nil:
    section.add "entitlementArn", valid_402656657
  var valid_402656658 = path.getOrDefault("flowArn")
  valid_402656658 = validateParameter(valid_402656658, JString, required = true,
                                      default = nil)
  if valid_402656658 != nil:
    section.add "flowArn", valid_402656658
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
  var valid_402656659 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656659 = validateParameter(valid_402656659, JString,
                                      required = false, default = nil)
  if valid_402656659 != nil:
    section.add "X-Amz-Security-Token", valid_402656659
  var valid_402656660 = header.getOrDefault("X-Amz-Signature")
  valid_402656660 = validateParameter(valid_402656660, JString,
                                      required = false, default = nil)
  if valid_402656660 != nil:
    section.add "X-Amz-Signature", valid_402656660
  var valid_402656661 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656661 = validateParameter(valid_402656661, JString,
                                      required = false, default = nil)
  if valid_402656661 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656661
  var valid_402656662 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656662 = validateParameter(valid_402656662, JString,
                                      required = false, default = nil)
  if valid_402656662 != nil:
    section.add "X-Amz-Algorithm", valid_402656662
  var valid_402656663 = header.getOrDefault("X-Amz-Date")
  valid_402656663 = validateParameter(valid_402656663, JString,
                                      required = false, default = nil)
  if valid_402656663 != nil:
    section.add "X-Amz-Date", valid_402656663
  var valid_402656664 = header.getOrDefault("X-Amz-Credential")
  valid_402656664 = validateParameter(valid_402656664, JString,
                                      required = false, default = nil)
  if valid_402656664 != nil:
    section.add "X-Amz-Credential", valid_402656664
  var valid_402656665 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656665 = validateParameter(valid_402656665, JString,
                                      required = false, default = nil)
  if valid_402656665 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656665
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656666: Call_RevokeFlowEntitlement_402656654;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
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

proc call*(call_402656667: Call_RevokeFlowEntitlement_402656654;
           entitlementArn: string; flowArn: string): Recallable =
  ## revokeFlowEntitlement
  ## Revokes an entitlement from a flow. Once an entitlement is revoked, the content becomes unavailable to the subscriber and the associated output is removed.
  ##   
                                                                                                                                                                ## entitlementArn: string (required)
                                                                                                                                                                ##                 
                                                                                                                                                                ## : 
                                                                                                                                                                ## The 
                                                                                                                                                                ## ARN 
                                                                                                                                                                ## of 
                                                                                                                                                                ## the 
                                                                                                                                                                ## entitlement 
                                                                                                                                                                ## that 
                                                                                                                                                                ## you 
                                                                                                                                                                ## want 
                                                                                                                                                                ## to 
                                                                                                                                                                ## revoke.
  ##   
                                                                                                                                                                          ## flowArn: string (required)
                                                                                                                                                                          ##          
                                                                                                                                                                          ## : 
                                                                                                                                                                          ## The 
                                                                                                                                                                          ## flow 
                                                                                                                                                                          ## that 
                                                                                                                                                                          ## you 
                                                                                                                                                                          ## want 
                                                                                                                                                                          ## to 
                                                                                                                                                                          ## revoke 
                                                                                                                                                                          ## an 
                                                                                                                                                                          ## entitlement 
                                                                                                                                                                          ## from.
  var path_402656668 = newJObject()
  add(path_402656668, "entitlementArn", newJString(entitlementArn))
  add(path_402656668, "flowArn", newJString(flowArn))
  result = call_402656667.call(path_402656668, nil, nil, nil, nil)

var revokeFlowEntitlement* = Call_RevokeFlowEntitlement_402656654(
    name: "revokeFlowEntitlement", meth: HttpMethod.HttpDelete,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/entitlements/{entitlementArn}",
    validator: validate_RevokeFlowEntitlement_402656655, base: "/",
    makeUrl: url_RevokeFlowEntitlement_402656656,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartFlow_402656669 = ref object of OpenApiRestCall_402656038
proc url_StartFlow_402656671(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/start/"),
                 (kind: VariableSegment, value: "flowArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartFlow_402656670(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Starts a flow.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
                                 ##          : The ARN of the flow that you want to start.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `flowArn` field"
  var valid_402656672 = path.getOrDefault("flowArn")
  valid_402656672 = validateParameter(valid_402656672, JString, required = true,
                                      default = nil)
  if valid_402656672 != nil:
    section.add "flowArn", valid_402656672
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
  if body != nil:
    result.add "body", body

proc call*(call_402656680: Call_StartFlow_402656669; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts a flow.
                                                                                         ## 
  let valid = call_402656680.validator(path, query, header, formData, body, _)
  let scheme = call_402656680.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656680.makeUrl(scheme.get, call_402656680.host, call_402656680.base,
                                   call_402656680.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656680, uri, valid, _)

proc call*(call_402656681: Call_StartFlow_402656669; flowArn: string): Recallable =
  ## startFlow
  ## Starts a flow.
  ##   flowArn: string (required)
                   ##          : The ARN of the flow that you want to start.
  var path_402656682 = newJObject()
  add(path_402656682, "flowArn", newJString(flowArn))
  result = call_402656681.call(path_402656682, nil, nil, nil, nil)

var startFlow* = Call_StartFlow_402656669(name: "startFlow",
    meth: HttpMethod.HttpPost, host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/start/{flowArn}", validator: validate_StartFlow_402656670,
    base: "/", makeUrl: url_StartFlow_402656671,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopFlow_402656683 = ref object of OpenApiRestCall_402656038
proc url_StopFlow_402656685(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/stop/"),
                 (kind: VariableSegment, value: "flowArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopFlow_402656684(path: JsonNode; query: JsonNode;
                                 header: JsonNode; formData: JsonNode;
                                 body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Stops a flow.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
                                 ##          : The ARN of the flow that you want to stop.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `flowArn` field"
  var valid_402656686 = path.getOrDefault("flowArn")
  valid_402656686 = validateParameter(valid_402656686, JString, required = true,
                                      default = nil)
  if valid_402656686 != nil:
    section.add "flowArn", valid_402656686
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
  var valid_402656687 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656687 = validateParameter(valid_402656687, JString,
                                      required = false, default = nil)
  if valid_402656687 != nil:
    section.add "X-Amz-Security-Token", valid_402656687
  var valid_402656688 = header.getOrDefault("X-Amz-Signature")
  valid_402656688 = validateParameter(valid_402656688, JString,
                                      required = false, default = nil)
  if valid_402656688 != nil:
    section.add "X-Amz-Signature", valid_402656688
  var valid_402656689 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656689 = validateParameter(valid_402656689, JString,
                                      required = false, default = nil)
  if valid_402656689 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656689
  var valid_402656690 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656690 = validateParameter(valid_402656690, JString,
                                      required = false, default = nil)
  if valid_402656690 != nil:
    section.add "X-Amz-Algorithm", valid_402656690
  var valid_402656691 = header.getOrDefault("X-Amz-Date")
  valid_402656691 = validateParameter(valid_402656691, JString,
                                      required = false, default = nil)
  if valid_402656691 != nil:
    section.add "X-Amz-Date", valid_402656691
  var valid_402656692 = header.getOrDefault("X-Amz-Credential")
  valid_402656692 = validateParameter(valid_402656692, JString,
                                      required = false, default = nil)
  if valid_402656692 != nil:
    section.add "X-Amz-Credential", valid_402656692
  var valid_402656693 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656693 = validateParameter(valid_402656693, JString,
                                      required = false, default = nil)
  if valid_402656693 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656693
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656694: Call_StopFlow_402656683; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a flow.
                                                                                         ## 
  let valid = call_402656694.validator(path, query, header, formData, body, _)
  let scheme = call_402656694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656694.makeUrl(scheme.get, call_402656694.host, call_402656694.base,
                                   call_402656694.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656694, uri, valid, _)

proc call*(call_402656695: Call_StopFlow_402656683; flowArn: string): Recallable =
  ## stopFlow
  ## Stops a flow.
  ##   flowArn: string (required)
                  ##          : The ARN of the flow that you want to stop.
  var path_402656696 = newJObject()
  add(path_402656696, "flowArn", newJString(flowArn))
  result = call_402656695.call(path_402656696, nil, nil, nil, nil)

var stopFlow* = Call_StopFlow_402656683(name: "stopFlow",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediaconnect.amazonaws.com",
                                        route: "/v1/flows/stop/{flowArn}",
                                        validator: validate_StopFlow_402656684,
                                        base: "/", makeUrl: url_StopFlow_402656685,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_402656697 = ref object of OpenApiRestCall_402656038
proc url_UntagResource_402656699(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resourceArn" in path, "`resourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
                 (kind: VariableSegment, value: "resourceArn"),
                 (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_402656698(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes specified tags from a resource.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resourceArn: JString (required)
                                 ##              : The Amazon Resource Name (ARN) that identifies the AWS Elemental MediaConnect resource from which to delete tags.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `resourceArn` field"
  var valid_402656700 = path.getOrDefault("resourceArn")
  valid_402656700 = validateParameter(valid_402656700, JString, required = true,
                                      default = nil)
  if valid_402656700 != nil:
    section.add "resourceArn", valid_402656700
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
                                  ##          : The keys of the tags to be removed.
  section = newJObject()
  assert query != nil,
         "query argument is necessary due to required `tagKeys` field"
  var valid_402656701 = query.getOrDefault("tagKeys")
  valid_402656701 = validateParameter(valid_402656701, JArray, required = true,
                                      default = nil)
  if valid_402656701 != nil:
    section.add "tagKeys", valid_402656701
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
  var valid_402656702 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656702 = validateParameter(valid_402656702, JString,
                                      required = false, default = nil)
  if valid_402656702 != nil:
    section.add "X-Amz-Security-Token", valid_402656702
  var valid_402656703 = header.getOrDefault("X-Amz-Signature")
  valid_402656703 = validateParameter(valid_402656703, JString,
                                      required = false, default = nil)
  if valid_402656703 != nil:
    section.add "X-Amz-Signature", valid_402656703
  var valid_402656704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656704 = validateParameter(valid_402656704, JString,
                                      required = false, default = nil)
  if valid_402656704 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656704
  var valid_402656705 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656705 = validateParameter(valid_402656705, JString,
                                      required = false, default = nil)
  if valid_402656705 != nil:
    section.add "X-Amz-Algorithm", valid_402656705
  var valid_402656706 = header.getOrDefault("X-Amz-Date")
  valid_402656706 = validateParameter(valid_402656706, JString,
                                      required = false, default = nil)
  if valid_402656706 != nil:
    section.add "X-Amz-Date", valid_402656706
  var valid_402656707 = header.getOrDefault("X-Amz-Credential")
  valid_402656707 = validateParameter(valid_402656707, JString,
                                      required = false, default = nil)
  if valid_402656707 != nil:
    section.add "X-Amz-Credential", valid_402656707
  var valid_402656708 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656708 = validateParameter(valid_402656708, JString,
                                      required = false, default = nil)
  if valid_402656708 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656708
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656709: Call_UntagResource_402656697; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes specified tags from a resource.
                                                                                         ## 
  let valid = call_402656709.validator(path, query, header, formData, body, _)
  let scheme = call_402656709.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656709.makeUrl(scheme.get, call_402656709.host, call_402656709.base,
                                   call_402656709.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656709, uri, valid, _)

proc call*(call_402656710: Call_UntagResource_402656697; tagKeys: JsonNode;
           resourceArn: string): Recallable =
  ## untagResource
  ## Deletes specified tags from a resource.
  ##   tagKeys: JArray (required)
                                            ##          : The keys of the tags to be removed.
  ##   
                                                                                             ## resourceArn: string (required)
                                                                                             ##              
                                                                                             ## : 
                                                                                             ## The 
                                                                                             ## Amazon 
                                                                                             ## Resource 
                                                                                             ## Name 
                                                                                             ## (ARN) 
                                                                                             ## that 
                                                                                             ## identifies 
                                                                                             ## the 
                                                                                             ## AWS 
                                                                                             ## Elemental 
                                                                                             ## MediaConnect 
                                                                                             ## resource 
                                                                                             ## from 
                                                                                             ## which 
                                                                                             ## to 
                                                                                             ## delete 
                                                                                             ## tags.
  var path_402656711 = newJObject()
  var query_402656712 = newJObject()
  if tagKeys != nil:
    query_402656712.add "tagKeys", tagKeys
  add(path_402656711, "resourceArn", newJString(resourceArn))
  result = call_402656710.call(path_402656711, query_402656712, nil, nil, nil)

var untagResource* = Call_UntagResource_402656697(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "mediaconnect.amazonaws.com",
    route: "/tags/{resourceArn}#tagKeys", validator: validate_UntagResource_402656698,
    base: "/", makeUrl: url_UntagResource_402656699,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateFlowSource_402656713 = ref object of OpenApiRestCall_402656038
proc url_UpdateFlowSource_402656715(protocol: Scheme; host: string;
                                    base: string; route: string; path: JsonNode;
                                    query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "flowArn" in path, "`flowArn` is a required path parameter"
  assert "sourceArn" in path, "`sourceArn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/v1/flows/"),
                 (kind: VariableSegment, value: "flowArn"),
                 (kind: ConstantSegment, value: "/source/"),
                 (kind: VariableSegment, value: "sourceArn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateFlowSource_402656714(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates the source of a flow.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   flowArn: JString (required)
                                 ##          : The flow that is associated with the source that you want to update.
  ##   
                                                                                                                   ## sourceArn: JString (required)
                                                                                                                   ##            
                                                                                                                   ## : 
                                                                                                                   ## The 
                                                                                                                   ## ARN 
                                                                                                                   ## of 
                                                                                                                   ## the 
                                                                                                                   ## source 
                                                                                                                   ## that 
                                                                                                                   ## you 
                                                                                                                   ## want 
                                                                                                                   ## to 
                                                                                                                   ## update.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `flowArn` field"
  var valid_402656716 = path.getOrDefault("flowArn")
  valid_402656716 = validateParameter(valid_402656716, JString, required = true,
                                      default = nil)
  if valid_402656716 != nil:
    section.add "flowArn", valid_402656716
  var valid_402656717 = path.getOrDefault("sourceArn")
  valid_402656717 = validateParameter(valid_402656717, JString, required = true,
                                      default = nil)
  if valid_402656717 != nil:
    section.add "sourceArn", valid_402656717
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

proc call*(call_402656726: Call_UpdateFlowSource_402656713;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates the source of a flow.
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

proc call*(call_402656727: Call_UpdateFlowSource_402656713; flowArn: string;
           sourceArn: string; body: JsonNode): Recallable =
  ## updateFlowSource
  ## Updates the source of a flow.
  ##   flowArn: string (required)
                                  ##          : The flow that is associated with the source that you want to update.
  ##   
                                                                                                                    ## sourceArn: string (required)
                                                                                                                    ##            
                                                                                                                    ## : 
                                                                                                                    ## The 
                                                                                                                    ## ARN 
                                                                                                                    ## of 
                                                                                                                    ## the 
                                                                                                                    ## source 
                                                                                                                    ## that 
                                                                                                                    ## you 
                                                                                                                    ## want 
                                                                                                                    ## to 
                                                                                                                    ## update.
  ##   
                                                                                                                              ## body: JObject (required)
  var path_402656728 = newJObject()
  var body_402656729 = newJObject()
  add(path_402656728, "flowArn", newJString(flowArn))
  add(path_402656728, "sourceArn", newJString(sourceArn))
  if body != nil:
    body_402656729 = body
  result = call_402656727.call(path_402656728, nil, nil, nil, body_402656729)

var updateFlowSource* = Call_UpdateFlowSource_402656713(
    name: "updateFlowSource", meth: HttpMethod.HttpPut,
    host: "mediaconnect.amazonaws.com",
    route: "/v1/flows/{flowArn}/source/{sourceArn}",
    validator: validate_UpdateFlowSource_402656714, base: "/",
    makeUrl: url_UpdateFlowSource_402656715,
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