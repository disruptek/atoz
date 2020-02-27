
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, httpcore,
  sigv4

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
  Scheme {.pure.} = enum
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
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_616856 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_616856](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_616856): Option[Scheme] {.used.} =
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

proc hydratePath(input: JsonNode; segments: seq[PathToken]): Option[string] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "outposts.ap-northeast-1.amazonaws.com", "ap-southeast-1": "outposts.ap-southeast-1.amazonaws.com",
                           "us-west-2": "outposts.us-west-2.amazonaws.com",
                           "eu-west-2": "outposts.eu-west-2.amazonaws.com", "ap-northeast-3": "outposts.ap-northeast-3.amazonaws.com", "eu-central-1": "outposts.eu-central-1.amazonaws.com",
                           "us-east-2": "outposts.us-east-2.amazonaws.com",
                           "us-east-1": "outposts.us-east-1.amazonaws.com", "cn-northwest-1": "outposts.cn-northwest-1.amazonaws.com.cn", "ap-northeast-2": "outposts.ap-northeast-2.amazonaws.com",
                           "ap-south-1": "outposts.ap-south-1.amazonaws.com",
                           "eu-north-1": "outposts.eu-north-1.amazonaws.com",
                           "us-west-1": "outposts.us-west-1.amazonaws.com", "us-gov-east-1": "outposts.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "outposts.eu-west-3.amazonaws.com", "cn-north-1": "outposts.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "outposts.sa-east-1.amazonaws.com",
                           "eu-west-1": "outposts.eu-west-1.amazonaws.com", "us-gov-west-1": "outposts.us-gov-west-1.amazonaws.com", "ap-southeast-2": "outposts.ap-southeast-2.amazonaws.com", "ca-central-1": "outposts.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "outposts.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "outposts.ap-southeast-1.amazonaws.com",
      "us-west-2": "outposts.us-west-2.amazonaws.com",
      "eu-west-2": "outposts.eu-west-2.amazonaws.com",
      "ap-northeast-3": "outposts.ap-northeast-3.amazonaws.com",
      "eu-central-1": "outposts.eu-central-1.amazonaws.com",
      "us-east-2": "outposts.us-east-2.amazonaws.com",
      "us-east-1": "outposts.us-east-1.amazonaws.com",
      "cn-northwest-1": "outposts.cn-northwest-1.amazonaws.com.cn",
      "ap-northeast-2": "outposts.ap-northeast-2.amazonaws.com",
      "ap-south-1": "outposts.ap-south-1.amazonaws.com",
      "eu-north-1": "outposts.eu-north-1.amazonaws.com",
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateOutpost_617455 = ref object of OpenApiRestCall_616856
proc url_CreateOutpost_617457(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateOutpost_617456(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Creates an Outpost.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617458 = header.getOrDefault("X-Amz-Date")
  valid_617458 = validateParameter(valid_617458, JString, required = false,
                                 default = nil)
  if valid_617458 != nil:
    section.add "X-Amz-Date", valid_617458
  var valid_617459 = header.getOrDefault("X-Amz-Security-Token")
  valid_617459 = validateParameter(valid_617459, JString, required = false,
                                 default = nil)
  if valid_617459 != nil:
    section.add "X-Amz-Security-Token", valid_617459
  var valid_617460 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617460 = validateParameter(valid_617460, JString, required = false,
                                 default = nil)
  if valid_617460 != nil:
    section.add "X-Amz-Content-Sha256", valid_617460
  var valid_617461 = header.getOrDefault("X-Amz-Algorithm")
  valid_617461 = validateParameter(valid_617461, JString, required = false,
                                 default = nil)
  if valid_617461 != nil:
    section.add "X-Amz-Algorithm", valid_617461
  var valid_617462 = header.getOrDefault("X-Amz-Signature")
  valid_617462 = validateParameter(valid_617462, JString, required = false,
                                 default = nil)
  if valid_617462 != nil:
    section.add "X-Amz-Signature", valid_617462
  var valid_617463 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617463 = validateParameter(valid_617463, JString, required = false,
                                 default = nil)
  if valid_617463 != nil:
    section.add "X-Amz-SignedHeaders", valid_617463
  var valid_617464 = header.getOrDefault("X-Amz-Credential")
  valid_617464 = validateParameter(valid_617464, JString, required = false,
                                 default = nil)
  if valid_617464 != nil:
    section.add "X-Amz-Credential", valid_617464
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_617466: Call_CreateOutpost_617455; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates an Outpost.
  ## 
  let valid = call_617466.validator(path, query, header, formData, body, _)
  let scheme = call_617466.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617466.url(scheme.get, call_617466.host, call_617466.base,
                         call_617466.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617466, url, valid, _)

proc call*(call_617467: Call_CreateOutpost_617455; body: JsonNode): Recallable =
  ## createOutpost
  ## Creates an Outpost.
  ##   body: JObject (required)
  var body_617468 = newJObject()
  if body != nil:
    body_617468 = body
  result = call_617467.call(nil, nil, nil, nil, body_617468)

var createOutpost* = Call_CreateOutpost_617455(name: "createOutpost",
    meth: HttpMethod.HttpPost, host: "outposts.amazonaws.com", route: "/outposts",
    validator: validate_CreateOutpost_617456, base: "/", url: url_CreateOutpost_617457,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOutposts_617195 = ref object of OpenApiRestCall_616856
proc url_ListOutposts_617197(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOutposts_617196(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## List the Outposts for your AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The pagination token.
  ##   MaxResults: JInt
  ##             : The maximum page size.
  section = newJObject()
  var valid_617309 = query.getOrDefault("NextToken")
  valid_617309 = validateParameter(valid_617309, JString, required = false,
                                 default = nil)
  if valid_617309 != nil:
    section.add "NextToken", valid_617309
  var valid_617310 = query.getOrDefault("MaxResults")
  valid_617310 = validateParameter(valid_617310, JInt, required = false, default = nil)
  if valid_617310 != nil:
    section.add "MaxResults", valid_617310
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617311 = header.getOrDefault("X-Amz-Date")
  valid_617311 = validateParameter(valid_617311, JString, required = false,
                                 default = nil)
  if valid_617311 != nil:
    section.add "X-Amz-Date", valid_617311
  var valid_617312 = header.getOrDefault("X-Amz-Security-Token")
  valid_617312 = validateParameter(valid_617312, JString, required = false,
                                 default = nil)
  if valid_617312 != nil:
    section.add "X-Amz-Security-Token", valid_617312
  var valid_617313 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617313 = validateParameter(valid_617313, JString, required = false,
                                 default = nil)
  if valid_617313 != nil:
    section.add "X-Amz-Content-Sha256", valid_617313
  var valid_617314 = header.getOrDefault("X-Amz-Algorithm")
  valid_617314 = validateParameter(valid_617314, JString, required = false,
                                 default = nil)
  if valid_617314 != nil:
    section.add "X-Amz-Algorithm", valid_617314
  var valid_617315 = header.getOrDefault("X-Amz-Signature")
  valid_617315 = validateParameter(valid_617315, JString, required = false,
                                 default = nil)
  if valid_617315 != nil:
    section.add "X-Amz-Signature", valid_617315
  var valid_617316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617316 = validateParameter(valid_617316, JString, required = false,
                                 default = nil)
  if valid_617316 != nil:
    section.add "X-Amz-SignedHeaders", valid_617316
  var valid_617317 = header.getOrDefault("X-Amz-Credential")
  valid_617317 = validateParameter(valid_617317, JString, required = false,
                                 default = nil)
  if valid_617317 != nil:
    section.add "X-Amz-Credential", valid_617317
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617341: Call_ListOutposts_617195; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List the Outposts for your AWS account.
  ## 
  let valid = call_617341.validator(path, query, header, formData, body, _)
  let scheme = call_617341.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617341.url(scheme.get, call_617341.host, call_617341.base,
                         call_617341.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617341, url, valid, _)

proc call*(call_617412: Call_ListOutposts_617195; NextToken: string = "";
          MaxResults: int = 0): Recallable =
  ## listOutposts
  ## List the Outposts for your AWS account.
  ##   NextToken: string
  ##            : The pagination token.
  ##   MaxResults: int
  ##             : The maximum page size.
  var query_617413 = newJObject()
  add(query_617413, "NextToken", newJString(NextToken))
  add(query_617413, "MaxResults", newJInt(MaxResults))
  result = call_617412.call(nil, query_617413, nil, nil, nil)

var listOutposts* = Call_ListOutposts_617195(name: "listOutposts",
    meth: HttpMethod.HttpGet, host: "outposts.amazonaws.com", route: "/outposts",
    validator: validate_ListOutposts_617196, base: "/", url: url_ListOutposts_617197,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOutpost_617469 = ref object of OpenApiRestCall_616856
proc url_GetOutpost_617471(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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

proc validate_GetOutpost_617470(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Gets information about the specified Outpost.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   OutpostId: JString (required)
  ##            : The ID of the Outpost.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `OutpostId` field"
  var valid_617486 = path.getOrDefault("OutpostId")
  valid_617486 = validateParameter(valid_617486, JString, required = true,
                                 default = nil)
  if valid_617486 != nil:
    section.add "OutpostId", valid_617486
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617487 = header.getOrDefault("X-Amz-Date")
  valid_617487 = validateParameter(valid_617487, JString, required = false,
                                 default = nil)
  if valid_617487 != nil:
    section.add "X-Amz-Date", valid_617487
  var valid_617488 = header.getOrDefault("X-Amz-Security-Token")
  valid_617488 = validateParameter(valid_617488, JString, required = false,
                                 default = nil)
  if valid_617488 != nil:
    section.add "X-Amz-Security-Token", valid_617488
  var valid_617489 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617489 = validateParameter(valid_617489, JString, required = false,
                                 default = nil)
  if valid_617489 != nil:
    section.add "X-Amz-Content-Sha256", valid_617489
  var valid_617490 = header.getOrDefault("X-Amz-Algorithm")
  valid_617490 = validateParameter(valid_617490, JString, required = false,
                                 default = nil)
  if valid_617490 != nil:
    section.add "X-Amz-Algorithm", valid_617490
  var valid_617491 = header.getOrDefault("X-Amz-Signature")
  valid_617491 = validateParameter(valid_617491, JString, required = false,
                                 default = nil)
  if valid_617491 != nil:
    section.add "X-Amz-Signature", valid_617491
  var valid_617492 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617492 = validateParameter(valid_617492, JString, required = false,
                                 default = nil)
  if valid_617492 != nil:
    section.add "X-Amz-SignedHeaders", valid_617492
  var valid_617493 = header.getOrDefault("X-Amz-Credential")
  valid_617493 = validateParameter(valid_617493, JString, required = false,
                                 default = nil)
  if valid_617493 != nil:
    section.add "X-Amz-Credential", valid_617493
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617494: Call_GetOutpost_617469; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets information about the specified Outpost.
  ## 
  let valid = call_617494.validator(path, query, header, formData, body, _)
  let scheme = call_617494.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617494.url(scheme.get, call_617494.host, call_617494.base,
                         call_617494.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617494, url, valid, _)

proc call*(call_617495: Call_GetOutpost_617469; OutpostId: string): Recallable =
  ## getOutpost
  ## Gets information about the specified Outpost.
  ##   OutpostId: string (required)
  ##            : The ID of the Outpost.
  var path_617496 = newJObject()
  add(path_617496, "OutpostId", newJString(OutpostId))
  result = call_617495.call(path_617496, nil, nil, nil, nil)

var getOutpost* = Call_GetOutpost_617469(name: "getOutpost",
                                      meth: HttpMethod.HttpGet,
                                      host: "outposts.amazonaws.com",
                                      route: "/outposts/{OutpostId}",
                                      validator: validate_GetOutpost_617470,
                                      base: "/", url: url_GetOutpost_617471,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOutpost_617497 = ref object of OpenApiRestCall_616856
proc url_DeleteOutpost_617499(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteOutpost_617498(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Deletes the Outpost.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   OutpostId: JString (required)
  ##            : The ID of the Outpost.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `OutpostId` field"
  var valid_617500 = path.getOrDefault("OutpostId")
  valid_617500 = validateParameter(valid_617500, JString, required = true,
                                 default = nil)
  if valid_617500 != nil:
    section.add "OutpostId", valid_617500
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617501 = header.getOrDefault("X-Amz-Date")
  valid_617501 = validateParameter(valid_617501, JString, required = false,
                                 default = nil)
  if valid_617501 != nil:
    section.add "X-Amz-Date", valid_617501
  var valid_617502 = header.getOrDefault("X-Amz-Security-Token")
  valid_617502 = validateParameter(valid_617502, JString, required = false,
                                 default = nil)
  if valid_617502 != nil:
    section.add "X-Amz-Security-Token", valid_617502
  var valid_617503 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617503 = validateParameter(valid_617503, JString, required = false,
                                 default = nil)
  if valid_617503 != nil:
    section.add "X-Amz-Content-Sha256", valid_617503
  var valid_617504 = header.getOrDefault("X-Amz-Algorithm")
  valid_617504 = validateParameter(valid_617504, JString, required = false,
                                 default = nil)
  if valid_617504 != nil:
    section.add "X-Amz-Algorithm", valid_617504
  var valid_617505 = header.getOrDefault("X-Amz-Signature")
  valid_617505 = validateParameter(valid_617505, JString, required = false,
                                 default = nil)
  if valid_617505 != nil:
    section.add "X-Amz-Signature", valid_617505
  var valid_617506 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617506 = validateParameter(valid_617506, JString, required = false,
                                 default = nil)
  if valid_617506 != nil:
    section.add "X-Amz-SignedHeaders", valid_617506
  var valid_617507 = header.getOrDefault("X-Amz-Credential")
  valid_617507 = validateParameter(valid_617507, JString, required = false,
                                 default = nil)
  if valid_617507 != nil:
    section.add "X-Amz-Credential", valid_617507
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617508: Call_DeleteOutpost_617497; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the Outpost.
  ## 
  let valid = call_617508.validator(path, query, header, formData, body, _)
  let scheme = call_617508.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617508.url(scheme.get, call_617508.host, call_617508.base,
                         call_617508.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617508, url, valid, _)

proc call*(call_617509: Call_DeleteOutpost_617497; OutpostId: string): Recallable =
  ## deleteOutpost
  ## Deletes the Outpost.
  ##   OutpostId: string (required)
  ##            : The ID of the Outpost.
  var path_617510 = newJObject()
  add(path_617510, "OutpostId", newJString(OutpostId))
  result = call_617509.call(path_617510, nil, nil, nil, nil)

var deleteOutpost* = Call_DeleteOutpost_617497(name: "deleteOutpost",
    meth: HttpMethod.HttpDelete, host: "outposts.amazonaws.com",
    route: "/outposts/{OutpostId}", validator: validate_DeleteOutpost_617498,
    base: "/", url: url_DeleteOutpost_617499, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSite_617511 = ref object of OpenApiRestCall_616856
proc url_DeleteSite_617513(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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

proc validate_DeleteSite_617512(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Deletes the site.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   SiteId: JString (required)
  ##         : The ID of the site.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `SiteId` field"
  var valid_617514 = path.getOrDefault("SiteId")
  valid_617514 = validateParameter(valid_617514, JString, required = true,
                                 default = nil)
  if valid_617514 != nil:
    section.add "SiteId", valid_617514
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617515 = header.getOrDefault("X-Amz-Date")
  valid_617515 = validateParameter(valid_617515, JString, required = false,
                                 default = nil)
  if valid_617515 != nil:
    section.add "X-Amz-Date", valid_617515
  var valid_617516 = header.getOrDefault("X-Amz-Security-Token")
  valid_617516 = validateParameter(valid_617516, JString, required = false,
                                 default = nil)
  if valid_617516 != nil:
    section.add "X-Amz-Security-Token", valid_617516
  var valid_617517 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617517 = validateParameter(valid_617517, JString, required = false,
                                 default = nil)
  if valid_617517 != nil:
    section.add "X-Amz-Content-Sha256", valid_617517
  var valid_617518 = header.getOrDefault("X-Amz-Algorithm")
  valid_617518 = validateParameter(valid_617518, JString, required = false,
                                 default = nil)
  if valid_617518 != nil:
    section.add "X-Amz-Algorithm", valid_617518
  var valid_617519 = header.getOrDefault("X-Amz-Signature")
  valid_617519 = validateParameter(valid_617519, JString, required = false,
                                 default = nil)
  if valid_617519 != nil:
    section.add "X-Amz-Signature", valid_617519
  var valid_617520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617520 = validateParameter(valid_617520, JString, required = false,
                                 default = nil)
  if valid_617520 != nil:
    section.add "X-Amz-SignedHeaders", valid_617520
  var valid_617521 = header.getOrDefault("X-Amz-Credential")
  valid_617521 = validateParameter(valid_617521, JString, required = false,
                                 default = nil)
  if valid_617521 != nil:
    section.add "X-Amz-Credential", valid_617521
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617522: Call_DeleteSite_617511; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the site.
  ## 
  let valid = call_617522.validator(path, query, header, formData, body, _)
  let scheme = call_617522.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617522.url(scheme.get, call_617522.host, call_617522.base,
                         call_617522.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617522, url, valid, _)

proc call*(call_617523: Call_DeleteSite_617511; SiteId: string): Recallable =
  ## deleteSite
  ## Deletes the site.
  ##   SiteId: string (required)
  ##         : The ID of the site.
  var path_617524 = newJObject()
  add(path_617524, "SiteId", newJString(SiteId))
  result = call_617523.call(path_617524, nil, nil, nil, nil)

var deleteSite* = Call_DeleteSite_617511(name: "deleteSite",
                                      meth: HttpMethod.HttpDelete,
                                      host: "outposts.amazonaws.com",
                                      route: "/sites/{SiteId}",
                                      validator: validate_DeleteSite_617512,
                                      base: "/", url: url_DeleteSite_617513,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOutpostInstanceTypes_617525 = ref object of OpenApiRestCall_616856
proc url_GetOutpostInstanceTypes_617527(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
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

proc validate_GetOutpostInstanceTypes_617526(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Lists the instance types for the specified Outpost.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   OutpostId: JString (required)
  ##            : The ID of the Outpost.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `OutpostId` field"
  var valid_617528 = path.getOrDefault("OutpostId")
  valid_617528 = validateParameter(valid_617528, JString, required = true,
                                 default = nil)
  if valid_617528 != nil:
    section.add "OutpostId", valid_617528
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The pagination token.
  ##   MaxResults: JInt
  ##             : The maximum page size.
  section = newJObject()
  var valid_617529 = query.getOrDefault("NextToken")
  valid_617529 = validateParameter(valid_617529, JString, required = false,
                                 default = nil)
  if valid_617529 != nil:
    section.add "NextToken", valid_617529
  var valid_617530 = query.getOrDefault("MaxResults")
  valid_617530 = validateParameter(valid_617530, JInt, required = false, default = nil)
  if valid_617530 != nil:
    section.add "MaxResults", valid_617530
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617531 = header.getOrDefault("X-Amz-Date")
  valid_617531 = validateParameter(valid_617531, JString, required = false,
                                 default = nil)
  if valid_617531 != nil:
    section.add "X-Amz-Date", valid_617531
  var valid_617532 = header.getOrDefault("X-Amz-Security-Token")
  valid_617532 = validateParameter(valid_617532, JString, required = false,
                                 default = nil)
  if valid_617532 != nil:
    section.add "X-Amz-Security-Token", valid_617532
  var valid_617533 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617533 = validateParameter(valid_617533, JString, required = false,
                                 default = nil)
  if valid_617533 != nil:
    section.add "X-Amz-Content-Sha256", valid_617533
  var valid_617534 = header.getOrDefault("X-Amz-Algorithm")
  valid_617534 = validateParameter(valid_617534, JString, required = false,
                                 default = nil)
  if valid_617534 != nil:
    section.add "X-Amz-Algorithm", valid_617534
  var valid_617535 = header.getOrDefault("X-Amz-Signature")
  valid_617535 = validateParameter(valid_617535, JString, required = false,
                                 default = nil)
  if valid_617535 != nil:
    section.add "X-Amz-Signature", valid_617535
  var valid_617536 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617536 = validateParameter(valid_617536, JString, required = false,
                                 default = nil)
  if valid_617536 != nil:
    section.add "X-Amz-SignedHeaders", valid_617536
  var valid_617537 = header.getOrDefault("X-Amz-Credential")
  valid_617537 = validateParameter(valid_617537, JString, required = false,
                                 default = nil)
  if valid_617537 != nil:
    section.add "X-Amz-Credential", valid_617537
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617538: Call_GetOutpostInstanceTypes_617525; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the instance types for the specified Outpost.
  ## 
  let valid = call_617538.validator(path, query, header, formData, body, _)
  let scheme = call_617538.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617538.url(scheme.get, call_617538.host, call_617538.base,
                         call_617538.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617538, url, valid, _)

proc call*(call_617539: Call_GetOutpostInstanceTypes_617525; OutpostId: string;
          NextToken: string = ""; MaxResults: int = 0): Recallable =
  ## getOutpostInstanceTypes
  ## Lists the instance types for the specified Outpost.
  ##   OutpostId: string (required)
  ##            : The ID of the Outpost.
  ##   NextToken: string
  ##            : The pagination token.
  ##   MaxResults: int
  ##             : The maximum page size.
  var path_617540 = newJObject()
  var query_617541 = newJObject()
  add(path_617540, "OutpostId", newJString(OutpostId))
  add(query_617541, "NextToken", newJString(NextToken))
  add(query_617541, "MaxResults", newJInt(MaxResults))
  result = call_617539.call(path_617540, query_617541, nil, nil, nil)

var getOutpostInstanceTypes* = Call_GetOutpostInstanceTypes_617525(
    name: "getOutpostInstanceTypes", meth: HttpMethod.HttpGet,
    host: "outposts.amazonaws.com", route: "/outposts/{OutpostId}/instanceTypes",
    validator: validate_GetOutpostInstanceTypes_617526, base: "/",
    url: url_GetOutpostInstanceTypes_617527, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSites_617542 = ref object of OpenApiRestCall_616856
proc url_ListSites_617544(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSites_617543(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode; _: string = ""): JsonNode =
  ## Lists the sites for the specified AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : The pagination token.
  ##   MaxResults: JInt
  ##             : The maximum page size.
  section = newJObject()
  var valid_617545 = query.getOrDefault("NextToken")
  valid_617545 = validateParameter(valid_617545, JString, required = false,
                                 default = nil)
  if valid_617545 != nil:
    section.add "NextToken", valid_617545
  var valid_617546 = query.getOrDefault("MaxResults")
  valid_617546 = validateParameter(valid_617546, JInt, required = false, default = nil)
  if valid_617546 != nil:
    section.add "MaxResults", valid_617546
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Date: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-Signature: JString
  ##   X-Amz-SignedHeaders: JString
  ##   X-Amz-Credential: JString
  section = newJObject()
  var valid_617547 = header.getOrDefault("X-Amz-Date")
  valid_617547 = validateParameter(valid_617547, JString, required = false,
                                 default = nil)
  if valid_617547 != nil:
    section.add "X-Amz-Date", valid_617547
  var valid_617548 = header.getOrDefault("X-Amz-Security-Token")
  valid_617548 = validateParameter(valid_617548, JString, required = false,
                                 default = nil)
  if valid_617548 != nil:
    section.add "X-Amz-Security-Token", valid_617548
  var valid_617549 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_617549 = validateParameter(valid_617549, JString, required = false,
                                 default = nil)
  if valid_617549 != nil:
    section.add "X-Amz-Content-Sha256", valid_617549
  var valid_617550 = header.getOrDefault("X-Amz-Algorithm")
  valid_617550 = validateParameter(valid_617550, JString, required = false,
                                 default = nil)
  if valid_617550 != nil:
    section.add "X-Amz-Algorithm", valid_617550
  var valid_617551 = header.getOrDefault("X-Amz-Signature")
  valid_617551 = validateParameter(valid_617551, JString, required = false,
                                 default = nil)
  if valid_617551 != nil:
    section.add "X-Amz-Signature", valid_617551
  var valid_617552 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_617552 = validateParameter(valid_617552, JString, required = false,
                                 default = nil)
  if valid_617552 != nil:
    section.add "X-Amz-SignedHeaders", valid_617552
  var valid_617553 = header.getOrDefault("X-Amz-Credential")
  valid_617553 = validateParameter(valid_617553, JString, required = false,
                                 default = nil)
  if valid_617553 != nil:
    section.add "X-Amz-Credential", valid_617553
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_617554: Call_ListSites_617542; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Lists the sites for the specified AWS account.
  ## 
  let valid = call_617554.validator(path, query, header, formData, body, _)
  let scheme = call_617554.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_617554.url(scheme.get, call_617554.host, call_617554.base,
                         call_617554.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_617554, url, valid, _)

proc call*(call_617555: Call_ListSites_617542; NextToken: string = "";
          MaxResults: int = 0): Recallable =
  ## listSites
  ## Lists the sites for the specified AWS account.
  ##   NextToken: string
  ##            : The pagination token.
  ##   MaxResults: int
  ##             : The maximum page size.
  var query_617556 = newJObject()
  add(query_617556, "NextToken", newJString(NextToken))
  add(query_617556, "MaxResults", newJInt(MaxResults))
  result = call_617555.call(nil, query_617556, nil, nil, nil)

var listSites* = Call_ListSites_617542(name: "listSites", meth: HttpMethod.HttpGet,
                                    host: "outposts.amazonaws.com",
                                    route: "/sites",
                                    validator: validate_ListSites_617543,
                                    base: "/", url: url_ListSites_617544,
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
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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
    scope = credentialScope(region = region, service = awsServiceName, date = date)
    request = canonicalRequest(recall.meth, $url, query, recall.headers, recall.body,
                             normalize = normal, digest = algo)
    sts = stringToSign(request.hash(algo), scope, date = date, digest = algo)
    signature = calculateSignature(secret = secret, date = date, region = region,
                                 service = awsServiceName, sts, digest = algo)
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
    headers["content-md5"] = $text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
