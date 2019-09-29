
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_593437 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_593437](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_593437): Option[Scheme] {.used.} =
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
    if js.kind notin {JString, JInt, JFloat, JNull, JBool}:
      return
    head = $js
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_BatchUpdateSchedule_594049 = ref object of OpenApiRestCall_593437
proc url_BatchUpdateSchedule_594051(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_BatchUpdateSchedule_594050(path: JsonNode; query: JsonNode;
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
  var valid_594052 = path.getOrDefault("channelId")
  valid_594052 = validateParameter(valid_594052, JString, required = true,
                                 default = nil)
  if valid_594052 != nil:
    section.add "channelId", valid_594052
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
  var valid_594053 = header.getOrDefault("X-Amz-Date")
  valid_594053 = validateParameter(valid_594053, JString, required = false,
                                 default = nil)
  if valid_594053 != nil:
    section.add "X-Amz-Date", valid_594053
  var valid_594054 = header.getOrDefault("X-Amz-Security-Token")
  valid_594054 = validateParameter(valid_594054, JString, required = false,
                                 default = nil)
  if valid_594054 != nil:
    section.add "X-Amz-Security-Token", valid_594054
  var valid_594055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594055 = validateParameter(valid_594055, JString, required = false,
                                 default = nil)
  if valid_594055 != nil:
    section.add "X-Amz-Content-Sha256", valid_594055
  var valid_594056 = header.getOrDefault("X-Amz-Algorithm")
  valid_594056 = validateParameter(valid_594056, JString, required = false,
                                 default = nil)
  if valid_594056 != nil:
    section.add "X-Amz-Algorithm", valid_594056
  var valid_594057 = header.getOrDefault("X-Amz-Signature")
  valid_594057 = validateParameter(valid_594057, JString, required = false,
                                 default = nil)
  if valid_594057 != nil:
    section.add "X-Amz-Signature", valid_594057
  var valid_594058 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594058 = validateParameter(valid_594058, JString, required = false,
                                 default = nil)
  if valid_594058 != nil:
    section.add "X-Amz-SignedHeaders", valid_594058
  var valid_594059 = header.getOrDefault("X-Amz-Credential")
  valid_594059 = validateParameter(valid_594059, JString, required = false,
                                 default = nil)
  if valid_594059 != nil:
    section.add "X-Amz-Credential", valid_594059
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594061: Call_BatchUpdateSchedule_594049; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a channel schedule
  ## 
  let valid = call_594061.validator(path, query, header, formData, body)
  let scheme = call_594061.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594061.url(scheme.get, call_594061.host, call_594061.base,
                         call_594061.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594061, url, valid)

proc call*(call_594062: Call_BatchUpdateSchedule_594049; channelId: string;
          body: JsonNode): Recallable =
  ## batchUpdateSchedule
  ## Update a channel schedule
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_594063 = newJObject()
  var body_594064 = newJObject()
  add(path_594063, "channelId", newJString(channelId))
  if body != nil:
    body_594064 = body
  result = call_594062.call(path_594063, nil, nil, nil, body_594064)

var batchUpdateSchedule* = Call_BatchUpdateSchedule_594049(
    name: "batchUpdateSchedule", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com", route: "/prod/channels/{channelId}/schedule",
    validator: validate_BatchUpdateSchedule_594050, base: "/",
    url: url_BatchUpdateSchedule_594051, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchedule_593774 = ref object of OpenApiRestCall_593437
proc url_DescribeSchedule_593776(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeSchedule_593775(path: JsonNode; query: JsonNode;
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
  var valid_593902 = path.getOrDefault("channelId")
  valid_593902 = validateParameter(valid_593902, JString, required = true,
                                 default = nil)
  if valid_593902 != nil:
    section.add "channelId", valid_593902
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
  var valid_593903 = query.getOrDefault("NextToken")
  valid_593903 = validateParameter(valid_593903, JString, required = false,
                                 default = nil)
  if valid_593903 != nil:
    section.add "NextToken", valid_593903
  var valid_593904 = query.getOrDefault("maxResults")
  valid_593904 = validateParameter(valid_593904, JInt, required = false, default = nil)
  if valid_593904 != nil:
    section.add "maxResults", valid_593904
  var valid_593905 = query.getOrDefault("nextToken")
  valid_593905 = validateParameter(valid_593905, JString, required = false,
                                 default = nil)
  if valid_593905 != nil:
    section.add "nextToken", valid_593905
  var valid_593906 = query.getOrDefault("MaxResults")
  valid_593906 = validateParameter(valid_593906, JString, required = false,
                                 default = nil)
  if valid_593906 != nil:
    section.add "MaxResults", valid_593906
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
  var valid_593907 = header.getOrDefault("X-Amz-Date")
  valid_593907 = validateParameter(valid_593907, JString, required = false,
                                 default = nil)
  if valid_593907 != nil:
    section.add "X-Amz-Date", valid_593907
  var valid_593908 = header.getOrDefault("X-Amz-Security-Token")
  valid_593908 = validateParameter(valid_593908, JString, required = false,
                                 default = nil)
  if valid_593908 != nil:
    section.add "X-Amz-Security-Token", valid_593908
  var valid_593909 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593909 = validateParameter(valid_593909, JString, required = false,
                                 default = nil)
  if valid_593909 != nil:
    section.add "X-Amz-Content-Sha256", valid_593909
  var valid_593910 = header.getOrDefault("X-Amz-Algorithm")
  valid_593910 = validateParameter(valid_593910, JString, required = false,
                                 default = nil)
  if valid_593910 != nil:
    section.add "X-Amz-Algorithm", valid_593910
  var valid_593911 = header.getOrDefault("X-Amz-Signature")
  valid_593911 = validateParameter(valid_593911, JString, required = false,
                                 default = nil)
  if valid_593911 != nil:
    section.add "X-Amz-Signature", valid_593911
  var valid_593912 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593912 = validateParameter(valid_593912, JString, required = false,
                                 default = nil)
  if valid_593912 != nil:
    section.add "X-Amz-SignedHeaders", valid_593912
  var valid_593913 = header.getOrDefault("X-Amz-Credential")
  valid_593913 = validateParameter(valid_593913, JString, required = false,
                                 default = nil)
  if valid_593913 != nil:
    section.add "X-Amz-Credential", valid_593913
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593936: Call_DescribeSchedule_593774; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get a channel schedule
  ## 
  let valid = call_593936.validator(path, query, header, formData, body)
  let scheme = call_593936.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593936.url(scheme.get, call_593936.host, call_593936.base,
                         call_593936.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593936, url, valid)

proc call*(call_594007: Call_DescribeSchedule_593774; channelId: string;
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
  var path_594008 = newJObject()
  var query_594010 = newJObject()
  add(path_594008, "channelId", newJString(channelId))
  add(query_594010, "NextToken", newJString(NextToken))
  add(query_594010, "maxResults", newJInt(maxResults))
  add(query_594010, "nextToken", newJString(nextToken))
  add(query_594010, "MaxResults", newJString(MaxResults))
  result = call_594007.call(path_594008, query_594010, nil, nil, nil)

var describeSchedule* = Call_DescribeSchedule_593774(name: "describeSchedule",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_DescribeSchedule_593775, base: "/",
    url: url_DescribeSchedule_593776, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchedule_594065 = ref object of OpenApiRestCall_593437
proc url_DeleteSchedule_594067(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteSchedule_594066(path: JsonNode; query: JsonNode;
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
  var valid_594068 = path.getOrDefault("channelId")
  valid_594068 = validateParameter(valid_594068, JString, required = true,
                                 default = nil)
  if valid_594068 != nil:
    section.add "channelId", valid_594068
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
  var valid_594069 = header.getOrDefault("X-Amz-Date")
  valid_594069 = validateParameter(valid_594069, JString, required = false,
                                 default = nil)
  if valid_594069 != nil:
    section.add "X-Amz-Date", valid_594069
  var valid_594070 = header.getOrDefault("X-Amz-Security-Token")
  valid_594070 = validateParameter(valid_594070, JString, required = false,
                                 default = nil)
  if valid_594070 != nil:
    section.add "X-Amz-Security-Token", valid_594070
  var valid_594071 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594071 = validateParameter(valid_594071, JString, required = false,
                                 default = nil)
  if valid_594071 != nil:
    section.add "X-Amz-Content-Sha256", valid_594071
  var valid_594072 = header.getOrDefault("X-Amz-Algorithm")
  valid_594072 = validateParameter(valid_594072, JString, required = false,
                                 default = nil)
  if valid_594072 != nil:
    section.add "X-Amz-Algorithm", valid_594072
  var valid_594073 = header.getOrDefault("X-Amz-Signature")
  valid_594073 = validateParameter(valid_594073, JString, required = false,
                                 default = nil)
  if valid_594073 != nil:
    section.add "X-Amz-Signature", valid_594073
  var valid_594074 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594074 = validateParameter(valid_594074, JString, required = false,
                                 default = nil)
  if valid_594074 != nil:
    section.add "X-Amz-SignedHeaders", valid_594074
  var valid_594075 = header.getOrDefault("X-Amz-Credential")
  valid_594075 = validateParameter(valid_594075, JString, required = false,
                                 default = nil)
  if valid_594075 != nil:
    section.add "X-Amz-Credential", valid_594075
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594076: Call_DeleteSchedule_594065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete all schedule actions on a channel.
  ## 
  let valid = call_594076.validator(path, query, header, formData, body)
  let scheme = call_594076.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594076.url(scheme.get, call_594076.host, call_594076.base,
                         call_594076.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594076, url, valid)

proc call*(call_594077: Call_DeleteSchedule_594065; channelId: string): Recallable =
  ## deleteSchedule
  ## Delete all schedule actions on a channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_594078 = newJObject()
  add(path_594078, "channelId", newJString(channelId))
  result = call_594077.call(path_594078, nil, nil, nil, nil)

var deleteSchedule* = Call_DeleteSchedule_594065(name: "deleteSchedule",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_DeleteSchedule_594066, base: "/", url: url_DeleteSchedule_594067,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateChannel_594096 = ref object of OpenApiRestCall_593437
proc url_CreateChannel_594098(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateChannel_594097(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594099 = header.getOrDefault("X-Amz-Date")
  valid_594099 = validateParameter(valid_594099, JString, required = false,
                                 default = nil)
  if valid_594099 != nil:
    section.add "X-Amz-Date", valid_594099
  var valid_594100 = header.getOrDefault("X-Amz-Security-Token")
  valid_594100 = validateParameter(valid_594100, JString, required = false,
                                 default = nil)
  if valid_594100 != nil:
    section.add "X-Amz-Security-Token", valid_594100
  var valid_594101 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594101 = validateParameter(valid_594101, JString, required = false,
                                 default = nil)
  if valid_594101 != nil:
    section.add "X-Amz-Content-Sha256", valid_594101
  var valid_594102 = header.getOrDefault("X-Amz-Algorithm")
  valid_594102 = validateParameter(valid_594102, JString, required = false,
                                 default = nil)
  if valid_594102 != nil:
    section.add "X-Amz-Algorithm", valid_594102
  var valid_594103 = header.getOrDefault("X-Amz-Signature")
  valid_594103 = validateParameter(valid_594103, JString, required = false,
                                 default = nil)
  if valid_594103 != nil:
    section.add "X-Amz-Signature", valid_594103
  var valid_594104 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594104 = validateParameter(valid_594104, JString, required = false,
                                 default = nil)
  if valid_594104 != nil:
    section.add "X-Amz-SignedHeaders", valid_594104
  var valid_594105 = header.getOrDefault("X-Amz-Credential")
  valid_594105 = validateParameter(valid_594105, JString, required = false,
                                 default = nil)
  if valid_594105 != nil:
    section.add "X-Amz-Credential", valid_594105
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594107: Call_CreateChannel_594096; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new channel
  ## 
  let valid = call_594107.validator(path, query, header, formData, body)
  let scheme = call_594107.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594107.url(scheme.get, call_594107.host, call_594107.base,
                         call_594107.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594107, url, valid)

proc call*(call_594108: Call_CreateChannel_594096; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a new channel
  ##   body: JObject (required)
  var body_594109 = newJObject()
  if body != nil:
    body_594109 = body
  result = call_594108.call(nil, nil, nil, nil, body_594109)

var createChannel* = Call_CreateChannel_594096(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels", validator: validate_CreateChannel_594097, base: "/",
    url: url_CreateChannel_594098, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_594079 = ref object of OpenApiRestCall_593437
proc url_ListChannels_594081(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListChannels_594080(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594082 = query.getOrDefault("NextToken")
  valid_594082 = validateParameter(valid_594082, JString, required = false,
                                 default = nil)
  if valid_594082 != nil:
    section.add "NextToken", valid_594082
  var valid_594083 = query.getOrDefault("maxResults")
  valid_594083 = validateParameter(valid_594083, JInt, required = false, default = nil)
  if valid_594083 != nil:
    section.add "maxResults", valid_594083
  var valid_594084 = query.getOrDefault("nextToken")
  valid_594084 = validateParameter(valid_594084, JString, required = false,
                                 default = nil)
  if valid_594084 != nil:
    section.add "nextToken", valid_594084
  var valid_594085 = query.getOrDefault("MaxResults")
  valid_594085 = validateParameter(valid_594085, JString, required = false,
                                 default = nil)
  if valid_594085 != nil:
    section.add "MaxResults", valid_594085
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
  var valid_594086 = header.getOrDefault("X-Amz-Date")
  valid_594086 = validateParameter(valid_594086, JString, required = false,
                                 default = nil)
  if valid_594086 != nil:
    section.add "X-Amz-Date", valid_594086
  var valid_594087 = header.getOrDefault("X-Amz-Security-Token")
  valid_594087 = validateParameter(valid_594087, JString, required = false,
                                 default = nil)
  if valid_594087 != nil:
    section.add "X-Amz-Security-Token", valid_594087
  var valid_594088 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594088 = validateParameter(valid_594088, JString, required = false,
                                 default = nil)
  if valid_594088 != nil:
    section.add "X-Amz-Content-Sha256", valid_594088
  var valid_594089 = header.getOrDefault("X-Amz-Algorithm")
  valid_594089 = validateParameter(valid_594089, JString, required = false,
                                 default = nil)
  if valid_594089 != nil:
    section.add "X-Amz-Algorithm", valid_594089
  var valid_594090 = header.getOrDefault("X-Amz-Signature")
  valid_594090 = validateParameter(valid_594090, JString, required = false,
                                 default = nil)
  if valid_594090 != nil:
    section.add "X-Amz-Signature", valid_594090
  var valid_594091 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594091 = validateParameter(valid_594091, JString, required = false,
                                 default = nil)
  if valid_594091 != nil:
    section.add "X-Amz-SignedHeaders", valid_594091
  var valid_594092 = header.getOrDefault("X-Amz-Credential")
  valid_594092 = validateParameter(valid_594092, JString, required = false,
                                 default = nil)
  if valid_594092 != nil:
    section.add "X-Amz-Credential", valid_594092
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594093: Call_ListChannels_594079; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of channels that have been created
  ## 
  let valid = call_594093.validator(path, query, header, formData, body)
  let scheme = call_594093.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594093.url(scheme.get, call_594093.host, call_594093.base,
                         call_594093.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594093, url, valid)

proc call*(call_594094: Call_ListChannels_594079; NextToken: string = "";
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
  var query_594095 = newJObject()
  add(query_594095, "NextToken", newJString(NextToken))
  add(query_594095, "maxResults", newJInt(maxResults))
  add(query_594095, "nextToken", newJString(nextToken))
  add(query_594095, "MaxResults", newJString(MaxResults))
  result = call_594094.call(nil, query_594095, nil, nil, nil)

var listChannels* = Call_ListChannels_594079(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels", validator: validate_ListChannels_594080, base: "/",
    url: url_ListChannels_594081, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInput_594127 = ref object of OpenApiRestCall_593437
proc url_CreateInput_594129(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateInput_594128(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594130 = header.getOrDefault("X-Amz-Date")
  valid_594130 = validateParameter(valid_594130, JString, required = false,
                                 default = nil)
  if valid_594130 != nil:
    section.add "X-Amz-Date", valid_594130
  var valid_594131 = header.getOrDefault("X-Amz-Security-Token")
  valid_594131 = validateParameter(valid_594131, JString, required = false,
                                 default = nil)
  if valid_594131 != nil:
    section.add "X-Amz-Security-Token", valid_594131
  var valid_594132 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594132 = validateParameter(valid_594132, JString, required = false,
                                 default = nil)
  if valid_594132 != nil:
    section.add "X-Amz-Content-Sha256", valid_594132
  var valid_594133 = header.getOrDefault("X-Amz-Algorithm")
  valid_594133 = validateParameter(valid_594133, JString, required = false,
                                 default = nil)
  if valid_594133 != nil:
    section.add "X-Amz-Algorithm", valid_594133
  var valid_594134 = header.getOrDefault("X-Amz-Signature")
  valid_594134 = validateParameter(valid_594134, JString, required = false,
                                 default = nil)
  if valid_594134 != nil:
    section.add "X-Amz-Signature", valid_594134
  var valid_594135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594135 = validateParameter(valid_594135, JString, required = false,
                                 default = nil)
  if valid_594135 != nil:
    section.add "X-Amz-SignedHeaders", valid_594135
  var valid_594136 = header.getOrDefault("X-Amz-Credential")
  valid_594136 = validateParameter(valid_594136, JString, required = false,
                                 default = nil)
  if valid_594136 != nil:
    section.add "X-Amz-Credential", valid_594136
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594138: Call_CreateInput_594127; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create an input
  ## 
  let valid = call_594138.validator(path, query, header, formData, body)
  let scheme = call_594138.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594138.url(scheme.get, call_594138.host, call_594138.base,
                         call_594138.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594138, url, valid)

proc call*(call_594139: Call_CreateInput_594127; body: JsonNode): Recallable =
  ## createInput
  ## Create an input
  ##   body: JObject (required)
  var body_594140 = newJObject()
  if body != nil:
    body_594140 = body
  result = call_594139.call(nil, nil, nil, nil, body_594140)

var createInput* = Call_CreateInput_594127(name: "createInput",
                                        meth: HttpMethod.HttpPost,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs",
                                        validator: validate_CreateInput_594128,
                                        base: "/", url: url_CreateInput_594129,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputs_594110 = ref object of OpenApiRestCall_593437
proc url_ListInputs_594112(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListInputs_594111(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594113 = query.getOrDefault("NextToken")
  valid_594113 = validateParameter(valid_594113, JString, required = false,
                                 default = nil)
  if valid_594113 != nil:
    section.add "NextToken", valid_594113
  var valid_594114 = query.getOrDefault("maxResults")
  valid_594114 = validateParameter(valid_594114, JInt, required = false, default = nil)
  if valid_594114 != nil:
    section.add "maxResults", valid_594114
  var valid_594115 = query.getOrDefault("nextToken")
  valid_594115 = validateParameter(valid_594115, JString, required = false,
                                 default = nil)
  if valid_594115 != nil:
    section.add "nextToken", valid_594115
  var valid_594116 = query.getOrDefault("MaxResults")
  valid_594116 = validateParameter(valid_594116, JString, required = false,
                                 default = nil)
  if valid_594116 != nil:
    section.add "MaxResults", valid_594116
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
  var valid_594117 = header.getOrDefault("X-Amz-Date")
  valid_594117 = validateParameter(valid_594117, JString, required = false,
                                 default = nil)
  if valid_594117 != nil:
    section.add "X-Amz-Date", valid_594117
  var valid_594118 = header.getOrDefault("X-Amz-Security-Token")
  valid_594118 = validateParameter(valid_594118, JString, required = false,
                                 default = nil)
  if valid_594118 != nil:
    section.add "X-Amz-Security-Token", valid_594118
  var valid_594119 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594119 = validateParameter(valid_594119, JString, required = false,
                                 default = nil)
  if valid_594119 != nil:
    section.add "X-Amz-Content-Sha256", valid_594119
  var valid_594120 = header.getOrDefault("X-Amz-Algorithm")
  valid_594120 = validateParameter(valid_594120, JString, required = false,
                                 default = nil)
  if valid_594120 != nil:
    section.add "X-Amz-Algorithm", valid_594120
  var valid_594121 = header.getOrDefault("X-Amz-Signature")
  valid_594121 = validateParameter(valid_594121, JString, required = false,
                                 default = nil)
  if valid_594121 != nil:
    section.add "X-Amz-Signature", valid_594121
  var valid_594122 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594122 = validateParameter(valid_594122, JString, required = false,
                                 default = nil)
  if valid_594122 != nil:
    section.add "X-Amz-SignedHeaders", valid_594122
  var valid_594123 = header.getOrDefault("X-Amz-Credential")
  valid_594123 = validateParameter(valid_594123, JString, required = false,
                                 default = nil)
  if valid_594123 != nil:
    section.add "X-Amz-Credential", valid_594123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594124: Call_ListInputs_594110; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of inputs that have been created
  ## 
  let valid = call_594124.validator(path, query, header, formData, body)
  let scheme = call_594124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594124.url(scheme.get, call_594124.host, call_594124.base,
                         call_594124.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594124, url, valid)

proc call*(call_594125: Call_ListInputs_594110; NextToken: string = "";
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
  var query_594126 = newJObject()
  add(query_594126, "NextToken", newJString(NextToken))
  add(query_594126, "maxResults", newJInt(maxResults))
  add(query_594126, "nextToken", newJString(nextToken))
  add(query_594126, "MaxResults", newJString(MaxResults))
  result = call_594125.call(nil, query_594126, nil, nil, nil)

var listInputs* = Call_ListInputs_594110(name: "listInputs",
                                      meth: HttpMethod.HttpGet,
                                      host: "medialive.amazonaws.com",
                                      route: "/prod/inputs",
                                      validator: validate_ListInputs_594111,
                                      base: "/", url: url_ListInputs_594112,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInputSecurityGroup_594158 = ref object of OpenApiRestCall_593437
proc url_CreateInputSecurityGroup_594160(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateInputSecurityGroup_594159(path: JsonNode; query: JsonNode;
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
  var valid_594161 = header.getOrDefault("X-Amz-Date")
  valid_594161 = validateParameter(valid_594161, JString, required = false,
                                 default = nil)
  if valid_594161 != nil:
    section.add "X-Amz-Date", valid_594161
  var valid_594162 = header.getOrDefault("X-Amz-Security-Token")
  valid_594162 = validateParameter(valid_594162, JString, required = false,
                                 default = nil)
  if valid_594162 != nil:
    section.add "X-Amz-Security-Token", valid_594162
  var valid_594163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594163 = validateParameter(valid_594163, JString, required = false,
                                 default = nil)
  if valid_594163 != nil:
    section.add "X-Amz-Content-Sha256", valid_594163
  var valid_594164 = header.getOrDefault("X-Amz-Algorithm")
  valid_594164 = validateParameter(valid_594164, JString, required = false,
                                 default = nil)
  if valid_594164 != nil:
    section.add "X-Amz-Algorithm", valid_594164
  var valid_594165 = header.getOrDefault("X-Amz-Signature")
  valid_594165 = validateParameter(valid_594165, JString, required = false,
                                 default = nil)
  if valid_594165 != nil:
    section.add "X-Amz-Signature", valid_594165
  var valid_594166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594166 = validateParameter(valid_594166, JString, required = false,
                                 default = nil)
  if valid_594166 != nil:
    section.add "X-Amz-SignedHeaders", valid_594166
  var valid_594167 = header.getOrDefault("X-Amz-Credential")
  valid_594167 = validateParameter(valid_594167, JString, required = false,
                                 default = nil)
  if valid_594167 != nil:
    section.add "X-Amz-Credential", valid_594167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594169: Call_CreateInputSecurityGroup_594158; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Input Security Group
  ## 
  let valid = call_594169.validator(path, query, header, formData, body)
  let scheme = call_594169.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594169.url(scheme.get, call_594169.host, call_594169.base,
                         call_594169.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594169, url, valid)

proc call*(call_594170: Call_CreateInputSecurityGroup_594158; body: JsonNode): Recallable =
  ## createInputSecurityGroup
  ## Creates a Input Security Group
  ##   body: JObject (required)
  var body_594171 = newJObject()
  if body != nil:
    body_594171 = body
  result = call_594170.call(nil, nil, nil, nil, body_594171)

var createInputSecurityGroup* = Call_CreateInputSecurityGroup_594158(
    name: "createInputSecurityGroup", meth: HttpMethod.HttpPost,
    host: "medialive.amazonaws.com", route: "/prod/inputSecurityGroups",
    validator: validate_CreateInputSecurityGroup_594159, base: "/",
    url: url_CreateInputSecurityGroup_594160, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputSecurityGroups_594141 = ref object of OpenApiRestCall_593437
proc url_ListInputSecurityGroups_594143(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListInputSecurityGroups_594142(path: JsonNode; query: JsonNode;
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
  var valid_594144 = query.getOrDefault("NextToken")
  valid_594144 = validateParameter(valid_594144, JString, required = false,
                                 default = nil)
  if valid_594144 != nil:
    section.add "NextToken", valid_594144
  var valid_594145 = query.getOrDefault("maxResults")
  valid_594145 = validateParameter(valid_594145, JInt, required = false, default = nil)
  if valid_594145 != nil:
    section.add "maxResults", valid_594145
  var valid_594146 = query.getOrDefault("nextToken")
  valid_594146 = validateParameter(valid_594146, JString, required = false,
                                 default = nil)
  if valid_594146 != nil:
    section.add "nextToken", valid_594146
  var valid_594147 = query.getOrDefault("MaxResults")
  valid_594147 = validateParameter(valid_594147, JString, required = false,
                                 default = nil)
  if valid_594147 != nil:
    section.add "MaxResults", valid_594147
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
  var valid_594148 = header.getOrDefault("X-Amz-Date")
  valid_594148 = validateParameter(valid_594148, JString, required = false,
                                 default = nil)
  if valid_594148 != nil:
    section.add "X-Amz-Date", valid_594148
  var valid_594149 = header.getOrDefault("X-Amz-Security-Token")
  valid_594149 = validateParameter(valid_594149, JString, required = false,
                                 default = nil)
  if valid_594149 != nil:
    section.add "X-Amz-Security-Token", valid_594149
  var valid_594150 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594150 = validateParameter(valid_594150, JString, required = false,
                                 default = nil)
  if valid_594150 != nil:
    section.add "X-Amz-Content-Sha256", valid_594150
  var valid_594151 = header.getOrDefault("X-Amz-Algorithm")
  valid_594151 = validateParameter(valid_594151, JString, required = false,
                                 default = nil)
  if valid_594151 != nil:
    section.add "X-Amz-Algorithm", valid_594151
  var valid_594152 = header.getOrDefault("X-Amz-Signature")
  valid_594152 = validateParameter(valid_594152, JString, required = false,
                                 default = nil)
  if valid_594152 != nil:
    section.add "X-Amz-Signature", valid_594152
  var valid_594153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594153 = validateParameter(valid_594153, JString, required = false,
                                 default = nil)
  if valid_594153 != nil:
    section.add "X-Amz-SignedHeaders", valid_594153
  var valid_594154 = header.getOrDefault("X-Amz-Credential")
  valid_594154 = validateParameter(valid_594154, JString, required = false,
                                 default = nil)
  if valid_594154 != nil:
    section.add "X-Amz-Credential", valid_594154
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594155: Call_ListInputSecurityGroups_594141; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces a list of Input Security Groups for an account
  ## 
  let valid = call_594155.validator(path, query, header, formData, body)
  let scheme = call_594155.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594155.url(scheme.get, call_594155.host, call_594155.base,
                         call_594155.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594155, url, valid)

proc call*(call_594156: Call_ListInputSecurityGroups_594141;
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
  var query_594157 = newJObject()
  add(query_594157, "NextToken", newJString(NextToken))
  add(query_594157, "maxResults", newJInt(maxResults))
  add(query_594157, "nextToken", newJString(nextToken))
  add(query_594157, "MaxResults", newJString(MaxResults))
  result = call_594156.call(nil, query_594157, nil, nil, nil)

var listInputSecurityGroups* = Call_ListInputSecurityGroups_594141(
    name: "listInputSecurityGroups", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/inputSecurityGroups",
    validator: validate_ListInputSecurityGroups_594142, base: "/",
    url: url_ListInputSecurityGroups_594143, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_594186 = ref object of OpenApiRestCall_593437
proc url_CreateTags_594188(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_CreateTags_594187(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594189 = path.getOrDefault("resource-arn")
  valid_594189 = validateParameter(valid_594189, JString, required = true,
                                 default = nil)
  if valid_594189 != nil:
    section.add "resource-arn", valid_594189
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
  var valid_594190 = header.getOrDefault("X-Amz-Date")
  valid_594190 = validateParameter(valid_594190, JString, required = false,
                                 default = nil)
  if valid_594190 != nil:
    section.add "X-Amz-Date", valid_594190
  var valid_594191 = header.getOrDefault("X-Amz-Security-Token")
  valid_594191 = validateParameter(valid_594191, JString, required = false,
                                 default = nil)
  if valid_594191 != nil:
    section.add "X-Amz-Security-Token", valid_594191
  var valid_594192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594192 = validateParameter(valid_594192, JString, required = false,
                                 default = nil)
  if valid_594192 != nil:
    section.add "X-Amz-Content-Sha256", valid_594192
  var valid_594193 = header.getOrDefault("X-Amz-Algorithm")
  valid_594193 = validateParameter(valid_594193, JString, required = false,
                                 default = nil)
  if valid_594193 != nil:
    section.add "X-Amz-Algorithm", valid_594193
  var valid_594194 = header.getOrDefault("X-Amz-Signature")
  valid_594194 = validateParameter(valid_594194, JString, required = false,
                                 default = nil)
  if valid_594194 != nil:
    section.add "X-Amz-Signature", valid_594194
  var valid_594195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594195 = validateParameter(valid_594195, JString, required = false,
                                 default = nil)
  if valid_594195 != nil:
    section.add "X-Amz-SignedHeaders", valid_594195
  var valid_594196 = header.getOrDefault("X-Amz-Credential")
  valid_594196 = validateParameter(valid_594196, JString, required = false,
                                 default = nil)
  if valid_594196 != nil:
    section.add "X-Amz-Credential", valid_594196
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594198: Call_CreateTags_594186; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create tags for a resource
  ## 
  let valid = call_594198.validator(path, query, header, formData, body)
  let scheme = call_594198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594198.url(scheme.get, call_594198.host, call_594198.base,
                         call_594198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594198, url, valid)

proc call*(call_594199: Call_CreateTags_594186; resourceArn: string; body: JsonNode): Recallable =
  ## createTags
  ## Create tags for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_594200 = newJObject()
  var body_594201 = newJObject()
  add(path_594200, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_594201 = body
  result = call_594199.call(path_594200, nil, nil, nil, body_594201)

var createTags* = Call_CreateTags_594186(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "medialive.amazonaws.com",
                                      route: "/prod/tags/{resource-arn}",
                                      validator: validate_CreateTags_594187,
                                      base: "/", url: url_CreateTags_594188,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_594172 = ref object of OpenApiRestCall_593437
proc url_ListTagsForResource_594174(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListTagsForResource_594173(path: JsonNode; query: JsonNode;
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
  var valid_594175 = path.getOrDefault("resource-arn")
  valid_594175 = validateParameter(valid_594175, JString, required = true,
                                 default = nil)
  if valid_594175 != nil:
    section.add "resource-arn", valid_594175
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
  var valid_594176 = header.getOrDefault("X-Amz-Date")
  valid_594176 = validateParameter(valid_594176, JString, required = false,
                                 default = nil)
  if valid_594176 != nil:
    section.add "X-Amz-Date", valid_594176
  var valid_594177 = header.getOrDefault("X-Amz-Security-Token")
  valid_594177 = validateParameter(valid_594177, JString, required = false,
                                 default = nil)
  if valid_594177 != nil:
    section.add "X-Amz-Security-Token", valid_594177
  var valid_594178 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594178 = validateParameter(valid_594178, JString, required = false,
                                 default = nil)
  if valid_594178 != nil:
    section.add "X-Amz-Content-Sha256", valid_594178
  var valid_594179 = header.getOrDefault("X-Amz-Algorithm")
  valid_594179 = validateParameter(valid_594179, JString, required = false,
                                 default = nil)
  if valid_594179 != nil:
    section.add "X-Amz-Algorithm", valid_594179
  var valid_594180 = header.getOrDefault("X-Amz-Signature")
  valid_594180 = validateParameter(valid_594180, JString, required = false,
                                 default = nil)
  if valid_594180 != nil:
    section.add "X-Amz-Signature", valid_594180
  var valid_594181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594181 = validateParameter(valid_594181, JString, required = false,
                                 default = nil)
  if valid_594181 != nil:
    section.add "X-Amz-SignedHeaders", valid_594181
  var valid_594182 = header.getOrDefault("X-Amz-Credential")
  valid_594182 = validateParameter(valid_594182, JString, required = false,
                                 default = nil)
  if valid_594182 != nil:
    section.add "X-Amz-Credential", valid_594182
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594183: Call_ListTagsForResource_594172; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of tags that have been created for a resource
  ## 
  let valid = call_594183.validator(path, query, header, formData, body)
  let scheme = call_594183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594183.url(scheme.get, call_594183.host, call_594183.base,
                         call_594183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594183, url, valid)

proc call*(call_594184: Call_ListTagsForResource_594172; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Produces list of tags that have been created for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  var path_594185 = newJObject()
  add(path_594185, "resource-arn", newJString(resourceArn))
  result = call_594184.call(path_594185, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_594172(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/tags/{resource-arn}",
    validator: validate_ListTagsForResource_594173, base: "/",
    url: url_ListTagsForResource_594174, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_594216 = ref object of OpenApiRestCall_593437
proc url_UpdateChannel_594218(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateChannel_594217(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594219 = path.getOrDefault("channelId")
  valid_594219 = validateParameter(valid_594219, JString, required = true,
                                 default = nil)
  if valid_594219 != nil:
    section.add "channelId", valid_594219
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
  var valid_594220 = header.getOrDefault("X-Amz-Date")
  valid_594220 = validateParameter(valid_594220, JString, required = false,
                                 default = nil)
  if valid_594220 != nil:
    section.add "X-Amz-Date", valid_594220
  var valid_594221 = header.getOrDefault("X-Amz-Security-Token")
  valid_594221 = validateParameter(valid_594221, JString, required = false,
                                 default = nil)
  if valid_594221 != nil:
    section.add "X-Amz-Security-Token", valid_594221
  var valid_594222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594222 = validateParameter(valid_594222, JString, required = false,
                                 default = nil)
  if valid_594222 != nil:
    section.add "X-Amz-Content-Sha256", valid_594222
  var valid_594223 = header.getOrDefault("X-Amz-Algorithm")
  valid_594223 = validateParameter(valid_594223, JString, required = false,
                                 default = nil)
  if valid_594223 != nil:
    section.add "X-Amz-Algorithm", valid_594223
  var valid_594224 = header.getOrDefault("X-Amz-Signature")
  valid_594224 = validateParameter(valid_594224, JString, required = false,
                                 default = nil)
  if valid_594224 != nil:
    section.add "X-Amz-Signature", valid_594224
  var valid_594225 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594225 = validateParameter(valid_594225, JString, required = false,
                                 default = nil)
  if valid_594225 != nil:
    section.add "X-Amz-SignedHeaders", valid_594225
  var valid_594226 = header.getOrDefault("X-Amz-Credential")
  valid_594226 = validateParameter(valid_594226, JString, required = false,
                                 default = nil)
  if valid_594226 != nil:
    section.add "X-Amz-Credential", valid_594226
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594228: Call_UpdateChannel_594216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a channel.
  ## 
  let valid = call_594228.validator(path, query, header, formData, body)
  let scheme = call_594228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594228.url(scheme.get, call_594228.host, call_594228.base,
                         call_594228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594228, url, valid)

proc call*(call_594229: Call_UpdateChannel_594216; channelId: string; body: JsonNode): Recallable =
  ## updateChannel
  ## Updates a channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_594230 = newJObject()
  var body_594231 = newJObject()
  add(path_594230, "channelId", newJString(channelId))
  if body != nil:
    body_594231 = body
  result = call_594229.call(path_594230, nil, nil, nil, body_594231)

var updateChannel* = Call_UpdateChannel_594216(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_UpdateChannel_594217,
    base: "/", url: url_UpdateChannel_594218, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_594202 = ref object of OpenApiRestCall_593437
proc url_DescribeChannel_594204(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeChannel_594203(path: JsonNode; query: JsonNode;
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
  var valid_594205 = path.getOrDefault("channelId")
  valid_594205 = validateParameter(valid_594205, JString, required = true,
                                 default = nil)
  if valid_594205 != nil:
    section.add "channelId", valid_594205
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
  var valid_594206 = header.getOrDefault("X-Amz-Date")
  valid_594206 = validateParameter(valid_594206, JString, required = false,
                                 default = nil)
  if valid_594206 != nil:
    section.add "X-Amz-Date", valid_594206
  var valid_594207 = header.getOrDefault("X-Amz-Security-Token")
  valid_594207 = validateParameter(valid_594207, JString, required = false,
                                 default = nil)
  if valid_594207 != nil:
    section.add "X-Amz-Security-Token", valid_594207
  var valid_594208 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594208 = validateParameter(valid_594208, JString, required = false,
                                 default = nil)
  if valid_594208 != nil:
    section.add "X-Amz-Content-Sha256", valid_594208
  var valid_594209 = header.getOrDefault("X-Amz-Algorithm")
  valid_594209 = validateParameter(valid_594209, JString, required = false,
                                 default = nil)
  if valid_594209 != nil:
    section.add "X-Amz-Algorithm", valid_594209
  var valid_594210 = header.getOrDefault("X-Amz-Signature")
  valid_594210 = validateParameter(valid_594210, JString, required = false,
                                 default = nil)
  if valid_594210 != nil:
    section.add "X-Amz-Signature", valid_594210
  var valid_594211 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594211 = validateParameter(valid_594211, JString, required = false,
                                 default = nil)
  if valid_594211 != nil:
    section.add "X-Amz-SignedHeaders", valid_594211
  var valid_594212 = header.getOrDefault("X-Amz-Credential")
  valid_594212 = validateParameter(valid_594212, JString, required = false,
                                 default = nil)
  if valid_594212 != nil:
    section.add "X-Amz-Credential", valid_594212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594213: Call_DescribeChannel_594202; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a channel
  ## 
  let valid = call_594213.validator(path, query, header, formData, body)
  let scheme = call_594213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594213.url(scheme.get, call_594213.host, call_594213.base,
                         call_594213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594213, url, valid)

proc call*(call_594214: Call_DescribeChannel_594202; channelId: string): Recallable =
  ## describeChannel
  ## Gets details about a channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_594215 = newJObject()
  add(path_594215, "channelId", newJString(channelId))
  result = call_594214.call(path_594215, nil, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_594202(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_DescribeChannel_594203,
    base: "/", url: url_DescribeChannel_594204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_594232 = ref object of OpenApiRestCall_593437
proc url_DeleteChannel_594234(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteChannel_594233(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594235 = path.getOrDefault("channelId")
  valid_594235 = validateParameter(valid_594235, JString, required = true,
                                 default = nil)
  if valid_594235 != nil:
    section.add "channelId", valid_594235
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
  var valid_594236 = header.getOrDefault("X-Amz-Date")
  valid_594236 = validateParameter(valid_594236, JString, required = false,
                                 default = nil)
  if valid_594236 != nil:
    section.add "X-Amz-Date", valid_594236
  var valid_594237 = header.getOrDefault("X-Amz-Security-Token")
  valid_594237 = validateParameter(valid_594237, JString, required = false,
                                 default = nil)
  if valid_594237 != nil:
    section.add "X-Amz-Security-Token", valid_594237
  var valid_594238 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594238 = validateParameter(valid_594238, JString, required = false,
                                 default = nil)
  if valid_594238 != nil:
    section.add "X-Amz-Content-Sha256", valid_594238
  var valid_594239 = header.getOrDefault("X-Amz-Algorithm")
  valid_594239 = validateParameter(valid_594239, JString, required = false,
                                 default = nil)
  if valid_594239 != nil:
    section.add "X-Amz-Algorithm", valid_594239
  var valid_594240 = header.getOrDefault("X-Amz-Signature")
  valid_594240 = validateParameter(valid_594240, JString, required = false,
                                 default = nil)
  if valid_594240 != nil:
    section.add "X-Amz-Signature", valid_594240
  var valid_594241 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594241 = validateParameter(valid_594241, JString, required = false,
                                 default = nil)
  if valid_594241 != nil:
    section.add "X-Amz-SignedHeaders", valid_594241
  var valid_594242 = header.getOrDefault("X-Amz-Credential")
  valid_594242 = validateParameter(valid_594242, JString, required = false,
                                 default = nil)
  if valid_594242 != nil:
    section.add "X-Amz-Credential", valid_594242
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594243: Call_DeleteChannel_594232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts deletion of channel. The associated outputs are also deleted.
  ## 
  let valid = call_594243.validator(path, query, header, formData, body)
  let scheme = call_594243.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594243.url(scheme.get, call_594243.host, call_594243.base,
                         call_594243.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594243, url, valid)

proc call*(call_594244: Call_DeleteChannel_594232; channelId: string): Recallable =
  ## deleteChannel
  ## Starts deletion of channel. The associated outputs are also deleted.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_594245 = newJObject()
  add(path_594245, "channelId", newJString(channelId))
  result = call_594244.call(path_594245, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_594232(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_DeleteChannel_594233,
    base: "/", url: url_DeleteChannel_594234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInput_594260 = ref object of OpenApiRestCall_593437
proc url_UpdateInput_594262(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateInput_594261(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594263 = path.getOrDefault("inputId")
  valid_594263 = validateParameter(valid_594263, JString, required = true,
                                 default = nil)
  if valid_594263 != nil:
    section.add "inputId", valid_594263
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
  var valid_594264 = header.getOrDefault("X-Amz-Date")
  valid_594264 = validateParameter(valid_594264, JString, required = false,
                                 default = nil)
  if valid_594264 != nil:
    section.add "X-Amz-Date", valid_594264
  var valid_594265 = header.getOrDefault("X-Amz-Security-Token")
  valid_594265 = validateParameter(valid_594265, JString, required = false,
                                 default = nil)
  if valid_594265 != nil:
    section.add "X-Amz-Security-Token", valid_594265
  var valid_594266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594266 = validateParameter(valid_594266, JString, required = false,
                                 default = nil)
  if valid_594266 != nil:
    section.add "X-Amz-Content-Sha256", valid_594266
  var valid_594267 = header.getOrDefault("X-Amz-Algorithm")
  valid_594267 = validateParameter(valid_594267, JString, required = false,
                                 default = nil)
  if valid_594267 != nil:
    section.add "X-Amz-Algorithm", valid_594267
  var valid_594268 = header.getOrDefault("X-Amz-Signature")
  valid_594268 = validateParameter(valid_594268, JString, required = false,
                                 default = nil)
  if valid_594268 != nil:
    section.add "X-Amz-Signature", valid_594268
  var valid_594269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594269 = validateParameter(valid_594269, JString, required = false,
                                 default = nil)
  if valid_594269 != nil:
    section.add "X-Amz-SignedHeaders", valid_594269
  var valid_594270 = header.getOrDefault("X-Amz-Credential")
  valid_594270 = validateParameter(valid_594270, JString, required = false,
                                 default = nil)
  if valid_594270 != nil:
    section.add "X-Amz-Credential", valid_594270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594272: Call_UpdateInput_594260; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an input.
  ## 
  let valid = call_594272.validator(path, query, header, formData, body)
  let scheme = call_594272.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594272.url(scheme.get, call_594272.host, call_594272.base,
                         call_594272.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594272, url, valid)

proc call*(call_594273: Call_UpdateInput_594260; inputId: string; body: JsonNode): Recallable =
  ## updateInput
  ## Updates an input.
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_594274 = newJObject()
  var body_594275 = newJObject()
  add(path_594274, "inputId", newJString(inputId))
  if body != nil:
    body_594275 = body
  result = call_594273.call(path_594274, nil, nil, nil, body_594275)

var updateInput* = Call_UpdateInput_594260(name: "updateInput",
                                        meth: HttpMethod.HttpPut,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs/{inputId}",
                                        validator: validate_UpdateInput_594261,
                                        base: "/", url: url_UpdateInput_594262,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInput_594246 = ref object of OpenApiRestCall_593437
proc url_DescribeInput_594248(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeInput_594247(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594249 = path.getOrDefault("inputId")
  valid_594249 = validateParameter(valid_594249, JString, required = true,
                                 default = nil)
  if valid_594249 != nil:
    section.add "inputId", valid_594249
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
  var valid_594250 = header.getOrDefault("X-Amz-Date")
  valid_594250 = validateParameter(valid_594250, JString, required = false,
                                 default = nil)
  if valid_594250 != nil:
    section.add "X-Amz-Date", valid_594250
  var valid_594251 = header.getOrDefault("X-Amz-Security-Token")
  valid_594251 = validateParameter(valid_594251, JString, required = false,
                                 default = nil)
  if valid_594251 != nil:
    section.add "X-Amz-Security-Token", valid_594251
  var valid_594252 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594252 = validateParameter(valid_594252, JString, required = false,
                                 default = nil)
  if valid_594252 != nil:
    section.add "X-Amz-Content-Sha256", valid_594252
  var valid_594253 = header.getOrDefault("X-Amz-Algorithm")
  valid_594253 = validateParameter(valid_594253, JString, required = false,
                                 default = nil)
  if valid_594253 != nil:
    section.add "X-Amz-Algorithm", valid_594253
  var valid_594254 = header.getOrDefault("X-Amz-Signature")
  valid_594254 = validateParameter(valid_594254, JString, required = false,
                                 default = nil)
  if valid_594254 != nil:
    section.add "X-Amz-Signature", valid_594254
  var valid_594255 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594255 = validateParameter(valid_594255, JString, required = false,
                                 default = nil)
  if valid_594255 != nil:
    section.add "X-Amz-SignedHeaders", valid_594255
  var valid_594256 = header.getOrDefault("X-Amz-Credential")
  valid_594256 = validateParameter(valid_594256, JString, required = false,
                                 default = nil)
  if valid_594256 != nil:
    section.add "X-Amz-Credential", valid_594256
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594257: Call_DescribeInput_594246; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces details about an input
  ## 
  let valid = call_594257.validator(path, query, header, formData, body)
  let scheme = call_594257.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594257.url(scheme.get, call_594257.host, call_594257.base,
                         call_594257.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594257, url, valid)

proc call*(call_594258: Call_DescribeInput_594246; inputId: string): Recallable =
  ## describeInput
  ## Produces details about an input
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_594259 = newJObject()
  add(path_594259, "inputId", newJString(inputId))
  result = call_594258.call(path_594259, nil, nil, nil, nil)

var describeInput* = Call_DescribeInput_594246(name: "describeInput",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/inputs/{inputId}", validator: validate_DescribeInput_594247,
    base: "/", url: url_DescribeInput_594248, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInput_594276 = ref object of OpenApiRestCall_593437
proc url_DeleteInput_594278(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteInput_594277(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594279 = path.getOrDefault("inputId")
  valid_594279 = validateParameter(valid_594279, JString, required = true,
                                 default = nil)
  if valid_594279 != nil:
    section.add "inputId", valid_594279
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
  var valid_594280 = header.getOrDefault("X-Amz-Date")
  valid_594280 = validateParameter(valid_594280, JString, required = false,
                                 default = nil)
  if valid_594280 != nil:
    section.add "X-Amz-Date", valid_594280
  var valid_594281 = header.getOrDefault("X-Amz-Security-Token")
  valid_594281 = validateParameter(valid_594281, JString, required = false,
                                 default = nil)
  if valid_594281 != nil:
    section.add "X-Amz-Security-Token", valid_594281
  var valid_594282 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594282 = validateParameter(valid_594282, JString, required = false,
                                 default = nil)
  if valid_594282 != nil:
    section.add "X-Amz-Content-Sha256", valid_594282
  var valid_594283 = header.getOrDefault("X-Amz-Algorithm")
  valid_594283 = validateParameter(valid_594283, JString, required = false,
                                 default = nil)
  if valid_594283 != nil:
    section.add "X-Amz-Algorithm", valid_594283
  var valid_594284 = header.getOrDefault("X-Amz-Signature")
  valid_594284 = validateParameter(valid_594284, JString, required = false,
                                 default = nil)
  if valid_594284 != nil:
    section.add "X-Amz-Signature", valid_594284
  var valid_594285 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594285 = validateParameter(valid_594285, JString, required = false,
                                 default = nil)
  if valid_594285 != nil:
    section.add "X-Amz-SignedHeaders", valid_594285
  var valid_594286 = header.getOrDefault("X-Amz-Credential")
  valid_594286 = validateParameter(valid_594286, JString, required = false,
                                 default = nil)
  if valid_594286 != nil:
    section.add "X-Amz-Credential", valid_594286
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594287: Call_DeleteInput_594276; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the input end point
  ## 
  let valid = call_594287.validator(path, query, header, formData, body)
  let scheme = call_594287.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594287.url(scheme.get, call_594287.host, call_594287.base,
                         call_594287.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594287, url, valid)

proc call*(call_594288: Call_DeleteInput_594276; inputId: string): Recallable =
  ## deleteInput
  ## Deletes the input end point
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_594289 = newJObject()
  add(path_594289, "inputId", newJString(inputId))
  result = call_594288.call(path_594289, nil, nil, nil, nil)

var deleteInput* = Call_DeleteInput_594276(name: "deleteInput",
                                        meth: HttpMethod.HttpDelete,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs/{inputId}",
                                        validator: validate_DeleteInput_594277,
                                        base: "/", url: url_DeleteInput_594278,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInputSecurityGroup_594304 = ref object of OpenApiRestCall_593437
proc url_UpdateInputSecurityGroup_594306(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_UpdateInputSecurityGroup_594305(path: JsonNode; query: JsonNode;
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
  var valid_594307 = path.getOrDefault("inputSecurityGroupId")
  valid_594307 = validateParameter(valid_594307, JString, required = true,
                                 default = nil)
  if valid_594307 != nil:
    section.add "inputSecurityGroupId", valid_594307
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
  var valid_594308 = header.getOrDefault("X-Amz-Date")
  valid_594308 = validateParameter(valid_594308, JString, required = false,
                                 default = nil)
  if valid_594308 != nil:
    section.add "X-Amz-Date", valid_594308
  var valid_594309 = header.getOrDefault("X-Amz-Security-Token")
  valid_594309 = validateParameter(valid_594309, JString, required = false,
                                 default = nil)
  if valid_594309 != nil:
    section.add "X-Amz-Security-Token", valid_594309
  var valid_594310 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594310 = validateParameter(valid_594310, JString, required = false,
                                 default = nil)
  if valid_594310 != nil:
    section.add "X-Amz-Content-Sha256", valid_594310
  var valid_594311 = header.getOrDefault("X-Amz-Algorithm")
  valid_594311 = validateParameter(valid_594311, JString, required = false,
                                 default = nil)
  if valid_594311 != nil:
    section.add "X-Amz-Algorithm", valid_594311
  var valid_594312 = header.getOrDefault("X-Amz-Signature")
  valid_594312 = validateParameter(valid_594312, JString, required = false,
                                 default = nil)
  if valid_594312 != nil:
    section.add "X-Amz-Signature", valid_594312
  var valid_594313 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594313 = validateParameter(valid_594313, JString, required = false,
                                 default = nil)
  if valid_594313 != nil:
    section.add "X-Amz-SignedHeaders", valid_594313
  var valid_594314 = header.getOrDefault("X-Amz-Credential")
  valid_594314 = validateParameter(valid_594314, JString, required = false,
                                 default = nil)
  if valid_594314 != nil:
    section.add "X-Amz-Credential", valid_594314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594316: Call_UpdateInputSecurityGroup_594304; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update an Input Security Group's Whilelists.
  ## 
  let valid = call_594316.validator(path, query, header, formData, body)
  let scheme = call_594316.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594316.url(scheme.get, call_594316.host, call_594316.base,
                         call_594316.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594316, url, valid)

proc call*(call_594317: Call_UpdateInputSecurityGroup_594304;
          inputSecurityGroupId: string; body: JsonNode): Recallable =
  ## updateInputSecurityGroup
  ## Update an Input Security Group's Whilelists.
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_594318 = newJObject()
  var body_594319 = newJObject()
  add(path_594318, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  if body != nil:
    body_594319 = body
  result = call_594317.call(path_594318, nil, nil, nil, body_594319)

var updateInputSecurityGroup* = Call_UpdateInputSecurityGroup_594304(
    name: "updateInputSecurityGroup", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_UpdateInputSecurityGroup_594305, base: "/",
    url: url_UpdateInputSecurityGroup_594306, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInputSecurityGroup_594290 = ref object of OpenApiRestCall_593437
proc url_DescribeInputSecurityGroup_594292(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DescribeInputSecurityGroup_594291(path: JsonNode; query: JsonNode;
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
  var valid_594293 = path.getOrDefault("inputSecurityGroupId")
  valid_594293 = validateParameter(valid_594293, JString, required = true,
                                 default = nil)
  if valid_594293 != nil:
    section.add "inputSecurityGroupId", valid_594293
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
  var valid_594294 = header.getOrDefault("X-Amz-Date")
  valid_594294 = validateParameter(valid_594294, JString, required = false,
                                 default = nil)
  if valid_594294 != nil:
    section.add "X-Amz-Date", valid_594294
  var valid_594295 = header.getOrDefault("X-Amz-Security-Token")
  valid_594295 = validateParameter(valid_594295, JString, required = false,
                                 default = nil)
  if valid_594295 != nil:
    section.add "X-Amz-Security-Token", valid_594295
  var valid_594296 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594296 = validateParameter(valid_594296, JString, required = false,
                                 default = nil)
  if valid_594296 != nil:
    section.add "X-Amz-Content-Sha256", valid_594296
  var valid_594297 = header.getOrDefault("X-Amz-Algorithm")
  valid_594297 = validateParameter(valid_594297, JString, required = false,
                                 default = nil)
  if valid_594297 != nil:
    section.add "X-Amz-Algorithm", valid_594297
  var valid_594298 = header.getOrDefault("X-Amz-Signature")
  valid_594298 = validateParameter(valid_594298, JString, required = false,
                                 default = nil)
  if valid_594298 != nil:
    section.add "X-Amz-Signature", valid_594298
  var valid_594299 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594299 = validateParameter(valid_594299, JString, required = false,
                                 default = nil)
  if valid_594299 != nil:
    section.add "X-Amz-SignedHeaders", valid_594299
  var valid_594300 = header.getOrDefault("X-Amz-Credential")
  valid_594300 = validateParameter(valid_594300, JString, required = false,
                                 default = nil)
  if valid_594300 != nil:
    section.add "X-Amz-Credential", valid_594300
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594301: Call_DescribeInputSecurityGroup_594290; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces a summary of an Input Security Group
  ## 
  let valid = call_594301.validator(path, query, header, formData, body)
  let scheme = call_594301.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594301.url(scheme.get, call_594301.host, call_594301.base,
                         call_594301.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594301, url, valid)

proc call*(call_594302: Call_DescribeInputSecurityGroup_594290;
          inputSecurityGroupId: string): Recallable =
  ## describeInputSecurityGroup
  ## Produces a summary of an Input Security Group
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  var path_594303 = newJObject()
  add(path_594303, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  result = call_594302.call(path_594303, nil, nil, nil, nil)

var describeInputSecurityGroup* = Call_DescribeInputSecurityGroup_594290(
    name: "describeInputSecurityGroup", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_DescribeInputSecurityGroup_594291, base: "/",
    url: url_DescribeInputSecurityGroup_594292,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInputSecurityGroup_594320 = ref object of OpenApiRestCall_593437
proc url_DeleteInputSecurityGroup_594322(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_DeleteInputSecurityGroup_594321(path: JsonNode; query: JsonNode;
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
  var valid_594323 = path.getOrDefault("inputSecurityGroupId")
  valid_594323 = validateParameter(valid_594323, JString, required = true,
                                 default = nil)
  if valid_594323 != nil:
    section.add "inputSecurityGroupId", valid_594323
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
  var valid_594324 = header.getOrDefault("X-Amz-Date")
  valid_594324 = validateParameter(valid_594324, JString, required = false,
                                 default = nil)
  if valid_594324 != nil:
    section.add "X-Amz-Date", valid_594324
  var valid_594325 = header.getOrDefault("X-Amz-Security-Token")
  valid_594325 = validateParameter(valid_594325, JString, required = false,
                                 default = nil)
  if valid_594325 != nil:
    section.add "X-Amz-Security-Token", valid_594325
  var valid_594326 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594326 = validateParameter(valid_594326, JString, required = false,
                                 default = nil)
  if valid_594326 != nil:
    section.add "X-Amz-Content-Sha256", valid_594326
  var valid_594327 = header.getOrDefault("X-Amz-Algorithm")
  valid_594327 = validateParameter(valid_594327, JString, required = false,
                                 default = nil)
  if valid_594327 != nil:
    section.add "X-Amz-Algorithm", valid_594327
  var valid_594328 = header.getOrDefault("X-Amz-Signature")
  valid_594328 = validateParameter(valid_594328, JString, required = false,
                                 default = nil)
  if valid_594328 != nil:
    section.add "X-Amz-Signature", valid_594328
  var valid_594329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594329 = validateParameter(valid_594329, JString, required = false,
                                 default = nil)
  if valid_594329 != nil:
    section.add "X-Amz-SignedHeaders", valid_594329
  var valid_594330 = header.getOrDefault("X-Amz-Credential")
  valid_594330 = validateParameter(valid_594330, JString, required = false,
                                 default = nil)
  if valid_594330 != nil:
    section.add "X-Amz-Credential", valid_594330
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594331: Call_DeleteInputSecurityGroup_594320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Input Security Group
  ## 
  let valid = call_594331.validator(path, query, header, formData, body)
  let scheme = call_594331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594331.url(scheme.get, call_594331.host, call_594331.base,
                         call_594331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594331, url, valid)

proc call*(call_594332: Call_DeleteInputSecurityGroup_594320;
          inputSecurityGroupId: string): Recallable =
  ## deleteInputSecurityGroup
  ## Deletes an Input Security Group
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  var path_594333 = newJObject()
  add(path_594333, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  result = call_594332.call(path_594333, nil, nil, nil, nil)

var deleteInputSecurityGroup* = Call_DeleteInputSecurityGroup_594320(
    name: "deleteInputSecurityGroup", meth: HttpMethod.HttpDelete,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_DeleteInputSecurityGroup_594321, base: "/",
    url: url_DeleteInputSecurityGroup_594322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReservation_594348 = ref object of OpenApiRestCall_593437
proc url_UpdateReservation_594350(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateReservation_594349(path: JsonNode; query: JsonNode;
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
  var valid_594351 = path.getOrDefault("reservationId")
  valid_594351 = validateParameter(valid_594351, JString, required = true,
                                 default = nil)
  if valid_594351 != nil:
    section.add "reservationId", valid_594351
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
  var valid_594352 = header.getOrDefault("X-Amz-Date")
  valid_594352 = validateParameter(valid_594352, JString, required = false,
                                 default = nil)
  if valid_594352 != nil:
    section.add "X-Amz-Date", valid_594352
  var valid_594353 = header.getOrDefault("X-Amz-Security-Token")
  valid_594353 = validateParameter(valid_594353, JString, required = false,
                                 default = nil)
  if valid_594353 != nil:
    section.add "X-Amz-Security-Token", valid_594353
  var valid_594354 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594354 = validateParameter(valid_594354, JString, required = false,
                                 default = nil)
  if valid_594354 != nil:
    section.add "X-Amz-Content-Sha256", valid_594354
  var valid_594355 = header.getOrDefault("X-Amz-Algorithm")
  valid_594355 = validateParameter(valid_594355, JString, required = false,
                                 default = nil)
  if valid_594355 != nil:
    section.add "X-Amz-Algorithm", valid_594355
  var valid_594356 = header.getOrDefault("X-Amz-Signature")
  valid_594356 = validateParameter(valid_594356, JString, required = false,
                                 default = nil)
  if valid_594356 != nil:
    section.add "X-Amz-Signature", valid_594356
  var valid_594357 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594357 = validateParameter(valid_594357, JString, required = false,
                                 default = nil)
  if valid_594357 != nil:
    section.add "X-Amz-SignedHeaders", valid_594357
  var valid_594358 = header.getOrDefault("X-Amz-Credential")
  valid_594358 = validateParameter(valid_594358, JString, required = false,
                                 default = nil)
  if valid_594358 != nil:
    section.add "X-Amz-Credential", valid_594358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594360: Call_UpdateReservation_594348; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update reservation.
  ## 
  let valid = call_594360.validator(path, query, header, formData, body)
  let scheme = call_594360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594360.url(scheme.get, call_594360.host, call_594360.base,
                         call_594360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594360, url, valid)

proc call*(call_594361: Call_UpdateReservation_594348; reservationId: string;
          body: JsonNode): Recallable =
  ## updateReservation
  ## Update reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_594362 = newJObject()
  var body_594363 = newJObject()
  add(path_594362, "reservationId", newJString(reservationId))
  if body != nil:
    body_594363 = body
  result = call_594361.call(path_594362, nil, nil, nil, body_594363)

var updateReservation* = Call_UpdateReservation_594348(name: "updateReservation",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_UpdateReservation_594349, base: "/",
    url: url_UpdateReservation_594350, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservation_594334 = ref object of OpenApiRestCall_593437
proc url_DescribeReservation_594336(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeReservation_594335(path: JsonNode; query: JsonNode;
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
  var valid_594337 = path.getOrDefault("reservationId")
  valid_594337 = validateParameter(valid_594337, JString, required = true,
                                 default = nil)
  if valid_594337 != nil:
    section.add "reservationId", valid_594337
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
  var valid_594338 = header.getOrDefault("X-Amz-Date")
  valid_594338 = validateParameter(valid_594338, JString, required = false,
                                 default = nil)
  if valid_594338 != nil:
    section.add "X-Amz-Date", valid_594338
  var valid_594339 = header.getOrDefault("X-Amz-Security-Token")
  valid_594339 = validateParameter(valid_594339, JString, required = false,
                                 default = nil)
  if valid_594339 != nil:
    section.add "X-Amz-Security-Token", valid_594339
  var valid_594340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594340 = validateParameter(valid_594340, JString, required = false,
                                 default = nil)
  if valid_594340 != nil:
    section.add "X-Amz-Content-Sha256", valid_594340
  var valid_594341 = header.getOrDefault("X-Amz-Algorithm")
  valid_594341 = validateParameter(valid_594341, JString, required = false,
                                 default = nil)
  if valid_594341 != nil:
    section.add "X-Amz-Algorithm", valid_594341
  var valid_594342 = header.getOrDefault("X-Amz-Signature")
  valid_594342 = validateParameter(valid_594342, JString, required = false,
                                 default = nil)
  if valid_594342 != nil:
    section.add "X-Amz-Signature", valid_594342
  var valid_594343 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594343 = validateParameter(valid_594343, JString, required = false,
                                 default = nil)
  if valid_594343 != nil:
    section.add "X-Amz-SignedHeaders", valid_594343
  var valid_594344 = header.getOrDefault("X-Amz-Credential")
  valid_594344 = validateParameter(valid_594344, JString, required = false,
                                 default = nil)
  if valid_594344 != nil:
    section.add "X-Amz-Credential", valid_594344
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594345: Call_DescribeReservation_594334; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details for a reservation.
  ## 
  let valid = call_594345.validator(path, query, header, formData, body)
  let scheme = call_594345.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594345.url(scheme.get, call_594345.host, call_594345.base,
                         call_594345.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594345, url, valid)

proc call*(call_594346: Call_DescribeReservation_594334; reservationId: string): Recallable =
  ## describeReservation
  ## Get details for a reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_594347 = newJObject()
  add(path_594347, "reservationId", newJString(reservationId))
  result = call_594346.call(path_594347, nil, nil, nil, nil)

var describeReservation* = Call_DescribeReservation_594334(
    name: "describeReservation", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/reservations/{reservationId}",
    validator: validate_DescribeReservation_594335, base: "/",
    url: url_DescribeReservation_594336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReservation_594364 = ref object of OpenApiRestCall_593437
proc url_DeleteReservation_594366(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteReservation_594365(path: JsonNode; query: JsonNode;
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
  var valid_594367 = path.getOrDefault("reservationId")
  valid_594367 = validateParameter(valid_594367, JString, required = true,
                                 default = nil)
  if valid_594367 != nil:
    section.add "reservationId", valid_594367
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
  var valid_594368 = header.getOrDefault("X-Amz-Date")
  valid_594368 = validateParameter(valid_594368, JString, required = false,
                                 default = nil)
  if valid_594368 != nil:
    section.add "X-Amz-Date", valid_594368
  var valid_594369 = header.getOrDefault("X-Amz-Security-Token")
  valid_594369 = validateParameter(valid_594369, JString, required = false,
                                 default = nil)
  if valid_594369 != nil:
    section.add "X-Amz-Security-Token", valid_594369
  var valid_594370 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594370 = validateParameter(valid_594370, JString, required = false,
                                 default = nil)
  if valid_594370 != nil:
    section.add "X-Amz-Content-Sha256", valid_594370
  var valid_594371 = header.getOrDefault("X-Amz-Algorithm")
  valid_594371 = validateParameter(valid_594371, JString, required = false,
                                 default = nil)
  if valid_594371 != nil:
    section.add "X-Amz-Algorithm", valid_594371
  var valid_594372 = header.getOrDefault("X-Amz-Signature")
  valid_594372 = validateParameter(valid_594372, JString, required = false,
                                 default = nil)
  if valid_594372 != nil:
    section.add "X-Amz-Signature", valid_594372
  var valid_594373 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594373 = validateParameter(valid_594373, JString, required = false,
                                 default = nil)
  if valid_594373 != nil:
    section.add "X-Amz-SignedHeaders", valid_594373
  var valid_594374 = header.getOrDefault("X-Amz-Credential")
  valid_594374 = validateParameter(valid_594374, JString, required = false,
                                 default = nil)
  if valid_594374 != nil:
    section.add "X-Amz-Credential", valid_594374
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594375: Call_DeleteReservation_594364; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete an expired reservation.
  ## 
  let valid = call_594375.validator(path, query, header, formData, body)
  let scheme = call_594375.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594375.url(scheme.get, call_594375.host, call_594375.base,
                         call_594375.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594375, url, valid)

proc call*(call_594376: Call_DeleteReservation_594364; reservationId: string): Recallable =
  ## deleteReservation
  ## Delete an expired reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_594377 = newJObject()
  add(path_594377, "reservationId", newJString(reservationId))
  result = call_594376.call(path_594377, nil, nil, nil, nil)

var deleteReservation* = Call_DeleteReservation_594364(name: "deleteReservation",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_DeleteReservation_594365, base: "/",
    url: url_DeleteReservation_594366, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_594378 = ref object of OpenApiRestCall_593437
proc url_DeleteTags_594380(protocol: Scheme; host: string; base: string; route: string;
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
  result.path = base & hydrated.get

proc validate_DeleteTags_594379(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594381 = path.getOrDefault("resource-arn")
  valid_594381 = validateParameter(valid_594381, JString, required = true,
                                 default = nil)
  if valid_594381 != nil:
    section.add "resource-arn", valid_594381
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : Placeholder documentation for __listOf__string
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_594382 = query.getOrDefault("tagKeys")
  valid_594382 = validateParameter(valid_594382, JArray, required = true, default = nil)
  if valid_594382 != nil:
    section.add "tagKeys", valid_594382
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
  var valid_594383 = header.getOrDefault("X-Amz-Date")
  valid_594383 = validateParameter(valid_594383, JString, required = false,
                                 default = nil)
  if valid_594383 != nil:
    section.add "X-Amz-Date", valid_594383
  var valid_594384 = header.getOrDefault("X-Amz-Security-Token")
  valid_594384 = validateParameter(valid_594384, JString, required = false,
                                 default = nil)
  if valid_594384 != nil:
    section.add "X-Amz-Security-Token", valid_594384
  var valid_594385 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594385 = validateParameter(valid_594385, JString, required = false,
                                 default = nil)
  if valid_594385 != nil:
    section.add "X-Amz-Content-Sha256", valid_594385
  var valid_594386 = header.getOrDefault("X-Amz-Algorithm")
  valid_594386 = validateParameter(valid_594386, JString, required = false,
                                 default = nil)
  if valid_594386 != nil:
    section.add "X-Amz-Algorithm", valid_594386
  var valid_594387 = header.getOrDefault("X-Amz-Signature")
  valid_594387 = validateParameter(valid_594387, JString, required = false,
                                 default = nil)
  if valid_594387 != nil:
    section.add "X-Amz-Signature", valid_594387
  var valid_594388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594388 = validateParameter(valid_594388, JString, required = false,
                                 default = nil)
  if valid_594388 != nil:
    section.add "X-Amz-SignedHeaders", valid_594388
  var valid_594389 = header.getOrDefault("X-Amz-Credential")
  valid_594389 = validateParameter(valid_594389, JString, required = false,
                                 default = nil)
  if valid_594389 != nil:
    section.add "X-Amz-Credential", valid_594389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594390: Call_DeleteTags_594378; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags for a resource
  ## 
  let valid = call_594390.validator(path, query, header, formData, body)
  let scheme = call_594390.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594390.url(scheme.get, call_594390.host, call_594390.base,
                         call_594390.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594390, url, valid)

proc call*(call_594391: Call_DeleteTags_594378; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## deleteTags
  ## Removes tags for a resource
  ##   tagKeys: JArray (required)
  ##          : Placeholder documentation for __listOf__string
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  var path_594392 = newJObject()
  var query_594393 = newJObject()
  if tagKeys != nil:
    query_594393.add "tagKeys", tagKeys
  add(path_594392, "resource-arn", newJString(resourceArn))
  result = call_594391.call(path_594392, query_594393, nil, nil, nil)

var deleteTags* = Call_DeleteTags_594378(name: "deleteTags",
                                      meth: HttpMethod.HttpDelete,
                                      host: "medialive.amazonaws.com", route: "/prod/tags/{resource-arn}#tagKeys",
                                      validator: validate_DeleteTags_594379,
                                      base: "/", url: url_DeleteTags_594380,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOffering_594394 = ref object of OpenApiRestCall_593437
proc url_DescribeOffering_594396(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeOffering_594395(path: JsonNode; query: JsonNode;
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
  var valid_594397 = path.getOrDefault("offeringId")
  valid_594397 = validateParameter(valid_594397, JString, required = true,
                                 default = nil)
  if valid_594397 != nil:
    section.add "offeringId", valid_594397
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
  var valid_594398 = header.getOrDefault("X-Amz-Date")
  valid_594398 = validateParameter(valid_594398, JString, required = false,
                                 default = nil)
  if valid_594398 != nil:
    section.add "X-Amz-Date", valid_594398
  var valid_594399 = header.getOrDefault("X-Amz-Security-Token")
  valid_594399 = validateParameter(valid_594399, JString, required = false,
                                 default = nil)
  if valid_594399 != nil:
    section.add "X-Amz-Security-Token", valid_594399
  var valid_594400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594400 = validateParameter(valid_594400, JString, required = false,
                                 default = nil)
  if valid_594400 != nil:
    section.add "X-Amz-Content-Sha256", valid_594400
  var valid_594401 = header.getOrDefault("X-Amz-Algorithm")
  valid_594401 = validateParameter(valid_594401, JString, required = false,
                                 default = nil)
  if valid_594401 != nil:
    section.add "X-Amz-Algorithm", valid_594401
  var valid_594402 = header.getOrDefault("X-Amz-Signature")
  valid_594402 = validateParameter(valid_594402, JString, required = false,
                                 default = nil)
  if valid_594402 != nil:
    section.add "X-Amz-Signature", valid_594402
  var valid_594403 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594403 = validateParameter(valid_594403, JString, required = false,
                                 default = nil)
  if valid_594403 != nil:
    section.add "X-Amz-SignedHeaders", valid_594403
  var valid_594404 = header.getOrDefault("X-Amz-Credential")
  valid_594404 = validateParameter(valid_594404, JString, required = false,
                                 default = nil)
  if valid_594404 != nil:
    section.add "X-Amz-Credential", valid_594404
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594405: Call_DescribeOffering_594394; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details for an offering.
  ## 
  let valid = call_594405.validator(path, query, header, formData, body)
  let scheme = call_594405.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594405.url(scheme.get, call_594405.host, call_594405.base,
                         call_594405.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594405, url, valid)

proc call*(call_594406: Call_DescribeOffering_594394; offeringId: string): Recallable =
  ## describeOffering
  ## Get details for an offering.
  ##   offeringId: string (required)
  ##             : Placeholder documentation for __string
  var path_594407 = newJObject()
  add(path_594407, "offeringId", newJString(offeringId))
  result = call_594406.call(path_594407, nil, nil, nil, nil)

var describeOffering* = Call_DescribeOffering_594394(name: "describeOffering",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/offerings/{offeringId}", validator: validate_DescribeOffering_594395,
    base: "/", url: url_DescribeOffering_594396,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_594408 = ref object of OpenApiRestCall_593437
proc url_ListOfferings_594410(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListOfferings_594409(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594411 = query.getOrDefault("codec")
  valid_594411 = validateParameter(valid_594411, JString, required = false,
                                 default = nil)
  if valid_594411 != nil:
    section.add "codec", valid_594411
  var valid_594412 = query.getOrDefault("channelClass")
  valid_594412 = validateParameter(valid_594412, JString, required = false,
                                 default = nil)
  if valid_594412 != nil:
    section.add "channelClass", valid_594412
  var valid_594413 = query.getOrDefault("channelConfiguration")
  valid_594413 = validateParameter(valid_594413, JString, required = false,
                                 default = nil)
  if valid_594413 != nil:
    section.add "channelConfiguration", valid_594413
  var valid_594414 = query.getOrDefault("resolution")
  valid_594414 = validateParameter(valid_594414, JString, required = false,
                                 default = nil)
  if valid_594414 != nil:
    section.add "resolution", valid_594414
  var valid_594415 = query.getOrDefault("maximumFramerate")
  valid_594415 = validateParameter(valid_594415, JString, required = false,
                                 default = nil)
  if valid_594415 != nil:
    section.add "maximumFramerate", valid_594415
  var valid_594416 = query.getOrDefault("NextToken")
  valid_594416 = validateParameter(valid_594416, JString, required = false,
                                 default = nil)
  if valid_594416 != nil:
    section.add "NextToken", valid_594416
  var valid_594417 = query.getOrDefault("maxResults")
  valid_594417 = validateParameter(valid_594417, JInt, required = false, default = nil)
  if valid_594417 != nil:
    section.add "maxResults", valid_594417
  var valid_594418 = query.getOrDefault("nextToken")
  valid_594418 = validateParameter(valid_594418, JString, required = false,
                                 default = nil)
  if valid_594418 != nil:
    section.add "nextToken", valid_594418
  var valid_594419 = query.getOrDefault("videoQuality")
  valid_594419 = validateParameter(valid_594419, JString, required = false,
                                 default = nil)
  if valid_594419 != nil:
    section.add "videoQuality", valid_594419
  var valid_594420 = query.getOrDefault("maximumBitrate")
  valid_594420 = validateParameter(valid_594420, JString, required = false,
                                 default = nil)
  if valid_594420 != nil:
    section.add "maximumBitrate", valid_594420
  var valid_594421 = query.getOrDefault("specialFeature")
  valid_594421 = validateParameter(valid_594421, JString, required = false,
                                 default = nil)
  if valid_594421 != nil:
    section.add "specialFeature", valid_594421
  var valid_594422 = query.getOrDefault("resourceType")
  valid_594422 = validateParameter(valid_594422, JString, required = false,
                                 default = nil)
  if valid_594422 != nil:
    section.add "resourceType", valid_594422
  var valid_594423 = query.getOrDefault("MaxResults")
  valid_594423 = validateParameter(valid_594423, JString, required = false,
                                 default = nil)
  if valid_594423 != nil:
    section.add "MaxResults", valid_594423
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
  var valid_594424 = header.getOrDefault("X-Amz-Date")
  valid_594424 = validateParameter(valid_594424, JString, required = false,
                                 default = nil)
  if valid_594424 != nil:
    section.add "X-Amz-Date", valid_594424
  var valid_594425 = header.getOrDefault("X-Amz-Security-Token")
  valid_594425 = validateParameter(valid_594425, JString, required = false,
                                 default = nil)
  if valid_594425 != nil:
    section.add "X-Amz-Security-Token", valid_594425
  var valid_594426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594426 = validateParameter(valid_594426, JString, required = false,
                                 default = nil)
  if valid_594426 != nil:
    section.add "X-Amz-Content-Sha256", valid_594426
  var valid_594427 = header.getOrDefault("X-Amz-Algorithm")
  valid_594427 = validateParameter(valid_594427, JString, required = false,
                                 default = nil)
  if valid_594427 != nil:
    section.add "X-Amz-Algorithm", valid_594427
  var valid_594428 = header.getOrDefault("X-Amz-Signature")
  valid_594428 = validateParameter(valid_594428, JString, required = false,
                                 default = nil)
  if valid_594428 != nil:
    section.add "X-Amz-Signature", valid_594428
  var valid_594429 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594429 = validateParameter(valid_594429, JString, required = false,
                                 default = nil)
  if valid_594429 != nil:
    section.add "X-Amz-SignedHeaders", valid_594429
  var valid_594430 = header.getOrDefault("X-Amz-Credential")
  valid_594430 = validateParameter(valid_594430, JString, required = false,
                                 default = nil)
  if valid_594430 != nil:
    section.add "X-Amz-Credential", valid_594430
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594431: Call_ListOfferings_594408; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List offerings available for purchase.
  ## 
  let valid = call_594431.validator(path, query, header, formData, body)
  let scheme = call_594431.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594431.url(scheme.get, call_594431.host, call_594431.base,
                         call_594431.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594431, url, valid)

proc call*(call_594432: Call_ListOfferings_594408; codec: string = "";
          channelClass: string = ""; channelConfiguration: string = "";
          resolution: string = ""; maximumFramerate: string = "";
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          videoQuality: string = ""; maximumBitrate: string = "";
          specialFeature: string = ""; resourceType: string = "";
          MaxResults: string = ""): Recallable =
  ## listOfferings
  ## List offerings available for purchase.
  ##   codec: string
  ##        : Placeholder documentation for __string
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
  var query_594433 = newJObject()
  add(query_594433, "codec", newJString(codec))
  add(query_594433, "channelClass", newJString(channelClass))
  add(query_594433, "channelConfiguration", newJString(channelConfiguration))
  add(query_594433, "resolution", newJString(resolution))
  add(query_594433, "maximumFramerate", newJString(maximumFramerate))
  add(query_594433, "NextToken", newJString(NextToken))
  add(query_594433, "maxResults", newJInt(maxResults))
  add(query_594433, "nextToken", newJString(nextToken))
  add(query_594433, "videoQuality", newJString(videoQuality))
  add(query_594433, "maximumBitrate", newJString(maximumBitrate))
  add(query_594433, "specialFeature", newJString(specialFeature))
  add(query_594433, "resourceType", newJString(resourceType))
  add(query_594433, "MaxResults", newJString(MaxResults))
  result = call_594432.call(nil, query_594433, nil, nil, nil)

var listOfferings* = Call_ListOfferings_594408(name: "listOfferings",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/offerings", validator: validate_ListOfferings_594409, base: "/",
    url: url_ListOfferings_594410, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReservations_594434 = ref object of OpenApiRestCall_593437
proc url_ListReservations_594436(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListReservations_594435(path: JsonNode; query: JsonNode;
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
  var valid_594437 = query.getOrDefault("codec")
  valid_594437 = validateParameter(valid_594437, JString, required = false,
                                 default = nil)
  if valid_594437 != nil:
    section.add "codec", valid_594437
  var valid_594438 = query.getOrDefault("channelClass")
  valid_594438 = validateParameter(valid_594438, JString, required = false,
                                 default = nil)
  if valid_594438 != nil:
    section.add "channelClass", valid_594438
  var valid_594439 = query.getOrDefault("resolution")
  valid_594439 = validateParameter(valid_594439, JString, required = false,
                                 default = nil)
  if valid_594439 != nil:
    section.add "resolution", valid_594439
  var valid_594440 = query.getOrDefault("maximumFramerate")
  valid_594440 = validateParameter(valid_594440, JString, required = false,
                                 default = nil)
  if valid_594440 != nil:
    section.add "maximumFramerate", valid_594440
  var valid_594441 = query.getOrDefault("NextToken")
  valid_594441 = validateParameter(valid_594441, JString, required = false,
                                 default = nil)
  if valid_594441 != nil:
    section.add "NextToken", valid_594441
  var valid_594442 = query.getOrDefault("maxResults")
  valid_594442 = validateParameter(valid_594442, JInt, required = false, default = nil)
  if valid_594442 != nil:
    section.add "maxResults", valid_594442
  var valid_594443 = query.getOrDefault("nextToken")
  valid_594443 = validateParameter(valid_594443, JString, required = false,
                                 default = nil)
  if valid_594443 != nil:
    section.add "nextToken", valid_594443
  var valid_594444 = query.getOrDefault("videoQuality")
  valid_594444 = validateParameter(valid_594444, JString, required = false,
                                 default = nil)
  if valid_594444 != nil:
    section.add "videoQuality", valid_594444
  var valid_594445 = query.getOrDefault("maximumBitrate")
  valid_594445 = validateParameter(valid_594445, JString, required = false,
                                 default = nil)
  if valid_594445 != nil:
    section.add "maximumBitrate", valid_594445
  var valid_594446 = query.getOrDefault("specialFeature")
  valid_594446 = validateParameter(valid_594446, JString, required = false,
                                 default = nil)
  if valid_594446 != nil:
    section.add "specialFeature", valid_594446
  var valid_594447 = query.getOrDefault("resourceType")
  valid_594447 = validateParameter(valid_594447, JString, required = false,
                                 default = nil)
  if valid_594447 != nil:
    section.add "resourceType", valid_594447
  var valid_594448 = query.getOrDefault("MaxResults")
  valid_594448 = validateParameter(valid_594448, JString, required = false,
                                 default = nil)
  if valid_594448 != nil:
    section.add "MaxResults", valid_594448
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
  var valid_594449 = header.getOrDefault("X-Amz-Date")
  valid_594449 = validateParameter(valid_594449, JString, required = false,
                                 default = nil)
  if valid_594449 != nil:
    section.add "X-Amz-Date", valid_594449
  var valid_594450 = header.getOrDefault("X-Amz-Security-Token")
  valid_594450 = validateParameter(valid_594450, JString, required = false,
                                 default = nil)
  if valid_594450 != nil:
    section.add "X-Amz-Security-Token", valid_594450
  var valid_594451 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594451 = validateParameter(valid_594451, JString, required = false,
                                 default = nil)
  if valid_594451 != nil:
    section.add "X-Amz-Content-Sha256", valid_594451
  var valid_594452 = header.getOrDefault("X-Amz-Algorithm")
  valid_594452 = validateParameter(valid_594452, JString, required = false,
                                 default = nil)
  if valid_594452 != nil:
    section.add "X-Amz-Algorithm", valid_594452
  var valid_594453 = header.getOrDefault("X-Amz-Signature")
  valid_594453 = validateParameter(valid_594453, JString, required = false,
                                 default = nil)
  if valid_594453 != nil:
    section.add "X-Amz-Signature", valid_594453
  var valid_594454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594454 = validateParameter(valid_594454, JString, required = false,
                                 default = nil)
  if valid_594454 != nil:
    section.add "X-Amz-SignedHeaders", valid_594454
  var valid_594455 = header.getOrDefault("X-Amz-Credential")
  valid_594455 = validateParameter(valid_594455, JString, required = false,
                                 default = nil)
  if valid_594455 != nil:
    section.add "X-Amz-Credential", valid_594455
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594456: Call_ListReservations_594434; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List purchased reservations.
  ## 
  let valid = call_594456.validator(path, query, header, formData, body)
  let scheme = call_594456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594456.url(scheme.get, call_594456.host, call_594456.base,
                         call_594456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594456, url, valid)

proc call*(call_594457: Call_ListReservations_594434; codec: string = "";
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
  var query_594458 = newJObject()
  add(query_594458, "codec", newJString(codec))
  add(query_594458, "channelClass", newJString(channelClass))
  add(query_594458, "resolution", newJString(resolution))
  add(query_594458, "maximumFramerate", newJString(maximumFramerate))
  add(query_594458, "NextToken", newJString(NextToken))
  add(query_594458, "maxResults", newJInt(maxResults))
  add(query_594458, "nextToken", newJString(nextToken))
  add(query_594458, "videoQuality", newJString(videoQuality))
  add(query_594458, "maximumBitrate", newJString(maximumBitrate))
  add(query_594458, "specialFeature", newJString(specialFeature))
  add(query_594458, "resourceType", newJString(resourceType))
  add(query_594458, "MaxResults", newJString(MaxResults))
  result = call_594457.call(nil, query_594458, nil, nil, nil)

var listReservations* = Call_ListReservations_594434(name: "listReservations",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/reservations", validator: validate_ListReservations_594435,
    base: "/", url: url_ListReservations_594436,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_594459 = ref object of OpenApiRestCall_593437
proc url_PurchaseOffering_594461(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_PurchaseOffering_594460(path: JsonNode; query: JsonNode;
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
  var valid_594462 = path.getOrDefault("offeringId")
  valid_594462 = validateParameter(valid_594462, JString, required = true,
                                 default = nil)
  if valid_594462 != nil:
    section.add "offeringId", valid_594462
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
  var valid_594463 = header.getOrDefault("X-Amz-Date")
  valid_594463 = validateParameter(valid_594463, JString, required = false,
                                 default = nil)
  if valid_594463 != nil:
    section.add "X-Amz-Date", valid_594463
  var valid_594464 = header.getOrDefault("X-Amz-Security-Token")
  valid_594464 = validateParameter(valid_594464, JString, required = false,
                                 default = nil)
  if valid_594464 != nil:
    section.add "X-Amz-Security-Token", valid_594464
  var valid_594465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594465 = validateParameter(valid_594465, JString, required = false,
                                 default = nil)
  if valid_594465 != nil:
    section.add "X-Amz-Content-Sha256", valid_594465
  var valid_594466 = header.getOrDefault("X-Amz-Algorithm")
  valid_594466 = validateParameter(valid_594466, JString, required = false,
                                 default = nil)
  if valid_594466 != nil:
    section.add "X-Amz-Algorithm", valid_594466
  var valid_594467 = header.getOrDefault("X-Amz-Signature")
  valid_594467 = validateParameter(valid_594467, JString, required = false,
                                 default = nil)
  if valid_594467 != nil:
    section.add "X-Amz-Signature", valid_594467
  var valid_594468 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594468 = validateParameter(valid_594468, JString, required = false,
                                 default = nil)
  if valid_594468 != nil:
    section.add "X-Amz-SignedHeaders", valid_594468
  var valid_594469 = header.getOrDefault("X-Amz-Credential")
  valid_594469 = validateParameter(valid_594469, JString, required = false,
                                 default = nil)
  if valid_594469 != nil:
    section.add "X-Amz-Credential", valid_594469
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594471: Call_PurchaseOffering_594459; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Purchase an offering and create a reservation.
  ## 
  let valid = call_594471.validator(path, query, header, formData, body)
  let scheme = call_594471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594471.url(scheme.get, call_594471.host, call_594471.base,
                         call_594471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594471, url, valid)

proc call*(call_594472: Call_PurchaseOffering_594459; offeringId: string;
          body: JsonNode): Recallable =
  ## purchaseOffering
  ## Purchase an offering and create a reservation.
  ##   offeringId: string (required)
  ##             : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_594473 = newJObject()
  var body_594474 = newJObject()
  add(path_594473, "offeringId", newJString(offeringId))
  if body != nil:
    body_594474 = body
  result = call_594472.call(path_594473, nil, nil, nil, body_594474)

var purchaseOffering* = Call_PurchaseOffering_594459(name: "purchaseOffering",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/offerings/{offeringId}/purchase",
    validator: validate_PurchaseOffering_594460, base: "/",
    url: url_PurchaseOffering_594461, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChannel_594475 = ref object of OpenApiRestCall_593437
proc url_StartChannel_594477(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_StartChannel_594476(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594478 = path.getOrDefault("channelId")
  valid_594478 = validateParameter(valid_594478, JString, required = true,
                                 default = nil)
  if valid_594478 != nil:
    section.add "channelId", valid_594478
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
  var valid_594479 = header.getOrDefault("X-Amz-Date")
  valid_594479 = validateParameter(valid_594479, JString, required = false,
                                 default = nil)
  if valid_594479 != nil:
    section.add "X-Amz-Date", valid_594479
  var valid_594480 = header.getOrDefault("X-Amz-Security-Token")
  valid_594480 = validateParameter(valid_594480, JString, required = false,
                                 default = nil)
  if valid_594480 != nil:
    section.add "X-Amz-Security-Token", valid_594480
  var valid_594481 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594481 = validateParameter(valid_594481, JString, required = false,
                                 default = nil)
  if valid_594481 != nil:
    section.add "X-Amz-Content-Sha256", valid_594481
  var valid_594482 = header.getOrDefault("X-Amz-Algorithm")
  valid_594482 = validateParameter(valid_594482, JString, required = false,
                                 default = nil)
  if valid_594482 != nil:
    section.add "X-Amz-Algorithm", valid_594482
  var valid_594483 = header.getOrDefault("X-Amz-Signature")
  valid_594483 = validateParameter(valid_594483, JString, required = false,
                                 default = nil)
  if valid_594483 != nil:
    section.add "X-Amz-Signature", valid_594483
  var valid_594484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594484 = validateParameter(valid_594484, JString, required = false,
                                 default = nil)
  if valid_594484 != nil:
    section.add "X-Amz-SignedHeaders", valid_594484
  var valid_594485 = header.getOrDefault("X-Amz-Credential")
  valid_594485 = validateParameter(valid_594485, JString, required = false,
                                 default = nil)
  if valid_594485 != nil:
    section.add "X-Amz-Credential", valid_594485
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594486: Call_StartChannel_594475; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an existing channel
  ## 
  let valid = call_594486.validator(path, query, header, formData, body)
  let scheme = call_594486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594486.url(scheme.get, call_594486.host, call_594486.base,
                         call_594486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594486, url, valid)

proc call*(call_594487: Call_StartChannel_594475; channelId: string): Recallable =
  ## startChannel
  ## Starts an existing channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_594488 = newJObject()
  add(path_594488, "channelId", newJString(channelId))
  result = call_594487.call(path_594488, nil, nil, nil, nil)

var startChannel* = Call_StartChannel_594475(name: "startChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/start", validator: validate_StartChannel_594476,
    base: "/", url: url_StartChannel_594477, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopChannel_594489 = ref object of OpenApiRestCall_593437
proc url_StopChannel_594491(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_StopChannel_594490(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_594492 = path.getOrDefault("channelId")
  valid_594492 = validateParameter(valid_594492, JString, required = true,
                                 default = nil)
  if valid_594492 != nil:
    section.add "channelId", valid_594492
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
  var valid_594493 = header.getOrDefault("X-Amz-Date")
  valid_594493 = validateParameter(valid_594493, JString, required = false,
                                 default = nil)
  if valid_594493 != nil:
    section.add "X-Amz-Date", valid_594493
  var valid_594494 = header.getOrDefault("X-Amz-Security-Token")
  valid_594494 = validateParameter(valid_594494, JString, required = false,
                                 default = nil)
  if valid_594494 != nil:
    section.add "X-Amz-Security-Token", valid_594494
  var valid_594495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594495 = validateParameter(valid_594495, JString, required = false,
                                 default = nil)
  if valid_594495 != nil:
    section.add "X-Amz-Content-Sha256", valid_594495
  var valid_594496 = header.getOrDefault("X-Amz-Algorithm")
  valid_594496 = validateParameter(valid_594496, JString, required = false,
                                 default = nil)
  if valid_594496 != nil:
    section.add "X-Amz-Algorithm", valid_594496
  var valid_594497 = header.getOrDefault("X-Amz-Signature")
  valid_594497 = validateParameter(valid_594497, JString, required = false,
                                 default = nil)
  if valid_594497 != nil:
    section.add "X-Amz-Signature", valid_594497
  var valid_594498 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594498 = validateParameter(valid_594498, JString, required = false,
                                 default = nil)
  if valid_594498 != nil:
    section.add "X-Amz-SignedHeaders", valid_594498
  var valid_594499 = header.getOrDefault("X-Amz-Credential")
  valid_594499 = validateParameter(valid_594499, JString, required = false,
                                 default = nil)
  if valid_594499 != nil:
    section.add "X-Amz-Credential", valid_594499
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_594500: Call_StopChannel_594489; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running channel
  ## 
  let valid = call_594500.validator(path, query, header, formData, body)
  let scheme = call_594500.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594500.url(scheme.get, call_594500.host, call_594500.base,
                         call_594500.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594500, url, valid)

proc call*(call_594501: Call_StopChannel_594489; channelId: string): Recallable =
  ## stopChannel
  ## Stops a running channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_594502 = newJObject()
  add(path_594502, "channelId", newJString(channelId))
  result = call_594501.call(path_594502, nil, nil, nil, nil)

var stopChannel* = Call_StopChannel_594489(name: "stopChannel",
                                        meth: HttpMethod.HttpPost,
                                        host: "medialive.amazonaws.com", route: "/prod/channels/{channelId}/stop",
                                        validator: validate_StopChannel_594490,
                                        base: "/", url: url_StopChannel_594491,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannelClass_594503 = ref object of OpenApiRestCall_593437
proc url_UpdateChannelClass_594505(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateChannelClass_594504(path: JsonNode; query: JsonNode;
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
  var valid_594506 = path.getOrDefault("channelId")
  valid_594506 = validateParameter(valid_594506, JString, required = true,
                                 default = nil)
  if valid_594506 != nil:
    section.add "channelId", valid_594506
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
  var valid_594507 = header.getOrDefault("X-Amz-Date")
  valid_594507 = validateParameter(valid_594507, JString, required = false,
                                 default = nil)
  if valid_594507 != nil:
    section.add "X-Amz-Date", valid_594507
  var valid_594508 = header.getOrDefault("X-Amz-Security-Token")
  valid_594508 = validateParameter(valid_594508, JString, required = false,
                                 default = nil)
  if valid_594508 != nil:
    section.add "X-Amz-Security-Token", valid_594508
  var valid_594509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_594509 = validateParameter(valid_594509, JString, required = false,
                                 default = nil)
  if valid_594509 != nil:
    section.add "X-Amz-Content-Sha256", valid_594509
  var valid_594510 = header.getOrDefault("X-Amz-Algorithm")
  valid_594510 = validateParameter(valid_594510, JString, required = false,
                                 default = nil)
  if valid_594510 != nil:
    section.add "X-Amz-Algorithm", valid_594510
  var valid_594511 = header.getOrDefault("X-Amz-Signature")
  valid_594511 = validateParameter(valid_594511, JString, required = false,
                                 default = nil)
  if valid_594511 != nil:
    section.add "X-Amz-Signature", valid_594511
  var valid_594512 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_594512 = validateParameter(valid_594512, JString, required = false,
                                 default = nil)
  if valid_594512 != nil:
    section.add "X-Amz-SignedHeaders", valid_594512
  var valid_594513 = header.getOrDefault("X-Amz-Credential")
  valid_594513 = validateParameter(valid_594513, JString, required = false,
                                 default = nil)
  if valid_594513 != nil:
    section.add "X-Amz-Credential", valid_594513
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_594515: Call_UpdateChannelClass_594503; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the class of the channel.
  ## 
  let valid = call_594515.validator(path, query, header, formData, body)
  let scheme = call_594515.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_594515.url(scheme.get, call_594515.host, call_594515.base,
                         call_594515.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_594515, url, valid)

proc call*(call_594516: Call_UpdateChannelClass_594503; channelId: string;
          body: JsonNode): Recallable =
  ## updateChannelClass
  ## Changes the class of the channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_594517 = newJObject()
  var body_594518 = newJObject()
  add(path_594517, "channelId", newJString(channelId))
  if body != nil:
    body_594518 = body
  result = call_594516.call(path_594517, nil, nil, nil, body_594518)

var updateChannelClass* = Call_UpdateChannelClass_594503(
    name: "updateChannelClass", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/channelClass",
    validator: validate_UpdateChannelClass_594504, base: "/",
    url: url_UpdateChannelClass_594505, schemes: {Scheme.Https, Scheme.Http})
export
  rest

proc sign(recall: var Recallable; query: JsonNode; algo: SigningAlgo = SHA256) =
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

method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.} =
  let headers = massageHeaders(input.getOrDefault("header"))
  result = newRecallable(call, url, headers, input.getOrDefault("body").getStr)
  result.sign(input.getOrDefault("query"), SHA256)
