
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

  OpenApiRestCall_601380 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601380](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601380): Option[Scheme] {.used.} =
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
  Call_CreateOutpost_601975 = ref object of OpenApiRestCall_601380
proc url_CreateOutpost_601977(protocol: Scheme; host: string; base: string;
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

proc validate_CreateOutpost_601976(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601978 = header.getOrDefault("X-Amz-Signature")
  valid_601978 = validateParameter(valid_601978, JString, required = false,
                                 default = nil)
  if valid_601978 != nil:
    section.add "X-Amz-Signature", valid_601978
  var valid_601979 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601979 = validateParameter(valid_601979, JString, required = false,
                                 default = nil)
  if valid_601979 != nil:
    section.add "X-Amz-Content-Sha256", valid_601979
  var valid_601980 = header.getOrDefault("X-Amz-Date")
  valid_601980 = validateParameter(valid_601980, JString, required = false,
                                 default = nil)
  if valid_601980 != nil:
    section.add "X-Amz-Date", valid_601980
  var valid_601981 = header.getOrDefault("X-Amz-Credential")
  valid_601981 = validateParameter(valid_601981, JString, required = false,
                                 default = nil)
  if valid_601981 != nil:
    section.add "X-Amz-Credential", valid_601981
  var valid_601982 = header.getOrDefault("X-Amz-Security-Token")
  valid_601982 = validateParameter(valid_601982, JString, required = false,
                                 default = nil)
  if valid_601982 != nil:
    section.add "X-Amz-Security-Token", valid_601982
  var valid_601983 = header.getOrDefault("X-Amz-Algorithm")
  valid_601983 = validateParameter(valid_601983, JString, required = false,
                                 default = nil)
  if valid_601983 != nil:
    section.add "X-Amz-Algorithm", valid_601983
  var valid_601984 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601984 = validateParameter(valid_601984, JString, required = false,
                                 default = nil)
  if valid_601984 != nil:
    section.add "X-Amz-SignedHeaders", valid_601984
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601986: Call_CreateOutpost_601975; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates an Outpost.
  ## 
  let valid = call_601986.validator(path, query, header, formData, body)
  let scheme = call_601986.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601986.url(scheme.get, call_601986.host, call_601986.base,
                         call_601986.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601986, url, valid)

proc call*(call_601987: Call_CreateOutpost_601975; body: JsonNode): Recallable =
  ## createOutpost
  ## Creates an Outpost.
  ##   body: JObject (required)
  var body_601988 = newJObject()
  if body != nil:
    body_601988 = body
  result = call_601987.call(nil, nil, nil, nil, body_601988)

var createOutpost* = Call_CreateOutpost_601975(name: "createOutpost",
    meth: HttpMethod.HttpPost, host: "outposts.amazonaws.com", route: "/outposts",
    validator: validate_CreateOutpost_601976, base: "/", url: url_CreateOutpost_601977,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOutposts_601718 = ref object of OpenApiRestCall_601380
proc url_ListOutposts_601720(protocol: Scheme; host: string; base: string;
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

proc validate_ListOutposts_601719(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601832 = query.getOrDefault("MaxResults")
  valid_601832 = validateParameter(valid_601832, JInt, required = false, default = nil)
  if valid_601832 != nil:
    section.add "MaxResults", valid_601832
  var valid_601833 = query.getOrDefault("NextToken")
  valid_601833 = validateParameter(valid_601833, JString, required = false,
                                 default = nil)
  if valid_601833 != nil:
    section.add "NextToken", valid_601833
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
  var valid_601834 = header.getOrDefault("X-Amz-Signature")
  valid_601834 = validateParameter(valid_601834, JString, required = false,
                                 default = nil)
  if valid_601834 != nil:
    section.add "X-Amz-Signature", valid_601834
  var valid_601835 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601835 = validateParameter(valid_601835, JString, required = false,
                                 default = nil)
  if valid_601835 != nil:
    section.add "X-Amz-Content-Sha256", valid_601835
  var valid_601836 = header.getOrDefault("X-Amz-Date")
  valid_601836 = validateParameter(valid_601836, JString, required = false,
                                 default = nil)
  if valid_601836 != nil:
    section.add "X-Amz-Date", valid_601836
  var valid_601837 = header.getOrDefault("X-Amz-Credential")
  valid_601837 = validateParameter(valid_601837, JString, required = false,
                                 default = nil)
  if valid_601837 != nil:
    section.add "X-Amz-Credential", valid_601837
  var valid_601838 = header.getOrDefault("X-Amz-Security-Token")
  valid_601838 = validateParameter(valid_601838, JString, required = false,
                                 default = nil)
  if valid_601838 != nil:
    section.add "X-Amz-Security-Token", valid_601838
  var valid_601839 = header.getOrDefault("X-Amz-Algorithm")
  valid_601839 = validateParameter(valid_601839, JString, required = false,
                                 default = nil)
  if valid_601839 != nil:
    section.add "X-Amz-Algorithm", valid_601839
  var valid_601840 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601840 = validateParameter(valid_601840, JString, required = false,
                                 default = nil)
  if valid_601840 != nil:
    section.add "X-Amz-SignedHeaders", valid_601840
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601863: Call_ListOutposts_601718; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the Outposts for your AWS account.
  ## 
  let valid = call_601863.validator(path, query, header, formData, body)
  let scheme = call_601863.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601863.url(scheme.get, call_601863.host, call_601863.base,
                         call_601863.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601863, url, valid)

proc call*(call_601934: Call_ListOutposts_601718; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## listOutposts
  ## List the Outposts for your AWS account.
  ##   MaxResults: int
  ##             : The maximum page size.
  ##   NextToken: string
  ##            : The pagination token.
  var query_601935 = newJObject()
  add(query_601935, "MaxResults", newJInt(MaxResults))
  add(query_601935, "NextToken", newJString(NextToken))
  result = call_601934.call(nil, query_601935, nil, nil, nil)

var listOutposts* = Call_ListOutposts_601718(name: "listOutposts",
    meth: HttpMethod.HttpGet, host: "outposts.amazonaws.com", route: "/outposts",
    validator: validate_ListOutposts_601719, base: "/", url: url_ListOutposts_601720,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOutpost_601989 = ref object of OpenApiRestCall_601380
proc url_GetOutpost_601991(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_GetOutpost_601990(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602006 = path.getOrDefault("OutpostId")
  valid_602006 = validateParameter(valid_602006, JString, required = true,
                                 default = nil)
  if valid_602006 != nil:
    section.add "OutpostId", valid_602006
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
  var valid_602007 = header.getOrDefault("X-Amz-Signature")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "X-Amz-Signature", valid_602007
  var valid_602008 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602008 = validateParameter(valid_602008, JString, required = false,
                                 default = nil)
  if valid_602008 != nil:
    section.add "X-Amz-Content-Sha256", valid_602008
  var valid_602009 = header.getOrDefault("X-Amz-Date")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Date", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Credential")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Credential", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Security-Token")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Security-Token", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-Algorithm")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-Algorithm", valid_602012
  var valid_602013 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-SignedHeaders", valid_602013
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602014: Call_GetOutpost_601989; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets information about the specified Outpost.
  ## 
  let valid = call_602014.validator(path, query, header, formData, body)
  let scheme = call_602014.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602014.url(scheme.get, call_602014.host, call_602014.base,
                         call_602014.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602014, url, valid)

proc call*(call_602015: Call_GetOutpost_601989; OutpostId: string): Recallable =
  ## getOutpost
  ## Gets information about the specified Outpost.
  ##   OutpostId: string (required)
  ##            : The ID of the Outpost.
  var path_602016 = newJObject()
  add(path_602016, "OutpostId", newJString(OutpostId))
  result = call_602015.call(path_602016, nil, nil, nil, nil)

var getOutpost* = Call_GetOutpost_601989(name: "getOutpost",
                                      meth: HttpMethod.HttpGet,
                                      host: "outposts.amazonaws.com",
                                      route: "/outposts/{OutpostId}",
                                      validator: validate_GetOutpost_601990,
                                      base: "/", url: url_GetOutpost_601991,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_GetOutpostInstanceTypes_602017 = ref object of OpenApiRestCall_601380
proc url_GetOutpostInstanceTypes_602019(protocol: Scheme; host: string; base: string;
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

proc validate_GetOutpostInstanceTypes_602018(path: JsonNode; query: JsonNode;
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
  var valid_602020 = path.getOrDefault("OutpostId")
  valid_602020 = validateParameter(valid_602020, JString, required = true,
                                 default = nil)
  if valid_602020 != nil:
    section.add "OutpostId", valid_602020
  result.add "path", section
  ## parameters in `query` object:
  ##   MaxResults: JInt
  ##             : The maximum page size.
  ##   NextToken: JString
  ##            : The pagination token.
  section = newJObject()
  var valid_602021 = query.getOrDefault("MaxResults")
  valid_602021 = validateParameter(valid_602021, JInt, required = false, default = nil)
  if valid_602021 != nil:
    section.add "MaxResults", valid_602021
  var valid_602022 = query.getOrDefault("NextToken")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "NextToken", valid_602022
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
  var valid_602023 = header.getOrDefault("X-Amz-Signature")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Signature", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Content-Sha256", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Date")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Date", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Credential")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Credential", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Security-Token")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Security-Token", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-Algorithm")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-Algorithm", valid_602028
  var valid_602029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602029 = validateParameter(valid_602029, JString, required = false,
                                 default = nil)
  if valid_602029 != nil:
    section.add "X-Amz-SignedHeaders", valid_602029
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602030: Call_GetOutpostInstanceTypes_602017; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the instance types for the specified Outpost.
  ## 
  let valid = call_602030.validator(path, query, header, formData, body)
  let scheme = call_602030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602030.url(scheme.get, call_602030.host, call_602030.base,
                         call_602030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602030, url, valid)

proc call*(call_602031: Call_GetOutpostInstanceTypes_602017; OutpostId: string;
          MaxResults: int = 0; NextToken: string = ""): Recallable =
  ## getOutpostInstanceTypes
  ## Lists the instance types for the specified Outpost.
  ##   MaxResults: int
  ##             : The maximum page size.
  ##   NextToken: string
  ##            : The pagination token.
  ##   OutpostId: string (required)
  ##            : The ID of the Outpost.
  var path_602032 = newJObject()
  var query_602033 = newJObject()
  add(query_602033, "MaxResults", newJInt(MaxResults))
  add(query_602033, "NextToken", newJString(NextToken))
  add(path_602032, "OutpostId", newJString(OutpostId))
  result = call_602031.call(path_602032, query_602033, nil, nil, nil)

var getOutpostInstanceTypes* = Call_GetOutpostInstanceTypes_602017(
    name: "getOutpostInstanceTypes", meth: HttpMethod.HttpGet,
    host: "outposts.amazonaws.com", route: "/outposts/{OutpostId}/instanceTypes",
    validator: validate_GetOutpostInstanceTypes_602018, base: "/",
    url: url_GetOutpostInstanceTypes_602019, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListSites_602034 = ref object of OpenApiRestCall_601380
proc url_ListSites_602036(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListSites_602035(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602037 = query.getOrDefault("MaxResults")
  valid_602037 = validateParameter(valid_602037, JInt, required = false, default = nil)
  if valid_602037 != nil:
    section.add "MaxResults", valid_602037
  var valid_602038 = query.getOrDefault("NextToken")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "NextToken", valid_602038
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
  var valid_602039 = header.getOrDefault("X-Amz-Signature")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "X-Amz-Signature", valid_602039
  var valid_602040 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602040 = validateParameter(valid_602040, JString, required = false,
                                 default = nil)
  if valid_602040 != nil:
    section.add "X-Amz-Content-Sha256", valid_602040
  var valid_602041 = header.getOrDefault("X-Amz-Date")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Date", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Credential")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Credential", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Security-Token")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Security-Token", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Algorithm")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Algorithm", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-SignedHeaders", valid_602045
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602046: Call_ListSites_602034; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Lists the sites for the specified AWS account.
  ## 
  let valid = call_602046.validator(path, query, header, formData, body)
  let scheme = call_602046.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602046.url(scheme.get, call_602046.host, call_602046.base,
                         call_602046.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602046, url, valid)

proc call*(call_602047: Call_ListSites_602034; MaxResults: int = 0;
          NextToken: string = ""): Recallable =
  ## listSites
  ## Lists the sites for the specified AWS account.
  ##   MaxResults: int
  ##             : The maximum page size.
  ##   NextToken: string
  ##            : The pagination token.
  var query_602048 = newJObject()
  add(query_602048, "MaxResults", newJInt(MaxResults))
  add(query_602048, "NextToken", newJString(NextToken))
  result = call_602047.call(nil, query_602048, nil, nil, nil)

var listSites* = Call_ListSites_602034(name: "listSites", meth: HttpMethod.HttpGet,
                                    host: "outposts.amazonaws.com",
                                    route: "/sites",
                                    validator: validate_ListSites_602035,
                                    base: "/", url: url_ListSites_602036,
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
