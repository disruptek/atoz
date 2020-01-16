
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

  OpenApiRestCall_605589 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_605589](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_605589): Option[Scheme] {.used.} =
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
  Call_BatchUpdateSchedule_606202 = ref object of OpenApiRestCall_605589
proc url_BatchUpdateSchedule_606204(protocol: Scheme; host: string; base: string;
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

proc validate_BatchUpdateSchedule_606203(path: JsonNode; query: JsonNode;
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
  var valid_606205 = path.getOrDefault("channelId")
  valid_606205 = validateParameter(valid_606205, JString, required = true,
                                 default = nil)
  if valid_606205 != nil:
    section.add "channelId", valid_606205
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
  var valid_606206 = header.getOrDefault("X-Amz-Signature")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "X-Amz-Signature", valid_606206
  var valid_606207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "X-Amz-Content-Sha256", valid_606207
  var valid_606208 = header.getOrDefault("X-Amz-Date")
  valid_606208 = validateParameter(valid_606208, JString, required = false,
                                 default = nil)
  if valid_606208 != nil:
    section.add "X-Amz-Date", valid_606208
  var valid_606209 = header.getOrDefault("X-Amz-Credential")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Credential", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Security-Token")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Security-Token", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-Algorithm")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-Algorithm", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-SignedHeaders", valid_606212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606214: Call_BatchUpdateSchedule_606202; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a channel schedule
  ## 
  let valid = call_606214.validator(path, query, header, formData, body)
  let scheme = call_606214.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606214.url(scheme.get, call_606214.host, call_606214.base,
                         call_606214.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606214, url, valid)

proc call*(call_606215: Call_BatchUpdateSchedule_606202; channelId: string;
          body: JsonNode): Recallable =
  ## batchUpdateSchedule
  ## Update a channel schedule
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_606216 = newJObject()
  var body_606217 = newJObject()
  add(path_606216, "channelId", newJString(channelId))
  if body != nil:
    body_606217 = body
  result = call_606215.call(path_606216, nil, nil, nil, body_606217)

