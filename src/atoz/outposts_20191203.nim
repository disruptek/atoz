
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

  OpenApiRestCall_597380 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_597380](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_597380): Option[Scheme] {.used.} =
  ## select a supported scheme from a set of candidates
  for scheme in Scheme.low ..
      Scheme.high:
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
  if js ==
      nil:
    if default != nil:
      return validateParameter(default, kind, required = required)
  result = js
  if result ==
      nil:
    assert not required, $kind & " expected; received nil"
    if required:
      result = newJNull()
  else:
    assert js.kind ==
        kind, $kind & " expected; received " &
        $js.kind

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
  Call_CreateOutpost_597975 = ref object of OpenApiRestCall_597380
proc url_CreateOutpost_597977(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateOutpost_597976(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_597978 = header.getOrDefault("X-Amz-Signature")
  valid_597978 = validateParameter(valid_597978, JString, required = false,
                                 default = nil)
  if valid_597978 != nil:
    section.add "X-Amz-Signature", valid_597978
  var valid_597979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597979 = validateParameter(valid_597979, JString, required = false,
                                 default = nil)
  if valid_597979 != nil:
    section.add "X-Amz-Content-Sha256", valid_597979
  var valid_597980 = header.getOrDefault("X-Amz-Date")
  valid_597980 = validateParameter(valid_597980, JString, required = false,
                                 default = nil)
  if valid_597980 != nil:
    section.add "X-Amz-Date", valid_597980
  var valid_597981 = header.getOrDefault("X-Amz-Credential")
  valid_597981 = validateParameter(valid_597981, JString, required = false,
                                 default = nil)
  if valid_597981 != nil:
    section.add "X-Amz-Credential", valid_597981
  var valid_597982 = header.getOrDefault("X-Amz-Security-Token")
  valid_597982 = validateParameter(valid_597982, JString, required = false,
                                 default = nil)
  if valid_597982 != nil:
    section.add "X-Amz-Security-Token", valid_597982
  var valid_597983 = header.getOrDefault("X-Amz-Algorithm")
  valid_597983 = validateParameter(valid_597983, JString, required = false,
                                 default = nil)
  if valid_597983 != nil:
    section.add "X-Amz-Algorithm", valid_597983
  var valid_597984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597984 = validateParameter(valid_597984, JString, required = false,
                                 default = nil)
  if valid_597984 != nil:
    section.add "X-Amz-SignedHeaders", valid_597984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_597986: Call_CreateOutpost_597975; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Outpost.
  ## 
  let valid = call_597986.validator(path, query, header, formData, body)
  let scheme = call_597986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597986.url(scheme.get, call_597986.host, call_597986.base,
                         call_597986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597986, url, valid)

proc call*(call_597987: Call_CreateOutpost_597975; body: JsonNode): Recallable =
  ## createOutpost
  ## Creates an Outpost.
  ##   body: JObject (required)
  var body_597988 = newJObject()
  if body != nil:
    body_597988 = body
  result = call_597987.call(nil, nil, nil, nil, body_597988)

var createOutpost* = Call_CreateOutpost_597975(name: "createOutpost",
    meth: HttpMethod.HttpPost, host: "outposts.amazonaws.com", route: "/outposts",
    validator: validate_CreateOutpost_597976, base: "/", url: url_CreateOutpost_597977,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOutposts_597718 = ref object of OpenApiRestCall_597380
proc url_ListOutposts_597720(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOutposts_597719(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_597832 = query.getOrDefault("MaxResults")
  valid_597832 = validateParameter(valid_597832, JInt, required = false, default = nil)
  if valid_597832 != nil:
    section.add "MaxResults", valid_597832
  var valid_597833 = query.getOrDefault("NextToken")
  valid_597833 = validateParameter(valid_597833, JString, required = false,
                                 default = nil)
  if valid_597833 != nil:
    section.add "NextToken", valid_597833
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
  var valid_597834 = header.getOrDefault("X-Amz-Signature")
  valid_597834 = validateParameter(valid_597834, JString, required = false,
                                 default = nil)
  if valid_597834 != nil:
    section.add "X-Amz-Signature", valid_597834
  var valid_597835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_597835 = validateParameter(valid_597835, JString, required = false,
                                 default = nil)
  if valid_597835 != nil:
    section.add "X-Amz-Content-Sha256", valid_597835
  var valid_597836 = header.getOrDefault("X-Amz-Date")
  valid_597836 = validateParameter(valid_597836, JString, required = false,
                                 default = nil)
  if valid_597836 != nil:
    section.add "X-Amz-Date", valid_597836
  var valid_597837 = header.getOrDefault("X-Amz-Credential")
  valid_597837 = validateParameter(valid_597837, JString, required = false,
                                 default = nil)
  if valid_597837 != nil:
    section.add "X-Amz-Credential", valid_597837
  var valid_597838 = header.getOrDefault("X-Amz-Security-Token")
  valid_597838 = validateParameter(valid_597838, JString, required = false,
                                 default = nil)
  if valid_597838 != nil:
    section.add "X-Amz-Security-Token", valid_597838
  var valid_597839 = header.getOrDefault("X-Amz-Algorithm")
  valid_597839 = validateParameter(valid_597839, JString, required = false,
                                 default = nil)
  if valid_597839 != nil:
    section.add "X-Amz-Algorithm", valid_597839
  var valid_597840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_597840 = validateParameter(valid_597840, JString, required = false,
                                 default = nil)
  if valid_597840 != nil:
    section.add "X-Amz-SignedHeaders", valid_597840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_597863: Call_ListOutposts_597718; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the Outposts for your AWS account.
  ## 
  let valid = call_597863.validator(path, query, header, formData, body)
  let scheme = call_597863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_597863.url(scheme.get, call_597863.host, call_597863.base,
                         call_597863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_597863, url, valid)

proc call*(call_597934: Call_ListOutposts_597718; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## listOutposts
  ## List the Outposts for your AWS account.
  ##   MaxResults: int
  ##             : The maximum page size.
  ##   NextToken: string
  ##            : The pagination token.
  var query_597935 = newJObject()
  add(query_597935, "MaxResults", newJInt(MaxResults))
  add(query_597935, "NextToken", newJString(NextToken))
  result = call_597934.call(nil, query_597935, nil, nil, nil)

var listOutposts* = Call_ListOutposts_597718(name: "listOutposts",
    meth: HttpMethod.HttpGet, host: "outposts.amazonaws.com", route: "/outposts",
    validator: validate_ListOutposts_597719, base: "/", url: url_ListOutposts_597720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOutpost_597989 = ref object of OpenApiRestCall_597380
proc url_GetOutpost_597991(protocol: Scheme; host: string; base: string; route: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetOutpost_597990(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598006 = path.getOrDefault("OutpostId")
  valid_598006 = validateParameter(valid_598006, JString, required = true,
                                 default = nil)
  if valid_598006 != nil:
    section.add "OutpostId", valid_598006
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
  var valid_598007 = header.getOrDefault("X-Amz-Signature")
  valid_598007 = validateParameter(valid_598007, JString, required = false,
                                 default = nil)
  if valid_598007 != nil:
    section.add "X-Amz-Signature", valid_598007
  var valid_598008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598008 = validateParameter(valid_598008, JString, required = false,
                                 default = nil)
  if valid_598008 != nil:
    section.add "X-Amz-Content-Sha256", valid_598008
  var valid_598009 = header.getOrDefault("X-Amz-Date")
  valid_598009 = validateParameter(valid_598009, JString, required = false,
                                 default = nil)
  if valid_598009 != nil:
    section.add "X-Amz-Date", valid_598009
  var valid_598010 = header.getOrDefault("X-Amz-Credential")
  valid_598010 = validateParameter(valid_598010, JString, required = false,
                                 default = nil)
  if valid_598010 != nil:
    section.add "X-Amz-Credential", valid_598010
  var valid_598011 = header.getOrDefault("X-Amz-Security-Token")
  valid_598011 = validateParameter(valid_598011, JString, required = false,
                                 default = nil)
  if valid_598011 != nil:
    section.add "X-Amz-Security-Token", valid_598011
  var valid_598012 = header.getOrDefault("X-Amz-Algorithm")
  valid_598012 = validateParameter(valid_598012, JString, required = false,
                                 default = nil)
  if valid_598012 != nil:
    section.add "X-Amz-Algorithm", valid_598012
  var valid_598013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598013 = validateParameter(valid_598013, JString, required = false,
                                 default = nil)
  if valid_598013 != nil:
    section.add "X-Amz-SignedHeaders", valid_598013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598014: Call_GetOutpost_597989; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified Outpost.
  ## 
  let valid = call_598014.validator(path, query, header, formData, body)
  let scheme = call_598014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598014.url(scheme.get, call_598014.host, call_598014.base,
                         call_598014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598014, url, valid)

proc call*(call_598015: Call_GetOutpost_597989; OutpostId: string): Recallable =
  ## getOutpost
  ## Gets information about the specified Outpost.
  ##   OutpostId: string (required)
  ##            : The ID of the Outpost.
  var path_598016 = newJObject()
  add(path_598016, "OutpostId", newJString(OutpostId))
  result = call_598015.call(path_598016, nil, nil, nil, nil)

var getOutpost* = Call_GetOutpost_597989(name: "getOutpost",
                                      meth: HttpMethod.HttpGet,
                                      host: "outposts.amazonaws.com",
                                      route: "/outposts/{OutpostId}",
                                      validator: validate_GetOutpost_597990,
                                      base: "/", url: url_GetOutpost_597991,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOutpostInstanceTypes_598017 = ref object of OpenApiRestCall_597380
proc url_GetOutpostInstanceTypes_598019(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_GetOutpostInstanceTypes_598018(path: JsonNode; query: JsonNode;
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
  var valid_598020 = path.getOrDefault("OutpostId")
  valid_598020 = validateParameter(valid_598020, JString, required = true,
                                 default = nil)
  if valid_598020 != nil:
    section.add "OutpostId", valid_598020
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : The maximum page size.
  ##   NextToken: JString
  ##            : The pagination token.
  section = newJObject()
  var valid_598021 = query.getOrDefault("MaxResults")
  valid_598021 = validateParameter(valid_598021, JInt, required = false, default = nil)
  if valid_598021 != nil:
    section.add "MaxResults", valid_598021
  var valid_598022 = query.getOrDefault("NextToken")
  valid_598022 = validateParameter(valid_598022, JString, required = false,
                                 default = nil)
  if valid_598022 != nil:
    section.add "NextToken", valid_598022
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
  var valid_598023 = header.getOrDefault("X-Amz-Signature")
  valid_598023 = validateParameter(valid_598023, JString, required = false,
                                 default = nil)
  if valid_598023 != nil:
    section.add "X-Amz-Signature", valid_598023
  var valid_598024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598024 = validateParameter(valid_598024, JString, required = false,
                                 default = nil)
  if valid_598024 != nil:
    section.add "X-Amz-Content-Sha256", valid_598024
  var valid_598025 = header.getOrDefault("X-Amz-Date")
  valid_598025 = validateParameter(valid_598025, JString, required = false,
                                 default = nil)
  if valid_598025 != nil:
    section.add "X-Amz-Date", valid_598025
  var valid_598026 = header.getOrDefault("X-Amz-Credential")
  valid_598026 = validateParameter(valid_598026, JString, required = false,
                                 default = nil)
  if valid_598026 != nil:
    section.add "X-Amz-Credential", valid_598026
  var valid_598027 = header.getOrDefault("X-Amz-Security-Token")
  valid_598027 = validateParameter(valid_598027, JString, required = false,
                                 default = nil)
  if valid_598027 != nil:
    section.add "X-Amz-Security-Token", valid_598027
  var valid_598028 = header.getOrDefault("X-Amz-Algorithm")
  valid_598028 = validateParameter(valid_598028, JString, required = false,
                                 default = nil)
  if valid_598028 != nil:
    section.add "X-Amz-Algorithm", valid_598028
  var valid_598029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598029 = validateParameter(valid_598029, JString, required = false,
                                 default = nil)
  if valid_598029 != nil:
    section.add "X-Amz-SignedHeaders", valid_598029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598030: Call_GetOutpostInstanceTypes_598017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the instance types for the specified Outpost.
  ## 
  let valid = call_598030.validator(path, query, header, formData, body)
  let scheme = call_598030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598030.url(scheme.get, call_598030.host, call_598030.base,
                         call_598030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598030, url, valid)

proc call*(call_598031: Call_GetOutpostInstanceTypes_598017; OutpostId: string;
          MaxResults: int = 0; NextToken: string = ""): Recallable =
  ## getOutpostInstanceTypes
  ## Lists the instance types for the specified Outpost.
  ##   MaxResults: int
  ##             : The maximum page size.
  ##   NextToken: string
  ##            : The pagination token.
  ##   OutpostId: string (required)
  ##            : The ID of the Outpost.
  var path_598032 = newJObject()
  var query_598033 = newJObject()
  add(query_598033, "MaxResults", newJInt(MaxResults))
  add(query_598033, "NextToken", newJString(NextToken))
  add(path_598032, "OutpostId", newJString(OutpostId))
  result = call_598031.call(path_598032, query_598033, nil, nil, nil)

var getOutpostInstanceTypes* = Call_GetOutpostInstanceTypes_598017(
    name: "getOutpostInstanceTypes", meth: HttpMethod.HttpGet,
    host: "outposts.amazonaws.com", route: "/outposts/{OutpostId}/instanceTypes",
    validator: validate_GetOutpostInstanceTypes_598018, base: "/",
    url: url_GetOutpostInstanceTypes_598019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSites_598034 = ref object of OpenApiRestCall_597380
proc url_ListSites_598036(protocol: Scheme; host: string; base: string; route: string;
                         path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListSites_598035(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_598037 = query.getOrDefault("MaxResults")
  valid_598037 = validateParameter(valid_598037, JInt, required = false, default = nil)
  if valid_598037 != nil:
    section.add "MaxResults", valid_598037
  var valid_598038 = query.getOrDefault("NextToken")
  valid_598038 = validateParameter(valid_598038, JString, required = false,
                                 default = nil)
  if valid_598038 != nil:
    section.add "NextToken", valid_598038
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
  var valid_598039 = header.getOrDefault("X-Amz-Signature")
  valid_598039 = validateParameter(valid_598039, JString, required = false,
                                 default = nil)
  if valid_598039 != nil:
    section.add "X-Amz-Signature", valid_598039
  var valid_598040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_598040 = validateParameter(valid_598040, JString, required = false,
                                 default = nil)
  if valid_598040 != nil:
    section.add "X-Amz-Content-Sha256", valid_598040
  var valid_598041 = header.getOrDefault("X-Amz-Date")
  valid_598041 = validateParameter(valid_598041, JString, required = false,
                                 default = nil)
  if valid_598041 != nil:
    section.add "X-Amz-Date", valid_598041
  var valid_598042 = header.getOrDefault("X-Amz-Credential")
  valid_598042 = validateParameter(valid_598042, JString, required = false,
                                 default = nil)
  if valid_598042 != nil:
    section.add "X-Amz-Credential", valid_598042
  var valid_598043 = header.getOrDefault("X-Amz-Security-Token")
  valid_598043 = validateParameter(valid_598043, JString, required = false,
                                 default = nil)
  if valid_598043 != nil:
    section.add "X-Amz-Security-Token", valid_598043
  var valid_598044 = header.getOrDefault("X-Amz-Algorithm")
  valid_598044 = validateParameter(valid_598044, JString, required = false,
                                 default = nil)
  if valid_598044 != nil:
    section.add "X-Amz-Algorithm", valid_598044
  var valid_598045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_598045 = validateParameter(valid_598045, JString, required = false,
                                 default = nil)
  if valid_598045 != nil:
    section.add "X-Amz-SignedHeaders", valid_598045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_598046: Call_ListSites_598034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the sites for the specified AWS account.
  ## 
  let valid = call_598046.validator(path, query, header, formData, body)
  let scheme = call_598046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_598046.url(scheme.get, call_598046.host, call_598046.base,
                         call_598046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_598046, url, valid)

proc call*(call_598047: Call_ListSites_598034; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## listSites
  ## Lists the sites for the specified AWS account.
  ##   MaxResults: int
  ##             : The maximum page size.
  ##   NextToken: string
  ##            : The pagination token.
  var query_598048 = newJObject()
  add(query_598048, "MaxResults", newJInt(MaxResults))
  add(query_598048, "NextToken", newJString(NextToken))
  result = call_598047.call(nil, query_598048, nil, nil, nil)

var listSites* = Call_ListSites_598034(name: "listSites", meth: HttpMethod.HttpGet,
                                    host: "outposts.amazonaws.com",
                                    route: "/sites",
                                    validator: validate_ListSites_598035,
                                    base: "/", url: url_ListSites_598036,
                                    schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc atozSign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
  let
    date = makeDateTime()
    access = os.getEnv("AWS_ACCESS_KEY_ID", "")
    secret = os.getEnv("AWS_SECRET_ACCESS_KEY", "")
    region = os.getEnv("AWS_REGION", "")
  assert secret != "", "need secret key in env"
  assert access != "", "need access key in env"
  assert region != "", "need region in env"
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

method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.atozSign(input.getOrDefault("query"), SHA256)
