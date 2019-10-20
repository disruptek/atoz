
import
  json, options, hashes, uri, tables, rest, os, uri, strutils, httpcore, sigv4

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

  OpenApiRestCall_592364 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_592364](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_592364): Option[Scheme] {.used.} =
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
method hook(call: OpenApiRestCall; url: Uri; input: JsonNode): Recallable {.base.}
type
  Call_CreateChannel_592962 = ref object of OpenApiRestCall_592364
proc url_CreateChannel_592964(protocol: Scheme; host: string; base: string;
                             route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateChannel_592963(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592965 = header.getOrDefault("X-Amz-Signature")
  valid_592965 = validateParameter(valid_592965, JString, required = false,
                                 default = nil)
  if valid_592965 != nil:
    section.add "X-Amz-Signature", valid_592965
  var valid_592966 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592966 = validateParameter(valid_592966, JString, required = false,
                                 default = nil)
  if valid_592966 != nil:
    section.add "X-Amz-Content-Sha256", valid_592966
  var valid_592967 = header.getOrDefault("X-Amz-Date")
  valid_592967 = validateParameter(valid_592967, JString, required = false,
                                 default = nil)
  if valid_592967 != nil:
    section.add "X-Amz-Date", valid_592967
  var valid_592968 = header.getOrDefault("X-Amz-Credential")
  valid_592968 = validateParameter(valid_592968, JString, required = false,
                                 default = nil)
  if valid_592968 != nil:
    section.add "X-Amz-Credential", valid_592968
  var valid_592969 = header.getOrDefault("X-Amz-Security-Token")
  valid_592969 = validateParameter(valid_592969, JString, required = false,
                                 default = nil)
  if valid_592969 != nil:
    section.add "X-Amz-Security-Token", valid_592969
  var valid_592970 = header.getOrDefault("X-Amz-Algorithm")
  valid_592970 = validateParameter(valid_592970, JString, required = false,
                                 default = nil)
  if valid_592970 != nil:
    section.add "X-Amz-Algorithm", valid_592970
  var valid_592971 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592971 = validateParameter(valid_592971, JString, required = false,
                                 default = nil)
  if valid_592971 != nil:
    section.add "X-Amz-SignedHeaders", valid_592971
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_592973: Call_CreateChannel_592962; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Channel.
  ## 
  let valid = call_592973.validator(path, query, header, formData, body)
  let scheme = call_592973.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592973.url(scheme.get, call_592973.host, call_592973.base,
                         call_592973.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592973, url, valid)

proc call*(call_592974: Call_CreateChannel_592962; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a new Channel.
  ##   body: JObject (required)
  var body_592975 = newJObject()
  if body != nil:
    body_592975 = body
  result = call_592974.call(nil, nil, nil, nil, body_592975)

var createChannel* = Call_CreateChannel_592962(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "mediapackage.amazonaws.com",
    route: "/channels", validator: validate_CreateChannel_592963, base: "/",
    url: url_CreateChannel_592964, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_592703 = ref object of OpenApiRestCall_592364
proc url_ListChannels_592705(protocol: Scheme; host: string; base: string;
                            route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListChannels_592704(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_592817 = query.getOrDefault("nextToken")
  valid_592817 = validateParameter(valid_592817, JString, required = false,
                                 default = nil)
  if valid_592817 != nil:
    section.add "nextToken", valid_592817
  var valid_592818 = query.getOrDefault("MaxResults")
  valid_592818 = validateParameter(valid_592818, JString, required = false,
                                 default = nil)
  if valid_592818 != nil:
    section.add "MaxResults", valid_592818
  var valid_592819 = query.getOrDefault("NextToken")
  valid_592819 = validateParameter(valid_592819, JString, required = false,
                                 default = nil)
  if valid_592819 != nil:
    section.add "NextToken", valid_592819
  var valid_592820 = query.getOrDefault("maxResults")
  valid_592820 = validateParameter(valid_592820, JInt, required = false, default = nil)
  if valid_592820 != nil:
    section.add "maxResults", valid_592820
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
  var valid_592821 = header.getOrDefault("X-Amz-Signature")
  valid_592821 = validateParameter(valid_592821, JString, required = false,
                                 default = nil)
  if valid_592821 != nil:
    section.add "X-Amz-Signature", valid_592821
  var valid_592822 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592822 = validateParameter(valid_592822, JString, required = false,
                                 default = nil)
  if valid_592822 != nil:
    section.add "X-Amz-Content-Sha256", valid_592822
  var valid_592823 = header.getOrDefault("X-Amz-Date")
  valid_592823 = validateParameter(valid_592823, JString, required = false,
                                 default = nil)
  if valid_592823 != nil:
    section.add "X-Amz-Date", valid_592823
  var valid_592824 = header.getOrDefault("X-Amz-Credential")
  valid_592824 = validateParameter(valid_592824, JString, required = false,
                                 default = nil)
  if valid_592824 != nil:
    section.add "X-Amz-Credential", valid_592824
  var valid_592825 = header.getOrDefault("X-Amz-Security-Token")
  valid_592825 = validateParameter(valid_592825, JString, required = false,
                                 default = nil)
  if valid_592825 != nil:
    section.add "X-Amz-Security-Token", valid_592825
  var valid_592826 = header.getOrDefault("X-Amz-Algorithm")
  valid_592826 = validateParameter(valid_592826, JString, required = false,
                                 default = nil)
  if valid_592826 != nil:
    section.add "X-Amz-Algorithm", valid_592826
  var valid_592827 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592827 = validateParameter(valid_592827, JString, required = false,
                                 default = nil)
  if valid_592827 != nil:
    section.add "X-Amz-SignedHeaders", valid_592827
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592850: Call_ListChannels_592703; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of Channels.
  ## 
  let valid = call_592850.validator(path, query, header, formData, body)
  let scheme = call_592850.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592850.url(scheme.get, call_592850.host, call_592850.base,
                         call_592850.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592850, url, valid)

proc call*(call_592921: Call_ListChannels_592703; nextToken: string = "";
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
  var query_592922 = newJObject()
  add(query_592922, "nextToken", newJString(nextToken))
  add(query_592922, "MaxResults", newJString(MaxResults))
  add(query_592922, "NextToken", newJString(NextToken))
  add(query_592922, "maxResults", newJInt(maxResults))
  result = call_592921.call(nil, query_592922, nil, nil, nil)

var listChannels* = Call_ListChannels_592703(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/channels", validator: validate_ListChannels_592704, base: "/",
    url: url_ListChannels_592705, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHarvestJob_592995 = ref object of OpenApiRestCall_592364
proc url_CreateHarvestJob_592997(protocol: Scheme; host: string; base: string;
                                route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateHarvestJob_592996(path: JsonNode; query: JsonNode;
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
  var valid_592998 = header.getOrDefault("X-Amz-Signature")
  valid_592998 = validateParameter(valid_592998, JString, required = false,
                                 default = nil)
  if valid_592998 != nil:
    section.add "X-Amz-Signature", valid_592998
  var valid_592999 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592999 = validateParameter(valid_592999, JString, required = false,
                                 default = nil)
  if valid_592999 != nil:
    section.add "X-Amz-Content-Sha256", valid_592999
  var valid_593000 = header.getOrDefault("X-Amz-Date")
  valid_593000 = validateParameter(valid_593000, JString, required = false,
                                 default = nil)
  if valid_593000 != nil:
    section.add "X-Amz-Date", valid_593000
  var valid_593001 = header.getOrDefault("X-Amz-Credential")
  valid_593001 = validateParameter(valid_593001, JString, required = false,
                                 default = nil)
  if valid_593001 != nil:
    section.add "X-Amz-Credential", valid_593001
  var valid_593002 = header.getOrDefault("X-Amz-Security-Token")
  valid_593002 = validateParameter(valid_593002, JString, required = false,
                                 default = nil)
  if valid_593002 != nil:
    section.add "X-Amz-Security-Token", valid_593002
  var valid_593003 = header.getOrDefault("X-Amz-Algorithm")
  valid_593003 = validateParameter(valid_593003, JString, required = false,
                                 default = nil)
  if valid_593003 != nil:
    section.add "X-Amz-Algorithm", valid_593003
  var valid_593004 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593004 = validateParameter(valid_593004, JString, required = false,
                                 default = nil)
  if valid_593004 != nil:
    section.add "X-Amz-SignedHeaders", valid_593004
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593006: Call_CreateHarvestJob_592995; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new HarvestJob record.
  ## 
  let valid = call_593006.validator(path, query, header, formData, body)
  let scheme = call_593006.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593006.url(scheme.get, call_593006.host, call_593006.base,
                         call_593006.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593006, url, valid)

proc call*(call_593007: Call_CreateHarvestJob_592995; body: JsonNode): Recallable =
  ## createHarvestJob
  ## Creates a new HarvestJob record.
  ##   body: JObject (required)
  var body_593008 = newJObject()
  if body != nil:
    body_593008 = body
  result = call_593007.call(nil, nil, nil, nil, body_593008)

var createHarvestJob* = Call_CreateHarvestJob_592995(name: "createHarvestJob",
    meth: HttpMethod.HttpPost, host: "mediapackage.amazonaws.com",
    route: "/harvest_jobs", validator: validate_CreateHarvestJob_592996, base: "/",
    url: url_CreateHarvestJob_592997, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHarvestJobs_592976 = ref object of OpenApiRestCall_592364
proc url_ListHarvestJobs_592978(protocol: Scheme; host: string; base: string;
                               route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListHarvestJobs_592977(path: JsonNode; query: JsonNode;
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
  var valid_592979 = query.getOrDefault("nextToken")
  valid_592979 = validateParameter(valid_592979, JString, required = false,
                                 default = nil)
  if valid_592979 != nil:
    section.add "nextToken", valid_592979
  var valid_592980 = query.getOrDefault("MaxResults")
  valid_592980 = validateParameter(valid_592980, JString, required = false,
                                 default = nil)
  if valid_592980 != nil:
    section.add "MaxResults", valid_592980
  var valid_592981 = query.getOrDefault("NextToken")
  valid_592981 = validateParameter(valid_592981, JString, required = false,
                                 default = nil)
  if valid_592981 != nil:
    section.add "NextToken", valid_592981
  var valid_592982 = query.getOrDefault("includeChannelId")
  valid_592982 = validateParameter(valid_592982, JString, required = false,
                                 default = nil)
  if valid_592982 != nil:
    section.add "includeChannelId", valid_592982
  var valid_592983 = query.getOrDefault("includeStatus")
  valid_592983 = validateParameter(valid_592983, JString, required = false,
                                 default = nil)
  if valid_592983 != nil:
    section.add "includeStatus", valid_592983
  var valid_592984 = query.getOrDefault("maxResults")
  valid_592984 = validateParameter(valid_592984, JInt, required = false, default = nil)
  if valid_592984 != nil:
    section.add "maxResults", valid_592984
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
  var valid_592985 = header.getOrDefault("X-Amz-Signature")
  valid_592985 = validateParameter(valid_592985, JString, required = false,
                                 default = nil)
  if valid_592985 != nil:
    section.add "X-Amz-Signature", valid_592985
  var valid_592986 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_592986 = validateParameter(valid_592986, JString, required = false,
                                 default = nil)
  if valid_592986 != nil:
    section.add "X-Amz-Content-Sha256", valid_592986
  var valid_592987 = header.getOrDefault("X-Amz-Date")
  valid_592987 = validateParameter(valid_592987, JString, required = false,
                                 default = nil)
  if valid_592987 != nil:
    section.add "X-Amz-Date", valid_592987
  var valid_592988 = header.getOrDefault("X-Amz-Credential")
  valid_592988 = validateParameter(valid_592988, JString, required = false,
                                 default = nil)
  if valid_592988 != nil:
    section.add "X-Amz-Credential", valid_592988
  var valid_592989 = header.getOrDefault("X-Amz-Security-Token")
  valid_592989 = validateParameter(valid_592989, JString, required = false,
                                 default = nil)
  if valid_592989 != nil:
    section.add "X-Amz-Security-Token", valid_592989
  var valid_592990 = header.getOrDefault("X-Amz-Algorithm")
  valid_592990 = validateParameter(valid_592990, JString, required = false,
                                 default = nil)
  if valid_592990 != nil:
    section.add "X-Amz-Algorithm", valid_592990
  var valid_592991 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_592991 = validateParameter(valid_592991, JString, required = false,
                                 default = nil)
  if valid_592991 != nil:
    section.add "X-Amz-SignedHeaders", valid_592991
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_592992: Call_ListHarvestJobs_592976; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of HarvestJob records.
  ## 
  let valid = call_592992.validator(path, query, header, formData, body)
  let scheme = call_592992.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_592992.url(scheme.get, call_592992.host, call_592992.base,
                         call_592992.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_592992, url, valid)

proc call*(call_592993: Call_ListHarvestJobs_592976; nextToken: string = "";
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
  var query_592994 = newJObject()
  add(query_592994, "nextToken", newJString(nextToken))
  add(query_592994, "MaxResults", newJString(MaxResults))
  add(query_592994, "NextToken", newJString(NextToken))
  add(query_592994, "includeChannelId", newJString(includeChannelId))
  add(query_592994, "includeStatus", newJString(includeStatus))
  add(query_592994, "maxResults", newJInt(maxResults))
  result = call_592993.call(nil, query_592994, nil, nil, nil)

var listHarvestJobs* = Call_ListHarvestJobs_592976(name: "listHarvestJobs",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/harvest_jobs", validator: validate_ListHarvestJobs_592977, base: "/",
    url: url_ListHarvestJobs_592978, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOriginEndpoint_593027 = ref object of OpenApiRestCall_592364
proc url_CreateOriginEndpoint_593029(protocol: Scheme; host: string; base: string;
                                    route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_CreateOriginEndpoint_593028(path: JsonNode; query: JsonNode;
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
  var valid_593030 = header.getOrDefault("X-Amz-Signature")
  valid_593030 = validateParameter(valid_593030, JString, required = false,
                                 default = nil)
  if valid_593030 != nil:
    section.add "X-Amz-Signature", valid_593030
  var valid_593031 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593031 = validateParameter(valid_593031, JString, required = false,
                                 default = nil)
  if valid_593031 != nil:
    section.add "X-Amz-Content-Sha256", valid_593031
  var valid_593032 = header.getOrDefault("X-Amz-Date")
  valid_593032 = validateParameter(valid_593032, JString, required = false,
                                 default = nil)
  if valid_593032 != nil:
    section.add "X-Amz-Date", valid_593032
  var valid_593033 = header.getOrDefault("X-Amz-Credential")
  valid_593033 = validateParameter(valid_593033, JString, required = false,
                                 default = nil)
  if valid_593033 != nil:
    section.add "X-Amz-Credential", valid_593033
  var valid_593034 = header.getOrDefault("X-Amz-Security-Token")
  valid_593034 = validateParameter(valid_593034, JString, required = false,
                                 default = nil)
  if valid_593034 != nil:
    section.add "X-Amz-Security-Token", valid_593034
  var valid_593035 = header.getOrDefault("X-Amz-Algorithm")
  valid_593035 = validateParameter(valid_593035, JString, required = false,
                                 default = nil)
  if valid_593035 != nil:
    section.add "X-Amz-Algorithm", valid_593035
  var valid_593036 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593036 = validateParameter(valid_593036, JString, required = false,
                                 default = nil)
  if valid_593036 != nil:
    section.add "X-Amz-SignedHeaders", valid_593036
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593038: Call_CreateOriginEndpoint_593027; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new OriginEndpoint record.
  ## 
  let valid = call_593038.validator(path, query, header, formData, body)
  let scheme = call_593038.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593038.url(scheme.get, call_593038.host, call_593038.base,
                         call_593038.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593038, url, valid)

proc call*(call_593039: Call_CreateOriginEndpoint_593027; body: JsonNode): Recallable =
  ## createOriginEndpoint
  ## Creates a new OriginEndpoint record.
  ##   body: JObject (required)
  var body_593040 = newJObject()
  if body != nil:
    body_593040 = body
  result = call_593039.call(nil, nil, nil, nil, body_593040)

var createOriginEndpoint* = Call_CreateOriginEndpoint_593027(
    name: "createOriginEndpoint", meth: HttpMethod.HttpPost,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints",
    validator: validate_CreateOriginEndpoint_593028, base: "/",
    url: url_CreateOriginEndpoint_593029, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOriginEndpoints_593009 = ref object of OpenApiRestCall_592364
proc url_ListOriginEndpoints_593011(protocol: Scheme; host: string; base: string;
                                   route: string; path: JsonNode; query: JsonNode): Uri =
  result.scheme = $protocol
  result.hostname = host
  result.query = $queryString(query)
  result.path = base & route

proc validate_ListOriginEndpoints_593010(path: JsonNode; query: JsonNode;
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
  var valid_593012 = query.getOrDefault("nextToken")
  valid_593012 = validateParameter(valid_593012, JString, required = false,
                                 default = nil)
  if valid_593012 != nil:
    section.add "nextToken", valid_593012
  var valid_593013 = query.getOrDefault("MaxResults")
  valid_593013 = validateParameter(valid_593013, JString, required = false,
                                 default = nil)
  if valid_593013 != nil:
    section.add "MaxResults", valid_593013
  var valid_593014 = query.getOrDefault("NextToken")
  valid_593014 = validateParameter(valid_593014, JString, required = false,
                                 default = nil)
  if valid_593014 != nil:
    section.add "NextToken", valid_593014
  var valid_593015 = query.getOrDefault("channelId")
  valid_593015 = validateParameter(valid_593015, JString, required = false,
                                 default = nil)
  if valid_593015 != nil:
    section.add "channelId", valid_593015
  var valid_593016 = query.getOrDefault("maxResults")
  valid_593016 = validateParameter(valid_593016, JInt, required = false, default = nil)
  if valid_593016 != nil:
    section.add "maxResults", valid_593016
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
  var valid_593017 = header.getOrDefault("X-Amz-Signature")
  valid_593017 = validateParameter(valid_593017, JString, required = false,
                                 default = nil)
  if valid_593017 != nil:
    section.add "X-Amz-Signature", valid_593017
  var valid_593018 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593018 = validateParameter(valid_593018, JString, required = false,
                                 default = nil)
  if valid_593018 != nil:
    section.add "X-Amz-Content-Sha256", valid_593018
  var valid_593019 = header.getOrDefault("X-Amz-Date")
  valid_593019 = validateParameter(valid_593019, JString, required = false,
                                 default = nil)
  if valid_593019 != nil:
    section.add "X-Amz-Date", valid_593019
  var valid_593020 = header.getOrDefault("X-Amz-Credential")
  valid_593020 = validateParameter(valid_593020, JString, required = false,
                                 default = nil)
  if valid_593020 != nil:
    section.add "X-Amz-Credential", valid_593020
  var valid_593021 = header.getOrDefault("X-Amz-Security-Token")
  valid_593021 = validateParameter(valid_593021, JString, required = false,
                                 default = nil)
  if valid_593021 != nil:
    section.add "X-Amz-Security-Token", valid_593021
  var valid_593022 = header.getOrDefault("X-Amz-Algorithm")
  valid_593022 = validateParameter(valid_593022, JString, required = false,
                                 default = nil)
  if valid_593022 != nil:
    section.add "X-Amz-Algorithm", valid_593022
  var valid_593023 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593023 = validateParameter(valid_593023, JString, required = false,
                                 default = nil)
  if valid_593023 != nil:
    section.add "X-Amz-SignedHeaders", valid_593023
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593024: Call_ListOriginEndpoints_593009; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of OriginEndpoint records.
  ## 
  let valid = call_593024.validator(path, query, header, formData, body)
  let scheme = call_593024.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593024.url(scheme.get, call_593024.host, call_593024.base,
                         call_593024.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593024, url, valid)

proc call*(call_593025: Call_ListOriginEndpoints_593009; nextToken: string = "";
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
  var query_593026 = newJObject()
  add(query_593026, "nextToken", newJString(nextToken))
  add(query_593026, "MaxResults", newJString(MaxResults))
  add(query_593026, "NextToken", newJString(NextToken))
  add(query_593026, "channelId", newJString(channelId))
  add(query_593026, "maxResults", newJInt(maxResults))
  result = call_593025.call(nil, query_593026, nil, nil, nil)

var listOriginEndpoints* = Call_ListOriginEndpoints_593009(
    name: "listOriginEndpoints", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints",
    validator: validate_ListOriginEndpoints_593010, base: "/",
    url: url_ListOriginEndpoints_593011, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_593069 = ref object of OpenApiRestCall_592364
proc url_UpdateChannel_593071(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateChannel_593070(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593072 = path.getOrDefault("id")
  valid_593072 = validateParameter(valid_593072, JString, required = true,
                                 default = nil)
  if valid_593072 != nil:
    section.add "id", valid_593072
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
  var valid_593073 = header.getOrDefault("X-Amz-Signature")
  valid_593073 = validateParameter(valid_593073, JString, required = false,
                                 default = nil)
  if valid_593073 != nil:
    section.add "X-Amz-Signature", valid_593073
  var valid_593074 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593074 = validateParameter(valid_593074, JString, required = false,
                                 default = nil)
  if valid_593074 != nil:
    section.add "X-Amz-Content-Sha256", valid_593074
  var valid_593075 = header.getOrDefault("X-Amz-Date")
  valid_593075 = validateParameter(valid_593075, JString, required = false,
                                 default = nil)
  if valid_593075 != nil:
    section.add "X-Amz-Date", valid_593075
  var valid_593076 = header.getOrDefault("X-Amz-Credential")
  valid_593076 = validateParameter(valid_593076, JString, required = false,
                                 default = nil)
  if valid_593076 != nil:
    section.add "X-Amz-Credential", valid_593076
  var valid_593077 = header.getOrDefault("X-Amz-Security-Token")
  valid_593077 = validateParameter(valid_593077, JString, required = false,
                                 default = nil)
  if valid_593077 != nil:
    section.add "X-Amz-Security-Token", valid_593077
  var valid_593078 = header.getOrDefault("X-Amz-Algorithm")
  valid_593078 = validateParameter(valid_593078, JString, required = false,
                                 default = nil)
  if valid_593078 != nil:
    section.add "X-Amz-Algorithm", valid_593078
  var valid_593079 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593079 = validateParameter(valid_593079, JString, required = false,
                                 default = nil)
  if valid_593079 != nil:
    section.add "X-Amz-SignedHeaders", valid_593079
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593081: Call_UpdateChannel_593069; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing Channel.
  ## 
  let valid = call_593081.validator(path, query, header, formData, body)
  let scheme = call_593081.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593081.url(scheme.get, call_593081.host, call_593081.base,
                         call_593081.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593081, url, valid)

proc call*(call_593082: Call_UpdateChannel_593069; id: string; body: JsonNode): Recallable =
  ## updateChannel
  ## Updates an existing Channel.
  ##   id: string (required)
  ##     : The ID of the Channel to update.
  ##   body: JObject (required)
  var path_593083 = newJObject()
  var body_593084 = newJObject()
  add(path_593083, "id", newJString(id))
  if body != nil:
    body_593084 = body
  result = call_593082.call(path_593083, nil, nil, nil, body_593084)

var updateChannel* = Call_UpdateChannel_593069(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_UpdateChannel_593070, base: "/",
    url: url_UpdateChannel_593071, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_593041 = ref object of OpenApiRestCall_592364
proc url_DescribeChannel_593043(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeChannel_593042(path: JsonNode; query: JsonNode;
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
  var valid_593058 = path.getOrDefault("id")
  valid_593058 = validateParameter(valid_593058, JString, required = true,
                                 default = nil)
  if valid_593058 != nil:
    section.add "id", valid_593058
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
  var valid_593059 = header.getOrDefault("X-Amz-Signature")
  valid_593059 = validateParameter(valid_593059, JString, required = false,
                                 default = nil)
  if valid_593059 != nil:
    section.add "X-Amz-Signature", valid_593059
  var valid_593060 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593060 = validateParameter(valid_593060, JString, required = false,
                                 default = nil)
  if valid_593060 != nil:
    section.add "X-Amz-Content-Sha256", valid_593060
  var valid_593061 = header.getOrDefault("X-Amz-Date")
  valid_593061 = validateParameter(valid_593061, JString, required = false,
                                 default = nil)
  if valid_593061 != nil:
    section.add "X-Amz-Date", valid_593061
  var valid_593062 = header.getOrDefault("X-Amz-Credential")
  valid_593062 = validateParameter(valid_593062, JString, required = false,
                                 default = nil)
  if valid_593062 != nil:
    section.add "X-Amz-Credential", valid_593062
  var valid_593063 = header.getOrDefault("X-Amz-Security-Token")
  valid_593063 = validateParameter(valid_593063, JString, required = false,
                                 default = nil)
  if valid_593063 != nil:
    section.add "X-Amz-Security-Token", valid_593063
  var valid_593064 = header.getOrDefault("X-Amz-Algorithm")
  valid_593064 = validateParameter(valid_593064, JString, required = false,
                                 default = nil)
  if valid_593064 != nil:
    section.add "X-Amz-Algorithm", valid_593064
  var valid_593065 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593065 = validateParameter(valid_593065, JString, required = false,
                                 default = nil)
  if valid_593065 != nil:
    section.add "X-Amz-SignedHeaders", valid_593065
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593066: Call_DescribeChannel_593041; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a Channel.
  ## 
  let valid = call_593066.validator(path, query, header, formData, body)
  let scheme = call_593066.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593066.url(scheme.get, call_593066.host, call_593066.base,
                         call_593066.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593066, url, valid)

proc call*(call_593067: Call_DescribeChannel_593041; id: string): Recallable =
  ## describeChannel
  ## Gets details about a Channel.
  ##   id: string (required)
  ##     : The ID of a Channel.
  var path_593068 = newJObject()
  add(path_593068, "id", newJString(id))
  result = call_593067.call(path_593068, nil, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_593041(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_DescribeChannel_593042, base: "/",
    url: url_DescribeChannel_593043, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_593085 = ref object of OpenApiRestCall_592364
proc url_DeleteChannel_593087(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteChannel_593086(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_593088 = path.getOrDefault("id")
  valid_593088 = validateParameter(valid_593088, JString, required = true,
                                 default = nil)
  if valid_593088 != nil:
    section.add "id", valid_593088
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
  var valid_593089 = header.getOrDefault("X-Amz-Signature")
  valid_593089 = validateParameter(valid_593089, JString, required = false,
                                 default = nil)
  if valid_593089 != nil:
    section.add "X-Amz-Signature", valid_593089
  var valid_593090 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593090 = validateParameter(valid_593090, JString, required = false,
                                 default = nil)
  if valid_593090 != nil:
    section.add "X-Amz-Content-Sha256", valid_593090
  var valid_593091 = header.getOrDefault("X-Amz-Date")
  valid_593091 = validateParameter(valid_593091, JString, required = false,
                                 default = nil)
  if valid_593091 != nil:
    section.add "X-Amz-Date", valid_593091
  var valid_593092 = header.getOrDefault("X-Amz-Credential")
  valid_593092 = validateParameter(valid_593092, JString, required = false,
                                 default = nil)
  if valid_593092 != nil:
    section.add "X-Amz-Credential", valid_593092
  var valid_593093 = header.getOrDefault("X-Amz-Security-Token")
  valid_593093 = validateParameter(valid_593093, JString, required = false,
                                 default = nil)
  if valid_593093 != nil:
    section.add "X-Amz-Security-Token", valid_593093
  var valid_593094 = header.getOrDefault("X-Amz-Algorithm")
  valid_593094 = validateParameter(valid_593094, JString, required = false,
                                 default = nil)
  if valid_593094 != nil:
    section.add "X-Amz-Algorithm", valid_593094
  var valid_593095 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593095 = validateParameter(valid_593095, JString, required = false,
                                 default = nil)
  if valid_593095 != nil:
    section.add "X-Amz-SignedHeaders", valid_593095
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593096: Call_DeleteChannel_593085; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing Channel.
  ## 
  let valid = call_593096.validator(path, query, header, formData, body)
  let scheme = call_593096.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593096.url(scheme.get, call_593096.host, call_593096.base,
                         call_593096.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593096, url, valid)

proc call*(call_593097: Call_DeleteChannel_593085; id: string): Recallable =
  ## deleteChannel
  ## Deletes an existing Channel.
  ##   id: string (required)
  ##     : The ID of the Channel to delete.
  var path_593098 = newJObject()
  add(path_593098, "id", newJString(id))
  result = call_593097.call(path_593098, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_593085(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_DeleteChannel_593086, base: "/",
    url: url_DeleteChannel_593087, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOriginEndpoint_593113 = ref object of OpenApiRestCall_592364
proc url_UpdateOriginEndpoint_593115(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UpdateOriginEndpoint_593114(path: JsonNode; query: JsonNode;
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
  var valid_593116 = path.getOrDefault("id")
  valid_593116 = validateParameter(valid_593116, JString, required = true,
                                 default = nil)
  if valid_593116 != nil:
    section.add "id", valid_593116
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
  var valid_593117 = header.getOrDefault("X-Amz-Signature")
  valid_593117 = validateParameter(valid_593117, JString, required = false,
                                 default = nil)
  if valid_593117 != nil:
    section.add "X-Amz-Signature", valid_593117
  var valid_593118 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593118 = validateParameter(valid_593118, JString, required = false,
                                 default = nil)
  if valid_593118 != nil:
    section.add "X-Amz-Content-Sha256", valid_593118
  var valid_593119 = header.getOrDefault("X-Amz-Date")
  valid_593119 = validateParameter(valid_593119, JString, required = false,
                                 default = nil)
  if valid_593119 != nil:
    section.add "X-Amz-Date", valid_593119
  var valid_593120 = header.getOrDefault("X-Amz-Credential")
  valid_593120 = validateParameter(valid_593120, JString, required = false,
                                 default = nil)
  if valid_593120 != nil:
    section.add "X-Amz-Credential", valid_593120
  var valid_593121 = header.getOrDefault("X-Amz-Security-Token")
  valid_593121 = validateParameter(valid_593121, JString, required = false,
                                 default = nil)
  if valid_593121 != nil:
    section.add "X-Amz-Security-Token", valid_593121
  var valid_593122 = header.getOrDefault("X-Amz-Algorithm")
  valid_593122 = validateParameter(valid_593122, JString, required = false,
                                 default = nil)
  if valid_593122 != nil:
    section.add "X-Amz-Algorithm", valid_593122
  var valid_593123 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593123 = validateParameter(valid_593123, JString, required = false,
                                 default = nil)
  if valid_593123 != nil:
    section.add "X-Amz-SignedHeaders", valid_593123
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593125: Call_UpdateOriginEndpoint_593113; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing OriginEndpoint.
  ## 
  let valid = call_593125.validator(path, query, header, formData, body)
  let scheme = call_593125.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593125.url(scheme.get, call_593125.host, call_593125.base,
                         call_593125.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593125, url, valid)

proc call*(call_593126: Call_UpdateOriginEndpoint_593113; id: string; body: JsonNode): Recallable =
  ## updateOriginEndpoint
  ## Updates an existing OriginEndpoint.
  ##   id: string (required)
  ##     : The ID of the OriginEndpoint to update.
  ##   body: JObject (required)
  var path_593127 = newJObject()
  var body_593128 = newJObject()
  add(path_593127, "id", newJString(id))
  if body != nil:
    body_593128 = body
  result = call_593126.call(path_593127, nil, nil, nil, body_593128)

var updateOriginEndpoint* = Call_UpdateOriginEndpoint_593113(
    name: "updateOriginEndpoint", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_UpdateOriginEndpoint_593114, base: "/",
    url: url_UpdateOriginEndpoint_593115, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOriginEndpoint_593099 = ref object of OpenApiRestCall_592364
proc url_DescribeOriginEndpoint_593101(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeOriginEndpoint_593100(path: JsonNode; query: JsonNode;
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
  var valid_593102 = path.getOrDefault("id")
  valid_593102 = validateParameter(valid_593102, JString, required = true,
                                 default = nil)
  if valid_593102 != nil:
    section.add "id", valid_593102
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
  var valid_593103 = header.getOrDefault("X-Amz-Signature")
  valid_593103 = validateParameter(valid_593103, JString, required = false,
                                 default = nil)
  if valid_593103 != nil:
    section.add "X-Amz-Signature", valid_593103
  var valid_593104 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593104 = validateParameter(valid_593104, JString, required = false,
                                 default = nil)
  if valid_593104 != nil:
    section.add "X-Amz-Content-Sha256", valid_593104
  var valid_593105 = header.getOrDefault("X-Amz-Date")
  valid_593105 = validateParameter(valid_593105, JString, required = false,
                                 default = nil)
  if valid_593105 != nil:
    section.add "X-Amz-Date", valid_593105
  var valid_593106 = header.getOrDefault("X-Amz-Credential")
  valid_593106 = validateParameter(valid_593106, JString, required = false,
                                 default = nil)
  if valid_593106 != nil:
    section.add "X-Amz-Credential", valid_593106
  var valid_593107 = header.getOrDefault("X-Amz-Security-Token")
  valid_593107 = validateParameter(valid_593107, JString, required = false,
                                 default = nil)
  if valid_593107 != nil:
    section.add "X-Amz-Security-Token", valid_593107
  var valid_593108 = header.getOrDefault("X-Amz-Algorithm")
  valid_593108 = validateParameter(valid_593108, JString, required = false,
                                 default = nil)
  if valid_593108 != nil:
    section.add "X-Amz-Algorithm", valid_593108
  var valid_593109 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593109 = validateParameter(valid_593109, JString, required = false,
                                 default = nil)
  if valid_593109 != nil:
    section.add "X-Amz-SignedHeaders", valid_593109
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593110: Call_DescribeOriginEndpoint_593099; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about an existing OriginEndpoint.
  ## 
  let valid = call_593110.validator(path, query, header, formData, body)
  let scheme = call_593110.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593110.url(scheme.get, call_593110.host, call_593110.base,
                         call_593110.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593110, url, valid)

proc call*(call_593111: Call_DescribeOriginEndpoint_593099; id: string): Recallable =
  ## describeOriginEndpoint
  ## Gets details about an existing OriginEndpoint.
  ##   id: string (required)
  ##     : The ID of the OriginEndpoint.
  var path_593112 = newJObject()
  add(path_593112, "id", newJString(id))
  result = call_593111.call(path_593112, nil, nil, nil, nil)

var describeOriginEndpoint* = Call_DescribeOriginEndpoint_593099(
    name: "describeOriginEndpoint", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_DescribeOriginEndpoint_593100, base: "/",
    url: url_DescribeOriginEndpoint_593101, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOriginEndpoint_593129 = ref object of OpenApiRestCall_592364
proc url_DeleteOriginEndpoint_593131(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DeleteOriginEndpoint_593130(path: JsonNode; query: JsonNode;
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
  var valid_593132 = path.getOrDefault("id")
  valid_593132 = validateParameter(valid_593132, JString, required = true,
                                 default = nil)
  if valid_593132 != nil:
    section.add "id", valid_593132
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
  var valid_593133 = header.getOrDefault("X-Amz-Signature")
  valid_593133 = validateParameter(valid_593133, JString, required = false,
                                 default = nil)
  if valid_593133 != nil:
    section.add "X-Amz-Signature", valid_593133
  var valid_593134 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593134 = validateParameter(valid_593134, JString, required = false,
                                 default = nil)
  if valid_593134 != nil:
    section.add "X-Amz-Content-Sha256", valid_593134
  var valid_593135 = header.getOrDefault("X-Amz-Date")
  valid_593135 = validateParameter(valid_593135, JString, required = false,
                                 default = nil)
  if valid_593135 != nil:
    section.add "X-Amz-Date", valid_593135
  var valid_593136 = header.getOrDefault("X-Amz-Credential")
  valid_593136 = validateParameter(valid_593136, JString, required = false,
                                 default = nil)
  if valid_593136 != nil:
    section.add "X-Amz-Credential", valid_593136
  var valid_593137 = header.getOrDefault("X-Amz-Security-Token")
  valid_593137 = validateParameter(valid_593137, JString, required = false,
                                 default = nil)
  if valid_593137 != nil:
    section.add "X-Amz-Security-Token", valid_593137
  var valid_593138 = header.getOrDefault("X-Amz-Algorithm")
  valid_593138 = validateParameter(valid_593138, JString, required = false,
                                 default = nil)
  if valid_593138 != nil:
    section.add "X-Amz-Algorithm", valid_593138
  var valid_593139 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593139 = validateParameter(valid_593139, JString, required = false,
                                 default = nil)
  if valid_593139 != nil:
    section.add "X-Amz-SignedHeaders", valid_593139
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593140: Call_DeleteOriginEndpoint_593129; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing OriginEndpoint.
  ## 
  let valid = call_593140.validator(path, query, header, formData, body)
  let scheme = call_593140.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593140.url(scheme.get, call_593140.host, call_593140.base,
                         call_593140.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593140, url, valid)

proc call*(call_593141: Call_DeleteOriginEndpoint_593129; id: string): Recallable =
  ## deleteOriginEndpoint
  ## Deletes an existing OriginEndpoint.
  ##   id: string (required)
  ##     : The ID of the OriginEndpoint to delete.
  var path_593142 = newJObject()
  add(path_593142, "id", newJString(id))
  result = call_593141.call(path_593142, nil, nil, nil, nil)

var deleteOriginEndpoint* = Call_DeleteOriginEndpoint_593129(
    name: "deleteOriginEndpoint", meth: HttpMethod.HttpDelete,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_DeleteOriginEndpoint_593130, base: "/",
    url: url_DeleteOriginEndpoint_593131, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHarvestJob_593143 = ref object of OpenApiRestCall_592364
proc url_DescribeHarvestJob_593145(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_DescribeHarvestJob_593144(path: JsonNode; query: JsonNode;
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
  var valid_593146 = path.getOrDefault("id")
  valid_593146 = validateParameter(valid_593146, JString, required = true,
                                 default = nil)
  if valid_593146 != nil:
    section.add "id", valid_593146
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
  var valid_593147 = header.getOrDefault("X-Amz-Signature")
  valid_593147 = validateParameter(valid_593147, JString, required = false,
                                 default = nil)
  if valid_593147 != nil:
    section.add "X-Amz-Signature", valid_593147
  var valid_593148 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593148 = validateParameter(valid_593148, JString, required = false,
                                 default = nil)
  if valid_593148 != nil:
    section.add "X-Amz-Content-Sha256", valid_593148
  var valid_593149 = header.getOrDefault("X-Amz-Date")
  valid_593149 = validateParameter(valid_593149, JString, required = false,
                                 default = nil)
  if valid_593149 != nil:
    section.add "X-Amz-Date", valid_593149
  var valid_593150 = header.getOrDefault("X-Amz-Credential")
  valid_593150 = validateParameter(valid_593150, JString, required = false,
                                 default = nil)
  if valid_593150 != nil:
    section.add "X-Amz-Credential", valid_593150
  var valid_593151 = header.getOrDefault("X-Amz-Security-Token")
  valid_593151 = validateParameter(valid_593151, JString, required = false,
                                 default = nil)
  if valid_593151 != nil:
    section.add "X-Amz-Security-Token", valid_593151
  var valid_593152 = header.getOrDefault("X-Amz-Algorithm")
  valid_593152 = validateParameter(valid_593152, JString, required = false,
                                 default = nil)
  if valid_593152 != nil:
    section.add "X-Amz-Algorithm", valid_593152
  var valid_593153 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593153 = validateParameter(valid_593153, JString, required = false,
                                 default = nil)
  if valid_593153 != nil:
    section.add "X-Amz-SignedHeaders", valid_593153
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593154: Call_DescribeHarvestJob_593143; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about an existing HarvestJob.
  ## 
  let valid = call_593154.validator(path, query, header, formData, body)
  let scheme = call_593154.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593154.url(scheme.get, call_593154.host, call_593154.base,
                         call_593154.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593154, url, valid)

proc call*(call_593155: Call_DescribeHarvestJob_593143; id: string): Recallable =
  ## describeHarvestJob
  ## Gets details about an existing HarvestJob.
  ##   id: string (required)
  ##     : The ID of the HarvestJob.
  var path_593156 = newJObject()
  add(path_593156, "id", newJString(id))
  result = call_593155.call(path_593156, nil, nil, nil, nil)

var describeHarvestJob* = Call_DescribeHarvestJob_593143(
    name: "describeHarvestJob", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/harvest_jobs/{id}",
    validator: validate_DescribeHarvestJob_593144, base: "/",
    url: url_DescribeHarvestJob_593145, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_593171 = ref object of OpenApiRestCall_592364
proc url_TagResource_593173(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_TagResource_593172(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_593174 = path.getOrDefault("resource-arn")
  valid_593174 = validateParameter(valid_593174, JString, required = true,
                                 default = nil)
  if valid_593174 != nil:
    section.add "resource-arn", valid_593174
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
  var valid_593175 = header.getOrDefault("X-Amz-Signature")
  valid_593175 = validateParameter(valid_593175, JString, required = false,
                                 default = nil)
  if valid_593175 != nil:
    section.add "X-Amz-Signature", valid_593175
  var valid_593176 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593176 = validateParameter(valid_593176, JString, required = false,
                                 default = nil)
  if valid_593176 != nil:
    section.add "X-Amz-Content-Sha256", valid_593176
  var valid_593177 = header.getOrDefault("X-Amz-Date")
  valid_593177 = validateParameter(valid_593177, JString, required = false,
                                 default = nil)
  if valid_593177 != nil:
    section.add "X-Amz-Date", valid_593177
  var valid_593178 = header.getOrDefault("X-Amz-Credential")
  valid_593178 = validateParameter(valid_593178, JString, required = false,
                                 default = nil)
  if valid_593178 != nil:
    section.add "X-Amz-Credential", valid_593178
  var valid_593179 = header.getOrDefault("X-Amz-Security-Token")
  valid_593179 = validateParameter(valid_593179, JString, required = false,
                                 default = nil)
  if valid_593179 != nil:
    section.add "X-Amz-Security-Token", valid_593179
  var valid_593180 = header.getOrDefault("X-Amz-Algorithm")
  valid_593180 = validateParameter(valid_593180, JString, required = false,
                                 default = nil)
  if valid_593180 != nil:
    section.add "X-Amz-Algorithm", valid_593180
  var valid_593181 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593181 = validateParameter(valid_593181, JString, required = false,
                                 default = nil)
  if valid_593181 != nil:
    section.add "X-Amz-SignedHeaders", valid_593181
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_593183: Call_TagResource_593171; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593183.validator(path, query, header, formData, body)
  let scheme = call_593183.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593183.url(scheme.get, call_593183.host, call_593183.base,
                         call_593183.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593183, url, valid)

proc call*(call_593184: Call_TagResource_593171; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ##   resourceArn: string (required)
  ##   body: JObject (required)
  var path_593185 = newJObject()
  var body_593186 = newJObject()
  add(path_593185, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_593186 = body
  result = call_593184.call(path_593185, nil, nil, nil, body_593186)

var tagResource* = Call_TagResource_593171(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediapackage.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_593172,
                                        base: "/", url: url_TagResource_593173,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_593157 = ref object of OpenApiRestCall_592364
proc url_ListTagsForResource_593159(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_ListTagsForResource_593158(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_593160 = path.getOrDefault("resource-arn")
  valid_593160 = validateParameter(valid_593160, JString, required = true,
                                 default = nil)
  if valid_593160 != nil:
    section.add "resource-arn", valid_593160
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
  var valid_593161 = header.getOrDefault("X-Amz-Signature")
  valid_593161 = validateParameter(valid_593161, JString, required = false,
                                 default = nil)
  if valid_593161 != nil:
    section.add "X-Amz-Signature", valid_593161
  var valid_593162 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593162 = validateParameter(valid_593162, JString, required = false,
                                 default = nil)
  if valid_593162 != nil:
    section.add "X-Amz-Content-Sha256", valid_593162
  var valid_593163 = header.getOrDefault("X-Amz-Date")
  valid_593163 = validateParameter(valid_593163, JString, required = false,
                                 default = nil)
  if valid_593163 != nil:
    section.add "X-Amz-Date", valid_593163
  var valid_593164 = header.getOrDefault("X-Amz-Credential")
  valid_593164 = validateParameter(valid_593164, JString, required = false,
                                 default = nil)
  if valid_593164 != nil:
    section.add "X-Amz-Credential", valid_593164
  var valid_593165 = header.getOrDefault("X-Amz-Security-Token")
  valid_593165 = validateParameter(valid_593165, JString, required = false,
                                 default = nil)
  if valid_593165 != nil:
    section.add "X-Amz-Security-Token", valid_593165
  var valid_593166 = header.getOrDefault("X-Amz-Algorithm")
  valid_593166 = validateParameter(valid_593166, JString, required = false,
                                 default = nil)
  if valid_593166 != nil:
    section.add "X-Amz-Algorithm", valid_593166
  var valid_593167 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593167 = validateParameter(valid_593167, JString, required = false,
                                 default = nil)
  if valid_593167 != nil:
    section.add "X-Amz-SignedHeaders", valid_593167
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593168: Call_ListTagsForResource_593157; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593168.validator(path, query, header, formData, body)
  let scheme = call_593168.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593168.url(scheme.get, call_593168.host, call_593168.base,
                         call_593168.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593168, url, valid)

proc call*(call_593169: Call_ListTagsForResource_593157; resourceArn: string): Recallable =
  ## listTagsForResource
  ##   resourceArn: string (required)
  var path_593170 = newJObject()
  add(path_593170, "resource-arn", newJString(resourceArn))
  result = call_593169.call(path_593170, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_593157(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_593158, base: "/",
    url: url_ListTagsForResource_593159, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RotateChannelCredentials_593187 = ref object of OpenApiRestCall_592364
proc url_RotateChannelCredentials_593189(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_RotateChannelCredentials_593188(path: JsonNode; query: JsonNode;
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
  var valid_593190 = path.getOrDefault("id")
  valid_593190 = validateParameter(valid_593190, JString, required = true,
                                 default = nil)
  if valid_593190 != nil:
    section.add "id", valid_593190
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
  var valid_593191 = header.getOrDefault("X-Amz-Signature")
  valid_593191 = validateParameter(valid_593191, JString, required = false,
                                 default = nil)
  if valid_593191 != nil:
    section.add "X-Amz-Signature", valid_593191
  var valid_593192 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593192 = validateParameter(valid_593192, JString, required = false,
                                 default = nil)
  if valid_593192 != nil:
    section.add "X-Amz-Content-Sha256", valid_593192
  var valid_593193 = header.getOrDefault("X-Amz-Date")
  valid_593193 = validateParameter(valid_593193, JString, required = false,
                                 default = nil)
  if valid_593193 != nil:
    section.add "X-Amz-Date", valid_593193
  var valid_593194 = header.getOrDefault("X-Amz-Credential")
  valid_593194 = validateParameter(valid_593194, JString, required = false,
                                 default = nil)
  if valid_593194 != nil:
    section.add "X-Amz-Credential", valid_593194
  var valid_593195 = header.getOrDefault("X-Amz-Security-Token")
  valid_593195 = validateParameter(valid_593195, JString, required = false,
                                 default = nil)
  if valid_593195 != nil:
    section.add "X-Amz-Security-Token", valid_593195
  var valid_593196 = header.getOrDefault("X-Amz-Algorithm")
  valid_593196 = validateParameter(valid_593196, JString, required = false,
                                 default = nil)
  if valid_593196 != nil:
    section.add "X-Amz-Algorithm", valid_593196
  var valid_593197 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593197 = validateParameter(valid_593197, JString, required = false,
                                 default = nil)
  if valid_593197 != nil:
    section.add "X-Amz-SignedHeaders", valid_593197
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593198: Call_RotateChannelCredentials_593187; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
  ## 
  let valid = call_593198.validator(path, query, header, formData, body)
  let scheme = call_593198.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593198.url(scheme.get, call_593198.host, call_593198.base,
                         call_593198.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593198, url, valid)

proc call*(call_593199: Call_RotateChannelCredentials_593187; id: string): Recallable =
  ## rotateChannelCredentials
  ## Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
  ##   id: string (required)
  ##     : The ID of the channel to update.
  var path_593200 = newJObject()
  add(path_593200, "id", newJString(id))
  result = call_593199.call(path_593200, nil, nil, nil, nil)

var rotateChannelCredentials* = Call_RotateChannelCredentials_593187(
    name: "rotateChannelCredentials", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com", route: "/channels/{id}/credentials",
    validator: validate_RotateChannelCredentials_593188, base: "/",
    url: url_RotateChannelCredentials_593189, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RotateIngestEndpointCredentials_593201 = ref object of OpenApiRestCall_592364
proc url_RotateIngestEndpointCredentials_593203(protocol: Scheme; host: string;
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
  result.path = base & hydrated.get

proc validate_RotateIngestEndpointCredentials_593202(path: JsonNode;
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
  var valid_593204 = path.getOrDefault("id")
  valid_593204 = validateParameter(valid_593204, JString, required = true,
                                 default = nil)
  if valid_593204 != nil:
    section.add "id", valid_593204
  var valid_593205 = path.getOrDefault("ingest_endpoint_id")
  valid_593205 = validateParameter(valid_593205, JString, required = true,
                                 default = nil)
  if valid_593205 != nil:
    section.add "ingest_endpoint_id", valid_593205
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
  var valid_593206 = header.getOrDefault("X-Amz-Signature")
  valid_593206 = validateParameter(valid_593206, JString, required = false,
                                 default = nil)
  if valid_593206 != nil:
    section.add "X-Amz-Signature", valid_593206
  var valid_593207 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593207 = validateParameter(valid_593207, JString, required = false,
                                 default = nil)
  if valid_593207 != nil:
    section.add "X-Amz-Content-Sha256", valid_593207
  var valid_593208 = header.getOrDefault("X-Amz-Date")
  valid_593208 = validateParameter(valid_593208, JString, required = false,
                                 default = nil)
  if valid_593208 != nil:
    section.add "X-Amz-Date", valid_593208
  var valid_593209 = header.getOrDefault("X-Amz-Credential")
  valid_593209 = validateParameter(valid_593209, JString, required = false,
                                 default = nil)
  if valid_593209 != nil:
    section.add "X-Amz-Credential", valid_593209
  var valid_593210 = header.getOrDefault("X-Amz-Security-Token")
  valid_593210 = validateParameter(valid_593210, JString, required = false,
                                 default = nil)
  if valid_593210 != nil:
    section.add "X-Amz-Security-Token", valid_593210
  var valid_593211 = header.getOrDefault("X-Amz-Algorithm")
  valid_593211 = validateParameter(valid_593211, JString, required = false,
                                 default = nil)
  if valid_593211 != nil:
    section.add "X-Amz-Algorithm", valid_593211
  var valid_593212 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593212 = validateParameter(valid_593212, JString, required = false,
                                 default = nil)
  if valid_593212 != nil:
    section.add "X-Amz-SignedHeaders", valid_593212
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593213: Call_RotateIngestEndpointCredentials_593201;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
  ## 
  let valid = call_593213.validator(path, query, header, formData, body)
  let scheme = call_593213.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593213.url(scheme.get, call_593213.host, call_593213.base,
                         call_593213.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593213, url, valid)

proc call*(call_593214: Call_RotateIngestEndpointCredentials_593201; id: string;
          ingestEndpointId: string): Recallable =
  ## rotateIngestEndpointCredentials
  ## Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
  ##   id: string (required)
  ##     : The ID of the channel the IngestEndpoint is on.
  ##   ingestEndpointId: string (required)
  ##                   : The id of the IngestEndpoint whose credentials should be rotated
  var path_593215 = newJObject()
  add(path_593215, "id", newJString(id))
  add(path_593215, "ingest_endpoint_id", newJString(ingestEndpointId))
  result = call_593214.call(path_593215, nil, nil, nil, nil)

var rotateIngestEndpointCredentials* = Call_RotateIngestEndpointCredentials_593201(
    name: "rotateIngestEndpointCredentials", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com",
    route: "/channels/{id}/ingest_endpoints/{ingest_endpoint_id}/credentials",
    validator: validate_RotateIngestEndpointCredentials_593202, base: "/",
    url: url_RotateIngestEndpointCredentials_593203,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_593216 = ref object of OpenApiRestCall_592364
proc url_UntagResource_593218(protocol: Scheme; host: string; base: string;
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
  result.path = base & hydrated.get

proc validate_UntagResource_593217(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_593219 = path.getOrDefault("resource-arn")
  valid_593219 = validateParameter(valid_593219, JString, required = true,
                                 default = nil)
  if valid_593219 != nil:
    section.add "resource-arn", valid_593219
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key(s) of tag to be deleted
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_593220 = query.getOrDefault("tagKeys")
  valid_593220 = validateParameter(valid_593220, JArray, required = true, default = nil)
  if valid_593220 != nil:
    section.add "tagKeys", valid_593220
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
  var valid_593221 = header.getOrDefault("X-Amz-Signature")
  valid_593221 = validateParameter(valid_593221, JString, required = false,
                                 default = nil)
  if valid_593221 != nil:
    section.add "X-Amz-Signature", valid_593221
  var valid_593222 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_593222 = validateParameter(valid_593222, JString, required = false,
                                 default = nil)
  if valid_593222 != nil:
    section.add "X-Amz-Content-Sha256", valid_593222
  var valid_593223 = header.getOrDefault("X-Amz-Date")
  valid_593223 = validateParameter(valid_593223, JString, required = false,
                                 default = nil)
  if valid_593223 != nil:
    section.add "X-Amz-Date", valid_593223
  var valid_593224 = header.getOrDefault("X-Amz-Credential")
  valid_593224 = validateParameter(valid_593224, JString, required = false,
                                 default = nil)
  if valid_593224 != nil:
    section.add "X-Amz-Credential", valid_593224
  var valid_593225 = header.getOrDefault("X-Amz-Security-Token")
  valid_593225 = validateParameter(valid_593225, JString, required = false,
                                 default = nil)
  if valid_593225 != nil:
    section.add "X-Amz-Security-Token", valid_593225
  var valid_593226 = header.getOrDefault("X-Amz-Algorithm")
  valid_593226 = validateParameter(valid_593226, JString, required = false,
                                 default = nil)
  if valid_593226 != nil:
    section.add "X-Amz-Algorithm", valid_593226
  var valid_593227 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_593227 = validateParameter(valid_593227, JString, required = false,
                                 default = nil)
  if valid_593227 != nil:
    section.add "X-Amz-SignedHeaders", valid_593227
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_593228: Call_UntagResource_593216; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_593228.validator(path, query, header, formData, body)
  let scheme = call_593228.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_593228.url(scheme.get, call_593228.host, call_593228.base,
                         call_593228.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = hook(call_593228, url, valid)

proc call*(call_593229: Call_UntagResource_593216; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ##   resourceArn: string (required)
  ##   tagKeys: JArray (required)
  ##          : The key(s) of tag to be deleted
  var path_593230 = newJObject()
  var query_593231 = newJObject()
  add(path_593230, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_593231.add "tagKeys", tagKeys
  result = call_593229.call(path_593230, query_593231, nil, nil, nil)

var untagResource* = Call_UntagResource_593216(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "mediapackage.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_593217,
    base: "/", url: url_UntagResource_593218, schemes: {Scheme.Https, Scheme.Http})
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
