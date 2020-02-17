
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

  OpenApiRestCall_610658 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_610658](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_610658): Option[Scheme] {.used.} =
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
  Call_BatchUpdateSchedule_611271 = ref object of OpenApiRestCall_610658
proc url_BatchUpdateSchedule_611273(protocol: Scheme; host: string; base: string;
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

proc validate_BatchUpdateSchedule_611272(path: JsonNode; query: JsonNode;
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
  var valid_611274 = path.getOrDefault("channelId")
  valid_611274 = validateParameter(valid_611274, JString, required = true,
                                 default = nil)
  if valid_611274 != nil:
    section.add "channelId", valid_611274
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
  var valid_611275 = header.getOrDefault("X-Amz-Signature")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "X-Amz-Signature", valid_611275
  var valid_611276 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "X-Amz-Content-Sha256", valid_611276
  var valid_611277 = header.getOrDefault("X-Amz-Date")
  valid_611277 = validateParameter(valid_611277, JString, required = false,
                                 default = nil)
  if valid_611277 != nil:
    section.add "X-Amz-Date", valid_611277
  var valid_611278 = header.getOrDefault("X-Amz-Credential")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-Credential", valid_611278
  var valid_611279 = header.getOrDefault("X-Amz-Security-Token")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "X-Amz-Security-Token", valid_611279
  var valid_611280 = header.getOrDefault("X-Amz-Algorithm")
  valid_611280 = validateParameter(valid_611280, JString, required = false,
                                 default = nil)
  if valid_611280 != nil:
    section.add "X-Amz-Algorithm", valid_611280
  var valid_611281 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611281 = validateParameter(valid_611281, JString, required = false,
                                 default = nil)
  if valid_611281 != nil:
    section.add "X-Amz-SignedHeaders", valid_611281
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611283: Call_BatchUpdateSchedule_611271; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a channel schedule
  ## 
  let valid = call_611283.validator(path, query, header, formData, body)
  let scheme = call_611283.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611283.url(scheme.get, call_611283.host, call_611283.base,
                         call_611283.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611283, url, valid)

proc call*(call_611284: Call_BatchUpdateSchedule_611271; channelId: string;
          body: JsonNode): Recallable =
  ## batchUpdateSchedule
  ## Update a channel schedule
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_611285 = newJObject()
  var body_611286 = newJObject()
  add(path_611285, "channelId", newJString(channelId))
  if body != nil:
    body_611286 = body
  result = call_611284.call(path_611285, nil, nil, nil, body_611286)

var batchUpdateSchedule* = Call_BatchUpdateSchedule_611271(
    name: "batchUpdateSchedule", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com", route: "/prod/channels/{channelId}/schedule",
    validator: validate_BatchUpdateSchedule_611272, base: "/",
    url: url_BatchUpdateSchedule_611273, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeSchedule_610996 = ref object of OpenApiRestCall_610658
proc url_DescribeSchedule_610998(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeSchedule_610997(path: JsonNode; query: JsonNode;
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
  var valid_611124 = path.getOrDefault("channelId")
  valid_611124 = validateParameter(valid_611124, JString, required = true,
                                 default = nil)
  if valid_611124 != nil:
    section.add "channelId", valid_611124
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
  var valid_611125 = query.getOrDefault("nextToken")
  valid_611125 = validateParameter(valid_611125, JString, required = false,
                                 default = nil)
  if valid_611125 != nil:
    section.add "nextToken", valid_611125
  var valid_611126 = query.getOrDefault("MaxResults")
  valid_611126 = validateParameter(valid_611126, JString, required = false,
                                 default = nil)
  if valid_611126 != nil:
    section.add "MaxResults", valid_611126
  var valid_611127 = query.getOrDefault("NextToken")
  valid_611127 = validateParameter(valid_611127, JString, required = false,
                                 default = nil)
  if valid_611127 != nil:
    section.add "NextToken", valid_611127
  var valid_611128 = query.getOrDefault("maxResults")
  valid_611128 = validateParameter(valid_611128, JInt, required = false, default = nil)
  if valid_611128 != nil:
    section.add "maxResults", valid_611128
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
  var valid_611129 = header.getOrDefault("X-Amz-Signature")
  valid_611129 = validateParameter(valid_611129, JString, required = false,
                                 default = nil)
  if valid_611129 != nil:
    section.add "X-Amz-Signature", valid_611129
  var valid_611130 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611130 = validateParameter(valid_611130, JString, required = false,
                                 default = nil)
  if valid_611130 != nil:
    section.add "X-Amz-Content-Sha256", valid_611130
  var valid_611131 = header.getOrDefault("X-Amz-Date")
  valid_611131 = validateParameter(valid_611131, JString, required = false,
                                 default = nil)
  if valid_611131 != nil:
    section.add "X-Amz-Date", valid_611131
  var valid_611132 = header.getOrDefault("X-Amz-Credential")
  valid_611132 = validateParameter(valid_611132, JString, required = false,
                                 default = nil)
  if valid_611132 != nil:
    section.add "X-Amz-Credential", valid_611132
  var valid_611133 = header.getOrDefault("X-Amz-Security-Token")
  valid_611133 = validateParameter(valid_611133, JString, required = false,
                                 default = nil)
  if valid_611133 != nil:
    section.add "X-Amz-Security-Token", valid_611133
  var valid_611134 = header.getOrDefault("X-Amz-Algorithm")
  valid_611134 = validateParameter(valid_611134, JString, required = false,
                                 default = nil)
  if valid_611134 != nil:
    section.add "X-Amz-Algorithm", valid_611134
  var valid_611135 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611135 = validateParameter(valid_611135, JString, required = false,
                                 default = nil)
  if valid_611135 != nil:
    section.add "X-Amz-SignedHeaders", valid_611135
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611158: Call_DescribeSchedule_610996; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get a channel schedule
  ## 
  let valid = call_611158.validator(path, query, header, formData, body)
  let scheme = call_611158.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611158.url(scheme.get, call_611158.host, call_611158.base,
                         call_611158.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611158, url, valid)

proc call*(call_611229: Call_DescribeSchedule_610996; channelId: string;
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
  var path_611230 = newJObject()
  var query_611232 = newJObject()
  add(query_611232, "nextToken", newJString(nextToken))
  add(query_611232, "MaxResults", newJString(MaxResults))
  add(query_611232, "NextToken", newJString(NextToken))
  add(path_611230, "channelId", newJString(channelId))
  add(query_611232, "maxResults", newJInt(maxResults))
  result = call_611229.call(path_611230, query_611232, nil, nil, nil)

var describeSchedule* = Call_DescribeSchedule_610996(name: "describeSchedule",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_DescribeSchedule_610997, base: "/",
    url: url_DescribeSchedule_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteSchedule_611287 = ref object of OpenApiRestCall_610658
proc url_DeleteSchedule_611289(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteSchedule_611288(path: JsonNode; query: JsonNode;
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
  var valid_611290 = path.getOrDefault("channelId")
  valid_611290 = validateParameter(valid_611290, JString, required = true,
                                 default = nil)
  if valid_611290 != nil:
    section.add "channelId", valid_611290
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
  var valid_611291 = header.getOrDefault("X-Amz-Signature")
  valid_611291 = validateParameter(valid_611291, JString, required = false,
                                 default = nil)
  if valid_611291 != nil:
    section.add "X-Amz-Signature", valid_611291
  var valid_611292 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611292 = validateParameter(valid_611292, JString, required = false,
                                 default = nil)
  if valid_611292 != nil:
    section.add "X-Amz-Content-Sha256", valid_611292
  var valid_611293 = header.getOrDefault("X-Amz-Date")
  valid_611293 = validateParameter(valid_611293, JString, required = false,
                                 default = nil)
  if valid_611293 != nil:
    section.add "X-Amz-Date", valid_611293
  var valid_611294 = header.getOrDefault("X-Amz-Credential")
  valid_611294 = validateParameter(valid_611294, JString, required = false,
                                 default = nil)
  if valid_611294 != nil:
    section.add "X-Amz-Credential", valid_611294
  var valid_611295 = header.getOrDefault("X-Amz-Security-Token")
  valid_611295 = validateParameter(valid_611295, JString, required = false,
                                 default = nil)
  if valid_611295 != nil:
    section.add "X-Amz-Security-Token", valid_611295
  var valid_611296 = header.getOrDefault("X-Amz-Algorithm")
  valid_611296 = validateParameter(valid_611296, JString, required = false,
                                 default = nil)
  if valid_611296 != nil:
    section.add "X-Amz-Algorithm", valid_611296
  var valid_611297 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611297 = validateParameter(valid_611297, JString, required = false,
                                 default = nil)
  if valid_611297 != nil:
    section.add "X-Amz-SignedHeaders", valid_611297
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611298: Call_DeleteSchedule_611287; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete all schedule actions on a channel.
  ## 
  let valid = call_611298.validator(path, query, header, formData, body)
  let scheme = call_611298.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611298.url(scheme.get, call_611298.host, call_611298.base,
                         call_611298.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611298, url, valid)

proc call*(call_611299: Call_DeleteSchedule_611287; channelId: string): Recallable =
  ## deleteSchedule
  ## Delete all schedule actions on a channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_611300 = newJObject()
  add(path_611300, "channelId", newJString(channelId))
  result = call_611299.call(path_611300, nil, nil, nil, nil)

var deleteSchedule* = Call_DeleteSchedule_611287(name: "deleteSchedule",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/schedule",
    validator: validate_DeleteSchedule_611288, base: "/", url: url_DeleteSchedule_611289,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateChannel_611318 = ref object of OpenApiRestCall_610658
proc url_CreateChannel_611320(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateChannel_611319(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611321 = header.getOrDefault("X-Amz-Signature")
  valid_611321 = validateParameter(valid_611321, JString, required = false,
                                 default = nil)
  if valid_611321 != nil:
    section.add "X-Amz-Signature", valid_611321
  var valid_611322 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611322 = validateParameter(valid_611322, JString, required = false,
                                 default = nil)
  if valid_611322 != nil:
    section.add "X-Amz-Content-Sha256", valid_611322
  var valid_611323 = header.getOrDefault("X-Amz-Date")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "X-Amz-Date", valid_611323
  var valid_611324 = header.getOrDefault("X-Amz-Credential")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-Credential", valid_611324
  var valid_611325 = header.getOrDefault("X-Amz-Security-Token")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-Security-Token", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-Algorithm")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Algorithm", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-SignedHeaders", valid_611327
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611329: Call_CreateChannel_611318; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new channel
  ## 
  let valid = call_611329.validator(path, query, header, formData, body)
  let scheme = call_611329.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611329.url(scheme.get, call_611329.host, call_611329.base,
                         call_611329.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611329, url, valid)

proc call*(call_611330: Call_CreateChannel_611318; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a new channel
  ##   body: JObject (required)
  var body_611331 = newJObject()
  if body != nil:
    body_611331 = body
  result = call_611330.call(nil, nil, nil, nil, body_611331)

var createChannel* = Call_CreateChannel_611318(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels", validator: validate_CreateChannel_611319, base: "/",
    url: url_CreateChannel_611320, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_611301 = ref object of OpenApiRestCall_610658
proc url_ListChannels_611303(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListChannels_611302(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611304 = query.getOrDefault("nextToken")
  valid_611304 = validateParameter(valid_611304, JString, required = false,
                                 default = nil)
  if valid_611304 != nil:
    section.add "nextToken", valid_611304
  var valid_611305 = query.getOrDefault("MaxResults")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "MaxResults", valid_611305
  var valid_611306 = query.getOrDefault("NextToken")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "NextToken", valid_611306
  var valid_611307 = query.getOrDefault("maxResults")
  valid_611307 = validateParameter(valid_611307, JInt, required = false, default = nil)
  if valid_611307 != nil:
    section.add "maxResults", valid_611307
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

proc call*(call_611315: Call_ListChannels_611301; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of channels that have been created
  ## 
  let valid = call_611315.validator(path, query, header, formData, body)
  let scheme = call_611315.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611315.url(scheme.get, call_611315.host, call_611315.base,
                         call_611315.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611315, url, valid)

proc call*(call_611316: Call_ListChannels_611301; nextToken: string = "";
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
  var query_611317 = newJObject()
  add(query_611317, "nextToken", newJString(nextToken))
  add(query_611317, "MaxResults", newJString(MaxResults))
  add(query_611317, "NextToken", newJString(NextToken))
  add(query_611317, "maxResults", newJInt(maxResults))
  result = call_611316.call(nil, query_611317, nil, nil, nil)

var listChannels* = Call_ListChannels_611301(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels", validator: validate_ListChannels_611302, base: "/",
    url: url_ListChannels_611303, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInput_611349 = ref object of OpenApiRestCall_610658
proc url_CreateInput_611351(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInput_611350(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611352 = header.getOrDefault("X-Amz-Signature")
  valid_611352 = validateParameter(valid_611352, JString, required = false,
                                 default = nil)
  if valid_611352 != nil:
    section.add "X-Amz-Signature", valid_611352
  var valid_611353 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611353 = validateParameter(valid_611353, JString, required = false,
                                 default = nil)
  if valid_611353 != nil:
    section.add "X-Amz-Content-Sha256", valid_611353
  var valid_611354 = header.getOrDefault("X-Amz-Date")
  valid_611354 = validateParameter(valid_611354, JString, required = false,
                                 default = nil)
  if valid_611354 != nil:
    section.add "X-Amz-Date", valid_611354
  var valid_611355 = header.getOrDefault("X-Amz-Credential")
  valid_611355 = validateParameter(valid_611355, JString, required = false,
                                 default = nil)
  if valid_611355 != nil:
    section.add "X-Amz-Credential", valid_611355
  var valid_611356 = header.getOrDefault("X-Amz-Security-Token")
  valid_611356 = validateParameter(valid_611356, JString, required = false,
                                 default = nil)
  if valid_611356 != nil:
    section.add "X-Amz-Security-Token", valid_611356
  var valid_611357 = header.getOrDefault("X-Amz-Algorithm")
  valid_611357 = validateParameter(valid_611357, JString, required = false,
                                 default = nil)
  if valid_611357 != nil:
    section.add "X-Amz-Algorithm", valid_611357
  var valid_611358 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611358 = validateParameter(valid_611358, JString, required = false,
                                 default = nil)
  if valid_611358 != nil:
    section.add "X-Amz-SignedHeaders", valid_611358
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611360: Call_CreateInput_611349; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create an input
  ## 
  let valid = call_611360.validator(path, query, header, formData, body)
  let scheme = call_611360.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611360.url(scheme.get, call_611360.host, call_611360.base,
                         call_611360.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611360, url, valid)

proc call*(call_611361: Call_CreateInput_611349; body: JsonNode): Recallable =
  ## createInput
  ## Create an input
  ##   body: JObject (required)
  var body_611362 = newJObject()
  if body != nil:
    body_611362 = body
  result = call_611361.call(nil, nil, nil, nil, body_611362)

var createInput* = Call_CreateInput_611349(name: "createInput",
                                        meth: HttpMethod.HttpPost,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs",
                                        validator: validate_CreateInput_611350,
                                        base: "/", url: url_CreateInput_611351,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputs_611332 = ref object of OpenApiRestCall_610658
proc url_ListInputs_611334(protocol: Scheme; host: string; base: string; route: string;
                          path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInputs_611333(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611335 = query.getOrDefault("nextToken")
  valid_611335 = validateParameter(valid_611335, JString, required = false,
                                 default = nil)
  if valid_611335 != nil:
    section.add "nextToken", valid_611335
  var valid_611336 = query.getOrDefault("MaxResults")
  valid_611336 = validateParameter(valid_611336, JString, required = false,
                                 default = nil)
  if valid_611336 != nil:
    section.add "MaxResults", valid_611336
  var valid_611337 = query.getOrDefault("NextToken")
  valid_611337 = validateParameter(valid_611337, JString, required = false,
                                 default = nil)
  if valid_611337 != nil:
    section.add "NextToken", valid_611337
  var valid_611338 = query.getOrDefault("maxResults")
  valid_611338 = validateParameter(valid_611338, JInt, required = false, default = nil)
  if valid_611338 != nil:
    section.add "maxResults", valid_611338
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
  var valid_611339 = header.getOrDefault("X-Amz-Signature")
  valid_611339 = validateParameter(valid_611339, JString, required = false,
                                 default = nil)
  if valid_611339 != nil:
    section.add "X-Amz-Signature", valid_611339
  var valid_611340 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611340 = validateParameter(valid_611340, JString, required = false,
                                 default = nil)
  if valid_611340 != nil:
    section.add "X-Amz-Content-Sha256", valid_611340
  var valid_611341 = header.getOrDefault("X-Amz-Date")
  valid_611341 = validateParameter(valid_611341, JString, required = false,
                                 default = nil)
  if valid_611341 != nil:
    section.add "X-Amz-Date", valid_611341
  var valid_611342 = header.getOrDefault("X-Amz-Credential")
  valid_611342 = validateParameter(valid_611342, JString, required = false,
                                 default = nil)
  if valid_611342 != nil:
    section.add "X-Amz-Credential", valid_611342
  var valid_611343 = header.getOrDefault("X-Amz-Security-Token")
  valid_611343 = validateParameter(valid_611343, JString, required = false,
                                 default = nil)
  if valid_611343 != nil:
    section.add "X-Amz-Security-Token", valid_611343
  var valid_611344 = header.getOrDefault("X-Amz-Algorithm")
  valid_611344 = validateParameter(valid_611344, JString, required = false,
                                 default = nil)
  if valid_611344 != nil:
    section.add "X-Amz-Algorithm", valid_611344
  var valid_611345 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611345 = validateParameter(valid_611345, JString, required = false,
                                 default = nil)
  if valid_611345 != nil:
    section.add "X-Amz-SignedHeaders", valid_611345
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611346: Call_ListInputs_611332; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of inputs that have been created
  ## 
  let valid = call_611346.validator(path, query, header, formData, body)
  let scheme = call_611346.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611346.url(scheme.get, call_611346.host, call_611346.base,
                         call_611346.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611346, url, valid)

proc call*(call_611347: Call_ListInputs_611332; nextToken: string = "";
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
  var query_611348 = newJObject()
  add(query_611348, "nextToken", newJString(nextToken))
  add(query_611348, "MaxResults", newJString(MaxResults))
  add(query_611348, "NextToken", newJString(NextToken))
  add(query_611348, "maxResults", newJInt(maxResults))
  result = call_611347.call(nil, query_611348, nil, nil, nil)

var listInputs* = Call_ListInputs_611332(name: "listInputs",
                                      meth: HttpMethod.HttpGet,
                                      host: "medialive.amazonaws.com",
                                      route: "/prod/inputs",
                                      validator: validate_ListInputs_611333,
                                      base: "/", url: url_ListInputs_611334,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateInputSecurityGroup_611380 = ref object of OpenApiRestCall_610658
proc url_CreateInputSecurityGroup_611382(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateInputSecurityGroup_611381(path: JsonNode; query: JsonNode;
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
  var valid_611383 = header.getOrDefault("X-Amz-Signature")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Signature", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Content-Sha256", valid_611384
  var valid_611385 = header.getOrDefault("X-Amz-Date")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-Date", valid_611385
  var valid_611386 = header.getOrDefault("X-Amz-Credential")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-Credential", valid_611386
  var valid_611387 = header.getOrDefault("X-Amz-Security-Token")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-Security-Token", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-Algorithm")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-Algorithm", valid_611388
  var valid_611389 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611389 = validateParameter(valid_611389, JString, required = false,
                                 default = nil)
  if valid_611389 != nil:
    section.add "X-Amz-SignedHeaders", valid_611389
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611391: Call_CreateInputSecurityGroup_611380; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a Input Security Group
  ## 
  let valid = call_611391.validator(path, query, header, formData, body)
  let scheme = call_611391.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611391.url(scheme.get, call_611391.host, call_611391.base,
                         call_611391.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611391, url, valid)

proc call*(call_611392: Call_CreateInputSecurityGroup_611380; body: JsonNode): Recallable =
  ## createInputSecurityGroup
  ## Creates a Input Security Group
  ##   body: JObject (required)
  var body_611393 = newJObject()
  if body != nil:
    body_611393 = body
  result = call_611392.call(nil, nil, nil, nil, body_611393)

var createInputSecurityGroup* = Call_CreateInputSecurityGroup_611380(
    name: "createInputSecurityGroup", meth: HttpMethod.HttpPost,
    host: "medialive.amazonaws.com", route: "/prod/inputSecurityGroups",
    validator: validate_CreateInputSecurityGroup_611381, base: "/",
    url: url_CreateInputSecurityGroup_611382, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListInputSecurityGroups_611363 = ref object of OpenApiRestCall_610658
proc url_ListInputSecurityGroups_611365(protocol: Scheme; host: string; base: string;
                                       route: string; path: JsonNode;
                                       query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListInputSecurityGroups_611364(path: JsonNode; query: JsonNode;
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
  var valid_611366 = query.getOrDefault("nextToken")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "nextToken", valid_611366
  var valid_611367 = query.getOrDefault("MaxResults")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "MaxResults", valid_611367
  var valid_611368 = query.getOrDefault("NextToken")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "NextToken", valid_611368
  var valid_611369 = query.getOrDefault("maxResults")
  valid_611369 = validateParameter(valid_611369, JInt, required = false, default = nil)
  if valid_611369 != nil:
    section.add "maxResults", valid_611369
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
  var valid_611370 = header.getOrDefault("X-Amz-Signature")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Signature", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Content-Sha256", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-Date")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-Date", valid_611372
  var valid_611373 = header.getOrDefault("X-Amz-Credential")
  valid_611373 = validateParameter(valid_611373, JString, required = false,
                                 default = nil)
  if valid_611373 != nil:
    section.add "X-Amz-Credential", valid_611373
  var valid_611374 = header.getOrDefault("X-Amz-Security-Token")
  valid_611374 = validateParameter(valid_611374, JString, required = false,
                                 default = nil)
  if valid_611374 != nil:
    section.add "X-Amz-Security-Token", valid_611374
  var valid_611375 = header.getOrDefault("X-Amz-Algorithm")
  valid_611375 = validateParameter(valid_611375, JString, required = false,
                                 default = nil)
  if valid_611375 != nil:
    section.add "X-Amz-Algorithm", valid_611375
  var valid_611376 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611376 = validateParameter(valid_611376, JString, required = false,
                                 default = nil)
  if valid_611376 != nil:
    section.add "X-Amz-SignedHeaders", valid_611376
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611377: Call_ListInputSecurityGroups_611363; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces a list of Input Security Groups for an account
  ## 
  let valid = call_611377.validator(path, query, header, formData, body)
  let scheme = call_611377.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611377.url(scheme.get, call_611377.host, call_611377.base,
                         call_611377.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611377, url, valid)

proc call*(call_611378: Call_ListInputSecurityGroups_611363;
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
  var query_611379 = newJObject()
  add(query_611379, "nextToken", newJString(nextToken))
  add(query_611379, "MaxResults", newJString(MaxResults))
  add(query_611379, "NextToken", newJString(NextToken))
  add(query_611379, "maxResults", newJInt(maxResults))
  result = call_611378.call(nil, query_611379, nil, nil, nil)

var listInputSecurityGroups* = Call_ListInputSecurityGroups_611363(
    name: "listInputSecurityGroups", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/inputSecurityGroups",
    validator: validate_ListInputSecurityGroups_611364, base: "/",
    url: url_ListInputSecurityGroups_611365, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultiplex_611411 = ref object of OpenApiRestCall_610658
proc url_CreateMultiplex_611413(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateMultiplex_611412(path: JsonNode; query: JsonNode;
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
  var valid_611414 = header.getOrDefault("X-Amz-Signature")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-Signature", valid_611414
  var valid_611415 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Content-Sha256", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-Date")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-Date", valid_611416
  var valid_611417 = header.getOrDefault("X-Amz-Credential")
  valid_611417 = validateParameter(valid_611417, JString, required = false,
                                 default = nil)
  if valid_611417 != nil:
    section.add "X-Amz-Credential", valid_611417
  var valid_611418 = header.getOrDefault("X-Amz-Security-Token")
  valid_611418 = validateParameter(valid_611418, JString, required = false,
                                 default = nil)
  if valid_611418 != nil:
    section.add "X-Amz-Security-Token", valid_611418
  var valid_611419 = header.getOrDefault("X-Amz-Algorithm")
  valid_611419 = validateParameter(valid_611419, JString, required = false,
                                 default = nil)
  if valid_611419 != nil:
    section.add "X-Amz-Algorithm", valid_611419
  var valid_611420 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611420 = validateParameter(valid_611420, JString, required = false,
                                 default = nil)
  if valid_611420 != nil:
    section.add "X-Amz-SignedHeaders", valid_611420
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611422: Call_CreateMultiplex_611411; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new multiplex.
  ## 
  let valid = call_611422.validator(path, query, header, formData, body)
  let scheme = call_611422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611422.url(scheme.get, call_611422.host, call_611422.base,
                         call_611422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611422, url, valid)

proc call*(call_611423: Call_CreateMultiplex_611411; body: JsonNode): Recallable =
  ## createMultiplex
  ## Create a new multiplex.
  ##   body: JObject (required)
  var body_611424 = newJObject()
  if body != nil:
    body_611424 = body
  result = call_611423.call(nil, nil, nil, nil, body_611424)

var createMultiplex* = Call_CreateMultiplex_611411(name: "createMultiplex",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes", validator: validate_CreateMultiplex_611412,
    base: "/", url: url_CreateMultiplex_611413, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultiplexes_611394 = ref object of OpenApiRestCall_610658
proc url_ListMultiplexes_611396(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListMultiplexes_611395(path: JsonNode; query: JsonNode;
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
  var valid_611397 = query.getOrDefault("nextToken")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "nextToken", valid_611397
  var valid_611398 = query.getOrDefault("MaxResults")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "MaxResults", valid_611398
  var valid_611399 = query.getOrDefault("NextToken")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "NextToken", valid_611399
  var valid_611400 = query.getOrDefault("maxResults")
  valid_611400 = validateParameter(valid_611400, JInt, required = false, default = nil)
  if valid_611400 != nil:
    section.add "maxResults", valid_611400
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
  var valid_611401 = header.getOrDefault("X-Amz-Signature")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "X-Amz-Signature", valid_611401
  var valid_611402 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "X-Amz-Content-Sha256", valid_611402
  var valid_611403 = header.getOrDefault("X-Amz-Date")
  valid_611403 = validateParameter(valid_611403, JString, required = false,
                                 default = nil)
  if valid_611403 != nil:
    section.add "X-Amz-Date", valid_611403
  var valid_611404 = header.getOrDefault("X-Amz-Credential")
  valid_611404 = validateParameter(valid_611404, JString, required = false,
                                 default = nil)
  if valid_611404 != nil:
    section.add "X-Amz-Credential", valid_611404
  var valid_611405 = header.getOrDefault("X-Amz-Security-Token")
  valid_611405 = validateParameter(valid_611405, JString, required = false,
                                 default = nil)
  if valid_611405 != nil:
    section.add "X-Amz-Security-Token", valid_611405
  var valid_611406 = header.getOrDefault("X-Amz-Algorithm")
  valid_611406 = validateParameter(valid_611406, JString, required = false,
                                 default = nil)
  if valid_611406 != nil:
    section.add "X-Amz-Algorithm", valid_611406
  var valid_611407 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611407 = validateParameter(valid_611407, JString, required = false,
                                 default = nil)
  if valid_611407 != nil:
    section.add "X-Amz-SignedHeaders", valid_611407
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611408: Call_ListMultiplexes_611394; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Retrieve a list of the existing multiplexes.
  ## 
  let valid = call_611408.validator(path, query, header, formData, body)
  let scheme = call_611408.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611408.url(scheme.get, call_611408.host, call_611408.base,
                         call_611408.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611408, url, valid)

proc call*(call_611409: Call_ListMultiplexes_611394; nextToken: string = "";
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
  var query_611410 = newJObject()
  add(query_611410, "nextToken", newJString(nextToken))
  add(query_611410, "MaxResults", newJString(MaxResults))
  add(query_611410, "NextToken", newJString(NextToken))
  add(query_611410, "maxResults", newJInt(maxResults))
  result = call_611409.call(nil, query_611410, nil, nil, nil)

var listMultiplexes* = Call_ListMultiplexes_611394(name: "listMultiplexes",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes", validator: validate_ListMultiplexes_611395,
    base: "/", url: url_ListMultiplexes_611396, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateMultiplexProgram_611444 = ref object of OpenApiRestCall_610658
proc url_CreateMultiplexProgram_611446(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateMultiplexProgram_611445(path: JsonNode; query: JsonNode;
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
  var valid_611447 = path.getOrDefault("multiplexId")
  valid_611447 = validateParameter(valid_611447, JString, required = true,
                                 default = nil)
  if valid_611447 != nil:
    section.add "multiplexId", valid_611447
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
  var valid_611448 = header.getOrDefault("X-Amz-Signature")
  valid_611448 = validateParameter(valid_611448, JString, required = false,
                                 default = nil)
  if valid_611448 != nil:
    section.add "X-Amz-Signature", valid_611448
  var valid_611449 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611449 = validateParameter(valid_611449, JString, required = false,
                                 default = nil)
  if valid_611449 != nil:
    section.add "X-Amz-Content-Sha256", valid_611449
  var valid_611450 = header.getOrDefault("X-Amz-Date")
  valid_611450 = validateParameter(valid_611450, JString, required = false,
                                 default = nil)
  if valid_611450 != nil:
    section.add "X-Amz-Date", valid_611450
  var valid_611451 = header.getOrDefault("X-Amz-Credential")
  valid_611451 = validateParameter(valid_611451, JString, required = false,
                                 default = nil)
  if valid_611451 != nil:
    section.add "X-Amz-Credential", valid_611451
  var valid_611452 = header.getOrDefault("X-Amz-Security-Token")
  valid_611452 = validateParameter(valid_611452, JString, required = false,
                                 default = nil)
  if valid_611452 != nil:
    section.add "X-Amz-Security-Token", valid_611452
  var valid_611453 = header.getOrDefault("X-Amz-Algorithm")
  valid_611453 = validateParameter(valid_611453, JString, required = false,
                                 default = nil)
  if valid_611453 != nil:
    section.add "X-Amz-Algorithm", valid_611453
  var valid_611454 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-SignedHeaders", valid_611454
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611456: Call_CreateMultiplexProgram_611444; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create a new program in the multiplex.
  ## 
  let valid = call_611456.validator(path, query, header, formData, body)
  let scheme = call_611456.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611456.url(scheme.get, call_611456.host, call_611456.base,
                         call_611456.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611456, url, valid)

proc call*(call_611457: Call_CreateMultiplexProgram_611444; body: JsonNode;
          multiplexId: string): Recallable =
  ## createMultiplexProgram
  ## Create a new program in the multiplex.
  ##   body: JObject (required)
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_611458 = newJObject()
  var body_611459 = newJObject()
  if body != nil:
    body_611459 = body
  add(path_611458, "multiplexId", newJString(multiplexId))
  result = call_611457.call(path_611458, nil, nil, nil, body_611459)

var createMultiplexProgram* = Call_CreateMultiplexProgram_611444(
    name: "createMultiplexProgram", meth: HttpMethod.HttpPost,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs",
    validator: validate_CreateMultiplexProgram_611445, base: "/",
    url: url_CreateMultiplexProgram_611446, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListMultiplexPrograms_611425 = ref object of OpenApiRestCall_610658
proc url_ListMultiplexPrograms_611427(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListMultiplexPrograms_611426(path: JsonNode; query: JsonNode;
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
  var valid_611428 = path.getOrDefault("multiplexId")
  valid_611428 = validateParameter(valid_611428, JString, required = true,
                                 default = nil)
  if valid_611428 != nil:
    section.add "multiplexId", valid_611428
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
  var valid_611429 = query.getOrDefault("nextToken")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "nextToken", valid_611429
  var valid_611430 = query.getOrDefault("MaxResults")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "MaxResults", valid_611430
  var valid_611431 = query.getOrDefault("NextToken")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "NextToken", valid_611431
  var valid_611432 = query.getOrDefault("maxResults")
  valid_611432 = validateParameter(valid_611432, JInt, required = false, default = nil)
  if valid_611432 != nil:
    section.add "maxResults", valid_611432
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
  var valid_611433 = header.getOrDefault("X-Amz-Signature")
  valid_611433 = validateParameter(valid_611433, JString, required = false,
                                 default = nil)
  if valid_611433 != nil:
    section.add "X-Amz-Signature", valid_611433
  var valid_611434 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611434 = validateParameter(valid_611434, JString, required = false,
                                 default = nil)
  if valid_611434 != nil:
    section.add "X-Amz-Content-Sha256", valid_611434
  var valid_611435 = header.getOrDefault("X-Amz-Date")
  valid_611435 = validateParameter(valid_611435, JString, required = false,
                                 default = nil)
  if valid_611435 != nil:
    section.add "X-Amz-Date", valid_611435
  var valid_611436 = header.getOrDefault("X-Amz-Credential")
  valid_611436 = validateParameter(valid_611436, JString, required = false,
                                 default = nil)
  if valid_611436 != nil:
    section.add "X-Amz-Credential", valid_611436
  var valid_611437 = header.getOrDefault("X-Amz-Security-Token")
  valid_611437 = validateParameter(valid_611437, JString, required = false,
                                 default = nil)
  if valid_611437 != nil:
    section.add "X-Amz-Security-Token", valid_611437
  var valid_611438 = header.getOrDefault("X-Amz-Algorithm")
  valid_611438 = validateParameter(valid_611438, JString, required = false,
                                 default = nil)
  if valid_611438 != nil:
    section.add "X-Amz-Algorithm", valid_611438
  var valid_611439 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611439 = validateParameter(valid_611439, JString, required = false,
                                 default = nil)
  if valid_611439 != nil:
    section.add "X-Amz-SignedHeaders", valid_611439
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611440: Call_ListMultiplexPrograms_611425; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List the programs that currently exist for a specific multiplex.
  ## 
  let valid = call_611440.validator(path, query, header, formData, body)
  let scheme = call_611440.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611440.url(scheme.get, call_611440.host, call_611440.base,
                         call_611440.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611440, url, valid)

proc call*(call_611441: Call_ListMultiplexPrograms_611425; multiplexId: string;
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
  var path_611442 = newJObject()
  var query_611443 = newJObject()
  add(query_611443, "nextToken", newJString(nextToken))
  add(query_611443, "MaxResults", newJString(MaxResults))
  add(query_611443, "NextToken", newJString(NextToken))
  add(path_611442, "multiplexId", newJString(multiplexId))
  add(query_611443, "maxResults", newJInt(maxResults))
  result = call_611441.call(path_611442, query_611443, nil, nil, nil)

var listMultiplexPrograms* = Call_ListMultiplexPrograms_611425(
    name: "listMultiplexPrograms", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs",
    validator: validate_ListMultiplexPrograms_611426, base: "/",
    url: url_ListMultiplexPrograms_611427, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateTags_611474 = ref object of OpenApiRestCall_610658
proc url_CreateTags_611476(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_CreateTags_611475(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611477 = path.getOrDefault("resource-arn")
  valid_611477 = validateParameter(valid_611477, JString, required = true,
                                 default = nil)
  if valid_611477 != nil:
    section.add "resource-arn", valid_611477
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
  var valid_611478 = header.getOrDefault("X-Amz-Signature")
  valid_611478 = validateParameter(valid_611478, JString, required = false,
                                 default = nil)
  if valid_611478 != nil:
    section.add "X-Amz-Signature", valid_611478
  var valid_611479 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611479 = validateParameter(valid_611479, JString, required = false,
                                 default = nil)
  if valid_611479 != nil:
    section.add "X-Amz-Content-Sha256", valid_611479
  var valid_611480 = header.getOrDefault("X-Amz-Date")
  valid_611480 = validateParameter(valid_611480, JString, required = false,
                                 default = nil)
  if valid_611480 != nil:
    section.add "X-Amz-Date", valid_611480
  var valid_611481 = header.getOrDefault("X-Amz-Credential")
  valid_611481 = validateParameter(valid_611481, JString, required = false,
                                 default = nil)
  if valid_611481 != nil:
    section.add "X-Amz-Credential", valid_611481
  var valid_611482 = header.getOrDefault("X-Amz-Security-Token")
  valid_611482 = validateParameter(valid_611482, JString, required = false,
                                 default = nil)
  if valid_611482 != nil:
    section.add "X-Amz-Security-Token", valid_611482
  var valid_611483 = header.getOrDefault("X-Amz-Algorithm")
  valid_611483 = validateParameter(valid_611483, JString, required = false,
                                 default = nil)
  if valid_611483 != nil:
    section.add "X-Amz-Algorithm", valid_611483
  var valid_611484 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-SignedHeaders", valid_611484
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611486: Call_CreateTags_611474; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Create tags for a resource
  ## 
  let valid = call_611486.validator(path, query, header, formData, body)
  let scheme = call_611486.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611486.url(scheme.get, call_611486.host, call_611486.base,
                         call_611486.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611486, url, valid)

proc call*(call_611487: Call_CreateTags_611474; resourceArn: string; body: JsonNode): Recallable =
  ## createTags
  ## Create tags for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_611488 = newJObject()
  var body_611489 = newJObject()
  add(path_611488, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_611489 = body
  result = call_611487.call(path_611488, nil, nil, nil, body_611489)

var createTags* = Call_CreateTags_611474(name: "createTags",
                                      meth: HttpMethod.HttpPost,
                                      host: "medialive.amazonaws.com",
                                      route: "/prod/tags/{resource-arn}",
                                      validator: validate_CreateTags_611475,
                                      base: "/", url: url_CreateTags_611476,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_611460 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_611462(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_611461(path: JsonNode; query: JsonNode;
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
  var valid_611463 = path.getOrDefault("resource-arn")
  valid_611463 = validateParameter(valid_611463, JString, required = true,
                                 default = nil)
  if valid_611463 != nil:
    section.add "resource-arn", valid_611463
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
  var valid_611464 = header.getOrDefault("X-Amz-Signature")
  valid_611464 = validateParameter(valid_611464, JString, required = false,
                                 default = nil)
  if valid_611464 != nil:
    section.add "X-Amz-Signature", valid_611464
  var valid_611465 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611465 = validateParameter(valid_611465, JString, required = false,
                                 default = nil)
  if valid_611465 != nil:
    section.add "X-Amz-Content-Sha256", valid_611465
  var valid_611466 = header.getOrDefault("X-Amz-Date")
  valid_611466 = validateParameter(valid_611466, JString, required = false,
                                 default = nil)
  if valid_611466 != nil:
    section.add "X-Amz-Date", valid_611466
  var valid_611467 = header.getOrDefault("X-Amz-Credential")
  valid_611467 = validateParameter(valid_611467, JString, required = false,
                                 default = nil)
  if valid_611467 != nil:
    section.add "X-Amz-Credential", valid_611467
  var valid_611468 = header.getOrDefault("X-Amz-Security-Token")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Security-Token", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Algorithm")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Algorithm", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-SignedHeaders", valid_611470
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611471: Call_ListTagsForResource_611460; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces list of tags that have been created for a resource
  ## 
  let valid = call_611471.validator(path, query, header, formData, body)
  let scheme = call_611471.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611471.url(scheme.get, call_611471.host, call_611471.base,
                         call_611471.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611471, url, valid)

proc call*(call_611472: Call_ListTagsForResource_611460; resourceArn: string): Recallable =
  ## listTagsForResource
  ## Produces list of tags that have been created for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  var path_611473 = newJObject()
  add(path_611473, "resource-arn", newJString(resourceArn))
  result = call_611472.call(path_611473, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_611460(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/tags/{resource-arn}",
    validator: validate_ListTagsForResource_611461, base: "/",
    url: url_ListTagsForResource_611462, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_611504 = ref object of OpenApiRestCall_610658
proc url_UpdateChannel_611506(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateChannel_611505(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611507 = path.getOrDefault("channelId")
  valid_611507 = validateParameter(valid_611507, JString, required = true,
                                 default = nil)
  if valid_611507 != nil:
    section.add "channelId", valid_611507
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
  var valid_611508 = header.getOrDefault("X-Amz-Signature")
  valid_611508 = validateParameter(valid_611508, JString, required = false,
                                 default = nil)
  if valid_611508 != nil:
    section.add "X-Amz-Signature", valid_611508
  var valid_611509 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611509 = validateParameter(valid_611509, JString, required = false,
                                 default = nil)
  if valid_611509 != nil:
    section.add "X-Amz-Content-Sha256", valid_611509
  var valid_611510 = header.getOrDefault("X-Amz-Date")
  valid_611510 = validateParameter(valid_611510, JString, required = false,
                                 default = nil)
  if valid_611510 != nil:
    section.add "X-Amz-Date", valid_611510
  var valid_611511 = header.getOrDefault("X-Amz-Credential")
  valid_611511 = validateParameter(valid_611511, JString, required = false,
                                 default = nil)
  if valid_611511 != nil:
    section.add "X-Amz-Credential", valid_611511
  var valid_611512 = header.getOrDefault("X-Amz-Security-Token")
  valid_611512 = validateParameter(valid_611512, JString, required = false,
                                 default = nil)
  if valid_611512 != nil:
    section.add "X-Amz-Security-Token", valid_611512
  var valid_611513 = header.getOrDefault("X-Amz-Algorithm")
  valid_611513 = validateParameter(valid_611513, JString, required = false,
                                 default = nil)
  if valid_611513 != nil:
    section.add "X-Amz-Algorithm", valid_611513
  var valid_611514 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-SignedHeaders", valid_611514
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611516: Call_UpdateChannel_611504; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a channel.
  ## 
  let valid = call_611516.validator(path, query, header, formData, body)
  let scheme = call_611516.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611516.url(scheme.get, call_611516.host, call_611516.base,
                         call_611516.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611516, url, valid)

proc call*(call_611517: Call_UpdateChannel_611504; channelId: string; body: JsonNode): Recallable =
  ## updateChannel
  ## Updates a channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_611518 = newJObject()
  var body_611519 = newJObject()
  add(path_611518, "channelId", newJString(channelId))
  if body != nil:
    body_611519 = body
  result = call_611517.call(path_611518, nil, nil, nil, body_611519)

var updateChannel* = Call_UpdateChannel_611504(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_UpdateChannel_611505,
    base: "/", url: url_UpdateChannel_611506, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_611490 = ref object of OpenApiRestCall_610658
proc url_DescribeChannel_611492(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeChannel_611491(path: JsonNode; query: JsonNode;
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
  var valid_611493 = path.getOrDefault("channelId")
  valid_611493 = validateParameter(valid_611493, JString, required = true,
                                 default = nil)
  if valid_611493 != nil:
    section.add "channelId", valid_611493
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
  var valid_611494 = header.getOrDefault("X-Amz-Signature")
  valid_611494 = validateParameter(valid_611494, JString, required = false,
                                 default = nil)
  if valid_611494 != nil:
    section.add "X-Amz-Signature", valid_611494
  var valid_611495 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611495 = validateParameter(valid_611495, JString, required = false,
                                 default = nil)
  if valid_611495 != nil:
    section.add "X-Amz-Content-Sha256", valid_611495
  var valid_611496 = header.getOrDefault("X-Amz-Date")
  valid_611496 = validateParameter(valid_611496, JString, required = false,
                                 default = nil)
  if valid_611496 != nil:
    section.add "X-Amz-Date", valid_611496
  var valid_611497 = header.getOrDefault("X-Amz-Credential")
  valid_611497 = validateParameter(valid_611497, JString, required = false,
                                 default = nil)
  if valid_611497 != nil:
    section.add "X-Amz-Credential", valid_611497
  var valid_611498 = header.getOrDefault("X-Amz-Security-Token")
  valid_611498 = validateParameter(valid_611498, JString, required = false,
                                 default = nil)
  if valid_611498 != nil:
    section.add "X-Amz-Security-Token", valid_611498
  var valid_611499 = header.getOrDefault("X-Amz-Algorithm")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Algorithm", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-SignedHeaders", valid_611500
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611501: Call_DescribeChannel_611490; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a channel
  ## 
  let valid = call_611501.validator(path, query, header, formData, body)
  let scheme = call_611501.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611501.url(scheme.get, call_611501.host, call_611501.base,
                         call_611501.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611501, url, valid)

proc call*(call_611502: Call_DescribeChannel_611490; channelId: string): Recallable =
  ## describeChannel
  ## Gets details about a channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_611503 = newJObject()
  add(path_611503, "channelId", newJString(channelId))
  result = call_611502.call(path_611503, nil, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_611490(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_DescribeChannel_611491,
    base: "/", url: url_DescribeChannel_611492, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_611520 = ref object of OpenApiRestCall_610658
proc url_DeleteChannel_611522(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteChannel_611521(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611523 = path.getOrDefault("channelId")
  valid_611523 = validateParameter(valid_611523, JString, required = true,
                                 default = nil)
  if valid_611523 != nil:
    section.add "channelId", valid_611523
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
  var valid_611524 = header.getOrDefault("X-Amz-Signature")
  valid_611524 = validateParameter(valid_611524, JString, required = false,
                                 default = nil)
  if valid_611524 != nil:
    section.add "X-Amz-Signature", valid_611524
  var valid_611525 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611525 = validateParameter(valid_611525, JString, required = false,
                                 default = nil)
  if valid_611525 != nil:
    section.add "X-Amz-Content-Sha256", valid_611525
  var valid_611526 = header.getOrDefault("X-Amz-Date")
  valid_611526 = validateParameter(valid_611526, JString, required = false,
                                 default = nil)
  if valid_611526 != nil:
    section.add "X-Amz-Date", valid_611526
  var valid_611527 = header.getOrDefault("X-Amz-Credential")
  valid_611527 = validateParameter(valid_611527, JString, required = false,
                                 default = nil)
  if valid_611527 != nil:
    section.add "X-Amz-Credential", valid_611527
  var valid_611528 = header.getOrDefault("X-Amz-Security-Token")
  valid_611528 = validateParameter(valid_611528, JString, required = false,
                                 default = nil)
  if valid_611528 != nil:
    section.add "X-Amz-Security-Token", valid_611528
  var valid_611529 = header.getOrDefault("X-Amz-Algorithm")
  valid_611529 = validateParameter(valid_611529, JString, required = false,
                                 default = nil)
  if valid_611529 != nil:
    section.add "X-Amz-Algorithm", valid_611529
  var valid_611530 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611530 = validateParameter(valid_611530, JString, required = false,
                                 default = nil)
  if valid_611530 != nil:
    section.add "X-Amz-SignedHeaders", valid_611530
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611531: Call_DeleteChannel_611520; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts deletion of channel. The associated outputs are also deleted.
  ## 
  let valid = call_611531.validator(path, query, header, formData, body)
  let scheme = call_611531.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611531.url(scheme.get, call_611531.host, call_611531.base,
                         call_611531.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611531, url, valid)

proc call*(call_611532: Call_DeleteChannel_611520; channelId: string): Recallable =
  ## deleteChannel
  ## Starts deletion of channel. The associated outputs are also deleted.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_611533 = newJObject()
  add(path_611533, "channelId", newJString(channelId))
  result = call_611532.call(path_611533, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_611520(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}", validator: validate_DeleteChannel_611521,
    base: "/", url: url_DeleteChannel_611522, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInput_611548 = ref object of OpenApiRestCall_610658
proc url_UpdateInput_611550(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateInput_611549(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611551 = path.getOrDefault("inputId")
  valid_611551 = validateParameter(valid_611551, JString, required = true,
                                 default = nil)
  if valid_611551 != nil:
    section.add "inputId", valid_611551
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
  var valid_611552 = header.getOrDefault("X-Amz-Signature")
  valid_611552 = validateParameter(valid_611552, JString, required = false,
                                 default = nil)
  if valid_611552 != nil:
    section.add "X-Amz-Signature", valid_611552
  var valid_611553 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611553 = validateParameter(valid_611553, JString, required = false,
                                 default = nil)
  if valid_611553 != nil:
    section.add "X-Amz-Content-Sha256", valid_611553
  var valid_611554 = header.getOrDefault("X-Amz-Date")
  valid_611554 = validateParameter(valid_611554, JString, required = false,
                                 default = nil)
  if valid_611554 != nil:
    section.add "X-Amz-Date", valid_611554
  var valid_611555 = header.getOrDefault("X-Amz-Credential")
  valid_611555 = validateParameter(valid_611555, JString, required = false,
                                 default = nil)
  if valid_611555 != nil:
    section.add "X-Amz-Credential", valid_611555
  var valid_611556 = header.getOrDefault("X-Amz-Security-Token")
  valid_611556 = validateParameter(valid_611556, JString, required = false,
                                 default = nil)
  if valid_611556 != nil:
    section.add "X-Amz-Security-Token", valid_611556
  var valid_611557 = header.getOrDefault("X-Amz-Algorithm")
  valid_611557 = validateParameter(valid_611557, JString, required = false,
                                 default = nil)
  if valid_611557 != nil:
    section.add "X-Amz-Algorithm", valid_611557
  var valid_611558 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611558 = validateParameter(valid_611558, JString, required = false,
                                 default = nil)
  if valid_611558 != nil:
    section.add "X-Amz-SignedHeaders", valid_611558
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611560: Call_UpdateInput_611548; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an input.
  ## 
  let valid = call_611560.validator(path, query, header, formData, body)
  let scheme = call_611560.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611560.url(scheme.get, call_611560.host, call_611560.base,
                         call_611560.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611560, url, valid)

proc call*(call_611561: Call_UpdateInput_611548; body: JsonNode; inputId: string): Recallable =
  ## updateInput
  ## Updates an input.
  ##   body: JObject (required)
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_611562 = newJObject()
  var body_611563 = newJObject()
  if body != nil:
    body_611563 = body
  add(path_611562, "inputId", newJString(inputId))
  result = call_611561.call(path_611562, nil, nil, nil, body_611563)

var updateInput* = Call_UpdateInput_611548(name: "updateInput",
                                        meth: HttpMethod.HttpPut,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs/{inputId}",
                                        validator: validate_UpdateInput_611549,
                                        base: "/", url: url_UpdateInput_611550,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInput_611534 = ref object of OpenApiRestCall_610658
proc url_DescribeInput_611536(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeInput_611535(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611537 = path.getOrDefault("inputId")
  valid_611537 = validateParameter(valid_611537, JString, required = true,
                                 default = nil)
  if valid_611537 != nil:
    section.add "inputId", valid_611537
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
  var valid_611538 = header.getOrDefault("X-Amz-Signature")
  valid_611538 = validateParameter(valid_611538, JString, required = false,
                                 default = nil)
  if valid_611538 != nil:
    section.add "X-Amz-Signature", valid_611538
  var valid_611539 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611539 = validateParameter(valid_611539, JString, required = false,
                                 default = nil)
  if valid_611539 != nil:
    section.add "X-Amz-Content-Sha256", valid_611539
  var valid_611540 = header.getOrDefault("X-Amz-Date")
  valid_611540 = validateParameter(valid_611540, JString, required = false,
                                 default = nil)
  if valid_611540 != nil:
    section.add "X-Amz-Date", valid_611540
  var valid_611541 = header.getOrDefault("X-Amz-Credential")
  valid_611541 = validateParameter(valid_611541, JString, required = false,
                                 default = nil)
  if valid_611541 != nil:
    section.add "X-Amz-Credential", valid_611541
  var valid_611542 = header.getOrDefault("X-Amz-Security-Token")
  valid_611542 = validateParameter(valid_611542, JString, required = false,
                                 default = nil)
  if valid_611542 != nil:
    section.add "X-Amz-Security-Token", valid_611542
  var valid_611543 = header.getOrDefault("X-Amz-Algorithm")
  valid_611543 = validateParameter(valid_611543, JString, required = false,
                                 default = nil)
  if valid_611543 != nil:
    section.add "X-Amz-Algorithm", valid_611543
  var valid_611544 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611544 = validateParameter(valid_611544, JString, required = false,
                                 default = nil)
  if valid_611544 != nil:
    section.add "X-Amz-SignedHeaders", valid_611544
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611545: Call_DescribeInput_611534; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces details about an input
  ## 
  let valid = call_611545.validator(path, query, header, formData, body)
  let scheme = call_611545.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611545.url(scheme.get, call_611545.host, call_611545.base,
                         call_611545.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611545, url, valid)

proc call*(call_611546: Call_DescribeInput_611534; inputId: string): Recallable =
  ## describeInput
  ## Produces details about an input
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_611547 = newJObject()
  add(path_611547, "inputId", newJString(inputId))
  result = call_611546.call(path_611547, nil, nil, nil, nil)

var describeInput* = Call_DescribeInput_611534(name: "describeInput",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/inputs/{inputId}", validator: validate_DescribeInput_611535,
    base: "/", url: url_DescribeInput_611536, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInput_611564 = ref object of OpenApiRestCall_610658
proc url_DeleteInput_611566(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteInput_611565(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611567 = path.getOrDefault("inputId")
  valid_611567 = validateParameter(valid_611567, JString, required = true,
                                 default = nil)
  if valid_611567 != nil:
    section.add "inputId", valid_611567
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
  var valid_611568 = header.getOrDefault("X-Amz-Signature")
  valid_611568 = validateParameter(valid_611568, JString, required = false,
                                 default = nil)
  if valid_611568 != nil:
    section.add "X-Amz-Signature", valid_611568
  var valid_611569 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611569 = validateParameter(valid_611569, JString, required = false,
                                 default = nil)
  if valid_611569 != nil:
    section.add "X-Amz-Content-Sha256", valid_611569
  var valid_611570 = header.getOrDefault("X-Amz-Date")
  valid_611570 = validateParameter(valid_611570, JString, required = false,
                                 default = nil)
  if valid_611570 != nil:
    section.add "X-Amz-Date", valid_611570
  var valid_611571 = header.getOrDefault("X-Amz-Credential")
  valid_611571 = validateParameter(valid_611571, JString, required = false,
                                 default = nil)
  if valid_611571 != nil:
    section.add "X-Amz-Credential", valid_611571
  var valid_611572 = header.getOrDefault("X-Amz-Security-Token")
  valid_611572 = validateParameter(valid_611572, JString, required = false,
                                 default = nil)
  if valid_611572 != nil:
    section.add "X-Amz-Security-Token", valid_611572
  var valid_611573 = header.getOrDefault("X-Amz-Algorithm")
  valid_611573 = validateParameter(valid_611573, JString, required = false,
                                 default = nil)
  if valid_611573 != nil:
    section.add "X-Amz-Algorithm", valid_611573
  var valid_611574 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611574 = validateParameter(valid_611574, JString, required = false,
                                 default = nil)
  if valid_611574 != nil:
    section.add "X-Amz-SignedHeaders", valid_611574
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611575: Call_DeleteInput_611564; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes the input end point
  ## 
  let valid = call_611575.validator(path, query, header, formData, body)
  let scheme = call_611575.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611575.url(scheme.get, call_611575.host, call_611575.base,
                         call_611575.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611575, url, valid)

proc call*(call_611576: Call_DeleteInput_611564; inputId: string): Recallable =
  ## deleteInput
  ## Deletes the input end point
  ##   inputId: string (required)
  ##          : Placeholder documentation for __string
  var path_611577 = newJObject()
  add(path_611577, "inputId", newJString(inputId))
  result = call_611576.call(path_611577, nil, nil, nil, nil)

var deleteInput* = Call_DeleteInput_611564(name: "deleteInput",
                                        meth: HttpMethod.HttpDelete,
                                        host: "medialive.amazonaws.com",
                                        route: "/prod/inputs/{inputId}",
                                        validator: validate_DeleteInput_611565,
                                        base: "/", url: url_DeleteInput_611566,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateInputSecurityGroup_611592 = ref object of OpenApiRestCall_610658
proc url_UpdateInputSecurityGroup_611594(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateInputSecurityGroup_611593(path: JsonNode; query: JsonNode;
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
  var valid_611595 = path.getOrDefault("inputSecurityGroupId")
  valid_611595 = validateParameter(valid_611595, JString, required = true,
                                 default = nil)
  if valid_611595 != nil:
    section.add "inputSecurityGroupId", valid_611595
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
  var valid_611596 = header.getOrDefault("X-Amz-Signature")
  valid_611596 = validateParameter(valid_611596, JString, required = false,
                                 default = nil)
  if valid_611596 != nil:
    section.add "X-Amz-Signature", valid_611596
  var valid_611597 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611597 = validateParameter(valid_611597, JString, required = false,
                                 default = nil)
  if valid_611597 != nil:
    section.add "X-Amz-Content-Sha256", valid_611597
  var valid_611598 = header.getOrDefault("X-Amz-Date")
  valid_611598 = validateParameter(valid_611598, JString, required = false,
                                 default = nil)
  if valid_611598 != nil:
    section.add "X-Amz-Date", valid_611598
  var valid_611599 = header.getOrDefault("X-Amz-Credential")
  valid_611599 = validateParameter(valid_611599, JString, required = false,
                                 default = nil)
  if valid_611599 != nil:
    section.add "X-Amz-Credential", valid_611599
  var valid_611600 = header.getOrDefault("X-Amz-Security-Token")
  valid_611600 = validateParameter(valid_611600, JString, required = false,
                                 default = nil)
  if valid_611600 != nil:
    section.add "X-Amz-Security-Token", valid_611600
  var valid_611601 = header.getOrDefault("X-Amz-Algorithm")
  valid_611601 = validateParameter(valid_611601, JString, required = false,
                                 default = nil)
  if valid_611601 != nil:
    section.add "X-Amz-Algorithm", valid_611601
  var valid_611602 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611602 = validateParameter(valid_611602, JString, required = false,
                                 default = nil)
  if valid_611602 != nil:
    section.add "X-Amz-SignedHeaders", valid_611602
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611604: Call_UpdateInputSecurityGroup_611592; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update an Input Security Group's Whilelists.
  ## 
  let valid = call_611604.validator(path, query, header, formData, body)
  let scheme = call_611604.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611604.url(scheme.get, call_611604.host, call_611604.base,
                         call_611604.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611604, url, valid)

proc call*(call_611605: Call_UpdateInputSecurityGroup_611592;
          inputSecurityGroupId: string; body: JsonNode): Recallable =
  ## updateInputSecurityGroup
  ## Update an Input Security Group's Whilelists.
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_611606 = newJObject()
  var body_611607 = newJObject()
  add(path_611606, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  if body != nil:
    body_611607 = body
  result = call_611605.call(path_611606, nil, nil, nil, body_611607)

var updateInputSecurityGroup* = Call_UpdateInputSecurityGroup_611592(
    name: "updateInputSecurityGroup", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_UpdateInputSecurityGroup_611593, base: "/",
    url: url_UpdateInputSecurityGroup_611594, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeInputSecurityGroup_611578 = ref object of OpenApiRestCall_610658
proc url_DescribeInputSecurityGroup_611580(protocol: Scheme; host: string;
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

proc validate_DescribeInputSecurityGroup_611579(path: JsonNode; query: JsonNode;
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
  var valid_611581 = path.getOrDefault("inputSecurityGroupId")
  valid_611581 = validateParameter(valid_611581, JString, required = true,
                                 default = nil)
  if valid_611581 != nil:
    section.add "inputSecurityGroupId", valid_611581
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
  var valid_611582 = header.getOrDefault("X-Amz-Signature")
  valid_611582 = validateParameter(valid_611582, JString, required = false,
                                 default = nil)
  if valid_611582 != nil:
    section.add "X-Amz-Signature", valid_611582
  var valid_611583 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611583 = validateParameter(valid_611583, JString, required = false,
                                 default = nil)
  if valid_611583 != nil:
    section.add "X-Amz-Content-Sha256", valid_611583
  var valid_611584 = header.getOrDefault("X-Amz-Date")
  valid_611584 = validateParameter(valid_611584, JString, required = false,
                                 default = nil)
  if valid_611584 != nil:
    section.add "X-Amz-Date", valid_611584
  var valid_611585 = header.getOrDefault("X-Amz-Credential")
  valid_611585 = validateParameter(valid_611585, JString, required = false,
                                 default = nil)
  if valid_611585 != nil:
    section.add "X-Amz-Credential", valid_611585
  var valid_611586 = header.getOrDefault("X-Amz-Security-Token")
  valid_611586 = validateParameter(valid_611586, JString, required = false,
                                 default = nil)
  if valid_611586 != nil:
    section.add "X-Amz-Security-Token", valid_611586
  var valid_611587 = header.getOrDefault("X-Amz-Algorithm")
  valid_611587 = validateParameter(valid_611587, JString, required = false,
                                 default = nil)
  if valid_611587 != nil:
    section.add "X-Amz-Algorithm", valid_611587
  var valid_611588 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611588 = validateParameter(valid_611588, JString, required = false,
                                 default = nil)
  if valid_611588 != nil:
    section.add "X-Amz-SignedHeaders", valid_611588
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611589: Call_DescribeInputSecurityGroup_611578; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Produces a summary of an Input Security Group
  ## 
  let valid = call_611589.validator(path, query, header, formData, body)
  let scheme = call_611589.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611589.url(scheme.get, call_611589.host, call_611589.base,
                         call_611589.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611589, url, valid)

proc call*(call_611590: Call_DescribeInputSecurityGroup_611578;
          inputSecurityGroupId: string): Recallable =
  ## describeInputSecurityGroup
  ## Produces a summary of an Input Security Group
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  var path_611591 = newJObject()
  add(path_611591, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  result = call_611590.call(path_611591, nil, nil, nil, nil)

var describeInputSecurityGroup* = Call_DescribeInputSecurityGroup_611578(
    name: "describeInputSecurityGroup", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_DescribeInputSecurityGroup_611579, base: "/",
    url: url_DescribeInputSecurityGroup_611580,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteInputSecurityGroup_611608 = ref object of OpenApiRestCall_610658
proc url_DeleteInputSecurityGroup_611610(protocol: Scheme; host: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteInputSecurityGroup_611609(path: JsonNode; query: JsonNode;
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
  var valid_611611 = path.getOrDefault("inputSecurityGroupId")
  valid_611611 = validateParameter(valid_611611, JString, required = true,
                                 default = nil)
  if valid_611611 != nil:
    section.add "inputSecurityGroupId", valid_611611
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
  var valid_611612 = header.getOrDefault("X-Amz-Signature")
  valid_611612 = validateParameter(valid_611612, JString, required = false,
                                 default = nil)
  if valid_611612 != nil:
    section.add "X-Amz-Signature", valid_611612
  var valid_611613 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611613 = validateParameter(valid_611613, JString, required = false,
                                 default = nil)
  if valid_611613 != nil:
    section.add "X-Amz-Content-Sha256", valid_611613
  var valid_611614 = header.getOrDefault("X-Amz-Date")
  valid_611614 = validateParameter(valid_611614, JString, required = false,
                                 default = nil)
  if valid_611614 != nil:
    section.add "X-Amz-Date", valid_611614
  var valid_611615 = header.getOrDefault("X-Amz-Credential")
  valid_611615 = validateParameter(valid_611615, JString, required = false,
                                 default = nil)
  if valid_611615 != nil:
    section.add "X-Amz-Credential", valid_611615
  var valid_611616 = header.getOrDefault("X-Amz-Security-Token")
  valid_611616 = validateParameter(valid_611616, JString, required = false,
                                 default = nil)
  if valid_611616 != nil:
    section.add "X-Amz-Security-Token", valid_611616
  var valid_611617 = header.getOrDefault("X-Amz-Algorithm")
  valid_611617 = validateParameter(valid_611617, JString, required = false,
                                 default = nil)
  if valid_611617 != nil:
    section.add "X-Amz-Algorithm", valid_611617
  var valid_611618 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611618 = validateParameter(valid_611618, JString, required = false,
                                 default = nil)
  if valid_611618 != nil:
    section.add "X-Amz-SignedHeaders", valid_611618
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611619: Call_DeleteInputSecurityGroup_611608; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an Input Security Group
  ## 
  let valid = call_611619.validator(path, query, header, formData, body)
  let scheme = call_611619.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611619.url(scheme.get, call_611619.host, call_611619.base,
                         call_611619.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611619, url, valid)

proc call*(call_611620: Call_DeleteInputSecurityGroup_611608;
          inputSecurityGroupId: string): Recallable =
  ## deleteInputSecurityGroup
  ## Deletes an Input Security Group
  ##   inputSecurityGroupId: string (required)
  ##                       : Placeholder documentation for __string
  var path_611621 = newJObject()
  add(path_611621, "inputSecurityGroupId", newJString(inputSecurityGroupId))
  result = call_611620.call(path_611621, nil, nil, nil, nil)

var deleteInputSecurityGroup* = Call_DeleteInputSecurityGroup_611608(
    name: "deleteInputSecurityGroup", meth: HttpMethod.HttpDelete,
    host: "medialive.amazonaws.com",
    route: "/prod/inputSecurityGroups/{inputSecurityGroupId}",
    validator: validate_DeleteInputSecurityGroup_611609, base: "/",
    url: url_DeleteInputSecurityGroup_611610, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMultiplex_611636 = ref object of OpenApiRestCall_610658
proc url_UpdateMultiplex_611638(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateMultiplex_611637(path: JsonNode; query: JsonNode;
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
  var valid_611639 = path.getOrDefault("multiplexId")
  valid_611639 = validateParameter(valid_611639, JString, required = true,
                                 default = nil)
  if valid_611639 != nil:
    section.add "multiplexId", valid_611639
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
  var valid_611640 = header.getOrDefault("X-Amz-Signature")
  valid_611640 = validateParameter(valid_611640, JString, required = false,
                                 default = nil)
  if valid_611640 != nil:
    section.add "X-Amz-Signature", valid_611640
  var valid_611641 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611641 = validateParameter(valid_611641, JString, required = false,
                                 default = nil)
  if valid_611641 != nil:
    section.add "X-Amz-Content-Sha256", valid_611641
  var valid_611642 = header.getOrDefault("X-Amz-Date")
  valid_611642 = validateParameter(valid_611642, JString, required = false,
                                 default = nil)
  if valid_611642 != nil:
    section.add "X-Amz-Date", valid_611642
  var valid_611643 = header.getOrDefault("X-Amz-Credential")
  valid_611643 = validateParameter(valid_611643, JString, required = false,
                                 default = nil)
  if valid_611643 != nil:
    section.add "X-Amz-Credential", valid_611643
  var valid_611644 = header.getOrDefault("X-Amz-Security-Token")
  valid_611644 = validateParameter(valid_611644, JString, required = false,
                                 default = nil)
  if valid_611644 != nil:
    section.add "X-Amz-Security-Token", valid_611644
  var valid_611645 = header.getOrDefault("X-Amz-Algorithm")
  valid_611645 = validateParameter(valid_611645, JString, required = false,
                                 default = nil)
  if valid_611645 != nil:
    section.add "X-Amz-Algorithm", valid_611645
  var valid_611646 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611646 = validateParameter(valid_611646, JString, required = false,
                                 default = nil)
  if valid_611646 != nil:
    section.add "X-Amz-SignedHeaders", valid_611646
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611648: Call_UpdateMultiplex_611636; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates a multiplex.
  ## 
  let valid = call_611648.validator(path, query, header, formData, body)
  let scheme = call_611648.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611648.url(scheme.get, call_611648.host, call_611648.base,
                         call_611648.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611648, url, valid)

proc call*(call_611649: Call_UpdateMultiplex_611636; body: JsonNode;
          multiplexId: string): Recallable =
  ## updateMultiplex
  ## Updates a multiplex.
  ##   body: JObject (required)
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_611650 = newJObject()
  var body_611651 = newJObject()
  if body != nil:
    body_611651 = body
  add(path_611650, "multiplexId", newJString(multiplexId))
  result = call_611649.call(path_611650, nil, nil, nil, body_611651)

var updateMultiplex* = Call_UpdateMultiplex_611636(name: "updateMultiplex",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}", validator: validate_UpdateMultiplex_611637,
    base: "/", url: url_UpdateMultiplex_611638, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMultiplex_611622 = ref object of OpenApiRestCall_610658
proc url_DescribeMultiplex_611624(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeMultiplex_611623(path: JsonNode; query: JsonNode;
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
  var valid_611625 = path.getOrDefault("multiplexId")
  valid_611625 = validateParameter(valid_611625, JString, required = true,
                                 default = nil)
  if valid_611625 != nil:
    section.add "multiplexId", valid_611625
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
  var valid_611626 = header.getOrDefault("X-Amz-Signature")
  valid_611626 = validateParameter(valid_611626, JString, required = false,
                                 default = nil)
  if valid_611626 != nil:
    section.add "X-Amz-Signature", valid_611626
  var valid_611627 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611627 = validateParameter(valid_611627, JString, required = false,
                                 default = nil)
  if valid_611627 != nil:
    section.add "X-Amz-Content-Sha256", valid_611627
  var valid_611628 = header.getOrDefault("X-Amz-Date")
  valid_611628 = validateParameter(valid_611628, JString, required = false,
                                 default = nil)
  if valid_611628 != nil:
    section.add "X-Amz-Date", valid_611628
  var valid_611629 = header.getOrDefault("X-Amz-Credential")
  valid_611629 = validateParameter(valid_611629, JString, required = false,
                                 default = nil)
  if valid_611629 != nil:
    section.add "X-Amz-Credential", valid_611629
  var valid_611630 = header.getOrDefault("X-Amz-Security-Token")
  valid_611630 = validateParameter(valid_611630, JString, required = false,
                                 default = nil)
  if valid_611630 != nil:
    section.add "X-Amz-Security-Token", valid_611630
  var valid_611631 = header.getOrDefault("X-Amz-Algorithm")
  valid_611631 = validateParameter(valid_611631, JString, required = false,
                                 default = nil)
  if valid_611631 != nil:
    section.add "X-Amz-Algorithm", valid_611631
  var valid_611632 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611632 = validateParameter(valid_611632, JString, required = false,
                                 default = nil)
  if valid_611632 != nil:
    section.add "X-Amz-SignedHeaders", valid_611632
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611633: Call_DescribeMultiplex_611622; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a multiplex.
  ## 
  let valid = call_611633.validator(path, query, header, formData, body)
  let scheme = call_611633.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611633.url(scheme.get, call_611633.host, call_611633.base,
                         call_611633.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611633, url, valid)

proc call*(call_611634: Call_DescribeMultiplex_611622; multiplexId: string): Recallable =
  ## describeMultiplex
  ## Gets details about a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_611635 = newJObject()
  add(path_611635, "multiplexId", newJString(multiplexId))
  result = call_611634.call(path_611635, nil, nil, nil, nil)

var describeMultiplex* = Call_DescribeMultiplex_611622(name: "describeMultiplex",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}",
    validator: validate_DescribeMultiplex_611623, base: "/",
    url: url_DescribeMultiplex_611624, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMultiplex_611652 = ref object of OpenApiRestCall_610658
proc url_DeleteMultiplex_611654(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteMultiplex_611653(path: JsonNode; query: JsonNode;
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
  var valid_611655 = path.getOrDefault("multiplexId")
  valid_611655 = validateParameter(valid_611655, JString, required = true,
                                 default = nil)
  if valid_611655 != nil:
    section.add "multiplexId", valid_611655
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
  var valid_611656 = header.getOrDefault("X-Amz-Signature")
  valid_611656 = validateParameter(valid_611656, JString, required = false,
                                 default = nil)
  if valid_611656 != nil:
    section.add "X-Amz-Signature", valid_611656
  var valid_611657 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611657 = validateParameter(valid_611657, JString, required = false,
                                 default = nil)
  if valid_611657 != nil:
    section.add "X-Amz-Content-Sha256", valid_611657
  var valid_611658 = header.getOrDefault("X-Amz-Date")
  valid_611658 = validateParameter(valid_611658, JString, required = false,
                                 default = nil)
  if valid_611658 != nil:
    section.add "X-Amz-Date", valid_611658
  var valid_611659 = header.getOrDefault("X-Amz-Credential")
  valid_611659 = validateParameter(valid_611659, JString, required = false,
                                 default = nil)
  if valid_611659 != nil:
    section.add "X-Amz-Credential", valid_611659
  var valid_611660 = header.getOrDefault("X-Amz-Security-Token")
  valid_611660 = validateParameter(valid_611660, JString, required = false,
                                 default = nil)
  if valid_611660 != nil:
    section.add "X-Amz-Security-Token", valid_611660
  var valid_611661 = header.getOrDefault("X-Amz-Algorithm")
  valid_611661 = validateParameter(valid_611661, JString, required = false,
                                 default = nil)
  if valid_611661 != nil:
    section.add "X-Amz-Algorithm", valid_611661
  var valid_611662 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611662 = validateParameter(valid_611662, JString, required = false,
                                 default = nil)
  if valid_611662 != nil:
    section.add "X-Amz-SignedHeaders", valid_611662
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611663: Call_DeleteMultiplex_611652; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a multiplex. The multiplex must be idle.
  ## 
  let valid = call_611663.validator(path, query, header, formData, body)
  let scheme = call_611663.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611663.url(scheme.get, call_611663.host, call_611663.base,
                         call_611663.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611663, url, valid)

proc call*(call_611664: Call_DeleteMultiplex_611652; multiplexId: string): Recallable =
  ## deleteMultiplex
  ## Delete a multiplex. The multiplex must be idle.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_611665 = newJObject()
  add(path_611665, "multiplexId", newJString(multiplexId))
  result = call_611664.call(path_611665, nil, nil, nil, nil)

var deleteMultiplex* = Call_DeleteMultiplex_611652(name: "deleteMultiplex",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}", validator: validate_DeleteMultiplex_611653,
    base: "/", url: url_DeleteMultiplex_611654, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateMultiplexProgram_611681 = ref object of OpenApiRestCall_610658
proc url_UpdateMultiplexProgram_611683(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateMultiplexProgram_611682(path: JsonNode; query: JsonNode;
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
  var valid_611684 = path.getOrDefault("multiplexId")
  valid_611684 = validateParameter(valid_611684, JString, required = true,
                                 default = nil)
  if valid_611684 != nil:
    section.add "multiplexId", valid_611684
  var valid_611685 = path.getOrDefault("programName")
  valid_611685 = validateParameter(valid_611685, JString, required = true,
                                 default = nil)
  if valid_611685 != nil:
    section.add "programName", valid_611685
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
  var valid_611686 = header.getOrDefault("X-Amz-Signature")
  valid_611686 = validateParameter(valid_611686, JString, required = false,
                                 default = nil)
  if valid_611686 != nil:
    section.add "X-Amz-Signature", valid_611686
  var valid_611687 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611687 = validateParameter(valid_611687, JString, required = false,
                                 default = nil)
  if valid_611687 != nil:
    section.add "X-Amz-Content-Sha256", valid_611687
  var valid_611688 = header.getOrDefault("X-Amz-Date")
  valid_611688 = validateParameter(valid_611688, JString, required = false,
                                 default = nil)
  if valid_611688 != nil:
    section.add "X-Amz-Date", valid_611688
  var valid_611689 = header.getOrDefault("X-Amz-Credential")
  valid_611689 = validateParameter(valid_611689, JString, required = false,
                                 default = nil)
  if valid_611689 != nil:
    section.add "X-Amz-Credential", valid_611689
  var valid_611690 = header.getOrDefault("X-Amz-Security-Token")
  valid_611690 = validateParameter(valid_611690, JString, required = false,
                                 default = nil)
  if valid_611690 != nil:
    section.add "X-Amz-Security-Token", valid_611690
  var valid_611691 = header.getOrDefault("X-Amz-Algorithm")
  valid_611691 = validateParameter(valid_611691, JString, required = false,
                                 default = nil)
  if valid_611691 != nil:
    section.add "X-Amz-Algorithm", valid_611691
  var valid_611692 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611692 = validateParameter(valid_611692, JString, required = false,
                                 default = nil)
  if valid_611692 != nil:
    section.add "X-Amz-SignedHeaders", valid_611692
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611694: Call_UpdateMultiplexProgram_611681; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update a program in a multiplex.
  ## 
  let valid = call_611694.validator(path, query, header, formData, body)
  let scheme = call_611694.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611694.url(scheme.get, call_611694.host, call_611694.base,
                         call_611694.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611694, url, valid)

proc call*(call_611695: Call_UpdateMultiplexProgram_611681; body: JsonNode;
          multiplexId: string; programName: string): Recallable =
  ## updateMultiplexProgram
  ## Update a program in a multiplex.
  ##   body: JObject (required)
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   programName: string (required)
  ##              : Placeholder documentation for __string
  var path_611696 = newJObject()
  var body_611697 = newJObject()
  if body != nil:
    body_611697 = body
  add(path_611696, "multiplexId", newJString(multiplexId))
  add(path_611696, "programName", newJString(programName))
  result = call_611695.call(path_611696, nil, nil, nil, body_611697)

var updateMultiplexProgram* = Call_UpdateMultiplexProgram_611681(
    name: "updateMultiplexProgram", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs/{programName}",
    validator: validate_UpdateMultiplexProgram_611682, base: "/",
    url: url_UpdateMultiplexProgram_611683, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeMultiplexProgram_611666 = ref object of OpenApiRestCall_610658
proc url_DescribeMultiplexProgram_611668(protocol: Scheme; host: string;
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

proc validate_DescribeMultiplexProgram_611667(path: JsonNode; query: JsonNode;
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
  var valid_611669 = path.getOrDefault("multiplexId")
  valid_611669 = validateParameter(valid_611669, JString, required = true,
                                 default = nil)
  if valid_611669 != nil:
    section.add "multiplexId", valid_611669
  var valid_611670 = path.getOrDefault("programName")
  valid_611670 = validateParameter(valid_611670, JString, required = true,
                                 default = nil)
  if valid_611670 != nil:
    section.add "programName", valid_611670
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
  var valid_611671 = header.getOrDefault("X-Amz-Signature")
  valid_611671 = validateParameter(valid_611671, JString, required = false,
                                 default = nil)
  if valid_611671 != nil:
    section.add "X-Amz-Signature", valid_611671
  var valid_611672 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611672 = validateParameter(valid_611672, JString, required = false,
                                 default = nil)
  if valid_611672 != nil:
    section.add "X-Amz-Content-Sha256", valid_611672
  var valid_611673 = header.getOrDefault("X-Amz-Date")
  valid_611673 = validateParameter(valid_611673, JString, required = false,
                                 default = nil)
  if valid_611673 != nil:
    section.add "X-Amz-Date", valid_611673
  var valid_611674 = header.getOrDefault("X-Amz-Credential")
  valid_611674 = validateParameter(valid_611674, JString, required = false,
                                 default = nil)
  if valid_611674 != nil:
    section.add "X-Amz-Credential", valid_611674
  var valid_611675 = header.getOrDefault("X-Amz-Security-Token")
  valid_611675 = validateParameter(valid_611675, JString, required = false,
                                 default = nil)
  if valid_611675 != nil:
    section.add "X-Amz-Security-Token", valid_611675
  var valid_611676 = header.getOrDefault("X-Amz-Algorithm")
  valid_611676 = validateParameter(valid_611676, JString, required = false,
                                 default = nil)
  if valid_611676 != nil:
    section.add "X-Amz-Algorithm", valid_611676
  var valid_611677 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611677 = validateParameter(valid_611677, JString, required = false,
                                 default = nil)
  if valid_611677 != nil:
    section.add "X-Amz-SignedHeaders", valid_611677
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611678: Call_DescribeMultiplexProgram_611666; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get the details for a program in a multiplex.
  ## 
  let valid = call_611678.validator(path, query, header, formData, body)
  let scheme = call_611678.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611678.url(scheme.get, call_611678.host, call_611678.base,
                         call_611678.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611678, url, valid)

proc call*(call_611679: Call_DescribeMultiplexProgram_611666; multiplexId: string;
          programName: string): Recallable =
  ## describeMultiplexProgram
  ## Get the details for a program in a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   programName: string (required)
  ##              : Placeholder documentation for __string
  var path_611680 = newJObject()
  add(path_611680, "multiplexId", newJString(multiplexId))
  add(path_611680, "programName", newJString(programName))
  result = call_611679.call(path_611680, nil, nil, nil, nil)

var describeMultiplexProgram* = Call_DescribeMultiplexProgram_611666(
    name: "describeMultiplexProgram", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs/{programName}",
    validator: validate_DescribeMultiplexProgram_611667, base: "/",
    url: url_DescribeMultiplexProgram_611668, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteMultiplexProgram_611698 = ref object of OpenApiRestCall_610658
proc url_DeleteMultiplexProgram_611700(protocol: Scheme; host: string; base: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteMultiplexProgram_611699(path: JsonNode; query: JsonNode;
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
  var valid_611701 = path.getOrDefault("multiplexId")
  valid_611701 = validateParameter(valid_611701, JString, required = true,
                                 default = nil)
  if valid_611701 != nil:
    section.add "multiplexId", valid_611701
  var valid_611702 = path.getOrDefault("programName")
  valid_611702 = validateParameter(valid_611702, JString, required = true,
                                 default = nil)
  if valid_611702 != nil:
    section.add "programName", valid_611702
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
  var valid_611703 = header.getOrDefault("X-Amz-Signature")
  valid_611703 = validateParameter(valid_611703, JString, required = false,
                                 default = nil)
  if valid_611703 != nil:
    section.add "X-Amz-Signature", valid_611703
  var valid_611704 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611704 = validateParameter(valid_611704, JString, required = false,
                                 default = nil)
  if valid_611704 != nil:
    section.add "X-Amz-Content-Sha256", valid_611704
  var valid_611705 = header.getOrDefault("X-Amz-Date")
  valid_611705 = validateParameter(valid_611705, JString, required = false,
                                 default = nil)
  if valid_611705 != nil:
    section.add "X-Amz-Date", valid_611705
  var valid_611706 = header.getOrDefault("X-Amz-Credential")
  valid_611706 = validateParameter(valid_611706, JString, required = false,
                                 default = nil)
  if valid_611706 != nil:
    section.add "X-Amz-Credential", valid_611706
  var valid_611707 = header.getOrDefault("X-Amz-Security-Token")
  valid_611707 = validateParameter(valid_611707, JString, required = false,
                                 default = nil)
  if valid_611707 != nil:
    section.add "X-Amz-Security-Token", valid_611707
  var valid_611708 = header.getOrDefault("X-Amz-Algorithm")
  valid_611708 = validateParameter(valid_611708, JString, required = false,
                                 default = nil)
  if valid_611708 != nil:
    section.add "X-Amz-Algorithm", valid_611708
  var valid_611709 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611709 = validateParameter(valid_611709, JString, required = false,
                                 default = nil)
  if valid_611709 != nil:
    section.add "X-Amz-SignedHeaders", valid_611709
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611710: Call_DeleteMultiplexProgram_611698; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete a program from a multiplex.
  ## 
  let valid = call_611710.validator(path, query, header, formData, body)
  let scheme = call_611710.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611710.url(scheme.get, call_611710.host, call_611710.base,
                         call_611710.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611710, url, valid)

proc call*(call_611711: Call_DeleteMultiplexProgram_611698; multiplexId: string;
          programName: string): Recallable =
  ## deleteMultiplexProgram
  ## Delete a program from a multiplex.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  ##   programName: string (required)
  ##              : Placeholder documentation for __string
  var path_611712 = newJObject()
  add(path_611712, "multiplexId", newJString(multiplexId))
  add(path_611712, "programName", newJString(programName))
  result = call_611711.call(path_611712, nil, nil, nil, nil)

var deleteMultiplexProgram* = Call_DeleteMultiplexProgram_611698(
    name: "deleteMultiplexProgram", meth: HttpMethod.HttpDelete,
    host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/programs/{programName}",
    validator: validate_DeleteMultiplexProgram_611699, base: "/",
    url: url_DeleteMultiplexProgram_611700, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateReservation_611727 = ref object of OpenApiRestCall_610658
proc url_UpdateReservation_611729(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateReservation_611728(path: JsonNode; query: JsonNode;
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
  var valid_611730 = path.getOrDefault("reservationId")
  valid_611730 = validateParameter(valid_611730, JString, required = true,
                                 default = nil)
  if valid_611730 != nil:
    section.add "reservationId", valid_611730
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
  var valid_611731 = header.getOrDefault("X-Amz-Signature")
  valid_611731 = validateParameter(valid_611731, JString, required = false,
                                 default = nil)
  if valid_611731 != nil:
    section.add "X-Amz-Signature", valid_611731
  var valid_611732 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611732 = validateParameter(valid_611732, JString, required = false,
                                 default = nil)
  if valid_611732 != nil:
    section.add "X-Amz-Content-Sha256", valid_611732
  var valid_611733 = header.getOrDefault("X-Amz-Date")
  valid_611733 = validateParameter(valid_611733, JString, required = false,
                                 default = nil)
  if valid_611733 != nil:
    section.add "X-Amz-Date", valid_611733
  var valid_611734 = header.getOrDefault("X-Amz-Credential")
  valid_611734 = validateParameter(valid_611734, JString, required = false,
                                 default = nil)
  if valid_611734 != nil:
    section.add "X-Amz-Credential", valid_611734
  var valid_611735 = header.getOrDefault("X-Amz-Security-Token")
  valid_611735 = validateParameter(valid_611735, JString, required = false,
                                 default = nil)
  if valid_611735 != nil:
    section.add "X-Amz-Security-Token", valid_611735
  var valid_611736 = header.getOrDefault("X-Amz-Algorithm")
  valid_611736 = validateParameter(valid_611736, JString, required = false,
                                 default = nil)
  if valid_611736 != nil:
    section.add "X-Amz-Algorithm", valid_611736
  var valid_611737 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611737 = validateParameter(valid_611737, JString, required = false,
                                 default = nil)
  if valid_611737 != nil:
    section.add "X-Amz-SignedHeaders", valid_611737
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611739: Call_UpdateReservation_611727; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Update reservation.
  ## 
  let valid = call_611739.validator(path, query, header, formData, body)
  let scheme = call_611739.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611739.url(scheme.get, call_611739.host, call_611739.base,
                         call_611739.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611739, url, valid)

proc call*(call_611740: Call_UpdateReservation_611727; body: JsonNode;
          reservationId: string): Recallable =
  ## updateReservation
  ## Update reservation.
  ##   body: JObject (required)
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_611741 = newJObject()
  var body_611742 = newJObject()
  if body != nil:
    body_611742 = body
  add(path_611741, "reservationId", newJString(reservationId))
  result = call_611740.call(path_611741, nil, nil, nil, body_611742)

var updateReservation* = Call_UpdateReservation_611727(name: "updateReservation",
    meth: HttpMethod.HttpPut, host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_UpdateReservation_611728, base: "/",
    url: url_UpdateReservation_611729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeReservation_611713 = ref object of OpenApiRestCall_610658
proc url_DescribeReservation_611715(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeReservation_611714(path: JsonNode; query: JsonNode;
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
  var valid_611716 = path.getOrDefault("reservationId")
  valid_611716 = validateParameter(valid_611716, JString, required = true,
                                 default = nil)
  if valid_611716 != nil:
    section.add "reservationId", valid_611716
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
  var valid_611717 = header.getOrDefault("X-Amz-Signature")
  valid_611717 = validateParameter(valid_611717, JString, required = false,
                                 default = nil)
  if valid_611717 != nil:
    section.add "X-Amz-Signature", valid_611717
  var valid_611718 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611718 = validateParameter(valid_611718, JString, required = false,
                                 default = nil)
  if valid_611718 != nil:
    section.add "X-Amz-Content-Sha256", valid_611718
  var valid_611719 = header.getOrDefault("X-Amz-Date")
  valid_611719 = validateParameter(valid_611719, JString, required = false,
                                 default = nil)
  if valid_611719 != nil:
    section.add "X-Amz-Date", valid_611719
  var valid_611720 = header.getOrDefault("X-Amz-Credential")
  valid_611720 = validateParameter(valid_611720, JString, required = false,
                                 default = nil)
  if valid_611720 != nil:
    section.add "X-Amz-Credential", valid_611720
  var valid_611721 = header.getOrDefault("X-Amz-Security-Token")
  valid_611721 = validateParameter(valid_611721, JString, required = false,
                                 default = nil)
  if valid_611721 != nil:
    section.add "X-Amz-Security-Token", valid_611721
  var valid_611722 = header.getOrDefault("X-Amz-Algorithm")
  valid_611722 = validateParameter(valid_611722, JString, required = false,
                                 default = nil)
  if valid_611722 != nil:
    section.add "X-Amz-Algorithm", valid_611722
  var valid_611723 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611723 = validateParameter(valid_611723, JString, required = false,
                                 default = nil)
  if valid_611723 != nil:
    section.add "X-Amz-SignedHeaders", valid_611723
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611724: Call_DescribeReservation_611713; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details for a reservation.
  ## 
  let valid = call_611724.validator(path, query, header, formData, body)
  let scheme = call_611724.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611724.url(scheme.get, call_611724.host, call_611724.base,
                         call_611724.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611724, url, valid)

proc call*(call_611725: Call_DescribeReservation_611713; reservationId: string): Recallable =
  ## describeReservation
  ## Get details for a reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_611726 = newJObject()
  add(path_611726, "reservationId", newJString(reservationId))
  result = call_611725.call(path_611726, nil, nil, nil, nil)

var describeReservation* = Call_DescribeReservation_611713(
    name: "describeReservation", meth: HttpMethod.HttpGet,
    host: "medialive.amazonaws.com", route: "/prod/reservations/{reservationId}",
    validator: validate_DescribeReservation_611714, base: "/",
    url: url_DescribeReservation_611715, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteReservation_611743 = ref object of OpenApiRestCall_610658
proc url_DeleteReservation_611745(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteReservation_611744(path: JsonNode; query: JsonNode;
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
  var valid_611746 = path.getOrDefault("reservationId")
  valid_611746 = validateParameter(valid_611746, JString, required = true,
                                 default = nil)
  if valid_611746 != nil:
    section.add "reservationId", valid_611746
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
  var valid_611747 = header.getOrDefault("X-Amz-Signature")
  valid_611747 = validateParameter(valid_611747, JString, required = false,
                                 default = nil)
  if valid_611747 != nil:
    section.add "X-Amz-Signature", valid_611747
  var valid_611748 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611748 = validateParameter(valid_611748, JString, required = false,
                                 default = nil)
  if valid_611748 != nil:
    section.add "X-Amz-Content-Sha256", valid_611748
  var valid_611749 = header.getOrDefault("X-Amz-Date")
  valid_611749 = validateParameter(valid_611749, JString, required = false,
                                 default = nil)
  if valid_611749 != nil:
    section.add "X-Amz-Date", valid_611749
  var valid_611750 = header.getOrDefault("X-Amz-Credential")
  valid_611750 = validateParameter(valid_611750, JString, required = false,
                                 default = nil)
  if valid_611750 != nil:
    section.add "X-Amz-Credential", valid_611750
  var valid_611751 = header.getOrDefault("X-Amz-Security-Token")
  valid_611751 = validateParameter(valid_611751, JString, required = false,
                                 default = nil)
  if valid_611751 != nil:
    section.add "X-Amz-Security-Token", valid_611751
  var valid_611752 = header.getOrDefault("X-Amz-Algorithm")
  valid_611752 = validateParameter(valid_611752, JString, required = false,
                                 default = nil)
  if valid_611752 != nil:
    section.add "X-Amz-Algorithm", valid_611752
  var valid_611753 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611753 = validateParameter(valid_611753, JString, required = false,
                                 default = nil)
  if valid_611753 != nil:
    section.add "X-Amz-SignedHeaders", valid_611753
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611754: Call_DeleteReservation_611743; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Delete an expired reservation.
  ## 
  let valid = call_611754.validator(path, query, header, formData, body)
  let scheme = call_611754.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611754.url(scheme.get, call_611754.host, call_611754.base,
                         call_611754.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611754, url, valid)

proc call*(call_611755: Call_DeleteReservation_611743; reservationId: string): Recallable =
  ## deleteReservation
  ## Delete an expired reservation.
  ##   reservationId: string (required)
  ##                : Placeholder documentation for __string
  var path_611756 = newJObject()
  add(path_611756, "reservationId", newJString(reservationId))
  result = call_611755.call(path_611756, nil, nil, nil, nil)

var deleteReservation* = Call_DeleteReservation_611743(name: "deleteReservation",
    meth: HttpMethod.HttpDelete, host: "medialive.amazonaws.com",
    route: "/prod/reservations/{reservationId}",
    validator: validate_DeleteReservation_611744, base: "/",
    url: url_DeleteReservation_611745, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteTags_611757 = ref object of OpenApiRestCall_610658
proc url_DeleteTags_611759(protocol: Scheme; host: string; base: string; route: string;
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
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteTags_611758(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611760 = path.getOrDefault("resource-arn")
  valid_611760 = validateParameter(valid_611760, JString, required = true,
                                 default = nil)
  if valid_611760 != nil:
    section.add "resource-arn", valid_611760
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : Placeholder documentation for __listOf__string
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_611761 = query.getOrDefault("tagKeys")
  valid_611761 = validateParameter(valid_611761, JArray, required = true, default = nil)
  if valid_611761 != nil:
    section.add "tagKeys", valid_611761
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
  var valid_611762 = header.getOrDefault("X-Amz-Signature")
  valid_611762 = validateParameter(valid_611762, JString, required = false,
                                 default = nil)
  if valid_611762 != nil:
    section.add "X-Amz-Signature", valid_611762
  var valid_611763 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611763 = validateParameter(valid_611763, JString, required = false,
                                 default = nil)
  if valid_611763 != nil:
    section.add "X-Amz-Content-Sha256", valid_611763
  var valid_611764 = header.getOrDefault("X-Amz-Date")
  valid_611764 = validateParameter(valid_611764, JString, required = false,
                                 default = nil)
  if valid_611764 != nil:
    section.add "X-Amz-Date", valid_611764
  var valid_611765 = header.getOrDefault("X-Amz-Credential")
  valid_611765 = validateParameter(valid_611765, JString, required = false,
                                 default = nil)
  if valid_611765 != nil:
    section.add "X-Amz-Credential", valid_611765
  var valid_611766 = header.getOrDefault("X-Amz-Security-Token")
  valid_611766 = validateParameter(valid_611766, JString, required = false,
                                 default = nil)
  if valid_611766 != nil:
    section.add "X-Amz-Security-Token", valid_611766
  var valid_611767 = header.getOrDefault("X-Amz-Algorithm")
  valid_611767 = validateParameter(valid_611767, JString, required = false,
                                 default = nil)
  if valid_611767 != nil:
    section.add "X-Amz-Algorithm", valid_611767
  var valid_611768 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611768 = validateParameter(valid_611768, JString, required = false,
                                 default = nil)
  if valid_611768 != nil:
    section.add "X-Amz-SignedHeaders", valid_611768
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611769: Call_DeleteTags_611757; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Removes tags for a resource
  ## 
  let valid = call_611769.validator(path, query, header, formData, body)
  let scheme = call_611769.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611769.url(scheme.get, call_611769.host, call_611769.base,
                         call_611769.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611769, url, valid)

proc call*(call_611770: Call_DeleteTags_611757; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## deleteTags
  ## Removes tags for a resource
  ##   resourceArn: string (required)
  ##              : Placeholder documentation for __string
  ##   tagKeys: JArray (required)
  ##          : Placeholder documentation for __listOf__string
  var path_611771 = newJObject()
  var query_611772 = newJObject()
  add(path_611771, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_611772.add "tagKeys", tagKeys
  result = call_611770.call(path_611771, query_611772, nil, nil, nil)

var deleteTags* = Call_DeleteTags_611757(name: "deleteTags",
                                      meth: HttpMethod.HttpDelete,
                                      host: "medialive.amazonaws.com", route: "/prod/tags/{resource-arn}#tagKeys",
                                      validator: validate_DeleteTags_611758,
                                      base: "/", url: url_DeleteTags_611759,
                                      schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOffering_611773 = ref object of OpenApiRestCall_610658
proc url_DescribeOffering_611775(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeOffering_611774(path: JsonNode; query: JsonNode;
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
  var valid_611776 = path.getOrDefault("offeringId")
  valid_611776 = validateParameter(valid_611776, JString, required = true,
                                 default = nil)
  if valid_611776 != nil:
    section.add "offeringId", valid_611776
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
  var valid_611777 = header.getOrDefault("X-Amz-Signature")
  valid_611777 = validateParameter(valid_611777, JString, required = false,
                                 default = nil)
  if valid_611777 != nil:
    section.add "X-Amz-Signature", valid_611777
  var valid_611778 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611778 = validateParameter(valid_611778, JString, required = false,
                                 default = nil)
  if valid_611778 != nil:
    section.add "X-Amz-Content-Sha256", valid_611778
  var valid_611779 = header.getOrDefault("X-Amz-Date")
  valid_611779 = validateParameter(valid_611779, JString, required = false,
                                 default = nil)
  if valid_611779 != nil:
    section.add "X-Amz-Date", valid_611779
  var valid_611780 = header.getOrDefault("X-Amz-Credential")
  valid_611780 = validateParameter(valid_611780, JString, required = false,
                                 default = nil)
  if valid_611780 != nil:
    section.add "X-Amz-Credential", valid_611780
  var valid_611781 = header.getOrDefault("X-Amz-Security-Token")
  valid_611781 = validateParameter(valid_611781, JString, required = false,
                                 default = nil)
  if valid_611781 != nil:
    section.add "X-Amz-Security-Token", valid_611781
  var valid_611782 = header.getOrDefault("X-Amz-Algorithm")
  valid_611782 = validateParameter(valid_611782, JString, required = false,
                                 default = nil)
  if valid_611782 != nil:
    section.add "X-Amz-Algorithm", valid_611782
  var valid_611783 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611783 = validateParameter(valid_611783, JString, required = false,
                                 default = nil)
  if valid_611783 != nil:
    section.add "X-Amz-SignedHeaders", valid_611783
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611784: Call_DescribeOffering_611773; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Get details for an offering.
  ## 
  let valid = call_611784.validator(path, query, header, formData, body)
  let scheme = call_611784.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611784.url(scheme.get, call_611784.host, call_611784.base,
                         call_611784.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611784, url, valid)

proc call*(call_611785: Call_DescribeOffering_611773; offeringId: string): Recallable =
  ## describeOffering
  ## Get details for an offering.
  ##   offeringId: string (required)
  ##             : Placeholder documentation for __string
  var path_611786 = newJObject()
  add(path_611786, "offeringId", newJString(offeringId))
  result = call_611785.call(path_611786, nil, nil, nil, nil)

var describeOffering* = Call_DescribeOffering_611773(name: "describeOffering",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/offerings/{offeringId}", validator: validate_DescribeOffering_611774,
    base: "/", url: url_DescribeOffering_611775,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOfferings_611787 = ref object of OpenApiRestCall_610658
proc url_ListOfferings_611789(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOfferings_611788(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611790 = query.getOrDefault("specialFeature")
  valid_611790 = validateParameter(valid_611790, JString, required = false,
                                 default = nil)
  if valid_611790 != nil:
    section.add "specialFeature", valid_611790
  var valid_611791 = query.getOrDefault("nextToken")
  valid_611791 = validateParameter(valid_611791, JString, required = false,
                                 default = nil)
  if valid_611791 != nil:
    section.add "nextToken", valid_611791
  var valid_611792 = query.getOrDefault("MaxResults")
  valid_611792 = validateParameter(valid_611792, JString, required = false,
                                 default = nil)
  if valid_611792 != nil:
    section.add "MaxResults", valid_611792
  var valid_611793 = query.getOrDefault("channelClass")
  valid_611793 = validateParameter(valid_611793, JString, required = false,
                                 default = nil)
  if valid_611793 != nil:
    section.add "channelClass", valid_611793
  var valid_611794 = query.getOrDefault("NextToken")
  valid_611794 = validateParameter(valid_611794, JString, required = false,
                                 default = nil)
  if valid_611794 != nil:
    section.add "NextToken", valid_611794
  var valid_611795 = query.getOrDefault("videoQuality")
  valid_611795 = validateParameter(valid_611795, JString, required = false,
                                 default = nil)
  if valid_611795 != nil:
    section.add "videoQuality", valid_611795
  var valid_611796 = query.getOrDefault("maximumFramerate")
  valid_611796 = validateParameter(valid_611796, JString, required = false,
                                 default = nil)
  if valid_611796 != nil:
    section.add "maximumFramerate", valid_611796
  var valid_611797 = query.getOrDefault("maximumBitrate")
  valid_611797 = validateParameter(valid_611797, JString, required = false,
                                 default = nil)
  if valid_611797 != nil:
    section.add "maximumBitrate", valid_611797
  var valid_611798 = query.getOrDefault("resourceType")
  valid_611798 = validateParameter(valid_611798, JString, required = false,
                                 default = nil)
  if valid_611798 != nil:
    section.add "resourceType", valid_611798
  var valid_611799 = query.getOrDefault("duration")
  valid_611799 = validateParameter(valid_611799, JString, required = false,
                                 default = nil)
  if valid_611799 != nil:
    section.add "duration", valid_611799
  var valid_611800 = query.getOrDefault("channelConfiguration")
  valid_611800 = validateParameter(valid_611800, JString, required = false,
                                 default = nil)
  if valid_611800 != nil:
    section.add "channelConfiguration", valid_611800
  var valid_611801 = query.getOrDefault("codec")
  valid_611801 = validateParameter(valid_611801, JString, required = false,
                                 default = nil)
  if valid_611801 != nil:
    section.add "codec", valid_611801
  var valid_611802 = query.getOrDefault("resolution")
  valid_611802 = validateParameter(valid_611802, JString, required = false,
                                 default = nil)
  if valid_611802 != nil:
    section.add "resolution", valid_611802
  var valid_611803 = query.getOrDefault("maxResults")
  valid_611803 = validateParameter(valid_611803, JInt, required = false, default = nil)
  if valid_611803 != nil:
    section.add "maxResults", valid_611803
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
  var valid_611804 = header.getOrDefault("X-Amz-Signature")
  valid_611804 = validateParameter(valid_611804, JString, required = false,
                                 default = nil)
  if valid_611804 != nil:
    section.add "X-Amz-Signature", valid_611804
  var valid_611805 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611805 = validateParameter(valid_611805, JString, required = false,
                                 default = nil)
  if valid_611805 != nil:
    section.add "X-Amz-Content-Sha256", valid_611805
  var valid_611806 = header.getOrDefault("X-Amz-Date")
  valid_611806 = validateParameter(valid_611806, JString, required = false,
                                 default = nil)
  if valid_611806 != nil:
    section.add "X-Amz-Date", valid_611806
  var valid_611807 = header.getOrDefault("X-Amz-Credential")
  valid_611807 = validateParameter(valid_611807, JString, required = false,
                                 default = nil)
  if valid_611807 != nil:
    section.add "X-Amz-Credential", valid_611807
  var valid_611808 = header.getOrDefault("X-Amz-Security-Token")
  valid_611808 = validateParameter(valid_611808, JString, required = false,
                                 default = nil)
  if valid_611808 != nil:
    section.add "X-Amz-Security-Token", valid_611808
  var valid_611809 = header.getOrDefault("X-Amz-Algorithm")
  valid_611809 = validateParameter(valid_611809, JString, required = false,
                                 default = nil)
  if valid_611809 != nil:
    section.add "X-Amz-Algorithm", valid_611809
  var valid_611810 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611810 = validateParameter(valid_611810, JString, required = false,
                                 default = nil)
  if valid_611810 != nil:
    section.add "X-Amz-SignedHeaders", valid_611810
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611811: Call_ListOfferings_611787; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List offerings available for purchase.
  ## 
  let valid = call_611811.validator(path, query, header, formData, body)
  let scheme = call_611811.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611811.url(scheme.get, call_611811.host, call_611811.base,
                         call_611811.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611811, url, valid)

proc call*(call_611812: Call_ListOfferings_611787; specialFeature: string = "";
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
  var query_611813 = newJObject()
  add(query_611813, "specialFeature", newJString(specialFeature))
  add(query_611813, "nextToken", newJString(nextToken))
  add(query_611813, "MaxResults", newJString(MaxResults))
  add(query_611813, "channelClass", newJString(channelClass))
  add(query_611813, "NextToken", newJString(NextToken))
  add(query_611813, "videoQuality", newJString(videoQuality))
  add(query_611813, "maximumFramerate", newJString(maximumFramerate))
  add(query_611813, "maximumBitrate", newJString(maximumBitrate))
  add(query_611813, "resourceType", newJString(resourceType))
  add(query_611813, "duration", newJString(duration))
  add(query_611813, "channelConfiguration", newJString(channelConfiguration))
  add(query_611813, "codec", newJString(codec))
  add(query_611813, "resolution", newJString(resolution))
  add(query_611813, "maxResults", newJInt(maxResults))
  result = call_611812.call(nil, query_611813, nil, nil, nil)

var listOfferings* = Call_ListOfferings_611787(name: "listOfferings",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/offerings", validator: validate_ListOfferings_611788, base: "/",
    url: url_ListOfferings_611789, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListReservations_611814 = ref object of OpenApiRestCall_610658
proc url_ListReservations_611816(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListReservations_611815(path: JsonNode; query: JsonNode;
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
  var valid_611817 = query.getOrDefault("specialFeature")
  valid_611817 = validateParameter(valid_611817, JString, required = false,
                                 default = nil)
  if valid_611817 != nil:
    section.add "specialFeature", valid_611817
  var valid_611818 = query.getOrDefault("nextToken")
  valid_611818 = validateParameter(valid_611818, JString, required = false,
                                 default = nil)
  if valid_611818 != nil:
    section.add "nextToken", valid_611818
  var valid_611819 = query.getOrDefault("MaxResults")
  valid_611819 = validateParameter(valid_611819, JString, required = false,
                                 default = nil)
  if valid_611819 != nil:
    section.add "MaxResults", valid_611819
  var valid_611820 = query.getOrDefault("channelClass")
  valid_611820 = validateParameter(valid_611820, JString, required = false,
                                 default = nil)
  if valid_611820 != nil:
    section.add "channelClass", valid_611820
  var valid_611821 = query.getOrDefault("NextToken")
  valid_611821 = validateParameter(valid_611821, JString, required = false,
                                 default = nil)
  if valid_611821 != nil:
    section.add "NextToken", valid_611821
  var valid_611822 = query.getOrDefault("videoQuality")
  valid_611822 = validateParameter(valid_611822, JString, required = false,
                                 default = nil)
  if valid_611822 != nil:
    section.add "videoQuality", valid_611822
  var valid_611823 = query.getOrDefault("maximumFramerate")
  valid_611823 = validateParameter(valid_611823, JString, required = false,
                                 default = nil)
  if valid_611823 != nil:
    section.add "maximumFramerate", valid_611823
  var valid_611824 = query.getOrDefault("maximumBitrate")
  valid_611824 = validateParameter(valid_611824, JString, required = false,
                                 default = nil)
  if valid_611824 != nil:
    section.add "maximumBitrate", valid_611824
  var valid_611825 = query.getOrDefault("resourceType")
  valid_611825 = validateParameter(valid_611825, JString, required = false,
                                 default = nil)
  if valid_611825 != nil:
    section.add "resourceType", valid_611825
  var valid_611826 = query.getOrDefault("codec")
  valid_611826 = validateParameter(valid_611826, JString, required = false,
                                 default = nil)
  if valid_611826 != nil:
    section.add "codec", valid_611826
  var valid_611827 = query.getOrDefault("resolution")
  valid_611827 = validateParameter(valid_611827, JString, required = false,
                                 default = nil)
  if valid_611827 != nil:
    section.add "resolution", valid_611827
  var valid_611828 = query.getOrDefault("maxResults")
  valid_611828 = validateParameter(valid_611828, JInt, required = false, default = nil)
  if valid_611828 != nil:
    section.add "maxResults", valid_611828
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
  var valid_611829 = header.getOrDefault("X-Amz-Signature")
  valid_611829 = validateParameter(valid_611829, JString, required = false,
                                 default = nil)
  if valid_611829 != nil:
    section.add "X-Amz-Signature", valid_611829
  var valid_611830 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611830 = validateParameter(valid_611830, JString, required = false,
                                 default = nil)
  if valid_611830 != nil:
    section.add "X-Amz-Content-Sha256", valid_611830
  var valid_611831 = header.getOrDefault("X-Amz-Date")
  valid_611831 = validateParameter(valid_611831, JString, required = false,
                                 default = nil)
  if valid_611831 != nil:
    section.add "X-Amz-Date", valid_611831
  var valid_611832 = header.getOrDefault("X-Amz-Credential")
  valid_611832 = validateParameter(valid_611832, JString, required = false,
                                 default = nil)
  if valid_611832 != nil:
    section.add "X-Amz-Credential", valid_611832
  var valid_611833 = header.getOrDefault("X-Amz-Security-Token")
  valid_611833 = validateParameter(valid_611833, JString, required = false,
                                 default = nil)
  if valid_611833 != nil:
    section.add "X-Amz-Security-Token", valid_611833
  var valid_611834 = header.getOrDefault("X-Amz-Algorithm")
  valid_611834 = validateParameter(valid_611834, JString, required = false,
                                 default = nil)
  if valid_611834 != nil:
    section.add "X-Amz-Algorithm", valid_611834
  var valid_611835 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611835 = validateParameter(valid_611835, JString, required = false,
                                 default = nil)
  if valid_611835 != nil:
    section.add "X-Amz-SignedHeaders", valid_611835
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611836: Call_ListReservations_611814; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## List purchased reservations.
  ## 
  let valid = call_611836.validator(path, query, header, formData, body)
  let scheme = call_611836.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611836.url(scheme.get, call_611836.host, call_611836.base,
                         call_611836.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611836, url, valid)

proc call*(call_611837: Call_ListReservations_611814; specialFeature: string = "";
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
  var query_611838 = newJObject()
  add(query_611838, "specialFeature", newJString(specialFeature))
  add(query_611838, "nextToken", newJString(nextToken))
  add(query_611838, "MaxResults", newJString(MaxResults))
  add(query_611838, "channelClass", newJString(channelClass))
  add(query_611838, "NextToken", newJString(NextToken))
  add(query_611838, "videoQuality", newJString(videoQuality))
  add(query_611838, "maximumFramerate", newJString(maximumFramerate))
  add(query_611838, "maximumBitrate", newJString(maximumBitrate))
  add(query_611838, "resourceType", newJString(resourceType))
  add(query_611838, "codec", newJString(codec))
  add(query_611838, "resolution", newJString(resolution))
  add(query_611838, "maxResults", newJInt(maxResults))
  result = call_611837.call(nil, query_611838, nil, nil, nil)

var listReservations* = Call_ListReservations_611814(name: "listReservations",
    meth: HttpMethod.HttpGet, host: "medialive.amazonaws.com",
    route: "/prod/reservations", validator: validate_ListReservations_611815,
    base: "/", url: url_ListReservations_611816,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_PurchaseOffering_611839 = ref object of OpenApiRestCall_610658
proc url_PurchaseOffering_611841(protocol: Scheme; host: string; base: string;
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

proc validate_PurchaseOffering_611840(path: JsonNode; query: JsonNode;
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
  var valid_611842 = path.getOrDefault("offeringId")
  valid_611842 = validateParameter(valid_611842, JString, required = true,
                                 default = nil)
  if valid_611842 != nil:
    section.add "offeringId", valid_611842
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
  var valid_611843 = header.getOrDefault("X-Amz-Signature")
  valid_611843 = validateParameter(valid_611843, JString, required = false,
                                 default = nil)
  if valid_611843 != nil:
    section.add "X-Amz-Signature", valid_611843
  var valid_611844 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611844 = validateParameter(valid_611844, JString, required = false,
                                 default = nil)
  if valid_611844 != nil:
    section.add "X-Amz-Content-Sha256", valid_611844
  var valid_611845 = header.getOrDefault("X-Amz-Date")
  valid_611845 = validateParameter(valid_611845, JString, required = false,
                                 default = nil)
  if valid_611845 != nil:
    section.add "X-Amz-Date", valid_611845
  var valid_611846 = header.getOrDefault("X-Amz-Credential")
  valid_611846 = validateParameter(valid_611846, JString, required = false,
                                 default = nil)
  if valid_611846 != nil:
    section.add "X-Amz-Credential", valid_611846
  var valid_611847 = header.getOrDefault("X-Amz-Security-Token")
  valid_611847 = validateParameter(valid_611847, JString, required = false,
                                 default = nil)
  if valid_611847 != nil:
    section.add "X-Amz-Security-Token", valid_611847
  var valid_611848 = header.getOrDefault("X-Amz-Algorithm")
  valid_611848 = validateParameter(valid_611848, JString, required = false,
                                 default = nil)
  if valid_611848 != nil:
    section.add "X-Amz-Algorithm", valid_611848
  var valid_611849 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611849 = validateParameter(valid_611849, JString, required = false,
                                 default = nil)
  if valid_611849 != nil:
    section.add "X-Amz-SignedHeaders", valid_611849
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611851: Call_PurchaseOffering_611839; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Purchase an offering and create a reservation.
  ## 
  let valid = call_611851.validator(path, query, header, formData, body)
  let scheme = call_611851.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611851.url(scheme.get, call_611851.host, call_611851.base,
                         call_611851.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611851, url, valid)

proc call*(call_611852: Call_PurchaseOffering_611839; body: JsonNode;
          offeringId: string): Recallable =
  ## purchaseOffering
  ## Purchase an offering and create a reservation.
  ##   body: JObject (required)
  ##   offeringId: string (required)
  ##             : Placeholder documentation for __string
  var path_611853 = newJObject()
  var body_611854 = newJObject()
  if body != nil:
    body_611854 = body
  add(path_611853, "offeringId", newJString(offeringId))
  result = call_611852.call(path_611853, nil, nil, nil, body_611854)

var purchaseOffering* = Call_PurchaseOffering_611839(name: "purchaseOffering",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/offerings/{offeringId}/purchase",
    validator: validate_PurchaseOffering_611840, base: "/",
    url: url_PurchaseOffering_611841, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartChannel_611855 = ref object of OpenApiRestCall_610658
proc url_StartChannel_611857(protocol: Scheme; host: string; base: string;
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

proc validate_StartChannel_611856(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611858 = path.getOrDefault("channelId")
  valid_611858 = validateParameter(valid_611858, JString, required = true,
                                 default = nil)
  if valid_611858 != nil:
    section.add "channelId", valid_611858
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
  var valid_611859 = header.getOrDefault("X-Amz-Signature")
  valid_611859 = validateParameter(valid_611859, JString, required = false,
                                 default = nil)
  if valid_611859 != nil:
    section.add "X-Amz-Signature", valid_611859
  var valid_611860 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611860 = validateParameter(valid_611860, JString, required = false,
                                 default = nil)
  if valid_611860 != nil:
    section.add "X-Amz-Content-Sha256", valid_611860
  var valid_611861 = header.getOrDefault("X-Amz-Date")
  valid_611861 = validateParameter(valid_611861, JString, required = false,
                                 default = nil)
  if valid_611861 != nil:
    section.add "X-Amz-Date", valid_611861
  var valid_611862 = header.getOrDefault("X-Amz-Credential")
  valid_611862 = validateParameter(valid_611862, JString, required = false,
                                 default = nil)
  if valid_611862 != nil:
    section.add "X-Amz-Credential", valid_611862
  var valid_611863 = header.getOrDefault("X-Amz-Security-Token")
  valid_611863 = validateParameter(valid_611863, JString, required = false,
                                 default = nil)
  if valid_611863 != nil:
    section.add "X-Amz-Security-Token", valid_611863
  var valid_611864 = header.getOrDefault("X-Amz-Algorithm")
  valid_611864 = validateParameter(valid_611864, JString, required = false,
                                 default = nil)
  if valid_611864 != nil:
    section.add "X-Amz-Algorithm", valid_611864
  var valid_611865 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611865 = validateParameter(valid_611865, JString, required = false,
                                 default = nil)
  if valid_611865 != nil:
    section.add "X-Amz-SignedHeaders", valid_611865
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611866: Call_StartChannel_611855; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Starts an existing channel
  ## 
  let valid = call_611866.validator(path, query, header, formData, body)
  let scheme = call_611866.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611866.url(scheme.get, call_611866.host, call_611866.base,
                         call_611866.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611866, url, valid)

proc call*(call_611867: Call_StartChannel_611855; channelId: string): Recallable =
  ## startChannel
  ## Starts an existing channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_611868 = newJObject()
  add(path_611868, "channelId", newJString(channelId))
  result = call_611867.call(path_611868, nil, nil, nil, nil)

var startChannel* = Call_StartChannel_611855(name: "startChannel",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/start", validator: validate_StartChannel_611856,
    base: "/", url: url_StartChannel_611857, schemes: {Scheme.Https, Scheme.Http})
type
  Call_StartMultiplex_611869 = ref object of OpenApiRestCall_610658
proc url_StartMultiplex_611871(protocol: Scheme; host: string; base: string;
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

proc validate_StartMultiplex_611870(path: JsonNode; query: JsonNode;
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
  var valid_611872 = path.getOrDefault("multiplexId")
  valid_611872 = validateParameter(valid_611872, JString, required = true,
                                 default = nil)
  if valid_611872 != nil:
    section.add "multiplexId", valid_611872
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
  var valid_611873 = header.getOrDefault("X-Amz-Signature")
  valid_611873 = validateParameter(valid_611873, JString, required = false,
                                 default = nil)
  if valid_611873 != nil:
    section.add "X-Amz-Signature", valid_611873
  var valid_611874 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611874 = validateParameter(valid_611874, JString, required = false,
                                 default = nil)
  if valid_611874 != nil:
    section.add "X-Amz-Content-Sha256", valid_611874
  var valid_611875 = header.getOrDefault("X-Amz-Date")
  valid_611875 = validateParameter(valid_611875, JString, required = false,
                                 default = nil)
  if valid_611875 != nil:
    section.add "X-Amz-Date", valid_611875
  var valid_611876 = header.getOrDefault("X-Amz-Credential")
  valid_611876 = validateParameter(valid_611876, JString, required = false,
                                 default = nil)
  if valid_611876 != nil:
    section.add "X-Amz-Credential", valid_611876
  var valid_611877 = header.getOrDefault("X-Amz-Security-Token")
  valid_611877 = validateParameter(valid_611877, JString, required = false,
                                 default = nil)
  if valid_611877 != nil:
    section.add "X-Amz-Security-Token", valid_611877
  var valid_611878 = header.getOrDefault("X-Amz-Algorithm")
  valid_611878 = validateParameter(valid_611878, JString, required = false,
                                 default = nil)
  if valid_611878 != nil:
    section.add "X-Amz-Algorithm", valid_611878
  var valid_611879 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611879 = validateParameter(valid_611879, JString, required = false,
                                 default = nil)
  if valid_611879 != nil:
    section.add "X-Amz-SignedHeaders", valid_611879
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611880: Call_StartMultiplex_611869; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Start (run) the multiplex. Starting the multiplex does not start the channels. You must explicitly start each channel.
  ## 
  let valid = call_611880.validator(path, query, header, formData, body)
  let scheme = call_611880.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611880.url(scheme.get, call_611880.host, call_611880.base,
                         call_611880.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611880, url, valid)

proc call*(call_611881: Call_StartMultiplex_611869; multiplexId: string): Recallable =
  ## startMultiplex
  ## Start (run) the multiplex. Starting the multiplex does not start the channels. You must explicitly start each channel.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_611882 = newJObject()
  add(path_611882, "multiplexId", newJString(multiplexId))
  result = call_611881.call(path_611882, nil, nil, nil, nil)

var startMultiplex* = Call_StartMultiplex_611869(name: "startMultiplex",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/start",
    validator: validate_StartMultiplex_611870, base: "/", url: url_StartMultiplex_611871,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopChannel_611883 = ref object of OpenApiRestCall_610658
proc url_StopChannel_611885(protocol: Scheme; host: string; base: string;
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

proc validate_StopChannel_611884(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611886 = path.getOrDefault("channelId")
  valid_611886 = validateParameter(valid_611886, JString, required = true,
                                 default = nil)
  if valid_611886 != nil:
    section.add "channelId", valid_611886
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
  var valid_611887 = header.getOrDefault("X-Amz-Signature")
  valid_611887 = validateParameter(valid_611887, JString, required = false,
                                 default = nil)
  if valid_611887 != nil:
    section.add "X-Amz-Signature", valid_611887
  var valid_611888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611888 = validateParameter(valid_611888, JString, required = false,
                                 default = nil)
  if valid_611888 != nil:
    section.add "X-Amz-Content-Sha256", valid_611888
  var valid_611889 = header.getOrDefault("X-Amz-Date")
  valid_611889 = validateParameter(valid_611889, JString, required = false,
                                 default = nil)
  if valid_611889 != nil:
    section.add "X-Amz-Date", valid_611889
  var valid_611890 = header.getOrDefault("X-Amz-Credential")
  valid_611890 = validateParameter(valid_611890, JString, required = false,
                                 default = nil)
  if valid_611890 != nil:
    section.add "X-Amz-Credential", valid_611890
  var valid_611891 = header.getOrDefault("X-Amz-Security-Token")
  valid_611891 = validateParameter(valid_611891, JString, required = false,
                                 default = nil)
  if valid_611891 != nil:
    section.add "X-Amz-Security-Token", valid_611891
  var valid_611892 = header.getOrDefault("X-Amz-Algorithm")
  valid_611892 = validateParameter(valid_611892, JString, required = false,
                                 default = nil)
  if valid_611892 != nil:
    section.add "X-Amz-Algorithm", valid_611892
  var valid_611893 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611893 = validateParameter(valid_611893, JString, required = false,
                                 default = nil)
  if valid_611893 != nil:
    section.add "X-Amz-SignedHeaders", valid_611893
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611894: Call_StopChannel_611883; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running channel
  ## 
  let valid = call_611894.validator(path, query, header, formData, body)
  let scheme = call_611894.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611894.url(scheme.get, call_611894.host, call_611894.base,
                         call_611894.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611894, url, valid)

proc call*(call_611895: Call_StopChannel_611883; channelId: string): Recallable =
  ## stopChannel
  ## Stops a running channel
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  var path_611896 = newJObject()
  add(path_611896, "channelId", newJString(channelId))
  result = call_611895.call(path_611896, nil, nil, nil, nil)

var stopChannel* = Call_StopChannel_611883(name: "stopChannel",
                                        meth: HttpMethod.HttpPost,
                                        host: "medialive.amazonaws.com", route: "/prod/channels/{channelId}/stop",
                                        validator: validate_StopChannel_611884,
                                        base: "/", url: url_StopChannel_611885,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_StopMultiplex_611897 = ref object of OpenApiRestCall_610658
proc url_StopMultiplex_611899(protocol: Scheme; host: string; base: string;
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

proc validate_StopMultiplex_611898(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_611900 = path.getOrDefault("multiplexId")
  valid_611900 = validateParameter(valid_611900, JString, required = true,
                                 default = nil)
  if valid_611900 != nil:
    section.add "multiplexId", valid_611900
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
  var valid_611901 = header.getOrDefault("X-Amz-Signature")
  valid_611901 = validateParameter(valid_611901, JString, required = false,
                                 default = nil)
  if valid_611901 != nil:
    section.add "X-Amz-Signature", valid_611901
  var valid_611902 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611902 = validateParameter(valid_611902, JString, required = false,
                                 default = nil)
  if valid_611902 != nil:
    section.add "X-Amz-Content-Sha256", valid_611902
  var valid_611903 = header.getOrDefault("X-Amz-Date")
  valid_611903 = validateParameter(valid_611903, JString, required = false,
                                 default = nil)
  if valid_611903 != nil:
    section.add "X-Amz-Date", valid_611903
  var valid_611904 = header.getOrDefault("X-Amz-Credential")
  valid_611904 = validateParameter(valid_611904, JString, required = false,
                                 default = nil)
  if valid_611904 != nil:
    section.add "X-Amz-Credential", valid_611904
  var valid_611905 = header.getOrDefault("X-Amz-Security-Token")
  valid_611905 = validateParameter(valid_611905, JString, required = false,
                                 default = nil)
  if valid_611905 != nil:
    section.add "X-Amz-Security-Token", valid_611905
  var valid_611906 = header.getOrDefault("X-Amz-Algorithm")
  valid_611906 = validateParameter(valid_611906, JString, required = false,
                                 default = nil)
  if valid_611906 != nil:
    section.add "X-Amz-Algorithm", valid_611906
  var valid_611907 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611907 = validateParameter(valid_611907, JString, required = false,
                                 default = nil)
  if valid_611907 != nil:
    section.add "X-Amz-SignedHeaders", valid_611907
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611908: Call_StopMultiplex_611897; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Stops a running multiplex. If the multiplex isn't running, this action has no effect.
  ## 
  let valid = call_611908.validator(path, query, header, formData, body)
  let scheme = call_611908.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611908.url(scheme.get, call_611908.host, call_611908.base,
                         call_611908.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611908, url, valid)

proc call*(call_611909: Call_StopMultiplex_611897; multiplexId: string): Recallable =
  ## stopMultiplex
  ## Stops a running multiplex. If the multiplex isn't running, this action has no effect.
  ##   multiplexId: string (required)
  ##              : Placeholder documentation for __string
  var path_611910 = newJObject()
  add(path_611910, "multiplexId", newJString(multiplexId))
  result = call_611909.call(path_611910, nil, nil, nil, nil)

var stopMultiplex* = Call_StopMultiplex_611897(name: "stopMultiplex",
    meth: HttpMethod.HttpPost, host: "medialive.amazonaws.com",
    route: "/prod/multiplexes/{multiplexId}/stop",
    validator: validate_StopMultiplex_611898, base: "/", url: url_StopMultiplex_611899,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannelClass_611911 = ref object of OpenApiRestCall_610658
proc url_UpdateChannelClass_611913(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateChannelClass_611912(path: JsonNode; query: JsonNode;
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
  var valid_611914 = path.getOrDefault("channelId")
  valid_611914 = validateParameter(valid_611914, JString, required = true,
                                 default = nil)
  if valid_611914 != nil:
    section.add "channelId", valid_611914
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
  var valid_611915 = header.getOrDefault("X-Amz-Signature")
  valid_611915 = validateParameter(valid_611915, JString, required = false,
                                 default = nil)
  if valid_611915 != nil:
    section.add "X-Amz-Signature", valid_611915
  var valid_611916 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611916 = validateParameter(valid_611916, JString, required = false,
                                 default = nil)
  if valid_611916 != nil:
    section.add "X-Amz-Content-Sha256", valid_611916
  var valid_611917 = header.getOrDefault("X-Amz-Date")
  valid_611917 = validateParameter(valid_611917, JString, required = false,
                                 default = nil)
  if valid_611917 != nil:
    section.add "X-Amz-Date", valid_611917
  var valid_611918 = header.getOrDefault("X-Amz-Credential")
  valid_611918 = validateParameter(valid_611918, JString, required = false,
                                 default = nil)
  if valid_611918 != nil:
    section.add "X-Amz-Credential", valid_611918
  var valid_611919 = header.getOrDefault("X-Amz-Security-Token")
  valid_611919 = validateParameter(valid_611919, JString, required = false,
                                 default = nil)
  if valid_611919 != nil:
    section.add "X-Amz-Security-Token", valid_611919
  var valid_611920 = header.getOrDefault("X-Amz-Algorithm")
  valid_611920 = validateParameter(valid_611920, JString, required = false,
                                 default = nil)
  if valid_611920 != nil:
    section.add "X-Amz-Algorithm", valid_611920
  var valid_611921 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611921 = validateParameter(valid_611921, JString, required = false,
                                 default = nil)
  if valid_611921 != nil:
    section.add "X-Amz-SignedHeaders", valid_611921
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611923: Call_UpdateChannelClass_611911; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the class of the channel.
  ## 
  let valid = call_611923.validator(path, query, header, formData, body)
  let scheme = call_611923.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611923.url(scheme.get, call_611923.host, call_611923.base,
                         call_611923.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611923, url, valid)

proc call*(call_611924: Call_UpdateChannelClass_611911; channelId: string;
          body: JsonNode): Recallable =
  ## updateChannelClass
  ## Changes the class of the channel.
  ##   channelId: string (required)
  ##            : Placeholder documentation for __string
  ##   body: JObject (required)
  var path_611925 = newJObject()
  var body_611926 = newJObject()
  add(path_611925, "channelId", newJString(channelId))
  if body != nil:
    body_611926 = body
  result = call_611924.call(path_611925, nil, nil, nil, body_611926)

var updateChannelClass* = Call_UpdateChannelClass_611911(
    name: "updateChannelClass", meth: HttpMethod.HttpPut,
    host: "medialive.amazonaws.com",
    route: "/prod/channels/{channelId}/channelClass",
    validator: validate_UpdateChannelClass_611912, base: "/",
    url: url_UpdateChannelClass_611913, schemes: {Scheme.Https, Scheme.Http})
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
