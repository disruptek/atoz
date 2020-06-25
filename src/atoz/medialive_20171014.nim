
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Elemental MediaLive
## version: 2017-10-14
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## API for AWS Elemental MediaLive
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/medialive/
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
    makeUrl*: proc (protocol: Scheme; host: string; base: string; route: string;
                  path: JsonNode; query: JsonNode): Uri

  OpenApiRestCall_21625435 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_21625435](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_21625435): Option[Scheme] {.used.} =
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "medialive.ap-northeast-1.amazonaws.com", "ap-southeast-1": "medialive.ap-southeast-1.amazonaws.com",
                           "us-west-2": "medialive.us-west-2.amazonaws.com",
                           "eu-west-2": "medialive.eu-west-2.amazonaws.com", "ap-northeast-3": "medialive.ap-northeast-3.amazonaws.com", "eu-central-1": "medialive.eu-central-1.amazonaws.com",
                           "us-east-2": "medialive.us-east-2.amazonaws.com",
                           "us-east-1": "medialive.us-east-1.amazonaws.com", "cn-northwest-1": "medialive.cn-northwest-1.amazonaws.com.cn",
                           "ap-south-1": "medialive.ap-south-1.amazonaws.com",
                           "eu-north-1": "medialive.eu-north-1.amazonaws.com", "ap-northeast-2": "medialive.ap-northeast-2.amazonaws.com",
                           "us-west-1": "medialive.us-west-1.amazonaws.com", "us-gov-east-1": "medialive.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "medialive.eu-west-3.amazonaws.com", "cn-north-1": "medialive.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "medialive.sa-east-1.amazonaws.com",
                           "eu-west-1": "medialive.eu-west-1.amazonaws.com", "us-gov-west-1": "medialive.us-gov-west-1.amazonaws.com", "ap-southeast-2": "medialive.ap-southeast-2.amazonaws.com", "ca-central-1": "medialive.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "medialive.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "medialive.ap-southeast-1.amazonaws.com",
      "us-west-2": "medialive.us-west-2.amazonaws.com",
      "eu-west-2": "medialive.eu-west-2.amazonaws.com",
      "ap-northeast-3": "medialive.ap-northeast-3.amazonaws.com",
      "eu-central-1": "medialive.eu-central-1.amazonaws.com",
      "us-east-2": "medialive.us-east-2.amazonaws.com",
      "us-east-1": "medialive.us-east-1.amazonaws.com",
      "cn-northwest-1": "medialive.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "medialive.ap-south-1.amazonaws.com",
      "eu-north-1": "medialive.eu-north-1.amazonaws.com",
      "ap-northeast-2": "medialive.ap-northeast-2.amazonaws.com",
      "us-west-1": "medialive.us-west-1.amazonaws.com",
      "us-gov-east-1": "medialive.us-gov-east-1.amazonaws.com",
      "eu-west-3": "medialive.eu-west-3.amazonaws.com",
      "cn-north-1": "medialive.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "medialive.sa-east-1.amazonaws.com",
      "eu-west-1": "medialive.eu-west-1.amazonaws.com",
      "us-gov-west-1": "medialive.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "medialive.ap-southeast-2.amazonaws.com",
      "ca-central-1": "medialive.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "medialive"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_BatchUpdateSchedule_21626036 = ref object of OpenApiRestCall_21625435
