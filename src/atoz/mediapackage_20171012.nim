
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
  Call_CreateChannel_606186 = ref object of OpenApiRestCall_605589
proc url_CreateChannel_606188(protocol: Scheme; host: string; base: string;
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

proc validate_CreateChannel_606187(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606189 = header.getOrDefault("X-Amz-Signature")
  valid_606189 = validateParameter(valid_606189, JString, required = false,
                                 default = nil)
  if valid_606189 != nil:
    section.add "X-Amz-Signature", valid_606189
  var valid_606190 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606190 = validateParameter(valid_606190, JString, required = false,
                                 default = nil)
  if valid_606190 != nil:
    section.add "X-Amz-Content-Sha256", valid_606190
  var valid_606191 = header.getOrDefault("X-Amz-Date")
  valid_606191 = validateParameter(valid_606191, JString, required = false,
                                 default = nil)
  if valid_606191 != nil:
    section.add "X-Amz-Date", valid_606191
  var valid_606192 = header.getOrDefault("X-Amz-Credential")
  valid_606192 = validateParameter(valid_606192, JString, required = false,
                                 default = nil)
  if valid_606192 != nil:
    section.add "X-Amz-Credential", valid_606192
  var valid_606193 = header.getOrDefault("X-Amz-Security-Token")
  valid_606193 = validateParameter(valid_606193, JString, required = false,
                                 default = nil)
  if valid_606193 != nil:
    section.add "X-Amz-Security-Token", valid_606193
  var valid_606194 = header.getOrDefault("X-Amz-Algorithm")
  valid_606194 = validateParameter(valid_606194, JString, required = false,
                                 default = nil)
  if valid_606194 != nil:
    section.add "X-Amz-Algorithm", valid_606194
  var valid_606195 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606195 = validateParameter(valid_606195, JString, required = false,
                                 default = nil)
  if valid_606195 != nil:
    section.add "X-Amz-SignedHeaders", valid_606195
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606197: Call_CreateChannel_606186; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Channel.
  ## 
  let valid = call_606197.validator(path, query, header, formData, body)
  let scheme = call_606197.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606197.url(scheme.get, call_606197.host, call_606197.base,
                         call_606197.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606197, url, valid)

proc call*(call_606198: Call_CreateChannel_606186; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a new Channel.
  ##   body: JObject (required)
  var body_606199 = newJObject()
  if body != nil:
    body_606199 = body
  result = call_606198.call(nil, nil, nil, nil, body_606199)

var createChannel* = Call_CreateChannel_606186(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "mediapackage.amazonaws.com",
    route: "/channels", validator: validate_CreateChannel_606187, base: "/",
    url: url_CreateChannel_606188, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_605927 = ref object of OpenApiRestCall_605589
proc url_ListChannels_605929(protocol: Scheme; host: string; base: string;
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

proc validate_ListChannels_605928(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606041 = query.getOrDefault("nextToken")
  valid_606041 = validateParameter(valid_606041, JString, required = false,
                                 default = nil)
  if valid_606041 != nil:
    section.add "nextToken", valid_606041
  var valid_606042 = query.getOrDefault("MaxResults")
  valid_606042 = validateParameter(valid_606042, JString, required = false,
                                 default = nil)
  if valid_606042 != nil:
    section.add "MaxResults", valid_606042
  var valid_606043 = query.getOrDefault("NextToken")
  valid_606043 = validateParameter(valid_606043, JString, required = false,
                                 default = nil)
  if valid_606043 != nil:
    section.add "NextToken", valid_606043
  var valid_606044 = query.getOrDefault("maxResults")
  valid_606044 = validateParameter(valid_606044, JInt, required = false, default = nil)
  if valid_606044 != nil:
    section.add "maxResults", valid_606044
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
  var valid_606045 = header.getOrDefault("X-Amz-Signature")
  valid_606045 = validateParameter(valid_606045, JString, required = false,
                                 default = nil)
  if valid_606045 != nil:
    section.add "X-Amz-Signature", valid_606045
  var valid_606046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606046 = validateParameter(valid_606046, JString, required = false,
                                 default = nil)
  if valid_606046 != nil:
    section.add "X-Amz-Content-Sha256", valid_606046
  var valid_606047 = header.getOrDefault("X-Amz-Date")
  valid_606047 = validateParameter(valid_606047, JString, required = false,
                                 default = nil)
  if valid_606047 != nil:
    section.add "X-Amz-Date", valid_606047
  var valid_606048 = header.getOrDefault("X-Amz-Credential")
  valid_606048 = validateParameter(valid_606048, JString, required = false,
                                 default = nil)
  if valid_606048 != nil:
    section.add "X-Amz-Credential", valid_606048
  var valid_606049 = header.getOrDefault("X-Amz-Security-Token")
  valid_606049 = validateParameter(valid_606049, JString, required = false,
                                 default = nil)
  if valid_606049 != nil:
    section.add "X-Amz-Security-Token", valid_606049
  var valid_606050 = header.getOrDefault("X-Amz-Algorithm")
  valid_606050 = validateParameter(valid_606050, JString, required = false,
                                 default = nil)
  if valid_606050 != nil:
    section.add "X-Amz-Algorithm", valid_606050
  var valid_606051 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606051 = validateParameter(valid_606051, JString, required = false,
                                 default = nil)
  if valid_606051 != nil:
    section.add "X-Amz-SignedHeaders", valid_606051
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606074: Call_ListChannels_605927; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of Channels.
  ## 
  let valid = call_606074.validator(path, query, header, formData, body)
  let scheme = call_606074.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606074.url(scheme.get, call_606074.host, call_606074.base,
                         call_606074.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606074, url, valid)

proc call*(call_606145: Call_ListChannels_605927; nextToken: string = "";
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
  var query_606146 = newJObject()
  add(query_606146, "nextToken", newJString(nextToken))
  add(query_606146, "MaxResults", newJString(MaxResults))
  add(query_606146, "NextToken", newJString(NextToken))
  add(query_606146, "maxResults", newJInt(maxResults))
  result = call_606145.call(nil, query_606146, nil, nil, nil)

var listChannels* = Call_ListChannels_605927(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/channels", validator: validate_ListChannels_605928, base: "/",
    url: url_ListChannels_605929, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHarvestJob_606219 = ref object of OpenApiRestCall_605589
proc url_CreateHarvestJob_606221(protocol: Scheme; host: string; base: string;
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

proc validate_CreateHarvestJob_606220(path: JsonNode; query: JsonNode;
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
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606230: Call_CreateHarvestJob_606219; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new HarvestJob record.
  ## 
  let valid = call_606230.validator(path, query, header, formData, body)
  let scheme = call_606230.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606230.url(scheme.get, call_606230.host, call_606230.base,
                         call_606230.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606230, url, valid)

proc call*(call_606231: Call_CreateHarvestJob_606219; body: JsonNode): Recallable =
  ## createHarvestJob
  ## Creates a new HarvestJob record.
  ##   body: JObject (required)
  var body_606232 = newJObject()
  if body != nil:
    body_606232 = body
  result = call_606231.call(nil, nil, nil, nil, body_606232)

var createHarvestJob* = Call_CreateHarvestJob_606219(name: "createHarvestJob",
    meth: HttpMethod.HttpPost, host: "mediapackage.amazonaws.com",
    route: "/harvest_jobs", validator: validate_CreateHarvestJob_606220, base: "/",
    url: url_CreateHarvestJob_606221, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHarvestJobs_606200 = ref object of OpenApiRestCall_605589
proc url_ListHarvestJobs_606202(protocol: Scheme; host: string; base: string;
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

proc validate_ListHarvestJobs_606201(path: JsonNode; query: JsonNode;
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
  var valid_606203 = query.getOrDefault("nextToken")
  valid_606203 = validateParameter(valid_606203, JString, required = false,
                                 default = nil)
  if valid_606203 != nil:
    section.add "nextToken", valid_606203
  var valid_606204 = query.getOrDefault("MaxResults")
  valid_606204 = validateParameter(valid_606204, JString, required = false,
                                 default = nil)
  if valid_606204 != nil:
    section.add "MaxResults", valid_606204
  var valid_606205 = query.getOrDefault("NextToken")
  valid_606205 = validateParameter(valid_606205, JString, required = false,
                                 default = nil)
  if valid_606205 != nil:
    section.add "NextToken", valid_606205
  var valid_606206 = query.getOrDefault("includeChannelId")
  valid_606206 = validateParameter(valid_606206, JString, required = false,
                                 default = nil)
  if valid_606206 != nil:
    section.add "includeChannelId", valid_606206
  var valid_606207 = query.getOrDefault("includeStatus")
  valid_606207 = validateParameter(valid_606207, JString, required = false,
                                 default = nil)
  if valid_606207 != nil:
    section.add "includeStatus", valid_606207
  var valid_606208 = query.getOrDefault("maxResults")
  valid_606208 = validateParameter(valid_606208, JInt, required = false, default = nil)
  if valid_606208 != nil:
    section.add "maxResults", valid_606208
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
  var valid_606209 = header.getOrDefault("X-Amz-Signature")
  valid_606209 = validateParameter(valid_606209, JString, required = false,
                                 default = nil)
  if valid_606209 != nil:
    section.add "X-Amz-Signature", valid_606209
  var valid_606210 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606210 = validateParameter(valid_606210, JString, required = false,
                                 default = nil)
  if valid_606210 != nil:
    section.add "X-Amz-Content-Sha256", valid_606210
  var valid_606211 = header.getOrDefault("X-Amz-Date")
  valid_606211 = validateParameter(valid_606211, JString, required = false,
                                 default = nil)
  if valid_606211 != nil:
    section.add "X-Amz-Date", valid_606211
  var valid_606212 = header.getOrDefault("X-Amz-Credential")
  valid_606212 = validateParameter(valid_606212, JString, required = false,
                                 default = nil)
  if valid_606212 != nil:
    section.add "X-Amz-Credential", valid_606212
  var valid_606213 = header.getOrDefault("X-Amz-Security-Token")
  valid_606213 = validateParameter(valid_606213, JString, required = false,
                                 default = nil)
  if valid_606213 != nil:
    section.add "X-Amz-Security-Token", valid_606213
  var valid_606214 = header.getOrDefault("X-Amz-Algorithm")
  valid_606214 = validateParameter(valid_606214, JString, required = false,
                                 default = nil)
  if valid_606214 != nil:
    section.add "X-Amz-Algorithm", valid_606214
  var valid_606215 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606215 = validateParameter(valid_606215, JString, required = false,
                                 default = nil)
  if valid_606215 != nil:
    section.add "X-Amz-SignedHeaders", valid_606215
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606216: Call_ListHarvestJobs_606200; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of HarvestJob records.
  ## 
  let valid = call_606216.validator(path, query, header, formData, body)
  let scheme = call_606216.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606216.url(scheme.get, call_606216.host, call_606216.base,
                         call_606216.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606216, url, valid)

proc call*(call_606217: Call_ListHarvestJobs_606200; nextToken: string = "";
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
  var query_606218 = newJObject()
  add(query_606218, "nextToken", newJString(nextToken))
  add(query_606218, "MaxResults", newJString(MaxResults))
  add(query_606218, "NextToken", newJString(NextToken))
  add(query_606218, "includeChannelId", newJString(includeChannelId))
  add(query_606218, "includeStatus", newJString(includeStatus))
  add(query_606218, "maxResults", newJInt(maxResults))
  result = call_606217.call(nil, query_606218, nil, nil, nil)

var listHarvestJobs* = Call_ListHarvestJobs_606200(name: "listHarvestJobs",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/harvest_jobs", validator: validate_ListHarvestJobs_606201, base: "/",
    url: url_ListHarvestJobs_606202, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOriginEndpoint_606251 = ref object of OpenApiRestCall_605589
proc url_CreateOriginEndpoint_606253(protocol: Scheme; host: string; base: string;
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

proc validate_CreateOriginEndpoint_606252(path: JsonNode; query: JsonNode;
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
  var valid_606254 = header.getOrDefault("X-Amz-Signature")
  valid_606254 = validateParameter(valid_606254, JString, required = false,
                                 default = nil)
  if valid_606254 != nil:
    section.add "X-Amz-Signature", valid_606254
  var valid_606255 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606255 = validateParameter(valid_606255, JString, required = false,
                                 default = nil)
  if valid_606255 != nil:
    section.add "X-Amz-Content-Sha256", valid_606255
  var valid_606256 = header.getOrDefault("X-Amz-Date")
  valid_606256 = validateParameter(valid_606256, JString, required = false,
                                 default = nil)
  if valid_606256 != nil:
    section.add "X-Amz-Date", valid_606256
  var valid_606257 = header.getOrDefault("X-Amz-Credential")
  valid_606257 = validateParameter(valid_606257, JString, required = false,
                                 default = nil)
  if valid_606257 != nil:
    section.add "X-Amz-Credential", valid_606257
  var valid_606258 = header.getOrDefault("X-Amz-Security-Token")
  valid_606258 = validateParameter(valid_606258, JString, required = false,
                                 default = nil)
  if valid_606258 != nil:
    section.add "X-Amz-Security-Token", valid_606258
  var valid_606259 = header.getOrDefault("X-Amz-Algorithm")
  valid_606259 = validateParameter(valid_606259, JString, required = false,
                                 default = nil)
  if valid_606259 != nil:
    section.add "X-Amz-Algorithm", valid_606259
  var valid_606260 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606260 = validateParameter(valid_606260, JString, required = false,
                                 default = nil)
  if valid_606260 != nil:
    section.add "X-Amz-SignedHeaders", valid_606260
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606262: Call_CreateOriginEndpoint_606251; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new OriginEndpoint record.
  ## 
  let valid = call_606262.validator(path, query, header, formData, body)
  let scheme = call_606262.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606262.url(scheme.get, call_606262.host, call_606262.base,
                         call_606262.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606262, url, valid)

proc call*(call_606263: Call_CreateOriginEndpoint_606251; body: JsonNode): Recallable =
  ## createOriginEndpoint
  ## Creates a new OriginEndpoint record.
  ##   body: JObject (required)
  var body_606264 = newJObject()
  if body != nil:
    body_606264 = body
  result = call_606263.call(nil, nil, nil, nil, body_606264)

var createOriginEndpoint* = Call_CreateOriginEndpoint_606251(
    name: "createOriginEndpoint", meth: HttpMethod.HttpPost,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints",
    validator: validate_CreateOriginEndpoint_606252, base: "/",
    url: url_CreateOriginEndpoint_606253, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOriginEndpoints_606233 = ref object of OpenApiRestCall_605589
proc url_ListOriginEndpoints_606235(protocol: Scheme; host: string; base: string;
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

proc validate_ListOriginEndpoints_606234(path: JsonNode; query: JsonNode;
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
  var valid_606236 = query.getOrDefault("nextToken")
  valid_606236 = validateParameter(valid_606236, JString, required = false,
                                 default = nil)
  if valid_606236 != nil:
    section.add "nextToken", valid_606236
  var valid_606237 = query.getOrDefault("MaxResults")
  valid_606237 = validateParameter(valid_606237, JString, required = false,
                                 default = nil)
  if valid_606237 != nil:
    section.add "MaxResults", valid_606237
  var valid_606238 = query.getOrDefault("NextToken")
  valid_606238 = validateParameter(valid_606238, JString, required = false,
                                 default = nil)
  if valid_606238 != nil:
    section.add "NextToken", valid_606238
  var valid_606239 = query.getOrDefault("channelId")
  valid_606239 = validateParameter(valid_606239, JString, required = false,
                                 default = nil)
  if valid_606239 != nil:
    section.add "channelId", valid_606239
  var valid_606240 = query.getOrDefault("maxResults")
  valid_606240 = validateParameter(valid_606240, JInt, required = false, default = nil)
  if valid_606240 != nil:
    section.add "maxResults", valid_606240
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
  var valid_606241 = header.getOrDefault("X-Amz-Signature")
  valid_606241 = validateParameter(valid_606241, JString, required = false,
                                 default = nil)
  if valid_606241 != nil:
    section.add "X-Amz-Signature", valid_606241
  var valid_606242 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606242 = validateParameter(valid_606242, JString, required = false,
                                 default = nil)
  if valid_606242 != nil:
    section.add "X-Amz-Content-Sha256", valid_606242
  var valid_606243 = header.getOrDefault("X-Amz-Date")
  valid_606243 = validateParameter(valid_606243, JString, required = false,
                                 default = nil)
  if valid_606243 != nil:
    section.add "X-Amz-Date", valid_606243
  var valid_606244 = header.getOrDefault("X-Amz-Credential")
  valid_606244 = validateParameter(valid_606244, JString, required = false,
                                 default = nil)
  if valid_606244 != nil:
    section.add "X-Amz-Credential", valid_606244
  var valid_606245 = header.getOrDefault("X-Amz-Security-Token")
  valid_606245 = validateParameter(valid_606245, JString, required = false,
                                 default = nil)
  if valid_606245 != nil:
    section.add "X-Amz-Security-Token", valid_606245
  var valid_606246 = header.getOrDefault("X-Amz-Algorithm")
  valid_606246 = validateParameter(valid_606246, JString, required = false,
                                 default = nil)
  if valid_606246 != nil:
    section.add "X-Amz-Algorithm", valid_606246
  var valid_606247 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606247 = validateParameter(valid_606247, JString, required = false,
                                 default = nil)
  if valid_606247 != nil:
    section.add "X-Amz-SignedHeaders", valid_606247
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606248: Call_ListOriginEndpoints_606233; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of OriginEndpoint records.
  ## 
  let valid = call_606248.validator(path, query, header, formData, body)
  let scheme = call_606248.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606248.url(scheme.get, call_606248.host, call_606248.base,
                         call_606248.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606248, url, valid)

proc call*(call_606249: Call_ListOriginEndpoints_606233; nextToken: string = "";
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
  var query_606250 = newJObject()
  add(query_606250, "nextToken", newJString(nextToken))
  add(query_606250, "MaxResults", newJString(MaxResults))
  add(query_606250, "NextToken", newJString(NextToken))
  add(query_606250, "channelId", newJString(channelId))
  add(query_606250, "maxResults", newJInt(maxResults))
  result = call_606249.call(nil, query_606250, nil, nil, nil)

var listOriginEndpoints* = Call_ListOriginEndpoints_606233(
    name: "listOriginEndpoints", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints",
    validator: validate_ListOriginEndpoints_606234, base: "/",
    url: url_ListOriginEndpoints_606235, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_606293 = ref object of OpenApiRestCall_605589
proc url_UpdateChannel_606295(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateChannel_606294(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606296 = path.getOrDefault("id")
  valid_606296 = validateParameter(valid_606296, JString, required = true,
                                 default = nil)
  if valid_606296 != nil:
    section.add "id", valid_606296
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
  var valid_606297 = header.getOrDefault("X-Amz-Signature")
  valid_606297 = validateParameter(valid_606297, JString, required = false,
                                 default = nil)
  if valid_606297 != nil:
    section.add "X-Amz-Signature", valid_606297
  var valid_606298 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606298 = validateParameter(valid_606298, JString, required = false,
                                 default = nil)
  if valid_606298 != nil:
    section.add "X-Amz-Content-Sha256", valid_606298
  var valid_606299 = header.getOrDefault("X-Amz-Date")
  valid_606299 = validateParameter(valid_606299, JString, required = false,
                                 default = nil)
  if valid_606299 != nil:
    section.add "X-Amz-Date", valid_606299
  var valid_606300 = header.getOrDefault("X-Amz-Credential")
  valid_606300 = validateParameter(valid_606300, JString, required = false,
                                 default = nil)
  if valid_606300 != nil:
    section.add "X-Amz-Credential", valid_606300
  var valid_606301 = header.getOrDefault("X-Amz-Security-Token")
  valid_606301 = validateParameter(valid_606301, JString, required = false,
                                 default = nil)
  if valid_606301 != nil:
    section.add "X-Amz-Security-Token", valid_606301
  var valid_606302 = header.getOrDefault("X-Amz-Algorithm")
  valid_606302 = validateParameter(valid_606302, JString, required = false,
                                 default = nil)
  if valid_606302 != nil:
    section.add "X-Amz-Algorithm", valid_606302
  var valid_606303 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606303 = validateParameter(valid_606303, JString, required = false,
                                 default = nil)
  if valid_606303 != nil:
    section.add "X-Amz-SignedHeaders", valid_606303
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606305: Call_UpdateChannel_606293; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing Channel.
  ## 
  let valid = call_606305.validator(path, query, header, formData, body)
  let scheme = call_606305.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606305.url(scheme.get, call_606305.host, call_606305.base,
                         call_606305.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606305, url, valid)

proc call*(call_606306: Call_UpdateChannel_606293; id: string; body: JsonNode): Recallable =
  ## updateChannel
  ## Updates an existing Channel.
  ##   id: string (required)
  ##     : The ID of the Channel to update.
  ##   body: JObject (required)
  var path_606307 = newJObject()
  var body_606308 = newJObject()
  add(path_606307, "id", newJString(id))
  if body != nil:
    body_606308 = body
  result = call_606306.call(path_606307, nil, nil, nil, body_606308)

var updateChannel* = Call_UpdateChannel_606293(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_UpdateChannel_606294, base: "/",
    url: url_UpdateChannel_606295, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_606265 = ref object of OpenApiRestCall_605589
proc url_DescribeChannel_606267(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeChannel_606266(path: JsonNode; query: JsonNode;
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
  var valid_606282 = path.getOrDefault("id")
  valid_606282 = validateParameter(valid_606282, JString, required = true,
                                 default = nil)
  if valid_606282 != nil:
    section.add "id", valid_606282
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
  if body != nil:
    result.add "body", body

proc call*(call_606290: Call_DescribeChannel_606265; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a Channel.
  ## 
  let valid = call_606290.validator(path, query, header, formData, body)
  let scheme = call_606290.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606290.url(scheme.get, call_606290.host, call_606290.base,
                         call_606290.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606290, url, valid)

proc call*(call_606291: Call_DescribeChannel_606265; id: string): Recallable =
  ## describeChannel
  ## Gets details about a Channel.
  ##   id: string (required)
  ##     : The ID of a Channel.
  var path_606292 = newJObject()
  add(path_606292, "id", newJString(id))
  result = call_606291.call(path_606292, nil, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_606265(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_DescribeChannel_606266, base: "/",
    url: url_DescribeChannel_606267, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_606309 = ref object of OpenApiRestCall_605589
proc url_DeleteChannel_606311(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteChannel_606310(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_606312 = path.getOrDefault("id")
  valid_606312 = validateParameter(valid_606312, JString, required = true,
                                 default = nil)
  if valid_606312 != nil:
    section.add "id", valid_606312
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
  var valid_606313 = header.getOrDefault("X-Amz-Signature")
  valid_606313 = validateParameter(valid_606313, JString, required = false,
                                 default = nil)
  if valid_606313 != nil:
    section.add "X-Amz-Signature", valid_606313
  var valid_606314 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606314 = validateParameter(valid_606314, JString, required = false,
                                 default = nil)
  if valid_606314 != nil:
    section.add "X-Amz-Content-Sha256", valid_606314
  var valid_606315 = header.getOrDefault("X-Amz-Date")
  valid_606315 = validateParameter(valid_606315, JString, required = false,
                                 default = nil)
  if valid_606315 != nil:
    section.add "X-Amz-Date", valid_606315
  var valid_606316 = header.getOrDefault("X-Amz-Credential")
  valid_606316 = validateParameter(valid_606316, JString, required = false,
                                 default = nil)
  if valid_606316 != nil:
    section.add "X-Amz-Credential", valid_606316
  var valid_606317 = header.getOrDefault("X-Amz-Security-Token")
  valid_606317 = validateParameter(valid_606317, JString, required = false,
                                 default = nil)
  if valid_606317 != nil:
    section.add "X-Amz-Security-Token", valid_606317
  var valid_606318 = header.getOrDefault("X-Amz-Algorithm")
  valid_606318 = validateParameter(valid_606318, JString, required = false,
                                 default = nil)
  if valid_606318 != nil:
    section.add "X-Amz-Algorithm", valid_606318
  var valid_606319 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606319 = validateParameter(valid_606319, JString, required = false,
                                 default = nil)
  if valid_606319 != nil:
    section.add "X-Amz-SignedHeaders", valid_606319
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606320: Call_DeleteChannel_606309; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing Channel.
  ## 
  let valid = call_606320.validator(path, query, header, formData, body)
  let scheme = call_606320.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606320.url(scheme.get, call_606320.host, call_606320.base,
                         call_606320.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606320, url, valid)

proc call*(call_606321: Call_DeleteChannel_606309; id: string): Recallable =
  ## deleteChannel
  ## Deletes an existing Channel.
  ##   id: string (required)
  ##     : The ID of the Channel to delete.
  var path_606322 = newJObject()
  add(path_606322, "id", newJString(id))
  result = call_606321.call(path_606322, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_606309(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_DeleteChannel_606310, base: "/",
    url: url_DeleteChannel_606311, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOriginEndpoint_606337 = ref object of OpenApiRestCall_605589
proc url_UpdateOriginEndpoint_606339(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UpdateOriginEndpoint_606338(path: JsonNode; query: JsonNode;
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
  var valid_606340 = path.getOrDefault("id")
  valid_606340 = validateParameter(valid_606340, JString, required = true,
                                 default = nil)
  if valid_606340 != nil:
    section.add "id", valid_606340
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
  var valid_606341 = header.getOrDefault("X-Amz-Signature")
  valid_606341 = validateParameter(valid_606341, JString, required = false,
                                 default = nil)
  if valid_606341 != nil:
    section.add "X-Amz-Signature", valid_606341
  var valid_606342 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606342 = validateParameter(valid_606342, JString, required = false,
                                 default = nil)
  if valid_606342 != nil:
    section.add "X-Amz-Content-Sha256", valid_606342
  var valid_606343 = header.getOrDefault("X-Amz-Date")
  valid_606343 = validateParameter(valid_606343, JString, required = false,
                                 default = nil)
  if valid_606343 != nil:
    section.add "X-Amz-Date", valid_606343
  var valid_606344 = header.getOrDefault("X-Amz-Credential")
  valid_606344 = validateParameter(valid_606344, JString, required = false,
                                 default = nil)
  if valid_606344 != nil:
    section.add "X-Amz-Credential", valid_606344
  var valid_606345 = header.getOrDefault("X-Amz-Security-Token")
  valid_606345 = validateParameter(valid_606345, JString, required = false,
                                 default = nil)
  if valid_606345 != nil:
    section.add "X-Amz-Security-Token", valid_606345
  var valid_606346 = header.getOrDefault("X-Amz-Algorithm")
  valid_606346 = validateParameter(valid_606346, JString, required = false,
                                 default = nil)
  if valid_606346 != nil:
    section.add "X-Amz-Algorithm", valid_606346
  var valid_606347 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606347 = validateParameter(valid_606347, JString, required = false,
                                 default = nil)
  if valid_606347 != nil:
    section.add "X-Amz-SignedHeaders", valid_606347
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606349: Call_UpdateOriginEndpoint_606337; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing OriginEndpoint.
  ## 
  let valid = call_606349.validator(path, query, header, formData, body)
  let scheme = call_606349.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606349.url(scheme.get, call_606349.host, call_606349.base,
                         call_606349.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606349, url, valid)

proc call*(call_606350: Call_UpdateOriginEndpoint_606337; id: string; body: JsonNode): Recallable =
  ## updateOriginEndpoint
  ## Updates an existing OriginEndpoint.
  ##   id: string (required)
  ##     : The ID of the OriginEndpoint to update.
  ##   body: JObject (required)
  var path_606351 = newJObject()
  var body_606352 = newJObject()
  add(path_606351, "id", newJString(id))
  if body != nil:
    body_606352 = body
  result = call_606350.call(path_606351, nil, nil, nil, body_606352)

var updateOriginEndpoint* = Call_UpdateOriginEndpoint_606337(
    name: "updateOriginEndpoint", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_UpdateOriginEndpoint_606338, base: "/",
    url: url_UpdateOriginEndpoint_606339, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOriginEndpoint_606323 = ref object of OpenApiRestCall_605589
proc url_DescribeOriginEndpoint_606325(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeOriginEndpoint_606324(path: JsonNode; query: JsonNode;
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
  var valid_606326 = path.getOrDefault("id")
  valid_606326 = validateParameter(valid_606326, JString, required = true,
                                 default = nil)
  if valid_606326 != nil:
    section.add "id", valid_606326
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
  var valid_606327 = header.getOrDefault("X-Amz-Signature")
  valid_606327 = validateParameter(valid_606327, JString, required = false,
                                 default = nil)
  if valid_606327 != nil:
    section.add "X-Amz-Signature", valid_606327
  var valid_606328 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606328 = validateParameter(valid_606328, JString, required = false,
                                 default = nil)
  if valid_606328 != nil:
    section.add "X-Amz-Content-Sha256", valid_606328
  var valid_606329 = header.getOrDefault("X-Amz-Date")
  valid_606329 = validateParameter(valid_606329, JString, required = false,
                                 default = nil)
  if valid_606329 != nil:
    section.add "X-Amz-Date", valid_606329
  var valid_606330 = header.getOrDefault("X-Amz-Credential")
  valid_606330 = validateParameter(valid_606330, JString, required = false,
                                 default = nil)
  if valid_606330 != nil:
    section.add "X-Amz-Credential", valid_606330
  var valid_606331 = header.getOrDefault("X-Amz-Security-Token")
  valid_606331 = validateParameter(valid_606331, JString, required = false,
                                 default = nil)
  if valid_606331 != nil:
    section.add "X-Amz-Security-Token", valid_606331
  var valid_606332 = header.getOrDefault("X-Amz-Algorithm")
  valid_606332 = validateParameter(valid_606332, JString, required = false,
                                 default = nil)
  if valid_606332 != nil:
    section.add "X-Amz-Algorithm", valid_606332
  var valid_606333 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606333 = validateParameter(valid_606333, JString, required = false,
                                 default = nil)
  if valid_606333 != nil:
    section.add "X-Amz-SignedHeaders", valid_606333
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606334: Call_DescribeOriginEndpoint_606323; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about an existing OriginEndpoint.
  ## 
  let valid = call_606334.validator(path, query, header, formData, body)
  let scheme = call_606334.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606334.url(scheme.get, call_606334.host, call_606334.base,
                         call_606334.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606334, url, valid)

proc call*(call_606335: Call_DescribeOriginEndpoint_606323; id: string): Recallable =
  ## describeOriginEndpoint
  ## Gets details about an existing OriginEndpoint.
  ##   id: string (required)
  ##     : The ID of the OriginEndpoint.
  var path_606336 = newJObject()
  add(path_606336, "id", newJString(id))
  result = call_606335.call(path_606336, nil, nil, nil, nil)

var describeOriginEndpoint* = Call_DescribeOriginEndpoint_606323(
    name: "describeOriginEndpoint", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_DescribeOriginEndpoint_606324, base: "/",
    url: url_DescribeOriginEndpoint_606325, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOriginEndpoint_606353 = ref object of OpenApiRestCall_605589
proc url_DeleteOriginEndpoint_606355(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DeleteOriginEndpoint_606354(path: JsonNode; query: JsonNode;
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
  var valid_606356 = path.getOrDefault("id")
  valid_606356 = validateParameter(valid_606356, JString, required = true,
                                 default = nil)
  if valid_606356 != nil:
    section.add "id", valid_606356
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
  var valid_606357 = header.getOrDefault("X-Amz-Signature")
  valid_606357 = validateParameter(valid_606357, JString, required = false,
                                 default = nil)
  if valid_606357 != nil:
    section.add "X-Amz-Signature", valid_606357
  var valid_606358 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606358 = validateParameter(valid_606358, JString, required = false,
                                 default = nil)
  if valid_606358 != nil:
    section.add "X-Amz-Content-Sha256", valid_606358
  var valid_606359 = header.getOrDefault("X-Amz-Date")
  valid_606359 = validateParameter(valid_606359, JString, required = false,
                                 default = nil)
  if valid_606359 != nil:
    section.add "X-Amz-Date", valid_606359
  var valid_606360 = header.getOrDefault("X-Amz-Credential")
  valid_606360 = validateParameter(valid_606360, JString, required = false,
                                 default = nil)
  if valid_606360 != nil:
    section.add "X-Amz-Credential", valid_606360
  var valid_606361 = header.getOrDefault("X-Amz-Security-Token")
  valid_606361 = validateParameter(valid_606361, JString, required = false,
                                 default = nil)
  if valid_606361 != nil:
    section.add "X-Amz-Security-Token", valid_606361
  var valid_606362 = header.getOrDefault("X-Amz-Algorithm")
  valid_606362 = validateParameter(valid_606362, JString, required = false,
                                 default = nil)
  if valid_606362 != nil:
    section.add "X-Amz-Algorithm", valid_606362
  var valid_606363 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606363 = validateParameter(valid_606363, JString, required = false,
                                 default = nil)
  if valid_606363 != nil:
    section.add "X-Amz-SignedHeaders", valid_606363
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606364: Call_DeleteOriginEndpoint_606353; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing OriginEndpoint.
  ## 
  let valid = call_606364.validator(path, query, header, formData, body)
  let scheme = call_606364.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606364.url(scheme.get, call_606364.host, call_606364.base,
                         call_606364.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606364, url, valid)

proc call*(call_606365: Call_DeleteOriginEndpoint_606353; id: string): Recallable =
  ## deleteOriginEndpoint
  ## Deletes an existing OriginEndpoint.
  ##   id: string (required)
  ##     : The ID of the OriginEndpoint to delete.
  var path_606366 = newJObject()
  add(path_606366, "id", newJString(id))
  result = call_606365.call(path_606366, nil, nil, nil, nil)

var deleteOriginEndpoint* = Call_DeleteOriginEndpoint_606353(
    name: "deleteOriginEndpoint", meth: HttpMethod.HttpDelete,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_DeleteOriginEndpoint_606354, base: "/",
    url: url_DeleteOriginEndpoint_606355, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHarvestJob_606367 = ref object of OpenApiRestCall_605589
proc url_DescribeHarvestJob_606369(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_DescribeHarvestJob_606368(path: JsonNode; query: JsonNode;
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
  var valid_606370 = path.getOrDefault("id")
  valid_606370 = validateParameter(valid_606370, JString, required = true,
                                 default = nil)
  if valid_606370 != nil:
    section.add "id", valid_606370
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
  var valid_606371 = header.getOrDefault("X-Amz-Signature")
  valid_606371 = validateParameter(valid_606371, JString, required = false,
                                 default = nil)
  if valid_606371 != nil:
    section.add "X-Amz-Signature", valid_606371
  var valid_606372 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606372 = validateParameter(valid_606372, JString, required = false,
                                 default = nil)
  if valid_606372 != nil:
    section.add "X-Amz-Content-Sha256", valid_606372
  var valid_606373 = header.getOrDefault("X-Amz-Date")
  valid_606373 = validateParameter(valid_606373, JString, required = false,
                                 default = nil)
  if valid_606373 != nil:
    section.add "X-Amz-Date", valid_606373
  var valid_606374 = header.getOrDefault("X-Amz-Credential")
  valid_606374 = validateParameter(valid_606374, JString, required = false,
                                 default = nil)
  if valid_606374 != nil:
    section.add "X-Amz-Credential", valid_606374
  var valid_606375 = header.getOrDefault("X-Amz-Security-Token")
  valid_606375 = validateParameter(valid_606375, JString, required = false,
                                 default = nil)
  if valid_606375 != nil:
    section.add "X-Amz-Security-Token", valid_606375
  var valid_606376 = header.getOrDefault("X-Amz-Algorithm")
  valid_606376 = validateParameter(valid_606376, JString, required = false,
                                 default = nil)
  if valid_606376 != nil:
    section.add "X-Amz-Algorithm", valid_606376
  var valid_606377 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606377 = validateParameter(valid_606377, JString, required = false,
                                 default = nil)
  if valid_606377 != nil:
    section.add "X-Amz-SignedHeaders", valid_606377
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606378: Call_DescribeHarvestJob_606367; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about an existing HarvestJob.
  ## 
  let valid = call_606378.validator(path, query, header, formData, body)
  let scheme = call_606378.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606378.url(scheme.get, call_606378.host, call_606378.base,
                         call_606378.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606378, url, valid)

proc call*(call_606379: Call_DescribeHarvestJob_606367; id: string): Recallable =
  ## describeHarvestJob
  ## Gets details about an existing HarvestJob.
  ##   id: string (required)
  ##     : The ID of the HarvestJob.
  var path_606380 = newJObject()
  add(path_606380, "id", newJString(id))
  result = call_606379.call(path_606380, nil, nil, nil, nil)

var describeHarvestJob* = Call_DescribeHarvestJob_606367(
    name: "describeHarvestJob", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/harvest_jobs/{id}",
    validator: validate_DescribeHarvestJob_606368, base: "/",
    url: url_DescribeHarvestJob_606369, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_606395 = ref object of OpenApiRestCall_605589
proc url_TagResource_606397(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_TagResource_606396(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_606398 = path.getOrDefault("resource-arn")
  valid_606398 = validateParameter(valid_606398, JString, required = true,
                                 default = nil)
  if valid_606398 != nil:
    section.add "resource-arn", valid_606398
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
  var valid_606399 = header.getOrDefault("X-Amz-Signature")
  valid_606399 = validateParameter(valid_606399, JString, required = false,
                                 default = nil)
  if valid_606399 != nil:
    section.add "X-Amz-Signature", valid_606399
  var valid_606400 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606400 = validateParameter(valid_606400, JString, required = false,
                                 default = nil)
  if valid_606400 != nil:
    section.add "X-Amz-Content-Sha256", valid_606400
  var valid_606401 = header.getOrDefault("X-Amz-Date")
  valid_606401 = validateParameter(valid_606401, JString, required = false,
                                 default = nil)
  if valid_606401 != nil:
    section.add "X-Amz-Date", valid_606401
  var valid_606402 = header.getOrDefault("X-Amz-Credential")
  valid_606402 = validateParameter(valid_606402, JString, required = false,
                                 default = nil)
  if valid_606402 != nil:
    section.add "X-Amz-Credential", valid_606402
  var valid_606403 = header.getOrDefault("X-Amz-Security-Token")
  valid_606403 = validateParameter(valid_606403, JString, required = false,
                                 default = nil)
  if valid_606403 != nil:
    section.add "X-Amz-Security-Token", valid_606403
  var valid_606404 = header.getOrDefault("X-Amz-Algorithm")
  valid_606404 = validateParameter(valid_606404, JString, required = false,
                                 default = nil)
  if valid_606404 != nil:
    section.add "X-Amz-Algorithm", valid_606404
  var valid_606405 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606405 = validateParameter(valid_606405, JString, required = false,
                                 default = nil)
  if valid_606405 != nil:
    section.add "X-Amz-SignedHeaders", valid_606405
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_606407: Call_TagResource_606395; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606407.validator(path, query, header, formData, body)
  let scheme = call_606407.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606407.url(scheme.get, call_606407.host, call_606407.base,
                         call_606407.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606407, url, valid)

proc call*(call_606408: Call_TagResource_606395; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ##   resourceArn: string (required)
  ##   body: JObject (required)
  var path_606409 = newJObject()
  var body_606410 = newJObject()
  add(path_606409, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_606410 = body
  result = call_606408.call(path_606409, nil, nil, nil, body_606410)

var tagResource* = Call_TagResource_606395(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediapackage.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_606396,
                                        base: "/", url: url_TagResource_606397,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_606381 = ref object of OpenApiRestCall_605589
proc url_ListTagsForResource_606383(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_ListTagsForResource_606382(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_606384 = path.getOrDefault("resource-arn")
  valid_606384 = validateParameter(valid_606384, JString, required = true,
                                 default = nil)
  if valid_606384 != nil:
    section.add "resource-arn", valid_606384
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
  var valid_606385 = header.getOrDefault("X-Amz-Signature")
  valid_606385 = validateParameter(valid_606385, JString, required = false,
                                 default = nil)
  if valid_606385 != nil:
    section.add "X-Amz-Signature", valid_606385
  var valid_606386 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606386 = validateParameter(valid_606386, JString, required = false,
                                 default = nil)
  if valid_606386 != nil:
    section.add "X-Amz-Content-Sha256", valid_606386
  var valid_606387 = header.getOrDefault("X-Amz-Date")
  valid_606387 = validateParameter(valid_606387, JString, required = false,
                                 default = nil)
  if valid_606387 != nil:
    section.add "X-Amz-Date", valid_606387
  var valid_606388 = header.getOrDefault("X-Amz-Credential")
  valid_606388 = validateParameter(valid_606388, JString, required = false,
                                 default = nil)
  if valid_606388 != nil:
    section.add "X-Amz-Credential", valid_606388
  var valid_606389 = header.getOrDefault("X-Amz-Security-Token")
  valid_606389 = validateParameter(valid_606389, JString, required = false,
                                 default = nil)
  if valid_606389 != nil:
    section.add "X-Amz-Security-Token", valid_606389
  var valid_606390 = header.getOrDefault("X-Amz-Algorithm")
  valid_606390 = validateParameter(valid_606390, JString, required = false,
                                 default = nil)
  if valid_606390 != nil:
    section.add "X-Amz-Algorithm", valid_606390
  var valid_606391 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606391 = validateParameter(valid_606391, JString, required = false,
                                 default = nil)
  if valid_606391 != nil:
    section.add "X-Amz-SignedHeaders", valid_606391
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606392: Call_ListTagsForResource_606381; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606392.validator(path, query, header, formData, body)
  let scheme = call_606392.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606392.url(scheme.get, call_606392.host, call_606392.base,
                         call_606392.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606392, url, valid)

proc call*(call_606393: Call_ListTagsForResource_606381; resourceArn: string): Recallable =
  ## listTagsForResource
  ##   resourceArn: string (required)
  var path_606394 = newJObject()
  add(path_606394, "resource-arn", newJString(resourceArn))
  result = call_606393.call(path_606394, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_606381(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_606382, base: "/",
    url: url_ListTagsForResource_606383, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RotateChannelCredentials_606411 = ref object of OpenApiRestCall_605589
proc url_RotateChannelCredentials_606413(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RotateChannelCredentials_606412(path: JsonNode; query: JsonNode;
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
  var valid_606414 = path.getOrDefault("id")
  valid_606414 = validateParameter(valid_606414, JString, required = true,
                                 default = nil)
  if valid_606414 != nil:
    section.add "id", valid_606414
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
  var valid_606415 = header.getOrDefault("X-Amz-Signature")
  valid_606415 = validateParameter(valid_606415, JString, required = false,
                                 default = nil)
  if valid_606415 != nil:
    section.add "X-Amz-Signature", valid_606415
  var valid_606416 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606416 = validateParameter(valid_606416, JString, required = false,
                                 default = nil)
  if valid_606416 != nil:
    section.add "X-Amz-Content-Sha256", valid_606416
  var valid_606417 = header.getOrDefault("X-Amz-Date")
  valid_606417 = validateParameter(valid_606417, JString, required = false,
                                 default = nil)
  if valid_606417 != nil:
    section.add "X-Amz-Date", valid_606417
  var valid_606418 = header.getOrDefault("X-Amz-Credential")
  valid_606418 = validateParameter(valid_606418, JString, required = false,
                                 default = nil)
  if valid_606418 != nil:
    section.add "X-Amz-Credential", valid_606418
  var valid_606419 = header.getOrDefault("X-Amz-Security-Token")
  valid_606419 = validateParameter(valid_606419, JString, required = false,
                                 default = nil)
  if valid_606419 != nil:
    section.add "X-Amz-Security-Token", valid_606419
  var valid_606420 = header.getOrDefault("X-Amz-Algorithm")
  valid_606420 = validateParameter(valid_606420, JString, required = false,
                                 default = nil)
  if valid_606420 != nil:
    section.add "X-Amz-Algorithm", valid_606420
  var valid_606421 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606421 = validateParameter(valid_606421, JString, required = false,
                                 default = nil)
  if valid_606421 != nil:
    section.add "X-Amz-SignedHeaders", valid_606421
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606422: Call_RotateChannelCredentials_606411; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
  ## 
  let valid = call_606422.validator(path, query, header, formData, body)
  let scheme = call_606422.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606422.url(scheme.get, call_606422.host, call_606422.base,
                         call_606422.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606422, url, valid)

proc call*(call_606423: Call_RotateChannelCredentials_606411; id: string): Recallable =
  ## rotateChannelCredentials
  ## Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
  ##   id: string (required)
  ##     : The ID of the channel to update.
  var path_606424 = newJObject()
  add(path_606424, "id", newJString(id))
  result = call_606423.call(path_606424, nil, nil, nil, nil)

var rotateChannelCredentials* = Call_RotateChannelCredentials_606411(
    name: "rotateChannelCredentials", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com", route: "/channels/{id}/credentials",
    validator: validate_RotateChannelCredentials_606412, base: "/",
    url: url_RotateChannelCredentials_606413, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RotateIngestEndpointCredentials_606425 = ref object of OpenApiRestCall_605589
proc url_RotateIngestEndpointCredentials_606427(protocol: Scheme; host: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_RotateIngestEndpointCredentials_606426(path: JsonNode;
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
  var valid_606428 = path.getOrDefault("id")
  valid_606428 = validateParameter(valid_606428, JString, required = true,
                                 default = nil)
  if valid_606428 != nil:
    section.add "id", valid_606428
  var valid_606429 = path.getOrDefault("ingest_endpoint_id")
  valid_606429 = validateParameter(valid_606429, JString, required = true,
                                 default = nil)
  if valid_606429 != nil:
    section.add "ingest_endpoint_id", valid_606429
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
  var valid_606430 = header.getOrDefault("X-Amz-Signature")
  valid_606430 = validateParameter(valid_606430, JString, required = false,
                                 default = nil)
  if valid_606430 != nil:
    section.add "X-Amz-Signature", valid_606430
  var valid_606431 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606431 = validateParameter(valid_606431, JString, required = false,
                                 default = nil)
  if valid_606431 != nil:
    section.add "X-Amz-Content-Sha256", valid_606431
  var valid_606432 = header.getOrDefault("X-Amz-Date")
  valid_606432 = validateParameter(valid_606432, JString, required = false,
                                 default = nil)
  if valid_606432 != nil:
    section.add "X-Amz-Date", valid_606432
  var valid_606433 = header.getOrDefault("X-Amz-Credential")
  valid_606433 = validateParameter(valid_606433, JString, required = false,
                                 default = nil)
  if valid_606433 != nil:
    section.add "X-Amz-Credential", valid_606433
  var valid_606434 = header.getOrDefault("X-Amz-Security-Token")
  valid_606434 = validateParameter(valid_606434, JString, required = false,
                                 default = nil)
  if valid_606434 != nil:
    section.add "X-Amz-Security-Token", valid_606434
  var valid_606435 = header.getOrDefault("X-Amz-Algorithm")
  valid_606435 = validateParameter(valid_606435, JString, required = false,
                                 default = nil)
  if valid_606435 != nil:
    section.add "X-Amz-Algorithm", valid_606435
  var valid_606436 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606436 = validateParameter(valid_606436, JString, required = false,
                                 default = nil)
  if valid_606436 != nil:
    section.add "X-Amz-SignedHeaders", valid_606436
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606437: Call_RotateIngestEndpointCredentials_606425;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
  ## 
  let valid = call_606437.validator(path, query, header, formData, body)
  let scheme = call_606437.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606437.url(scheme.get, call_606437.host, call_606437.base,
                         call_606437.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606437, url, valid)

proc call*(call_606438: Call_RotateIngestEndpointCredentials_606425; id: string;
          ingestEndpointId: string): Recallable =
  ## rotateIngestEndpointCredentials
  ## Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
  ##   id: string (required)
  ##     : The ID of the channel the IngestEndpoint is on.
  ##   ingestEndpointId: string (required)
  ##                   : The id of the IngestEndpoint whose credentials should be rotated
  var path_606439 = newJObject()
  add(path_606439, "id", newJString(id))
  add(path_606439, "ingest_endpoint_id", newJString(ingestEndpointId))
  result = call_606438.call(path_606439, nil, nil, nil, nil)

var rotateIngestEndpointCredentials* = Call_RotateIngestEndpointCredentials_606425(
    name: "rotateIngestEndpointCredentials", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com",
    route: "/channels/{id}/ingest_endpoints/{ingest_endpoint_id}/credentials",
    validator: validate_RotateIngestEndpointCredentials_606426, base: "/",
    url: url_RotateIngestEndpointCredentials_606427,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_606440 = ref object of OpenApiRestCall_605589
proc url_UntagResource_606442(protocol: Scheme; host: string; base: string;
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
  if base ==
      "/" and
      hydrated.get.startsWith "/":
    result.path = hydrated.get
  else:
    result.path = base & hydrated.get

proc validate_UntagResource_606441(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_606443 = path.getOrDefault("resource-arn")
  valid_606443 = validateParameter(valid_606443, JString, required = true,
                                 default = nil)
  if valid_606443 != nil:
    section.add "resource-arn", valid_606443
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key(s) of tag to be deleted
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_606444 = query.getOrDefault("tagKeys")
  valid_606444 = validateParameter(valid_606444, JArray, required = true, default = nil)
  if valid_606444 != nil:
    section.add "tagKeys", valid_606444
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
  var valid_606445 = header.getOrDefault("X-Amz-Signature")
  valid_606445 = validateParameter(valid_606445, JString, required = false,
                                 default = nil)
  if valid_606445 != nil:
    section.add "X-Amz-Signature", valid_606445
  var valid_606446 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_606446 = validateParameter(valid_606446, JString, required = false,
                                 default = nil)
  if valid_606446 != nil:
    section.add "X-Amz-Content-Sha256", valid_606446
  var valid_606447 = header.getOrDefault("X-Amz-Date")
  valid_606447 = validateParameter(valid_606447, JString, required = false,
                                 default = nil)
  if valid_606447 != nil:
    section.add "X-Amz-Date", valid_606447
  var valid_606448 = header.getOrDefault("X-Amz-Credential")
  valid_606448 = validateParameter(valid_606448, JString, required = false,
                                 default = nil)
  if valid_606448 != nil:
    section.add "X-Amz-Credential", valid_606448
  var valid_606449 = header.getOrDefault("X-Amz-Security-Token")
  valid_606449 = validateParameter(valid_606449, JString, required = false,
                                 default = nil)
  if valid_606449 != nil:
    section.add "X-Amz-Security-Token", valid_606449
  var valid_606450 = header.getOrDefault("X-Amz-Algorithm")
  valid_606450 = validateParameter(valid_606450, JString, required = false,
                                 default = nil)
  if valid_606450 != nil:
    section.add "X-Amz-Algorithm", valid_606450
  var valid_606451 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_606451 = validateParameter(valid_606451, JString, required = false,
                                 default = nil)
  if valid_606451 != nil:
    section.add "X-Amz-SignedHeaders", valid_606451
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_606452: Call_UntagResource_606440; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_606452.validator(path, query, header, formData, body)
  let scheme = call_606452.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_606452.url(scheme.get, call_606452.host, call_606452.base,
                         call_606452.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_606452, url, valid)

proc call*(call_606453: Call_UntagResource_606440; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ##   resourceArn: string (required)
  ##   tagKeys: JArray (required)
  ##          : The key(s) of tag to be deleted
  var path_606454 = newJObject()
  var query_606455 = newJObject()
  add(path_606454, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_606455.add "tagKeys", tagKeys
  result = call_606453.call(path_606454, query_606455, nil, nil, nil)

var untagResource* = Call_UntagResource_606440(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "mediapackage.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_606441,
    base: "/", url: url_UntagResource_606442, schemes: {Scheme.Https, Scheme.Http})
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
