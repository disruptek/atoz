
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, httpcore, sigv4

## auto-generated via openapi macro
## title: AWS Elemental MediaPackage
## version: 2017-10-12
## termsOfService: https://aws.amazon.com/service-terms/
## license:
##     name: Apache 2.0 License
##     url: http://www.apache.org/licenses/
## 
## AWS Elemental MediaPackage
## 
## Amazon Web Services documentation
## https://docs.aws.amazon.com/mediapackage/
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
  awsServers = {Scheme.Http: {"ap-northeast-1": "mediapackage.ap-northeast-1.amazonaws.com", "ap-southeast-1": "mediapackage.ap-southeast-1.amazonaws.com",
                           "us-west-2": "mediapackage.us-west-2.amazonaws.com",
                           "eu-west-2": "mediapackage.eu-west-2.amazonaws.com", "ap-northeast-3": "mediapackage.ap-northeast-3.amazonaws.com", "eu-central-1": "mediapackage.eu-central-1.amazonaws.com",
                           "us-east-2": "mediapackage.us-east-2.amazonaws.com",
                           "us-east-1": "mediapackage.us-east-1.amazonaws.com", "cn-northwest-1": "mediapackage.cn-northwest-1.amazonaws.com.cn", "ap-south-1": "mediapackage.ap-south-1.amazonaws.com", "eu-north-1": "mediapackage.eu-north-1.amazonaws.com", "ap-northeast-2": "mediapackage.ap-northeast-2.amazonaws.com",
                           "us-west-1": "mediapackage.us-west-1.amazonaws.com", "us-gov-east-1": "mediapackage.us-gov-east-1.amazonaws.com",
                           "eu-west-3": "mediapackage.eu-west-3.amazonaws.com", "cn-north-1": "mediapackage.cn-north-1.amazonaws.com.cn",
                           "sa-east-1": "mediapackage.sa-east-1.amazonaws.com",
                           "eu-west-1": "mediapackage.eu-west-1.amazonaws.com", "us-gov-west-1": "mediapackage.us-gov-west-1.amazonaws.com", "ap-southeast-2": "mediapackage.ap-southeast-2.amazonaws.com", "ca-central-1": "mediapackage.ca-central-1.amazonaws.com"}.toTable, Scheme.Https: {
      "ap-northeast-1": "mediapackage.ap-northeast-1.amazonaws.com",
      "ap-southeast-1": "mediapackage.ap-southeast-1.amazonaws.com",
      "us-west-2": "mediapackage.us-west-2.amazonaws.com",
      "eu-west-2": "mediapackage.eu-west-2.amazonaws.com",
      "ap-northeast-3": "mediapackage.ap-northeast-3.amazonaws.com",
      "eu-central-1": "mediapackage.eu-central-1.amazonaws.com",
      "us-east-2": "mediapackage.us-east-2.amazonaws.com",
      "us-east-1": "mediapackage.us-east-1.amazonaws.com",
      "cn-northwest-1": "mediapackage.cn-northwest-1.amazonaws.com.cn",
      "ap-south-1": "mediapackage.ap-south-1.amazonaws.com",
      "eu-north-1": "mediapackage.eu-north-1.amazonaws.com",
      "ap-northeast-2": "mediapackage.ap-northeast-2.amazonaws.com",
      "us-west-1": "mediapackage.us-west-1.amazonaws.com",
      "us-gov-east-1": "mediapackage.us-gov-east-1.amazonaws.com",
      "eu-west-3": "mediapackage.eu-west-3.amazonaws.com",
      "cn-north-1": "mediapackage.cn-north-1.amazonaws.com.cn",
      "sa-east-1": "mediapackage.sa-east-1.amazonaws.com",
      "eu-west-1": "mediapackage.eu-west-1.amazonaws.com",
      "us-gov-west-1": "mediapackage.us-gov-west-1.amazonaws.com",
      "ap-southeast-2": "mediapackage.ap-southeast-2.amazonaws.com",
      "ca-central-1": "mediapackage.ca-central-1.amazonaws.com"}.toTable}.toTable
