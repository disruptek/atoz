
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5,
  base64, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Outposts
## version: 2019-12-03
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS Outposts is a fully-managed service that extends AWS infrastructure, APIs, and tools to customer premises. By providing local access to AWS-managed infrastructure, AWS Outposts enables customers to build and run applications on premises using the same programming interfaces as in AWS Regions, while using local compute and storage resources for lower latency and local data processing needs.
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/outposts/
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
  awsServers = {Scheme.Https: {"ap-northeast-1": "outposts.ap-northeast-1.amazonaws.com", "ap-southeast-1": "outposts.ap-southeast-1.amazonaws.com",
                               "us-west-2": "outposts.us-west-2.amazonaws.com",
                               "eu-west-2": "outposts.eu-west-2.amazonaws.com", "ap-northeast-3": "outposts.ap-northeast-3.amazonaws.com", "eu-central-1": "outposts.eu-central-1.amazonaws.com",
                               "us-east-2": "outposts.us-east-2.amazonaws.com",
                               "us-east-1": "outposts.us-east-1.amazonaws.com", "cn-northwest-1": "outposts.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "outposts.ap-south-1.amazonaws.com", "eu-north-1": "outposts.eu-north-1.amazonaws.com", "ap-northeast-2": "outposts.ap-northeast-2.amazonaws.com",
                               "us-west-1": "outposts.us-west-1.amazonaws.com", "us-gov-east-1": "outposts.us-gov-east-1.amazonaws.com",
                               "eu-west-3": "outposts.eu-west-3.amazonaws.com", "cn-north-1": "outposts.cn-north-1.amazonaws.com.cn",
                               "sa-east-1": "outposts.sa-east-1.amazonaws.com",
                               "eu-west-1": "outposts.eu-west-1.amazonaws.com", "us-gov-west-1": "outposts.us-gov-west-1.amazonaws.com", "ap-southeast-2": "outposts.ap-southeast-2.amazonaws.com", "ca-central-1": "outposts.ca-central-1.amazonaws.com"}.toTable, Scheme.Http: {
      "ap-northeast-1": "outposts.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "outposts.ap-southeast-1.amazonaws.com",
      "us-west-2": "outposts.us-west-2.amazonaws.com",
      "eu-west-2": "outposts.eu-west-2.amazonaws.com",
      "ap-northeast-3": "outposts.ap-northeast-3.amazonaws.com",
      "eu-central-1": "outposts.eu-central-1.amazonaws.com",
      "us-east-2": "outposts.us-east-2.amazonaws.com",
      "us-east-1": "outposts.us-east-1.amazonaws.com",
      "cn-northwest-1": "outposts.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "outposts.ap-south-1.amazonaws.com",
      "eu-north-1": "outposts.eu-north-1.amazonaws.com",
      "ap-northeast-2": "outposts.ap-northeast-2.amazonaws.com",
      "us-west-1": "outposts.us-west-1.amazonaws.com",
      "us-gov-east-1": "outposts.us-gov-east-1.amazonaws.com",
      "eu-west-3": "outposts.eu-west-3.amazonaws.com",
      "cn-north-1": "outposts.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "outposts.sa-east-1.amazonaws.com",
      "eu-west-1": "outposts.eu-west-1.amazonaws.com",
      "us-gov-west-1": "outposts.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "outposts.ap-southeast-2.amazonaws.com",
      "ca-central-1": "outposts.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "outposts"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode;
                body: string = ""): Recallable {.base.}
type
  Call_CreateOutpost_402656471 = ref object of OpenApiRestCall_402656038
proc url_CreateOutpost_402656473(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateOutpost_402656472(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates an Outpost.
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
  var valid_402656474 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656474 = validateParameter(valid_402656474, JString,
                                      required = false, default = nil)
  if valid_402656474 != nil:
    section.add "X-Amz-Security-Token", valid_402656474
  var valid_402656475 = header.getOrDefault("X-Amz-Signature")
  valid_402656475 = validateParameter(valid_402656475, JString,
                                      required = false, default = nil)
  if valid_402656475 != nil:
    section.add "X-Amz-Signature", valid_402656475
  var valid_402656476 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656476 = validateParameter(valid_402656476, JString,
                                      required = false, default = nil)
  if valid_402656476 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656476
  var valid_402656477 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656477 = validateParameter(valid_402656477, JString,
                                      required = false, default = nil)
  if valid_402656477 != nil:
    section.add "X-Amz-Algorithm", valid_402656477
  var valid_402656478 = header.getOrDefault("X-Amz-Date")
  valid_402656478 = validateParameter(valid_402656478, JString,
                                      required = false, default = nil)
  if valid_402656478 != nil:
    section.add "X-Amz-Date", valid_402656478
  var valid_402656479 = header.getOrDefault("X-Amz-Credential")
  valid_402656479 = validateParameter(valid_402656479, JString,
                                      required = false, default = nil)
  if valid_402656479 != nil:
    section.add "X-Amz-Credential", valid_402656479
  var valid_402656480 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656480 = validateParameter(valid_402656480, JString,
                                      required = false, default = nil)
  if valid_402656480 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656480
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

proc call*(call_402656482: Call_CreateOutpost_402656471; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an Outpost.
                                                                                         ## 
  let valid = call_402656482.validator(path, query, header, formData, body, _)
  let scheme = call_402656482.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656482.makeUrl(scheme.get, call_402656482.host, call_402656482.base,
                                   call_402656482.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656482, uri, valid, _)

proc call*(call_402656483: Call_CreateOutpost_402656471; body: JsonNode): Recallable =
  ## createOutpost
  ## Creates an Outpost.
  ##   body: JObject (required)
  var body_402656484 = newJObject()
  if body != nil:
    body_402656484 = body
  result = call_402656483.call(nil, nil, nil, nil, body_402656484)

var createOutpost* = Call_CreateOutpost_402656471(name: "createOutpost",
    meth: HttpMethod.HttpPost, host: "outposts.amazonaws.com",
    route: "/outposts", validator: validate_CreateOutpost_402656472, base: "/",
    makeUrl: url_CreateOutpost_402656473, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOutposts_402656288 = ref object of OpenApiRestCall_402656038
proc url_ListOutposts_402656290(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOutposts_402656289(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List the Outposts for your AWS account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
                                  ##             : The maximum page size.
  ##   
                                                                         ## NextToken: JString
                                                                         ##            
                                                                         ## : 
                                                                         ## The 
                                                                         ## pagination 
                                                                         ## token.
  section = newJObject()
  var valid_402656369 = query.getOrDefault("MaxResults")
  valid_402656369 = validateParameter(valid_402656369, JInt, required = false,
                                      default = nil)
  if valid_402656369 != nil:
    section.add "MaxResults", valid_402656369
  var valid_402656370 = query.getOrDefault("NextToken")
  valid_402656370 = validateParameter(valid_402656370, JString,
                                      required = false, default = nil)
  if valid_402656370 != nil:
    section.add "NextToken", valid_402656370
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
  var valid_402656371 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656371 = validateParameter(valid_402656371, JString,
                                      required = false, default = nil)
  if valid_402656371 != nil:
    section.add "X-Amz-Security-Token", valid_402656371
  var valid_402656372 = header.getOrDefault("X-Amz-Signature")
  valid_402656372 = validateParameter(valid_402656372, JString,
                                      required = false, default = nil)
  if valid_402656372 != nil:
    section.add "X-Amz-Signature", valid_402656372
  var valid_402656373 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656373 = validateParameter(valid_402656373, JString,
                                      required = false, default = nil)
  if valid_402656373 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656373
  var valid_402656374 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656374 = validateParameter(valid_402656374, JString,
                                      required = false, default = nil)
  if valid_402656374 != nil:
    section.add "X-Amz-Algorithm", valid_402656374
  var valid_402656375 = header.getOrDefault("X-Amz-Date")
  valid_402656375 = validateParameter(valid_402656375, JString,
                                      required = false, default = nil)
  if valid_402656375 != nil:
    section.add "X-Amz-Date", valid_402656375
  var valid_402656376 = header.getOrDefault("X-Amz-Credential")
  valid_402656376 = validateParameter(valid_402656376, JString,
                                      required = false, default = nil)
  if valid_402656376 != nil:
    section.add "X-Amz-Credential", valid_402656376
  var valid_402656377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656377 = validateParameter(valid_402656377, JString,
                                      required = false, default = nil)
  if valid_402656377 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656391: Call_ListOutposts_402656288; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the Outposts for your AWS account.
                                                                                         ## 
  let valid = call_402656391.validator(path, query, header, formData, body, _)
  let scheme = call_402656391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656391.makeUrl(scheme.get, call_402656391.host, call_402656391.base,
                                   call_402656391.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656391, uri, valid, _)

proc call*(call_402656440: Call_ListOutposts_402656288; MaxResults: int = 0;
           NextToken: string = ""): Recallable =
  ## listOutposts
  ## List the Outposts for your AWS account.
  ##   MaxResults: int
                                            ##             : The maximum page size.
  ##   
                                                                                   ## NextToken: string
                                                                                   ##            
                                                                                   ## : 
                                                                                   ## The 
                                                                                   ## pagination 
                                                                                   ## token.
  var query_402656441 = newJObject()
  add(query_402656441, "MaxResults", newJInt(MaxResults))
  add(query_402656441, "NextToken", newJString(NextToken))
  result = call_402656440.call(nil, query_402656441, nil, nil, nil)

var listOutposts* = Call_ListOutposts_402656288(name: "listOutposts",
    meth: HttpMethod.HttpGet, host: "outposts.amazonaws.com",
    route: "/outposts", validator: validate_ListOutposts_402656289, base: "/",
    makeUrl: url_ListOutposts_402656290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOutpost_402656485 = ref object of OpenApiRestCall_402656038
proc url_GetOutpost_402656487(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "OutpostId" in path, "`OutpostId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/outposts/"),
                 (kind: VariableSegment, value: "OutpostId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetOutpost_402656486(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets information about the specified Outpost.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   OutpostId: JString (required)
                                 ##            : The ID of the Outpost.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `OutpostId` field"
  var valid_402656499 = path.getOrDefault("OutpostId")
  valid_402656499 = validateParameter(valid_402656499, JString, required = true,
                                      default = nil)
  if valid_402656499 != nil:
    section.add "OutpostId", valid_402656499
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
  var valid_402656500 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656500 = validateParameter(valid_402656500, JString,
                                      required = false, default = nil)
  if valid_402656500 != nil:
    section.add "X-Amz-Security-Token", valid_402656500
  var valid_402656501 = header.getOrDefault("X-Amz-Signature")
  valid_402656501 = validateParameter(valid_402656501, JString,
                                      required = false, default = nil)
  if valid_402656501 != nil:
    section.add "X-Amz-Signature", valid_402656501
  var valid_402656502 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656502 = validateParameter(valid_402656502, JString,
                                      required = false, default = nil)
  if valid_402656502 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656502
  var valid_402656503 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656503 = validateParameter(valid_402656503, JString,
                                      required = false, default = nil)
  if valid_402656503 != nil:
    section.add "X-Amz-Algorithm", valid_402656503
  var valid_402656504 = header.getOrDefault("X-Amz-Date")
  valid_402656504 = validateParameter(valid_402656504, JString,
                                      required = false, default = nil)
  if valid_402656504 != nil:
    section.add "X-Amz-Date", valid_402656504
  var valid_402656505 = header.getOrDefault("X-Amz-Credential")
  valid_402656505 = validateParameter(valid_402656505, JString,
                                      required = false, default = nil)
  if valid_402656505 != nil:
    section.add "X-Amz-Credential", valid_402656505
  var valid_402656506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656506 = validateParameter(valid_402656506, JString,
                                      required = false, default = nil)
  if valid_402656506 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656506
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656507: Call_GetOutpost_402656485; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the specified Outpost.
                                                                                         ## 
  let valid = call_402656507.validator(path, query, header, formData, body, _)
  let scheme = call_402656507.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656507.makeUrl(scheme.get, call_402656507.host, call_402656507.base,
                                   call_402656507.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656507, uri, valid, _)

proc call*(call_402656508: Call_GetOutpost_402656485; OutpostId: string): Recallable =
  ## getOutpost
  ## Gets information about the specified Outpost.
  ##   OutpostId: string (required)
                                                  ##            : The ID of the Outpost.
  var path_402656509 = newJObject()
  add(path_402656509, "OutpostId", newJString(OutpostId))
  result = call_402656508.call(path_402656509, nil, nil, nil, nil)

var getOutpost* = Call_GetOutpost_402656485(name: "getOutpost",
    meth: HttpMethod.HttpGet, host: "outposts.amazonaws.com",
    route: "/outposts/{OutpostId}", validator: validate_GetOutpost_402656486,
    base: "/", makeUrl: url_GetOutpost_402656487,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOutpost_402656510 = ref object of OpenApiRestCall_402656038
proc url_DeleteOutpost_402656512(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "OutpostId" in path, "`OutpostId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/outposts/"),
                 (kind: VariableSegment, value: "OutpostId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteOutpost_402656511(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the Outpost.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   OutpostId: JString (required)
                                 ##            : The ID of the Outpost.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `OutpostId` field"
  var valid_402656513 = path.getOrDefault("OutpostId")
  valid_402656513 = validateParameter(valid_402656513, JString, required = true,
                                      default = nil)
  if valid_402656513 != nil:
    section.add "OutpostId", valid_402656513
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
  var valid_402656514 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656514 = validateParameter(valid_402656514, JString,
                                      required = false, default = nil)
  if valid_402656514 != nil:
    section.add "X-Amz-Security-Token", valid_402656514
  var valid_402656515 = header.getOrDefault("X-Amz-Signature")
  valid_402656515 = validateParameter(valid_402656515, JString,
                                      required = false, default = nil)
  if valid_402656515 != nil:
    section.add "X-Amz-Signature", valid_402656515
  var valid_402656516 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656516 = validateParameter(valid_402656516, JString,
                                      required = false, default = nil)
  if valid_402656516 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656516
  var valid_402656517 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656517 = validateParameter(valid_402656517, JString,
                                      required = false, default = nil)
  if valid_402656517 != nil:
    section.add "X-Amz-Algorithm", valid_402656517
  var valid_402656518 = header.getOrDefault("X-Amz-Date")
  valid_402656518 = validateParameter(valid_402656518, JString,
                                      required = false, default = nil)
  if valid_402656518 != nil:
    section.add "X-Amz-Date", valid_402656518
  var valid_402656519 = header.getOrDefault("X-Amz-Credential")
  valid_402656519 = validateParameter(valid_402656519, JString,
                                      required = false, default = nil)
  if valid_402656519 != nil:
    section.add "X-Amz-Credential", valid_402656519
  var valid_402656520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656520 = validateParameter(valid_402656520, JString,
                                      required = false, default = nil)
  if valid_402656520 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656521: Call_DeleteOutpost_402656510; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the Outpost.
                                                                                         ## 
  let valid = call_402656521.validator(path, query, header, formData, body, _)
  let scheme = call_402656521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656521.makeUrl(scheme.get, call_402656521.host, call_402656521.base,
                                   call_402656521.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656521, uri, valid, _)

proc call*(call_402656522: Call_DeleteOutpost_402656510; OutpostId: string): Recallable =
  ## deleteOutpost
  ## Deletes the Outpost.
  ##   OutpostId: string (required)
                         ##            : The ID of the Outpost.
  var path_402656523 = newJObject()
  add(path_402656523, "OutpostId", newJString(OutpostId))
  result = call_402656522.call(path_402656523, nil, nil, nil, nil)

var deleteOutpost* = Call_DeleteOutpost_402656510(name: "deleteOutpost",
    meth: HttpMethod.HttpDelete, host: "outposts.amazonaws.com",
    route: "/outposts/{OutpostId}", validator: validate_DeleteOutpost_402656511,
    base: "/", makeUrl: url_DeleteOutpost_402656512,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSite_402656524 = ref object of OpenApiRestCall_402656038
proc url_DeleteSite_402656526(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "SiteId" in path, "`SiteId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/sites/"),
                 (kind: VariableSegment, value: "SiteId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSite_402656525(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the site.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SiteId: JString (required)
                                 ##         : The ID of the site.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `SiteId` field"
  var valid_402656527 = path.getOrDefault("SiteId")
  valid_402656527 = validateParameter(valid_402656527, JString, required = true,
                                      default = nil)
  if valid_402656527 != nil:
    section.add "SiteId", valid_402656527
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
  var valid_402656528 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656528 = validateParameter(valid_402656528, JString,
                                      required = false, default = nil)
  if valid_402656528 != nil:
    section.add "X-Amz-Security-Token", valid_402656528
  var valid_402656529 = header.getOrDefault("X-Amz-Signature")
  valid_402656529 = validateParameter(valid_402656529, JString,
                                      required = false, default = nil)
  if valid_402656529 != nil:
    section.add "X-Amz-Signature", valid_402656529
  var valid_402656530 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656530 = validateParameter(valid_402656530, JString,
                                      required = false, default = nil)
  if valid_402656530 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656530
  var valid_402656531 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656531 = validateParameter(valid_402656531, JString,
                                      required = false, default = nil)
  if valid_402656531 != nil:
    section.add "X-Amz-Algorithm", valid_402656531
  var valid_402656532 = header.getOrDefault("X-Amz-Date")
  valid_402656532 = validateParameter(valid_402656532, JString,
                                      required = false, default = nil)
  if valid_402656532 != nil:
    section.add "X-Amz-Date", valid_402656532
  var valid_402656533 = header.getOrDefault("X-Amz-Credential")
  valid_402656533 = validateParameter(valid_402656533, JString,
                                      required = false, default = nil)
  if valid_402656533 != nil:
    section.add "X-Amz-Credential", valid_402656533
  var valid_402656534 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656534 = validateParameter(valid_402656534, JString,
                                      required = false, default = nil)
  if valid_402656534 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656534
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656535: Call_DeleteSite_402656524; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the site.
                                                                                         ## 
  let valid = call_402656535.validator(path, query, header, formData, body, _)
  let scheme = call_402656535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656535.makeUrl(scheme.get, call_402656535.host, call_402656535.base,
                                   call_402656535.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656535, uri, valid, _)

proc call*(call_402656536: Call_DeleteSite_402656524; SiteId: string): Recallable =
  ## deleteSite
  ## Deletes the site.
  ##   SiteId: string (required)
                      ##         : The ID of the site.
  var path_402656537 = newJObject()
  add(path_402656537, "SiteId", newJString(SiteId))
  result = call_402656536.call(path_402656537, nil, nil, nil, nil)

var deleteSite* = Call_DeleteSite_402656524(name: "deleteSite",
    meth: HttpMethod.HttpDelete, host: "outposts.amazonaws.com",
    route: "/sites/{SiteId}", validator: validate_DeleteSite_402656525,
    base: "/", makeUrl: url_DeleteSite_402656526,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOutpostInstanceTypes_402656538 = ref object of OpenApiRestCall_402656038
proc url_GetOutpostInstanceTypes_402656540(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "OutpostId" in path, "`OutpostId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/outposts/"),
                 (kind: VariableSegment, value: "OutpostId"),
                 (kind: ConstantSegment, value: "/instanceTypes")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetOutpostInstanceTypes_402656539(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the instance types for the specified Outpost.
                ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   OutpostId: JString (required)
                                 ##            : The ID of the Outpost.
  section = newJObject()
  assert path != nil,
         "path argument is necessary due to required `OutpostId` field"
  var valid_402656541 = path.getOrDefault("OutpostId")
  valid_402656541 = validateParameter(valid_402656541, JString, required = true,
                                      default = nil)
  if valid_402656541 != nil:
    section.add "OutpostId", valid_402656541
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
                                  ##             : The maximum page size.
  ##   
                                                                         ## NextToken: JString
                                                                         ##            
                                                                         ## : 
                                                                         ## The 
                                                                         ## pagination 
                                                                         ## token.
  section = newJObject()
  var valid_402656542 = query.getOrDefault("MaxResults")
  valid_402656542 = validateParameter(valid_402656542, JInt, required = false,
                                      default = nil)
  if valid_402656542 != nil:
    section.add "MaxResults", valid_402656542
  var valid_402656543 = query.getOrDefault("NextToken")
  valid_402656543 = validateParameter(valid_402656543, JString,
                                      required = false, default = nil)
  if valid_402656543 != nil:
    section.add "NextToken", valid_402656543
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
  var valid_402656544 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656544 = validateParameter(valid_402656544, JString,
                                      required = false, default = nil)
  if valid_402656544 != nil:
    section.add "X-Amz-Security-Token", valid_402656544
  var valid_402656545 = header.getOrDefault("X-Amz-Signature")
  valid_402656545 = validateParameter(valid_402656545, JString,
                                      required = false, default = nil)
  if valid_402656545 != nil:
    section.add "X-Amz-Signature", valid_402656545
  var valid_402656546 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656546 = validateParameter(valid_402656546, JString,
                                      required = false, default = nil)
  if valid_402656546 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656546
  var valid_402656547 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656547 = validateParameter(valid_402656547, JString,
                                      required = false, default = nil)
  if valid_402656547 != nil:
    section.add "X-Amz-Algorithm", valid_402656547
  var valid_402656548 = header.getOrDefault("X-Amz-Date")
  valid_402656548 = validateParameter(valid_402656548, JString,
                                      required = false, default = nil)
  if valid_402656548 != nil:
    section.add "X-Amz-Date", valid_402656548
  var valid_402656549 = header.getOrDefault("X-Amz-Credential")
  valid_402656549 = validateParameter(valid_402656549, JString,
                                      required = false, default = nil)
  if valid_402656549 != nil:
    section.add "X-Amz-Credential", valid_402656549
  var valid_402656550 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656550 = validateParameter(valid_402656550, JString,
                                      required = false, default = nil)
  if valid_402656550 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656550
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656551: Call_GetOutpostInstanceTypes_402656538;
           path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the instance types for the specified Outpost.
                                                                                         ## 
  let valid = call_402656551.validator(path, query, header, formData, body, _)
  let scheme = call_402656551.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656551.makeUrl(scheme.get, call_402656551.host, call_402656551.base,
                                   call_402656551.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656551, uri, valid, _)

proc call*(call_402656552: Call_GetOutpostInstanceTypes_402656538;
           OutpostId: string; MaxResults: int = 0; NextToken: string = ""): Recallable =
  ## getOutpostInstanceTypes
  ## Lists the instance types for the specified Outpost.
  ##   OutpostId: string (required)
                                                        ##            : The ID of the Outpost.
  ##   
                                                                                              ## MaxResults: int
                                                                                              ##             
                                                                                              ## : 
                                                                                              ## The 
                                                                                              ## maximum 
                                                                                              ## page 
                                                                                              ## size.
  ##   
                                                                                                      ## NextToken: string
                                                                                                      ##            
                                                                                                      ## : 
                                                                                                      ## The 
                                                                                                      ## pagination 
                                                                                                      ## token.
  var path_402656553 = newJObject()
  var query_402656554 = newJObject()
  add(path_402656553, "OutpostId", newJString(OutpostId))
  add(query_402656554, "MaxResults", newJInt(MaxResults))
  add(query_402656554, "NextToken", newJString(NextToken))
  result = call_402656552.call(path_402656553, query_402656554, nil, nil, nil)

var getOutpostInstanceTypes* = Call_GetOutpostInstanceTypes_402656538(
    name: "getOutpostInstanceTypes", meth: HttpMethod.HttpGet,
    host: "outposts.amazonaws.com",
    route: "/outposts/{OutpostId}/instanceTypes",
    validator: validate_GetOutpostInstanceTypes_402656539, base: "/",
    makeUrl: url_GetOutpostInstanceTypes_402656540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSites_402656555 = ref object of OpenApiRestCall_402656038
proc url_ListSites_402656557(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSites_402656556(path: JsonNode; query: JsonNode;
                                  header: JsonNode; formData: JsonNode;
                                  body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Lists the sites for the specified AWS account.
                ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
                                  ##             : The maximum page size.
  ##   
                                                                         ## NextToken: JString
                                                                         ##            
                                                                         ## : 
                                                                         ## The 
                                                                         ## pagination 
                                                                         ## token.
  section = newJObject()
  var valid_402656558 = query.getOrDefault("MaxResults")
  valid_402656558 = validateParameter(valid_402656558, JInt, required = false,
                                      default = nil)
  if valid_402656558 != nil:
    section.add "MaxResults", valid_402656558
  var valid_402656559 = query.getOrDefault("NextToken")
  valid_402656559 = validateParameter(valid_402656559, JString,
                                      required = false, default = nil)
  if valid_402656559 != nil:
    section.add "NextToken", valid_402656559
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
  var valid_402656560 = header.getOrDefault("X-Amz-Security-Token")
  valid_402656560 = validateParameter(valid_402656560, JString,
                                      required = false, default = nil)
  if valid_402656560 != nil:
    section.add "X-Amz-Security-Token", valid_402656560
  var valid_402656561 = header.getOrDefault("X-Amz-Signature")
  valid_402656561 = validateParameter(valid_402656561, JString,
                                      required = false, default = nil)
  if valid_402656561 != nil:
    section.add "X-Amz-Signature", valid_402656561
  var valid_402656562 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_402656562 = validateParameter(valid_402656562, JString,
                                      required = false, default = nil)
  if valid_402656562 != nil:
    section.add "X-Amz-Content-Sha256", valid_402656562
  var valid_402656563 = header.getOrDefault("X-Amz-Algorithm")
  valid_402656563 = validateParameter(valid_402656563, JString,
                                      required = false, default = nil)
  if valid_402656563 != nil:
    section.add "X-Amz-Algorithm", valid_402656563
  var valid_402656564 = header.getOrDefault("X-Amz-Date")
  valid_402656564 = validateParameter(valid_402656564, JString,
                                      required = false, default = nil)
  if valid_402656564 != nil:
    section.add "X-Amz-Date", valid_402656564
  var valid_402656565 = header.getOrDefault("X-Amz-Credential")
  valid_402656565 = validateParameter(valid_402656565, JString,
                                      required = false, default = nil)
  if valid_402656565 != nil:
    section.add "X-Amz-Credential", valid_402656565
  var valid_402656566 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_402656566 = validateParameter(valid_402656566, JString,
                                      required = false, default = nil)
  if valid_402656566 != nil:
    section.add "X-Amz-SignedHeaders", valid_402656566
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_402656567: Call_ListSites_402656555; path: JsonNode = nil;
           query: JsonNode = nil; header: JsonNode = nil;
           formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the sites for the specified AWS account.
                                                                                         ## 
  let valid = call_402656567.validator(path, query, header, formData, body, _)
  let scheme = call_402656567.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_402656567.makeUrl(scheme.get, call_402656567.host, call_402656567.base,
                                   call_402656567.route,
                                   valid.getOrDefault("path"),
                                   valid.getOrDefault("query"))
  result = atozHook(call_402656567, uri, valid, _)

proc call*(call_402656568: Call_ListSites_402656555; MaxResults: int = 0;
           NextToken: string = ""): Recallable =
  ## listSites
  ## Lists the sites for the specified AWS account.
  ##   MaxResults: int
                                                   ##             : The maximum page size.
  ##   
                                                                                          ## NextToken: string
                                                                                          ##            
                                                                                          ## : 
                                                                                          ## The 
                                                                                          ## pagination 
                                                                                          ## token.
  var query_402656569 = newJObject()
  add(query_402656569, "MaxResults", newJInt(MaxResults))
  add(query_402656569, "NextToken", newJString(NextToken))
  result = call_402656568.call(nil, query_402656569, nil, nil, nil)

var listSites* = Call_ListSites_402656555(name: "listSites",
    meth: HttpMethod.HttpGet, host: "outposts.amazonaws.com", route: "/sites",
    validator: validate_ListSites_402656556, base: "/", makeUrl: url_ListSites_402656557,
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