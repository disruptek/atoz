
import
  json, options, hashes, uri, strutils, tables, rest, os, uri, strutils, md5, base64,
  httpcore, sigv4

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
method atozHook(call: OpenApiRestCall; url: Uri; input: JsonNode; body: string = ""): Recallable {.
    base.}
type
  Call_CreateChannel_21626021 = ref object of OpenApiRestCall_21625435
proc url_CreateChannel_21626023(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateChannel_21626022(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Creates a new Channel.
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
  var valid_21626024 = header.getOrDefault("X-Amz-Date")
  valid_21626024 = validateParameter(valid_21626024, JString, required = false,
                                   default = nil)
  if valid_21626024 != nil:
    section.add "X-Amz-Date", valid_21626024
  var valid_21626025 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626025 = validateParameter(valid_21626025, JString, required = false,
                                   default = nil)
  if valid_21626025 != nil:
    section.add "X-Amz-Security-Token", valid_21626025
  var valid_21626026 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626026 = validateParameter(valid_21626026, JString, required = false,
                                   default = nil)
  if valid_21626026 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626026
  var valid_21626027 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626027 = validateParameter(valid_21626027, JString, required = false,
                                   default = nil)
  if valid_21626027 != nil:
    section.add "X-Amz-Algorithm", valid_21626027
  var valid_21626028 = header.getOrDefault("X-Amz-Signature")
  valid_21626028 = validateParameter(valid_21626028, JString, required = false,
                                   default = nil)
  if valid_21626028 != nil:
    section.add "X-Amz-Signature", valid_21626028
  var valid_21626029 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626029 = validateParameter(valid_21626029, JString, required = false,
                                   default = nil)
  if valid_21626029 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626029
  var valid_21626030 = header.getOrDefault("X-Amz-Credential")
  valid_21626030 = validateParameter(valid_21626030, JString, required = false,
                                   default = nil)
  if valid_21626030 != nil:
    section.add "X-Amz-Credential", valid_21626030
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

proc call*(call_21626032: Call_CreateChannel_21626021; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new Channel.
  ## 
  let valid = call_21626032.validator(path, query, header, formData, body, _)
  let scheme = call_21626032.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626032.makeUrl(scheme.get, call_21626032.host, call_21626032.base,
                               call_21626032.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626032, uri, valid, _)

proc call*(call_21626033: Call_CreateChannel_21626021; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a new Channel.
  ##   body: JObject (required)
  var body_21626034 = newJObject()
  if body != nil:
    body_21626034 = body
  result = call_21626033.call(nil, nil, nil, nil, body_21626034)

var createChannel* = Call_CreateChannel_21626021(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "mediapackage.amazonaws.com",
    route: "/channels", validator: validate_CreateChannel_21626022, base: "/",
    makeUrl: url_CreateChannel_21626023, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_21625779 = ref object of OpenApiRestCall_21625435
proc url_ListChannels_21625781(protocol: Scheme; host: string; base: string;
                              route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListChannels_21625780(path: JsonNode; query: JsonNode;
                                   header: JsonNode; formData: JsonNode;
                                   body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Returns a collection of Channels.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : Upper bound on number of records to return.
  ##   nextToken: JString
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21625882 = query.getOrDefault("NextToken")
  valid_21625882 = validateParameter(valid_21625882, JString, required = false,
                                   default = nil)
  if valid_21625882 != nil:
    section.add "NextToken", valid_21625882
  var valid_21625883 = query.getOrDefault("maxResults")
  valid_21625883 = validateParameter(valid_21625883, JInt, required = false,
                                   default = nil)
  if valid_21625883 != nil:
    section.add "maxResults", valid_21625883
  var valid_21625884 = query.getOrDefault("nextToken")
  valid_21625884 = validateParameter(valid_21625884, JString, required = false,
                                   default = nil)
  if valid_21625884 != nil:
    section.add "nextToken", valid_21625884
  var valid_21625885 = query.getOrDefault("MaxResults")
  valid_21625885 = validateParameter(valid_21625885, JString, required = false,
                                   default = nil)
  if valid_21625885 != nil:
    section.add "MaxResults", valid_21625885
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
  var valid_21625886 = header.getOrDefault("X-Amz-Date")
  valid_21625886 = validateParameter(valid_21625886, JString, required = false,
                                   default = nil)
  if valid_21625886 != nil:
    section.add "X-Amz-Date", valid_21625886
  var valid_21625887 = header.getOrDefault("X-Amz-Security-Token")
  valid_21625887 = validateParameter(valid_21625887, JString, required = false,
                                   default = nil)
  if valid_21625887 != nil:
    section.add "X-Amz-Security-Token", valid_21625887
  var valid_21625888 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21625888 = validateParameter(valid_21625888, JString, required = false,
                                   default = nil)
  if valid_21625888 != nil:
    section.add "X-Amz-Content-Sha256", valid_21625888
  var valid_21625889 = header.getOrDefault("X-Amz-Algorithm")
  valid_21625889 = validateParameter(valid_21625889, JString, required = false,
                                   default = nil)
  if valid_21625889 != nil:
    section.add "X-Amz-Algorithm", valid_21625889
  var valid_21625890 = header.getOrDefault("X-Amz-Signature")
  valid_21625890 = validateParameter(valid_21625890, JString, required = false,
                                   default = nil)
  if valid_21625890 != nil:
    section.add "X-Amz-Signature", valid_21625890
  var valid_21625891 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21625891 = validateParameter(valid_21625891, JString, required = false,
                                   default = nil)
  if valid_21625891 != nil:
    section.add "X-Amz-SignedHeaders", valid_21625891
  var valid_21625892 = header.getOrDefault("X-Amz-Credential")
  valid_21625892 = validateParameter(valid_21625892, JString, required = false,
                                   default = nil)
  if valid_21625892 != nil:
    section.add "X-Amz-Credential", valid_21625892
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21625917: Call_ListChannels_21625779; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a collection of Channels.
  ## 
  let valid = call_21625917.validator(path, query, header, formData, body, _)
  let scheme = call_21625917.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21625917.makeUrl(scheme.get, call_21625917.host, call_21625917.base,
                               call_21625917.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21625917, uri, valid, _)

proc call*(call_21625980: Call_ListChannels_21625779; NextToken: string = "";
          maxResults: int = 0; nextToken: string = ""; MaxResults: string = ""): Recallable =
  ## listChannels
  ## Returns a collection of Channels.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : Upper bound on number of records to return.
  ##   nextToken: string
  ##            : A token used to resume pagination from the end of a previous request.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21625982 = newJObject()
  add(query_21625982, "NextToken", newJString(NextToken))
  add(query_21625982, "maxResults", newJInt(maxResults))
  add(query_21625982, "nextToken", newJString(nextToken))
  add(query_21625982, "MaxResults", newJString(MaxResults))
  result = call_21625980.call(nil, query_21625982, nil, nil, nil)

var listChannels* = Call_ListChannels_21625779(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/channels", validator: validate_ListChannels_21625780, base: "/",
    makeUrl: url_ListChannels_21625781, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHarvestJob_21626054 = ref object of OpenApiRestCall_21625435
proc url_CreateHarvestJob_21626056(protocol: Scheme; host: string; base: string;
                                  route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateHarvestJob_21626055(path: JsonNode; query: JsonNode;
                                       header: JsonNode; formData: JsonNode;
                                       body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new HarvestJob record.
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
  var valid_21626057 = header.getOrDefault("X-Amz-Date")
  valid_21626057 = validateParameter(valid_21626057, JString, required = false,
                                   default = nil)
  if valid_21626057 != nil:
    section.add "X-Amz-Date", valid_21626057
  var valid_21626058 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626058 = validateParameter(valid_21626058, JString, required = false,
                                   default = nil)
  if valid_21626058 != nil:
    section.add "X-Amz-Security-Token", valid_21626058
  var valid_21626059 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626059 = validateParameter(valid_21626059, JString, required = false,
                                   default = nil)
  if valid_21626059 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626059
  var valid_21626060 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626060 = validateParameter(valid_21626060, JString, required = false,
                                   default = nil)
  if valid_21626060 != nil:
    section.add "X-Amz-Algorithm", valid_21626060
  var valid_21626061 = header.getOrDefault("X-Amz-Signature")
  valid_21626061 = validateParameter(valid_21626061, JString, required = false,
                                   default = nil)
  if valid_21626061 != nil:
    section.add "X-Amz-Signature", valid_21626061
  var valid_21626062 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626062 = validateParameter(valid_21626062, JString, required = false,
                                   default = nil)
  if valid_21626062 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626062
  var valid_21626063 = header.getOrDefault("X-Amz-Credential")
  valid_21626063 = validateParameter(valid_21626063, JString, required = false,
                                   default = nil)
  if valid_21626063 != nil:
    section.add "X-Amz-Credential", valid_21626063
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

proc call*(call_21626065: Call_CreateHarvestJob_21626054; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new HarvestJob record.
  ## 
  let valid = call_21626065.validator(path, query, header, formData, body, _)
  let scheme = call_21626065.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626065.makeUrl(scheme.get, call_21626065.host, call_21626065.base,
                               call_21626065.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626065, uri, valid, _)

proc call*(call_21626066: Call_CreateHarvestJob_21626054; body: JsonNode): Recallable =
  ## createHarvestJob
  ## Creates a new HarvestJob record.
  ##   body: JObject (required)
  var body_21626067 = newJObject()
  if body != nil:
    body_21626067 = body
  result = call_21626066.call(nil, nil, nil, nil, body_21626067)

var createHarvestJob* = Call_CreateHarvestJob_21626054(name: "createHarvestJob",
    meth: HttpMethod.HttpPost, host: "mediapackage.amazonaws.com",
    route: "/harvest_jobs", validator: validate_CreateHarvestJob_21626055,
    base: "/", makeUrl: url_CreateHarvestJob_21626056,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHarvestJobs_21626035 = ref object of OpenApiRestCall_21625435
proc url_ListHarvestJobs_21626037(protocol: Scheme; host: string; base: string;
                                 route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListHarvestJobs_21626036(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a collection of HarvestJob records.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   includeStatus: JString
  ##                : When specified, the request will return only HarvestJobs in the given status.
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The upper bound on the number of records to return.
  ##   nextToken: JString
  ##            : A token used to resume pagination from the end of a previous request.
  ##   includeChannelId: JString
  ##                   : When specified, the request will return only HarvestJobs associated with the given Channel ID.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626038 = query.getOrDefault("includeStatus")
  valid_21626038 = validateParameter(valid_21626038, JString, required = false,
                                   default = nil)
  if valid_21626038 != nil:
    section.add "includeStatus", valid_21626038
  var valid_21626039 = query.getOrDefault("NextToken")
  valid_21626039 = validateParameter(valid_21626039, JString, required = false,
                                   default = nil)
  if valid_21626039 != nil:
    section.add "NextToken", valid_21626039
  var valid_21626040 = query.getOrDefault("maxResults")
  valid_21626040 = validateParameter(valid_21626040, JInt, required = false,
                                   default = nil)
  if valid_21626040 != nil:
    section.add "maxResults", valid_21626040
  var valid_21626041 = query.getOrDefault("nextToken")
  valid_21626041 = validateParameter(valid_21626041, JString, required = false,
                                   default = nil)
  if valid_21626041 != nil:
    section.add "nextToken", valid_21626041
  var valid_21626042 = query.getOrDefault("includeChannelId")
  valid_21626042 = validateParameter(valid_21626042, JString, required = false,
                                   default = nil)
  if valid_21626042 != nil:
    section.add "includeChannelId", valid_21626042
  var valid_21626043 = query.getOrDefault("MaxResults")
  valid_21626043 = validateParameter(valid_21626043, JString, required = false,
                                   default = nil)
  if valid_21626043 != nil:
    section.add "MaxResults", valid_21626043
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
  var valid_21626044 = header.getOrDefault("X-Amz-Date")
  valid_21626044 = validateParameter(valid_21626044, JString, required = false,
                                   default = nil)
  if valid_21626044 != nil:
    section.add "X-Amz-Date", valid_21626044
  var valid_21626045 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626045 = validateParameter(valid_21626045, JString, required = false,
                                   default = nil)
  if valid_21626045 != nil:
    section.add "X-Amz-Security-Token", valid_21626045
  var valid_21626046 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626046 = validateParameter(valid_21626046, JString, required = false,
                                   default = nil)
  if valid_21626046 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626046
  var valid_21626047 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626047 = validateParameter(valid_21626047, JString, required = false,
                                   default = nil)
  if valid_21626047 != nil:
    section.add "X-Amz-Algorithm", valid_21626047
  var valid_21626048 = header.getOrDefault("X-Amz-Signature")
  valid_21626048 = validateParameter(valid_21626048, JString, required = false,
                                   default = nil)
  if valid_21626048 != nil:
    section.add "X-Amz-Signature", valid_21626048
  var valid_21626049 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626049 = validateParameter(valid_21626049, JString, required = false,
                                   default = nil)
  if valid_21626049 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626049
  var valid_21626050 = header.getOrDefault("X-Amz-Credential")
  valid_21626050 = validateParameter(valid_21626050, JString, required = false,
                                   default = nil)
  if valid_21626050 != nil:
    section.add "X-Amz-Credential", valid_21626050
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626051: Call_ListHarvestJobs_21626035; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a collection of HarvestJob records.
  ## 
  let valid = call_21626051.validator(path, query, header, formData, body, _)
  let scheme = call_21626051.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626051.makeUrl(scheme.get, call_21626051.host, call_21626051.base,
                               call_21626051.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626051, uri, valid, _)

proc call*(call_21626052: Call_ListHarvestJobs_21626035;
          includeStatus: string = ""; NextToken: string = ""; maxResults: int = 0;
          nextToken: string = ""; includeChannelId: string = ""; MaxResults: string = ""): Recallable =
  ## listHarvestJobs
  ## Returns a collection of HarvestJob records.
  ##   includeStatus: string
  ##                : When specified, the request will return only HarvestJobs in the given status.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The upper bound on the number of records to return.
  ##   nextToken: string
  ##            : A token used to resume pagination from the end of a previous request.
  ##   includeChannelId: string
  ##                   : When specified, the request will return only HarvestJobs associated with the given Channel ID.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626053 = newJObject()
  add(query_21626053, "includeStatus", newJString(includeStatus))
  add(query_21626053, "NextToken", newJString(NextToken))
  add(query_21626053, "maxResults", newJInt(maxResults))
  add(query_21626053, "nextToken", newJString(nextToken))
  add(query_21626053, "includeChannelId", newJString(includeChannelId))
  add(query_21626053, "MaxResults", newJString(MaxResults))
  result = call_21626052.call(nil, query_21626053, nil, nil, nil)

var listHarvestJobs* = Call_ListHarvestJobs_21626035(name: "listHarvestJobs",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/harvest_jobs", validator: validate_ListHarvestJobs_21626036, base: "/",
    makeUrl: url_ListHarvestJobs_21626037, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOriginEndpoint_21626086 = ref object of OpenApiRestCall_21625435
proc url_CreateOriginEndpoint_21626088(protocol: Scheme; host: string; base: string;
                                      route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_CreateOriginEndpoint_21626087(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Creates a new OriginEndpoint record.
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
  var valid_21626089 = header.getOrDefault("X-Amz-Date")
  valid_21626089 = validateParameter(valid_21626089, JString, required = false,
                                   default = nil)
  if valid_21626089 != nil:
    section.add "X-Amz-Date", valid_21626089
  var valid_21626090 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626090 = validateParameter(valid_21626090, JString, required = false,
                                   default = nil)
  if valid_21626090 != nil:
    section.add "X-Amz-Security-Token", valid_21626090
  var valid_21626091 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626091 = validateParameter(valid_21626091, JString, required = false,
                                   default = nil)
  if valid_21626091 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626091
  var valid_21626092 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626092 = validateParameter(valid_21626092, JString, required = false,
                                   default = nil)
  if valid_21626092 != nil:
    section.add "X-Amz-Algorithm", valid_21626092
  var valid_21626093 = header.getOrDefault("X-Amz-Signature")
  valid_21626093 = validateParameter(valid_21626093, JString, required = false,
                                   default = nil)
  if valid_21626093 != nil:
    section.add "X-Amz-Signature", valid_21626093
  var valid_21626094 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626094 = validateParameter(valid_21626094, JString, required = false,
                                   default = nil)
  if valid_21626094 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626094
  var valid_21626095 = header.getOrDefault("X-Amz-Credential")
  valid_21626095 = validateParameter(valid_21626095, JString, required = false,
                                   default = nil)
  if valid_21626095 != nil:
    section.add "X-Amz-Credential", valid_21626095
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

proc call*(call_21626097: Call_CreateOriginEndpoint_21626086; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Creates a new OriginEndpoint record.
  ## 
  let valid = call_21626097.validator(path, query, header, formData, body, _)
  let scheme = call_21626097.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626097.makeUrl(scheme.get, call_21626097.host, call_21626097.base,
                               call_21626097.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626097, uri, valid, _)

proc call*(call_21626098: Call_CreateOriginEndpoint_21626086; body: JsonNode): Recallable =
  ## createOriginEndpoint
  ## Creates a new OriginEndpoint record.
  ##   body: JObject (required)
  var body_21626099 = newJObject()
  if body != nil:
    body_21626099 = body
  result = call_21626098.call(nil, nil, nil, nil, body_21626099)

var createOriginEndpoint* = Call_CreateOriginEndpoint_21626086(
    name: "createOriginEndpoint", meth: HttpMethod.HttpPost,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints",
    validator: validate_CreateOriginEndpoint_21626087, base: "/",
    makeUrl: url_CreateOriginEndpoint_21626088,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOriginEndpoints_21626068 = ref object of OpenApiRestCall_21625435
proc url_ListOriginEndpoints_21626070(protocol: Scheme; host: string; base: string;
                                     route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  if base == "/" and route.startsWith "/":
    result.path = route
  else:
    result.path = base & route

proc validate_ListOriginEndpoints_21626069(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Returns a collection of OriginEndpoint records.
  ## 
  var section: JsonNode
  result = newJObject()
  section = newJObject()
  result.add "path", section
  ## parameters in `query` object:
  ##   NextToken: JString
  ##            : Pagination token
  ##   maxResults: JInt
  ##             : The upper bound on the number of records to return.
  ##   nextToken: JString
  ##            : A token used to resume pagination from the end of a previous request.
  ##   channelId: JString
  ##            : When specified, the request will return only OriginEndpoints associated with the given Channel ID.
  ##   MaxResults: JString
  ##             : Pagination limit
  section = newJObject()
  var valid_21626071 = query.getOrDefault("NextToken")
  valid_21626071 = validateParameter(valid_21626071, JString, required = false,
                                   default = nil)
  if valid_21626071 != nil:
    section.add "NextToken", valid_21626071
  var valid_21626072 = query.getOrDefault("maxResults")
  valid_21626072 = validateParameter(valid_21626072, JInt, required = false,
                                   default = nil)
  if valid_21626072 != nil:
    section.add "maxResults", valid_21626072
  var valid_21626073 = query.getOrDefault("nextToken")
  valid_21626073 = validateParameter(valid_21626073, JString, required = false,
                                   default = nil)
  if valid_21626073 != nil:
    section.add "nextToken", valid_21626073
  var valid_21626074 = query.getOrDefault("channelId")
  valid_21626074 = validateParameter(valid_21626074, JString, required = false,
                                   default = nil)
  if valid_21626074 != nil:
    section.add "channelId", valid_21626074
  var valid_21626075 = query.getOrDefault("MaxResults")
  valid_21626075 = validateParameter(valid_21626075, JString, required = false,
                                   default = nil)
  if valid_21626075 != nil:
    section.add "MaxResults", valid_21626075
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
  var valid_21626076 = header.getOrDefault("X-Amz-Date")
  valid_21626076 = validateParameter(valid_21626076, JString, required = false,
                                   default = nil)
  if valid_21626076 != nil:
    section.add "X-Amz-Date", valid_21626076
  var valid_21626077 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626077 = validateParameter(valid_21626077, JString, required = false,
                                   default = nil)
  if valid_21626077 != nil:
    section.add "X-Amz-Security-Token", valid_21626077
  var valid_21626078 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626078 = validateParameter(valid_21626078, JString, required = false,
                                   default = nil)
  if valid_21626078 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626078
  var valid_21626079 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626079 = validateParameter(valid_21626079, JString, required = false,
                                   default = nil)
  if valid_21626079 != nil:
    section.add "X-Amz-Algorithm", valid_21626079
  var valid_21626080 = header.getOrDefault("X-Amz-Signature")
  valid_21626080 = validateParameter(valid_21626080, JString, required = false,
                                   default = nil)
  if valid_21626080 != nil:
    section.add "X-Amz-Signature", valid_21626080
  var valid_21626081 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626081 = validateParameter(valid_21626081, JString, required = false,
                                   default = nil)
  if valid_21626081 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626081
  var valid_21626082 = header.getOrDefault("X-Amz-Credential")
  valid_21626082 = validateParameter(valid_21626082, JString, required = false,
                                   default = nil)
  if valid_21626082 != nil:
    section.add "X-Amz-Credential", valid_21626082
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626083: Call_ListOriginEndpoints_21626068; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Returns a collection of OriginEndpoint records.
  ## 
  let valid = call_21626083.validator(path, query, header, formData, body, _)
  let scheme = call_21626083.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626083.makeUrl(scheme.get, call_21626083.host, call_21626083.base,
                               call_21626083.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626083, uri, valid, _)

proc call*(call_21626084: Call_ListOriginEndpoints_21626068;
          NextToken: string = ""; maxResults: int = 0; nextToken: string = "";
          channelId: string = ""; MaxResults: string = ""): Recallable =
  ## listOriginEndpoints
  ## Returns a collection of OriginEndpoint records.
  ##   NextToken: string
  ##            : Pagination token
  ##   maxResults: int
  ##             : The upper bound on the number of records to return.
  ##   nextToken: string
  ##            : A token used to resume pagination from the end of a previous request.
  ##   channelId: string
  ##            : When specified, the request will return only OriginEndpoints associated with the given Channel ID.
  ##   MaxResults: string
  ##             : Pagination limit
  var query_21626085 = newJObject()
  add(query_21626085, "NextToken", newJString(NextToken))
  add(query_21626085, "maxResults", newJInt(maxResults))
  add(query_21626085, "nextToken", newJString(nextToken))
  add(query_21626085, "channelId", newJString(channelId))
  add(query_21626085, "MaxResults", newJString(MaxResults))
  result = call_21626084.call(nil, query_21626085, nil, nil, nil)

var listOriginEndpoints* = Call_ListOriginEndpoints_21626068(
    name: "listOriginEndpoints", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints",
    validator: validate_ListOriginEndpoints_21626069, base: "/",
    makeUrl: url_ListOriginEndpoints_21626070,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_21626127 = ref object of OpenApiRestCall_21625435
proc url_UpdateChannel_21626129(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateChannel_21626128(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Updates an existing Channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the Channel to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_21626130 = path.getOrDefault("id")
  valid_21626130 = validateParameter(valid_21626130, JString, required = true,
                                   default = nil)
  if valid_21626130 != nil:
    section.add "id", valid_21626130
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
  var valid_21626131 = header.getOrDefault("X-Amz-Date")
  valid_21626131 = validateParameter(valid_21626131, JString, required = false,
                                   default = nil)
  if valid_21626131 != nil:
    section.add "X-Amz-Date", valid_21626131
  var valid_21626132 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626132 = validateParameter(valid_21626132, JString, required = false,
                                   default = nil)
  if valid_21626132 != nil:
    section.add "X-Amz-Security-Token", valid_21626132
  var valid_21626133 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626133 = validateParameter(valid_21626133, JString, required = false,
                                   default = nil)
  if valid_21626133 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626133
  var valid_21626134 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626134 = validateParameter(valid_21626134, JString, required = false,
                                   default = nil)
  if valid_21626134 != nil:
    section.add "X-Amz-Algorithm", valid_21626134
  var valid_21626135 = header.getOrDefault("X-Amz-Signature")
  valid_21626135 = validateParameter(valid_21626135, JString, required = false,
                                   default = nil)
  if valid_21626135 != nil:
    section.add "X-Amz-Signature", valid_21626135
  var valid_21626136 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626136 = validateParameter(valid_21626136, JString, required = false,
                                   default = nil)
  if valid_21626136 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626136
  var valid_21626137 = header.getOrDefault("X-Amz-Credential")
  valid_21626137 = validateParameter(valid_21626137, JString, required = false,
                                   default = nil)
  if valid_21626137 != nil:
    section.add "X-Amz-Credential", valid_21626137
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

proc call*(call_21626139: Call_UpdateChannel_21626127; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing Channel.
  ## 
  let valid = call_21626139.validator(path, query, header, formData, body, _)
  let scheme = call_21626139.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626139.makeUrl(scheme.get, call_21626139.host, call_21626139.base,
                               call_21626139.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626139, uri, valid, _)

proc call*(call_21626140: Call_UpdateChannel_21626127; id: string; body: JsonNode): Recallable =
  ## updateChannel
  ## Updates an existing Channel.
  ##   id: string (required)
  ##     : The ID of the Channel to update.
  ##   body: JObject (required)
  var path_21626141 = newJObject()
  var body_21626142 = newJObject()
  add(path_21626141, "id", newJString(id))
  if body != nil:
    body_21626142 = body
  result = call_21626140.call(path_21626141, nil, nil, nil, body_21626142)

var updateChannel* = Call_UpdateChannel_21626127(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_UpdateChannel_21626128, base: "/",
    makeUrl: url_UpdateChannel_21626129, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_21626100 = ref object of OpenApiRestCall_21625435
proc url_DescribeChannel_21626102(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeChannel_21626101(path: JsonNode; query: JsonNode;
                                      header: JsonNode; formData: JsonNode;
                                      body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets details about a Channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of a Channel.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_21626116 = path.getOrDefault("id")
  valid_21626116 = validateParameter(valid_21626116, JString, required = true,
                                   default = nil)
  if valid_21626116 != nil:
    section.add "id", valid_21626116
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
  if body != nil:
    result.add "body", body

proc call*(call_21626124: Call_DescribeChannel_21626100; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details about a Channel.
  ## 
  let valid = call_21626124.validator(path, query, header, formData, body, _)
  let scheme = call_21626124.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626124.makeUrl(scheme.get, call_21626124.host, call_21626124.base,
                               call_21626124.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626124, uri, valid, _)

proc call*(call_21626125: Call_DescribeChannel_21626100; id: string): Recallable =
  ## describeChannel
  ## Gets details about a Channel.
  ##   id: string (required)
  ##     : The ID of a Channel.
  var path_21626126 = newJObject()
  add(path_21626126, "id", newJString(id))
  result = call_21626125.call(path_21626126, nil, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_21626100(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_DescribeChannel_21626101,
    base: "/", makeUrl: url_DescribeChannel_21626102,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_21626143 = ref object of OpenApiRestCall_21625435
proc url_DeleteChannel_21626145(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteChannel_21626144(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  ## Deletes an existing Channel.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the Channel to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_21626146 = path.getOrDefault("id")
  valid_21626146 = validateParameter(valid_21626146, JString, required = true,
                                   default = nil)
  if valid_21626146 != nil:
    section.add "id", valid_21626146
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
  var valid_21626147 = header.getOrDefault("X-Amz-Date")
  valid_21626147 = validateParameter(valid_21626147, JString, required = false,
                                   default = nil)
  if valid_21626147 != nil:
    section.add "X-Amz-Date", valid_21626147
  var valid_21626148 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626148 = validateParameter(valid_21626148, JString, required = false,
                                   default = nil)
  if valid_21626148 != nil:
    section.add "X-Amz-Security-Token", valid_21626148
  var valid_21626149 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626149 = validateParameter(valid_21626149, JString, required = false,
                                   default = nil)
  if valid_21626149 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626149
  var valid_21626150 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626150 = validateParameter(valid_21626150, JString, required = false,
                                   default = nil)
  if valid_21626150 != nil:
    section.add "X-Amz-Algorithm", valid_21626150
  var valid_21626151 = header.getOrDefault("X-Amz-Signature")
  valid_21626151 = validateParameter(valid_21626151, JString, required = false,
                                   default = nil)
  if valid_21626151 != nil:
    section.add "X-Amz-Signature", valid_21626151
  var valid_21626152 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626152 = validateParameter(valid_21626152, JString, required = false,
                                   default = nil)
  if valid_21626152 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626152
  var valid_21626153 = header.getOrDefault("X-Amz-Credential")
  valid_21626153 = validateParameter(valid_21626153, JString, required = false,
                                   default = nil)
  if valid_21626153 != nil:
    section.add "X-Amz-Credential", valid_21626153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626154: Call_DeleteChannel_21626143; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing Channel.
  ## 
  let valid = call_21626154.validator(path, query, header, formData, body, _)
  let scheme = call_21626154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626154.makeUrl(scheme.get, call_21626154.host, call_21626154.base,
                               call_21626154.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626154, uri, valid, _)

proc call*(call_21626155: Call_DeleteChannel_21626143; id: string): Recallable =
  ## deleteChannel
  ## Deletes an existing Channel.
  ##   id: string (required)
  ##     : The ID of the Channel to delete.
  var path_21626156 = newJObject()
  add(path_21626156, "id", newJString(id))
  result = call_21626155.call(path_21626156, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_21626143(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_DeleteChannel_21626144, base: "/",
    makeUrl: url_DeleteChannel_21626145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOriginEndpoint_21626171 = ref object of OpenApiRestCall_21625435
proc url_UpdateOriginEndpoint_21626173(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateOriginEndpoint_21626172(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Updates an existing OriginEndpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the OriginEndpoint to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_21626174 = path.getOrDefault("id")
  valid_21626174 = validateParameter(valid_21626174, JString, required = true,
                                   default = nil)
  if valid_21626174 != nil:
    section.add "id", valid_21626174
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
  var valid_21626175 = header.getOrDefault("X-Amz-Date")
  valid_21626175 = validateParameter(valid_21626175, JString, required = false,
                                   default = nil)
  if valid_21626175 != nil:
    section.add "X-Amz-Date", valid_21626175
  var valid_21626176 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626176 = validateParameter(valid_21626176, JString, required = false,
                                   default = nil)
  if valid_21626176 != nil:
    section.add "X-Amz-Security-Token", valid_21626176
  var valid_21626177 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626177 = validateParameter(valid_21626177, JString, required = false,
                                   default = nil)
  if valid_21626177 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626177
  var valid_21626178 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626178 = validateParameter(valid_21626178, JString, required = false,
                                   default = nil)
  if valid_21626178 != nil:
    section.add "X-Amz-Algorithm", valid_21626178
  var valid_21626179 = header.getOrDefault("X-Amz-Signature")
  valid_21626179 = validateParameter(valid_21626179, JString, required = false,
                                   default = nil)
  if valid_21626179 != nil:
    section.add "X-Amz-Signature", valid_21626179
  var valid_21626180 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626180 = validateParameter(valid_21626180, JString, required = false,
                                   default = nil)
  if valid_21626180 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626180
  var valid_21626181 = header.getOrDefault("X-Amz-Credential")
  valid_21626181 = validateParameter(valid_21626181, JString, required = false,
                                   default = nil)
  if valid_21626181 != nil:
    section.add "X-Amz-Credential", valid_21626181
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

proc call*(call_21626183: Call_UpdateOriginEndpoint_21626171; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Updates an existing OriginEndpoint.
  ## 
  let valid = call_21626183.validator(path, query, header, formData, body, _)
  let scheme = call_21626183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626183.makeUrl(scheme.get, call_21626183.host, call_21626183.base,
                               call_21626183.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626183, uri, valid, _)

proc call*(call_21626184: Call_UpdateOriginEndpoint_21626171; id: string;
          body: JsonNode): Recallable =
  ## updateOriginEndpoint
  ## Updates an existing OriginEndpoint.
  ##   id: string (required)
  ##     : The ID of the OriginEndpoint to update.
  ##   body: JObject (required)
  var path_21626185 = newJObject()
  var body_21626186 = newJObject()
  add(path_21626185, "id", newJString(id))
  if body != nil:
    body_21626186 = body
  result = call_21626184.call(path_21626185, nil, nil, nil, body_21626186)

var updateOriginEndpoint* = Call_UpdateOriginEndpoint_21626171(
    name: "updateOriginEndpoint", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_UpdateOriginEndpoint_21626172, base: "/",
    makeUrl: url_UpdateOriginEndpoint_21626173,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOriginEndpoint_21626157 = ref object of OpenApiRestCall_21625435
proc url_DescribeOriginEndpoint_21626159(protocol: Scheme; host: string;
                                        base: string; route: string; path: JsonNode;
                                        query: JsonNode): Uri =
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

proc validate_DescribeOriginEndpoint_21626158(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets details about an existing OriginEndpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the OriginEndpoint.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_21626160 = path.getOrDefault("id")
  valid_21626160 = validateParameter(valid_21626160, JString, required = true,
                                   default = nil)
  if valid_21626160 != nil:
    section.add "id", valid_21626160
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
  var valid_21626161 = header.getOrDefault("X-Amz-Date")
  valid_21626161 = validateParameter(valid_21626161, JString, required = false,
                                   default = nil)
  if valid_21626161 != nil:
    section.add "X-Amz-Date", valid_21626161
  var valid_21626162 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626162 = validateParameter(valid_21626162, JString, required = false,
                                   default = nil)
  if valid_21626162 != nil:
    section.add "X-Amz-Security-Token", valid_21626162
  var valid_21626163 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626163 = validateParameter(valid_21626163, JString, required = false,
                                   default = nil)
  if valid_21626163 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626163
  var valid_21626164 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626164 = validateParameter(valid_21626164, JString, required = false,
                                   default = nil)
  if valid_21626164 != nil:
    section.add "X-Amz-Algorithm", valid_21626164
  var valid_21626165 = header.getOrDefault("X-Amz-Signature")
  valid_21626165 = validateParameter(valid_21626165, JString, required = false,
                                   default = nil)
  if valid_21626165 != nil:
    section.add "X-Amz-Signature", valid_21626165
  var valid_21626166 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626166 = validateParameter(valid_21626166, JString, required = false,
                                   default = nil)
  if valid_21626166 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626166
  var valid_21626167 = header.getOrDefault("X-Amz-Credential")
  valid_21626167 = validateParameter(valid_21626167, JString, required = false,
                                   default = nil)
  if valid_21626167 != nil:
    section.add "X-Amz-Credential", valid_21626167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626168: Call_DescribeOriginEndpoint_21626157;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details about an existing OriginEndpoint.
  ## 
  let valid = call_21626168.validator(path, query, header, formData, body, _)
  let scheme = call_21626168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626168.makeUrl(scheme.get, call_21626168.host, call_21626168.base,
                               call_21626168.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626168, uri, valid, _)

proc call*(call_21626169: Call_DescribeOriginEndpoint_21626157; id: string): Recallable =
  ## describeOriginEndpoint
  ## Gets details about an existing OriginEndpoint.
  ##   id: string (required)
  ##     : The ID of the OriginEndpoint.
  var path_21626170 = newJObject()
  add(path_21626170, "id", newJString(id))
  result = call_21626169.call(path_21626170, nil, nil, nil, nil)

var describeOriginEndpoint* = Call_DescribeOriginEndpoint_21626157(
    name: "describeOriginEndpoint", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_DescribeOriginEndpoint_21626158, base: "/",
    makeUrl: url_DescribeOriginEndpoint_21626159,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOriginEndpoint_21626187 = ref object of OpenApiRestCall_21625435
proc url_DeleteOriginEndpoint_21626189(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteOriginEndpoint_21626188(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Deletes an existing OriginEndpoint.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the OriginEndpoint to delete.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_21626190 = path.getOrDefault("id")
  valid_21626190 = validateParameter(valid_21626190, JString, required = true,
                                   default = nil)
  if valid_21626190 != nil:
    section.add "id", valid_21626190
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
  var valid_21626191 = header.getOrDefault("X-Amz-Date")
  valid_21626191 = validateParameter(valid_21626191, JString, required = false,
                                   default = nil)
  if valid_21626191 != nil:
    section.add "X-Amz-Date", valid_21626191
  var valid_21626192 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626192 = validateParameter(valid_21626192, JString, required = false,
                                   default = nil)
  if valid_21626192 != nil:
    section.add "X-Amz-Security-Token", valid_21626192
  var valid_21626193 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626193 = validateParameter(valid_21626193, JString, required = false,
                                   default = nil)
  if valid_21626193 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626193
  var valid_21626194 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626194 = validateParameter(valid_21626194, JString, required = false,
                                   default = nil)
  if valid_21626194 != nil:
    section.add "X-Amz-Algorithm", valid_21626194
  var valid_21626195 = header.getOrDefault("X-Amz-Signature")
  valid_21626195 = validateParameter(valid_21626195, JString, required = false,
                                   default = nil)
  if valid_21626195 != nil:
    section.add "X-Amz-Signature", valid_21626195
  var valid_21626196 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626196 = validateParameter(valid_21626196, JString, required = false,
                                   default = nil)
  if valid_21626196 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626196
  var valid_21626197 = header.getOrDefault("X-Amz-Credential")
  valid_21626197 = validateParameter(valid_21626197, JString, required = false,
                                   default = nil)
  if valid_21626197 != nil:
    section.add "X-Amz-Credential", valid_21626197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626198: Call_DeleteOriginEndpoint_21626187; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Deletes an existing OriginEndpoint.
  ## 
  let valid = call_21626198.validator(path, query, header, formData, body, _)
  let scheme = call_21626198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626198.makeUrl(scheme.get, call_21626198.host, call_21626198.base,
                               call_21626198.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626198, uri, valid, _)

proc call*(call_21626199: Call_DeleteOriginEndpoint_21626187; id: string): Recallable =
  ## deleteOriginEndpoint
  ## Deletes an existing OriginEndpoint.
  ##   id: string (required)
  ##     : The ID of the OriginEndpoint to delete.
  var path_21626200 = newJObject()
  add(path_21626200, "id", newJString(id))
  result = call_21626199.call(path_21626200, nil, nil, nil, nil)

var deleteOriginEndpoint* = Call_DeleteOriginEndpoint_21626187(
    name: "deleteOriginEndpoint", meth: HttpMethod.HttpDelete,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_DeleteOriginEndpoint_21626188, base: "/",
    makeUrl: url_DeleteOriginEndpoint_21626189,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHarvestJob_21626201 = ref object of OpenApiRestCall_21625435
proc url_DescribeHarvestJob_21626203(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeHarvestJob_21626202(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Gets details about an existing HarvestJob.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the HarvestJob.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_21626204 = path.getOrDefault("id")
  valid_21626204 = validateParameter(valid_21626204, JString, required = true,
                                   default = nil)
  if valid_21626204 != nil:
    section.add "id", valid_21626204
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
  var valid_21626205 = header.getOrDefault("X-Amz-Date")
  valid_21626205 = validateParameter(valid_21626205, JString, required = false,
                                   default = nil)
  if valid_21626205 != nil:
    section.add "X-Amz-Date", valid_21626205
  var valid_21626206 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626206 = validateParameter(valid_21626206, JString, required = false,
                                   default = nil)
  if valid_21626206 != nil:
    section.add "X-Amz-Security-Token", valid_21626206
  var valid_21626207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626207 = validateParameter(valid_21626207, JString, required = false,
                                   default = nil)
  if valid_21626207 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626207
  var valid_21626208 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626208 = validateParameter(valid_21626208, JString, required = false,
                                   default = nil)
  if valid_21626208 != nil:
    section.add "X-Amz-Algorithm", valid_21626208
  var valid_21626209 = header.getOrDefault("X-Amz-Signature")
  valid_21626209 = validateParameter(valid_21626209, JString, required = false,
                                   default = nil)
  if valid_21626209 != nil:
    section.add "X-Amz-Signature", valid_21626209
  var valid_21626210 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626210 = validateParameter(valid_21626210, JString, required = false,
                                   default = nil)
  if valid_21626210 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626210
  var valid_21626211 = header.getOrDefault("X-Amz-Credential")
  valid_21626211 = validateParameter(valid_21626211, JString, required = false,
                                   default = nil)
  if valid_21626211 != nil:
    section.add "X-Amz-Credential", valid_21626211
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626212: Call_DescribeHarvestJob_21626201; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  ## Gets details about an existing HarvestJob.
  ## 
  let valid = call_21626212.validator(path, query, header, formData, body, _)
  let scheme = call_21626212.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626212.makeUrl(scheme.get, call_21626212.host, call_21626212.base,
                               call_21626212.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626212, uri, valid, _)

proc call*(call_21626213: Call_DescribeHarvestJob_21626201; id: string): Recallable =
  ## describeHarvestJob
  ## Gets details about an existing HarvestJob.
  ##   id: string (required)
  ##     : The ID of the HarvestJob.
  var path_21626214 = newJObject()
  add(path_21626214, "id", newJString(id))
  result = call_21626213.call(path_21626214, nil, nil, nil, nil)

var describeHarvestJob* = Call_DescribeHarvestJob_21626201(
    name: "describeHarvestJob", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/harvest_jobs/{id}",
    validator: validate_DescribeHarvestJob_21626202, base: "/",
    makeUrl: url_DescribeHarvestJob_21626203, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_21626229 = ref object of OpenApiRestCall_21625435
proc url_TagResource_21626231(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_21626230(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21626232 = path.getOrDefault("resource-arn")
  valid_21626232 = validateParameter(valid_21626232, JString, required = true,
                                   default = nil)
  if valid_21626232 != nil:
    section.add "resource-arn", valid_21626232
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
  var valid_21626233 = header.getOrDefault("X-Amz-Date")
  valid_21626233 = validateParameter(valid_21626233, JString, required = false,
                                   default = nil)
  if valid_21626233 != nil:
    section.add "X-Amz-Date", valid_21626233
  var valid_21626234 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626234 = validateParameter(valid_21626234, JString, required = false,
                                   default = nil)
  if valid_21626234 != nil:
    section.add "X-Amz-Security-Token", valid_21626234
  var valid_21626235 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626235 = validateParameter(valid_21626235, JString, required = false,
                                   default = nil)
  if valid_21626235 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626235
  var valid_21626236 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626236 = validateParameter(valid_21626236, JString, required = false,
                                   default = nil)
  if valid_21626236 != nil:
    section.add "X-Amz-Algorithm", valid_21626236
  var valid_21626237 = header.getOrDefault("X-Amz-Signature")
  valid_21626237 = validateParameter(valid_21626237, JString, required = false,
                                   default = nil)
  if valid_21626237 != nil:
    section.add "X-Amz-Signature", valid_21626237
  var valid_21626238 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626238 = validateParameter(valid_21626238, JString, required = false,
                                   default = nil)
  if valid_21626238 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626238
  var valid_21626239 = header.getOrDefault("X-Amz-Credential")
  valid_21626239 = validateParameter(valid_21626239, JString, required = false,
                                   default = nil)
  if valid_21626239 != nil:
    section.add "X-Amz-Credential", valid_21626239
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

proc call*(call_21626241: Call_TagResource_21626229; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626241.validator(path, query, header, formData, body, _)
  let scheme = call_21626241.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626241.makeUrl(scheme.get, call_21626241.host, call_21626241.base,
                               call_21626241.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626241, uri, valid, _)

proc call*(call_21626242: Call_TagResource_21626229; resourceArn: string;
          body: JsonNode): Recallable =
  ## tagResource
  ##   resourceArn: string (required)
  ##   body: JObject (required)
  var path_21626243 = newJObject()
  var body_21626244 = newJObject()
  add(path_21626243, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_21626244 = body
  result = call_21626242.call(path_21626243, nil, nil, nil, body_21626244)

var tagResource* = Call_TagResource_21626229(name: "tagResource",
    meth: HttpMethod.HttpPost, host: "mediapackage.amazonaws.com",
    route: "/tags/{resource-arn}", validator: validate_TagResource_21626230,
    base: "/", makeUrl: url_TagResource_21626231,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_21626215 = ref object of OpenApiRestCall_21625435
proc url_ListTagsForResource_21626217(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_21626216(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21626218 = path.getOrDefault("resource-arn")
  valid_21626218 = validateParameter(valid_21626218, JString, required = true,
                                   default = nil)
  if valid_21626218 != nil:
    section.add "resource-arn", valid_21626218
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
  var valid_21626219 = header.getOrDefault("X-Amz-Date")
  valid_21626219 = validateParameter(valid_21626219, JString, required = false,
                                   default = nil)
  if valid_21626219 != nil:
    section.add "X-Amz-Date", valid_21626219
  var valid_21626220 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626220 = validateParameter(valid_21626220, JString, required = false,
                                   default = nil)
  if valid_21626220 != nil:
    section.add "X-Amz-Security-Token", valid_21626220
  var valid_21626221 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626221 = validateParameter(valid_21626221, JString, required = false,
                                   default = nil)
  if valid_21626221 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626221
  var valid_21626222 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626222 = validateParameter(valid_21626222, JString, required = false,
                                   default = nil)
  if valid_21626222 != nil:
    section.add "X-Amz-Algorithm", valid_21626222
  var valid_21626223 = header.getOrDefault("X-Amz-Signature")
  valid_21626223 = validateParameter(valid_21626223, JString, required = false,
                                   default = nil)
  if valid_21626223 != nil:
    section.add "X-Amz-Signature", valid_21626223
  var valid_21626224 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626224 = validateParameter(valid_21626224, JString, required = false,
                                   default = nil)
  if valid_21626224 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626224
  var valid_21626225 = header.getOrDefault("X-Amz-Credential")
  valid_21626225 = validateParameter(valid_21626225, JString, required = false,
                                   default = nil)
  if valid_21626225 != nil:
    section.add "X-Amz-Credential", valid_21626225
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626226: Call_ListTagsForResource_21626215; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626226.validator(path, query, header, formData, body, _)
  let scheme = call_21626226.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626226.makeUrl(scheme.get, call_21626226.host, call_21626226.base,
                               call_21626226.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626226, uri, valid, _)

proc call*(call_21626227: Call_ListTagsForResource_21626215; resourceArn: string): Recallable =
  ## listTagsForResource
  ##   resourceArn: string (required)
  var path_21626228 = newJObject()
  add(path_21626228, "resource-arn", newJString(resourceArn))
  result = call_21626227.call(path_21626228, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_21626215(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_21626216, base: "/",
    makeUrl: url_ListTagsForResource_21626217,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RotateChannelCredentials_21626245 = ref object of OpenApiRestCall_21625435
proc url_RotateChannelCredentials_21626247(protocol: Scheme; host: string;
    base: string; route: string; path: JsonNode; query: JsonNode): Uri =
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

proc validate_RotateChannelCredentials_21626246(path: JsonNode; query: JsonNode;
    header: JsonNode; formData: JsonNode; body: JsonNode; _: string = ""): JsonNode {.
    nosinks.} =
  ## Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   id: JString (required)
  ##     : The ID of the channel to update.
  section = newJObject()
  assert path != nil, "path argument is necessary due to required `id` field"
  var valid_21626248 = path.getOrDefault("id")
  valid_21626248 = validateParameter(valid_21626248, JString, required = true,
                                   default = nil)
  if valid_21626248 != nil:
    section.add "id", valid_21626248
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
  var valid_21626249 = header.getOrDefault("X-Amz-Date")
  valid_21626249 = validateParameter(valid_21626249, JString, required = false,
                                   default = nil)
  if valid_21626249 != nil:
    section.add "X-Amz-Date", valid_21626249
  var valid_21626250 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626250 = validateParameter(valid_21626250, JString, required = false,
                                   default = nil)
  if valid_21626250 != nil:
    section.add "X-Amz-Security-Token", valid_21626250
  var valid_21626251 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626251 = validateParameter(valid_21626251, JString, required = false,
                                   default = nil)
  if valid_21626251 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626251
  var valid_21626252 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626252 = validateParameter(valid_21626252, JString, required = false,
                                   default = nil)
  if valid_21626252 != nil:
    section.add "X-Amz-Algorithm", valid_21626252
  var valid_21626253 = header.getOrDefault("X-Amz-Signature")
  valid_21626253 = validateParameter(valid_21626253, JString, required = false,
                                   default = nil)
  if valid_21626253 != nil:
    section.add "X-Amz-Signature", valid_21626253
  var valid_21626254 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626254 = validateParameter(valid_21626254, JString, required = false,
                                   default = nil)
  if valid_21626254 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626254
  var valid_21626255 = header.getOrDefault("X-Amz-Credential")
  valid_21626255 = validateParameter(valid_21626255, JString, required = false,
                                   default = nil)
  if valid_21626255 != nil:
    section.add "X-Amz-Credential", valid_21626255
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626256: Call_RotateChannelCredentials_21626245;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
  ## 
  let valid = call_21626256.validator(path, query, header, formData, body, _)
  let scheme = call_21626256.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626256.makeUrl(scheme.get, call_21626256.host, call_21626256.base,
                               call_21626256.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626256, uri, valid, _)

proc call*(call_21626257: Call_RotateChannelCredentials_21626245; id: string): Recallable =
  ## rotateChannelCredentials
  ## Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
  ##   id: string (required)
  ##     : The ID of the channel to update.
  var path_21626258 = newJObject()
  add(path_21626258, "id", newJString(id))
  result = call_21626257.call(path_21626258, nil, nil, nil, nil)

var rotateChannelCredentials* = Call_RotateChannelCredentials_21626245(
    name: "rotateChannelCredentials", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com", route: "/channels/{id}/credentials",
    validator: validate_RotateChannelCredentials_21626246, base: "/",
    makeUrl: url_RotateChannelCredentials_21626247,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_RotateIngestEndpointCredentials_21626259 = ref object of OpenApiRestCall_21625435
proc url_RotateIngestEndpointCredentials_21626261(protocol: Scheme; host: string;
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

proc validate_RotateIngestEndpointCredentials_21626260(path: JsonNode;
    query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode;
    _: string = ""): JsonNode {.nosinks.} =
  ## Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
  ## 
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   ingest_endpoint_id: JString (required)
  ##                     : The id of the IngestEndpoint whose credentials should be rotated
  ##   id: JString (required)
  ##     : The ID of the channel the IngestEndpoint is on.
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `ingest_endpoint_id` field"
  var valid_21626262 = path.getOrDefault("ingest_endpoint_id")
  valid_21626262 = validateParameter(valid_21626262, JString, required = true,
                                   default = nil)
  if valid_21626262 != nil:
    section.add "ingest_endpoint_id", valid_21626262
  var valid_21626263 = path.getOrDefault("id")
  valid_21626263 = validateParameter(valid_21626263, JString, required = true,
                                   default = nil)
  if valid_21626263 != nil:
    section.add "id", valid_21626263
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
  var valid_21626264 = header.getOrDefault("X-Amz-Date")
  valid_21626264 = validateParameter(valid_21626264, JString, required = false,
                                   default = nil)
  if valid_21626264 != nil:
    section.add "X-Amz-Date", valid_21626264
  var valid_21626265 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626265 = validateParameter(valid_21626265, JString, required = false,
                                   default = nil)
  if valid_21626265 != nil:
    section.add "X-Amz-Security-Token", valid_21626265
  var valid_21626266 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626266 = validateParameter(valid_21626266, JString, required = false,
                                   default = nil)
  if valid_21626266 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626266
  var valid_21626267 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626267 = validateParameter(valid_21626267, JString, required = false,
                                   default = nil)
  if valid_21626267 != nil:
    section.add "X-Amz-Algorithm", valid_21626267
  var valid_21626268 = header.getOrDefault("X-Amz-Signature")
  valid_21626268 = validateParameter(valid_21626268, JString, required = false,
                                   default = nil)
  if valid_21626268 != nil:
    section.add "X-Amz-Signature", valid_21626268
  var valid_21626269 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626269 = validateParameter(valid_21626269, JString, required = false,
                                   default = nil)
  if valid_21626269 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626269
  var valid_21626270 = header.getOrDefault("X-Amz-Credential")
  valid_21626270 = validateParameter(valid_21626270, JString, required = false,
                                   default = nil)
  if valid_21626270 != nil:
    section.add "X-Amz-Credential", valid_21626270
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626271: Call_RotateIngestEndpointCredentials_21626259;
          path: JsonNode = nil; query: JsonNode = nil; header: JsonNode = nil;
          formData: JsonNode = nil; body: JsonNode = nil; _: string = ""): Recallable =
  ## Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
  ## 
  let valid = call_21626271.validator(path, query, header, formData, body, _)
  let scheme = call_21626271.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626271.makeUrl(scheme.get, call_21626271.host, call_21626271.base,
                               call_21626271.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626271, uri, valid, _)

proc call*(call_21626272: Call_RotateIngestEndpointCredentials_21626259;
          ingestEndpointId: string; id: string): Recallable =
  ## rotateIngestEndpointCredentials
  ## Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
  ##   ingestEndpointId: string (required)
  ##                   : The id of the IngestEndpoint whose credentials should be rotated
  ##   id: string (required)
  ##     : The ID of the channel the IngestEndpoint is on.
  var path_21626273 = newJObject()
  add(path_21626273, "ingest_endpoint_id", newJString(ingestEndpointId))
  add(path_21626273, "id", newJString(id))
  result = call_21626272.call(path_21626273, nil, nil, nil, nil)

var rotateIngestEndpointCredentials* = Call_RotateIngestEndpointCredentials_21626259(
    name: "rotateIngestEndpointCredentials", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com",
    route: "/channels/{id}/ingest_endpoints/{ingest_endpoint_id}/credentials",
    validator: validate_RotateIngestEndpointCredentials_21626260, base: "/",
    makeUrl: url_RotateIngestEndpointCredentials_21626261,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_21626274 = ref object of OpenApiRestCall_21625435
proc url_UntagResource_21626276(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_21626275(path: JsonNode; query: JsonNode;
                                    header: JsonNode; formData: JsonNode;
                                    body: JsonNode; _: string = ""): JsonNode {.nosinks.} =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_21626277 = path.getOrDefault("resource-arn")
  valid_21626277 = validateParameter(valid_21626277, JString, required = true,
                                   default = nil)
  if valid_21626277 != nil:
    section.add "resource-arn", valid_21626277
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key(s) of tag to be deleted
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_21626278 = query.getOrDefault("tagKeys")
  valid_21626278 = validateParameter(valid_21626278, JArray, required = true,
                                   default = nil)
  if valid_21626278 != nil:
    section.add "tagKeys", valid_21626278
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
  var valid_21626279 = header.getOrDefault("X-Amz-Date")
  valid_21626279 = validateParameter(valid_21626279, JString, required = false,
                                   default = nil)
  if valid_21626279 != nil:
    section.add "X-Amz-Date", valid_21626279
  var valid_21626280 = header.getOrDefault("X-Amz-Security-Token")
  valid_21626280 = validateParameter(valid_21626280, JString, required = false,
                                   default = nil)
  if valid_21626280 != nil:
    section.add "X-Amz-Security-Token", valid_21626280
  var valid_21626281 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_21626281 = validateParameter(valid_21626281, JString, required = false,
                                   default = nil)
  if valid_21626281 != nil:
    section.add "X-Amz-Content-Sha256", valid_21626281
  var valid_21626282 = header.getOrDefault("X-Amz-Algorithm")
  valid_21626282 = validateParameter(valid_21626282, JString, required = false,
                                   default = nil)
  if valid_21626282 != nil:
    section.add "X-Amz-Algorithm", valid_21626282
  var valid_21626283 = header.getOrDefault("X-Amz-Signature")
  valid_21626283 = validateParameter(valid_21626283, JString, required = false,
                                   default = nil)
  if valid_21626283 != nil:
    section.add "X-Amz-Signature", valid_21626283
  var valid_21626284 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_21626284 = validateParameter(valid_21626284, JString, required = false,
                                   default = nil)
  if valid_21626284 != nil:
    section.add "X-Amz-SignedHeaders", valid_21626284
  var valid_21626285 = header.getOrDefault("X-Amz-Credential")
  valid_21626285 = validateParameter(valid_21626285, JString, required = false,
                                   default = nil)
  if valid_21626285 != nil:
    section.add "X-Amz-Credential", valid_21626285
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_21626286: Call_UntagResource_21626274; path: JsonNode = nil;
          query: JsonNode = nil; header: JsonNode = nil; formData: JsonNode = nil;
          body: JsonNode = nil; _: string = ""): Recallable =
  let valid = call_21626286.validator(path, query, header, formData, body, _)
  let scheme = call_21626286.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let uri = call_21626286.makeUrl(scheme.get, call_21626286.host, call_21626286.base,
                               call_21626286.route, valid.getOrDefault("path"),
                               valid.getOrDefault("query"))
  result = atozHook(call_21626286, uri, valid, _)

proc call*(call_21626287: Call_UntagResource_21626274; tagKeys: JsonNode;
          resourceArn: string): Recallable =
  ## untagResource
  ##   tagKeys: JArray (required)
  ##          : The key(s) of tag to be deleted
  ##   resourceArn: string (required)
  var path_21626288 = newJObject()
  var query_21626289 = newJObject()
  if tagKeys != nil:
    query_21626289.add "tagKeys", tagKeys
  add(path_21626288, "resource-arn", newJString(resourceArn))
  result = call_21626287.call(path_21626288, query_21626289, nil, nil, nil)

var untagResource* = Call_UntagResource_21626274(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "mediapackage.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_21626275,
    base: "/", makeUrl: url_UntagResource_21626276,
    schemes: {Scheme.Https, Scheme.Http})
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