const
  awsServiceName = "mediapackage"
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateChannel_611255 = ref object of OpenApiRestCall_610658
proc url_CreateChannel_611257(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateChannel_611256(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new Channel.
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
  var valid_611258 = header.getOrDefault("X-Amz-Signature")
  valid_611258 = validateParameter(valid_611258, JString, required = false,
                                 default = nil)
  if valid_611258 != nil:
    section.add "X-Amz-Signature", valid_611258
  var valid_611259 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611259 = validateParameter(valid_611259, JString, required = false,
                                 default = nil)
  if valid_611259 != nil:
    section.add "X-Amz-Content-Sha256", valid_611259
  var valid_611260 = header.getOrDefault("X-Amz-Date")
  valid_611260 = validateParameter(valid_611260, JString, required = false,
                                 default = nil)
  if valid_611260 != nil:
    section.add "X-Amz-Date", valid_611260
  var valid_611261 = header.getOrDefault("X-Amz-Credential")
  valid_611261 = validateParameter(valid_611261, JString, required = false,
                                 default = nil)
  if valid_611261 != nil:
    section.add "X-Amz-Credential", valid_611261
  var valid_611262 = header.getOrDefault("X-Amz-Security-Token")
  valid_611262 = validateParameter(valid_611262, JString, required = false,
                                 default = nil)
  if valid_611262 != nil:
    section.add "X-Amz-Security-Token", valid_611262
  var valid_611263 = header.getOrDefault("X-Amz-Algorithm")
  valid_611263 = validateParameter(valid_611263, JString, required = false,
                                 default = nil)
  if valid_611263 != nil:
    section.add "X-Amz-Algorithm", valid_611263
  var valid_611264 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611264 = validateParameter(valid_611264, JString, required = false,
                                 default = nil)
  if valid_611264 != nil:
    section.add "X-Amz-SignedHeaders", valid_611264
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611266: Call_CreateChannel_611255; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Channel.
  ## 
  let valid = call_611266.validator(path, query, header, formData, body)
  let scheme = call_611266.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611266.url(scheme.get, call_611266.host, call_611266.base,
                         call_611266.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611266, url, valid)

proc call*(call_611267: Call_CreateChannel_611255; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a new Channel.
  ##   body: JObject (required)
  var body_611268 = newJObject()
  if body != nil:
    body_611268 = body
  result = call_611267.call(nil, nil, nil, nil, body_611268)

var createChannel* = Call_CreateChannel_611255(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "mediapackage.amazonaws.com",
    route: "/channels", validator: validate_CreateChannel_611256, base: "/",
    url: url_CreateChannel_611257, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_610996 = ref object of OpenApiRestCall_610658
proc url_ListChannels_610998(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListChannels_610997(path: JsonNode; query: JsonNode; header: JsonNode;
                                 formData: JsonNode; body: JsonNode): JsonNode =
  ## Returns a collection of Channels.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Upper bound on number of records to return.
  section = newJObject()
  var valid_611110 = query.getOrDefault("nextToken")
  valid_611110 = validateParameter(valid_611110, JString, required = false,
                                 default = nil)
  if valid_611110 != nil:
    section.add "nextToken", valid_611110
  var valid_611111 = query.getOrDefault("MaxResults")
  valid_611111 = validateParameter(valid_611111, JString, required = false,
                                 default = nil)
  if valid_611111 != nil:
    section.add "MaxResults", valid_611111
  var valid_611112 = query.getOrDefault("NextToken")
  valid_611112 = validateParameter(valid_611112, JString, required = false,
                                 default = nil)
  if valid_611112 != nil:
    section.add "NextToken", valid_611112
  var valid_611113 = query.getOrDefault("maxResults")
  valid_611113 = validateParameter(valid_611113, JInt, required = false, default = nil)
  if valid_611113 != nil:
    section.add "maxResults", valid_611113
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
  var valid_611114 = header.getOrDefault("X-Amz-Signature")
  valid_611114 = validateParameter(valid_611114, JString, required = false,
                                 default = nil)
  if valid_611114 != nil:
    section.add "X-Amz-Signature", valid_611114
  var valid_611115 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611115 = validateParameter(valid_611115, JString, required = false,
                                 default = nil)
  if valid_611115 != nil:
    section.add "X-Amz-Content-Sha256", valid_611115
  var valid_611116 = header.getOrDefault("X-Amz-Date")
  valid_611116 = validateParameter(valid_611116, JString, required = false,
                                 default = nil)
  if valid_611116 != nil:
    section.add "X-Amz-Date", valid_611116
  var valid_611117 = header.getOrDefault("X-Amz-Credential")
  valid_611117 = validateParameter(valid_611117, JString, required = false,
                                 default = nil)
  if valid_611117 != nil:
    section.add "X-Amz-Credential", valid_611117
  var valid_611118 = header.getOrDefault("X-Amz-Security-Token")
  valid_611118 = validateParameter(valid_611118, JString, required = false,
                                 default = nil)
  if valid_611118 != nil:
    section.add "X-Amz-Security-Token", valid_611118
  var valid_611119 = header.getOrDefault("X-Amz-Algorithm")
  valid_611119 = validateParameter(valid_611119, JString, required = false,
                                 default = nil)
  if valid_611119 != nil:
    section.add "X-Amz-Algorithm", valid_611119
  var valid_611120 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611120 = validateParameter(valid_611120, JString, required = false,
                                 default = nil)
  if valid_611120 != nil:
    section.add "X-Amz-SignedHeaders", valid_611120
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611143: Call_ListChannels_610996; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of Channels.
  ## 
  let valid = call_611143.validator(path, query, header, formData, body)
  let scheme = call_611143.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611143.url(scheme.get, call_611143.host, call_611143.base,
                         call_611143.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611143, url, valid)

proc call*(call_611214: Call_ListChannels_610996; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; maxResults: int = 0): Recallable =
  ## listChannels
  ## Returns a collection of Channels.
  ##   nextToken: string
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Upper bound on number of records to return.
  var query_611215 = newJObject()
  add(query_611215, "nextToken", newJString(nextToken))
  add(query_611215, "MaxResults", newJString(MaxResults))
  add(query_611215, "NextToken", newJString(NextToken))
  add(query_611215, "maxResults", newJInt(maxResults))
  result = call_611214.call(nil, query_611215, nil, nil, nil)

var listChannels* = Call_ListChannels_610996(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/channels", validator: validate_ListChannels_610997, base: "/",
    url: url_ListChannels_610998, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHarvestJob_611288 = ref object of OpenApiRestCall_610658
proc url_CreateHarvestJob_611290(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateHarvestJob_611289(path: JsonNode; query: JsonNode;
                                     header: JsonNode; formData: JsonNode;
                                     body: JsonNode): JsonNode =
  ## Creates a new HarvestJob record.
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611299: Call_CreateHarvestJob_611288; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new HarvestJob record.
  ## 
  let valid = call_611299.validator(path, query, header, formData, body)
  let scheme = call_611299.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611299.url(scheme.get, call_611299.host, call_611299.base,
                         call_611299.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611299, url, valid)

proc call*(call_611300: Call_CreateHarvestJob_611288; body: JsonNode): Recallable =
  ## createHarvestJob
  ## Creates a new HarvestJob record.
  ##   body: JObject (required)
  var body_611301 = newJObject()
  if body != nil:
    body_611301 = body
  result = call_611300.call(nil, nil, nil, nil, body_611301)

var createHarvestJob* = Call_CreateHarvestJob_611288(name: "createHarvestJob",
    meth: HttpMethod.HttpPost, host: "mediapackage.amazonaws.com",
    route: "/harvest_jobs", validator: validate_CreateHarvestJob_611289, base: "/",
    url: url_CreateHarvestJob_611290, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHarvestJobs_611269 = ref object of OpenApiRestCall_610658
proc url_ListHarvestJobs_611271(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHarvestJobs_611270(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Returns a collection of HarvestJob records.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   includeChannelId: JString
  ##                   : When specified, the request will return only HarvestJobs associated with the given Channel ID.
  ##   includeStatus: JString
  ##                : When specified, the request will return only HarvestJobs in the given status.
  ##   maxResults: JInt
  ##             : The upper bound on the number of records to return.
  section = newJObject()
  var valid_611272 = query.getOrDefault("nextToken")
  valid_611272 = validateParameter(valid_611272, JString, required = false,
                                 default = nil)
  if valid_611272 != nil:
    section.add "nextToken", valid_611272
  var valid_611273 = query.getOrDefault("MaxResults")
  valid_611273 = validateParameter(valid_611273, JString, required = false,
                                 default = nil)
  if valid_611273 != nil:
    section.add "MaxResults", valid_611273
  var valid_611274 = query.getOrDefault("NextToken")
  valid_611274 = validateParameter(valid_611274, JString, required = false,
                                 default = nil)
  if valid_611274 != nil:
    section.add "NextToken", valid_611274
  var valid_611275 = query.getOrDefault("includeChannelId")
  valid_611275 = validateParameter(valid_611275, JString, required = false,
                                 default = nil)
  if valid_611275 != nil:
    section.add "includeChannelId", valid_611275
  var valid_611276 = query.getOrDefault("includeStatus")
  valid_611276 = validateParameter(valid_611276, JString, required = false,
                                 default = nil)
  if valid_611276 != nil:
    section.add "includeStatus", valid_611276
  var valid_611277 = query.getOrDefault("maxResults")
  valid_611277 = validateParameter(valid_611277, JInt, required = false, default = nil)
  if valid_611277 != nil:
    section.add "maxResults", valid_611277
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
  var valid_611278 = header.getOrDefault("X-Amz-Signature")
  valid_611278 = validateParameter(valid_611278, JString, required = false,
                                 default = nil)
  if valid_611278 != nil:
    section.add "X-Amz-Signature", valid_611278
  var valid_611279 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611279 = validateParameter(valid_611279, JString, required = false,
                                 default = nil)
  if valid_611279 != nil:
    section.add "X-Amz-Content-Sha256", valid_611279
  var valid_611280 = header.getOrDefault("X-Amz-Date")
  valid_611280 = validateParameter(valid_611280, JString, required = false,
                                 default = nil)
  if valid_611280 != nil:
    section.add "X-Amz-Date", valid_611280
  var valid_611281 = header.getOrDefault("X-Amz-Credential")
  valid_611281 = validateParameter(valid_611281, JString, required = false,
                                 default = nil)
  if valid_611281 != nil:
    section.add "X-Amz-Credential", valid_611281
  var valid_611282 = header.getOrDefault("X-Amz-Security-Token")
  valid_611282 = validateParameter(valid_611282, JString, required = false,
                                 default = nil)
  if valid_611282 != nil:
    section.add "X-Amz-Security-Token", valid_611282
  var valid_611283 = header.getOrDefault("X-Amz-Algorithm")
  valid_611283 = validateParameter(valid_611283, JString, required = false,
                                 default = nil)
  if valid_611283 != nil:
    section.add "X-Amz-Algorithm", valid_611283
  var valid_611284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611284 = validateParameter(valid_611284, JString, required = false,
                                 default = nil)
  if valid_611284 != nil:
    section.add "X-Amz-SignedHeaders", valid_611284
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611285: Call_ListHarvestJobs_611269; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of HarvestJob records.
  ## 
  let valid = call_611285.validator(path, query, header, formData, body)
  let scheme = call_611285.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611285.url(scheme.get, call_611285.host, call_611285.base,
                         call_611285.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611285, url, valid)

proc call*(call_611286: Call_ListHarvestJobs_611269; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = "";
          includeChannelId: string = ""; includeStatus: string = ""; maxResults: int = 0): Recallable =
  ## listHarvestJobs
  ## Returns a collection of HarvestJob records.
  ##   nextToken: string
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   includeChannelId: string
  ##                   : When specified, the request will return only HarvestJobs associated with the given Channel ID.
  ##   includeStatus: string
  ##                : When specified, the request will return only HarvestJobs in the given status.
  ##   maxResults: int
  ##             : The upper bound on the number of records to return.
  var query_611287 = newJObject()
  add(query_611287, "nextToken", newJString(nextToken))
  add(query_611287, "MaxResults", newJString(MaxResults))
  add(query_611287, "NextToken", newJString(NextToken))
  add(query_611287, "includeChannelId", newJString(includeChannelId))
  add(query_611287, "includeStatus", newJString(includeStatus))
  add(query_611287, "maxResults", newJInt(maxResults))
  result = call_611286.call(nil, query_611287, nil, nil, nil)

var listHarvestJobs* = Call_ListHarvestJobs_611269(name: "listHarvestJobs",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/harvest_jobs", validator: validate_ListHarvestJobs_611270, base: "/",
    url: url_ListHarvestJobs_611271, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOriginEndpoint_611320 = ref object of OpenApiRestCall_610658
proc url_CreateOriginEndpoint_611322(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateOriginEndpoint_611321(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Creates a new OriginEndpoint record.
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
  var valid_611323 = header.getOrDefault("X-Amz-Signature")
  valid_611323 = validateParameter(valid_611323, JString, required = false,
                                 default = nil)
  if valid_611323 != nil:
    section.add "X-Amz-Signature", valid_611323
  var valid_611324 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611324 = validateParameter(valid_611324, JString, required = false,
                                 default = nil)
  if valid_611324 != nil:
    section.add "X-Amz-Content-Sha256", valid_611324
  var valid_611325 = header.getOrDefault("X-Amz-Date")
  valid_611325 = validateParameter(valid_611325, JString, required = false,
                                 default = nil)
  if valid_611325 != nil:
    section.add "X-Amz-Date", valid_611325
  var valid_611326 = header.getOrDefault("X-Amz-Credential")
  valid_611326 = validateParameter(valid_611326, JString, required = false,
                                 default = nil)
  if valid_611326 != nil:
    section.add "X-Amz-Credential", valid_611326
  var valid_611327 = header.getOrDefault("X-Amz-Security-Token")
  valid_611327 = validateParameter(valid_611327, JString, required = false,
                                 default = nil)
  if valid_611327 != nil:
    section.add "X-Amz-Security-Token", valid_611327
  var valid_611328 = header.getOrDefault("X-Amz-Algorithm")
  valid_611328 = validateParameter(valid_611328, JString, required = false,
                                 default = nil)
  if valid_611328 != nil:
    section.add "X-Amz-Algorithm", valid_611328
  var valid_611329 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611329 = validateParameter(valid_611329, JString, required = false,
                                 default = nil)
  if valid_611329 != nil:
    section.add "X-Amz-SignedHeaders", valid_611329
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611331: Call_CreateOriginEndpoint_611320; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new OriginEndpoint record.
  ## 
  let valid = call_611331.validator(path, query, header, formData, body)
  let scheme = call_611331.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611331.url(scheme.get, call_611331.host, call_611331.base,
                         call_611331.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611331, url, valid)

proc call*(call_611332: Call_CreateOriginEndpoint_611320; body: JsonNode): Recallable =
  ## createOriginEndpoint
  ## Creates a new OriginEndpoint record.
  ##   body: JObject (required)
  var body_611333 = newJObject()
  if body != nil:
    body_611333 = body
  result = call_611332.call(nil, nil, nil, nil, body_611333)

var createOriginEndpoint* = Call_CreateOriginEndpoint_611320(
    name: "createOriginEndpoint", meth: HttpMethod.HttpPost,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints",
    validator: validate_CreateOriginEndpoint_611321, base: "/",
    url: url_CreateOriginEndpoint_611322, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOriginEndpoints_611302 = ref object of OpenApiRestCall_610658
proc url_ListOriginEndpoints_611304(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOriginEndpoints_611303(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  ## Returns a collection of OriginEndpoint records.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   nextToken: JString
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: JString
  ##             : Pagination limit
  ##   NextToken: JString
  ##            : Pagination token
  ##   channelId: JString
  ##            : When specified, the request will return only OriginEndpoints associated with the given Channel ID.
  ##   maxResults: JInt
  ##             : The upper bound on the number of records to return.
  section = newJObject()
  var valid_611305 = query.getOrDefault("nextToken")
  valid_611305 = validateParameter(valid_611305, JString, required = false,
                                 default = nil)
  if valid_611305 != nil:
    section.add "nextToken", valid_611305
  var valid_611306 = query.getOrDefault("MaxResults")
  valid_611306 = validateParameter(valid_611306, JString, required = false,
                                 default = nil)
  if valid_611306 != nil:
    section.add "MaxResults", valid_611306
  var valid_611307 = query.getOrDefault("NextToken")
  valid_611307 = validateParameter(valid_611307, JString, required = false,
                                 default = nil)
  if valid_611307 != nil:
    section.add "NextToken", valid_611307
  var valid_611308 = query.getOrDefault("channelId")
  valid_611308 = validateParameter(valid_611308, JString, required = false,
                                 default = nil)
  if valid_611308 != nil:
    section.add "channelId", valid_611308
  var valid_611309 = query.getOrDefault("maxResults")
  valid_611309 = validateParameter(valid_611309, JInt, required = false, default = nil)
  if valid_611309 != nil:
    section.add "maxResults", valid_611309
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
  var valid_611310 = header.getOrDefault("X-Amz-Signature")
  valid_611310 = validateParameter(valid_611310, JString, required = false,
                                 default = nil)
  if valid_611310 != nil:
    section.add "X-Amz-Signature", valid_611310
  var valid_611311 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611311 = validateParameter(valid_611311, JString, required = false,
                                 default = nil)
  if valid_611311 != nil:
    section.add "X-Amz-Content-Sha256", valid_611311
  var valid_611312 = header.getOrDefault("X-Amz-Date")
  valid_611312 = validateParameter(valid_611312, JString, required = false,
                                 default = nil)
  if valid_611312 != nil:
    section.add "X-Amz-Date", valid_611312
  var valid_611313 = header.getOrDefault("X-Amz-Credential")
  valid_611313 = validateParameter(valid_611313, JString, required = false,
                                 default = nil)
  if valid_611313 != nil:
    section.add "X-Amz-Credential", valid_611313
  var valid_611314 = header.getOrDefault("X-Amz-Security-Token")
  valid_611314 = validateParameter(valid_611314, JString, required = false,
                                 default = nil)
  if valid_611314 != nil:
    section.add "X-Amz-Security-Token", valid_611314
  var valid_611315 = header.getOrDefault("X-Amz-Algorithm")
  valid_611315 = validateParameter(valid_611315, JString, required = false,
                                 default = nil)
  if valid_611315 != nil:
    section.add "X-Amz-Algorithm", valid_611315
  var valid_611316 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611316 = validateParameter(valid_611316, JString, required = false,
                                 default = nil)
  if valid_611316 != nil:
    section.add "X-Amz-SignedHeaders", valid_611316
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611317: Call_ListOriginEndpoints_611302; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of OriginEndpoint records.
  ## 
  let valid = call_611317.validator(path, query, header, formData, body)
  let scheme = call_611317.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611317.url(scheme.get, call_611317.host, call_611317.base,
                         call_611317.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611317, url, valid)

proc call*(call_611318: Call_ListOriginEndpoints_611302; nextToken: string = "";
          MaxResults: string = ""; NextToken: string = ""; channelId: string = "";
          maxResults: int = 0): Recallable =
  ## listOriginEndpoints
  ## Returns a collection of OriginEndpoint records.
  ##   nextToken: string
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: string
  ##             : Pagination limit
  ##   NextToken: string
  ##            : Pagination token
  ##   channelId: string
  ##            : When specified, the request will return only OriginEndpoints associated with the given Channel ID.
  ##   maxResults: int
  ##             : The upper bound on the number of records to return.
  var query_611319 = newJObject()
  add(query_611319, "nextToken", newJString(nextToken))
  add(query_611319, "MaxResults", newJString(MaxResults))
  add(query_611319, "NextToken", newJString(NextToken))
  add(query_611319, "channelId", newJString(channelId))
  add(query_611319, "maxResults", newJInt(maxResults))
  result = call_611318.call(nil, query_611319, nil, nil, nil)

var listOriginEndpoints* = Call_ListOriginEndpoints_611302(
    name: "listOriginEndpoints", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints",
    validator: validate_ListOriginEndpoints_611303, base: "/",
    url: url_ListOriginEndpoints_611304, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_611362 = ref object of OpenApiRestCall_610658
proc url_UpdateChannel_611364(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateChannel_611363(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing Channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the Channel to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_611365 = path.getOrDefault("id")
  valid_611365 = validateParameter(valid_611365, JString, required = true,
                                 default = nil)
  if valid_611365 != nil:
    section.add "id", valid_611365
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
  var valid_611366 = header.getOrDefault("X-Amz-Signature")
  valid_611366 = validateParameter(valid_611366, JString, required = false,
                                 default = nil)
  if valid_611366 != nil:
    section.add "X-Amz-Signature", valid_611366
  var valid_611367 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611367 = validateParameter(valid_611367, JString, required = false,
                                 default = nil)
  if valid_611367 != nil:
    section.add "X-Amz-Content-Sha256", valid_611367
  var valid_611368 = header.getOrDefault("X-Amz-Date")
  valid_611368 = validateParameter(valid_611368, JString, required = false,
                                 default = nil)
  if valid_611368 != nil:
    section.add "X-Amz-Date", valid_611368
  var valid_611369 = header.getOrDefault("X-Amz-Credential")
  valid_611369 = validateParameter(valid_611369, JString, required = false,
                                 default = nil)
  if valid_611369 != nil:
    section.add "X-Amz-Credential", valid_611369
  var valid_611370 = header.getOrDefault("X-Amz-Security-Token")
  valid_611370 = validateParameter(valid_611370, JString, required = false,
                                 default = nil)
  if valid_611370 != nil:
    section.add "X-Amz-Security-Token", valid_611370
  var valid_611371 = header.getOrDefault("X-Amz-Algorithm")
  valid_611371 = validateParameter(valid_611371, JString, required = false,
                                 default = nil)
  if valid_611371 != nil:
    section.add "X-Amz-Algorithm", valid_611371
  var valid_611372 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611372 = validateParameter(valid_611372, JString, required = false,
                                 default = nil)
  if valid_611372 != nil:
    section.add "X-Amz-SignedHeaders", valid_611372
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611374: Call_UpdateChannel_611362; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing Channel.
  ## 
  let valid = call_611374.validator(path, query, header, formData, body)
  let scheme = call_611374.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611374.url(scheme.get, call_611374.host, call_611374.base,
                         call_611374.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611374, url, valid)

proc call*(call_611375: Call_UpdateChannel_611362; id: string; body: JsonNode): Recallable =
  ## updateChannel
  ## Updates an existing Channel.
  ##   id: string (required)
  ##     : The ID of the Channel to update.
  ##   body: JObject (required)
  var path_611376 = newJObject()
  var body_611377 = newJObject()
  add(path_611376, "id", newJString(id))
  if body != nil:
    body_611377 = body
  result = call_611375.call(path_611376, nil, nil, nil, body_611377)

var updateChannel* = Call_UpdateChannel_611362(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_UpdateChannel_611363, base: "/",
    url: url_UpdateChannel_611364, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_611334 = ref object of OpenApiRestCall_610658
proc url_DescribeChannel_611336(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeChannel_611335(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode): JsonNode =
  ## Gets details about a Channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of a Channel.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_611351 = path.getOrDefault("id")
  valid_611351 = validateParameter(valid_611351, JString, required = true,
                                 default = nil)
  if valid_611351 != nil:
    section.add "id", valid_611351
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
  if body != nil:
    result.add "body", body

proc call*(call_611359: Call_DescribeChannel_611334; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a Channel.
  ## 
  let valid = call_611359.validator(path, query, header, formData, body)
  let scheme = call_611359.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611359.url(scheme.get, call_611359.host, call_611359.base,
                         call_611359.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611359, url, valid)

proc call*(call_611360: Call_DescribeChannel_611334; id: string): Recallable =
  ## describeChannel
  ## Gets details about a Channel.
  ##   id: string (required)
  ##     : The ID of a Channel.
  var path_611361 = newJObject()
  add(path_611361, "id", newJString(id))
  result = call_611360.call(path_611361, nil, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_611334(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_DescribeChannel_611335, base: "/",
    url: url_DescribeChannel_611336, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_611378 = ref object of OpenApiRestCall_610658
proc url_DeleteChannel_611380(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteChannel_611379(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing Channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the Channel to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_611381 = path.getOrDefault("id")
  valid_611381 = validateParameter(valid_611381, JString, required = true,
                                 default = nil)
  if valid_611381 != nil:
    section.add "id", valid_611381
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
  var valid_611382 = header.getOrDefault("X-Amz-Signature")
  valid_611382 = validateParameter(valid_611382, JString, required = false,
                                 default = nil)
  if valid_611382 != nil:
    section.add "X-Amz-Signature", valid_611382
  var valid_611383 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611383 = validateParameter(valid_611383, JString, required = false,
                                 default = nil)
  if valid_611383 != nil:
    section.add "X-Amz-Content-Sha256", valid_611383
  var valid_611384 = header.getOrDefault("X-Amz-Date")
  valid_611384 = validateParameter(valid_611384, JString, required = false,
                                 default = nil)
  if valid_611384 != nil:
    section.add "X-Amz-Date", valid_611384
  var valid_611385 = header.getOrDefault("X-Amz-Credential")
  valid_611385 = validateParameter(valid_611385, JString, required = false,
                                 default = nil)
  if valid_611385 != nil:
    section.add "X-Amz-Credential", valid_611385
  var valid_611386 = header.getOrDefault("X-Amz-Security-Token")
  valid_611386 = validateParameter(valid_611386, JString, required = false,
                                 default = nil)
  if valid_611386 != nil:
    section.add "X-Amz-Security-Token", valid_611386
  var valid_611387 = header.getOrDefault("X-Amz-Algorithm")
  valid_611387 = validateParameter(valid_611387, JString, required = false,
                                 default = nil)
  if valid_611387 != nil:
    section.add "X-Amz-Algorithm", valid_611387
  var valid_611388 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611388 = validateParameter(valid_611388, JString, required = false,
                                 default = nil)
  if valid_611388 != nil:
    section.add "X-Amz-SignedHeaders", valid_611388
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611389: Call_DeleteChannel_611378; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing Channel.
  ## 
  let valid = call_611389.validator(path, query, header, formData, body)
  let scheme = call_611389.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611389.url(scheme.get, call_611389.host, call_611389.base,
                         call_611389.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611389, url, valid)

proc call*(call_611390: Call_DeleteChannel_611378; id: string): Recallable =
  ## deleteChannel
  ## Deletes an existing Channel.
  ##   id: string (required)
  ##     : The ID of the Channel to delete.
  var path_611391 = newJObject()
  add(path_611391, "id", newJString(id))
  result = call_611390.call(path_611391, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_611378(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_DeleteChannel_611379, base: "/",
    url: url_DeleteChannel_611380, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOriginEndpoint_611406 = ref object of OpenApiRestCall_610658
proc url_UpdateOriginEndpoint_611408(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/origin_endpoints/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateOriginEndpoint_611407(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Updates an existing OriginEndpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the OriginEndpoint to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_611409 = path.getOrDefault("id")
  valid_611409 = validateParameter(valid_611409, JString, required = true,
                                 default = nil)
  if valid_611409 != nil:
    section.add "id", valid_611409
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
  var valid_611410 = header.getOrDefault("X-Amz-Signature")
  valid_611410 = validateParameter(valid_611410, JString, required = false,
                                 default = nil)
  if valid_611410 != nil:
    section.add "X-Amz-Signature", valid_611410
  var valid_611411 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611411 = validateParameter(valid_611411, JString, required = false,
                                 default = nil)
  if valid_611411 != nil:
    section.add "X-Amz-Content-Sha256", valid_611411
  var valid_611412 = header.getOrDefault("X-Amz-Date")
  valid_611412 = validateParameter(valid_611412, JString, required = false,
                                 default = nil)
  if valid_611412 != nil:
    section.add "X-Amz-Date", valid_611412
  var valid_611413 = header.getOrDefault("X-Amz-Credential")
  valid_611413 = validateParameter(valid_611413, JString, required = false,
                                 default = nil)
  if valid_611413 != nil:
    section.add "X-Amz-Credential", valid_611413
  var valid_611414 = header.getOrDefault("X-Amz-Security-Token")
  valid_611414 = validateParameter(valid_611414, JString, required = false,
                                 default = nil)
  if valid_611414 != nil:
    section.add "X-Amz-Security-Token", valid_611414
  var valid_611415 = header.getOrDefault("X-Amz-Algorithm")
  valid_611415 = validateParameter(valid_611415, JString, required = false,
                                 default = nil)
  if valid_611415 != nil:
    section.add "X-Amz-Algorithm", valid_611415
  var valid_611416 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611416 = validateParameter(valid_611416, JString, required = false,
                                 default = nil)
  if valid_611416 != nil:
    section.add "X-Amz-SignedHeaders", valid_611416
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611418: Call_UpdateOriginEndpoint_611406; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing OriginEndpoint.
  ## 
  let valid = call_611418.validator(path, query, header, formData, body)
  let scheme = call_611418.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611418.url(scheme.get, call_611418.host, call_611418.base,
                         call_611418.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611418, url, valid)

proc call*(call_611419: Call_UpdateOriginEndpoint_611406; id: string; body: JsonNode): Recallable =
  ## updateOriginEndpoint
  ## Updates an existing OriginEndpoint.
  ##   id: string (required)
  ##     : The ID of the OriginEndpoint to update.
  ##   body: JObject (required)
  var path_611420 = newJObject()
  var body_611421 = newJObject()
  add(path_611420, "id", newJString(id))
  if body != nil:
    body_611421 = body
  result = call_611419.call(path_611420, nil, nil, nil, body_611421)

var updateOriginEndpoint* = Call_UpdateOriginEndpoint_611406(
    name: "updateOriginEndpoint", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_UpdateOriginEndpoint_611407, base: "/",
    url: url_UpdateOriginEndpoint_611408, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOriginEndpoint_611392 = ref object of OpenApiRestCall_610658
proc url_DescribeOriginEndpoint_611394(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/origin_endpoints/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeOriginEndpoint_611393(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Gets details about an existing OriginEndpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the OriginEndpoint.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_611395 = path.getOrDefault("id")
  valid_611395 = validateParameter(valid_611395, JString, required = true,
                                 default = nil)
  if valid_611395 != nil:
    section.add "id", valid_611395
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
  var valid_611396 = header.getOrDefault("X-Amz-Signature")
  valid_611396 = validateParameter(valid_611396, JString, required = false,
                                 default = nil)
  if valid_611396 != nil:
    section.add "X-Amz-Signature", valid_611396
  var valid_611397 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611397 = validateParameter(valid_611397, JString, required = false,
                                 default = nil)
  if valid_611397 != nil:
    section.add "X-Amz-Content-Sha256", valid_611397
  var valid_611398 = header.getOrDefault("X-Amz-Date")
  valid_611398 = validateParameter(valid_611398, JString, required = false,
                                 default = nil)
  if valid_611398 != nil:
    section.add "X-Amz-Date", valid_611398
  var valid_611399 = header.getOrDefault("X-Amz-Credential")
  valid_611399 = validateParameter(valid_611399, JString, required = false,
                                 default = nil)
  if valid_611399 != nil:
    section.add "X-Amz-Credential", valid_611399
  var valid_611400 = header.getOrDefault("X-Amz-Security-Token")
  valid_611400 = validateParameter(valid_611400, JString, required = false,
                                 default = nil)
  if valid_611400 != nil:
    section.add "X-Amz-Security-Token", valid_611400
  var valid_611401 = header.getOrDefault("X-Amz-Algorithm")
  valid_611401 = validateParameter(valid_611401, JString, required = false,
                                 default = nil)
  if valid_611401 != nil:
    section.add "X-Amz-Algorithm", valid_611401
  var valid_611402 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611402 = validateParameter(valid_611402, JString, required = false,
                                 default = nil)
  if valid_611402 != nil:
    section.add "X-Amz-SignedHeaders", valid_611402
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611403: Call_DescribeOriginEndpoint_611392; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about an existing OriginEndpoint.
  ## 
  let valid = call_611403.validator(path, query, header, formData, body)
  let scheme = call_611403.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611403.url(scheme.get, call_611403.host, call_611403.base,
                         call_611403.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611403, url, valid)

proc call*(call_611404: Call_DescribeOriginEndpoint_611392; id: string): Recallable =
  ## describeOriginEndpoint
  ## Gets details about an existing OriginEndpoint.
  ##   id: string (required)
  ##     : The ID of the OriginEndpoint.
  var path_611405 = newJObject()
  add(path_611405, "id", newJString(id))
  result = call_611404.call(path_611405, nil, nil, nil, nil)

var describeOriginEndpoint* = Call_DescribeOriginEndpoint_611392(
    name: "describeOriginEndpoint", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_DescribeOriginEndpoint_611393, base: "/",
    url: url_DescribeOriginEndpoint_611394, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOriginEndpoint_611422 = ref object of OpenApiRestCall_610658
proc url_DeleteOriginEndpoint_611424(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/origin_endpoints/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteOriginEndpoint_611423(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Deletes an existing OriginEndpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the OriginEndpoint to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_611425 = path.getOrDefault("id")
  valid_611425 = validateParameter(valid_611425, JString, required = true,
                                 default = nil)
  if valid_611425 != nil:
    section.add "id", valid_611425
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
  var valid_611426 = header.getOrDefault("X-Amz-Signature")
  valid_611426 = validateParameter(valid_611426, JString, required = false,
                                 default = nil)
  if valid_611426 != nil:
    section.add "X-Amz-Signature", valid_611426
  var valid_611427 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611427 = validateParameter(valid_611427, JString, required = false,
                                 default = nil)
  if valid_611427 != nil:
    section.add "X-Amz-Content-Sha256", valid_611427
  var valid_611428 = header.getOrDefault("X-Amz-Date")
  valid_611428 = validateParameter(valid_611428, JString, required = false,
                                 default = nil)
  if valid_611428 != nil:
    section.add "X-Amz-Date", valid_611428
  var valid_611429 = header.getOrDefault("X-Amz-Credential")
  valid_611429 = validateParameter(valid_611429, JString, required = false,
                                 default = nil)
  if valid_611429 != nil:
    section.add "X-Amz-Credential", valid_611429
  var valid_611430 = header.getOrDefault("X-Amz-Security-Token")
  valid_611430 = validateParameter(valid_611430, JString, required = false,
                                 default = nil)
  if valid_611430 != nil:
    section.add "X-Amz-Security-Token", valid_611430
  var valid_611431 = header.getOrDefault("X-Amz-Algorithm")
  valid_611431 = validateParameter(valid_611431, JString, required = false,
                                 default = nil)
  if valid_611431 != nil:
    section.add "X-Amz-Algorithm", valid_611431
  var valid_611432 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611432 = validateParameter(valid_611432, JString, required = false,
                                 default = nil)
  if valid_611432 != nil:
    section.add "X-Amz-SignedHeaders", valid_611432
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611433: Call_DeleteOriginEndpoint_611422; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing OriginEndpoint.
  ## 
  let valid = call_611433.validator(path, query, header, formData, body)
  let scheme = call_611433.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611433.url(scheme.get, call_611433.host, call_611433.base,
                         call_611433.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611433, url, valid)

proc call*(call_611434: Call_DeleteOriginEndpoint_611422; id: string): Recallable =
  ## deleteOriginEndpoint
  ## Deletes an existing OriginEndpoint.
  ##   id: string (required)
  ##     : The ID of the OriginEndpoint to delete.
  var path_611435 = newJObject()
  add(path_611435, "id", newJString(id))
  result = call_611434.call(path_611435, nil, nil, nil, nil)

var deleteOriginEndpoint* = Call_DeleteOriginEndpoint_611422(
    name: "deleteOriginEndpoint", meth: HttpMethod.HttpDelete,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_DeleteOriginEndpoint_611423, base: "/",
    url: url_DeleteOriginEndpoint_611424, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHarvestJob_611436 = ref object of OpenApiRestCall_610658
proc url_DescribeHarvestJob_611438(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/harvest_jobs/"),
               (kind: VariableSegment, value: "id")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeHarvestJob_611437(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode): JsonNode =
  ## Gets details about an existing HarvestJob.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the HarvestJob.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_611439 = path.getOrDefault("id")
  valid_611439 = validateParameter(valid_611439, JString, required = true,
                                 default = nil)
  if valid_611439 != nil:
    section.add "id", valid_611439
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
  var valid_611440 = header.getOrDefault("X-Amz-Signature")
  valid_611440 = validateParameter(valid_611440, JString, required = false,
                                 default = nil)
  if valid_611440 != nil:
    section.add "X-Amz-Signature", valid_611440
  var valid_611441 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611441 = validateParameter(valid_611441, JString, required = false,
                                 default = nil)
  if valid_611441 != nil:
    section.add "X-Amz-Content-Sha256", valid_611441
  var valid_611442 = header.getOrDefault("X-Amz-Date")
  valid_611442 = validateParameter(valid_611442, JString, required = false,
                                 default = nil)
  if valid_611442 != nil:
    section.add "X-Amz-Date", valid_611442
  var valid_611443 = header.getOrDefault("X-Amz-Credential")
  valid_611443 = validateParameter(valid_611443, JString, required = false,
                                 default = nil)
  if valid_611443 != nil:
    section.add "X-Amz-Credential", valid_611443
  var valid_611444 = header.getOrDefault("X-Amz-Security-Token")
  valid_611444 = validateParameter(valid_611444, JString, required = false,
                                 default = nil)
  if valid_611444 != nil:
    section.add "X-Amz-Security-Token", valid_611444
  var valid_611445 = header.getOrDefault("X-Amz-Algorithm")
  valid_611445 = validateParameter(valid_611445, JString, required = false,
                                 default = nil)
  if valid_611445 != nil:
    section.add "X-Amz-Algorithm", valid_611445
  var valid_611446 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611446 = validateParameter(valid_611446, JString, required = false,
                                 default = nil)
  if valid_611446 != nil:
    section.add "X-Amz-SignedHeaders", valid_611446
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611447: Call_DescribeHarvestJob_611436; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about an existing HarvestJob.
  ## 
  let valid = call_611447.validator(path, query, header, formData, body)
  let scheme = call_611447.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611447.url(scheme.get, call_611447.host, call_611447.base,
                         call_611447.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611447, url, valid)

proc call*(call_611448: Call_DescribeHarvestJob_611436; id: string): Recallable =
  ## describeHarvestJob
  ## Gets details about an existing HarvestJob.
  ##   id: string (required)
  ##     : The ID of the HarvestJob.
  var path_611449 = newJObject()
  add(path_611449, "id", newJString(id))
  result = call_611448.call(path_611449, nil, nil, nil, nil)

var describeHarvestJob* = Call_DescribeHarvestJob_611436(
    name: "describeHarvestJob", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/harvest_jobs/{id}",
    validator: validate_DescribeHarvestJob_611437, base: "/",
    url: url_DescribeHarvestJob_611438, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_611464 = ref object of OpenApiRestCall_610658
proc url_TagResource_611466(protocol: Scheme; host: string; base: string;
                           route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_611465(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_611467 = path.getOrDefault("resource-arn")
  valid_611467 = validateParameter(valid_611467, JString, required = true,
                                 default = nil)
  if valid_611467 != nil:
    section.add "resource-arn", valid_611467
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
  var valid_611468 = header.getOrDefault("X-Amz-Signature")
  valid_611468 = validateParameter(valid_611468, JString, required = false,
                                 default = nil)
  if valid_611468 != nil:
    section.add "X-Amz-Signature", valid_611468
  var valid_611469 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611469 = validateParameter(valid_611469, JString, required = false,
                                 default = nil)
  if valid_611469 != nil:
    section.add "X-Amz-Content-Sha256", valid_611469
  var valid_611470 = header.getOrDefault("X-Amz-Date")
  valid_611470 = validateParameter(valid_611470, JString, required = false,
                                 default = nil)
  if valid_611470 != nil:
    section.add "X-Amz-Date", valid_611470
  var valid_611471 = header.getOrDefault("X-Amz-Credential")
  valid_611471 = validateParameter(valid_611471, JString, required = false,
                                 default = nil)
  if valid_611471 != nil:
    section.add "X-Amz-Credential", valid_611471
  var valid_611472 = header.getOrDefault("X-Amz-Security-Token")
  valid_611472 = validateParameter(valid_611472, JString, required = false,
                                 default = nil)
  if valid_611472 != nil:
    section.add "X-Amz-Security-Token", valid_611472
  var valid_611473 = header.getOrDefault("X-Amz-Algorithm")
  valid_611473 = validateParameter(valid_611473, JString, required = false,
                                 default = nil)
  if valid_611473 != nil:
    section.add "X-Amz-Algorithm", valid_611473
  var valid_611474 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611474 = validateParameter(valid_611474, JString, required = false,
                                 default = nil)
  if valid_611474 != nil:
    section.add "X-Amz-SignedHeaders", valid_611474
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_611476: Call_TagResource_611464; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611476.validator(path, query, header, formData, body)
  let scheme = call_611476.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611476.url(scheme.get, call_611476.host, call_611476.base,
                         call_611476.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611476, url, valid)

proc call*(call_611477: Call_TagResource_611464; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ##   resourceArn: string (required)
  ##   body: JObject (required)
  var path_611478 = newJObject()
  var body_611479 = newJObject()
  add(path_611478, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_611479 = body
  result = call_611477.call(path_611478, nil, nil, nil, body_611479)

var tagResource* = Call_TagResource_611464(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediapackage.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_611465,
                                        base: "/", url: url_TagResource_611466,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_611450 = ref object of OpenApiRestCall_610658
proc url_ListTagsForResource_611452(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_611451(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_611453 = path.getOrDefault("resource-arn")
  valid_611453 = validateParameter(valid_611453, JString, required = true,
                                 default = nil)
  if valid_611453 != nil:
    section.add "resource-arn", valid_611453
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
  var valid_611454 = header.getOrDefault("X-Amz-Signature")
  valid_611454 = validateParameter(valid_611454, JString, required = false,
                                 default = nil)
  if valid_611454 != nil:
    section.add "X-Amz-Signature", valid_611454
  var valid_611455 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611455 = validateParameter(valid_611455, JString, required = false,
                                 default = nil)
  if valid_611455 != nil:
    section.add "X-Amz-Content-Sha256", valid_611455
  var valid_611456 = header.getOrDefault("X-Amz-Date")
  valid_611456 = validateParameter(valid_611456, JString, required = false,
                                 default = nil)
  if valid_611456 != nil:
    section.add "X-Amz-Date", valid_611456
  var valid_611457 = header.getOrDefault("X-Amz-Credential")
  valid_611457 = validateParameter(valid_611457, JString, required = false,
                                 default = nil)
  if valid_611457 != nil:
    section.add "X-Amz-Credential", valid_611457
  var valid_611458 = header.getOrDefault("X-Amz-Security-Token")
  valid_611458 = validateParameter(valid_611458, JString, required = false,
                                 default = nil)
  if valid_611458 != nil:
    section.add "X-Amz-Security-Token", valid_611458
  var valid_611459 = header.getOrDefault("X-Amz-Algorithm")
  valid_611459 = validateParameter(valid_611459, JString, required = false,
                                 default = nil)
  if valid_611459 != nil:
    section.add "X-Amz-Algorithm", valid_611459
  var valid_611460 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611460 = validateParameter(valid_611460, JString, required = false,
                                 default = nil)
  if valid_611460 != nil:
    section.add "X-Amz-SignedHeaders", valid_611460
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611461: Call_ListTagsForResource_611450; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611461.validator(path, query, header, formData, body)
  let scheme = call_611461.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611461.url(scheme.get, call_611461.host, call_611461.base,
                         call_611461.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611461, url, valid)

proc call*(call_611462: Call_ListTagsForResource_611450; resourceArn: string): Recallable =
  ## listTagsForResource
  ##   resourceArn: string (required)
  var path_611463 = newJObject()
  add(path_611463, "resource-arn", newJString(resourceArn))
  result = call_611462.call(path_611463, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_611450(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_611451, base: "/",
    url: url_ListTagsForResource_611452, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RotateChannelCredentials_611480 = ref object of OpenApiRestCall_610658
proc url_RotateChannelCredentials_611482(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "id"),
               (kind: ConstantSegment, value: "/credentials")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RotateChannelCredentials_611481(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the channel to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_611483 = path.getOrDefault("id")
  valid_611483 = validateParameter(valid_611483, JString, required = true,
                                 default = nil)
  if valid_611483 != nil:
    section.add "id", valid_611483
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
  var valid_611484 = header.getOrDefault("X-Amz-Signature")
  valid_611484 = validateParameter(valid_611484, JString, required = false,
                                 default = nil)
  if valid_611484 != nil:
    section.add "X-Amz-Signature", valid_611484
  var valid_611485 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611485 = validateParameter(valid_611485, JString, required = false,
                                 default = nil)
  if valid_611485 != nil:
    section.add "X-Amz-Content-Sha256", valid_611485
  var valid_611486 = header.getOrDefault("X-Amz-Date")
  valid_611486 = validateParameter(valid_611486, JString, required = false,
                                 default = nil)
  if valid_611486 != nil:
    section.add "X-Amz-Date", valid_611486
  var valid_611487 = header.getOrDefault("X-Amz-Credential")
  valid_611487 = validateParameter(valid_611487, JString, required = false,
                                 default = nil)
  if valid_611487 != nil:
    section.add "X-Amz-Credential", valid_611487
  var valid_611488 = header.getOrDefault("X-Amz-Security-Token")
  valid_611488 = validateParameter(valid_611488, JString, required = false,
                                 default = nil)
  if valid_611488 != nil:
    section.add "X-Amz-Security-Token", valid_611488
  var valid_611489 = header.getOrDefault("X-Amz-Algorithm")
  valid_611489 = validateParameter(valid_611489, JString, required = false,
                                 default = nil)
  if valid_611489 != nil:
    section.add "X-Amz-Algorithm", valid_611489
  var valid_611490 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611490 = validateParameter(valid_611490, JString, required = false,
                                 default = nil)
  if valid_611490 != nil:
    section.add "X-Amz-SignedHeaders", valid_611490
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611491: Call_RotateChannelCredentials_611480; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
  ## 
  let valid = call_611491.validator(path, query, header, formData, body)
  let scheme = call_611491.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611491.url(scheme.get, call_611491.host, call_611491.base,
                         call_611491.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611491, url, valid)

proc call*(call_611492: Call_RotateChannelCredentials_611480; id: string): Recallable =
  ## rotateChannelCredentials
  ## Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
  ##   id: string (required)
  ##     : The ID of the channel to update.
  var path_611493 = newJObject()
  add(path_611493, "id", newJString(id))
  result = call_611492.call(path_611493, nil, nil, nil, nil)

var rotateChannelCredentials* = Call_RotateChannelCredentials_611480(
    name: "rotateChannelCredentials", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com", route: "/channels/{id}/credentials",
    validator: validate_RotateChannelCredentials_611481, base: "/",
    url: url_RotateChannelCredentials_611482, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RotateIngestEndpointCredentials_611494 = ref object of OpenApiRestCall_610658
proc url_RotateIngestEndpointCredentials_611496(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "id" in path, "`id` is a required path parameter"
  assert "ingest_endpoint_id" in path,
        "`ingest_endpoint_id` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/channels/"),
               (kind: VariableSegment, value: "id"),
               (kind: ConstantSegment, value: "/ingest_endpoints/"),
               (kind: VariableSegment, value: "ingest_endpoint_id"),
               (kind: ConstantSegment, value: "/credentials")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RotateIngestEndpointCredentials_611495(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): JsonNode =
  ## Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the channel the IngestEndpoint is on.
  ##   ingest_endpoint_id: JString (required)
  ##                     : The id of the IngestEndpoint whose credentials should be rotated
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_611497 = path.getOrDefault("id")
  valid_611497 = validateParameter(valid_611497, JString, required = true,
                                 default = nil)
  if valid_611497 != nil:
    section.add "id", valid_611497
  var valid_611498 = path.getOrDefault("ingest_endpoint_id")
  valid_611498 = validateParameter(valid_611498, JString, required = true,
                                 default = nil)
  if valid_611498 != nil:
    section.add "ingest_endpoint_id", valid_611498
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
  var valid_611499 = header.getOrDefault("X-Amz-Signature")
  valid_611499 = validateParameter(valid_611499, JString, required = false,
                                 default = nil)
  if valid_611499 != nil:
    section.add "X-Amz-Signature", valid_611499
  var valid_611500 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611500 = validateParameter(valid_611500, JString, required = false,
                                 default = nil)
  if valid_611500 != nil:
    section.add "X-Amz-Content-Sha256", valid_611500
  var valid_611501 = header.getOrDefault("X-Amz-Date")
  valid_611501 = validateParameter(valid_611501, JString, required = false,
                                 default = nil)
  if valid_611501 != nil:
    section.add "X-Amz-Date", valid_611501
  var valid_611502 = header.getOrDefault("X-Amz-Credential")
  valid_611502 = validateParameter(valid_611502, JString, required = false,
                                 default = nil)
  if valid_611502 != nil:
    section.add "X-Amz-Credential", valid_611502
  var valid_611503 = header.getOrDefault("X-Amz-Security-Token")
  valid_611503 = validateParameter(valid_611503, JString, required = false,
                                 default = nil)
  if valid_611503 != nil:
    section.add "X-Amz-Security-Token", valid_611503
  var valid_611504 = header.getOrDefault("X-Amz-Algorithm")
  valid_611504 = validateParameter(valid_611504, JString, required = false,
                                 default = nil)
  if valid_611504 != nil:
    section.add "X-Amz-Algorithm", valid_611504
  var valid_611505 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611505 = validateParameter(valid_611505, JString, required = false,
                                 default = nil)
  if valid_611505 != nil:
    section.add "X-Amz-SignedHeaders", valid_611505
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611506: Call_RotateIngestEndpointCredentials_611494;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
  ## 
  let valid = call_611506.validator(path, query, header, formData, body)
  let scheme = call_611506.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611506.url(scheme.get, call_611506.host, call_611506.base,
                         call_611506.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611506, url, valid)

proc call*(call_611507: Call_RotateIngestEndpointCredentials_611494; id: string;
          ingestEndpointId: string): Recallable =
  ## rotateIngestEndpointCredentials
  ## Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
  ##   id: string (required)
  ##     : The ID of the channel the IngestEndpoint is on.
  ##   ingestEndpointId: string (required)
  ##                   : The id of the IngestEndpoint whose credentials should be rotated
  var path_611508 = newJObject()
  add(path_611508, "id", newJString(id))
  add(path_611508, "ingest_endpoint_id", newJString(ingestEndpointId))
  result = call_611507.call(path_611508, nil, nil, nil, nil)

var rotateIngestEndpointCredentials* = Call_RotateIngestEndpointCredentials_611494(
    name: "rotateIngestEndpointCredentials", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com",
    route: "/channels/{id}/ingest_endpoints/{ingest_endpoint_id}/credentials",
    validator: validate_RotateIngestEndpointCredentials_611495, base: "/",
    url: url_RotateIngestEndpointCredentials_611496,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_611509 = ref object of OpenApiRestCall_610658
proc url_UntagResource_611511(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  assert path != nil, "path is required to populate template"
  assert "resource-arn" in path, "`resource-arn` is a required path parameter"
  const
    segments = @[(kind: ConstantSegment, value: "/tags/"),
               (kind: VariableSegment, value: "resource-arn"),
               (kind: ConstantSegment, value: "#tagKeys")]
  var hydrated = hydratePath(path, segments)
  if hydrated.isNone:
    raise newException(ValueError, "unable to fully hydrate path")
  if base == "/" and hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_611510(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_611512 = path.getOrDefault("resource-arn")
  valid_611512 = validateParameter(valid_611512, JString, required = true,
                                 default = nil)
  if valid_611512 != nil:
    section.add "resource-arn", valid_611512
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key(s) of tag to be deleted
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_611513 = query.getOrDefault("tagKeys")
  valid_611513 = validateParameter(valid_611513, JArray, required = true, default = nil)
  if valid_611513 != nil:
    section.add "tagKeys", valid_611513
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
  var valid_611514 = header.getOrDefault("X-Amz-Signature")
  valid_611514 = validateParameter(valid_611514, JString, required = false,
                                 default = nil)
  if valid_611514 != nil:
    section.add "X-Amz-Signature", valid_611514
  var valid_611515 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_611515 = validateParameter(valid_611515, JString, required = false,
                                 default = nil)
  if valid_611515 != nil:
    section.add "X-Amz-Content-Sha256", valid_611515
  var valid_611516 = header.getOrDefault("X-Amz-Date")
  valid_611516 = validateParameter(valid_611516, JString, required = false,
                                 default = nil)
  if valid_611516 != nil:
    section.add "X-Amz-Date", valid_611516
  var valid_611517 = header.getOrDefault("X-Amz-Credential")
  valid_611517 = validateParameter(valid_611517, JString, required = false,
                                 default = nil)
  if valid_611517 != nil:
    section.add "X-Amz-Credential", valid_611517
  var valid_611518 = header.getOrDefault("X-Amz-Security-Token")
  valid_611518 = validateParameter(valid_611518, JString, required = false,
                                 default = nil)
  if valid_611518 != nil:
    section.add "X-Amz-Security-Token", valid_611518
  var valid_611519 = header.getOrDefault("X-Amz-Algorithm")
  valid_611519 = validateParameter(valid_611519, JString, required = false,
                                 default = nil)
  if valid_611519 != nil:
    section.add "X-Amz-Algorithm", valid_611519
  var valid_611520 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_611520 = validateParameter(valid_611520, JString, required = false,
                                 default = nil)
  if valid_611520 != nil:
    section.add "X-Amz-SignedHeaders", valid_611520
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_611521: Call_UntagResource_611509; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_611521.validator(path, query, header, formData, body)
  let scheme = call_611521.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_611521.url(scheme.get, call_611521.host, call_611521.base,
                         call_611521.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_611521, url, valid)

proc call*(call_611522: Call_UntagResource_611509; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ##   resourceArn: string (required)
  ##   tagKeys: JArray (required)
  ##          : The key(s) of tag to be deleted
  var path_611523 = newJObject()
  var query_611524 = newJObject()
  add(path_611523, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_611524.add "tagKeys", tagKeys
  result = call_611522.call(path_611523, query_611524, nil, nil, nil)

var untagResource* = Call_UntagResource_611509(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "mediapackage.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_611510,
    base: "/", url: url_UntagResource_611511, schemes: {Scheme.Https, Scheme.Http})
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
