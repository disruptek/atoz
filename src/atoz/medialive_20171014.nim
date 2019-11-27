
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_599368 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_599368](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_599368): Option[Scheme] {.used.} =
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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchUpdateSchedule_599980 = ref object of OpenApiRestCall_599368
proc url_BatchUpdateSchedule_599982(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_BatchUpdateSchedule_599981(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Update a channel schedule
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_599983 = path.getOrDefault("channelId")
  valid_599983 = validateParameter(valid_599983, JString, required = true,
                                 default = nil)
  if valid_599983 != nil:
    section.add "channelId", valid_599983
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
  var valid_599984 = header.getOrDefault("X-Amz-Date")
  valid_599984 = validateParameter(valid_599984, JString, required = false,
                                 default = nil)
  if valid_599984 != nil:
    section.add "X-Amz-Date", valid_599984
  var valid_599985 = header.getOrDefault("X-Amz-Security-Token")
  valid_599985 = validateParameter(valid_599985, JString, required = false,
                                 default = nil)
  if valid_599985 != nil:
    section.add "X-Amz-Security-Token", valid_599985
  var valid_599986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599986 = validateParameter(valid_599986, JString, required = false,
                                 default = nil)
  if valid_599986 != nil:
    section.add "X-Amz-Content-Sha256", valid_599986
  var valid_599987 = header.getOrDefault("X-Amz-Algorithm")
  valid_599987 = validateParameter(valid_599987, JString, required = false,
                                 default = nil)
  if valid_599987 != nil:
    section.add "X-Amz-Algorithm", valid_599987
  var valid_599988 = header.getOrDefault("X-Amz-Signature")
  valid_599988 = validateParameter(valid_599988, JString, required = false,
                                 default = nil)
  if valid_599988 != nil:
    section.add "X-Amz-Signature", valid_599988
  var valid_599989 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599989 = validateParameter(valid_599989, JString, required = false,
                                 default = nil)
  if valid_599989 != nil:
    section.add "X-Amz-SignedHeaders", valid_599989
  var valid_599990 = header.getOrDefault("X-Amz-Credential")
  valid_599990 = validateParameter(valid_599990, JString, required = false,
                                 default = nil)
  if valid_599990 != nil:
    section.add "X-Amz-Credential", valid_599990
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_599992: Call_BatchUpdateSchedule_599980; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a channel schedule
  ## 
  let valid = call_599992.validator(path, query, header, formData, body)
  let scheme = call_599992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599992.url(scheme.get, call_599992.host, call_599992.base,
                         call_599992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599992, url, valid)

proc call*(call_599993: Call_BatchUpdateSchedule_599980; channelId: string;
          body: JsonNode): Recallable =
  ## batchUpdateSchedule
  ## Update a channel schedule
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_599994 = newJObject()
  var body_599995 = newJObject()
  add(path_599994, "channelId", newJString(channelId))
  if body != nil:
    body_599995 = body
  result = call_599993.call(path_599994, nil, nil, nil, body_599995)

var batchUpdateSchedule* = Call_BatchUpdateSchedule_599980(
    name: "batchUpdateSchedule", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com", route: "/prod/channels/{channelId}/schedule",
    validator: validate_BatchUpdateSchedule_599981, base: "/",
    url: url_BatchUpdateSchedule_599982, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchedule_599705 = ref object of OpenApiRestCall_599368
proc url_DescribeSchedule_599707(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeSchedule_599706(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Get a channel schedule
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_599833 = path.getOrDefault("channelId")
  valid_599833 = validateParameter(valid_599833, JString, required = true,
                                 default = nil)
  if valid_599833 != nil:
    section.add "channelId", valid_599833
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
  var valid_599834 = query.getOrDefault("NextToken")
  valid_599834 = validateParameter(valid_599834, JString, required = false,
                                 default = nil)
  if valid_599834 != nil:
    section.add "NextToken", valid_599834
  var valid_599835 = query.getOrDefault("maxResults")
  valid_599835 = validateParameter(valid_599835, JInt, required = false, default = nil)
  if valid_599835 != nil:
    section.add "maxResults", valid_599835
  var valid_599836 = query.getOrDefault("nextToken")
  valid_599836 = validateParameter(valid_599836, JString, required = false,
                                 default = nil)
  if valid_599836 != nil:
    section.add "nextToken", valid_599836
  var valid_599837 = query.getOrDefault("MaxResults")
  valid_599837 = validateParameter(valid_599837, JString, required = false,
                                 default = nil)
  if valid_599837 != nil:
    section.add "MaxResults", valid_599837
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
  var valid_599838 = header.getOrDefault("X-Amz-Date")
  valid_599838 = validateParameter(valid_599838, JString, required = false,
                                 default = nil)
  if valid_599838 != nil:
    section.add "X-Amz-Date", valid_599838
  var valid_599839 = header.getOrDefault("X-Amz-Security-Token")
  valid_599839 = validateParameter(valid_599839, JString, required = false,
                                 default = nil)
  if valid_599839 != nil:
    section.add "X-Amz-Security-Token", valid_599839
  var valid_599840 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_599840 = validateParameter(valid_599840, JString, required = false,
                                 default = nil)
  if valid_599840 != nil:
    section.add "X-Amz-Content-Sha256", valid_599840
  var valid_599841 = header.getOrDefault("X-Amz-Algorithm")
  valid_599841 = validateParameter(valid_599841, JString, required = false,
                                 default = nil)
  if valid_599841 != nil:
    section.add "X-Amz-Algorithm", valid_599841
  var valid_599842 = header.getOrDefault("X-Amz-Signature")
  valid_599842 = validateParameter(valid_599842, JString, required = false,
                                 default = nil)
  if valid_599842 != nil:
    section.add "X-Amz-Signature", valid_599842
  var valid_599843 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_599843 = validateParameter(valid_599843, JString, required = false,
                                 default = nil)
  if valid_599843 != nil:
    section.add "X-Amz-SignedHeaders", valid_599843
  var valid_599844 = header.getOrDefault("X-Amz-Credential")
  valid_599844 = validateParameter(valid_599844, JString, required = false,
                                 default = nil)
  if valid_599844 != nil:
    section.add "X-Amz-Credential", valid_599844
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_599867: Call_DescribeSchedule_599705; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get a channel schedule
  ## 
  let valid = call_599867.validator(path, query, header, formData, body)
  let scheme = call_599867.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_599867.url(scheme.get, call_599867.host, call_599867.base,
                         call_599867.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_599867, url, valid)

proc call*(call_599938: Call_DescribeSchedule_599705; channelId: string;
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
  var path_599939 = newJObject()
  var query_599941 = newJObject()
  add(path_599939, "channelId", newJString(channelId))
  add(query_599941, "NextToken", newJString(NextToken))
  add(query_599941, "maxResults", newJInt(maxResults))
  add(query_599941, "nextToken", newJString(nextToken))
  add(query_599941, "MaxResults", newJString(MaxResults))
  result = call_599938.call(path_599939, query_599941, nil, nil, nil)

var describeSchedule* = Call_DescribeSchedule_599705(name: "describeSchedule",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_DescribeSchedule_599706, base: "/",
    url: url_DescribeSchedule_599707, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchedule_599996 = ref object of OpenApiRestCall_599368
proc url_DeleteSchedule_599998(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteSchedule_599997(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
  ## Delete all schedule actions on a channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_599999 = path.getOrDefault("channelId")
  valid_599999 = validateParameter(valid_599999, JString, required = true,
                                 default = nil)
  if valid_599999 != nil:
    section.add "channelId", valid_599999
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
  var valid_600000 = header.getOrDefault("X-Amz-Date")
  valid_600000 = validateParameter(valid_600000, JString, required = false,
                                 default = nil)
  if valid_600000 != nil:
    section.add "X-Amz-Date", valid_600000
  var valid_600001 = header.getOrDefault("X-Amz-Security-Token")
  valid_600001 = validateParameter(valid_600001, JString, required = false,
                                 default = nil)
  if valid_600001 != nil:
    section.add "X-Amz-Security-Token", valid_600001
  var valid_600002 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600002 = validateParameter(valid_600002, JString, required = false,
                                 default = nil)
  if valid_600002 != nil:
    section.add "X-Amz-Content-Sha256", valid_600002
  var valid_600003 = header.getOrDefault("X-Amz-Algorithm")
  valid_600003 = validateParameter(valid_600003, JString, required = false,
                                 default = nil)
  if valid_600003 != nil:
    section.add "X-Amz-Algorithm", valid_600003
  var valid_600004 = header.getOrDefault("X-Amz-Signature")
  valid_600004 = validateParameter(valid_600004, JString, required = false,
                                 default = nil)
  if valid_600004 != nil:
    section.add "X-Amz-Signature", valid_600004
  var valid_600005 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600005 = validateParameter(valid_600005, JString, required = false,
                                 default = nil)
  if valid_600005 != nil:
    section.add "X-Amz-SignedHeaders", valid_600005
  var valid_600006 = header.getOrDefault("X-Amz-Credential")
  valid_600006 = validateParameter(valid_600006, JString, required = false,
                                 default = nil)
  if valid_600006 != nil:
    section.add "X-Amz-Credential", valid_600006
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600007: Call_DeleteSchedule_599996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete all schedule actions on a channel.
  ## 
  let valid = call_600007.validator(path, query, header, formData, body)
  let scheme = call_600007.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600007.url(scheme.get, call_600007.host, call_600007.base,
                         call_600007.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600007, url, valid)

proc call*(call_600008: Call_DeleteSchedule_599996; channelId: string): Recallable =
  ## deleteSchedule
  ## Delete all schedule actions on a channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_600009 = newJObject()
  add(path_600009, "channelId", newJString(channelId))
  result = call_600008.call(path_600009, nil, nil, nil, nil)

var deleteSchedule* = Call_DeleteSchedule_599996(name: "deleteSchedule",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_DeleteSchedule_599997, base: "/", url: url_DeleteSchedule_599998,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateChannel_600027 = ref object of OpenApiRestCall_599368
proc url_CreateChannel_600029(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateChannel_600028(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600030 = header.getOrDefault("X-Amz-Date")
  valid_600030 = validateParameter(valid_600030, JString, required = false,
                                 default = nil)
  if valid_600030 != nil:
    section.add "X-Amz-Date", valid_600030
  var valid_600031 = header.getOrDefault("X-Amz-Security-Token")
  valid_600031 = validateParameter(valid_600031, JString, required = false,
                                 default = nil)
  if valid_600031 != nil:
    section.add "X-Amz-Security-Token", valid_600031
  var valid_600032 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600032 = validateParameter(valid_600032, JString, required = false,
                                 default = nil)
  if valid_600032 != nil:
    section.add "X-Amz-Content-Sha256", valid_600032
  var valid_600033 = header.getOrDefault("X-Amz-Algorithm")
  valid_600033 = validateParameter(valid_600033, JString, required = false,
                                 default = nil)
  if valid_600033 != nil:
    section.add "X-Amz-Algorithm", valid_600033
  var valid_600034 = header.getOrDefault("X-Amz-Signature")
  valid_600034 = validateParameter(valid_600034, JString, required = false,
                                 default = nil)
  if valid_600034 != nil:
    section.add "X-Amz-Signature", valid_600034
  var valid_600035 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600035 = validateParameter(valid_600035, JString, required = false,
                                 default = nil)
  if valid_600035 != nil:
    section.add "X-Amz-SignedHeaders", valid_600035
  var valid_600036 = header.getOrDefault("X-Amz-Credential")
  valid_600036 = validateParameter(valid_600036, JString, required = false,
                                 default = nil)
  if valid_600036 != nil:
    section.add "X-Amz-Credential", valid_600036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600038: Call_CreateChannel_600027; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new channel
  ## 
  let valid = call_600038.validator(path, query, header, formData, body)
  let scheme = call_600038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600038.url(scheme.get, call_600038.host, call_600038.base,
                         call_600038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600038, url, valid)

proc call*(call_600039: Call_CreateChannel_600027; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a new channel
  ##   body: JObject (required)
  var body_600040 = newJObject()
  if body != nil:
    body_600040 = body
  result = call_600039.call(nil, nil, nil, nil, body_600040)

var createChannel* = Call_CreateChannel_600027(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels", validator: validate_CreateChannel_600028, base: "/",
    url: url_CreateChannel_600029, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_600010 = ref object of OpenApiRestCall_599368
proc url_ListChannels_600012(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListChannels_600011(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600013 = query.getOrDefault("NextToken")
  valid_600013 = validateParameter(valid_600013, JString, required = false,
                                 default = nil)
  if valid_600013 != nil:
    section.add "NextToken", valid_600013
  var valid_600014 = query.getOrDefault("maxResults")
  valid_600014 = validateParameter(valid_600014, JInt, required = false, default = nil)
  if valid_600014 != nil:
    section.add "maxResults", valid_600014
  var valid_600015 = query.getOrDefault("nextToken")
  valid_600015 = validateParameter(valid_600015, JString, required = false,
                                 default = nil)
  if valid_600015 != nil:
    section.add "nextToken", valid_600015
  var valid_600016 = query.getOrDefault("MaxResults")
  valid_600016 = validateParameter(valid_600016, JString, required = false,
                                 default = nil)
  if valid_600016 != nil:
    section.add "MaxResults", valid_600016
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
  var valid_600017 = header.getOrDefault("X-Amz-Date")
  valid_600017 = validateParameter(valid_600017, JString, required = false,
                                 default = nil)
  if valid_600017 != nil:
    section.add "X-Amz-Date", valid_600017
  var valid_600018 = header.getOrDefault("X-Amz-Security-Token")
  valid_600018 = validateParameter(valid_600018, JString, required = false,
                                 default = nil)
  if valid_600018 != nil:
    section.add "X-Amz-Security-Token", valid_600018
  var valid_600019 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600019 = validateParameter(valid_600019, JString, required = false,
                                 default = nil)
  if valid_600019 != nil:
    section.add "X-Amz-Content-Sha256", valid_600019
  var valid_600020 = header.getOrDefault("X-Amz-Algorithm")
  valid_600020 = validateParameter(valid_600020, JString, required = false,
                                 default = nil)
  if valid_600020 != nil:
    section.add "X-Amz-Algorithm", valid_600020
  var valid_600021 = header.getOrDefault("X-Amz-Signature")
  valid_600021 = validateParameter(valid_600021, JString, required = false,
                                 default = nil)
  if valid_600021 != nil:
    section.add "X-Amz-Signature", valid_600021
  var valid_600022 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600022 = validateParameter(valid_600022, JString, required = false,
                                 default = nil)
  if valid_600022 != nil:
    section.add "X-Amz-SignedHeaders", valid_600022
  var valid_600023 = header.getOrDefault("X-Amz-Credential")
  valid_600023 = validateParameter(valid_600023, JString, required = false,
                                 default = nil)
  if valid_600023 != nil:
    section.add "X-Amz-Credential", valid_600023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600024: Call_ListChannels_600010; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of channels that have been created
  ## 
  let valid = call_600024.validator(path, query, header, formData, body)
  let scheme = call_600024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600024.url(scheme.get, call_600024.host, call_600024.base,
                         call_600024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600024, url, valid)

proc call*(call_600025: Call_ListChannels_600010; NextToken: string = "";
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
  var query_600026 = newJObject()
  add(query_600026, "NextToken", newJString(NextToken))
  add(query_600026, "maxResults", newJInt(maxResults))
  add(query_600026, "nextToken", newJString(nextToken))
  add(query_600026, "MaxResults", newJString(MaxResults))
  result = call_600025.call(nil, query_600026, nil, nil, nil)

var listChannels* = Call_ListChannels_600010(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels", validator: validate_ListChannels_600011, base: "/",
    url: url_ListChannels_600012, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInput_600058 = ref object of OpenApiRestCall_599368
proc url_CreateInput_600060(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInput_600059(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600061 = header.getOrDefault("X-Amz-Date")
  valid_600061 = validateParameter(valid_600061, JString, required = false,
                                 default = nil)
  if valid_600061 != nil:
    section.add "X-Amz-Date", valid_600061
  var valid_600062 = header.getOrDefault("X-Amz-Security-Token")
  valid_600062 = validateParameter(valid_600062, JString, required = false,
                                 default = nil)
  if valid_600062 != nil:
    section.add "X-Amz-Security-Token", valid_600062
  var valid_600063 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600063 = validateParameter(valid_600063, JString, required = false,
                                 default = nil)
  if valid_600063 != nil:
    section.add "X-Amz-Content-Sha256", valid_600063
  var valid_600064 = header.getOrDefault("X-Amz-Algorithm")
  valid_600064 = validateParameter(valid_600064, JString, required = false,
                                 default = nil)
  if valid_600064 != nil:
    section.add "X-Amz-Algorithm", valid_600064
  var valid_600065 = header.getOrDefault("X-Amz-Signature")
  valid_600065 = validateParameter(valid_600065, JString, required = false,
                                 default = nil)
  if valid_600065 != nil:
    section.add "X-Amz-Signature", valid_600065
  var valid_600066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600066 = validateParameter(valid_600066, JString, required = false,
                                 default = nil)
  if valid_600066 != nil:
    section.add "X-Amz-SignedHeaders", valid_600066
  var valid_600067 = header.getOrDefault("X-Amz-Credential")
  valid_600067 = validateParameter(valid_600067, JString, required = false,
                                 default = nil)
  if valid_600067 != nil:
    section.add "X-Amz-Credential", valid_600067
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600069: Call_CreateInput_600058; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create an input
  ## 
  let valid = call_600069.validator(path, query, header, formData, body)
  let scheme = call_600069.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600069.url(scheme.get, call_600069.host, call_600069.base,
                         call_600069.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600069, url, valid)

proc call*(call_600070: Call_CreateInput_600058; body: JsonNode): Recallable =
  ## createInput
  ## Create an input
  ##   body: JObject (required)
  var body_600071 = newJObject()
  if body != nil:
    body_600071 = body
  result = call_600070.call(nil, nil, nil, nil, body_600071)

var createInput* = Call_CreateInput_600058(name: "createInput",
                                        meth: HttpMethod.HttpPost,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs",
                                        validator: validate_CreateInput_600059,
                                        base: "/", url: url_CreateInput_600060,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputs_600041 = ref object of OpenApiRestCall_599368
proc url_ListInputs_600043(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInputs_600042(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600044 = query.getOrDefault("NextToken")
  valid_600044 = validateParameter(valid_600044, JString, required = false,
                                 default = nil)
  if valid_600044 != nil:
    section.add "NextToken", valid_600044
  var valid_600045 = query.getOrDefault("maxResults")
  valid_600045 = validateParameter(valid_600045, JInt, required = false, default = nil)
  if valid_600045 != nil:
    section.add "maxResults", valid_600045
  var valid_600046 = query.getOrDefault("nextToken")
  valid_600046 = validateParameter(valid_600046, JString, required = false,
                                 default = nil)
  if valid_600046 != nil:
    section.add "nextToken", valid_600046
  var valid_600047 = query.getOrDefault("MaxResults")
  valid_600047 = validateParameter(valid_600047, JString, required = false,
                                 default = nil)
  if valid_600047 != nil:
    section.add "MaxResults", valid_600047
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
  var valid_600048 = header.getOrDefault("X-Amz-Date")
  valid_600048 = validateParameter(valid_600048, JString, required = false,
                                 default = nil)
  if valid_600048 != nil:
    section.add "X-Amz-Date", valid_600048
  var valid_600049 = header.getOrDefault("X-Amz-Security-Token")
  valid_600049 = validateParameter(valid_600049, JString, required = false,
                                 default = nil)
  if valid_600049 != nil:
    section.add "X-Amz-Security-Token", valid_600049
  var valid_600050 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600050 = validateParameter(valid_600050, JString, required = false,
                                 default = nil)
  if valid_600050 != nil:
    section.add "X-Amz-Content-Sha256", valid_600050
  var valid_600051 = header.getOrDefault("X-Amz-Algorithm")
  valid_600051 = validateParameter(valid_600051, JString, required = false,
                                 default = nil)
  if valid_600051 != nil:
    section.add "X-Amz-Algorithm", valid_600051
  var valid_600052 = header.getOrDefault("X-Amz-Signature")
  valid_600052 = validateParameter(valid_600052, JString, required = false,
                                 default = nil)
  if valid_600052 != nil:
    section.add "X-Amz-Signature", valid_600052
  var valid_600053 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600053 = validateParameter(valid_600053, JString, required = false,
                                 default = nil)
  if valid_600053 != nil:
    section.add "X-Amz-SignedHeaders", valid_600053
  var valid_600054 = header.getOrDefault("X-Amz-Credential")
  valid_600054 = validateParameter(valid_600054, JString, required = false,
                                 default = nil)
  if valid_600054 != nil:
    section.add "X-Amz-Credential", valid_600054
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600055: Call_ListInputs_600041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of inputs that have been created
  ## 
  let valid = call_600055.validator(path, query, header, formData, body)
  let scheme = call_600055.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600055.url(scheme.get, call_600055.host, call_600055.base,
                         call_600055.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600055, url, valid)

proc call*(call_600056: Call_ListInputs_600041; NextToken: string = "";
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
  var query_600057 = newJObject()
  add(query_600057, "NextToken", newJString(NextToken))
  add(query_600057, "maxResults", newJInt(maxResults))
  add(query_600057, "nextToken", newJString(nextToken))
  add(query_600057, "MaxResults", newJString(MaxResults))
  result = call_600056.call(nil, query_600057, nil, nil, nil)

var listInputs* = Call_ListInputs_600041(name: "listInputs",
                                      meth: HttpMethod.HttpGet,
                                      host: "medialive.amazonaws.com",
                                      route: "/prod/inputs",
                                      validator: validate_ListInputs_600042,
                                      base: "/", url: url_ListInputs_600043,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInputSecurityGroup_600089 = ref object of OpenApiRestCall_599368
proc url_CreateInputSecurityGroup_600091(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInputSecurityGroup_600090(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600092 = header.getOrDefault("X-Amz-Date")
  valid_600092 = validateParameter(valid_600092, JString, required = false,
                                 default = nil)
  if valid_600092 != nil:
    section.add "X-Amz-Date", valid_600092
  var valid_600093 = header.getOrDefault("X-Amz-Security-Token")
  valid_600093 = validateParameter(valid_600093, JString, required = false,
                                 default = nil)
  if valid_600093 != nil:
    section.add "X-Amz-Security-Token", valid_600093
  var valid_600094 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600094 = validateParameter(valid_600094, JString, required = false,
                                 default = nil)
  if valid_600094 != nil:
    section.add "X-Amz-Content-Sha256", valid_600094
  var valid_600095 = header.getOrDefault("X-Amz-Algorithm")
  valid_600095 = validateParameter(valid_600095, JString, required = false,
                                 default = nil)
  if valid_600095 != nil:
    section.add "X-Amz-Algorithm", valid_600095
  var valid_600096 = header.getOrDefault("X-Amz-Signature")
  valid_600096 = validateParameter(valid_600096, JString, required = false,
                                 default = nil)
  if valid_600096 != nil:
    section.add "X-Amz-Signature", valid_600096
  var valid_600097 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600097 = validateParameter(valid_600097, JString, required = false,
                                 default = nil)
  if valid_600097 != nil:
    section.add "X-Amz-SignedHeaders", valid_600097
  var valid_600098 = header.getOrDefault("X-Amz-Credential")
  valid_600098 = validateParameter(valid_600098, JString, required = false,
                                 default = nil)
  if valid_600098 != nil:
    section.add "X-Amz-Credential", valid_600098
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600100: Call_CreateInputSecurityGroup_600089; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Input Security Group
  ## 
  let valid = call_600100.validator(path, query, header, formData, body)
  let scheme = call_600100.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600100.url(scheme.get, call_600100.host, call_600100.base,
                         call_600100.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600100, url, valid)

proc call*(call_600101: Call_CreateInputSecurityGroup_600089; body: JsonNode): Recallable =
  ## createInputSecurityGroup
  ## Creates a Input Security Group
  ##   body: JObject (required)
  var body_600102 = newJObject()
  if body != nil:
    body_600102 = body
  result = call_600101.call(nil, nil, nil, nil, body_600102)

var createInputSecurityGroup* = Call_CreateInputSecurityGroup_600089(
    name: "createInputSecurityGroup", meth: HttpMethod.HttpPost,
    host: "medialive.amazonaws.com", route: "/prod/inputSecurityGroups",
    validator: validate_CreateInputSecurityGroup_600090, base: "/",
    url: url_CreateInputSecurityGroup_600091, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputSecurityGroups_600072 = ref object of OpenApiRestCall_599368
proc url_ListInputSecurityGroups_600074(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInputSecurityGroups_600073(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600075 = query.getOrDefault("NextToken")
  valid_600075 = validateParameter(valid_600075, JString, required = false,
                                 default = nil)
  if valid_600075 != nil:
    section.add "NextToken", valid_600075
  var valid_600076 = query.getOrDefault("maxResults")
  valid_600076 = validateParameter(valid_600076, JInt, required = false, default = nil)
  if valid_600076 != nil:
    section.add "maxResults", valid_600076
  var valid_600077 = query.getOrDefault("nextToken")
  valid_600077 = validateParameter(valid_600077, JString, required = false,
                                 default = nil)
  if valid_600077 != nil:
    section.add "nextToken", valid_600077
  var valid_600078 = query.getOrDefault("MaxResults")
  valid_600078 = validateParameter(valid_600078, JString, required = false,
                                 default = nil)
  if valid_600078 != nil:
    section.add "MaxResults", valid_600078
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
  var valid_600079 = header.getOrDefault("X-Amz-Date")
  valid_600079 = validateParameter(valid_600079, JString, required = false,
                                 default = nil)
  if valid_600079 != nil:
    section.add "X-Amz-Date", valid_600079
  var valid_600080 = header.getOrDefault("X-Amz-Security-Token")
  valid_600080 = validateParameter(valid_600080, JString, required = false,
                                 default = nil)
  if valid_600080 != nil:
    section.add "X-Amz-Security-Token", valid_600080
  var valid_600081 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600081 = validateParameter(valid_600081, JString, required = false,
                                 default = nil)
  if valid_600081 != nil:
    section.add "X-Amz-Content-Sha256", valid_600081
  var valid_600082 = header.getOrDefault("X-Amz-Algorithm")
  valid_600082 = validateParameter(valid_600082, JString, required = false,
                                 default = nil)
  if valid_600082 != nil:
    section.add "X-Amz-Algorithm", valid_600082
  var valid_600083 = header.getOrDefault("X-Amz-Signature")
  valid_600083 = validateParameter(valid_600083, JString, required = false,
                                 default = nil)
  if valid_600083 != nil:
    section.add "X-Amz-Signature", valid_600083
  var valid_600084 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600084 = validateParameter(valid_600084, JString, required = false,
                                 default = nil)
  if valid_600084 != nil:
    section.add "X-Amz-SignedHeaders", valid_600084
  var valid_600085 = header.getOrDefault("X-Amz-Credential")
  valid_600085 = validateParameter(valid_600085, JString, required = false,
                                 default = nil)
  if valid_600085 != nil:
    section.add "X-Amz-Credential", valid_600085
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600086: Call_ListInputSecurityGroups_600072; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces a list of Input Security Groups for an account
  ## 
  let valid = call_600086.validator(path, query, header, formData, body)
  let scheme = call_600086.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600086.url(scheme.get, call_600086.host, call_600086.base,
                         call_600086.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600086, url, valid)

proc call*(call_600087: Call_ListInputSecurityGroups_600072;
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
  var query_600088 = newJObject()
  add(query_600088, "NextToken", newJString(NextToken))
  add(query_600088, "maxResults", newJInt(maxResults))
  add(query_600088, "nextToken", newJString(nextToken))
  add(query_600088, "MaxResults", newJString(MaxResults))
  result = call_600087.call(nil, query_600088, nil, nil, nil)

var listInputSecurityGroups* = Call_ListInputSecurityGroups_600072(
    name: "listInputSecurityGroups", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/inputSecurityGroups",
    validator: validate_ListInputSecurityGroups_600073, base: "/",
    url: url_ListInputSecurityGroups_600074, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultiplex_600120 = ref object of OpenApiRestCall_599368
proc url_CreateMultiplex_600122(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMultiplex_600121(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_600123 = header.getOrDefault("X-Amz-Date")
  valid_600123 = validateParameter(valid_600123, JString, required = false,
                                 default = nil)
  if valid_600123 != nil:
    section.add "X-Amz-Date", valid_600123
  var valid_600124 = header.getOrDefault("X-Amz-Security-Token")
  valid_600124 = validateParameter(valid_600124, JString, required = false,
                                 default = nil)
  if valid_600124 != nil:
    section.add "X-Amz-Security-Token", valid_600124
  var valid_600125 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600125 = validateParameter(valid_600125, JString, required = false,
                                 default = nil)
  if valid_600125 != nil:
    section.add "X-Amz-Content-Sha256", valid_600125
  var valid_600126 = header.getOrDefault("X-Amz-Algorithm")
  valid_600126 = validateParameter(valid_600126, JString, required = false,
                                 default = nil)
  if valid_600126 != nil:
    section.add "X-Amz-Algorithm", valid_600126
  var valid_600127 = header.getOrDefault("X-Amz-Signature")
  valid_600127 = validateParameter(valid_600127, JString, required = false,
                                 default = nil)
  if valid_600127 != nil:
    section.add "X-Amz-Signature", valid_600127
  var valid_600128 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600128 = validateParameter(valid_600128, JString, required = false,
                                 default = nil)
  if valid_600128 != nil:
    section.add "X-Amz-SignedHeaders", valid_600128
  var valid_600129 = header.getOrDefault("X-Amz-Credential")
  valid_600129 = validateParameter(valid_600129, JString, required = false,
                                 default = nil)
  if valid_600129 != nil:
    section.add "X-Amz-Credential", valid_600129
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600131: Call_CreateMultiplex_600120; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new multiplex.
  ## 
  let valid = call_600131.validator(path, query, header, formData, body)
  let scheme = call_600131.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600131.url(scheme.get, call_600131.host, call_600131.base,
                         call_600131.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600131, url, valid)

proc call*(call_600132: Call_CreateMultiplex_600120; body: JsonNode): Recallable =
  ## createMultiplex
  ## Create a new multiplex.
  ##   body: JObject (required)
  var body_600133 = newJObject()
  if body != nil:
    body_600133 = body
  result = call_600132.call(nil, nil, nil, nil, body_600133)

var createMultiplex* = Call_CreateMultiplex_600120(name: "createMultiplex",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes", validator: validate_CreateMultiplex_600121,
    base: "/", url: url_CreateMultiplex_600122, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultiplexes_600103 = ref object of OpenApiRestCall_599368
proc url_ListMultiplexes_600105(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMultiplexes_600104(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_600106 = query.getOrDefault("NextToken")
  valid_600106 = validateParameter(valid_600106, JString, required = false,
                                 default = nil)
  if valid_600106 != nil:
    section.add "NextToken", valid_600106
  var valid_600107 = query.getOrDefault("maxResults")
  valid_600107 = validateParameter(valid_600107, JInt, required = false, default = nil)
  if valid_600107 != nil:
    section.add "maxResults", valid_600107
  var valid_600108 = query.getOrDefault("nextToken")
  valid_600108 = validateParameter(valid_600108, JString, required = false,
                                 default = nil)
  if valid_600108 != nil:
    section.add "nextToken", valid_600108
  var valid_600109 = query.getOrDefault("MaxResults")
  valid_600109 = validateParameter(valid_600109, JString, required = false,
                                 default = nil)
  if valid_600109 != nil:
    section.add "MaxResults", valid_600109
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
  var valid_600110 = header.getOrDefault("X-Amz-Date")
  valid_600110 = validateParameter(valid_600110, JString, required = false,
                                 default = nil)
  if valid_600110 != nil:
    section.add "X-Amz-Date", valid_600110
  var valid_600111 = header.getOrDefault("X-Amz-Security-Token")
  valid_600111 = validateParameter(valid_600111, JString, required = false,
                                 default = nil)
  if valid_600111 != nil:
    section.add "X-Amz-Security-Token", valid_600111
  var valid_600112 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600112 = validateParameter(valid_600112, JString, required = false,
                                 default = nil)
  if valid_600112 != nil:
    section.add "X-Amz-Content-Sha256", valid_600112
  var valid_600113 = header.getOrDefault("X-Amz-Algorithm")
  valid_600113 = validateParameter(valid_600113, JString, required = false,
                                 default = nil)
  if valid_600113 != nil:
    section.add "X-Amz-Algorithm", valid_600113
  var valid_600114 = header.getOrDefault("X-Amz-Signature")
  valid_600114 = validateParameter(valid_600114, JString, required = false,
                                 default = nil)
  if valid_600114 != nil:
    section.add "X-Amz-Signature", valid_600114
  var valid_600115 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600115 = validateParameter(valid_600115, JString, required = false,
                                 default = nil)
  if valid_600115 != nil:
    section.add "X-Amz-SignedHeaders", valid_600115
  var valid_600116 = header.getOrDefault("X-Amz-Credential")
  valid_600116 = validateParameter(valid_600116, JString, required = false,
                                 default = nil)
  if valid_600116 != nil:
    section.add "X-Amz-Credential", valid_600116
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600117: Call_ListMultiplexes_600103; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the existing multiplexes.
  ## 
  let valid = call_600117.validator(path, query, header, formData, body)
  let scheme = call_600117.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600117.url(scheme.get, call_600117.host, call_600117.base,
                         call_600117.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600117, url, valid)

proc call*(call_600118: Call_ListMultiplexes_600103; NextToken: string = "";
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
  var query_600119 = newJObject()
  add(query_600119, "NextToken", newJString(NextToken))
  add(query_600119, "maxResults", newJInt(maxResults))
  add(query_600119, "nextToken", newJString(nextToken))
  add(query_600119, "MaxResults", newJString(MaxResults))
  result = call_600118.call(nil, query_600119, nil, nil, nil)

var listMultiplexes* = Call_ListMultiplexes_600103(name: "listMultiplexes",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes", validator: validate_ListMultiplexes_600104,
    base: "/", url: url_ListMultiplexes_600105, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultiplexProgram_600153 = ref object of OpenApiRestCall_599368
proc url_CreateMultiplexProgram_600155(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateMultiplexProgram_600154(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600156 = path.getOrDefault("multiplexId")
  valid_600156 = validateParameter(valid_600156, JString, required = true,
                                 default = nil)
  if valid_600156 != nil:
    section.add "multiplexId", valid_600156
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
  var valid_600157 = header.getOrDefault("X-Amz-Date")
  valid_600157 = validateParameter(valid_600157, JString, required = false,
                                 default = nil)
  if valid_600157 != nil:
    section.add "X-Amz-Date", valid_600157
  var valid_600158 = header.getOrDefault("X-Amz-Security-Token")
  valid_600158 = validateParameter(valid_600158, JString, required = false,
                                 default = nil)
  if valid_600158 != nil:
    section.add "X-Amz-Security-Token", valid_600158
  var valid_600159 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600159 = validateParameter(valid_600159, JString, required = false,
                                 default = nil)
  if valid_600159 != nil:
    section.add "X-Amz-Content-Sha256", valid_600159
  var valid_600160 = header.getOrDefault("X-Amz-Algorithm")
  valid_600160 = validateParameter(valid_600160, JString, required = false,
                                 default = nil)
  if valid_600160 != nil:
    section.add "X-Amz-Algorithm", valid_600160
  var valid_600161 = header.getOrDefault("X-Amz-Signature")
  valid_600161 = validateParameter(valid_600161, JString, required = false,
                                 default = nil)
  if valid_600161 != nil:
    section.add "X-Amz-Signature", valid_600161
  var valid_600162 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600162 = validateParameter(valid_600162, JString, required = false,
                                 default = nil)
  if valid_600162 != nil:
    section.add "X-Amz-SignedHeaders", valid_600162
  var valid_600163 = header.getOrDefault("X-Amz-Credential")
  valid_600163 = validateParameter(valid_600163, JString, required = false,
                                 default = nil)
  if valid_600163 != nil:
    section.add "X-Amz-Credential", valid_600163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600165: Call_CreateMultiplexProgram_600153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new program in the multiplex.
  ## 
  let valid = call_600165.validator(path, query, header, formData, body)
  let scheme = call_600165.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600165.url(scheme.get, call_600165.host, call_600165.base,
                         call_600165.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600165, url, valid)

proc call*(call_600166: Call_CreateMultiplexProgram_600153; multiplexId: string;
          body: JsonNode): Recallable =
  ## createMultiplexProgram
  ## Create a new program in the multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_600167 = newJObject()
  var body_600168 = newJObject()
  add(path_600167, "multiplexId", newJString(multiplexId))
  if body != nil:
    body_600168 = body
  result = call_600166.call(path_600167, nil, nil, nil, body_600168)

var createMultiplexProgram* = Call_CreateMultiplexProgram_600153(
    name: "createMultiplexProgram", meth: HttpMethod.HttpPost,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs",
    validator: validate_CreateMultiplexProgram_600154, base: "/",
    url: url_CreateMultiplexProgram_600155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultiplexPrograms_600134 = ref object of OpenApiRestCall_599368
proc url_ListMultiplexPrograms_600136(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListMultiplexPrograms_600135(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600137 = path.getOrDefault("multiplexId")
  valid_600137 = validateParameter(valid_600137, JString, required = true,
                                 default = nil)
  if valid_600137 != nil:
    section.add "multiplexId", valid_600137
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
  var valid_600138 = query.getOrDefault("NextToken")
  valid_600138 = validateParameter(valid_600138, JString, required = false,
                                 default = nil)
  if valid_600138 != nil:
    section.add "NextToken", valid_600138
  var valid_600139 = query.getOrDefault("maxResults")
  valid_600139 = validateParameter(valid_600139, JInt, required = false, default = nil)
  if valid_600139 != nil:
    section.add "maxResults", valid_600139
  var valid_600140 = query.getOrDefault("nextToken")
  valid_600140 = validateParameter(valid_600140, JString, required = false,
                                 default = nil)
  if valid_600140 != nil:
    section.add "nextToken", valid_600140
  var valid_600141 = query.getOrDefault("MaxResults")
  valid_600141 = validateParameter(valid_600141, JString, required = false,
                                 default = nil)
  if valid_600141 != nil:
    section.add "MaxResults", valid_600141
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
  var valid_600142 = header.getOrDefault("X-Amz-Date")
  valid_600142 = validateParameter(valid_600142, JString, required = false,
                                 default = nil)
  if valid_600142 != nil:
    section.add "X-Amz-Date", valid_600142
  var valid_600143 = header.getOrDefault("X-Amz-Security-Token")
  valid_600143 = validateParameter(valid_600143, JString, required = false,
                                 default = nil)
  if valid_600143 != nil:
    section.add "X-Amz-Security-Token", valid_600143
  var valid_600144 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600144 = validateParameter(valid_600144, JString, required = false,
                                 default = nil)
  if valid_600144 != nil:
    section.add "X-Amz-Content-Sha256", valid_600144
  var valid_600145 = header.getOrDefault("X-Amz-Algorithm")
  valid_600145 = validateParameter(valid_600145, JString, required = false,
                                 default = nil)
  if valid_600145 != nil:
    section.add "X-Amz-Algorithm", valid_600145
  var valid_600146 = header.getOrDefault("X-Amz-Signature")
  valid_600146 = validateParameter(valid_600146, JString, required = false,
                                 default = nil)
  if valid_600146 != nil:
    section.add "X-Amz-Signature", valid_600146
  var valid_600147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600147 = validateParameter(valid_600147, JString, required = false,
                                 default = nil)
  if valid_600147 != nil:
    section.add "X-Amz-SignedHeaders", valid_600147
  var valid_600148 = header.getOrDefault("X-Amz-Credential")
  valid_600148 = validateParameter(valid_600148, JString, required = false,
                                 default = nil)
  if valid_600148 != nil:
    section.add "X-Amz-Credential", valid_600148
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600149: Call_ListMultiplexPrograms_600134; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the programs that currently exist for a specific multiplex.
  ## 
  let valid = call_600149.validator(path, query, header, formData, body)
  let scheme = call_600149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600149.url(scheme.get, call_600149.host, call_600149.base,
                         call_600149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600149, url, valid)

proc call*(call_600150: Call_ListMultiplexPrograms_600134; multiplexId: string;
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
  var path_600151 = newJObject()
  var query_600152 = newJObject()
  add(path_600151, "multiplexId", newJString(multiplexId))
  add(query_600152, "NextToken", newJString(NextToken))
  add(query_600152, "maxResults", newJInt(maxResults))
  add(query_600152, "nextToken", newJString(nextToken))
  add(query_600152, "MaxResults", newJString(MaxResults))
  result = call_600150.call(path_600151, query_600152, nil, nil, nil)

var listMultiplexPrograms* = Call_ListMultiplexPrograms_600134(
    name: "listMultiplexPrograms", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs",
    validator: validate_ListMultiplexPrograms_600135, base: "/",
    url: url_ListMultiplexPrograms_600136, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_600183 = ref object of OpenApiRestCall_599368
proc url_CreateTags_600185(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTags_600184(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600186 = path.getOrDefault("resource-arn")
  valid_600186 = validateParameter(valid_600186, JString, required = true,
                                 default = nil)
  if valid_600186 != nil:
    section.add "resource-arn", valid_600186
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
  var valid_600187 = header.getOrDefault("X-Amz-Date")
  valid_600187 = validateParameter(valid_600187, JString, required = false,
                                 default = nil)
  if valid_600187 != nil:
    section.add "X-Amz-Date", valid_600187
  var valid_600188 = header.getOrDefault("X-Amz-Security-Token")
  valid_600188 = validateParameter(valid_600188, JString, required = false,
                                 default = nil)
  if valid_600188 != nil:
    section.add "X-Amz-Security-Token", valid_600188
  var valid_600189 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600189 = validateParameter(valid_600189, JString, required = false,
                                 default = nil)
  if valid_600189 != nil:
    section.add "X-Amz-Content-Sha256", valid_600189
  var valid_600190 = header.getOrDefault("X-Amz-Algorithm")
  valid_600190 = validateParameter(valid_600190, JString, required = false,
                                 default = nil)
  if valid_600190 != nil:
    section.add "X-Amz-Algorithm", valid_600190
  var valid_600191 = header.getOrDefault("X-Amz-Signature")
  valid_600191 = validateParameter(valid_600191, JString, required = false,
                                 default = nil)
  if valid_600191 != nil:
    section.add "X-Amz-Signature", valid_600191
  var valid_600192 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600192 = validateParameter(valid_600192, JString, required = false,
                                 default = nil)
  if valid_600192 != nil:
    section.add "X-Amz-SignedHeaders", valid_600192
  var valid_600193 = header.getOrDefault("X-Amz-Credential")
  valid_600193 = validateParameter(valid_600193, JString, required = false,
                                 default = nil)
  if valid_600193 != nil:
    section.add "X-Amz-Credential", valid_600193
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600195: Call_CreateTags_600183; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create tags for a resource
  ## 
  let valid = call_600195.validator(path, query, header, formData, body)
  let scheme = call_600195.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600195.url(scheme.get, call_600195.host, call_600195.base,
                         call_600195.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600195, url, valid)

proc call*(call_600196: Call_CreateTags_600183; resourceArn: string; body: JsonNode): Recallable =
  ## createTags
  ## Create tags for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_600197 = newJObject()
  var body_600198 = newJObject()
  add(path_600197, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_600198 = body
  result = call_600196.call(path_600197, nil, nil, nil, body_600198)

var createTags* = Call_CreateTags_600183(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "medialive.amazonaws.com",
                                      route: "/prod/tags/{resource-arn}",
                                      validator: validate_CreateTags_600184,
                                      base: "/", url: url_CreateTags_600185,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_600169 = ref object of OpenApiRestCall_599368
proc url_ListTagsForResource_600171(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_600170(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_600172 = path.getOrDefault("resource-arn")
  valid_600172 = validateParameter(valid_600172, JString, required = true,
                                 default = nil)
  if valid_600172 != nil:
    section.add "resource-arn", valid_600172
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
  var valid_600173 = header.getOrDefault("X-Amz-Date")
  valid_600173 = validateParameter(valid_600173, JString, required = false,
                                 default = nil)
  if valid_600173 != nil:
    section.add "X-Amz-Date", valid_600173
  var valid_600174 = header.getOrDefault("X-Amz-Security-Token")
  valid_600174 = validateParameter(valid_600174, JString, required = false,
                                 default = nil)
  if valid_600174 != nil:
    section.add "X-Amz-Security-Token", valid_600174
  var valid_600175 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600175 = validateParameter(valid_600175, JString, required = false,
                                 default = nil)
  if valid_600175 != nil:
    section.add "X-Amz-Content-Sha256", valid_600175
  var valid_600176 = header.getOrDefault("X-Amz-Algorithm")
  valid_600176 = validateParameter(valid_600176, JString, required = false,
                                 default = nil)
  if valid_600176 != nil:
    section.add "X-Amz-Algorithm", valid_600176
  var valid_600177 = header.getOrDefault("X-Amz-Signature")
  valid_600177 = validateParameter(valid_600177, JString, required = false,
                                 default = nil)
  if valid_600177 != nil:
    section.add "X-Amz-Signature", valid_600177
  var valid_600178 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600178 = validateParameter(valid_600178, JString, required = false,
                                 default = nil)
  if valid_600178 != nil:
    section.add "X-Amz-SignedHeaders", valid_600178
  var valid_600179 = header.getOrDefault("X-Amz-Credential")
  valid_600179 = validateParameter(valid_600179, JString, required = false,
                                 default = nil)
  if valid_600179 != nil:
    section.add "X-Amz-Credential", valid_600179
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600180: Call_ListTagsForResource_600169; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of tags that have been created for a resource
  ## 
  let valid = call_600180.validator(path, query, header, formData, body)
  let scheme = call_600180.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600180.url(scheme.get, call_600180.host, call_600180.base,
                         call_600180.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600180, url, valid)

proc call*(call_600181: Call_ListTagsForResource_600169; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Produces list of tags that have been created for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  var path_600182 = newJObject()
  add(path_600182, "resource-arn", newJString(resourceArn))
  result = call_600181.call(path_600182, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_600169(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/tags/{resource-arn}",
    validator: validate_ListTagsForResource_600170, base: "/",
    url: url_ListTagsForResource_600171, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_600213 = ref object of OpenApiRestCall_599368
proc url_UpdateChannel_600215(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateChannel_600214(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates a channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_600216 = path.getOrDefault("channelId")
  valid_600216 = validateParameter(valid_600216, JString, required = true,
                                 default = nil)
  if valid_600216 != nil:
    section.add "channelId", valid_600216
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
  var valid_600217 = header.getOrDefault("X-Amz-Date")
  valid_600217 = validateParameter(valid_600217, JString, required = false,
                                 default = nil)
  if valid_600217 != nil:
    section.add "X-Amz-Date", valid_600217
  var valid_600218 = header.getOrDefault("X-Amz-Security-Token")
  valid_600218 = validateParameter(valid_600218, JString, required = false,
                                 default = nil)
  if valid_600218 != nil:
    section.add "X-Amz-Security-Token", valid_600218
  var valid_600219 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600219 = validateParameter(valid_600219, JString, required = false,
                                 default = nil)
  if valid_600219 != nil:
    section.add "X-Amz-Content-Sha256", valid_600219
  var valid_600220 = header.getOrDefault("X-Amz-Algorithm")
  valid_600220 = validateParameter(valid_600220, JString, required = false,
                                 default = nil)
  if valid_600220 != nil:
    section.add "X-Amz-Algorithm", valid_600220
  var valid_600221 = header.getOrDefault("X-Amz-Signature")
  valid_600221 = validateParameter(valid_600221, JString, required = false,
                                 default = nil)
  if valid_600221 != nil:
    section.add "X-Amz-Signature", valid_600221
  var valid_600222 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600222 = validateParameter(valid_600222, JString, required = false,
                                 default = nil)
  if valid_600222 != nil:
    section.add "X-Amz-SignedHeaders", valid_600222
  var valid_600223 = header.getOrDefault("X-Amz-Credential")
  valid_600223 = validateParameter(valid_600223, JString, required = false,
                                 default = nil)
  if valid_600223 != nil:
    section.add "X-Amz-Credential", valid_600223
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600225: Call_UpdateChannel_600213; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a channel.
  ## 
  let valid = call_600225.validator(path, query, header, formData, body)
  let scheme = call_600225.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600225.url(scheme.get, call_600225.host, call_600225.base,
                         call_600225.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600225, url, valid)

proc call*(call_600226: Call_UpdateChannel_600213; channelId: string; body: JsonNode): Recallable =
  ## updateChannel
  ## Updates a channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_600227 = newJObject()
  var body_600228 = newJObject()
  add(path_600227, "channelId", newJString(channelId))
  if body != nil:
    body_600228 = body
  result = call_600226.call(path_600227, nil, nil, nil, body_600228)

var updateChannel* = Call_UpdateChannel_600213(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_UpdateChannel_600214,
    base: "/", url: url_UpdateChannel_600215, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_600199 = ref object of OpenApiRestCall_599368
proc url_DescribeChannel_600201(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeChannel_600200(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets details about a channel
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_600202 = path.getOrDefault("channelId")
  valid_600202 = validateParameter(valid_600202, JString, required = true,
                                 default = nil)
  if valid_600202 != nil:
    section.add "channelId", valid_600202
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
  var valid_600203 = header.getOrDefault("X-Amz-Date")
  valid_600203 = validateParameter(valid_600203, JString, required = false,
                                 default = nil)
  if valid_600203 != nil:
    section.add "X-Amz-Date", valid_600203
  var valid_600204 = header.getOrDefault("X-Amz-Security-Token")
  valid_600204 = validateParameter(valid_600204, JString, required = false,
                                 default = nil)
  if valid_600204 != nil:
    section.add "X-Amz-Security-Token", valid_600204
  var valid_600205 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600205 = validateParameter(valid_600205, JString, required = false,
                                 default = nil)
  if valid_600205 != nil:
    section.add "X-Amz-Content-Sha256", valid_600205
  var valid_600206 = header.getOrDefault("X-Amz-Algorithm")
  valid_600206 = validateParameter(valid_600206, JString, required = false,
                                 default = nil)
  if valid_600206 != nil:
    section.add "X-Amz-Algorithm", valid_600206
  var valid_600207 = header.getOrDefault("X-Amz-Signature")
  valid_600207 = validateParameter(valid_600207, JString, required = false,
                                 default = nil)
  if valid_600207 != nil:
    section.add "X-Amz-Signature", valid_600207
  var valid_600208 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600208 = validateParameter(valid_600208, JString, required = false,
                                 default = nil)
  if valid_600208 != nil:
    section.add "X-Amz-SignedHeaders", valid_600208
  var valid_600209 = header.getOrDefault("X-Amz-Credential")
  valid_600209 = validateParameter(valid_600209, JString, required = false,
                                 default = nil)
  if valid_600209 != nil:
    section.add "X-Amz-Credential", valid_600209
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600210: Call_DescribeChannel_600199; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a channel
  ## 
  let valid = call_600210.validator(path, query, header, formData, body)
  let scheme = call_600210.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600210.url(scheme.get, call_600210.host, call_600210.base,
                         call_600210.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600210, url, valid)

proc call*(call_600211: Call_DescribeChannel_600199; channelId: string): Recallable =
  ## describeChannel
  ## Gets details about a channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_600212 = newJObject()
  add(path_600212, "channelId", newJString(channelId))
  result = call_600211.call(path_600212, nil, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_600199(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_DescribeChannel_600200,
    base: "/", url: url_DescribeChannel_600201, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_600229 = ref object of OpenApiRestCall_599368
proc url_DeleteChannel_600231(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteChannel_600230(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts deletion of channel. The associated outputs are also deleted.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_600232 = path.getOrDefault("channelId")
  valid_600232 = validateParameter(valid_600232, JString, required = true,
                                 default = nil)
  if valid_600232 != nil:
    section.add "channelId", valid_600232
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
  var valid_600233 = header.getOrDefault("X-Amz-Date")
  valid_600233 = validateParameter(valid_600233, JString, required = false,
                                 default = nil)
  if valid_600233 != nil:
    section.add "X-Amz-Date", valid_600233
  var valid_600234 = header.getOrDefault("X-Amz-Security-Token")
  valid_600234 = validateParameter(valid_600234, JString, required = false,
                                 default = nil)
  if valid_600234 != nil:
    section.add "X-Amz-Security-Token", valid_600234
  var valid_600235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600235 = validateParameter(valid_600235, JString, required = false,
                                 default = nil)
  if valid_600235 != nil:
    section.add "X-Amz-Content-Sha256", valid_600235
  var valid_600236 = header.getOrDefault("X-Amz-Algorithm")
  valid_600236 = validateParameter(valid_600236, JString, required = false,
                                 default = nil)
  if valid_600236 != nil:
    section.add "X-Amz-Algorithm", valid_600236
  var valid_600237 = header.getOrDefault("X-Amz-Signature")
  valid_600237 = validateParameter(valid_600237, JString, required = false,
                                 default = nil)
  if valid_600237 != nil:
    section.add "X-Amz-Signature", valid_600237
  var valid_600238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600238 = validateParameter(valid_600238, JString, required = false,
                                 default = nil)
  if valid_600238 != nil:
    section.add "X-Amz-SignedHeaders", valid_600238
  var valid_600239 = header.getOrDefault("X-Amz-Credential")
  valid_600239 = validateParameter(valid_600239, JString, required = false,
                                 default = nil)
  if valid_600239 != nil:
    section.add "X-Amz-Credential", valid_600239
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600240: Call_DeleteChannel_600229; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts deletion of channel. The associated outputs are also deleted.
  ## 
  let valid = call_600240.validator(path, query, header, formData, body)
  let scheme = call_600240.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600240.url(scheme.get, call_600240.host, call_600240.base,
                         call_600240.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600240, url, valid)

proc call*(call_600241: Call_DeleteChannel_600229; channelId: string): Recallable =
  ## deleteChannel
  ## Starts deletion of channel. The associated outputs are also deleted.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_600242 = newJObject()
  add(path_600242, "channelId", newJString(channelId))
  result = call_600241.call(path_600242, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_600229(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_DeleteChannel_600230,
    base: "/", url: url_DeleteChannel_600231, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInput_600257 = ref object of OpenApiRestCall_599368
proc url_UpdateInput_600259(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateInput_600258(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an input.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputId: JString (required)
  ##          : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputId` field"
  var valid_600260 = path.getOrDefault("inputId")
  valid_600260 = validateParameter(valid_600260, JString, required = true,
                                 default = nil)
  if valid_600260 != nil:
    section.add "inputId", valid_600260
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
  var valid_600261 = header.getOrDefault("X-Amz-Date")
  valid_600261 = validateParameter(valid_600261, JString, required = false,
                                 default = nil)
  if valid_600261 != nil:
    section.add "X-Amz-Date", valid_600261
  var valid_600262 = header.getOrDefault("X-Amz-Security-Token")
  valid_600262 = validateParameter(valid_600262, JString, required = false,
                                 default = nil)
  if valid_600262 != nil:
    section.add "X-Amz-Security-Token", valid_600262
  var valid_600263 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600263 = validateParameter(valid_600263, JString, required = false,
                                 default = nil)
  if valid_600263 != nil:
    section.add "X-Amz-Content-Sha256", valid_600263
  var valid_600264 = header.getOrDefault("X-Amz-Algorithm")
  valid_600264 = validateParameter(valid_600264, JString, required = false,
                                 default = nil)
  if valid_600264 != nil:
    section.add "X-Amz-Algorithm", valid_600264
  var valid_600265 = header.getOrDefault("X-Amz-Signature")
  valid_600265 = validateParameter(valid_600265, JString, required = false,
                                 default = nil)
  if valid_600265 != nil:
    section.add "X-Amz-Signature", valid_600265
  var valid_600266 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600266 = validateParameter(valid_600266, JString, required = false,
                                 default = nil)
  if valid_600266 != nil:
    section.add "X-Amz-SignedHeaders", valid_600266
  var valid_600267 = header.getOrDefault("X-Amz-Credential")
  valid_600267 = validateParameter(valid_600267, JString, required = false,
                                 default = nil)
  if valid_600267 != nil:
    section.add "X-Amz-Credential", valid_600267
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600269: Call_UpdateInput_600257; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an input.
  ## 
  let valid = call_600269.validator(path, query, header, formData, body)
  let scheme = call_600269.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600269.url(scheme.get, call_600269.host, call_600269.base,
                         call_600269.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600269, url, valid)

proc call*(call_600270: Call_UpdateInput_600257; inputId: string; body: JsonNode): Recallable =
  ## updateInput
  ## Updates an input.
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_600271 = newJObject()
  var body_600272 = newJObject()
  add(path_600271, "inputId", newJString(inputId))
  if body != nil:
    body_600272 = body
  result = call_600270.call(path_600271, nil, nil, nil, body_600272)

var updateInput* = Call_UpdateInput_600257(name: "updateInput",
                                        meth: HttpMethod.HttpPut,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs/{inputId}",
                                        validator: validate_UpdateInput_600258,
                                        base: "/", url: url_UpdateInput_600259,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInput_600243 = ref object of OpenApiRestCall_599368
proc url_DescribeInput_600245(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeInput_600244(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Produces details about an input
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputId: JString (required)
  ##          : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputId` field"
  var valid_600246 = path.getOrDefault("inputId")
  valid_600246 = validateParameter(valid_600246, JString, required = true,
                                 default = nil)
  if valid_600246 != nil:
    section.add "inputId", valid_600246
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
  var valid_600247 = header.getOrDefault("X-Amz-Date")
  valid_600247 = validateParameter(valid_600247, JString, required = false,
                                 default = nil)
  if valid_600247 != nil:
    section.add "X-Amz-Date", valid_600247
  var valid_600248 = header.getOrDefault("X-Amz-Security-Token")
  valid_600248 = validateParameter(valid_600248, JString, required = false,
                                 default = nil)
  if valid_600248 != nil:
    section.add "X-Amz-Security-Token", valid_600248
  var valid_600249 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600249 = validateParameter(valid_600249, JString, required = false,
                                 default = nil)
  if valid_600249 != nil:
    section.add "X-Amz-Content-Sha256", valid_600249
  var valid_600250 = header.getOrDefault("X-Amz-Algorithm")
  valid_600250 = validateParameter(valid_600250, JString, required = false,
                                 default = nil)
  if valid_600250 != nil:
    section.add "X-Amz-Algorithm", valid_600250
  var valid_600251 = header.getOrDefault("X-Amz-Signature")
  valid_600251 = validateParameter(valid_600251, JString, required = false,
                                 default = nil)
  if valid_600251 != nil:
    section.add "X-Amz-Signature", valid_600251
  var valid_600252 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600252 = validateParameter(valid_600252, JString, required = false,
                                 default = nil)
  if valid_600252 != nil:
    section.add "X-Amz-SignedHeaders", valid_600252
  var valid_600253 = header.getOrDefault("X-Amz-Credential")
  valid_600253 = validateParameter(valid_600253, JString, required = false,
                                 default = nil)
  if valid_600253 != nil:
    section.add "X-Amz-Credential", valid_600253
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600254: Call_DescribeInput_600243; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces details about an input
  ## 
  let valid = call_600254.validator(path, query, header, formData, body)
  let scheme = call_600254.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600254.url(scheme.get, call_600254.host, call_600254.base,
                         call_600254.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600254, url, valid)

proc call*(call_600255: Call_DescribeInput_600243; inputId: string): Recallable =
  ## describeInput
  ## Produces details about an input
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_600256 = newJObject()
  add(path_600256, "inputId", newJString(inputId))
  result = call_600255.call(path_600256, nil, nil, nil, nil)

var describeInput* = Call_DescribeInput_600243(name: "describeInput",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/inputs/{inputId}", validator: validate_DescribeInput_600244,
    base: "/", url: url_DescribeInput_600245, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInput_600273 = ref object of OpenApiRestCall_599368
proc url_DeleteInput_600275(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteInput_600274(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes the input end point
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputId: JString (required)
  ##          : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputId` field"
  var valid_600276 = path.getOrDefault("inputId")
  valid_600276 = validateParameter(valid_600276, JString, required = true,
                                 default = nil)
  if valid_600276 != nil:
    section.add "inputId", valid_600276
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
  var valid_600277 = header.getOrDefault("X-Amz-Date")
  valid_600277 = validateParameter(valid_600277, JString, required = false,
                                 default = nil)
  if valid_600277 != nil:
    section.add "X-Amz-Date", valid_600277
  var valid_600278 = header.getOrDefault("X-Amz-Security-Token")
  valid_600278 = validateParameter(valid_600278, JString, required = false,
                                 default = nil)
  if valid_600278 != nil:
    section.add "X-Amz-Security-Token", valid_600278
  var valid_600279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600279 = validateParameter(valid_600279, JString, required = false,
                                 default = nil)
  if valid_600279 != nil:
    section.add "X-Amz-Content-Sha256", valid_600279
  var valid_600280 = header.getOrDefault("X-Amz-Algorithm")
  valid_600280 = validateParameter(valid_600280, JString, required = false,
                                 default = nil)
  if valid_600280 != nil:
    section.add "X-Amz-Algorithm", valid_600280
  var valid_600281 = header.getOrDefault("X-Amz-Signature")
  valid_600281 = validateParameter(valid_600281, JString, required = false,
                                 default = nil)
  if valid_600281 != nil:
    section.add "X-Amz-Signature", valid_600281
  var valid_600282 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600282 = validateParameter(valid_600282, JString, required = false,
                                 default = nil)
  if valid_600282 != nil:
    section.add "X-Amz-SignedHeaders", valid_600282
  var valid_600283 = header.getOrDefault("X-Amz-Credential")
  valid_600283 = validateParameter(valid_600283, JString, required = false,
                                 default = nil)
  if valid_600283 != nil:
    section.add "X-Amz-Credential", valid_600283
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600284: Call_DeleteInput_600273; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the input end point
  ## 
  let valid = call_600284.validator(path, query, header, formData, body)
  let scheme = call_600284.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600284.url(scheme.get, call_600284.host, call_600284.base,
                         call_600284.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600284, url, valid)

proc call*(call_600285: Call_DeleteInput_600273; inputId: string): Recallable =
  ## deleteInput
  ## Deletes the input end point
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_600286 = newJObject()
  add(path_600286, "inputId", newJString(inputId))
  result = call_600285.call(path_600286, nil, nil, nil, nil)

var deleteInput* = Call_DeleteInput_600273(name: "deleteInput",
                                        meth: HttpMethod.HttpDelete,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs/{inputId}",
                                        validator: validate_DeleteInput_600274,
                                        base: "/", url: url_DeleteInput_600275,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInputSecurityGroup_600301 = ref object of OpenApiRestCall_599368
proc url_UpdateInputSecurityGroup_600303(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateInputSecurityGroup_600302(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Update an Input Security Group's Whilelists.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputSecurityGroupId: JString (required)
  ##                       : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputSecurityGroupId` field"
  var valid_600304 = path.getOrDefault("inputSecurityGroupId")
  valid_600304 = validateParameter(valid_600304, JString, required = true,
                                 default = nil)
  if valid_600304 != nil:
    section.add "inputSecurityGroupId", valid_600304
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
  var valid_600305 = header.getOrDefault("X-Amz-Date")
  valid_600305 = validateParameter(valid_600305, JString, required = false,
                                 default = nil)
  if valid_600305 != nil:
    section.add "X-Amz-Date", valid_600305
  var valid_600306 = header.getOrDefault("X-Amz-Security-Token")
  valid_600306 = validateParameter(valid_600306, JString, required = false,
                                 default = nil)
  if valid_600306 != nil:
    section.add "X-Amz-Security-Token", valid_600306
  var valid_600307 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600307 = validateParameter(valid_600307, JString, required = false,
                                 default = nil)
  if valid_600307 != nil:
    section.add "X-Amz-Content-Sha256", valid_600307
  var valid_600308 = header.getOrDefault("X-Amz-Algorithm")
  valid_600308 = validateParameter(valid_600308, JString, required = false,
                                 default = nil)
  if valid_600308 != nil:
    section.add "X-Amz-Algorithm", valid_600308
  var valid_600309 = header.getOrDefault("X-Amz-Signature")
  valid_600309 = validateParameter(valid_600309, JString, required = false,
                                 default = nil)
  if valid_600309 != nil:
    section.add "X-Amz-Signature", valid_600309
  var valid_600310 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600310 = validateParameter(valid_600310, JString, required = false,
                                 default = nil)
  if valid_600310 != nil:
    section.add "X-Amz-SignedHeaders", valid_600310
  var valid_600311 = header.getOrDefault("X-Amz-Credential")
  valid_600311 = validateParameter(valid_600311, JString, required = false,
                                 default = nil)
  if valid_600311 != nil:
    section.add "X-Amz-Credential", valid_600311
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600313: Call_UpdateInputSecurityGroup_600301; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update an Input Security Group's Whilelists.
  ## 
  let valid = call_600313.validator(path, query, header, formData, body)
  let scheme = call_600313.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600313.url(scheme.get, call_600313.host, call_600313.base,
                         call_600313.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600313, url, valid)

proc call*(call_600314: Call_UpdateInputSecurityGroup_600301;
          inputSecurityGroupId: string; body: JsonNode): Recallable =
  ## updateInputSecurityGroup
  ## Update an Input Security Group's Whilelists.
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_600315 = newJObject()
  var body_600316 = newJObject()
  add(path_600315, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  if body != nil:
    body_600316 = body
  result = call_600314.call(path_600315, nil, nil, nil, body_600316)

var updateInputSecurityGroup* = Call_UpdateInputSecurityGroup_600301(
    name: "updateInputSecurityGroup", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_UpdateInputSecurityGroup_600302, base: "/",
    url: url_UpdateInputSecurityGroup_600303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInputSecurityGroup_600287 = ref object of OpenApiRestCall_599368
proc url_DescribeInputSecurityGroup_600289(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeInputSecurityGroup_600288(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Produces a summary of an Input Security Group
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputSecurityGroupId: JString (required)
  ##                       : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputSecurityGroupId` field"
  var valid_600290 = path.getOrDefault("inputSecurityGroupId")
  valid_600290 = validateParameter(valid_600290, JString, required = true,
                                 default = nil)
  if valid_600290 != nil:
    section.add "inputSecurityGroupId", valid_600290
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
  var valid_600291 = header.getOrDefault("X-Amz-Date")
  valid_600291 = validateParameter(valid_600291, JString, required = false,
                                 default = nil)
  if valid_600291 != nil:
    section.add "X-Amz-Date", valid_600291
  var valid_600292 = header.getOrDefault("X-Amz-Security-Token")
  valid_600292 = validateParameter(valid_600292, JString, required = false,
                                 default = nil)
  if valid_600292 != nil:
    section.add "X-Amz-Security-Token", valid_600292
  var valid_600293 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600293 = validateParameter(valid_600293, JString, required = false,
                                 default = nil)
  if valid_600293 != nil:
    section.add "X-Amz-Content-Sha256", valid_600293
  var valid_600294 = header.getOrDefault("X-Amz-Algorithm")
  valid_600294 = validateParameter(valid_600294, JString, required = false,
                                 default = nil)
  if valid_600294 != nil:
    section.add "X-Amz-Algorithm", valid_600294
  var valid_600295 = header.getOrDefault("X-Amz-Signature")
  valid_600295 = validateParameter(valid_600295, JString, required = false,
                                 default = nil)
  if valid_600295 != nil:
    section.add "X-Amz-Signature", valid_600295
  var valid_600296 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600296 = validateParameter(valid_600296, JString, required = false,
                                 default = nil)
  if valid_600296 != nil:
    section.add "X-Amz-SignedHeaders", valid_600296
  var valid_600297 = header.getOrDefault("X-Amz-Credential")
  valid_600297 = validateParameter(valid_600297, JString, required = false,
                                 default = nil)
  if valid_600297 != nil:
    section.add "X-Amz-Credential", valid_600297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600298: Call_DescribeInputSecurityGroup_600287; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces a summary of an Input Security Group
  ## 
  let valid = call_600298.validator(path, query, header, formData, body)
  let scheme = call_600298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600298.url(scheme.get, call_600298.host, call_600298.base,
                         call_600298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600298, url, valid)

proc call*(call_600299: Call_DescribeInputSecurityGroup_600287;
          inputSecurityGroupId: string): Recallable =
  ## describeInputSecurityGroup
  ## Produces a summary of an Input Security Group
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  var path_600300 = newJObject()
  add(path_600300, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  result = call_600299.call(path_600300, nil, nil, nil, nil)

var describeInputSecurityGroup* = Call_DescribeInputSecurityGroup_600287(
    name: "describeInputSecurityGroup", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_DescribeInputSecurityGroup_600288, base: "/",
    url: url_DescribeInputSecurityGroup_600289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInputSecurityGroup_600317 = ref object of OpenApiRestCall_599368
proc url_DeleteInputSecurityGroup_600319(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteInputSecurityGroup_600318(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an Input Security Group
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   inputSecurityGroupId: JString (required)
  ##                       : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `inputSecurityGroupId` field"
  var valid_600320 = path.getOrDefault("inputSecurityGroupId")
  valid_600320 = validateParameter(valid_600320, JString, required = true,
                                 default = nil)
  if valid_600320 != nil:
    section.add "inputSecurityGroupId", valid_600320
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
  var valid_600321 = header.getOrDefault("X-Amz-Date")
  valid_600321 = validateParameter(valid_600321, JString, required = false,
                                 default = nil)
  if valid_600321 != nil:
    section.add "X-Amz-Date", valid_600321
  var valid_600322 = header.getOrDefault("X-Amz-Security-Token")
  valid_600322 = validateParameter(valid_600322, JString, required = false,
                                 default = nil)
  if valid_600322 != nil:
    section.add "X-Amz-Security-Token", valid_600322
  var valid_600323 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600323 = validateParameter(valid_600323, JString, required = false,
                                 default = nil)
  if valid_600323 != nil:
    section.add "X-Amz-Content-Sha256", valid_600323
  var valid_600324 = header.getOrDefault("X-Amz-Algorithm")
  valid_600324 = validateParameter(valid_600324, JString, required = false,
                                 default = nil)
  if valid_600324 != nil:
    section.add "X-Amz-Algorithm", valid_600324
  var valid_600325 = header.getOrDefault("X-Amz-Signature")
  valid_600325 = validateParameter(valid_600325, JString, required = false,
                                 default = nil)
  if valid_600325 != nil:
    section.add "X-Amz-Signature", valid_600325
  var valid_600326 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600326 = validateParameter(valid_600326, JString, required = false,
                                 default = nil)
  if valid_600326 != nil:
    section.add "X-Amz-SignedHeaders", valid_600326
  var valid_600327 = header.getOrDefault("X-Amz-Credential")
  valid_600327 = validateParameter(valid_600327, JString, required = false,
                                 default = nil)
  if valid_600327 != nil:
    section.add "X-Amz-Credential", valid_600327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600328: Call_DeleteInputSecurityGroup_600317; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Input Security Group
  ## 
  let valid = call_600328.validator(path, query, header, formData, body)
  let scheme = call_600328.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600328.url(scheme.get, call_600328.host, call_600328.base,
                         call_600328.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600328, url, valid)

proc call*(call_600329: Call_DeleteInputSecurityGroup_600317;
          inputSecurityGroupId: string): Recallable =
  ## deleteInputSecurityGroup
  ## Deletes an Input Security Group
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  var path_600330 = newJObject()
  add(path_600330, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  result = call_600329.call(path_600330, nil, nil, nil, nil)

var deleteInputSecurityGroup* = Call_DeleteInputSecurityGroup_600317(
    name: "deleteInputSecurityGroup", meth: HttpMethod.HttpDelete,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_DeleteInputSecurityGroup_600318, base: "/",
    url: url_DeleteInputSecurityGroup_600319, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMultiplex_600345 = ref object of OpenApiRestCall_599368
proc url_UpdateMultiplex_600347(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMultiplex_600346(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_600348 = path.getOrDefault("multiplexId")
  valid_600348 = validateParameter(valid_600348, JString, required = true,
                                 default = nil)
  if valid_600348 != nil:
    section.add "multiplexId", valid_600348
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
  var valid_600349 = header.getOrDefault("X-Amz-Date")
  valid_600349 = validateParameter(valid_600349, JString, required = false,
                                 default = nil)
  if valid_600349 != nil:
    section.add "X-Amz-Date", valid_600349
  var valid_600350 = header.getOrDefault("X-Amz-Security-Token")
  valid_600350 = validateParameter(valid_600350, JString, required = false,
                                 default = nil)
  if valid_600350 != nil:
    section.add "X-Amz-Security-Token", valid_600350
  var valid_600351 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600351 = validateParameter(valid_600351, JString, required = false,
                                 default = nil)
  if valid_600351 != nil:
    section.add "X-Amz-Content-Sha256", valid_600351
  var valid_600352 = header.getOrDefault("X-Amz-Algorithm")
  valid_600352 = validateParameter(valid_600352, JString, required = false,
                                 default = nil)
  if valid_600352 != nil:
    section.add "X-Amz-Algorithm", valid_600352
  var valid_600353 = header.getOrDefault("X-Amz-Signature")
  valid_600353 = validateParameter(valid_600353, JString, required = false,
                                 default = nil)
  if valid_600353 != nil:
    section.add "X-Amz-Signature", valid_600353
  var valid_600354 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600354 = validateParameter(valid_600354, JString, required = false,
                                 default = nil)
  if valid_600354 != nil:
    section.add "X-Amz-SignedHeaders", valid_600354
  var valid_600355 = header.getOrDefault("X-Amz-Credential")
  valid_600355 = validateParameter(valid_600355, JString, required = false,
                                 default = nil)
  if valid_600355 != nil:
    section.add "X-Amz-Credential", valid_600355
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600357: Call_UpdateMultiplex_600345; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a multiplex.
  ## 
  let valid = call_600357.validator(path, query, header, formData, body)
  let scheme = call_600357.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600357.url(scheme.get, call_600357.host, call_600357.base,
                         call_600357.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600357, url, valid)

proc call*(call_600358: Call_UpdateMultiplex_600345; multiplexId: string;
          body: JsonNode): Recallable =
  ## updateMultiplex
  ## Updates a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_600359 = newJObject()
  var body_600360 = newJObject()
  add(path_600359, "multiplexId", newJString(multiplexId))
  if body != nil:
    body_600360 = body
  result = call_600358.call(path_600359, nil, nil, nil, body_600360)

var updateMultiplex* = Call_UpdateMultiplex_600345(name: "updateMultiplex",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}", validator: validate_UpdateMultiplex_600346,
    base: "/", url: url_UpdateMultiplex_600347, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMultiplex_600331 = ref object of OpenApiRestCall_599368
proc url_DescribeMultiplex_600333(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeMultiplex_600332(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_600334 = path.getOrDefault("multiplexId")
  valid_600334 = validateParameter(valid_600334, JString, required = true,
                                 default = nil)
  if valid_600334 != nil:
    section.add "multiplexId", valid_600334
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
  var valid_600335 = header.getOrDefault("X-Amz-Date")
  valid_600335 = validateParameter(valid_600335, JString, required = false,
                                 default = nil)
  if valid_600335 != nil:
    section.add "X-Amz-Date", valid_600335
  var valid_600336 = header.getOrDefault("X-Amz-Security-Token")
  valid_600336 = validateParameter(valid_600336, JString, required = false,
                                 default = nil)
  if valid_600336 != nil:
    section.add "X-Amz-Security-Token", valid_600336
  var valid_600337 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600337 = validateParameter(valid_600337, JString, required = false,
                                 default = nil)
  if valid_600337 != nil:
    section.add "X-Amz-Content-Sha256", valid_600337
  var valid_600338 = header.getOrDefault("X-Amz-Algorithm")
  valid_600338 = validateParameter(valid_600338, JString, required = false,
                                 default = nil)
  if valid_600338 != nil:
    section.add "X-Amz-Algorithm", valid_600338
  var valid_600339 = header.getOrDefault("X-Amz-Signature")
  valid_600339 = validateParameter(valid_600339, JString, required = false,
                                 default = nil)
  if valid_600339 != nil:
    section.add "X-Amz-Signature", valid_600339
  var valid_600340 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600340 = validateParameter(valid_600340, JString, required = false,
                                 default = nil)
  if valid_600340 != nil:
    section.add "X-Amz-SignedHeaders", valid_600340
  var valid_600341 = header.getOrDefault("X-Amz-Credential")
  valid_600341 = validateParameter(valid_600341, JString, required = false,
                                 default = nil)
  if valid_600341 != nil:
    section.add "X-Amz-Credential", valid_600341
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600342: Call_DescribeMultiplex_600331; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a multiplex.
  ## 
  let valid = call_600342.validator(path, query, header, formData, body)
  let scheme = call_600342.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600342.url(scheme.get, call_600342.host, call_600342.base,
                         call_600342.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600342, url, valid)

proc call*(call_600343: Call_DescribeMultiplex_600331; multiplexId: string): Recallable =
  ## describeMultiplex
  ## Gets details about a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_600344 = newJObject()
  add(path_600344, "multiplexId", newJString(multiplexId))
  result = call_600343.call(path_600344, nil, nil, nil, nil)

var describeMultiplex* = Call_DescribeMultiplex_600331(name: "describeMultiplex",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}",
    validator: validate_DescribeMultiplex_600332, base: "/",
    url: url_DescribeMultiplex_600333, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMultiplex_600361 = ref object of OpenApiRestCall_599368
proc url_DeleteMultiplex_600363(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMultiplex_600362(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
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
  var valid_600364 = path.getOrDefault("multiplexId")
  valid_600364 = validateParameter(valid_600364, JString, required = true,
                                 default = nil)
  if valid_600364 != nil:
    section.add "multiplexId", valid_600364
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
  var valid_600365 = header.getOrDefault("X-Amz-Date")
  valid_600365 = validateParameter(valid_600365, JString, required = false,
                                 default = nil)
  if valid_600365 != nil:
    section.add "X-Amz-Date", valid_600365
  var valid_600366 = header.getOrDefault("X-Amz-Security-Token")
  valid_600366 = validateParameter(valid_600366, JString, required = false,
                                 default = nil)
  if valid_600366 != nil:
    section.add "X-Amz-Security-Token", valid_600366
  var valid_600367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600367 = validateParameter(valid_600367, JString, required = false,
                                 default = nil)
  if valid_600367 != nil:
    section.add "X-Amz-Content-Sha256", valid_600367
  var valid_600368 = header.getOrDefault("X-Amz-Algorithm")
  valid_600368 = validateParameter(valid_600368, JString, required = false,
                                 default = nil)
  if valid_600368 != nil:
    section.add "X-Amz-Algorithm", valid_600368
  var valid_600369 = header.getOrDefault("X-Amz-Signature")
  valid_600369 = validateParameter(valid_600369, JString, required = false,
                                 default = nil)
  if valid_600369 != nil:
    section.add "X-Amz-Signature", valid_600369
  var valid_600370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600370 = validateParameter(valid_600370, JString, required = false,
                                 default = nil)
  if valid_600370 != nil:
    section.add "X-Amz-SignedHeaders", valid_600370
  var valid_600371 = header.getOrDefault("X-Amz-Credential")
  valid_600371 = validateParameter(valid_600371, JString, required = false,
                                 default = nil)
  if valid_600371 != nil:
    section.add "X-Amz-Credential", valid_600371
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600372: Call_DeleteMultiplex_600361; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a multiplex. The multiplex must be idle.
  ## 
  let valid = call_600372.validator(path, query, header, formData, body)
  let scheme = call_600372.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600372.url(scheme.get, call_600372.host, call_600372.base,
                         call_600372.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600372, url, valid)

proc call*(call_600373: Call_DeleteMultiplex_600361; multiplexId: string): Recallable =
  ## deleteMultiplex
  ## Delete a multiplex. The multiplex must be idle.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_600374 = newJObject()
  add(path_600374, "multiplexId", newJString(multiplexId))
  result = call_600373.call(path_600374, nil, nil, nil, nil)

var deleteMultiplex* = Call_DeleteMultiplex_600361(name: "deleteMultiplex",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}", validator: validate_DeleteMultiplex_600362,
    base: "/", url: url_DeleteMultiplex_600363, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMultiplexProgram_600390 = ref object of OpenApiRestCall_599368
proc url_UpdateMultiplexProgram_600392(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMultiplexProgram_600391(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600393 = path.getOrDefault("multiplexId")
  valid_600393 = validateParameter(valid_600393, JString, required = true,
                                 default = nil)
  if valid_600393 != nil:
    section.add "multiplexId", valid_600393
  var valid_600394 = path.getOrDefault("programName")
  valid_600394 = validateParameter(valid_600394, JString, required = true,
                                 default = nil)
  if valid_600394 != nil:
    section.add "programName", valid_600394
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
  var valid_600395 = header.getOrDefault("X-Amz-Date")
  valid_600395 = validateParameter(valid_600395, JString, required = false,
                                 default = nil)
  if valid_600395 != nil:
    section.add "X-Amz-Date", valid_600395
  var valid_600396 = header.getOrDefault("X-Amz-Security-Token")
  valid_600396 = validateParameter(valid_600396, JString, required = false,
                                 default = nil)
  if valid_600396 != nil:
    section.add "X-Amz-Security-Token", valid_600396
  var valid_600397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600397 = validateParameter(valid_600397, JString, required = false,
                                 default = nil)
  if valid_600397 != nil:
    section.add "X-Amz-Content-Sha256", valid_600397
  var valid_600398 = header.getOrDefault("X-Amz-Algorithm")
  valid_600398 = validateParameter(valid_600398, JString, required = false,
                                 default = nil)
  if valid_600398 != nil:
    section.add "X-Amz-Algorithm", valid_600398
  var valid_600399 = header.getOrDefault("X-Amz-Signature")
  valid_600399 = validateParameter(valid_600399, JString, required = false,
                                 default = nil)
  if valid_600399 != nil:
    section.add "X-Amz-Signature", valid_600399
  var valid_600400 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600400 = validateParameter(valid_600400, JString, required = false,
                                 default = nil)
  if valid_600400 != nil:
    section.add "X-Amz-SignedHeaders", valid_600400
  var valid_600401 = header.getOrDefault("X-Amz-Credential")
  valid_600401 = validateParameter(valid_600401, JString, required = false,
                                 default = nil)
  if valid_600401 != nil:
    section.add "X-Amz-Credential", valid_600401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600403: Call_UpdateMultiplexProgram_600390; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a program in a multiplex.
  ## 
  let valid = call_600403.validator(path, query, header, formData, body)
  let scheme = call_600403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600403.url(scheme.get, call_600403.host, call_600403.base,
                         call_600403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600403, url, valid)

proc call*(call_600404: Call_UpdateMultiplexProgram_600390; multiplexId: string;
          programName: string; body: JsonNode): Recallable =
  ## updateMultiplexProgram
  ## Update a program in a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   programName: string (required)
  ##              : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_600405 = newJObject()
  var body_600406 = newJObject()
  add(path_600405, "multiplexId", newJString(multiplexId))
  add(path_600405, "programName", newJString(programName))
  if body != nil:
    body_600406 = body
  result = call_600404.call(path_600405, nil, nil, nil, body_600406)

var updateMultiplexProgram* = Call_UpdateMultiplexProgram_600390(
    name: "updateMultiplexProgram", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs/{programName}",
    validator: validate_UpdateMultiplexProgram_600391, base: "/",
    url: url_UpdateMultiplexProgram_600392, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMultiplexProgram_600375 = ref object of OpenApiRestCall_599368
proc url_DescribeMultiplexProgram_600377(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeMultiplexProgram_600376(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600378 = path.getOrDefault("multiplexId")
  valid_600378 = validateParameter(valid_600378, JString, required = true,
                                 default = nil)
  if valid_600378 != nil:
    section.add "multiplexId", valid_600378
  var valid_600379 = path.getOrDefault("programName")
  valid_600379 = validateParameter(valid_600379, JString, required = true,
                                 default = nil)
  if valid_600379 != nil:
    section.add "programName", valid_600379
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
  var valid_600380 = header.getOrDefault("X-Amz-Date")
  valid_600380 = validateParameter(valid_600380, JString, required = false,
                                 default = nil)
  if valid_600380 != nil:
    section.add "X-Amz-Date", valid_600380
  var valid_600381 = header.getOrDefault("X-Amz-Security-Token")
  valid_600381 = validateParameter(valid_600381, JString, required = false,
                                 default = nil)
  if valid_600381 != nil:
    section.add "X-Amz-Security-Token", valid_600381
  var valid_600382 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600382 = validateParameter(valid_600382, JString, required = false,
                                 default = nil)
  if valid_600382 != nil:
    section.add "X-Amz-Content-Sha256", valid_600382
  var valid_600383 = header.getOrDefault("X-Amz-Algorithm")
  valid_600383 = validateParameter(valid_600383, JString, required = false,
                                 default = nil)
  if valid_600383 != nil:
    section.add "X-Amz-Algorithm", valid_600383
  var valid_600384 = header.getOrDefault("X-Amz-Signature")
  valid_600384 = validateParameter(valid_600384, JString, required = false,
                                 default = nil)
  if valid_600384 != nil:
    section.add "X-Amz-Signature", valid_600384
  var valid_600385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600385 = validateParameter(valid_600385, JString, required = false,
                                 default = nil)
  if valid_600385 != nil:
    section.add "X-Amz-SignedHeaders", valid_600385
  var valid_600386 = header.getOrDefault("X-Amz-Credential")
  valid_600386 = validateParameter(valid_600386, JString, required = false,
                                 default = nil)
  if valid_600386 != nil:
    section.add "X-Amz-Credential", valid_600386
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600387: Call_DescribeMultiplexProgram_600375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the details for a program in a multiplex.
  ## 
  let valid = call_600387.validator(path, query, header, formData, body)
  let scheme = call_600387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600387.url(scheme.get, call_600387.host, call_600387.base,
                         call_600387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600387, url, valid)

proc call*(call_600388: Call_DescribeMultiplexProgram_600375; multiplexId: string;
          programName: string): Recallable =
  ## describeMultiplexProgram
  ## Get the details for a program in a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   programName: string (required)
  ##              : Placeholder documentation for __string
  var path_600389 = newJObject()
  add(path_600389, "multiplexId", newJString(multiplexId))
  add(path_600389, "programName", newJString(programName))
  result = call_600388.call(path_600389, nil, nil, nil, nil)

var describeMultiplexProgram* = Call_DescribeMultiplexProgram_600375(
    name: "describeMultiplexProgram", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs/{programName}",
    validator: validate_DescribeMultiplexProgram_600376, base: "/",
    url: url_DescribeMultiplexProgram_600377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMultiplexProgram_600407 = ref object of OpenApiRestCall_599368
proc url_DeleteMultiplexProgram_600409(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMultiplexProgram_600408(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600410 = path.getOrDefault("multiplexId")
  valid_600410 = validateParameter(valid_600410, JString, required = true,
                                 default = nil)
  if valid_600410 != nil:
    section.add "multiplexId", valid_600410
  var valid_600411 = path.getOrDefault("programName")
  valid_600411 = validateParameter(valid_600411, JString, required = true,
                                 default = nil)
  if valid_600411 != nil:
    section.add "programName", valid_600411
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
  var valid_600412 = header.getOrDefault("X-Amz-Date")
  valid_600412 = validateParameter(valid_600412, JString, required = false,
                                 default = nil)
  if valid_600412 != nil:
    section.add "X-Amz-Date", valid_600412
  var valid_600413 = header.getOrDefault("X-Amz-Security-Token")
  valid_600413 = validateParameter(valid_600413, JString, required = false,
                                 default = nil)
  if valid_600413 != nil:
    section.add "X-Amz-Security-Token", valid_600413
  var valid_600414 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600414 = validateParameter(valid_600414, JString, required = false,
                                 default = nil)
  if valid_600414 != nil:
    section.add "X-Amz-Content-Sha256", valid_600414
  var valid_600415 = header.getOrDefault("X-Amz-Algorithm")
  valid_600415 = validateParameter(valid_600415, JString, required = false,
                                 default = nil)
  if valid_600415 != nil:
    section.add "X-Amz-Algorithm", valid_600415
  var valid_600416 = header.getOrDefault("X-Amz-Signature")
  valid_600416 = validateParameter(valid_600416, JString, required = false,
                                 default = nil)
  if valid_600416 != nil:
    section.add "X-Amz-Signature", valid_600416
  var valid_600417 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600417 = validateParameter(valid_600417, JString, required = false,
                                 default = nil)
  if valid_600417 != nil:
    section.add "X-Amz-SignedHeaders", valid_600417
  var valid_600418 = header.getOrDefault("X-Amz-Credential")
  valid_600418 = validateParameter(valid_600418, JString, required = false,
                                 default = nil)
  if valid_600418 != nil:
    section.add "X-Amz-Credential", valid_600418
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600419: Call_DeleteMultiplexProgram_600407; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a program from a multiplex.
  ## 
  let valid = call_600419.validator(path, query, header, formData, body)
  let scheme = call_600419.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600419.url(scheme.get, call_600419.host, call_600419.base,
                         call_600419.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600419, url, valid)

proc call*(call_600420: Call_DeleteMultiplexProgram_600407; multiplexId: string;
          programName: string): Recallable =
  ## deleteMultiplexProgram
  ## Delete a program from a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   programName: string (required)
  ##              : Placeholder documentation for __string
  var path_600421 = newJObject()
  add(path_600421, "multiplexId", newJString(multiplexId))
  add(path_600421, "programName", newJString(programName))
  result = call_600420.call(path_600421, nil, nil, nil, nil)

var deleteMultiplexProgram* = Call_DeleteMultiplexProgram_600407(
    name: "deleteMultiplexProgram", meth: HttpMethod.HttpDelete,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs/{programName}",
    validator: validate_DeleteMultiplexProgram_600408, base: "/",
    url: url_DeleteMultiplexProgram_600409, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReservation_600436 = ref object of OpenApiRestCall_599368
proc url_UpdateReservation_600438(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateReservation_600437(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_600439 = path.getOrDefault("reservationId")
  valid_600439 = validateParameter(valid_600439, JString, required = true,
                                 default = nil)
  if valid_600439 != nil:
    section.add "reservationId", valid_600439
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
  var valid_600440 = header.getOrDefault("X-Amz-Date")
  valid_600440 = validateParameter(valid_600440, JString, required = false,
                                 default = nil)
  if valid_600440 != nil:
    section.add "X-Amz-Date", valid_600440
  var valid_600441 = header.getOrDefault("X-Amz-Security-Token")
  valid_600441 = validateParameter(valid_600441, JString, required = false,
                                 default = nil)
  if valid_600441 != nil:
    section.add "X-Amz-Security-Token", valid_600441
  var valid_600442 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600442 = validateParameter(valid_600442, JString, required = false,
                                 default = nil)
  if valid_600442 != nil:
    section.add "X-Amz-Content-Sha256", valid_600442
  var valid_600443 = header.getOrDefault("X-Amz-Algorithm")
  valid_600443 = validateParameter(valid_600443, JString, required = false,
                                 default = nil)
  if valid_600443 != nil:
    section.add "X-Amz-Algorithm", valid_600443
  var valid_600444 = header.getOrDefault("X-Amz-Signature")
  valid_600444 = validateParameter(valid_600444, JString, required = false,
                                 default = nil)
  if valid_600444 != nil:
    section.add "X-Amz-Signature", valid_600444
  var valid_600445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600445 = validateParameter(valid_600445, JString, required = false,
                                 default = nil)
  if valid_600445 != nil:
    section.add "X-Amz-SignedHeaders", valid_600445
  var valid_600446 = header.getOrDefault("X-Amz-Credential")
  valid_600446 = validateParameter(valid_600446, JString, required = false,
                                 default = nil)
  if valid_600446 != nil:
    section.add "X-Amz-Credential", valid_600446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600448: Call_UpdateReservation_600436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update reservation.
  ## 
  let valid = call_600448.validator(path, query, header, formData, body)
  let scheme = call_600448.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600448.url(scheme.get, call_600448.host, call_600448.base,
                         call_600448.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600448, url, valid)

proc call*(call_600449: Call_UpdateReservation_600436; reservationId: string;
          body: JsonNode): Recallable =
  ## updateReservation
  ## Update reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_600450 = newJObject()
  var body_600451 = newJObject()
  add(path_600450, "reservationId", newJString(reservationId))
  if body != nil:
    body_600451 = body
  result = call_600449.call(path_600450, nil, nil, nil, body_600451)

var updateReservation* = Call_UpdateReservation_600436(name: "updateReservation",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_UpdateReservation_600437, base: "/",
    url: url_UpdateReservation_600438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservation_600422 = ref object of OpenApiRestCall_599368
proc url_DescribeReservation_600424(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeReservation_600423(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
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
  var valid_600425 = path.getOrDefault("reservationId")
  valid_600425 = validateParameter(valid_600425, JString, required = true,
                                 default = nil)
  if valid_600425 != nil:
    section.add "reservationId", valid_600425
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
  var valid_600426 = header.getOrDefault("X-Amz-Date")
  valid_600426 = validateParameter(valid_600426, JString, required = false,
                                 default = nil)
  if valid_600426 != nil:
    section.add "X-Amz-Date", valid_600426
  var valid_600427 = header.getOrDefault("X-Amz-Security-Token")
  valid_600427 = validateParameter(valid_600427, JString, required = false,
                                 default = nil)
  if valid_600427 != nil:
    section.add "X-Amz-Security-Token", valid_600427
  var valid_600428 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600428 = validateParameter(valid_600428, JString, required = false,
                                 default = nil)
  if valid_600428 != nil:
    section.add "X-Amz-Content-Sha256", valid_600428
  var valid_600429 = header.getOrDefault("X-Amz-Algorithm")
  valid_600429 = validateParameter(valid_600429, JString, required = false,
                                 default = nil)
  if valid_600429 != nil:
    section.add "X-Amz-Algorithm", valid_600429
  var valid_600430 = header.getOrDefault("X-Amz-Signature")
  valid_600430 = validateParameter(valid_600430, JString, required = false,
                                 default = nil)
  if valid_600430 != nil:
    section.add "X-Amz-Signature", valid_600430
  var valid_600431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600431 = validateParameter(valid_600431, JString, required = false,
                                 default = nil)
  if valid_600431 != nil:
    section.add "X-Amz-SignedHeaders", valid_600431
  var valid_600432 = header.getOrDefault("X-Amz-Credential")
  valid_600432 = validateParameter(valid_600432, JString, required = false,
                                 default = nil)
  if valid_600432 != nil:
    section.add "X-Amz-Credential", valid_600432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600433: Call_DescribeReservation_600422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details for a reservation.
  ## 
  let valid = call_600433.validator(path, query, header, formData, body)
  let scheme = call_600433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600433.url(scheme.get, call_600433.host, call_600433.base,
                         call_600433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600433, url, valid)

proc call*(call_600434: Call_DescribeReservation_600422; reservationId: string): Recallable =
  ## describeReservation
  ## Get details for a reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_600435 = newJObject()
  add(path_600435, "reservationId", newJString(reservationId))
  result = call_600434.call(path_600435, nil, nil, nil, nil)

var describeReservation* = Call_DescribeReservation_600422(
    name: "describeReservation", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/reservations/{reservationId}",
    validator: validate_DescribeReservation_600423, base: "/",
    url: url_DescribeReservation_600424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReservation_600452 = ref object of OpenApiRestCall_599368
proc url_DeleteReservation_600454(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteReservation_600453(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode): JsonNode =
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
  var valid_600455 = path.getOrDefault("reservationId")
  valid_600455 = validateParameter(valid_600455, JString, required = true,
                                 default = nil)
  if valid_600455 != nil:
    section.add "reservationId", valid_600455
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
  var valid_600456 = header.getOrDefault("X-Amz-Date")
  valid_600456 = validateParameter(valid_600456, JString, required = false,
                                 default = nil)
  if valid_600456 != nil:
    section.add "X-Amz-Date", valid_600456
  var valid_600457 = header.getOrDefault("X-Amz-Security-Token")
  valid_600457 = validateParameter(valid_600457, JString, required = false,
                                 default = nil)
  if valid_600457 != nil:
    section.add "X-Amz-Security-Token", valid_600457
  var valid_600458 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600458 = validateParameter(valid_600458, JString, required = false,
                                 default = nil)
  if valid_600458 != nil:
    section.add "X-Amz-Content-Sha256", valid_600458
  var valid_600459 = header.getOrDefault("X-Amz-Algorithm")
  valid_600459 = validateParameter(valid_600459, JString, required = false,
                                 default = nil)
  if valid_600459 != nil:
    section.add "X-Amz-Algorithm", valid_600459
  var valid_600460 = header.getOrDefault("X-Amz-Signature")
  valid_600460 = validateParameter(valid_600460, JString, required = false,
                                 default = nil)
  if valid_600460 != nil:
    section.add "X-Amz-Signature", valid_600460
  var valid_600461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600461 = validateParameter(valid_600461, JString, required = false,
                                 default = nil)
  if valid_600461 != nil:
    section.add "X-Amz-SignedHeaders", valid_600461
  var valid_600462 = header.getOrDefault("X-Amz-Credential")
  valid_600462 = validateParameter(valid_600462, JString, required = false,
                                 default = nil)
  if valid_600462 != nil:
    section.add "X-Amz-Credential", valid_600462
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600463: Call_DeleteReservation_600452; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete an expired reservation.
  ## 
  let valid = call_600463.validator(path, query, header, formData, body)
  let scheme = call_600463.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600463.url(scheme.get, call_600463.host, call_600463.base,
                         call_600463.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600463, url, valid)

proc call*(call_600464: Call_DeleteReservation_600452; reservationId: string): Recallable =
  ## deleteReservation
  ## Delete an expired reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_600465 = newJObject()
  add(path_600465, "reservationId", newJString(reservationId))
  result = call_600464.call(path_600465, nil, nil, nil, nil)

var deleteReservation* = Call_DeleteReservation_600452(name: "deleteReservation",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_DeleteReservation_600453, base: "/",
    url: url_DeleteReservation_600454, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_600466 = ref object of OpenApiRestCall_599368
proc url_DeleteTags_600468(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTags_600467(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600469 = path.getOrDefault("resource-arn")
  valid_600469 = validateParameter(valid_600469, JString, required = true,
                                 default = nil)
  if valid_600469 != nil:
    section.add "resource-arn", valid_600469
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : Placeholder documentation for __listOf__string
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_600470 = query.getOrDefault("tagKeys")
  valid_600470 = validateParameter(valid_600470, JArray, required = true, default = nil)
  if valid_600470 != nil:
    section.add "tagKeys", valid_600470
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
  var valid_600471 = header.getOrDefault("X-Amz-Date")
  valid_600471 = validateParameter(valid_600471, JString, required = false,
                                 default = nil)
  if valid_600471 != nil:
    section.add "X-Amz-Date", valid_600471
  var valid_600472 = header.getOrDefault("X-Amz-Security-Token")
  valid_600472 = validateParameter(valid_600472, JString, required = false,
                                 default = nil)
  if valid_600472 != nil:
    section.add "X-Amz-Security-Token", valid_600472
  var valid_600473 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600473 = validateParameter(valid_600473, JString, required = false,
                                 default = nil)
  if valid_600473 != nil:
    section.add "X-Amz-Content-Sha256", valid_600473
  var valid_600474 = header.getOrDefault("X-Amz-Algorithm")
  valid_600474 = validateParameter(valid_600474, JString, required = false,
                                 default = nil)
  if valid_600474 != nil:
    section.add "X-Amz-Algorithm", valid_600474
  var valid_600475 = header.getOrDefault("X-Amz-Signature")
  valid_600475 = validateParameter(valid_600475, JString, required = false,
                                 default = nil)
  if valid_600475 != nil:
    section.add "X-Amz-Signature", valid_600475
  var valid_600476 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600476 = validateParameter(valid_600476, JString, required = false,
                                 default = nil)
  if valid_600476 != nil:
    section.add "X-Amz-SignedHeaders", valid_600476
  var valid_600477 = header.getOrDefault("X-Amz-Credential")
  valid_600477 = validateParameter(valid_600477, JString, required = false,
                                 default = nil)
  if valid_600477 != nil:
    section.add "X-Amz-Credential", valid_600477
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600478: Call_DeleteTags_600466; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags for a resource
  ## 
  let valid = call_600478.validator(path, query, header, formData, body)
  let scheme = call_600478.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600478.url(scheme.get, call_600478.host, call_600478.base,
                         call_600478.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600478, url, valid)

proc call*(call_600479: Call_DeleteTags_600466; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## deleteTags
  ## Removes tags for a resource
  ##   tagKeys: JArray (required)
  ##          : Placeholder documentation for __listOf__string
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  var path_600480 = newJObject()
  var query_600481 = newJObject()
  if tagKeys != nil:
    query_600481.add "tagKeys", tagKeys
  add(path_600480, "resource-arn", newJString(resourceArn))
  result = call_600479.call(path_600480, query_600481, nil, nil, nil)

var deleteTags* = Call_DeleteTags_600466(name: "deleteTags",
                                      meth: HttpMethod.HttpDelete,
                                      host: "medialive.amazonaws.com", route: "/prod/tags/{resource-arn}#tagKeys",
                                      validator: validate_DeleteTags_600467,
                                      base: "/", url: url_DeleteTags_600468,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOffering_600482 = ref object of OpenApiRestCall_599368
proc url_DescribeOffering_600484(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeOffering_600483(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_600485 = path.getOrDefault("offeringId")
  valid_600485 = validateParameter(valid_600485, JString, required = true,
                                 default = nil)
  if valid_600485 != nil:
    section.add "offeringId", valid_600485
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
  var valid_600486 = header.getOrDefault("X-Amz-Date")
  valid_600486 = validateParameter(valid_600486, JString, required = false,
                                 default = nil)
  if valid_600486 != nil:
    section.add "X-Amz-Date", valid_600486
  var valid_600487 = header.getOrDefault("X-Amz-Security-Token")
  valid_600487 = validateParameter(valid_600487, JString, required = false,
                                 default = nil)
  if valid_600487 != nil:
    section.add "X-Amz-Security-Token", valid_600487
  var valid_600488 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600488 = validateParameter(valid_600488, JString, required = false,
                                 default = nil)
  if valid_600488 != nil:
    section.add "X-Amz-Content-Sha256", valid_600488
  var valid_600489 = header.getOrDefault("X-Amz-Algorithm")
  valid_600489 = validateParameter(valid_600489, JString, required = false,
                                 default = nil)
  if valid_600489 != nil:
    section.add "X-Amz-Algorithm", valid_600489
  var valid_600490 = header.getOrDefault("X-Amz-Signature")
  valid_600490 = validateParameter(valid_600490, JString, required = false,
                                 default = nil)
  if valid_600490 != nil:
    section.add "X-Amz-Signature", valid_600490
  var valid_600491 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600491 = validateParameter(valid_600491, JString, required = false,
                                 default = nil)
  if valid_600491 != nil:
    section.add "X-Amz-SignedHeaders", valid_600491
  var valid_600492 = header.getOrDefault("X-Amz-Credential")
  valid_600492 = validateParameter(valid_600492, JString, required = false,
                                 default = nil)
  if valid_600492 != nil:
    section.add "X-Amz-Credential", valid_600492
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600493: Call_DescribeOffering_600482; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details for an offering.
  ## 
  let valid = call_600493.validator(path, query, header, formData, body)
  let scheme = call_600493.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600493.url(scheme.get, call_600493.host, call_600493.base,
                         call_600493.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600493, url, valid)

proc call*(call_600494: Call_DescribeOffering_600482; offeringId: string): Recallable =
  ## describeOffering
  ## Get details for an offering.
  ##   offeringId: string (required)
  ##             : Placeholder documentation for __string
  var path_600495 = newJObject()
  add(path_600495, "offeringId", newJString(offeringId))
  result = call_600494.call(path_600495, nil, nil, nil, nil)

var describeOffering* = Call_DescribeOffering_600482(name: "describeOffering",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/offerings/{offeringId}", validator: validate_DescribeOffering_600483,
    base: "/", url: url_DescribeOffering_600484,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_600496 = ref object of OpenApiRestCall_599368
proc url_ListOfferings_600498(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferings_600497(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600499 = query.getOrDefault("codec")
  valid_600499 = validateParameter(valid_600499, JString, required = false,
                                 default = nil)
  if valid_600499 != nil:
    section.add "codec", valid_600499
  var valid_600500 = query.getOrDefault("duration")
  valid_600500 = validateParameter(valid_600500, JString, required = false,
                                 default = nil)
  if valid_600500 != nil:
    section.add "duration", valid_600500
  var valid_600501 = query.getOrDefault("channelClass")
  valid_600501 = validateParameter(valid_600501, JString, required = false,
                                 default = nil)
  if valid_600501 != nil:
    section.add "channelClass", valid_600501
  var valid_600502 = query.getOrDefault("channelConfiguration")
  valid_600502 = validateParameter(valid_600502, JString, required = false,
                                 default = nil)
  if valid_600502 != nil:
    section.add "channelConfiguration", valid_600502
  var valid_600503 = query.getOrDefault("resolution")
  valid_600503 = validateParameter(valid_600503, JString, required = false,
                                 default = nil)
  if valid_600503 != nil:
    section.add "resolution", valid_600503
  var valid_600504 = query.getOrDefault("maximumFramerate")
  valid_600504 = validateParameter(valid_600504, JString, required = false,
                                 default = nil)
  if valid_600504 != nil:
    section.add "maximumFramerate", valid_600504
  var valid_600505 = query.getOrDefault("NextToken")
  valid_600505 = validateParameter(valid_600505, JString, required = false,
                                 default = nil)
  if valid_600505 != nil:
    section.add "NextToken", valid_600505
  var valid_600506 = query.getOrDefault("maxResults")
  valid_600506 = validateParameter(valid_600506, JInt, required = false, default = nil)
  if valid_600506 != nil:
    section.add "maxResults", valid_600506
  var valid_600507 = query.getOrDefault("nextToken")
  valid_600507 = validateParameter(valid_600507, JString, required = false,
                                 default = nil)
  if valid_600507 != nil:
    section.add "nextToken", valid_600507
  var valid_600508 = query.getOrDefault("videoQuality")
  valid_600508 = validateParameter(valid_600508, JString, required = false,
                                 default = nil)
  if valid_600508 != nil:
    section.add "videoQuality", valid_600508
  var valid_600509 = query.getOrDefault("maximumBitrate")
  valid_600509 = validateParameter(valid_600509, JString, required = false,
                                 default = nil)
  if valid_600509 != nil:
    section.add "maximumBitrate", valid_600509
  var valid_600510 = query.getOrDefault("specialFeature")
  valid_600510 = validateParameter(valid_600510, JString, required = false,
                                 default = nil)
  if valid_600510 != nil:
    section.add "specialFeature", valid_600510
  var valid_600511 = query.getOrDefault("resourceType")
  valid_600511 = validateParameter(valid_600511, JString, required = false,
                                 default = nil)
  if valid_600511 != nil:
    section.add "resourceType", valid_600511
  var valid_600512 = query.getOrDefault("MaxResults")
  valid_600512 = validateParameter(valid_600512, JString, required = false,
                                 default = nil)
  if valid_600512 != nil:
    section.add "MaxResults", valid_600512
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
  var valid_600513 = header.getOrDefault("X-Amz-Date")
  valid_600513 = validateParameter(valid_600513, JString, required = false,
                                 default = nil)
  if valid_600513 != nil:
    section.add "X-Amz-Date", valid_600513
  var valid_600514 = header.getOrDefault("X-Amz-Security-Token")
  valid_600514 = validateParameter(valid_600514, JString, required = false,
                                 default = nil)
  if valid_600514 != nil:
    section.add "X-Amz-Security-Token", valid_600514
  var valid_600515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600515 = validateParameter(valid_600515, JString, required = false,
                                 default = nil)
  if valid_600515 != nil:
    section.add "X-Amz-Content-Sha256", valid_600515
  var valid_600516 = header.getOrDefault("X-Amz-Algorithm")
  valid_600516 = validateParameter(valid_600516, JString, required = false,
                                 default = nil)
  if valid_600516 != nil:
    section.add "X-Amz-Algorithm", valid_600516
  var valid_600517 = header.getOrDefault("X-Amz-Signature")
  valid_600517 = validateParameter(valid_600517, JString, required = false,
                                 default = nil)
  if valid_600517 != nil:
    section.add "X-Amz-Signature", valid_600517
  var valid_600518 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600518 = validateParameter(valid_600518, JString, required = false,
                                 default = nil)
  if valid_600518 != nil:
    section.add "X-Amz-SignedHeaders", valid_600518
  var valid_600519 = header.getOrDefault("X-Amz-Credential")
  valid_600519 = validateParameter(valid_600519, JString, required = false,
                                 default = nil)
  if valid_600519 != nil:
    section.add "X-Amz-Credential", valid_600519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600520: Call_ListOfferings_600496; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List offerings available for purchase.
  ## 
  let valid = call_600520.validator(path, query, header, formData, body)
  let scheme = call_600520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600520.url(scheme.get, call_600520.host, call_600520.base,
                         call_600520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600520, url, valid)

proc call*(call_600521: Call_ListOfferings_600496; codec: string = "";
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
  var query_600522 = newJObject()
  add(query_600522, "codec", newJString(codec))
  add(query_600522, "duration", newJString(duration))
  add(query_600522, "channelClass", newJString(channelClass))
  add(query_600522, "channelConfiguration", newJString(channelConfiguration))
  add(query_600522, "resolution", newJString(resolution))
  add(query_600522, "maximumFramerate", newJString(maximumFramerate))
  add(query_600522, "NextToken", newJString(NextToken))
  add(query_600522, "maxResults", newJInt(maxResults))
  add(query_600522, "nextToken", newJString(nextToken))
  add(query_600522, "videoQuality", newJString(videoQuality))
  add(query_600522, "maximumBitrate", newJString(maximumBitrate))
  add(query_600522, "specialFeature", newJString(specialFeature))
  add(query_600522, "resourceType", newJString(resourceType))
  add(query_600522, "MaxResults", newJString(MaxResults))
  result = call_600521.call(nil, query_600522, nil, nil, nil)

var listOfferings* = Call_ListOfferings_600496(name: "listOfferings",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/offerings", validator: validate_ListOfferings_600497, base: "/",
    url: url_ListOfferings_600498, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReservations_600523 = ref object of OpenApiRestCall_599368
proc url_ListReservations_600525(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListReservations_600524(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_600526 = query.getOrDefault("codec")
  valid_600526 = validateParameter(valid_600526, JString, required = false,
                                 default = nil)
  if valid_600526 != nil:
    section.add "codec", valid_600526
  var valid_600527 = query.getOrDefault("channelClass")
  valid_600527 = validateParameter(valid_600527, JString, required = false,
                                 default = nil)
  if valid_600527 != nil:
    section.add "channelClass", valid_600527
  var valid_600528 = query.getOrDefault("resolution")
  valid_600528 = validateParameter(valid_600528, JString, required = false,
                                 default = nil)
  if valid_600528 != nil:
    section.add "resolution", valid_600528
  var valid_600529 = query.getOrDefault("maximumFramerate")
  valid_600529 = validateParameter(valid_600529, JString, required = false,
                                 default = nil)
  if valid_600529 != nil:
    section.add "maximumFramerate", valid_600529
  var valid_600530 = query.getOrDefault("NextToken")
  valid_600530 = validateParameter(valid_600530, JString, required = false,
                                 default = nil)
  if valid_600530 != nil:
    section.add "NextToken", valid_600530
  var valid_600531 = query.getOrDefault("maxResults")
  valid_600531 = validateParameter(valid_600531, JInt, required = false, default = nil)
  if valid_600531 != nil:
    section.add "maxResults", valid_600531
  var valid_600532 = query.getOrDefault("nextToken")
  valid_600532 = validateParameter(valid_600532, JString, required = false,
                                 default = nil)
  if valid_600532 != nil:
    section.add "nextToken", valid_600532
  var valid_600533 = query.getOrDefault("videoQuality")
  valid_600533 = validateParameter(valid_600533, JString, required = false,
                                 default = nil)
  if valid_600533 != nil:
    section.add "videoQuality", valid_600533
  var valid_600534 = query.getOrDefault("maximumBitrate")
  valid_600534 = validateParameter(valid_600534, JString, required = false,
                                 default = nil)
  if valid_600534 != nil:
    section.add "maximumBitrate", valid_600534
  var valid_600535 = query.getOrDefault("specialFeature")
  valid_600535 = validateParameter(valid_600535, JString, required = false,
                                 default = nil)
  if valid_600535 != nil:
    section.add "specialFeature", valid_600535
  var valid_600536 = query.getOrDefault("resourceType")
  valid_600536 = validateParameter(valid_600536, JString, required = false,
                                 default = nil)
  if valid_600536 != nil:
    section.add "resourceType", valid_600536
  var valid_600537 = query.getOrDefault("MaxResults")
  valid_600537 = validateParameter(valid_600537, JString, required = false,
                                 default = nil)
  if valid_600537 != nil:
    section.add "MaxResults", valid_600537
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
  var valid_600538 = header.getOrDefault("X-Amz-Date")
  valid_600538 = validateParameter(valid_600538, JString, required = false,
                                 default = nil)
  if valid_600538 != nil:
    section.add "X-Amz-Date", valid_600538
  var valid_600539 = header.getOrDefault("X-Amz-Security-Token")
  valid_600539 = validateParameter(valid_600539, JString, required = false,
                                 default = nil)
  if valid_600539 != nil:
    section.add "X-Amz-Security-Token", valid_600539
  var valid_600540 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600540 = validateParameter(valid_600540, JString, required = false,
                                 default = nil)
  if valid_600540 != nil:
    section.add "X-Amz-Content-Sha256", valid_600540
  var valid_600541 = header.getOrDefault("X-Amz-Algorithm")
  valid_600541 = validateParameter(valid_600541, JString, required = false,
                                 default = nil)
  if valid_600541 != nil:
    section.add "X-Amz-Algorithm", valid_600541
  var valid_600542 = header.getOrDefault("X-Amz-Signature")
  valid_600542 = validateParameter(valid_600542, JString, required = false,
                                 default = nil)
  if valid_600542 != nil:
    section.add "X-Amz-Signature", valid_600542
  var valid_600543 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600543 = validateParameter(valid_600543, JString, required = false,
                                 default = nil)
  if valid_600543 != nil:
    section.add "X-Amz-SignedHeaders", valid_600543
  var valid_600544 = header.getOrDefault("X-Amz-Credential")
  valid_600544 = validateParameter(valid_600544, JString, required = false,
                                 default = nil)
  if valid_600544 != nil:
    section.add "X-Amz-Credential", valid_600544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600545: Call_ListReservations_600523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List purchased reservations.
  ## 
  let valid = call_600545.validator(path, query, header, formData, body)
  let scheme = call_600545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600545.url(scheme.get, call_600545.host, call_600545.base,
                         call_600545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600545, url, valid)

proc call*(call_600546: Call_ListReservations_600523; codec: string = "";
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
  var query_600547 = newJObject()
  add(query_600547, "codec", newJString(codec))
  add(query_600547, "channelClass", newJString(channelClass))
  add(query_600547, "resolution", newJString(resolution))
  add(query_600547, "maximumFramerate", newJString(maximumFramerate))
  add(query_600547, "NextToken", newJString(NextToken))
  add(query_600547, "maxResults", newJInt(maxResults))
  add(query_600547, "nextToken", newJString(nextToken))
  add(query_600547, "videoQuality", newJString(videoQuality))
  add(query_600547, "maximumBitrate", newJString(maximumBitrate))
  add(query_600547, "specialFeature", newJString(specialFeature))
  add(query_600547, "resourceType", newJString(resourceType))
  add(query_600547, "MaxResults", newJString(MaxResults))
  result = call_600546.call(nil, query_600547, nil, nil, nil)

var listReservations* = Call_ListReservations_600523(name: "listReservations",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/reservations", validator: validate_ListReservations_600524,
    base: "/", url: url_ListReservations_600525,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_600548 = ref object of OpenApiRestCall_599368
proc url_PurchaseOffering_600550(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_PurchaseOffering_600549(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
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
  var valid_600551 = path.getOrDefault("offeringId")
  valid_600551 = validateParameter(valid_600551, JString, required = true,
                                 default = nil)
  if valid_600551 != nil:
    section.add "offeringId", valid_600551
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
  var valid_600552 = header.getOrDefault("X-Amz-Date")
  valid_600552 = validateParameter(valid_600552, JString, required = false,
                                 default = nil)
  if valid_600552 != nil:
    section.add "X-Amz-Date", valid_600552
  var valid_600553 = header.getOrDefault("X-Amz-Security-Token")
  valid_600553 = validateParameter(valid_600553, JString, required = false,
                                 default = nil)
  if valid_600553 != nil:
    section.add "X-Amz-Security-Token", valid_600553
  var valid_600554 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600554 = validateParameter(valid_600554, JString, required = false,
                                 default = nil)
  if valid_600554 != nil:
    section.add "X-Amz-Content-Sha256", valid_600554
  var valid_600555 = header.getOrDefault("X-Amz-Algorithm")
  valid_600555 = validateParameter(valid_600555, JString, required = false,
                                 default = nil)
  if valid_600555 != nil:
    section.add "X-Amz-Algorithm", valid_600555
  var valid_600556 = header.getOrDefault("X-Amz-Signature")
  valid_600556 = validateParameter(valid_600556, JString, required = false,
                                 default = nil)
  if valid_600556 != nil:
    section.add "X-Amz-Signature", valid_600556
  var valid_600557 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600557 = validateParameter(valid_600557, JString, required = false,
                                 default = nil)
  if valid_600557 != nil:
    section.add "X-Amz-SignedHeaders", valid_600557
  var valid_600558 = header.getOrDefault("X-Amz-Credential")
  valid_600558 = validateParameter(valid_600558, JString, required = false,
                                 default = nil)
  if valid_600558 != nil:
    section.add "X-Amz-Credential", valid_600558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600560: Call_PurchaseOffering_600548; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Purchase an offering and create a reservation.
  ## 
  let valid = call_600560.validator(path, query, header, formData, body)
  let scheme = call_600560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600560.url(scheme.get, call_600560.host, call_600560.base,
                         call_600560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600560, url, valid)

proc call*(call_600561: Call_PurchaseOffering_600548; offeringId: string;
          body: JsonNode): Recallable =
  ## purchaseOffering
  ## Purchase an offering and create a reservation.
  ##   offeringId: string (required)
  ##             : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_600562 = newJObject()
  var body_600563 = newJObject()
  add(path_600562, "offeringId", newJString(offeringId))
  if body != nil:
    body_600563 = body
  result = call_600561.call(path_600562, nil, nil, nil, body_600563)

var purchaseOffering* = Call_PurchaseOffering_600548(name: "purchaseOffering",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/offerings/{offeringId}/purchase",
    validator: validate_PurchaseOffering_600549, base: "/",
    url: url_PurchaseOffering_600550, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChannel_600564 = ref object of OpenApiRestCall_599368
proc url_StartChannel_600566(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartChannel_600565(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Starts an existing channel
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_600567 = path.getOrDefault("channelId")
  valid_600567 = validateParameter(valid_600567, JString, required = true,
                                 default = nil)
  if valid_600567 != nil:
    section.add "channelId", valid_600567
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
  var valid_600568 = header.getOrDefault("X-Amz-Date")
  valid_600568 = validateParameter(valid_600568, JString, required = false,
                                 default = nil)
  if valid_600568 != nil:
    section.add "X-Amz-Date", valid_600568
  var valid_600569 = header.getOrDefault("X-Amz-Security-Token")
  valid_600569 = validateParameter(valid_600569, JString, required = false,
                                 default = nil)
  if valid_600569 != nil:
    section.add "X-Amz-Security-Token", valid_600569
  var valid_600570 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600570 = validateParameter(valid_600570, JString, required = false,
                                 default = nil)
  if valid_600570 != nil:
    section.add "X-Amz-Content-Sha256", valid_600570
  var valid_600571 = header.getOrDefault("X-Amz-Algorithm")
  valid_600571 = validateParameter(valid_600571, JString, required = false,
                                 default = nil)
  if valid_600571 != nil:
    section.add "X-Amz-Algorithm", valid_600571
  var valid_600572 = header.getOrDefault("X-Amz-Signature")
  valid_600572 = validateParameter(valid_600572, JString, required = false,
                                 default = nil)
  if valid_600572 != nil:
    section.add "X-Amz-Signature", valid_600572
  var valid_600573 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600573 = validateParameter(valid_600573, JString, required = false,
                                 default = nil)
  if valid_600573 != nil:
    section.add "X-Amz-SignedHeaders", valid_600573
  var valid_600574 = header.getOrDefault("X-Amz-Credential")
  valid_600574 = validateParameter(valid_600574, JString, required = false,
                                 default = nil)
  if valid_600574 != nil:
    section.add "X-Amz-Credential", valid_600574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600575: Call_StartChannel_600564; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an existing channel
  ## 
  let valid = call_600575.validator(path, query, header, formData, body)
  let scheme = call_600575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600575.url(scheme.get, call_600575.host, call_600575.base,
                         call_600575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600575, url, valid)

proc call*(call_600576: Call_StartChannel_600564; channelId: string): Recallable =
  ## startChannel
  ## Starts an existing channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_600577 = newJObject()
  add(path_600577, "channelId", newJString(channelId))
  result = call_600576.call(path_600577, nil, nil, nil, nil)

var startChannel* = Call_StartChannel_600564(name: "startChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/start", validator: validate_StartChannel_600565,
    base: "/", url: url_StartChannel_600566, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMultiplex_600578 = ref object of OpenApiRestCall_599368
proc url_StartMultiplex_600580(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StartMultiplex_600579(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode): JsonNode =
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
  var valid_600581 = path.getOrDefault("multiplexId")
  valid_600581 = validateParameter(valid_600581, JString, required = true,
                                 default = nil)
  if valid_600581 != nil:
    section.add "multiplexId", valid_600581
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
  var valid_600582 = header.getOrDefault("X-Amz-Date")
  valid_600582 = validateParameter(valid_600582, JString, required = false,
                                 default = nil)
  if valid_600582 != nil:
    section.add "X-Amz-Date", valid_600582
  var valid_600583 = header.getOrDefault("X-Amz-Security-Token")
  valid_600583 = validateParameter(valid_600583, JString, required = false,
                                 default = nil)
  if valid_600583 != nil:
    section.add "X-Amz-Security-Token", valid_600583
  var valid_600584 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600584 = validateParameter(valid_600584, JString, required = false,
                                 default = nil)
  if valid_600584 != nil:
    section.add "X-Amz-Content-Sha256", valid_600584
  var valid_600585 = header.getOrDefault("X-Amz-Algorithm")
  valid_600585 = validateParameter(valid_600585, JString, required = false,
                                 default = nil)
  if valid_600585 != nil:
    section.add "X-Amz-Algorithm", valid_600585
  var valid_600586 = header.getOrDefault("X-Amz-Signature")
  valid_600586 = validateParameter(valid_600586, JString, required = false,
                                 default = nil)
  if valid_600586 != nil:
    section.add "X-Amz-Signature", valid_600586
  var valid_600587 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600587 = validateParameter(valid_600587, JString, required = false,
                                 default = nil)
  if valid_600587 != nil:
    section.add "X-Amz-SignedHeaders", valid_600587
  var valid_600588 = header.getOrDefault("X-Amz-Credential")
  valid_600588 = validateParameter(valid_600588, JString, required = false,
                                 default = nil)
  if valid_600588 != nil:
    section.add "X-Amz-Credential", valid_600588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600589: Call_StartMultiplex_600578; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Start (run) the multiplex. Starting the multiplex does not start the channels. You must explicitly start each channel.
  ## 
  let valid = call_600589.validator(path, query, header, formData, body)
  let scheme = call_600589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600589.url(scheme.get, call_600589.host, call_600589.base,
                         call_600589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600589, url, valid)

proc call*(call_600590: Call_StartMultiplex_600578; multiplexId: string): Recallable =
  ## startMultiplex
  ## Start (run) the multiplex. Starting the multiplex does not start the channels. You must explicitly start each channel.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_600591 = newJObject()
  add(path_600591, "multiplexId", newJString(multiplexId))
  result = call_600590.call(path_600591, nil, nil, nil, nil)

var startMultiplex* = Call_StartMultiplex_600578(name: "startMultiplex",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/start",
    validator: validate_StartMultiplex_600579, base: "/", url: url_StartMultiplex_600580,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopChannel_600592 = ref object of OpenApiRestCall_599368
proc url_StopChannel_600594(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopChannel_600593(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  ## Stops a running channel
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_600595 = path.getOrDefault("channelId")
  valid_600595 = validateParameter(valid_600595, JString, required = true,
                                 default = nil)
  if valid_600595 != nil:
    section.add "channelId", valid_600595
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
  var valid_600596 = header.getOrDefault("X-Amz-Date")
  valid_600596 = validateParameter(valid_600596, JString, required = false,
                                 default = nil)
  if valid_600596 != nil:
    section.add "X-Amz-Date", valid_600596
  var valid_600597 = header.getOrDefault("X-Amz-Security-Token")
  valid_600597 = validateParameter(valid_600597, JString, required = false,
                                 default = nil)
  if valid_600597 != nil:
    section.add "X-Amz-Security-Token", valid_600597
  var valid_600598 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600598 = validateParameter(valid_600598, JString, required = false,
                                 default = nil)
  if valid_600598 != nil:
    section.add "X-Amz-Content-Sha256", valid_600598
  var valid_600599 = header.getOrDefault("X-Amz-Algorithm")
  valid_600599 = validateParameter(valid_600599, JString, required = false,
                                 default = nil)
  if valid_600599 != nil:
    section.add "X-Amz-Algorithm", valid_600599
  var valid_600600 = header.getOrDefault("X-Amz-Signature")
  valid_600600 = validateParameter(valid_600600, JString, required = false,
                                 default = nil)
  if valid_600600 != nil:
    section.add "X-Amz-Signature", valid_600600
  var valid_600601 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600601 = validateParameter(valid_600601, JString, required = false,
                                 default = nil)
  if valid_600601 != nil:
    section.add "X-Amz-SignedHeaders", valid_600601
  var valid_600602 = header.getOrDefault("X-Amz-Credential")
  valid_600602 = validateParameter(valid_600602, JString, required = false,
                                 default = nil)
  if valid_600602 != nil:
    section.add "X-Amz-Credential", valid_600602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600603: Call_StopChannel_600592; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running channel
  ## 
  let valid = call_600603.validator(path, query, header, formData, body)
  let scheme = call_600603.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600603.url(scheme.get, call_600603.host, call_600603.base,
                         call_600603.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600603, url, valid)

proc call*(call_600604: Call_StopChannel_600592; channelId: string): Recallable =
  ## stopChannel
  ## Stops a running channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_600605 = newJObject()
  add(path_600605, "channelId", newJString(channelId))
  result = call_600604.call(path_600605, nil, nil, nil, nil)

var stopChannel* = Call_StopChannel_600592(name: "stopChannel",
                                        meth: HttpMethod.HttpPost,
                                        host: "medialive.amazonaws.com", route: "/prod/channels/{channelId}/stop",
                                        validator: validate_StopChannel_600593,
                                        base: "/", url: url_StopChannel_600594,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMultiplex_600606 = ref object of OpenApiRestCall_599368
proc url_StopMultiplex_600608(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_StopMultiplex_600607(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
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
  var valid_600609 = path.getOrDefault("multiplexId")
  valid_600609 = validateParameter(valid_600609, JString, required = true,
                                 default = nil)
  if valid_600609 != nil:
    section.add "multiplexId", valid_600609
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
  var valid_600610 = header.getOrDefault("X-Amz-Date")
  valid_600610 = validateParameter(valid_600610, JString, required = false,
                                 default = nil)
  if valid_600610 != nil:
    section.add "X-Amz-Date", valid_600610
  var valid_600611 = header.getOrDefault("X-Amz-Security-Token")
  valid_600611 = validateParameter(valid_600611, JString, required = false,
                                 default = nil)
  if valid_600611 != nil:
    section.add "X-Amz-Security-Token", valid_600611
  var valid_600612 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600612 = validateParameter(valid_600612, JString, required = false,
                                 default = nil)
  if valid_600612 != nil:
    section.add "X-Amz-Content-Sha256", valid_600612
  var valid_600613 = header.getOrDefault("X-Amz-Algorithm")
  valid_600613 = validateParameter(valid_600613, JString, required = false,
                                 default = nil)
  if valid_600613 != nil:
    section.add "X-Amz-Algorithm", valid_600613
  var valid_600614 = header.getOrDefault("X-Amz-Signature")
  valid_600614 = validateParameter(valid_600614, JString, required = false,
                                 default = nil)
  if valid_600614 != nil:
    section.add "X-Amz-Signature", valid_600614
  var valid_600615 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600615 = validateParameter(valid_600615, JString, required = false,
                                 default = nil)
  if valid_600615 != nil:
    section.add "X-Amz-SignedHeaders", valid_600615
  var valid_600616 = header.getOrDefault("X-Amz-Credential")
  valid_600616 = validateParameter(valid_600616, JString, required = false,
                                 default = nil)
  if valid_600616 != nil:
    section.add "X-Amz-Credential", valid_600616
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_600617: Call_StopMultiplex_600606; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running multiplex. If the multiplex isn't running, this action has no effect.
  ## 
  let valid = call_600617.validator(path, query, header, formData, body)
  let scheme = call_600617.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600617.url(scheme.get, call_600617.host, call_600617.base,
                         call_600617.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600617, url, valid)

proc call*(call_600618: Call_StopMultiplex_600606; multiplexId: string): Recallable =
  ## stopMultiplex
  ## Stops a running multiplex. If the multiplex isn't running, this action has no effect.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_600619 = newJObject()
  add(path_600619, "multiplexId", newJString(multiplexId))
  result = call_600618.call(path_600619, nil, nil, nil, nil)

var stopMultiplex* = Call_StopMultiplex_600606(name: "stopMultiplex",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/stop",
    validator: validate_StopMultiplex_600607, base: "/", url: url_StopMultiplex_600608,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannelClass_600620 = ref object of OpenApiRestCall_599368
proc url_UpdateChannelClass_600622(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateChannelClass_600621(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Changes the class of the channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   channelId: JString (required)
  ##            : Placeholder documentation for __string
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `channelId` field"
  var valid_600623 = path.getOrDefault("channelId")
  valid_600623 = validateParameter(valid_600623, JString, required = true,
                                 default = nil)
  if valid_600623 != nil:
    section.add "channelId", valid_600623
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
  var valid_600624 = header.getOrDefault("X-Amz-Date")
  valid_600624 = validateParameter(valid_600624, JString, required = false,
                                 default = nil)
  if valid_600624 != nil:
    section.add "X-Amz-Date", valid_600624
  var valid_600625 = header.getOrDefault("X-Amz-Security-Token")
  valid_600625 = validateParameter(valid_600625, JString, required = false,
                                 default = nil)
  if valid_600625 != nil:
    section.add "X-Amz-Security-Token", valid_600625
  var valid_600626 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_600626 = validateParameter(valid_600626, JString, required = false,
                                 default = nil)
  if valid_600626 != nil:
    section.add "X-Amz-Content-Sha256", valid_600626
  var valid_600627 = header.getOrDefault("X-Amz-Algorithm")
  valid_600627 = validateParameter(valid_600627, JString, required = false,
                                 default = nil)
  if valid_600627 != nil:
    section.add "X-Amz-Algorithm", valid_600627
  var valid_600628 = header.getOrDefault("X-Amz-Signature")
  valid_600628 = validateParameter(valid_600628, JString, required = false,
                                 default = nil)
  if valid_600628 != nil:
    section.add "X-Amz-Signature", valid_600628
  var valid_600629 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_600629 = validateParameter(valid_600629, JString, required = false,
                                 default = nil)
  if valid_600629 != nil:
    section.add "X-Amz-SignedHeaders", valid_600629
  var valid_600630 = header.getOrDefault("X-Amz-Credential")
  valid_600630 = validateParameter(valid_600630, JString, required = false,
                                 default = nil)
  if valid_600630 != nil:
    section.add "X-Amz-Credential", valid_600630
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_600632: Call_UpdateChannelClass_600620; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the class of the channel.
  ## 
  let valid = call_600632.validator(path, query, header, formData, body)
  let scheme = call_600632.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_600632.url(scheme.get, call_600632.host, call_600632.base,
                         call_600632.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_600632, url, valid)

proc call*(call_600633: Call_UpdateChannelClass_600620; channelId: string;
          body: JsonNode): Recallable =
  ## updateChannelClass
  ## Changes the class of the channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_600634 = newJObject()
  var body_600635 = newJObject()
  add(path_600634, "channelId", newJString(channelId))
  if body != nil:
    body_600635 = body
  result = call_600633.call(path_600634, nil, nil, nil, body_600635)

var updateChannelClass* = Call_UpdateChannelClass_600620(
    name: "updateChannelClass", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/channelClass",
    validator: validate_UpdateChannelClass_600621, base: "/",
    url: url_UpdateChannelClass_600622, schemes: {Scheme.Https, Scheme.Http})
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
