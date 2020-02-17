
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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
  ValidatorSignature = proc (query: JsonNode = nil; body: JsonNode = nil;
                          header: JsonNode = nil; path: JsonNode = nil;
                          formData: JsonNode = nil): JsonNode
  OpenApiRestCall = ref object of RestCall
    validator*: ValidatorSignature
    route*: string
    base*: string
    host*: string
    schemes*: set[Scheme]
    url*: proc (protocol: Scheme; host: string; base: string; route: string;
              path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_610649 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610649](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610649): Option[Scheme] {.used.} =
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
                           "us-east-1": "outposts.us-east-1.amazonaws.com", "cn-northwest-1": "outposts.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "outposts.ap-south-1.amazonaws.com",
                           "eu-north-1": "outposts.eu-north-1.amazonaws.com", "ap-northeast-2": "outposts.ap-northeast-2.amazonaws.com",
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateOutpost_611244 = ref object of OpenApiRestCall_610649
proc url_CreateOutpost_611246(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateOutpost_611245(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates an Outpost.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611247 = header.getOrDefault("X-Amz-Signature")
  valid_611247 = validateParameter(valid_611247, JString, required = false,
                                 default = nil)
  if valid_611247 != nil:
    section.add "X-Amz-Signature", valid_611247
  var valid_611248 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611248 = validateParameter(valid_611248, JString, required = false,
                                 default = nil)
  if valid_611248 != nil:
    section.add "X-Amz-Content-Sha256", valid_611248
  var valid_611249 = header.getOrDefault("X-Amz-Date")
  valid_611249 = validateParameter(valid_611249, JString, required = false,
                                 default = nil)
  if valid_611249 != nil:
    section.add "X-Amz-Date", valid_611249
  var valid_611250 = header.getOrDefault("X-Amz-Credential")
  valid_611250 = validateParameter(valid_611250, JString, required = false,
                                 default = nil)
  if valid_611250 != nil:
    section.add "X-Amz-Credential", valid_611250
  var valid_611251 = header.getOrDefault("X-Amz-Security-Token")
  valid_611251 = validateParameter(valid_611251, JString, required = false,
                                 default = nil)
  if valid_611251 != nil:
    section.add "X-Amz-Security-Token", valid_611251
  var valid_611252 = header.getOrDefault("X-Amz-Algorithm")
  valid_611252 = validateParameter(valid_611252, JString, required = false,
                                 default = nil)
  if valid_611252 != nil:
    section.add "X-Amz-Algorithm", valid_611252
  var valid_611253 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611253 = validateParameter(valid_611253, JString, required = false,
                                 default = nil)
  if valid_611253 != nil:
    section.add "X-Amz-SignedHeaders", valid_611253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611255: Call_CreateOutpost_611244; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Outpost.
  ## 
  let valid = call_611255.validator(path, query, header, formData, body)
  let scheme = call_611255.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611255.url(scheme.get, call_611255.host, call_611255.base,
                         call_611255.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611255, url, valid)

proc call*(call_611256: Call_CreateOutpost_611244; body: JsonNode): Recallable =
  ## createOutpost
  ## Creates an Outpost.
  ##   body: JObject (required)
  var body_611257 = newJObject()
  if body != nil:
    body_611257 = body
  result = call_611256.call(nil, nil, nil, nil, body_611257)

var createOutpost* = Call_CreateOutpost_611244(name: "createOutpost",
    meth: HttpMethod.HttpPost, host: "outposts.amazonaws.com", route: "/outposts",
    validator: validate_CreateOutpost_611245, base: "/", url: url_CreateOutpost_611246,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOutposts_610987 = ref object of OpenApiRestCall_610649
proc url_ListOutposts_610989(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOutposts_610988(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## List the Outposts for your AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : The maximum page size.
  ##   NextToken: JString
  ##            : The pagination token.
  section = newJObject()
  var valid_611101 = query.getOrDefault("MaxResults")
  valid_611101 = validateParameter(valid_611101, JInt, required = false, default = nil)
  if valid_611101 != nil:
    section.add "MaxResults", valid_611101
  var valid_611102 = query.getOrDefault("NextToken")
  valid_611102 = validateParameter(valid_611102, JString, required = false,
                                 default = nil)
  if valid_611102 != nil:
    section.add "NextToken", valid_611102
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611103 = header.getOrDefault("X-Amz-Signature")
  valid_611103 = validateParameter(valid_611103, JString, required = false,
                                 default = nil)
  if valid_611103 != nil:
    section.add "X-Amz-Signature", valid_611103
  var valid_611104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611104 = validateParameter(valid_611104, JString, required = false,
                                 default = nil)
  if valid_611104 != nil:
    section.add "X-Amz-Content-Sha256", valid_611104
  var valid_611105 = header.getOrDefault("X-Amz-Date")
  valid_611105 = validateParameter(valid_611105, JString, required = false,
                                 default = nil)
  if valid_611105 != nil:
    section.add "X-Amz-Date", valid_611105
  var valid_611106 = header.getOrDefault("X-Amz-Credential")
  valid_611106 = validateParameter(valid_611106, JString, required = false,
                                 default = nil)
  if valid_611106 != nil:
    section.add "X-Amz-Credential", valid_611106
  var valid_611107 = header.getOrDefault("X-Amz-Security-Token")
  valid_611107 = validateParameter(valid_611107, JString, required = false,
                                 default = nil)
  if valid_611107 != nil:
    section.add "X-Amz-Security-Token", valid_611107
  var valid_611108 = header.getOrDefault("X-Amz-Algorithm")
  valid_611108 = validateParameter(valid_611108, JString, required = false,
                                 default = nil)
  if valid_611108 != nil:
    section.add "X-Amz-Algorithm", valid_611108
  var valid_611109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611109 = validateParameter(valid_611109, JString, required = false,
                                 default = nil)
  if valid_611109 != nil:
    section.add "X-Amz-SignedHeaders", valid_611109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611132: Call_ListOutposts_610987; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the Outposts for your AWS account.
  ## 
  let valid = call_611132.validator(path, query, header, formData, body)
  let scheme = call_611132.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611132.url(scheme.get, call_611132.host, call_611132.base,
                         call_611132.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611132, url, valid)

proc call*(call_611203: Call_ListOutposts_610987; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## listOutposts
  ## List the Outposts for your AWS account.
  ##   MaxResults: int
  ##             : The maximum page size.
  ##   NextToken: string
  ##            : The pagination token.
  var query_611204 = newJObject()
  add(query_611204, "MaxResults", newJInt(MaxResults))
  add(query_611204, "NextToken", newJString(NextToken))
  result = call_611203.call(nil, query_611204, nil, nil, nil)

var listOutposts* = Call_ListOutposts_610987(name: "listOutposts",
    meth: HttpMethod.HttpGet, host: "outposts.amazonaws.com", route: "/outposts",
    validator: validate_ListOutposts_610988, base: "/", url: url_ListOutposts_610989,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOutpost_611258 = ref object of OpenApiRestCall_610649
proc url_GetOutpost_611260(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetOutpost_611259(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets information about the specified Outpost.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   OutpostId: JString (required)
  ##            : The ID of the Outpost.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `OutpostId` field"
  var valid_611275 = path.getOrDefault("OutpostId")
  valid_611275 = validateParameter(valid_611275, JString, required = true,
                                 default = nil)
  if valid_611275 != nil:
    section.add "OutpostId", valid_611275
  result.add "path", section
  section = newJObject()
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611276 = header.getOrDefault("X-Amz-Signature")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Signature", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Content-Sha256", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-Date")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-Date", valid_611278
  var valid_611279 = header.getOrDefault("X-Amz-Credential")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "X-Amz-Credential", valid_611279
  var valid_611280 = header.getOrDefault("X-Amz-Security-Token")
  valid_611280 = validateParameter(valid_611280, JString, required = false,
                                 default = nil)
  if valid_611280 != nil:
    section.add "X-Amz-Security-Token", valid_611280
  var valid_611281 = header.getOrDefault("X-Amz-Algorithm")
  valid_611281 = validateParameter(valid_611281, JString, required = false,
                                 default = nil)
  if valid_611281 != nil:
    section.add "X-Amz-Algorithm", valid_611281
  var valid_611282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611282 = validateParameter(valid_611282, JString, required = false,
                                 default = nil)
  if valid_611282 != nil:
    section.add "X-Amz-SignedHeaders", valid_611282
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611283: Call_GetOutpost_611258; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified Outpost.
  ## 
  let valid = call_611283.validator(path, query, header, formData, body)
  let scheme = call_611283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611283.url(scheme.get, call_611283.host, call_611283.base,
                         call_611283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611283, url, valid)

proc call*(call_611284: Call_GetOutpost_611258; OutpostId: string): Recallable =
  ## getOutpost
  ## Gets information about the specified Outpost.
  ##   OutpostId: string (required)
  ##            : The ID of the Outpost.
  var path_611285 = newJObject()
  add(path_611285, "OutpostId", newJString(OutpostId))
  result = call_611284.call(path_611285, nil, nil, nil, nil)

var getOutpost* = Call_GetOutpost_611258(name: "getOutpost",
                                      meth: HttpMethod.HttpGet,
                                      host: "outposts.amazonaws.com",
                                      route: "/outposts/{OutpostId}",
                                      validator: validate_GetOutpost_611259,
                                      base: "/", url: url_GetOutpost_611260,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOutpostInstanceTypes_611286 = ref object of OpenApiRestCall_610649
proc url_GetOutpostInstanceTypes_611288(protocol: Scheme; host: string; base: string;
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

proc validate_GetOutpostInstanceTypes_611287(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the instance types for the specified Outpost.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   OutpostId: JString (required)
  ##            : The ID of the Outpost.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `OutpostId` field"
  var valid_611289 = path.getOrDefault("OutpostId")
  valid_611289 = validateParameter(valid_611289, JString, required = true,
                                 default = nil)
  if valid_611289 != nil:
    section.add "OutpostId", valid_611289
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : The maximum page size.
  ##   NextToken: JString
  ##            : The pagination token.
  section = newJObject()
  var valid_611290 = query.getOrDefault("MaxResults")
  valid_611290 = validateParameter(valid_611290, JInt, required = false, default = nil)
  if valid_611290 != nil:
    section.add "MaxResults", valid_611290
  var valid_611291 = query.getOrDefault("NextToken")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "NextToken", valid_611291
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611292 = header.getOrDefault("X-Amz-Signature")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Signature", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Content-Sha256", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-Date")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Date", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-Credential")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-Credential", valid_611295
  var valid_611296 = header.getOrDefault("X-Amz-Security-Token")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-Security-Token", valid_611296
  var valid_611297 = header.getOrDefault("X-Amz-Algorithm")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-Algorithm", valid_611297
  var valid_611298 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611298 = validateParameter(valid_611298, JString, required = false,
                                 default = nil)
  if valid_611298 != nil:
    section.add "X-Amz-SignedHeaders", valid_611298
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611299: Call_GetOutpostInstanceTypes_611286; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the instance types for the specified Outpost.
  ## 
  let valid = call_611299.validator(path, query, header, formData, body)
  let scheme = call_611299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611299.url(scheme.get, call_611299.host, call_611299.base,
                         call_611299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611299, url, valid)

proc call*(call_611300: Call_GetOutpostInstanceTypes_611286; OutpostId: string;
          MaxResults: int = 0; NextToken: string = ""): Recallable =
  ## getOutpostInstanceTypes
  ## Lists the instance types for the specified Outpost.
  ##   MaxResults: int
  ##             : The maximum page size.
  ##   NextToken: string
  ##            : The pagination token.
  ##   OutpostId: string (required)
  ##            : The ID of the Outpost.
  var path_611301 = newJObject()
  var query_611302 = newJObject()
  add(query_611302, "MaxResults", newJInt(MaxResults))
  add(query_611302, "NextToken", newJString(NextToken))
  add(path_611301, "OutpostId", newJString(OutpostId))
  result = call_611300.call(path_611301, query_611302, nil, nil, nil)

var getOutpostInstanceTypes* = Call_GetOutpostInstanceTypes_611286(
    name: "getOutpostInstanceTypes", meth: HttpMethod.HttpGet,
    host: "outposts.amazonaws.com", route: "/outposts/{OutpostId}/instanceTypes",
    validator: validate_GetOutpostInstanceTypes_611287, base: "/",
    url: url_GetOutpostInstanceTypes_611288, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSites_611303 = ref object of OpenApiRestCall_610649
proc url_ListSites_611305(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSites_611304(path: JsonNode; query: JsonNode; header: JsonNode;
                              formData: JsonNode; body: JsonNode): JsonNode =
  ## Lists the sites for the specified AWS account.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : The maximum page size.
  ##   NextToken: JString
  ##            : The pagination token.
  section = newJObject()
  var valid_611306 = query.getOrDefault("MaxResults")
  valid_611306 = validateParameter(valid_611306, JInt, required = false, default = nil)
  if valid_611306 != nil:
    section.add "MaxResults", valid_611306
  var valid_611307 = query.getOrDefault("NextToken")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "NextToken", valid_611307
  result.add "query", section
  ## parameters in `header` object:
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_611308 = header.getOrDefault("X-Amz-Signature")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "X-Amz-Signature", valid_611308
  var valid_611309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611309 = validateParameter(valid_611309, JString, required = false,
                                 default = nil)
  if valid_611309 != nil:
    section.add "X-Amz-Content-Sha256", valid_611309
  var valid_611310 = header.getOrDefault("X-Amz-Date")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Date", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-Credential")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Credential", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Security-Token")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Security-Token", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-Algorithm")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Algorithm", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-SignedHeaders", valid_611314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611315: Call_ListSites_611303; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the sites for the specified AWS account.
  ## 
  let valid = call_611315.validator(path, query, header, formData, body)
  let scheme = call_611315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611315.url(scheme.get, call_611315.host, call_611315.base,
                         call_611315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611315, url, valid)

proc call*(call_611316: Call_ListSites_611303; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## listSites
  ## Lists the sites for the specified AWS account.
  ##   MaxResults: int
  ##             : The maximum page size.
  ##   NextToken: string
  ##            : The pagination token.
  var query_611317 = newJObject()
  add(query_611317, "MaxResults", newJInt(MaxResults))
  add(query_611317, "NextToken", newJString(NextToken))
  result = call_611316.call(nil, query_611317, nil, nil, nil)

var listSites* = Call_ListSites_611303(name: "listSites", meth: HttpMethod.HttpGet,
                                    host: "outposts.amazonaws.com",
                                    route: "/sites",
                                    validator: validate_ListSites_611304,
                                    base: "/", url: url_ListSites_611305,
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
  let
    algo = SHA256
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

type
  XAmz = enum
    SecurityToken = "X-Amz-Security-Token", ContentSha256 = "X-Amz-Content-Sha256"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  ## the hook is a terrible earworm
  var headers = newHttpHeaders(massageHeaders(input.getOrDefault("header")))
  let
    body = input.getOrDefault("body")
    text = if body == nil:
      "" elif body.kind == JString:
      body.getStr else:
      $body
  if body != nil and body.kind != JString:
    if not headers.hasKey("content-type"):
      headers["content-type"] = "application/x-amz-json-1.0"
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  headers[$ContentSha256] = hash(text, SHA256)
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