var batchUpdateSchedule* = Call_BatchUpdateSchedule_606202(
    name: "batchUpdateSchedule", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com", route: "/prod/channels/{channelId}/schedule",
    validator: validate_BatchUpdateSchedule_606203, base: "/",
    url: url_BatchUpdateSchedule_606204, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchedule_605927 = ref object of OpenApiRestCall_605589
proc url_DescribeSchedule_605929(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSchedule_605928(path: JsonNode; query: JsonNode;
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
  var valid_606055 = path.getOrDefault("channelId")
  valid_606055 = validateParameter(valid_606055, JString, required = true,
                                 default = nil)
  if valid_606055 != nil:
    section.add "channelId", valid_606055
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  section = newJObject()
  var valid_606056 = query.getOrDefault("nextToken")
  valid_606056 = validateParameter(valid_606056, JString, required = false,
                                 default = nil)
  if valid_606056 != nil:
    section.add "nextToken", valid_606056
  var valid_606057 = query.getOrDefault("MaxResults")
  valid_606057 = validateParameter(valid_606057, JString, required = false,
                                 default = nil)
  if valid_606057 != nil:
    section.add "MaxResults", valid_606057
  var valid_606058 = query.getOrDefault("NextToken")
  valid_606058 = validateParameter(valid_606058, JString, required = false,
                                 default = nil)
  if valid_606058 != nil:
    section.add "NextToken", valid_606058
  var valid_606059 = query.getOrDefault("maxResults")
  valid_606059 = validateParameter(valid_606059, JInt, required = false, default = nil)
  if valid_606059 != nil:
    section.add "maxResults", valid_606059
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
  var valid_606060 = header.getOrDefault("X-Amz-Signature")
  valid_606060 = validateParameter(valid_606060, JString, required = false,
                                 default = nil)
  if valid_606060 != nil:
    section.add "X-Amz-Signature", valid_606060
  var valid_606061 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606061 = validateParameter(valid_606061, JString, required = false,
                                 default = nil)
  if valid_606061 != nil:
    section.add "X-Amz-Content-Sha256", valid_606061
  var valid_606062 = header.getOrDefault("X-Amz-Date")
  valid_606062 = validateParameter(valid_606062, JString, required = false,
                                 default = nil)
  if valid_606062 != nil:
    section.add "X-Amz-Date", valid_606062
  var valid_606063 = header.getOrDefault("X-Amz-Credential")
  valid_606063 = validateParameter(valid_606063, JString, required = false,
                                 default = nil)
  if valid_606063 != nil:
    section.add "X-Amz-Credential", valid_606063
  var valid_606064 = header.getOrDefault("X-Amz-Security-Token")
  valid_606064 = validateParameter(valid_606064, JString, required = false,
                                 default = nil)
  if valid_606064 != nil:
    section.add "X-Amz-Security-Token", valid_606064
  var valid_606065 = header.getOrDefault("X-Amz-Algorithm")
  valid_606065 = validateParameter(valid_606065, JString, required = false,
                                 default = nil)
  if valid_606065 != nil:
    section.add "X-Amz-Algorithm", valid_606065
  var valid_606066 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606066 = validateParameter(valid_606066, JString, required = false,
                                 default = nil)
  if valid_606066 != nil:
    section.add "X-Amz-SignedHeaders", valid_606066
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606089: Call_DescribeSchedule_605927; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get a channel schedule
  ## 
  let valid = call_606089.validator(path, query, header, formData, body)
  let scheme = call_606089.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606089.url(scheme.get, call_606089.host, call_606089.base,
                         call_606089.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606089, url, valid)

proc call*(call_606160: Call_DescribeSchedule_605927; channelId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## describeSchedule
  ## Get a channel schedule
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  var path_606161 = newJObject()
  var query_606163 = newJObject()
  add(query_606163, "nextToken", newJString(nextToken))
  add(query_606163, "MaxResults", newJString(MaxResults))
  add(query_606163, "NextToken", newJString(NextToken))
  add(path_606161, "channelId", newJString(channelId))
  add(query_606163, "maxResults", newJInt(maxResults))
  result = call_606160.call(path_606161, query_606163, nil, nil, nil)

var describeSchedule* = Call_DescribeSchedule_605927(name: "describeSchedule",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_DescribeSchedule_605928, base: "/",
    url: url_DescribeSchedule_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchedule_606218 = ref object of OpenApiRestCall_605589
proc url_DeleteSchedule_606220(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSchedule_606219(path: JsonNode; query: JsonNode;
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
  var valid_606221 = path.getOrDefault("channelId")
  valid_606221 = validateParameter(valid_606221, JString, required = true,
                                 default = nil)
  if valid_606221 != nil:
    section.add "channelId", valid_606221
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
  var valid_606222 = header.getOrDefault("X-Amz-Signature")
  valid_606222 = validateParameter(valid_606222, JString, required = false,
                                 default = nil)
  if valid_606222 != nil:
    section.add "X-Amz-Signature", valid_606222
  var valid_606223 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606223 = validateParameter(valid_606223, JString, required = false,
                                 default = nil)
  if valid_606223 != nil:
    section.add "X-Amz-Content-Sha256", valid_606223
  var valid_606224 = header.getOrDefault("X-Amz-Date")
  valid_606224 = validateParameter(valid_606224, JString, required = false,
                                 default = nil)
  if valid_606224 != nil:
    section.add "X-Amz-Date", valid_606224
  var valid_606225 = header.getOrDefault("X-Amz-Credential")
  valid_606225 = validateParameter(valid_606225, JString, required = false,
                                 default = nil)
  if valid_606225 != nil:
    section.add "X-Amz-Credential", valid_606225
  var valid_606226 = header.getOrDefault("X-Amz-Security-Token")
  valid_606226 = validateParameter(valid_606226, JString, required = false,
                                 default = nil)
  if valid_606226 != nil:
    section.add "X-Amz-Security-Token", valid_606226
  var valid_606227 = header.getOrDefault("X-Amz-Algorithm")
  valid_606227 = validateParameter(valid_606227, JString, required = false,
                                 default = nil)
  if valid_606227 != nil:
    section.add "X-Amz-Algorithm", valid_606227
  var valid_606228 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606228 = validateParameter(valid_606228, JString, required = false,
                                 default = nil)
  if valid_606228 != nil:
    section.add "X-Amz-SignedHeaders", valid_606228
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606229: Call_DeleteSchedule_606218; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete all schedule actions on a channel.
  ## 
  let valid = call_606229.validator(path, query, header, formData, body)
  let scheme = call_606229.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606229.url(scheme.get, call_606229.host, call_606229.base,
                         call_606229.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606229, url, valid)

proc call*(call_606230: Call_DeleteSchedule_606218; channelId: string): Recallable =
  ## deleteSchedule
  ## Delete all schedule actions on a channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_606231 = newJObject()
  add(path_606231, "channelId", newJString(channelId))
  result = call_606230.call(path_606231, nil, nil, nil, nil)

var deleteSchedule* = Call_DeleteSchedule_606218(name: "deleteSchedule",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_DeleteSchedule_606219, base: "/", url: url_DeleteSchedule_606220,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateChannel_606249 = ref object of OpenApiRestCall_605589
proc url_CreateChannel_606251(protocol: Scheme; host: string; base: string;
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

proc validate_CreateChannel_606250(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606252 = header.getOrDefault("X-Amz-Signature")
  valid_606252 = validateParameter(valid_606252, JString, required = false,
                                 default = nil)
  if valid_606252 != nil:
    section.add "X-Amz-Signature", valid_606252
  var valid_606253 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606253 = validateParameter(valid_606253, JString, required = false,
                                 default = nil)
  if valid_606253 != nil:
    section.add "X-Amz-Content-Sha256", valid_606253
  var valid_606254 = header.getOrDefault("X-Amz-Date")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Date", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Credential")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Credential", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Security-Token")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Security-Token", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Algorithm")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Algorithm", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-SignedHeaders", valid_606258
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606260: Call_CreateChannel_606249; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new channel
  ## 
  let valid = call_606260.validator(path, query, header, formData, body)
  let scheme = call_606260.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606260.url(scheme.get, call_606260.host, call_606260.base,
                         call_606260.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606260, url, valid)

proc call*(call_606261: Call_CreateChannel_606249; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a new channel
  ##   body: JObject (required)
  var body_606262 = newJObject()
  if body != nil:
    body_606262 = body
  result = call_606261.call(nil, nil, nil, nil, body_606262)

var createChannel* = Call_CreateChannel_606249(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels", validator: validate_CreateChannel_606250, base: "/",
    url: url_CreateChannel_606251, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_606232 = ref object of OpenApiRestCall_605589
proc url_ListChannels_606234(protocol: Scheme; host: string; base: string;
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

proc validate_ListChannels_606233(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Produces list of channels that have been created
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  section = newJObject()
  var valid_606235 = query.getOrDefault("nextToken")
  valid_606235 = validateParameter(valid_606235, JString, required = false,
                                 default = nil)
  if valid_606235 != nil:
    section.add "nextToken", valid_606235
  var valid_606236 = query.getOrDefault("MaxResults")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "MaxResults", valid_606236
  var valid_606237 = query.getOrDefault("NextToken")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "NextToken", valid_606237
  var valid_606238 = query.getOrDefault("maxResults")
  valid_606238 = validateParameter(valid_606238, JInt, required = false, default = nil)
  if valid_606238 != nil:
    section.add "maxResults", valid_606238
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
  var valid_606239 = header.getOrDefault("X-Amz-Signature")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "X-Amz-Signature", valid_606239
  var valid_606240 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606240 = validateParameter(valid_606240, JString, required = false,
                                 default = nil)
  if valid_606240 != nil:
    section.add "X-Amz-Content-Sha256", valid_606240
  var valid_606241 = header.getOrDefault("X-Amz-Date")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Date", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Credential")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Credential", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Security-Token")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Security-Token", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-Algorithm")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-Algorithm", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-SignedHeaders", valid_606245
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606246: Call_ListChannels_606232; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of channels that have been created
  ## 
  let valid = call_606246.validator(path, query, header, formData, body)
  let scheme = call_606246.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606246.url(scheme.get, call_606246.host, call_606246.base,
                         call_606246.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606246, url, valid)

proc call*(call_606247: Call_ListChannels_606232; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listChannels
  ## Produces list of channels that have been created
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  var query_606248 = newJObject()
  add(query_606248, "nextToken", newJString(nextToken))
  add(query_606248, "MaxResults", newJString(MaxResults))
  add(query_606248, "NextToken", newJString(NextToken))
  add(query_606248, "maxResults", newJInt(maxResults))
  result = call_606247.call(nil, query_606248, nil, nil, nil)

var listChannels* = Call_ListChannels_606232(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels", validator: validate_ListChannels_606233, base: "/",
    url: url_ListChannels_606234, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInput_606280 = ref object of OpenApiRestCall_605589
proc url_CreateInput_606282(protocol: Scheme; host: string; base: string;
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

proc validate_CreateInput_606281(path: JsonNode; query: JsonNode; header: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606283 = header.getOrDefault("X-Amz-Signature")
  valid_606283 = validateParameter(valid_606283, JString, required = false,
                                 default = nil)
  if valid_606283 != nil:
    section.add "X-Amz-Signature", valid_606283
  var valid_606284 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606284 = validateParameter(valid_606284, JString, required = false,
                                 default = nil)
  if valid_606284 != nil:
    section.add "X-Amz-Content-Sha256", valid_606284
  var valid_606285 = header.getOrDefault("X-Amz-Date")
  valid_606285 = validateParameter(valid_606285, JString, required = false,
                                 default = nil)
  if valid_606285 != nil:
    section.add "X-Amz-Date", valid_606285
  var valid_606286 = header.getOrDefault("X-Amz-Credential")
  valid_606286 = validateParameter(valid_606286, JString, required = false,
                                 default = nil)
  if valid_606286 != nil:
    section.add "X-Amz-Credential", valid_606286
  var valid_606287 = header.getOrDefault("X-Amz-Security-Token")
  valid_606287 = validateParameter(valid_606287, JString, required = false,
                                 default = nil)
  if valid_606287 != nil:
    section.add "X-Amz-Security-Token", valid_606287
  var valid_606288 = header.getOrDefault("X-Amz-Algorithm")
  valid_606288 = validateParameter(valid_606288, JString, required = false,
                                 default = nil)
  if valid_606288 != nil:
    section.add "X-Amz-Algorithm", valid_606288
  var valid_606289 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606289 = validateParameter(valid_606289, JString, required = false,
                                 default = nil)
  if valid_606289 != nil:
    section.add "X-Amz-SignedHeaders", valid_606289
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606291: Call_CreateInput_606280; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create an input
  ## 
  let valid = call_606291.validator(path, query, header, formData, body)
  let scheme = call_606291.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606291.url(scheme.get, call_606291.host, call_606291.base,
                         call_606291.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606291, url, valid)

proc call*(call_606292: Call_CreateInput_606280; body: JsonNode): Recallable =
  ## createInput
  ## Create an input
  ##   body: JObject (required)
  var body_606293 = newJObject()
  if body != nil:
    body_606293 = body
  result = call_606292.call(nil, nil, nil, nil, body_606293)

var createInput* = Call_CreateInput_606280(name: "createInput",
                                        meth: HttpMethod.HttpPost,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs",
                                        validator: validate_CreateInput_606281,
                                        base: "/", url: url_CreateInput_606282,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputs_606263 = ref object of OpenApiRestCall_605589
proc url_ListInputs_606265(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListInputs_606264(path: JsonNode; query: JsonNode; header: JsonNode;
                               formData: JsonNode; body: JsonNode): JsonNode =
  ## Produces list of inputs that have been created
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  section = newJObject()
  var valid_606266 = query.getOrDefault("nextToken")
  valid_606266 = validateParameter(valid_606266, JString, required = false,
                                 default = nil)
  if valid_606266 != nil:
    section.add "nextToken", valid_606266
  var valid_606267 = query.getOrDefault("MaxResults")
  valid_606267 = validateParameter(valid_606267, JString, required = false,
                                 default = nil)
  if valid_606267 != nil:
    section.add "MaxResults", valid_606267
  var valid_606268 = query.getOrDefault("NextToken")
  valid_606268 = validateParameter(valid_606268, JString, required = false,
                                 default = nil)
  if valid_606268 != nil:
    section.add "NextToken", valid_606268
  var valid_606269 = query.getOrDefault("maxResults")
  valid_606269 = validateParameter(valid_606269, JInt, required = false, default = nil)
  if valid_606269 != nil:
    section.add "maxResults", valid_606269
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
  var valid_606270 = header.getOrDefault("X-Amz-Signature")
  valid_606270 = validateParameter(valid_606270, JString, required = false,
                                 default = nil)
  if valid_606270 != nil:
    section.add "X-Amz-Signature", valid_606270
  var valid_606271 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606271 = validateParameter(valid_606271, JString, required = false,
                                 default = nil)
  if valid_606271 != nil:
    section.add "X-Amz-Content-Sha256", valid_606271
  var valid_606272 = header.getOrDefault("X-Amz-Date")
  valid_606272 = validateParameter(valid_606272, JString, required = false,
                                 default = nil)
  if valid_606272 != nil:
    section.add "X-Amz-Date", valid_606272
  var valid_606273 = header.getOrDefault("X-Amz-Credential")
  valid_606273 = validateParameter(valid_606273, JString, required = false,
                                 default = nil)
  if valid_606273 != nil:
    section.add "X-Amz-Credential", valid_606273
  var valid_606274 = header.getOrDefault("X-Amz-Security-Token")
  valid_606274 = validateParameter(valid_606274, JString, required = false,
                                 default = nil)
  if valid_606274 != nil:
    section.add "X-Amz-Security-Token", valid_606274
  var valid_606275 = header.getOrDefault("X-Amz-Algorithm")
  valid_606275 = validateParameter(valid_606275, JString, required = false,
                                 default = nil)
  if valid_606275 != nil:
    section.add "X-Amz-Algorithm", valid_606275
  var valid_606276 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606276 = validateParameter(valid_606276, JString, required = false,
                                 default = nil)
  if valid_606276 != nil:
    section.add "X-Amz-SignedHeaders", valid_606276
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606277: Call_ListInputs_606263; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of inputs that have been created
  ## 
  let valid = call_606277.validator(path, query, header, formData, body)
  let scheme = call_606277.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606277.url(scheme.get, call_606277.host, call_606277.base,
                         call_606277.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606277, url, valid)

proc call*(call_606278: Call_ListInputs_606263; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listInputs
  ## Produces list of inputs that have been created
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  var query_606279 = newJObject()
  add(query_606279, "nextToken", newJString(nextToken))
  add(query_606279, "MaxResults", newJString(MaxResults))
  add(query_606279, "NextToken", newJString(NextToken))
  add(query_606279, "maxResults", newJInt(maxResults))
  result = call_606278.call(nil, query_606279, nil, nil, nil)

var listInputs* = Call_ListInputs_606263(name: "listInputs",
                                      meth: HttpMethod.HttpGet,
                                      host: "medialive.amazonaws.com",
                                      route: "/prod/inputs",
                                      validator: validate_ListInputs_606264,
                                      base: "/", url: url_ListInputs_606265,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInputSecurityGroup_606311 = ref object of OpenApiRestCall_605589
proc url_CreateInputSecurityGroup_606313(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInputSecurityGroup_606312(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606314 = header.getOrDefault("X-Amz-Signature")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Signature", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Content-Sha256", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-Date")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Date", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-Credential")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Credential", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-Security-Token")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Security-Token", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-Algorithm")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-Algorithm", valid_606319
  var valid_606320 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606320 = validateParameter(valid_606320, JString, required = false,
                                 default = nil)
  if valid_606320 != nil:
    section.add "X-Amz-SignedHeaders", valid_606320
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606322: Call_CreateInputSecurityGroup_606311; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Input Security Group
  ## 
  let valid = call_606322.validator(path, query, header, formData, body)
  let scheme = call_606322.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606322.url(scheme.get, call_606322.host, call_606322.base,
                         call_606322.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606322, url, valid)

proc call*(call_606323: Call_CreateInputSecurityGroup_606311; body: JsonNode): Recallable =
  ## createInputSecurityGroup
  ## Creates a Input Security Group
  ##   body: JObject (required)
  var body_606324 = newJObject()
  if body != nil:
    body_606324 = body
  result = call_606323.call(nil, nil, nil, nil, body_606324)

var createInputSecurityGroup* = Call_CreateInputSecurityGroup_606311(
    name: "createInputSecurityGroup", meth: HttpMethod.HttpPost,
    host: "medialive.amazonaws.com", route: "/prod/inputSecurityGroups",
    validator: validate_CreateInputSecurityGroup_606312, base: "/",
    url: url_CreateInputSecurityGroup_606313, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputSecurityGroups_606294 = ref object of OpenApiRestCall_605589
proc url_ListInputSecurityGroups_606296(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base ==
      "/" and
      route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInputSecurityGroups_606295(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Produces a list of Input Security Groups for an account
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  section = newJObject()
  var valid_606297 = query.getOrDefault("nextToken")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "nextToken", valid_606297
  var valid_606298 = query.getOrDefault("MaxResults")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "MaxResults", valid_606298
  var valid_606299 = query.getOrDefault("NextToken")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "NextToken", valid_606299
  var valid_606300 = query.getOrDefault("maxResults")
  valid_606300 = validateParameter(valid_606300, JInt, required = false, default = nil)
  if valid_606300 != nil:
    section.add "maxResults", valid_606300
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
  var valid_606301 = header.getOrDefault("X-Amz-Signature")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Signature", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Content-Sha256", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-Date")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-Date", valid_606303
  var valid_606304 = header.getOrDefault("X-Amz-Credential")
  valid_606304 = validateParameter(valid_606304, JString, required = false,
                                 default = nil)
  if valid_606304 != nil:
    section.add "X-Amz-Credential", valid_606304
  var valid_606305 = header.getOrDefault("X-Amz-Security-Token")
  valid_606305 = validateParameter(valid_606305, JString, required = false,
                                 default = nil)
  if valid_606305 != nil:
    section.add "X-Amz-Security-Token", valid_606305
  var valid_606306 = header.getOrDefault("X-Amz-Algorithm")
  valid_606306 = validateParameter(valid_606306, JString, required = false,
                                 default = nil)
  if valid_606306 != nil:
    section.add "X-Amz-Algorithm", valid_606306
  var valid_606307 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606307 = validateParameter(valid_606307, JString, required = false,
                                 default = nil)
  if valid_606307 != nil:
    section.add "X-Amz-SignedHeaders", valid_606307
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606308: Call_ListInputSecurityGroups_606294; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces a list of Input Security Groups for an account
  ## 
  let valid = call_606308.validator(path, query, header, formData, body)
  let scheme = call_606308.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606308.url(scheme.get, call_606308.host, call_606308.base,
                         call_606308.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606308, url, valid)

proc call*(call_606309: Call_ListInputSecurityGroups_606294;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listInputSecurityGroups
  ## Produces a list of Input Security Groups for an account
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  var query_606310 = newJObject()
  add(query_606310, "nextToken", newJString(nextToken))
  add(query_606310, "MaxResults", newJString(MaxResults))
  add(query_606310, "NextToken", newJString(NextToken))
  add(query_606310, "maxResults", newJInt(maxResults))
  result = call_606309.call(nil, query_606310, nil, nil, nil)

var listInputSecurityGroups* = Call_ListInputSecurityGroups_606294(
    name: "listInputSecurityGroups", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/inputSecurityGroups",
    validator: validate_ListInputSecurityGroups_606295, base: "/",
    url: url_ListInputSecurityGroups_606296, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultiplex_606342 = ref object of OpenApiRestCall_605589
proc url_CreateMultiplex_606344(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMultiplex_606343(path: JsonNode; query: JsonNode;
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
  ##   X-Amz-Signature: JString
  ##   X-Amz-Content-Sha256: JString
  ##   X-Amz-Date: JString
  ##   X-Amz-Credential: JString
  ##   X-Amz-Security-Token: JString
  ##   X-Amz-Algorithm: JString
  ##   X-Amz-SignedHeaders: JString
  section = newJObject()
  var valid_606345 = header.getOrDefault("X-Amz-Signature")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Signature", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Content-Sha256", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-Date")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-Date", valid_606347
  var valid_606348 = header.getOrDefault("X-Amz-Credential")
  valid_606348 = validateParameter(valid_606348, JString, required = false,
                                 default = nil)
  if valid_606348 != nil:
    section.add "X-Amz-Credential", valid_606348
  var valid_606349 = header.getOrDefault("X-Amz-Security-Token")
  valid_606349 = validateParameter(valid_606349, JString, required = false,
                                 default = nil)
  if valid_606349 != nil:
    section.add "X-Amz-Security-Token", valid_606349
  var valid_606350 = header.getOrDefault("X-Amz-Algorithm")
  valid_606350 = validateParameter(valid_606350, JString, required = false,
                                 default = nil)
  if valid_606350 != nil:
    section.add "X-Amz-Algorithm", valid_606350
  var valid_606351 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606351 = validateParameter(valid_606351, JString, required = false,
                                 default = nil)
  if valid_606351 != nil:
    section.add "X-Amz-SignedHeaders", valid_606351
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606353: Call_CreateMultiplex_606342; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new multiplex.
  ## 
  let valid = call_606353.validator(path, query, header, formData, body)
  let scheme = call_606353.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606353.url(scheme.get, call_606353.host, call_606353.base,
                         call_606353.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606353, url, valid)

proc call*(call_606354: Call_CreateMultiplex_606342; body: JsonNode): Recallable =
  ## createMultiplex
  ## Create a new multiplex.
  ##   body: JObject (required)
  var body_606355 = newJObject()
  if body != nil:
    body_606355 = body
  result = call_606354.call(nil, nil, nil, nil, body_606355)

var createMultiplex* = Call_CreateMultiplex_606342(name: "createMultiplex",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes", validator: validate_CreateMultiplex_606343,
    base: "/", url: url_CreateMultiplex_606344, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultiplexes_606325 = ref object of OpenApiRestCall_605589
proc url_ListMultiplexes_606327(protocol: Scheme; host: string; base: string;
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

proc validate_ListMultiplexes_606326(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Retrieve a list of the existing multiplexes.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  section = newJObject()
  var valid_606328 = query.getOrDefault("nextToken")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "nextToken", valid_606328
  var valid_606329 = query.getOrDefault("MaxResults")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "MaxResults", valid_606329
  var valid_606330 = query.getOrDefault("NextToken")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "NextToken", valid_606330
  var valid_606331 = query.getOrDefault("maxResults")
  valid_606331 = validateParameter(valid_606331, JInt, required = false, default = nil)
  if valid_606331 != nil:
    section.add "maxResults", valid_606331
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
  var valid_606332 = header.getOrDefault("X-Amz-Signature")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-Signature", valid_606332
  var valid_606333 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-Content-Sha256", valid_606333
  var valid_606334 = header.getOrDefault("X-Amz-Date")
  valid_606334 = validateParameter(valid_606334, JString, required = false,
                                 default = nil)
  if valid_606334 != nil:
    section.add "X-Amz-Date", valid_606334
  var valid_606335 = header.getOrDefault("X-Amz-Credential")
  valid_606335 = validateParameter(valid_606335, JString, required = false,
                                 default = nil)
  if valid_606335 != nil:
    section.add "X-Amz-Credential", valid_606335
  var valid_606336 = header.getOrDefault("X-Amz-Security-Token")
  valid_606336 = validateParameter(valid_606336, JString, required = false,
                                 default = nil)
  if valid_606336 != nil:
    section.add "X-Amz-Security-Token", valid_606336
  var valid_606337 = header.getOrDefault("X-Amz-Algorithm")
  valid_606337 = validateParameter(valid_606337, JString, required = false,
                                 default = nil)
  if valid_606337 != nil:
    section.add "X-Amz-Algorithm", valid_606337
  var valid_606338 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606338 = validateParameter(valid_606338, JString, required = false,
                                 default = nil)
  if valid_606338 != nil:
    section.add "X-Amz-SignedHeaders", valid_606338
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606339: Call_ListMultiplexes_606325; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the existing multiplexes.
  ## 
  let valid = call_606339.validator(path, query, header, formData, body)
  let scheme = call_606339.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606339.url(scheme.get, call_606339.host, call_606339.base,
                         call_606339.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606339, url, valid)

proc call*(call_606340: Call_ListMultiplexes_606325; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listMultiplexes
  ## Retrieve a list of the existing multiplexes.
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  var query_606341 = newJObject()
  add(query_606341, "nextToken", newJString(nextToken))
  add(query_606341, "MaxResults", newJString(MaxResults))
  add(query_606341, "NextToken", newJString(NextToken))
  add(query_606341, "maxResults", newJInt(maxResults))
  result = call_606340.call(nil, query_606341, nil, nil, nil)

var listMultiplexes* = Call_ListMultiplexes_606325(name: "listMultiplexes",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes", validator: validate_ListMultiplexes_606326,
    base: "/", url: url_ListMultiplexes_606327, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultiplexProgram_606375 = ref object of OpenApiRestCall_605589
proc url_CreateMultiplexProgram_606377(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMultiplexProgram_606376(path: JsonNode; query: JsonNode;
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
  var valid_606378 = path.getOrDefault("multiplexId")
  valid_606378 = validateParameter(valid_606378, JString, required = true,
                                 default = nil)
  if valid_606378 != nil:
    section.add "multiplexId", valid_606378
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
  var valid_606379 = header.getOrDefault("X-Amz-Signature")
  valid_606379 = validateParameter(valid_606379, JString, required = false,
                                 default = nil)
  if valid_606379 != nil:
    section.add "X-Amz-Signature", valid_606379
  var valid_606380 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606380 = validateParameter(valid_606380, JString, required = false,
                                 default = nil)
  if valid_606380 != nil:
    section.add "X-Amz-Content-Sha256", valid_606380
  var valid_606381 = header.getOrDefault("X-Amz-Date")
  valid_606381 = validateParameter(valid_606381, JString, required = false,
                                 default = nil)
  if valid_606381 != nil:
    section.add "X-Amz-Date", valid_606381
  var valid_606382 = header.getOrDefault("X-Amz-Credential")
  valid_606382 = validateParameter(valid_606382, JString, required = false,
                                 default = nil)
  if valid_606382 != nil:
    section.add "X-Amz-Credential", valid_606382
  var valid_606383 = header.getOrDefault("X-Amz-Security-Token")
  valid_606383 = validateParameter(valid_606383, JString, required = false,
                                 default = nil)
  if valid_606383 != nil:
    section.add "X-Amz-Security-Token", valid_606383
  var valid_606384 = header.getOrDefault("X-Amz-Algorithm")
  valid_606384 = validateParameter(valid_606384, JString, required = false,
                                 default = nil)
  if valid_606384 != nil:
    section.add "X-Amz-Algorithm", valid_606384
  var valid_606385 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-SignedHeaders", valid_606385
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606387: Call_CreateMultiplexProgram_606375; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new program in the multiplex.
  ## 
  let valid = call_606387.validator(path, query, header, formData, body)
  let scheme = call_606387.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606387.url(scheme.get, call_606387.host, call_606387.base,
                         call_606387.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606387, url, valid)

proc call*(call_606388: Call_CreateMultiplexProgram_606375; body: JsonNode;
          multiplexId: string): Recallable =
  ## createMultiplexProgram
  ## Create a new program in the multiplex.
  ##   body: JObject (required)
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_606389 = newJObject()
  var body_606390 = newJObject()
  if body != nil:
    body_606390 = body
  add(path_606389, "multiplexId", newJString(multiplexId))
  result = call_606388.call(path_606389, nil, nil, nil, body_606390)

var createMultiplexProgram* = Call_CreateMultiplexProgram_606375(
    name: "createMultiplexProgram", meth: HttpMethod.HttpPost,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs",
    validator: validate_CreateMultiplexProgram_606376, base: "/",
    url: url_CreateMultiplexProgram_606377, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultiplexPrograms_606356 = ref object of OpenApiRestCall_605589
proc url_ListMultiplexPrograms_606358(protocol: Scheme; host: string; base: string;
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

proc validate_ListMultiplexPrograms_606357(path: JsonNode; query: JsonNode;
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
  var valid_606359 = path.getOrDefault("multiplexId")
  valid_606359 = validateParameter(valid_606359, JString, required = true,
                                 default = nil)
  if valid_606359 != nil:
    section.add "multiplexId", valid_606359
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  section = newJObject()
  var valid_606360 = query.getOrDefault("nextToken")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "nextToken", valid_606360
  var valid_606361 = query.getOrDefault("MaxResults")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "MaxResults", valid_606361
  var valid_606362 = query.getOrDefault("NextToken")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "NextToken", valid_606362
  var valid_606363 = query.getOrDefault("maxResults")
  valid_606363 = validateParameter(valid_606363, JInt, required = false, default = nil)
  if valid_606363 != nil:
    section.add "maxResults", valid_606363
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
  var valid_606364 = header.getOrDefault("X-Amz-Signature")
  valid_606364 = validateParameter(valid_606364, JString, required = false,
                                 default = nil)
  if valid_606364 != nil:
    section.add "X-Amz-Signature", valid_606364
  var valid_606365 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606365 = validateParameter(valid_606365, JString, required = false,
                                 default = nil)
  if valid_606365 != nil:
    section.add "X-Amz-Content-Sha256", valid_606365
  var valid_606366 = header.getOrDefault("X-Amz-Date")
  valid_606366 = validateParameter(valid_606366, JString, required = false,
                                 default = nil)
  if valid_606366 != nil:
    section.add "X-Amz-Date", valid_606366
  var valid_606367 = header.getOrDefault("X-Amz-Credential")
  valid_606367 = validateParameter(valid_606367, JString, required = false,
                                 default = nil)
  if valid_606367 != nil:
    section.add "X-Amz-Credential", valid_606367
  var valid_606368 = header.getOrDefault("X-Amz-Security-Token")
  valid_606368 = validateParameter(valid_606368, JString, required = false,
                                 default = nil)
  if valid_606368 != nil:
    section.add "X-Amz-Security-Token", valid_606368
  var valid_606369 = header.getOrDefault("X-Amz-Algorithm")
  valid_606369 = validateParameter(valid_606369, JString, required = false,
                                 default = nil)
  if valid_606369 != nil:
    section.add "X-Amz-Algorithm", valid_606369
  var valid_606370 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606370 = validateParameter(valid_606370, JString, required = false,
                                 default = nil)
  if valid_606370 != nil:
    section.add "X-Amz-SignedHeaders", valid_606370
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606371: Call_ListMultiplexPrograms_606356; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the programs that currently exist for a specific multiplex.
  ## 
  let valid = call_606371.validator(path, query, header, formData, body)
  let scheme = call_606371.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606371.url(scheme.get, call_606371.host, call_606371.base,
                         call_606371.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606371, url, valid)

proc call*(call_606372: Call_ListMultiplexPrograms_606356; multiplexId: string;
          nextToken: string = ""; MaxResults: string = ""; NextToken: string = "";
          maxResults: int = 0): Recallable =
  ## listMultiplexPrograms
  ## List the programs that currently exist for a specific multiplex.
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  var path_606373 = newJObject()
  var query_606374 = newJObject()
  add(query_606374, "nextToken", newJString(nextToken))
  add(query_606374, "MaxResults", newJString(MaxResults))
  add(query_606374, "NextToken", newJString(NextToken))
  add(path_606373, "multiplexId", newJString(multiplexId))
  add(query_606374, "maxResults", newJInt(maxResults))
  result = call_606372.call(path_606373, query_606374, nil, nil, nil)

var listMultiplexPrograms* = Call_ListMultiplexPrograms_606356(
    name: "listMultiplexPrograms", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs",
    validator: validate_ListMultiplexPrograms_606357, base: "/",
    url: url_ListMultiplexPrograms_606358, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_606405 = ref object of OpenApiRestCall_605589
proc url_CreateTags_606407(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateTags_606406(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606408 = path.getOrDefault("resource-arn")
  valid_606408 = validateParameter(valid_606408, JString, required = true,
                                 default = nil)
  if valid_606408 != nil:
    section.add "resource-arn", valid_606408
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
  var valid_606409 = header.getOrDefault("X-Amz-Signature")
  valid_606409 = validateParameter(valid_606409, JString, required = false,
                                 default = nil)
  if valid_606409 != nil:
    section.add "X-Amz-Signature", valid_606409
  var valid_606410 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606410 = validateParameter(valid_606410, JString, required = false,
                                 default = nil)
  if valid_606410 != nil:
    section.add "X-Amz-Content-Sha256", valid_606410
  var valid_606411 = header.getOrDefault("X-Amz-Date")
  valid_606411 = validateParameter(valid_606411, JString, required = false,
                                 default = nil)
  if valid_606411 != nil:
    section.add "X-Amz-Date", valid_606411
  var valid_606412 = header.getOrDefault("X-Amz-Credential")
  valid_606412 = validateParameter(valid_606412, JString, required = false,
                                 default = nil)
  if valid_606412 != nil:
    section.add "X-Amz-Credential", valid_606412
  var valid_606413 = header.getOrDefault("X-Amz-Security-Token")
  valid_606413 = validateParameter(valid_606413, JString, required = false,
                                 default = nil)
  if valid_606413 != nil:
    section.add "X-Amz-Security-Token", valid_606413
  var valid_606414 = header.getOrDefault("X-Amz-Algorithm")
  valid_606414 = validateParameter(valid_606414, JString, required = false,
                                 default = nil)
  if valid_606414 != nil:
    section.add "X-Amz-Algorithm", valid_606414
  var valid_606415 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-SignedHeaders", valid_606415
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606417: Call_CreateTags_606405; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create tags for a resource
  ## 
  let valid = call_606417.validator(path, query, header, formData, body)
  let scheme = call_606417.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606417.url(scheme.get, call_606417.host, call_606417.base,
                         call_606417.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606417, url, valid)

proc call*(call_606418: Call_CreateTags_606405; resourceArn: string; body: JsonNode): Recallable =
  ## createTags
  ## Create tags for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_606419 = newJObject()
  var body_606420 = newJObject()
  add(path_606419, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_606420 = body
  result = call_606418.call(path_606419, nil, nil, nil, body_606420)

var createTags* = Call_CreateTags_606405(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "medialive.amazonaws.com",
                                      route: "/prod/tags/{resource-arn}",
                                      validator: validate_CreateTags_606406,
                                      base: "/", url: url_CreateTags_606407,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606391 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606393(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_606392(path: JsonNode; query: JsonNode;
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
  var valid_606394 = path.getOrDefault("resource-arn")
  valid_606394 = validateParameter(valid_606394, JString, required = true,
                                 default = nil)
  if valid_606394 != nil:
    section.add "resource-arn", valid_606394
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
  var valid_606395 = header.getOrDefault("X-Amz-Signature")
  valid_606395 = validateParameter(valid_606395, JString, required = false,
                                 default = nil)
  if valid_606395 != nil:
    section.add "X-Amz-Signature", valid_606395
  var valid_606396 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606396 = validateParameter(valid_606396, JString, required = false,
                                 default = nil)
  if valid_606396 != nil:
    section.add "X-Amz-Content-Sha256", valid_606396
  var valid_606397 = header.getOrDefault("X-Amz-Date")
  valid_606397 = validateParameter(valid_606397, JString, required = false,
                                 default = nil)
  if valid_606397 != nil:
    section.add "X-Amz-Date", valid_606397
  var valid_606398 = header.getOrDefault("X-Amz-Credential")
  valid_606398 = validateParameter(valid_606398, JString, required = false,
                                 default = nil)
  if valid_606398 != nil:
    section.add "X-Amz-Credential", valid_606398
  var valid_606399 = header.getOrDefault("X-Amz-Security-Token")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Security-Token", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Algorithm")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Algorithm", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-SignedHeaders", valid_606401
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606402: Call_ListTagsForResource_606391; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of tags that have been created for a resource
  ## 
  let valid = call_606402.validator(path, query, header, formData, body)
  let scheme = call_606402.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606402.url(scheme.get, call_606402.host, call_606402.base,
                         call_606402.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606402, url, valid)

proc call*(call_606403: Call_ListTagsForResource_606391; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Produces list of tags that have been created for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  var path_606404 = newJObject()
  add(path_606404, "resource-arn", newJString(resourceArn))
  result = call_606403.call(path_606404, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606391(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/tags/{resource-arn}",
    validator: validate_ListTagsForResource_606392, base: "/",
    url: url_ListTagsForResource_606393, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_606435 = ref object of OpenApiRestCall_605589
proc url_UpdateChannel_606437(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateChannel_606436(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606438 = path.getOrDefault("channelId")
  valid_606438 = validateParameter(valid_606438, JString, required = true,
                                 default = nil)
  if valid_606438 != nil:
    section.add "channelId", valid_606438
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
  var valid_606439 = header.getOrDefault("X-Amz-Signature")
  valid_606439 = validateParameter(valid_606439, JString, required = false,
                                 default = nil)
  if valid_606439 != nil:
    section.add "X-Amz-Signature", valid_606439
  var valid_606440 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606440 = validateParameter(valid_606440, JString, required = false,
                                 default = nil)
  if valid_606440 != nil:
    section.add "X-Amz-Content-Sha256", valid_606440
  var valid_606441 = header.getOrDefault("X-Amz-Date")
  valid_606441 = validateParameter(valid_606441, JString, required = false,
                                 default = nil)
  if valid_606441 != nil:
    section.add "X-Amz-Date", valid_606441
  var valid_606442 = header.getOrDefault("X-Amz-Credential")
  valid_606442 = validateParameter(valid_606442, JString, required = false,
                                 default = nil)
  if valid_606442 != nil:
    section.add "X-Amz-Credential", valid_606442
  var valid_606443 = header.getOrDefault("X-Amz-Security-Token")
  valid_606443 = validateParameter(valid_606443, JString, required = false,
                                 default = nil)
  if valid_606443 != nil:
    section.add "X-Amz-Security-Token", valid_606443
  var valid_606444 = header.getOrDefault("X-Amz-Algorithm")
  valid_606444 = validateParameter(valid_606444, JString, required = false,
                                 default = nil)
  if valid_606444 != nil:
    section.add "X-Amz-Algorithm", valid_606444
  var valid_606445 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-SignedHeaders", valid_606445
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606447: Call_UpdateChannel_606435; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a channel.
  ## 
  let valid = call_606447.validator(path, query, header, formData, body)
  let scheme = call_606447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606447.url(scheme.get, call_606447.host, call_606447.base,
                         call_606447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606447, url, valid)

proc call*(call_606448: Call_UpdateChannel_606435; channelId: string; body: JsonNode): Recallable =
  ## updateChannel
  ## Updates a channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_606449 = newJObject()
  var body_606450 = newJObject()
  add(path_606449, "channelId", newJString(channelId))
  if body != nil:
    body_606450 = body
  result = call_606448.call(path_606449, nil, nil, nil, body_606450)

var updateChannel* = Call_UpdateChannel_606435(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_UpdateChannel_606436,
    base: "/", url: url_UpdateChannel_606437, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_606421 = ref object of OpenApiRestCall_605589
proc url_DescribeChannel_606423(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeChannel_606422(path: JsonNode; query: JsonNode;
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
  var valid_606424 = path.getOrDefault("channelId")
  valid_606424 = validateParameter(valid_606424, JString, required = true,
                                 default = nil)
  if valid_606424 != nil:
    section.add "channelId", valid_606424
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
  var valid_606425 = header.getOrDefault("X-Amz-Signature")
  valid_606425 = validateParameter(valid_606425, JString, required = false,
                                 default = nil)
  if valid_606425 != nil:
    section.add "X-Amz-Signature", valid_606425
  var valid_606426 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606426 = validateParameter(valid_606426, JString, required = false,
                                 default = nil)
  if valid_606426 != nil:
    section.add "X-Amz-Content-Sha256", valid_606426
  var valid_606427 = header.getOrDefault("X-Amz-Date")
  valid_606427 = validateParameter(valid_606427, JString, required = false,
                                 default = nil)
  if valid_606427 != nil:
    section.add "X-Amz-Date", valid_606427
  var valid_606428 = header.getOrDefault("X-Amz-Credential")
  valid_606428 = validateParameter(valid_606428, JString, required = false,
                                 default = nil)
  if valid_606428 != nil:
    section.add "X-Amz-Credential", valid_606428
  var valid_606429 = header.getOrDefault("X-Amz-Security-Token")
  valid_606429 = validateParameter(valid_606429, JString, required = false,
                                 default = nil)
  if valid_606429 != nil:
    section.add "X-Amz-Security-Token", valid_606429
  var valid_606430 = header.getOrDefault("X-Amz-Algorithm")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Algorithm", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-SignedHeaders", valid_606431
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606432: Call_DescribeChannel_606421; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a channel
  ## 
  let valid = call_606432.validator(path, query, header, formData, body)
  let scheme = call_606432.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606432.url(scheme.get, call_606432.host, call_606432.base,
                         call_606432.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606432, url, valid)

proc call*(call_606433: Call_DescribeChannel_606421; channelId: string): Recallable =
  ## describeChannel
  ## Gets details about a channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_606434 = newJObject()
  add(path_606434, "channelId", newJString(channelId))
  result = call_606433.call(path_606434, nil, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_606421(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_DescribeChannel_606422,
    base: "/", url: url_DescribeChannel_606423, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_606451 = ref object of OpenApiRestCall_605589
proc url_DeleteChannel_606453(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteChannel_606452(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606454 = path.getOrDefault("channelId")
  valid_606454 = validateParameter(valid_606454, JString, required = true,
                                 default = nil)
  if valid_606454 != nil:
    section.add "channelId", valid_606454
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
  var valid_606455 = header.getOrDefault("X-Amz-Signature")
  valid_606455 = validateParameter(valid_606455, JString, required = false,
                                 default = nil)
  if valid_606455 != nil:
    section.add "X-Amz-Signature", valid_606455
  var valid_606456 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606456 = validateParameter(valid_606456, JString, required = false,
                                 default = nil)
  if valid_606456 != nil:
    section.add "X-Amz-Content-Sha256", valid_606456
  var valid_606457 = header.getOrDefault("X-Amz-Date")
  valid_606457 = validateParameter(valid_606457, JString, required = false,
                                 default = nil)
  if valid_606457 != nil:
    section.add "X-Amz-Date", valid_606457
  var valid_606458 = header.getOrDefault("X-Amz-Credential")
  valid_606458 = validateParameter(valid_606458, JString, required = false,
                                 default = nil)
  if valid_606458 != nil:
    section.add "X-Amz-Credential", valid_606458
  var valid_606459 = header.getOrDefault("X-Amz-Security-Token")
  valid_606459 = validateParameter(valid_606459, JString, required = false,
                                 default = nil)
  if valid_606459 != nil:
    section.add "X-Amz-Security-Token", valid_606459
  var valid_606460 = header.getOrDefault("X-Amz-Algorithm")
  valid_606460 = validateParameter(valid_606460, JString, required = false,
                                 default = nil)
  if valid_606460 != nil:
    section.add "X-Amz-Algorithm", valid_606460
  var valid_606461 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606461 = validateParameter(valid_606461, JString, required = false,
                                 default = nil)
  if valid_606461 != nil:
    section.add "X-Amz-SignedHeaders", valid_606461
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606462: Call_DeleteChannel_606451; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts deletion of channel. The associated outputs are also deleted.
  ## 
  let valid = call_606462.validator(path, query, header, formData, body)
  let scheme = call_606462.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606462.url(scheme.get, call_606462.host, call_606462.base,
                         call_606462.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606462, url, valid)

proc call*(call_606463: Call_DeleteChannel_606451; channelId: string): Recallable =
  ## deleteChannel
  ## Starts deletion of channel. The associated outputs are also deleted.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_606464 = newJObject()
  add(path_606464, "channelId", newJString(channelId))
  result = call_606463.call(path_606464, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_606451(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_DeleteChannel_606452,
    base: "/", url: url_DeleteChannel_606453, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInput_606479 = ref object of OpenApiRestCall_605589
proc url_UpdateInput_606481(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateInput_606480(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606482 = path.getOrDefault("inputId")
  valid_606482 = validateParameter(valid_606482, JString, required = true,
                                 default = nil)
  if valid_606482 != nil:
    section.add "inputId", valid_606482
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
  var valid_606483 = header.getOrDefault("X-Amz-Signature")
  valid_606483 = validateParameter(valid_606483, JString, required = false,
                                 default = nil)
  if valid_606483 != nil:
    section.add "X-Amz-Signature", valid_606483
  var valid_606484 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606484 = validateParameter(valid_606484, JString, required = false,
                                 default = nil)
  if valid_606484 != nil:
    section.add "X-Amz-Content-Sha256", valid_606484
  var valid_606485 = header.getOrDefault("X-Amz-Date")
  valid_606485 = validateParameter(valid_606485, JString, required = false,
                                 default = nil)
  if valid_606485 != nil:
    section.add "X-Amz-Date", valid_606485
  var valid_606486 = header.getOrDefault("X-Amz-Credential")
  valid_606486 = validateParameter(valid_606486, JString, required = false,
                                 default = nil)
  if valid_606486 != nil:
    section.add "X-Amz-Credential", valid_606486
  var valid_606487 = header.getOrDefault("X-Amz-Security-Token")
  valid_606487 = validateParameter(valid_606487, JString, required = false,
                                 default = nil)
  if valid_606487 != nil:
    section.add "X-Amz-Security-Token", valid_606487
  var valid_606488 = header.getOrDefault("X-Amz-Algorithm")
  valid_606488 = validateParameter(valid_606488, JString, required = false,
                                 default = nil)
  if valid_606488 != nil:
    section.add "X-Amz-Algorithm", valid_606488
  var valid_606489 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606489 = validateParameter(valid_606489, JString, required = false,
                                 default = nil)
  if valid_606489 != nil:
    section.add "X-Amz-SignedHeaders", valid_606489
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606491: Call_UpdateInput_606479; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an input.
  ## 
  let valid = call_606491.validator(path, query, header, formData, body)
  let scheme = call_606491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606491.url(scheme.get, call_606491.host, call_606491.base,
                         call_606491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606491, url, valid)

proc call*(call_606492: Call_UpdateInput_606479; body: JsonNode; inputId: string): Recallable =
  ## updateInput
  ## Updates an input.
  ##   body: JObject (required)
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_606493 = newJObject()
  var body_606494 = newJObject()
  if body != nil:
    body_606494 = body
  add(path_606493, "inputId", newJString(inputId))
  result = call_606492.call(path_606493, nil, nil, nil, body_606494)

var updateInput* = Call_UpdateInput_606479(name: "updateInput",
                                        meth: HttpMethod.HttpPut,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs/{inputId}",
                                        validator: validate_UpdateInput_606480,
                                        base: "/", url: url_UpdateInput_606481,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInput_606465 = ref object of OpenApiRestCall_605589
proc url_DescribeInput_606467(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeInput_606466(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606468 = path.getOrDefault("inputId")
  valid_606468 = validateParameter(valid_606468, JString, required = true,
                                 default = nil)
  if valid_606468 != nil:
    section.add "inputId", valid_606468
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
  var valid_606469 = header.getOrDefault("X-Amz-Signature")
  valid_606469 = validateParameter(valid_606469, JString, required = false,
                                 default = nil)
  if valid_606469 != nil:
    section.add "X-Amz-Signature", valid_606469
  var valid_606470 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606470 = validateParameter(valid_606470, JString, required = false,
                                 default = nil)
  if valid_606470 != nil:
    section.add "X-Amz-Content-Sha256", valid_606470
  var valid_606471 = header.getOrDefault("X-Amz-Date")
  valid_606471 = validateParameter(valid_606471, JString, required = false,
                                 default = nil)
  if valid_606471 != nil:
    section.add "X-Amz-Date", valid_606471
  var valid_606472 = header.getOrDefault("X-Amz-Credential")
  valid_606472 = validateParameter(valid_606472, JString, required = false,
                                 default = nil)
  if valid_606472 != nil:
    section.add "X-Amz-Credential", valid_606472
  var valid_606473 = header.getOrDefault("X-Amz-Security-Token")
  valid_606473 = validateParameter(valid_606473, JString, required = false,
                                 default = nil)
  if valid_606473 != nil:
    section.add "X-Amz-Security-Token", valid_606473
  var valid_606474 = header.getOrDefault("X-Amz-Algorithm")
  valid_606474 = validateParameter(valid_606474, JString, required = false,
                                 default = nil)
  if valid_606474 != nil:
    section.add "X-Amz-Algorithm", valid_606474
  var valid_606475 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606475 = validateParameter(valid_606475, JString, required = false,
                                 default = nil)
  if valid_606475 != nil:
    section.add "X-Amz-SignedHeaders", valid_606475
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606476: Call_DescribeInput_606465; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces details about an input
  ## 
  let valid = call_606476.validator(path, query, header, formData, body)
  let scheme = call_606476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606476.url(scheme.get, call_606476.host, call_606476.base,
                         call_606476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606476, url, valid)

proc call*(call_606477: Call_DescribeInput_606465; inputId: string): Recallable =
  ## describeInput
  ## Produces details about an input
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_606478 = newJObject()
  add(path_606478, "inputId", newJString(inputId))
  result = call_606477.call(path_606478, nil, nil, nil, nil)

var describeInput* = Call_DescribeInput_606465(name: "describeInput",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/inputs/{inputId}", validator: validate_DescribeInput_606466,
    base: "/", url: url_DescribeInput_606467, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInput_606495 = ref object of OpenApiRestCall_605589
proc url_DeleteInput_606497(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInput_606496(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606498 = path.getOrDefault("inputId")
  valid_606498 = validateParameter(valid_606498, JString, required = true,
                                 default = nil)
  if valid_606498 != nil:
    section.add "inputId", valid_606498
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
  var valid_606499 = header.getOrDefault("X-Amz-Signature")
  valid_606499 = validateParameter(valid_606499, JString, required = false,
                                 default = nil)
  if valid_606499 != nil:
    section.add "X-Amz-Signature", valid_606499
  var valid_606500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606500 = validateParameter(valid_606500, JString, required = false,
                                 default = nil)
  if valid_606500 != nil:
    section.add "X-Amz-Content-Sha256", valid_606500
  var valid_606501 = header.getOrDefault("X-Amz-Date")
  valid_606501 = validateParameter(valid_606501, JString, required = false,
                                 default = nil)
  if valid_606501 != nil:
    section.add "X-Amz-Date", valid_606501
  var valid_606502 = header.getOrDefault("X-Amz-Credential")
  valid_606502 = validateParameter(valid_606502, JString, required = false,
                                 default = nil)
  if valid_606502 != nil:
    section.add "X-Amz-Credential", valid_606502
  var valid_606503 = header.getOrDefault("X-Amz-Security-Token")
  valid_606503 = validateParameter(valid_606503, JString, required = false,
                                 default = nil)
  if valid_606503 != nil:
    section.add "X-Amz-Security-Token", valid_606503
  var valid_606504 = header.getOrDefault("X-Amz-Algorithm")
  valid_606504 = validateParameter(valid_606504, JString, required = false,
                                 default = nil)
  if valid_606504 != nil:
    section.add "X-Amz-Algorithm", valid_606504
  var valid_606505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606505 = validateParameter(valid_606505, JString, required = false,
                                 default = nil)
  if valid_606505 != nil:
    section.add "X-Amz-SignedHeaders", valid_606505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606506: Call_DeleteInput_606495; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the input end point
  ## 
  let valid = call_606506.validator(path, query, header, formData, body)
  let scheme = call_606506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606506.url(scheme.get, call_606506.host, call_606506.base,
                         call_606506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606506, url, valid)

proc call*(call_606507: Call_DeleteInput_606495; inputId: string): Recallable =
  ## deleteInput
  ## Deletes the input end point
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_606508 = newJObject()
  add(path_606508, "inputId", newJString(inputId))
  result = call_606507.call(path_606508, nil, nil, nil, nil)

var deleteInput* = Call_DeleteInput_606495(name: "deleteInput",
                                        meth: HttpMethod.HttpDelete,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs/{inputId}",
                                        validator: validate_DeleteInput_606496,
                                        base: "/", url: url_DeleteInput_606497,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInputSecurityGroup_606523 = ref object of OpenApiRestCall_605589
proc url_UpdateInputSecurityGroup_606525(protocol: Scheme; host: string;
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

proc validate_UpdateInputSecurityGroup_606524(path: JsonNode; query: JsonNode;
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
  var valid_606526 = path.getOrDefault("inputSecurityGroupId")
  valid_606526 = validateParameter(valid_606526, JString, required = true,
                                 default = nil)
  if valid_606526 != nil:
    section.add "inputSecurityGroupId", valid_606526
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
  var valid_606527 = header.getOrDefault("X-Amz-Signature")
  valid_606527 = validateParameter(valid_606527, JString, required = false,
                                 default = nil)
  if valid_606527 != nil:
    section.add "X-Amz-Signature", valid_606527
  var valid_606528 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606528 = validateParameter(valid_606528, JString, required = false,
                                 default = nil)
  if valid_606528 != nil:
    section.add "X-Amz-Content-Sha256", valid_606528
  var valid_606529 = header.getOrDefault("X-Amz-Date")
  valid_606529 = validateParameter(valid_606529, JString, required = false,
                                 default = nil)
  if valid_606529 != nil:
    section.add "X-Amz-Date", valid_606529
  var valid_606530 = header.getOrDefault("X-Amz-Credential")
  valid_606530 = validateParameter(valid_606530, JString, required = false,
                                 default = nil)
  if valid_606530 != nil:
    section.add "X-Amz-Credential", valid_606530
  var valid_606531 = header.getOrDefault("X-Amz-Security-Token")
  valid_606531 = validateParameter(valid_606531, JString, required = false,
                                 default = nil)
  if valid_606531 != nil:
    section.add "X-Amz-Security-Token", valid_606531
  var valid_606532 = header.getOrDefault("X-Amz-Algorithm")
  valid_606532 = validateParameter(valid_606532, JString, required = false,
                                 default = nil)
  if valid_606532 != nil:
    section.add "X-Amz-Algorithm", valid_606532
  var valid_606533 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606533 = validateParameter(valid_606533, JString, required = false,
                                 default = nil)
  if valid_606533 != nil:
    section.add "X-Amz-SignedHeaders", valid_606533
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606535: Call_UpdateInputSecurityGroup_606523; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update an Input Security Group's Whilelists.
  ## 
  let valid = call_606535.validator(path, query, header, formData, body)
  let scheme = call_606535.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606535.url(scheme.get, call_606535.host, call_606535.base,
                         call_606535.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606535, url, valid)

proc call*(call_606536: Call_UpdateInputSecurityGroup_606523;
          inputSecurityGroupId: string; body: JsonNode): Recallable =
  ## updateInputSecurityGroup
  ## Update an Input Security Group's Whilelists.
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_606537 = newJObject()
  var body_606538 = newJObject()
  add(path_606537, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  if body != nil:
    body_606538 = body
  result = call_606536.call(path_606537, nil, nil, nil, body_606538)

var updateInputSecurityGroup* = Call_UpdateInputSecurityGroup_606523(
    name: "updateInputSecurityGroup", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_UpdateInputSecurityGroup_606524, base: "/",
    url: url_UpdateInputSecurityGroup_606525, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInputSecurityGroup_606509 = ref object of OpenApiRestCall_605589
proc url_DescribeInputSecurityGroup_606511(protocol: Scheme; host: string;
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

proc validate_DescribeInputSecurityGroup_606510(path: JsonNode; query: JsonNode;
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
  var valid_606512 = path.getOrDefault("inputSecurityGroupId")
  valid_606512 = validateParameter(valid_606512, JString, required = true,
                                 default = nil)
  if valid_606512 != nil:
    section.add "inputSecurityGroupId", valid_606512
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
  var valid_606513 = header.getOrDefault("X-Amz-Signature")
  valid_606513 = validateParameter(valid_606513, JString, required = false,
                                 default = nil)
  if valid_606513 != nil:
    section.add "X-Amz-Signature", valid_606513
  var valid_606514 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606514 = validateParameter(valid_606514, JString, required = false,
                                 default = nil)
  if valid_606514 != nil:
    section.add "X-Amz-Content-Sha256", valid_606514
  var valid_606515 = header.getOrDefault("X-Amz-Date")
  valid_606515 = validateParameter(valid_606515, JString, required = false,
                                 default = nil)
  if valid_606515 != nil:
    section.add "X-Amz-Date", valid_606515
  var valid_606516 = header.getOrDefault("X-Amz-Credential")
  valid_606516 = validateParameter(valid_606516, JString, required = false,
                                 default = nil)
  if valid_606516 != nil:
    section.add "X-Amz-Credential", valid_606516
  var valid_606517 = header.getOrDefault("X-Amz-Security-Token")
  valid_606517 = validateParameter(valid_606517, JString, required = false,
                                 default = nil)
  if valid_606517 != nil:
    section.add "X-Amz-Security-Token", valid_606517
  var valid_606518 = header.getOrDefault("X-Amz-Algorithm")
  valid_606518 = validateParameter(valid_606518, JString, required = false,
                                 default = nil)
  if valid_606518 != nil:
    section.add "X-Amz-Algorithm", valid_606518
  var valid_606519 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606519 = validateParameter(valid_606519, JString, required = false,
                                 default = nil)
  if valid_606519 != nil:
    section.add "X-Amz-SignedHeaders", valid_606519
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606520: Call_DescribeInputSecurityGroup_606509; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces a summary of an Input Security Group
  ## 
  let valid = call_606520.validator(path, query, header, formData, body)
  let scheme = call_606520.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606520.url(scheme.get, call_606520.host, call_606520.base,
                         call_606520.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606520, url, valid)

proc call*(call_606521: Call_DescribeInputSecurityGroup_606509;
          inputSecurityGroupId: string): Recallable =
  ## describeInputSecurityGroup
  ## Produces a summary of an Input Security Group
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  var path_606522 = newJObject()
  add(path_606522, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  result = call_606521.call(path_606522, nil, nil, nil, nil)

var describeInputSecurityGroup* = Call_DescribeInputSecurityGroup_606509(
    name: "describeInputSecurityGroup", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_DescribeInputSecurityGroup_606510, base: "/",
    url: url_DescribeInputSecurityGroup_606511,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInputSecurityGroup_606539 = ref object of OpenApiRestCall_605589
proc url_DeleteInputSecurityGroup_606541(protocol: Scheme; host: string;
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

proc validate_DeleteInputSecurityGroup_606540(path: JsonNode; query: JsonNode;
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
  var valid_606542 = path.getOrDefault("inputSecurityGroupId")
  valid_606542 = validateParameter(valid_606542, JString, required = true,
                                 default = nil)
  if valid_606542 != nil:
    section.add "inputSecurityGroupId", valid_606542
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
  var valid_606543 = header.getOrDefault("X-Amz-Signature")
  valid_606543 = validateParameter(valid_606543, JString, required = false,
                                 default = nil)
  if valid_606543 != nil:
    section.add "X-Amz-Signature", valid_606543
  var valid_606544 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606544 = validateParameter(valid_606544, JString, required = false,
                                 default = nil)
  if valid_606544 != nil:
    section.add "X-Amz-Content-Sha256", valid_606544
  var valid_606545 = header.getOrDefault("X-Amz-Date")
  valid_606545 = validateParameter(valid_606545, JString, required = false,
                                 default = nil)
  if valid_606545 != nil:
    section.add "X-Amz-Date", valid_606545
  var valid_606546 = header.getOrDefault("X-Amz-Credential")
  valid_606546 = validateParameter(valid_606546, JString, required = false,
                                 default = nil)
  if valid_606546 != nil:
    section.add "X-Amz-Credential", valid_606546
  var valid_606547 = header.getOrDefault("X-Amz-Security-Token")
  valid_606547 = validateParameter(valid_606547, JString, required = false,
                                 default = nil)
  if valid_606547 != nil:
    section.add "X-Amz-Security-Token", valid_606547
  var valid_606548 = header.getOrDefault("X-Amz-Algorithm")
  valid_606548 = validateParameter(valid_606548, JString, required = false,
                                 default = nil)
  if valid_606548 != nil:
    section.add "X-Amz-Algorithm", valid_606548
  var valid_606549 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606549 = validateParameter(valid_606549, JString, required = false,
                                 default = nil)
  if valid_606549 != nil:
    section.add "X-Amz-SignedHeaders", valid_606549
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606550: Call_DeleteInputSecurityGroup_606539; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Input Security Group
  ## 
  let valid = call_606550.validator(path, query, header, formData, body)
  let scheme = call_606550.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606550.url(scheme.get, call_606550.host, call_606550.base,
                         call_606550.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606550, url, valid)

proc call*(call_606551: Call_DeleteInputSecurityGroup_606539;
          inputSecurityGroupId: string): Recallable =
  ## deleteInputSecurityGroup
  ## Deletes an Input Security Group
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  var path_606552 = newJObject()
  add(path_606552, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  result = call_606551.call(path_606552, nil, nil, nil, nil)

var deleteInputSecurityGroup* = Call_DeleteInputSecurityGroup_606539(
    name: "deleteInputSecurityGroup", meth: HttpMethod.HttpDelete,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_DeleteInputSecurityGroup_606540, base: "/",
    url: url_DeleteInputSecurityGroup_606541, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMultiplex_606567 = ref object of OpenApiRestCall_605589
proc url_UpdateMultiplex_606569(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMultiplex_606568(path: JsonNode; query: JsonNode;
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
  var valid_606570 = path.getOrDefault("multiplexId")
  valid_606570 = validateParameter(valid_606570, JString, required = true,
                                 default = nil)
  if valid_606570 != nil:
    section.add "multiplexId", valid_606570
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
  var valid_606571 = header.getOrDefault("X-Amz-Signature")
  valid_606571 = validateParameter(valid_606571, JString, required = false,
                                 default = nil)
  if valid_606571 != nil:
    section.add "X-Amz-Signature", valid_606571
  var valid_606572 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606572 = validateParameter(valid_606572, JString, required = false,
                                 default = nil)
  if valid_606572 != nil:
    section.add "X-Amz-Content-Sha256", valid_606572
  var valid_606573 = header.getOrDefault("X-Amz-Date")
  valid_606573 = validateParameter(valid_606573, JString, required = false,
                                 default = nil)
  if valid_606573 != nil:
    section.add "X-Amz-Date", valid_606573
  var valid_606574 = header.getOrDefault("X-Amz-Credential")
  valid_606574 = validateParameter(valid_606574, JString, required = false,
                                 default = nil)
  if valid_606574 != nil:
    section.add "X-Amz-Credential", valid_606574
  var valid_606575 = header.getOrDefault("X-Amz-Security-Token")
  valid_606575 = validateParameter(valid_606575, JString, required = false,
                                 default = nil)
  if valid_606575 != nil:
    section.add "X-Amz-Security-Token", valid_606575
  var valid_606576 = header.getOrDefault("X-Amz-Algorithm")
  valid_606576 = validateParameter(valid_606576, JString, required = false,
                                 default = nil)
  if valid_606576 != nil:
    section.add "X-Amz-Algorithm", valid_606576
  var valid_606577 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606577 = validateParameter(valid_606577, JString, required = false,
                                 default = nil)
  if valid_606577 != nil:
    section.add "X-Amz-SignedHeaders", valid_606577
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606579: Call_UpdateMultiplex_606567; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a multiplex.
  ## 
  let valid = call_606579.validator(path, query, header, formData, body)
  let scheme = call_606579.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606579.url(scheme.get, call_606579.host, call_606579.base,
                         call_606579.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606579, url, valid)

proc call*(call_606580: Call_UpdateMultiplex_606567; body: JsonNode;
          multiplexId: string): Recallable =
  ## updateMultiplex
  ## Updates a multiplex.
  ##   body: JObject (required)
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_606581 = newJObject()
  var body_606582 = newJObject()
  if body != nil:
    body_606582 = body
  add(path_606581, "multiplexId", newJString(multiplexId))
  result = call_606580.call(path_606581, nil, nil, nil, body_606582)

var updateMultiplex* = Call_UpdateMultiplex_606567(name: "updateMultiplex",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}", validator: validate_UpdateMultiplex_606568,
    base: "/", url: url_UpdateMultiplex_606569, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMultiplex_606553 = ref object of OpenApiRestCall_605589
proc url_DescribeMultiplex_606555(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeMultiplex_606554(path: JsonNode; query: JsonNode;
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
  var valid_606556 = path.getOrDefault("multiplexId")
  valid_606556 = validateParameter(valid_606556, JString, required = true,
                                 default = nil)
  if valid_606556 != nil:
    section.add "multiplexId", valid_606556
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
  var valid_606557 = header.getOrDefault("X-Amz-Signature")
  valid_606557 = validateParameter(valid_606557, JString, required = false,
                                 default = nil)
  if valid_606557 != nil:
    section.add "X-Amz-Signature", valid_606557
  var valid_606558 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606558 = validateParameter(valid_606558, JString, required = false,
                                 default = nil)
  if valid_606558 != nil:
    section.add "X-Amz-Content-Sha256", valid_606558
  var valid_606559 = header.getOrDefault("X-Amz-Date")
  valid_606559 = validateParameter(valid_606559, JString, required = false,
                                 default = nil)
  if valid_606559 != nil:
    section.add "X-Amz-Date", valid_606559
  var valid_606560 = header.getOrDefault("X-Amz-Credential")
  valid_606560 = validateParameter(valid_606560, JString, required = false,
                                 default = nil)
  if valid_606560 != nil:
    section.add "X-Amz-Credential", valid_606560
  var valid_606561 = header.getOrDefault("X-Amz-Security-Token")
  valid_606561 = validateParameter(valid_606561, JString, required = false,
                                 default = nil)
  if valid_606561 != nil:
    section.add "X-Amz-Security-Token", valid_606561
  var valid_606562 = header.getOrDefault("X-Amz-Algorithm")
  valid_606562 = validateParameter(valid_606562, JString, required = false,
                                 default = nil)
  if valid_606562 != nil:
    section.add "X-Amz-Algorithm", valid_606562
  var valid_606563 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606563 = validateParameter(valid_606563, JString, required = false,
                                 default = nil)
  if valid_606563 != nil:
    section.add "X-Amz-SignedHeaders", valid_606563
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606564: Call_DescribeMultiplex_606553; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a multiplex.
  ## 
  let valid = call_606564.validator(path, query, header, formData, body)
  let scheme = call_606564.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606564.url(scheme.get, call_606564.host, call_606564.base,
                         call_606564.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606564, url, valid)

proc call*(call_606565: Call_DescribeMultiplex_606553; multiplexId: string): Recallable =
  ## describeMultiplex
  ## Gets details about a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_606566 = newJObject()
  add(path_606566, "multiplexId", newJString(multiplexId))
  result = call_606565.call(path_606566, nil, nil, nil, nil)

var describeMultiplex* = Call_DescribeMultiplex_606553(name: "describeMultiplex",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}",
    validator: validate_DescribeMultiplex_606554, base: "/",
    url: url_DescribeMultiplex_606555, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMultiplex_606583 = ref object of OpenApiRestCall_605589
proc url_DeleteMultiplex_606585(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMultiplex_606584(path: JsonNode; query: JsonNode;
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
  var valid_606586 = path.getOrDefault("multiplexId")
  valid_606586 = validateParameter(valid_606586, JString, required = true,
                                 default = nil)
  if valid_606586 != nil:
    section.add "multiplexId", valid_606586
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
  var valid_606587 = header.getOrDefault("X-Amz-Signature")
  valid_606587 = validateParameter(valid_606587, JString, required = false,
                                 default = nil)
  if valid_606587 != nil:
    section.add "X-Amz-Signature", valid_606587
  var valid_606588 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606588 = validateParameter(valid_606588, JString, required = false,
                                 default = nil)
  if valid_606588 != nil:
    section.add "X-Amz-Content-Sha256", valid_606588
  var valid_606589 = header.getOrDefault("X-Amz-Date")
  valid_606589 = validateParameter(valid_606589, JString, required = false,
                                 default = nil)
  if valid_606589 != nil:
    section.add "X-Amz-Date", valid_606589
  var valid_606590 = header.getOrDefault("X-Amz-Credential")
  valid_606590 = validateParameter(valid_606590, JString, required = false,
                                 default = nil)
  if valid_606590 != nil:
    section.add "X-Amz-Credential", valid_606590
  var valid_606591 = header.getOrDefault("X-Amz-Security-Token")
  valid_606591 = validateParameter(valid_606591, JString, required = false,
                                 default = nil)
  if valid_606591 != nil:
    section.add "X-Amz-Security-Token", valid_606591
  var valid_606592 = header.getOrDefault("X-Amz-Algorithm")
  valid_606592 = validateParameter(valid_606592, JString, required = false,
                                 default = nil)
  if valid_606592 != nil:
    section.add "X-Amz-Algorithm", valid_606592
  var valid_606593 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606593 = validateParameter(valid_606593, JString, required = false,
                                 default = nil)
  if valid_606593 != nil:
    section.add "X-Amz-SignedHeaders", valid_606593
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606594: Call_DeleteMultiplex_606583; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a multiplex. The multiplex must be idle.
  ## 
  let valid = call_606594.validator(path, query, header, formData, body)
  let scheme = call_606594.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606594.url(scheme.get, call_606594.host, call_606594.base,
                         call_606594.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606594, url, valid)

proc call*(call_606595: Call_DeleteMultiplex_606583; multiplexId: string): Recallable =
  ## deleteMultiplex
  ## Delete a multiplex. The multiplex must be idle.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_606596 = newJObject()
  add(path_606596, "multiplexId", newJString(multiplexId))
  result = call_606595.call(path_606596, nil, nil, nil, nil)

var deleteMultiplex* = Call_DeleteMultiplex_606583(name: "deleteMultiplex",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}", validator: validate_DeleteMultiplex_606584,
    base: "/", url: url_DeleteMultiplex_606585, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMultiplexProgram_606612 = ref object of OpenApiRestCall_605589
proc url_UpdateMultiplexProgram_606614(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMultiplexProgram_606613(path: JsonNode; query: JsonNode;
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
  var valid_606615 = path.getOrDefault("multiplexId")
  valid_606615 = validateParameter(valid_606615, JString, required = true,
                                 default = nil)
  if valid_606615 != nil:
    section.add "multiplexId", valid_606615
  var valid_606616 = path.getOrDefault("programName")
  valid_606616 = validateParameter(valid_606616, JString, required = true,
                                 default = nil)
  if valid_606616 != nil:
    section.add "programName", valid_606616
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
  var valid_606617 = header.getOrDefault("X-Amz-Signature")
  valid_606617 = validateParameter(valid_606617, JString, required = false,
                                 default = nil)
  if valid_606617 != nil:
    section.add "X-Amz-Signature", valid_606617
  var valid_606618 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606618 = validateParameter(valid_606618, JString, required = false,
                                 default = nil)
  if valid_606618 != nil:
    section.add "X-Amz-Content-Sha256", valid_606618
  var valid_606619 = header.getOrDefault("X-Amz-Date")
  valid_606619 = validateParameter(valid_606619, JString, required = false,
                                 default = nil)
  if valid_606619 != nil:
    section.add "X-Amz-Date", valid_606619
  var valid_606620 = header.getOrDefault("X-Amz-Credential")
  valid_606620 = validateParameter(valid_606620, JString, required = false,
                                 default = nil)
  if valid_606620 != nil:
    section.add "X-Amz-Credential", valid_606620
  var valid_606621 = header.getOrDefault("X-Amz-Security-Token")
  valid_606621 = validateParameter(valid_606621, JString, required = false,
                                 default = nil)
  if valid_606621 != nil:
    section.add "X-Amz-Security-Token", valid_606621
  var valid_606622 = header.getOrDefault("X-Amz-Algorithm")
  valid_606622 = validateParameter(valid_606622, JString, required = false,
                                 default = nil)
  if valid_606622 != nil:
    section.add "X-Amz-Algorithm", valid_606622
  var valid_606623 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606623 = validateParameter(valid_606623, JString, required = false,
                                 default = nil)
  if valid_606623 != nil:
    section.add "X-Amz-SignedHeaders", valid_606623
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606625: Call_UpdateMultiplexProgram_606612; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a program in a multiplex.
  ## 
  let valid = call_606625.validator(path, query, header, formData, body)
  let scheme = call_606625.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606625.url(scheme.get, call_606625.host, call_606625.base,
                         call_606625.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606625, url, valid)

proc call*(call_606626: Call_UpdateMultiplexProgram_606612; body: JsonNode;
          multiplexId: string; programName: string): Recallable =
  ## updateMultiplexProgram
  ## Update a program in a multiplex.
  ##   body: JObject (required)
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   programName: string (required)
  ##              : Placeholder documentation for __string
  var path_606627 = newJObject()
  var body_606628 = newJObject()
  if body != nil:
    body_606628 = body
  add(path_606627, "multiplexId", newJString(multiplexId))
  add(path_606627, "programName", newJString(programName))
  result = call_606626.call(path_606627, nil, nil, nil, body_606628)

var updateMultiplexProgram* = Call_UpdateMultiplexProgram_606612(
    name: "updateMultiplexProgram", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs/{programName}",
    validator: validate_UpdateMultiplexProgram_606613, base: "/",
    url: url_UpdateMultiplexProgram_606614, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMultiplexProgram_606597 = ref object of OpenApiRestCall_605589
proc url_DescribeMultiplexProgram_606599(protocol: Scheme; host: string;
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

proc validate_DescribeMultiplexProgram_606598(path: JsonNode; query: JsonNode;
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
  var valid_606600 = path.getOrDefault("multiplexId")
  valid_606600 = validateParameter(valid_606600, JString, required = true,
                                 default = nil)
  if valid_606600 != nil:
    section.add "multiplexId", valid_606600
  var valid_606601 = path.getOrDefault("programName")
  valid_606601 = validateParameter(valid_606601, JString, required = true,
                                 default = nil)
  if valid_606601 != nil:
    section.add "programName", valid_606601
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
  var valid_606602 = header.getOrDefault("X-Amz-Signature")
  valid_606602 = validateParameter(valid_606602, JString, required = false,
                                 default = nil)
  if valid_606602 != nil:
    section.add "X-Amz-Signature", valid_606602
  var valid_606603 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606603 = validateParameter(valid_606603, JString, required = false,
                                 default = nil)
  if valid_606603 != nil:
    section.add "X-Amz-Content-Sha256", valid_606603
  var valid_606604 = header.getOrDefault("X-Amz-Date")
  valid_606604 = validateParameter(valid_606604, JString, required = false,
                                 default = nil)
  if valid_606604 != nil:
    section.add "X-Amz-Date", valid_606604
  var valid_606605 = header.getOrDefault("X-Amz-Credential")
  valid_606605 = validateParameter(valid_606605, JString, required = false,
                                 default = nil)
  if valid_606605 != nil:
    section.add "X-Amz-Credential", valid_606605
  var valid_606606 = header.getOrDefault("X-Amz-Security-Token")
  valid_606606 = validateParameter(valid_606606, JString, required = false,
                                 default = nil)
  if valid_606606 != nil:
    section.add "X-Amz-Security-Token", valid_606606
  var valid_606607 = header.getOrDefault("X-Amz-Algorithm")
  valid_606607 = validateParameter(valid_606607, JString, required = false,
                                 default = nil)
  if valid_606607 != nil:
    section.add "X-Amz-Algorithm", valid_606607
  var valid_606608 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606608 = validateParameter(valid_606608, JString, required = false,
                                 default = nil)
  if valid_606608 != nil:
    section.add "X-Amz-SignedHeaders", valid_606608
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606609: Call_DescribeMultiplexProgram_606597; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the details for a program in a multiplex.
  ## 
  let valid = call_606609.validator(path, query, header, formData, body)
  let scheme = call_606609.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606609.url(scheme.get, call_606609.host, call_606609.base,
                         call_606609.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606609, url, valid)

proc call*(call_606610: Call_DescribeMultiplexProgram_606597; multiplexId: string;
          programName: string): Recallable =
  ## describeMultiplexProgram
  ## Get the details for a program in a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   programName: string (required)
  ##              : Placeholder documentation for __string
  var path_606611 = newJObject()
  add(path_606611, "multiplexId", newJString(multiplexId))
  add(path_606611, "programName", newJString(programName))
  result = call_606610.call(path_606611, nil, nil, nil, nil)

var describeMultiplexProgram* = Call_DescribeMultiplexProgram_606597(
    name: "describeMultiplexProgram", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs/{programName}",
    validator: validate_DescribeMultiplexProgram_606598, base: "/",
    url: url_DescribeMultiplexProgram_606599, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMultiplexProgram_606629 = ref object of OpenApiRestCall_605589
proc url_DeleteMultiplexProgram_606631(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMultiplexProgram_606630(path: JsonNode; query: JsonNode;
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
  var valid_606632 = path.getOrDefault("multiplexId")
  valid_606632 = validateParameter(valid_606632, JString, required = true,
                                 default = nil)
  if valid_606632 != nil:
    section.add "multiplexId", valid_606632
  var valid_606633 = path.getOrDefault("programName")
  valid_606633 = validateParameter(valid_606633, JString, required = true,
                                 default = nil)
  if valid_606633 != nil:
    section.add "programName", valid_606633
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
  var valid_606634 = header.getOrDefault("X-Amz-Signature")
  valid_606634 = validateParameter(valid_606634, JString, required = false,
                                 default = nil)
  if valid_606634 != nil:
    section.add "X-Amz-Signature", valid_606634
  var valid_606635 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606635 = validateParameter(valid_606635, JString, required = false,
                                 default = nil)
  if valid_606635 != nil:
    section.add "X-Amz-Content-Sha256", valid_606635
  var valid_606636 = header.getOrDefault("X-Amz-Date")
  valid_606636 = validateParameter(valid_606636, JString, required = false,
                                 default = nil)
  if valid_606636 != nil:
    section.add "X-Amz-Date", valid_606636
  var valid_606637 = header.getOrDefault("X-Amz-Credential")
  valid_606637 = validateParameter(valid_606637, JString, required = false,
                                 default = nil)
  if valid_606637 != nil:
    section.add "X-Amz-Credential", valid_606637
  var valid_606638 = header.getOrDefault("X-Amz-Security-Token")
  valid_606638 = validateParameter(valid_606638, JString, required = false,
                                 default = nil)
  if valid_606638 != nil:
    section.add "X-Amz-Security-Token", valid_606638
  var valid_606639 = header.getOrDefault("X-Amz-Algorithm")
  valid_606639 = validateParameter(valid_606639, JString, required = false,
                                 default = nil)
  if valid_606639 != nil:
    section.add "X-Amz-Algorithm", valid_606639
  var valid_606640 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606640 = validateParameter(valid_606640, JString, required = false,
                                 default = nil)
  if valid_606640 != nil:
    section.add "X-Amz-SignedHeaders", valid_606640
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606641: Call_DeleteMultiplexProgram_606629; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a program from a multiplex.
  ## 
  let valid = call_606641.validator(path, query, header, formData, body)
  let scheme = call_606641.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606641.url(scheme.get, call_606641.host, call_606641.base,
                         call_606641.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606641, url, valid)

proc call*(call_606642: Call_DeleteMultiplexProgram_606629; multiplexId: string;
          programName: string): Recallable =
  ## deleteMultiplexProgram
  ## Delete a program from a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   programName: string (required)
  ##              : Placeholder documentation for __string
  var path_606643 = newJObject()
  add(path_606643, "multiplexId", newJString(multiplexId))
  add(path_606643, "programName", newJString(programName))
  result = call_606642.call(path_606643, nil, nil, nil, nil)

var deleteMultiplexProgram* = Call_DeleteMultiplexProgram_606629(
    name: "deleteMultiplexProgram", meth: HttpMethod.HttpDelete,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs/{programName}",
    validator: validate_DeleteMultiplexProgram_606630, base: "/",
    url: url_DeleteMultiplexProgram_606631, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReservation_606658 = ref object of OpenApiRestCall_605589
proc url_UpdateReservation_606660(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateReservation_606659(path: JsonNode; query: JsonNode;
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
  var valid_606661 = path.getOrDefault("reservationId")
  valid_606661 = validateParameter(valid_606661, JString, required = true,
                                 default = nil)
  if valid_606661 != nil:
    section.add "reservationId", valid_606661
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
  var valid_606662 = header.getOrDefault("X-Amz-Signature")
  valid_606662 = validateParameter(valid_606662, JString, required = false,
                                 default = nil)
  if valid_606662 != nil:
    section.add "X-Amz-Signature", valid_606662
  var valid_606663 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606663 = validateParameter(valid_606663, JString, required = false,
                                 default = nil)
  if valid_606663 != nil:
    section.add "X-Amz-Content-Sha256", valid_606663
  var valid_606664 = header.getOrDefault("X-Amz-Date")
  valid_606664 = validateParameter(valid_606664, JString, required = false,
                                 default = nil)
  if valid_606664 != nil:
    section.add "X-Amz-Date", valid_606664
  var valid_606665 = header.getOrDefault("X-Amz-Credential")
  valid_606665 = validateParameter(valid_606665, JString, required = false,
                                 default = nil)
  if valid_606665 != nil:
    section.add "X-Amz-Credential", valid_606665
  var valid_606666 = header.getOrDefault("X-Amz-Security-Token")
  valid_606666 = validateParameter(valid_606666, JString, required = false,
                                 default = nil)
  if valid_606666 != nil:
    section.add "X-Amz-Security-Token", valid_606666
  var valid_606667 = header.getOrDefault("X-Amz-Algorithm")
  valid_606667 = validateParameter(valid_606667, JString, required = false,
                                 default = nil)
  if valid_606667 != nil:
    section.add "X-Amz-Algorithm", valid_606667
  var valid_606668 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606668 = validateParameter(valid_606668, JString, required = false,
                                 default = nil)
  if valid_606668 != nil:
    section.add "X-Amz-SignedHeaders", valid_606668
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606670: Call_UpdateReservation_606658; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update reservation.
  ## 
  let valid = call_606670.validator(path, query, header, formData, body)
  let scheme = call_606670.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606670.url(scheme.get, call_606670.host, call_606670.base,
                         call_606670.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606670, url, valid)

proc call*(call_606671: Call_UpdateReservation_606658; body: JsonNode;
          reservationId: string): Recallable =
  ## updateReservation
  ## Update reservation.
  ##   body: JObject (required)
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_606672 = newJObject()
  var body_606673 = newJObject()
  if body != nil:
    body_606673 = body
  add(path_606672, "reservationId", newJString(reservationId))
  result = call_606671.call(path_606672, nil, nil, nil, body_606673)

var updateReservation* = Call_UpdateReservation_606658(name: "updateReservation",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_UpdateReservation_606659, base: "/",
    url: url_UpdateReservation_606660, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservation_606644 = ref object of OpenApiRestCall_605589
proc url_DescribeReservation_606646(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeReservation_606645(path: JsonNode; query: JsonNode;
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
  var valid_606647 = path.getOrDefault("reservationId")
  valid_606647 = validateParameter(valid_606647, JString, required = true,
                                 default = nil)
  if valid_606647 != nil:
    section.add "reservationId", valid_606647
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
  var valid_606648 = header.getOrDefault("X-Amz-Signature")
  valid_606648 = validateParameter(valid_606648, JString, required = false,
                                 default = nil)
  if valid_606648 != nil:
    section.add "X-Amz-Signature", valid_606648
  var valid_606649 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606649 = validateParameter(valid_606649, JString, required = false,
                                 default = nil)
  if valid_606649 != nil:
    section.add "X-Amz-Content-Sha256", valid_606649
  var valid_606650 = header.getOrDefault("X-Amz-Date")
  valid_606650 = validateParameter(valid_606650, JString, required = false,
                                 default = nil)
  if valid_606650 != nil:
    section.add "X-Amz-Date", valid_606650
  var valid_606651 = header.getOrDefault("X-Amz-Credential")
  valid_606651 = validateParameter(valid_606651, JString, required = false,
                                 default = nil)
  if valid_606651 != nil:
    section.add "X-Amz-Credential", valid_606651
  var valid_606652 = header.getOrDefault("X-Amz-Security-Token")
  valid_606652 = validateParameter(valid_606652, JString, required = false,
                                 default = nil)
  if valid_606652 != nil:
    section.add "X-Amz-Security-Token", valid_606652
  var valid_606653 = header.getOrDefault("X-Amz-Algorithm")
  valid_606653 = validateParameter(valid_606653, JString, required = false,
                                 default = nil)
  if valid_606653 != nil:
    section.add "X-Amz-Algorithm", valid_606653
  var valid_606654 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606654 = validateParameter(valid_606654, JString, required = false,
                                 default = nil)
  if valid_606654 != nil:
    section.add "X-Amz-SignedHeaders", valid_606654
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606655: Call_DescribeReservation_606644; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details for a reservation.
  ## 
  let valid = call_606655.validator(path, query, header, formData, body)
  let scheme = call_606655.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606655.url(scheme.get, call_606655.host, call_606655.base,
                         call_606655.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606655, url, valid)

proc call*(call_606656: Call_DescribeReservation_606644; reservationId: string): Recallable =
  ## describeReservation
  ## Get details for a reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_606657 = newJObject()
  add(path_606657, "reservationId", newJString(reservationId))
  result = call_606656.call(path_606657, nil, nil, nil, nil)

var describeReservation* = Call_DescribeReservation_606644(
    name: "describeReservation", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/reservations/{reservationId}",
    validator: validate_DescribeReservation_606645, base: "/",
    url: url_DescribeReservation_606646, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReservation_606674 = ref object of OpenApiRestCall_605589
proc url_DeleteReservation_606676(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteReservation_606675(path: JsonNode; query: JsonNode;
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
  var valid_606677 = path.getOrDefault("reservationId")
  valid_606677 = validateParameter(valid_606677, JString, required = true,
                                 default = nil)
  if valid_606677 != nil:
    section.add "reservationId", valid_606677
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
  var valid_606678 = header.getOrDefault("X-Amz-Signature")
  valid_606678 = validateParameter(valid_606678, JString, required = false,
                                 default = nil)
  if valid_606678 != nil:
    section.add "X-Amz-Signature", valid_606678
  var valid_606679 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606679 = validateParameter(valid_606679, JString, required = false,
                                 default = nil)
  if valid_606679 != nil:
    section.add "X-Amz-Content-Sha256", valid_606679
  var valid_606680 = header.getOrDefault("X-Amz-Date")
  valid_606680 = validateParameter(valid_606680, JString, required = false,
                                 default = nil)
  if valid_606680 != nil:
    section.add "X-Amz-Date", valid_606680
  var valid_606681 = header.getOrDefault("X-Amz-Credential")
  valid_606681 = validateParameter(valid_606681, JString, required = false,
                                 default = nil)
  if valid_606681 != nil:
    section.add "X-Amz-Credential", valid_606681
  var valid_606682 = header.getOrDefault("X-Amz-Security-Token")
  valid_606682 = validateParameter(valid_606682, JString, required = false,
                                 default = nil)
  if valid_606682 != nil:
    section.add "X-Amz-Security-Token", valid_606682
  var valid_606683 = header.getOrDefault("X-Amz-Algorithm")
  valid_606683 = validateParameter(valid_606683, JString, required = false,
                                 default = nil)
  if valid_606683 != nil:
    section.add "X-Amz-Algorithm", valid_606683
  var valid_606684 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606684 = validateParameter(valid_606684, JString, required = false,
                                 default = nil)
  if valid_606684 != nil:
    section.add "X-Amz-SignedHeaders", valid_606684
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606685: Call_DeleteReservation_606674; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete an expired reservation.
  ## 
  let valid = call_606685.validator(path, query, header, formData, body)
  let scheme = call_606685.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606685.url(scheme.get, call_606685.host, call_606685.base,
                         call_606685.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606685, url, valid)

proc call*(call_606686: Call_DeleteReservation_606674; reservationId: string): Recallable =
  ## deleteReservation
  ## Delete an expired reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_606687 = newJObject()
  add(path_606687, "reservationId", newJString(reservationId))
  result = call_606686.call(path_606687, nil, nil, nil, nil)

var deleteReservation* = Call_DeleteReservation_606674(name: "deleteReservation",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_DeleteReservation_606675, base: "/",
    url: url_DeleteReservation_606676, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_606688 = ref object of OpenApiRestCall_605589
proc url_DeleteTags_606690(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteTags_606689(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606691 = path.getOrDefault("resource-arn")
  valid_606691 = validateParameter(valid_606691, JString, required = true,
                                 default = nil)
  if valid_606691 != nil:
    section.add "resource-arn", valid_606691
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : Placeholder documentation for __listOf__string
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_606692 = query.getOrDefault("tagKeys")
  valid_606692 = validateParameter(valid_606692, JArray, required = true, default = nil)
  if valid_606692 != nil:
    section.add "tagKeys", valid_606692
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
  var valid_606693 = header.getOrDefault("X-Amz-Signature")
  valid_606693 = validateParameter(valid_606693, JString, required = false,
                                 default = nil)
  if valid_606693 != nil:
    section.add "X-Amz-Signature", valid_606693
  var valid_606694 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606694 = validateParameter(valid_606694, JString, required = false,
                                 default = nil)
  if valid_606694 != nil:
    section.add "X-Amz-Content-Sha256", valid_606694
  var valid_606695 = header.getOrDefault("X-Amz-Date")
  valid_606695 = validateParameter(valid_606695, JString, required = false,
                                 default = nil)
  if valid_606695 != nil:
    section.add "X-Amz-Date", valid_606695
  var valid_606696 = header.getOrDefault("X-Amz-Credential")
  valid_606696 = validateParameter(valid_606696, JString, required = false,
                                 default = nil)
  if valid_606696 != nil:
    section.add "X-Amz-Credential", valid_606696
  var valid_606697 = header.getOrDefault("X-Amz-Security-Token")
  valid_606697 = validateParameter(valid_606697, JString, required = false,
                                 default = nil)
  if valid_606697 != nil:
    section.add "X-Amz-Security-Token", valid_606697
  var valid_606698 = header.getOrDefault("X-Amz-Algorithm")
  valid_606698 = validateParameter(valid_606698, JString, required = false,
                                 default = nil)
  if valid_606698 != nil:
    section.add "X-Amz-Algorithm", valid_606698
  var valid_606699 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606699 = validateParameter(valid_606699, JString, required = false,
                                 default = nil)
  if valid_606699 != nil:
    section.add "X-Amz-SignedHeaders", valid_606699
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606700: Call_DeleteTags_606688; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags for a resource
  ## 
  let valid = call_606700.validator(path, query, header, formData, body)
  let scheme = call_606700.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606700.url(scheme.get, call_606700.host, call_606700.base,
                         call_606700.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606700, url, valid)

proc call*(call_606701: Call_DeleteTags_606688; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## deleteTags
  ## Removes tags for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  ##   tagKeys: JArray (required)
  ##          : Placeholder documentation for __listOf__string
  var path_606702 = newJObject()
  var query_606703 = newJObject()
  add(path_606702, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_606703.add "tagKeys", tagKeys
  result = call_606701.call(path_606702, query_606703, nil, nil, nil)

var deleteTags* = Call_DeleteTags_606688(name: "deleteTags",
                                      meth: HttpMethod.HttpDelete,
                                      host: "medialive.amazonaws.com", route: "/prod/tags/{resource-arn}#tagKeys",
                                      validator: validate_DeleteTags_606689,
                                      base: "/", url: url_DeleteTags_606690,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOffering_606704 = ref object of OpenApiRestCall_605589
proc url_DescribeOffering_606706(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeOffering_606705(path: JsonNode; query: JsonNode;
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
  var valid_606707 = path.getOrDefault("offeringId")
  valid_606707 = validateParameter(valid_606707, JString, required = true,
                                 default = nil)
  if valid_606707 != nil:
    section.add "offeringId", valid_606707
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
  var valid_606708 = header.getOrDefault("X-Amz-Signature")
  valid_606708 = validateParameter(valid_606708, JString, required = false,
                                 default = nil)
  if valid_606708 != nil:
    section.add "X-Amz-Signature", valid_606708
  var valid_606709 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606709 = validateParameter(valid_606709, JString, required = false,
                                 default = nil)
  if valid_606709 != nil:
    section.add "X-Amz-Content-Sha256", valid_606709
  var valid_606710 = header.getOrDefault("X-Amz-Date")
  valid_606710 = validateParameter(valid_606710, JString, required = false,
                                 default = nil)
  if valid_606710 != nil:
    section.add "X-Amz-Date", valid_606710
  var valid_606711 = header.getOrDefault("X-Amz-Credential")
  valid_606711 = validateParameter(valid_606711, JString, required = false,
                                 default = nil)
  if valid_606711 != nil:
    section.add "X-Amz-Credential", valid_606711
  var valid_606712 = header.getOrDefault("X-Amz-Security-Token")
  valid_606712 = validateParameter(valid_606712, JString, required = false,
                                 default = nil)
  if valid_606712 != nil:
    section.add "X-Amz-Security-Token", valid_606712
  var valid_606713 = header.getOrDefault("X-Amz-Algorithm")
  valid_606713 = validateParameter(valid_606713, JString, required = false,
                                 default = nil)
  if valid_606713 != nil:
    section.add "X-Amz-Algorithm", valid_606713
  var valid_606714 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606714 = validateParameter(valid_606714, JString, required = false,
                                 default = nil)
  if valid_606714 != nil:
    section.add "X-Amz-SignedHeaders", valid_606714
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606715: Call_DescribeOffering_606704; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details for an offering.
  ## 
  let valid = call_606715.validator(path, query, header, formData, body)
  let scheme = call_606715.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606715.url(scheme.get, call_606715.host, call_606715.base,
                         call_606715.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606715, url, valid)

proc call*(call_606716: Call_DescribeOffering_606704; offeringId: string): Recallable =
  ## describeOffering
  ## Get details for an offering.
  ##   offeringId: string (required)
  ##             : Placeholder documentation for __string
  var path_606717 = newJObject()
  add(path_606717, "offeringId", newJString(offeringId))
  result = call_606716.call(path_606717, nil, nil, nil, nil)

var describeOffering* = Call_DescribeOffering_606704(name: "describeOffering",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/offerings/{offeringId}", validator: validate_DescribeOffering_606705,
    base: "/", url: url_DescribeOffering_606706,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_606718 = ref object of OpenApiRestCall_605589
proc url_ListOfferings_606720(protocol: Scheme; host: string; base: string;
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

proc validate_ListOfferings_606719(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## List offerings available for purchase.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   specialFeature: JString
  ##                 : Placeholder documentation for __string
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   channelClass: JString
  ##               : Placeholder documentation for __string
  ##   NextToken: JString
  ##            : Pagination token
  ##   videoQuality: JString
  ##               : Placeholder documentation for __string
  ##   maximumFramerate: JString
  ##                   : Placeholder documentation for __string
  ##   maximumBitrate: JString
  ##                 : Placeholder documentation for __string
  ##   resourceType: JString
  ##               : Placeholder documentation for __string
  ##   duration: JString
  ##           : Placeholder documentation for __string
  ##   channelConfiguration: JString
  ##                       : Placeholder documentation for __string
  ##   codec: JString
  ##        : Placeholder documentation for __string
  ##   resolution: JString
  ##             : Placeholder documentation for __string
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  section = newJObject()
  var valid_606721 = query.getOrDefault("specialFeature")
  valid_606721 = validateParameter(valid_606721, JString, required = false,
                                 default = nil)
  if valid_606721 != nil:
    section.add "specialFeature", valid_606721
  var valid_606722 = query.getOrDefault("nextToken")
  valid_606722 = validateParameter(valid_606722, JString, required = false,
                                 default = nil)
  if valid_606722 != nil:
    section.add "nextToken", valid_606722
  var valid_606723 = query.getOrDefault("MaxResults")
  valid_606723 = validateParameter(valid_606723, JString, required = false,
                                 default = nil)
  if valid_606723 != nil:
    section.add "MaxResults", valid_606723
  var valid_606724 = query.getOrDefault("channelClass")
  valid_606724 = validateParameter(valid_606724, JString, required = false,
                                 default = nil)
  if valid_606724 != nil:
    section.add "channelClass", valid_606724
  var valid_606725 = query.getOrDefault("NextToken")
  valid_606725 = validateParameter(valid_606725, JString, required = false,
                                 default = nil)
  if valid_606725 != nil:
    section.add "NextToken", valid_606725
  var valid_606726 = query.getOrDefault("videoQuality")
  valid_606726 = validateParameter(valid_606726, JString, required = false,
                                 default = nil)
  if valid_606726 != nil:
    section.add "videoQuality", valid_606726
  var valid_606727 = query.getOrDefault("maximumFramerate")
  valid_606727 = validateParameter(valid_606727, JString, required = false,
                                 default = nil)
  if valid_606727 != nil:
    section.add "maximumFramerate", valid_606727
  var valid_606728 = query.getOrDefault("maximumBitrate")
  valid_606728 = validateParameter(valid_606728, JString, required = false,
                                 default = nil)
  if valid_606728 != nil:
    section.add "maximumBitrate", valid_606728
  var valid_606729 = query.getOrDefault("resourceType")
  valid_606729 = validateParameter(valid_606729, JString, required = false,
                                 default = nil)
  if valid_606729 != nil:
    section.add "resourceType", valid_606729
  var valid_606730 = query.getOrDefault("duration")
  valid_606730 = validateParameter(valid_606730, JString, required = false,
                                 default = nil)
  if valid_606730 != nil:
    section.add "duration", valid_606730
  var valid_606731 = query.getOrDefault("channelConfiguration")
  valid_606731 = validateParameter(valid_606731, JString, required = false,
                                 default = nil)
  if valid_606731 != nil:
    section.add "channelConfiguration", valid_606731
  var valid_606732 = query.getOrDefault("codec")
  valid_606732 = validateParameter(valid_606732, JString, required = false,
                                 default = nil)
  if valid_606732 != nil:
    section.add "codec", valid_606732
  var valid_606733 = query.getOrDefault("resolution")
  valid_606733 = validateParameter(valid_606733, JString, required = false,
                                 default = nil)
  if valid_606733 != nil:
    section.add "resolution", valid_606733
  var valid_606734 = query.getOrDefault("maxResults")
  valid_606734 = validateParameter(valid_606734, JInt, required = false, default = nil)
  if valid_606734 != nil:
    section.add "maxResults", valid_606734
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
  var valid_606735 = header.getOrDefault("X-Amz-Signature")
  valid_606735 = validateParameter(valid_606735, JString, required = false,
                                 default = nil)
  if valid_606735 != nil:
    section.add "X-Amz-Signature", valid_606735
  var valid_606736 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606736 = validateParameter(valid_606736, JString, required = false,
                                 default = nil)
  if valid_606736 != nil:
    section.add "X-Amz-Content-Sha256", valid_606736
  var valid_606737 = header.getOrDefault("X-Amz-Date")
  valid_606737 = validateParameter(valid_606737, JString, required = false,
                                 default = nil)
  if valid_606737 != nil:
    section.add "X-Amz-Date", valid_606737
  var valid_606738 = header.getOrDefault("X-Amz-Credential")
  valid_606738 = validateParameter(valid_606738, JString, required = false,
                                 default = nil)
  if valid_606738 != nil:
    section.add "X-Amz-Credential", valid_606738
  var valid_606739 = header.getOrDefault("X-Amz-Security-Token")
  valid_606739 = validateParameter(valid_606739, JString, required = false,
                                 default = nil)
  if valid_606739 != nil:
    section.add "X-Amz-Security-Token", valid_606739
  var valid_606740 = header.getOrDefault("X-Amz-Algorithm")
  valid_606740 = validateParameter(valid_606740, JString, required = false,
                                 default = nil)
  if valid_606740 != nil:
    section.add "X-Amz-Algorithm", valid_606740
  var valid_606741 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606741 = validateParameter(valid_606741, JString, required = false,
                                 default = nil)
  if valid_606741 != nil:
    section.add "X-Amz-SignedHeaders", valid_606741
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606742: Call_ListOfferings_606718; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List offerings available for purchase.
  ## 
  let valid = call_606742.validator(path, query, header, formData, body)
  let scheme = call_606742.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606742.url(scheme.get, call_606742.host, call_606742.base,
                         call_606742.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606742, url, valid)

proc call*(call_606743: Call_ListOfferings_606718; specialFeature: string = "";
          nextToken: string = ""; MaxResults: string = ""; channelClass: string = "";
          NextToken: string = ""; videoQuality: string = "";
          maximumFramerate: string = ""; maximumBitrate: string = "";
          resourceType: string = ""; duration: string = "";
          channelConfiguration: string = ""; codec: string = "";
          resolution: string = ""; maxResults: int = 0): Recallable =
  ## listOfferings
  ## List offerings available for purchase.
  ##   specialFeature: string
  ##                 : Placeholder documentation for __string
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  ##   channelClass: string
  ##               : Placeholder documentation for __string
  ##   NextToken: string
  ##            : Pagination token
  ##   videoQuality: string
  ##               : Placeholder documentation for __string
  ##   maximumFramerate: string
  ##                   : Placeholder documentation for __string
  ##   maximumBitrate: string
  ##                 : Placeholder documentation for __string
  ##   resourceType: string
  ##               : Placeholder documentation for __string
  ##   duration: string
  ##           : Placeholder documentation for __string
  ##   channelConfiguration: string
  ##                       : Placeholder documentation for __string
  ##   codec: string
  ##        : Placeholder documentation for __string
  ##   resolution: string
  ##             : Placeholder documentation for __string
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  var query_606744 = newJObject()
  add(query_606744, "specialFeature", newJString(specialFeature))
  add(query_606744, "nextToken", newJString(nextToken))
  add(query_606744, "MaxResults", newJString(MaxResults))
  add(query_606744, "channelClass", newJString(channelClass))
  add(query_606744, "NextToken", newJString(NextToken))
  add(query_606744, "videoQuality", newJString(videoQuality))
  add(query_606744, "maximumFramerate", newJString(maximumFramerate))
  add(query_606744, "maximumBitrate", newJString(maximumBitrate))
  add(query_606744, "resourceType", newJString(resourceType))
  add(query_606744, "duration", newJString(duration))
  add(query_606744, "channelConfiguration", newJString(channelConfiguration))
  add(query_606744, "codec", newJString(codec))
  add(query_606744, "resolution", newJString(resolution))
  add(query_606744, "maxResults", newJInt(maxResults))
  result = call_606743.call(nil, query_606744, nil, nil, nil)

var listOfferings* = Call_ListOfferings_606718(name: "listOfferings",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/offerings", validator: validate_ListOfferings_606719, base: "/",
    url: url_ListOfferings_606720, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReservations_606745 = ref object of OpenApiRestCall_605589
proc url_ListReservations_606747(protocol: Scheme; host: string; base: string;
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

proc validate_ListReservations_606746(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## List purchased reservations.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   specialFeature: JString
  ##                 : Placeholder documentation for __string
  ##   nextToken: JString
  ##            : Placeholder documentation for __string
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   channelClass: JString
  ##               : Placeholder documentation for __string
  ##   NextToken: JString
  ##            : Pagination token
  ##   videoQuality: JString
  ##               : Placeholder documentation for __string
  ##   maximumFramerate: JString
  ##                   : Placeholder documentation for __string
  ##   maximumBitrate: JString
  ##                 : Placeholder documentation for __string
  ##   resourceType: JString
  ##               : Placeholder documentation for __string
  ##   codec: JString
  ##        : Placeholder documentation for __string
  ##   resolution: JString
  ##             : Placeholder documentation for __string
  ##   maxResults: JInt
  ##             : Placeholder documentation for MaxResults
  section = newJObject()
  var valid_606748 = query.getOrDefault("specialFeature")
  valid_606748 = validateParameter(valid_606748, JString, required = false,
                                 default = nil)
  if valid_606748 != nil:
    section.add "specialFeature", valid_606748
  var valid_606749 = query.getOrDefault("nextToken")
  valid_606749 = validateParameter(valid_606749, JString, required = false,
                                 default = nil)
  if valid_606749 != nil:
    section.add "nextToken", valid_606749
  var valid_606750 = query.getOrDefault("MaxResults")
  valid_606750 = validateParameter(valid_606750, JString, required = false,
                                 default = nil)
  if valid_606750 != nil:
    section.add "MaxResults", valid_606750
  var valid_606751 = query.getOrDefault("channelClass")
  valid_606751 = validateParameter(valid_606751, JString, required = false,
                                 default = nil)
  if valid_606751 != nil:
    section.add "channelClass", valid_606751
  var valid_606752 = query.getOrDefault("NextToken")
  valid_606752 = validateParameter(valid_606752, JString, required = false,
                                 default = nil)
  if valid_606752 != nil:
    section.add "NextToken", valid_606752
  var valid_606753 = query.getOrDefault("videoQuality")
  valid_606753 = validateParameter(valid_606753, JString, required = false,
                                 default = nil)
  if valid_606753 != nil:
    section.add "videoQuality", valid_606753
  var valid_606754 = query.getOrDefault("maximumFramerate")
  valid_606754 = validateParameter(valid_606754, JString, required = false,
                                 default = nil)
  if valid_606754 != nil:
    section.add "maximumFramerate", valid_606754
  var valid_606755 = query.getOrDefault("maximumBitrate")
  valid_606755 = validateParameter(valid_606755, JString, required = false,
                                 default = nil)
  if valid_606755 != nil:
    section.add "maximumBitrate", valid_606755
  var valid_606756 = query.getOrDefault("resourceType")
  valid_606756 = validateParameter(valid_606756, JString, required = false,
                                 default = nil)
  if valid_606756 != nil:
    section.add "resourceType", valid_606756
  var valid_606757 = query.getOrDefault("codec")
  valid_606757 = validateParameter(valid_606757, JString, required = false,
                                 default = nil)
  if valid_606757 != nil:
    section.add "codec", valid_606757
  var valid_606758 = query.getOrDefault("resolution")
  valid_606758 = validateParameter(valid_606758, JString, required = false,
                                 default = nil)
  if valid_606758 != nil:
    section.add "resolution", valid_606758
  var valid_606759 = query.getOrDefault("maxResults")
  valid_606759 = validateParameter(valid_606759, JInt, required = false, default = nil)
  if valid_606759 != nil:
    section.add "maxResults", valid_606759
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
  var valid_606760 = header.getOrDefault("X-Amz-Signature")
  valid_606760 = validateParameter(valid_606760, JString, required = false,
                                 default = nil)
  if valid_606760 != nil:
    section.add "X-Amz-Signature", valid_606760
  var valid_606761 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606761 = validateParameter(valid_606761, JString, required = false,
                                 default = nil)
  if valid_606761 != nil:
    section.add "X-Amz-Content-Sha256", valid_606761
  var valid_606762 = header.getOrDefault("X-Amz-Date")
  valid_606762 = validateParameter(valid_606762, JString, required = false,
                                 default = nil)
  if valid_606762 != nil:
    section.add "X-Amz-Date", valid_606762
  var valid_606763 = header.getOrDefault("X-Amz-Credential")
  valid_606763 = validateParameter(valid_606763, JString, required = false,
                                 default = nil)
  if valid_606763 != nil:
    section.add "X-Amz-Credential", valid_606763
  var valid_606764 = header.getOrDefault("X-Amz-Security-Token")
  valid_606764 = validateParameter(valid_606764, JString, required = false,
                                 default = nil)
  if valid_606764 != nil:
    section.add "X-Amz-Security-Token", valid_606764
  var valid_606765 = header.getOrDefault("X-Amz-Algorithm")
  valid_606765 = validateParameter(valid_606765, JString, required = false,
                                 default = nil)
  if valid_606765 != nil:
    section.add "X-Amz-Algorithm", valid_606765
  var valid_606766 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606766 = validateParameter(valid_606766, JString, required = false,
                                 default = nil)
  if valid_606766 != nil:
    section.add "X-Amz-SignedHeaders", valid_606766
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606767: Call_ListReservations_606745; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List purchased reservations.
  ## 
  let valid = call_606767.validator(path, query, header, formData, body)
  let scheme = call_606767.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606767.url(scheme.get, call_606767.host, call_606767.base,
                         call_606767.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606767, url, valid)

proc call*(call_606768: Call_ListReservations_606745; specialFeature: string = "";
          nextToken: string = ""; MaxResults: string = ""; channelClass: string = "";
          NextToken: string = ""; videoQuality: string = "";
          maximumFramerate: string = ""; maximumBitrate: string = "";
          resourceType: string = ""; codec: string = ""; resolution: string = "";
          maxResults: int = 0): Recallable =
  ## listReservations
  ## List purchased reservations.
  ##   specialFeature: string
  ##                 : Placeholder documentation for __string
  ##   nextToken: string
  ##            : Placeholder documentation for __string
  ##   MaxResults: string
  ##             : Pagination limit
  ##   channelClass: string
  ##               : Placeholder documentation for __string
  ##   NextToken: string
  ##            : Pagination token
  ##   videoQuality: string
  ##               : Placeholder documentation for __string
  ##   maximumFramerate: string
  ##                   : Placeholder documentation for __string
  ##   maximumBitrate: string
  ##                 : Placeholder documentation for __string
  ##   resourceType: string
  ##               : Placeholder documentation for __string
  ##   codec: string
  ##        : Placeholder documentation for __string
  ##   resolution: string
  ##             : Placeholder documentation for __string
  ##   maxResults: int
  ##             : Placeholder documentation for MaxResults
  var query_606769 = newJObject()
  add(query_606769, "specialFeature", newJString(specialFeature))
  add(query_606769, "nextToken", newJString(nextToken))
  add(query_606769, "MaxResults", newJString(MaxResults))
  add(query_606769, "channelClass", newJString(channelClass))
  add(query_606769, "NextToken", newJString(NextToken))
  add(query_606769, "videoQuality", newJString(videoQuality))
  add(query_606769, "maximumFramerate", newJString(maximumFramerate))
  add(query_606769, "maximumBitrate", newJString(maximumBitrate))
  add(query_606769, "resourceType", newJString(resourceType))
  add(query_606769, "codec", newJString(codec))
  add(query_606769, "resolution", newJString(resolution))
  add(query_606769, "maxResults", newJInt(maxResults))
  result = call_606768.call(nil, query_606769, nil, nil, nil)

var listReservations* = Call_ListReservations_606745(name: "listReservations",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/reservations", validator: validate_ListReservations_606746,
    base: "/", url: url_ListReservations_606747,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_606770 = ref object of OpenApiRestCall_605589
proc url_PurchaseOffering_606772(protocol: Scheme; host: string; base: string;
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

proc validate_PurchaseOffering_606771(path: JsonNode; query: JsonNode;
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
  var valid_606773 = path.getOrDefault("offeringId")
  valid_606773 = validateParameter(valid_606773, JString, required = true,
                                 default = nil)
  if valid_606773 != nil:
    section.add "offeringId", valid_606773
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
  var valid_606774 = header.getOrDefault("X-Amz-Signature")
  valid_606774 = validateParameter(valid_606774, JString, required = false,
                                 default = nil)
  if valid_606774 != nil:
    section.add "X-Amz-Signature", valid_606774
  var valid_606775 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606775 = validateParameter(valid_606775, JString, required = false,
                                 default = nil)
  if valid_606775 != nil:
    section.add "X-Amz-Content-Sha256", valid_606775
  var valid_606776 = header.getOrDefault("X-Amz-Date")
  valid_606776 = validateParameter(valid_606776, JString, required = false,
                                 default = nil)
  if valid_606776 != nil:
    section.add "X-Amz-Date", valid_606776
  var valid_606777 = header.getOrDefault("X-Amz-Credential")
  valid_606777 = validateParameter(valid_606777, JString, required = false,
                                 default = nil)
  if valid_606777 != nil:
    section.add "X-Amz-Credential", valid_606777
  var valid_606778 = header.getOrDefault("X-Amz-Security-Token")
  valid_606778 = validateParameter(valid_606778, JString, required = false,
                                 default = nil)
  if valid_606778 != nil:
    section.add "X-Amz-Security-Token", valid_606778
  var valid_606779 = header.getOrDefault("X-Amz-Algorithm")
  valid_606779 = validateParameter(valid_606779, JString, required = false,
                                 default = nil)
  if valid_606779 != nil:
    section.add "X-Amz-Algorithm", valid_606779
  var valid_606780 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606780 = validateParameter(valid_606780, JString, required = false,
                                 default = nil)
  if valid_606780 != nil:
    section.add "X-Amz-SignedHeaders", valid_606780
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606782: Call_PurchaseOffering_606770; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Purchase an offering and create a reservation.
  ## 
  let valid = call_606782.validator(path, query, header, formData, body)
  let scheme = call_606782.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606782.url(scheme.get, call_606782.host, call_606782.base,
                         call_606782.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606782, url, valid)

proc call*(call_606783: Call_PurchaseOffering_606770; body: JsonNode;
          offeringId: string): Recallable =
  ## purchaseOffering
  ## Purchase an offering and create a reservation.
  ##   body: JObject (required)
  ##   offeringId: string (required)
  ##             : Placeholder documentation for __string
  var path_606784 = newJObject()
  var body_606785 = newJObject()
  if body != nil:
    body_606785 = body
  add(path_606784, "offeringId", newJString(offeringId))
  result = call_606783.call(path_606784, nil, nil, nil, body_606785)

var purchaseOffering* = Call_PurchaseOffering_606770(name: "purchaseOffering",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/offerings/{offeringId}/purchase",
    validator: validate_PurchaseOffering_606771, base: "/",
    url: url_PurchaseOffering_606772, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChannel_606786 = ref object of OpenApiRestCall_605589
proc url_StartChannel_606788(protocol: Scheme; host: string; base: string;
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

proc validate_StartChannel_606787(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606789 = path.getOrDefault("channelId")
  valid_606789 = validateParameter(valid_606789, JString, required = true,
                                 default = nil)
  if valid_606789 != nil:
    section.add "channelId", valid_606789
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
  var valid_606790 = header.getOrDefault("X-Amz-Signature")
  valid_606790 = validateParameter(valid_606790, JString, required = false,
                                 default = nil)
  if valid_606790 != nil:
    section.add "X-Amz-Signature", valid_606790
  var valid_606791 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606791 = validateParameter(valid_606791, JString, required = false,
                                 default = nil)
  if valid_606791 != nil:
    section.add "X-Amz-Content-Sha256", valid_606791
  var valid_606792 = header.getOrDefault("X-Amz-Date")
  valid_606792 = validateParameter(valid_606792, JString, required = false,
                                 default = nil)
  if valid_606792 != nil:
    section.add "X-Amz-Date", valid_606792
  var valid_606793 = header.getOrDefault("X-Amz-Credential")
  valid_606793 = validateParameter(valid_606793, JString, required = false,
                                 default = nil)
  if valid_606793 != nil:
    section.add "X-Amz-Credential", valid_606793
  var valid_606794 = header.getOrDefault("X-Amz-Security-Token")
  valid_606794 = validateParameter(valid_606794, JString, required = false,
                                 default = nil)
  if valid_606794 != nil:
    section.add "X-Amz-Security-Token", valid_606794
  var valid_606795 = header.getOrDefault("X-Amz-Algorithm")
  valid_606795 = validateParameter(valid_606795, JString, required = false,
                                 default = nil)
  if valid_606795 != nil:
    section.add "X-Amz-Algorithm", valid_606795
  var valid_606796 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606796 = validateParameter(valid_606796, JString, required = false,
                                 default = nil)
  if valid_606796 != nil:
    section.add "X-Amz-SignedHeaders", valid_606796
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606797: Call_StartChannel_606786; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an existing channel
  ## 
  let valid = call_606797.validator(path, query, header, formData, body)
  let scheme = call_606797.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606797.url(scheme.get, call_606797.host, call_606797.base,
                         call_606797.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606797, url, valid)

proc call*(call_606798: Call_StartChannel_606786; channelId: string): Recallable =
  ## startChannel
  ## Starts an existing channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_606799 = newJObject()
  add(path_606799, "channelId", newJString(channelId))
  result = call_606798.call(path_606799, nil, nil, nil, nil)

var startChannel* = Call_StartChannel_606786(name: "startChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/start", validator: validate_StartChannel_606787,
    base: "/", url: url_StartChannel_606788, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMultiplex_606800 = ref object of OpenApiRestCall_605589
proc url_StartMultiplex_606802(protocol: Scheme; host: string; base: string;
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

proc validate_StartMultiplex_606801(path: JsonNode; query: JsonNode;
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
  var valid_606803 = path.getOrDefault("multiplexId")
  valid_606803 = validateParameter(valid_606803, JString, required = true,
                                 default = nil)
  if valid_606803 != nil:
    section.add "multiplexId", valid_606803
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
  var valid_606804 = header.getOrDefault("X-Amz-Signature")
  valid_606804 = validateParameter(valid_606804, JString, required = false,
                                 default = nil)
  if valid_606804 != nil:
    section.add "X-Amz-Signature", valid_606804
  var valid_606805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606805 = validateParameter(valid_606805, JString, required = false,
                                 default = nil)
  if valid_606805 != nil:
    section.add "X-Amz-Content-Sha256", valid_606805
  var valid_606806 = header.getOrDefault("X-Amz-Date")
  valid_606806 = validateParameter(valid_606806, JString, required = false,
                                 default = nil)
  if valid_606806 != nil:
    section.add "X-Amz-Date", valid_606806
  var valid_606807 = header.getOrDefault("X-Amz-Credential")
  valid_606807 = validateParameter(valid_606807, JString, required = false,
                                 default = nil)
  if valid_606807 != nil:
    section.add "X-Amz-Credential", valid_606807
  var valid_606808 = header.getOrDefault("X-Amz-Security-Token")
  valid_606808 = validateParameter(valid_606808, JString, required = false,
                                 default = nil)
  if valid_606808 != nil:
    section.add "X-Amz-Security-Token", valid_606808
  var valid_606809 = header.getOrDefault("X-Amz-Algorithm")
  valid_606809 = validateParameter(valid_606809, JString, required = false,
                                 default = nil)
  if valid_606809 != nil:
    section.add "X-Amz-Algorithm", valid_606809
  var valid_606810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606810 = validateParameter(valid_606810, JString, required = false,
                                 default = nil)
  if valid_606810 != nil:
    section.add "X-Amz-SignedHeaders", valid_606810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606811: Call_StartMultiplex_606800; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Start (run) the multiplex. Starting the multiplex does not start the channels. You must explicitly start each channel.
  ## 
  let valid = call_606811.validator(path, query, header, formData, body)
  let scheme = call_606811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606811.url(scheme.get, call_606811.host, call_606811.base,
                         call_606811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606811, url, valid)

proc call*(call_606812: Call_StartMultiplex_606800; multiplexId: string): Recallable =
  ## startMultiplex
  ## Start (run) the multiplex. Starting the multiplex does not start the channels. You must explicitly start each channel.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_606813 = newJObject()
  add(path_606813, "multiplexId", newJString(multiplexId))
  result = call_606812.call(path_606813, nil, nil, nil, nil)

var startMultiplex* = Call_StartMultiplex_606800(name: "startMultiplex",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/start",
    validator: validate_StartMultiplex_606801, base: "/", url: url_StartMultiplex_606802,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopChannel_606814 = ref object of OpenApiRestCall_605589
proc url_StopChannel_606816(protocol: Scheme; host: string; base: string;
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

proc validate_StopChannel_606815(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606817 = path.getOrDefault("channelId")
  valid_606817 = validateParameter(valid_606817, JString, required = true,
                                 default = nil)
  if valid_606817 != nil:
    section.add "channelId", valid_606817
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
  var valid_606818 = header.getOrDefault("X-Amz-Signature")
  valid_606818 = validateParameter(valid_606818, JString, required = false,
                                 default = nil)
  if valid_606818 != nil:
    section.add "X-Amz-Signature", valid_606818
  var valid_606819 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606819 = validateParameter(valid_606819, JString, required = false,
                                 default = nil)
  if valid_606819 != nil:
    section.add "X-Amz-Content-Sha256", valid_606819
  var valid_606820 = header.getOrDefault("X-Amz-Date")
  valid_606820 = validateParameter(valid_606820, JString, required = false,
                                 default = nil)
  if valid_606820 != nil:
    section.add "X-Amz-Date", valid_606820
  var valid_606821 = header.getOrDefault("X-Amz-Credential")
  valid_606821 = validateParameter(valid_606821, JString, required = false,
                                 default = nil)
  if valid_606821 != nil:
    section.add "X-Amz-Credential", valid_606821
  var valid_606822 = header.getOrDefault("X-Amz-Security-Token")
  valid_606822 = validateParameter(valid_606822, JString, required = false,
                                 default = nil)
  if valid_606822 != nil:
    section.add "X-Amz-Security-Token", valid_606822
  var valid_606823 = header.getOrDefault("X-Amz-Algorithm")
  valid_606823 = validateParameter(valid_606823, JString, required = false,
                                 default = nil)
  if valid_606823 != nil:
    section.add "X-Amz-Algorithm", valid_606823
  var valid_606824 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606824 = validateParameter(valid_606824, JString, required = false,
                                 default = nil)
  if valid_606824 != nil:
    section.add "X-Amz-SignedHeaders", valid_606824
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606825: Call_StopChannel_606814; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running channel
  ## 
  let valid = call_606825.validator(path, query, header, formData, body)
  let scheme = call_606825.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606825.url(scheme.get, call_606825.host, call_606825.base,
                         call_606825.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606825, url, valid)

proc call*(call_606826: Call_StopChannel_606814; channelId: string): Recallable =
  ## stopChannel
  ## Stops a running channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_606827 = newJObject()
  add(path_606827, "channelId", newJString(channelId))
  result = call_606826.call(path_606827, nil, nil, nil, nil)

var stopChannel* = Call_StopChannel_606814(name: "stopChannel",
                                        meth: HttpMethod.HttpPost,
                                        host: "medialive.amazonaws.com", route: "/prod/channels/{channelId}/stop",
                                        validator: validate_StopChannel_606815,
                                        base: "/", url: url_StopChannel_606816,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMultiplex_606828 = ref object of OpenApiRestCall_605589
proc url_StopMultiplex_606830(protocol: Scheme; host: string; base: string;
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

proc validate_StopMultiplex_606829(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606831 = path.getOrDefault("multiplexId")
  valid_606831 = validateParameter(valid_606831, JString, required = true,
                                 default = nil)
  if valid_606831 != nil:
    section.add "multiplexId", valid_606831
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
  var valid_606832 = header.getOrDefault("X-Amz-Signature")
  valid_606832 = validateParameter(valid_606832, JString, required = false,
                                 default = nil)
  if valid_606832 != nil:
    section.add "X-Amz-Signature", valid_606832
  var valid_606833 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606833 = validateParameter(valid_606833, JString, required = false,
                                 default = nil)
  if valid_606833 != nil:
    section.add "X-Amz-Content-Sha256", valid_606833
  var valid_606834 = header.getOrDefault("X-Amz-Date")
  valid_606834 = validateParameter(valid_606834, JString, required = false,
                                 default = nil)
  if valid_606834 != nil:
    section.add "X-Amz-Date", valid_606834
  var valid_606835 = header.getOrDefault("X-Amz-Credential")
  valid_606835 = validateParameter(valid_606835, JString, required = false,
                                 default = nil)
  if valid_606835 != nil:
    section.add "X-Amz-Credential", valid_606835
  var valid_606836 = header.getOrDefault("X-Amz-Security-Token")
  valid_606836 = validateParameter(valid_606836, JString, required = false,
                                 default = nil)
  if valid_606836 != nil:
    section.add "X-Amz-Security-Token", valid_606836
  var valid_606837 = header.getOrDefault("X-Amz-Algorithm")
  valid_606837 = validateParameter(valid_606837, JString, required = false,
                                 default = nil)
  if valid_606837 != nil:
    section.add "X-Amz-Algorithm", valid_606837
  var valid_606838 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606838 = validateParameter(valid_606838, JString, required = false,
                                 default = nil)
  if valid_606838 != nil:
    section.add "X-Amz-SignedHeaders", valid_606838
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606839: Call_StopMultiplex_606828; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running multiplex. If the multiplex isn't running, this action has no effect.
  ## 
  let valid = call_606839.validator(path, query, header, formData, body)
  let scheme = call_606839.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606839.url(scheme.get, call_606839.host, call_606839.base,
                         call_606839.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606839, url, valid)

proc call*(call_606840: Call_StopMultiplex_606828; multiplexId: string): Recallable =
  ## stopMultiplex
  ## Stops a running multiplex. If the multiplex isn't running, this action has no effect.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_606841 = newJObject()
  add(path_606841, "multiplexId", newJString(multiplexId))
  result = call_606840.call(path_606841, nil, nil, nil, nil)

var stopMultiplex* = Call_StopMultiplex_606828(name: "stopMultiplex",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/stop",
    validator: validate_StopMultiplex_606829, base: "/", url: url_StopMultiplex_606830,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannelClass_606842 = ref object of OpenApiRestCall_605589
proc url_UpdateChannelClass_606844(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateChannelClass_606843(path: JsonNode; query: JsonNode;
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
  var valid_606845 = path.getOrDefault("channelId")
  valid_606845 = validateParameter(valid_606845, JString, required = true,
                                 default = nil)
  if valid_606845 != nil:
    section.add "channelId", valid_606845
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
  var valid_606846 = header.getOrDefault("X-Amz-Signature")
  valid_606846 = validateParameter(valid_606846, JString, required = false,
                                 default = nil)
  if valid_606846 != nil:
    section.add "X-Amz-Signature", valid_606846
  var valid_606847 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606847 = validateParameter(valid_606847, JString, required = false,
                                 default = nil)
  if valid_606847 != nil:
    section.add "X-Amz-Content-Sha256", valid_606847
  var valid_606848 = header.getOrDefault("X-Amz-Date")
  valid_606848 = validateParameter(valid_606848, JString, required = false,
                                 default = nil)
  if valid_606848 != nil:
    section.add "X-Amz-Date", valid_606848
  var valid_606849 = header.getOrDefault("X-Amz-Credential")
  valid_606849 = validateParameter(valid_606849, JString, required = false,
                                 default = nil)
  if valid_606849 != nil:
    section.add "X-Amz-Credential", valid_606849
  var valid_606850 = header.getOrDefault("X-Amz-Security-Token")
  valid_606850 = validateParameter(valid_606850, JString, required = false,
                                 default = nil)
  if valid_606850 != nil:
    section.add "X-Amz-Security-Token", valid_606850
  var valid_606851 = header.getOrDefault("X-Amz-Algorithm")
  valid_606851 = validateParameter(valid_606851, JString, required = false,
                                 default = nil)
  if valid_606851 != nil:
    section.add "X-Amz-Algorithm", valid_606851
  var valid_606852 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606852 = validateParameter(valid_606852, JString, required = false,
                                 default = nil)
  if valid_606852 != nil:
    section.add "X-Amz-SignedHeaders", valid_606852
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606854: Call_UpdateChannelClass_606842; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the class of the channel.
  ## 
  let valid = call_606854.validator(path, query, header, formData, body)
  let scheme = call_606854.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606854.url(scheme.get, call_606854.host, call_606854.base,
                         call_606854.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606854, url, valid)

proc call*(call_606855: Call_UpdateChannelClass_606842; channelId: string;
          body: JsonNode): Recallable =
  ## updateChannelClass
  ## Changes the class of the channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_606856 = newJObject()
  var body_606857 = newJObject()
  add(path_606856, "channelId", newJString(channelId))
  if body != nil:
    body_606857 = body
  result = call_606855.call(path_606856, nil, nil, nil, body_606857)

var updateChannelClass* = Call_UpdateChannelClass_606842(
    name: "updateChannelClass", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/channelClass",
    validator: validate_UpdateChannelClass_606843, base: "/",
    url: url_UpdateChannelClass_606844, schemes: {Scheme.Https, Scheme.Http})
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
  result = newRecallable(call, url, headers, $input.getOrDefault("body"))
  result.atozSign(input.getOrDefault("query"), SHA256)
