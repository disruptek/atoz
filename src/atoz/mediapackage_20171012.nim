
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

  OpenApiRestCall_601389 = ref object of OpenApiRestCall
proc hash(scheme: Scheme): Hash {.used.} =
  result = hash(ord(scheme))

proc clone[T: OpenApiRestCall_601389](t: T): T {.used.} =
  result = T(name: t.name, meth: t.meth, host: t.host, base: t.base, route: t.route,
           schemes: t.schemes, validator: t.validator, url: t.url)

proc pickScheme(t: OpenApiRestCall_601389): Option[Scheme] {.used.} =
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
  Call_CreateChannel_601986 = ref object of OpenApiRestCall_601389
proc url_CreateChannel_601988(protocol: Scheme; host: string; base: string;
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

proc validate_CreateChannel_601987(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601989 = header.getOrDefault("X-Amz-Signature")
  valid_601989 = validateParameter(valid_601989, JString, required = false,
                                 default = nil)
  if valid_601989 != nil:
    section.add "X-Amz-Signature", valid_601989
  var valid_601990 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601990 = validateParameter(valid_601990, JString, required = false,
                                 default = nil)
  if valid_601990 != nil:
    section.add "X-Amz-Content-Sha256", valid_601990
  var valid_601991 = header.getOrDefault("X-Amz-Date")
  valid_601991 = validateParameter(valid_601991, JString, required = false,
                                 default = nil)
  if valid_601991 != nil:
    section.add "X-Amz-Date", valid_601991
  var valid_601992 = header.getOrDefault("X-Amz-Credential")
  valid_601992 = validateParameter(valid_601992, JString, required = false,
                                 default = nil)
  if valid_601992 != nil:
    section.add "X-Amz-Credential", valid_601992
  var valid_601993 = header.getOrDefault("X-Amz-Security-Token")
  valid_601993 = validateParameter(valid_601993, JString, required = false,
                                 default = nil)
  if valid_601993 != nil:
    section.add "X-Amz-Security-Token", valid_601993
  var valid_601994 = header.getOrDefault("X-Amz-Algorithm")
  valid_601994 = validateParameter(valid_601994, JString, required = false,
                                 default = nil)
  if valid_601994 != nil:
    section.add "X-Amz-Algorithm", valid_601994
  var valid_601995 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601995 = validateParameter(valid_601995, JString, required = false,
                                 default = nil)
  if valid_601995 != nil:
    section.add "X-Amz-SignedHeaders", valid_601995
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_601997: Call_CreateChannel_601986; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new Channel.
  ## 
  let valid = call_601997.validator(path, query, header, formData, body)
  let scheme = call_601997.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601997.url(scheme.get, call_601997.host, call_601997.base,
                         call_601997.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601997, url, valid)

proc call*(call_601998: Call_CreateChannel_601986; body: JsonNode): Recallable =
  ## createChannel
  ## Creates a new Channel.
  ##   body: JObject (required)
  var body_601999 = newJObject()
  if body != nil:
    body_601999 = body
  result = call_601998.call(nil, nil, nil, nil, body_601999)

var createChannel* = Call_CreateChannel_601986(name: "createChannel",
    meth: HttpMethod.HttpPost, host: "mediapackage.amazonaws.com",
    route: "/channels", validator: validate_CreateChannel_601987, base: "/",
    url: url_CreateChannel_601988, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListChannels_601727 = ref object of OpenApiRestCall_601389
proc url_ListChannels_601729(protocol: Scheme; host: string; base: string;
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

proc validate_ListChannels_601728(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_601841 = query.getOrDefault("nextToken")
  valid_601841 = validateParameter(valid_601841, JString, required = false,
                                 default = nil)
  if valid_601841 != nil:
    section.add "nextToken", valid_601841
  var valid_601842 = query.getOrDefault("MaxResults")
  valid_601842 = validateParameter(valid_601842, JString, required = false,
                                 default = nil)
  if valid_601842 != nil:
    section.add "MaxResults", valid_601842
  var valid_601843 = query.getOrDefault("NextToken")
  valid_601843 = validateParameter(valid_601843, JString, required = false,
                                 default = nil)
  if valid_601843 != nil:
    section.add "NextToken", valid_601843
  var valid_601844 = query.getOrDefault("maxResults")
  valid_601844 = validateParameter(valid_601844, JInt, required = false, default = nil)
  if valid_601844 != nil:
    section.add "maxResults", valid_601844
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
  var valid_601845 = header.getOrDefault("X-Amz-Signature")
  valid_601845 = validateParameter(valid_601845, JString, required = false,
                                 default = nil)
  if valid_601845 != nil:
    section.add "X-Amz-Signature", valid_601845
  var valid_601846 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_601846 = validateParameter(valid_601846, JString, required = false,
                                 default = nil)
  if valid_601846 != nil:
    section.add "X-Amz-Content-Sha256", valid_601846
  var valid_601847 = header.getOrDefault("X-Amz-Date")
  valid_601847 = validateParameter(valid_601847, JString, required = false,
                                 default = nil)
  if valid_601847 != nil:
    section.add "X-Amz-Date", valid_601847
  var valid_601848 = header.getOrDefault("X-Amz-Credential")
  valid_601848 = validateParameter(valid_601848, JString, required = false,
                                 default = nil)
  if valid_601848 != nil:
    section.add "X-Amz-Credential", valid_601848
  var valid_601849 = header.getOrDefault("X-Amz-Security-Token")
  valid_601849 = validateParameter(valid_601849, JString, required = false,
                                 default = nil)
  if valid_601849 != nil:
    section.add "X-Amz-Security-Token", valid_601849
  var valid_601850 = header.getOrDefault("X-Amz-Algorithm")
  valid_601850 = validateParameter(valid_601850, JString, required = false,
                                 default = nil)
  if valid_601850 != nil:
    section.add "X-Amz-Algorithm", valid_601850
  var valid_601851 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_601851 = validateParameter(valid_601851, JString, required = false,
                                 default = nil)
  if valid_601851 != nil:
    section.add "X-Amz-SignedHeaders", valid_601851
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_601874: Call_ListChannels_601727; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of Channels.
  ## 
  let valid = call_601874.validator(path, query, header, formData, body)
  let scheme = call_601874.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_601874.url(scheme.get, call_601874.host, call_601874.base,
                         call_601874.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_601874, url, valid)

proc call*(call_601945: Call_ListChannels_601727; nextToken: string = "";
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
  var query_601946 = newJObject()
  add(query_601946, "nextToken", newJString(nextToken))
  add(query_601946, "MaxResults", newJString(MaxResults))
  add(query_601946, "NextToken", newJString(NextToken))
  add(query_601946, "maxResults", newJInt(maxResults))
  result = call_601945.call(nil, query_601946, nil, nil, nil)

var listChannels* = Call_ListChannels_601727(name: "listChannels",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/channels", validator: validate_ListChannels_601728, base: "/",
    url: url_ListChannels_601729, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateHarvestJob_602019 = ref object of OpenApiRestCall_601389
proc url_CreateHarvestJob_602021(protocol: Scheme; host: string; base: string;
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

proc validate_CreateHarvestJob_602020(path: JsonNode; query: JsonNode;
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
  var valid_602022 = header.getOrDefault("X-Amz-Signature")
  valid_602022 = validateParameter(valid_602022, JString, required = false,
                                 default = nil)
  if valid_602022 != nil:
    section.add "X-Amz-Signature", valid_602022
  var valid_602023 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602023 = validateParameter(valid_602023, JString, required = false,
                                 default = nil)
  if valid_602023 != nil:
    section.add "X-Amz-Content-Sha256", valid_602023
  var valid_602024 = header.getOrDefault("X-Amz-Date")
  valid_602024 = validateParameter(valid_602024, JString, required = false,
                                 default = nil)
  if valid_602024 != nil:
    section.add "X-Amz-Date", valid_602024
  var valid_602025 = header.getOrDefault("X-Amz-Credential")
  valid_602025 = validateParameter(valid_602025, JString, required = false,
                                 default = nil)
  if valid_602025 != nil:
    section.add "X-Amz-Credential", valid_602025
  var valid_602026 = header.getOrDefault("X-Amz-Security-Token")
  valid_602026 = validateParameter(valid_602026, JString, required = false,
                                 default = nil)
  if valid_602026 != nil:
    section.add "X-Amz-Security-Token", valid_602026
  var valid_602027 = header.getOrDefault("X-Amz-Algorithm")
  valid_602027 = validateParameter(valid_602027, JString, required = false,
                                 default = nil)
  if valid_602027 != nil:
    section.add "X-Amz-Algorithm", valid_602027
  var valid_602028 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602028 = validateParameter(valid_602028, JString, required = false,
                                 default = nil)
  if valid_602028 != nil:
    section.add "X-Amz-SignedHeaders", valid_602028
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602030: Call_CreateHarvestJob_602019; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new HarvestJob record.
  ## 
  let valid = call_602030.validator(path, query, header, formData, body)
  let scheme = call_602030.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602030.url(scheme.get, call_602030.host, call_602030.base,
                         call_602030.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602030, url, valid)

proc call*(call_602031: Call_CreateHarvestJob_602019; body: JsonNode): Recallable =
  ## createHarvestJob
  ## Creates a new HarvestJob record.
  ##   body: JObject (required)
  var body_602032 = newJObject()
  if body != nil:
    body_602032 = body
  result = call_602031.call(nil, nil, nil, nil, body_602032)

var createHarvestJob* = Call_CreateHarvestJob_602019(name: "createHarvestJob",
    meth: HttpMethod.HttpPost, host: "mediapackage.amazonaws.com",
    route: "/harvest_jobs", validator: validate_CreateHarvestJob_602020, base: "/",
    url: url_CreateHarvestJob_602021, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListHarvestJobs_602000 = ref object of OpenApiRestCall_601389
proc url_ListHarvestJobs_602002(protocol: Scheme; host: string; base: string;
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

proc validate_ListHarvestJobs_602001(path: JsonNode; query: JsonNode;
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
  var valid_602003 = query.getOrDefault("nextToken")
  valid_602003 = validateParameter(valid_602003, JString, required = false,
                                 default = nil)
  if valid_602003 != nil:
    section.add "nextToken", valid_602003
  var valid_602004 = query.getOrDefault("MaxResults")
  valid_602004 = validateParameter(valid_602004, JString, required = false,
                                 default = nil)
  if valid_602004 != nil:
    section.add "MaxResults", valid_602004
  var valid_602005 = query.getOrDefault("NextToken")
  valid_602005 = validateParameter(valid_602005, JString, required = false,
                                 default = nil)
  if valid_602005 != nil:
    section.add "NextToken", valid_602005
  var valid_602006 = query.getOrDefault("includeChannelId")
  valid_602006 = validateParameter(valid_602006, JString, required = false,
                                 default = nil)
  if valid_602006 != nil:
    section.add "includeChannelId", valid_602006
  var valid_602007 = query.getOrDefault("includeStatus")
  valid_602007 = validateParameter(valid_602007, JString, required = false,
                                 default = nil)
  if valid_602007 != nil:
    section.add "includeStatus", valid_602007
  var valid_602008 = query.getOrDefault("maxResults")
  valid_602008 = validateParameter(valid_602008, JInt, required = false, default = nil)
  if valid_602008 != nil:
    section.add "maxResults", valid_602008
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
  var valid_602009 = header.getOrDefault("X-Amz-Signature")
  valid_602009 = validateParameter(valid_602009, JString, required = false,
                                 default = nil)
  if valid_602009 != nil:
    section.add "X-Amz-Signature", valid_602009
  var valid_602010 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602010 = validateParameter(valid_602010, JString, required = false,
                                 default = nil)
  if valid_602010 != nil:
    section.add "X-Amz-Content-Sha256", valid_602010
  var valid_602011 = header.getOrDefault("X-Amz-Date")
  valid_602011 = validateParameter(valid_602011, JString, required = false,
                                 default = nil)
  if valid_602011 != nil:
    section.add "X-Amz-Date", valid_602011
  var valid_602012 = header.getOrDefault("X-Amz-Credential")
  valid_602012 = validateParameter(valid_602012, JString, required = false,
                                 default = nil)
  if valid_602012 != nil:
    section.add "X-Amz-Credential", valid_602012
  var valid_602013 = header.getOrDefault("X-Amz-Security-Token")
  valid_602013 = validateParameter(valid_602013, JString, required = false,
                                 default = nil)
  if valid_602013 != nil:
    section.add "X-Amz-Security-Token", valid_602013
  var valid_602014 = header.getOrDefault("X-Amz-Algorithm")
  valid_602014 = validateParameter(valid_602014, JString, required = false,
                                 default = nil)
  if valid_602014 != nil:
    section.add "X-Amz-Algorithm", valid_602014
  var valid_602015 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602015 = validateParameter(valid_602015, JString, required = false,
                                 default = nil)
  if valid_602015 != nil:
    section.add "X-Amz-SignedHeaders", valid_602015
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602016: Call_ListHarvestJobs_602000; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of HarvestJob records.
  ## 
  let valid = call_602016.validator(path, query, header, formData, body)
  let scheme = call_602016.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602016.url(scheme.get, call_602016.host, call_602016.base,
                         call_602016.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602016, url, valid)

proc call*(call_602017: Call_ListHarvestJobs_602000; nextToken: string = "";
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
  var query_602018 = newJObject()
  add(query_602018, "nextToken", newJString(nextToken))
  add(query_602018, "MaxResults", newJString(MaxResults))
  add(query_602018, "NextToken", newJString(NextToken))
  add(query_602018, "includeChannelId", newJString(includeChannelId))
  add(query_602018, "includeStatus", newJString(includeStatus))
  add(query_602018, "maxResults", newJInt(maxResults))
  result = call_602017.call(nil, query_602018, nil, nil, nil)

var listHarvestJobs* = Call_ListHarvestJobs_602000(name: "listHarvestJobs",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/harvest_jobs", validator: validate_ListHarvestJobs_602001, base: "/",
    url: url_ListHarvestJobs_602002, schemes: {Scheme.Https, Scheme.Http})
type
  Call_CreateOriginEndpoint_602051 = ref object of OpenApiRestCall_601389
proc url_CreateOriginEndpoint_602053(protocol: Scheme; host: string; base: string;
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

proc validate_CreateOriginEndpoint_602052(path: JsonNode; query: JsonNode;
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
  var valid_602054 = header.getOrDefault("X-Amz-Signature")
  valid_602054 = validateParameter(valid_602054, JString, required = false,
                                 default = nil)
  if valid_602054 != nil:
    section.add "X-Amz-Signature", valid_602054
  var valid_602055 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602055 = validateParameter(valid_602055, JString, required = false,
                                 default = nil)
  if valid_602055 != nil:
    section.add "X-Amz-Content-Sha256", valid_602055
  var valid_602056 = header.getOrDefault("X-Amz-Date")
  valid_602056 = validateParameter(valid_602056, JString, required = false,
                                 default = nil)
  if valid_602056 != nil:
    section.add "X-Amz-Date", valid_602056
  var valid_602057 = header.getOrDefault("X-Amz-Credential")
  valid_602057 = validateParameter(valid_602057, JString, required = false,
                                 default = nil)
  if valid_602057 != nil:
    section.add "X-Amz-Credential", valid_602057
  var valid_602058 = header.getOrDefault("X-Amz-Security-Token")
  valid_602058 = validateParameter(valid_602058, JString, required = false,
                                 default = nil)
  if valid_602058 != nil:
    section.add "X-Amz-Security-Token", valid_602058
  var valid_602059 = header.getOrDefault("X-Amz-Algorithm")
  valid_602059 = validateParameter(valid_602059, JString, required = false,
                                 default = nil)
  if valid_602059 != nil:
    section.add "X-Amz-Algorithm", valid_602059
  var valid_602060 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602060 = validateParameter(valid_602060, JString, required = false,
                                 default = nil)
  if valid_602060 != nil:
    section.add "X-Amz-SignedHeaders", valid_602060
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602062: Call_CreateOriginEndpoint_602051; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Creates a new OriginEndpoint record.
  ## 
  let valid = call_602062.validator(path, query, header, formData, body)
  let scheme = call_602062.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602062.url(scheme.get, call_602062.host, call_602062.base,
                         call_602062.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602062, url, valid)

proc call*(call_602063: Call_CreateOriginEndpoint_602051; body: JsonNode): Recallable =
  ## createOriginEndpoint
  ## Creates a new OriginEndpoint record.
  ##   body: JObject (required)
  var body_602064 = newJObject()
  if body != nil:
    body_602064 = body
  result = call_602063.call(nil, nil, nil, nil, body_602064)

var createOriginEndpoint* = Call_CreateOriginEndpoint_602051(
    name: "createOriginEndpoint", meth: HttpMethod.HttpPost,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints",
    validator: validate_CreateOriginEndpoint_602052, base: "/",
    url: url_CreateOriginEndpoint_602053, schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListOriginEndpoints_602033 = ref object of OpenApiRestCall_601389
proc url_ListOriginEndpoints_602035(protocol: Scheme; host: string; base: string;
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

proc validate_ListOriginEndpoints_602034(path: JsonNode; query: JsonNode;
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
  var valid_602036 = query.getOrDefault("nextToken")
  valid_602036 = validateParameter(valid_602036, JString, required = false,
                                 default = nil)
  if valid_602036 != nil:
    section.add "nextToken", valid_602036
  var valid_602037 = query.getOrDefault("MaxResults")
  valid_602037 = validateParameter(valid_602037, JString, required = false,
                                 default = nil)
  if valid_602037 != nil:
    section.add "MaxResults", valid_602037
  var valid_602038 = query.getOrDefault("NextToken")
  valid_602038 = validateParameter(valid_602038, JString, required = false,
                                 default = nil)
  if valid_602038 != nil:
    section.add "NextToken", valid_602038
  var valid_602039 = query.getOrDefault("channelId")
  valid_602039 = validateParameter(valid_602039, JString, required = false,
                                 default = nil)
  if valid_602039 != nil:
    section.add "channelId", valid_602039
  var valid_602040 = query.getOrDefault("maxResults")
  valid_602040 = validateParameter(valid_602040, JInt, required = false, default = nil)
  if valid_602040 != nil:
    section.add "maxResults", valid_602040
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
  var valid_602041 = header.getOrDefault("X-Amz-Signature")
  valid_602041 = validateParameter(valid_602041, JString, required = false,
                                 default = nil)
  if valid_602041 != nil:
    section.add "X-Amz-Signature", valid_602041
  var valid_602042 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602042 = validateParameter(valid_602042, JString, required = false,
                                 default = nil)
  if valid_602042 != nil:
    section.add "X-Amz-Content-Sha256", valid_602042
  var valid_602043 = header.getOrDefault("X-Amz-Date")
  valid_602043 = validateParameter(valid_602043, JString, required = false,
                                 default = nil)
  if valid_602043 != nil:
    section.add "X-Amz-Date", valid_602043
  var valid_602044 = header.getOrDefault("X-Amz-Credential")
  valid_602044 = validateParameter(valid_602044, JString, required = false,
                                 default = nil)
  if valid_602044 != nil:
    section.add "X-Amz-Credential", valid_602044
  var valid_602045 = header.getOrDefault("X-Amz-Security-Token")
  valid_602045 = validateParameter(valid_602045, JString, required = false,
                                 default = nil)
  if valid_602045 != nil:
    section.add "X-Amz-Security-Token", valid_602045
  var valid_602046 = header.getOrDefault("X-Amz-Algorithm")
  valid_602046 = validateParameter(valid_602046, JString, required = false,
                                 default = nil)
  if valid_602046 != nil:
    section.add "X-Amz-Algorithm", valid_602046
  var valid_602047 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602047 = validateParameter(valid_602047, JString, required = false,
                                 default = nil)
  if valid_602047 != nil:
    section.add "X-Amz-SignedHeaders", valid_602047
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602048: Call_ListOriginEndpoints_602033; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Returns a collection of OriginEndpoint records.
  ## 
  let valid = call_602048.validator(path, query, header, formData, body)
  let scheme = call_602048.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602048.url(scheme.get, call_602048.host, call_602048.base,
                         call_602048.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602048, url, valid)

proc call*(call_602049: Call_ListOriginEndpoints_602033; nextToken: string = "";
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
  var query_602050 = newJObject()
  add(query_602050, "nextToken", newJString(nextToken))
  add(query_602050, "MaxResults", newJString(MaxResults))
  add(query_602050, "NextToken", newJString(NextToken))
  add(query_602050, "channelId", newJString(channelId))
  add(query_602050, "maxResults", newJInt(maxResults))
  result = call_602049.call(nil, query_602050, nil, nil, nil)

var listOriginEndpoints* = Call_ListOriginEndpoints_602033(
    name: "listOriginEndpoints", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints",
    validator: validate_ListOriginEndpoints_602034, base: "/",
    url: url_ListOriginEndpoints_602035, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateChannel_602093 = ref object of OpenApiRestCall_601389
proc url_UpdateChannel_602095(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateChannel_602094(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602096 = path.getOrDefault("id")
  valid_602096 = validateParameter(valid_602096, JString, required = true,
                                 default = nil)
  if valid_602096 != nil:
    section.add "id", valid_602096
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
  var valid_602097 = header.getOrDefault("X-Amz-Signature")
  valid_602097 = validateParameter(valid_602097, JString, required = false,
                                 default = nil)
  if valid_602097 != nil:
    section.add "X-Amz-Signature", valid_602097
  var valid_602098 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602098 = validateParameter(valid_602098, JString, required = false,
                                 default = nil)
  if valid_602098 != nil:
    section.add "X-Amz-Content-Sha256", valid_602098
  var valid_602099 = header.getOrDefault("X-Amz-Date")
  valid_602099 = validateParameter(valid_602099, JString, required = false,
                                 default = nil)
  if valid_602099 != nil:
    section.add "X-Amz-Date", valid_602099
  var valid_602100 = header.getOrDefault("X-Amz-Credential")
  valid_602100 = validateParameter(valid_602100, JString, required = false,
                                 default = nil)
  if valid_602100 != nil:
    section.add "X-Amz-Credential", valid_602100
  var valid_602101 = header.getOrDefault("X-Amz-Security-Token")
  valid_602101 = validateParameter(valid_602101, JString, required = false,
                                 default = nil)
  if valid_602101 != nil:
    section.add "X-Amz-Security-Token", valid_602101
  var valid_602102 = header.getOrDefault("X-Amz-Algorithm")
  valid_602102 = validateParameter(valid_602102, JString, required = false,
                                 default = nil)
  if valid_602102 != nil:
    section.add "X-Amz-Algorithm", valid_602102
  var valid_602103 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602103 = validateParameter(valid_602103, JString, required = false,
                                 default = nil)
  if valid_602103 != nil:
    section.add "X-Amz-SignedHeaders", valid_602103
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602105: Call_UpdateChannel_602093; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing Channel.
  ## 
  let valid = call_602105.validator(path, query, header, formData, body)
  let scheme = call_602105.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602105.url(scheme.get, call_602105.host, call_602105.base,
                         call_602105.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602105, url, valid)

proc call*(call_602106: Call_UpdateChannel_602093; id: string; body: JsonNode): Recallable =
  ## updateChannel
  ## Updates an existing Channel.
  ##   id: string (required)
  ##     : The ID of the Channel to update.
  ##   body: JObject (required)
  var path_602107 = newJObject()
  var body_602108 = newJObject()
  add(path_602107, "id", newJString(id))
  if body != nil:
    body_602108 = body
  result = call_602106.call(path_602107, nil, nil, nil, body_602108)

var updateChannel* = Call_UpdateChannel_602093(name: "updateChannel",
    meth: HttpMethod.HttpPut, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_UpdateChannel_602094, base: "/",
    url: url_UpdateChannel_602095, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeChannel_602065 = ref object of OpenApiRestCall_601389
proc url_DescribeChannel_602067(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeChannel_602066(path: JsonNode; query: JsonNode;
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
  var valid_602082 = path.getOrDefault("id")
  valid_602082 = validateParameter(valid_602082, JString, required = true,
                                 default = nil)
  if valid_602082 != nil:
    section.add "id", valid_602082
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
  var valid_602083 = header.getOrDefault("X-Amz-Signature")
  valid_602083 = validateParameter(valid_602083, JString, required = false,
                                 default = nil)
  if valid_602083 != nil:
    section.add "X-Amz-Signature", valid_602083
  var valid_602084 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602084 = validateParameter(valid_602084, JString, required = false,
                                 default = nil)
  if valid_602084 != nil:
    section.add "X-Amz-Content-Sha256", valid_602084
  var valid_602085 = header.getOrDefault("X-Amz-Date")
  valid_602085 = validateParameter(valid_602085, JString, required = false,
                                 default = nil)
  if valid_602085 != nil:
    section.add "X-Amz-Date", valid_602085
  var valid_602086 = header.getOrDefault("X-Amz-Credential")
  valid_602086 = validateParameter(valid_602086, JString, required = false,
                                 default = nil)
  if valid_602086 != nil:
    section.add "X-Amz-Credential", valid_602086
  var valid_602087 = header.getOrDefault("X-Amz-Security-Token")
  valid_602087 = validateParameter(valid_602087, JString, required = false,
                                 default = nil)
  if valid_602087 != nil:
    section.add "X-Amz-Security-Token", valid_602087
  var valid_602088 = header.getOrDefault("X-Amz-Algorithm")
  valid_602088 = validateParameter(valid_602088, JString, required = false,
                                 default = nil)
  if valid_602088 != nil:
    section.add "X-Amz-Algorithm", valid_602088
  var valid_602089 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602089 = validateParameter(valid_602089, JString, required = false,
                                 default = nil)
  if valid_602089 != nil:
    section.add "X-Amz-SignedHeaders", valid_602089
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602090: Call_DescribeChannel_602065; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about a Channel.
  ## 
  let valid = call_602090.validator(path, query, header, formData, body)
  let scheme = call_602090.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602090.url(scheme.get, call_602090.host, call_602090.base,
                         call_602090.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602090, url, valid)

proc call*(call_602091: Call_DescribeChannel_602065; id: string): Recallable =
  ## describeChannel
  ## Gets details about a Channel.
  ##   id: string (required)
  ##     : The ID of a Channel.
  var path_602092 = newJObject()
  add(path_602092, "id", newJString(id))
  result = call_602091.call(path_602092, nil, nil, nil, nil)

var describeChannel* = Call_DescribeChannel_602065(name: "describeChannel",
    meth: HttpMethod.HttpGet, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_DescribeChannel_602066, base: "/",
    url: url_DescribeChannel_602067, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteChannel_602109 = ref object of OpenApiRestCall_601389
proc url_DeleteChannel_602111(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteChannel_602110(path: JsonNode; query: JsonNode; header: JsonNode;
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
  var valid_602112 = path.getOrDefault("id")
  valid_602112 = validateParameter(valid_602112, JString, required = true,
                                 default = nil)
  if valid_602112 != nil:
    section.add "id", valid_602112
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
  var valid_602113 = header.getOrDefault("X-Amz-Signature")
  valid_602113 = validateParameter(valid_602113, JString, required = false,
                                 default = nil)
  if valid_602113 != nil:
    section.add "X-Amz-Signature", valid_602113
  var valid_602114 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602114 = validateParameter(valid_602114, JString, required = false,
                                 default = nil)
  if valid_602114 != nil:
    section.add "X-Amz-Content-Sha256", valid_602114
  var valid_602115 = header.getOrDefault("X-Amz-Date")
  valid_602115 = validateParameter(valid_602115, JString, required = false,
                                 default = nil)
  if valid_602115 != nil:
    section.add "X-Amz-Date", valid_602115
  var valid_602116 = header.getOrDefault("X-Amz-Credential")
  valid_602116 = validateParameter(valid_602116, JString, required = false,
                                 default = nil)
  if valid_602116 != nil:
    section.add "X-Amz-Credential", valid_602116
  var valid_602117 = header.getOrDefault("X-Amz-Security-Token")
  valid_602117 = validateParameter(valid_602117, JString, required = false,
                                 default = nil)
  if valid_602117 != nil:
    section.add "X-Amz-Security-Token", valid_602117
  var valid_602118 = header.getOrDefault("X-Amz-Algorithm")
  valid_602118 = validateParameter(valid_602118, JString, required = false,
                                 default = nil)
  if valid_602118 != nil:
    section.add "X-Amz-Algorithm", valid_602118
  var valid_602119 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602119 = validateParameter(valid_602119, JString, required = false,
                                 default = nil)
  if valid_602119 != nil:
    section.add "X-Amz-SignedHeaders", valid_602119
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602120: Call_DeleteChannel_602109; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing Channel.
  ## 
  let valid = call_602120.validator(path, query, header, formData, body)
  let scheme = call_602120.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602120.url(scheme.get, call_602120.host, call_602120.base,
                         call_602120.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602120, url, valid)

proc call*(call_602121: Call_DeleteChannel_602109; id: string): Recallable =
  ## deleteChannel
  ## Deletes an existing Channel.
  ##   id: string (required)
  ##     : The ID of the Channel to delete.
  var path_602122 = newJObject()
  add(path_602122, "id", newJString(id))
  result = call_602121.call(path_602122, nil, nil, nil, nil)

var deleteChannel* = Call_DeleteChannel_602109(name: "deleteChannel",
    meth: HttpMethod.HttpDelete, host: "mediapackage.amazonaws.com",
    route: "/channels/{id}", validator: validate_DeleteChannel_602110, base: "/",
    url: url_DeleteChannel_602111, schemes: {Scheme.Https, Scheme.Http})
type
  Call_UpdateOriginEndpoint_602137 = ref object of OpenApiRestCall_601389
proc url_UpdateOriginEndpoint_602139(protocol: Scheme; host: string; base: string;
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

proc validate_UpdateOriginEndpoint_602138(path: JsonNode; query: JsonNode;
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
  var valid_602140 = path.getOrDefault("id")
  valid_602140 = validateParameter(valid_602140, JString, required = true,
                                 default = nil)
  if valid_602140 != nil:
    section.add "id", valid_602140
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
  var valid_602141 = header.getOrDefault("X-Amz-Signature")
  valid_602141 = validateParameter(valid_602141, JString, required = false,
                                 default = nil)
  if valid_602141 != nil:
    section.add "X-Amz-Signature", valid_602141
  var valid_602142 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602142 = validateParameter(valid_602142, JString, required = false,
                                 default = nil)
  if valid_602142 != nil:
    section.add "X-Amz-Content-Sha256", valid_602142
  var valid_602143 = header.getOrDefault("X-Amz-Date")
  valid_602143 = validateParameter(valid_602143, JString, required = false,
                                 default = nil)
  if valid_602143 != nil:
    section.add "X-Amz-Date", valid_602143
  var valid_602144 = header.getOrDefault("X-Amz-Credential")
  valid_602144 = validateParameter(valid_602144, JString, required = false,
                                 default = nil)
  if valid_602144 != nil:
    section.add "X-Amz-Credential", valid_602144
  var valid_602145 = header.getOrDefault("X-Amz-Security-Token")
  valid_602145 = validateParameter(valid_602145, JString, required = false,
                                 default = nil)
  if valid_602145 != nil:
    section.add "X-Amz-Security-Token", valid_602145
  var valid_602146 = header.getOrDefault("X-Amz-Algorithm")
  valid_602146 = validateParameter(valid_602146, JString, required = false,
                                 default = nil)
  if valid_602146 != nil:
    section.add "X-Amz-Algorithm", valid_602146
  var valid_602147 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602147 = validateParameter(valid_602147, JString, required = false,
                                 default = nil)
  if valid_602147 != nil:
    section.add "X-Amz-SignedHeaders", valid_602147
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602149: Call_UpdateOriginEndpoint_602137; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Updates an existing OriginEndpoint.
  ## 
  let valid = call_602149.validator(path, query, header, formData, body)
  let scheme = call_602149.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602149.url(scheme.get, call_602149.host, call_602149.base,
                         call_602149.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602149, url, valid)

proc call*(call_602150: Call_UpdateOriginEndpoint_602137; id: string; body: JsonNode): Recallable =
  ## updateOriginEndpoint
  ## Updates an existing OriginEndpoint.
  ##   id: string (required)
  ##     : The ID of the OriginEndpoint to update.
  ##   body: JObject (required)
  var path_602151 = newJObject()
  var body_602152 = newJObject()
  add(path_602151, "id", newJString(id))
  if body != nil:
    body_602152 = body
  result = call_602150.call(path_602151, nil, nil, nil, body_602152)

var updateOriginEndpoint* = Call_UpdateOriginEndpoint_602137(
    name: "updateOriginEndpoint", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_UpdateOriginEndpoint_602138, base: "/",
    url: url_UpdateOriginEndpoint_602139, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeOriginEndpoint_602123 = ref object of OpenApiRestCall_601389
proc url_DescribeOriginEndpoint_602125(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeOriginEndpoint_602124(path: JsonNode; query: JsonNode;
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
  var valid_602126 = path.getOrDefault("id")
  valid_602126 = validateParameter(valid_602126, JString, required = true,
                                 default = nil)
  if valid_602126 != nil:
    section.add "id", valid_602126
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
  var valid_602127 = header.getOrDefault("X-Amz-Signature")
  valid_602127 = validateParameter(valid_602127, JString, required = false,
                                 default = nil)
  if valid_602127 != nil:
    section.add "X-Amz-Signature", valid_602127
  var valid_602128 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602128 = validateParameter(valid_602128, JString, required = false,
                                 default = nil)
  if valid_602128 != nil:
    section.add "X-Amz-Content-Sha256", valid_602128
  var valid_602129 = header.getOrDefault("X-Amz-Date")
  valid_602129 = validateParameter(valid_602129, JString, required = false,
                                 default = nil)
  if valid_602129 != nil:
    section.add "X-Amz-Date", valid_602129
  var valid_602130 = header.getOrDefault("X-Amz-Credential")
  valid_602130 = validateParameter(valid_602130, JString, required = false,
                                 default = nil)
  if valid_602130 != nil:
    section.add "X-Amz-Credential", valid_602130
  var valid_602131 = header.getOrDefault("X-Amz-Security-Token")
  valid_602131 = validateParameter(valid_602131, JString, required = false,
                                 default = nil)
  if valid_602131 != nil:
    section.add "X-Amz-Security-Token", valid_602131
  var valid_602132 = header.getOrDefault("X-Amz-Algorithm")
  valid_602132 = validateParameter(valid_602132, JString, required = false,
                                 default = nil)
  if valid_602132 != nil:
    section.add "X-Amz-Algorithm", valid_602132
  var valid_602133 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602133 = validateParameter(valid_602133, JString, required = false,
                                 default = nil)
  if valid_602133 != nil:
    section.add "X-Amz-SignedHeaders", valid_602133
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602134: Call_DescribeOriginEndpoint_602123; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about an existing OriginEndpoint.
  ## 
  let valid = call_602134.validator(path, query, header, formData, body)
  let scheme = call_602134.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602134.url(scheme.get, call_602134.host, call_602134.base,
                         call_602134.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602134, url, valid)

proc call*(call_602135: Call_DescribeOriginEndpoint_602123; id: string): Recallable =
  ## describeOriginEndpoint
  ## Gets details about an existing OriginEndpoint.
  ##   id: string (required)
  ##     : The ID of the OriginEndpoint.
  var path_602136 = newJObject()
  add(path_602136, "id", newJString(id))
  result = call_602135.call(path_602136, nil, nil, nil, nil)

var describeOriginEndpoint* = Call_DescribeOriginEndpoint_602123(
    name: "describeOriginEndpoint", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_DescribeOriginEndpoint_602124, base: "/",
    url: url_DescribeOriginEndpoint_602125, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DeleteOriginEndpoint_602153 = ref object of OpenApiRestCall_601389
proc url_DeleteOriginEndpoint_602155(protocol: Scheme; host: string; base: string;
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

proc validate_DeleteOriginEndpoint_602154(path: JsonNode; query: JsonNode;
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
  var valid_602156 = path.getOrDefault("id")
  valid_602156 = validateParameter(valid_602156, JString, required = true,
                                 default = nil)
  if valid_602156 != nil:
    section.add "id", valid_602156
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
  var valid_602157 = header.getOrDefault("X-Amz-Signature")
  valid_602157 = validateParameter(valid_602157, JString, required = false,
                                 default = nil)
  if valid_602157 != nil:
    section.add "X-Amz-Signature", valid_602157
  var valid_602158 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602158 = validateParameter(valid_602158, JString, required = false,
                                 default = nil)
  if valid_602158 != nil:
    section.add "X-Amz-Content-Sha256", valid_602158
  var valid_602159 = header.getOrDefault("X-Amz-Date")
  valid_602159 = validateParameter(valid_602159, JString, required = false,
                                 default = nil)
  if valid_602159 != nil:
    section.add "X-Amz-Date", valid_602159
  var valid_602160 = header.getOrDefault("X-Amz-Credential")
  valid_602160 = validateParameter(valid_602160, JString, required = false,
                                 default = nil)
  if valid_602160 != nil:
    section.add "X-Amz-Credential", valid_602160
  var valid_602161 = header.getOrDefault("X-Amz-Security-Token")
  valid_602161 = validateParameter(valid_602161, JString, required = false,
                                 default = nil)
  if valid_602161 != nil:
    section.add "X-Amz-Security-Token", valid_602161
  var valid_602162 = header.getOrDefault("X-Amz-Algorithm")
  valid_602162 = validateParameter(valid_602162, JString, required = false,
                                 default = nil)
  if valid_602162 != nil:
    section.add "X-Amz-Algorithm", valid_602162
  var valid_602163 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602163 = validateParameter(valid_602163, JString, required = false,
                                 default = nil)
  if valid_602163 != nil:
    section.add "X-Amz-SignedHeaders", valid_602163
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602164: Call_DeleteOriginEndpoint_602153; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Deletes an existing OriginEndpoint.
  ## 
  let valid = call_602164.validator(path, query, header, formData, body)
  let scheme = call_602164.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602164.url(scheme.get, call_602164.host, call_602164.base,
                         call_602164.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602164, url, valid)

proc call*(call_602165: Call_DeleteOriginEndpoint_602153; id: string): Recallable =
  ## deleteOriginEndpoint
  ## Deletes an existing OriginEndpoint.
  ##   id: string (required)
  ##     : The ID of the OriginEndpoint to delete.
  var path_602166 = newJObject()
  add(path_602166, "id", newJString(id))
  result = call_602165.call(path_602166, nil, nil, nil, nil)

var deleteOriginEndpoint* = Call_DeleteOriginEndpoint_602153(
    name: "deleteOriginEndpoint", meth: HttpMethod.HttpDelete,
    host: "mediapackage.amazonaws.com", route: "/origin_endpoints/{id}",
    validator: validate_DeleteOriginEndpoint_602154, base: "/",
    url: url_DeleteOriginEndpoint_602155, schemes: {Scheme.Https, Scheme.Http})
type
  Call_DescribeHarvestJob_602167 = ref object of OpenApiRestCall_601389
proc url_DescribeHarvestJob_602169(protocol: Scheme; host: string; base: string;
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

proc validate_DescribeHarvestJob_602168(path: JsonNode; query: JsonNode;
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
  var valid_602170 = path.getOrDefault("id")
  valid_602170 = validateParameter(valid_602170, JString, required = true,
                                 default = nil)
  if valid_602170 != nil:
    section.add "id", valid_602170
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
  var valid_602171 = header.getOrDefault("X-Amz-Signature")
  valid_602171 = validateParameter(valid_602171, JString, required = false,
                                 default = nil)
  if valid_602171 != nil:
    section.add "X-Amz-Signature", valid_602171
  var valid_602172 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602172 = validateParameter(valid_602172, JString, required = false,
                                 default = nil)
  if valid_602172 != nil:
    section.add "X-Amz-Content-Sha256", valid_602172
  var valid_602173 = header.getOrDefault("X-Amz-Date")
  valid_602173 = validateParameter(valid_602173, JString, required = false,
                                 default = nil)
  if valid_602173 != nil:
    section.add "X-Amz-Date", valid_602173
  var valid_602174 = header.getOrDefault("X-Amz-Credential")
  valid_602174 = validateParameter(valid_602174, JString, required = false,
                                 default = nil)
  if valid_602174 != nil:
    section.add "X-Amz-Credential", valid_602174
  var valid_602175 = header.getOrDefault("X-Amz-Security-Token")
  valid_602175 = validateParameter(valid_602175, JString, required = false,
                                 default = nil)
  if valid_602175 != nil:
    section.add "X-Amz-Security-Token", valid_602175
  var valid_602176 = header.getOrDefault("X-Amz-Algorithm")
  valid_602176 = validateParameter(valid_602176, JString, required = false,
                                 default = nil)
  if valid_602176 != nil:
    section.add "X-Amz-Algorithm", valid_602176
  var valid_602177 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602177 = validateParameter(valid_602177, JString, required = false,
                                 default = nil)
  if valid_602177 != nil:
    section.add "X-Amz-SignedHeaders", valid_602177
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602178: Call_DescribeHarvestJob_602167; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Gets details about an existing HarvestJob.
  ## 
  let valid = call_602178.validator(path, query, header, formData, body)
  let scheme = call_602178.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602178.url(scheme.get, call_602178.host, call_602178.base,
                         call_602178.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602178, url, valid)

proc call*(call_602179: Call_DescribeHarvestJob_602167; id: string): Recallable =
  ## describeHarvestJob
  ## Gets details about an existing HarvestJob.
  ##   id: string (required)
  ##     : The ID of the HarvestJob.
  var path_602180 = newJObject()
  add(path_602180, "id", newJString(id))
  result = call_602179.call(path_602180, nil, nil, nil, nil)

var describeHarvestJob* = Call_DescribeHarvestJob_602167(
    name: "describeHarvestJob", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/harvest_jobs/{id}",
    validator: validate_DescribeHarvestJob_602168, base: "/",
    url: url_DescribeHarvestJob_602169, schemes: {Scheme.Https, Scheme.Http})
type
  Call_TagResource_602195 = ref object of OpenApiRestCall_601389
proc url_TagResource_602197(protocol: Scheme; host: string; base: string;
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

proc validate_TagResource_602196(path: JsonNode; query: JsonNode; header: JsonNode;
                                formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_602198 = path.getOrDefault("resource-arn")
  valid_602198 = validateParameter(valid_602198, JString, required = true,
                                 default = nil)
  if valid_602198 != nil:
    section.add "resource-arn", valid_602198
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
  var valid_602199 = header.getOrDefault("X-Amz-Signature")
  valid_602199 = validateParameter(valid_602199, JString, required = false,
                                 default = nil)
  if valid_602199 != nil:
    section.add "X-Amz-Signature", valid_602199
  var valid_602200 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602200 = validateParameter(valid_602200, JString, required = false,
                                 default = nil)
  if valid_602200 != nil:
    section.add "X-Amz-Content-Sha256", valid_602200
  var valid_602201 = header.getOrDefault("X-Amz-Date")
  valid_602201 = validateParameter(valid_602201, JString, required = false,
                                 default = nil)
  if valid_602201 != nil:
    section.add "X-Amz-Date", valid_602201
  var valid_602202 = header.getOrDefault("X-Amz-Credential")
  valid_602202 = validateParameter(valid_602202, JString, required = false,
                                 default = nil)
  if valid_602202 != nil:
    section.add "X-Amz-Credential", valid_602202
  var valid_602203 = header.getOrDefault("X-Amz-Security-Token")
  valid_602203 = validateParameter(valid_602203, JString, required = false,
                                 default = nil)
  if valid_602203 != nil:
    section.add "X-Amz-Security-Token", valid_602203
  var valid_602204 = header.getOrDefault("X-Amz-Algorithm")
  valid_602204 = validateParameter(valid_602204, JString, required = false,
                                 default = nil)
  if valid_602204 != nil:
    section.add "X-Amz-Algorithm", valid_602204
  var valid_602205 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602205 = validateParameter(valid_602205, JString, required = false,
                                 default = nil)
  if valid_602205 != nil:
    section.add "X-Amz-SignedHeaders", valid_602205
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  ## parameters in `body` object:
  ##   body: JObject (required)
  assert body != nil, "body argument is necessary"
  section = validateParameter(body, JObject, required = true, default = nil)
  if body != nil:
    result.add "body", body

proc call*(call_602207: Call_TagResource_602195; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602207.validator(path, query, header, formData, body)
  let scheme = call_602207.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602207.url(scheme.get, call_602207.host, call_602207.base,
                         call_602207.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602207, url, valid)

proc call*(call_602208: Call_TagResource_602195; resourceArn: string; body: JsonNode): Recallable =
  ## tagResource
  ##   resourceArn: string (required)
  ##   body: JObject (required)
  var path_602209 = newJObject()
  var body_602210 = newJObject()
  add(path_602209, "resource-arn", newJString(resourceArn))
  if body != nil:
    body_602210 = body
  result = call_602208.call(path_602209, nil, nil, nil, body_602210)

var tagResource* = Call_TagResource_602195(name: "tagResource",
                                        meth: HttpMethod.HttpPost,
                                        host: "mediapackage.amazonaws.com",
                                        route: "/tags/{resource-arn}",
                                        validator: validate_TagResource_602196,
                                        base: "/", url: url_TagResource_602197,
                                        schemes: {Scheme.Https, Scheme.Http})
type
  Call_ListTagsForResource_602181 = ref object of OpenApiRestCall_601389
proc url_ListTagsForResource_602183(protocol: Scheme; host: string; base: string;
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

proc validate_ListTagsForResource_602182(path: JsonNode; query: JsonNode;
                                        header: JsonNode; formData: JsonNode;
                                        body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_602184 = path.getOrDefault("resource-arn")
  valid_602184 = validateParameter(valid_602184, JString, required = true,
                                 default = nil)
  if valid_602184 != nil:
    section.add "resource-arn", valid_602184
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
  var valid_602185 = header.getOrDefault("X-Amz-Signature")
  valid_602185 = validateParameter(valid_602185, JString, required = false,
                                 default = nil)
  if valid_602185 != nil:
    section.add "X-Amz-Signature", valid_602185
  var valid_602186 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602186 = validateParameter(valid_602186, JString, required = false,
                                 default = nil)
  if valid_602186 != nil:
    section.add "X-Amz-Content-Sha256", valid_602186
  var valid_602187 = header.getOrDefault("X-Amz-Date")
  valid_602187 = validateParameter(valid_602187, JString, required = false,
                                 default = nil)
  if valid_602187 != nil:
    section.add "X-Amz-Date", valid_602187
  var valid_602188 = header.getOrDefault("X-Amz-Credential")
  valid_602188 = validateParameter(valid_602188, JString, required = false,
                                 default = nil)
  if valid_602188 != nil:
    section.add "X-Amz-Credential", valid_602188
  var valid_602189 = header.getOrDefault("X-Amz-Security-Token")
  valid_602189 = validateParameter(valid_602189, JString, required = false,
                                 default = nil)
  if valid_602189 != nil:
    section.add "X-Amz-Security-Token", valid_602189
  var valid_602190 = header.getOrDefault("X-Amz-Algorithm")
  valid_602190 = validateParameter(valid_602190, JString, required = false,
                                 default = nil)
  if valid_602190 != nil:
    section.add "X-Amz-Algorithm", valid_602190
  var valid_602191 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602191 = validateParameter(valid_602191, JString, required = false,
                                 default = nil)
  if valid_602191 != nil:
    section.add "X-Amz-SignedHeaders", valid_602191
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602192: Call_ListTagsForResource_602181; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602192.validator(path, query, header, formData, body)
  let scheme = call_602192.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602192.url(scheme.get, call_602192.host, call_602192.base,
                         call_602192.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602192, url, valid)

proc call*(call_602193: Call_ListTagsForResource_602181; resourceArn: string): Recallable =
  ## listTagsForResource
  ##   resourceArn: string (required)
  var path_602194 = newJObject()
  add(path_602194, "resource-arn", newJString(resourceArn))
  result = call_602193.call(path_602194, nil, nil, nil, nil)

var listTagsForResource* = Call_ListTagsForResource_602181(
    name: "listTagsForResource", meth: HttpMethod.HttpGet,
    host: "mediapackage.amazonaws.com", route: "/tags/{resource-arn}",
    validator: validate_ListTagsForResource_602182, base: "/",
    url: url_ListTagsForResource_602183, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RotateChannelCredentials_602211 = ref object of OpenApiRestCall_601389
proc url_RotateChannelCredentials_602213(protocol: Scheme; host: string;
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

proc validate_RotateChannelCredentials_602212(path: JsonNode; query: JsonNode;
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
  var valid_602214 = path.getOrDefault("id")
  valid_602214 = validateParameter(valid_602214, JString, required = true,
                                 default = nil)
  if valid_602214 != nil:
    section.add "id", valid_602214
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
  var valid_602215 = header.getOrDefault("X-Amz-Signature")
  valid_602215 = validateParameter(valid_602215, JString, required = false,
                                 default = nil)
  if valid_602215 != nil:
    section.add "X-Amz-Signature", valid_602215
  var valid_602216 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602216 = validateParameter(valid_602216, JString, required = false,
                                 default = nil)
  if valid_602216 != nil:
    section.add "X-Amz-Content-Sha256", valid_602216
  var valid_602217 = header.getOrDefault("X-Amz-Date")
  valid_602217 = validateParameter(valid_602217, JString, required = false,
                                 default = nil)
  if valid_602217 != nil:
    section.add "X-Amz-Date", valid_602217
  var valid_602218 = header.getOrDefault("X-Amz-Credential")
  valid_602218 = validateParameter(valid_602218, JString, required = false,
                                 default = nil)
  if valid_602218 != nil:
    section.add "X-Amz-Credential", valid_602218
  var valid_602219 = header.getOrDefault("X-Amz-Security-Token")
  valid_602219 = validateParameter(valid_602219, JString, required = false,
                                 default = nil)
  if valid_602219 != nil:
    section.add "X-Amz-Security-Token", valid_602219
  var valid_602220 = header.getOrDefault("X-Amz-Algorithm")
  valid_602220 = validateParameter(valid_602220, JString, required = false,
                                 default = nil)
  if valid_602220 != nil:
    section.add "X-Amz-Algorithm", valid_602220
  var valid_602221 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602221 = validateParameter(valid_602221, JString, required = false,
                                 default = nil)
  if valid_602221 != nil:
    section.add "X-Amz-SignedHeaders", valid_602221
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602222: Call_RotateChannelCredentials_602211; path: JsonNode;
          query: JsonNode; header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  ## Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
  ## 
  let valid = call_602222.validator(path, query, header, formData, body)
  let scheme = call_602222.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602222.url(scheme.get, call_602222.host, call_602222.base,
                         call_602222.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602222, url, valid)

proc call*(call_602223: Call_RotateChannelCredentials_602211; id: string): Recallable =
  ## rotateChannelCredentials
  ## Changes the Channel's first IngestEndpoint's username and password. WARNING - This API is deprecated. Please use RotateIngestEndpointCredentials instead
  ##   id: string (required)
  ##     : The ID of the channel to update.
  var path_602224 = newJObject()
  add(path_602224, "id", newJString(id))
  result = call_602223.call(path_602224, nil, nil, nil, nil)

var rotateChannelCredentials* = Call_RotateChannelCredentials_602211(
    name: "rotateChannelCredentials", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com", route: "/channels/{id}/credentials",
    validator: validate_RotateChannelCredentials_602212, base: "/",
    url: url_RotateChannelCredentials_602213, schemes: {Scheme.Https, Scheme.Http})
type
  Call_RotateIngestEndpointCredentials_602225 = ref object of OpenApiRestCall_601389
proc url_RotateIngestEndpointCredentials_602227(protocol: Scheme; host: string;
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

proc validate_RotateIngestEndpointCredentials_602226(path: JsonNode;
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
  var valid_602228 = path.getOrDefault("id")
  valid_602228 = validateParameter(valid_602228, JString, required = true,
                                 default = nil)
  if valid_602228 != nil:
    section.add "id", valid_602228
  var valid_602229 = path.getOrDefault("ingest_endpoint_id")
  valid_602229 = validateParameter(valid_602229, JString, required = true,
                                 default = nil)
  if valid_602229 != nil:
    section.add "ingest_endpoint_id", valid_602229
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
  var valid_602230 = header.getOrDefault("X-Amz-Signature")
  valid_602230 = validateParameter(valid_602230, JString, required = false,
                                 default = nil)
  if valid_602230 != nil:
    section.add "X-Amz-Signature", valid_602230
  var valid_602231 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602231 = validateParameter(valid_602231, JString, required = false,
                                 default = nil)
  if valid_602231 != nil:
    section.add "X-Amz-Content-Sha256", valid_602231
  var valid_602232 = header.getOrDefault("X-Amz-Date")
  valid_602232 = validateParameter(valid_602232, JString, required = false,
                                 default = nil)
  if valid_602232 != nil:
    section.add "X-Amz-Date", valid_602232
  var valid_602233 = header.getOrDefault("X-Amz-Credential")
  valid_602233 = validateParameter(valid_602233, JString, required = false,
                                 default = nil)
  if valid_602233 != nil:
    section.add "X-Amz-Credential", valid_602233
  var valid_602234 = header.getOrDefault("X-Amz-Security-Token")
  valid_602234 = validateParameter(valid_602234, JString, required = false,
                                 default = nil)
  if valid_602234 != nil:
    section.add "X-Amz-Security-Token", valid_602234
  var valid_602235 = header.getOrDefault("X-Amz-Algorithm")
  valid_602235 = validateParameter(valid_602235, JString, required = false,
                                 default = nil)
  if valid_602235 != nil:
    section.add "X-Amz-Algorithm", valid_602235
  var valid_602236 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602236 = validateParameter(valid_602236, JString, required = false,
                                 default = nil)
  if valid_602236 != nil:
    section.add "X-Amz-SignedHeaders", valid_602236
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602237: Call_RotateIngestEndpointCredentials_602225;
          path: JsonNode; query: JsonNode; header: JsonNode; formData: JsonNode;
          body: JsonNode): Recallable =
  ## Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
  ## 
  let valid = call_602237.validator(path, query, header, formData, body)
  let scheme = call_602237.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602237.url(scheme.get, call_602237.host, call_602237.base,
                         call_602237.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602237, url, valid)

proc call*(call_602238: Call_RotateIngestEndpointCredentials_602225; id: string;
          ingestEndpointId: string): Recallable =
  ## rotateIngestEndpointCredentials
  ## Rotate the IngestEndpoint's username and password, as specified by the IngestEndpoint's id.
  ##   id: string (required)
  ##     : The ID of the channel the IngestEndpoint is on.
  ##   ingestEndpointId: string (required)
  ##                   : The id of the IngestEndpoint whose credentials should be rotated
  var path_602239 = newJObject()
  add(path_602239, "id", newJString(id))
  add(path_602239, "ingest_endpoint_id", newJString(ingestEndpointId))
  result = call_602238.call(path_602239, nil, nil, nil, nil)

var rotateIngestEndpointCredentials* = Call_RotateIngestEndpointCredentials_602225(
    name: "rotateIngestEndpointCredentials", meth: HttpMethod.HttpPut,
    host: "mediapackage.amazonaws.com",
    route: "/channels/{id}/ingest_endpoints/{ingest_endpoint_id}/credentials",
    validator: validate_RotateIngestEndpointCredentials_602226, base: "/",
    url: url_RotateIngestEndpointCredentials_602227,
    schemes: {Scheme.Https, Scheme.Http})
type
  Call_UntagResource_602240 = ref object of OpenApiRestCall_601389
proc url_UntagResource_602242(protocol: Scheme; host: string; base: string;
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

proc validate_UntagResource_602241(path: JsonNode; query: JsonNode; header: JsonNode;
                                  formData: JsonNode; body: JsonNode): JsonNode =
  var section: JsonNode
  result = newJObject()
  ## parameters in `path` object:
  ##   resource-arn: JString (required)
  section = newJObject()
  assert path != nil,
        "path argument is necessary due to required `resource-arn` field"
  var valid_602243 = path.getOrDefault("resource-arn")
  valid_602243 = validateParameter(valid_602243, JString, required = true,
                                 default = nil)
  if valid_602243 != nil:
    section.add "resource-arn", valid_602243
  result.add "path", section
  ## parameters in `query` object:
  ##   tagKeys: JArray (required)
  ##          : The key(s) of tag to be deleted
  section = newJObject()
  assert query != nil, "query argument is necessary due to required `tagKeys` field"
  var valid_602244 = query.getOrDefault("tagKeys")
  valid_602244 = validateParameter(valid_602244, JArray, required = true, default = nil)
  if valid_602244 != nil:
    section.add "tagKeys", valid_602244
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
  var valid_602245 = header.getOrDefault("X-Amz-Signature")
  valid_602245 = validateParameter(valid_602245, JString, required = false,
                                 default = nil)
  if valid_602245 != nil:
    section.add "X-Amz-Signature", valid_602245
  var valid_602246 = header.getOrDefault("X-Amz-Content-Sha256")
  valid_602246 = validateParameter(valid_602246, JString, required = false,
                                 default = nil)
  if valid_602246 != nil:
    section.add "X-Amz-Content-Sha256", valid_602246
  var valid_602247 = header.getOrDefault("X-Amz-Date")
  valid_602247 = validateParameter(valid_602247, JString, required = false,
                                 default = nil)
  if valid_602247 != nil:
    section.add "X-Amz-Date", valid_602247
  var valid_602248 = header.getOrDefault("X-Amz-Credential")
  valid_602248 = validateParameter(valid_602248, JString, required = false,
                                 default = nil)
  if valid_602248 != nil:
    section.add "X-Amz-Credential", valid_602248
  var valid_602249 = header.getOrDefault("X-Amz-Security-Token")
  valid_602249 = validateParameter(valid_602249, JString, required = false,
                                 default = nil)
  if valid_602249 != nil:
    section.add "X-Amz-Security-Token", valid_602249
  var valid_602250 = header.getOrDefault("X-Amz-Algorithm")
  valid_602250 = validateParameter(valid_602250, JString, required = false,
                                 default = nil)
  if valid_602250 != nil:
    section.add "X-Amz-Algorithm", valid_602250
  var valid_602251 = header.getOrDefault("X-Amz-SignedHeaders")
  valid_602251 = validateParameter(valid_602251, JString, required = false,
                                 default = nil)
  if valid_602251 != nil:
    section.add "X-Amz-SignedHeaders", valid_602251
  result.add "header", section
  section = newJObject()
  result.add "formData", section
  if body != nil:
    result.add "body", body

proc call*(call_602252: Call_UntagResource_602240; path: JsonNode; query: JsonNode;
          header: JsonNode; formData: JsonNode; body: JsonNode): Recallable =
  let valid = call_602252.validator(path, query, header, formData, body)
  let scheme = call_602252.pickScheme
  if scheme.isNone:
    raise newException(IOError, "unable to find a supported scheme")
  let url = call_602252.url(scheme.get, call_602252.host, call_602252.base,
                         call_602252.route, valid.getOrDefault("path"),
                         valid.getOrDefault("query"))
  result = atozHook(call_602252, url, valid)

proc call*(call_602253: Call_UntagResource_602240; resourceArn: string;
          tagKeys: JsonNode): Recallable =
  ## untagResource
  ##   resourceArn: string (required)
  ##   tagKeys: JArray (required)
  ##          : The key(s) of tag to be deleted
  var path_602254 = newJObject()
  var query_602255 = newJObject()
  add(path_602254, "resource-arn", newJString(resourceArn))
  if tagKeys != nil:
    query_602255.add "tagKeys", tagKeys
  result = call_602253.call(path_602254, query_602255, nil, nil, nil)

var untagResource* = Call_UntagResource_602240(name: "untagResource",
    meth: HttpMethod.HttpDelete, host: "mediapackage.amazonaws.com",
    route: "/tags/{resource-arn}#tagKeys", validator: validate_UntagResource_602241,
    base: "/", url: url_UntagResource_602242, schemes: {Scheme.Https, Scheme.Http})
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