proc url_BatchUpdateSchedule_21626038(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId"),
               (kind: ConstantSegment, value: "/schedule")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_BatchUpdateSchedule_21626037(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Update a channel schedule
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_21626039 = path.getOrDefault("channelId")
  valid_21626039 = validateParameter(valid_21626039, JString, required = true,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "channelId", valid_21626039
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
  var valid_21626040 = header.getOrDefault("X-Amz-Date")
  valid_21626040 = validateParameter(valid_21626040, JString, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "X-Amz-Date", valid_21626040
  var valid_21626041 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "X-Amz-Security-Token", valid_21626041
  var valid_21626042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626042
  var valid_21626043 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "X-Amz-Algorithm", valid_21626043
  var valid_21626044 = header.getOrDefault("X-Amz-Signature")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Signature", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-Credential")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Credential", valid_21626046
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

proc call*(call_21626048: Call_BatchUpdateSchedule_21626036; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Update a channel schedule
  ## 
  let valid = call_21626048.validator(path, query, header, formData, body, _)
  let scheme = call_21626048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626048.makeUrl(scheme.get, call_21626048.host, call_21626048.base,
                               call_21626048.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626048, uri, valid, _)

proc call*(call_21626049: Call_BatchUpdateSchedule_21626036; channelId: string;
          body: JsonNode): Recallable =
  ## batchUpdateSchedule
  ## Update a channel schedule
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_21626050 = newJObject()
  var body_21626051 = newJObject()
  add(path_21626050, "channelId", newJString(channelId))
  if body != nil:
    body_21626051 = body
  result = call_21626049.call(path_21626050, nil, nil, nil, body_21626051)

var batchUpdateSchedule* = Call_BatchUpdateSchedule_21626036(
    name: "batchUpdateSchedule", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com", route: "/prod/channels/{channelId}/schedule",
    validator: validate_BatchUpdateSchedule_21626037, base: "/",
    makeUrl: url_BatchUpdateSchedule_21626038,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchedule_21625779 = ref object of OpenApiRestCall_21625435
proc url_DescribeSchedule_21625781(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId"),
               (kind: ConstantSegment, value: "/schedule")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeSchedule_21625780(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get a channel schedule
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_21625895 = path.getOrDefault("channelId")
  valid_21625895 = validateParameter(valid_21625895, JString, required = true,
                                   default = nil)
  if valid_21625895 != nil:
    section.add "channelId", valid_21625895
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21625896 = query.getOrDefault("NextToken")
  valid_21625896 = validateParameter(valid_21625896, JString, required = false,
                                   default = nil)
  if valid_21625896 != nil:
    section.add "NextToken", valid_21625896
  var valid_21625897 = query.getOrDefault("maxResults")
  valid_21625897 = validateParameter(valid_21625897, JInt, required = false,
                                   default = nil)
  if valid_21625897 != nil:
    section.add "maxResults", valid_21625897
  var valid_21625898 = query.getOrDefault("nextToken")
  valid_21625898 = validateParameter(valid_21625898, JString, required = false,
                                   default = nil)
  if valid_21625898 != nil:
    section.add "nextToken", valid_21625898
  var valid_21625899 = query.getOrDefault("MaxResults")
  valid_21625899 = validateParameter(valid_21625899, JString, required = false,
                                   default = nil)
  if valid_21625899 != nil:
    section.add "MaxResults", valid_21625899
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
  var valid_21625900 = header.getOrDefault("X-Amz-Date")
  valid_21625900 = validateParameter(valid_21625900, JString, required = false,
                                   default = nil)
  if valid_21625900 != nil:
    section.add "X-Amz-Date", valid_21625900
  var valid_21625901 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625901 = validateParameter(valid_21625901, JString, required = false,
                                   default = nil)
  if valid_21625901 != nil:
    section.add "X-Amz-Security-Token", valid_21625901
  var valid_21625902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625902 = validateParameter(valid_21625902, JString, required = false,
                                   default = nil)
  if valid_21625902 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625902
  var valid_21625903 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625903 = validateParameter(valid_21625903, JString, required = false,
                                   default = nil)
  if valid_21625903 != nil:
    section.add "X-Amz-Algorithm", valid_21625903
  var valid_21625904 = header.getOrDefault("X-Amz-Signature")
  valid_21625904 = validateParameter(valid_21625904, JString, required = false,
                                   default = nil)
  if valid_21625904 != nil:
    section.add "X-Amz-Signature", valid_21625904
  var valid_21625905 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625905 = validateParameter(valid_21625905, JString, required = false,
                                   default = nil)
  if valid_21625905 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625905
  var valid_21625906 = header.getOrDefault("X-Amz-Credential")
  valid_21625906 = validateParameter(valid_21625906, JString, required = false,
                                   default = nil)
  if valid_21625906 != nil:
    section.add "X-Amz-Credential", valid_21625906
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625931: Call_DescribeSchedule_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Get a channel schedule
  ## 
  let valid = call_21625931.validator(path, query, header, formData, body, _)
  let scheme = call_21625931.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625931.makeUrl(scheme.get, call_21625931.host, call_21625931.base,
                               call_21625931.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625931, uri, valid, _)

proc call*(call_21625994: Call_DescribeSchedule_21625779; channelId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## describeSchedule
  ## Get a channel schedule
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21625996 = newJObject()
  var query_21625998 = newJObject()
  add(path_21625996, "channelId", newJString(channelId))
  add(query_21625998, "NextToken", newJString(NextToken))
  add(query_21625998, "maxResults", newJInt(maxResults))
  add(query_21625998, "nextToken", newJString(nextToken))
  add(query_21625998, "MaxResults", newJString(MaxResults))
  result = call_21625994.call(path_21625996, query_21625998, nil, nil, nil)

var describeSchedule* = Call_DescribeSchedule_21625779(name: "describeSchedule",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_DescribeSchedule_21625780, base: "/",
    makeUrl: url_DescribeSchedule_21625781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchedule_21626052 = ref object of OpenApiRestCall_21625435
proc url_DeleteSchedule_21626054(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId"),
               (kind: ConstantSegment, value: "/schedule")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSchedule_21626053(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete all schedule actions on a channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_21626055 = path.getOrDefault("channelId")
  valid_21626055 = validateParameter(valid_21626055, JString, required = true,
                                   default = nil)
  if valid_21626055 != nil:
    section.add "channelId", valid_21626055
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
  var valid_21626056 = header.getOrDefault("X-Amz-Date")
  valid_21626056 = validateParameter(valid_21626056, JString, required = false,
                                   default = nil)
  if valid_21626056 != nil:
    section.add "X-Amz-Date", valid_21626056
  var valid_21626057 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Security-Token", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Algorithm", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Signature")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Signature", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-Credential")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-Credential", valid_21626062
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626063: Call_DeleteSchedule_21626052; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete all schedule actions on a channel.
  ## 
  let valid = call_21626063.validator(path, query, header, formData, body, _)
  let scheme = call_21626063.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626063.makeUrl(scheme.get, call_21626063.host, call_21626063.base,
                               call_21626063.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626063, uri, valid, _)

proc call*(call_21626064: Call_DeleteSchedule_21626052; channelId: string): Recallable =
  ## deleteSchedule
  ## Delete all schedule actions on a channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_21626065 = newJObject()
  add(path_21626065, "channelId", newJString(channelId))
  result = call_21626064.call(path_21626065, nil, nil, nil, nil)

var deleteSchedule* = Call_DeleteSchedule_21626052(name: "deleteSchedule",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_DeleteSchedule_21626053, base: "/",
    makeUrl: url_DeleteSchedule_21626054, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateChannel_21626083 = ref object of OpenApiRestCall_21625435
proc url_CreateChannel_21626085(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateChannel_21626084(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a new channel
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
  var valid_21626086 = header.getOrDefault("X-Amz-Date")
  valid_21626086 = validateParameter(valid_21626086, JString, required = false,
                                   default = nil)
  if valid_21626086 != nil:
    section.add "X-Amz-Date", valid_21626086
  var valid_21626087 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626087 = validateParameter(valid_21626087, JString, required = false,
                                   default = nil)
  if valid_21626087 != nil:
    section.add "X-Amz-Security-Token", valid_21626087
  var valid_21626088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626088 = validateParameter(valid_21626088, JString, required = false,
                                   default = nil)
  if valid_21626088 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626088
  var valid_21626089 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-Algorithm", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-Signature")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Signature", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626091
  var valid_21626092 = header.getOrDefault("X-Amz-Credential")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Credential", valid_21626092
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

proc call*(call_21626094: Call_CreateChannel_21626083; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new channel
  ## 
  let valid = call_21626094.validator(path, query, header, formData, body, _)
  let scheme = call_21626094.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626094.makeUrl(scheme.get, call_21626094.host, call_21626094.base,
                               call_21626094.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626094, uri, valid, _)

proc call*(call_21626095: Call_CreateChannel_21626083; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a new channel
  ##   body: JObject (required)
  var body_21626096 = newJObject()
  if body != nil:
    body_21626096 = body
  result = call_21626095.call(nil, nil, nil, nil, body_21626096)

var createChannel* = Call_CreateChannel_21626083(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels", validator: validate_CreateChannel_21626084, base: "/",
    makeUrl: url_CreateChannel_21626085, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_21626066 = ref object of OpenApiRestCall_21625435
proc url_ListChannels_21626068(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListChannels_21626067(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Produces list of channels that have been created
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626069 = query.getOrDefault("NextToken")
  valid_21626069 = validateParameter(valid_21626069, JString, required = false,
                                   default = nil)
  if valid_21626069 != nil:
    section.add "NextToken", valid_21626069
  var valid_21626070 = query.getOrDefault("maxResults")
  valid_21626070 = validateParameter(valid_21626070, JInt, required = false,
                                   default = nil)
  if valid_21626070 != nil:
    section.add "maxResults", valid_21626070
  var valid_21626071 = query.getOrDefault("nextToken")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "nextToken", valid_21626071
  var valid_21626072 = query.getOrDefault("MaxResults")
  valid_21626072 = validateParameter(valid_21626072, JString, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "MaxResults", valid_21626072
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
  var valid_21626073 = header.getOrDefault("X-Amz-Date")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "X-Amz-Date", valid_21626073
  var valid_21626074 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "X-Amz-Security-Token", valid_21626074
  var valid_21626075 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626075
  var valid_21626076 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-Algorithm", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-Signature")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Signature", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Credential")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Credential", valid_21626079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626080: Call_ListChannels_21626066; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Produces list of channels that have been created
  ## 
  let valid = call_21626080.validator(path, query, header, formData, body, _)
  let scheme = call_21626080.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626080.makeUrl(scheme.get, call_21626080.host, call_21626080.base,
                               call_21626080.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626080, uri, valid, _)

proc call*(call_21626081: Call_ListChannels_21626066; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listChannels
  ## Produces list of channels that have been created
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626082 = newJObject()
  add(query_21626082, "NextToken", newJString(NextToken))
  add(query_21626082, "maxResults", newJInt(maxResults))
  add(query_21626082, "nextToken", newJString(nextToken))
  add(query_21626082, "MaxResults", newJString(MaxResults))
  result = call_21626081.call(nil, query_21626082, nil, nil, nil)

var listChannels* = Call_ListChannels_21626066(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels", validator: validate_ListChannels_21626067, base: "/",
    makeUrl: url_ListChannels_21626068, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInput_21626114 = ref object of OpenApiRestCall_21625435
proc url_CreateInput_21626116(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInput_21626115(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create an input
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
  var valid_21626117 = header.getOrDefault("X-Amz-Date")
  valid_21626117 = validateParameter(valid_21626117, JString, required = false,
                                   default = nil)
  if valid_21626117 != nil:
    section.add "X-Amz-Date", valid_21626117
  var valid_21626118 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626118 = validateParameter(valid_21626118, JString, required = false,
                                   default = nil)
  if valid_21626118 != nil:
    section.add "X-Amz-Security-Token", valid_21626118
  var valid_21626119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626119 = validateParameter(valid_21626119, JString, required = false,
                                   default = nil)
  if valid_21626119 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626119
  var valid_21626120 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626120 = validateParameter(valid_21626120, JString, required = false,
                                   default = nil)
  if valid_21626120 != nil:
    section.add "X-Amz-Algorithm", valid_21626120
  var valid_21626121 = header.getOrDefault("X-Amz-Signature")
  valid_21626121 = validateParameter(valid_21626121, JString, required = false,
                                   default = nil)
  if valid_21626121 != nil:
    section.add "X-Amz-Signature", valid_21626121
  var valid_21626122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626122 = validateParameter(valid_21626122, JString, required = false,
                                   default = nil)
  if valid_21626122 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626122
  var valid_21626123 = header.getOrDefault("X-Amz-Credential")
  valid_21626123 = validateParameter(valid_21626123, JString, required = false,
                                   default = nil)
  if valid_21626123 != nil:
    section.add "X-Amz-Credential", valid_21626123
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

proc call*(call_21626125: Call_CreateInput_21626114; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Create an input
  ## 
  let valid = call_21626125.validator(path, query, header, formData, body, _)
  let scheme = call_21626125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626125.makeUrl(scheme.get, call_21626125.host, call_21626125.base,
                               call_21626125.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626125, uri, valid, _)

proc call*(call_21626126: Call_CreateInput_21626114; body: JsonNode): Recallable =
  ## createInput
  ## Create an input
  ##   body: JObject (required)
  var body_21626127 = newJObject()
  if body != nil:
    body_21626127 = body
  result = call_21626126.call(nil, nil, nil, nil, body_21626127)

var createInput* = Call_CreateInput_21626114(name: "createInput",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/inputs", validator: validate_CreateInput_21626115, base: "/",
    makeUrl: url_CreateInput_21626116, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputs_21626097 = ref object of OpenApiRestCall_21625435
proc url_ListInputs_21626099(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInputs_21626098(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Produces list of inputs that have been created
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626100 = query.getOrDefault("NextToken")
  valid_21626100 = validateParameter(valid_21626100, JString, required = false,
                                   default = nil)
  if valid_21626100 != nil:
    section.add "NextToken", valid_21626100
  var valid_21626101 = query.getOrDefault("maxResults")
  valid_21626101 = validateParameter(valid_21626101, JInt, required = false,
                                   default = nil)
  if valid_21626101 != nil:
    section.add "maxResults", valid_21626101
  var valid_21626102 = query.getOrDefault("nextToken")
  valid_21626102 = validateParameter(valid_21626102, JString, required = false,
                                   default = nil)
  if valid_21626102 != nil:
    section.add "nextToken", valid_21626102
  var valid_21626103 = query.getOrDefault("MaxResults")
  valid_21626103 = validateParameter(valid_21626103, JString, required = false,
                                   default = nil)
  if valid_21626103 != nil:
    section.add "MaxResults", valid_21626103
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
  var valid_21626104 = header.getOrDefault("X-Amz-Date")
  valid_21626104 = validateParameter(valid_21626104, JString, required = false,
                                   default = nil)
  if valid_21626104 != nil:
    section.add "X-Amz-Date", valid_21626104
  var valid_21626105 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626105 = validateParameter(valid_21626105, JString, required = false,
                                   default = nil)
  if valid_21626105 != nil:
    section.add "X-Amz-Security-Token", valid_21626105
  var valid_21626106 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626106 = validateParameter(valid_21626106, JString, required = false,
                                   default = nil)
  if valid_21626106 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626106
  var valid_21626107 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626107 = validateParameter(valid_21626107, JString, required = false,
                                   default = nil)
  if valid_21626107 != nil:
    section.add "X-Amz-Algorithm", valid_21626107
  var valid_21626108 = header.getOrDefault("X-Amz-Signature")
  valid_21626108 = validateParameter(valid_21626108, JString, required = false,
                                   default = nil)
  if valid_21626108 != nil:
    section.add "X-Amz-Signature", valid_21626108
  var valid_21626109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626109 = validateParameter(valid_21626109, JString, required = false,
                                   default = nil)
  if valid_21626109 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626109
  var valid_21626110 = header.getOrDefault("X-Amz-Credential")
  valid_21626110 = validateParameter(valid_21626110, JString, required = false,
                                   default = nil)
  if valid_21626110 != nil:
    section.add "X-Amz-Credential", valid_21626110
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626111: Call_ListInputs_21626097; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Produces list of inputs that have been created
  ## 
  let valid = call_21626111.validator(path, query, header, formData, body, _)
  let scheme = call_21626111.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626111.makeUrl(scheme.get, call_21626111.host, call_21626111.base,
                               call_21626111.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626111, uri, valid, _)

proc call*(call_21626112: Call_ListInputs_21626097; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listInputs
  ## Produces list of inputs that have been created
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626113 = newJObject()
  add(query_21626113, "NextToken", newJString(NextToken))
  add(query_21626113, "maxResults", newJInt(maxResults))
  add(query_21626113, "nextToken", newJString(nextToken))
  add(query_21626113, "MaxResults", newJString(MaxResults))
  result = call_21626112.call(nil, query_21626113, nil, nil, nil)

var listInputs* = Call_ListInputs_21626097(name: "listInputs",
                                        meth: HttpMethod.HttpGet,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs",
                                        validator: validate_ListInputs_21626098,
                                        base: "/", makeUrl: url_ListInputs_21626099,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInputSecurityGroup_21626145 = ref object of OpenApiRestCall_21625435
proc url_CreateInputSecurityGroup_21626147(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInputSecurityGroup_21626146(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a Input Security Group
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
  var valid_21626148 = header.getOrDefault("X-Amz-Date")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Date", valid_21626148
  var valid_21626149 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Security-Token", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Algorithm", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-Signature")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-Signature", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626153
  var valid_21626154 = header.getOrDefault("X-Amz-Credential")
  valid_21626154 = validateParameter(valid_21626154, JString, required = false,
                                   default = nil)
  if valid_21626154 != nil:
    section.add "X-Amz-Credential", valid_21626154
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

proc call*(call_21626156: Call_CreateInputSecurityGroup_21626145;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a Input Security Group
  ## 
  let valid = call_21626156.validator(path, query, header, formData, body, _)
  let scheme = call_21626156.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626156.makeUrl(scheme.get, call_21626156.host, call_21626156.base,
                               call_21626156.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626156, uri, valid, _)

proc call*(call_21626157: Call_CreateInputSecurityGroup_21626145; body: JsonNode): Recallable =
  ## createInputSecurityGroup
  ## Creates a Input Security Group
  ##   body: JObject (required)
  var body_21626158 = newJObject()
  if body != nil:
    body_21626158 = body
  result = call_21626157.call(nil, nil, nil, nil, body_21626158)

var createInputSecurityGroup* = Call_CreateInputSecurityGroup_21626145(
    name: "createInputSecurityGroup", meth: HttpMethod.HttpPost,
    host: "medialive.amazonaws.com", route: "/prod/inputSecurityGroups",
    validator: validate_CreateInputSecurityGroup_21626146, base: "/",
    makeUrl: url_CreateInputSecurityGroup_21626147,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputSecurityGroups_21626128 = ref object of OpenApiRestCall_21625435
proc url_ListInputSecurityGroups_21626130(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInputSecurityGroups_21626129(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Produces a list of Input Security Groups for an account
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626131 = query.getOrDefault("NextToken")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "NextToken", valid_21626131
  var valid_21626132 = query.getOrDefault("maxResults")
  valid_21626132 = validateParameter(valid_21626132, JInt, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "maxResults", valid_21626132
  var valid_21626133 = query.getOrDefault("nextToken")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "nextToken", valid_21626133
  var valid_21626134 = query.getOrDefault("MaxResults")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "MaxResults", valid_21626134
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
  var valid_21626135 = header.getOrDefault("X-Amz-Date")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Date", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-Security-Token", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626137
  var valid_21626138 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626138 = validateParameter(valid_21626138, JString, required = false,
                                   default = nil)
  if valid_21626138 != nil:
    section.add "X-Amz-Algorithm", valid_21626138
  var valid_21626139 = header.getOrDefault("X-Amz-Signature")
  valid_21626139 = validateParameter(valid_21626139, JString, required = false,
                                   default = nil)
  if valid_21626139 != nil:
    section.add "X-Amz-Signature", valid_21626139
  var valid_21626140 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626140 = validateParameter(valid_21626140, JString, required = false,
                                   default = nil)
  if valid_21626140 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626140
  var valid_21626141 = header.getOrDefault("X-Amz-Credential")
  valid_21626141 = validateParameter(valid_21626141, JString, required = false,
                                   default = nil)
  if valid_21626141 != nil:
    section.add "X-Amz-Credential", valid_21626141
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626142: Call_ListInputSecurityGroups_21626128;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Produces a list of Input Security Groups for an account
  ## 
  let valid = call_21626142.validator(path, query, header, formData, body, _)
  let scheme = call_21626142.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626142.makeUrl(scheme.get, call_21626142.host, call_21626142.base,
                               call_21626142.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626142, uri, valid, _)

proc call*(call_21626143: Call_ListInputSecurityGroups_21626128;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listInputSecurityGroups
  ## Produces a list of Input Security Groups for an account
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626144 = newJObject()
  add(query_21626144, "NextToken", newJString(NextToken))
  add(query_21626144, "maxResults", newJInt(maxResults))
  add(query_21626144, "nextToken", newJString(nextToken))
  add(query_21626144, "MaxResults", newJString(MaxResults))
  result = call_21626143.call(nil, query_21626144, nil, nil, nil)

var listInputSecurityGroups* = Call_ListInputSecurityGroups_21626128(
    name: "listInputSecurityGroups", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/inputSecurityGroups",
    validator: validate_ListInputSecurityGroups_21626129, base: "/",
    makeUrl: url_ListInputSecurityGroups_21626130,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultiplex_21626176 = ref object of OpenApiRestCall_21625435
proc url_CreateMultiplex_21626178(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMultiplex_21626177(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create a new multiplex.
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
  var valid_21626179 = header.getOrDefault("X-Amz-Date")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Date", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-Security-Token", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626181
  var valid_21626182 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626182 = validateParameter(valid_21626182, JString, required = false,
                                   default = nil)
  if valid_21626182 != nil:
    section.add "X-Amz-Algorithm", valid_21626182
  var valid_21626183 = header.getOrDefault("X-Amz-Signature")
  valid_21626183 = validateParameter(valid_21626183, JString, required = false,
                                   default = nil)
  if valid_21626183 != nil:
    section.add "X-Amz-Signature", valid_21626183
  var valid_21626184 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626184 = validateParameter(valid_21626184, JString, required = false,
                                   default = nil)
  if valid_21626184 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626184
  var valid_21626185 = header.getOrDefault("X-Amz-Credential")
  valid_21626185 = validateParameter(valid_21626185, JString, required = false,
                                   default = nil)
  if valid_21626185 != nil:
    section.add "X-Amz-Credential", valid_21626185
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

proc call*(call_21626187: Call_CreateMultiplex_21626176; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new multiplex.
  ## 
  let valid = call_21626187.validator(path, query, header, formData, body, _)
  let scheme = call_21626187.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626187.makeUrl(scheme.get, call_21626187.host, call_21626187.base,
                               call_21626187.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626187, uri, valid, _)

proc call*(call_21626188: Call_CreateMultiplex_21626176; body: JsonNode): Recallable =
  ## createMultiplex
  ## Create a new multiplex.
  ##   body: JObject (required)
  var body_21626189 = newJObject()
  if body != nil:
    body_21626189 = body
  result = call_21626188.call(nil, nil, nil, nil, body_21626189)

var createMultiplex* = Call_CreateMultiplex_21626176(name: "createMultiplex",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes", validator: validate_CreateMultiplex_21626177,
    base: "/", makeUrl: url_CreateMultiplex_21626178,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultiplexes_21626159 = ref object of OpenApiRestCall_21625435
proc url_ListMultiplexes_21626161(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMultiplexes_21626160(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Retrieve a list of the existing multiplexes.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626162 = query.getOrDefault("NextToken")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "NextToken", valid_21626162
  var valid_21626163 = query.getOrDefault("maxResults")
  valid_21626163 = validateParameter(valid_21626163, JInt, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "maxResults", valid_21626163
  var valid_21626164 = query.getOrDefault("nextToken")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "nextToken", valid_21626164
  var valid_21626165 = query.getOrDefault("MaxResults")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "MaxResults", valid_21626165
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
  var valid_21626166 = header.getOrDefault("X-Amz-Date")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-Date", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Security-Token", valid_21626167
  var valid_21626168 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626168 = validateParameter(valid_21626168, JString, required = false,
                                   default = nil)
  if valid_21626168 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626168
  var valid_21626169 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626169 = validateParameter(valid_21626169, JString, required = false,
                                   default = nil)
  if valid_21626169 != nil:
    section.add "X-Amz-Algorithm", valid_21626169
  var valid_21626170 = header.getOrDefault("X-Amz-Signature")
  valid_21626170 = validateParameter(valid_21626170, JString, required = false,
                                   default = nil)
  if valid_21626170 != nil:
    section.add "X-Amz-Signature", valid_21626170
  var valid_21626171 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626171 = validateParameter(valid_21626171, JString, required = false,
                                   default = nil)
  if valid_21626171 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626171
  var valid_21626172 = header.getOrDefault("X-Amz-Credential")
  valid_21626172 = validateParameter(valid_21626172, JString, required = false,
                                   default = nil)
  if valid_21626172 != nil:
    section.add "X-Amz-Credential", valid_21626172
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626173: Call_ListMultiplexes_21626159; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Retrieve a list of the existing multiplexes.
  ## 
  let valid = call_21626173.validator(path, query, header, formData, body, _)
  let scheme = call_21626173.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626173.makeUrl(scheme.get, call_21626173.host, call_21626173.base,
                               call_21626173.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626173, uri, valid, _)

proc call*(call_21626174: Call_ListMultiplexes_21626159; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listMultiplexes
  ## Retrieve a list of the existing multiplexes.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626175 = newJObject()
  add(query_21626175, "NextToken", newJString(NextToken))
  add(query_21626175, "maxResults", newJInt(maxResults))
  add(query_21626175, "nextToken", newJString(nextToken))
  add(query_21626175, "MaxResults", newJString(MaxResults))
  result = call_21626174.call(nil, query_21626175, nil, nil, nil)

var listMultiplexes* = Call_ListMultiplexes_21626159(name: "listMultiplexes",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes", validator: validate_ListMultiplexes_21626160,
    base: "/", makeUrl: url_ListMultiplexes_21626161,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultiplexProgram_21626209 = ref object of OpenApiRestCall_21625435
proc url_CreateMultiplexProgram_21626211(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
               (kind: VariableSegment, value: "multiplexId"),
               (kind: ConstantSegment, value: "/programs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateMultiplexProgram_21626210(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create a new program in the multiplex.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
  ##              : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `multiplexId` field"
  var valid_21626212 = path.getOrDefault("multiplexId")
  valid_21626212 = validateParameter(valid_21626212, JString, required = true,
                                   default = nil)
  if valid_21626212 != nil:
    section.add "multiplexId", valid_21626212
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
  var valid_21626213 = header.getOrDefault("X-Amz-Date")
  valid_21626213 = validateParameter(valid_21626213, JString, required = false,
                                   default = nil)
  if valid_21626213 != nil:
    section.add "X-Amz-Date", valid_21626213
  var valid_21626214 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626214 = validateParameter(valid_21626214, JString, required = false,
                                   default = nil)
  if valid_21626214 != nil:
    section.add "X-Amz-Security-Token", valid_21626214
  var valid_21626215 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626215 = validateParameter(valid_21626215, JString, required = false,
                                   default = nil)
  if valid_21626215 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626215
  var valid_21626216 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626216 = validateParameter(valid_21626216, JString, required = false,
                                   default = nil)
  if valid_21626216 != nil:
    section.add "X-Amz-Algorithm", valid_21626216
  var valid_21626217 = header.getOrDefault("X-Amz-Signature")
  valid_21626217 = validateParameter(valid_21626217, JString, required = false,
                                   default = nil)
  if valid_21626217 != nil:
    section.add "X-Amz-Signature", valid_21626217
  var valid_21626218 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626218 = validateParameter(valid_21626218, JString, required = false,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626218
  var valid_21626219 = header.getOrDefault("X-Amz-Credential")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Credential", valid_21626219
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

proc call*(call_21626221: Call_CreateMultiplexProgram_21626209;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Create a new program in the multiplex.
  ## 
  let valid = call_21626221.validator(path, query, header, formData, body, _)
  let scheme = call_21626221.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626221.makeUrl(scheme.get, call_21626221.host, call_21626221.base,
                               call_21626221.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626221, uri, valid, _)

proc call*(call_21626222: Call_CreateMultiplexProgram_21626209;
          multiplexId: string; body: JsonNode): Recallable =
  ## createMultiplexProgram
  ## Create a new program in the multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_21626223 = newJObject()
  var body_21626224 = newJObject()
  add(path_21626223, "multiplexId", newJString(multiplexId))
  if body != nil:
    body_21626224 = body
  result = call_21626222.call(path_21626223, nil, nil, nil, body_21626224)

var createMultiplexProgram* = Call_CreateMultiplexProgram_21626209(
    name: "createMultiplexProgram", meth: HttpMethod.HttpPost,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs",
    validator: validate_CreateMultiplexProgram_21626210, base: "/",
    makeUrl: url_CreateMultiplexProgram_21626211,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultiplexPrograms_21626190 = ref object of OpenApiRestCall_21625435
proc url_ListMultiplexPrograms_21626192(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
               (kind: VariableSegment, value: "multiplexId"),
               (kind: ConstantSegment, value: "/programs")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListMultiplexPrograms_21626191(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List the programs that currently exist for a specific multiplex.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
  ##              : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `multiplexId` field"
  var valid_21626193 = path.getOrDefault("multiplexId")
  valid_21626193 = validateParameter(valid_21626193, JString, required = true,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "multiplexId", valid_21626193
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626194 = query.getOrDefault("NextToken")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "NextToken", valid_21626194
  var valid_21626195 = query.getOrDefault("maxResults")
  valid_21626195 = validateParameter(valid_21626195, JInt, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "maxResults", valid_21626195
  var valid_21626196 = query.getOrDefault("nextToken")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "nextToken", valid_21626196
  var valid_21626197 = query.getOrDefault("MaxResults")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "MaxResults", valid_21626197
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
  var valid_21626198 = header.getOrDefault("X-Amz-Date")
  valid_21626198 = validateParameter(valid_21626198, JString, required = false,
                                   default = nil)
  if valid_21626198 != nil:
    section.add "X-Amz-Date", valid_21626198
  var valid_21626199 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626199 = validateParameter(valid_21626199, JString, required = false,
                                   default = nil)
  if valid_21626199 != nil:
    section.add "X-Amz-Security-Token", valid_21626199
  var valid_21626200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626200 = validateParameter(valid_21626200, JString, required = false,
                                   default = nil)
  if valid_21626200 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626200
  var valid_21626201 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626201 = validateParameter(valid_21626201, JString, required = false,
                                   default = nil)
  if valid_21626201 != nil:
    section.add "X-Amz-Algorithm", valid_21626201
  var valid_21626202 = header.getOrDefault("X-Amz-Signature")
  valid_21626202 = validateParameter(valid_21626202, JString, required = false,
                                   default = nil)
  if valid_21626202 != nil:
    section.add "X-Amz-Signature", valid_21626202
  var valid_21626203 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626203 = validateParameter(valid_21626203, JString, required = false,
                                   default = nil)
  if valid_21626203 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626203
  var valid_21626204 = header.getOrDefault("X-Amz-Credential")
  valid_21626204 = validateParameter(valid_21626204, JString, required = false,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "X-Amz-Credential", valid_21626204
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626205: Call_ListMultiplexPrograms_21626190;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## List the programs that currently exist for a specific multiplex.
  ## 
  let valid = call_21626205.validator(path, query, header, formData, body, _)
  let scheme = call_21626205.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626205.makeUrl(scheme.get, call_21626205.host, call_21626205.base,
                               call_21626205.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626205, uri, valid, _)

proc call*(call_21626206: Call_ListMultiplexPrograms_21626190; multiplexId: string;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          MaxResults: string = ""): Recallable =
  ## listMultiplexPrograms
  ## List the programs that currently exist for a specific multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  var path_21626207 = newJObject()
  var query_21626208 = newJObject()
  add(path_21626207, "multiplexId", newJString(multiplexId))
  add(query_21626208, "NextToken", newJString(NextToken))
  add(query_21626208, "maxResults", newJInt(maxResults))
  add(query_21626208, "nextToken", newJString(nextToken))
  add(query_21626208, "MaxResults", newJString(MaxResults))
  result = call_21626206.call(path_21626207, query_21626208, nil, nil, nil)

var listMultiplexPrograms* = Call_ListMultiplexPrograms_21626190(
    name: "listMultiplexPrograms", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs",
    validator: validate_ListMultiplexPrograms_21626191, base: "/",
    makeUrl: url_ListMultiplexPrograms_21626192,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_21626239 = ref object of OpenApiRestCall_21625435
proc url_CreateTags_21626241(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTags_21626240(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Create tags for a resource
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21626242 = path.getOrDefault("resource-arn")
  valid_21626242 = validateParameter(valid_21626242, JString, required = true,
                                   default = nil)
  if valid_21626242 != nil:
    section.add "resource-arn", valid_21626242
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
  var valid_21626243 = header.getOrDefault("X-Amz-Date")
  valid_21626243 = validateParameter(valid_21626243, JString, required = false,
                                   default = nil)
  if valid_21626243 != nil:
    section.add "X-Amz-Date", valid_21626243
  var valid_21626244 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626244 = validateParameter(valid_21626244, JString, required = false,
                                   default = nil)
  if valid_21626244 != nil:
    section.add "X-Amz-Security-Token", valid_21626244
  var valid_21626245 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626245 = validateParameter(valid_21626245, JString, required = false,
                                   default = nil)
  if valid_21626245 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626245
  var valid_21626246 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626246 = validateParameter(valid_21626246, JString, required = false,
                                   default = nil)
  if valid_21626246 != nil:
    section.add "X-Amz-Algorithm", valid_21626246
  var valid_21626247 = header.getOrDefault("X-Amz-Signature")
  valid_21626247 = validateParameter(valid_21626247, JString, required = false,
                                   default = nil)
  if valid_21626247 != nil:
    section.add "X-Amz-Signature", valid_21626247
  var valid_21626248 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626248 = validateParameter(valid_21626248, JString, required = false,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626248
  var valid_21626249 = header.getOrDefault("X-Amz-Credential")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Credential", valid_21626249
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

proc call*(call_21626251: Call_CreateTags_21626239; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Create tags for a resource
  ## 
  let valid = call_21626251.validator(path, query, header, formData, body, _)
  let scheme = call_21626251.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626251.makeUrl(scheme.get, call_21626251.host, call_21626251.base,
                               call_21626251.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626251, uri, valid, _)

proc call*(call_21626252: Call_CreateTags_21626239; resourceArn: string;
          body: JsonNode): Recallable =
  ## createTags
  ## Create tags for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_21626253 = newJObject()
  var body_21626254 = newJObject()
  add(path_21626253, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_21626254 = body
  result = call_21626252.call(path_21626253, nil, nil, nil, body_21626254)

var createTags* = Call_CreateTags_21626239(name: "createTags",
                                        meth: HttpMethod.HttpPost,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/tags/{resource-arn}",
                                        validator: validate_CreateTags_21626240,
                                        base: "/", makeUrl: url_CreateTags_21626241,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626225 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626227(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_21626226(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Produces list of tags that have been created for a resource
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21626228 = path.getOrDefault("resource-arn")
  valid_21626228 = validateParameter(valid_21626228, JString, required = true,
                                   default = nil)
  if valid_21626228 != nil:
    section.add "resource-arn", valid_21626228
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
  var valid_21626229 = header.getOrDefault("X-Amz-Date")
  valid_21626229 = validateParameter(valid_21626229, JString, required = false,
                                   default = nil)
  if valid_21626229 != nil:
    section.add "X-Amz-Date", valid_21626229
  var valid_21626230 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626230 = validateParameter(valid_21626230, JString, required = false,
                                   default = nil)
  if valid_21626230 != nil:
    section.add "X-Amz-Security-Token", valid_21626230
  var valid_21626231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626231 = validateParameter(valid_21626231, JString, required = false,
                                   default = nil)
  if valid_21626231 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626231
  var valid_21626232 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626232 = validateParameter(valid_21626232, JString, required = false,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "X-Amz-Algorithm", valid_21626232
  var valid_21626233 = header.getOrDefault("X-Amz-Signature")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Signature", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626234
  var valid_21626235 = header.getOrDefault("X-Amz-Credential")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "X-Amz-Credential", valid_21626235
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626236: Call_ListTagsForResource_21626225; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Produces list of tags that have been created for a resource
  ## 
  let valid = call_21626236.validator(path, query, header, formData, body, _)
  let scheme = call_21626236.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626236.makeUrl(scheme.get, call_21626236.host, call_21626236.base,
                               call_21626236.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626236, uri, valid, _)

proc call*(call_21626237: Call_ListTagsForResource_21626225; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Produces list of tags that have been created for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  var path_21626238 = newJObject()
  add(path_21626238, "resource-arn", newJString(resourceArn))
  result = call_21626237.call(path_21626238, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626225(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/tags/{resource-arn}",
    validator: validate_ListTagsForResource_21626226, base: "/",
    makeUrl: url_ListTagsForResource_21626227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_21626269 = ref object of OpenApiRestCall_21625435
proc url_UpdateChannel_21626271(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateChannel_21626270(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Updates a channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_21626272 = path.getOrDefault("channelId")
  valid_21626272 = validateParameter(valid_21626272, JString, required = true,
                                   default = nil)
  if valid_21626272 != nil:
    section.add "channelId", valid_21626272
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
  var valid_21626273 = header.getOrDefault("X-Amz-Date")
  valid_21626273 = validateParameter(valid_21626273, JString, required = false,
                                   default = nil)
  if valid_21626273 != nil:
    section.add "X-Amz-Date", valid_21626273
  var valid_21626274 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626274 = validateParameter(valid_21626274, JString, required = false,
                                   default = nil)
  if valid_21626274 != nil:
    section.add "X-Amz-Security-Token", valid_21626274
  var valid_21626275 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626275 = validateParameter(valid_21626275, JString, required = false,
                                   default = nil)
  if valid_21626275 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626275
  var valid_21626276 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626276 = validateParameter(valid_21626276, JString, required = false,
                                   default = nil)
  if valid_21626276 != nil:
    section.add "X-Amz-Algorithm", valid_21626276
  var valid_21626277 = header.getOrDefault("X-Amz-Signature")
  valid_21626277 = validateParameter(valid_21626277, JString, required = false,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "X-Amz-Signature", valid_21626277
  var valid_21626278 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626278 = validateParameter(valid_21626278, JString, required = false,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626278
  var valid_21626279 = header.getOrDefault("X-Amz-Credential")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Credential", valid_21626279
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

proc call*(call_21626281: Call_UpdateChannel_21626269; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a channel.
  ## 
  let valid = call_21626281.validator(path, query, header, formData, body, _)
  let scheme = call_21626281.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626281.makeUrl(scheme.get, call_21626281.host, call_21626281.base,
                               call_21626281.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626281, uri, valid, _)

proc call*(call_21626282: Call_UpdateChannel_21626269; channelId: string;
          body: JsonNode): Recallable =
  ## updateChannel
  ## Updates a channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_21626283 = newJObject()
  var body_21626284 = newJObject()
  add(path_21626283, "channelId", newJString(channelId))
  if body != nil:
    body_21626284 = body
  result = call_21626282.call(path_21626283, nil, nil, nil, body_21626284)

var updateChannel* = Call_UpdateChannel_21626269(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_UpdateChannel_21626270,
    base: "/", makeUrl: url_UpdateChannel_21626271,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_21626255 = ref object of OpenApiRestCall_21625435
proc url_DescribeChannel_21626257(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeChannel_21626256(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets details about a channel
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_21626258 = path.getOrDefault("channelId")
  valid_21626258 = validateParameter(valid_21626258, JString, required = true,
                                   default = nil)
  if valid_21626258 != nil:
    section.add "channelId", valid_21626258
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
  var valid_21626259 = header.getOrDefault("X-Amz-Date")
  valid_21626259 = validateParameter(valid_21626259, JString, required = false,
                                   default = nil)
  if valid_21626259 != nil:
    section.add "X-Amz-Date", valid_21626259
  var valid_21626260 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626260 = validateParameter(valid_21626260, JString, required = false,
                                   default = nil)
  if valid_21626260 != nil:
    section.add "X-Amz-Security-Token", valid_21626260
  var valid_21626261 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626261 = validateParameter(valid_21626261, JString, required = false,
                                   default = nil)
  if valid_21626261 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626261
  var valid_21626262 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626262 = validateParameter(valid_21626262, JString, required = false,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "X-Amz-Algorithm", valid_21626262
  var valid_21626263 = header.getOrDefault("X-Amz-Signature")
  valid_21626263 = validateParameter(valid_21626263, JString, required = false,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "X-Amz-Signature", valid_21626263
  var valid_21626264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-Credential")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-Credential", valid_21626265
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626266: Call_DescribeChannel_21626255; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details about a channel
  ## 
  let valid = call_21626266.validator(path, query, header, formData, body, _)
  let scheme = call_21626266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626266.makeUrl(scheme.get, call_21626266.host, call_21626266.base,
                               call_21626266.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626266, uri, valid, _)

proc call*(call_21626267: Call_DescribeChannel_21626255; channelId: string): Recallable =
  ## describeChannel
  ## Gets details about a channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_21626268 = newJObject()
  add(path_21626268, "channelId", newJString(channelId))
  result = call_21626267.call(path_21626268, nil, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_21626255(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_DescribeChannel_21626256,
    base: "/", makeUrl: url_DescribeChannel_21626257,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_21626285 = ref object of OpenApiRestCall_21625435
proc url_DeleteChannel_21626287(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteChannel_21626286(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Starts deletion of channel. The associated outputs are also deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_21626288 = path.getOrDefault("channelId")
  valid_21626288 = validateParameter(valid_21626288, JString, required = true,
                                   default = nil)
  if valid_21626288 != nil:
    section.add "channelId", valid_21626288
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
  var valid_21626289 = header.getOrDefault("X-Amz-Date")
  valid_21626289 = validateParameter(valid_21626289, JString, required = false,
                                   default = nil)
  if valid_21626289 != nil:
    section.add "X-Amz-Date", valid_21626289
  var valid_21626290 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626290 = validateParameter(valid_21626290, JString, required = false,
                                   default = nil)
  if valid_21626290 != nil:
    section.add "X-Amz-Security-Token", valid_21626290
  var valid_21626291 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626291 = validateParameter(valid_21626291, JString, required = false,
                                   default = nil)
  if valid_21626291 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626291
  var valid_21626292 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626292 = validateParameter(valid_21626292, JString, required = false,
                                   default = nil)
  if valid_21626292 != nil:
    section.add "X-Amz-Algorithm", valid_21626292
  var valid_21626293 = header.getOrDefault("X-Amz-Signature")
  valid_21626293 = validateParameter(valid_21626293, JString, required = false,
                                   default = nil)
  if valid_21626293 != nil:
    section.add "X-Amz-Signature", valid_21626293
  var valid_21626294 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626294 = validateParameter(valid_21626294, JString, required = false,
                                   default = nil)
  if valid_21626294 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626294
  var valid_21626295 = header.getOrDefault("X-Amz-Credential")
  valid_21626295 = validateParameter(valid_21626295, JString, required = false,
                                   default = nil)
  if valid_21626295 != nil:
    section.add "X-Amz-Credential", valid_21626295
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626296: Call_DeleteChannel_21626285; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts deletion of channel. The associated outputs are also deleted.
  ## 
  let valid = call_21626296.validator(path, query, header, formData, body, _)
  let scheme = call_21626296.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626296.makeUrl(scheme.get, call_21626296.host, call_21626296.base,
                               call_21626296.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626296, uri, valid, _)

proc call*(call_21626297: Call_DeleteChannel_21626285; channelId: string): Recallable =
  ## deleteChannel
  ## Starts deletion of channel. The associated outputs are also deleted.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_21626298 = newJObject()
  add(path_21626298, "channelId", newJString(channelId))
  result = call_21626297.call(path_21626298, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_21626285(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_DeleteChannel_21626286,
    base: "/", makeUrl: url_DeleteChannel_21626287,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInput_21626313 = ref object of OpenApiRestCall_21625435
proc url_UpdateInput_21626315(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputId" in path, "`inputId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputs/"),
               (kind: VariableSegment, value: "inputId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateInput_21626314(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an input.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputId: JString (required)
  ##          : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputId` field"
  var valid_21626316 = path.getOrDefault("inputId")
  valid_21626316 = validateParameter(valid_21626316, JString, required = true,
                                   default = nil)
  if valid_21626316 != nil:
    section.add "inputId", valid_21626316
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
  var valid_21626317 = header.getOrDefault("X-Amz-Date")
  valid_21626317 = validateParameter(valid_21626317, JString, required = false,
                                   default = nil)
  if valid_21626317 != nil:
    section.add "X-Amz-Date", valid_21626317
  var valid_21626318 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626318 = validateParameter(valid_21626318, JString, required = false,
                                   default = nil)
  if valid_21626318 != nil:
    section.add "X-Amz-Security-Token", valid_21626318
  var valid_21626319 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626319 = validateParameter(valid_21626319, JString, required = false,
                                   default = nil)
  if valid_21626319 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626319
  var valid_21626320 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626320 = validateParameter(valid_21626320, JString, required = false,
                                   default = nil)
  if valid_21626320 != nil:
    section.add "X-Amz-Algorithm", valid_21626320
  var valid_21626321 = header.getOrDefault("X-Amz-Signature")
  valid_21626321 = validateParameter(valid_21626321, JString, required = false,
                                   default = nil)
  if valid_21626321 != nil:
    section.add "X-Amz-Signature", valid_21626321
  var valid_21626322 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626322 = validateParameter(valid_21626322, JString, required = false,
                                   default = nil)
  if valid_21626322 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626322
  var valid_21626323 = header.getOrDefault("X-Amz-Credential")
  valid_21626323 = validateParameter(valid_21626323, JString, required = false,
                                   default = nil)
  if valid_21626323 != nil:
    section.add "X-Amz-Credential", valid_21626323
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

proc call*(call_21626325: Call_UpdateInput_21626313; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an input.
  ## 
  let valid = call_21626325.validator(path, query, header, formData, body, _)
  let scheme = call_21626325.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626325.makeUrl(scheme.get, call_21626325.host, call_21626325.base,
                               call_21626325.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626325, uri, valid, _)

proc call*(call_21626326: Call_UpdateInput_21626313; inputId: string; body: JsonNode): Recallable =
  ## updateInput
  ## Updates an input.
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_21626327 = newJObject()
  var body_21626328 = newJObject()
  add(path_21626327, "inputId", newJString(inputId))
  if body != nil:
    body_21626328 = body
  result = call_21626326.call(path_21626327, nil, nil, nil, body_21626328)

var updateInput* = Call_UpdateInput_21626313(name: "updateInput",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/inputs/{inputId}", validator: validate_UpdateInput_21626314,
    base: "/", makeUrl: url_UpdateInput_21626315,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInput_21626299 = ref object of OpenApiRestCall_21625435
proc url_DescribeInput_21626301(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputId" in path, "`inputId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputs/"),
               (kind: VariableSegment, value: "inputId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeInput_21626300(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Produces details about an input
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputId: JString (required)
  ##          : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputId` field"
  var valid_21626302 = path.getOrDefault("inputId")
  valid_21626302 = validateParameter(valid_21626302, JString, required = true,
                                   default = nil)
  if valid_21626302 != nil:
    section.add "inputId", valid_21626302
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
  var valid_21626303 = header.getOrDefault("X-Amz-Date")
  valid_21626303 = validateParameter(valid_21626303, JString, required = false,
                                   default = nil)
  if valid_21626303 != nil:
    section.add "X-Amz-Date", valid_21626303
  var valid_21626304 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626304 = validateParameter(valid_21626304, JString, required = false,
                                   default = nil)
  if valid_21626304 != nil:
    section.add "X-Amz-Security-Token", valid_21626304
  var valid_21626305 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626305 = validateParameter(valid_21626305, JString, required = false,
                                   default = nil)
  if valid_21626305 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626305
  var valid_21626306 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626306 = validateParameter(valid_21626306, JString, required = false,
                                   default = nil)
  if valid_21626306 != nil:
    section.add "X-Amz-Algorithm", valid_21626306
  var valid_21626307 = header.getOrDefault("X-Amz-Signature")
  valid_21626307 = validateParameter(valid_21626307, JString, required = false,
                                   default = nil)
  if valid_21626307 != nil:
    section.add "X-Amz-Signature", valid_21626307
  var valid_21626308 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626308 = validateParameter(valid_21626308, JString, required = false,
                                   default = nil)
  if valid_21626308 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626308
  var valid_21626309 = header.getOrDefault("X-Amz-Credential")
  valid_21626309 = validateParameter(valid_21626309, JString, required = false,
                                   default = nil)
  if valid_21626309 != nil:
    section.add "X-Amz-Credential", valid_21626309
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626310: Call_DescribeInput_21626299; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Produces details about an input
  ## 
  let valid = call_21626310.validator(path, query, header, formData, body, _)
  let scheme = call_21626310.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626310.makeUrl(scheme.get, call_21626310.host, call_21626310.base,
                               call_21626310.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626310, uri, valid, _)

proc call*(call_21626311: Call_DescribeInput_21626299; inputId: string): Recallable =
  ## describeInput
  ## Produces details about an input
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_21626312 = newJObject()
  add(path_21626312, "inputId", newJString(inputId))
  result = call_21626311.call(path_21626312, nil, nil, nil, nil)

var describeInput* = Call_DescribeInput_21626299(name: "describeInput",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/inputs/{inputId}", validator: validate_DescribeInput_21626300,
    base: "/", makeUrl: url_DescribeInput_21626301,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInput_21626329 = ref object of OpenApiRestCall_21625435
proc url_DeleteInput_21626331(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputId" in path, "`inputId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputs/"),
               (kind: VariableSegment, value: "inputId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteInput_21626330(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes the input end point
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputId: JString (required)
  ##          : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputId` field"
  var valid_21626332 = path.getOrDefault("inputId")
  valid_21626332 = validateParameter(valid_21626332, JString, required = true,
                                   default = nil)
  if valid_21626332 != nil:
    section.add "inputId", valid_21626332
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
  var valid_21626333 = header.getOrDefault("X-Amz-Date")
  valid_21626333 = validateParameter(valid_21626333, JString, required = false,
                                   default = nil)
  if valid_21626333 != nil:
    section.add "X-Amz-Date", valid_21626333
  var valid_21626334 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626334 = validateParameter(valid_21626334, JString, required = false,
                                   default = nil)
  if valid_21626334 != nil:
    section.add "X-Amz-Security-Token", valid_21626334
  var valid_21626335 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626335 = validateParameter(valid_21626335, JString, required = false,
                                   default = nil)
  if valid_21626335 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626335
  var valid_21626336 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626336 = validateParameter(valid_21626336, JString, required = false,
                                   default = nil)
  if valid_21626336 != nil:
    section.add "X-Amz-Algorithm", valid_21626336
  var valid_21626337 = header.getOrDefault("X-Amz-Signature")
  valid_21626337 = validateParameter(valid_21626337, JString, required = false,
                                   default = nil)
  if valid_21626337 != nil:
    section.add "X-Amz-Signature", valid_21626337
  var valid_21626338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626338 = validateParameter(valid_21626338, JString, required = false,
                                   default = nil)
  if valid_21626338 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626338
  var valid_21626339 = header.getOrDefault("X-Amz-Credential")
  valid_21626339 = validateParameter(valid_21626339, JString, required = false,
                                   default = nil)
  if valid_21626339 != nil:
    section.add "X-Amz-Credential", valid_21626339
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626340: Call_DeleteInput_21626329; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes the input end point
  ## 
  let valid = call_21626340.validator(path, query, header, formData, body, _)
  let scheme = call_21626340.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626340.makeUrl(scheme.get, call_21626340.host, call_21626340.base,
                               call_21626340.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626340, uri, valid, _)

proc call*(call_21626341: Call_DeleteInput_21626329; inputId: string): Recallable =
  ## deleteInput
  ## Deletes the input end point
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_21626342 = newJObject()
  add(path_21626342, "inputId", newJString(inputId))
  result = call_21626341.call(path_21626342, nil, nil, nil, nil)

var deleteInput* = Call_DeleteInput_21626329(name: "deleteInput",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/inputs/{inputId}", validator: validate_DeleteInput_21626330,
    base: "/", makeUrl: url_DeleteInput_21626331,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInputSecurityGroup_21626357 = ref object of OpenApiRestCall_21625435
proc url_UpdateInputSecurityGroup_21626359(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputSecurityGroupId" in path,
        "`inputSecurityGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputSecurityGroups/"),
               (kind: VariableSegment, value: "inputSecurityGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateInputSecurityGroup_21626358(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Update an Input Security Group's Whilelists.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputSecurityGroupId: JString (required)
  ##                       : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputSecurityGroupId` field"
  var valid_21626360 = path.getOrDefault("inputSecurityGroupId")
  valid_21626360 = validateParameter(valid_21626360, JString, required = true,
                                   default = nil)
  if valid_21626360 != nil:
    section.add "inputSecurityGroupId", valid_21626360
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
  var valid_21626361 = header.getOrDefault("X-Amz-Date")
  valid_21626361 = validateParameter(valid_21626361, JString, required = false,
                                   default = nil)
  if valid_21626361 != nil:
    section.add "X-Amz-Date", valid_21626361
  var valid_21626362 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626362 = validateParameter(valid_21626362, JString, required = false,
                                   default = nil)
  if valid_21626362 != nil:
    section.add "X-Amz-Security-Token", valid_21626362
  var valid_21626363 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626363 = validateParameter(valid_21626363, JString, required = false,
                                   default = nil)
  if valid_21626363 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626363
  var valid_21626364 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626364 = validateParameter(valid_21626364, JString, required = false,
                                   default = nil)
  if valid_21626364 != nil:
    section.add "X-Amz-Algorithm", valid_21626364
  var valid_21626365 = header.getOrDefault("X-Amz-Signature")
  valid_21626365 = validateParameter(valid_21626365, JString, required = false,
                                   default = nil)
  if valid_21626365 != nil:
    section.add "X-Amz-Signature", valid_21626365
  var valid_21626366 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626366 = validateParameter(valid_21626366, JString, required = false,
                                   default = nil)
  if valid_21626366 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626366
  var valid_21626367 = header.getOrDefault("X-Amz-Credential")
  valid_21626367 = validateParameter(valid_21626367, JString, required = false,
                                   default = nil)
  if valid_21626367 != nil:
    section.add "X-Amz-Credential", valid_21626367
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

proc call*(call_21626369: Call_UpdateInputSecurityGroup_21626357;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update an Input Security Group's Whilelists.
  ## 
  let valid = call_21626369.validator(path, query, header, formData, body, _)
  let scheme = call_21626369.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626369.makeUrl(scheme.get, call_21626369.host, call_21626369.base,
                               call_21626369.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626369, uri, valid, _)

proc call*(call_21626370: Call_UpdateInputSecurityGroup_21626357;
          inputSecurityGroupId: string; body: JsonNode): Recallable =
  ## updateInputSecurityGroup
  ## Update an Input Security Group's Whilelists.
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_21626371 = newJObject()
  var body_21626372 = newJObject()
  add(path_21626371, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  if body != nil:
    body_21626372 = body
  result = call_21626370.call(path_21626371, nil, nil, nil, body_21626372)

var updateInputSecurityGroup* = Call_UpdateInputSecurityGroup_21626357(
    name: "updateInputSecurityGroup", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_UpdateInputSecurityGroup_21626358, base: "/",
    makeUrl: url_UpdateInputSecurityGroup_21626359,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInputSecurityGroup_21626343 = ref object of OpenApiRestCall_21625435
proc url_DescribeInputSecurityGroup_21626345(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputSecurityGroupId" in path,
        "`inputSecurityGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputSecurityGroups/"),
               (kind: VariableSegment, value: "inputSecurityGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeInputSecurityGroup_21626344(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Produces a summary of an Input Security Group
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputSecurityGroupId: JString (required)
  ##                       : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputSecurityGroupId` field"
  var valid_21626346 = path.getOrDefault("inputSecurityGroupId")
  valid_21626346 = validateParameter(valid_21626346, JString, required = true,
                                   default = nil)
  if valid_21626346 != nil:
    section.add "inputSecurityGroupId", valid_21626346
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
  var valid_21626347 = header.getOrDefault("X-Amz-Date")
  valid_21626347 = validateParameter(valid_21626347, JString, required = false,
                                   default = nil)
  if valid_21626347 != nil:
    section.add "X-Amz-Date", valid_21626347
  var valid_21626348 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626348 = validateParameter(valid_21626348, JString, required = false,
                                   default = nil)
  if valid_21626348 != nil:
    section.add "X-Amz-Security-Token", valid_21626348
  var valid_21626349 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626349 = validateParameter(valid_21626349, JString, required = false,
                                   default = nil)
  if valid_21626349 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626349
  var valid_21626350 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626350 = validateParameter(valid_21626350, JString, required = false,
                                   default = nil)
  if valid_21626350 != nil:
    section.add "X-Amz-Algorithm", valid_21626350
  var valid_21626351 = header.getOrDefault("X-Amz-Signature")
  valid_21626351 = validateParameter(valid_21626351, JString, required = false,
                                   default = nil)
  if valid_21626351 != nil:
    section.add "X-Amz-Signature", valid_21626351
  var valid_21626352 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626352 = validateParameter(valid_21626352, JString, required = false,
                                   default = nil)
  if valid_21626352 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626352
  var valid_21626353 = header.getOrDefault("X-Amz-Credential")
  valid_21626353 = validateParameter(valid_21626353, JString, required = false,
                                   default = nil)
  if valid_21626353 != nil:
    section.add "X-Amz-Credential", valid_21626353
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626354: Call_DescribeInputSecurityGroup_21626343;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Produces a summary of an Input Security Group
  ## 
  let valid = call_21626354.validator(path, query, header, formData, body, _)
  let scheme = call_21626354.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626354.makeUrl(scheme.get, call_21626354.host, call_21626354.base,
                               call_21626354.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626354, uri, valid, _)

proc call*(call_21626355: Call_DescribeInputSecurityGroup_21626343;
          inputSecurityGroupId: string): Recallable =
  ## describeInputSecurityGroup
  ## Produces a summary of an Input Security Group
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  var path_21626356 = newJObject()
  add(path_21626356, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  result = call_21626355.call(path_21626356, nil, nil, nil, nil)

var describeInputSecurityGroup* = Call_DescribeInputSecurityGroup_21626343(
    name: "describeInputSecurityGroup", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_DescribeInputSecurityGroup_21626344, base: "/",
    makeUrl: url_DescribeInputSecurityGroup_21626345,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInputSecurityGroup_21626373 = ref object of OpenApiRestCall_21625435
proc url_DeleteInputSecurityGroup_21626375(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "inputSecurityGroupId" in path,
        "`inputSecurityGroupId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/inputSecurityGroups/"),
               (kind: VariableSegment, value: "inputSecurityGroupId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteInputSecurityGroup_21626374(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an Input Security Group
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputSecurityGroupId: JString (required)
  ##                       : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputSecurityGroupId` field"
  var valid_21626376 = path.getOrDefault("inputSecurityGroupId")
  valid_21626376 = validateParameter(valid_21626376, JString, required = true,
                                   default = nil)
  if valid_21626376 != nil:
    section.add "inputSecurityGroupId", valid_21626376
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
  var valid_21626377 = header.getOrDefault("X-Amz-Date")
  valid_21626377 = validateParameter(valid_21626377, JString, required = false,
                                   default = nil)
  if valid_21626377 != nil:
    section.add "X-Amz-Date", valid_21626377
  var valid_21626378 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626378 = validateParameter(valid_21626378, JString, required = false,
                                   default = nil)
  if valid_21626378 != nil:
    section.add "X-Amz-Security-Token", valid_21626378
  var valid_21626379 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626379 = validateParameter(valid_21626379, JString, required = false,
                                   default = nil)
  if valid_21626379 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626379
  var valid_21626380 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626380 = validateParameter(valid_21626380, JString, required = false,
                                   default = nil)
  if valid_21626380 != nil:
    section.add "X-Amz-Algorithm", valid_21626380
  var valid_21626381 = header.getOrDefault("X-Amz-Signature")
  valid_21626381 = validateParameter(valid_21626381, JString, required = false,
                                   default = nil)
  if valid_21626381 != nil:
    section.add "X-Amz-Signature", valid_21626381
  var valid_21626382 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626382 = validateParameter(valid_21626382, JString, required = false,
                                   default = nil)
  if valid_21626382 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626382
  var valid_21626383 = header.getOrDefault("X-Amz-Credential")
  valid_21626383 = validateParameter(valid_21626383, JString, required = false,
                                   default = nil)
  if valid_21626383 != nil:
    section.add "X-Amz-Credential", valid_21626383
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626384: Call_DeleteInputSecurityGroup_21626373;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an Input Security Group
  ## 
  let valid = call_21626384.validator(path, query, header, formData, body, _)
  let scheme = call_21626384.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626384.makeUrl(scheme.get, call_21626384.host, call_21626384.base,
                               call_21626384.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626384, uri, valid, _)

proc call*(call_21626385: Call_DeleteInputSecurityGroup_21626373;
          inputSecurityGroupId: string): Recallable =
  ## deleteInputSecurityGroup
  ## Deletes an Input Security Group
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  var path_21626386 = newJObject()
  add(path_21626386, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  result = call_21626385.call(path_21626386, nil, nil, nil, nil)

var deleteInputSecurityGroup* = Call_DeleteInputSecurityGroup_21626373(
    name: "deleteInputSecurityGroup", meth: HttpMethod.HttpDelete,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_DeleteInputSecurityGroup_21626374, base: "/",
    makeUrl: url_DeleteInputSecurityGroup_21626375,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMultiplex_21626401 = ref object of OpenApiRestCall_21625435
proc url_UpdateMultiplex_21626403(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
               (kind: VariableSegment, value: "multiplexId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMultiplex_21626402(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates a multiplex.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
  ##              : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `multiplexId` field"
  var valid_21626404 = path.getOrDefault("multiplexId")
  valid_21626404 = validateParameter(valid_21626404, JString, required = true,
                                   default = nil)
  if valid_21626404 != nil:
    section.add "multiplexId", valid_21626404
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
  var valid_21626405 = header.getOrDefault("X-Amz-Date")
  valid_21626405 = validateParameter(valid_21626405, JString, required = false,
                                   default = nil)
  if valid_21626405 != nil:
    section.add "X-Amz-Date", valid_21626405
  var valid_21626406 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626406 = validateParameter(valid_21626406, JString, required = false,
                                   default = nil)
  if valid_21626406 != nil:
    section.add "X-Amz-Security-Token", valid_21626406
  var valid_21626407 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626407 = validateParameter(valid_21626407, JString, required = false,
                                   default = nil)
  if valid_21626407 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626407
  var valid_21626408 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626408 = validateParameter(valid_21626408, JString, required = false,
                                   default = nil)
  if valid_21626408 != nil:
    section.add "X-Amz-Algorithm", valid_21626408
  var valid_21626409 = header.getOrDefault("X-Amz-Signature")
  valid_21626409 = validateParameter(valid_21626409, JString, required = false,
                                   default = nil)
  if valid_21626409 != nil:
    section.add "X-Amz-Signature", valid_21626409
  var valid_21626410 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626410 = validateParameter(valid_21626410, JString, required = false,
                                   default = nil)
  if valid_21626410 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626410
  var valid_21626411 = header.getOrDefault("X-Amz-Credential")
  valid_21626411 = validateParameter(valid_21626411, JString, required = false,
                                   default = nil)
  if valid_21626411 != nil:
    section.add "X-Amz-Credential", valid_21626411
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

proc call*(call_21626413: Call_UpdateMultiplex_21626401; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates a multiplex.
  ## 
  let valid = call_21626413.validator(path, query, header, formData, body, _)
  let scheme = call_21626413.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626413.makeUrl(scheme.get, call_21626413.host, call_21626413.base,
                               call_21626413.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626413, uri, valid, _)

proc call*(call_21626414: Call_UpdateMultiplex_21626401; multiplexId: string;
          body: JsonNode): Recallable =
  ## updateMultiplex
  ## Updates a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_21626415 = newJObject()
  var body_21626416 = newJObject()
  add(path_21626415, "multiplexId", newJString(multiplexId))
  if body != nil:
    body_21626416 = body
  result = call_21626414.call(path_21626415, nil, nil, nil, body_21626416)

var updateMultiplex* = Call_UpdateMultiplex_21626401(name: "updateMultiplex",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}", validator: validate_UpdateMultiplex_21626402,
    base: "/", makeUrl: url_UpdateMultiplex_21626403,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMultiplex_21626387 = ref object of OpenApiRestCall_21625435
proc url_DescribeMultiplex_21626389(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
               (kind: VariableSegment, value: "multiplexId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeMultiplex_21626388(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets details about a multiplex.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
  ##              : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `multiplexId` field"
  var valid_21626390 = path.getOrDefault("multiplexId")
  valid_21626390 = validateParameter(valid_21626390, JString, required = true,
                                   default = nil)
  if valid_21626390 != nil:
    section.add "multiplexId", valid_21626390
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
  var valid_21626391 = header.getOrDefault("X-Amz-Date")
  valid_21626391 = validateParameter(valid_21626391, JString, required = false,
                                   default = nil)
  if valid_21626391 != nil:
    section.add "X-Amz-Date", valid_21626391
  var valid_21626392 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626392 = validateParameter(valid_21626392, JString, required = false,
                                   default = nil)
  if valid_21626392 != nil:
    section.add "X-Amz-Security-Token", valid_21626392
  var valid_21626393 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626393 = validateParameter(valid_21626393, JString, required = false,
                                   default = nil)
  if valid_21626393 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626393
  var valid_21626394 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626394 = validateParameter(valid_21626394, JString, required = false,
                                   default = nil)
  if valid_21626394 != nil:
    section.add "X-Amz-Algorithm", valid_21626394
  var valid_21626395 = header.getOrDefault("X-Amz-Signature")
  valid_21626395 = validateParameter(valid_21626395, JString, required = false,
                                   default = nil)
  if valid_21626395 != nil:
    section.add "X-Amz-Signature", valid_21626395
  var valid_21626396 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626396 = validateParameter(valid_21626396, JString, required = false,
                                   default = nil)
  if valid_21626396 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626396
  var valid_21626397 = header.getOrDefault("X-Amz-Credential")
  valid_21626397 = validateParameter(valid_21626397, JString, required = false,
                                   default = nil)
  if valid_21626397 != nil:
    section.add "X-Amz-Credential", valid_21626397
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626398: Call_DescribeMultiplex_21626387; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details about a multiplex.
  ## 
  let valid = call_21626398.validator(path, query, header, formData, body, _)
  let scheme = call_21626398.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626398.makeUrl(scheme.get, call_21626398.host, call_21626398.base,
                               call_21626398.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626398, uri, valid, _)

proc call*(call_21626399: Call_DescribeMultiplex_21626387; multiplexId: string): Recallable =
  ## describeMultiplex
  ## Gets details about a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_21626400 = newJObject()
  add(path_21626400, "multiplexId", newJString(multiplexId))
  result = call_21626399.call(path_21626400, nil, nil, nil, nil)

var describeMultiplex* = Call_DescribeMultiplex_21626387(name: "describeMultiplex",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}",
    validator: validate_DescribeMultiplex_21626388, base: "/",
    makeUrl: url_DescribeMultiplex_21626389, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMultiplex_21626417 = ref object of OpenApiRestCall_21625435
proc url_DeleteMultiplex_21626419(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
               (kind: VariableSegment, value: "multiplexId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMultiplex_21626418(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete a multiplex. The multiplex must be idle.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
  ##              : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `multiplexId` field"
  var valid_21626420 = path.getOrDefault("multiplexId")
  valid_21626420 = validateParameter(valid_21626420, JString, required = true,
                                   default = nil)
  if valid_21626420 != nil:
    section.add "multiplexId", valid_21626420
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
  var valid_21626421 = header.getOrDefault("X-Amz-Date")
  valid_21626421 = validateParameter(valid_21626421, JString, required = false,
                                   default = nil)
  if valid_21626421 != nil:
    section.add "X-Amz-Date", valid_21626421
  var valid_21626422 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626422 = validateParameter(valid_21626422, JString, required = false,
                                   default = nil)
  if valid_21626422 != nil:
    section.add "X-Amz-Security-Token", valid_21626422
  var valid_21626423 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626423 = validateParameter(valid_21626423, JString, required = false,
                                   default = nil)
  if valid_21626423 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626423
  var valid_21626424 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626424 = validateParameter(valid_21626424, JString, required = false,
                                   default = nil)
  if valid_21626424 != nil:
    section.add "X-Amz-Algorithm", valid_21626424
  var valid_21626425 = header.getOrDefault("X-Amz-Signature")
  valid_21626425 = validateParameter(valid_21626425, JString, required = false,
                                   default = nil)
  if valid_21626425 != nil:
    section.add "X-Amz-Signature", valid_21626425
  var valid_21626426 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626426 = validateParameter(valid_21626426, JString, required = false,
                                   default = nil)
  if valid_21626426 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626426
  var valid_21626427 = header.getOrDefault("X-Amz-Credential")
  valid_21626427 = validateParameter(valid_21626427, JString, required = false,
                                   default = nil)
  if valid_21626427 != nil:
    section.add "X-Amz-Credential", valid_21626427
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626428: Call_DeleteMultiplex_21626417; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a multiplex. The multiplex must be idle.
  ## 
  let valid = call_21626428.validator(path, query, header, formData, body, _)
  let scheme = call_21626428.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626428.makeUrl(scheme.get, call_21626428.host, call_21626428.base,
                               call_21626428.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626428, uri, valid, _)

proc call*(call_21626429: Call_DeleteMultiplex_21626417; multiplexId: string): Recallable =
  ## deleteMultiplex
  ## Delete a multiplex. The multiplex must be idle.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_21626430 = newJObject()
  add(path_21626430, "multiplexId", newJString(multiplexId))
  result = call_21626429.call(path_21626430, nil, nil, nil, nil)

var deleteMultiplex* = Call_DeleteMultiplex_21626417(name: "deleteMultiplex",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}", validator: validate_DeleteMultiplex_21626418,
    base: "/", makeUrl: url_DeleteMultiplex_21626419,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMultiplexProgram_21626446 = ref object of OpenApiRestCall_21625435
proc url_UpdateMultiplexProgram_21626448(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  assert "programName" in path, "`programName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
               (kind: VariableSegment, value: "multiplexId"),
               (kind: ConstantSegment, value: "/programs/"),
               (kind: VariableSegment, value: "programName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMultiplexProgram_21626447(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Update a program in a multiplex.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
  ##              : Placeholder documentation for __string
  ##   programName: JString (required)
  ##              : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `multiplexId` field"
  var valid_21626449 = path.getOrDefault("multiplexId")
  valid_21626449 = validateParameter(valid_21626449, JString, required = true,
                                   default = nil)
  if valid_21626449 != nil:
    section.add "multiplexId", valid_21626449
  var valid_21626450 = path.getOrDefault("programName")
  valid_21626450 = validateParameter(valid_21626450, JString, required = true,
                                   default = nil)
  if valid_21626450 != nil:
    section.add "programName", valid_21626450
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
  var valid_21626451 = header.getOrDefault("X-Amz-Date")
  valid_21626451 = validateParameter(valid_21626451, JString, required = false,
                                   default = nil)
  if valid_21626451 != nil:
    section.add "X-Amz-Date", valid_21626451
  var valid_21626452 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626452 = validateParameter(valid_21626452, JString, required = false,
                                   default = nil)
  if valid_21626452 != nil:
    section.add "X-Amz-Security-Token", valid_21626452
  var valid_21626453 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626453 = validateParameter(valid_21626453, JString, required = false,
                                   default = nil)
  if valid_21626453 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626453
  var valid_21626454 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626454 = validateParameter(valid_21626454, JString, required = false,
                                   default = nil)
  if valid_21626454 != nil:
    section.add "X-Amz-Algorithm", valid_21626454
  var valid_21626455 = header.getOrDefault("X-Amz-Signature")
  valid_21626455 = validateParameter(valid_21626455, JString, required = false,
                                   default = nil)
  if valid_21626455 != nil:
    section.add "X-Amz-Signature", valid_21626455
  var valid_21626456 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626456 = validateParameter(valid_21626456, JString, required = false,
                                   default = nil)
  if valid_21626456 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626456
  var valid_21626457 = header.getOrDefault("X-Amz-Credential")
  valid_21626457 = validateParameter(valid_21626457, JString, required = false,
                                   default = nil)
  if valid_21626457 != nil:
    section.add "X-Amz-Credential", valid_21626457
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

proc call*(call_21626459: Call_UpdateMultiplexProgram_21626446;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Update a program in a multiplex.
  ## 
  let valid = call_21626459.validator(path, query, header, formData, body, _)
  let scheme = call_21626459.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626459.makeUrl(scheme.get, call_21626459.host, call_21626459.base,
                               call_21626459.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626459, uri, valid, _)

proc call*(call_21626460: Call_UpdateMultiplexProgram_21626446;
          multiplexId: string; programName: string; body: JsonNode): Recallable =
  ## updateMultiplexProgram
  ## Update a program in a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   programName: string (required)
  ##              : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_21626461 = newJObject()
  var body_21626462 = newJObject()
  add(path_21626461, "multiplexId", newJString(multiplexId))
  add(path_21626461, "programName", newJString(programName))
  if body != nil:
    body_21626462 = body
  result = call_21626460.call(path_21626461, nil, nil, nil, body_21626462)

var updateMultiplexProgram* = Call_UpdateMultiplexProgram_21626446(
    name: "updateMultiplexProgram", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs/{programName}",
    validator: validate_UpdateMultiplexProgram_21626447, base: "/",
    makeUrl: url_UpdateMultiplexProgram_21626448,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMultiplexProgram_21626431 = ref object of OpenApiRestCall_21625435
proc url_DescribeMultiplexProgram_21626433(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  assert "programName" in path, "`programName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
               (kind: VariableSegment, value: "multiplexId"),
               (kind: ConstantSegment, value: "/programs/"),
               (kind: VariableSegment, value: "programName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeMultiplexProgram_21626432(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get the details for a program in a multiplex.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
  ##              : Placeholder documentation for __string
  ##   programName: JString (required)
  ##              : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `multiplexId` field"
  var valid_21626434 = path.getOrDefault("multiplexId")
  valid_21626434 = validateParameter(valid_21626434, JString, required = true,
                                   default = nil)
  if valid_21626434 != nil:
    section.add "multiplexId", valid_21626434
  var valid_21626435 = path.getOrDefault("programName")
  valid_21626435 = validateParameter(valid_21626435, JString, required = true,
                                   default = nil)
  if valid_21626435 != nil:
    section.add "programName", valid_21626435
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
  var valid_21626436 = header.getOrDefault("X-Amz-Date")
  valid_21626436 = validateParameter(valid_21626436, JString, required = false,
                                   default = nil)
  if valid_21626436 != nil:
    section.add "X-Amz-Date", valid_21626436
  var valid_21626437 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626437 = validateParameter(valid_21626437, JString, required = false,
                                   default = nil)
  if valid_21626437 != nil:
    section.add "X-Amz-Security-Token", valid_21626437
  var valid_21626438 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626438 = validateParameter(valid_21626438, JString, required = false,
                                   default = nil)
  if valid_21626438 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626438
  var valid_21626439 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626439 = validateParameter(valid_21626439, JString, required = false,
                                   default = nil)
  if valid_21626439 != nil:
    section.add "X-Amz-Algorithm", valid_21626439
  var valid_21626440 = header.getOrDefault("X-Amz-Signature")
  valid_21626440 = validateParameter(valid_21626440, JString, required = false,
                                   default = nil)
  if valid_21626440 != nil:
    section.add "X-Amz-Signature", valid_21626440
  var valid_21626441 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626441 = validateParameter(valid_21626441, JString, required = false,
                                   default = nil)
  if valid_21626441 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626441
  var valid_21626442 = header.getOrDefault("X-Amz-Credential")
  valid_21626442 = validateParameter(valid_21626442, JString, required = false,
                                   default = nil)
  if valid_21626442 != nil:
    section.add "X-Amz-Credential", valid_21626442
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626443: Call_DescribeMultiplexProgram_21626431;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Get the details for a program in a multiplex.
  ## 
  let valid = call_21626443.validator(path, query, header, formData, body, _)
  let scheme = call_21626443.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626443.makeUrl(scheme.get, call_21626443.host, call_21626443.base,
                               call_21626443.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626443, uri, valid, _)

proc call*(call_21626444: Call_DescribeMultiplexProgram_21626431;
          multiplexId: string; programName: string): Recallable =
  ## describeMultiplexProgram
  ## Get the details for a program in a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   programName: string (required)
  ##              : Placeholder documentation for __string
  var path_21626445 = newJObject()
  add(path_21626445, "multiplexId", newJString(multiplexId))
  add(path_21626445, "programName", newJString(programName))
  result = call_21626444.call(path_21626445, nil, nil, nil, nil)

var describeMultiplexProgram* = Call_DescribeMultiplexProgram_21626431(
    name: "describeMultiplexProgram", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs/{programName}",
    validator: validate_DescribeMultiplexProgram_21626432, base: "/",
    makeUrl: url_DescribeMultiplexProgram_21626433,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMultiplexProgram_21626463 = ref object of OpenApiRestCall_21625435
proc url_DeleteMultiplexProgram_21626465(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  assert "programName" in path, "`programName` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
               (kind: VariableSegment, value: "multiplexId"),
               (kind: ConstantSegment, value: "/programs/"),
               (kind: VariableSegment, value: "programName")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMultiplexProgram_21626464(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete a program from a multiplex.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
  ##              : Placeholder documentation for __string
  ##   programName: JString (required)
  ##              : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `multiplexId` field"
  var valid_21626466 = path.getOrDefault("multiplexId")
  valid_21626466 = validateParameter(valid_21626466, JString, required = true,
                                   default = nil)
  if valid_21626466 != nil:
    section.add "multiplexId", valid_21626466
  var valid_21626467 = path.getOrDefault("programName")
  valid_21626467 = validateParameter(valid_21626467, JString, required = true,
                                   default = nil)
  if valid_21626467 != nil:
    section.add "programName", valid_21626467
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
  var valid_21626468 = header.getOrDefault("X-Amz-Date")
  valid_21626468 = validateParameter(valid_21626468, JString, required = false,
                                   default = nil)
  if valid_21626468 != nil:
    section.add "X-Amz-Date", valid_21626468
  var valid_21626469 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626469 = validateParameter(valid_21626469, JString, required = false,
                                   default = nil)
  if valid_21626469 != nil:
    section.add "X-Amz-Security-Token", valid_21626469
  var valid_21626470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626470 = validateParameter(valid_21626470, JString, required = false,
                                   default = nil)
  if valid_21626470 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626470
  var valid_21626471 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626471 = validateParameter(valid_21626471, JString, required = false,
                                   default = nil)
  if valid_21626471 != nil:
    section.add "X-Amz-Algorithm", valid_21626471
  var valid_21626472 = header.getOrDefault("X-Amz-Signature")
  valid_21626472 = validateParameter(valid_21626472, JString, required = false,
                                   default = nil)
  if valid_21626472 != nil:
    section.add "X-Amz-Signature", valid_21626472
  var valid_21626473 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626473 = validateParameter(valid_21626473, JString, required = false,
                                   default = nil)
  if valid_21626473 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626473
  var valid_21626474 = header.getOrDefault("X-Amz-Credential")
  valid_21626474 = validateParameter(valid_21626474, JString, required = false,
                                   default = nil)
  if valid_21626474 != nil:
    section.add "X-Amz-Credential", valid_21626474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626475: Call_DeleteMultiplexProgram_21626463;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete a program from a multiplex.
  ## 
  let valid = call_21626475.validator(path, query, header, formData, body, _)
  let scheme = call_21626475.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626475.makeUrl(scheme.get, call_21626475.host, call_21626475.base,
                               call_21626475.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626475, uri, valid, _)

proc call*(call_21626476: Call_DeleteMultiplexProgram_21626463;
          multiplexId: string; programName: string): Recallable =
  ## deleteMultiplexProgram
  ## Delete a program from a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   programName: string (required)
  ##              : Placeholder documentation for __string
  var path_21626477 = newJObject()
  add(path_21626477, "multiplexId", newJString(multiplexId))
  add(path_21626477, "programName", newJString(programName))
  result = call_21626476.call(path_21626477, nil, nil, nil, nil)

var deleteMultiplexProgram* = Call_DeleteMultiplexProgram_21626463(
    name: "deleteMultiplexProgram", meth: HttpMethod.HttpDelete,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs/{programName}",
    validator: validate_DeleteMultiplexProgram_21626464, base: "/",
    makeUrl: url_DeleteMultiplexProgram_21626465,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReservation_21626492 = ref object of OpenApiRestCall_21625435
proc url_UpdateReservation_21626494(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "reservationId" in path, "`reservationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/reservations/"),
               (kind: VariableSegment, value: "reservationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateReservation_21626493(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Update reservation.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   reservationId: JString (required)
  ##                : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `reservationId` field"
  var valid_21626495 = path.getOrDefault("reservationId")
  valid_21626495 = validateParameter(valid_21626495, JString, required = true,
                                   default = nil)
  if valid_21626495 != nil:
    section.add "reservationId", valid_21626495
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
  var valid_21626496 = header.getOrDefault("X-Amz-Date")
  valid_21626496 = validateParameter(valid_21626496, JString, required = false,
                                   default = nil)
  if valid_21626496 != nil:
    section.add "X-Amz-Date", valid_21626496
  var valid_21626497 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626497 = validateParameter(valid_21626497, JString, required = false,
                                   default = nil)
  if valid_21626497 != nil:
    section.add "X-Amz-Security-Token", valid_21626497
  var valid_21626498 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626498 = validateParameter(valid_21626498, JString, required = false,
                                   default = nil)
  if valid_21626498 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626498
  var valid_21626499 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626499 = validateParameter(valid_21626499, JString, required = false,
                                   default = nil)
  if valid_21626499 != nil:
    section.add "X-Amz-Algorithm", valid_21626499
  var valid_21626500 = header.getOrDefault("X-Amz-Signature")
  valid_21626500 = validateParameter(valid_21626500, JString, required = false,
                                   default = nil)
  if valid_21626500 != nil:
    section.add "X-Amz-Signature", valid_21626500
  var valid_21626501 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626501 = validateParameter(valid_21626501, JString, required = false,
                                   default = nil)
  if valid_21626501 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626501
  var valid_21626502 = header.getOrDefault("X-Amz-Credential")
  valid_21626502 = validateParameter(valid_21626502, JString, required = false,
                                   default = nil)
  if valid_21626502 != nil:
    section.add "X-Amz-Credential", valid_21626502
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

proc call*(call_21626504: Call_UpdateReservation_21626492; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Update reservation.
  ## 
  let valid = call_21626504.validator(path, query, header, formData, body, _)
  let scheme = call_21626504.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626504.makeUrl(scheme.get, call_21626504.host, call_21626504.base,
                               call_21626504.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626504, uri, valid, _)

proc call*(call_21626505: Call_UpdateReservation_21626492; reservationId: string;
          body: JsonNode): Recallable =
  ## updateReservation
  ## Update reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_21626506 = newJObject()
  var body_21626507 = newJObject()
  add(path_21626506, "reservationId", newJString(reservationId))
  if body != nil:
    body_21626507 = body
  result = call_21626505.call(path_21626506, nil, nil, nil, body_21626507)

var updateReservation* = Call_UpdateReservation_21626492(name: "updateReservation",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_UpdateReservation_21626493, base: "/",
    makeUrl: url_UpdateReservation_21626494, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservation_21626478 = ref object of OpenApiRestCall_21625435
proc url_DescribeReservation_21626480(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "reservationId" in path, "`reservationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/reservations/"),
               (kind: VariableSegment, value: "reservationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeReservation_21626479(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get details for a reservation.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   reservationId: JString (required)
  ##                : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `reservationId` field"
  var valid_21626481 = path.getOrDefault("reservationId")
  valid_21626481 = validateParameter(valid_21626481, JString, required = true,
                                   default = nil)
  if valid_21626481 != nil:
    section.add "reservationId", valid_21626481
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
  var valid_21626482 = header.getOrDefault("X-Amz-Date")
  valid_21626482 = validateParameter(valid_21626482, JString, required = false,
                                   default = nil)
  if valid_21626482 != nil:
    section.add "X-Amz-Date", valid_21626482
  var valid_21626483 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626483 = validateParameter(valid_21626483, JString, required = false,
                                   default = nil)
  if valid_21626483 != nil:
    section.add "X-Amz-Security-Token", valid_21626483
  var valid_21626484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626484 = validateParameter(valid_21626484, JString, required = false,
                                   default = nil)
  if valid_21626484 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626484
  var valid_21626485 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626485 = validateParameter(valid_21626485, JString, required = false,
                                   default = nil)
  if valid_21626485 != nil:
    section.add "X-Amz-Algorithm", valid_21626485
  var valid_21626486 = header.getOrDefault("X-Amz-Signature")
  valid_21626486 = validateParameter(valid_21626486, JString, required = false,
                                   default = nil)
  if valid_21626486 != nil:
    section.add "X-Amz-Signature", valid_21626486
  var valid_21626487 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626487 = validateParameter(valid_21626487, JString, required = false,
                                   default = nil)
  if valid_21626487 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626487
  var valid_21626488 = header.getOrDefault("X-Amz-Credential")
  valid_21626488 = validateParameter(valid_21626488, JString, required = false,
                                   default = nil)
  if valid_21626488 != nil:
    section.add "X-Amz-Credential", valid_21626488
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626489: Call_DescribeReservation_21626478; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Get details for a reservation.
  ## 
  let valid = call_21626489.validator(path, query, header, formData, body, _)
  let scheme = call_21626489.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626489.makeUrl(scheme.get, call_21626489.host, call_21626489.base,
                               call_21626489.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626489, uri, valid, _)

proc call*(call_21626490: Call_DescribeReservation_21626478; reservationId: string): Recallable =
  ## describeReservation
  ## Get details for a reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_21626491 = newJObject()
  add(path_21626491, "reservationId", newJString(reservationId))
  result = call_21626490.call(path_21626491, nil, nil, nil, nil)

var describeReservation* = Call_DescribeReservation_21626478(
    name: "describeReservation", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/reservations/{reservationId}",
    validator: validate_DescribeReservation_21626479, base: "/",
    makeUrl: url_DescribeReservation_21626480,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReservation_21626508 = ref object of OpenApiRestCall_21625435
proc url_DeleteReservation_21626510(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "reservationId" in path, "`reservationId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/reservations/"),
               (kind: VariableSegment, value: "reservationId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteReservation_21626509(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Delete an expired reservation.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   reservationId: JString (required)
  ##                : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `reservationId` field"
  var valid_21626511 = path.getOrDefault("reservationId")
  valid_21626511 = validateParameter(valid_21626511, JString, required = true,
                                   default = nil)
  if valid_21626511 != nil:
    section.add "reservationId", valid_21626511
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
  var valid_21626512 = header.getOrDefault("X-Amz-Date")
  valid_21626512 = validateParameter(valid_21626512, JString, required = false,
                                   default = nil)
  if valid_21626512 != nil:
    section.add "X-Amz-Date", valid_21626512
  var valid_21626513 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626513 = validateParameter(valid_21626513, JString, required = false,
                                   default = nil)
  if valid_21626513 != nil:
    section.add "X-Amz-Security-Token", valid_21626513
  var valid_21626514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626514 = validateParameter(valid_21626514, JString, required = false,
                                   default = nil)
  if valid_21626514 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626514
  var valid_21626515 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626515 = validateParameter(valid_21626515, JString, required = false,
                                   default = nil)
  if valid_21626515 != nil:
    section.add "X-Amz-Algorithm", valid_21626515
  var valid_21626516 = header.getOrDefault("X-Amz-Signature")
  valid_21626516 = validateParameter(valid_21626516, JString, required = false,
                                   default = nil)
  if valid_21626516 != nil:
    section.add "X-Amz-Signature", valid_21626516
  var valid_21626517 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626517 = validateParameter(valid_21626517, JString, required = false,
                                   default = nil)
  if valid_21626517 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626517
  var valid_21626518 = header.getOrDefault("X-Amz-Credential")
  valid_21626518 = validateParameter(valid_21626518, JString, required = false,
                                   default = nil)
  if valid_21626518 != nil:
    section.add "X-Amz-Credential", valid_21626518
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626519: Call_DeleteReservation_21626508; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Delete an expired reservation.
  ## 
  let valid = call_21626519.validator(path, query, header, formData, body, _)
  let scheme = call_21626519.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626519.makeUrl(scheme.get, call_21626519.host, call_21626519.base,
                               call_21626519.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626519, uri, valid, _)

proc call*(call_21626520: Call_DeleteReservation_21626508; reservationId: string): Recallable =
  ## deleteReservation
  ## Delete an expired reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_21626521 = newJObject()
  add(path_21626521, "reservationId", newJString(reservationId))
  result = call_21626520.call(path_21626521, nil, nil, nil, nil)

var deleteReservation* = Call_DeleteReservation_21626508(name: "deleteReservation",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_DeleteReservation_21626509, base: "/",
    makeUrl: url_DeleteReservation_21626510, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_21626522 = ref object of OpenApiRestCall_21625435
proc url_DeleteTags_21626524(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/tags/"),
               (kind: VariableSegment, value: "resource-arn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTags_21626523(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Removes tags for a resource
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  ##               : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21626525 = path.getOrDefault("resource-arn")
  valid_21626525 = validateParameter(valid_21626525, JString, required = true,
                                   default = nil)
  if valid_21626525 != nil:
    section.add "resource-arn", valid_21626525
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : Placeholder documentation for __listOf__string
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21626526 = query.getOrDefault("tagKeys")
  valid_21626526 = validateParameter(valid_21626526, JArray, required = true,
                                   default = nil)
  if valid_21626526 != nil:
    section.add "tagKeys", valid_21626526
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
  var valid_21626527 = header.getOrDefault("X-Amz-Date")
  valid_21626527 = validateParameter(valid_21626527, JString, required = false,
                                   default = nil)
  if valid_21626527 != nil:
    section.add "X-Amz-Date", valid_21626527
  var valid_21626528 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626528 = validateParameter(valid_21626528, JString, required = false,
                                   default = nil)
  if valid_21626528 != nil:
    section.add "X-Amz-Security-Token", valid_21626528
  var valid_21626529 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626529 = validateParameter(valid_21626529, JString, required = false,
                                   default = nil)
  if valid_21626529 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626529
  var valid_21626530 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626530 = validateParameter(valid_21626530, JString, required = false,
                                   default = nil)
  if valid_21626530 != nil:
    section.add "X-Amz-Algorithm", valid_21626530
  var valid_21626531 = header.getOrDefault("X-Amz-Signature")
  valid_21626531 = validateParameter(valid_21626531, JString, required = false,
                                   default = nil)
  if valid_21626531 != nil:
    section.add "X-Amz-Signature", valid_21626531
  var valid_21626532 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626532 = validateParameter(valid_21626532, JString, required = false,
                                   default = nil)
  if valid_21626532 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626532
  var valid_21626533 = header.getOrDefault("X-Amz-Credential")
  valid_21626533 = validateParameter(valid_21626533, JString, required = false,
                                   default = nil)
  if valid_21626533 != nil:
    section.add "X-Amz-Credential", valid_21626533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626534: Call_DeleteTags_21626522; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Removes tags for a resource
  ## 
  let valid = call_21626534.validator(path, query, header, formData, body, _)
  let scheme = call_21626534.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626534.makeUrl(scheme.get, call_21626534.host, call_21626534.base,
                               call_21626534.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626534, uri, valid, _)

proc call*(call_21626535: Call_DeleteTags_21626522; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## deleteTags
  ## Removes tags for a resource
  ##   tagKeys: JArray (required)
  ##          : Placeholder documentation for __listOf__string
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  var path_21626536 = newJObject()
  var query_21626537 = newJObject()
  if tagKeys != nil:
    query_21626537.add "tagKeys", tagKeys
  add(path_21626536, "resource-arn", newJString(resourceArn))
  result = call_21626535.call(path_21626536, query_21626537, nil, nil, nil)

var deleteTags* = Call_DeleteTags_21626522(name: "deleteTags",
                                        meth: HttpMethod.HttpDelete,
                                        host: "medialive.amazonaws.com", route: "/prod/tags/{resource-arn}#tagKeys",
                                        validator: validate_DeleteTags_21626523,
                                        base: "/", makeUrl: url_DeleteTags_21626524,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOffering_21626538 = ref object of OpenApiRestCall_21625435
proc url_DescribeOffering_21626540(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "offeringId" in path, "`offeringId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/offerings/"),
               (kind: VariableSegment, value: "offeringId")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeOffering_21626539(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Get details for an offering.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   offeringId: JString (required)
  ##             : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `offeringId` field"
  var valid_21626541 = path.getOrDefault("offeringId")
  valid_21626541 = validateParameter(valid_21626541, JString, required = true,
                                   default = nil)
  if valid_21626541 != nil:
    section.add "offeringId", valid_21626541
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
  var valid_21626542 = header.getOrDefault("X-Amz-Date")
  valid_21626542 = validateParameter(valid_21626542, JString, required = false,
                                   default = nil)
  if valid_21626542 != nil:
    section.add "X-Amz-Date", valid_21626542
  var valid_21626543 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626543 = validateParameter(valid_21626543, JString, required = false,
                                   default = nil)
  if valid_21626543 != nil:
    section.add "X-Amz-Security-Token", valid_21626543
  var valid_21626544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626544 = validateParameter(valid_21626544, JString, required = false,
                                   default = nil)
  if valid_21626544 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626544
  var valid_21626545 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626545 = validateParameter(valid_21626545, JString, required = false,
                                   default = nil)
  if valid_21626545 != nil:
    section.add "X-Amz-Algorithm", valid_21626545
  var valid_21626546 = header.getOrDefault("X-Amz-Signature")
  valid_21626546 = validateParameter(valid_21626546, JString, required = false,
                                   default = nil)
  if valid_21626546 != nil:
    section.add "X-Amz-Signature", valid_21626546
  var valid_21626547 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626547 = validateParameter(valid_21626547, JString, required = false,
                                   default = nil)
  if valid_21626547 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626547
  var valid_21626548 = header.getOrDefault("X-Amz-Credential")
  valid_21626548 = validateParameter(valid_21626548, JString, required = false,
                                   default = nil)
  if valid_21626548 != nil:
    section.add "X-Amz-Credential", valid_21626548
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626549: Call_DescribeOffering_21626538; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Get details for an offering.
  ## 
  let valid = call_21626549.validator(path, query, header, formData, body, _)
  let scheme = call_21626549.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626549.makeUrl(scheme.get, call_21626549.host, call_21626549.base,
                               call_21626549.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626549, uri, valid, _)

proc call*(call_21626550: Call_DescribeOffering_21626538; offeringId: string): Recallable =
  ## describeOffering
  ## Get details for an offering.
  ##   offeringId: string (required)
  ##             : Placeholder documentation for __string
  var path_21626551 = newJObject()
  add(path_21626551, "offeringId", newJString(offeringId))
  result = call_21626550.call(path_21626551, nil, nil, nil, nil)

var describeOffering* = Call_DescribeOffering_21626538(name: "describeOffering",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/offerings/{offeringId}", validator: validate_DescribeOffering_21626539,
    base: "/", makeUrl: url_DescribeOffering_21626540,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_21626552 = ref object of OpenApiRestCall_21625435
proc url_ListOfferings_21626554(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferings_21626553(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## List offerings available for purchase.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   codec: JString
  ##        : Placeholder documentation for __string
  ##   duration: JString
  ##           : Placeholder documentation for __string
  ##   channelClass: JString
  ##               : Placeholder documentation for __string
  ##   channelConfiguration: JString
  ##                       : Placeholder documentation for __string
  ##   resolution: JString
  ##             : Placeholder documentation for __string
  ##   maximumFramerate: JString
  ##                   : Placeholder documentation for __string
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   videoQuality: JString
  ##               : Placeholder documentation for __string
  ##   maximumBitrate: JString
  ##                 : Placeholder documentation for __string
  ##   specialFeature: JString
  ##                 : Placeholder documentation for __string
  ##   resourceType: JString
  ##               : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626555 = query.getOrDefault("codec")
  valid_21626555 = validateParameter(valid_21626555, JString, required = false,
                                   default = nil)
  if valid_21626555 != nil:
    section.add "codec", valid_21626555
  var valid_21626556 = query.getOrDefault("duration")
  valid_21626556 = validateParameter(valid_21626556, JString, required = false,
                                   default = nil)
  if valid_21626556 != nil:
    section.add "duration", valid_21626556
  var valid_21626557 = query.getOrDefault("channelClass")
  valid_21626557 = validateParameter(valid_21626557, JString, required = false,
                                   default = nil)
  if valid_21626557 != nil:
    section.add "channelClass", valid_21626557
  var valid_21626558 = query.getOrDefault("channelConfiguration")
  valid_21626558 = validateParameter(valid_21626558, JString, required = false,
                                   default = nil)
  if valid_21626558 != nil:
    section.add "channelConfiguration", valid_21626558
  var valid_21626559 = query.getOrDefault("resolution")
  valid_21626559 = validateParameter(valid_21626559, JString, required = false,
                                   default = nil)
  if valid_21626559 != nil:
    section.add "resolution", valid_21626559
  var valid_21626560 = query.getOrDefault("maximumFramerate")
  valid_21626560 = validateParameter(valid_21626560, JString, required = false,
                                   default = nil)
  if valid_21626560 != nil:
    section.add "maximumFramerate", valid_21626560
  var valid_21626561 = query.getOrDefault("NextToken")
  valid_21626561 = validateParameter(valid_21626561, JString, required = false,
                                   default = nil)
  if valid_21626561 != nil:
    section.add "NextToken", valid_21626561
  var valid_21626562 = query.getOrDefault("maxResults")
  valid_21626562 = validateParameter(valid_21626562, JInt, required = false,
                                   default = nil)
  if valid_21626562 != nil:
    section.add "maxResults", valid_21626562
  var valid_21626563 = query.getOrDefault("nextToken")
  valid_21626563 = validateParameter(valid_21626563, JString, required = false,
                                   default = nil)
  if valid_21626563 != nil:
    section.add "nextToken", valid_21626563
  var valid_21626564 = query.getOrDefault("videoQuality")
  valid_21626564 = validateParameter(valid_21626564, JString, required = false,
                                   default = nil)
  if valid_21626564 != nil:
    section.add "videoQuality", valid_21626564
  var valid_21626565 = query.getOrDefault("maximumBitrate")
  valid_21626565 = validateParameter(valid_21626565, JString, required = false,
                                   default = nil)
  if valid_21626565 != nil:
    section.add "maximumBitrate", valid_21626565
  var valid_21626566 = query.getOrDefault("specialFeature")
  valid_21626566 = validateParameter(valid_21626566, JString, required = false,
                                   default = nil)
  if valid_21626566 != nil:
    section.add "specialFeature", valid_21626566
  var valid_21626567 = query.getOrDefault("resourceType")
  valid_21626567 = validateParameter(valid_21626567, JString, required = false,
                                   default = nil)
  if valid_21626567 != nil:
    section.add "resourceType", valid_21626567
  var valid_21626568 = query.getOrDefault("MaxResults")
  valid_21626568 = validateParameter(valid_21626568, JString, required = false,
                                   default = nil)
  if valid_21626568 != nil:
    section.add "MaxResults", valid_21626568
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
  var valid_21626569 = header.getOrDefault("X-Amz-Date")
  valid_21626569 = validateParameter(valid_21626569, JString, required = false,
                                   default = nil)
  if valid_21626569 != nil:
    section.add "X-Amz-Date", valid_21626569
  var valid_21626570 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626570 = validateParameter(valid_21626570, JString, required = false,
                                   default = nil)
  if valid_21626570 != nil:
    section.add "X-Amz-Security-Token", valid_21626570
  var valid_21626571 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626571 = validateParameter(valid_21626571, JString, required = false,
                                   default = nil)
  if valid_21626571 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626571
  var valid_21626572 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626572 = validateParameter(valid_21626572, JString, required = false,
                                   default = nil)
  if valid_21626572 != nil:
    section.add "X-Amz-Algorithm", valid_21626572
  var valid_21626573 = header.getOrDefault("X-Amz-Signature")
  valid_21626573 = validateParameter(valid_21626573, JString, required = false,
                                   default = nil)
  if valid_21626573 != nil:
    section.add "X-Amz-Signature", valid_21626573
  var valid_21626574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626574 = validateParameter(valid_21626574, JString, required = false,
                                   default = nil)
  if valid_21626574 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626574
  var valid_21626575 = header.getOrDefault("X-Amz-Credential")
  valid_21626575 = validateParameter(valid_21626575, JString, required = false,
                                   default = nil)
  if valid_21626575 != nil:
    section.add "X-Amz-Credential", valid_21626575
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626576: Call_ListOfferings_21626552; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List offerings available for purchase.
  ## 
  let valid = call_21626576.validator(path, query, header, formData, body, _)
  let scheme = call_21626576.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626576.makeUrl(scheme.get, call_21626576.host, call_21626576.base,
                               call_21626576.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626576, uri, valid, _)

proc call*(call_21626577: Call_ListOfferings_21626552; codec: string = "";
          duration: string = ""; channelClass: string = "";
          channelConfiguration: string = ""; resolution: string = "";
          maximumFramerate: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; videoQuality: string = "";
          maximumBitrate: string = ""; specialFeature: string = "";
          resourceType: string = ""; MaxResults: string = ""): Recallable =
  ## listOfferings
  ## List offerings available for purchase.
  ##   codec: string
  ##        : Placeholder documentation for __string
  ##   duration: string
  ##           : Placeholder documentation for __string
  ##   channelClass: string
  ##               : Placeholder documentation for __string
  ##   channelConfiguration: string
  ##                       : Placeholder documentation for __string
  ##   resolution: string
  ##             : Placeholder documentation for __string
  ##   maximumFramerate: string
  ##                   : Placeholder documentation for __string
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   videoQuality: string
  ##               : Placeholder documentation for __string
  ##   maximumBitrate: string
  ##                 : Placeholder documentation for __string
  ##   specialFeature: string
  ##                 : Placeholder documentation for __string
  ##   resourceType: string
  ##               : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626578 = newJObject()
  add(query_21626578, "codec", newJString(codec))
  add(query_21626578, "duration", newJString(duration))
  add(query_21626578, "channelClass", newJString(channelClass))
  add(query_21626578, "channelConfiguration", newJString(channelConfiguration))
  add(query_21626578, "resolution", newJString(resolution))
  add(query_21626578, "maximumFramerate", newJString(maximumFramerate))
  add(query_21626578, "NextToken", newJString(NextToken))
  add(query_21626578, "maxResults", newJInt(maxResults))
  add(query_21626578, "nextToken", newJString(nextToken))
  add(query_21626578, "videoQuality", newJString(videoQuality))
  add(query_21626578, "maximumBitrate", newJString(maximumBitrate))
  add(query_21626578, "specialFeature", newJString(specialFeature))
  add(query_21626578, "resourceType", newJString(resourceType))
  add(query_21626578, "MaxResults", newJString(MaxResults))
  result = call_21626577.call(nil, query_21626578, nil, nil, nil)

var listOfferings* = Call_ListOfferings_21626552(name: "listOfferings",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/offerings", validator: validate_ListOfferings_21626553, base: "/",
    makeUrl: url_ListOfferings_21626554, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReservations_21626579 = ref object of OpenApiRestCall_21625435
proc url_ListReservations_21626581(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListReservations_21626580(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## List purchased reservations.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   codec: JString
  ##        : Placeholder documentation for __string
  ##   channelClass: JString
  ##               : Placeholder documentation for __string
  ##   resolution: JString
  ##             : Placeholder documentation for __string
  ##   maximumFramerate: JString
  ##                   : Placeholder documentation for __string
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   videoQuality: JString
  ##               : Placeholder documentation for __string
  ##   maximumBitrate: JString
  ##                 : Placeholder documentation for __string
  ##   specialFeature: JString
  ##                 : Placeholder documentation for __string
  ##   resourceType: JString
  ##               : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626582 = query.getOrDefault("codec")
  valid_21626582 = validateParameter(valid_21626582, JString, required = false,
                                   default = nil)
  if valid_21626582 != nil:
    section.add "codec", valid_21626582
  var valid_21626583 = query.getOrDefault("channelClass")
  valid_21626583 = validateParameter(valid_21626583, JString, required = false,
                                   default = nil)
  if valid_21626583 != nil:
    section.add "channelClass", valid_21626583
  var valid_21626584 = query.getOrDefault("resolution")
  valid_21626584 = validateParameter(valid_21626584, JString, required = false,
                                   default = nil)
  if valid_21626584 != nil:
    section.add "resolution", valid_21626584
  var valid_21626585 = query.getOrDefault("maximumFramerate")
  valid_21626585 = validateParameter(valid_21626585, JString, required = false,
                                   default = nil)
  if valid_21626585 != nil:
    section.add "maximumFramerate", valid_21626585
  var valid_21626586 = query.getOrDefault("NextToken")
  valid_21626586 = validateParameter(valid_21626586, JString, required = false,
                                   default = nil)
  if valid_21626586 != nil:
    section.add "NextToken", valid_21626586
  var valid_21626587 = query.getOrDefault("maxResults")
  valid_21626587 = validateParameter(valid_21626587, JInt, required = false,
                                   default = nil)
  if valid_21626587 != nil:
    section.add "maxResults", valid_21626587
  var valid_21626588 = query.getOrDefault("nextToken")
  valid_21626588 = validateParameter(valid_21626588, JString, required = false,
                                   default = nil)
  if valid_21626588 != nil:
    section.add "nextToken", valid_21626588
  var valid_21626589 = query.getOrDefault("videoQuality")
  valid_21626589 = validateParameter(valid_21626589, JString, required = false,
                                   default = nil)
  if valid_21626589 != nil:
    section.add "videoQuality", valid_21626589
  var valid_21626590 = query.getOrDefault("maximumBitrate")
  valid_21626590 = validateParameter(valid_21626590, JString, required = false,
                                   default = nil)
  if valid_21626590 != nil:
    section.add "maximumBitrate", valid_21626590
  var valid_21626591 = query.getOrDefault("specialFeature")
  valid_21626591 = validateParameter(valid_21626591, JString, required = false,
                                   default = nil)
  if valid_21626591 != nil:
    section.add "specialFeature", valid_21626591
  var valid_21626592 = query.getOrDefault("resourceType")
  valid_21626592 = validateParameter(valid_21626592, JString, required = false,
                                   default = nil)
  if valid_21626592 != nil:
    section.add "resourceType", valid_21626592
  var valid_21626593 = query.getOrDefault("MaxResults")
  valid_21626593 = validateParameter(valid_21626593, JString, required = false,
                                   default = nil)
  if valid_21626593 != nil:
    section.add "MaxResults", valid_21626593
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
  var valid_21626594 = header.getOrDefault("X-Amz-Date")
  valid_21626594 = validateParameter(valid_21626594, JString, required = false,
                                   default = nil)
  if valid_21626594 != nil:
    section.add "X-Amz-Date", valid_21626594
  var valid_21626595 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626595 = validateParameter(valid_21626595, JString, required = false,
                                   default = nil)
  if valid_21626595 != nil:
    section.add "X-Amz-Security-Token", valid_21626595
  var valid_21626596 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626596 = validateParameter(valid_21626596, JString, required = false,
                                   default = nil)
  if valid_21626596 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626596
  var valid_21626597 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626597 = validateParameter(valid_21626597, JString, required = false,
                                   default = nil)
  if valid_21626597 != nil:
    section.add "X-Amz-Algorithm", valid_21626597
  var valid_21626598 = header.getOrDefault("X-Amz-Signature")
  valid_21626598 = validateParameter(valid_21626598, JString, required = false,
                                   default = nil)
  if valid_21626598 != nil:
    section.add "X-Amz-Signature", valid_21626598
  var valid_21626599 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626599 = validateParameter(valid_21626599, JString, required = false,
                                   default = nil)
  if valid_21626599 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626599
  var valid_21626600 = header.getOrDefault("X-Amz-Credential")
  valid_21626600 = validateParameter(valid_21626600, JString, required = false,
                                   default = nil)
  if valid_21626600 != nil:
    section.add "X-Amz-Credential", valid_21626600
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626601: Call_ListReservations_21626579; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## List purchased reservations.
  ## 
  let valid = call_21626601.validator(path, query, header, formData, body, _)
  let scheme = call_21626601.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626601.makeUrl(scheme.get, call_21626601.host, call_21626601.base,
                               call_21626601.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626601, uri, valid, _)

proc call*(call_21626602: Call_ListReservations_21626579; codec: string = "";
          channelClass: string = ""; resolution: string = "";
          maximumFramerate: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; videoQuality: string = "";
          maximumBitrate: string = ""; specialFeature: string = "";
          resourceType: string = ""; MaxResults: string = ""): Recallable =
  ## listReservations
  ## List purchased reservations.
  ##   codec: string
  ##        : Placeholder documentation for __string
  ##   channelClass: string
  ##               : Placeholder documentation for __string
  ##   resolution: string
  ##             : Placeholder documentation for __string
  ##   maximumFramerate: string
  ##                   : Placeholder documentation for __string
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   videoQuality: string
  ##               : Placeholder documentation for __string
  ##   maximumBitrate: string
  ##                 : Placeholder documentation for __string
  ##   specialFeature: string
  ##                 : Placeholder documentation for __string
  ##   resourceType: string
  ##               : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626603 = newJObject()
  add(query_21626603, "codec", newJString(codec))
  add(query_21626603, "channelClass", newJString(channelClass))
  add(query_21626603, "resolution", newJString(resolution))
  add(query_21626603, "maximumFramerate", newJString(maximumFramerate))
  add(query_21626603, "NextToken", newJString(NextToken))
  add(query_21626603, "maxResults", newJInt(maxResults))
  add(query_21626603, "nextToken", newJString(nextToken))
  add(query_21626603, "videoQuality", newJString(videoQuality))
  add(query_21626603, "maximumBitrate", newJString(maximumBitrate))
  add(query_21626603, "specialFeature", newJString(specialFeature))
  add(query_21626603, "resourceType", newJString(resourceType))
  add(query_21626603, "MaxResults", newJString(MaxResults))
  result = call_21626602.call(nil, query_21626603, nil, nil, nil)

var listReservations* = Call_ListReservations_21626579(name: "listReservations",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/reservations", validator: validate_ListReservations_21626580,
    base: "/", makeUrl: url_ListReservations_21626581,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_21626604 = ref object of OpenApiRestCall_21625435
proc url_PurchaseOffering_21626606(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "offeringId" in path, "`offeringId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/offerings/"),
               (kind: VariableSegment, value: "offeringId"),
               (kind: ConstantSegment, value: "/purchase")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PurchaseOffering_21626605(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Purchase an offering and create a reservation.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   offeringId: JString (required)
  ##             : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `offeringId` field"
  var valid_21626607 = path.getOrDefault("offeringId")
  valid_21626607 = validateParameter(valid_21626607, JString, required = true,
                                   default = nil)
  if valid_21626607 != nil:
    section.add "offeringId", valid_21626607
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
  var valid_21626608 = header.getOrDefault("X-Amz-Date")
  valid_21626608 = validateParameter(valid_21626608, JString, required = false,
                                   default = nil)
  if valid_21626608 != nil:
    section.add "X-Amz-Date", valid_21626608
  var valid_21626609 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626609 = validateParameter(valid_21626609, JString, required = false,
                                   default = nil)
  if valid_21626609 != nil:
    section.add "X-Amz-Security-Token", valid_21626609
  var valid_21626610 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626610 = validateParameter(valid_21626610, JString, required = false,
                                   default = nil)
  if valid_21626610 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626610
  var valid_21626611 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626611 = validateParameter(valid_21626611, JString, required = false,
                                   default = nil)
  if valid_21626611 != nil:
    section.add "X-Amz-Algorithm", valid_21626611
  var valid_21626612 = header.getOrDefault("X-Amz-Signature")
  valid_21626612 = validateParameter(valid_21626612, JString, required = false,
                                   default = nil)
  if valid_21626612 != nil:
    section.add "X-Amz-Signature", valid_21626612
  var valid_21626613 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626613 = validateParameter(valid_21626613, JString, required = false,
                                   default = nil)
  if valid_21626613 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626613
  var valid_21626614 = header.getOrDefault("X-Amz-Credential")
  valid_21626614 = validateParameter(valid_21626614, JString, required = false,
                                   default = nil)
  if valid_21626614 != nil:
    section.add "X-Amz-Credential", valid_21626614
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

proc call*(call_21626616: Call_PurchaseOffering_21626604; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Purchase an offering and create a reservation.
  ## 
  let valid = call_21626616.validator(path, query, header, formData, body, _)
  let scheme = call_21626616.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626616.makeUrl(scheme.get, call_21626616.host, call_21626616.base,
                               call_21626616.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626616, uri, valid, _)

proc call*(call_21626617: Call_PurchaseOffering_21626604; offeringId: string;
          body: JsonNode): Recallable =
  ## purchaseOffering
  ## Purchase an offering and create a reservation.
  ##   offeringId: string (required)
  ##             : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_21626618 = newJObject()
  var body_21626619 = newJObject()
  add(path_21626618, "offeringId", newJString(offeringId))
  if body != nil:
    body_21626619 = body
  result = call_21626617.call(path_21626618, nil, nil, nil, body_21626619)

var purchaseOffering* = Call_PurchaseOffering_21626604(name: "purchaseOffering",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/offerings/{offeringId}/purchase",
    validator: validate_PurchaseOffering_21626605, base: "/",
    makeUrl: url_PurchaseOffering_21626606, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChannel_21626620 = ref object of OpenApiRestCall_21625435
proc url_StartChannel_21626622(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId"),
               (kind: ConstantSegment, value: "/start")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartChannel_21626621(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Starts an existing channel
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_21626623 = path.getOrDefault("channelId")
  valid_21626623 = validateParameter(valid_21626623, JString, required = true,
                                   default = nil)
  if valid_21626623 != nil:
    section.add "channelId", valid_21626623
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
  var valid_21626624 = header.getOrDefault("X-Amz-Date")
  valid_21626624 = validateParameter(valid_21626624, JString, required = false,
                                   default = nil)
  if valid_21626624 != nil:
    section.add "X-Amz-Date", valid_21626624
  var valid_21626625 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626625 = validateParameter(valid_21626625, JString, required = false,
                                   default = nil)
  if valid_21626625 != nil:
    section.add "X-Amz-Security-Token", valid_21626625
  var valid_21626626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626626 = validateParameter(valid_21626626, JString, required = false,
                                   default = nil)
  if valid_21626626 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626626
  var valid_21626627 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626627 = validateParameter(valid_21626627, JString, required = false,
                                   default = nil)
  if valid_21626627 != nil:
    section.add "X-Amz-Algorithm", valid_21626627
  var valid_21626628 = header.getOrDefault("X-Amz-Signature")
  valid_21626628 = validateParameter(valid_21626628, JString, required = false,
                                   default = nil)
  if valid_21626628 != nil:
    section.add "X-Amz-Signature", valid_21626628
  var valid_21626629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626629 = validateParameter(valid_21626629, JString, required = false,
                                   default = nil)
  if valid_21626629 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626629
  var valid_21626630 = header.getOrDefault("X-Amz-Credential")
  valid_21626630 = validateParameter(valid_21626630, JString, required = false,
                                   default = nil)
  if valid_21626630 != nil:
    section.add "X-Amz-Credential", valid_21626630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626631: Call_StartChannel_21626620; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Starts an existing channel
  ## 
  let valid = call_21626631.validator(path, query, header, formData, body, _)
  let scheme = call_21626631.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626631.makeUrl(scheme.get, call_21626631.host, call_21626631.base,
                               call_21626631.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626631, uri, valid, _)

proc call*(call_21626632: Call_StartChannel_21626620; channelId: string): Recallable =
  ## startChannel
  ## Starts an existing channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_21626633 = newJObject()
  add(path_21626633, "channelId", newJString(channelId))
  result = call_21626632.call(path_21626633, nil, nil, nil, nil)

var startChannel* = Call_StartChannel_21626620(name: "startChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/start", validator: validate_StartChannel_21626621,
    base: "/", makeUrl: url_StartChannel_21626622,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMultiplex_21626634 = ref object of OpenApiRestCall_21625435
proc url_StartMultiplex_21626636(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
               (kind: VariableSegment, value: "multiplexId"),
               (kind: ConstantSegment, value: "/start")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartMultiplex_21626635(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Start (run) the multiplex. Starting the multiplex does not start the channels. You must explicitly start each channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
  ##              : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `multiplexId` field"
  var valid_21626637 = path.getOrDefault("multiplexId")
  valid_21626637 = validateParameter(valid_21626637, JString, required = true,
                                   default = nil)
  if valid_21626637 != nil:
    section.add "multiplexId", valid_21626637
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
  var valid_21626638 = header.getOrDefault("X-Amz-Date")
  valid_21626638 = validateParameter(valid_21626638, JString, required = false,
                                   default = nil)
  if valid_21626638 != nil:
    section.add "X-Amz-Date", valid_21626638
  var valid_21626639 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626639 = validateParameter(valid_21626639, JString, required = false,
                                   default = nil)
  if valid_21626639 != nil:
    section.add "X-Amz-Security-Token", valid_21626639
  var valid_21626640 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626640 = validateParameter(valid_21626640, JString, required = false,
                                   default = nil)
  if valid_21626640 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626640
  var valid_21626641 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626641 = validateParameter(valid_21626641, JString, required = false,
                                   default = nil)
  if valid_21626641 != nil:
    section.add "X-Amz-Algorithm", valid_21626641
  var valid_21626642 = header.getOrDefault("X-Amz-Signature")
  valid_21626642 = validateParameter(valid_21626642, JString, required = false,
                                   default = nil)
  if valid_21626642 != nil:
    section.add "X-Amz-Signature", valid_21626642
  var valid_21626643 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626643 = validateParameter(valid_21626643, JString, required = false,
                                   default = nil)
  if valid_21626643 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626643
  var valid_21626644 = header.getOrDefault("X-Amz-Credential")
  valid_21626644 = validateParameter(valid_21626644, JString, required = false,
                                   default = nil)
  if valid_21626644 != nil:
    section.add "X-Amz-Credential", valid_21626644
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626645: Call_StartMultiplex_21626634; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Start (run) the multiplex. Starting the multiplex does not start the channels. You must explicitly start each channel.
  ## 
  let valid = call_21626645.validator(path, query, header, formData, body, _)
  let scheme = call_21626645.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626645.makeUrl(scheme.get, call_21626645.host, call_21626645.base,
                               call_21626645.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626645, uri, valid, _)

proc call*(call_21626646: Call_StartMultiplex_21626634; multiplexId: string): Recallable =
  ## startMultiplex
  ## Start (run) the multiplex. Starting the multiplex does not start the channels. You must explicitly start each channel.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_21626647 = newJObject()
  add(path_21626647, "multiplexId", newJString(multiplexId))
  result = call_21626646.call(path_21626647, nil, nil, nil, nil)

var startMultiplex* = Call_StartMultiplex_21626634(name: "startMultiplex",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/start",
    validator: validate_StartMultiplex_21626635, base: "/",
    makeUrl: url_StartMultiplex_21626636, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopChannel_21626648 = ref object of OpenApiRestCall_21625435
proc url_StopChannel_21626650(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId"),
               (kind: ConstantSegment, value: "/stop")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopChannel_21626649(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Stops a running channel
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_21626651 = path.getOrDefault("channelId")
  valid_21626651 = validateParameter(valid_21626651, JString, required = true,
                                   default = nil)
  if valid_21626651 != nil:
    section.add "channelId", valid_21626651
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
  var valid_21626652 = header.getOrDefault("X-Amz-Date")
  valid_21626652 = validateParameter(valid_21626652, JString, required = false,
                                   default = nil)
  if valid_21626652 != nil:
    section.add "X-Amz-Date", valid_21626652
  var valid_21626653 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626653 = validateParameter(valid_21626653, JString, required = false,
                                   default = nil)
  if valid_21626653 != nil:
    section.add "X-Amz-Security-Token", valid_21626653
  var valid_21626654 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626654 = validateParameter(valid_21626654, JString, required = false,
                                   default = nil)
  if valid_21626654 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626654
  var valid_21626655 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626655 = validateParameter(valid_21626655, JString, required = false,
                                   default = nil)
  if valid_21626655 != nil:
    section.add "X-Amz-Algorithm", valid_21626655
  var valid_21626656 = header.getOrDefault("X-Amz-Signature")
  valid_21626656 = validateParameter(valid_21626656, JString, required = false,
                                   default = nil)
  if valid_21626656 != nil:
    section.add "X-Amz-Signature", valid_21626656
  var valid_21626657 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626657 = validateParameter(valid_21626657, JString, required = false,
                                   default = nil)
  if valid_21626657 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626657
  var valid_21626658 = header.getOrDefault("X-Amz-Credential")
  valid_21626658 = validateParameter(valid_21626658, JString, required = false,
                                   default = nil)
  if valid_21626658 != nil:
    section.add "X-Amz-Credential", valid_21626658
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626659: Call_StopChannel_21626648; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a running channel
  ## 
  let valid = call_21626659.validator(path, query, header, formData, body, _)
  let scheme = call_21626659.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626659.makeUrl(scheme.get, call_21626659.host, call_21626659.base,
                               call_21626659.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626659, uri, valid, _)

proc call*(call_21626660: Call_StopChannel_21626648; channelId: string): Recallable =
  ## stopChannel
  ## Stops a running channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_21626661 = newJObject()
  add(path_21626661, "channelId", newJString(channelId))
  result = call_21626660.call(path_21626661, nil, nil, nil, nil)

var stopChannel* = Call_StopChannel_21626648(name: "stopChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/stop", validator: validate_StopChannel_21626649,
    base: "/", makeUrl: url_StopChannel_21626650,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMultiplex_21626662 = ref object of OpenApiRestCall_21625435
proc url_StopMultiplex_21626664(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "multiplexId" in path, "`multiplexId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/multiplexes/"),
               (kind: VariableSegment, value: "multiplexId"),
               (kind: ConstantSegment, value: "/stop")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopMultiplex_21626663(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Stops a running multiplex. If the multiplex isn't running, this action has no effect.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   multiplexId: JString (required)
  ##              : Placeholder documentation for __string
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `multiplexId` field"
  var valid_21626665 = path.getOrDefault("multiplexId")
  valid_21626665 = validateParameter(valid_21626665, JString, required = true,
                                   default = nil)
  if valid_21626665 != nil:
    section.add "multiplexId", valid_21626665
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
  var valid_21626666 = header.getOrDefault("X-Amz-Date")
  valid_21626666 = validateParameter(valid_21626666, JString, required = false,
                                   default = nil)
  if valid_21626666 != nil:
    section.add "X-Amz-Date", valid_21626666
  var valid_21626667 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626667 = validateParameter(valid_21626667, JString, required = false,
                                   default = nil)
  if valid_21626667 != nil:
    section.add "X-Amz-Security-Token", valid_21626667
  var valid_21626668 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626668 = validateParameter(valid_21626668, JString, required = false,
                                   default = nil)
  if valid_21626668 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626668
  var valid_21626669 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626669 = validateParameter(valid_21626669, JString, required = false,
                                   default = nil)
  if valid_21626669 != nil:
    section.add "X-Amz-Algorithm", valid_21626669
  var valid_21626670 = header.getOrDefault("X-Amz-Signature")
  valid_21626670 = validateParameter(valid_21626670, JString, required = false,
                                   default = nil)
  if valid_21626670 != nil:
    section.add "X-Amz-Signature", valid_21626670
  var valid_21626671 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626671 = validateParameter(valid_21626671, JString, required = false,
                                   default = nil)
  if valid_21626671 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626671
  var valid_21626672 = header.getOrDefault("X-Amz-Credential")
  valid_21626672 = validateParameter(valid_21626672, JString, required = false,
                                   default = nil)
  if valid_21626672 != nil:
    section.add "X-Amz-Credential", valid_21626672
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626673: Call_StopMultiplex_21626662; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Stops a running multiplex. If the multiplex isn't running, this action has no effect.
  ## 
  let valid = call_21626673.validator(path, query, header, formData, body, _)
  let scheme = call_21626673.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626673.makeUrl(scheme.get, call_21626673.host, call_21626673.base,
                               call_21626673.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626673, uri, valid, _)

proc call*(call_21626674: Call_StopMultiplex_21626662; multiplexId: string): Recallable =
  ## stopMultiplex
  ## Stops a running multiplex. If the multiplex isn't running, this action has no effect.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_21626675 = newJObject()
  add(path_21626675, "multiplexId", newJString(multiplexId))
  result = call_21626674.call(path_21626675, nil, nil, nil, nil)

var stopMultiplex* = Call_StopMultiplex_21626662(name: "stopMultiplex",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/stop",
    validator: validate_StopMultiplex_21626663, base: "/",
    makeUrl: url_StopMultiplex_21626664, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannelClass_21626676 = ref object of OpenApiRestCall_21625435
proc url_UpdateChannelClass_21626678(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "channelId" in path, "`channelId` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/prod/channels/"),
               (kind: VariableSegment, value: "channelId"),
               (kind: ConstantSegment, value: "/channelClass")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateChannelClass_21626677(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Changes the class of the channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_21626679 = path.getOrDefault("channelId")
  valid_21626679 = validateParameter(valid_21626679, JString, required = true,
                                   default = nil)
  if valid_21626679 != nil:
    section.add "channelId", valid_21626679
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
  var valid_21626680 = header.getOrDefault("X-Amz-Date")
  valid_21626680 = validateParameter(valid_21626680, JString, required = false,
                                   default = nil)
  if valid_21626680 != nil:
    section.add "X-Amz-Date", valid_21626680
  var valid_21626681 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626681 = validateParameter(valid_21626681, JString, required = false,
                                   default = nil)
  if valid_21626681 != nil:
    section.add "X-Amz-Security-Token", valid_21626681
  var valid_21626682 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626682 = validateParameter(valid_21626682, JString, required = false,
                                   default = nil)
  if valid_21626682 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626682
  var valid_21626683 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626683 = validateParameter(valid_21626683, JString, required = false,
                                   default = nil)
  if valid_21626683 != nil:
    section.add "X-Amz-Algorithm", valid_21626683
  var valid_21626684 = header.getOrDefault("X-Amz-Signature")
  valid_21626684 = validateParameter(valid_21626684, JString, required = false,
                                   default = nil)
  if valid_21626684 != nil:
    section.add "X-Amz-Signature", valid_21626684
  var valid_21626685 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626685 = validateParameter(valid_21626685, JString, required = false,
                                   default = nil)
  if valid_21626685 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626685
  var valid_21626686 = header.getOrDefault("X-Amz-Credential")
  valid_21626686 = validateParameter(valid_21626686, JString, required = false,
                                   default = nil)
  if valid_21626686 != nil:
    section.add "X-Amz-Credential", valid_21626686
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

proc call*(call_21626688: Call_UpdateChannelClass_21626676; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes the class of the channel.
  ## 
  let valid = call_21626688.validator(path, query, header, formData, body, _)
  let scheme = call_21626688.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626688.makeUrl(scheme.get, call_21626688.host, call_21626688.base,
                               call_21626688.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626688, uri, valid, _)

proc call*(call_21626689: Call_UpdateChannelClass_21626676; channelId: string;
          body: JsonNode): Recallable =
  ## updateChannelClass
  ## Changes the class of the channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_21626690 = newJObject()
  var body_21626691 = newJObject()
  add(path_21626690, "channelId", newJString(channelId))
  if body != nil:
    body_21626691 = body
  result = call_21626689.call(path_21626690, nil, nil, nil, body_21626691)

var updateChannelClass* = Call_UpdateChannelClass_21626676(
    name: "updateChannelClass", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/channelClass",
    validator: validate_UpdateChannelClass_21626677, base: "/",
    makeUrl: url_UpdateChannelClass_21626678, schemes: {Scheme.Https, Scheme.Http})
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
    headers["content-md5"] = base64.encode text.toMD5
  if not headers.hasKey($SecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[$SecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)

when not defined(ssl):
  {.error: "use ssl".}