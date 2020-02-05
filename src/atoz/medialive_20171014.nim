
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

  OpenApiRestCall_612658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_612658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_612658): Option[Scheme] {.used.} =
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
  Call_BatchUpdateSchedule_613271 = ref object of OpenApiRestCall_612658
proc url_BatchUpdateSchedule_613273(protocol: Scheme; host: string; base: string;
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

proc validate_BatchUpdateSchedule_613272(path: JsonNode; query: JsonNode;
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
  var valid_613274 = path.getOrDefault("channelId")
  valid_613274 = validateParameter(valid_613274, JString, required = true,
                                 default = nil)
  if valid_613274 != nil:
    section.add "channelId", valid_613274
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
  var valid_613275 = header.getOrDefault("X-Amz-Signature")
  valid_613275 = validateParameter(valid_613275, JString, required = false,
                                 default = nil)
  if valid_613275 != nil:
    section.add "X-Amz-Signature", valid_613275
  var valid_613276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613276 = validateParameter(valid_613276, JString, required = false,
                                 default = nil)
  if valid_613276 != nil:
    section.add "X-Amz-Content-Sha256", valid_613276
  var valid_613277 = header.getOrDefault("X-Amz-Date")
  valid_613277 = validateParameter(valid_613277, JString, required = false,
                                 default = nil)
  if valid_613277 != nil:
    section.add "X-Amz-Date", valid_613277
  var valid_613278 = header.getOrDefault("X-Amz-Credential")
  valid_613278 = validateParameter(valid_613278, JString, required = false,
                                 default = nil)
  if valid_613278 != nil:
    section.add "X-Amz-Credential", valid_613278
  var valid_613279 = header.getOrDefault("X-Amz-Security-Token")
  valid_613279 = validateParameter(valid_613279, JString, required = false,
                                 default = nil)
  if valid_613279 != nil:
    section.add "X-Amz-Security-Token", valid_613279
  var valid_613280 = header.getOrDefault("X-Amz-Algorithm")
  valid_613280 = validateParameter(valid_613280, JString, required = false,
                                 default = nil)
  if valid_613280 != nil:
    section.add "X-Amz-Algorithm", valid_613280
  var valid_613281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613281 = validateParameter(valid_613281, JString, required = false,
                                 default = nil)
  if valid_613281 != nil:
    section.add "X-Amz-SignedHeaders", valid_613281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613283: Call_BatchUpdateSchedule_613271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a channel schedule
  ## 
  let valid = call_613283.validator(path, query, header, formData, body)
  let scheme = call_613283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613283.url(scheme.get, call_613283.host, call_613283.base,
                         call_613283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613283, url, valid)

proc call*(call_613284: Call_BatchUpdateSchedule_613271; channelId: string;
          body: JsonNode): Recallable =
  ## batchUpdateSchedule
  ## Update a channel schedule
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_613285 = newJObject()
  var body_613286 = newJObject()
  add(path_613285, "channelId", newJString(channelId))
  if body != nil:
    body_613286 = body
  result = call_613284.call(path_613285, nil, nil, nil, body_613286)

var batchUpdateSchedule* = Call_BatchUpdateSchedule_613271(
    name: "batchUpdateSchedule", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com", route: "/prod/channels/{channelId}/schedule",
    validator: validate_BatchUpdateSchedule_613272, base: "/",
    url: url_BatchUpdateSchedule_613273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchedule_612996 = ref object of OpenApiRestCall_612658
proc url_DescribeSchedule_612998(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSchedule_612997(path: JsonNode; query: JsonNode;
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
  var valid_613124 = path.getOrDefault("channelId")
  valid_613124 = validateParameter(valid_613124, JString, required = true,
                                 default = nil)
  if valid_613124 != nil:
    section.add "channelId", valid_613124
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
  var valid_613125 = query.getOrDefault("nextToken")
  valid_613125 = validateParameter(valid_613125, JString, required = false,
                                 default = nil)
  if valid_613125 != nil:
    section.add "nextToken", valid_613125
  var valid_613126 = query.getOrDefault("MaxResults")
  valid_613126 = validateParameter(valid_613126, JString, required = false,
                                 default = nil)
  if valid_613126 != nil:
    section.add "MaxResults", valid_613126
  var valid_613127 = query.getOrDefault("NextToken")
  valid_613127 = validateParameter(valid_613127, JString, required = false,
                                 default = nil)
  if valid_613127 != nil:
    section.add "NextToken", valid_613127
  var valid_613128 = query.getOrDefault("maxResults")
  valid_613128 = validateParameter(valid_613128, JInt, required = false, default = nil)
  if valid_613128 != nil:
    section.add "maxResults", valid_613128
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
  var valid_613129 = header.getOrDefault("X-Amz-Signature")
  valid_613129 = validateParameter(valid_613129, JString, required = false,
                                 default = nil)
  if valid_613129 != nil:
    section.add "X-Amz-Signature", valid_613129
  var valid_613130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613130 = validateParameter(valid_613130, JString, required = false,
                                 default = nil)
  if valid_613130 != nil:
    section.add "X-Amz-Content-Sha256", valid_613130
  var valid_613131 = header.getOrDefault("X-Amz-Date")
  valid_613131 = validateParameter(valid_613131, JString, required = false,
                                 default = nil)
  if valid_613131 != nil:
    section.add "X-Amz-Date", valid_613131
  var valid_613132 = header.getOrDefault("X-Amz-Credential")
  valid_613132 = validateParameter(valid_613132, JString, required = false,
                                 default = nil)
  if valid_613132 != nil:
    section.add "X-Amz-Credential", valid_613132
  var valid_613133 = header.getOrDefault("X-Amz-Security-Token")
  valid_613133 = validateParameter(valid_613133, JString, required = false,
                                 default = nil)
  if valid_613133 != nil:
    section.add "X-Amz-Security-Token", valid_613133
  var valid_613134 = header.getOrDefault("X-Amz-Algorithm")
  valid_613134 = validateParameter(valid_613134, JString, required = false,
                                 default = nil)
  if valid_613134 != nil:
    section.add "X-Amz-Algorithm", valid_613134
  var valid_613135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613135 = validateParameter(valid_613135, JString, required = false,
                                 default = nil)
  if valid_613135 != nil:
    section.add "X-Amz-SignedHeaders", valid_613135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613158: Call_DescribeSchedule_612996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get a channel schedule
  ## 
  let valid = call_613158.validator(path, query, header, formData, body)
  let scheme = call_613158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613158.url(scheme.get, call_613158.host, call_613158.base,
                         call_613158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613158, url, valid)

proc call*(call_613229: Call_DescribeSchedule_612996; channelId: string;
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
  var path_613230 = newJObject()
  var query_613232 = newJObject()
  add(query_613232, "nextToken", newJString(nextToken))
  add(query_613232, "MaxResults", newJString(MaxResults))
  add(query_613232, "NextToken", newJString(NextToken))
  add(path_613230, "channelId", newJString(channelId))
  add(query_613232, "maxResults", newJInt(maxResults))
  result = call_613229.call(path_613230, query_613232, nil, nil, nil)

var describeSchedule* = Call_DescribeSchedule_612996(name: "describeSchedule",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_DescribeSchedule_612997, base: "/",
    url: url_DescribeSchedule_612998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchedule_613287 = ref object of OpenApiRestCall_612658
proc url_DeleteSchedule_613289(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSchedule_613288(path: JsonNode; query: JsonNode;
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
  var valid_613290 = path.getOrDefault("channelId")
  valid_613290 = validateParameter(valid_613290, JString, required = true,
                                 default = nil)
  if valid_613290 != nil:
    section.add "channelId", valid_613290
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
  var valid_613291 = header.getOrDefault("X-Amz-Signature")
  valid_613291 = validateParameter(valid_613291, JString, required = false,
                                 default = nil)
  if valid_613291 != nil:
    section.add "X-Amz-Signature", valid_613291
  var valid_613292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613292 = validateParameter(valid_613292, JString, required = false,
                                 default = nil)
  if valid_613292 != nil:
    section.add "X-Amz-Content-Sha256", valid_613292
  var valid_613293 = header.getOrDefault("X-Amz-Date")
  valid_613293 = validateParameter(valid_613293, JString, required = false,
                                 default = nil)
  if valid_613293 != nil:
    section.add "X-Amz-Date", valid_613293
  var valid_613294 = header.getOrDefault("X-Amz-Credential")
  valid_613294 = validateParameter(valid_613294, JString, required = false,
                                 default = nil)
  if valid_613294 != nil:
    section.add "X-Amz-Credential", valid_613294
  var valid_613295 = header.getOrDefault("X-Amz-Security-Token")
  valid_613295 = validateParameter(valid_613295, JString, required = false,
                                 default = nil)
  if valid_613295 != nil:
    section.add "X-Amz-Security-Token", valid_613295
  var valid_613296 = header.getOrDefault("X-Amz-Algorithm")
  valid_613296 = validateParameter(valid_613296, JString, required = false,
                                 default = nil)
  if valid_613296 != nil:
    section.add "X-Amz-Algorithm", valid_613296
  var valid_613297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613297 = validateParameter(valid_613297, JString, required = false,
                                 default = nil)
  if valid_613297 != nil:
    section.add "X-Amz-SignedHeaders", valid_613297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613298: Call_DeleteSchedule_613287; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete all schedule actions on a channel.
  ## 
  let valid = call_613298.validator(path, query, header, formData, body)
  let scheme = call_613298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613298.url(scheme.get, call_613298.host, call_613298.base,
                         call_613298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613298, url, valid)

proc call*(call_613299: Call_DeleteSchedule_613287; channelId: string): Recallable =
  ## deleteSchedule
  ## Delete all schedule actions on a channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_613300 = newJObject()
  add(path_613300, "channelId", newJString(channelId))
  result = call_613299.call(path_613300, nil, nil, nil, nil)

var deleteSchedule* = Call_DeleteSchedule_613287(name: "deleteSchedule",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_DeleteSchedule_613288, base: "/", url: url_DeleteSchedule_613289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateChannel_613318 = ref object of OpenApiRestCall_612658
proc url_CreateChannel_613320(protocol: Scheme; host: string; base: string;
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

proc validate_CreateChannel_613319(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613321 = header.getOrDefault("X-Amz-Signature")
  valid_613321 = validateParameter(valid_613321, JString, required = false,
                                 default = nil)
  if valid_613321 != nil:
    section.add "X-Amz-Signature", valid_613321
  var valid_613322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613322 = validateParameter(valid_613322, JString, required = false,
                                 default = nil)
  if valid_613322 != nil:
    section.add "X-Amz-Content-Sha256", valid_613322
  var valid_613323 = header.getOrDefault("X-Amz-Date")
  valid_613323 = validateParameter(valid_613323, JString, required = false,
                                 default = nil)
  if valid_613323 != nil:
    section.add "X-Amz-Date", valid_613323
  var valid_613324 = header.getOrDefault("X-Amz-Credential")
  valid_613324 = validateParameter(valid_613324, JString, required = false,
                                 default = nil)
  if valid_613324 != nil:
    section.add "X-Amz-Credential", valid_613324
  var valid_613325 = header.getOrDefault("X-Amz-Security-Token")
  valid_613325 = validateParameter(valid_613325, JString, required = false,
                                 default = nil)
  if valid_613325 != nil:
    section.add "X-Amz-Security-Token", valid_613325
  var valid_613326 = header.getOrDefault("X-Amz-Algorithm")
  valid_613326 = validateParameter(valid_613326, JString, required = false,
                                 default = nil)
  if valid_613326 != nil:
    section.add "X-Amz-Algorithm", valid_613326
  var valid_613327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613327 = validateParameter(valid_613327, JString, required = false,
                                 default = nil)
  if valid_613327 != nil:
    section.add "X-Amz-SignedHeaders", valid_613327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613329: Call_CreateChannel_613318; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new channel
  ## 
  let valid = call_613329.validator(path, query, header, formData, body)
  let scheme = call_613329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613329.url(scheme.get, call_613329.host, call_613329.base,
                         call_613329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613329, url, valid)

proc call*(call_613330: Call_CreateChannel_613318; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a new channel
  ##   body: JObject (required)
  var body_613331 = newJObject()
  if body != nil:
    body_613331 = body
  result = call_613330.call(nil, nil, nil, nil, body_613331)

var createChannel* = Call_CreateChannel_613318(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels", validator: validate_CreateChannel_613319, base: "/",
    url: url_CreateChannel_613320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_613301 = ref object of OpenApiRestCall_612658
proc url_ListChannels_613303(protocol: Scheme; host: string; base: string;
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

proc validate_ListChannels_613302(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613304 = query.getOrDefault("nextToken")
  valid_613304 = validateParameter(valid_613304, JString, required = false,
                                 default = nil)
  if valid_613304 != nil:
    section.add "nextToken", valid_613304
  var valid_613305 = query.getOrDefault("MaxResults")
  valid_613305 = validateParameter(valid_613305, JString, required = false,
                                 default = nil)
  if valid_613305 != nil:
    section.add "MaxResults", valid_613305
  var valid_613306 = query.getOrDefault("NextToken")
  valid_613306 = validateParameter(valid_613306, JString, required = false,
                                 default = nil)
  if valid_613306 != nil:
    section.add "NextToken", valid_613306
  var valid_613307 = query.getOrDefault("maxResults")
  valid_613307 = validateParameter(valid_613307, JInt, required = false, default = nil)
  if valid_613307 != nil:
    section.add "maxResults", valid_613307
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
  var valid_613308 = header.getOrDefault("X-Amz-Signature")
  valid_613308 = validateParameter(valid_613308, JString, required = false,
                                 default = nil)
  if valid_613308 != nil:
    section.add "X-Amz-Signature", valid_613308
  var valid_613309 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613309 = validateParameter(valid_613309, JString, required = false,
                                 default = nil)
  if valid_613309 != nil:
    section.add "X-Amz-Content-Sha256", valid_613309
  var valid_613310 = header.getOrDefault("X-Amz-Date")
  valid_613310 = validateParameter(valid_613310, JString, required = false,
                                 default = nil)
  if valid_613310 != nil:
    section.add "X-Amz-Date", valid_613310
  var valid_613311 = header.getOrDefault("X-Amz-Credential")
  valid_613311 = validateParameter(valid_613311, JString, required = false,
                                 default = nil)
  if valid_613311 != nil:
    section.add "X-Amz-Credential", valid_613311
  var valid_613312 = header.getOrDefault("X-Amz-Security-Token")
  valid_613312 = validateParameter(valid_613312, JString, required = false,
                                 default = nil)
  if valid_613312 != nil:
    section.add "X-Amz-Security-Token", valid_613312
  var valid_613313 = header.getOrDefault("X-Amz-Algorithm")
  valid_613313 = validateParameter(valid_613313, JString, required = false,
                                 default = nil)
  if valid_613313 != nil:
    section.add "X-Amz-Algorithm", valid_613313
  var valid_613314 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613314 = validateParameter(valid_613314, JString, required = false,
                                 default = nil)
  if valid_613314 != nil:
    section.add "X-Amz-SignedHeaders", valid_613314
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613315: Call_ListChannels_613301; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of channels that have been created
  ## 
  let valid = call_613315.validator(path, query, header, formData, body)
  let scheme = call_613315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613315.url(scheme.get, call_613315.host, call_613315.base,
                         call_613315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613315, url, valid)

proc call*(call_613316: Call_ListChannels_613301; nextToken: string = "";
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
  var query_613317 = newJObject()
  add(query_613317, "nextToken", newJString(nextToken))
  add(query_613317, "MaxResults", newJString(MaxResults))
  add(query_613317, "NextToken", newJString(NextToken))
  add(query_613317, "maxResults", newJInt(maxResults))
  result = call_613316.call(nil, query_613317, nil, nil, nil)

var listChannels* = Call_ListChannels_613301(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels", validator: validate_ListChannels_613302, base: "/",
    url: url_ListChannels_613303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInput_613349 = ref object of OpenApiRestCall_612658
proc url_CreateInput_613351(protocol: Scheme; host: string; base: string;
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

proc validate_CreateInput_613350(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613352 = header.getOrDefault("X-Amz-Signature")
  valid_613352 = validateParameter(valid_613352, JString, required = false,
                                 default = nil)
  if valid_613352 != nil:
    section.add "X-Amz-Signature", valid_613352
  var valid_613353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613353 = validateParameter(valid_613353, JString, required = false,
                                 default = nil)
  if valid_613353 != nil:
    section.add "X-Amz-Content-Sha256", valid_613353
  var valid_613354 = header.getOrDefault("X-Amz-Date")
  valid_613354 = validateParameter(valid_613354, JString, required = false,
                                 default = nil)
  if valid_613354 != nil:
    section.add "X-Amz-Date", valid_613354
  var valid_613355 = header.getOrDefault("X-Amz-Credential")
  valid_613355 = validateParameter(valid_613355, JString, required = false,
                                 default = nil)
  if valid_613355 != nil:
    section.add "X-Amz-Credential", valid_613355
  var valid_613356 = header.getOrDefault("X-Amz-Security-Token")
  valid_613356 = validateParameter(valid_613356, JString, required = false,
                                 default = nil)
  if valid_613356 != nil:
    section.add "X-Amz-Security-Token", valid_613356
  var valid_613357 = header.getOrDefault("X-Amz-Algorithm")
  valid_613357 = validateParameter(valid_613357, JString, required = false,
                                 default = nil)
  if valid_613357 != nil:
    section.add "X-Amz-Algorithm", valid_613357
  var valid_613358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613358 = validateParameter(valid_613358, JString, required = false,
                                 default = nil)
  if valid_613358 != nil:
    section.add "X-Amz-SignedHeaders", valid_613358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613360: Call_CreateInput_613349; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create an input
  ## 
  let valid = call_613360.validator(path, query, header, formData, body)
  let scheme = call_613360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613360.url(scheme.get, call_613360.host, call_613360.base,
                         call_613360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613360, url, valid)

proc call*(call_613361: Call_CreateInput_613349; body: JsonNode): Recallable =
  ## createInput
  ## Create an input
  ##   body: JObject (required)
  var body_613362 = newJObject()
  if body != nil:
    body_613362 = body
  result = call_613361.call(nil, nil, nil, nil, body_613362)

var createInput* = Call_CreateInput_613349(name: "createInput",
                                        meth: HttpMethod.HttpPost,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs",
                                        validator: validate_CreateInput_613350,
                                        base: "/", url: url_CreateInput_613351,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputs_613332 = ref object of OpenApiRestCall_612658
proc url_ListInputs_613334(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_ListInputs_613333(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613335 = query.getOrDefault("nextToken")
  valid_613335 = validateParameter(valid_613335, JString, required = false,
                                 default = nil)
  if valid_613335 != nil:
    section.add "nextToken", valid_613335
  var valid_613336 = query.getOrDefault("MaxResults")
  valid_613336 = validateParameter(valid_613336, JString, required = false,
                                 default = nil)
  if valid_613336 != nil:
    section.add "MaxResults", valid_613336
  var valid_613337 = query.getOrDefault("NextToken")
  valid_613337 = validateParameter(valid_613337, JString, required = false,
                                 default = nil)
  if valid_613337 != nil:
    section.add "NextToken", valid_613337
  var valid_613338 = query.getOrDefault("maxResults")
  valid_613338 = validateParameter(valid_613338, JInt, required = false, default = nil)
  if valid_613338 != nil:
    section.add "maxResults", valid_613338
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
  var valid_613339 = header.getOrDefault("X-Amz-Signature")
  valid_613339 = validateParameter(valid_613339, JString, required = false,
                                 default = nil)
  if valid_613339 != nil:
    section.add "X-Amz-Signature", valid_613339
  var valid_613340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613340 = validateParameter(valid_613340, JString, required = false,
                                 default = nil)
  if valid_613340 != nil:
    section.add "X-Amz-Content-Sha256", valid_613340
  var valid_613341 = header.getOrDefault("X-Amz-Date")
  valid_613341 = validateParameter(valid_613341, JString, required = false,
                                 default = nil)
  if valid_613341 != nil:
    section.add "X-Amz-Date", valid_613341
  var valid_613342 = header.getOrDefault("X-Amz-Credential")
  valid_613342 = validateParameter(valid_613342, JString, required = false,
                                 default = nil)
  if valid_613342 != nil:
    section.add "X-Amz-Credential", valid_613342
  var valid_613343 = header.getOrDefault("X-Amz-Security-Token")
  valid_613343 = validateParameter(valid_613343, JString, required = false,
                                 default = nil)
  if valid_613343 != nil:
    section.add "X-Amz-Security-Token", valid_613343
  var valid_613344 = header.getOrDefault("X-Amz-Algorithm")
  valid_613344 = validateParameter(valid_613344, JString, required = false,
                                 default = nil)
  if valid_613344 != nil:
    section.add "X-Amz-Algorithm", valid_613344
  var valid_613345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613345 = validateParameter(valid_613345, JString, required = false,
                                 default = nil)
  if valid_613345 != nil:
    section.add "X-Amz-SignedHeaders", valid_613345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613346: Call_ListInputs_613332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of inputs that have been created
  ## 
  let valid = call_613346.validator(path, query, header, formData, body)
  let scheme = call_613346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613346.url(scheme.get, call_613346.host, call_613346.base,
                         call_613346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613346, url, valid)

proc call*(call_613347: Call_ListInputs_613332; nextToken: string = "";
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
  var query_613348 = newJObject()
  add(query_613348, "nextToken", newJString(nextToken))
  add(query_613348, "MaxResults", newJString(MaxResults))
  add(query_613348, "NextToken", newJString(NextToken))
  add(query_613348, "maxResults", newJInt(maxResults))
  result = call_613347.call(nil, query_613348, nil, nil, nil)

var listInputs* = Call_ListInputs_613332(name: "listInputs",
                                      meth: HttpMethod.HttpGet,
                                      host: "medialive.amazonaws.com",
                                      route: "/prod/inputs",
                                      validator: validate_ListInputs_613333,
                                      base: "/", url: url_ListInputs_613334,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInputSecurityGroup_613380 = ref object of OpenApiRestCall_612658
proc url_CreateInputSecurityGroup_613382(protocol: Scheme; host: string;
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

proc validate_CreateInputSecurityGroup_613381(path: JsonNode; query: JsonNode;
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
  var valid_613383 = header.getOrDefault("X-Amz-Signature")
  valid_613383 = validateParameter(valid_613383, JString, required = false,
                                 default = nil)
  if valid_613383 != nil:
    section.add "X-Amz-Signature", valid_613383
  var valid_613384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613384 = validateParameter(valid_613384, JString, required = false,
                                 default = nil)
  if valid_613384 != nil:
    section.add "X-Amz-Content-Sha256", valid_613384
  var valid_613385 = header.getOrDefault("X-Amz-Date")
  valid_613385 = validateParameter(valid_613385, JString, required = false,
                                 default = nil)
  if valid_613385 != nil:
    section.add "X-Amz-Date", valid_613385
  var valid_613386 = header.getOrDefault("X-Amz-Credential")
  valid_613386 = validateParameter(valid_613386, JString, required = false,
                                 default = nil)
  if valid_613386 != nil:
    section.add "X-Amz-Credential", valid_613386
  var valid_613387 = header.getOrDefault("X-Amz-Security-Token")
  valid_613387 = validateParameter(valid_613387, JString, required = false,
                                 default = nil)
  if valid_613387 != nil:
    section.add "X-Amz-Security-Token", valid_613387
  var valid_613388 = header.getOrDefault("X-Amz-Algorithm")
  valid_613388 = validateParameter(valid_613388, JString, required = false,
                                 default = nil)
  if valid_613388 != nil:
    section.add "X-Amz-Algorithm", valid_613388
  var valid_613389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613389 = validateParameter(valid_613389, JString, required = false,
                                 default = nil)
  if valid_613389 != nil:
    section.add "X-Amz-SignedHeaders", valid_613389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613391: Call_CreateInputSecurityGroup_613380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Input Security Group
  ## 
  let valid = call_613391.validator(path, query, header, formData, body)
  let scheme = call_613391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613391.url(scheme.get, call_613391.host, call_613391.base,
                         call_613391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613391, url, valid)

proc call*(call_613392: Call_CreateInputSecurityGroup_613380; body: JsonNode): Recallable =
  ## createInputSecurityGroup
  ## Creates a Input Security Group
  ##   body: JObject (required)
  var body_613393 = newJObject()
  if body != nil:
    body_613393 = body
  result = call_613392.call(nil, nil, nil, nil, body_613393)

var createInputSecurityGroup* = Call_CreateInputSecurityGroup_613380(
    name: "createInputSecurityGroup", meth: HttpMethod.HttpPost,
    host: "medialive.amazonaws.com", route: "/prod/inputSecurityGroups",
    validator: validate_CreateInputSecurityGroup_613381, base: "/",
    url: url_CreateInputSecurityGroup_613382, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputSecurityGroups_613363 = ref object of OpenApiRestCall_612658
proc url_ListInputSecurityGroups_613365(protocol: Scheme; host: string; base: string;
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

proc validate_ListInputSecurityGroups_613364(path: JsonNode; query: JsonNode;
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
  var valid_613366 = query.getOrDefault("nextToken")
  valid_613366 = validateParameter(valid_613366, JString, required = false,
                                 default = nil)
  if valid_613366 != nil:
    section.add "nextToken", valid_613366
  var valid_613367 = query.getOrDefault("MaxResults")
  valid_613367 = validateParameter(valid_613367, JString, required = false,
                                 default = nil)
  if valid_613367 != nil:
    section.add "MaxResults", valid_613367
  var valid_613368 = query.getOrDefault("NextToken")
  valid_613368 = validateParameter(valid_613368, JString, required = false,
                                 default = nil)
  if valid_613368 != nil:
    section.add "NextToken", valid_613368
  var valid_613369 = query.getOrDefault("maxResults")
  valid_613369 = validateParameter(valid_613369, JInt, required = false, default = nil)
  if valid_613369 != nil:
    section.add "maxResults", valid_613369
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
  var valid_613370 = header.getOrDefault("X-Amz-Signature")
  valid_613370 = validateParameter(valid_613370, JString, required = false,
                                 default = nil)
  if valid_613370 != nil:
    section.add "X-Amz-Signature", valid_613370
  var valid_613371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613371 = validateParameter(valid_613371, JString, required = false,
                                 default = nil)
  if valid_613371 != nil:
    section.add "X-Amz-Content-Sha256", valid_613371
  var valid_613372 = header.getOrDefault("X-Amz-Date")
  valid_613372 = validateParameter(valid_613372, JString, required = false,
                                 default = nil)
  if valid_613372 != nil:
    section.add "X-Amz-Date", valid_613372
  var valid_613373 = header.getOrDefault("X-Amz-Credential")
  valid_613373 = validateParameter(valid_613373, JString, required = false,
                                 default = nil)
  if valid_613373 != nil:
    section.add "X-Amz-Credential", valid_613373
  var valid_613374 = header.getOrDefault("X-Amz-Security-Token")
  valid_613374 = validateParameter(valid_613374, JString, required = false,
                                 default = nil)
  if valid_613374 != nil:
    section.add "X-Amz-Security-Token", valid_613374
  var valid_613375 = header.getOrDefault("X-Amz-Algorithm")
  valid_613375 = validateParameter(valid_613375, JString, required = false,
                                 default = nil)
  if valid_613375 != nil:
    section.add "X-Amz-Algorithm", valid_613375
  var valid_613376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613376 = validateParameter(valid_613376, JString, required = false,
                                 default = nil)
  if valid_613376 != nil:
    section.add "X-Amz-SignedHeaders", valid_613376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613377: Call_ListInputSecurityGroups_613363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces a list of Input Security Groups for an account
  ## 
  let valid = call_613377.validator(path, query, header, formData, body)
  let scheme = call_613377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613377.url(scheme.get, call_613377.host, call_613377.base,
                         call_613377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613377, url, valid)

proc call*(call_613378: Call_ListInputSecurityGroups_613363;
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
  var query_613379 = newJObject()
  add(query_613379, "nextToken", newJString(nextToken))
  add(query_613379, "MaxResults", newJString(MaxResults))
  add(query_613379, "NextToken", newJString(NextToken))
  add(query_613379, "maxResults", newJInt(maxResults))
  result = call_613378.call(nil, query_613379, nil, nil, nil)

var listInputSecurityGroups* = Call_ListInputSecurityGroups_613363(
    name: "listInputSecurityGroups", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/inputSecurityGroups",
    validator: validate_ListInputSecurityGroups_613364, base: "/",
    url: url_ListInputSecurityGroups_613365, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultiplex_613411 = ref object of OpenApiRestCall_612658
proc url_CreateMultiplex_613413(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMultiplex_613412(path: JsonNode; query: JsonNode;
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
  var valid_613414 = header.getOrDefault("X-Amz-Signature")
  valid_613414 = validateParameter(valid_613414, JString, required = false,
                                 default = nil)
  if valid_613414 != nil:
    section.add "X-Amz-Signature", valid_613414
  var valid_613415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613415 = validateParameter(valid_613415, JString, required = false,
                                 default = nil)
  if valid_613415 != nil:
    section.add "X-Amz-Content-Sha256", valid_613415
  var valid_613416 = header.getOrDefault("X-Amz-Date")
  valid_613416 = validateParameter(valid_613416, JString, required = false,
                                 default = nil)
  if valid_613416 != nil:
    section.add "X-Amz-Date", valid_613416
  var valid_613417 = header.getOrDefault("X-Amz-Credential")
  valid_613417 = validateParameter(valid_613417, JString, required = false,
                                 default = nil)
  if valid_613417 != nil:
    section.add "X-Amz-Credential", valid_613417
  var valid_613418 = header.getOrDefault("X-Amz-Security-Token")
  valid_613418 = validateParameter(valid_613418, JString, required = false,
                                 default = nil)
  if valid_613418 != nil:
    section.add "X-Amz-Security-Token", valid_613418
  var valid_613419 = header.getOrDefault("X-Amz-Algorithm")
  valid_613419 = validateParameter(valid_613419, JString, required = false,
                                 default = nil)
  if valid_613419 != nil:
    section.add "X-Amz-Algorithm", valid_613419
  var valid_613420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613420 = validateParameter(valid_613420, JString, required = false,
                                 default = nil)
  if valid_613420 != nil:
    section.add "X-Amz-SignedHeaders", valid_613420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613422: Call_CreateMultiplex_613411; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new multiplex.
  ## 
  let valid = call_613422.validator(path, query, header, formData, body)
  let scheme = call_613422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613422.url(scheme.get, call_613422.host, call_613422.base,
                         call_613422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613422, url, valid)

proc call*(call_613423: Call_CreateMultiplex_613411; body: JsonNode): Recallable =
  ## createMultiplex
  ## Create a new multiplex.
  ##   body: JObject (required)
  var body_613424 = newJObject()
  if body != nil:
    body_613424 = body
  result = call_613423.call(nil, nil, nil, nil, body_613424)

var createMultiplex* = Call_CreateMultiplex_613411(name: "createMultiplex",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes", validator: validate_CreateMultiplex_613412,
    base: "/", url: url_CreateMultiplex_613413, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultiplexes_613394 = ref object of OpenApiRestCall_612658
proc url_ListMultiplexes_613396(protocol: Scheme; host: string; base: string;
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

proc validate_ListMultiplexes_613395(path: JsonNode; query: JsonNode;
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
  var valid_613397 = query.getOrDefault("nextToken")
  valid_613397 = validateParameter(valid_613397, JString, required = false,
                                 default = nil)
  if valid_613397 != nil:
    section.add "nextToken", valid_613397
  var valid_613398 = query.getOrDefault("MaxResults")
  valid_613398 = validateParameter(valid_613398, JString, required = false,
                                 default = nil)
  if valid_613398 != nil:
    section.add "MaxResults", valid_613398
  var valid_613399 = query.getOrDefault("NextToken")
  valid_613399 = validateParameter(valid_613399, JString, required = false,
                                 default = nil)
  if valid_613399 != nil:
    section.add "NextToken", valid_613399
  var valid_613400 = query.getOrDefault("maxResults")
  valid_613400 = validateParameter(valid_613400, JInt, required = false, default = nil)
  if valid_613400 != nil:
    section.add "maxResults", valid_613400
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
  var valid_613401 = header.getOrDefault("X-Amz-Signature")
  valid_613401 = validateParameter(valid_613401, JString, required = false,
                                 default = nil)
  if valid_613401 != nil:
    section.add "X-Amz-Signature", valid_613401
  var valid_613402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613402 = validateParameter(valid_613402, JString, required = false,
                                 default = nil)
  if valid_613402 != nil:
    section.add "X-Amz-Content-Sha256", valid_613402
  var valid_613403 = header.getOrDefault("X-Amz-Date")
  valid_613403 = validateParameter(valid_613403, JString, required = false,
                                 default = nil)
  if valid_613403 != nil:
    section.add "X-Amz-Date", valid_613403
  var valid_613404 = header.getOrDefault("X-Amz-Credential")
  valid_613404 = validateParameter(valid_613404, JString, required = false,
                                 default = nil)
  if valid_613404 != nil:
    section.add "X-Amz-Credential", valid_613404
  var valid_613405 = header.getOrDefault("X-Amz-Security-Token")
  valid_613405 = validateParameter(valid_613405, JString, required = false,
                                 default = nil)
  if valid_613405 != nil:
    section.add "X-Amz-Security-Token", valid_613405
  var valid_613406 = header.getOrDefault("X-Amz-Algorithm")
  valid_613406 = validateParameter(valid_613406, JString, required = false,
                                 default = nil)
  if valid_613406 != nil:
    section.add "X-Amz-Algorithm", valid_613406
  var valid_613407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613407 = validateParameter(valid_613407, JString, required = false,
                                 default = nil)
  if valid_613407 != nil:
    section.add "X-Amz-SignedHeaders", valid_613407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613408: Call_ListMultiplexes_613394; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the existing multiplexes.
  ## 
  let valid = call_613408.validator(path, query, header, formData, body)
  let scheme = call_613408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613408.url(scheme.get, call_613408.host, call_613408.base,
                         call_613408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613408, url, valid)

proc call*(call_613409: Call_ListMultiplexes_613394; nextToken: string = "";
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
  var query_613410 = newJObject()
  add(query_613410, "nextToken", newJString(nextToken))
  add(query_613410, "MaxResults", newJString(MaxResults))
  add(query_613410, "NextToken", newJString(NextToken))
  add(query_613410, "maxResults", newJInt(maxResults))
  result = call_613409.call(nil, query_613410, nil, nil, nil)

var listMultiplexes* = Call_ListMultiplexes_613394(name: "listMultiplexes",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes", validator: validate_ListMultiplexes_613395,
    base: "/", url: url_ListMultiplexes_613396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultiplexProgram_613444 = ref object of OpenApiRestCall_612658
proc url_CreateMultiplexProgram_613446(protocol: Scheme; host: string; base: string;
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

proc validate_CreateMultiplexProgram_613445(path: JsonNode; query: JsonNode;
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
  var valid_613447 = path.getOrDefault("multiplexId")
  valid_613447 = validateParameter(valid_613447, JString, required = true,
                                 default = nil)
  if valid_613447 != nil:
    section.add "multiplexId", valid_613447
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
  var valid_613448 = header.getOrDefault("X-Amz-Signature")
  valid_613448 = validateParameter(valid_613448, JString, required = false,
                                 default = nil)
  if valid_613448 != nil:
    section.add "X-Amz-Signature", valid_613448
  var valid_613449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613449 = validateParameter(valid_613449, JString, required = false,
                                 default = nil)
  if valid_613449 != nil:
    section.add "X-Amz-Content-Sha256", valid_613449
  var valid_613450 = header.getOrDefault("X-Amz-Date")
  valid_613450 = validateParameter(valid_613450, JString, required = false,
                                 default = nil)
  if valid_613450 != nil:
    section.add "X-Amz-Date", valid_613450
  var valid_613451 = header.getOrDefault("X-Amz-Credential")
  valid_613451 = validateParameter(valid_613451, JString, required = false,
                                 default = nil)
  if valid_613451 != nil:
    section.add "X-Amz-Credential", valid_613451
  var valid_613452 = header.getOrDefault("X-Amz-Security-Token")
  valid_613452 = validateParameter(valid_613452, JString, required = false,
                                 default = nil)
  if valid_613452 != nil:
    section.add "X-Amz-Security-Token", valid_613452
  var valid_613453 = header.getOrDefault("X-Amz-Algorithm")
  valid_613453 = validateParameter(valid_613453, JString, required = false,
                                 default = nil)
  if valid_613453 != nil:
    section.add "X-Amz-Algorithm", valid_613453
  var valid_613454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613454 = validateParameter(valid_613454, JString, required = false,
                                 default = nil)
  if valid_613454 != nil:
    section.add "X-Amz-SignedHeaders", valid_613454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613456: Call_CreateMultiplexProgram_613444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new program in the multiplex.
  ## 
  let valid = call_613456.validator(path, query, header, formData, body)
  let scheme = call_613456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613456.url(scheme.get, call_613456.host, call_613456.base,
                         call_613456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613456, url, valid)

proc call*(call_613457: Call_CreateMultiplexProgram_613444; body: JsonNode;
          multiplexId: string): Recallable =
  ## createMultiplexProgram
  ## Create a new program in the multiplex.
  ##   body: JObject (required)
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_613458 = newJObject()
  var body_613459 = newJObject()
  if body != nil:
    body_613459 = body
  add(path_613458, "multiplexId", newJString(multiplexId))
  result = call_613457.call(path_613458, nil, nil, nil, body_613459)

var createMultiplexProgram* = Call_CreateMultiplexProgram_613444(
    name: "createMultiplexProgram", meth: HttpMethod.HttpPost,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs",
    validator: validate_CreateMultiplexProgram_613445, base: "/",
    url: url_CreateMultiplexProgram_613446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultiplexPrograms_613425 = ref object of OpenApiRestCall_612658
proc url_ListMultiplexPrograms_613427(protocol: Scheme; host: string; base: string;
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

proc validate_ListMultiplexPrograms_613426(path: JsonNode; query: JsonNode;
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
  var valid_613428 = path.getOrDefault("multiplexId")
  valid_613428 = validateParameter(valid_613428, JString, required = true,
                                 default = nil)
  if valid_613428 != nil:
    section.add "multiplexId", valid_613428
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
  var valid_613429 = query.getOrDefault("nextToken")
  valid_613429 = validateParameter(valid_613429, JString, required = false,
                                 default = nil)
  if valid_613429 != nil:
    section.add "nextToken", valid_613429
  var valid_613430 = query.getOrDefault("MaxResults")
  valid_613430 = validateParameter(valid_613430, JString, required = false,
                                 default = nil)
  if valid_613430 != nil:
    section.add "MaxResults", valid_613430
  var valid_613431 = query.getOrDefault("NextToken")
  valid_613431 = validateParameter(valid_613431, JString, required = false,
                                 default = nil)
  if valid_613431 != nil:
    section.add "NextToken", valid_613431
  var valid_613432 = query.getOrDefault("maxResults")
  valid_613432 = validateParameter(valid_613432, JInt, required = false, default = nil)
  if valid_613432 != nil:
    section.add "maxResults", valid_613432
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
  var valid_613433 = header.getOrDefault("X-Amz-Signature")
  valid_613433 = validateParameter(valid_613433, JString, required = false,
                                 default = nil)
  if valid_613433 != nil:
    section.add "X-Amz-Signature", valid_613433
  var valid_613434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613434 = validateParameter(valid_613434, JString, required = false,
                                 default = nil)
  if valid_613434 != nil:
    section.add "X-Amz-Content-Sha256", valid_613434
  var valid_613435 = header.getOrDefault("X-Amz-Date")
  valid_613435 = validateParameter(valid_613435, JString, required = false,
                                 default = nil)
  if valid_613435 != nil:
    section.add "X-Amz-Date", valid_613435
  var valid_613436 = header.getOrDefault("X-Amz-Credential")
  valid_613436 = validateParameter(valid_613436, JString, required = false,
                                 default = nil)
  if valid_613436 != nil:
    section.add "X-Amz-Credential", valid_613436
  var valid_613437 = header.getOrDefault("X-Amz-Security-Token")
  valid_613437 = validateParameter(valid_613437, JString, required = false,
                                 default = nil)
  if valid_613437 != nil:
    section.add "X-Amz-Security-Token", valid_613437
  var valid_613438 = header.getOrDefault("X-Amz-Algorithm")
  valid_613438 = validateParameter(valid_613438, JString, required = false,
                                 default = nil)
  if valid_613438 != nil:
    section.add "X-Amz-Algorithm", valid_613438
  var valid_613439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613439 = validateParameter(valid_613439, JString, required = false,
                                 default = nil)
  if valid_613439 != nil:
    section.add "X-Amz-SignedHeaders", valid_613439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613440: Call_ListMultiplexPrograms_613425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the programs that currently exist for a specific multiplex.
  ## 
  let valid = call_613440.validator(path, query, header, formData, body)
  let scheme = call_613440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613440.url(scheme.get, call_613440.host, call_613440.base,
                         call_613440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613440, url, valid)

proc call*(call_613441: Call_ListMultiplexPrograms_613425; multiplexId: string;
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
  var path_613442 = newJObject()
  var query_613443 = newJObject()
  add(query_613443, "nextToken", newJString(nextToken))
  add(query_613443, "MaxResults", newJString(MaxResults))
  add(query_613443, "NextToken", newJString(NextToken))
  add(path_613442, "multiplexId", newJString(multiplexId))
  add(query_613443, "maxResults", newJInt(maxResults))
  result = call_613441.call(path_613442, query_613443, nil, nil, nil)

var listMultiplexPrograms* = Call_ListMultiplexPrograms_613425(
    name: "listMultiplexPrograms", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs",
    validator: validate_ListMultiplexPrograms_613426, base: "/",
    url: url_ListMultiplexPrograms_613427, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_613474 = ref object of OpenApiRestCall_612658
proc url_CreateTags_613476(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_CreateTags_613475(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613477 = path.getOrDefault("resource-arn")
  valid_613477 = validateParameter(valid_613477, JString, required = true,
                                 default = nil)
  if valid_613477 != nil:
    section.add "resource-arn", valid_613477
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
  var valid_613478 = header.getOrDefault("X-Amz-Signature")
  valid_613478 = validateParameter(valid_613478, JString, required = false,
                                 default = nil)
  if valid_613478 != nil:
    section.add "X-Amz-Signature", valid_613478
  var valid_613479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613479 = validateParameter(valid_613479, JString, required = false,
                                 default = nil)
  if valid_613479 != nil:
    section.add "X-Amz-Content-Sha256", valid_613479
  var valid_613480 = header.getOrDefault("X-Amz-Date")
  valid_613480 = validateParameter(valid_613480, JString, required = false,
                                 default = nil)
  if valid_613480 != nil:
    section.add "X-Amz-Date", valid_613480
  var valid_613481 = header.getOrDefault("X-Amz-Credential")
  valid_613481 = validateParameter(valid_613481, JString, required = false,
                                 default = nil)
  if valid_613481 != nil:
    section.add "X-Amz-Credential", valid_613481
  var valid_613482 = header.getOrDefault("X-Amz-Security-Token")
  valid_613482 = validateParameter(valid_613482, JString, required = false,
                                 default = nil)
  if valid_613482 != nil:
    section.add "X-Amz-Security-Token", valid_613482
  var valid_613483 = header.getOrDefault("X-Amz-Algorithm")
  valid_613483 = validateParameter(valid_613483, JString, required = false,
                                 default = nil)
  if valid_613483 != nil:
    section.add "X-Amz-Algorithm", valid_613483
  var valid_613484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613484 = validateParameter(valid_613484, JString, required = false,
                                 default = nil)
  if valid_613484 != nil:
    section.add "X-Amz-SignedHeaders", valid_613484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613486: Call_CreateTags_613474; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create tags for a resource
  ## 
  let valid = call_613486.validator(path, query, header, formData, body)
  let scheme = call_613486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613486.url(scheme.get, call_613486.host, call_613486.base,
                         call_613486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613486, url, valid)

proc call*(call_613487: Call_CreateTags_613474; resourceArn: string; body: JsonNode): Recallable =
  ## createTags
  ## Create tags for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_613488 = newJObject()
  var body_613489 = newJObject()
  add(path_613488, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_613489 = body
  result = call_613487.call(path_613488, nil, nil, nil, body_613489)

var createTags* = Call_CreateTags_613474(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "medialive.amazonaws.com",
                                      route: "/prod/tags/{resource-arn}",
                                      validator: validate_CreateTags_613475,
                                      base: "/", url: url_CreateTags_613476,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_613460 = ref object of OpenApiRestCall_612658
proc url_ListTagsForResource_613462(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_613461(path: JsonNode; query: JsonNode;
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
  var valid_613463 = path.getOrDefault("resource-arn")
  valid_613463 = validateParameter(valid_613463, JString, required = true,
                                 default = nil)
  if valid_613463 != nil:
    section.add "resource-arn", valid_613463
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
  var valid_613464 = header.getOrDefault("X-Amz-Signature")
  valid_613464 = validateParameter(valid_613464, JString, required = false,
                                 default = nil)
  if valid_613464 != nil:
    section.add "X-Amz-Signature", valid_613464
  var valid_613465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613465 = validateParameter(valid_613465, JString, required = false,
                                 default = nil)
  if valid_613465 != nil:
    section.add "X-Amz-Content-Sha256", valid_613465
  var valid_613466 = header.getOrDefault("X-Amz-Date")
  valid_613466 = validateParameter(valid_613466, JString, required = false,
                                 default = nil)
  if valid_613466 != nil:
    section.add "X-Amz-Date", valid_613466
  var valid_613467 = header.getOrDefault("X-Amz-Credential")
  valid_613467 = validateParameter(valid_613467, JString, required = false,
                                 default = nil)
  if valid_613467 != nil:
    section.add "X-Amz-Credential", valid_613467
  var valid_613468 = header.getOrDefault("X-Amz-Security-Token")
  valid_613468 = validateParameter(valid_613468, JString, required = false,
                                 default = nil)
  if valid_613468 != nil:
    section.add "X-Amz-Security-Token", valid_613468
  var valid_613469 = header.getOrDefault("X-Amz-Algorithm")
  valid_613469 = validateParameter(valid_613469, JString, required = false,
                                 default = nil)
  if valid_613469 != nil:
    section.add "X-Amz-Algorithm", valid_613469
  var valid_613470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613470 = validateParameter(valid_613470, JString, required = false,
                                 default = nil)
  if valid_613470 != nil:
    section.add "X-Amz-SignedHeaders", valid_613470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613471: Call_ListTagsForResource_613460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of tags that have been created for a resource
  ## 
  let valid = call_613471.validator(path, query, header, formData, body)
  let scheme = call_613471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613471.url(scheme.get, call_613471.host, call_613471.base,
                         call_613471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613471, url, valid)

proc call*(call_613472: Call_ListTagsForResource_613460; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Produces list of tags that have been created for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  var path_613473 = newJObject()
  add(path_613473, "resource-arn", newJString(resourceArn))
  result = call_613472.call(path_613473, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_613460(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/tags/{resource-arn}",
    validator: validate_ListTagsForResource_613461, base: "/",
    url: url_ListTagsForResource_613462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_613504 = ref object of OpenApiRestCall_612658
proc url_UpdateChannel_613506(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateChannel_613505(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613507 = path.getOrDefault("channelId")
  valid_613507 = validateParameter(valid_613507, JString, required = true,
                                 default = nil)
  if valid_613507 != nil:
    section.add "channelId", valid_613507
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
  var valid_613508 = header.getOrDefault("X-Amz-Signature")
  valid_613508 = validateParameter(valid_613508, JString, required = false,
                                 default = nil)
  if valid_613508 != nil:
    section.add "X-Amz-Signature", valid_613508
  var valid_613509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613509 = validateParameter(valid_613509, JString, required = false,
                                 default = nil)
  if valid_613509 != nil:
    section.add "X-Amz-Content-Sha256", valid_613509
  var valid_613510 = header.getOrDefault("X-Amz-Date")
  valid_613510 = validateParameter(valid_613510, JString, required = false,
                                 default = nil)
  if valid_613510 != nil:
    section.add "X-Amz-Date", valid_613510
  var valid_613511 = header.getOrDefault("X-Amz-Credential")
  valid_613511 = validateParameter(valid_613511, JString, required = false,
                                 default = nil)
  if valid_613511 != nil:
    section.add "X-Amz-Credential", valid_613511
  var valid_613512 = header.getOrDefault("X-Amz-Security-Token")
  valid_613512 = validateParameter(valid_613512, JString, required = false,
                                 default = nil)
  if valid_613512 != nil:
    section.add "X-Amz-Security-Token", valid_613512
  var valid_613513 = header.getOrDefault("X-Amz-Algorithm")
  valid_613513 = validateParameter(valid_613513, JString, required = false,
                                 default = nil)
  if valid_613513 != nil:
    section.add "X-Amz-Algorithm", valid_613513
  var valid_613514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613514 = validateParameter(valid_613514, JString, required = false,
                                 default = nil)
  if valid_613514 != nil:
    section.add "X-Amz-SignedHeaders", valid_613514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613516: Call_UpdateChannel_613504; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a channel.
  ## 
  let valid = call_613516.validator(path, query, header, formData, body)
  let scheme = call_613516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613516.url(scheme.get, call_613516.host, call_613516.base,
                         call_613516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613516, url, valid)

proc call*(call_613517: Call_UpdateChannel_613504; channelId: string; body: JsonNode): Recallable =
  ## updateChannel
  ## Updates a channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_613518 = newJObject()
  var body_613519 = newJObject()
  add(path_613518, "channelId", newJString(channelId))
  if body != nil:
    body_613519 = body
  result = call_613517.call(path_613518, nil, nil, nil, body_613519)

var updateChannel* = Call_UpdateChannel_613504(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_UpdateChannel_613505,
    base: "/", url: url_UpdateChannel_613506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_613490 = ref object of OpenApiRestCall_612658
proc url_DescribeChannel_613492(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeChannel_613491(path: JsonNode; query: JsonNode;
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
  var valid_613493 = path.getOrDefault("channelId")
  valid_613493 = validateParameter(valid_613493, JString, required = true,
                                 default = nil)
  if valid_613493 != nil:
    section.add "channelId", valid_613493
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
  var valid_613494 = header.getOrDefault("X-Amz-Signature")
  valid_613494 = validateParameter(valid_613494, JString, required = false,
                                 default = nil)
  if valid_613494 != nil:
    section.add "X-Amz-Signature", valid_613494
  var valid_613495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613495 = validateParameter(valid_613495, JString, required = false,
                                 default = nil)
  if valid_613495 != nil:
    section.add "X-Amz-Content-Sha256", valid_613495
  var valid_613496 = header.getOrDefault("X-Amz-Date")
  valid_613496 = validateParameter(valid_613496, JString, required = false,
                                 default = nil)
  if valid_613496 != nil:
    section.add "X-Amz-Date", valid_613496
  var valid_613497 = header.getOrDefault("X-Amz-Credential")
  valid_613497 = validateParameter(valid_613497, JString, required = false,
                                 default = nil)
  if valid_613497 != nil:
    section.add "X-Amz-Credential", valid_613497
  var valid_613498 = header.getOrDefault("X-Amz-Security-Token")
  valid_613498 = validateParameter(valid_613498, JString, required = false,
                                 default = nil)
  if valid_613498 != nil:
    section.add "X-Amz-Security-Token", valid_613498
  var valid_613499 = header.getOrDefault("X-Amz-Algorithm")
  valid_613499 = validateParameter(valid_613499, JString, required = false,
                                 default = nil)
  if valid_613499 != nil:
    section.add "X-Amz-Algorithm", valid_613499
  var valid_613500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613500 = validateParameter(valid_613500, JString, required = false,
                                 default = nil)
  if valid_613500 != nil:
    section.add "X-Amz-SignedHeaders", valid_613500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613501: Call_DescribeChannel_613490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a channel
  ## 
  let valid = call_613501.validator(path, query, header, formData, body)
  let scheme = call_613501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613501.url(scheme.get, call_613501.host, call_613501.base,
                         call_613501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613501, url, valid)

proc call*(call_613502: Call_DescribeChannel_613490; channelId: string): Recallable =
  ## describeChannel
  ## Gets details about a channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_613503 = newJObject()
  add(path_613503, "channelId", newJString(channelId))
  result = call_613502.call(path_613503, nil, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_613490(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_DescribeChannel_613491,
    base: "/", url: url_DescribeChannel_613492, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_613520 = ref object of OpenApiRestCall_612658
proc url_DeleteChannel_613522(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteChannel_613521(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613523 = path.getOrDefault("channelId")
  valid_613523 = validateParameter(valid_613523, JString, required = true,
                                 default = nil)
  if valid_613523 != nil:
    section.add "channelId", valid_613523
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
  var valid_613524 = header.getOrDefault("X-Amz-Signature")
  valid_613524 = validateParameter(valid_613524, JString, required = false,
                                 default = nil)
  if valid_613524 != nil:
    section.add "X-Amz-Signature", valid_613524
  var valid_613525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613525 = validateParameter(valid_613525, JString, required = false,
                                 default = nil)
  if valid_613525 != nil:
    section.add "X-Amz-Content-Sha256", valid_613525
  var valid_613526 = header.getOrDefault("X-Amz-Date")
  valid_613526 = validateParameter(valid_613526, JString, required = false,
                                 default = nil)
  if valid_613526 != nil:
    section.add "X-Amz-Date", valid_613526
  var valid_613527 = header.getOrDefault("X-Amz-Credential")
  valid_613527 = validateParameter(valid_613527, JString, required = false,
                                 default = nil)
  if valid_613527 != nil:
    section.add "X-Amz-Credential", valid_613527
  var valid_613528 = header.getOrDefault("X-Amz-Security-Token")
  valid_613528 = validateParameter(valid_613528, JString, required = false,
                                 default = nil)
  if valid_613528 != nil:
    section.add "X-Amz-Security-Token", valid_613528
  var valid_613529 = header.getOrDefault("X-Amz-Algorithm")
  valid_613529 = validateParameter(valid_613529, JString, required = false,
                                 default = nil)
  if valid_613529 != nil:
    section.add "X-Amz-Algorithm", valid_613529
  var valid_613530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613530 = validateParameter(valid_613530, JString, required = false,
                                 default = nil)
  if valid_613530 != nil:
    section.add "X-Amz-SignedHeaders", valid_613530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613531: Call_DeleteChannel_613520; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts deletion of channel. The associated outputs are also deleted.
  ## 
  let valid = call_613531.validator(path, query, header, formData, body)
  let scheme = call_613531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613531.url(scheme.get, call_613531.host, call_613531.base,
                         call_613531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613531, url, valid)

proc call*(call_613532: Call_DeleteChannel_613520; channelId: string): Recallable =
  ## deleteChannel
  ## Starts deletion of channel. The associated outputs are also deleted.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_613533 = newJObject()
  add(path_613533, "channelId", newJString(channelId))
  result = call_613532.call(path_613533, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_613520(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_DeleteChannel_613521,
    base: "/", url: url_DeleteChannel_613522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInput_613548 = ref object of OpenApiRestCall_612658
proc url_UpdateInput_613550(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateInput_613549(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613551 = path.getOrDefault("inputId")
  valid_613551 = validateParameter(valid_613551, JString, required = true,
                                 default = nil)
  if valid_613551 != nil:
    section.add "inputId", valid_613551
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
  var valid_613552 = header.getOrDefault("X-Amz-Signature")
  valid_613552 = validateParameter(valid_613552, JString, required = false,
                                 default = nil)
  if valid_613552 != nil:
    section.add "X-Amz-Signature", valid_613552
  var valid_613553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613553 = validateParameter(valid_613553, JString, required = false,
                                 default = nil)
  if valid_613553 != nil:
    section.add "X-Amz-Content-Sha256", valid_613553
  var valid_613554 = header.getOrDefault("X-Amz-Date")
  valid_613554 = validateParameter(valid_613554, JString, required = false,
                                 default = nil)
  if valid_613554 != nil:
    section.add "X-Amz-Date", valid_613554
  var valid_613555 = header.getOrDefault("X-Amz-Credential")
  valid_613555 = validateParameter(valid_613555, JString, required = false,
                                 default = nil)
  if valid_613555 != nil:
    section.add "X-Amz-Credential", valid_613555
  var valid_613556 = header.getOrDefault("X-Amz-Security-Token")
  valid_613556 = validateParameter(valid_613556, JString, required = false,
                                 default = nil)
  if valid_613556 != nil:
    section.add "X-Amz-Security-Token", valid_613556
  var valid_613557 = header.getOrDefault("X-Amz-Algorithm")
  valid_613557 = validateParameter(valid_613557, JString, required = false,
                                 default = nil)
  if valid_613557 != nil:
    section.add "X-Amz-Algorithm", valid_613557
  var valid_613558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613558 = validateParameter(valid_613558, JString, required = false,
                                 default = nil)
  if valid_613558 != nil:
    section.add "X-Amz-SignedHeaders", valid_613558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613560: Call_UpdateInput_613548; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an input.
  ## 
  let valid = call_613560.validator(path, query, header, formData, body)
  let scheme = call_613560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613560.url(scheme.get, call_613560.host, call_613560.base,
                         call_613560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613560, url, valid)

proc call*(call_613561: Call_UpdateInput_613548; body: JsonNode; inputId: string): Recallable =
  ## updateInput
  ## Updates an input.
  ##   body: JObject (required)
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_613562 = newJObject()
  var body_613563 = newJObject()
  if body != nil:
    body_613563 = body
  add(path_613562, "inputId", newJString(inputId))
  result = call_613561.call(path_613562, nil, nil, nil, body_613563)

var updateInput* = Call_UpdateInput_613548(name: "updateInput",
                                        meth: HttpMethod.HttpPut,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs/{inputId}",
                                        validator: validate_UpdateInput_613549,
                                        base: "/", url: url_UpdateInput_613550,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInput_613534 = ref object of OpenApiRestCall_612658
proc url_DescribeInput_613536(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeInput_613535(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613537 = path.getOrDefault("inputId")
  valid_613537 = validateParameter(valid_613537, JString, required = true,
                                 default = nil)
  if valid_613537 != nil:
    section.add "inputId", valid_613537
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
  var valid_613538 = header.getOrDefault("X-Amz-Signature")
  valid_613538 = validateParameter(valid_613538, JString, required = false,
                                 default = nil)
  if valid_613538 != nil:
    section.add "X-Amz-Signature", valid_613538
  var valid_613539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613539 = validateParameter(valid_613539, JString, required = false,
                                 default = nil)
  if valid_613539 != nil:
    section.add "X-Amz-Content-Sha256", valid_613539
  var valid_613540 = header.getOrDefault("X-Amz-Date")
  valid_613540 = validateParameter(valid_613540, JString, required = false,
                                 default = nil)
  if valid_613540 != nil:
    section.add "X-Amz-Date", valid_613540
  var valid_613541 = header.getOrDefault("X-Amz-Credential")
  valid_613541 = validateParameter(valid_613541, JString, required = false,
                                 default = nil)
  if valid_613541 != nil:
    section.add "X-Amz-Credential", valid_613541
  var valid_613542 = header.getOrDefault("X-Amz-Security-Token")
  valid_613542 = validateParameter(valid_613542, JString, required = false,
                                 default = nil)
  if valid_613542 != nil:
    section.add "X-Amz-Security-Token", valid_613542
  var valid_613543 = header.getOrDefault("X-Amz-Algorithm")
  valid_613543 = validateParameter(valid_613543, JString, required = false,
                                 default = nil)
  if valid_613543 != nil:
    section.add "X-Amz-Algorithm", valid_613543
  var valid_613544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613544 = validateParameter(valid_613544, JString, required = false,
                                 default = nil)
  if valid_613544 != nil:
    section.add "X-Amz-SignedHeaders", valid_613544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613545: Call_DescribeInput_613534; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces details about an input
  ## 
  let valid = call_613545.validator(path, query, header, formData, body)
  let scheme = call_613545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613545.url(scheme.get, call_613545.host, call_613545.base,
                         call_613545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613545, url, valid)

proc call*(call_613546: Call_DescribeInput_613534; inputId: string): Recallable =
  ## describeInput
  ## Produces details about an input
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_613547 = newJObject()
  add(path_613547, "inputId", newJString(inputId))
  result = call_613546.call(path_613547, nil, nil, nil, nil)

var describeInput* = Call_DescribeInput_613534(name: "describeInput",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/inputs/{inputId}", validator: validate_DescribeInput_613535,
    base: "/", url: url_DescribeInput_613536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInput_613564 = ref object of OpenApiRestCall_612658
proc url_DeleteInput_613566(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInput_613565(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613567 = path.getOrDefault("inputId")
  valid_613567 = validateParameter(valid_613567, JString, required = true,
                                 default = nil)
  if valid_613567 != nil:
    section.add "inputId", valid_613567
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
  var valid_613568 = header.getOrDefault("X-Amz-Signature")
  valid_613568 = validateParameter(valid_613568, JString, required = false,
                                 default = nil)
  if valid_613568 != nil:
    section.add "X-Amz-Signature", valid_613568
  var valid_613569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613569 = validateParameter(valid_613569, JString, required = false,
                                 default = nil)
  if valid_613569 != nil:
    section.add "X-Amz-Content-Sha256", valid_613569
  var valid_613570 = header.getOrDefault("X-Amz-Date")
  valid_613570 = validateParameter(valid_613570, JString, required = false,
                                 default = nil)
  if valid_613570 != nil:
    section.add "X-Amz-Date", valid_613570
  var valid_613571 = header.getOrDefault("X-Amz-Credential")
  valid_613571 = validateParameter(valid_613571, JString, required = false,
                                 default = nil)
  if valid_613571 != nil:
    section.add "X-Amz-Credential", valid_613571
  var valid_613572 = header.getOrDefault("X-Amz-Security-Token")
  valid_613572 = validateParameter(valid_613572, JString, required = false,
                                 default = nil)
  if valid_613572 != nil:
    section.add "X-Amz-Security-Token", valid_613572
  var valid_613573 = header.getOrDefault("X-Amz-Algorithm")
  valid_613573 = validateParameter(valid_613573, JString, required = false,
                                 default = nil)
  if valid_613573 != nil:
    section.add "X-Amz-Algorithm", valid_613573
  var valid_613574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613574 = validateParameter(valid_613574, JString, required = false,
                                 default = nil)
  if valid_613574 != nil:
    section.add "X-Amz-SignedHeaders", valid_613574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613575: Call_DeleteInput_613564; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the input end point
  ## 
  let valid = call_613575.validator(path, query, header, formData, body)
  let scheme = call_613575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613575.url(scheme.get, call_613575.host, call_613575.base,
                         call_613575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613575, url, valid)

proc call*(call_613576: Call_DeleteInput_613564; inputId: string): Recallable =
  ## deleteInput
  ## Deletes the input end point
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_613577 = newJObject()
  add(path_613577, "inputId", newJString(inputId))
  result = call_613576.call(path_613577, nil, nil, nil, nil)

var deleteInput* = Call_DeleteInput_613564(name: "deleteInput",
                                        meth: HttpMethod.HttpDelete,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs/{inputId}",
                                        validator: validate_DeleteInput_613565,
                                        base: "/", url: url_DeleteInput_613566,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInputSecurityGroup_613592 = ref object of OpenApiRestCall_612658
proc url_UpdateInputSecurityGroup_613594(protocol: Scheme; host: string;
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

proc validate_UpdateInputSecurityGroup_613593(path: JsonNode; query: JsonNode;
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
  var valid_613595 = path.getOrDefault("inputSecurityGroupId")
  valid_613595 = validateParameter(valid_613595, JString, required = true,
                                 default = nil)
  if valid_613595 != nil:
    section.add "inputSecurityGroupId", valid_613595
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
  var valid_613596 = header.getOrDefault("X-Amz-Signature")
  valid_613596 = validateParameter(valid_613596, JString, required = false,
                                 default = nil)
  if valid_613596 != nil:
    section.add "X-Amz-Signature", valid_613596
  var valid_613597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613597 = validateParameter(valid_613597, JString, required = false,
                                 default = nil)
  if valid_613597 != nil:
    section.add "X-Amz-Content-Sha256", valid_613597
  var valid_613598 = header.getOrDefault("X-Amz-Date")
  valid_613598 = validateParameter(valid_613598, JString, required = false,
                                 default = nil)
  if valid_613598 != nil:
    section.add "X-Amz-Date", valid_613598
  var valid_613599 = header.getOrDefault("X-Amz-Credential")
  valid_613599 = validateParameter(valid_613599, JString, required = false,
                                 default = nil)
  if valid_613599 != nil:
    section.add "X-Amz-Credential", valid_613599
  var valid_613600 = header.getOrDefault("X-Amz-Security-Token")
  valid_613600 = validateParameter(valid_613600, JString, required = false,
                                 default = nil)
  if valid_613600 != nil:
    section.add "X-Amz-Security-Token", valid_613600
  var valid_613601 = header.getOrDefault("X-Amz-Algorithm")
  valid_613601 = validateParameter(valid_613601, JString, required = false,
                                 default = nil)
  if valid_613601 != nil:
    section.add "X-Amz-Algorithm", valid_613601
  var valid_613602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613602 = validateParameter(valid_613602, JString, required = false,
                                 default = nil)
  if valid_613602 != nil:
    section.add "X-Amz-SignedHeaders", valid_613602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613604: Call_UpdateInputSecurityGroup_613592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update an Input Security Group's Whilelists.
  ## 
  let valid = call_613604.validator(path, query, header, formData, body)
  let scheme = call_613604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613604.url(scheme.get, call_613604.host, call_613604.base,
                         call_613604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613604, url, valid)

proc call*(call_613605: Call_UpdateInputSecurityGroup_613592;
          inputSecurityGroupId: string; body: JsonNode): Recallable =
  ## updateInputSecurityGroup
  ## Update an Input Security Group's Whilelists.
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_613606 = newJObject()
  var body_613607 = newJObject()
  add(path_613606, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  if body != nil:
    body_613607 = body
  result = call_613605.call(path_613606, nil, nil, nil, body_613607)

var updateInputSecurityGroup* = Call_UpdateInputSecurityGroup_613592(
    name: "updateInputSecurityGroup", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_UpdateInputSecurityGroup_613593, base: "/",
    url: url_UpdateInputSecurityGroup_613594, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInputSecurityGroup_613578 = ref object of OpenApiRestCall_612658
proc url_DescribeInputSecurityGroup_613580(protocol: Scheme; host: string;
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

proc validate_DescribeInputSecurityGroup_613579(path: JsonNode; query: JsonNode;
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
  var valid_613581 = path.getOrDefault("inputSecurityGroupId")
  valid_613581 = validateParameter(valid_613581, JString, required = true,
                                 default = nil)
  if valid_613581 != nil:
    section.add "inputSecurityGroupId", valid_613581
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
  var valid_613582 = header.getOrDefault("X-Amz-Signature")
  valid_613582 = validateParameter(valid_613582, JString, required = false,
                                 default = nil)
  if valid_613582 != nil:
    section.add "X-Amz-Signature", valid_613582
  var valid_613583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613583 = validateParameter(valid_613583, JString, required = false,
                                 default = nil)
  if valid_613583 != nil:
    section.add "X-Amz-Content-Sha256", valid_613583
  var valid_613584 = header.getOrDefault("X-Amz-Date")
  valid_613584 = validateParameter(valid_613584, JString, required = false,
                                 default = nil)
  if valid_613584 != nil:
    section.add "X-Amz-Date", valid_613584
  var valid_613585 = header.getOrDefault("X-Amz-Credential")
  valid_613585 = validateParameter(valid_613585, JString, required = false,
                                 default = nil)
  if valid_613585 != nil:
    section.add "X-Amz-Credential", valid_613585
  var valid_613586 = header.getOrDefault("X-Amz-Security-Token")
  valid_613586 = validateParameter(valid_613586, JString, required = false,
                                 default = nil)
  if valid_613586 != nil:
    section.add "X-Amz-Security-Token", valid_613586
  var valid_613587 = header.getOrDefault("X-Amz-Algorithm")
  valid_613587 = validateParameter(valid_613587, JString, required = false,
                                 default = nil)
  if valid_613587 != nil:
    section.add "X-Amz-Algorithm", valid_613587
  var valid_613588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613588 = validateParameter(valid_613588, JString, required = false,
                                 default = nil)
  if valid_613588 != nil:
    section.add "X-Amz-SignedHeaders", valid_613588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613589: Call_DescribeInputSecurityGroup_613578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces a summary of an Input Security Group
  ## 
  let valid = call_613589.validator(path, query, header, formData, body)
  let scheme = call_613589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613589.url(scheme.get, call_613589.host, call_613589.base,
                         call_613589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613589, url, valid)

proc call*(call_613590: Call_DescribeInputSecurityGroup_613578;
          inputSecurityGroupId: string): Recallable =
  ## describeInputSecurityGroup
  ## Produces a summary of an Input Security Group
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  var path_613591 = newJObject()
  add(path_613591, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  result = call_613590.call(path_613591, nil, nil, nil, nil)

var describeInputSecurityGroup* = Call_DescribeInputSecurityGroup_613578(
    name: "describeInputSecurityGroup", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_DescribeInputSecurityGroup_613579, base: "/",
    url: url_DescribeInputSecurityGroup_613580,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInputSecurityGroup_613608 = ref object of OpenApiRestCall_612658
proc url_DeleteInputSecurityGroup_613610(protocol: Scheme; host: string;
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

proc validate_DeleteInputSecurityGroup_613609(path: JsonNode; query: JsonNode;
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
  var valid_613611 = path.getOrDefault("inputSecurityGroupId")
  valid_613611 = validateParameter(valid_613611, JString, required = true,
                                 default = nil)
  if valid_613611 != nil:
    section.add "inputSecurityGroupId", valid_613611
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
  var valid_613612 = header.getOrDefault("X-Amz-Signature")
  valid_613612 = validateParameter(valid_613612, JString, required = false,
                                 default = nil)
  if valid_613612 != nil:
    section.add "X-Amz-Signature", valid_613612
  var valid_613613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613613 = validateParameter(valid_613613, JString, required = false,
                                 default = nil)
  if valid_613613 != nil:
    section.add "X-Amz-Content-Sha256", valid_613613
  var valid_613614 = header.getOrDefault("X-Amz-Date")
  valid_613614 = validateParameter(valid_613614, JString, required = false,
                                 default = nil)
  if valid_613614 != nil:
    section.add "X-Amz-Date", valid_613614
  var valid_613615 = header.getOrDefault("X-Amz-Credential")
  valid_613615 = validateParameter(valid_613615, JString, required = false,
                                 default = nil)
  if valid_613615 != nil:
    section.add "X-Amz-Credential", valid_613615
  var valid_613616 = header.getOrDefault("X-Amz-Security-Token")
  valid_613616 = validateParameter(valid_613616, JString, required = false,
                                 default = nil)
  if valid_613616 != nil:
    section.add "X-Amz-Security-Token", valid_613616
  var valid_613617 = header.getOrDefault("X-Amz-Algorithm")
  valid_613617 = validateParameter(valid_613617, JString, required = false,
                                 default = nil)
  if valid_613617 != nil:
    section.add "X-Amz-Algorithm", valid_613617
  var valid_613618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613618 = validateParameter(valid_613618, JString, required = false,
                                 default = nil)
  if valid_613618 != nil:
    section.add "X-Amz-SignedHeaders", valid_613618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613619: Call_DeleteInputSecurityGroup_613608; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Input Security Group
  ## 
  let valid = call_613619.validator(path, query, header, formData, body)
  let scheme = call_613619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613619.url(scheme.get, call_613619.host, call_613619.base,
                         call_613619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613619, url, valid)

proc call*(call_613620: Call_DeleteInputSecurityGroup_613608;
          inputSecurityGroupId: string): Recallable =
  ## deleteInputSecurityGroup
  ## Deletes an Input Security Group
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  var path_613621 = newJObject()
  add(path_613621, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  result = call_613620.call(path_613621, nil, nil, nil, nil)

var deleteInputSecurityGroup* = Call_DeleteInputSecurityGroup_613608(
    name: "deleteInputSecurityGroup", meth: HttpMethod.HttpDelete,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_DeleteInputSecurityGroup_613609, base: "/",
    url: url_DeleteInputSecurityGroup_613610, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMultiplex_613636 = ref object of OpenApiRestCall_612658
proc url_UpdateMultiplex_613638(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMultiplex_613637(path: JsonNode; query: JsonNode;
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
  var valid_613639 = path.getOrDefault("multiplexId")
  valid_613639 = validateParameter(valid_613639, JString, required = true,
                                 default = nil)
  if valid_613639 != nil:
    section.add "multiplexId", valid_613639
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
  var valid_613640 = header.getOrDefault("X-Amz-Signature")
  valid_613640 = validateParameter(valid_613640, JString, required = false,
                                 default = nil)
  if valid_613640 != nil:
    section.add "X-Amz-Signature", valid_613640
  var valid_613641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613641 = validateParameter(valid_613641, JString, required = false,
                                 default = nil)
  if valid_613641 != nil:
    section.add "X-Amz-Content-Sha256", valid_613641
  var valid_613642 = header.getOrDefault("X-Amz-Date")
  valid_613642 = validateParameter(valid_613642, JString, required = false,
                                 default = nil)
  if valid_613642 != nil:
    section.add "X-Amz-Date", valid_613642
  var valid_613643 = header.getOrDefault("X-Amz-Credential")
  valid_613643 = validateParameter(valid_613643, JString, required = false,
                                 default = nil)
  if valid_613643 != nil:
    section.add "X-Amz-Credential", valid_613643
  var valid_613644 = header.getOrDefault("X-Amz-Security-Token")
  valid_613644 = validateParameter(valid_613644, JString, required = false,
                                 default = nil)
  if valid_613644 != nil:
    section.add "X-Amz-Security-Token", valid_613644
  var valid_613645 = header.getOrDefault("X-Amz-Algorithm")
  valid_613645 = validateParameter(valid_613645, JString, required = false,
                                 default = nil)
  if valid_613645 != nil:
    section.add "X-Amz-Algorithm", valid_613645
  var valid_613646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613646 = validateParameter(valid_613646, JString, required = false,
                                 default = nil)
  if valid_613646 != nil:
    section.add "X-Amz-SignedHeaders", valid_613646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613648: Call_UpdateMultiplex_613636; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a multiplex.
  ## 
  let valid = call_613648.validator(path, query, header, formData, body)
  let scheme = call_613648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613648.url(scheme.get, call_613648.host, call_613648.base,
                         call_613648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613648, url, valid)

proc call*(call_613649: Call_UpdateMultiplex_613636; body: JsonNode;
          multiplexId: string): Recallable =
  ## updateMultiplex
  ## Updates a multiplex.
  ##   body: JObject (required)
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_613650 = newJObject()
  var body_613651 = newJObject()
  if body != nil:
    body_613651 = body
  add(path_613650, "multiplexId", newJString(multiplexId))
  result = call_613649.call(path_613650, nil, nil, nil, body_613651)

var updateMultiplex* = Call_UpdateMultiplex_613636(name: "updateMultiplex",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}", validator: validate_UpdateMultiplex_613637,
    base: "/", url: url_UpdateMultiplex_613638, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMultiplex_613622 = ref object of OpenApiRestCall_612658
proc url_DescribeMultiplex_613624(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeMultiplex_613623(path: JsonNode; query: JsonNode;
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
  var valid_613625 = path.getOrDefault("multiplexId")
  valid_613625 = validateParameter(valid_613625, JString, required = true,
                                 default = nil)
  if valid_613625 != nil:
    section.add "multiplexId", valid_613625
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
  var valid_613626 = header.getOrDefault("X-Amz-Signature")
  valid_613626 = validateParameter(valid_613626, JString, required = false,
                                 default = nil)
  if valid_613626 != nil:
    section.add "X-Amz-Signature", valid_613626
  var valid_613627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613627 = validateParameter(valid_613627, JString, required = false,
                                 default = nil)
  if valid_613627 != nil:
    section.add "X-Amz-Content-Sha256", valid_613627
  var valid_613628 = header.getOrDefault("X-Amz-Date")
  valid_613628 = validateParameter(valid_613628, JString, required = false,
                                 default = nil)
  if valid_613628 != nil:
    section.add "X-Amz-Date", valid_613628
  var valid_613629 = header.getOrDefault("X-Amz-Credential")
  valid_613629 = validateParameter(valid_613629, JString, required = false,
                                 default = nil)
  if valid_613629 != nil:
    section.add "X-Amz-Credential", valid_613629
  var valid_613630 = header.getOrDefault("X-Amz-Security-Token")
  valid_613630 = validateParameter(valid_613630, JString, required = false,
                                 default = nil)
  if valid_613630 != nil:
    section.add "X-Amz-Security-Token", valid_613630
  var valid_613631 = header.getOrDefault("X-Amz-Algorithm")
  valid_613631 = validateParameter(valid_613631, JString, required = false,
                                 default = nil)
  if valid_613631 != nil:
    section.add "X-Amz-Algorithm", valid_613631
  var valid_613632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613632 = validateParameter(valid_613632, JString, required = false,
                                 default = nil)
  if valid_613632 != nil:
    section.add "X-Amz-SignedHeaders", valid_613632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613633: Call_DescribeMultiplex_613622; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a multiplex.
  ## 
  let valid = call_613633.validator(path, query, header, formData, body)
  let scheme = call_613633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613633.url(scheme.get, call_613633.host, call_613633.base,
                         call_613633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613633, url, valid)

proc call*(call_613634: Call_DescribeMultiplex_613622; multiplexId: string): Recallable =
  ## describeMultiplex
  ## Gets details about a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_613635 = newJObject()
  add(path_613635, "multiplexId", newJString(multiplexId))
  result = call_613634.call(path_613635, nil, nil, nil, nil)

var describeMultiplex* = Call_DescribeMultiplex_613622(name: "describeMultiplex",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}",
    validator: validate_DescribeMultiplex_613623, base: "/",
    url: url_DescribeMultiplex_613624, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMultiplex_613652 = ref object of OpenApiRestCall_612658
proc url_DeleteMultiplex_613654(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMultiplex_613653(path: JsonNode; query: JsonNode;
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
  var valid_613655 = path.getOrDefault("multiplexId")
  valid_613655 = validateParameter(valid_613655, JString, required = true,
                                 default = nil)
  if valid_613655 != nil:
    section.add "multiplexId", valid_613655
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
  var valid_613656 = header.getOrDefault("X-Amz-Signature")
  valid_613656 = validateParameter(valid_613656, JString, required = false,
                                 default = nil)
  if valid_613656 != nil:
    section.add "X-Amz-Signature", valid_613656
  var valid_613657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613657 = validateParameter(valid_613657, JString, required = false,
                                 default = nil)
  if valid_613657 != nil:
    section.add "X-Amz-Content-Sha256", valid_613657
  var valid_613658 = header.getOrDefault("X-Amz-Date")
  valid_613658 = validateParameter(valid_613658, JString, required = false,
                                 default = nil)
  if valid_613658 != nil:
    section.add "X-Amz-Date", valid_613658
  var valid_613659 = header.getOrDefault("X-Amz-Credential")
  valid_613659 = validateParameter(valid_613659, JString, required = false,
                                 default = nil)
  if valid_613659 != nil:
    section.add "X-Amz-Credential", valid_613659
  var valid_613660 = header.getOrDefault("X-Amz-Security-Token")
  valid_613660 = validateParameter(valid_613660, JString, required = false,
                                 default = nil)
  if valid_613660 != nil:
    section.add "X-Amz-Security-Token", valid_613660
  var valid_613661 = header.getOrDefault("X-Amz-Algorithm")
  valid_613661 = validateParameter(valid_613661, JString, required = false,
                                 default = nil)
  if valid_613661 != nil:
    section.add "X-Amz-Algorithm", valid_613661
  var valid_613662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613662 = validateParameter(valid_613662, JString, required = false,
                                 default = nil)
  if valid_613662 != nil:
    section.add "X-Amz-SignedHeaders", valid_613662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613663: Call_DeleteMultiplex_613652; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a multiplex. The multiplex must be idle.
  ## 
  let valid = call_613663.validator(path, query, header, formData, body)
  let scheme = call_613663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613663.url(scheme.get, call_613663.host, call_613663.base,
                         call_613663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613663, url, valid)

proc call*(call_613664: Call_DeleteMultiplex_613652; multiplexId: string): Recallable =
  ## deleteMultiplex
  ## Delete a multiplex. The multiplex must be idle.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_613665 = newJObject()
  add(path_613665, "multiplexId", newJString(multiplexId))
  result = call_613664.call(path_613665, nil, nil, nil, nil)

var deleteMultiplex* = Call_DeleteMultiplex_613652(name: "deleteMultiplex",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}", validator: validate_DeleteMultiplex_613653,
    base: "/", url: url_DeleteMultiplex_613654, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMultiplexProgram_613681 = ref object of OpenApiRestCall_612658
proc url_UpdateMultiplexProgram_613683(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMultiplexProgram_613682(path: JsonNode; query: JsonNode;
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
  var valid_613684 = path.getOrDefault("multiplexId")
  valid_613684 = validateParameter(valid_613684, JString, required = true,
                                 default = nil)
  if valid_613684 != nil:
    section.add "multiplexId", valid_613684
  var valid_613685 = path.getOrDefault("programName")
  valid_613685 = validateParameter(valid_613685, JString, required = true,
                                 default = nil)
  if valid_613685 != nil:
    section.add "programName", valid_613685
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
  var valid_613686 = header.getOrDefault("X-Amz-Signature")
  valid_613686 = validateParameter(valid_613686, JString, required = false,
                                 default = nil)
  if valid_613686 != nil:
    section.add "X-Amz-Signature", valid_613686
  var valid_613687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613687 = validateParameter(valid_613687, JString, required = false,
                                 default = nil)
  if valid_613687 != nil:
    section.add "X-Amz-Content-Sha256", valid_613687
  var valid_613688 = header.getOrDefault("X-Amz-Date")
  valid_613688 = validateParameter(valid_613688, JString, required = false,
                                 default = nil)
  if valid_613688 != nil:
    section.add "X-Amz-Date", valid_613688
  var valid_613689 = header.getOrDefault("X-Amz-Credential")
  valid_613689 = validateParameter(valid_613689, JString, required = false,
                                 default = nil)
  if valid_613689 != nil:
    section.add "X-Amz-Credential", valid_613689
  var valid_613690 = header.getOrDefault("X-Amz-Security-Token")
  valid_613690 = validateParameter(valid_613690, JString, required = false,
                                 default = nil)
  if valid_613690 != nil:
    section.add "X-Amz-Security-Token", valid_613690
  var valid_613691 = header.getOrDefault("X-Amz-Algorithm")
  valid_613691 = validateParameter(valid_613691, JString, required = false,
                                 default = nil)
  if valid_613691 != nil:
    section.add "X-Amz-Algorithm", valid_613691
  var valid_613692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613692 = validateParameter(valid_613692, JString, required = false,
                                 default = nil)
  if valid_613692 != nil:
    section.add "X-Amz-SignedHeaders", valid_613692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613694: Call_UpdateMultiplexProgram_613681; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a program in a multiplex.
  ## 
  let valid = call_613694.validator(path, query, header, formData, body)
  let scheme = call_613694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613694.url(scheme.get, call_613694.host, call_613694.base,
                         call_613694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613694, url, valid)

proc call*(call_613695: Call_UpdateMultiplexProgram_613681; body: JsonNode;
          multiplexId: string; programName: string): Recallable =
  ## updateMultiplexProgram
  ## Update a program in a multiplex.
  ##   body: JObject (required)
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   programName: string (required)
  ##              : Placeholder documentation for __string
  var path_613696 = newJObject()
  var body_613697 = newJObject()
  if body != nil:
    body_613697 = body
  add(path_613696, "multiplexId", newJString(multiplexId))
  add(path_613696, "programName", newJString(programName))
  result = call_613695.call(path_613696, nil, nil, nil, body_613697)

var updateMultiplexProgram* = Call_UpdateMultiplexProgram_613681(
    name: "updateMultiplexProgram", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs/{programName}",
    validator: validate_UpdateMultiplexProgram_613682, base: "/",
    url: url_UpdateMultiplexProgram_613683, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMultiplexProgram_613666 = ref object of OpenApiRestCall_612658
proc url_DescribeMultiplexProgram_613668(protocol: Scheme; host: string;
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

proc validate_DescribeMultiplexProgram_613667(path: JsonNode; query: JsonNode;
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
  var valid_613669 = path.getOrDefault("multiplexId")
  valid_613669 = validateParameter(valid_613669, JString, required = true,
                                 default = nil)
  if valid_613669 != nil:
    section.add "multiplexId", valid_613669
  var valid_613670 = path.getOrDefault("programName")
  valid_613670 = validateParameter(valid_613670, JString, required = true,
                                 default = nil)
  if valid_613670 != nil:
    section.add "programName", valid_613670
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
  var valid_613671 = header.getOrDefault("X-Amz-Signature")
  valid_613671 = validateParameter(valid_613671, JString, required = false,
                                 default = nil)
  if valid_613671 != nil:
    section.add "X-Amz-Signature", valid_613671
  var valid_613672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613672 = validateParameter(valid_613672, JString, required = false,
                                 default = nil)
  if valid_613672 != nil:
    section.add "X-Amz-Content-Sha256", valid_613672
  var valid_613673 = header.getOrDefault("X-Amz-Date")
  valid_613673 = validateParameter(valid_613673, JString, required = false,
                                 default = nil)
  if valid_613673 != nil:
    section.add "X-Amz-Date", valid_613673
  var valid_613674 = header.getOrDefault("X-Amz-Credential")
  valid_613674 = validateParameter(valid_613674, JString, required = false,
                                 default = nil)
  if valid_613674 != nil:
    section.add "X-Amz-Credential", valid_613674
  var valid_613675 = header.getOrDefault("X-Amz-Security-Token")
  valid_613675 = validateParameter(valid_613675, JString, required = false,
                                 default = nil)
  if valid_613675 != nil:
    section.add "X-Amz-Security-Token", valid_613675
  var valid_613676 = header.getOrDefault("X-Amz-Algorithm")
  valid_613676 = validateParameter(valid_613676, JString, required = false,
                                 default = nil)
  if valid_613676 != nil:
    section.add "X-Amz-Algorithm", valid_613676
  var valid_613677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613677 = validateParameter(valid_613677, JString, required = false,
                                 default = nil)
  if valid_613677 != nil:
    section.add "X-Amz-SignedHeaders", valid_613677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613678: Call_DescribeMultiplexProgram_613666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the details for a program in a multiplex.
  ## 
  let valid = call_613678.validator(path, query, header, formData, body)
  let scheme = call_613678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613678.url(scheme.get, call_613678.host, call_613678.base,
                         call_613678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613678, url, valid)

proc call*(call_613679: Call_DescribeMultiplexProgram_613666; multiplexId: string;
          programName: string): Recallable =
  ## describeMultiplexProgram
  ## Get the details for a program in a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   programName: string (required)
  ##              : Placeholder documentation for __string
  var path_613680 = newJObject()
  add(path_613680, "multiplexId", newJString(multiplexId))
  add(path_613680, "programName", newJString(programName))
  result = call_613679.call(path_613680, nil, nil, nil, nil)

var describeMultiplexProgram* = Call_DescribeMultiplexProgram_613666(
    name: "describeMultiplexProgram", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs/{programName}",
    validator: validate_DescribeMultiplexProgram_613667, base: "/",
    url: url_DescribeMultiplexProgram_613668, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMultiplexProgram_613698 = ref object of OpenApiRestCall_612658
proc url_DeleteMultiplexProgram_613700(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMultiplexProgram_613699(path: JsonNode; query: JsonNode;
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
  var valid_613701 = path.getOrDefault("multiplexId")
  valid_613701 = validateParameter(valid_613701, JString, required = true,
                                 default = nil)
  if valid_613701 != nil:
    section.add "multiplexId", valid_613701
  var valid_613702 = path.getOrDefault("programName")
  valid_613702 = validateParameter(valid_613702, JString, required = true,
                                 default = nil)
  if valid_613702 != nil:
    section.add "programName", valid_613702
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
  var valid_613703 = header.getOrDefault("X-Amz-Signature")
  valid_613703 = validateParameter(valid_613703, JString, required = false,
                                 default = nil)
  if valid_613703 != nil:
    section.add "X-Amz-Signature", valid_613703
  var valid_613704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613704 = validateParameter(valid_613704, JString, required = false,
                                 default = nil)
  if valid_613704 != nil:
    section.add "X-Amz-Content-Sha256", valid_613704
  var valid_613705 = header.getOrDefault("X-Amz-Date")
  valid_613705 = validateParameter(valid_613705, JString, required = false,
                                 default = nil)
  if valid_613705 != nil:
    section.add "X-Amz-Date", valid_613705
  var valid_613706 = header.getOrDefault("X-Amz-Credential")
  valid_613706 = validateParameter(valid_613706, JString, required = false,
                                 default = nil)
  if valid_613706 != nil:
    section.add "X-Amz-Credential", valid_613706
  var valid_613707 = header.getOrDefault("X-Amz-Security-Token")
  valid_613707 = validateParameter(valid_613707, JString, required = false,
                                 default = nil)
  if valid_613707 != nil:
    section.add "X-Amz-Security-Token", valid_613707
  var valid_613708 = header.getOrDefault("X-Amz-Algorithm")
  valid_613708 = validateParameter(valid_613708, JString, required = false,
                                 default = nil)
  if valid_613708 != nil:
    section.add "X-Amz-Algorithm", valid_613708
  var valid_613709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613709 = validateParameter(valid_613709, JString, required = false,
                                 default = nil)
  if valid_613709 != nil:
    section.add "X-Amz-SignedHeaders", valid_613709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613710: Call_DeleteMultiplexProgram_613698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a program from a multiplex.
  ## 
  let valid = call_613710.validator(path, query, header, formData, body)
  let scheme = call_613710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613710.url(scheme.get, call_613710.host, call_613710.base,
                         call_613710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613710, url, valid)

proc call*(call_613711: Call_DeleteMultiplexProgram_613698; multiplexId: string;
          programName: string): Recallable =
  ## deleteMultiplexProgram
  ## Delete a program from a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   programName: string (required)
  ##              : Placeholder documentation for __string
  var path_613712 = newJObject()
  add(path_613712, "multiplexId", newJString(multiplexId))
  add(path_613712, "programName", newJString(programName))
  result = call_613711.call(path_613712, nil, nil, nil, nil)

var deleteMultiplexProgram* = Call_DeleteMultiplexProgram_613698(
    name: "deleteMultiplexProgram", meth: HttpMethod.HttpDelete,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs/{programName}",
    validator: validate_DeleteMultiplexProgram_613699, base: "/",
    url: url_DeleteMultiplexProgram_613700, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReservation_613727 = ref object of OpenApiRestCall_612658
proc url_UpdateReservation_613729(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateReservation_613728(path: JsonNode; query: JsonNode;
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
  var valid_613730 = path.getOrDefault("reservationId")
  valid_613730 = validateParameter(valid_613730, JString, required = true,
                                 default = nil)
  if valid_613730 != nil:
    section.add "reservationId", valid_613730
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
  var valid_613731 = header.getOrDefault("X-Amz-Signature")
  valid_613731 = validateParameter(valid_613731, JString, required = false,
                                 default = nil)
  if valid_613731 != nil:
    section.add "X-Amz-Signature", valid_613731
  var valid_613732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613732 = validateParameter(valid_613732, JString, required = false,
                                 default = nil)
  if valid_613732 != nil:
    section.add "X-Amz-Content-Sha256", valid_613732
  var valid_613733 = header.getOrDefault("X-Amz-Date")
  valid_613733 = validateParameter(valid_613733, JString, required = false,
                                 default = nil)
  if valid_613733 != nil:
    section.add "X-Amz-Date", valid_613733
  var valid_613734 = header.getOrDefault("X-Amz-Credential")
  valid_613734 = validateParameter(valid_613734, JString, required = false,
                                 default = nil)
  if valid_613734 != nil:
    section.add "X-Amz-Credential", valid_613734
  var valid_613735 = header.getOrDefault("X-Amz-Security-Token")
  valid_613735 = validateParameter(valid_613735, JString, required = false,
                                 default = nil)
  if valid_613735 != nil:
    section.add "X-Amz-Security-Token", valid_613735
  var valid_613736 = header.getOrDefault("X-Amz-Algorithm")
  valid_613736 = validateParameter(valid_613736, JString, required = false,
                                 default = nil)
  if valid_613736 != nil:
    section.add "X-Amz-Algorithm", valid_613736
  var valid_613737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613737 = validateParameter(valid_613737, JString, required = false,
                                 default = nil)
  if valid_613737 != nil:
    section.add "X-Amz-SignedHeaders", valid_613737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613739: Call_UpdateReservation_613727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update reservation.
  ## 
  let valid = call_613739.validator(path, query, header, formData, body)
  let scheme = call_613739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613739.url(scheme.get, call_613739.host, call_613739.base,
                         call_613739.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613739, url, valid)

proc call*(call_613740: Call_UpdateReservation_613727; body: JsonNode;
          reservationId: string): Recallable =
  ## updateReservation
  ## Update reservation.
  ##   body: JObject (required)
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_613741 = newJObject()
  var body_613742 = newJObject()
  if body != nil:
    body_613742 = body
  add(path_613741, "reservationId", newJString(reservationId))
  result = call_613740.call(path_613741, nil, nil, nil, body_613742)

var updateReservation* = Call_UpdateReservation_613727(name: "updateReservation",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_UpdateReservation_613728, base: "/",
    url: url_UpdateReservation_613729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservation_613713 = ref object of OpenApiRestCall_612658
proc url_DescribeReservation_613715(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeReservation_613714(path: JsonNode; query: JsonNode;
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
  var valid_613716 = path.getOrDefault("reservationId")
  valid_613716 = validateParameter(valid_613716, JString, required = true,
                                 default = nil)
  if valid_613716 != nil:
    section.add "reservationId", valid_613716
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
  var valid_613717 = header.getOrDefault("X-Amz-Signature")
  valid_613717 = validateParameter(valid_613717, JString, required = false,
                                 default = nil)
  if valid_613717 != nil:
    section.add "X-Amz-Signature", valid_613717
  var valid_613718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613718 = validateParameter(valid_613718, JString, required = false,
                                 default = nil)
  if valid_613718 != nil:
    section.add "X-Amz-Content-Sha256", valid_613718
  var valid_613719 = header.getOrDefault("X-Amz-Date")
  valid_613719 = validateParameter(valid_613719, JString, required = false,
                                 default = nil)
  if valid_613719 != nil:
    section.add "X-Amz-Date", valid_613719
  var valid_613720 = header.getOrDefault("X-Amz-Credential")
  valid_613720 = validateParameter(valid_613720, JString, required = false,
                                 default = nil)
  if valid_613720 != nil:
    section.add "X-Amz-Credential", valid_613720
  var valid_613721 = header.getOrDefault("X-Amz-Security-Token")
  valid_613721 = validateParameter(valid_613721, JString, required = false,
                                 default = nil)
  if valid_613721 != nil:
    section.add "X-Amz-Security-Token", valid_613721
  var valid_613722 = header.getOrDefault("X-Amz-Algorithm")
  valid_613722 = validateParameter(valid_613722, JString, required = false,
                                 default = nil)
  if valid_613722 != nil:
    section.add "X-Amz-Algorithm", valid_613722
  var valid_613723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613723 = validateParameter(valid_613723, JString, required = false,
                                 default = nil)
  if valid_613723 != nil:
    section.add "X-Amz-SignedHeaders", valid_613723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613724: Call_DescribeReservation_613713; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details for a reservation.
  ## 
  let valid = call_613724.validator(path, query, header, formData, body)
  let scheme = call_613724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613724.url(scheme.get, call_613724.host, call_613724.base,
                         call_613724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613724, url, valid)

proc call*(call_613725: Call_DescribeReservation_613713; reservationId: string): Recallable =
  ## describeReservation
  ## Get details for a reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_613726 = newJObject()
  add(path_613726, "reservationId", newJString(reservationId))
  result = call_613725.call(path_613726, nil, nil, nil, nil)

var describeReservation* = Call_DescribeReservation_613713(
    name: "describeReservation", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/reservations/{reservationId}",
    validator: validate_DescribeReservation_613714, base: "/",
    url: url_DescribeReservation_613715, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReservation_613743 = ref object of OpenApiRestCall_612658
proc url_DeleteReservation_613745(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteReservation_613744(path: JsonNode; query: JsonNode;
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
  var valid_613746 = path.getOrDefault("reservationId")
  valid_613746 = validateParameter(valid_613746, JString, required = true,
                                 default = nil)
  if valid_613746 != nil:
    section.add "reservationId", valid_613746
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
  var valid_613747 = header.getOrDefault("X-Amz-Signature")
  valid_613747 = validateParameter(valid_613747, JString, required = false,
                                 default = nil)
  if valid_613747 != nil:
    section.add "X-Amz-Signature", valid_613747
  var valid_613748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613748 = validateParameter(valid_613748, JString, required = false,
                                 default = nil)
  if valid_613748 != nil:
    section.add "X-Amz-Content-Sha256", valid_613748
  var valid_613749 = header.getOrDefault("X-Amz-Date")
  valid_613749 = validateParameter(valid_613749, JString, required = false,
                                 default = nil)
  if valid_613749 != nil:
    section.add "X-Amz-Date", valid_613749
  var valid_613750 = header.getOrDefault("X-Amz-Credential")
  valid_613750 = validateParameter(valid_613750, JString, required = false,
                                 default = nil)
  if valid_613750 != nil:
    section.add "X-Amz-Credential", valid_613750
  var valid_613751 = header.getOrDefault("X-Amz-Security-Token")
  valid_613751 = validateParameter(valid_613751, JString, required = false,
                                 default = nil)
  if valid_613751 != nil:
    section.add "X-Amz-Security-Token", valid_613751
  var valid_613752 = header.getOrDefault("X-Amz-Algorithm")
  valid_613752 = validateParameter(valid_613752, JString, required = false,
                                 default = nil)
  if valid_613752 != nil:
    section.add "X-Amz-Algorithm", valid_613752
  var valid_613753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613753 = validateParameter(valid_613753, JString, required = false,
                                 default = nil)
  if valid_613753 != nil:
    section.add "X-Amz-SignedHeaders", valid_613753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613754: Call_DeleteReservation_613743; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete an expired reservation.
  ## 
  let valid = call_613754.validator(path, query, header, formData, body)
  let scheme = call_613754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613754.url(scheme.get, call_613754.host, call_613754.base,
                         call_613754.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613754, url, valid)

proc call*(call_613755: Call_DeleteReservation_613743; reservationId: string): Recallable =
  ## deleteReservation
  ## Delete an expired reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_613756 = newJObject()
  add(path_613756, "reservationId", newJString(reservationId))
  result = call_613755.call(path_613756, nil, nil, nil, nil)

var deleteReservation* = Call_DeleteReservation_613743(name: "deleteReservation",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_DeleteReservation_613744, base: "/",
    url: url_DeleteReservation_613745, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_613757 = ref object of OpenApiRestCall_612658
proc url_DeleteTags_613759(protocol: Scheme; host: string; base: string; route: string;
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

proc validate_DeleteTags_613758(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613760 = path.getOrDefault("resource-arn")
  valid_613760 = validateParameter(valid_613760, JString, required = true,
                                 default = nil)
  if valid_613760 != nil:
    section.add "resource-arn", valid_613760
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : Placeholder documentation for __listOf__string
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_613761 = query.getOrDefault("tagKeys")
  valid_613761 = validateParameter(valid_613761, JArray, required = true, default = nil)
  if valid_613761 != nil:
    section.add "tagKeys", valid_613761
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
  var valid_613762 = header.getOrDefault("X-Amz-Signature")
  valid_613762 = validateParameter(valid_613762, JString, required = false,
                                 default = nil)
  if valid_613762 != nil:
    section.add "X-Amz-Signature", valid_613762
  var valid_613763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613763 = validateParameter(valid_613763, JString, required = false,
                                 default = nil)
  if valid_613763 != nil:
    section.add "X-Amz-Content-Sha256", valid_613763
  var valid_613764 = header.getOrDefault("X-Amz-Date")
  valid_613764 = validateParameter(valid_613764, JString, required = false,
                                 default = nil)
  if valid_613764 != nil:
    section.add "X-Amz-Date", valid_613764
  var valid_613765 = header.getOrDefault("X-Amz-Credential")
  valid_613765 = validateParameter(valid_613765, JString, required = false,
                                 default = nil)
  if valid_613765 != nil:
    section.add "X-Amz-Credential", valid_613765
  var valid_613766 = header.getOrDefault("X-Amz-Security-Token")
  valid_613766 = validateParameter(valid_613766, JString, required = false,
                                 default = nil)
  if valid_613766 != nil:
    section.add "X-Amz-Security-Token", valid_613766
  var valid_613767 = header.getOrDefault("X-Amz-Algorithm")
  valid_613767 = validateParameter(valid_613767, JString, required = false,
                                 default = nil)
  if valid_613767 != nil:
    section.add "X-Amz-Algorithm", valid_613767
  var valid_613768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613768 = validateParameter(valid_613768, JString, required = false,
                                 default = nil)
  if valid_613768 != nil:
    section.add "X-Amz-SignedHeaders", valid_613768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613769: Call_DeleteTags_613757; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags for a resource
  ## 
  let valid = call_613769.validator(path, query, header, formData, body)
  let scheme = call_613769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613769.url(scheme.get, call_613769.host, call_613769.base,
                         call_613769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613769, url, valid)

proc call*(call_613770: Call_DeleteTags_613757; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## deleteTags
  ## Removes tags for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  ##   tagKeys: JArray (required)
  ##          : Placeholder documentation for __listOf__string
  var path_613771 = newJObject()
  var query_613772 = newJObject()
  add(path_613771, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_613772.add "tagKeys", tagKeys
  result = call_613770.call(path_613771, query_613772, nil, nil, nil)

var deleteTags* = Call_DeleteTags_613757(name: "deleteTags",
                                      meth: HttpMethod.HttpDelete,
                                      host: "medialive.amazonaws.com", route: "/prod/tags/{resource-arn}#tagKeys",
                                      validator: validate_DeleteTags_613758,
                                      base: "/", url: url_DeleteTags_613759,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOffering_613773 = ref object of OpenApiRestCall_612658
proc url_DescribeOffering_613775(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeOffering_613774(path: JsonNode; query: JsonNode;
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
  var valid_613776 = path.getOrDefault("offeringId")
  valid_613776 = validateParameter(valid_613776, JString, required = true,
                                 default = nil)
  if valid_613776 != nil:
    section.add "offeringId", valid_613776
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
  var valid_613777 = header.getOrDefault("X-Amz-Signature")
  valid_613777 = validateParameter(valid_613777, JString, required = false,
                                 default = nil)
  if valid_613777 != nil:
    section.add "X-Amz-Signature", valid_613777
  var valid_613778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613778 = validateParameter(valid_613778, JString, required = false,
                                 default = nil)
  if valid_613778 != nil:
    section.add "X-Amz-Content-Sha256", valid_613778
  var valid_613779 = header.getOrDefault("X-Amz-Date")
  valid_613779 = validateParameter(valid_613779, JString, required = false,
                                 default = nil)
  if valid_613779 != nil:
    section.add "X-Amz-Date", valid_613779
  var valid_613780 = header.getOrDefault("X-Amz-Credential")
  valid_613780 = validateParameter(valid_613780, JString, required = false,
                                 default = nil)
  if valid_613780 != nil:
    section.add "X-Amz-Credential", valid_613780
  var valid_613781 = header.getOrDefault("X-Amz-Security-Token")
  valid_613781 = validateParameter(valid_613781, JString, required = false,
                                 default = nil)
  if valid_613781 != nil:
    section.add "X-Amz-Security-Token", valid_613781
  var valid_613782 = header.getOrDefault("X-Amz-Algorithm")
  valid_613782 = validateParameter(valid_613782, JString, required = false,
                                 default = nil)
  if valid_613782 != nil:
    section.add "X-Amz-Algorithm", valid_613782
  var valid_613783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613783 = validateParameter(valid_613783, JString, required = false,
                                 default = nil)
  if valid_613783 != nil:
    section.add "X-Amz-SignedHeaders", valid_613783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613784: Call_DescribeOffering_613773; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details for an offering.
  ## 
  let valid = call_613784.validator(path, query, header, formData, body)
  let scheme = call_613784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613784.url(scheme.get, call_613784.host, call_613784.base,
                         call_613784.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613784, url, valid)

proc call*(call_613785: Call_DescribeOffering_613773; offeringId: string): Recallable =
  ## describeOffering
  ## Get details for an offering.
  ##   offeringId: string (required)
  ##             : Placeholder documentation for __string
  var path_613786 = newJObject()
  add(path_613786, "offeringId", newJString(offeringId))
  result = call_613785.call(path_613786, nil, nil, nil, nil)

var describeOffering* = Call_DescribeOffering_613773(name: "describeOffering",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/offerings/{offeringId}", validator: validate_DescribeOffering_613774,
    base: "/", url: url_DescribeOffering_613775,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_613787 = ref object of OpenApiRestCall_612658
proc url_ListOfferings_613789(protocol: Scheme; host: string; base: string;
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

proc validate_ListOfferings_613788(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613790 = query.getOrDefault("specialFeature")
  valid_613790 = validateParameter(valid_613790, JString, required = false,
                                 default = nil)
  if valid_613790 != nil:
    section.add "specialFeature", valid_613790
  var valid_613791 = query.getOrDefault("nextToken")
  valid_613791 = validateParameter(valid_613791, JString, required = false,
                                 default = nil)
  if valid_613791 != nil:
    section.add "nextToken", valid_613791
  var valid_613792 = query.getOrDefault("MaxResults")
  valid_613792 = validateParameter(valid_613792, JString, required = false,
                                 default = nil)
  if valid_613792 != nil:
    section.add "MaxResults", valid_613792
  var valid_613793 = query.getOrDefault("channelClass")
  valid_613793 = validateParameter(valid_613793, JString, required = false,
                                 default = nil)
  if valid_613793 != nil:
    section.add "channelClass", valid_613793
  var valid_613794 = query.getOrDefault("NextToken")
  valid_613794 = validateParameter(valid_613794, JString, required = false,
                                 default = nil)
  if valid_613794 != nil:
    section.add "NextToken", valid_613794
  var valid_613795 = query.getOrDefault("videoQuality")
  valid_613795 = validateParameter(valid_613795, JString, required = false,
                                 default = nil)
  if valid_613795 != nil:
    section.add "videoQuality", valid_613795
  var valid_613796 = query.getOrDefault("maximumFramerate")
  valid_613796 = validateParameter(valid_613796, JString, required = false,
                                 default = nil)
  if valid_613796 != nil:
    section.add "maximumFramerate", valid_613796
  var valid_613797 = query.getOrDefault("maximumBitrate")
  valid_613797 = validateParameter(valid_613797, JString, required = false,
                                 default = nil)
  if valid_613797 != nil:
    section.add "maximumBitrate", valid_613797
  var valid_613798 = query.getOrDefault("resourceType")
  valid_613798 = validateParameter(valid_613798, JString, required = false,
                                 default = nil)
  if valid_613798 != nil:
    section.add "resourceType", valid_613798
  var valid_613799 = query.getOrDefault("duration")
  valid_613799 = validateParameter(valid_613799, JString, required = false,
                                 default = nil)
  if valid_613799 != nil:
    section.add "duration", valid_613799
  var valid_613800 = query.getOrDefault("channelConfiguration")
  valid_613800 = validateParameter(valid_613800, JString, required = false,
                                 default = nil)
  if valid_613800 != nil:
    section.add "channelConfiguration", valid_613800
  var valid_613801 = query.getOrDefault("codec")
  valid_613801 = validateParameter(valid_613801, JString, required = false,
                                 default = nil)
  if valid_613801 != nil:
    section.add "codec", valid_613801
  var valid_613802 = query.getOrDefault("resolution")
  valid_613802 = validateParameter(valid_613802, JString, required = false,
                                 default = nil)
  if valid_613802 != nil:
    section.add "resolution", valid_613802
  var valid_613803 = query.getOrDefault("maxResults")
  valid_613803 = validateParameter(valid_613803, JInt, required = false, default = nil)
  if valid_613803 != nil:
    section.add "maxResults", valid_613803
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
  var valid_613804 = header.getOrDefault("X-Amz-Signature")
  valid_613804 = validateParameter(valid_613804, JString, required = false,
                                 default = nil)
  if valid_613804 != nil:
    section.add "X-Amz-Signature", valid_613804
  var valid_613805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613805 = validateParameter(valid_613805, JString, required = false,
                                 default = nil)
  if valid_613805 != nil:
    section.add "X-Amz-Content-Sha256", valid_613805
  var valid_613806 = header.getOrDefault("X-Amz-Date")
  valid_613806 = validateParameter(valid_613806, JString, required = false,
                                 default = nil)
  if valid_613806 != nil:
    section.add "X-Amz-Date", valid_613806
  var valid_613807 = header.getOrDefault("X-Amz-Credential")
  valid_613807 = validateParameter(valid_613807, JString, required = false,
                                 default = nil)
  if valid_613807 != nil:
    section.add "X-Amz-Credential", valid_613807
  var valid_613808 = header.getOrDefault("X-Amz-Security-Token")
  valid_613808 = validateParameter(valid_613808, JString, required = false,
                                 default = nil)
  if valid_613808 != nil:
    section.add "X-Amz-Security-Token", valid_613808
  var valid_613809 = header.getOrDefault("X-Amz-Algorithm")
  valid_613809 = validateParameter(valid_613809, JString, required = false,
                                 default = nil)
  if valid_613809 != nil:
    section.add "X-Amz-Algorithm", valid_613809
  var valid_613810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613810 = validateParameter(valid_613810, JString, required = false,
                                 default = nil)
  if valid_613810 != nil:
    section.add "X-Amz-SignedHeaders", valid_613810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613811: Call_ListOfferings_613787; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List offerings available for purchase.
  ## 
  let valid = call_613811.validator(path, query, header, formData, body)
  let scheme = call_613811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613811.url(scheme.get, call_613811.host, call_613811.base,
                         call_613811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613811, url, valid)

proc call*(call_613812: Call_ListOfferings_613787; specialFeature: string = "";
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
  var query_613813 = newJObject()
  add(query_613813, "specialFeature", newJString(specialFeature))
  add(query_613813, "nextToken", newJString(nextToken))
  add(query_613813, "MaxResults", newJString(MaxResults))
  add(query_613813, "channelClass", newJString(channelClass))
  add(query_613813, "NextToken", newJString(NextToken))
  add(query_613813, "videoQuality", newJString(videoQuality))
  add(query_613813, "maximumFramerate", newJString(maximumFramerate))
  add(query_613813, "maximumBitrate", newJString(maximumBitrate))
  add(query_613813, "resourceType", newJString(resourceType))
  add(query_613813, "duration", newJString(duration))
  add(query_613813, "channelConfiguration", newJString(channelConfiguration))
  add(query_613813, "codec", newJString(codec))
  add(query_613813, "resolution", newJString(resolution))
  add(query_613813, "maxResults", newJInt(maxResults))
  result = call_613812.call(nil, query_613813, nil, nil, nil)

var listOfferings* = Call_ListOfferings_613787(name: "listOfferings",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/offerings", validator: validate_ListOfferings_613788, base: "/",
    url: url_ListOfferings_613789, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReservations_613814 = ref object of OpenApiRestCall_612658
proc url_ListReservations_613816(protocol: Scheme; host: string; base: string;
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

proc validate_ListReservations_613815(path: JsonNode; query: JsonNode;
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
  var valid_613817 = query.getOrDefault("specialFeature")
  valid_613817 = validateParameter(valid_613817, JString, required = false,
                                 default = nil)
  if valid_613817 != nil:
    section.add "specialFeature", valid_613817
  var valid_613818 = query.getOrDefault("nextToken")
  valid_613818 = validateParameter(valid_613818, JString, required = false,
                                 default = nil)
  if valid_613818 != nil:
    section.add "nextToken", valid_613818
  var valid_613819 = query.getOrDefault("MaxResults")
  valid_613819 = validateParameter(valid_613819, JString, required = false,
                                 default = nil)
  if valid_613819 != nil:
    section.add "MaxResults", valid_613819
  var valid_613820 = query.getOrDefault("channelClass")
  valid_613820 = validateParameter(valid_613820, JString, required = false,
                                 default = nil)
  if valid_613820 != nil:
    section.add "channelClass", valid_613820
  var valid_613821 = query.getOrDefault("NextToken")
  valid_613821 = validateParameter(valid_613821, JString, required = false,
                                 default = nil)
  if valid_613821 != nil:
    section.add "NextToken", valid_613821
  var valid_613822 = query.getOrDefault("videoQuality")
  valid_613822 = validateParameter(valid_613822, JString, required = false,
                                 default = nil)
  if valid_613822 != nil:
    section.add "videoQuality", valid_613822
  var valid_613823 = query.getOrDefault("maximumFramerate")
  valid_613823 = validateParameter(valid_613823, JString, required = false,
                                 default = nil)
  if valid_613823 != nil:
    section.add "maximumFramerate", valid_613823
  var valid_613824 = query.getOrDefault("maximumBitrate")
  valid_613824 = validateParameter(valid_613824, JString, required = false,
                                 default = nil)
  if valid_613824 != nil:
    section.add "maximumBitrate", valid_613824
  var valid_613825 = query.getOrDefault("resourceType")
  valid_613825 = validateParameter(valid_613825, JString, required = false,
                                 default = nil)
  if valid_613825 != nil:
    section.add "resourceType", valid_613825
  var valid_613826 = query.getOrDefault("codec")
  valid_613826 = validateParameter(valid_613826, JString, required = false,
                                 default = nil)
  if valid_613826 != nil:
    section.add "codec", valid_613826
  var valid_613827 = query.getOrDefault("resolution")
  valid_613827 = validateParameter(valid_613827, JString, required = false,
                                 default = nil)
  if valid_613827 != nil:
    section.add "resolution", valid_613827
  var valid_613828 = query.getOrDefault("maxResults")
  valid_613828 = validateParameter(valid_613828, JInt, required = false, default = nil)
  if valid_613828 != nil:
    section.add "maxResults", valid_613828
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
  var valid_613829 = header.getOrDefault("X-Amz-Signature")
  valid_613829 = validateParameter(valid_613829, JString, required = false,
                                 default = nil)
  if valid_613829 != nil:
    section.add "X-Amz-Signature", valid_613829
  var valid_613830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613830 = validateParameter(valid_613830, JString, required = false,
                                 default = nil)
  if valid_613830 != nil:
    section.add "X-Amz-Content-Sha256", valid_613830
  var valid_613831 = header.getOrDefault("X-Amz-Date")
  valid_613831 = validateParameter(valid_613831, JString, required = false,
                                 default = nil)
  if valid_613831 != nil:
    section.add "X-Amz-Date", valid_613831
  var valid_613832 = header.getOrDefault("X-Amz-Credential")
  valid_613832 = validateParameter(valid_613832, JString, required = false,
                                 default = nil)
  if valid_613832 != nil:
    section.add "X-Amz-Credential", valid_613832
  var valid_613833 = header.getOrDefault("X-Amz-Security-Token")
  valid_613833 = validateParameter(valid_613833, JString, required = false,
                                 default = nil)
  if valid_613833 != nil:
    section.add "X-Amz-Security-Token", valid_613833
  var valid_613834 = header.getOrDefault("X-Amz-Algorithm")
  valid_613834 = validateParameter(valid_613834, JString, required = false,
                                 default = nil)
  if valid_613834 != nil:
    section.add "X-Amz-Algorithm", valid_613834
  var valid_613835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613835 = validateParameter(valid_613835, JString, required = false,
                                 default = nil)
  if valid_613835 != nil:
    section.add "X-Amz-SignedHeaders", valid_613835
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613836: Call_ListReservations_613814; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List purchased reservations.
  ## 
  let valid = call_613836.validator(path, query, header, formData, body)
  let scheme = call_613836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613836.url(scheme.get, call_613836.host, call_613836.base,
                         call_613836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613836, url, valid)

proc call*(call_613837: Call_ListReservations_613814; specialFeature: string = "";
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
  var query_613838 = newJObject()
  add(query_613838, "specialFeature", newJString(specialFeature))
  add(query_613838, "nextToken", newJString(nextToken))
  add(query_613838, "MaxResults", newJString(MaxResults))
  add(query_613838, "channelClass", newJString(channelClass))
  add(query_613838, "NextToken", newJString(NextToken))
  add(query_613838, "videoQuality", newJString(videoQuality))
  add(query_613838, "maximumFramerate", newJString(maximumFramerate))
  add(query_613838, "maximumBitrate", newJString(maximumBitrate))
  add(query_613838, "resourceType", newJString(resourceType))
  add(query_613838, "codec", newJString(codec))
  add(query_613838, "resolution", newJString(resolution))
  add(query_613838, "maxResults", newJInt(maxResults))
  result = call_613837.call(nil, query_613838, nil, nil, nil)

var listReservations* = Call_ListReservations_613814(name: "listReservations",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/reservations", validator: validate_ListReservations_613815,
    base: "/", url: url_ListReservations_613816,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_613839 = ref object of OpenApiRestCall_612658
proc url_PurchaseOffering_613841(protocol: Scheme; host: string; base: string;
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

proc validate_PurchaseOffering_613840(path: JsonNode; query: JsonNode;
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
  var valid_613842 = path.getOrDefault("offeringId")
  valid_613842 = validateParameter(valid_613842, JString, required = true,
                                 default = nil)
  if valid_613842 != nil:
    section.add "offeringId", valid_613842
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
  var valid_613843 = header.getOrDefault("X-Amz-Signature")
  valid_613843 = validateParameter(valid_613843, JString, required = false,
                                 default = nil)
  if valid_613843 != nil:
    section.add "X-Amz-Signature", valid_613843
  var valid_613844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613844 = validateParameter(valid_613844, JString, required = false,
                                 default = nil)
  if valid_613844 != nil:
    section.add "X-Amz-Content-Sha256", valid_613844
  var valid_613845 = header.getOrDefault("X-Amz-Date")
  valid_613845 = validateParameter(valid_613845, JString, required = false,
                                 default = nil)
  if valid_613845 != nil:
    section.add "X-Amz-Date", valid_613845
  var valid_613846 = header.getOrDefault("X-Amz-Credential")
  valid_613846 = validateParameter(valid_613846, JString, required = false,
                                 default = nil)
  if valid_613846 != nil:
    section.add "X-Amz-Credential", valid_613846
  var valid_613847 = header.getOrDefault("X-Amz-Security-Token")
  valid_613847 = validateParameter(valid_613847, JString, required = false,
                                 default = nil)
  if valid_613847 != nil:
    section.add "X-Amz-Security-Token", valid_613847
  var valid_613848 = header.getOrDefault("X-Amz-Algorithm")
  valid_613848 = validateParameter(valid_613848, JString, required = false,
                                 default = nil)
  if valid_613848 != nil:
    section.add "X-Amz-Algorithm", valid_613848
  var valid_613849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613849 = validateParameter(valid_613849, JString, required = false,
                                 default = nil)
  if valid_613849 != nil:
    section.add "X-Amz-SignedHeaders", valid_613849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613851: Call_PurchaseOffering_613839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Purchase an offering and create a reservation.
  ## 
  let valid = call_613851.validator(path, query, header, formData, body)
  let scheme = call_613851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613851.url(scheme.get, call_613851.host, call_613851.base,
                         call_613851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613851, url, valid)

proc call*(call_613852: Call_PurchaseOffering_613839; body: JsonNode;
          offeringId: string): Recallable =
  ## purchaseOffering
  ## Purchase an offering and create a reservation.
  ##   body: JObject (required)
  ##   offeringId: string (required)
  ##             : Placeholder documentation for __string
  var path_613853 = newJObject()
  var body_613854 = newJObject()
  if body != nil:
    body_613854 = body
  add(path_613853, "offeringId", newJString(offeringId))
  result = call_613852.call(path_613853, nil, nil, nil, body_613854)

var purchaseOffering* = Call_PurchaseOffering_613839(name: "purchaseOffering",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/offerings/{offeringId}/purchase",
    validator: validate_PurchaseOffering_613840, base: "/",
    url: url_PurchaseOffering_613841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChannel_613855 = ref object of OpenApiRestCall_612658
proc url_StartChannel_613857(protocol: Scheme; host: string; base: string;
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

proc validate_StartChannel_613856(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613858 = path.getOrDefault("channelId")
  valid_613858 = validateParameter(valid_613858, JString, required = true,
                                 default = nil)
  if valid_613858 != nil:
    section.add "channelId", valid_613858
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
  var valid_613859 = header.getOrDefault("X-Amz-Signature")
  valid_613859 = validateParameter(valid_613859, JString, required = false,
                                 default = nil)
  if valid_613859 != nil:
    section.add "X-Amz-Signature", valid_613859
  var valid_613860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613860 = validateParameter(valid_613860, JString, required = false,
                                 default = nil)
  if valid_613860 != nil:
    section.add "X-Amz-Content-Sha256", valid_613860
  var valid_613861 = header.getOrDefault("X-Amz-Date")
  valid_613861 = validateParameter(valid_613861, JString, required = false,
                                 default = nil)
  if valid_613861 != nil:
    section.add "X-Amz-Date", valid_613861
  var valid_613862 = header.getOrDefault("X-Amz-Credential")
  valid_613862 = validateParameter(valid_613862, JString, required = false,
                                 default = nil)
  if valid_613862 != nil:
    section.add "X-Amz-Credential", valid_613862
  var valid_613863 = header.getOrDefault("X-Amz-Security-Token")
  valid_613863 = validateParameter(valid_613863, JString, required = false,
                                 default = nil)
  if valid_613863 != nil:
    section.add "X-Amz-Security-Token", valid_613863
  var valid_613864 = header.getOrDefault("X-Amz-Algorithm")
  valid_613864 = validateParameter(valid_613864, JString, required = false,
                                 default = nil)
  if valid_613864 != nil:
    section.add "X-Amz-Algorithm", valid_613864
  var valid_613865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613865 = validateParameter(valid_613865, JString, required = false,
                                 default = nil)
  if valid_613865 != nil:
    section.add "X-Amz-SignedHeaders", valid_613865
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613866: Call_StartChannel_613855; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an existing channel
  ## 
  let valid = call_613866.validator(path, query, header, formData, body)
  let scheme = call_613866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613866.url(scheme.get, call_613866.host, call_613866.base,
                         call_613866.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613866, url, valid)

proc call*(call_613867: Call_StartChannel_613855; channelId: string): Recallable =
  ## startChannel
  ## Starts an existing channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_613868 = newJObject()
  add(path_613868, "channelId", newJString(channelId))
  result = call_613867.call(path_613868, nil, nil, nil, nil)

var startChannel* = Call_StartChannel_613855(name: "startChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/start", validator: validate_StartChannel_613856,
    base: "/", url: url_StartChannel_613857, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMultiplex_613869 = ref object of OpenApiRestCall_612658
proc url_StartMultiplex_613871(protocol: Scheme; host: string; base: string;
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

proc validate_StartMultiplex_613870(path: JsonNode; query: JsonNode;
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
  var valid_613872 = path.getOrDefault("multiplexId")
  valid_613872 = validateParameter(valid_613872, JString, required = true,
                                 default = nil)
  if valid_613872 != nil:
    section.add "multiplexId", valid_613872
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
  var valid_613873 = header.getOrDefault("X-Amz-Signature")
  valid_613873 = validateParameter(valid_613873, JString, required = false,
                                 default = nil)
  if valid_613873 != nil:
    section.add "X-Amz-Signature", valid_613873
  var valid_613874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613874 = validateParameter(valid_613874, JString, required = false,
                                 default = nil)
  if valid_613874 != nil:
    section.add "X-Amz-Content-Sha256", valid_613874
  var valid_613875 = header.getOrDefault("X-Amz-Date")
  valid_613875 = validateParameter(valid_613875, JString, required = false,
                                 default = nil)
  if valid_613875 != nil:
    section.add "X-Amz-Date", valid_613875
  var valid_613876 = header.getOrDefault("X-Amz-Credential")
  valid_613876 = validateParameter(valid_613876, JString, required = false,
                                 default = nil)
  if valid_613876 != nil:
    section.add "X-Amz-Credential", valid_613876
  var valid_613877 = header.getOrDefault("X-Amz-Security-Token")
  valid_613877 = validateParameter(valid_613877, JString, required = false,
                                 default = nil)
  if valid_613877 != nil:
    section.add "X-Amz-Security-Token", valid_613877
  var valid_613878 = header.getOrDefault("X-Amz-Algorithm")
  valid_613878 = validateParameter(valid_613878, JString, required = false,
                                 default = nil)
  if valid_613878 != nil:
    section.add "X-Amz-Algorithm", valid_613878
  var valid_613879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613879 = validateParameter(valid_613879, JString, required = false,
                                 default = nil)
  if valid_613879 != nil:
    section.add "X-Amz-SignedHeaders", valid_613879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613880: Call_StartMultiplex_613869; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Start (run) the multiplex. Starting the multiplex does not start the channels. You must explicitly start each channel.
  ## 
  let valid = call_613880.validator(path, query, header, formData, body)
  let scheme = call_613880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613880.url(scheme.get, call_613880.host, call_613880.base,
                         call_613880.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613880, url, valid)

proc call*(call_613881: Call_StartMultiplex_613869; multiplexId: string): Recallable =
  ## startMultiplex
  ## Start (run) the multiplex. Starting the multiplex does not start the channels. You must explicitly start each channel.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_613882 = newJObject()
  add(path_613882, "multiplexId", newJString(multiplexId))
  result = call_613881.call(path_613882, nil, nil, nil, nil)

var startMultiplex* = Call_StartMultiplex_613869(name: "startMultiplex",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/start",
    validator: validate_StartMultiplex_613870, base: "/", url: url_StartMultiplex_613871,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopChannel_613883 = ref object of OpenApiRestCall_612658
proc url_StopChannel_613885(protocol: Scheme; host: string; base: string;
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

proc validate_StopChannel_613884(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613886 = path.getOrDefault("channelId")
  valid_613886 = validateParameter(valid_613886, JString, required = true,
                                 default = nil)
  if valid_613886 != nil:
    section.add "channelId", valid_613886
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
  var valid_613887 = header.getOrDefault("X-Amz-Signature")
  valid_613887 = validateParameter(valid_613887, JString, required = false,
                                 default = nil)
  if valid_613887 != nil:
    section.add "X-Amz-Signature", valid_613887
  var valid_613888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613888 = validateParameter(valid_613888, JString, required = false,
                                 default = nil)
  if valid_613888 != nil:
    section.add "X-Amz-Content-Sha256", valid_613888
  var valid_613889 = header.getOrDefault("X-Amz-Date")
  valid_613889 = validateParameter(valid_613889, JString, required = false,
                                 default = nil)
  if valid_613889 != nil:
    section.add "X-Amz-Date", valid_613889
  var valid_613890 = header.getOrDefault("X-Amz-Credential")
  valid_613890 = validateParameter(valid_613890, JString, required = false,
                                 default = nil)
  if valid_613890 != nil:
    section.add "X-Amz-Credential", valid_613890
  var valid_613891 = header.getOrDefault("X-Amz-Security-Token")
  valid_613891 = validateParameter(valid_613891, JString, required = false,
                                 default = nil)
  if valid_613891 != nil:
    section.add "X-Amz-Security-Token", valid_613891
  var valid_613892 = header.getOrDefault("X-Amz-Algorithm")
  valid_613892 = validateParameter(valid_613892, JString, required = false,
                                 default = nil)
  if valid_613892 != nil:
    section.add "X-Amz-Algorithm", valid_613892
  var valid_613893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613893 = validateParameter(valid_613893, JString, required = false,
                                 default = nil)
  if valid_613893 != nil:
    section.add "X-Amz-SignedHeaders", valid_613893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613894: Call_StopChannel_613883; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running channel
  ## 
  let valid = call_613894.validator(path, query, header, formData, body)
  let scheme = call_613894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613894.url(scheme.get, call_613894.host, call_613894.base,
                         call_613894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613894, url, valid)

proc call*(call_613895: Call_StopChannel_613883; channelId: string): Recallable =
  ## stopChannel
  ## Stops a running channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_613896 = newJObject()
  add(path_613896, "channelId", newJString(channelId))
  result = call_613895.call(path_613896, nil, nil, nil, nil)

var stopChannel* = Call_StopChannel_613883(name: "stopChannel",
                                        meth: HttpMethod.HttpPost,
                                        host: "medialive.amazonaws.com", route: "/prod/channels/{channelId}/stop",
                                        validator: validate_StopChannel_613884,
                                        base: "/", url: url_StopChannel_613885,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMultiplex_613897 = ref object of OpenApiRestCall_612658
proc url_StopMultiplex_613899(protocol: Scheme; host: string; base: string;
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

proc validate_StopMultiplex_613898(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_613900 = path.getOrDefault("multiplexId")
  valid_613900 = validateParameter(valid_613900, JString, required = true,
                                 default = nil)
  if valid_613900 != nil:
    section.add "multiplexId", valid_613900
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
  var valid_613901 = header.getOrDefault("X-Amz-Signature")
  valid_613901 = validateParameter(valid_613901, JString, required = false,
                                 default = nil)
  if valid_613901 != nil:
    section.add "X-Amz-Signature", valid_613901
  var valid_613902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613902 = validateParameter(valid_613902, JString, required = false,
                                 default = nil)
  if valid_613902 != nil:
    section.add "X-Amz-Content-Sha256", valid_613902
  var valid_613903 = header.getOrDefault("X-Amz-Date")
  valid_613903 = validateParameter(valid_613903, JString, required = false,
                                 default = nil)
  if valid_613903 != nil:
    section.add "X-Amz-Date", valid_613903
  var valid_613904 = header.getOrDefault("X-Amz-Credential")
  valid_613904 = validateParameter(valid_613904, JString, required = false,
                                 default = nil)
  if valid_613904 != nil:
    section.add "X-Amz-Credential", valid_613904
  var valid_613905 = header.getOrDefault("X-Amz-Security-Token")
  valid_613905 = validateParameter(valid_613905, JString, required = false,
                                 default = nil)
  if valid_613905 != nil:
    section.add "X-Amz-Security-Token", valid_613905
  var valid_613906 = header.getOrDefault("X-Amz-Algorithm")
  valid_613906 = validateParameter(valid_613906, JString, required = false,
                                 default = nil)
  if valid_613906 != nil:
    section.add "X-Amz-Algorithm", valid_613906
  var valid_613907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613907 = validateParameter(valid_613907, JString, required = false,
                                 default = nil)
  if valid_613907 != nil:
    section.add "X-Amz-SignedHeaders", valid_613907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_613908: Call_StopMultiplex_613897; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running multiplex. If the multiplex isn't running, this action has no effect.
  ## 
  let valid = call_613908.validator(path, query, header, formData, body)
  let scheme = call_613908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613908.url(scheme.get, call_613908.host, call_613908.base,
                         call_613908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613908, url, valid)

proc call*(call_613909: Call_StopMultiplex_613897; multiplexId: string): Recallable =
  ## stopMultiplex
  ## Stops a running multiplex. If the multiplex isn't running, this action has no effect.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_613910 = newJObject()
  add(path_613910, "multiplexId", newJString(multiplexId))
  result = call_613909.call(path_613910, nil, nil, nil, nil)

var stopMultiplex* = Call_StopMultiplex_613897(name: "stopMultiplex",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/stop",
    validator: validate_StopMultiplex_613898, base: "/", url: url_StopMultiplex_613899,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannelClass_613911 = ref object of OpenApiRestCall_612658
proc url_UpdateChannelClass_613913(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateChannelClass_613912(path: JsonNode; query: JsonNode;
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
  var valid_613914 = path.getOrDefault("channelId")
  valid_613914 = validateParameter(valid_613914, JString, required = true,
                                 default = nil)
  if valid_613914 != nil:
    section.add "channelId", valid_613914
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
  var valid_613915 = header.getOrDefault("X-Amz-Signature")
  valid_613915 = validateParameter(valid_613915, JString, required = false,
                                 default = nil)
  if valid_613915 != nil:
    section.add "X-Amz-Signature", valid_613915
  var valid_613916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_613916 = validateParameter(valid_613916, JString, required = false,
                                 default = nil)
  if valid_613916 != nil:
    section.add "X-Amz-Content-Sha256", valid_613916
  var valid_613917 = header.getOrDefault("X-Amz-Date")
  valid_613917 = validateParameter(valid_613917, JString, required = false,
                                 default = nil)
  if valid_613917 != nil:
    section.add "X-Amz-Date", valid_613917
  var valid_613918 = header.getOrDefault("X-Amz-Credential")
  valid_613918 = validateParameter(valid_613918, JString, required = false,
                                 default = nil)
  if valid_613918 != nil:
    section.add "X-Amz-Credential", valid_613918
  var valid_613919 = header.getOrDefault("X-Amz-Security-Token")
  valid_613919 = validateParameter(valid_613919, JString, required = false,
                                 default = nil)
  if valid_613919 != nil:
    section.add "X-Amz-Security-Token", valid_613919
  var valid_613920 = header.getOrDefault("X-Amz-Algorithm")
  valid_613920 = validateParameter(valid_613920, JString, required = false,
                                 default = nil)
  if valid_613920 != nil:
    section.add "X-Amz-Algorithm", valid_613920
  var valid_613921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_613921 = validateParameter(valid_613921, JString, required = false,
                                 default = nil)
  if valid_613921 != nil:
    section.add "X-Amz-SignedHeaders", valid_613921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_613923: Call_UpdateChannelClass_613911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the class of the channel.
  ## 
  let valid = call_613923.validator(path, query, header, formData, body)
  let scheme = call_613923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_613923.url(scheme.get, call_613923.host, call_613923.base,
                         call_613923.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_613923, url, valid)

proc call*(call_613924: Call_UpdateChannelClass_613911; channelId: string;
          body: JsonNode): Recallable =
  ## updateChannelClass
  ## Changes the class of the channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_613925 = newJObject()
  var body_613926 = newJObject()
  add(path_613925, "channelId", newJString(channelId))
  if body != nil:
    body_613926 = body
  result = call_613924.call(path_613925, nil, nil, nil, body_613926)

var updateChannelClass* = Call_UpdateChannelClass_613911(
    name: "updateChannelClass", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/channelClass",
    validator: validate_UpdateChannelClass_613912, base: "/",
    url: url_UpdateChannelClass_613913, schemes: {Scheme.Https, Scheme.Http})
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
  const
    XAmzSecurityToken = "X-Amz-Security-Token"
  if not headers.hasKey(XAmzSecurityToken):
    let session = getEnv("AWS_SESSION_TOKEN", "")
    if session != "":
      headers[XAmzSecurityToken] = session
  result = newRecallable(call, url, headers, text)
  result.atozSign(input.getOrDefault("query"), SHA256)
